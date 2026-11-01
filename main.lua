--[[
    🟩 TDX MACRO HUB V24 - CLEAN RECORDER & STATUS
--]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("🟩 V24 Script Loaded")

-- ==========================================
-- 🛡️ SECURITY
-- ==========================================
pcall(function()
    local oldKick = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() == "Kick" then return end
        return oldKick(self, ...)
    end)
end)

-- ==========================================
-- 🎨 WINDUI WINDOW
-- ==========================================
local Window = WindUI:CreateWindow({
    Title = "🟩 TDX V24",
    Folder = "TDXMassive",
    Size = UDim2.fromOffset(650, 520),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = false,
    ToggleKey = "RightShift",
})

local function Notify(title, text)
    print("[TDX] " .. title .. ": " .. text)
    pcall(function() Window:Notify({ Title = title, Content = text, Duration = 3 }) end)
end

-- ==========================================
-- ⏺ RECORDER WITH LIVE STATUS
-- ==========================================
local MacroTab = Window:Tab({ Title = "Recorder", Icon = "disc" })
local state = { recording = false, playing = false, speed = 1.0, events = {}, last_time = 0, loop = false }

-- 1. Create the Status Label
local StatusParagraph = MacroTab:Paragraph({ Title = "Status:", Desc = "⚪ Idle" })

local function UpdateStatus()
    if state.recording then
        pcall(function() StatusParagraph:SetDesc("🔴 RECORDING...") end)
    elseif state.playing then
        pcall(function() StatusParagraph:SetDesc("🟢 PLAYING...") end)
    else
        pcall(function() StatusParagraph:SetDesc("⚪ Idle") end)
    end
end

-- 2. Recording Logic
local function add_event(data)
    if not state.recording then return end
    local now = os.clock()
    data.delay = now - state.last_time
    state.last_time = now
    table.insert(state.events, data)
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not state.recording then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        add_event({t="click", x=input.Position.X, y=input.Position.Y, state="down"})
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then 
        add_event({t="click", button="right", state="down"})
    elseif input.UserInputType == Enum.UserInputType.Keyboard then 
        add_event({t="key", key=input.KeyCode.Name, state="down"}) 
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp or not state.recording then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        add_event({t="click", x=input.Position.X, y=input.Position.Y, state="up"})
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then 
        add_event({t="click", button="right", state="up"})
    elseif input.UserInputType == Enum.UserInputType.Keyboard then 
        add_event({t="key", key=input.KeyCode.Name, state="up"}) 
    end
end)

UserInputService.InputChanged:Connect(function(input, gp)
    if gp or not state.recording then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            if input.Delta.X ~= 0 or input.Delta.Y ~= 0 then
                add_event({t="camera", x=input.Delta.X, y=input.Delta.Y})
            end
        end
    end
end)

-- 3. Playback Logic
local function PlayMacro()
    if state.playing then 
        state.playing = false
        UpdateStatus()
        Notify("Playback", "Stopped")
        return 
    end
    
    -- Check if name is valid
    if not _G.StrategyName or _G.StrategyName == "" or _G.StrategyName == "None" then
        Notify("Error", "Please type a name or select a strategy first!")
        return
    end
    
    -- Check if file actually exists
    if not isfile(_G.StrategyName .. ".json") then
        Notify("Error", "File '" .. _G.StrategyName .. ".json' not found! Did you save it?")
        return
    end
    
    local data = HttpService:JSONDecode(readfile(_G.StrategyName .. ".json"))
    state.playing = true
    UpdateStatus()
    Notify("Playback", "Playing...")
    
    task.spawn(function()
        while state.playing do
            for _, ev in ipairs(data) do
                if not state.playing then break end
                task.wait(ev.delay / state.speed)
                
                if ev.t == "key" then
                    if ev.state == "down" then keypress(ev.key) else keyrelease(ev.key) end
                elseif ev.t == "click" then
                    if ev.state == "down" then
                        if ev.button == "right" then mouse2press() else mouse1press() end
                    else
                        if ev.button == "right" then mouse2release() else mouse1release() end
                    end
                elseif ev.t == "camera" then
                    mousemoverel(ev.x, ev.y)
                end
            end
            if not state.loop then break end
            task.wait(1)
        end
        mouse1release(); mouse2release()
        state.playing = false
        UpdateStatus()
        Notify("Playback", "Finished")
    end)
end

local function ToggleRecord()
    if state.playing then
        Notify("Error", "Stop playback before recording!")
        return
    end
    
    state.recording = not state.recording 
    if state.recording then
        state.events = {}; state.last_time = os.clock()
        Notify("Recorder", "Recording started")
    else
        Notify("Recorder", "Recording stopped")
    end
    UpdateStatus()
end

-- 4. UI Elements
MacroTab:Button({ Title = "⏺ Start / Stop Recording [Key: [ ]", Callback = ToggleRecord })

-- File Name Input
local NameInput = MacroTab:Input({ 
    Title = "Save / Load Name", 
    Placeholder = "Type name here...", 
    Callback = function(text) _G.StrategyName = text end 
})

-- Save Button
MacroTab:Button({
    Title = "💾 Save Strategy",
    Callback = function()
        if not _G.StrategyName or _G.StrategyName == "" or _G.StrategyName == "None" then 
            Notify("Error", "Enter a name first!") 
            return 
        end
        if #state.events == 0 then
            Notify("Error", "No events recorded! Click Record first.")
            return
        end
        
        local ok = pcall(function() writefile(_G.StrategyName .. ".json", HttpService:JSONEncode(state.events)) end)
        if ok then 
            Notify("Saved", "Saved " .. _G.StrategyName .. ".json")
        else 
            Notify("Error", "Failed to write file.") 
        end
    end
})

MacroTab:Divider()

-- Dropdown Setup
local files = listfiles() or {}
local macroList = {}
for _, f in ipairs(files) do
    if string.find(f, "%.json$") then table.insert(macroList, (string.gsub(f, "%.json$", ""))) end
end
if #macroList == 0 then table.insert(macroList, "None") end

-- Dropdown Element
_G.MacroDropdown = MacroTab:Dropdown({ 
    Title = "Select Saved Strategy", 
    Values = macroList, 
    Callback = function(option) 
        _G.StrategyName = option 
        -- Auto-fill the text box so you know what's selected
        pcall(function() NameInput:SetValue(option) end)
    end 
})

MacroTab:Slider({ Title = "Playback Speed", Value = { Min = 0.1, Max = 3.0, Default = 1.0 }, Step = 0.1, Callback = function(value) state.speed = value end })
MacroTab:Toggle({ Title = "Loop Playback", Value = false, Callback = function(bool) state.loop = bool end })
MacroTab:Button({ Title = "▶ Play Macro [Key: ]", Callback = PlayMacro })

-- ==========================================
-- ⌨️ KEYBINDS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if UserInputService:GetFocusedTextBox() then return end
    
    if input.KeyCode == Enum.KeyCode.LeftBracket then
        print("Keybind Detected: [")
        ToggleRecord()
    elseif input.KeyCode == Enum.KeyCode.RightBracket then
        print("Keybind Detected: ]")
        PlayMacro()
    elseif input.KeyCode == Enum.KeyCode.P then
        print("Keybind Detected: P")
        state.recording = false
        state.playing = false
        UpdateStatus()
        Notify("PANIC", "All stopped")
    end
end)
