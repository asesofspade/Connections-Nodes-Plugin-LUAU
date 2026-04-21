local Watcher = {}
local RunService = game:GetService("RunService")

function Watcher:Init(config)
    self.AllowedClasses = config.AllowedClasses
    self.Containers = config.Containers
end

function Watcher:Start(frame, Draw)
    local seen = {}

    spawn(function()
        while true do
            for obj,_ in pairs(Draw.Nodes) do
                if typeof(obj) == "Instance" and not obj.Parent then
                    local nodeData = Draw.Nodes[obj]
                    if nodeData then
                        if nodeData.Button then nodeData.Button:Destroy() end
                        if nodeData.Label then nodeData.Label:Destroy() end
                        if nodeData.Tooltip then nodeData.Tooltip:Destroy() end
                    end
                    Draw.Nodes[obj] = nil
                end
            end

            for _, container in ipairs(self.Containers) do
                for _, obj in pairs(container:GetDescendants()) do
                    if self.AllowedClasses[obj.ClassName] then
                        if not seen[obj] then
                            seen[obj] = true
                            Draw:AddNodeIfNew(obj, frame)

                            obj.Changed:Connect(function(prop)
                                if prop == "Name" or prop == "ClassName" then
                                    Draw:UpdateNode(obj)
                                end
                            end)

                            if obj:IsA("ModuleScript") or obj:IsA("Script") or obj:IsA("LocalScript") then
                                local deps = Draw:GetDependencies(obj)
                                for _, dep in ipairs(deps) do
                                    Draw:DrawLine(obj, dep, frame)
                                end
                            end
                        else
                            Draw:UpdateNode(obj)
                        end
                    end
                end
            end

            Draw:UpdateAllLines()

            wait(0.5)
        end
    end)
end



return Watcher
