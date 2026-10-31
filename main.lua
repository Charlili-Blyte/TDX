--[[
    🟩 TDX MACRO HUB V3 - PREMIUM EDITION
    Features: Animations, Custom Slider, Anti-Kick, Auto-Farm, Live Radar.
--]]

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Theme = {
    Background = Color3.fromRGB(12, 12, 14),
    Sidebar = Color3.fromRGB(18, 18, 22),
    Element = Color3.fromRGB(24, 24, 30),
    Accent = Color3.fromRGB(34, 197, 94),
    Danger = Color3.fromRGB(239, 68, 68),
    Text = Color3.fromRGB(240, 240, 240),
    SubText = Color3.fromRGB(150, 150, 160)
}

local function log(text)
    print("[TDX Hub] " .. text)
    if _G.TDX_Console then _G.TDX_Console(text) end
end

-- ==========================================
-- 🛡️ SECURITY & PROTECTION
-- ==========================================
pcall(function()
    local oldKick = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() == "Kick" then
            log("🚫 ANTI-KICK: Blocked Kick Attempt!")
            return
        end
        return oldKick(self, ...)
    end)
end)

task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    Player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- ==========================================
-- 🎨 UI CREATION
-- ==========================================
local parentGui = game:GetService("CoreGui")
pcall(function() parentGui = gethui() end)
if parentGui:FindFirstChild("TDX_Hub") then parentGui.TDX_Hub:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TDX_Hub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parentGui

-- Main Window
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 600, 0, 400)
Main.Position = UDim2.new(0.5, -300, 0.5, -200)
Main.BackgroundColor3 = Theme.Background
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Theme.Element
MainStroke.Thickness = 1

-- Dragging Logic
local dragging, dragInput, dragStart, startPos
local function updateDrag(input)
    local delta = input.Position - dragStart
    Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
Main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then updateDrag(input) end
end)

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Theme.Sidebar
TopBar.BorderSizePixel = 0
TopBar.Parent = Main
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)
local TopBarFix = Instance.new("Frame") -- Hides bottom rounded corners
TopBarFix.Size = UDim2.new(1, 0, 0, 15)
TopBarFix.Position = UDim2.new(0, 0, 1, -15)
TopBarFix.BackgroundColor3 = Theme.Sidebar
TopBarFix.BorderSizePixel = 0
TopBarFix.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🟩 TDX MACRO V3"
Title.TextColor3 = Theme.Accent
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 5)
CloseBtn.BackgroundColor3 = Theme.Element
CloseBtn.Text = "✖"
CloseBtn.TextColor3 = Theme.Danger
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -75, 0, 5)
MinimizeBtn.BackgroundColor3 = Theme.Element
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Theme.Text
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = TopBar
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -130, 1, -40)
Content.Position = UDim2.new(0, 130, 0, 40)
Content.BackgroundTransparency = 1
Content.Parent = Main

-- Tabs System
local tabs, pages = {}, {}
local currentTab = nil

local function SwitchTab(name)
    if currentTab == name then return end
    currentTab = name
    for tName, tBtn in pairs(tabs) do
        local isActive = (tName == name)
        TweenService:Create(tBtn, TweenInfo.new(0.2), {BackgroundColor3 = isActive and Theme.Element or Theme.Sidebar, TextColor3 = isActive and Theme.Text or Theme.SubText}):Play()
        if pages[tName] then pages[tName].Visible = isActive end
    end
end

local function CreateTab(name, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.Position = UDim2.new(0, 5, 0, #tabs * 40 + 5)
    btn.BackgroundColor3 = Theme.Sidebar
    btn.Text = "  " .. text
    btn.TextColor3 = Theme.SubText
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 1, -20)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = Content
    
    tabs[name] = btn
    pages[name] = frame
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
    return frame
end

-- Minimize logic
local minimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local targetSize = minimized and UDim2.new(0, 600, 0, 40) or UDim2.new(0, 600, 0, 400)
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = targetSize}):Play()
end)

local MacroPage = CreateTab("macro", "⏺  Macro")
local StratPage = CreateTab("strat", "📁  Strategies")
local InfoPage = CreateTab("info", "🛡️  Security")

-- Console Logger (Bottom Right of Content)
local ConsoleBox = Instance.new("ScrollingFrame")
ConsoleBox.Size = UDim2.new(0, 200, 0, 100)
ConsoleBox.Position = UDim2.new(1, -210, 1, -110)
ConsoleBox.BackgroundColor3 = Theme.Sidebar
ConsoleBox.BorderSizePixel = 0
ConsoleBox.ScrollBarThickness = 2
ConsoleBox.Parent = Content
Instance.new("UICorner", ConsoleBox).CornerRadius = UDim.new(0, 6)
local ConsoleLayout = Instance.new("UIListLayout", ConsoleBox)

