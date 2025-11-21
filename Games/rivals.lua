--=====================================================
-- SECTION: Services & Shared State
--=====================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local themes = {
    Dark = {
        Background = Color3.fromRGB(18, 20, 28),
        Header = Color3.fromRGB(32, 34, 46),
        Section = Color3.fromRGB(28, 30, 42),
        Button = Color3.fromRGB(45, 47, 60),
        ButtonAccent = Color3.fromRGB(90, 120, 255),
        ButtonMuted = Color3.fromRGB(52, 56, 72),
        Input = Color3.fromRGB(48, 52, 68),
        ToggleOn = Color3.fromRGB(70, 190, 130),
        ToggleOff = Color3.fromRGB(60, 62, 82),
        TextPrimary = Color3.fromRGB(235, 235, 255),
        TextMuted = Color3.fromRGB(175, 180, 210),
        TabActive = Color3.fromRGB(90, 120, 255),
        TabInactive = Color3.fromRGB(45, 47, 60),
    },
    Midnight = {
        Background = Color3.fromRGB(10, 13, 24),
        Header = Color3.fromRGB(20, 22, 34),
        Section = Color3.fromRGB(18, 20, 30),
        Button = Color3.fromRGB(30, 32, 44),
        ButtonAccent = Color3.fromRGB(120, 90, 255),
        ButtonMuted = Color3.fromRGB(42, 44, 60),
        Input = Color3.fromRGB(38, 40, 55),
        ToggleOn = Color3.fromRGB(110, 160, 255),
        ToggleOff = Color3.fromRGB(50, 52, 66),
        TextPrimary = Color3.fromRGB(225, 230, 255),
        TextMuted = Color3.fromRGB(150, 160, 210),
        TabActive = Color3.fromRGB(120, 90, 255),
        TabInactive = Color3.fromRGB(40, 42, 56),
    },
    Light = {
        Background = Color3.fromRGB(235, 237, 245),
        Header = Color3.fromRGB(210, 214, 230),
        Section = Color3.fromRGB(218, 222, 236),
        Button = Color3.fromRGB(199, 204, 225),
        ButtonAccent = Color3.fromRGB(110, 140, 255),
        ButtonMuted = Color3.fromRGB(190, 195, 212),
        Input = Color3.fromRGB(205, 210, 226),
        ToggleOn = Color3.fromRGB(100, 190, 140),
        ToggleOff = Color3.fromRGB(170, 175, 195),
        TextPrimary = Color3.fromRGB(35, 40, 60),
        TextMuted = Color3.fromRGB(75, 85, 115),
        TabActive = Color3.fromRGB(110, 140, 255),
        TabInactive = Color3.fromRGB(150, 155, 180),
    },
}

local state = {
    toggles = {
        Aimbot = false,
        ESP = false,
        Trigger = true,
    },
    keybinds = {
        Aimbot = Enum.KeyCode.Q,
        ESP = Enum.KeyCode.T,
        Trigger = Enum.KeyCode.Y,
    },
    showHideKey = Enum.KeyCode.RightControl,
    waitingForKey = nil,
    themeName = "Dark",
    currentTab = "Combat",
    guiVisible = true,
    maxDistance = 350,
    fieldOfView = 80,
    triggerCooldown = 0,
    espColor = Color3.fromRGB(255, 130, 150),
    aimbotTargetMode = "Head",
    aimbotSmoothness = 1,
}

local highlightFolder = Instance.new("Folder")
highlightFolder.Name = "RivalsESP"
highlightFolder.Parent = (gethui and gethui())
    or (game:FindFirstChild("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"))

local highlights = {}
local tabButtons = {}
local tabContainers = {}
local toggleRefs = {}
local keybindRefs = {}
local targetButtons = {}
local themables = {
    Background = {},
    Header = {},
    Section = {},
    Button = {},
    ButtonMuted = {},
    Input = {},
    TextPrimary = {},
    TextMuted = {},
    ButtonAccent = {},
}
local showHideHintLabel
local mainFrame
local statusText
local colorPicker = {
    Frame = nil,
    Wheel = nil,
    Cursor = nil,
    RInput = nil,
    GInput = nil,
    BInput = nil,
    HexInput = nil,
    Button = nil,
    updating = false,
}
local colorToHex

--=====================================================
-- SECTION: Theme Helpers
--=====================================================
local function currentTheme()
    return themes[state.themeName] or themes.Dark
end

local function registerThemeTarget(category, instance)
    if not instance then
        return
    end
    themables[category] = themables[category] or {}
    table.insert(themables[category], instance)
end

