--[[
    🟩 TDX MACRO HUB V2.1 (Fixed)
--]]

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function log(text)
    print("[TDX Hub] " .. text)
    if _G.TDX_Console then
        _G.TDX_Console(text)
    end
end

-- 🛡️ SAFE ANTI-KICK
pcall(function()
    local oldKick
    oldKick = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() == "Kick" then
            log("🚫 ANTI-KICK: Blocked Kick!")
            return
        end
        return oldKick(self, ...)
    end)
end)

-- Anti-AFK
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
pcall(function() parentGui = gethui() end) -- Better executor compatibility
if parentGui:FindFirstChild("TDX_Hub") then parentGui.TDX_Hub:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TDX_Hub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = parentGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 550, 0, 380)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🟩 TDX LUA MACRO V2"
Title.TextColor3 = Color3.fromRGB(34, 197, 94)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Dragging
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
    end
end)
TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 120, 1, -35)
Sidebar.Position = UDim2.new(0, 0, 0, 35)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Sidebar.Parent = MainFrame

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -120, 1, -35)
ContentArea.Position = UDim2.new(0, 120, 0, 35)
ContentArea.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
ContentArea.Parent = MainFrame

local tabs, pages = {}, {}
local function SwitchTab(target)
    for name, btn in pairs(tabs) do
        btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    end
    for name, frame in pairs(pages) do
        frame.Visible = false
    end
    tabs[target].BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    pages[target].Visible = true
end

local function CreateTab(name, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamMedium
    btn.Parent = Sidebar
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 1, -20)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = ContentArea
    
    tabs[name] = btn
    pages[name] = frame
    btn.MouseButton1Click:Connect(function() SwitchTab(name) end)
    return frame
end

local RecordTab = CreateTab("record", "⏺ Record")
local PlayTab = CreateTab("play", "▶ Playback")
local StratTab = CreateTab("strat", "📁 Strategies")
SwitchTab("record")

-- Console Logger
local ConsoleBox = Instance.new("ScrollingFrame")
ConsoleBox.Size = UDim2.new(1, 0, 0, 80)
ConsoleBox.Position = UDim2.new(0, 0, 1, -80)
ConsoleBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
ConsoleBox.ScrollBarThickness = 2
ConsoleBox.Parent = ContentArea
local ConsoleLayout = Instance.new("UIListLayout", ConsoleBox)

_G.TDX_Console = function(text)
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -10, 0, 20)
    msg.BackgroundTransparency = 1
    msg.Text = "> " .. text
    msg.TextColor3 = Color3.fromRGB(34, 197, 94)
    msg.Font = Enum.Font.Code
    msg.TextSize = 11
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.Parent = ConsoleBox
    task.wait()
    ConsoleBox.CanvasSize = UDim2.new(0, 0, 0, ConsoleLayout.AbsoluteContentSize.Y)
    ConsoleBox.CanvasPosition = Vector2.new(0, ConsoleLayout.AbsoluteContentSize.Y)
end

-- ==========================================
-- ⏺ RECORD TAB
-- ==========================================
local RecBtn = Instance.new("TextButton")
RecBtn.Size = UDim2.new(1, 0, 0, 40)
RecBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
RecBtn.Text = "Start Recording"
RecBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RecBtn.Font = Enum.Font.GothamBold
RecBtn.Parent = RecordTab
Instance.new("UICorner", RecBtn).CornerRadius = UDim.new(0, 6)

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(1, 0, 0, 40)
StopBtn.Position = UDim2.new(0, 0, 0, 50)
StopBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
StopBtn.Text = "Stop & Save JSON"
StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StopBtn.Font = Enum.Font.GothamBold
StopBtn.Parent = RecordTab
Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 6)

local FileNameInput = Instance.new("TextBox")
FileNameInput.Size = UDim2.new(1, 0, 0, 30)
FileNameInput.Position = UDim2.new(0, 0, 0, 100)
FileNameInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
FileNameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
FileNameInput.PlaceholderText = "Enter Strategy Name..."
FileNameInput.Parent = RecordTab
Instance.new("UICorner", FileNameInput).CornerRadius = UDim.new(0, 6)

local is_recording = false
local events = {}
local last_time = 0

local function add_event(data)
    if not is_recording then return end
    local now = tick()
    data.delay = now - last_time
    last_time = now
    table.insert(events, data)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not is_recording then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then add_event({t = "click", x = input.Position.X, y = input.Position.Y, state = "down"})
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then add_event({t = "click", button = "right", state = "down"})
    elseif input.UserInputType == Enum.UserInputType.Keyboard then add_event({t = "key", key = input.KeyCode.Name, state = "down"}) end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed or not is_recording then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then add_event({t = "click", x = input.Position.X, y = input.Position.Y, state = "up"})
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then add_event({t = "click", button = "right", state = "up"})
    elseif input.UserInputType == Enum.UserInputType.Keyboard then add_event({t = "key", key = input.KeyCode.Name, state = "up"}) end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed or not is_recording then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            add_event({t = "camera", x = input.Delta.X, y = input.Delta.Y})
        else
            add_event({t = "move", x = input.Position.X, y = input.Position.Y})
        end
    end
end)

RecBtn.MouseButton1Click:Connect(function()
    events = {}; is_recording = true; last_time = tick()
    RecBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
    log("🔴 Recording started...")
end)

