-- Load Rayfield Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Toggle states for ESP, Hitbox, and Aimbot
local highlightEnabled = false
local hitboxEnabled = false
local aimbotEnabled = false

-- ESP color settings
local espFillColor = Color3.fromRGB(255, 0, 0)   -- #FF0000
local espOutlineColor = Color3.fromRGB(255, 0, 0)  -- #FF0000

-- Hitbox settings variables
_G.HeadSize = 10  -- Default hitbox size when enabled
local hitboxColor = Color3.fromRGB(255, 0, 0)  -- #FF0000

-- FOV circle setup
local FOVCircle = Drawing.new("Circle")
FOVCircle.Radius = 200
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.new(1, 1, 1)
FOVCircle.Visible = false  -- Initially hidden

-- Aimbot variables
local lookAtTarget = false
local lockedTarget = nil

-- Function to update a character's hitbox
local function updateHitbox(character)
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        if hitboxEnabled then
            hrp.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize)
            hrp.Transparency = 0.7
            hrp.BrickColor = BrickColor.new(hitboxColor)
            hrp.Material = Enum.Material.Neon
            hrp.CanCollide = false
        else
            hrp.Size = Vector3.new(2, 2, 1)
            hrp.Transparency = 1
            hrp.BrickColor = BrickColor.new("Bright blue")
            hrp.Material = Enum.Material.SmoothPlastic
            hrp.CanCollide = true
        end
    end
end

-- Apply hitbox updates to players (except local player)
local function applyHitboxToPlayer(player)
    if player == LocalPlayer then return end
    if player.Character then
        updateHitbox(player.Character)
    end
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("HumanoidRootPart", 5)
        updateHitbox(character)
    end)
end

for _, player in pairs(Players:GetPlayers()) do
    applyHitboxToPlayer(player)
end
Players.PlayerAdded:Connect(applyHitboxToPlayer)

-- Function to apply ESP highlight to a player's character
local function applyHighlight(player)
    if player == LocalPlayer then return end
    local function onCharacterAdded(character)
        if highlightEnabled then
            local highlight = Instance.new("Highlight", character)
            highlight.Archivable = true
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Enabled = true
            highlight.FillColor = espFillColor
            highlight.OutlineColor = espOutlineColor
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
        end
    end

    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

for _, player in pairs(Players:GetPlayers()) do
    applyHighlight(player)
end
Players.PlayerAdded:Connect(applyHighlight)

-- Aimbot helper function: Checks if a target is valid for locking on.
local function isTargetValid(player)
    if not player.Character then return false end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not hrp or not humanoid or humanoid.Health <= 0 then return false end

    local blacklist = {}
    if LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            table.insert(blacklist, part)
        end
    end
    for _, part in ipairs(player.Character:GetDescendants()) do
        table.insert(blacklist, part)
    end

    local parts = Camera:GetPartsObscuringTarget({ hrp.Position }, blacklist)
    return #parts == 0
end

-- Returns the closest valid player (within the FOV circle) for initial lock-on.
local function GetClosestPlayer()
    local closest, minDist = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if isTargetValid(player) then
                local hrpPos = player.Character.HumanoidRootPart.Position
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrpPos)
                if onScreen then
                    local pos2D = Vector2.new(screenPos.X, screenPos.Y)
                    local dist = (mousePos - pos2D).Magnitude
                    if dist <= FOVCircle.Radius and dist < minDist then
                        minDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

-- Create the main window using Rayfield
local Window = Rayfield:CreateWindow({
    Name = "Universal Aimbot Script",
    LoadingTitle = "Universal Aimbot Script",
    LoadingSubtitle = "by Astyll",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "UASConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

-- General Tab
local GeneralTab = Window:CreateTab("General", "box")

-- Aimbot Toggle
local toggleAimbot = GeneralTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Flag = "ToggleAimbot",
    Callback = function(Value)
        aimbotEnabled = Value
        FOVCircle.Visible = aimbotEnabled
    end
})

local AimbotKeybind = GeneralTab:CreateKeybind({
    Name = "Aimbot Keybind",
    CurrentKeybind = "G",
    HoldToInteract = false,
    Flag = "AimbotKeybind",
    Callback = function()
        aimbotEnabled = not aimbotEnabled
        toggleAimbot:Set(aimbotEnabled)
        FOVCircle.Visible = aimbotEnabled
    end
})

-- ESP Toggle
local toggleESP = GeneralTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Flag = "ToggleESP",
    Callback = function(Value)
        highlightEnabled = Value
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local highlight = player.Character:FindFirstChild("Highlight")
                if highlight then
                    highlight:Destroy()
                end
                if highlightEnabled then
                    applyHighlight(player)
                end
            end
        end
    end
})

