--[[
    🟩 TDX MACRO HUB V35 - NATIVE TABS & COORDINATE RECORDER
    No External Libraries. 100% Native Roblox UI.
--]]

local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Cleanup old UIs
if CoreGui:FindFirstChild("TDX_MainUI") then CoreGui.TDX_MainUI:Destroy() end
if CoreGui:FindFirstChild("TDX_ActionRecorder") then CoreGui.TDX_ActionRecorder:Destroy() end

-- ==========================================
-- 🔑 SETTINGS
-- ==========================================
local RecordKey = "Z"
local PlayKey = "X"
local AbilityKey = "G"
local isRecording = false
local isPlaying = false
local loopPlayback = false
local actions = {}
local lastTowerKey = "1"
local lastPlacedIndex = 0

-- ==========================================
-- 🧠 HELPER FUNCTIONS (Zero physical movement)
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
ScreenGui.Name = "TDX_MainUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 400)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", MainFrame)
stroke.Color = Color3.fromRGB(34, 197, 94)
stroke.Thickness = 1

-- Top Bar
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Title.Text = "🟩 TDX MACRO V35"
Title.TextColor3 = Color3.fromRGB(34, 197, 94)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

-- Tabs
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 30)
TabBar.Position = UDim2.new(0, 10, 0, 45)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -20, 1, -85)
ContentArea.Position = UDim2.new(0, 10, 0, 80)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local function CreateTabButton(text, xPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 75, 1, 0)
    btn.Position = UDim2.new(0, xPos, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    return btn
end

local RecTabBtn = CreateTabButton("Recorder", 0)
local PlayTabBtn = CreateTabButton("Player", 80)
local KeyTabBtn = CreateTabButton("Settings", 160)
local ScanTabBtn = CreateTabButton("Scanner", 240)

-- Frames
local function CreatePage()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.Visible = false
    f.Parent = ContentArea
    return f
end

local RecPage = CreatePage()
local PlayPage = CreatePage()
local KeyPage = CreatePage()
local ScanPage = CreatePage()

local function SwitchTab(page, btn)
    RecPage.Visible = false; PlayPage.Visible = false; KeyPage.Visible = false; ScanPage.Visible = false
    RecTabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35); PlayTabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    KeyTabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35); ScanTabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    
    page.Visible = true
    btn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
end

RecTabBtn.MouseButton1Click:Connect(function() SwitchTab(RecPage, RecTabBtn) end)
PlayTabBtn.MouseButton1Click:Connect(function() SwitchTab(PlayPage, PlayTabBtn) end)
KeyTabBtn.MouseButton1Click:Connect(function() SwitchTab(KeyPage, KeyTabBtn) end)
ScanTabBtn.MouseButton1Click:Connect(function() SwitchTab(ScanPage, ScanTabBtn) end)

-- ==========================================
-- 📄 PAGE 1: RECORDER
-- ==========================================
local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, 0, 0, 20)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Status: Idle (0 actions)"
StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusText.Font = Enum.Font.Gotham
StatusText.TextSize = 12
StatusText.Parent = RecPage

local RecBtn = Instance.new("TextButton")
RecBtn.Size = UDim2.new(1, 0, 0, 40)
RecBtn.Position = UDim2.new(0, 0, 0, 30)
RecBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
RecBtn.Text = "⏺ START RECORDING (Key: Z)"
RecBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RecBtn.Font = Enum.Font.GothamBold
RecBtn.Parent = RecPage
Instance.new("UICorner", RecBtn).CornerRadius = UDim.new(0, 6)

local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(1, 0, 0, 40)
SaveBtn.Position = UDim2.new(0, 0, 0, 80)
SaveBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
SaveBtn.Text = "💾 PRINT JSON TO F9"
SaveBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.Parent = RecPage
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)

local HelpText = Instance.new("TextLabel")
HelpText.Size = UDim2.new(1, 0, 0, 60)
HelpText.Position = UDim2.new(0, 0, 0, 130)
HelpText.BackgroundTransparency = 1
HelpText.Text = "How to use: Click Start, place a tower, press E twice, press G. Click Stop. Click Print to see JSON."
HelpText.TextColor3 = Color3.fromRGB(150, 150, 150)
HelpText.Font = Enum.Font.Gotham
HelpText.TextSize = 11
HelpText.TextWrapped = true
HelpText.Parent = RecPage

-- ==========================================
-- 📄 PAGE 2: PLAYER
-- ==========================================
local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(1, 0, 0, 40)
PlayBtn.Position = UDim2.new(0, 0, 0, 0)
PlayBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
PlayBtn.Text = "▶ PLAY MACRO (Key: X)"
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.Parent = PlayPage
Instance.new("UICorner", PlayBtn).CornerRadius = UDim.new(0, 6)

local LoopBtn = Instance.new("TextButton")
LoopBtn.Size = UDim2.new(1, 0, 0, 30)
LoopBtn.Position = UDim2.new(0, 0, 0, 50)
LoopBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
LoopBtn.Text = "Loop: OFF"
LoopBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
LoopBtn.Font = Enum.Font.GothamBold
LoopBtn.Parent = PlayPage
Instance.new("UICorner", LoopBtn).CornerRadius = UDim.new(0, 6)

