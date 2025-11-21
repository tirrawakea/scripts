local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local guiParent = (gethui and gethui()) or CoreGui

local themes = {
    Neon = {
        background = Color3.fromRGB(12, 14, 20),
        panel = Color3.fromRGB(22, 25, 34),
        accent = Color3.fromRGB(90, 205, 255),
        accentDark = Color3.fromRGB(60, 140, 200),
        stroke = Color3.fromRGB(70, 90, 130),
        text = Color3.fromRGB(235, 238, 245),
        subtle = Color3.fromRGB(170, 185, 205),
        gradient1 = Color3.fromRGB(30, 36, 54),
        gradient2 = Color3.fromRGB(10, 12, 18),
        tabHover = Color3.fromRGB(30, 35, 46),
        chip = Color3.fromRGB(32, 36, 48),
    },
    Sunrise = {
        background = Color3.fromRGB(18, 13, 10),
        panel = Color3.fromRGB(32, 24, 18),
        accent = Color3.fromRGB(255, 170, 80),
        accentDark = Color3.fromRGB(210, 120, 60),
        stroke = Color3.fromRGB(120, 80, 55),
        text = Color3.fromRGB(245, 235, 220),
        subtle = Color3.fromRGB(210, 180, 150),
        gradient1 = Color3.fromRGB(70, 45, 30),
        gradient2 = Color3.fromRGB(18, 13, 10),
        tabHover = Color3.fromRGB(55, 38, 26),
        chip = Color3.fromRGB(48, 34, 24),
    },
    Aether = {
        background = Color3.fromRGB(13, 16, 17),
        panel = Color3.fromRGB(24, 30, 32),
        accent = Color3.fromRGB(120, 225, 190),
        accentDark = Color3.fromRGB(70, 150, 130),
        stroke = Color3.fromRGB(60, 95, 90),
        text = Color3.fromRGB(230, 240, 235),
        subtle = Color3.fromRGB(180, 195, 190),
        gradient1 = Color3.fromRGB(28, 40, 44),
        gradient2 = Color3.fromRGB(13, 16, 17),
        tabHover = Color3.fromRGB(32, 44, 46),
        chip = Color3.fromRGB(30, 38, 40),
    },
}

local palette = themes.Neon

local alphabetRanges = {
    {name = "A - C", letters = {"A", "B", "C"}},
    {name = "D - F", letters = {"D", "E", "F"}},
    {name = "G - I", letters = {"G", "H", "I"}},
    {name = "J - L", letters = {"J", "K", "L"}},
    {name = "M - O", letters = {"M", "N", "O"}},
    {name = "P - R", letters = {"P", "Q", "R"}},
    {name = "S - T", letters = {"S", "T"}},
    {name = "U - V", letters = {"U", "V"}},
    {name = "W - X", letters = {"W", "X"}},
    {name = "Y - Z", letters = {"Y", "Z"}},
}

local sectionPanels = {}
local primaryButtons = {}
local dropdownHeaders = {}
local dropdownBodies = {}
local letterButtons = {}
local tabButtons = {}
local tabPages = {}
local themeButtons = {}

local CurrentKey = Enum.KeyCode.RightBracket
local WaitingForKey = false
local lastSetTime = 0

local KeyDisplayNames = {
    RightBracket = "]",
    LeftBracket = "[",
    Semicolon = ";",
    Quote = "'",
    Comma = ",",
    Period = ".",
    Slash = "/",
    BackSlash = "\\",
    Minus = "-",
    Equals = "=",
    Backquote = "`",

    LeftShift = "LShift",
    RightShift = "RShift",
    LeftControl = "LCtrl",
    RightControl = "RCtrl",
    LeftAlt = "LAlt",
    RightAlt = "RAlt",

    Return = "Enter",
    Space = "Space",
    Tab = "Tab",
    Backspace = "Backspace",
    Delete = "Del",
    Insert = "Ins",
    Home = "Home",
    End = "End",
    PageUp = "PgUp",
    PageDown = "PgDn",

    Up = "Up",
    Down = "Down",
    Left = "Left",
    Right = "Right",
}

local function getKeyName(key)
    return KeyDisplayNames[key.Name] or key.Name
end

local function tween(object, info, props)
    TweenService:Create(object, info, props):Play()
end

