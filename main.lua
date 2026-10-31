--[[
    🟩 TDX MACRO HUB V13 - FINAL EDITION
    Features: WindUI, Background TDX Auto-Join, Pro Recorder, Global Keybinds.
--]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

-- ==========================================
-- 🛡️ SECURITY (ANTI-KICK / ANTI-AFK)
-- ==========================================
pcall(function()
    local oldKick = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() == "Kick" then return end
        return oldKick(self, ...)
    end)
end)

task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- ==========================================
-- 🎨 WINDUI WINDOW
-- ==========================================
local Window = WindUI:CreateWindow({
    Title = "🟩 TDX Premium",
    Folder = "TDXHub",
    Size = UDim2.fromOffset(620, 480),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 180,
    HasOutline = false,
})

local JoinsTab = Window:Tab({ Title = "Joins", Icon = "globe" })
local MacroTab = Window:Tab({ Title = "Recorder", Icon = "disc" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- ==========================================
-- 🌐 TDX SPECIFIC BACKGROUND AUTO-JOIN
-- ==========================================
local function fire_tdx_button(btn_name)
    local btn = playerGui:FindFirstChild(btn_name, true)
    if not btn then return false end

    local fired = false

    -- METHOD 1: getconnections
    if getconnections then
        for _, signal_name in ipairs({"MouseButton1Click", "MouseButton1Down", "Activated"}) do
            local signal = btn[signal_name]
            if signal then
                local conns = getconnections(signal)
                for _, conn in pairs(conns) do
                    if conn.Enabled then
                        pcall(function() conn:Fire() end)
                        fired = true
                    end
                end
            end
        end
    end

    -- METHOD 2: firesignal
    if not fired and firesignal then
        pcall(function() firesignal(btn.MouseButton1Click); fired = true end)
        pcall(function() firesignal(btn.MouseButton1Down); fired = true end)
        pcall(function() firesignal(btn.Activated); fired = true end)
    end

    -- METHOD 3: VirtualInputManager (Background)
    if not fired then
        local x = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 2)
        local y = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2)
        VirtualInputManager:SendMouseMoveEvent(x, y, Camera)
        task.wait(0.1)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.1)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
        fired = true
    end
    return fired
end

local function TDX_Join(mode_name)
    Window:Notify({ Title = "TDX Auto-Join", Content = "Joining " .. mode_name .. "...", Duration = 3 })
    
    if not fire_tdx_button("PlaySolo") then
        Window:Notify({ Title = "Error", Content = "PlaySolo button not found.", Duration = 3 })
        return 
    end
    task.wait(1.5)

    if not fire_tdx_button("Survival") then
        Window:Notify({ Title = "Error", Content = "Survival button not found.", Duration = 3 })
        return 
    end
    task.wait(1.5)

    if not fire_tdx_button(mode_name) then
        Window:Notify({ Title = "Error", Content = mode_name .. " button not found.", Duration = 3 })
        return 
    end
    
    Window:Notify({ Title = "TDX Auto-Join", Content = "Joined " .. mode_name .. "!", Duration = 3 })
end

JoinsTab:Button({ Title = "▶ Play Solo (Easy)", Callback = function() task.spawn(function() TDX_Join("Easy") end) end })
JoinsTab:Button({ Title = "▶ Play Solo (Intermediate)", Callback = function() task.spawn(function() TDX_Join("Intermediate") end) end })
JoinsTab:Button({ Title = "▶ Play Solo (Elite)", Callback = function() task.spawn(function() TDX_Join("Elite") end) end })
JoinsTab:Button({ Title = "▶ Play Solo (Expert)", Callback = function() task.spawn(function() TDX_Join("Expert") end) end })
JoinsTab:Button({ Title = "▶ Play Solo (Nightmare)", Callback = function() task.spawn(function() TDX_Join("Nightmare") end) end })

JoinsTab:Divider()
JoinsTab:Input({ Title = "Custom Mode", Placeholder = "e.g. Endless, Coop", Callback = function(text) _G.CustomMode = text end })
JoinsTab:Button({
    Title = "🌐 Custom Join",
    Callback = function()
        if _G.CustomMode and _G.CustomMode ~= "" then
            task.spawn(function() TDX_Join(_G.CustomMode) end)
        end
    end
})

-- ==========================================
-- ⏺ PRO RECORDER ENGINE
-- ==========================================
local state = { recording = false, playing = false, speed = 1.0, events = {} }
local last_time = 0

local function precise_sleep(duration)
    if duration <= 0 then return end
    local target = os.clock() + duration
    if duration > 0.002 then task.wait(duration - 0.0015) end
    while os.clock() < target do end
end

