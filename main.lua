--[[
    🟩 TDX MACRO HUB V26 - ARMORED EDITION
    Fixes: Input drops, Camera spin, UI clicks, Keybinds.
--]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local Window = WindUI:CreateWindow({
    Title = "🟩 TDX V26", Folder = "TDXMassive", Size = UDim2.fromOffset(650, 520),
    Transparent = true, Theme = "Dark", SideBarWidth = 170, HasOutline = false, ToggleKey = "RightShift",
})

local function Notify(title, text)
    pcall(function() Window:Notify({ Title = title, Content = text, Duration = 3 }) end)
end

-- ==========================================
-- ⏺ THE ARMORED RECORDER
-- ==========================================
local MacroTab = Window:Tab({ Title = "Recorder", Icon = "disc" })
local state = { recording = false, playing = false, speed = 1.0, events = {}, loop = false }
local StatusLabel = MacroTab:Paragraph({ Title = "Status", Desc = "⚪ Idle" })

local function UpdateStatus()
    local s = "⚪ Idle"
    if state.recording then s = "🔴 RECORDING..." elseif state.playing then s = "🟢 PLAYING..." end
    pcall(function() StatusLabel:SetDesc(s) end)
end

-- 1. Record Logic (Ignores text boxes, records everything else)
local function add_event(data)
    if not state.recording then return end
    data.time = os.clock()
    table.insert(state.events, data)
end

UserInputService.InputBegan:Connect(function(input)
    if not state.recording then return end
    -- Ignore if user is typing in chat or the UI text box
    if UserInputService:GetFocusedTextBox() then return end 

    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        add_event({t="click", x=input.Position.X, y=input.Position.Y, state="down", btn="left"})
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then 
        add_event({t="click", x=input.Position.X, y=input.Position.Y, state="down", btn="right"})
    elseif input.UserInputType == Enum.UserInputType.Keyboard then 
        add_event({t="key", key=input.KeyCode.Name, state="down"}) 
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if not state.recording then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        add_event({t="click", x=input.Position.X, y=input.Position.Y, state="up", btn="left"})
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then 
        add_event({t="click", x=input.Position.X, y=input.Position.Y, state="up", btn="right"})
    elseif input.UserInputType == Enum.UserInputType.Keyboard then 
        add_event({t="key", key=input.KeyCode.Name, state="up"}) 
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not state.recording then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            if input.Delta.X ~= 0 or input.Delta.Y ~= 0 then
                add_event({t="camera", x=input.Delta.X, y=input.Delta.Y})
            end
        end
    end
end)

-- 2. Playback Logic (High Precision + Safe Camera)
local function precise_wait(duration)
    if duration <= 0 then return end
    local start = os.clock()
    -- Busy-wait loop for exact millisecond precision
    while (os.clock() - start) < duration do
        -- This keeps the thread busy to prevent frame drops
    end
end

local function PlayMacro()
    if state.playing then state.playing = false; UpdateStatus(); return end
    if not _G.StrategyName or not isfile(_G.StrategyName .. ".json") then Notify("Error", "File not found!"); return end
    
    local data = HttpService:JSONDecode(readfile(_G.StrategyName .. ".json"))
    if #data == 0 then Notify("Error", "File is empty."); return end
    
    state.playing = true
    UpdateStatus()
    Notify("Playback", "Playing...")
    
    task.spawn(function()
        local last_event_time = data[1].time or os.clock()
        
        for i, ev in ipairs(data) do
            if not state.playing then break end
            
            -- Calculate delay between events
            local delay = 0
            if i > 1 and ev.time then
                delay = (ev.time - last_event_time) / state.speed
                last_event_time = ev.time
            end
            
            if delay > 0 then precise_wait(delay) end
            
            -- Execute Input
            if ev.t == "key" then
                if ev.state == "down" then keypress(ev.key) else keyrelease(ev.key) end
            elseif ev.t == "click" then
                if ev.state == "down" then
                    if ev.btn == "right" then mouse2press() else mouse1press() end
                else
                    if ev.btn == "right" then mouse2release() else mouse1release() end
                end
            elseif ev.t == "camera" then
                -- CAMERA CLAMP: Prevents massive spins from dropping frames
                local safe_x = math.clamp(ev.x, -100, 100)
                local safe_y = math.clamp(ev.y, -100, 100)
                mousemoverel(safe_x, safe_y)
            end
        end
        
        mouse1release(); mouse2release()
        state.playing = false
        UpdateStatus()
        Notify("Playback", "Finished")
    end)
end

local function ToggleRecord()
    if state.playing then Notify("Error", "Stop playback first!"); return end
    state.recording = not state.recording 
    if state.recording then
        state.events = {}
        Notify("Recorder", "Recording started")
    else
        Notify("Recorder", "Recording stopped")
    end
    UpdateStatus()
end

-- 3. UI Elements
MacroTab:Button({ Title = "⏺ Start / Stop Recording [Key: V]", Callback = ToggleRecord })
local NameInput = MacroTab:Input({ Title = "Save Name", Placeholder = "Enter Name...", Callback = function(text) _G.StrategyName = text end })

MacroTab:Button({
    Title = "💾 Save Strategy",
    Callback = function()
        if not _G.StrategyName or _G.StrategyName == "" then Notify("Error", "Enter a name!"); return end
        if #state.events == 0 then Notify("Error", "Nothing recorded!"); return end
        
        local ok = pcall(function() writefile(_G.StrategyName .. ".json", HttpService:JSONEncode(state.events)) end)
        if ok then 
            Notify("Saved", "Saved " .. _G.StrategyName)
            -- Refresh Dropdown safely
            local files = listfiles() or {}
            local list = {}
            for _, f in ipairs(files) do
                if string.find(f, "%.json$") then table.insert(list, (string.gsub(f, "%.json$", ""))) end
            end
            if _G.MacroDropdown then _G.MacroDropdown:Refresh(list) end
        else 
            Notify("Error", "Failed to save.")
        end
    end
})

-- Dropdown
local files = listfiles() or {}
local macroList = {}
for _, f in ipairs(files) do
    if string.find(f, "%.json$") then table.insert(macroList, (string.gsub(f, "%.json$", ""))) end
end
if #macroList == 0 then table.insert(macroList, "None") end

_G.MacroDropdown = MacroTab:Dropdown({ 
    Title = "Select Saved Strategy", Values = macroList, 
    Callback = function(option) 
        _G.StrategyName = option
        pcall(function() NameInput:SetValue(option) end)
    end 
})

MacroTab:Slider({ Title = "Playback Speed", Value = { Min = 0.1, Max = 3.0, Default = 1.0 }, Step = 0.1, Callback = function(value) state.speed = value end })
MacroTab:Toggle({ Title = "Loop Playback", Value = false, Callback = function(bool) state.loop = bool end })
MacroTab:Button({ Title = "▶ Play Macro [Key: C]", Callback = PlayMacro })

-- ==========================================
-- ⌨️ FIXED KEYBINDS (V, C, N)
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.V then ToggleRecord()
    elseif input.KeyCode == Enum.KeyCode.C then PlayMacro()
    elseif input.KeyCode == Enum.KeyCode.N then
        state.recording = false
        state.playing = false
        UpdateStatus()
        Notify("PANIC", "All stopped")
    end
end)
