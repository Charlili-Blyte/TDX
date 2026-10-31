--[[
    🟩 TDX MACRO HUB V15 - ULTIMATE EDITION
    Features: Hardware Recorder, Smart Camera, Auto-Join, WindUI.
--]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 🛡️ SECURITY
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

-- 🎨 WINDUI WINDOW (Press Right Shift to hide/show)
local Window = WindUI:CreateWindow({
    Title = "🟩 TDX Ultimate",
    Folder = "TDXUltimate",
    Size = UDim2.fromOffset(600, 460),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 160,
    HasOutline = false,
    ToggleKey = "RightShift",
})

local JoinTab = Window:Tab({ Title = "Auto-Join", Icon = "log-in" })
local MacroTab = Window:Tab({ Title = "Recorder", Icon = "disc" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

-- ==========================================
-- 🌐 ROBUST AUTO-JOIN SYSTEM
-- ==========================================

-- Ultra-reliable button finder
local function find_ui_element(target_text)
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) then
            if obj.Name:lower():find(target_text:lower()) then return obj end
            if obj:IsA("TextButton") and obj.Text:lower():find(target_text:lower()) then return obj end
        elseif obj:IsA("TextLabel") then
            if obj.Text:lower():find(target_text:lower()) then
                local parent_btn = obj.Parent
                if parent_btn and (parent_btn:IsA("TextButton") or parent_btn:IsA("ImageButton")) then
                    return parent_btn
                end
            end
        end
    end
    return nil
end

local function click_element(btn)
    if not btn then return false end
    
    -- Fire UI events in background (No cursor movement)
    if firesignal then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() firesignal(btn.MouseButton1Down) end)
        pcall(function() firesignal(btn.MouseButton1Up) end)
        return true
    end
    return false
end

local function TDX_Join(difficulty)
    Window:Notify({ Title = "Joining", Content = "Navigating to " .. difficulty .. "...", Duration = 3 })
    
    -- 1. Click Play Solo
    local soloBtn = find_ui_element("solo")
    if soloBtn then click_element(soloBtn) else
        Window:Notify({ Title = "Error", Content = "Play Solo not found.", Duration = 3 })
        return
    end
    task.wait(2) -- Wait for UI to load
    
    -- 2. Click Survival (or main mode)
    local survBtn = find_ui_element("survival")
    if survBtn then click_element(survBtn) else
        Window:Notify({ Title = "Error", Content = "Survival not found.", Duration = 3 })
        return
    end
    task.wait(2) -- Wait for UI to load
    
    -- 3. Click Difficulty
    local diffBtn = find_ui_element(difficulty)
    if diffBtn then 
        click_element(diffBtn)
        Window:Notify({ Title = "Success", Content = "Joining " .. difficulty .. "!", Duration = 3 })
    else
        Window:Notify({ Title = "Error", Content = difficulty .. " not found.", Duration = 3 })
    end
end

JoinTab:Button({ Title = "▶ Join Easy", Callback = function() task.spawn(function() TDX_Join("Easy") end) end })
JoinTab:Button({ Title = "▶ Join Intermediate", Callback = function() task.spawn(function() TDX_Join("Intermediate") end) end })
JoinTab:Button({ Title = "▶ Join Elite", Callback = function() task.spawn(function() TDX_Join("Elite") end) end })
JoinTab:Button({ Title = "▶ Join Expert", Callback = function() task.spawn(function() TDX_Join("Expert") end) end })
JoinTab:Button({ Title = "▶ Join Nightmare", Callback = function() task.spawn(function() TDX_Join("Nightmare") end) end })

JoinTab:Divider()

JoinTab:Input({ Title = "Custom Difficulty", Placeholder = "e.g. Endless", Callback = function(text) _G.CustomDiff = text end })
JoinTab:Button({
    Title = "▶ Custom Join",
    Callback = function()
        if _G.CustomDiff and _G.CustomDiff ~= "" then
            task.spawn(function() TDX_Join(_G.CustomDiff) end)
        end
    end
})

-- ==========================================
-- ⏺ ULTIMATE HARDWARE RECORDER
-- ==========================================
local state = { recording = false, playing = false, speed = 1.0, events = {}, last_time = 0 }

-- High-Precision Sleep Loop
local function ultra_sleep(duration)
    if duration <= 0 then return end
    local target = os.clock() + duration
    local sleep_time = duration - 0.002
    if sleep_time > 0 then
        task.wait(sleep_time)
    end
    while os.clock() < target do end
end

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
        -- Only record camera movement when holding Right Click
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            if input.Delta.X ~= 0 or input.Delta.Y ~= 0 then
                add_event({t="camera", x=input.Delta.X, y=input.Delta.Y})
            end
        end
    end
end)