local PlayStatus = Instance.new("TextLabel")
PlayStatus.Size = UDim2.new(1, 0, 0, 20)
PlayStatus.Position = UDim2.new(0, 0, 0, 90)
PlayStatus.BackgroundTransparency = 1
PlayStatus.Text = "Ready to play."
PlayStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
PlayStatus.Font = Enum.Font.Gotham
PlayStatus.Parent = PlayPage

-- ==========================================
-- 📄 PAGE 3: KEYBINDS
-- ==========================================
local function CreateKeybindInput(text, defaultVal, yPos, callback)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 150, 0, 25)
    lbl.Position = UDim2.new(0, 0, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = KeyPage

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 80, 0, 25)
    box.Position = UDim2.new(1, -80, 0, yPos)
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = defaultVal
    box.Font = Enum.Font.Code
    box.Parent = KeyPage
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    
    box.FocusLost:Connect(function()
        local txt = string.upper(box.Text)
        if #txt > 0 then callback(txt); box.Text = txt end
    end)
end

CreateKeybindInput("Record Key:", RecordKey, 10, function(val) RecordKey = val; RecBtn.Text = "⏺ START RECORDING (Key: "..val..")" end)
CreateKeybindInput("Play Key:", PlayKey, 45, function(val) PlayKey = val; PlayBtn.Text = "▶ PLAY MACRO (Key: "..val..")" end)
CreateKeybindInput("Ability Key:", AbilityKey, 80, function(val) AbilityKey = val end)

-- ==========================================
-- 📄 PAGE 4: SCANNER
-- ==========================================
local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(1, 0, 0, 40)
ScanBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
ScanBtn.Text = "🔍 START AUTO-SCAN"
ScanBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.Parent = ScanPage
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)

local ScanStatus = Instance.new("TextLabel")
ScanStatus.Size = UDim2.new(1, 0, 0, 60)
ScanStatus.Position = UDim2.new(0, 0, 0, 50)
ScanStatus.BackgroundTransparency = 1
ScanStatus.Text = "Needs 10k+ Cash. Sweeps screen for valid spots."
ScanStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
ScanStatus.Font = Enum.Font.Gotham
ScanStatus.TextWrapped = true
ScanStatus.Parent = ScanPage

-- ==========================================
-- 🧠 CORE LOGIC
-- ==========================================
local function updateStatus()
    if isRecording then
        StatusText.Text = "Status: 🔴 RECORDING (" .. #actions .. " actions)"
        StatusText.TextColor3 = Color3.fromRGB(200, 50, 50)
    else
        StatusText.Text = "Status: Idle (" .. #actions .. " actions)"
        StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end

-- Record Inputs
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
        elseif keyName == AbilityKey then
            table.insert(actions, {action = "ability", key = keyName})
            updateStatus()
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not isRecording then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mouse = UserInputService:GetMouseLocation()
        table.insert(actions, {
            action = "place", 
            tower = lastTowerKey, 
            x = math.floor(mouse.X), 
            y = math.floor(mouse.Y), 
            upgrades = 0
        })
        lastPlacedIndex = #actions
        updateStatus()
    end
end)

-- Buttons
RecBtn.MouseButton1Click:Connect(function()
    if isPlaying then return end
    isRecording = not isRecording
    if isRecording then
        actions = {}; lastPlacedIndex = 0
        RecBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        RecBtn.Text = "⏹ STOP RECORDING"
    else
        RecBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        RecBtn.Text = "⏺ START RECORDING (Key: "..RecordKey..")"
    end
    updateStatus()
end)

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

PlayBtn.MouseButton1Click:Connect(function()
    if isRecording or #actions == 0 then return end
    isPlaying = not isPlaying
    if isPlaying then
        PlayBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        PlayBtn.Text = "⏹ STOP PLAYING"
        PlayStatus.Text = "Playing..."
        
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
                    elseif act.action == "ability" then
                        vimPressKey(act.key)
                        task.wait(0.3)
                    end
                    task.wait(0.5)
                end
                if loopPlayback and isPlaying then task.wait(5) end
            until not loopPlayback or not isPlaying
            isPlaying = false
            PlayBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
            PlayBtn.Text = "▶ PLAY MACRO (Key: "..PlayKey..")"
            PlayStatus.Text = "Ready to play."
        end)
    else
        PlayBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
        PlayBtn.Text = "▶ PLAY MACRO (Key: "..PlayKey..")"
        PlayStatus.Text = "Stopped."
    end
end)

-- Global Keybinds
UserInputService.InputBegan:Connect(function(input, gp)
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode.Name == RecordKey then RecBtn:Activate() end
    if input.KeyCode.Name == PlayKey then PlayBtn:Activate() end
end)

-- Start on Recorder Tab
SwitchTab(RecPage, RecTabBtn)