local function applyThemeColors()
    local theme = currentTheme()
    local function applyList(category, property, color)
        local list = themables[category] or {}
        for i = #list, 1, -1 do
            local inst = list[i]
            if inst and inst.Parent then
                inst[property] = color
            else
                table.remove(list, i)
            end
        end
    end

    applyList("Background", "BackgroundColor3", theme.Background)
    applyList("Header", "BackgroundColor3", theme.Header)
    applyList("Section", "BackgroundColor3", theme.Section)
    applyList("Button", "BackgroundColor3", theme.Button)
    applyList("ButtonMuted", "BackgroundColor3", theme.ButtonMuted)
    applyList("ButtonAccent", "BackgroundColor3", theme.ButtonAccent)
    applyList("Input", "BackgroundColor3", theme.Input)
    applyList("TextPrimary", "TextColor3", theme.TextPrimary)
    applyList("TextMuted", "TextColor3", theme.TextMuted)
end
local function refreshTabButtons()
    local theme = currentTheme()
    for name, button in pairs(tabButtons) do
        if button.Parent then
            button.BackgroundColor3 = (name == state.currentTab) and theme.TabActive or theme.TabInactive
        end
    end
end

local function refreshToggleButtons()
    local theme = currentTheme()
    for id, refs in pairs(toggleRefs) do
        if refs.ToggleButton and refs.ToggleButton.Parent then
            refs.ToggleButton.BackgroundColor3 = state.toggles[id] and theme.ToggleOn or theme.ToggleOff
            refs.ToggleButton.Text = state.toggles[id] and "ON" or "OFF"
        end
    end
end

local function updateTargetButtons()
    local theme = currentTheme()
    for name, button in pairs(targetButtons) do
        if button.Parent then
            button.BackgroundColor3 = (name == state.aimbotTargetMode) and theme.ButtonAccent or theme.Button
        end
    end
end

local function updateColorButtonAppearance()
    if colorPicker.Button and colorPicker.Button.Parent then
        local color = state.espColor
        colorPicker.Button.BackgroundColor3 = color
        local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
        colorPicker.Button.TextColor3 = luminance > 0.6 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
        colorPicker.Button.Text = "Color " .. colorToHex(color)
    end
end

local function applyTheme(themeName)
    if not themes[themeName] then
        return
    end
    state.themeName = themeName
    applyThemeColors()
    refreshTabButtons()
    refreshToggleButtons()
    updateTargetButtons()
    updateColorButtonAppearance()
    if keybindRefs.ShowHide then
        keybindRefs.ShowHide.TextColor3 = currentTheme().TextPrimary
    end
end

--=====================================================
-- SECTION: ESP Helpers
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

local function setEspColor(color)
    state.espColor = color
    updateHighlightAppearance()
    updateColorButtonAppearance()
end

--=====================================================
-- SECTION: Aimbot Math Helpers
--=====================================================
local aimOffsets = {
    Head = Vector3.new(0, 0.6, 0),
    Body = Vector3.new(0, 0.25, 0),
    Legs = Vector3.new(0, 1.4, 0),
}

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
--=====================================================
-- SECTION: GUI Helpers
--=====================================================
local function updateShowHideHint()
    if showHideHintLabel then
        showHideHintLabel.Text = "Press " .. state.showHideKey.Name .. " to toggle"
        showHideHintLabel.TextColor3 = currentTheme().TextMuted
    end
end

local function setGuiVisible(visible)
    state.guiVisible = visible
    if mainFrame then
        mainFrame.Visible = visible
    end
end

local function switchTab(tabName)
    state.currentTab = tabName
    for name, container in pairs(tabContainers) do
        container.Visible = (name == tabName)
    end
    refreshTabButtons()
end

local function setToggle(id, enabled)
    if state.toggles[id] == enabled then
        return
    end
    state.toggles[id] = enabled
    refreshToggleButtons()
    if id == "ESP" then
        updateHighlightAppearance()
    elseif id == "Aimbot" then
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.AutoRotate = not enabled
        end
    end
end

local function setTargetMode(mode)
    state.aimbotTargetMode = mode
    updateTargetButtons()
end

local function registerToggleRow(id, toggleButton, keyButton)
    toggleRefs[id] = {
        ToggleButton = toggleButton,
        KeyButton = keyButton,
    }
end

local function registerKeybindRow(id, keyButton)
    keybindRefs[id] = keyButton
end

