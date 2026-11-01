--[[
    🟩 TDX MACRO HUB V22 - CONTEXT ACTION KEYBINDS
--]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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
    Title = "🟩 TDX Massive",
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
    pcall(function()
        Window:Notify({ Title = title, Content = text, Duration = 3 })
    end)
end

-- ==========================================
-- 🏠 DASHBOARD (Auto-Join)
-- ==========================================
local DashTab = Window:Tab({ Title = "Dashboard", Icon = "home" })

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

local function click_ui_element(btn)
    if not btn then return false end
    if getconnections then
        for _, sig_name in ipairs({"MouseButton1Click", "MouseButton1Down", "Activated"}) do
            local sig = btn[sig_name]
            if sig then
                for _, conn in pairs(getconnections(sig)) do
                    if conn.Enabled then pcall(function() conn:Fire() end) end
                end
            end
        end
        return true
    end
    if firesignal then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() firesignal(btn.Activated) end)
        return true
    end
    return false
end

local function TDX_Join(difficulty)
    Notify("Joining", "Navigating to " .. difficulty)
    local soloBtn = find_ui_element("solo")
    if soloBtn then click_ui_element(soloBtn) else return end
    task.wait(2)
    local survBtn = find_ui_element("survival")
    if survBtn then click_ui_element(survBtn) else return end
    task.wait(2)
    local diffBtn = find_ui_element(difficulty)
    if diffBtn then 
        click_ui_element(diffBtn)
        Notify("Success", "Joined " .. difficulty)
    end
end

DashTab:Button({ Title = "▶ Join Easy", Callback = function() task.spawn(function() TDX_Join("Easy") end) end })
DashTab:Button({ Title = "▶ Join Intermediate", Callback = function() task.spawn(function() TDX_Join("Intermediate") end) end })
DashTab:Button({ Title = "▶ Join Elite", Callback = function() task.spawn(function() TDX_Join("Elite") end) end })
DashTab:Button({ Title = "▶ Join Expert", Callback = function() task.spawn(function() TDX_Join("Expert") end) end })

-- ==========================================
-- 🚜 AUTO-FARM
-- ==========================================
local FarmTab = Window:Tab({ Title = "Auto-Farm", Icon = "tractor" })
local AutoFarmActive = false
local FarmSpots = { {x=500, y=500}, {x=600, y=500}, {x=700, y=500} }

FarmTab:Input({ Title = "Spot 1 (X, Y)", Placeholder = "500, 500", Callback = function(t) 
    local x, y = t:match("(%d+),%s*(%d+)")
    if x and y then FarmSpots[1] = {x=tonumber(x), y=tonumber(y)} end
end})
FarmTab:Input({ Title = "Spot 2 (X, Y)", Placeholder = "600, 500", Callback = function(t) 
    local x, y = t:match("(%d+),%s*(%d+)")
    if x and y then FarmSpots[2] = {x=tonumber(x), y=tonumber(y)} end
end})
FarmTab:Input({ Title = "Spot 3 (X, Y)", Placeholder = "700, 500", Callback = function(t) 
    local x, y = t:match("(%d+),%s*(%d+)")
    if x and y then FarmSpots[3] = {x=tonumber(x), y=tonumber(y)} end
end})

FarmTab:Toggle({
    Title = "Start Auto-Farm",
    Desc = "Automatically joins, places, and upgrades.",
    Value = false,
    Callback = function(state)
        AutoFarmActive = state
        if AutoFarmActive then
            Notify("Auto-Farm", "Started")
            task.spawn(function()
                while AutoFarmActive do
                    local soloBtn = find_ui_element("solo")
                    if soloBtn then
                        TDX_Join("Easy")
                        task.wait(20) 
                    else
                        keypress("1")
                        task.wait(0.2)
                        keyrelease("1")
                        task.wait(0.5)
                        for i, spot in ipairs(FarmSpots) do
                            if not AutoFarmActive then break end
                            mousemoveabs(spot.x, spot.y)
                            task.wait(0.1)
                            mouse1press()
                            task.wait(0.1)
                            mouse1release()
                            task.wait(0.3)
                            keypress("e")
                            task.wait(0.1)
                            keyrelease("e")
                            task.wait(0.2)
                            keypress("e")
                            task.wait(0.1)
                            keyrelease("e")
                            task.wait(1)
                        end
                    end
                    task.wait(5)
                end
            end)
        else
            Notify("Auto-Farm", "Stopped")
        end
    end
})

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

MacroTab:Button({ 
    Title = "⏺ Start / Stop Recording", 
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
MacroTab:Button({ Title = "▶ Play Macro", Callback = PlayMacro })

-- ==========================================
-- ⌨️ THE ULTIMATE KEYBIND FIX (ContextActionService)
-- ==========================================
-- ContextActionService bypasses all UI focus bugs and executor issues.

ContextActionService:BindAction("TDX_Record", function(_, state)
    if state == Enum.UserInputState.Begin then
        print("[Keybind] F7 Pressed")
        -- Toggle recording
        if _G.RecordToggle then _G.RecordToggle() end
    end
end, false, Enum.KeyCode.F7)

ContextActionService:BindAction("TDX_Play", function(_, state)
    if state == Enum.UserInputState.Begin then
        print("[Keybind] F6 Pressed")
        PlayMacro()
    end
end, false, Enum.KeyCode.F6)

ContextActionService:BindAction("TDX_Panic", function(_, state)
    if state == Enum.UserInputState.Begin then
        print("[Keybind] F9 Pressed")
        state.recording = false
        state.playing = false
        AutoFarmActive = false
        Notify("PANIC", "All macros stopped")
    end
end, false, Enum.KeyCode.F9)

-- Connect the F7 action to the UI button logic
_G.RecordToggle = function()
    state.recording = not state.recording 
    if state.recording then
        state.events = {}; state.last_time = os.clock()
        Notify("Recorder", "Recording started")
    else
        Notify("Recorder", "Recording stopped")
    end
end

print("✅ V22 Keybinds Loaded Successfully")