local function makeRounded(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
    return corner
end

local function addStroke(instance, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = color
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.Parent = instance
    return stroke
end

local destroyed = false

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TemoHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

local Shadow = Instance.new("Frame")
Shadow.Name = "Shadow"
Shadow.Size = UDim2.new(0, 520, 0, 520)
Shadow.Position = UDim2.new(0.5, -260, 0.5, -260)
Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Shadow.BackgroundTransparency = 0.35
Shadow.BorderSizePixel = 0
Shadow.Active = true
Shadow.Parent = ScreenGui
makeRounded(Shadow, 18)

local Container = Instance.new("Frame")
Container.Name = "Container"
Container.Size = UDim2.new(1, -28, 1, -28)
Container.Position = UDim2.new(0, 14, 0, 14)
Container.BackgroundColor3 = palette.background
Container.BorderSizePixel = 0
Container.ClipsDescendants = true
Container.Active = true
Container.Parent = Shadow
makeRounded(Container, 14)
addStroke(Container, palette.stroke, 1, 0.35)

local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 28, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 14, 20)),
})
grad.Rotation = 45
grad.Parent = Container

local Padding = Instance.new("UIPadding")
Padding.PaddingTop = UDim.new(0, 16)
Padding.PaddingBottom = UDim.new(0, 16)
Padding.PaddingLeft = UDim.new(0, 18)
Padding.PaddingRight = UDim.new(0, 18)
Padding.Parent = Container

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 70)
Header.BackgroundTransparency = 1
Header.LayoutOrder = 1
Header.Parent = Container

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -150, 0, 36)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 28
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = palette.text
title.Text = "TemoHub"
title.Parent = Header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, -150, 0, 22)
subtitle.Position = UDim2.new(0, 0, 0, 36)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 16
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextColor3 = palette.subtle
subtitle.Text = "Scripts, auto-finder, and quick settings"
subtitle.Parent = Header

local statusPill = Instance.new("TextLabel")
statusPill.AnchorPoint = Vector2.new(1, 0)
statusPill.Position = UDim2.new(1, 0, 0, 6)
statusPill.Size = UDim2.new(0, 140, 0, 28)
statusPill.BackgroundColor3 = palette.panel
statusPill.Font = Enum.Font.GothamSemibold
statusPill.TextSize = 14
statusPill.TextColor3 = palette.text
statusPill.Text = "Press ] to toggle"
statusPill.BorderSizePixel = 0
statusPill.Parent = Header
makeRounded(statusPill, 10)
addStroke(statusPill, palette.stroke, 1, 0.25)

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -96)
Content.Position = UDim2.new(0, 0, 0, 82)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.Parent = Container

local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, 0, 0, 38)
TabBar.BackgroundTransparency = 1
TabBar.BorderSizePixel = 0
TabBar.ClipsDescendants = true
TabBar.Parent = Content

local tabPadding = Instance.new("UIPadding")
tabPadding.PaddingTop = UDim.new(0, 2)
tabPadding.PaddingBottom = UDim.new(0, 6)
tabPadding.PaddingLeft = UDim.new(0, 2)
tabPadding.PaddingRight = UDim.new(0, 2)
tabPadding.Parent = TabBar

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 8)
tabLayout.Parent = TabBar

local TabIndicator = Instance.new("Frame")
TabIndicator.Name = "TabIndicator"
TabIndicator.Size = UDim2.new(0, 0, 0, 3)
TabIndicator.Position = UDim2.new(0, 0, 1, -1)
TabIndicator.AnchorPoint = Vector2.new(0, 1)
TabIndicator.BackgroundColor3 = palette.accent
TabIndicator.BorderSizePixel = 0
TabIndicator.Visible = false
TabIndicator.Parent = TabBar
makeRounded(TabIndicator, 3)

local Pages = Instance.new("Frame")
Pages.Name = "Pages"
Pages.Size = UDim2.new(1, 0, 1, -46)
Pages.Position = UDim2.new(0, 0, 0, 46)
Pages.BackgroundTransparency = 1
Pages.BorderSizePixel = 0
Pages.Parent = Content

local tabs = {}
local tabCount = 0
local activeTab = nil

local function setActiveTab(name)
    activeTab = name
    for tabName, data in pairs(tabs) do
        local isActive = tabName == name
        data.Page.Visible = isActive
        data.Button.BackgroundColor3 = isActive and palette.accentDark or palette.background
        data.Button.TextColor3 = isActive and Color3.new(1, 1, 1) or palette.text
    end
