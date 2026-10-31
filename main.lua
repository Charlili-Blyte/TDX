--[[
    🟩 TDX MACRO HUB V5 - NEON EDITION
    Features: Joins, Auto-Farm, Recorder, Security, Animations.
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
local playerGui = Player:WaitForChild("PlayerGui")

-- Theme
local Theme = {
    Background = Color3.fromRGB(10, 10, 15),
    Sidebar = Color3.fromRGB(15, 15, 22),
    Element = Color3.fromRGB(25, 25, 35),
    Accent = Color3.fromRGB(0, 255, 136), -- Neon Green
    Danger = Color3.fromRGB(255, 50, 100),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(140, 140, 160)
}

local function log(text)
    print("[TDX V5] " .. text)
    if _G.TDX_Console then _G.TDX_Console(text) end
end

-- ==========================================
-- 🛡️ SECURITY (ANTI-KICK / ANTI-AFK)
-- ==========================================
pcall(function()
    local oldKick = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() == "Kick" then
            log("🚫 Blocked Kick Attempt!")
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
-- 🎨 UI HELPER FUNCTIONS
-- ==========================================
local parentGui = game:GetService("CoreGui")
pcall(function() parentGui = gethui() end)
if parentGui:FindFirstChild("TDX_Hub_V5") then parentGui.TDX_Hub_V5:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TDX_Hub_V5"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parentGui

local function create(className, properties, children)
    local inst = Instance.new(className)
    for k, v in pairs(properties) do
        if k ~= "Parent" then inst[k] = v end
    end
    if children then
        for _, child in pairs(children) do child.Parent = inst end
    end
    if properties.Parent then inst.Parent = properties.Parent end
    return inst
end

local function addCorner(inst, radius)
    return create("UICorner", {CornerRadius = UDim.new(0, radius or 8), Parent = inst})
end

local function addStroke(inst, color, thickness)
    return create("UIStroke", {Color = color or Theme.Element, Thickness = thickness or 1, Parent = inst})
end

-- ==========================================
-- 🖥️ MAIN WINDOW
-- ==========================================
local Main = create("Frame", {
    Size = UDim2.new(0, 650, 0, 420),
    Position = UDim2.new(0.5, -325, 0.5, -210),
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    Parent = ScreenGui
})
addCorner(Main, 12)
addStroke(Main, Theme.Element, 1)

-- Dragging
local dragging, dragInput, dragStart, startPos
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = Main.Position
    end
end)
Main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Topbar
local TopBar = create("Frame", {
    Size = UDim2.new(1, 0, 0, 45), BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Parent = Main
})
create("TextLabel", {
    Size = UDim2.new(1, -100, 1, 0), Position = UDim2.new(0, 20, 0, 0),
    BackgroundTransparency = 1, Text = "🟩 TDX PREMIUM",
    TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar
})

local Close = create("TextButton", {
    Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -40, 0, 8),
    BackgroundColor3 = Theme.Element, Text = "✖", TextColor3 = Theme.Danger,
    Font = Enum.Font.GothamBold, Parent = TopBar
})
addCorner(Close, 6)
Close.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Sidebar
local Sidebar = create("Frame", {
    Size = UDim2.new(0, 140, 1, -45), Position = UDim2.new(0, 0, 0, 45),
    BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Parent = Main
})

-- Content Area
local Content = create("Frame", {
    Size = UDim2.new(1, -140, 1, -45), Position = UDim2.new(0, 140, 0, 45),
    BackgroundTransparency = 1, Parent = Main
})

-- Tabs
local tabs, pages = {}, {}
local currentTab = nil

local function SwitchTab(name)
    if currentTab == name then return end
    currentTab = name
    for tName, tBtn in pairs(tabs) do
        local isActive = (tName == name)
        TweenService:Create(tBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = isActive and Theme.Element or Theme.Sidebar,
            TextColor3 = isActive and Theme.Accent or Theme.SubText
        }):Play()
        if pages[tName] then pages[tName].Visible = isActive end
    end
end

