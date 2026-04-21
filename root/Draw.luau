local Draw = {}
local UserInputService = game:GetService("UserInputService")
local DrawActions = script.Parent.DrawActions

local ZoomSystem = require(DrawActions.Zoom)
local DragWorkspace = require(DrawActions.Drag)
local NodesModule = require(DrawActions.Nodes)

Draw.Nodes = {}
Draw.Lines = {}
local createdOrder = {}

function Draw:Init(config)
    self.Config = config
    self.NodeSize = config.NodeSize or Vector2.new(60,60)
    self.Padding = config.Padding or 10
    self.TypeColors = config.TypeColors or {}
    self.AllowedClasses = config.AllowedClasses or {}
    self.NodeSize = Vector2.new(self.NodeSize.X / 5, self.NodeSize.Y / 5)

    self.NodesModule = NodesModule
    self.NodesModule:Init(self)
end
local function TryGetSource(obj)
    if obj:IsA("ModuleScript") or obj:IsA("Script") or obj:IsA("LocalScript") then
        local success, src = pcall(function() return obj.Source end)
        if success then return src end
    end
    return nil
end

function Draw:_EnableNodeDrag(button, obj)
    local dragging = false
    local startPos
    local startButtonPos

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPos = input.Position
            startButtonPos = button.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    button.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = (input.Position - startPos) / self.ZoomSystem.UIScale.Scale
            local nodeData = self.Nodes[obj]
            if nodeData then
                nodeData.Button.Position = UDim2.new(0, startButtonPos.X.Offset + delta.X, 0, startButtonPos.Y.Offset + delta.Y)
                nodeData.Label.Position = UDim2.new(0, startButtonPos.X.Offset + delta.X, 0, startButtonPos.Y.Offset + delta.Y + self.NodeSize.X + 5)
                self:UpdateAllLines(obj)
            end
        end
    end)
end

function Draw:CreateNode(parent, obj, position)
    return self.NodesModule:CreateNode(parent,obj,position)
end

function Draw:CreateLegend(dock)
    self.LegendItems = {} 
    local yOffset = 10
    for className,color in pairs(self.TypeColors) do
    local count = 0
    for obj,_ in pairs(self.NodesModule.Nodes) do  
        if typeof(obj) == "Instance" and obj.ClassName == className then
            count = count + 1
        end
    end

        local legendNode = Instance.new("Frame")
        legendNode.Size = UDim2.new(0,20,0,20)
        legendNode.Position = UDim2.new(0,10,0,yOffset)
        legendNode.BackgroundColor3 = color
        legendNode.BorderSizePixel = 0
        legendNode.Parent = dock

        local legendLabel = Instance.new("TextLabel")
        legendLabel.Size = UDim2.new(0,200,0,20)
        legendLabel.Position = UDim2.new(0,40,0,yOffset)
        legendLabel.BackgroundTransparency = 1
        legendLabel.Text = className .. " ("..count..")"
        legendLabel.TextColor3 = Color3.new(1,1,1)
        legendLabel.TextScaled = true
        legendLabel.TextStrokeTransparency = 0
        legendLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        legendLabel.Parent = dock

        table.insert(self.LegendItems, legendNode)
        table.insert(self.LegendItems, legendLabel)

        yOffset = yOffset + 30
    end

    local lineColors = {
        {Color3.fromRGB(0,0,255),"1 connection"},
        {Color3.fromRGB(0,255,0),"2 connection"},
        {Color3.fromRGB(255,255,0),"3 connection"},
        {Color3.fromRGB(255,0,0),"4+ connection"}
    }
    yOffset = yOffset + 10
    for _,data in ipairs(lineColors) do
        local color,text = data[1],data[2]
        local legendLine = Instance.new("Frame")
        legendLine.Size = UDim2.new(0,40,0,4)
        legendLine.Position = UDim2.new(0,10,0,yOffset)
        legendLine.BackgroundColor3 = color
        legendLine.BorderSizePixel = 0
        legendLine.Parent = dock

        local legendLabel = Instance.new("TextLabel")
        legendLabel.Size = UDim2.new(0,150,0,20)
        legendLabel.Position = UDim2.new(0,60,0,yOffset-8)
        legendLabel.BackgroundTransparency = 1
        legendLabel.Text = text
        legendLabel.TextColor3 = Color3.new(1,1,1)
        legendLabel.TextScaled = true
        legendLabel.TextStrokeTransparency = 0
        legendLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        legendLabel.Parent = dock

        table.insert(self.LegendItems, legendLine)
        table.insert(self.LegendItems, legendLabel)

        yOffset = yOffset + 30
    end