end

local function createTab(tabName)
    tabCount += 1

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 120, 1, -8)
    button.BackgroundColor3 = palette.background
    button.AutoButtonColor = false
    button.TextColor3 = palette.text
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 15
    button.Text = tabName
    button.BorderSizePixel = 0
    button.LayoutOrder = tabCount
    button.Parent = TabBar
    makeRounded(button, 9)
    addStroke(button, palette.stroke, 1, 0.28)
    table.insert(tabButtons, button)

    button.MouseEnter:Connect(function()
        if activeTab == tabName then return end
        tween(button, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(30, 35, 45),
        })
    end)

    button.MouseLeave:Connect(function()
        if activeTab == tabName then return end
        tween(button, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            BackgroundColor3 = palette.background,
        })
    end)

    local page = Instance.new("ScrollingFrame")
    page.Name = tabName .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollBarThickness = 6
    page.ScrollBarImageColor3 = palette.accent
    page.Visible = false
    page.Parent = Pages

    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingTop = UDim.new(0, 4)
    pagePadding.PaddingBottom = UDim.new(0, 4)
    pagePadding.PaddingLeft = UDim.new(0, 2)
    pagePadding.PaddingRight = UDim.new(0, 2)
    pagePadding.Parent = page

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 12)
    pageLayout.Parent = page

    button.MouseButton1Click:Connect(function()
        setActiveTab(tabName)
    end)

    tabs[tabName] = {
        Button = button,
        Page = page,
    }
    tabPages[tabName] = page

    if not activeTab then
        setActiveTab(tabName)
    end

    return page
end

local function setStrokeColor(obj, color, transparency)
    if not obj then return end
    local stroke = obj:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Color = color
        if transparency then
            stroke.Transparency = transparency
        end
    end
end

local function applyTheme(name)
    local theme = themes[name]
    if not theme then return end

    palette = theme

    Container.BackgroundColor3 = theme.background
    setStrokeColor(Container, theme.stroke, 0.35)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.gradient1 or theme.background),
        ColorSequenceKeypoint.new(1, theme.gradient2 or theme.background),
    })

    statusPill.BackgroundColor3 = theme.panel
    statusPill.TextColor3 = theme.text
    setStrokeColor(statusPill, theme.stroke, 0.25)

    for _, section in ipairs(sectionPanels) do
        section.BackgroundColor3 = theme.panel
        setStrokeColor(section, theme.stroke, 0.2)
    end

    for _, btn in ipairs(primaryButtons) do
        btn.BackgroundColor3 = theme.accentDark
        btn.TextColor3 = Color3.new(1, 1, 1)
        setStrokeColor(btn, theme.stroke, 0.15)
    end

    for _, header in ipairs(dropdownHeaders) do
        header.BackgroundColor3 = theme.panel
        header.TextColor3 = theme.text
        setStrokeColor(header, theme.stroke, 0.25)
    end

    for _, body in ipairs(dropdownBodies) do
        body.BackgroundColor3 = theme.background
        setStrokeColor(body, theme.stroke, 0.18)
    end

    for _, letterBtn in ipairs(letterButtons) do
        letterBtn.BackgroundColor3 = theme.chip or theme.panel
        letterBtn.TextColor3 = theme.text
        setStrokeColor(letterBtn, theme.stroke, 0.2)
    end

    for _, tabBtn in ipairs(tabButtons) do
        setStrokeColor(tabBtn, theme.stroke, 0.28)
    end

    for _, page in pairs(tabPages) do
        page.ScrollBarImageColor3 = theme.accent
    end

    for key, btn in pairs(themeButtons) do
        local isActive = key == name
        local keyTheme = themes[key]
        btn.BackgroundColor3 = isActive and theme.accentDark or (keyTheme and keyTheme.chip) or Color3.fromRGB(32, 32, 32)
        btn.TextColor3 = isActive and Color3.new(1, 1, 1) or (keyTheme and (keyTheme.text or keyTheme.subtle)) or Color3.new(0.8, 0.8, 0.8)
        setStrokeColor(btn, keyTheme and keyTheme.stroke or theme.stroke, isActive and 0.1 or 0.45)
    end

    setActiveTab(activeTab)
    setKeybindText(WaitingForKey)