_G.TDX_Console = function(text)
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -10, 0, 15)
    msg.BackgroundTransparency = 1
    msg.Text = "> " .. text
    msg.TextColor3 = Theme.Accent
    msg.Font = Enum.Font.Code
    msg.TextSize = 11
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.Parent = ConsoleBox
    task.wait()
    ConsoleBox.CanvasSize = UDim2.new(0, 0, 0, ConsoleLayout.AbsoluteContentSize.Y)
    ConsoleBox.CanvasPosition = Vector2.new(0, ConsoleLayout.AbsoluteContentSize.Y)
end

-- ==========================================
-- 📡 ANIMATED RADAR (Bottom Right)
-- ==========================================
local Radar = Instance.new("Frame")
Radar.Size = UDim2.new(0, 100, 0, 100)
Radar.Position = UDim2.new(1, -110, 0, 10)
Radar.BackgroundColor3 = Theme.Sidebar
Radar.Parent = Content
Instance.new("UICorner", Radar).CornerRadius = UDim.new(1, 0)
local RadarStroke = Instance.new("UIStroke", Radar)
RadarStroke.Color = Theme.Accent
RadarStroke.Thickness = 2

local SweepContainer = Instance.new("Frame")
SweepContainer.Size = UDim2.new(1, 0, 1, 0)
SweepContainer.BackgroundTransparency = 1
SweepContainer.ClipsDescendants = true
SweepContainer.Parent = Radar
Instance.new("UICorner", SweepContainer).CornerRadius = UDim.new(1, 0)

local Sweep = Instance.new("Frame")
Sweep.Size = UDim2.new(0.5, 0, 0, 1)
Sweep.Position = UDim2.new(0.5, 0, 0.5, 0)
Sweep.BackgroundColor3 = Theme.Accent
Sweep.AnchorPoint = Vector2.new(0, 0.5)
Sweep.Parent = SweepContainer

RunService.RenderStepped:Connect(function()
    if Sweep and Sweep.Parent then
        Sweep.Rotation = (Sweep.Rotation + 3) % 360
    end
end)

-- ==========================================
-- ⏺ MACRO TAB
-- ==========================================
local state = { recording = false, playing = false, speed = 1.0, events = {} }
local last_time = 0

local RecBtn = Instance.new("TextButton")
RecBtn.Size = UDim2.new(0, 180, 0, 40)
RecBtn.Position = UDim2.new(0, 0, 0, 0)
RecBtn.BackgroundColor3 = Theme.Danger
RecBtn.Text = "⏺ Start Recording"
RecBtn.TextColor3 = Theme.Text
RecBtn.Font = Enum.Font.GothamBold
RecBtn.Parent = MacroPage
Instance.new("UICorner", RecBtn).CornerRadius = UDim.new(0, 6)

local NameInput = Instance.new("TextBox")
NameInput.Size = UDim2.new(0, 180, 0, 35)
NameInput.Position = UDim2.new(0, 0, 0, 50)
NameInput.BackgroundColor3 = Theme.Element
NameInput.TextColor3 = Theme.Text
NameInput.PlaceholderText = "Strategy Name..."
NameInput.Font = Enum.Font.Gotham
NameInput.Parent = MacroPage
Instance.new("UICorner", NameInput).CornerRadius = UDim.new(0, 6)

local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(0, 180, 0, 35)
SaveBtn.Position = UDim2.new(0, 0, 0, 95)
SaveBtn.BackgroundColor3 = Theme.Accent
SaveBtn.Text = "💾 Save Strategy"
SaveBtn.TextColor3 = Color3.new(0,0,0)
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.Parent = MacroPage
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)

local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(0, 180, 0, 40)
PlayBtn.Position = UDim2.new(0, 0, 0, 150)
PlayBtn.BackgroundColor3 = Theme.Accent
PlayBtn.Text = "▶ Play Macro"
PlayBtn.TextColor3 = Color3.new(0,0,0)
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.Parent = MacroPage
Instance.new("UICorner", PlayBtn).CornerRadius = UDim.new(0, 6)

-- Custom Slider
local SliderBg = Instance.new("Frame")
SliderBg.Size = UDim2.new(0, 180, 0, 6)
SliderBg.Position = UDim2.new(0, 0, 0, 210)
SliderBg.BackgroundColor3 = Theme.Element
SliderBg.Parent = MacroPage
Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.25, 0, 1, 0)
SliderFill.BackgroundColor3 = Theme.Accent
SliderFill.Parent = SliderBg
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