local function CreateTab(name, text)
    local btn = create("TextButton", {
        Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 0, #tabs * 45 + 10),
        BackgroundColor3 = Theme.Sidebar, Text = "   " .. text, TextColor3 = Theme.SubText,
        Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Sidebar
    })
    addCorner(btn, 8)

    local frame = create("Frame", {
        Size = UDim2.new(1, -30, 1, -30), Position = UDim2.new(0, 15, 0, 15),
        BackgroundTransparency = 1, Visible = false, Parent = Content
    })
    
    tabs[name] = btn
    pages[name] = frame
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
    return frame
end

local JoinsPage = CreateTab("joins", "🌐  Joins")
local MacroPage = CreateTab("macro", "⏺  Recorder")
local FarmPage = CreateTab("farm", "🚜  Auto-Farm")

-- Console (Bottom Right)
local Console = create("ScrollingFrame", {
    Size = UDim2.new(0, 250, 0, 120), Position = UDim2.new(1, -265, 1, -135),
    BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
    ScrollBarThickness = 2, Parent = Content
})
addCorner(Console, 8)
addStroke(Console, Theme.Element, 1)
local ConsoleLayout = create("UIListLayout", {Padding = UDim.new(0, 4), Parent = Console})

_G.TDX_Console = function(text)
    local msg = create("TextLabel", {
        Size = UDim2.new(1, -10, 0, 16), BackgroundTransparency = 1,
        Text = " > " .. text, TextColor3 = Theme.Accent, Font = Enum.Font.Code,
        TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = Console
    })
    task.wait()
    Console.CanvasSize = UDim2.new(0, 0, 0, ConsoleLayout.AbsoluteContentSize.Y)
    Console.CanvasPosition = Vector2.new(0, ConsoleLayout.AbsoluteContentSize.Y)
end

-- ==========================================
-- 🌐 JOINS PAGE
-- ==========================================
-- Helper function to click UI buttons using physical mouse
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
            -- Fallback if executor lacks mouse functions
            VirtualInputManager:SendMouseMoveEvent(center_x, center_y, Camera)
            task.wait(0.1)
            VirtualInputManager:SendMouseButtonEvent(center_x, center_y, 0, true, game, 1)
            task.wait(0.1)
            VirtualInputManager:SendMouseButtonEvent(center_x, center_y, 0, false, game, 1)
            return true
        end
    else
        log("❌ Could not find button: " .. btn_name)
        return false
    end
end

local function DoJoin(difficulty)
    log("🌐 Joining Solo...")
    if not click_ui_button("PlaySolo") then return end
    task.wait(1.5)
    
    log("🌐 Selecting Survival...")
    if not click_ui_button("Survival") then return end
    task.wait(1.5)
    
    log("🌐 Selecting " .. difficulty .. "...")
    if not click_ui_button(difficulty) then return end
    
    log("✅ Join sequence complete. Loading map...")
end

local SoloEasyBtn = create("TextButton", {
    Size = UDim2.new(0, 200, 0, 45), Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Theme.Accent, Text = "▶ Play Solo (Easy)",
    TextColor3 = Color3.new(0,0,0), Font = Enum.Font.GothamBold, Parent = JoinsPage
})
addCorner(SoloEasyBtn, 8)
SoloEasyBtn.MouseButton1Click:Connect(function()
    task.spawn(function() DoJoin("Easy") end)
end)

local SoloNormalBtn = create("TextButton", {
    Size = UDim2.new(0, 200, 0, 45), Position = UDim2.new(0, 0, 0, 55),
    BackgroundColor3 = Theme.Element, Text = "▶ Play Solo (Normal)",
    TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, Parent = JoinsPage
})
addCorner(SoloNormalBtn, 8)
SoloNormalBtn.MouseButton1Click:Connect(function()
    task.spawn(function() DoJoin("Normal") end)
end)

local SoloHardBtn = create("TextButton", {
    Size = UDim2.new(0, 200, 0, 45), Position = UDim2.new(0, 0, 0, 110),
    BackgroundColor3 = Theme.Danger, Text = "▶ Play Solo (Hard)",
    TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, Parent = JoinsPage
})
addCorner(SoloHardBtn, 8)
SoloHardBtn.MouseButton1Click:Connect(function()
    task.spawn(function() DoJoin("Hard") end)
end)

