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
    currentTab = "Combat",
    maxDistance = 350,
    fieldOfView = 80,
    triggerCooldown = 0,
    espColor = Color3.fromRGB(255, 130, 150),
    aimbotTargetMode = "Head",
}

local highlightFolder = Instance.new("Folder")
highlightFolder.Name = "RivalsESPOutlines"
highlightFolder.Parent = (gethui and gethui())
    or (game:FindFirstChild("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"))

local highlights = {}
local statusGui, statusText
local uiRoot, mainFrame, showHideHintLabel
local tabButtons = {}
local tabContainers = {}
local targetButtons = {}
local keybindRows = {}
local triggerRayParams = RaycastParams.new()
triggerRayParams.FilterType = Enum.RaycastFilterType.Blacklist

--=====================================================
-- SECTION: Utility Functions
--=====================================================
local function updateRaycastFilter()
    local filter = {}
    if LocalPlayer.Character then
        table.insert(filter, LocalPlayer.Character)
    end
    triggerRayParams.FilterDescendantsInstances = filter
end

local function updateStatus(text, color)
    statusText.Text = text
    statusText.TextColor3 = color
end

local function ensureHighlight(player)
    if player == LocalPlayer then
        return
    end

    local container = highlights[player]
    if not container then
        local highlight = Instance.new("Highlight")
        highlight.Name = "RivalsESPHighlight"
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 1
        highlight.OutlineColor = state.espColor
        highlight.Parent = highlightFolder

        container = {
            highlight = highlight,
            connections = {},
        }
        highlights[player] = container
    end

    local function onCharacter(character)
        container.highlight.Adornee = character
    end

    if player.Character then
        onCharacter(player.Character)
    end

    table.insert(container.connections, player.CharacterAdded:Connect(onCharacter))
    table.insert(container.connections, player.CharacterRemoving:Connect(function()
        container.highlight.Adornee = nil
    end))
end

local function cleanupHighlight(player)
    local container = highlights[player]
    if not container then
        return
    end

    for _, connection in ipairs(container.connections) do
        connection:Disconnect()
    end
    container.connections = {}

    container.highlight:Destroy()
    highlights[player] = nil
end

local function updateHighlightAppearance()
    for _, container in pairs(highlights) do
        container.highlight.OutlineColor = state.espColor
        container.highlight.OutlineTransparency = state.toggles.ESP and 0 or 1
        container.highlight.Enabled = state.toggles.ESP
    end
end

local function resolveTargetPart(character)
    if state.aimbotTargetMode == "Head" then
        return character:FindFirstChild("Head")
    elseif state.aimbotTargetMode == "Body" then
        return character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("HumanoidRootPart")
    else
        return character:FindFirstChild("LeftLowerLeg")
            or character:FindFirstChild("RightLowerLeg")
            or character:FindFirstChild("LeftLeg")
            or character:FindFirstChild("RightLeg")
            or character:FindFirstChild("LeftFoot")
            or character:FindFirstChild("RightFoot")
    end
end

local function getClosestPlayerInFOV()
    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    if not myRoot then
        return nil
    end

    local closest
    local smallestAngle = state.fieldOfView
    local cameraPosition = Camera.CFrame.Position
    local cameraLook = Camera.CFrame.LookVector

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local targetPart = character and resolveTargetPart(character)
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if targetPart and root and humanoid and humanoid.Health > 0 then
                local distance = (root.Position - myRoot.Position).Magnitude
                if distance <= state.maxDistance then
                    local direction = (targetPart.Position - cameraPosition).Unit
                    local dot = math.clamp(cameraLook:Dot(direction), -1, 1)
                    local angle = math.deg(math.acos(dot))
                    if angle < smallestAngle then
                        smallestAngle = angle
                        closest = player
                    end
                end
            end
        end
    end

    return closest
end

local function setGuiVisible(visible)
    state.guiVisible = visible
    if mainFrame then
        mainFrame.Visible = visible
    end
