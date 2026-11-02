--[[
    🟩 TDX MACRO - LOCKED CAMERA BACKGROUND ENGINE (V67)
--]]

local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if CoreGui:FindFirstChild("TDX_PremiumUI") then CoreGui.TDX_PremiumUI:Destroy() end

-- ==========================================
-- 🛡️ ANTI-KICK & ANTI-AFK
-- ==========================================
pcall(function()
    local oldKick = hookmetamethod(game, "__namecall", function(self, ...)
        if getnamecallmethod() == "Kick" then return end
        return oldKick(self, ...)
    end)
end)

task.spawn(function()
    player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

-- ==========================================
-- 🔑 YOUR CUSTOM JSON DATA
-- ==========================================
local YOUR_JSON = [[
[{"y":16.547216415405275,"x":-60.438072204589847,"action":"place","z":-37.13102722167969,"upgrades":0,"tower":"Two"},{"y":16.547216415405275,"x":-62.767818450927737,"action":"place","z":-35.27532196044922,"upgrades":0,"tower":"Two"},{"y":16.547216415405275,"x":-64.13795471191406,"action":"place","z":-36.81753158569336,"upgrades":0,"tower":"Four"},{"y":16.547216415405275,"x":-67.40562438964844,"action":"place","z":-37.11024475097656,"upgrades":0,"tower":"Seven"},{"y":16.547216415405275,"x":-67.61701965332031,"action":"place","z":-37.02852249145508,"upgrades":0,"tower":"Seven"},{"y":16.547216415405275,"x":-66.61177062988281,"action":"place","z":-31.423381805419923,"upgrades":0,"tower":"Seven"},{"y":16.547216415405275,"x":-66.90421295166016,"action":"place","z":-37.644596099853519,"upgrades":0,"tower":"Seven"},{"y":16.547216415405275,"x":-65.92965698242188,"action":"cast","z":-30.11572265625,"key":"G"},{"y":17.705970764160158,"x":-56.666465759277347,"action":"place","z":-40.545841217041019,"upgrades":0,"tower":"One"},{"y":17.705963134765626,"x":-55.464088439941409,"action":"place","z":-40.096466064453128,"upgrades":0,"tower":"One"},{"y":17.70596694946289,"x":-55.52960968017578,"action":"place","z":-40.72712707519531,"upgrades":0,"tower":"One"},{"y":17.705970764160158,"x":-54.19541931152344,"action":"place","z":-40.567195892333987,"upgrades":0,"tower":"One"},{"y":17.70596694946289,"x":-56.3300666809082,"action":"place","z":-41.13908767700195,"upgrades":0,"tower":"One"},{"y":17.70596694946289,"x":-54.13179016113281,"action":"place","z":-41.509788513183597,"upgrades":0,"tower":"One"},{"y":17.70596694946289,"x":-54.58381652832031,"action":"place","z":-41.10218811035156,"upgrades":0,"tower":"One"},{"y":17.70596694946289,"x":-54.07164001464844,"action":"place","z":-41.1390380859375,"upgrades":0,"tower":"One"},{"y":17.705970764160158,"x":-54.64346694946289,"action":"place","z":-41.44472885131836,"upgrades":0,"tower":"One"},{"y":17.705970764160158,"x":-54.86902618408203,"action":"place","z":-41.29194259643555,"upgrades":0,"tower":"One"},{"y":17.70596694946289,"x":-54.97953414916992,"action":"place","z":-40.965484619140628,"upgrades":0,"tower":"One"},{"y":17.70596694946289,"x":-52.18132019042969,"action":"place","z":-49.40530014038086,"upgrades":0,"tower":"One"},{"y":16.547216415405275,"x":-56.15593719482422,"action":"place","z":-48.59739685058594,"upgrades":0,"tower":"One"}]
]]

local actions = HttpService:JSONDecode(YOUR_JSON)
local isRecording = false
local isRunning = false
local savedCamera = nil
local cameraLock = nil
local upgradeIndex = 1
local lastTowerKey = "One"
local isAbilityArmed = false

local KeyMap = {
    ["One"] = Enum.KeyCode.One, ["Two"] = Enum.KeyCode.Two, ["Three"] = Enum.KeyCode.Three,
    ["Four"] = Enum.KeyCode.Four, ["Five"] = Enum.KeyCode.Five, ["Six"] = Enum.KeyCode.Six,
    ["Seven"] = Enum.KeyCode.Seven, ["Eight"] = Enum.KeyCode.Eight, ["Nine"] = Enum.KeyCode.Nine,
    ["Zero"] = Enum.KeyCode.Zero
}

local numberKeys = {
    Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five,
    Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine, Enum.KeyCode.Zero
}

-- ==========================================
-- 🧠 HELPER FUNCTIONS
-- ==========================================
local function getStats()
    local stats = player:FindFirstChild("leaderstats")
    if stats then
        local cash = stats:FindFirstChild("Cash") and stats.Cash.Value or 0
        local wave = stats:FindFirstChild("Wave") and stats.Wave.Value or 0
        return cash, wave
    end
    return 0, 0
end

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
    task.wait(0.25) 
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(x, y))
    task.wait(0.1)
