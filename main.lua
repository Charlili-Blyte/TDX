--[[
    🟩 TDX MACRO HUB V9 - WINDUI EDITION
    Features: Premium UI, Global Keybinds, TDX-Specific Joins, Recorder, Auto-Farm.
--]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
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
local FarmTab = Window:Tab({ Title = "Auto-Farm", Icon = "tractor" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

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

JoinsTab:Button({ Title = "▶ Play Solo (Easy)", Desc = "Join a Solo Easy match.", Callback = function() task.spawn(function() DoJoin("Easy") end) end })
JoinsTab:Button({ Title = "▶ Play Solo (Intermediate)", Desc = "Join a Solo Intermediate match.", Callback = function() task.spawn(function() DoJoin("Intermediate") end) end })
JoinsTab:Button({ Title = "▶ Play Solo (Elite)", Desc = "Join a Solo Elite match.", Callback = function() task.spawn(function() DoJoin("Elite") end) end })
JoinsTab:Button({ Title = "▶ Play Solo (Expert)", Desc = "Join a Solo Expert match.", Callback = function() task.spawn(function() DoJoin("Expert") end) end })

JoinsTab:Divider()

JoinsTab:Input({
    Title = "Custom Mode",
    Placeholder = "e.g. Endless, Coop",
    Callback = function(text) _G.CustomMode = text end
})

JoinsTab:Button({
    Title = "🌐 Custom Join",
    Callback = function()
        if _G.CustomMode and _G.CustomMode ~= "" then
            task.spawn(function() DoJoin(_G.CustomMode) end)
        end
    end
})

-- ==========================================
-- ⏺ RECORDER TAB
-- ==========================================
local state = { recording = false, playing = false, speed = 1.0, events = {} }
local last_time = 0

local function add_event(data)
    if not state.recording then return end
    local now = tick()
    data.delay = now - last_time
    last_time = now
    table.insert(state.events, data)
end

game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if gp or not state.recording then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then add_event({t="click", x=input.Position.X, y=input.Position.Y, state="down"})
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then add_event({t="click", button="right", state="down"})
    elseif input.UserInputType == Enum.UserInputType.Keyboard then add_event({t="key", key=input.KeyCode.Name, state="down"}) end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input, gp)
    if gp or not state.recording then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then add_event({t="click", x=input.Position.X, y=input.Position.Y, state="up"})
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then add_event({t="click", button="right", state="up"})
    elseif input.UserInputType == Enum.UserInputType.Keyboard then add_event({t="key", key=input.KeyCode.Name, state="up"}) end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input, gp)
    if gp or not state.recording then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            add_event({t="camera", x=input.Delta.X, y=input.Delta.Y})
        end
    end
end)

MacroTab:Keybind({
    Title = "Start / Stop Recording",
    Key = "F7",
    Callback = function()
        state.recording = not state.recording
        if state.recording then
            state.events = {}; last_time = tick()
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
        if not _G.StrategyName or _G.StrategyName == "" then
            Window:Notify({ Title = "Error", Content = "Please enter a name.", Duration = 3 })
            return
        end
        writefile(_G.StrategyName .. ".json", HttpService:JSONEncode(state.events))
        Window:Notify({ Title = "Saved", Content = "Saved " .. _G.StrategyName .. ".json", Duration = 3 })
    end
})

MacroTab:Divider()

MacroTab:Slider({
    Title = "Playback Speed",
    Value = { Min = 0.1, Max = 3.0, Default = 1.0 },
    Step = 0.1,
    Callback = function(value) state.speed = value end
})

MacroTab:Keybind({
    Title = "Play Macro",
    Key = "F6",
    Callback = function()
        if state.playing then state.playing = false; return end
        if not _G.StrategyName or not isfile(_G.StrategyName .. ".json") then
            Window:Notify({ Title = "Error", Content = "File not found!", Duration = 3 })
            return
        end
        
        local data = HttpService:JSONDecode(readfile(_G.StrategyName .. ".json"))
        state.playing = true
        
        task.spawn(function()
            for _, ev in ipairs(data) do
                if not state.playing then break end
                task.wait(ev.delay / state.speed)
                if ev.t == "key" then
                    VirtualInputManager:SendKeyEvent(ev.state == "down", Enum.KeyCode[ev.key], false, game)
                elseif ev.t == "click" then
                    VirtualInputManager:SendMouseButtonEvent(ev.x or 0, ev.y or 0, (ev.button == "right") and 1 or 0, ev.state == "down", game, 1)
                elseif ev.t == "camera" then
                    mousemoverel(ev.x, ev.y)
                end
            end
            state.playing = false
        end)
    end
})

-- ==========================================
-- 🚜 AUTO-FARM TAB
-- ==========================================
local farm_active = false

FarmTab:Toggle({
    Title = "Auto-Farm TDX",
    Desc = "Automatically places towers and farms.",
    Value = false,
    Callback = function(state)
        farm_active = state
        Window:Notify({ Title = "Auto-Farm", Content = state and "Enabled" or "Disabled", Duration = 3 })
    end
})

FarmTab:Paragraph({
    Title = "Notice",
    Desc = "Auto-Farm requires map-specific coordinates in the script. This UI is the visual toggle.",
})

-- ==========================================
-- ⚙️ SETTINGS TAB
-- ==========================================
SettingsTab:Keybind({
    Title = "Toggle UI Visibility",
    Key = "F1",
    Callback = function()
        Window:SetVisible(false)
    end
})

SettingsTab:Keybind({
    Title = "PANIC (Stop All)",
    Key = "F9",
    Callback = function()
        state.recording = false
        state.playing = false
        farm_active = false
        Window:Notify({ Title = "PANIC", Content = "All macros stopped.", Duration = 3 })
    end
})
