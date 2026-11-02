--[[
    🟩 TDX MACRO HUB V54 - CUSTOM 3D LAYOUT
--]]

local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

if CoreGui:FindFirstChild("TDX_NativeUI") then CoreGui.TDX_NativeUI:Destroy() end

-- ==========================================
-- 🔑 YOUR CUSTOM 3D MACRO DATA
-- ==========================================
local YOUR_JSON = [[
[{"y":16.547216415405275,"x":-57.132423400878909,"action":"place","z":-37.94575881958008,"upgrades":2,"tower":"2"},{"y":16.547216415405275,"x":-60.46790313720703,"action":"place","z":-38.06884765625,"upgrades":0,"tower":"4"},{"y":16.547216415405275,"x":-60.53814697265625,"action":"place","z":-38.01384735107422,"upgrades":0,"tower":"4"},{"y":16.547216415405275,"x":-60.61048126220703,"action":"place","z":-37.926902770996097,"upgrades":2,"tower":"4"},{"y":16.547216415405275,"x":-63.69281005859375,"action":"place","z":-37.6545295715332,"upgrades":1,"tower":"4"},{"y":16.547216415405275,"x":-44.16004943847656,"action":"cast","z":-34.6505126953125,"key":"G"},{"y":16.547216415405275,"x":-65.5914306640625,"action":"place","z":-37.44615936279297,"upgrades":0,"tower":"4"},{"y":16.547216415405275,"x":-65.08610534667969,"action":"place","z":-37.93526840209961,"upgrades":0,"tower":"4"},{"y":19.047216415405275,"x":-54.4071044921875,"action":"place","z":-39.014198303222659,"upgrades":0,"tower":"4"},{"y":16.547216415405275,"x":-59.54098892211914,"action":"place","z":-47.763370513916019,"upgrades":10,"tower":"1"},{"y":16.952802658081056,"x":-42.363807678222659,"action":"place","z":-73.71357727050781,"upgrades":0,"tower":"1"},{"y":16.547216415405275,"x":-40.28097152709961,"action":"place","z":-105.18995666503906,"upgrades":0,"tower":"3"},{"y":17.705970764160158,"x":-46.51573944091797,"action":"place","z":-114.99760437011719,"upgrades":0,"tower":"3"},{"y":17.705970764160158,"x":-39.40329360961914,"action":"place","z":-131.9550323486328,"upgrades":0,"tower":"3"},{"y":17.705963134765626,"x":-45.47077941894531,"action":"place","z":-115.96961975097656,"upgrades":0,"tower":"3"},{"y":17.705970764160158,"x":-53.509456634521487,"action":"place","z":-122.50880432128906,"upgrades":0,"tower":"3"},{"y":16.547216415405275,"x":-48.868736267089847,"action":"place","z":-111.0182876586914,"upgrades":0,"tower":"3"},{"y":16.547216415405275,"x":-58.60747528076172,"action":"place","z":-110.29446411132813,"upgrades":0,"tower":"3"},{"y":16.547216415405275,"x":-57.58295822143555,"action":"place","z":-128.09588623046876,"upgrades":0,"tower":"3"},{"y":17.705970764160158,"x":-72.60420989990235,"action":"place","z":-123.0303955078125,"upgrades":0,"tower":"3"},{"y":17.80330467224121,"x":-65.29105377197266,"action":"place","z":-101.697021484375,"upgrades":0,"tower":"3"},{"y":16.547216415405275,"x":-61.944297790527347,"action":"place","z":-132.1019287109375,"upgrades":0,"tower":"3"},{"y":16.547216415405275,"x":-59.429019927978519,"action":"place","z":-94.41914367675781,"upgrades":0,"tower":"3"},{"y":16.547216415405275,"x":-61.6287727355957,"action":"place","z":-118.44432067871094,"upgrades":0,"tower":"3"},{"y":17.819719314575197,"x":-61.97739791870117,"action":"place","z":-49.07274627685547,"upgrades":0,"tower":"1"},{"y":17.81972312927246,"x":-67.88981628417969,"action":"place","z":-49.191287994384769,"upgrades":7,"tower":"1"}]
]]

local actions = HttpService:JSONDecode(YOUR_JSON)
local isPlaying = false
local loopPlayback = false

local KeyMap = {
    ["1"] = Enum.KeyCode.One, ["2"] = Enum.KeyCode.Two, ["3"] = Enum.KeyCode.Three,
    ["4"] = Enum.KeyCode.Four, ["5"] = Enum.KeyCode.Five, ["6"] = Enum.KeyCode.Six,
}