end

local function get3DPosition()
    local mouse = UserInputService:GetMouseLocation()
    local ray = workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character, workspace.CurrentCamera}
    local result = workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
    return result and result.Position or nil
end

local function findUI(name)
    for _, obj in ipairs(playerGui:GetDescendants()) do
        if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Name:lower():find(name:lower()) then 
            return obj 
        end
    end
    return nil
end

local function autoJoin()
    local solo = findUI("solo")
    if solo then
        pcall(function() getconnections(solo.MouseButton1Click)[1]:Fire() end)
        task.wait(2)
        local surv = findUI("survival")
        if surv then pcall(function() getconnections(surv.MouseButton1Click)[1]:Fire() end) end
        task.wait(2)
        local easy = findUI("easy")
        if easy then pcall(function() getconnections(easy.MouseButton1Click)[1]:Fire() end) end
        task.wait(20) 
    end
end

-- ==========================================
-- 🎨 PREMIUM UI CREATION
-- ==========================================
local Theme = {
    Bg = Color3.fromRGB(15, 15, 20),
    Sidebar = Color3.fromRGB(20, 20, 25),
    Element = Color3.fromRGB(30, 30, 40),
    Accent = Color3.fromRGB(34, 197, 94),
    Danger = Color3.fromRGB(239, 68, 68),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(150, 150, 160)
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TDX_PremiumUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 100, 0, 30)
ToggleBtn.Position = UDim2.new(0, 20, 0.5, -15)
ToggleBtn.BackgroundColor3 = Theme.Accent
ToggleBtn.Text = "🟩 MENU (R-Ctrl)"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 450, 0, 340)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -170)
MainFrame.BackgroundColor3 = Theme.Bg
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", MainFrame)
stroke.Color = Theme.Element
stroke.Thickness = 1.5

local function toggleUI() MainFrame.Visible = not MainFrame.Visible end
ToggleBtn.MouseButton1Click:Connect(toggleUI)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Theme.Sidebar
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🟩 TDX LOCKED ENGINE"
Title.TextColor3 = Theme.Accent
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local TabsFrame = Instance.new("Frame")
TabsFrame.Size = UDim2.new(0, 120, 1, -35)
TabsFrame.Position = UDim2.new(0, 0, 0, 35)
TabsFrame.BackgroundColor3 = Theme.Sidebar
TabsFrame.Parent = MainFrame

local function createTabBtn(text, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.Position = UDim2.new(0, 5, 0, yPos)
    btn.BackgroundColor3 = Theme.Sidebar
    btn.Text = text
    btn.TextColor3 = Theme.SubText
    btn.Font = Enum.Font.GothamBold
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = TabsFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Element}):Play() end)
    btn.MouseLeave:Connect(function() if btn.TextColor3 ~= Theme.Accent then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Sidebar}):Play() end end)
    return btn
end

local RecTabBtn = createTabBtn("  ⏺ Recorder", 10)
local EngTabBtn = createTabBtn("  🚜 Engine", 55)

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -120, 1, -35)
ContentArea.Position = UDim2.new(0, 120, 0, 35)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local RecPage = Instance.new("Frame")
RecPage.Size = UDim2.new(1, -20, 1, -20)
RecPage.Position = UDim2.new(0, 10, 0, 10)
RecPage.BackgroundTransparency = 1
RecPage.Parent = ContentArea

local EngPage = Instance.new("Frame")
EngPage.Size = UDim2.new(1, -20, 1, -20)
EngPage.Position = UDim2.new(0, 10, 0, 10)
EngPage.BackgroundTransparency = 1
EngPage.Visible = false
EngPage.Parent = ContentArea

