--[[
    Standalone ESP + Aimbot pulled from Games/rivals.lua.
    Default binds: Q toggles aimbot, T toggles ESP.
]]

--=====================================================
-- Services & shared state
--=====================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end)

local state = {
    toggles = {
        Aimbot = true,
        ESP = true,
    },
    keybinds = {
        Aimbot = Enum.KeyCode.Q,
        ESP = Enum.KeyCode.T,
    },
    maxDistance = 350,
    fieldOfView = 80,
    espColor = Color3.fromRGB(255, 130, 150),
    aimbotTargetMode = "Head",
    aimbotSmoothness = 1,
}

local aimOffsets = {
    Head = Vector3.new(0, 0.6, 0),
    Body = Vector3.new(0, 0.25, 0),
    Legs = Vector3.new(0, 1.4, 0),
}

local highlightFolder = Instance.new("Folder")
highlightFolder.Name = "RivalsStandaloneESP"
highlightFolder.Parent = (gethui and gethui())
    or (game:FindFirstChild("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"))

local highlights = {}

--=====================================================
-- ESP helpers
--=====================================================
local function updateHighlightAppearance()
    for player, container in pairs(highlights) do
        if container.highlight.Parent then
            container.highlight.OutlineColor = state.espColor
            container.highlight.OutlineTransparency = state.toggles.ESP and 0 or 1
            container.highlight.Enabled = state.toggles.ESP
        else
            highlights[player] = nil
        end
    end
end

local function ensureHighlight(player)
    if player == LocalPlayer then
        return
    end
    if highlights[player] then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "RivalsESPHighlight"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 1
    highlight.OutlineColor = state.espColor
    highlight.Enabled = state.toggles.ESP
    highlight.Parent = highlightFolder

    local container = {
        highlight = highlight,
        connections = {},
    }

    local function attach(character)
        highlight.Adornee = character
    end

    if player.Character then
        attach(player.Character)
    end

    table.insert(container.connections, player.CharacterAdded:Connect(attach))
    table.insert(container.connections, player.CharacterRemoving:Connect(function()
        highlight.Adornee = nil
    end))

    highlights[player] = container
end

local function cleanupHighlight(player)
    local container = highlights[player]
    if not container then
        return
    end

    for _, connection in ipairs(container.connections) do
        connection:Disconnect()
    end
    container.highlight:Destroy()
    highlights[player] = nil
end

--=====================================================
-- Aimbot helpers
--=====================================================
local function resolveTargetPart(character)
    if not character then
        return nil
    end
    local mode = state.aimbotTargetMode
    local part
    if mode == "Head" then
        part = character:FindFirstChild("Head")
    elseif mode == "Body" then
        part = character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("HumanoidRootPart")
    else
        part = character:FindFirstChild("LeftLowerLeg")
            or character:FindFirstChild("RightLowerLeg")
            or character:FindFirstChild("LeftLeg")
            or character:FindFirstChild("RightLeg")
            or character:FindFirstChild("HumanoidRootPart")
    end
    return part, aimOffsets[mode] or Vector3.new()
end

local function getClosestPlayerInFOV()
    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        return nil, nil
    end

    local closestPlayer
    local closestPosition
    local smallestAngle = state.fieldOfView
    local cameraPos = Camera.CFrame.Position
    local look = Camera.CFrame.LookVector

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local targetPart, offset = resolveTargetPart(character)
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if targetPart and root and humanoid and humanoid.Health > 0 then
                local targetPos = targetPart.Position + offset
                local distance = (targetPos - myRoot.Position).Magnitude
                if distance <= state.maxDistance then
                    local direction = (targetPos - cameraPos).Unit
                    local angle = math.deg(math.acos(math.clamp(look:Dot(direction), -1, 1)))
                    if angle < smallestAngle then
                        smallestAngle = angle
                        closestPlayer = player
                        closestPosition = targetPos
                    end
                end
            end
        end
    end

    return closestPlayer, closestPosition
end

local function updateAutoRotate()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.AutoRotate = not state.toggles.Aimbot
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.1)
    updateAutoRotate()
end)

--=====================================================
-- Toggle + input handling
--=====================================================
local function setToggle(id, enabled)
    if state.toggles[id] == enabled then
        return
    end
    state.toggles[id] = enabled
    if id == "ESP" then
        updateHighlightAppearance()
    elseif id == "Aimbot" then
        updateAutoRotate()
    end
    print(string.format("[Rivals Lite] %s %s", id, enabled and "ON" or "OFF"))
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        for id, key in pairs(state.keybinds) do
            if input.KeyCode == key then
                setToggle(id, not state.toggles[id])
                break
            end
        end
    end
end)

--=====================================================
-- Player bookkeeping
--=====================================================
for _, player in ipairs(Players:GetPlayers()) do
    ensureHighlight(player)
end

Players.PlayerAdded:Connect(ensureHighlight)
Players.PlayerRemoving:Connect(cleanupHighlight)

updateHighlightAppearance()
updateAutoRotate()

--=====================================================
-- Render loop
--=====================================================
RunService.RenderStepped:Connect(function()
    if not state.toggles.Aimbot then
        return
    end

    local targetPlayer, targetPosition = getClosestPlayerInFOV()
    if not (targetPlayer and targetPosition) then
        return
    end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        local horizontalLook = Vector3.new(targetPosition.X, root.Position.Y, targetPosition.Z)
        root.CFrame = CFrame.new(root.Position, horizontalLook)
    end

    local desired = CFrame.new(Camera.CFrame.Position, targetPosition)
    local smooth = math.clamp(1 - (state.aimbotSmoothness / 5), 0.05, 1)
    Camera.CFrame = Camera.CFrame:Lerp(desired, smooth)
end)

print("[Rivals Lite] ESP and Aimbot loaded. Press Q for aimbot, T for ESP.")