local function createToggleRow(parent, id, labelText, description)
    local theme = currentTheme()
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 86)
    row.BackgroundColor3 = theme.Section
    row.Parent = parent
    registerThemeTarget("Section", row)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = row

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.TextColor3 = theme.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText
    label.Size = UDim2.new(1, -12, 0, 22)
    label.Position = UDim2.fromOffset(12, 8)
    label.Parent = row
    registerThemeTarget("TextPrimary", label)

    local desc = Instance.new("TextLabel")
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 14
    desc.TextColor3 = theme.TextMuted
    desc.TextWrapped = true
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.Text = description
    desc.Size = UDim2.new(1, -170, 0, 38)
    desc.Position = UDim2.fromOffset(12, 34)
    desc.Parent = row
    registerThemeTarget("TextMuted", desc)

    local buttonColumn = Instance.new("Frame")
    buttonColumn.BackgroundTransparency = 1
    buttonColumn.Size = UDim2.new(0, 150, 0, 60)
    buttonColumn.Position = UDim2.new(1, -160, 0, 14)
    buttonColumn.Parent = row

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = buttonColumn

    local keyButton = Instance.new("TextButton")
    keyButton.Size = UDim2.new(1, 0, 0, 26)
    keyButton.BackgroundColor3 = theme.Input
    keyButton.Font = Enum.Font.Gotham
    keyButton.TextSize = 14
    keyButton.TextColor3 = theme.TextPrimary
    keyButton.Text = state.keybinds[id].Name
    keyButton.Parent = buttonColumn
    registerThemeTarget("Input", keyButton)
    registerThemeTarget("TextPrimary", keyButton)

    keyButton.MouseButton1Click:Connect(function()
        state.waitingForKey = id
        keyButton.Text = "..."
    end)

    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(1, 0, 0, 28)
    toggleButton.BackgroundColor3 = state.toggles[id] and theme.ToggleOn or theme.ToggleOff
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = 16
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.Text = state.toggles[id] and "ON" or "OFF"
    toggleButton.Parent = buttonColumn

    toggleButton.MouseButton1Click:Connect(function()
        setToggle(id, not state.toggles[id])
    end)

    registerToggleRow(id, toggleButton, keyButton)
end

local function createKeybindRow(parent, id, labelText, description)
    local theme = currentTheme()
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 76)
    row.BackgroundColor3 = theme.Section
    row.Parent = parent
    registerThemeTarget("Section", row)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = row

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.Text = labelText
    label.TextColor3 = theme.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.fromOffset(12, 8)
    label.Size = UDim2.new(1, -12, 0, 24)
    label.Parent = row
    registerThemeTarget("TextPrimary", label)

    local desc = Instance.new("TextLabel")
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 14
    desc.TextColor3 = theme.TextMuted
    desc.Text = description
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Position = UDim2.fromOffset(12, 36)
    desc.Size = UDim2.new(1, -120, 0, 24)
    desc.Parent = row
    registerThemeTarget("TextMuted", desc)

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 100, 0, 30)
    button.Position = UDim2.new(1, -110, 0.5, -15)
    button.BackgroundColor3 = theme.Input
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.TextColor3 = theme.TextPrimary
    button.Text = id and state.keybinds[id].Name or state.showHideKey.Name
    button.Parent = row
    registerThemeTarget("Input", button)
    registerThemeTarget("TextPrimary", button)

    button.MouseButton1Click:Connect(function()
        state.waitingForKey = id or "ShowHide"
        button.Text = "..."
    end)

    if id then
        registerKeybindRow(id, button)
    else
        keybindRefs.ShowHide = button
    end
end

local function createSmoothnessSlider(parent)
    local theme = currentTheme()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 100)
    frame.BackgroundColor3 = theme.Section
    frame.Parent = parent
    registerThemeTarget("Section", frame)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.Text = "Aimbot Smoothness"
    label.TextColor3 = theme.TextPrimary
    label.Position = UDim2.fromOffset(12, 8)
    label.Size = UDim2.new(1, -12, 0, 22)
    label.Parent = frame
    registerThemeTarget("TextPrimary", label)

    local desc = Instance.new("TextLabel")
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 14
    desc.TextWrapped = true
    desc.TextColor3 = theme.TextMuted
    desc.Text = "0 = instant, 5 = slow"
    desc.Position = UDim2.fromOffset(12, 34)
    desc.Size = UDim2.new(1, -12, 0, 24)
    desc.Parent = frame
    registerThemeTarget("TextMuted", desc)

    local sliderTrack = Instance.new("Frame")
    sliderTrack.Size = UDim2.new(1, -40, 0, 10)
    sliderTrack.Position = UDim2.new(0, 20, 0, 72)
    sliderTrack.BackgroundColor3 = theme.Input
    sliderTrack.Parent = frame
    registerThemeTarget("Input", sliderTrack)

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 6)
    trackCorner.Parent = sliderTrack

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.BackgroundColor3 = theme.ButtonAccent
    knob.Parent = sliderTrack
    registerThemeTarget("ButtonAccent", knob)

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.Code
    valueLabel.TextSize = 14
    valueLabel.TextColor3 = theme.TextPrimary
    valueLabel.Position = UDim2.new(1, -24, 0, 64)
    valueLabel.Size = UDim2.new(0, 24, 0, 20)
    valueLabel.Parent = frame
    registerThemeTarget("TextPrimary", valueLabel)

    local function updateKnob()
        local pct = state.aimbotSmoothness / 5
        knob.Position = UDim2.new(pct, -7, 0.5, -7)
        valueLabel.Text = string.format("%.1f", state.aimbotSmoothness)
    end

    local dragging

    local function setFromPosition(x)
        local minX = sliderTrack.AbsolutePosition.X
        local maxX = minX + sliderTrack.AbsoluteSize.X
        local pct = math.clamp((x - minX) / (maxX - minX), 0, 1)
        state.aimbotSmoothness = math.floor(pct * 500 + 0.5) / 100
        updateKnob()
    end

    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setFromPosition(input.Position.X)
        end
    end)

    sliderTrack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setFromPosition(input.Position.X)
        end
    end)

    updateKnob()
