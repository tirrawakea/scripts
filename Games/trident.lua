--[[
    Trident Survival ESP + Aimbot
    - Outline ESP draws both body and head (unique colors)
    - Sleeping players are ignored completely (no ESP, no targeting)
    - Q toggles aimbot, T toggles ESP by default
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

local highlightFolderName = "TridentOutlineESP"
local guiParent = (gethui and gethui())
    or (game:FindFirstChild("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"))
local existing = guiParent:FindFirstChild(highlightFolderName)
if existing then
    existing:Destroy()
end

local highlightFolder = Instance.new("Folder")
highlightFolder.Name = highlightFolderName
highlightFolder.Parent = guiParent

local state = {
    toggles = {
        Aimbot = true,
        ESP = true,
    },
    keybinds = {
        Aimbot = Enum.KeyCode.Q,
        ESP = Enum.KeyCode.T,
    },
    colors = {
        Body = Color3.fromRGB(255, 110, 150),
        Head = Color3.fromRGB(255, 230, 120),
    },
    maxDistance = 400,
    fieldOfView = 85,
    espUpdateInterval = 0.2,
    aimbotTargetMode = "Head",
    aimbotSmoothness = 1.2,
}

local aimOffsets = {
    Head = Vector3.new(0, 0.6, 0),
    Body = Vector3.new(0, 0.25, 0),
    Legs = Vector3.new(0, 1.1, 0),
}

local headNames = {
    Head = true,
    UpperHead = true,
    LowerHead = true,
    Helmet = true,
    Mask = true,
}

local sleepMarkerNames = {"Sleeping", "IsSleeping", "Sleep", "SleepState", "Asleep", "IsAsleep"}
local sleepFolderNames = {"Status", "States", "State", "Effects", "Debuffs", "Statuses", "Flags"}

local highlights = {}

--=====================================================
-- Sleeping helpers
--=====================================================
local function interpretSleepValue(value)
    if value == nil then
        return nil
    end
    local valueType = typeof(value)
    if valueType == "boolean" then
        return value
    elseif valueType == "number" then
        if value == 0 then
            return false
        elseif value == 1 then
            return true
        end
    elseif valueType == "string" then
        local lower = value:lower()
        if lower:find("sleep") then
            return true
        elseif lower:find("awake") or lower:find("stand") then
            return false
        elseif lower == "true" or lower == "1" then
            return true
        elseif lower == "false" or lower == "0" then
            return false
        end
    end
    return nil
end

local function readSleepSignal(inst)
    if not inst then
        return nil
    end
    for attrName, attrValue in pairs(inst:GetAttributes()) do
        if attrName and attrName:lower():find("sleep") then
            local interpreted = interpretSleepValue(attrValue)
            if interpreted ~= nil then
                return interpreted
            end
        end
    end
    for _, name in ipairs(sleepMarkerNames) do
        local attr = inst:GetAttribute(name)
        if attr ~= nil then
            local interpreted = interpretSleepValue(attr)
            if interpreted ~= nil then
                return interpreted
            end
        end
        local child = inst:FindFirstChild(name)
        if child then
            if child:IsA("BoolValue") then
                return child.Value
            end
            if child:IsA("StringValue") then
                local interpreted = interpretSleepValue(child.Value)
                if interpreted ~= nil then
                    return interpreted
                end
            end
            if child:IsA("IntValue") or child:IsA("NumberValue") then
                local interpreted = interpretSleepValue(child.Value)
                if interpreted ~= nil then
                    return interpreted
                end
            end
        end
    end
    return nil
end

local function scanDescendantsForSleep(character)
    if not character then
        return nil
    end
    for _, descendant in ipairs(character:GetDescendants()) do
        for attrName, attrValue in pairs(descendant:GetAttributes()) do
            if attrName and attrName:lower():find("sleep") then
                local interpreted = interpretSleepValue(attrValue)
                if interpreted ~= nil then
                    return interpreted
                end
            end
        end
        local lowerName = descendant.Name:lower()
        if lowerName:find("sleep") then
            if descendant:IsA("BoolValue") then
                return descendant.Value
            elseif descendant:IsA("StringValue") then
                local interpreted = interpretSleepValue(descendant.Value)
                if interpreted ~= nil then
                    return interpreted
                end
            elseif descendant:IsA("NumberValue") or descendant:IsA("IntValue") then
                local interpreted = interpretSleepValue(descendant.Value)
                if interpreted ~= nil then
                    return interpreted
                end
            elseif descendant:IsA("ObjectValue") then
                return descendant.Value ~= nil
            end
        end
    end
    return nil
end

local function isPlayerSleeping(player)
    local character = player.Character
    if not character then
        return false
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    local sources = {player, character}
    if humanoid then
        table.insert(sources, humanoid)
    end

    for _, folderName in ipairs(sleepFolderNames) do
        local folder = character:FindFirstChild(folderName)
        if folder then
            table.insert(sources, folder)
        end
    end

    for _, inst in ipairs(sources) do
        local flag = readSleepSignal(inst)
        if flag ~= nil then
            return flag
        end
    end

    local statusValue = character:FindFirstChild("State")
    if statusValue and statusValue:IsA("StringValue") then
        if statusValue.Value:lower():find("sleep") then
            return true
        end
    end

    local descendantFlag = scanDescendantsForSleep(character)
    if descendantFlag ~= nil then
        return descendantFlag
    end

    if humanoid then
        local root = character:FindFirstChild("HumanoidRootPart")
        if humanoid.PlatformStand and humanoid.AutoRotate == false and root then
            local velocity = root.AssemblyLinearVelocity
            if velocity.Magnitude < 0.1 then
                return true
            end
        end
    end

    return false
end

--=====================================================
-- ESP helpers
--=====================================================
local function createOutline(color)
    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = color
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = false
    highlight.Parent = highlightFolder
    return highlight
end

local function resolveHead(character)
    if not character then
        return nil
    end
    for name in pairs(headNames) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return nil
end

local function ensureHighlight(player)
    if player == LocalPlayer then
        return
    end
    if highlights[player] then
        return
    end

    local container = {
        body = createOutline(state.colors.Body),
        head = createOutline(state.colors.Head),
        connections = {},
        charConnections = {},
    }

    local function clearCharacterConnections()
        for index, connection in ipairs(container.charConnections) do
            connection:Disconnect()
            container.charConnections[index] = nil
        end
    end

    local function attach(character)
        clearCharacterConnections()
        container.body.Adornee = character
        container.head.Adornee = resolveHead(character)
        if not character then
            return
        end

        table.insert(container.charConnections, character.ChildAdded:Connect(function(child)
            if headNames[child.Name] and child:IsA("BasePart") then
                container.head.Adornee = child
            end
        end))

        table.insert(container.charConnections, character.ChildRemoved:Connect(function(child)
            if child == container.head.Adornee then
                container.head.Adornee = resolveHead(character)
            end
        end))
    end

    if player.Character then
        attach(player.Character)
    end

    table.insert(container.connections, player.CharacterAdded:Connect(attach))
    table.insert(container.connections, player.CharacterRemoving:Connect(function()
        clearCharacterConnections()
        container.body.Adornee = nil
        container.head.Adornee = nil
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
    for _, connection in ipairs(container.charConnections) do
        connection:Disconnect()
    end
    if container.body then
        container.body:Destroy()
    end
    if container.head then
        container.head:Destroy()
    end
    highlights[player] = nil
end

local function updateHighlightAppearance()
    for player, container in pairs(highlights) do
        local body = container.body
        local head = container.head
        if not (body and head) or not body.Parent then
            cleanupHighlight(player)
        else
            local sleeping = isPlayerSleeping(player)
            local enabled = state.toggles.ESP and not sleeping
            body.OutlineColor = state.colors.Body
            head.OutlineColor = state.colors.Head
            body.Enabled = enabled
            head.Enabled = enabled and head.Adornee ~= nil
        end
    end
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
        part = resolveHead(character)
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
        if player ~= LocalPlayer and not isPlayerSleeping(player) then
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
    print(string.format("[Trident ESP] %s %s", id, enabled and "ON" or "OFF"))
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

local espAccumulator = 0
RunService.Heartbeat:Connect(function(dt)
    espAccumulator += dt
    if espAccumulator >= state.espUpdateInterval then
        espAccumulator = 0
        updateHighlightAppearance()
    end
end)

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

print("[Trident ESP] Outline ESP + sleeper-safe aimbot loaded. Q toggles aimbot, T toggles ESP.")
