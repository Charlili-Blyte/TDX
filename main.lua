--[[
    🟩 TDX MACRO HUB V23 - KEYBIND RESCUE
--]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("🟩 V23 Script Loaded")

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
    Title = "🟩 TDX V23",
    Folder = "TDXMassive",
    Size = UDim2.fromOffset(650, 520),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = false,
    ToggleKey = "RightShift",
})

local function Notify(title, text)
    print("[Notification] " .. title .. ": " .. text)
    pcall(function() Window:Notify({ Title = title, Content = text, Duration = 3 }) end)
end

-- ==========================================
-- ⏺ RECORDER
-- ==========================================
local MacroTab = Window:Tab({ Title = "Recorder", Icon = "disc" })
local state = { recording = false, playing = false, speed = 1.0, events = {}, last_time = 0, loop = false }

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

local function PlayMacro()
    if state.playing then 
        state.playing = false
        Notify("Playback", "Stopped")
        return 
    end
    
    if not _G.StrategyName or not isfile(_G.StrategyName .. ".json") then
        Notify("Error", "File not found!")
        return
    end
    
    local data = HttpService:JSONDecode(readfile(_G.StrategyName .. ".json"))
    state.playing = true
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
        Notify("Playback", "Finished")
    end)
end

local function ToggleRecord()
    state.recording = not state.recording 
    if state.recording then
        state.events = {}; state.last_time = os.clock()
        Notify("Recorder", "Recording started")
    else
        Notify("Recorder", "Recording stopped")
    end
end

MacroTab:Button({ Title = "⏺ Start / Stop Recording [Key: [ ]", Callback = ToggleRecord })
MacroTab:Input({ Title = "Save Name", Placeholder = "Enter Name...", Callback = function(text) _G.StrategyName = text end })

MacroTab:Button({
    Title = "💾 Save Strategy",
    Callback = function()
        if not _G.StrategyName or _G.StrategyName == "" then Notify("Error", "Enter a name!") return end
        local ok = pcall(function() writefile(_G.StrategyName .. ".json", HttpService:JSONEncode(state.events)) end)
        if ok then Notify("Saved", "Saved " .. _G.StrategyName) else Notify("Error", "Failed to write file.") end
    end
})

local files = listfiles() or {}
local macroList = {}
for _, f in ipairs(files) do
    if string.find(f, "%.json$") then table.insert(macroList, (string.gsub(f, "%.json$", ""))) end
end
if #macroList == 0 then table.insert(macroList, "None") end

_G.MacroDropdown = MacroTab:Dropdown({ Title = "Select Strategy", Values = macroList, Callback = function(option) _G.StrategyName = option end })
MacroTab:Slider({ Title = "Playback Speed", Value = { Min = 0.1, Max = 3.0, Default = 1.0 }, Step = 0.1, Callback = function(value) state.speed = value end })
MacroTab:Toggle({ Title = "Loop Playback", Value = false, Callback = function(bool) state.loop = bool end })
MacroTab:Button({ Title = "▶ Play Macro [Key: ]", Callback = PlayMacro })

-- ==========================================
-- ⌨️ THE NEW KEYBINDS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- If the user is typing in the Strategy Name box, don't trigger keybinds
    if UserInputService:GetFocusedTextBox() then return end
    
    -- Press '[' to Record
    if input.KeyCode == Enum.KeyCode.LeftBracket then
        print("Keybind Detected: Left Bracket [")
        ToggleRecord()
        
    -- Press ']' to Play
    elseif input.KeyCode == Enum.KeyCode.RightBracket then
        print("Keybind Detected: Right Bracket ]")
        PlayMacro()
        
    -- Press 'P' to Panic Stop
    elseif input.KeyCode == Enum.KeyCode.P then
        print("Keybind Detected: P")
        state.recording = false
        state.playing = false
        Notify("PANIC", "All macros stopped")
    end
end)
