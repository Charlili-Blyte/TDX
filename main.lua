--[[
    🟩 TDX MACRO HUB V37 - PREMIUM UI (Remapped Keys)
--]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Cleanup old UIs (Forces a fresh load)
if CoreGui:FindFirstChild("WindUI") then 
    local old = CoreGui:FindFirstChild("WindUI")
    if old:FindFirstChild("TDX Premium") then old["TDX Premium"]:Destroy() end 
end

-- ==========================================
-- 🔑 CUSTOM KEYBIND VARIABLES
-- ==========================================
local RecordKey = "Z"
local PlayKey = "X"

-- This is the magic remap:
-- You press 'C', but the macro sends 'G' to the game.
local TriggerAbilityKey = "C" 
local ActualAbilityKey = "G"

local isRecording = false
local isPlaying = false
local loopPlayback = false
local actions = {}
local lastTowerKey = "1"
local lastPlacedIndex = 0

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
-- 🎨 WINDUI WINDOW
-- ==========================================
local Window = WindUI:CreateWindow({
    Title = "🟩 TDX Premium V37", -- LOOK FOR V37
    Folder = "TDXPremium",
    Size = UDim2.fromOffset(600, 450),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = false,
    ToggleKey = "RightShift",
})

local RecTab = Window:Tab({ Title = "Recorder", Icon = "disc" })
local PlayTab = Window:Tab({ Title = "Player", Icon = "play" })
local KeyTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- ==========================================
-- 🧠 CORE LOGIC
-- ==========================================
local function toggleRecord()
    if isPlaying then return end
    isRecording = not isRecording
    if isRecording then
        actions = {}; lastPlacedIndex = 0
        Window:Notify({ Title = "Recorder", Content = "🔴 Recording Started", Duration = 3 })
    else
        Window:Notify({ Title = "Recorder", Content = "⏹ Recording Stopped (" .. #actions .. " actions)", Duration = 3 })
    end
end

local function togglePlay()
    if isRecording or #actions == 0 then return end
    isPlaying = not isPlaying
    
    if isPlaying then
        Window:Notify({ Title = "Player", Content = "▶ Playing Macro...", Duration = 3 })
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
                        -- It plays back the ActualAbilityKey (G)
                        vimPressKey(act.key)
                        task.wait(0.3)
                    end
                    task.wait(0.5)
                end
                if loopPlayback and isPlaying then 
                    Window:Notify({ Title = "Player", Content = "🔄 Looping...", Duration = 2 })
                    task.wait(5) 
                end
            until not loopPlayback or not isPlaying
            
            isPlaying = false
            Window:Notify({ Title = "Player", Content = "✅ Playback Finished", Duration = 3 })
        end)
    else
        Window:Notify({ Title = "Player", Content = "⏹ Stopped Playback", Duration = 3 })
    end
end

-- ==========================================
-- 📄 TAB 1: RECORDER
-- ==========================================
RecTab:Paragraph({ Title = "Action Recorder", Desc = "Records tower placements and upgrades without moving your physical mouse." })
RecTab:Button({ Title = "⏺ Toggle Recording [Z]", Callback = toggleRecord })

RecTab:Button({
    Title = "💾 Print JSON to F9",
    Callback = function()
        if #actions == 0 then return end
        print("========================================")
        print("COPY THIS JSON:")
        print(HttpService:JSONEncode(actions))
        print("========================================")
        Window:Notify({ Title = "Saved", Content = "JSON printed to console.", Duration = 3 })
    end
})

-- ==========================================
-- 📄 TAB 2: PLAYER
-- ==========================================
PlayTab:Paragraph({ Title = "Macro Player", Desc = "Plays back the recorded actions. Your physical cursor will NOT move." })
PlayTab:Button({ Title = "▶ Toggle Playback [X]", Callback = togglePlay })
PlayTab:Toggle({
    Title = "Loop Playback",
    Value = false,
    Callback = function(val) loopPlayback = val end
})

-- ==========================================
-- 📄 TAB 3: SETTINGS
-- ==========================================
KeyTab:Paragraph({ Title = "Keybinds", Desc = "You press 'C' to record the ability, but the macro will press 'G' during playback." })

KeyTab:Input({ Title = "Record Key", Placeholder = RecordKey, Callback = function(txt) 
    if #txt > 0 then RecordKey = string.upper(txt) end 
end})

KeyTab:Input({ Title = "Play Key", Placeholder = PlayKey, Callback = function(txt) 
    if #txt > 0 then PlayKey = string.upper(txt) end 
end})

-- ==========================================
-- 🧠 RECORDING LISTENERS
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
            
        -- ABILITY LOGIC: Press C, Save as G
        elseif keyName == TriggerAbilityKey then
            table.insert(actions, {action = "ability", key = ActualAbilityKey})
            print("Ability recorded (Pressing C, saving as G)")
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

print("✅ V37 Loaded successfully! Check top of UI.")