end

local function createSection(titleText)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 60)
    section.BackgroundColor3 = palette.panel
    section.BorderSizePixel = 0
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.LayoutOrder = 2
    makeRounded(section, 12)
    addStroke(section, palette.stroke, 1, 0.2)
    table.insert(sectionPanels, section)

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = section

    local stack = Instance.new("UIListLayout")
    stack.SortOrder = Enum.SortOrder.LayoutOrder
    stack.Padding = UDim.new(0, 10)
    stack.Parent = section

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 22)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamSemibold
    header.TextSize = 18
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.TextColor3 = palette.text
    header.Text = titleText
    header.LayoutOrder = 1
    header.Parent = section

    return section
end

local function createButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = palette.accentDark
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 16
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Text = text
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.LayoutOrder = 2
    btn.Parent = parent
    makeRounded(btn, 10)
    addStroke(btn, palette.stroke, 1, 0.15)
    table.insert(primaryButtons, btn)

    btn.MouseEnter:Connect(function()
        tween(btn, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            BackgroundColor3 = palette.accent,
        })
    end)

    btn.MouseLeave:Connect(function()
        tween(btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            BackgroundColor3 = palette.accentDark,
        })
    end)

    btn.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)

    return btn
end

local ScriptsPage = createTab("Scripts")
local ScriptsSection = createSection("Scripts")
ScriptsSection.LayoutOrder = 2
ScriptsSection.Parent = ScriptsPage

createButton(ScriptsSection, "Auto-Find Game", function()
    loadstring(game:HttpGet("https://pastebin.com/raw/0sUGfskc"))()
end)

local activeDropdown
local dropdownArrows = {}

local function buildDropdown(parent, labelText, letters)
    local wrapper = Instance.new("Frame")
    wrapper.Size = UDim2.new(1, 0, 0, 52)
    wrapper.BackgroundTransparency = 1
    wrapper.AutomaticSize = Enum.AutomaticSize.Y
    wrapper.LayoutOrder = 3
    wrapper.Parent = parent

    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = palette.background
    header.AutoButtonColor = false
    header.TextColor3 = palette.text
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Font = Enum.Font.GothamSemibold
    header.TextSize = 16
    header.Text = labelText
    header.BorderSizePixel = 0
    header.Parent = wrapper
    makeRounded(header, 8)
    addStroke(header, palette.stroke, 1, 0.25)
    table.insert(dropdownHeaders, header)

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -24, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = ">"
    arrow.TextColor3 = palette.subtle
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 18
    arrow.Parent = header

    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, 0, 0, 0)
    body.BackgroundColor3 = palette.background
    body.BorderSizePixel = 0
    body.Visible = false
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.ClipsDescendants = true
    body.Parent = wrapper
    makeRounded(body, 8)
    addStroke(body, palette.stroke, 1, 0.18)
    table.insert(dropdownBodies, body)

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = body

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 70, 0, 30)
    grid.CellPadding = UDim2.new(0, 8, 0, 8)
    grid.FillDirection = Enum.FillDirection.Horizontal
    grid.FillDirectionMaxCells = 3
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = body

    for _, letter in ipairs(letters) do
        local letterBtn = Instance.new("TextButton")
        letterBtn.Size = UDim2.new(0, 70, 0, 30)
        letterBtn.BackgroundColor3 = palette.chip or palette.panel
        letterBtn.AutoButtonColor = false
        letterBtn.TextColor3 = palette.text
        letterBtn.Font = Enum.Font.GothamSemibold
        letterBtn.TextSize = 15
        letterBtn.Text = letter
        letterBtn.BorderSizePixel = 0
        letterBtn.Parent = body
        makeRounded(letterBtn, 8)
        addStroke(letterBtn, palette.stroke, 1, 0.2)
        table.insert(letterButtons, letterBtn)

        letterBtn.MouseEnter:Connect(function()
            tween(letterBtn, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                BackgroundColor3 = palette.panel,
            })
        end)

        letterBtn.MouseLeave:Connect(function()
            tween(letterBtn, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                BackgroundColor3 = palette.chip or palette.panel,
            })
        end)

        letterBtn.MouseButton1Click:Connect(function()
            print("Selected:", letter, "from", labelText)
        end)
    end

    dropdownArrows[body] = arrow

    header.MouseButton1Click:Connect(function()
        local isOpening = not body.Visible

        if activeDropdown and activeDropdown ~= body then
            activeDropdown.Visible = false
            local arrowLabel = dropdownArrows[activeDropdown]
            if arrowLabel then
                arrowLabel.Text = ">"
            end
        end

        body.Visible = isOpening
        arrow.Text = isOpening and "v" or ">"
        activeDropdown = isOpening and body or nil
    end)
