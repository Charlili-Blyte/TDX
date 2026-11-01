--[[
    🟩 TDX COORDINATE RECORDER V34 (Zero Physical Movement)
    Records your exact X/Y clicks, Upgrades, and Abilities. Plays back completely in the background.
--]]

local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Cleanup old UIs
if CoreGui:FindFirstChild("TDX_ActionRecorder") then CoreGui.TDX_ActionRecorder:Destroy() end

-- ==========================================
-- 🔑 CUSTOM KEYBIND VARIABLES
-- ==========================================
local RecordKey = "F7"
local PlayKey = "F8"
local AbilityKey = "G" -- Change this to whatever opens your tower menu

local isRecording = false
local isPlaying = false
local loopPlayback = false
local actions = {}
local lastTowerKey = "1"
local lastPlacedIndex = 0

-- VIM Key Presser (No physical keyboard used)
local function vimPressKey(keyName)
    local key = Enum.KeyCode[keyName]
    if key then
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
end

-- VIM Mouse Clicker (No physical mouse moved)
local function vimClick(x, y)
    local cam = workspace.CurrentCamera
    VirtualInputManager:SendMouseMoveEvent(x, y, cam)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

-- ==========================================
-- 🎨 UI CREATION
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TDX_ActionRecorder"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 420)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", MainFrame)
stroke.Color = Color3.fromRGB(34, 197, 94)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "🟩 TDX Coordinate Recorder"
Title.TextColor3 = Color3.fromRGB(34, 197, 94)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0, 30)
Status.BackgroundTransparency = 1
Status.Text = "Status: Idle"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.Parent = MainFrame

local RecBtn = Instance.new("TextButton")
RecBtn.Size = UDim2.new(1, -20, 0, 35)
RecBtn.Position = UDim2.new(0, 10, 0, 60)
RecBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
RecBtn.Text = "⏺ START RECORDING"
RecBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RecBtn.Font = Enum.Font.GothamBold
RecBtn.Parent = MainFrame
Instance.new("UICorner", RecBtn).CornerRadius = UDim.new(0, 6)

local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(1, -20, 0, 35)
SaveBtn.Position = UDim2.new(0, 10, 0, 105)
SaveBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
SaveBtn.Text = "💾 PRINT JSON TO F9"
SaveBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.Parent = MainFrame
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)

local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(1, -20, 0, 35)
PlayBtn.Position = UDim2.new(0, 10, 0, 150)
PlayBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
PlayBtn.Text = "▶ PLAY MACRO (No Cursor Move)"
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.Parent = MainFrame
Instance.new("UICorner", PlayBtn).CornerRadius = UDim.new(0, 6)

local LoopToggle = Instance.new("TextButton")
LoopToggle.Size = UDim2.new(1, -20, 0, 30)
LoopToggle.Position = UDim2.new(0, 10, 0, 195)
LoopToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
LoopToggle.Text = "Loop: OFF"
LoopToggle.TextColor3 = Color3.fromRGB(200, 200, 200)
LoopToggle.Font = Enum.Font.GothamBold
LoopToggle.Parent = MainFrame
Instance.new("UICorner", LoopToggle).CornerRadius = UDim.new(0, 6)

local SettingsLabel = Instance.new("TextLabel")
SettingsLabel.Size = UDim2.new(1, 0, 0, 20)
SettingsLabel.Position = UDim2.new(0, 0, 0, 235)
SettingsLabel.BackgroundTransparency = 1
SettingsLabel.Text = "--- Keybind Settings ---"
SettingsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
SettingsLabel.Font = Enum.Font.GothamBold
SettingsLabel.Parent = MainFrame

local function createSettingBox(text, defaultVal, yPos, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 120, 0, 25)
    label.Position = UDim2.new(0, 10, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = MainFrame

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 100, 0, 25)
    box.Position = UDim2.new(1, -110, 0, yPos)
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = defaultVal
    box.Font = Enum.Font.Code
    box.Parent = MainFrame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    
    box.FocusLost:Connect(function()
        local txt = string.upper(box.Text)
        if #txt > 0 then callback(txt); box.Text = txt end
    end)
end

createSettingBox("Record Toggle Key:", RecordKey, 260, function(val) RecordKey = val end)
createSettingBox("Play Toggle Key:", PlayKey, 290, function(val) PlayKey = val end)
createSettingBox("Ability Key:", AbilityKey, 320, function(val) AbilityKey = val end)

