--[[
    🟩 TDX MACRO HUB V58 - SIMPLE AUTO-FARMER
--]]

local VirtualInputManager = game:GetService("VirtualInputManager")
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
local isFarming = false

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

local function performClick(x, y)
    VirtualInputManager:SendMouseMoveEvent(x, y, workspace.CurrentCamera)
    task.wait(0.25) 
    game:GetService("VirtualUser"):CaptureController()
    game:GetService("VirtualUser"):ClickButton1(Vector2.new(x, y))
    task.wait(0.1)
end

-- ==========================================
-- 🎨 SIMPLE UI
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TDX_NativeUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 150)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", MainFrame)
stroke.Color = Color3.fromRGB(34, 197, 94)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "🟩 TDX AUTO-FARM"
Title.TextColor3 = Color3.fromRGB(34, 197, 94)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 50)
ToggleBtn.Position = UDim2.new(0, 10, 0, 50)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
ToggleBtn.Text = "▶ START FARMING"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 16
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 30)
Status.Position = UDim2.new(0, 10, 0, 110)
Status.BackgroundTransparency = 1
Status.Text = "Status: Idle"
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.Parent = MainFrame

-- ==========================================
-- CORE LOOP (Build, Upgrade, Repeat)
-- ==========================================
ToggleBtn.MouseButton1Click:Connect(function()
    isFarming = not isFarming
    
    if isFarming then
        ToggleBtn.Text = "⏹ STOP FARMING"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        Status.Text = "Status: Aim Camera! Starting in 3s..."
        
        task.spawn(function()
            task.wait(3)
            
            local isFirstLoop = true
            
            while isFarming do
                for i, act in ipairs(actions) do
                    if not isFarming then break end
                    
                    local worldPos = Vector3.new(act.x, act.y, act.z)
                    local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(worldPos)
                    
                    if onScreen then
                        local clickX = math.floor(screenPos.X)
                        local clickY = math.floor(screenPos.Y)
                        
                        if act.action == "place" then
                            -- Only press the tower key on the first loop (to place them)
                            if isFirstLoop then
                                vimPressKey(act.tower)
                                task.wait(0.2)
                            end
                            
                            -- Click the spot (places tower first loop, upgrades it later)
                            performClick(clickX, clickY)
                            task.wait(0.2)
                            
                            -- Press E (Upgrade). If first loop, do recorded amount. If later, spam it.
                            local upgradesToDo = isFirstLoop and act.upgrades or 2
                            for u = 1, upgradesToDo do 
                                vimPressKey("E")
                                task.wait(0.2) 
                            end
                            
                        elseif act.action == "cast" then
                            vimPressKey(act.key)
                            task.wait(0.3)
                            performClick(clickX, clickY)
                            task.wait(0.3)
                        end
                    end
                    task.wait(0.1)
                end
                
                isFirstLoop = false
                Status.Text = "Status: Looping upgrades & abilities..."
                task.wait(2) -- Wait 2 seconds before looping again
            end
            
            ToggleBtn.Text = "▶ START FARMING"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
            Status.Text = "Status: Stopped"
        end)
    else
        ToggleBtn.Text = "▶ START FARMING"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
        Status.Text = "Status: Stopped"
    end
end)