end



function Draw:CreateZoomButtons(dock)
    local btnPlus = Instance.new("TextButton")
    btnPlus.Size = UDim2.new(0,30,0,30)
    btnPlus.Position = UDim2.new(1,-70,1,-40)
    btnPlus.AnchorPoint = Vector2.new(1,1)
    btnPlus.Text = "+"
    btnPlus.TextScaled = true
    btnPlus.Parent = dock
    btnPlus.MouseButton1Click:Connect(function()
        self.ZoomSystem.Zoom = math.min(self.ZoomSystem.MaxZoom,self.ZoomSystem.Zoom + self.ZoomSystem.ZoomStep)
        self.ZoomSystem.UIScale.Scale = self.ZoomSystem.Zoom
    end)

    local btnMinus = Instance.new("TextButton")
    btnMinus.Size = UDim2.new(0,30,0,30)
    btnMinus.Position = UDim2.new(1,-35,1,-40)
    btnMinus.AnchorPoint = Vector2.new(1,1)
    btnMinus.Text = "-"
    btnMinus.TextScaled = true
    btnMinus.Parent = dock
    btnMinus.MouseButton1Click:Connect(function()
        self.ZoomSystem.Zoom = math.max(self.ZoomSystem.MinZoom,self.ZoomSystem.Zoom - self.ZoomSystem.ZoomStep)
        self.ZoomSystem.UIScale.Scale = self.ZoomSystem.Zoom
    end)
end

-- Crear GUI completa
function Draw:CreateGUI(plugin)
    local dock = plugin:CreateDockWidgetPluginGui("NodeMap",DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Float,true,true,800,600,400,300
        ))
    dock.Name = "NodeMapGUI"
    dock.Title = "ConnectionsMap"
    dock.Enabled = true

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,1,0)
    frame.Position = UDim2.new(0.5,0,0.5,0)
    frame.AnchorPoint = Vector2.new(0.5,0.5)
    frame.BackgroundTransparency = 1
    frame.Parent = dock
    self.Frame = frame
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0,100,0,30)
    textBox.Position = UDim2.new(0,10,0,550) 
    textBox.PlaceholderText = "- / +"
    textBox.TextColor3 = Color3.new(0.184314, 0.184314, 0.184314) 
    textBox.ClearTextOnFocus = false
    textBox.Text = ""
    textBox.TextScaled = false
    textBox.TextSize = 14
    textBox.Parent = dock

    local btnToggleLegend = Instance.new("TextButton")
    btnToggleLegend.Size = UDim2.new(0, 100, 0, 30)
    btnToggleLegend.Position = UDim2.new(0, 10, 0, 510) 
    btnToggleLegend.Text = "Toggle Legend"
    btnToggleLegend.TextScaled = true
    btnToggleLegend.Parent = dock

    local legendVisible = true
    btnToggleLegend.MouseButton1Click:Connect(function()
        legendVisible = not legendVisible
        for _, item in ipairs(Draw.LegendItems) do
            item.Visible = legendVisible
        end
    end)


    local btnApply = Instance.new("TextButton")
    btnApply.Size = UDim2.new(0,50,0,30)
    btnApply.Position = UDim2.new(0,120,0,550)
    btnApply.Text = "Apply"
    btnApply.TextScaled = true
    btnApply.Parent = dock

    btnApply.MouseButton1Click:Connect(function()
        local delta = tonumber(textBox.Text)
        if delta then
            for _,nodeData in pairs(Draw.Nodes) do
                nodeData.Label.TextSize = math.clamp(nodeData.Label.TextSize + delta, 6, 50)
            end
        end
    end)

    self.ZoomSystem = ZoomSystem.new(frame,{InitialZoom=1,MinZoom=0.5,MaxZoom=2,ZoomStep=0.1})
    self.DragWorkspace = DragWorkspace.new(frame)

    for _,container in ipairs(self.Config.Containers) do
        for _,obj in pairs(container:GetDescendants()) do
            if self.AllowedClasses[obj.ClassName] then
                self:AddNodeIfNew(obj,frame)
            end
        end
    end

    self:CreateLegend(dock)
    self:CreateZoomButtons(dock)


    self:UpdateAllLines()
    return dock
