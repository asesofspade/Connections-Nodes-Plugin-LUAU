local DragWorkspace = {}
DragWorkspace.__index = DragWorkspace

local UserInputService = game:GetService("UserInputService")

function DragWorkspace.new(frame)
    local self = setmetatable({}, DragWorkspace)
    self.Frame = frame
    self.Dragging = false
    self.StartPos = nil
    self.OriginalPos = nil

    self:_ConnectDrag()
    return self
end

function DragWorkspace:_ConnectDrag()
    local frame = self.Frame

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = true
            self.StartPos = input.Position
            self.OriginalPos = frame.Position
        end
    end)

    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = false
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and self.Dragging then
            local delta = (input.Position - self.StartPos) / self.Frame.UIScale.Scale
            local newPos = self.OriginalPos + UDim2.new(0, delta.X, 0, delta.Y)
            frame.Position = newPos

        end
    end)
end

return DragWorkspace