end

local function switchTab(tabName)
    state.currentTab = tabName
    for name, button in pairs(tabButtons) do
        local active = (name == tabName)
        button.BackgroundColor3 = active and Color3.fromRGB(90, 120, 255) or Color3.fromRGB(45, 47, 60)
        if tabContainers[name] then
            tabContainers[name].Visible = active
        end
    end
end

local function setToggle(id, enabled)
    state.toggles[id] = enabled
    if id == "ESP" then
        updateHighlightAppearance()
    end

    local row = keybindRows[id]
    if row and row.ToggleButton then
        row.ToggleButton.Text = enabled and "ON" or "OFF"
        row.ToggleButton.BackgroundColor3 = enabled and Color3.fromRGB(60, 190, 130) or Color3.fromRGB(60, 62, 80)
    end
end

local function setEspColor(color)
    state.espColor = color
    updateHighlightAppearance()
end

local function setTargetMode(mode)
    state.aimbotTargetMode = mode
    for name, button in pairs(targetButtons) do
        button.BackgroundColor3 = (name == mode) and Color3.fromRGB(90, 120, 255) or Color3.fromRGB(45, 47, 60)
    end
end

local function updateShowHideHint()
    if showHideHintLabel then
        showHideHintLabel.Text = string.format("Press %s to show/hide", state.showHideKey.Name)
    end
end

--=====================================================
-- SECTION: GUI Helpers
--=====================================================
local function createToggleRow(parent, id, labelText, description)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 86)
    row.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 10)
    rowCorner.Parent = row

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.TextColor3 = Color3.fromRGB(235, 235, 255)
    label.Text = labelText
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.fromOffset(12, 8)
    label.Size = UDim2.new(1, -12, 0, 22)
    label.Parent = row

    local desc = Instance.new("TextLabel")
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 14
    desc.TextWrapped = true
    desc.TextColor3 = Color3.fromRGB(175, 180, 210)
    desc.Text = description
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.Position = UDim2.fromOffset(12, 34)
    desc.Size = UDim2.new(1, -170, 0, 40)
    desc.Parent = row

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
    keyButton.BackgroundColor3 = Color3.fromRGB(48, 52, 68)
    keyButton.Font = Enum.Font.Gotham
    keyButton.TextSize = 14
    keyButton.TextColor3 = Color3.new(1, 1, 1)
    keyButton.Text = state.keybinds[id].Name
    keyButton.Parent = buttonColumn

    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 6)
    keyCorner.Parent = keyButton

    keyButton.MouseButton1Click:Connect(function()
        state.waitingForKey = id
        keyButton.Text = "..."
    end)

    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(1, 0, 0, 28)
    toggleButton.BackgroundColor3 = state.toggles[id] and Color3.fromRGB(60, 190, 130) or Color3.fromRGB(60, 62, 80)
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = 16
    toggleButton.TextColor3 = Color3.new(1, 1, 1)
    toggleButton.Text = state.toggles[id] and "ON" or "OFF"
    toggleButton.Parent = buttonColumn

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 7)
    toggleCorner.Parent = toggleButton

    toggleButton.MouseButton1Click:Connect(function()
        setToggle(id, not state.toggles[id])
    end)

    keybindRows[id] = keybindRows[id] or {}
    keybindRows[id].ToggleButton = toggleButton
    keybindRows[id].KeyButton = keyButton
end