end

function Draw:AddNodeIfNew(obj,parent)
    if self.Nodes[obj] then return end
    if not self.AllowedClasses[obj.ClassName] then return end

    local typeCenters = {
        ModuleScript = Vector2.new(parent.AbsoluteSize.X*0.25,parent.AbsoluteSize.Y*0.3),
        Script = Vector2.new(parent.AbsoluteSize.X*0.5,parent.AbsoluteSize.Y*0.7),
        LocalScript = Vector2.new(parent.AbsoluteSize.X*0.75,parent.AbsoluteSize.Y*0.3)
    }

    local function createNode()
        local center = typeCenters[obj.ClassName] or Vector2.new(parent.AbsoluteSize.X/2,parent.AbsoluteSize.Y/2)
        local minRadius = math.min(parent.AbsoluteSize.X,parent.AbsoluteSize.Y)/6
        local maxRadius = math.min(parent.AbsoluteSize.X,parent.AbsoluteSize.Y)/3
        local angle = math.random()*2*math.pi
        local radius = math.random()*(maxRadius-minRadius)+minRadius

        local x = center.X + math.cos(angle)*radius - self.NodeSize.X/2
        local y = center.Y + math.sin(angle)*radius - self.NodeSize.X/2

        self:CreateNode(parent,obj,Vector2.new(x,y))
    end

    if parent.AbsoluteSize.X==0 or parent.AbsoluteSize.Y==0 then
        parent:GetPropertyChangedSignal("AbsoluteSize"):Wait()
    end

    createNode()
end

function Draw:UpdateNode(obj)
    local nodeData = self.Nodes[obj]
    if nodeData then
        nodeData.Label.Text = obj.Name
        nodeData.Tooltip.Text = self:GetObjectPath(obj)
        self:UpdateAllLines(obj)
    end
end

function Draw:GetObjectPath(obj)
    local parts = {}
    local current = obj
    while current and current ~= game do
        table.insert(parts,1,current.Name)
        current = current.Parent
    end
    return table.concat(parts,".")
end

local function ResolveSelfPath(root, path)
    local ref = root
    for part in path:gmatch("[^%.]+") do
        if type(ref) == "table" then
            ref = ref[part]
        elseif typeof(ref) == "Instance" then
            ref = ref:FindFirstChild(part)
        else
            ref = nil
            break
        end
    end
    return ref
end