local function vimPressKey(keyName)
    local key = KeyMap[keyName] or Enum.KeyCode[keyName]
    if key then
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end
end

local function backgroundClick(x, y)
    VirtualInputManager:SendMouseMoveEvent(x, y, workspace.CurrentCamera)
    task.wait(0.15) 
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(x, y))
    task.wait(0.1)
end

-- ==========================================
-- 🎨 NATIVE UI
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TDX_NativeUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 100, 0, 30)
ToggleBtn.Position = UDim2.new(0, 20, 0.5, -15)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
ToggleBtn.Text = "🟩 MENU (R-Ctrl)"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 260)
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", MainFrame)
stroke.Color = Color3.fromRGB(34, 197, 94)

local function toggleUI() MainFrame.Visible = not MainFrame.Visible end
ToggleBtn.MouseButton1Click:Connect(toggleUI)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "🟩 TDX MACRO V54"
Title.TextColor3 = Color3.fromRGB(34, 197, 94)
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0, 30)
Status.BackgroundTransparency = 1
Status.Text = "Status: " .. #actions .. " actions pre-loaded"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.Font = Enum.Font.Gotham
Status.Parent = MainFrame

local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(1, -20, 0, 45)
PlayBtn.Position = UDim2.new(0, 10, 0, 60)
PlayBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
PlayBtn.Text = "▶ START BUILDING (X)"
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.TextSize = 16
PlayBtn.Parent = MainFrame
Instance.new("UICorner", PlayBtn).CornerRadius = UDim.new(0, 6)

local LoopBtn = Instance.new("TextButton")
LoopBtn.Size = UDim2.new(1, -20, 0, 35)
LoopBtn.Position = UDim2.new(0, 10, 0, 115)
LoopBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
LoopBtn.Text = "Loop: OFF"
LoopBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
LoopBtn.Font = Enum.Font.GothamBold
LoopBtn.Parent = MainFrame
Instance.new("UICorner", LoopBtn).CornerRadius = UDim.new(0, 6)

local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -20, 0, 80)
Info.Position = UDim2.new(0, 10, 0, 160)
Info.BackgroundTransparency = 1
Info.Text = "This layout uses 3D World Coordinates. You can move your camera anywhere! Just make sure your camera is pointing somewhat towards the map when you start."
Info.TextColor3 = Color3.fromRGB(200, 150, 50)
Info.Font = Enum.Font.Gotham
Info.TextSize = 11
Info.TextWrapped = true
Info.Parent = MainFrame

-- ==========================================
-- CORE LOGIC
-- ==========================================
local function togglePlay()
    if #actions == 0 then return end
    isPlaying = not isPlaying
    
    if isPlaying then
        PlayBtn.Text = "⏹ STOP BUILDING"
        PlayBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        
        task.spawn(function()
            repeat
                for i, act in ipairs(actions) do
                    if not isPlaying then break end
                    
                    -- 3D TO 2D CONVERSION
                    local worldPos = Vector3.new(act.x, act.y, act.z)
                    local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(worldPos)
                    
                    if onScreen then
                        local clickX = math.floor(screenPos.X)
                        local clickY = math.floor(screenPos.Y)
                        
                        if act.action == "place" then
                            vimPressKey(act.tower)
                            task.wait(0.2)
                            backgroundClick(clickX, clickY)
                            task.wait(0.2)
                            for u = 1, act.upgrades do vimPressKey("E"); task.wait(0.3) end
                        elseif act.action == "cast" then
                            vimPressKey(act.key)
                            task.wait(0.3)
                            backgroundClick(clickX, clickY)
                            task.wait(0.3)
                        end
                    else
                        print("⚠️ Tower at " .. tostring(worldPos) .. " is off-screen! Move your camera.")
                    end
                    task.wait(0.3)
                end
                if loopPlayback and isPlaying then task.wait(5) end
            until not loopPlayback or not isPlaying
            isPlaying = false
            PlayBtn.Text = "▶ START BUILDING (X)"
            PlayBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
        end)
    else
        PlayBtn.Text = "▶ START BUILDING (X)"
        PlayBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
    end
end

PlayBtn.MouseButton1Click:Connect(togglePlay)

LoopBtn.MouseButton1Click:Connect(function()
    loopPlayback = not loopPlayback
    LoopBtn.Text = loopPlayback and "Loop: ON" or "Loop: OFF"
    LoopBtn.BackgroundColor3 = loopPlayback and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(40, 40, 40)
end)

-- ==========================================
-- GLOBAL KEYBINDS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gp)
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode.Name == "X" then togglePlay() 
    elseif input.KeyCode == Enum.KeyCode.RightControl then toggleUI() end
end)
