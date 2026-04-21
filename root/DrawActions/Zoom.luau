local ZoomSystem = {}
ZoomSystem.__index = ZoomSystem

local UserInputService = game:GetService("UserInputService")

function ZoomSystem.new(frame, options)
    local self = setmetatable({}, ZoomSystem)

    self.Frame = frame
    self.Zoom = options and options.InitialZoom or 1
    self.MinZoom = options and options.MinZoom or 0.5
    self.MaxZoom = options and options.MaxZoom or 2
    self.ZoomStep = options and options.ZoomStep or 0.1

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = self.Zoom
    uiScale.Parent = frame
    self.UIScale = uiScale

    return self
end

return ZoomSystem