local function createKeybindRow(parent, id, labelText, description, isShowHide)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 70)
    row.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 10)
    rowCorner.Parent = row

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.TextColor3 = Color3.fromRGB(235, 235, 255)
    label.Text = labelText
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Position = UDim2.fromOffset(12, 8)
    label.Size = UDim2.new(1, -12, 0, 22)
    label.Parent = row

    local desc = Instance.new("TextLabel")
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 14
    desc.TextWrapped = true
    desc.TextColor3 = Color3.fromRGB(175, 180, 210)
    desc.Text = description
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Position = UDim2.fromOffset(12, 34)
    desc.Size = UDim2.new(1, -120, 0, 28)
    desc.Parent = row

    local keyButton = Instance.new("TextButton")
    keyButton.Size = UDim2.new(0, 90, 0, 28)
    keyButton.Position = UDim2.new(1, -100, 0.5, -14)
    keyButton.BackgroundColor3 = Color3.fromRGB(48, 52, 68)
    keyButton.Font = Enum.Font.Gotham
    keyButton.TextSize = 14
    keyButton.TextColor3 = Color3.new(1, 1, 1)
    keyButton.Text = isShowHide and state.showHideKey.Name or state.keybinds[id].Name
    keyButton.Parent = row

    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 6)
    keyCorner.Parent = keyButton

    keyButton.MouseButton1Click:Connect(function()
        state.waitingForKey = isShowHide and "ShowHide" or id
        keyButton.Text = "..."
    end)

    if isShowHide then
        keybindRows.ShowHide = keyButton
    else
        keybindRows[id] = keybindRows[id] or {}
        keybindRows[id].KeyButton = keyButton
    end
end

local function createSlider(parent, labelText, component)
    local wrapper = Instance.new("Frame")
    wrapper.Size = UDim2.new(1, -8, 0, 54)
    wrapper.BackgroundTransparency = 1
    wrapper.Parent = parent

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = labelText
    label.Position = UDim2.fromOffset(6, 0)
    label.Size = UDim2.new(1, -12, 0, 18)
    label.Parent = wrapper

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -12, 0, 10)
    bar.Position = UDim2.fromOffset(6, 30)
    bar.BackgroundColor3 = Color3.fromRGB(45, 47, 60)
    bar.BorderSizePixel = 0
    bar.Parent = wrapper

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 6)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(110, 130, 255)
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(0.5, 0, 1, 0)
    fill.Parent = bar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = fill

    local valueLabel = Instance.new("TextLabel")
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.Code
    valueLabel.TextSize = 14
    valueLabel.TextColor3 = Color3.fromRGB(230, 230, 255)
    valueLabel.Text = "128"
    valueLabel.Position = UDim2.new(1, -40, 0, -2)
    valueLabel.Size = UDim2.new(0, 34, 0, 18)
    valueLabel.Parent = wrapper

    local function refresh()
        local current = math.floor(state.espColor[component] * 255 + 0.5)
        fill.Size = UDim2.new(current / 255, 0, 1, 0)
        valueLabel.Text = tostring(current)
    end
    refresh()

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local function setFromX(x)
                local percent = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local value = math.floor(percent * 255 + 0.5)
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
                fill.Size = UDim2.new(percent, 0, 1, 0)
                valueLabel.Text = tostring(value)
            end

            setFromX(input.Position.X)

            local moveConnection
            local releaseConnection

            moveConnection = UserInputService.InputChanged:Connect(function(moveInput)
                if moveInput.UserInputType == Enum.UserInputType.MouseMovement then
                    setFromX(moveInput.Position.X)
                end
            end)

            releaseConnection = UserInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 then
                    moveConnection:Disconnect()
                    releaseConnection:Disconnect()
                end
            end)
        end
    end)
end