local function add_event(data)
    if not state.recording then return end
    local now = os.clock()
    data.delay = now - last_time
    last_time = now
    table.insert(state.events, data)
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not state.recording then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then add_event({t="click", x=input.Position.X, y=input.Position.Y, state="down"})
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then add_event({t="click", button="right", state="down"})
    elseif input.UserInputType == Enum.UserInputType.Keyboard then add_event({t="key", key=input.KeyCode.Name, state="down"}) end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp or not state.recording then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then add_event({t="click", x=input.Position.X, y=input.Position.Y, state="up"})
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then add_event({t="click", button="right", state="up"})
    elseif input.UserInputType == Enum.UserInputType.Keyboard then add_event({t="key", key=input.KeyCode.Name, state="up"}) end
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

local function compress_events(events)
    if #events == 0 then return events end
    local compressed = {events[1]}
    for i = 2, #events do
        local ev = events[i]
        local last = compressed[#compressed]
        if ev.t == "camera" and last.t == "camera" and ev.delay < 0.01 then
            last.x = last.x + ev.x
            last.y = last.y + ev.y
            last.delay = last.delay + ev.delay
        else
            table.insert(compressed, ev)
        end
    end
    return compressed
end

local function PlayMacro()
    if state.playing then state.playing = false; return end
    if not _G.StrategyName or not isfile(_G.StrategyName .. ".json") then
        Window:Notify({ Title = "Error", Content = "Strategy file not found!", Duration = 3 })
        return
    end
    
    local data = HttpService:JSONDecode(readfile(_G.StrategyName .. ".json"))
    state.playing = true
    Window:Notify({ Title = "Playback", Content = "Playing...", Duration = 3 })
    
    task.spawn(function()
        for _, ev in ipairs(data) do
            if not state.playing then break end
            precise_sleep(ev.delay / state.speed)
            
            if ev.t == "key" then
                VirtualInputManager:SendKeyEvent(ev.state == "down", Enum.KeyCode[ev.key], false, game)
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
        mouse1release(); mouse2release()
        state.playing = false
        Window:Notify({ Title = "Playback", Content = "Finished.", Duration = 3 })
    end)
end

MacroTab:Button({ 
    Title = "⏺ Start / Stop Recording (F7)", 
    Callback = function() 
        state.recording = not state.recording 
        if state.recording then
            state.events = {}; last_time = os.clock()
            Window:Notify({ Title = "Recorder", Content = "Recording started.", Duration = 3 })
        else
            Window:Notify({ Title = "Recorder", Content = "Recording stopped.", Duration = 3 })
        end
    end 
})

MacroTab:Input({ Title = "Strategy Name", Placeholder = "Enter Name...", Callback = function(text) _G.StrategyName = text end })

MacroTab:Button({
    Title = "💾 Save Strategy",
    Callback = function()
        if not _G.StrategyName or _G.StrategyName == "" then return end
        local compressed = compress_events(state.events)
        writefile(_G.StrategyName .. ".json", HttpService:JSONEncode(compressed))
        Window:Notify({ Title = "Saved", Content = "Saved with " .. #compressed .. " events.", Duration = 3 })
    end
})

MacroTab:Slider({ Title = "Playback Speed", Value = { Min = 0.1, Max = 3.0, Default = 1.0 }, Step = 0.1, Callback = function(value) state.speed = value end })
MacroTab:Button({ Title = "▶ Play Macro (F6)", Callback = PlayMacro })

-- ==========================================
-- ⚙️ SETTINGS TAB
-- ==========================================
SettingsTab:Button({
    Title = "👁️ Hide UI (F1)",
    Callback = function()
        pcall(function() Window:Toggle() end)
    end
})

-- ==========================================
-- ⌨️ NATIVE GLOBAL KEYBINDS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Only ignore if the user is typing in a text box (so you can type in the Strategy Name box)
    if UserInputService:GetFocusedTextBox() then return end
    
    if input.KeyCode == Enum.KeyCode.F7 then
        state.recording = not state.recording
        if state.recording then 
            state.events = {}; last_time = os.clock()
            Window:Notify({ Title = "Recorder", Content = "Recording started.", Duration = 3 })
        else
            Window:Notify({ Title = "Recorder", Content = "Recording stopped.", Duration = 3 })
        end
    elseif input.KeyCode == Enum.KeyCode.F6 then
        PlayMacro()
    elseif input.KeyCode == Enum.KeyCode.F9 then
        state.recording = false; state.playing = false
        Window:Notify({ Title = "PANIC", Content = "All macros stopped.", Duration = 3 })
    elseif input.KeyCode == Enum.KeyCode.F1 then
        -- Use WindUI's native toggle function
        pcall(function() Window:Toggle() end)
    end
end)