function Draw:GetDependencies(obj)
    local deps = {}
    local src = TryGetSource(obj)
    if not src then return deps end

    local requireMap = {}

    local function addDep(ref, reason)
        if ref and not table.find(deps, ref) then
            table.insert(deps, ref)
        end
    end

    for var, modPath in src:gmatch("local%s+(%w+)%s*=%s*require%s*%((.-)%)") do
        local ref = obj:FindFirstChild(modPath) or obj.Parent:FindFirstChild(modPath)
        requireMap[var] = ref
        addDep(ref, "require var: "..modPath)
    end

    for modPath in src:gmatch("require%s*%((.-)%)") do
        local ref = obj:FindFirstChild(modPath) or obj.Parent:FindFirstChild(modPath)
        addDep(ref, "require anon: "..modPath)
    end

    for varName, modRef in pairs(requireMap) do
        for _ in src:gmatch(varName.."%.new%s*%(") do
            addDep(modRef, "require.new call: "..varName)
        end
    end

    for path in src:gmatch("game%.([%w%.]+)") do
        local ref = game
        for part in string.gmatch(path,"[^%.]+") do
            ref = ref and ref:FindFirstChild(part)
        end
        addDep(ref, "game path: "..path)
    end

    for requireExpr in src:gmatch("require%s*%((.-)%)") do
        local ref = nil
        if requireExpr:match("^self%.") then
            local path = requireExpr:gsub("^self%.", "")
            ref = ResolveSelfPath(self, path) 
        elseif requireExpr:match("^script%.Parent") then
            local path = requireExpr:gsub("^script%.Parent%.", "")
            ref = obj
            for part in path:gmatch("[^%.]+") do
                ref = ref and ref:FindFirstChild(part)
            end
        end
        addDep(ref, "require: "..requireExpr)
    end

    return deps
end


function Draw:DrawLine(fromObj,toObj,parent)
    if not self.Nodes[fromObj] or not self.Nodes[toObj] then return end
    if not self.Lines[fromObj] then self.Lines[fromObj]={} end
    if self.Lines[fromObj][toObj] then return end

    local line = Instance.new("Frame")
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0.5,0.5)
    line.ZIndex = -1
    line.Parent = parent

    self.Lines[fromObj][toObj] = line
    self:UpdateLine(fromObj,toObj)
end

function Draw:UpdateLine(fromObj,toObj)
    local line = self.Lines[fromObj] and self.Lines[fromObj][toObj]
    local fromNode = self.Nodes[fromObj]
    local toNode = self.Nodes[toObj]
    if not line or not fromNode or not toNode then
        if line then line:Destroy() end
        if self.Lines[fromObj] then self.Lines[fromObj][toObj]=nil end
        return
    end

    local x1 = fromNode.Button.Position.X.Offset + self.NodeSize.X/2
    local y1 = fromNode.Button.Position.Y.Offset + self.NodeSize.X/2
    local x2 = toNode.Button.Position.X.Offset + self.NodeSize.X/2
    local y2 = toNode.Button.Position.Y.Offset + self.NodeSize.X/2

    local dx,dy = x2-x1,y2-y1
    local dist = math.sqrt(dx*dx+dy*dy)
    local angle = math.deg(math.atan2(dy,dx))

    local count = 0
    for from,deps in pairs(self.Lines) do
        if deps[toObj] then count=count+1 end
    end

    if count==1 then
        line.BackgroundColor3 = Color3.fromRGB(0,0,255)
    elseif count==2 then
        line.BackgroundColor3 = Color3.fromRGB(0,255,0)
    elseif count==3 then
        line.BackgroundColor3 = Color3.fromRGB(255,255,0)
    else
        line.BackgroundColor3 = Color3.fromRGB(255,0,0)
    end

    line.Size = UDim2.new(0,dist,0,2)
    line.Position = UDim2.new(0,x1+dx/2,0,y1+dy/2)
    line.Rotation = angle
end

function Draw:UpdateAllLines(node)
    local parent = self.Frame
    if node then
        local currentDeps = {}
        for _,dep in ipairs(self:GetDependencies(node)) do
            if type(dep) == "string" then
                self:AddNodeIfNew(dep,parent)
            end
            currentDeps[dep]=true
            self:DrawLine(node,dep,parent)
        end
        if self.Lines[node] then
            for dep,line in pairs(self.Lines[node]) do
                if not currentDeps[dep] then
                    line:Destroy()
                    self.Lines[node][dep]=nil
                end
            end
        end
        for fromObj,deps in pairs(self.Lines) do
            if deps[node] then
                self:UpdateLine(fromObj,node)
            end
        end
    else
        for obj,_ in pairs(self.Nodes) do
            self:UpdateAllLines(obj)
        end
    end
end


return Draw