--=====================================================
-- SECTION: GUI Construction
--=====================================================
local function buildGui()
    uiRoot = Instance.new("ScreenGui")
    uiRoot.Name = "RivalsMainGui"
    uiRoot.ResetOnSpawn = false
    uiRoot.IgnoreGuiInset = true
    uiRoot.Parent = (gethui and gethui())
        or (game:FindFirstChild("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"))

    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 420, 0, 420)
    mainFrame.Position = UDim2.fromScale(0.5, 0.5) - UDim2.fromOffset(210, 210)
    mainFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = uiRoot

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 14)
    frameCorner.Parent = mainFrame

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 54)
    header.BackgroundColor3 = Color3.fromRGB(32, 34, 46)
    header.BorderSizePixel = 0
    header.Parent = mainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 14)
    headerCorner.Parent = header

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextColor3 = Color3.fromRGB(220, 220, 255)
    title.Text = "RIVALS HUB"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Position = UDim2.fromOffset(16, 0)
    title.Size = UDim2.new(0.5, 0, 1, 0)
    title.Parent = header

    showHideHintLabel = Instance.new("TextLabel")
    showHideHintLabel.BackgroundTransparency = 1
    showHideHintLabel.Font = Enum.Font.Gotham
    showHideHintLabel.TextSize = 14
    showHideHintLabel.TextColor3 = Color3.fromRGB(180, 185, 220)
    showHideHintLabel.TextXAlignment = Enum.TextXAlignment.Right
    showHideHintLabel.Position = UDim2.new(1, -160, 0, 0)
    showHideHintLabel.Size = UDim2.new(0, 140, 1, 0)
    showHideHintLabel.Parent = header
    updateShowHideHint()

    local closeButton = Instance.new("TextButton")
    closeButton.Text = "×"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 20
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.BackgroundColor3 = Color3.fromRGB(52, 56, 72)
    closeButton.Size = UDim2.new(0, 36, 0, 36)
    closeButton.Position = UDim2.new(1, -46, 0.5, -18)
    closeButton.Parent = header

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        uiRoot:Destroy()
        statusGui:Destroy()
    end)

    local dragging = false
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

    local function createTabButton(name)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 110, 1, 0)
        button.Font = Enum.Font.Gotham
        button.TextSize = 16
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Text = name
        button.BackgroundColor3 = Color3.fromRGB(45, 47, 60)
        button.Parent = tabBar

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = button

        button.MouseButton1Click:Connect(function()
            switchTab(name)
        end)

        tabButtons[name] = button
    end

    for _, name in ipairs({"Combat", "ESP", "Settings"}) do
        createTabButton(name)
    end

    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, -24, 1, -112)
    contentArea.Position = UDim2.fromOffset(12, 106)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = mainFrame

    local function createTabContainer(name)
        local scroller = Instance.new("ScrollingFrame")
        scroller.Size = UDim2.new(1, 0, 1, 0)
        scroller.BackgroundTransparency = 1
        scroller.ScrollBarThickness = 5
        scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroller.CanvasSize = UDim2.new()
        scroller.Visible = false
        scroller.Parent = contentArea

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

    local combatTab = createTabContainer("Combat")
    local espTab = createTabContainer("ESP")
    local settingsTab = createTabContainer("Settings")

    createToggleRow(combatTab, "Aimbot", "Aimbot", "Locks onto the closest player within range.")
    createToggleRow(combatTab, "Trigger", "Trigger Bot", "Automatically fires when your crosshair is on an enemy.")

    local pickerFrame = Instance.new("Frame")
    pickerFrame.Size = UDim2.new(1, -8, 0, 110)
    pickerFrame.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    pickerFrame.BorderSizePixel = 0
    pickerFrame.Parent = combatTab

    local pickerCorner = Instance.new("UICorner")
    pickerCorner.CornerRadius = UDim.new(0, 10)
    pickerCorner.Parent = pickerFrame

    local pickerLabel = Instance.new("TextLabel")
    pickerLabel.BackgroundTransparency = 1
    pickerLabel.Font = Enum.Font.GothamBold
    pickerLabel.TextSize = 18
    pickerLabel.TextColor3 = Color3.fromRGB(235, 235, 255)
    pickerLabel.Text = "Aimbot Target"
    pickerLabel.TextXAlignment = Enum.TextXAlignment.Left
    pickerLabel.Position = UDim2.fromOffset(12, 8)
    pickerLabel.Size = UDim2.new(1, -12, 0, 24)
    pickerLabel.Parent = pickerFrame

    local pickerDesc = Instance.new("TextLabel")
    pickerDesc.BackgroundTransparency = 1
    pickerDesc.Font = Enum.Font.Gotham
    pickerDesc.TextSize = 14
    pickerDesc.TextWrapped = true
    pickerDesc.TextColor3 = Color3.fromRGB(175, 180, 210)
    pickerDesc.Text = "Choose where the aimbot aims: head, body, or legs."
    pickerDesc.TextXAlignment = Enum.TextXAlignment.Left
    pickerDesc.Position = UDim2.fromOffset(12, 34)
    pickerDesc.Size = UDim2.new(1, -12, 0, 28)
    pickerDesc.Parent = pickerFrame

    local buttonHolder = Instance.new("Frame")
    buttonHolder.BackgroundTransparency = 1
    buttonHolder.Position = UDim2.fromOffset(12, 68)
    buttonHolder.Size = UDim2.new(1, -24, 0, 32)
    buttonHolder.Parent = pickerFrame

    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.Padding = UDim.new(0, 10)
    buttonLayout.Parent = buttonHolder

    for _, mode in ipairs({"Head", "Body", "Legs"}) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 100, 1, 0)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 16
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.BackgroundColor3 = (mode == state.aimbotTargetMode) and Color3.fromRGB(90, 120, 255) or Color3.fromRGB(45, 47, 60)
        btn.Text = mode
        btn.Parent = buttonHolder

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            setTargetMode(mode)
        end)

        targetButtons[mode] = btn
    end

    createToggleRow(espTab, "ESP", "ESP Outlines", "Highlights enemies with colored outlines like the OG script.")

    local colorFrame = Instance.new("Frame")
    colorFrame.Size = UDim2.new(1, -8, 0, 190)
    colorFrame.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    colorFrame.BorderSizePixel = 0
    colorFrame.Parent = espTab

    local colorCorner = Instance.new("UICorner")
    colorCorner.CornerRadius = UDim.new(0, 10)
    colorCorner.Parent = colorFrame

    local colorLabel = Instance.new("TextLabel")
    colorLabel.BackgroundTransparency = 1
    colorLabel.Font = Enum.Font.GothamBold
    colorLabel.TextSize = 18
    colorLabel.TextColor3 = Color3.fromRGB(235, 235, 255)
    colorLabel.Text = "Outline Color"
    colorLabel.TextXAlignment = Enum.TextXAlignment.Left
    colorLabel.Position = UDim2.fromOffset(12, 8)
    colorLabel.Size = UDim2.new(1, -12, 0, 24)
    colorLabel.Parent = colorFrame

    local colorDesc = Instance.new("TextLabel")
    colorDesc.BackgroundTransparency = 1
    colorDesc.Font = Enum.Font.Gotham
    colorDesc.TextSize = 14
    colorDesc.TextWrapped = true
    colorDesc.TextColor3 = Color3.fromRGB(175, 180, 210)
    colorDesc.Text = "RGB sliders to tweak the outline color in real time."
    colorDesc.TextXAlignment = Enum.TextXAlignment.Left
    colorDesc.Position = UDim2.fromOffset(12, 34)
    colorDesc.Size = UDim2.new(1, -12, 0, 30)
    colorDesc.Parent = colorFrame

    local sliderHolder = Instance.new("Frame")
    sliderHolder.BackgroundTransparency = 1
    sliderHolder.Position = UDim2.fromOffset(12, 70)
    sliderHolder.Size = UDim2.new(1, -24, 0, 110)
    sliderHolder.Parent = colorFrame

    for _, info in ipairs({{label = "Red", component = "R"}, {label = "Green", component = "G"}, {label = "Blue", component = "B"}}) do
        createSlider(sliderHolder, info.label, info.component)
    end

    createKeybindRow(settingsTab, "Aimbot", "Aimbot Toggle", "Keyboard shortcut to toggle the aimbot on/off.", false)
    createKeybindRow(settingsTab, "ESP", "ESP Toggle", "Keyboard shortcut to enable outline ESP.", false)
    createKeybindRow(settingsTab, "Trigger", "Trigger Toggle", "Keyboard shortcut to enable trigger bot.", false)
    createKeybindRow(settingsTab, nil, "Show/Hide UI", "Key used to hide or reveal this menu.", true)

    switchTab(state.currentTab)