end

for _, data in ipairs(alphabetRanges) do
    buildDropdown(ScriptsSection, data.name, data.letters)
end

local SettingsPage = createTab("Settings")
local SettingsSection = createSection("Settings")
SettingsSection.LayoutOrder = 3
SettingsSection.Parent = SettingsPage

local ThemeSection = createSection("Appearance")
ThemeSection.LayoutOrder = 1
ThemeSection.Parent = SettingsPage

local themeGrid = Instance.new("Frame")
themeGrid.BackgroundTransparency = 1
themeGrid.Size = UDim2.new(1, 0, 0, 80)
themeGrid.Parent = ThemeSection

local themeGridLayout = Instance.new("UIGridLayout")
themeGridLayout.CellSize = UDim2.new(0, 130, 0, 34)
themeGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
themeGridLayout.FillDirection = Enum.FillDirection.Horizontal
themeGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
themeGridLayout.Parent = themeGrid

local themeOrder = {"Neon", "Sunrise", "Aether"}

for _, themeName in ipairs(themeOrder) do
    local themeInfo = themes[themeName]
    local chip = Instance.new("TextButton")
    chip.Name = themeName .. "Theme"
    chip.BackgroundColor3 = themeInfo.chip or themeInfo.panel
    chip.AutoButtonColor = false
    chip.TextColor3 = themeInfo.text
    chip.Font = Enum.Font.GothamSemibold
    chip.TextSize = 14
    chip.Text = themeName
    chip.BorderSizePixel = 0
    chip.Parent = themeGrid
    makeRounded(chip, 9)
    addStroke(chip, themeInfo.stroke, 1, 0.4)
    themeButtons[themeName] = chip

    local accentBar = Instance.new("Frame")
    accentBar.BackgroundColor3 = themeInfo.accent
    accentBar.Size = UDim2.new(0, 6, 1, -10)
    accentBar.Position = UDim2.new(1, -10, 0, 5)
    accentBar.BorderSizePixel = 0
    accentBar.Parent = chip
    makeRounded(accentBar, 6)

    chip.MouseButton1Click:Connect(function()
        applyTheme(themeName)
    end)
end

local keyButton

local function setKeybindText(waiting)
    if waiting then
        if keyButton then
            keyButton.Text = "..."
        end
        statusPill.Text = "Waiting for key..."
        return
    end

    if keyButton then
        keyButton.Text = "Keybind: " .. getKeyName(CurrentKey) .. " (click to change)"
    end
    statusPill.Text = "Press " .. getKeyName(CurrentKey) .. " to toggle"
end

keyButton = createButton(SettingsSection, "Keybind: " .. getKeyName(CurrentKey) .. " (click to change)", function()
    WaitingForKey = true
    setKeybindText(true)
end)

local unloadButton = createButton(SettingsSection, "Unload UI", function()
    destroyed = true
    ScreenGui:Destroy()
end)

local dragging = false
local dragStart, startPos

local function updateDrag(input)
    if destroyed then return end
    local delta = input.Position - dragStart
    Shadow.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Shadow.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

Header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            if destroyed then return end
            updateDrag(input)
        end
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        if destroyed then return end
        updateDrag(input)
    end
end)

local function setVisible(state)
    if destroyed then return end
    Container.Visible = state
    Shadow.Visible = state
end

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if destroyed then return end

    if WaitingForKey and input.KeyCode ~= Enum.KeyCode.Unknown then
        CurrentKey = input.KeyCode
        WaitingForKey = false
        lastSetTime = os.clock()
        setKeybindText(false)
        print("New show/hide key:", getKeyName(CurrentKey))
        return
    end

    if input.KeyCode == CurrentKey then
        if os.clock() - lastSetTime < 0.25 then return end
        setVisible(not Container.Visible)
    end
end)

applyTheme("Neon")
setVisible(true)