end

local function createThemeButtons(parent)
    local theme = currentTheme()
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 110)
    frame.BackgroundColor3 = theme.Section
    frame.Parent = parent
    registerThemeTarget("Section", frame)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.TextColor3 = theme.TextPrimary
    label.Text = "Themes"
    label.Position = UDim2.fromOffset(12, 8)
    label.Size = UDim2.new(1, -12, 0, 24)
    label.Parent = frame
    registerThemeTarget("TextPrimary", label)

    local buttonRow = Instance.new("Frame")
    buttonRow.BackgroundTransparency = 1
    buttonRow.Size = UDim2.new(1, -24, 0, 50)
    buttonRow.Position = UDim2.fromOffset(12, 50)
    buttonRow.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 10)
    layout.Parent = buttonRow

    for name in pairs(themes) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 100, 1, 0)
        button.Text = name
        button.Font = Enum.Font.Gotham
        button.TextSize = 16
        button.TextColor3 = Color3.new(1, 1, 1)
        button.BackgroundColor3 = theme.Button
        button.Parent = buttonRow
        registerThemeTarget("Button", button)

        button.MouseButton1Click:Connect(function()
            applyTheme(name)
        end)
    end
end
--=====================================================
-- SECTION: Color Picker
--=====================================================
colorToHex = function(color)
    return string.format("#%02X%02X%02X",
        math.floor(color.R * 255 + 0.5),
        math.floor(color.G * 255 + 0.5),
        math.floor(color.B * 255 + 0.5)
    )
end

local function updateColorInputs()
    if not colorPicker.RInput then
        return
    end
    colorPicker.updating = true
    local r = math.floor(state.espColor.R * 255 + 0.5)
    local g = math.floor(state.espColor.G * 255 + 0.5)
    local b = math.floor(state.espColor.B * 255 + 0.5)
    colorPicker.RInput.Text = tostring(r)
    colorPicker.GInput.Text = tostring(g)
    colorPicker.BInput.Text = tostring(b)
    colorPicker.HexInput.Text = colorToHex(state.espColor)
    colorPicker.updating = false
end

local function updateWheelCursor()
    if not (colorPicker.Wheel and colorPicker.Cursor) then
        return
    end
    local size = colorPicker.Wheel.AbsoluteSize
    if size.X == 0 then
        task.defer(updateWheelCursor)
        return
    end
    local center = colorPicker.Wheel.AbsolutePosition + size / 2
    local h, s = state.espColor:ToHSV()
    local angle = h * math.pi * 2
    local radius = s * (size.X / 2)
    local pos = center + Vector2.new(math.cos(angle) * radius, math.sin(angle) * radius)
    colorPicker.Cursor.Position = UDim2.fromOffset(pos.X - colorPicker.Cursor.AbsoluteSize.X / 2, pos.Y - colorPicker.Cursor.AbsoluteSize.Y / 2)
end

local function updateColorFromWheel(position)
    if not colorPicker.Wheel then
        return
    end
    local size = colorPicker.Wheel.AbsoluteSize
    if size.X == 0 then
        return
    end
    local point = typeof(position) == "Vector3" and Vector2.new(position.X, position.Y) or position
    local center = colorPicker.Wheel.AbsolutePosition + size / 2
    local offset = point - center
    local radius = math.clamp(offset.Magnitude / (size.X / 2), 0, 1)
    local hue = math.atan2(offset.Y, offset.X) / (2 * math.pi)
    if hue < 0 then
        hue = hue + 1
    end
    setEspColor(Color3.fromHSV(hue, radius, 1))
    updateColorInputs()
    updateWheelCursor()
end

