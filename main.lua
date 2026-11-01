--[[
    🟩 TDX MACRO HUB V19 - BULLETPROOF
--]]

local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not success or not WindUI then
    print("❌ Failed to load WindUI library!")
    return
end
print("✅ WindUI Library Loaded")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Safe Notify Function
local function Notify(title, text)
    pcall(function()
        WindUI:Notify({ Title = title, Content = text, Duration = 3 })
    end)
end

-- Safe File Functions
local function get_saved_files()
    local list = {}
    local ok, files = pcall(function() return listfiles() end)
    if ok and files then
        for _, f in ipairs(files) do
            if string.find(f, "%.json$") then
                local clean_name = string.gsub(f, "%.json$", "")
                table.insert(list, clean_name)
            end
        end
    end
    return list
end

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
    Title = "🟩 TDX Ultimate",
    Folder = "TDXUltimate",
    Size = UDim2.fromOffset(650, 500),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170,
    HasOutline = false,
    ToggleKey = "RightShift",
})
print("✅ Window Created")

local DashTab = Window:Tab({ Title = "Dashboard", Icon = "home" })
local MacroTab = Window:Tab({ Title = "Recorder", Icon = "disc" })

-- ==========================================
-- 🏠 DASHBOARD TAB
-- ==========================================
DashTab:Paragraph({
    Title = "TDX Auto-Join",
    Desc = "Click a button to automatically join a match."
})

local function TDX_Join(difficulty)
    Notify("Joining", "Navigating to " .. difficulty)
    
    -- Background click using VIM
    local function click_by_name(name)
        local btn = playerGui:FindFirstChild(name, true)
        if btn then
            local x = btn.AbsolutePosition.X + (btn.AbsoluteSize.X / 2)
            local y = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y / 2)
            local VIM = game:GetService("VirtualInputManager")
            VIM:SendMouseMoveEvent(x, y, workspace.CurrentCamera)
            task.wait(0.1)
            VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.1)
            VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
            return true
        end
        return false
    end

    if not click_by_name("PlaySolo") then Notify("Error", "PlaySolo not found") return end
    task.wait(2)
    if not click_by_name("Survival") then Notify("Error", "Survival not found") return end
    task.wait(2)
    if not click_by_name(difficulty) then Notify("Error", difficulty .. " not found") return end
    
    Notify("Success", "Joining " .. difficulty)
end

DashTab:Button({ Title = "▶ Join Easy", Callback = function() task.spawn(function() TDX_Join("Easy") end) end })
DashTab:Button({ Title = "▶ Join Intermediate", Callback = function() task.spawn(function() TDX_Join("Intermediate") end) end })
DashTab:Button({ Title = "▶ Join Elite", Callback = function() task.spawn(function() TDX_Join("Elite") end) end })
DashTab:Button({ Title = "▶ Join Expert", Callback = function() task.spawn(function() TDX_Join("Expert") end) end })

-- ==========================================
-- ⏺ RECORDER TAB
-- ==========================================
local state = { recording = false, playing = false, speed = 1.0, events = {}, last_time = 0 }

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
    elseif input.UserInputType == Enum.UserInputType.Keyboard then 
        add_event({t="key", key=input.KeyCode.Name, state="down"}) 
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp or not state.recording then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        add_event({t="click", x=input.Position.X, y=input.Position.Y, state="up"})
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
    if state.playing then state.playing = false return end
    
    if not _G.StrategyName or not isfile(_G.StrategyName .. ".json") then
        Notify("Error", "File not found!")
        return
    end
    
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(_G.StrategyName .. ".json")) end)
    if not ok or not data then Notify("Error", "Failed to read file.") return end
    
    state.playing = true
    Notify("Playback", "Playing...")
    
    task.spawn(function()
        for _, ev in ipairs(data) do
            if not state.playing then break end
            task.wait(ev.delay)
            
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
        state.playing = false
        Notify("Playback", "Finished")
    end)
end

MacroTab:Button({ 
    Title = "⏺ Start / Stop Recording (F7)", 
    Callback = function() 
        state.recording = not state.recording 
        if state.recording then
            state.events = {}; state.last_time = os.clock()
            Notify("Recorder", "Recording started")
        else
            Notify("Recorder", "Recording stopped")
        end
    end 
})

MacroTab:Input({ 
    Title = "Save Name", 
    Placeholder = "Enter Name...", 
    Callback = function(text) _G.StrategyName = text end 
})

MacroTab:Button({
    Title = "💾 Save Strategy",
    Callback = function()
        if not _G.StrategyName or _G.StrategyName == "" then Notify("Error", "Enter a name first!") return end
        local ok = pcall(function()
            writefile(_G.StrategyName .. ".json", HttpService:JSONEncode(state.events))
        end)
        if ok then
            Notify("Saved", "Saved " .. _G.StrategyName)
        else
            Notify("Error", "Executor failed to write file.")
        end
    end
})

-- Load Dropdown
local macroList = get_saved_files()
if #macroList == 0 then table.insert(macroList, "None") end

local Dropdown = MacroTab:Dropdown({
    Title = "Select Strategy",
    Values = macroList,
    Callback = function(option) _G.StrategyName = option end
})

MacroTab:Slider({ 
    Title = "Playback Speed", 
    Value = { Min = 0.1, Max = 3.0, Default = 1.0 }, 
    Step = 0.1, 
    Callback = function(value) state.speed = value end 
})

MacroTab:Button({ Title = "▶ Play Macro (F6)", Callback = PlayMacro })

-- ==========================================
-- ⌨️ KEYBINDS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if UserInputService:GetFocusedTextBox() then return end
    
    if input.KeyCode == Enum.KeyCode.F7 then
        state.recording = not state.recording
        if state.recording then 
            state.events = {}; state.last_time = os.clock()
            Notify("Recorder", "Recording started")
        else
            Notify("Recorder", "Recording stopped")
        end
    elseif input.KeyCode == Enum.KeyCode.F6 then
        PlayMacro()
    elseif input.KeyCode == Enum.KeyCode.F9 then
        state.recording = false; state.playing = false
        Notify("PANIC", "All macros stopped")
    end
end)

print("✅ Script successfully loaded to the end!")
