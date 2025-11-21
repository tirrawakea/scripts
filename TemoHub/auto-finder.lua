local StarterGui = game:GetService("StarterGui")
local placeId = game.PlaceId

local function createPopup(title, message)
    local guiParent = gethui and gethui()
        or (game:FindService("CoreGui") or game:GetService("Players").LocalPlayer.PlayerGui)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "TemoHubPopup"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = guiParent

    local Shadow = Instance.new("Frame")
    Shadow.Size = UDim2.new(0, 320, 0, 170)
    Shadow.Position = UDim2.new(0.5, -160, 0.5, -85)
    Shadow.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    Shadow.BackgroundTransparency = 0.65
    Shadow.BorderSizePixel = 0
    Shadow.Parent = ScreenGui

    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 14)
    shadowCorner.Parent = Shadow

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -30, 1, -30)
    Frame.Position = UDim2.new(0, 15, 0, 15)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Frame.BorderSizePixel = 0
    Frame.Parent = Shadow

    local Stroke = Instance.new("UIStroke")
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Color = Color3.fromRGB(90, 90, 120)
    Stroke.Thickness = 1
    Stroke.Transparency = 0.3
    Stroke.Parent = Frame

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = Frame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 0, 28)
    TitleLabel.Position = UDim2.fromOffset(10, 10)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 20
    TitleLabel.TextColor3 = Color3.fromRGB(230, 230, 255)
    TitleLabel.Text = title
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Frame

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -20, 0, 1)
    divider.Position = UDim2.fromOffset(10, 42)
    divider.BackgroundColor3 = Color3.fromRGB(70, 70, 95)
    divider.BorderSizePixel = 0
    divider.Parent = Frame

    local MessageLabel = Instance.new("TextLabel")
    MessageLabel.Size = UDim2.new(1, -20, 0, 56)
    MessageLabel.Position = UDim2.fromOffset(10, 50)
    MessageLabel.BackgroundTransparency = 1
    MessageLabel.Font = Enum.Font.Gotham
    MessageLabel.TextSize = 18
    MessageLabel.TextColor3 = Color3.fromRGB(210, 210, 230)
    MessageLabel.TextWrapped = true
    MessageLabel.TextYAlignment = Enum.TextYAlignment.Top
    MessageLabel.Text = message
    MessageLabel.Parent = Frame

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 120, 0, 32)
    Button.Position = UDim2.new(0.5, -60, 1, -45)
    Button.BackgroundColor3 = Color3.fromRGB(70, 90, 255)
    Button.AutoButtonColor = false
    Button.Font = Enum.Font.GothamMedium
    Button.TextSize = 18
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.Text = "Got it"
    Button.Parent = Frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = Button

    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    buttonStroke.Color = Color3.fromRGB(120, 140, 255)
    buttonStroke.Thickness = 1
    buttonStroke.Parent = Button

    Button.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    -- drag support
    local dragging, dragStart, startPos
    local UserInputService = game:GetService("UserInputService")

    local function update(input)
        local delta = input.Position - dragStart
        Shadow.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    Frame.InputBegan:Connect(function(input)
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

    Frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                update(input)
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
end


local scriptRegistry = {
    [11729688377] = { url = "https://raw.githubusercontent.com/boogauser3533/natsuloader/main/SlideursHub-Loader.lua", message = "Loaded SlideursHub!\nPress Left-Shift." },
    [7336302630] = { url = "https://raw.githubusercontent.com/ArtChivegroup/Roblox/refs/heads/main/script/project_delta.lua", message = "Loaded!\nEnjoy your features." },
    [17625359962] = { url = "https://pastebin.com/raw/vXZ0NULy", message = "Loaded TemoRivals!\nPress Right-Control." },
    [2414851778] = { url = "https://pastefy.app/lfUeGvqH/raw", message = "Loaded Dungeon Quest!\nEnjoy!" },
    [55555555] = { url = "https://your-E-script-here", message = "Loaded script for E!\nEnjoy your features." },
    [66666666] = { url = "https://your-F-script-here", message = "Loaded script for F!\nEnjoy your features." },
    [77777777] = { url = "https://your-G-script-here", message = "Loaded script for G!\nEnjoy your features." },
    [88888888] = { url = "https://your-H-script-here", message = "Loaded script for H!\nEnjoy your features." },
    [99999999] = { url = "https://your-I-script-here", message = "Loaded script for I!\nEnjoy your features." },
    [10101010] = { url = "https://your-J-script-here", message = "Loaded script for J!\nEnjoy your features." },
    [11111112] = { url = "https://your-K-script-here", message = "Loaded script for K!\nEnjoy your features." },
    [12121212] = { url = "https://your-L-script-here", message = "Loaded script for L!\nEnjoy your features." },
    [13131313] = { url = "https://your-M-script-here", message = "Loaded script for M!\nEnjoy your features." },
    [14141414] = { url = "https://your-N-script-here", message = "Loaded script for N!\nEnjoy your features." },
    [15151515] = { url = "https://your-O-script-here", message = "Loaded script for O!\nEnjoy your features." },
    [16161616] = { url = "https://your-P-script-here", message = "Loaded script for P!\nEnjoy your features." },
    [17171717] = { url = "https://your-Q-script-here", message = "Loaded script for Q!\nEnjoy your features." },
    [18181818] = { url = "https://your-R-script-here", message = "Loaded script for R!\nEnjoy your features." },
    [19191919] = { url = "https://your-S-script-here", message = "Loaded script for S!\nEnjoy your features." },
    [13253735473] = {
        request = {
            Url = "https://raw.githubusercontent.com/mainstreamed/amongus-hook/main/mainloader.lua",
            Method = "GET",
        },
        message = "Loaded AmongUs Hook!\nUse Arrow Keys.",
    },
    [11156779721] = {
        url = "https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/NewMainScript.lua",
        message = "Loaded VapeV4!\nPress Right-Shift.",
        useSecondArg = true,
    },
    [21212121] = { url = "https://your-U-script-here", message = "Loaded script for U!\nEnjoy your features." },
    [23232323] = { url = "https://your-W-script-here", message = "Loaded script for W!\nEnjoy your features." },
    [24242424] = { url = "https://your-X-script-here", message = "Loaded script for X!\nEnjoy your features." },
    [25252525] = { url = "https://your-Y-script-here", message = "Loaded script for Y!\nEnjoy your features." },
    [26262626] = { url = "https://your-Z-script-here", message = "Loaded script for Z!\nEnjoy your features." },
    [592150372] = { url = "https://pastebin.com/raw/quUwkkSB", message = "Loaded TemoHub!\nHave Fun!" },
}

local function runScriptFor(id)
    local data = scriptRegistry[id]
    if not data then
        return false
    end

    local source
    if data.request then
        local response = request(data.request)
        source = response and response.Body
    else
        source = game:HttpGet(data.url, data.useSecondArg or false)
    end

    if not source then
        warn("Auto-Finder failed to download script for placeId:", id)
        createPopup("Auto-Finder", "Failed to download script for this game.")
        return true
    end

    local ok, err = pcall(function()
        loadstring(source)()
    end)

    if not ok then
        warn("Auto-Finder error:", err)
        createPopup("Auto-Finder", "Failed to execute script.\nCheck console.")
        return true
    end

    createPopup("Auto-Finder", data.message)
    return true
end

print("Auto-Finder: PlaceId =", placeId)

if placeId == 11729688377 then
    runScriptFor(placeId)
elseif placeId == 7336302630 then
    runScriptFor(placeId)
elseif placeId == 7353845952 then
    runScriptFor(7336302630)
elseif placeId == 17625359962 then
    runScriptFor(placeId)
elseif placeId == 2414851778 then
    runScriptFor(placeId)
elseif placeId == 14363263080 then
    runScriptFor(2414851778)
elseif placeId == 66666666 then
    runScriptFor(placeId)
elseif placeId == 77777777 then
    runScriptFor(placeId)
elseif placeId == 88888888 then
    runScriptFor(placeId)
elseif placeId == 99999999 then
    runScriptFor(placeId)
elseif placeId == 10101010 then
    runScriptFor(placeId)
elseif placeId == 11111112 then
    runScriptFor(placeId)
elseif placeId == 12121212 then
    runScriptFor(placeId)
elseif placeId == 13131313 then
    runScriptFor(placeId)
elseif placeId == 14141414 then
    runScriptFor(placeId)
elseif placeId == 15151515 then
    runScriptFor(placeId)
elseif placeId == 16161616 then
    runScriptFor(placeId)
elseif placeId == 17171717 then
    runScriptFor(placeId)
elseif placeId == 18181818 then
    runScriptFor(placeId)
elseif placeId == 19191919 then
    runScriptFor(placeId)
elseif placeId == 13253735473 then
    runScriptFor(placeId)
elseif placeId == 11156779721 then
    runScriptFor(placeId)
elseif placeId == 21212121 then
    runScriptFor(placeId)
elseif placeId == 23232323 then
    runScriptFor(placeId)
elseif placeId == 24242424 then
    runScriptFor(placeId)
elseif placeId == 25252525 then
    runScriptFor(placeId)
elseif placeId == 26262626 then
    runScriptFor(placeId)
elseif placeId == 592150372 then
    runScriptFor(placeId)
else
    createPopup("Auto-Finder", "No script found for this game.\nPlaceId: " .. placeId)
end