local function createColorPicker(parent)
    local theme = currentTheme()
    local colorFrame = Instance.new("Frame")
    colorFrame.Size = UDim2.new(1, -8, 0, 90)
    colorFrame.BackgroundColor3 = theme.Section
    colorFrame.Parent = parent
    registerThemeTarget("Section", colorFrame)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = colorFrame

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = theme.TextPrimary
    title.Text = "ESP Color"
    title.Position = UDim2.fromOffset(12, 8)
    title.Size = UDim2.new(1, -12, 0, 22)
    title.Parent = colorFrame
    registerThemeTarget("TextPrimary", title)

    local pickButton = Instance.new("TextButton")
    pickButton.Size = UDim2.new(0, 150, 0, 34)
    pickButton.Position = UDim2.new(0, 12, 0, 46)
    pickButton.BackgroundColor3 = theme.ButtonAccent
    pickButton.Font = Enum.Font.Gotham
    pickButton.TextSize = 16
    pickButton.TextColor3 = Color3.new(1, 1, 1)
    pickButton.Text = "Color " .. colorToHex(state.espColor)
    pickButton.Parent = colorFrame
    registerThemeTarget("ButtonAccent", pickButton)
    colorPicker.Button = pickButton

    local popParent = mainFrame or parent:FindFirstAncestorWhichIsA("Frame") or parent
    local popout = Instance.new("Frame")
    popout.Name = "ColorPickerPopout"
    popout.Size = UDim2.new(0, 260, 0, 300)
    popout.Position = UDim2.fromOffset(0, 0)
    popout.Visible = false
    popout.Active = true
    popout.ZIndex = 50
    popout.ClipsDescendants = false
    popout.BackgroundColor3 = theme.Section
    popout.Parent = popParent
    registerThemeTarget("Section", popout)

    local popCorner = Instance.new("UICorner")
    popCorner.CornerRadius = UDim.new(0, 12)
    popCorner.Parent = popout

    local popHeader = Instance.new("Frame")
    popHeader.Size = UDim2.new(1, 0, 0, 36)
    popHeader.BackgroundColor3 = theme.Header
    popHeader.ZIndex = 51
    popHeader.Parent = popout
    registerThemeTarget("Header", popHeader)

    local popHeaderCorner = Instance.new("UICorner")
    popHeaderCorner.CornerRadius = UDim.new(0, 12)
    popHeaderCorner.Parent = popHeader

    local popTitle = Instance.new("TextLabel")
    popTitle.BackgroundTransparency = 1
    popTitle.Font = Enum.Font.GothamBold
    popTitle.TextSize = 16
    popTitle.TextColor3 = theme.TextPrimary
    popTitle.TextXAlignment = Enum.TextXAlignment.Left
    popTitle.Text = "ESP Color Picker"
    popTitle.Size = UDim2.new(1, -40, 1, 0)
    popTitle.Position = UDim2.fromOffset(12, 0)
    popTitle.ZIndex = 52
    popTitle.Parent = popHeader
    registerThemeTarget("TextPrimary", popTitle)

    local popClose = Instance.new("TextButton")
    popClose.Size = UDim2.new(0, 30, 0, 24)
    popClose.Position = UDim2.new(1, -36, 0.5, -12)
    popClose.BackgroundColor3 = theme.ButtonMuted
    popClose.Font = Enum.Font.GothamBold
    popClose.TextSize = 18
    popClose.TextColor3 = Color3.new(1, 1, 1)
    popClose.Text = "×"
    popClose.ZIndex = 52
    popClose.Parent = popHeader
    registerThemeTarget("ButtonMuted", popClose)

    local popCloseCorner = Instance.new("UICorner")
    popCloseCorner.CornerRadius = UDim.new(0, 8)
    popCloseCorner.Parent = popClose

    local dragging = false
    local dragStart
    local startPos

    popHeader.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = popout.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            popout.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    local wheel = Instance.new("ImageButton")
    wheel.Size = UDim2.new(0, 190, 0, 190)
    wheel.Position = UDim2.new(0.5, -95, 0, 48)
    wheel.BackgroundTransparency = 1
    wheel.Image = "rbxassetid://6020299385"
    wheel.ZIndex = 52
    wheel.AutoButtonColor = false
    wheel.Parent = popout

    local cursor = Instance.new("Frame")
    cursor.Size = UDim2.new(0, 12, 0, 12)
    cursor.ZIndex = 53
    cursor.BackgroundColor3 = Color3.new(1, 1, 1)
    cursor.BorderSizePixel = 0
    cursor.Parent = popout

    local cursorCorner = Instance.new("UICorner")
    cursorCorner.CornerRadius = UDim.new(1, 0)
    cursorCorner.Parent = cursor

    colorPicker.Frame = popout
    colorPicker.Wheel = wheel
    colorPicker.Cursor = cursor

    local inputsFrame = Instance.new("Frame")
    inputsFrame.Size = UDim2.new(1, -24, 0, 44)
    inputsFrame.Position = UDim2.fromOffset(12, 250)
    inputsFrame.BackgroundTransparency = 1
    inputsFrame.ZIndex = 52
    inputsFrame.Parent = popout

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 6)
    layout.Parent = inputsFrame

    local function createRGBBox(name)
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0, 50, 1, 0)
        box.BackgroundColor3 = theme.Input
        box.Font = Enum.Font.Code
        box.TextSize = 14
        box.TextColor3 = theme.TextPrimary
        box.PlaceholderText = name
        box.Text = "0"
        box.ClearTextOnFocus = false
        box.ZIndex = 53
        box.Parent = inputsFrame
        registerThemeTarget("Input", box)
        registerThemeTarget("TextPrimary", box)
        return box
    end

    colorPicker.RInput = createRGBBox("R")
    colorPicker.GInput = createRGBBox("G")
    colorPicker.BInput = createRGBBox("B")

    local hexBox = Instance.new("TextBox")
    hexBox.Size = UDim2.new(0, 90, 1, 0)
    hexBox.BackgroundColor3 = theme.Input
    hexBox.Font = Enum.Font.Code
    hexBox.TextSize = 14
    hexBox.TextColor3 = theme.TextPrimary
    hexBox.ClearTextOnFocus = false
    hexBox.Text = colorToHex(state.espColor)
    hexBox.ZIndex = 53
    hexBox.Parent = inputsFrame
    registerThemeTarget("Input", hexBox)
    registerThemeTarget("TextPrimary", hexBox)
    colorPicker.HexInput = hexBox

    local function attachInput(box, component)
        box.FocusLost:Connect(function()
            if colorPicker.updating then
                return
            end
            local value = tonumber(box.Text)
            if not value then
                updateColorInputs()
                return
            end
            value = math.clamp(math.floor(value + 0.5), 0, 255)
            local r = math.floor(state.espColor.R * 255 + 0.5)
            local g = math.floor(state.espColor.G * 255 + 0.5)
            local b = math.floor(state.espColor.B * 255 + 0.5)
            if component == "R" then
                r = value
            elseif component == "G" then
                g = value
            else
                b = value
            end
            setEspColor(Color3.fromRGB(r, g, b))
            updateColorInputs()
            updateWheelCursor()
        end)
    end

    attachInput(colorPicker.RInput, "R")
    attachInput(colorPicker.GInput, "G")
    attachInput(colorPicker.BInput, "B")

    hexBox.FocusLost:Connect(function()
        if colorPicker.updating then
            return
        end
        local text = hexBox.Text:gsub("#", "")
        if #text == 6 then
            local success, result = pcall(function()
                return Color3.fromRGB(tonumber(text:sub(1, 2), 16), tonumber(text:sub(3, 4), 16), tonumber(text:sub(5, 6), 16))
            end)
            if success and result then
                setEspColor(result)
                updateColorInputs()
                updateWheelCursor()
            end
        else
            updateColorInputs()
        end
    end)

    wheel.MouseButton1Down:Connect(function(input)
        updateColorFromWheel(Vector2.new(input.Position.X, input.Position.Y))
        local moveConn
        moveConn = UserInputService.InputChanged:Connect(function(moveInput)
            if moveInput.UserInputType == Enum.UserInputType.MouseMovement then
                updateColorFromWheel(Vector2.new(moveInput.Position.X, moveInput.Position.Y))
            end
        end)
        local releaseConn
        releaseConn = UserInputService.InputEnded:Connect(function(endInput)
            if endInput.UserInputType == Enum.UserInputType.MouseButton1 then
                moveConn:Disconnect()
                releaseConn:Disconnect()
            end
        end)
    end)

    popout:GetPropertyChangedSignal("Visible"):Connect(function()
        if popout.Visible then
            updateColorInputs()
            task.defer(updateWheelCursor)
        end
    end)

    popClose.MouseButton1Click:Connect(function()
        popout.Visible = false
    end)

    pickButton.MouseButton1Click:Connect(function()
        if popout.Visible then
            popout.Visible = false
        else
            local parentAbsPos = popParent.AbsolutePosition
            local parentSize = popParent.AbsoluteSize
            local buttonAbs = pickButton.AbsolutePosition
            local desiredX = buttonAbs.X - parentAbsPos.X + pickButton.AbsoluteSize.X + 12
            local desiredY = buttonAbs.Y - parentAbsPos.Y - 20
            local maxX = parentSize.X - popout.AbsoluteSize.X - 12
            local maxY = parentSize.Y - popout.AbsoluteSize.Y - 12
            popout.Position = UDim2.new(0, math.clamp(desiredX, 12, math.max(12, maxX)), 0, math.clamp(desiredY, 12, math.max(12, maxY)))
            popout.Visible = true
            updateColorInputs()
            task.defer(updateWheelCursor)
        end
    end)