-- Custom Mode Joiner
create("TextLabel", {
    Size = UDim2.new(0, 200, 0, 20), Position = UDim2.new(0, 0, 0, 170),
    BackgroundTransparency = 1, Text = "Custom Mode Name:",
    TextColor3 = Theme.SubText, Font = Enum.Font.Gotham, TextSize = 12, Parent = JoinsPage
})

local CustomInput = create("TextBox", {
    Size = UDim2.new(0, 200, 0, 35), Position = UDim2.new(0, 0, 0, 195),
    BackgroundColor3 = Theme.Element, TextColor3 = Theme.Text,
    PlaceholderText = "e.g. Endless, Coop, Group...", Font = Enum.Font.Gotham, Parent = JoinsPage
})
addCorner(CustomInput, 8)

local CustomJoinBtn = create("TextButton", {
    Size = UDim2.new(0, 200, 0, 35), Position = UDim2.new(0, 0, 0, 240),
    BackgroundColor3 = Theme.Element, Text = "🌐 Custom Join",
    TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, Parent = JoinsPage
})
addCorner(CustomJoinBtn, 8)
CustomJoinBtn.MouseButton1Click:Connect(function()
    local mode = CustomInput.Text
    if mode == "" then return end
    task.spawn(function() DoJoin(mode) end)
end)


-- ==========================================
-- ⏺ RECORDER PAGE
-- ==========================================
local state = { recording = false, playing = false, speed = 1.0, events = {} }
local last_time = 0

local RecBtn = create("TextButton", {
    Size = UDim2.new(0, 200, 0, 45), Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Theme.Danger, Text = "⏺ Start Recording",
    TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, Parent = MacroPage
})
addCorner(RecBtn, 8)

local NameInput = create("TextBox", {
    Size = UDim2.new(0, 200, 0, 35), Position = UDim2.new(0, 0, 0, 60),
    BackgroundColor3 = Theme.Element, TextColor3 = Theme.Text,
    PlaceholderText = "Enter Strategy Name...", Font = Enum.Font.Gotham, Parent = MacroPage
})
addCorner(NameInput, 8)

local SaveBtn = create("TextButton", {
    Size = UDim2.new(0, 200, 0, 35), Position = UDim2.new(0, 0, 0, 105),
    BackgroundColor3 = Theme.Accent, Text = "💾 Save Strategy",
    TextColor3 = Color3.new(0,0,0), Font = Enum.Font.GothamBold, Parent = MacroPage
})
addCorner(SaveBtn, 8)

local PlayBtn = create("TextButton", {
    Size = UDim2.new(0, 200, 0, 45), Position = UDim2.new(0, 0, 0, 160),
    BackgroundColor3 = Theme.Accent, Text = "▶ Play Macro",
    TextColor3 = Color3.new(0,0,0), Font = Enum.Font.GothamBold, Parent = MacroPage
})
addCorner(PlayBtn, 8)

-- Speed Slider
local SliderBg = create("Frame", {
    Size = UDim2.new(0, 200, 0, 6), Position = UDim2.new(0, 0, 0, 230),
    BackgroundColor3 = Theme.Element, Parent = MacroPage
})
addCorner(SliderBg, 4)

local SliderFill = create("Frame", {
    Size = UDim2.new(0.3, 0, 1, 0), BackgroundColor3 = Theme.Accent, Parent = SliderBg
})
addCorner(SliderFill, 4)

local SliderDot = create("Frame", {
    Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -7, 0.5, -7),
    BackgroundColor3 = Theme.Text, Parent = SliderFill
})
addCorner(SliderDot, 7)

local SpeedLabel = create("TextLabel", {
    Size = UDim2.new(0, 200, 0, 20), Position = UDim2.new(0, 0, 0, 245),
    BackgroundTransparency = 1, Text = "Playback Speed: 1.0x",
    TextColor3 = Theme.SubText, Font = Enum.Font.Gotham, TextSize = 12, Parent = MacroPage
})

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
        RecBtn.BackgroundColor3 = Theme.Element; RecBtn.TextColor3 = Theme.Danger
        log("🔴 Recording started...")
    else
        RecBtn.Text = "⏺ Start Recording"
        RecBtn.BackgroundColor3 = Theme.Danger; RecBtn.TextColor3 = Theme.Text
        log("⏹ Recording stopped.")
    end