end

--=====================================================
-- SECTION: Status HUD Construction
--=====================================================
local function buildStatusGui()
    statusGui = Instance.new("ScreenGui")
    statusGui.Name = "RivalsStatus"
    statusGui.ResetOnSpawn = false
    statusGui.IgnoreGuiInset = true
    statusGui.Parent = (gethui and gethui())
        or (game:FindFirstChild("CoreGui") or LocalPlayer:WaitForChild("PlayerGui"))

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 80)
    frame.Position = UDim2.new(0, 12, 0, 12)
    frame.BackgroundColor3 = Color3.fromRGB(18, 19, 24)
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel = 0
    frame.Parent = statusGui

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
buildStatusGui()
buildGui()

for _, player in ipairs(Players:GetPlayers()) do
    ensureHighlight(player)
end

Players.PlayerAdded:Connect(ensureHighlight)
Players.PlayerRemoving:Connect(cleanupHighlight)

LocalPlayer.CharacterAdded:Connect(function()
    updateRaycastFilter()
end)
updateRaycastFilter()
updateHighlightAppearance()
setTargetMode(state.aimbotTargetMode)

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
                    if keybindRows.ShowHide then
                        keybindRows.ShowHide.Text = key.Name
                    end
                    updateShowHideHint()
                else
                    state.keybinds[state.waitingForKey] = key
                    local row = keybindRows[state.waitingForKey]
                    if row and row.KeyButton then
                        row.KeyButton.Text = key.Name
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
    -- Aimbot
    if state.toggles.Aimbot then
        local targetPlayer = getClosestPlayerInFOV()
        if targetPlayer then
            local character = targetPlayer.Character
            local aimPart = character and resolveTargetPart(character)
            local myCharacter = LocalPlayer.Character
            local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
            if aimPart and myRoot then
                local distance = (aimPart.Position - myRoot.Position).Magnitude
                updateStatus(string.format("AIMBOT: LOCKED\nDISTANCE: %d studs\nTARGET: %s", math.floor(distance), targetPlayer.Name), Color3.fromRGB(90, 255, 90))

                local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                if onScreen then
                    local deltaX = (screenPos.X - Mouse.X) * 0.75
                    local deltaY = (screenPos.Y - Mouse.Y) * 0.75
                    mousemoverel(deltaX, deltaY)
                end
            else
                updateStatus("AIMBOT: SEARCHING\nDISTANCE: --\nTARGET: --", Color3.fromRGB(255, 255, 120))
            end
        else
            updateStatus("AIMBOT: SEARCHING\nDISTANCE: --\nTARGET: --", Color3.fromRGB(255, 255, 120))
        end
    else
        updateStatus("AIMBOT: OFF\nDISTANCE: --\nTARGET: --", Color3.fromRGB(255, 90, 90))
    end

    -- Trigger bot
    state.triggerCooldown = math.max(0, state.triggerCooldown - dt)
    if state.toggles.Trigger and state.triggerCooldown <= 0 then
        local result = workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector * 500, triggerRayParams)
        if result then
            local character = result.Instance:FindFirstAncestorOfClass("Model")
            local player = character and Players:GetPlayerFromCharacter(character)
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if player and player ~= LocalPlayer and humanoid and humanoid.Health > 0 then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new())
                state.triggerCooldown = 0.15
            end
        end
    end
end)

print("[Rivals Hub] Loaded. Use the Combat/ESP/Settings tabs to configure features. Press " .. state.showHideKey.Name .. " to hide or show the menu.")