end
--=====================================================
-- SECTION: GUI Construction
--=====================================================
local function createTabContainer(parent, name)
    local scroller = Instance.new("ScrollingFrame")
    scroller.Size = UDim2.new(1, 0, 1, 0)
    scroller.CanvasSize = UDim2.new()
    scroller.ScrollBarThickness = 5
    scroller.BackgroundTransparency = 1
    scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroller.Visible = false
    scroller.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = scroller

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 4)
    padding.Parent = scroller

    tabContainers[name] = scroller
    return scroller
end

local function buildGui()
    local theme = currentTheme()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RivalsGUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = (gethui and gethui())
        or (game:FindFirstChild("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"))

    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 440, 0, 460)
    mainFrame.Position = UDim2.fromScale(0.5, 0.5) - UDim2.fromOffset(220, 230)
    mainFrame.BackgroundColor3 = theme.Background
    mainFrame.ClipsDescendants = false
    mainFrame.Parent = screenGui
    registerThemeTarget("Background", mainFrame)

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 14)
    frameCorner.Parent = mainFrame

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 54)
    header.BackgroundColor3 = theme.Header
    header.Parent = mainFrame
    registerThemeTarget("Header", header)

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 14)
    headerCorner.Parent = header

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextColor3 = theme.TextPrimary
    title.Text = "RIVALS HUB"
    title.Size = UDim2.new(0.5, 0, 1, 0)
    title.Position = UDim2.fromOffset(16, 0)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    registerThemeTarget("TextPrimary", title)

    showHideHintLabel = Instance.new("TextLabel")
    showHideHintLabel.BackgroundTransparency = 1
    showHideHintLabel.Font = Enum.Font.Gotham
    showHideHintLabel.TextSize = 14
    showHideHintLabel.TextColor3 = theme.TextMuted
    showHideHintLabel.TextXAlignment = Enum.TextXAlignment.Right
    showHideHintLabel.Size = UDim2.new(0, 160, 1, 0)
    showHideHintLabel.Position = UDim2.new(1, -200, 0, 0)
    showHideHintLabel.Parent = header
    registerThemeTarget("TextMuted", showHideHintLabel)
    updateShowHideHint()

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 36, 0, 36)
    closeButton.Position = UDim2.new(1, -44, 0.5, -18)
    closeButton.Text = "×"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 20
    closeButton.BackgroundColor3 = theme.ButtonMuted
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.Parent = header
    registerThemeTarget("ButtonMuted", closeButton)

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    local dragging
    local dragStart
    local startPos

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -24, 0, 36)
    tabBar.Position = UDim2.fromOffset(12, 64)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = mainFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 10)
    tabLayout.Parent = tabBar

    for _, name in ipairs({"Combat", "ESP", "Settings"}) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 110, 1, 0)
        button.Font = Enum.Font.Gotham
        button.TextSize = 16
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Text = name
        button.BackgroundColor3 = theme.TabInactive
        button.Parent = tabBar

        button.MouseButton1Click:Connect(function()
            switchTab(name)
        end)

        tabButtons[name] = button
    end

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -24, 1, -116)
    content.Position = UDim2.fromOffset(12, 106)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame

    local combatTab = createTabContainer(content, "Combat")
    local espTab = createTabContainer(content, "ESP")
    local settingsTab = createTabContainer(content, "Settings")

    createToggleRow(combatTab, "Aimbot", "Aimbot", "Lock onto the closest enemy within your FOV.")
    createToggleRow(combatTab, "Trigger", "Trigger Bot", "Auto fires when your crosshair is on an enemy.")

    local targetFrame = Instance.new("Frame")
    targetFrame.Size = UDim2.new(1, -8, 0, 110)
    targetFrame.BackgroundColor3 = theme.Section
    targetFrame.Parent = combatTab
    registerThemeTarget("Section", targetFrame)

    local targetCorner = Instance.new("UICorner")
    targetCorner.CornerRadius = UDim.new(0, 10)
    targetCorner.Parent = targetFrame

    local targetLabel = Instance.new("TextLabel")
    targetLabel.BackgroundTransparency = 1
    targetLabel.Font = Enum.Font.GothamBold
    targetLabel.TextSize = 18
    targetLabel.TextColor3 = theme.TextPrimary
    targetLabel.Text = "Aimbot Target"
    targetLabel.Position = UDim2.fromOffset(12, 8)
    targetLabel.Size = UDim2.new(1, -12, 0, 22)
    targetLabel.Parent = targetFrame
    registerThemeTarget("TextPrimary", targetLabel)

    local targetDesc = Instance.new("TextLabel")
    targetDesc.BackgroundTransparency = 1
    targetDesc.Font = Enum.Font.Gotham
    targetDesc.TextSize = 14
    targetDesc.TextColor3 = theme.TextMuted
    targetDesc.Text = "Head, Body, or Legs (legs aim slightly higher)."
    targetDesc.Position = UDim2.fromOffset(12, 34)
    targetDesc.Size = UDim2.new(1, -12, 0, 24)
    targetDesc.Parent = targetFrame
    registerThemeTarget("TextMuted", targetDesc)

    local buttonRow = Instance.new("Frame")
    buttonRow.BackgroundTransparency = 1
    buttonRow.Position = UDim2.fromOffset(12, 68)
    buttonRow.Size = UDim2.new(1, -24, 0, 32)
    buttonRow.Parent = targetFrame

    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.Padding = UDim.new(0, 10)
    buttonLayout.Parent = buttonRow

    for _, mode in ipairs({"Head", "Body", "Legs"}) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 100, 1, 0)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 16
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Text = mode
        btn.BackgroundColor3 = (mode == state.aimbotTargetMode) and theme.ButtonAccent or theme.Button
        btn.Parent = buttonRow
        registerThemeTarget("Button", btn)

        btn.MouseButton1Click:Connect(function()
            setTargetMode(mode)
        end)

        targetButtons[mode] = btn
    end

    createSmoothnessSlider(combatTab)

    createToggleRow(espTab, "ESP", "ESP Outlines", "Outline enemies through walls.")
    createColorPicker(espTab)

    createKeybindRow(settingsTab, "Aimbot", "Aimbot Key", "Toggles the aimbot.")
    createKeybindRow(settingsTab, "ESP", "ESP Key", "Toggles ESP outlines.")
    createKeybindRow(settingsTab, "Trigger", "Trigger Key", "Toggles trigger bot.")
    createKeybindRow(settingsTab, nil, "Show/Hide UI", "Key to show or hide the window.")
    createThemeButtons(settingsTab)

    applyThemeColors()
    refreshTabButtons()
    refreshToggleButtons()
    updateTargetButtons()
    updateColorButtonAppearance()
    switchTab(state.currentTab)
