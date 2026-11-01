--[[
    🟩 TDX MACRO HUB V18 - PREMIUM UI EDITION (Fixed)
--]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
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

task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- ==========================================
-- 📊 CUSTOM HUD (WATERMARK)
-- ==========================================
if playerGui:FindFirstChild("TDX_HUD") then playerGui.TDX_HUD:Destroy() end

local HUD = Instance.new("ScreenGui")
HUD.Name = "TDX_HUD"
HUD.ResetOnSpawn = false
HUD.Parent = playerGui

local HUD_Frame = Instance.new("Frame")
HUD_Frame.Size = UDim2.new(0, 220, 0, 60)
HUD_Frame.Position = UDim2.new(0, 15, 0, 15)
HUD_Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
HUD_Frame.BackgroundTransparency = 0.2
HUD_Frame.BorderSizePixel = 0
HUD_Frame.Parent = HUD

local HUD_Corner = Instance.new("UICorner", HUD_Frame)
HUD_Corner.CornerRadius = UDim.new(0, 8)

local HUD_Stroke = Instance.new("UIStroke", HUD_Frame)
HUD_Stroke.Color = Color3.fromRGB(34, 197, 94)
HUD_Stroke.Thickness = 1

local HUD_Title = Instance.new("TextLabel")
HUD_Title.Size = UDim2.new(1, 0, 0, 25)
HUD_Title.BackgroundTransparency = 1
HUD_Title.Text = "🟩 TDX ULTIMATE"
HUD_Title.TextColor3 = Color3.fromRGB(34, 197, 94)
HUD_Title.Font = Enum.Font.GothamBold
HUD_Title.TextSize = 12
HUD_Title.Parent = HUD_Frame

local HUD_Status = Instance.new("TextLabel")
HUD_Status.Size = UDim2.new(1, 0, 0, 35)
HUD_Status.Position = UDim2.new(0, 0, 0, 25)
HUD_Status.BackgroundTransparency = 1
HUD_Status.Text = "Farm: OFF | Macro: Idle"
HUD_Status.TextColor3 = Color3.fromRGB(200, 200, 200)
HUD_Status.Font = Enum.Font.Gotham
HUD_Status.TextSize = 11
HUD_Status.Parent = HUD_Frame

local function UpdateHUD(farmState, macroState)
    HUD_Status.Text = string.format("Farm: %s | Macro: %s", farmState, macroState)
end

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

-- ==========================================
-- 🏠 DASHBOARD TAB
-- ==========================================
local DashTab = Window:Tab({ Title = "Dashboard", Icon = "home" })

DashTab:Paragraph({
    Title = "Welcome to TDX Ultimate",
    Desc = "Select a difficulty below to automatically join the match. Use the Auto-Farm tab for hands-free farming, or the Recorder tab to create your own strategies."
})

DashTab:Divider()

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
    WindUI:Notify({ Title = "Joining", Content = "Navigating to " .. difficulty .. "...", Duration = 3 })
    local soloBtn = find_ui_element("solo")
    if soloBtn then click_ui_element(soloBtn) else return end
    task.wait(2)
    local survBtn = find_ui_element("survival")
    if survBtn then click_ui_element(survBtn) else return end
    task.wait(2)
    local diffBtn = find_ui_element(difficulty)
    if diffBtn then 
        click_ui_element(diffBtn)
        WindUI:Notify({ Title = "Success", Content = "Joined " .. difficulty .. "!", Duration = 3 })
    end
end

DashTab:Button({ Title = "▶ Join Easy", Callback = function() task.spawn(function() TDX_Join("Easy") end) end })
DashTab:Button({ Title = "▶ Join Intermediate", Callback = function() task.spawn(function() TDX_Join("Intermediate") end) end })
DashTab:Button({ Title = "▶ Join Elite", Callback = function() task.spawn(function() TDX_Join("Elite") end) end })
DashTab:Button({ Title = "▶ Join Expert", Callback = function() task.spawn(function() TDX_Join("Expert") end) end })

-- ==========================================
-- 🚜 AUTO-FARM TAB
-- ==========================================
local FarmTab = Window:Tab({ Title = "Auto-Farm", Icon = "tractor" })

local AutoFarmActive = false
local FarmSpots = {
    {x = 500, y = 500}, 
    {x = 600, y = 500},
    {x = 700, y = 500}
}

FarmTab:Paragraph({ 
    Title = "Auto-Farm Configuration", 
    Desc = "Enter your tower coordinates below. The bot will automatically join Easy and place towers at these exact screen positions."
})

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

FarmTab:Divider()

FarmTab:Toggle({
    Title = "Start Auto-Farm",
    Desc = "Automatically joins Easy and places towers.",
    Value = false,
    Callback = function(state)
        AutoFarmActive = state
        UpdateHUD(AutoFarmActive and "ON" or "OFF", state.playing and "Playing" or "Idle")
        if AutoFarmActive then
            WindUI:Notify({ Title = "Auto-Farm", Content = "Started. Joining Easy...", Duration = 3 })
            task.spawn(function()
                while AutoFarmActive do
                    local soloBtn = find_ui_element("solo")
                    if soloBtn then
                        TDX_Join("Easy")
                        task.wait(20) 
                    end

                    if AutoFarmActive and not find_ui_element("solo") then
                        WindUI:Notify({ Title = "Auto-Farm", Content = "Placing towers...", Duration = 3 })
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
            WindUI:Notify({ Title = "Auto-Farm", Content = "Stopped.", Duration = 3 })
        end
    end
})

-- ==========================================
-- ⏺ RECORDER TAB
-- ==========================================
local MacroTab = Window:Tab({ Title = "Recorder", Icon = "disc" })
local state = { recording = false, playing = false, speed = 1.0, events = {}, last_time = 0, loop = false }

local function ultra_sleep(duration)
    if duration <= 0 then return end
    local target = os.clock() + duration
    local sleep_time = duration - 0.002
    if sleep_time > 0 then task.wait(sleep_time) end
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
        WindUI:Notify({ Title = "Playback", Content = "Stopped.", Duration = 2 })
        UpdateHUD(AutoFarmActive and "ON" or "OFF", "Idle")
        return 
    end
    
    if not _G.StrategyName or not isfile(_G.StrategyName .. ".json") then
        WindUI:Notify({ Title = "Error", Content = "Strategy file not found!", Duration = 3 })
        return
    end
    
    local data = HttpService:JSONDecode(readfile(_G.StrategyName .. ".json"))
    state.playing = true
    WindUI:Notify({ Title = "Playback", Content = "Playing...", Duration = 3 })
    UpdateHUD(AutoFarmActive and "ON" or "OFF", "Playing...")
    
    task.spawn(function()
        while state.playing do
            for _, ev in ipairs(data) do
                if not state.playing then break end
                ultra_sleep(ev.delay / state.speed)
                
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
        WindUI:Notify({ Title = "Playback", Content = "Finished.", Duration = 3 })
        UpdateHUD(AutoFarmActive and "ON" or "OFF", "Idle")
    end)
end

MacroTab:Button({ 
    Title = "⏺ Start / Stop Recording", 
    Callback = function() 
        state.recording = not state.recording 
        if state.recording then
            state.events = {}; state.last_time = os.clock()
            WindUI:Notify({ Title = "Recorder", Content = "Recording started.", Duration = 3 })
            UpdateHUD(AutoFarmActive and "ON" or "OFF", "Recording...")
        else
            WindUI:Notify({ Title = "Recorder", Content = "Recording stopped.", Duration = 3 })
            UpdateHUD(AutoFarmActive and "ON" or "OFF", "Idle")
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
        if not _G.StrategyName or _G.StrategyName == "" then return end
        local compressed = compress_events(state.events)
        writefile(_G.StrategyName .. ".json", HttpService:JSONEncode(compressed))
        WindUI:Notify({ Title = "Saved", Content = "Saved " .. _G.StrategyName, Duration = 3 })
        
        local files = listfiles() or {}
        local list = {}
        for _, f in ipairs(files) do
            if string.find(f, "%.json$") then 
                -- FIXED: Wrapped gsub in parentheses
                table.insert(list, (string.gsub(f, "%.json$", ""))) 
            end
        end
        if _G.MacroDropdown then _G.MacroDropdown:Refresh(list) end
    end
})

MacroTab:Divider()

local files = listfiles() or {}
local macroList = {}
for _, f in ipairs(files) do
    if string.find(f, "%.json$") then 
        -- FIXED: Wrapped gsub in parentheses
        table.insert(macroList, (string.gsub(f, "%.json$", ""))) 
    end
end

_G.MacroDropdown = MacroTab:Dropdown({
    Title = "Select Strategy",
    Values = macroList,
    Callback = function(option) _G.StrategyName = option end
})

MacroTab:Button({
    Title = "🗑️ Delete Selected Strategy",
    Callback = function()
        if _G.StrategyName and isfile(_G.StrategyName .. ".json") then
            delfile(_G.StrategyName .. ".json")
            WindUI:Notify({ Title = "Deleted", Content = "Deleted " .. _G.StrategyName, Duration = 3 })
            local new_files = {}
            for _, f in ipairs(listfiles() or {}) do
                if string.find(f, "%.json$") then 
                    -- FIXED: Wrapped gsub in parentheses
                    table.insert(new_files, (string.gsub(f, "%.json$", ""))) 
                end
            end
            if _G.MacroDropdown then _G.MacroDropdown:Refresh(new_files) end
        end
    end
})

MacroTab:Slider({ 
    Title = "Playback Speed", 
    Value = { Min = 0.1, Max = 3.0, Default = 1.0 }, 
    Step = 0.1, 
    Callback = function(value) state.speed = value end 
})

MacroTab:Toggle({
    Title = "Loop Playback",
    Desc = "Automatically restart the macro when it finishes.",
    Value = false,
    Callback = function(bool) state.loop = bool end
})

MacroTab:Button({ Title = "▶ Play Macro", Callback = PlayMacro })

-- ==========================================
-- ⚙️ SETTINGS TAB
-- ==========================================
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

SettingsTab:Paragraph({ 
    Title = "Keybinds", 
    Desc = "F6: Play Macro\nF7: Record / Stop\nF9: Panic (Stop All)\nRight Shift: Toggle UI" 
})

SettingsTab:Toggle({
    Title = "Anti-Kick Protection",
    Desc = "Prevents TDX from kicking you.",
    Value = true,
    Callback = function(state)
        if state then
            pcall(function()
                local oldKick = hookmetamethod(game, "__namecall", function(self, ...)
                    if getnamecallmethod() == "Kick" then return end
                    return oldKick(self, ...)
                end)
            end)
        end
    end
})

-- ==========================================
-- ⌨️ KEYBINDS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if UserInputService:GetFocusedTextBox() then return end
    
    if input.KeyCode == Enum.KeyCode.F7 then
        state.recording = not state.recording
        if state.recording then 
            state.events = {}; state.last_time = os.clock()
            WindUI:Notify({ Title = "Recorder", Content = "Recording started.", Duration = 3 })
            UpdateHUD(AutoFarmActive and "ON" or "OFF", "Recording...")
        else
            WindUI:Notify({ Title = "Recorder", Content = "Recording stopped.", Duration = 3 })
            UpdateHUD(AutoFarmActive and "ON" or "OFF", "Idle")
        end
    elseif input.KeyCode == Enum.KeyCode.F6 then
        PlayMacro()
    elseif input.KeyCode == Enum.KeyCode.F9 then
        state.recording = false; state.playing = false; AutoFarmActive = false
        WindUI:Notify({ Title = "PANIC", Content = "All macros stopped.", Duration = 3 })
        UpdateHUD("OFF", "Idle")
    end
end)