-- ESP Keybind (default "H")
local espKeybind = GeneralTab:CreateKeybind({
    Name = "ESP Keybind",
    CurrentKeybind = "H",
    HoldToInteract = false,
    Flag = "ESPKeybind",
    Callback = function(Keybind)
        highlightEnabled = not highlightEnabled
        toggleESP:Set(highlightEnabled)
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local highlight = player.Character:FindFirstChild("Highlight")
                if highlight then
                    highlight:Destroy()
                end
                if highlightEnabled then
                    applyHighlight(player)
                end
            end
        end
    end,
})

-- Hitbox Toggle
local toggleHitbox = GeneralTab:CreateToggle({
    Name = "Hitbox Extender",
    CurrentValue = false,
    Flag = "ToggleHitbox",
    Callback = function(Value)
        hitboxEnabled = Value
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                updateHitbox(player.Character)
            end
        end
    end,
})

-- Hitbox Toggle Keybind (default "J")
local hitboxKeybind = GeneralTab:CreateKeybind({
    Name = "Hitbox Extender Keybind",
    CurrentKeybind = "J",
    HoldToInteract = false,
    Flag = "HitboxKeybind",
    Callback = function(Keybind)
        hitboxEnabled = not hitboxEnabled
        toggleHitbox:Set(hitboxEnabled)
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                updateHitbox(player.Character)
            end
        end
    end,
})

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", "bolt")

SettingsTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {2, 50},
    Increment = 1,
    Suffix = "",
    CurrentValue = _G.HeadSize,
    Flag = "HitboxSize",
    Callback = function(Value)
         _G.HeadSize = Value
         for _, player in pairs(Players:GetPlayers()) do
             if player ~= LocalPlayer and player.Character then
                 updateHitbox(player.Character)
             end
         end
    end,
})

-- FOV Circle Radius Slider
SettingsTab:CreateSlider({
    Name = "FOV Circle Radius",
    Range = {50, 500},
    Increment = 5,
    Suffix = "",
    CurrentValue = FOVCircle.Radius,
    Flag = "FOVCircleRadius",
    Callback = function(Value)
         FOVCircle.Radius = Value
    end,
})

-- Colors Tab
local ColorsTab = Window:CreateTab("Colors", "paintbrush")

ColorsTab:CreateColorPicker({
    Name = "ESP Fill Color",
    Color = espFillColor,
    Flag = "ESPFillColor",
    Callback = function(Value)
        espFillColor = Value
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local highlight = player.Character:FindFirstChild("Highlight")
                if highlight then
                    highlight.FillColor = espFillColor
                end
            end
        end
    end
})

ColorsTab:CreateColorPicker({
    Name = "ESP Outline Color",
    Color = espOutlineColor,
    Flag = "ESPOutlineColor",
    Callback = function(Value)
        espOutlineColor = Value
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local highlight = player.Character:FindFirstChild("Highlight")
                if highlight then
                    highlight.OutlineColor = espOutlineColor
                end
            end
        end
    end
})

ColorsTab:CreateColorPicker({
    Name = "Hitbox Color",
    Color = hitboxColor,
    Flag = "HitboxColor",
    Callback = function(Value)
        hitboxColor = Value
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                updateHitbox(player.Character)
            end
        end
    end
})

-- FOV Circle Color Picker
ColorsTab:CreateColorPicker({
    Name = "FOV Circle Color",
    Color = FOVCircle.Color,
    Flag = "FOVCircleColor",
    Callback = function(Value)
         FOVCircle.Color = Value
    end,
})

-- Mouse input logic for aimbot:
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        lookAtTarget = true
        lockedTarget = GetClosestPlayer()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        lookAtTarget = false
        lockedTarget = nil
    end
end)

-- Combined RenderStepped loop: update FOV circle and process aimbot lock-on when active.
RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = mousePos
    if aimbotEnabled and lookAtTarget then
        if lockedTarget then
            local character = lockedTarget.Character
            local humanoid = character and character:FindFirstChild("Humanoid")
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if not character or not hrp or not humanoid or humanoid.Health <= 0 then
                lockedTarget = nil
            end
        end

        if not lockedTarget then
            lockedTarget = GetClosestPlayer()
        end

        if lockedTarget and lockedTarget.Character and lockedTarget.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = lockedTarget.Character.HumanoidRootPart
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, hrp.Position)
        end
    end
end)