end
--=====================================================
-- SECTION: Status HUD
--=====================================================
local function buildStatusGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RivalsStatusHUD"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = (gethui and gethui())
        or (game:FindFirstChild("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"))

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 80)
    frame.Position = UDim2.new(0, 12, 0, 12)
    frame.BackgroundColor3 = Color3.fromRGB(18, 19, 24)
    frame.BackgroundTransparency = 0.25
    frame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    statusText = Instance.new("TextLabel")
    statusText.BackgroundTransparency = 1
    statusText.Font = Enum.Font.Code
    statusText.TextSize = 14
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.TextYAlignment = Enum.TextYAlignment.Top
    statusText.TextColor3 = Color3.fromRGB(255, 90, 90)
    statusText.Text = "AIMBOT: OFF\nDISTANCE: --\nTARGET: --"
    statusText.Position = UDim2.fromOffset(10, 10)
    statusText.Size = UDim2.new(1, -20, 1, -20)
    statusText.Parent = frame
end

--=====================================================
-- SECTION: Initialization
--=====================================================
buildGui()
buildStatusGui()

for _, player in ipairs(Players:GetPlayers()) do
    ensureHighlight(player)
end

Players.PlayerAdded:Connect(ensureHighlight)
Players.PlayerRemoving:Connect(cleanupHighlight)