local function switchTab(page, btn, otherPage, otherBtn)
    page.Visible = true; btn.BackgroundColor3 = Theme.Element; btn.TextColor3 = Theme.Accent
    otherPage.Visible = false; otherBtn.BackgroundColor3 = Theme.Sidebar; otherBtn.TextColor3 = Theme.SubText
end

RecTabBtn.MouseButton1Click:Connect(function() switchTab(RecPage, RecTabBtn, EngPage, EngTabBtn) end)
EngTabBtn.MouseButton1Click:Connect(function() switchTab(EngPage, EngTabBtn, RecPage, RecTabBtn) end)
switchTab(RecPage, RecTabBtn, EngPage, EngTabBtn)

local RecStatus = Instance.new("TextLabel")
RecStatus.Size = UDim2.new(1, 0, 0, 20)
RecStatus.BackgroundTransparency = 1
RecStatus.Text = "Status: Idle (21 actions loaded)"
RecStatus.TextColor3 = Theme.Text
RecStatus.Font = Enum.Font.Gotham
RecStatus.TextXAlignment = Enum.TextXAlignment.Left
RecStatus.Parent = RecPage

local function createBtn(parent, text, color, yPos, width, xPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(width, 0, 0, 40)
    btn.Position = UDim2.new(xPos, 0, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Font = Enum.Font.GothamBold
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local RecBtn = createBtn(RecPage, "⏺ START RECORDING [Z]", Theme.Danger, 30, 1, 0)
local SaveBtn = createBtn(RecPage, "💾 Copy JSON", Theme.Accent, 80, 0.48, 0)
SaveBtn.TextColor3 = Color3.fromRGB(0,0,0)
local CamBtn = createBtn(RecPage, "📸 Save Camera", Color3.fromRGB(200, 150, 50), 80, 0.48, 0.52)
CamBtn.TextColor3 = Color3.fromRGB(0,0,0)

local EngStatus = Instance.new("TextLabel")
EngStatus.Size = UDim2.new(1, 0, 0, 40)
EngStatus.BackgroundTransparency = 1
EngStatus.Text = "Phase: Idle | Wave: 0 | Cash: $0"
EngStatus.TextColor3 = Theme.Text
EngStatus.Font = Enum.Font.Gotham
EngStatus.TextXAlignment = Enum.TextXAlignment.Left
EngStatus.TextWrapped = true
EngStatus.Parent = EngPage

local RunBtn = createBtn(EngPage, "▶ START AUTO-FARM [X]", Color3.fromRGB(59, 130, 246), 50, 1, 0)

local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, 0, 0, 100)
Info.Position = UDim2.new(0, 0, 0, 100)
Info.BackgroundTransparency = 1
Info.Text = "Camera Lock is ACTIVE. You cannot move your camera while farming to ensure 3D placements are perfect."
Info.TextColor3 = Theme.SubText
Info.Font = Enum.Font.Gotham
Info.TextSize = 12
Info.TextWrapped = true
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.Parent = EngPage

-- ==========================================
-- 🧠 LOGIC FUNCTIONS
-- ==========================================
local function updateRecStatus()
    RecStatus.Text = string.format("Status: %s (%d actions)", isRecording and "🔴 RECORDING" or "Idle", #actions)
end

local function toggleRecord()
    if isRunning then return end
    isRecording = not isRecording
    if isRecording then
        actions = {}
        RecBtn.Text = "⏹ STOP RECORDING"
        RecBtn.BackgroundColor3 = Theme.Element
        RecBtn.TextColor3 = Theme.Danger
    else
        RecBtn.Text = "⏺ START RECORDING [Z]"
        RecBtn.BackgroundColor3 = Theme.Danger
        RecBtn.TextColor3 = Theme.Text
    end
    updateRecStatus()
end

local function togglePlay()
    if #actions == 0 then return end
    isRunning = not isRunning
    if isRunning then
        if not savedCamera then savedCamera = workspace.CurrentCamera.CFrame end
        RunBtn.Text = "⏹ STOP AUTO-FARM"
        RunBtn.BackgroundColor3 = Theme.Danger
        
        -- 🟢 PUTTING THE CAMERA LOCK BACK TO FIX PLACEMENTS
        cameraLock = RunService.RenderStepped:Connect(function()
            if isRunning and savedCamera then workspace.CurrentCamera.CFrame = savedCamera end
        end)

        task.spawn(function()
            if findUI("solo") then autoJoin() end
            local hasBuilt = false
            local upgradeTimer = 0
            local abilityTimer = 0

            while isRunning do
                local cash, wave = getStats()
                
                if findUI("solo") then
                    hasBuilt = false
                    autoJoin()
                end

                if not hasBuilt then
                    EngStatus.Text = string.format("Phase: BUILDING | Wave: %d | Cash: $%d", wave, cash)
                    for _, act in ipairs(actions) do
                        if not isRunning then break end
                        if act.action == "place" then
                            local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(Vector3.new(act.x, act.y, act.z))
                            if onScreen then
                                vimPressKey(act.tower)
                                task.wait(0.2)
                                backgroundClick(math.floor(screenPos.X), math.floor(screenPos.Y))
                                task.wait(0.3)
                            end
                        end
                    end
                    hasBuilt = true
                else
                    EngStatus.Text = string.format("Phase: UPGRADING | Wave: %d | Cash: $%d", wave, cash)
                    
                    if cash > 100 then
                        upgradeTimer = upgradeTimer + 1
                        if upgradeTimer >= 2 then
                            local towerAct = actions[upgradeIndex]
                            if towerAct and towerAct.action == "place" then
                                local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(Vector3.new(towerAct.x, towerAct.y, towerAct.z))
                                if onScreen then
                                    backgroundClick(math.floor(screenPos.X), math.floor(screenPos.Y))
                                    vimPressKey("E")
                                    vimPressKey("E")
                                end
                            end
                            upgradeIndex = upgradeIndex + 1
                            if upgradeIndex > #actions then upgradeIndex = 1 end
                            upgradeTimer = 0
                        end
                    end

                    abilityTimer = abilityTimer + 1
                    if abilityTimer >= 5 then
                        for _, act in ipairs(actions) do
                            if act.action == "cast" then
                                local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(Vector3.new(act.x, act.y, act.z))
                                if onScreen then
                                    vimPressKey(act.key)
                                    task.wait(0.3)
                                    backgroundClick(math.floor(screenPos.X), math.floor(screenPos.Y))
                                end
                            end
                        end
                        abilityTimer = 0
                    end
                end
                task.wait(1)
            end
        end)
    else
        isRunning = false
        if cameraLock then cameraLock:Disconnect() end
        RunBtn.Text = "▶ START AUTO-FARM [X]"
        RunBtn.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
        EngStatus.Text = "Phase: Idle"
    end
end

RecBtn.MouseButton1Click:Connect(toggleRecord)
RunBtn.MouseButton1Click:Connect(togglePlay)

SaveBtn.MouseButton1Click:Connect(function()
    if #actions == 0 then return end
    local json = HttpService:JSONEncode(actions)
    if setclipboard then setclipboard(json) end
    print("=== JSON COPIED TO CLIPBOARD ===")
    print(json)
end)

CamBtn.MouseButton1Click:Connect(function()
    savedCamera = workspace.CurrentCamera.CFrame
    EngStatus.Text = "Phase: Camera Saved! | Wave: 0 | Cash: $0"
end)

-- ==========================================
-- 🧠 RECORDING LISTENERS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not isRecording then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local keyName = input.KeyCode.Name
        
        if keyName == "Five" then
            lastTowerKey = "Seven"
        elseif table.find(numberKeys, input.KeyCode) then
            lastTowerKey = keyName
        elseif keyName == "C" then
            vimPressKey("G")
            task.wait(0.2)
            isAbilityArmed = true
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not isRecording then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local pos = get3DPosition()
        if pos then
            if isAbilityArmed then
                table.insert(actions, { action = "cast", key = "G", x = pos.X, y = pos.Y, z = pos.Z })
                isAbilityArmed = false
            else
                table.insert(actions, { action = "place", tower = lastTowerKey, x = pos.X, y = pos.Y, z = pos.Z, upgrades = 0 })
            end
            updateRecStatus()
        end
    end
end)

-- ==========================================
-- ⌨️ GLOBAL KEYBINDS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gp)
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode.Name == "Z" then toggleRecord() end
    if input.KeyCode.Name == "X" then togglePlay() end
    if input.KeyCode == Enum.KeyCode.RightControl then toggleUI() end
end)
