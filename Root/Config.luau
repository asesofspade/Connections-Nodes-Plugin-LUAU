local Config = {}

Config.AllowedClasses = {
    ModuleScript = true,
    Script = true,
    LocalScript = true,
    RemoteEvent = true,
    RemoteFunction = true,
    ScreenGui = true,
}

Config.TypeColors = {
    ModuleScript = Color3.fromRGB(255,200,0),
    Script = Color3.fromRGB(100,250,100),
    LocalScript = Color3.fromRGB(100,150,250),
    RemoteEvent = Color3.fromRGB(250,100,100),
    RemoteFunction = Color3.fromRGB(250,150,50),
    ScreenGui = Color3.fromRGB(150,100,250),
}

Config.NodeSize = Vector2.new(120, 50)

Config.Padding = 20

Config.Containers = {
    workspace,
    game:GetService("ReplicatedStorage"),
    game:GetService("ReplicatedFirst"),
    game:GetService("ServerStorage"),
    game:GetService("ServerScriptService"),
    game:GetService("StarterPlayer").StarterCharacterScripts,
    game:GetService("StarterGui"),
    game:GetService("StarterPack"),
}

return Config