local SliderDot = Instance.new("Frame")
SliderDot.Size = UDim2.new(0, 12, 0, 12)
SliderDot.Position = UDim2.new(1, -6, 0.5, -6)
SliderDot.BackgroundColor3 = Theme.Text
SliderDot.Parent = SliderFill
Instance.new("UICorner", SliderDot).CornerRadius = UDim.new(1, 0)

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0, 180, 0, 20)
SpeedLabel.Position = UDim2.new(0, 0, 0, 225)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Playback Speed: 1.0x"
SpeedLabel.TextColor3 = Theme.SubText
SpeedLabel.Font = Enum.Font.Gotham
SpeedLabel.TextSize = 12
SpeedLabel.Parent = MacroPage

-- Slider Logic
local sliding = false
SliderBg.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
UserInputService.InputChanged:Connect(function(i)
    if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
        local percent = math.clamp((i.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0.1, 3.0)
        SliderFill.Size = UDim2.new(percent / 3, 0, 1, 0)
        state.speed = percent
        SpeedLabel.Text = string.format("Playback Speed: %.1fx", state.speed)
    end
end)

-- Record Logic
local function add_event(data)
    if not state.recording then return end
    local now = tick()
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
            add_event({t="camera", x=input.Delta.X, y=input.Delta.Y})
        end
    end
end)

RecBtn.MouseButton1Click:Connect(function()
    state.recording = not state.recording
    if state.recording then
        state.events = {}; last_time = tick()
        RecBtn.Text = "⏹ Stop Recording"
        RecBtn.BackgroundColor3 = Theme.Element
        RecBtn.TextColor3 = Theme.Danger
        log("🔴 Recording...")
    else
        RecBtn.Text = "⏺ Start Recording"
        RecBtn.BackgroundColor3 = Theme.Danger
        RecBtn.TextColor3 = Theme.Text
        log("⏹ Recording Stopped.")
    end
end)

SaveBtn.MouseButton1Click:Connect(function()
    local fname = NameInput.Text
    if fname == "" then log("❌ Enter a name!") return end
    if #state.events == 0 then log("❌ No events recorded!") return end
    writefile(fname .. ".json", HttpService:JSONEncode(state.events))
    log("💾 Saved " .. fname .. ".json")
    _G.RefreshStrategies()
end)

PlayBtn.MouseButton1Click:Connect(function()
    if state.playing then state.playing = false; return end
    local fname = NameInput.Text
    if not isfile(fname .. ".json") then log("❌ File not found!") return end
    
    local data = HttpService:JSONDecode(readfile(fname .. ".json"))
    state.playing = true
    PlayBtn.Text = "⏹ Stop Playback"
    PlayBtn.BackgroundColor3 = Theme.Danger
    log("▶ Playing " .. fname .. " at " .. string.format("%.1fx", state.speed))
    
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
        PlayBtn.Text = "▶ Play Macro"
        PlayBtn.BackgroundColor3 = Theme.Accent
        log("✅ Finished.")
    end)
end)

-- ==========================================
-- 📁 STRATEGIES TAB
-- ==========================================
local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(0, 100, 0, 30)
RefreshBtn.BackgroundColor3 = Theme.Element
RefreshBtn.Text = "🔄 Refresh"
RefreshBtn.TextColor3 = Theme.Text
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.Parent = StratPage
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 6)

local FileList = Instance.new("ScrollingFrame")
FileList.Size = UDim2.new(1, -220, 1, 0)
FileList.BackgroundColor3 = Theme.Sidebar
FileList.BorderSizePixel = 0
FileList.Parent = StratPage
Instance.new("UICorner", FileList).CornerRadius = UDim.new(0, 6)
local FileLayout = Instance.new("UIListLayout", FileList)
FileLayout.Padding = UDim.new(0, 5)

_G.RefreshStrategies = function()
    for _, v in pairs(FileList:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
    local files = listfiles() or {}
    for _, file in ipairs(files) do
        if string.find(file, "%.json$") then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 30)
            btn.BackgroundColor3 = Theme.Element
            btn.Text = "📄 " .. string.gsub(file, "%.json$", "")
            btn.TextColor3 = Theme.Text
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = FileList
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            btn.MouseButton1Click:Connect(function()
                NameInput.Text = string.gsub(file, "%.json$", "")
                SwitchTab("macro")
                log("📂 Loaded " .. file)
            end)
        end
    end
    FileList.CanvasSize = UDim2.new(0, 0, 0, FileLayout.AbsoluteContentSize.Y)
end

RefreshBtn.MouseButton1Click:Connect(_G.RefreshStrategies)
SwitchTab("macro")
_G.RefreshStrategies()
log("✅ V3 UI Loaded successfully!")