--=====================================================
-- SECTION: Input Handling
--=====================================================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        if state.waitingForKey then
            local key = input.KeyCode
            if key ~= Enum.KeyCode.Unknown then
                if state.waitingForKey == "ShowHide" then
                    state.showHideKey = key
                    if keybindRefs.ShowHide then
                        keybindRefs.ShowHide.Text = key.Name
                    end
                    updateShowHideHint()
                else
                    state.keybinds[state.waitingForKey] = key
                    local row = keybindRefs[state.waitingForKey]
                    if row and row.Parent then
                        row.Text = key.Name
                    end
                end
            end
            state.waitingForKey = nil
            return
        end

        if input.KeyCode == state.showHideKey then
            setGuiVisible(not state.guiVisible)
            return
        end

        for id, key in pairs(state.keybinds) do
            if input.KeyCode == key then
                setToggle(id, not state.toggles[id])
                break
            end
        end
    end
end)

--=====================================================
-- SECTION: Render Loop
--=====================================================
RunService.RenderStepped:Connect(function(dt)
    if state.toggles.Aimbot then
        local targetPlayer, targetPosition = getClosestPlayerInFOV()
        if targetPlayer and targetPosition then
            local distance = (targetPosition - (LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart.Position or targetPosition)).Magnitude
            statusText.Text = string.format("AIMBOT: LOCKED\nDISTANCE: %d studs\nTARGET: %s", math.floor(distance), targetPlayer.Name)
            statusText.TextColor3 = Color3.fromRGB(90, 255, 90)

            local character = LocalPlayer.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root then
                local horizontalLook = Vector3.new(targetPosition.X, root.Position.Y, targetPosition.Z)
                root.CFrame = CFrame.new(root.Position, horizontalLook)
            end

            local desired = CFrame.new(Camera.CFrame.Position, targetPosition)
            local smooth = math.clamp(1 - (state.aimbotSmoothness / 5), 0.05, 1)
            Camera.CFrame = Camera.CFrame:Lerp(desired, smooth)
        else
            statusText.Text = "AIMBOT: SEARCHING\nDISTANCE: --\nTARGET: --"
            statusText.TextColor3 = Color3.fromRGB(255, 255, 120)
        end
    else
        statusText.Text = "AIMBOT: OFF\nDISTANCE: --\nTARGET: --"
        statusText.TextColor3 = Color3.fromRGB(255, 90, 90)
    end

    state.triggerCooldown = math.max(0, state.triggerCooldown - dt)
    if state.toggles.Trigger and state.triggerCooldown <= 0 then
        local result = workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector * 500)
        if result then
            local model = result.Instance:FindFirstAncestorOfClass("Model")
            local player = model and Players:GetPlayerFromCharacter(model)
            local humanoid = model and model:FindFirstChildOfClass("Humanoid")
            if player and player ~= LocalPlayer and humanoid and humanoid.Health > 0 then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new())
                state.triggerCooldown = 0.15
            end
        end
    end
end)

print("[Rivals Hub] Loaded. Use Combat/ESP/Settings tabs to customize. Press " .. state.showHideKey.Name .. " to hide or show the UI.")
