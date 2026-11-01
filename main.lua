--[[
    🟩 TDX MACRO HUB V44 - NATIVE BULLETPROOF
    No HTTP, No External Libraries. Clicks a button to open.
--]]

local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- Cleanup old UIs
if CoreGui:FindFirstChild("TDX_NativeUI") then CoreGui.TDX_NativeUI:Destroy() end

-- ==========================================
-- 🔑 SETTINGS
-- ==========================================
local RecordKey = "Z"
local PlayKey = "X"
local TriggerAbilityKey = "C" 
local ActualAbilityKey = "G" 

local isRecording = false
local isPlaying = false
local loopPlayback = false
local actions = {}
local lastTowerKey = "1"
local lastPlacedIndex = 0
local isAbilityArmed = false

-- ==========================================
-- 🧠 HELPER FUNCTIONS
-- ==========================================
local function vimPressKey(keyName)
    local key = Enum.KeyCode[keyName]
    if key then
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
end

local function vimClick(x, y)
    local cam = workspace.CurrentCamera
    VirtualInputManager:SendMouseMoveEvent(x, y, cam)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

-- ==========================================
-- 🎨 NATIVE UI CREATION
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TDX_NativeUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- 1. The Floating Toggle Button (So you can always open it)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 100, 0, 30)
ToggleBtn.Position = UDim2.new(0, 20, 0.5, -15)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
ToggleBtn.Text = "🟩 MENU"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

-- 2. The Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 280)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", MainFrame)
stroke.Color = Color3.fromRGB(34, 197, 94)
stroke.Thickness = 1

-- Toggle Logic
ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Header
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "🟩 TDX MACRO V44"
Title.TextColor3 = Color3.fromRGB(34, 197, 94)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0, 30)
Status.BackgroundTransparency = 1
Status.Text = "Status: Idle (0 actions)"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.Parent = MainFrame

-- Buttons
local RecBtn = Instance.new("TextButton")
RecBtn.Size = UDim2.new(1, -20, 0, 35)
RecBtn.Position = UDim2.new(0, 10, 0, 60)
RecBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
RecBtn.Text = "⏺ START RECORDING (Z)"
RecBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RecBtn.Font = Enum.Font.GothamBold
RecBtn.Parent = MainFrame
Instance.new("UICorner", RecBtn).CornerRadius = UDim.new(0, 6)

local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(1, -20, 0, 35)
PlayBtn.Position = UDim2.new(0, 10, 0, 105)
PlayBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
PlayBtn.Text = "▶ PLAY MACRO (X)"
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.Parent = MainFrame
Instance.new("UICorner", PlayBtn).CornerRadius = UDim.new(0, 6)

local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(1, -20, 0, 35)
SaveBtn.Position = UDim2.new(0, 10, 0, 150)
SaveBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
SaveBtn.Text = "💾 PRINT JSON TO F9"
SaveBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.Parent = MainFrame
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)

local LoopBtn = Instance.new("TextButton")
LoopBtn.Size = UDim2.new(1, -20, 0, 30)
LoopBtn.Position = UDim2.new(0, 10, 0, 195)
LoopBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
LoopBtn.Text = "Loop: OFF"
LoopBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
LoopBtn.Font = Enum.Font.GothamBold
LoopBtn.Parent = MainFrame
Instance.new("UICorner", LoopBtn).CornerRadius = UDim.new(0, 6)

-- Info Label
local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -20, 0, 40)
Info.Position = UDim2.new(0, 10, 0, 235)
Info.BackgroundTransparency = 1
Info.Text = "Press C to cast ability (sends G). Press E to upgrade placed tower."
Info.TextColor3 = Color3.fromRGB(150, 150, 150)
Info.Font = Enum.Font.Gotham
Info.TextSize = 11
Info.TextWrapped = true
Info.Parent = MainFrame

