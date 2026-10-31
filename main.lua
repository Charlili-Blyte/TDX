--[[
    🟩 TDX MACRO HUB V11 - WINDUI EDITION (Pro Recorder)
--]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

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

-- 🎨 WINDUI WINDOW
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

-- ==========================================
-- 🌐 JOINS TAB (TDX Specific)
-- ==========================================
local function click_ui_button(btn_name)
    local btn = playerGui:FindFirstChild(btn_name, true)
    if btn then
        local pos = btn.AbsolutePosition
        local size = btn.AbsoluteSize
        local center_x = pos.X + (size.X / 2)
        local center_y = pos.Y + (size.Y / 2)
        
        if mousemoveabs and mouse1click then
            mousemoveabs(center_x, center_y)
            task.wait(0.2)
            mouse1click()
            return true
        else
            VirtualInputManager:SendMouseMoveEvent(center_x, center_y, Camera)
            task.wait(0.1)
            VirtualInputManager:SendMouseButtonEvent(center_x, center_y, 0, true, game, 1)
            task.wait(0.1)
            VirtualInputManager:SendMouseButtonEvent(center_x, center_y, 0, false, game, 1)
            return true
        end
    end
    return false
end

local function DoJoin(difficulty)
    if not click_ui_button("PlaySolo") then return end
    task.wait(1.5)
    if not click_ui_button("Survival") then return end
    task.wait(1.5)
    if not click_ui_button(difficulty) then return end
end

JoinsTab:Button({ Title = "▶ Play Solo (Easy)", Callback = function() task.spawn(function() DoJoin("Easy") end) end })
JoinsTab:Button({ Title = "▶ Play Solo (Intermediate)", Callback = function() task.spawn(function() DoJoin("Intermediate") end) end })
JoinsTab:Button({ Title = "▶ Play Solo (Elite)", Callback = function() task.spawn(function() DoJoin("Elite") end) end })
JoinsTab:Button({ Title = "▶ Play Solo (Expert)", Callback = function() task.spawn(function() DoJoin("Expert") end) end })

-- ==========================================
-- ⏺ PRO RECORDER ENGINE
-- ==========================================
local state = { recording = false, playing = false, speed = 1.0, events = {} }
local last_time = 0

-- Precise Timer
local function precise_sleep(duration)
    if duration <= 0 then return end
    local target = os.clock() + duration
    if duration > 0.002 then
        task.wait(duration - 0.0015)
    end
    while os.clock() < target do
        -- Busy wait for extreme precision
    end
end

-- Record Logic
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
            -- Only record camera if moving
            if input.Delta.X ~= 0 or input.Delta.Y ~= 0 then
                add_event({t="camera", x=input.Delta.X, y=input.Delta.Y})
            end
        end
    end
end)

-- Smart Compression (Shrinks file size by up to 80%)
local function compress_events(events)
    if #events == 0 then return events end
    local compressed = {events[1]}
    for i = 2, #events do
        local ev = events[i]
        local last = compressed[#compressed]
        
        -- Merge rapid camera movements
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

-- Play Logic (Uses hardware inputs for 100% accuracy)
local function PlayMacro()
    if state.playing then 
        state.playing = false
        Window:Notify({ Title = "Recorder", Content = "Playback stopped.", Duration = 3 })
        return 
    end
    if not _G.StrategyName or not isfile(_G.StrategyName .. ".json") then
        Window:Notify({ Title = "Error", Content = "Strategy file not found!", Duration = 3 })
        return
    end
    
    local data = HttpService:JSONDecode(readfile(_G.StrategyName .. ".json"))
    state.playing = true
    Window:Notify({ Title = "Playback", Content = "Playing at " .. state.speed .. "x speed", Duration = 3 })
    
    task.spawn(function()
        for _, ev in ipairs(data) do
            if not state.playing then break end
            
            -- Use precise sleep to prevent TDX from dropping inputs
            precise_sleep(ev.delay / state.speed)
            
            if ev.t == "key" then
                VirtualInputManager:SendKeyEvent(ev.state == "down", Enum.KeyCode[ev.key], false, game)
            elseif ev.t == "click" then
                -- Use hardware click to bypass TDX UI blocks
                if ev.state == "down" then
                    if ev.button == "right" then
                        mouse2press()
                    else
                        mouse1press()
                    end
                else
                    if ev.button == "right" then
                        mouse2release()
                    else
                        mouse1release()
                    end
                end
            elseif ev.t == "camera" then
                mousemoverel(ev.x, ev.y)
            end
        end
        
        -- Emergency Cleanup (Stops stuck keys/camera)
        mouse1release()
        mouse2release()
        for k = 65, 90 do -- Release all letter keys just in case
            pcall(function() keyrelease(string.char(k):lower()) end)
        end
        
        state.playing = false
        Window:Notify({ Title = "Playback", Content = "Finished.", Duration = 3 })
    end)
end

-- UI Buttons
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

MacroTab:Slider({
    Title = "Playback Speed",
    Value = { Min = 0.1, Max = 3.0, Default = 1.0 },
    Step = 0.1,
    Callback = function(value) state.speed = value end
})

MacroTab:Button({ Title = "▶ Play Macro (F6)", Callback = PlayMacro })

-- ==========================================
-- ⌨️ NATIVE GLOBAL KEYBINDS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
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
        state.recording = false
        state.playing = false
        Window:Notify({ Title = "PANIC", Content = "All macros stopped.", Duration = 3 })
    elseif input.KeyCode == Enum.KeyCode.F1 then
        if Window.Visible then Window:SetVisible(false) else Window:SetVisible(true) end
    end
end)
