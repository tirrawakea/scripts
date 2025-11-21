-- Press V or click the UI button to toggle a loop that swaps WalkSpeed between 26 and 0 every 0.15s.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local humanoid
local savedSpeed = 16
local enabled = false
local loopToken
local toggleButton

local function currentHumanoid()
    local character = player.Character
    if character then
        return character:FindFirstChildOfClass("Humanoid")
    end
end

local function hookHumanoid()
    local character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
end

local function startLoop()
    if not humanoid then
        return
    end

    savedSpeed = humanoid.WalkSpeed
    local token = {}
    loopToken = token
    task.spawn(function()
        while enabled and loopToken == token do
            local h = currentHumanoid()
            if h then
                h.WalkSpeed = 26
            end
            task.wait(0.15)
            if not (enabled and loopToken == token) then
                break
            end
            h = currentHumanoid()
            if h then
                h.WalkSpeed = 0
            end
            task.wait(0.15)
        end
    end)
end

local function stopLoop()
    loopToken = nil
    local h = currentHumanoid()
    if h then
        h.WalkSpeed = savedSpeed
    end
end

local function updateButton()
    if not toggleButton then
        return
    end
    toggleButton.Text = enabled and "Speed: ON (V)" or "Speed: OFF (V)"
    toggleButton.BackgroundColor3 = enabled and Color3.fromRGB(35, 110, 60) or Color3.fromRGB(30, 30, 30)
end

local function setEnabled(state)
    enabled = state
    if enabled then
        startLoop()
    else
        stopLoop()
    end
    updateButton()
end

do
    local gui = Instance.new("ScreenGui")
    gui.Name = "SpeedToggleGui"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = CoreGui

    toggleButton = Instance.new("TextButton")
    toggleButton.Name = "SpeedToggleButton"
    toggleButton.Size = UDim2.new(0, 160, 0, 40)
    toggleButton.Position = UDim2.new(0, 20, 0, 200)
    toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    toggleButton.BorderSizePixel = 1
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.SourceSansBold
    toggleButton.TextSize = 18
    toggleButton.Text = "Speed: OFF (V)"
    toggleButton.Parent = gui

    toggleButton.MouseButton1Click:Connect(function()
        setEnabled(not enabled)
    end)

    updateButton()
end

hookHumanoid()
player.CharacterAdded:Connect(function()
    hookHumanoid()
    if enabled then
        loopToken = nil
        task.defer(startLoop)
        updateButton()
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.V then
        setEnabled(not enabled)
    end
end)
