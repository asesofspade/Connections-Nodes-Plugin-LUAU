-- Nodes.lua
local Nodes = {}

Nodes.Nodes = {}

function Nodes:Init(draw)
    self.Draw = draw
    self.NodeSize = draw.NodeSize
end

function Nodes:_EnableNodeDrag(button, obj)
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
            local delta = (input.Position - startPos) / self.Draw.ZoomSystem.UIScale.Scale
            local nodeData = self.Nodes[obj]
            if nodeData then
                nodeData.Button.Position = UDim2.new(0, startButtonPos.X.Offset + delta.X, 0, startButtonPos.Y.Offset + delta.Y)
                nodeData.Label.Position = UDim2.new(0, startButtonPos.X.Offset + delta.X, 0, startButtonPos.Y.Offset + delta.Y + self.NodeSize.X + 5)
                self.Draw:UpdateAllLines(obj)
            end
        end
    end)
end

function Nodes:CreateNode(parent, obj, position)
    if self.Nodes[obj] then return self.Nodes[obj].Button end
    if not self.Draw.AllowedClasses[obj.ClassName] then return end

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, self.NodeSize.X, 0, self.NodeSize.X)
    button.Position = UDim2.new(0, position.X, 0, position.Y)
    button.BackgroundColor3 = self.Draw.TypeColors[obj.ClassName] or Color3.fromRGB(180,180,180)
    button.BorderSizePixel = 0
    button.Text = ""
    button.Parent = parent
    button.Active = true

    local uicorner = Instance.new("UICorner")
    uicorner.CornerRadius = UDim.new(0.5,0)
    uicorner.Parent = button

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, self.NodeSize.X, 0, 25)
    label.Position = UDim2.new(0, position.X, 0, position.Y + self.NodeSize.X + 2)
    label.BackgroundTransparency = 1
    label.Text = obj.Name
    label.TextSize = 10
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    label.TextColor3 = Color3.new(1,1,1)
    label.Parent = parent

    local tooltip = Instance.new("TextLabel")
    tooltip.Size = UDim2.new(1.5,0,0,18)
    tooltip.Position = UDim2.new(0,0,0,-20)
    tooltip.TextSize = 7
    tooltip.TextColor3 = Color3.new(1,1,1)
    tooltip.TextStrokeTransparency = 0
    tooltip.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    tooltip.BackgroundTransparency = 1
    tooltip.Text = self.Draw:GetObjectPath(obj)
    tooltip.Visible = false
    tooltip.Parent = button

    button.MouseEnter:Connect(function() tooltip.Visible = true end)
    button.MouseLeave:Connect(function() tooltip.Visible = false end)

    self.Nodes[obj] = {
        Button = button,
        Label = label,
        Tooltip = tooltip,
    }

    self:_EnableNodeDrag(button,obj)
    return button
end

return Nodes
