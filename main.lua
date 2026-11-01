--[[
    🟩 TDX MACRO HUB V40 - FINAL STABLE
--]]

local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not success then
    print("🔴 ERROR: Failed to download WindUI.")
    return
end

local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- Cleanup old UIs
if CoreGui:FindFirstChild("WindUI") then 
    local old = CoreGui:FindFirstChild("WindUI")
    if old:FindFirstChild("TDX Premium") then old["TDX Premium"]:Destroy() end 
end

-- ==========================================
-- 🔑 SETTINGS & REMAPPED KEYS
-- ==========================================
local RecordKey = "Z"
local PlayKey = "X"

-- Press C, but the macro sends G
local TriggerAbilityKey = "C" 
local ActualAbilityKey = "G" 

local isRecording = false
local isPlaying = false
local loopPlayback = false
local actions = {}
local lastTowerKey = "1"
local lastPlacedIndex = 0

-- ==========================================
-- 🎨 WINDUI WINDOW
-- ==========================================
local Window = WindUI:CreateWindow({
    Title = "🟩 TDX Premium V40",
    Folder = "TDXPremium",
    Size = UDim2.fromOffset(600, 450),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = false,
    ToggleKey = "RightShift",
})

-- 🛡️ SAFE NOTIFY (This prevents the crash)
local function Notify(title, text)
    pcall(function()
        WindUI:Notify({ Title = title, Content = text, Duration = 3 })
    end)
end

local RecTab = Window:Tab({ Title = "Recorder", Icon = "disc" })
local PlayTab = Window:Tab({ Title = "Player", Icon = "play" })

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
-- CORE LOGIC
-- ==========================================
local function toggleRecord()
    if isPlaying then return end
    isRecording = not isRecording
    if isRecording then
        actions = {}; lastPlacedIndex = 0
        Notify("Recorder", "🔴 Recording Started")
    else
        Notify("Recorder", "⏹ Recording Stopped (" .. #actions .. " actions)")
    end
end

local function togglePlay()
    if isRecording or #actions == 0 then return end
    isPlaying = not isPlaying
    
    if isPlaying then
        Notify("Player", "▶ Playing Macro...")
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
                        vimPressKey(act.key) -- This presses 'G'
                        task.wait(0.3)
                    end
                    task.wait(0.5)
                end
                if loopPlayback and isPlaying then 
                    Notify("Player", "🔄 Looping...")
                    task.wait(5) 
                end
            until not loopPlayback or not isPlaying
            
            isPlaying = false
            Notify("Player", "✅ Playback Finished")
        end)
    else
        Notify("Player", "⏹ Stopped Playback")
    end
end

-- ==========================================
-- 📄 TAB 1: RECORDER
-- ==========================================
RecTab:Paragraph({ Title = "Action Recorder", Desc = "Press Z to record. Press C to log an ability (it will press G on playback)." })
RecTab:Button({ Title = "⏺ Toggle Recording [Z]", Callback = toggleRecord })

RecTab:Button({
    Title = "💾 Print JSON to F9",
    Callback = function()
        if #actions == 0 then return end
        print("========================================")
        print("COPY THIS JSON:")
        print(HttpService:JSONEncode(actions))
        print("========================================")
        Notify("Saved", "JSON printed to F9 console.")
    end
})

-- ==========================================
-- 📄 TAB 2: PLAYER
-- ==========================================
PlayTab:Paragraph({ Title = "Macro Player", Desc = "Plays back actions. Cursor will NOT move." })
PlayTab:Button({ Title = "▶ Toggle Playback [X]", Callback = togglePlay })
PlayTab:Toggle({
    Title = "Loop Playback",
    Value = false,
    Callback = function(val) loopPlayback = val end
})

-- ==========================================
-- 🧠 RECORDING LISTENERS
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
                print("Upgrade recorded for Tower #" .. lastPlacedIndex)
            end
        elseif keyName == TriggerAbilityKey then
            -- Press C, save as G
            table.insert(actions, {action = "ability", key = ActualAbilityKey})
            print("Ability recorded (Pressed C, saved as G)")
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
-- ⌨️ GLOBAL KEYBINDS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gp)
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode.Name == RecordKey then toggleRecord() end
    if input.KeyCode.Name == PlayKey then togglePlay() end
end)

print("✅ V40 Loaded successfully!")
