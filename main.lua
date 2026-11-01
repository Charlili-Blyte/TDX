--[[
    🟩 TDX MACRO HUB V43 - AUTO-REMAP & CAST
--]]

local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not success then return end

local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

if CoreGui:FindFirstChild("WindUI") then 
    local old = CoreGui:FindFirstChild("WindUI")
    if old:FindFirstChild("TDX Premium") then old["TDX Premium"]:Destroy() end 
end

-- ==========================================
-- 🔑 SETTINGS
-- ==========================================
local RecordKey = "Z"
local PlayKey = "X"
local TriggerAbilityKey = "C" -- Key YOU press
local ActualAbilityKey = "G"  -- Key the GAME receives

local isRecording = false
local isPlaying = false
local loopPlayback = false
local actions = {}
local lastTowerKey = "1"
local lastPlacedIndex = 0
local isAbilityArmed = false
local dragStartX, dragStartY = 0, 0

-- ==========================================
-- 🎨 WINDUI WINDOW
-- ==========================================
local Window = WindUI:CreateWindow({
    Title = "🟩 TDX Premium V43",
    Folder = "TDXPremium",
    Size = UDim2.fromOffset(600, 450),
    Transparent = true, Theme = "Dark", SideBarWidth = 170, HasOutline = false, ToggleKey = "RightShift",
})

local function Notify(title, text)
    pcall(function() WindUI:Notify({ Title = title, Content = text, Duration = 3 }) end)
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

local function vimDrag(startX, startY, endX, endY)
    local cam = workspace.CurrentCamera
    VirtualInputManager:SendMouseMoveEvent(startX, startY, cam)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(startX, startY, 0, true, game, 1)
    task.wait(0.2) 
    VirtualInputManager:SendMouseMoveEvent(endX, endY, cam)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(endX, endY, 0, false, game, 1)
end

-- ==========================================
-- CORE LOGIC
-- ==========================================
local function toggleRecord()
    if isPlaying then return end
    isRecording = not isRecording
    if isRecording then
        actions = {}; lastPlacedIndex = 0; isAbilityArmed = false
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
                    elseif act.action == "cast" then
                        vimPressKey(act.key)
                        task.wait(0.3)
                        vimClick(act.x, act.y)
                        task.wait(0.3)
                    elseif act.action == "drag" then
                        vimPressKey(act.key)
                        task.wait(0.3)
                        vimDrag(act.startX, act.startY, act.endX, act.endY)
                        task.wait(0.3)
                    end
                    task.wait(0.5)
                end
                if loopPlayback and isPlaying then task.wait(5) end
            until not loopPlayback or not isPlaying
            isPlaying = false
            Notify("Player", "✅ Playback Finished")
        end)
    else
        Notify("Player", "⏹ Stopped Playback")
    end
end

-- ==========================================
-- 📄 UI BUTTONS
-- ==========================================
RecTab:Button({ Title = "⏺ Toggle Recording [Z]", Callback = toggleRecord })
RecTab:Button({
    Title = "💾 Print JSON to F9",
    Callback = function()
        if #actions == 0 then return end
        print("========================================")
        print("COPY THIS JSON:")
        print(HttpService:JSONEncode(actions))
        print("========================================")
    end
})
PlayTab:Button({ Title = "▶ Toggle Playback [X]", Callback = togglePlay })
PlayTab:Toggle({ Title = "Loop Playback", Value = false, Callback = function(val) loopPlayback = val end })

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
            end
        elseif keyName == TriggerAbilityKey then
            -- MAGIC FIX: Send 'G' to the game right now so it actually opens the targeting UI!
            vimPressKey(ActualAbilityKey)
            task.wait(0.2) 
            isAbilityArmed = true
            print("Ability armed and activated in-game. Click to place.")
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not isRecording then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mouse = UserInputService:GetMouseLocation()
        if isAbilityArmed then
            dragStartX = math.floor(mouse.X)
            dragStartY = math.floor(mouse.Y)
        else
            table.insert(actions, {
                action = "place", tower = lastTowerKey, x = math.floor(mouse.X), y = math.floor(mouse.Y), upgrades = 0
            })
            lastPlacedIndex = #actions
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp or not isRecording then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if isAbilityArmed then
            local mouse = UserInputService:GetMouseLocation()
            local endX = math.floor(mouse.X)
            local endY = math.floor(mouse.Y)
            
            if math.abs(endX - dragStartX) > 10 or math.abs(endY - dragStartY) > 10 then
                table.insert(actions, {action = "drag", key = ActualAbilityKey, startX = dragStartX, startY = dragStartY, endX = endX, endY = endY})
            else
                table.insert(actions, {action = "cast", key = ActualAbilityKey, x = endX, y = endY})
            end
            isAbilityArmed = false
        end
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

-- Custom UI Toggle (If Right Shift fails)
local uiVisible = true
UserInputService.InputBegan:Connect(function(input, gp)
    if UserInputService:GetFocusedTextBox() then return end
    
    -- Press 'RightControl' to hide/show the UI
    if input.KeyCode == Enum.KeyCode.RightControl then
        uiVisible = not uiVisible
        if uiVisible then
            Window:Open() -- Brings the window back
        else
            Window:Close() -- Hides the window
        end
    end
end)