StopBtn.MouseButton1Click:Connect(function()
    if not is_recording then return end
    is_recording = false
    RecBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    
    local fname = FileNameInput.Text
    if fname == "" then fname = "TDX_Macro_" .. math.random(1000, 9999) end
    local json_data = HttpService:JSONEncode(events)
    writefile(fname .. ".json", json_data)
    log("💾 Saved " .. fname .. ".json")
    _G.RefreshStrategies()
end)

-- ==========================================
-- ▶ PLAYBACK TAB
-- ==========================================
local PlayFileInput = Instance.new("TextBox")
PlayFileInput.Size = UDim2.new(1, 0, 0, 30)
PlayFileInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
PlayFileInput.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayFileInput.PlaceholderText = "Enter Strategy Name to Play..."
PlayFileInput.Parent = PlayTab
Instance.new("UICorner", PlayFileInput).CornerRadius = UDim.new(0, 6)

local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(1, 0, 0, 40)
PlayBtn.Position = UDim2.new(0, 0, 0, 40)
PlayBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
PlayBtn.Text = "▶ Play Macro"
PlayBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.Parent = PlayTab
Instance.new("UICorner", PlayBtn).CornerRadius = UDim.new(0, 6)

local is_playing = false
PlayBtn.MouseButton1Click:Connect(function()
    if is_playing then is_playing = false; PlayBtn.Text = "▶ Play Macro"; return end
    
    local fname = PlayFileInput.Text
    if fname == "" then log("❌ Enter a file name!") return end
    if not isfile(fname .. ".json") then log("❌ File not found!") return end
    
    local success, data = pcall(function() return HttpService:JSONDecode(readfile(fname .. ".json")) end)
    if not success then log("❌ Failed to read JSON.") return end
    
    is_playing = true
    PlayBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    PlayBtn.Text = "⏹ Stop Playback"
    log("▶ Playing " .. fname)
    
    task.spawn(function()
        for _, ev in ipairs(data) do
            if not is_playing then break end
            task.wait(ev.delay)
            if ev.t == "key" then
                VirtualInputManager:SendKeyEvent(ev.state == "down", Enum.KeyCode[ev.key], false, game)
            elseif ev.t == "move" then
                VirtualInputManager:SendMouseMoveEvent(ev.x, ev.y, Camera)
            elseif ev.t == "click" then
                VirtualInputManager:SendMouseButtonEvent(ev.x or 0, ev.y or 0, (ev.button == "right") and 1 or 0, ev.state == "down", game, 1)
            end
        end
        is_playing = false
        PlayBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
        PlayBtn.Text = "▶ Play Macro"
        log("✅ Playback Finished.")
    end)
end)

-- ==========================================
-- 📁 STRATEGIES TAB
-- ==========================================
local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(0, 100, 0, 30)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
RefreshBtn.Text = "🔄 Refresh"
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.Parent = StratTab

local FileList = Instance.new("ScrollingFrame")
FileList.Size = UDim2.new(1, 0, 1, -40)
FileList.Position = UDim2.new(0, 0, 0, 40)
FileList.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
FileList.Parent = StratTab
local FileLayout = Instance.new("UIListLayout", FileList)

_G.RefreshStrategies = function()
    for _, v in pairs(FileList:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
    local files = listfiles() or {}
    for _, file in ipairs(files) do
        if string.find(file, "%.json$") then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -10, 0, 30)
            row.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            row.Parent = FileList
            
            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(1, -120, 1, 0)
            nameLbl.Position = UDim2.new(0, 5, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = "📄 " .. file
            nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Parent = row
            
            local loadBtn = Instance.new("TextButton")
            loadBtn.Size = UDim2.new(0, 50, 0, 20)
            loadBtn.Position = UDim2.new(1, -115, 0, 5)
            loadBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
            loadBtn.Text = "Load"
            loadBtn.Parent = row
            loadBtn.MouseButton1Click:Connect(function()
                PlayFileInput.Text = string.gsub(file, "%.json$", "")
                SwitchTab("play")
            end)
            
            local delBtn = Instance.new("TextButton")
            delBtn.Size = UDim2.new(0, 50, 0, 20)
            delBtn.Position = UDim2.new(1, -60, 0, 5)
            delBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            delBtn.Text = "Delete"
            delBtn.Parent = row
            delBtn.MouseButton1Click:Connect(function()
                delfile(file)
                _G.RefreshStrategies()
            end)
        end
    end
    FileList.CanvasSize = UDim2.new(0, 0, 0, FileLayout.AbsoluteContentSize.Y)
end

RefreshBtn.MouseButton1Click:Connect(_G.RefreshStrategies)

-- ==========================================
-- 📡 RADAR
-- ==========================================
local Radar = Instance.new("Frame")
Radar.Size = UDim2.new(0, 100, 0, 100)
Radar.Position = UDim2.new(1, -110, 1, -110)
Radar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Radar.Parent = MainFrame
Instance.new("UICorner", Radar).CornerRadius = UDim.new(1, 0)

local Stroke = Instance.new("UIStroke", Radar)
Stroke.Color = Color3.fromRGB(34, 197, 94)
Stroke.Thickness = 2

local Sweep = Instance.new("Frame")
Sweep.Size = UDim2.new(0.5, 0, 0, 1)
Sweep.Position = UDim2.new(0.5, 0, 0.5, 0)
Sweep.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
Sweep.AnchorPoint = Vector2.new(0, 0.5)
Sweep.Parent = Radar

RunService.RenderStepped:Connect(function()
    if Sweep and Sweep.Parent then
        Sweep.Rotation = (Sweep.Rotation + 2) % 360
    end
end)

log("✅ V2.1 Loaded successfully!")
_G.RefreshStrategies()