-- ==========================================
-- CORE LOGIC
-- ==========================================
local function updateStatus()
    if isRecording then
        Status.Text = "Status: 🔴 RECORDING (" .. #actions .. " actions)"
        Status.TextColor3 = Color3.fromRGB(200, 50, 50)
    else
        Status.Text = "Status: Idle (" .. #actions .. " actions)"
        Status.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end

local function toggleRecord()
    if isPlaying then return end
    isRecording = not isRecording
    if isRecording then
        actions = {}; lastPlacedIndex = 0; isAbilityArmed = false
        RecBtn.Text = "⏹ STOP RECORDING"
        RecBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    else
        RecBtn.Text = "⏺ START RECORDING (Z)"
        RecBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
    updateStatus()
end

local function togglePlay()
    if isRecording or #actions == 0 then return end
    isPlaying = not isPlaying
    
    if isPlaying then
        PlayBtn.Text = "⏹ STOP PLAYING"
        PlayBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        task.spawn(function()
            repeat
                for i, act in ipairs(actions) do
                    if not isPlaying then break end
                    if act.action == "place" then
                        vimPressKey(act.tower)
                        task.wait(0.2)
                        vimClick(act.x, act.y)
                        task.wait(0.2)
                        for u = 1, act.upgrades do vimPressKey("E"); task.wait(0.3) end
                    elseif act.action == "cast" then
                        vimPressKey(act.key)
                        task.wait(0.3)
                        vimClick(act.x, act.y)
                        task.wait(0.3)
                    end
                    task.wait(0.5)
                end
                if loopPlayback and isPlaying then task.wait(5) end
            until not loopPlayback or not isPlaying
            isPlaying = false
            PlayBtn.Text = "▶ PLAY MACRO (X)"
            PlayBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
        end)
    else
        PlayBtn.Text = "▶ PLAY MACRO (X)"
        PlayBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
    end
end

-- ==========================================
-- UI CONNECTIONS
-- ==========================================
RecBtn.MouseButton1Click:Connect(toggleRecord)
PlayBtn.MouseButton1Click:Connect(togglePlay)

SaveBtn.MouseButton1Click:Connect(function()
    print("========================================")
    print("COPY THIS JSON:")
    print(HttpService:JSONEncode(actions))
    print("========================================")
end)

LoopBtn.MouseButton1Click:Connect(function()
    loopPlayback = not loopPlayback
    LoopBtn.Text = loopPlayback and "Loop: ON" or "Loop: OFF"
    LoopBtn.BackgroundColor3 = loopPlayback and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(40, 40, 40)
end)

-- ==========================================
-- RECORDING LISTENERS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not isRecording then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local keyName = input.KeyCode.Name
        if string.match(keyName, "^%d$") then
            lastTowerKey = keyName
        elseif keyName == "E" then
            if lastPlacedIndex > 0 then
                actions[lastPlacedIndex].upgrades = actions[lastPlacedIndex].upgrades + 1
                updateStatus()
            end
        elseif keyName == TriggerAbilityKey then
            -- AUTO-ACTIVATE 'G' IN GAME
            vimPressKey(ActualAbilityKey)
            task.wait(0.2)
            isAbilityArmed = true
            print("Ability armed. Click the ground.")
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not isRecording then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mouse = UserInputService:GetMouseLocation()
        if isAbilityArmed then
            -- Record Ability Cast
            table.insert(actions, {
                action = "cast", 
                key = ActualAbilityKey, 
                x = math.floor(mouse.X), 
                y = math.floor(mouse.Y)
            })
            isAbilityArmed = false
            print("Ability Cast recorded.")
            updateStatus()
        else
            -- Record Tower Placement
            table.insert(actions, {
                action = "place", 
                tower = lastTowerKey, 
                x = math.floor(mouse.X), 
                y = math.floor(mouse.Y), 
                upgrades = 0
            })
            lastPlacedIndex = #actions
            print("Tower Placement recorded.")
            updateStatus()
        end
    end
end)

-- ==========================================
-- GLOBAL KEYBINDS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gp)
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode.Name == RecordKey then toggleRecord() end
    if input.KeyCode.Name == PlayKey then togglePlay() end
end)