end)

SaveBtn.MouseButton1Click:Connect(function()
    local fname = NameInput.Text
    if fname == "" then log("❌ Enter a name!") return end
    writefile(fname .. ".json", HttpService:JSONEncode(state.events))
    log("💾 Saved " .. fname .. ".json")
    if _G.RefreshList then _G.RefreshList() end
end)

PlayBtn.MouseButton1Click:Connect(function()
    if state.playing then state.playing = false; return end
    local fname = NameInput.Text
    if not isfile(fname .. ".json") then log("❌ File not found!") return end
    
    local data = HttpService:JSONDecode(readfile(fname .. ".json"))
    state.playing = true
    PlayBtn.Text = "⏹ Stop Playback"
    PlayBtn.BackgroundColor3 = Theme.Danger
    log("▶ Playing " .. fname)
    
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
-- 🚜 AUTO-FARM PAGE
-- ==========================================
local farm_active = false

local ToggleBg = create("Frame", {
    Size = UDim2.new(0, 50, 0, 26), Position = UDim2.new(0, 0, 0, 10),
    BackgroundColor3 = Theme.Element, Parent = FarmPage
})
addCorner(ToggleBg, 13)

local ToggleDot = create("Frame", {
    Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, 3, 0.5, -10),
    BackgroundColor3 = Theme.Text, Parent = ToggleBg
})
addCorner(ToggleDot, 10)

local ToggleBtn = create("TextButton", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = ToggleBg
})

local FarmLabel = create("TextLabel", {
    Size = UDim2.new(1, -60, 0, 30), Position = UDim2.new(0, 60, 0, 8),
    BackgroundTransparency = 1, Text = "Auto-Farm TDX (Easy)",
    TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = FarmPage
})

ToggleBtn.MouseButton1Click:Connect(function()
    farm_active = not farm_active
    if farm_active then
        TweenService:Create(ToggleBg, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
        TweenService:Create(ToggleDot, TweenInfo.new(0.2), {Position = UDim2.new(1, -23, 0.5, -10)}):Play()
        log("🚜 Auto-Farm Enabled. (Requires map grid setup!)")
    else
        TweenService:Create(ToggleBg, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Element}):Play()
        TweenService:Create(ToggleDot, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -10)}):Play()
        log("🛑 Auto-Farm Disabled.")
    end
end)

local FarmDesc = create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 100), Position = UDim2.new(0, 0, 0, 60),
    BackgroundTransparency = 1, Text = "Note: Auto-Farm requires you to set up your map grid inside the script. This UI is the visual toggle for the logic.",
    TextColor3 = Theme.SubText, Font = Enum.Font.Gotham, TextSize = 12,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = FarmPage
})

-- ==========================================
-- 📁 STRATEGIES (Integrated into Recorder Page)
-- ==========================================
local FileList = create("ScrollingFrame", {
    Size = UDim2.new(0, 200, 0, 120), Position = UDim2.new(0, 220, 0, 0),
    BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0,
    ScrollBarThickness = 2, Parent = MacroPage
})
addCorner(FileList, 8)
addStroke(FileList, Theme.Element, 1)
local FileLayout = create("UIListLayout", {Padding = UDim.new(0, 4), Parent = FileList})

_G.RefreshList = function()
    for _, v in pairs(FileList:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
    local files = listfiles() or {}
    for _, file in ipairs(files) do
        if string.find(file, "%.json$") then
            local btn = create("TextButton", {
                Size = UDim2.new(1, -8, 0, 24), BackgroundColor3 = Theme.Element,
                Text = "📄 " .. string.gsub(file, "%.json$", ""), TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left, TextSize = 11, Parent = FileList
            })
            addCorner(btn, 4)
            btn.MouseButton1Click:Connect(function()
                NameInput.Text = string.gsub(file, "%.json$", "")
                log("📂 Selected " .. file)
            end)
        end
    end
    FileList.CanvasSize = UDim2.new(0, 0, 0, FileLayout.AbsoluteContentSize.Y)
end

-- Start
SwitchTab("joins")
_G.RefreshList()
log("✅ V5 UI Loaded.")