-- Smart Camera Compression (Stops the camera from spinning wildly)
local function compress_events(events)
    if #events == 0 then return events end
    local compressed = {events[1]}
    for i = 2, #events do
        local ev = events[i]
        local last = compressed[#compressed]
        
        -- Merge rapid camera movements into one smooth turn
        if ev.t == "camera" and last.t == "camera" and ev.delay < 0.015 then
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
    if state.playing then 
        state.playing = false
        Window:Notify({ Title = "Playback", Content = "Stopped.", Duration = 2 })
        return 
    end
    
    if not _G.StrategyName or not isfile(_G.StrategyName .. ".json") then
        Window:Notify({ Title = "Error", Content = "Strategy file not found!", Duration = 3 })
        return
    end
    
    local data = HttpService:JSONDecode(readfile(_G.StrategyName .. ".json"))
    state.playing = true
    Window:Notify({ Title = "Playback", Content = "Playing at " .. state.speed .. "x speed...", Duration = 3 })
    
    task.spawn(function()
        for _, ev in ipairs(data) do
            if not state.playing then break end
            
            -- Precision wait
            ultra_sleep(ev.delay / state.speed)
            
            -- HARDWARE INPUT EMULATION (Bypasses TDX anti-cheat)
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
        
        -- Emergency Cleanup
        mouse1release(); mouse2release()
        for _, k in ipairs({"W","A","S","D","E","Q","R"}) do pcall(function() keyrelease(k) end) end
        
        state.playing = false
        Window:Notify({ Title = "Playback", Content = "Finished.", Duration = 3 })
    end)
end

-- UI Components for Recorder
MacroTab:Button({ 
    Title = "⏺ Start / Stop Recording (F7)", 
    Callback = function() 
        state.recording = not state.recording 
        if state.recording then
            state.events = {}; state.last_time = os.clock()
            Window:Notify({ Title = "Recorder", Content = "Recording started.", Duration = 3 })
        else
            Window:Notify({ Title = "Recorder", Content = "Recording stopped. Ready to save.", Duration = 3 })
        end
    end 
})

MacroTab:Input({ 
    Title = "Strategy Name", 
    Placeholder = "Enter Name...", 
    Callback = function(text) _G.StrategyName = text end 
})

MacroTab:Button({
    Title = "💾 Save Strategy",
    Callback = function()
        if not _G.StrategyName or _G.StrategyName == "" then return end
        local compressed = compress_events(state.events)
        writefile(_G.StrategyName .. ".json", HttpService:JSONEncode(compressed))
        Window:Notify({ Title = "Saved", Content = "Saved " .. #compressed .. " events.", Duration = 3 })
    end
})

MacroTab:Slider({ 
    Title = "Playback Speed", 
    Value = { Min = 0.1, Max = 3.0, Default = 1.0 }, 
    Step = 0.1, 
    Callback = function(value) state.speed = value end 
})

MacroTab:Button({ Title = "▶ Play Macro (F6)", Callback = PlayMacro })

-- ==========================================
-- ⚙️ SETTINGS & KEYBINDS
-- ==========================================
SettingsTab:Paragraph({ Title = "Keybinds", Desc = "F6: Play\nF7: Record\nRight Shift: Hide UI" })

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if UserInputService:GetFocusedTextBox() then return end
    
    if input.KeyCode == Enum.KeyCode.F7 then
        state.recording = not state.recording
        if state.recording then 
            state.events = {}; state.last_time = os.clock()
            Window:Notify({ Title = "Recorder", Content = "Recording started.", Duration = 3 })
        else
            Window:Notify({ Title = "Recorder", Content = "Recording stopped.", Duration = 3 })
        end
    elseif input.KeyCode == Enum.KeyCode.F6 then
        PlayMacro()
    elseif input.KeyCode == Enum.KeyCode.F9 then
        state.recording = false; state.playing = false
        Window:Notify({ Title = "PANIC", Content = "All macros stopped.", Duration = 3 })
    end
end)