-- ==========================================
-- 🧠 RECORDING LOGIC
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not isRecording then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local keyName = input.KeyCode.Name
        
        -- Tower Selection
        if string.match(keyName, "^%d$") then
            lastTowerKey = keyName
        -- Upgrades
        elseif keyName == "E" then
            if lastPlacedIndex > 0 then
                actions[lastPlacedIndex].upgrades = actions[lastPlacedIndex].upgrades + 1
                print("Upgrade recorded for Tower #" .. lastPlacedIndex)
            end
        -- Abilities
        elseif keyName == AbilityKey then
            table.insert(actions, {action = "ability", key = keyName})
            print("Ability recorded: " .. keyName)
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
        print("Placement recorded: Tower " .. lastTowerKey .. " at " .. math.floor(mouse.X) .. ", " .. math.floor(mouse.Y))
    end
end)

-- ==========================================
-- UI BUTTON CONNECTIONS
-- ==========================================
RecBtn.MouseButton1Click:Connect(function()
    if isPlaying then return end
    isRecording = not isRecording
    if isRecording then
        actions = {}; lastPlacedIndex = 0
        RecBtn.Text = "⏹ STOP RECORDING"
        RecBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        Status.Text = "Status: 🔴 RECORDING..."
        Status.TextColor3 = Color3.fromRGB(200, 50, 50)
    else
        RecBtn.Text = "⏺ START RECORDING"
        RecBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        Status.Text = "Status: Idle (" .. #actions .. " actions)"
        Status.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

SaveBtn.MouseButton1Click:Connect(function()
    print("========================================")
    print("COPY THIS JSON:")
    print("========================================")
    print(HttpService:JSONEncode(actions))
    print("========================================")
    Status.Text = "Status: JSON printed to F9!"
end)

LoopToggle.MouseButton1Click:Connect(function()
    loopPlayback = not loopPlayback
    if loopPlayback then
        LoopToggle.Text = "Loop: ON"
        LoopToggle.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
        LoopToggle.TextColor3 = Color3.fromRGB(0,0,0)
    else
        LoopToggle.Text = "Loop: OFF"
        LoopToggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        LoopToggle.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

-- ==========================================
-- ▶ ZERO-MOVEMENT PLAYBACK
-- ==========================================
PlayBtn.MouseButton1Click:Connect(function()
    if isRecording or #actions == 0 then return end
    
    isPlaying = not isPlaying
    if isPlaying then
        PlayBtn.Text = "⏹ STOP PLAYING"
        PlayBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        Status.Text = "Status: 🟢 PLAYING (VIM Mode)..."
        Status.TextColor3 = Color3.fromRGB(34, 197, 94)
        
        task.spawn(function()
            repeat
                for i, act in ipairs(actions) do
                    if not isPlaying then break end
                    
                    if act.action == "place" then
                        vimPressKey(act.tower)
                        task.wait(0.2)
                        vimClick(act.x, act.y) -- Clicks without moving your real mouse
                        task.wait(0.2)
                        
                        for u = 1, act.upgrades do
                            vimPressKey("E")
                            task.wait(0.3)
                        end
                        
                    elseif act.action == "ability" then
                        vimPressKey(act.key)
                        task.wait(0.3)
                    end
                    task.wait(0.5)
                end
                
                if loopPlayback and isPlaying then
                    Status.Text = "Status: 🔄 Looping (Waiting 5s)..."
                    task.wait(5)
                end
            until not loopPlayback or not isPlaying
            
            isPlaying = false
            PlayBtn.Text = "▶ PLAY MACRO (No Cursor Move)"
            PlayBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
            Status.Text = "Status: Idle"
            Status.TextColor3 = Color3.fromRGB(200, 200, 200)
        end)
    else
        PlayBtn.Text = "▶ PLAY MACRO (No Cursor Move)"
        PlayBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
        Status.Text = "Status: Stopped Playback"
    end
end)

-- ==========================================
-- ⌨️ GLOBAL LISTENER
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gp)
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode.Name == RecordKey then RecBtn:Activate() end
    if input.KeyCode.Name == PlayKey then PlayBtn:Activate() end
end)
