--[[
    🟩 TDX MACRO HUB V28 - CONFIG AUTO-FARMER
    Reads a JSON config from GitHub to place towers automatically.
--]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ⚠️ CHANGE THIS TO YOUR GITHUB RAW LINK FOR maps.json
local CONFIG_URL = "https://raw.githubusercontent.com/Charlili-Blyte/TDX/main/maps.json"

-- ==========================================
-- 🎨 WINDUI WINDOW
-- ==========================================
local Window = WindUI:CreateWindow({
    Title = "🟩 TDX Config Farmer", 
    Folder = "TDXAuto", 
    Size = UDim2.fromOffset(600, 450),
    Transparent = true, 
    Theme = "Dark", 
    SideBarWidth = 170, 
    HasOutline = false, 
    ToggleKey = "RightShift",
})

local function Notify(title, text)
    pcall(function() Window:Notify({ Title = title, Content = text, Duration = 3 }) end)
end

-- ==========================================
-- ⚙️ CONFIG LOADER & UI
-- ==========================================
local FarmTab = Window:Tab({ Title = "Auto-Farm", Icon = "tractor" })
local AutoFarmActive = false

local MapConfigs = {} -- Stores the loaded JSON data
local CurrentMapName = "None"
local CurrentTowers = {}

local StatusLabel = FarmTab:Paragraph({ Title = "Status", Desc = "⚪ Idle. Waiting to load config..." })
local MapDropdown

FarmTab:Button({
    Title = "🔄 Load Config from GitHub",
    Callback = function()
        StatusLabel:SetDesc("🟡 Fetching config from GitHub...")
        local success, response = pcall(function() return game:HttpGet(CONFIG_URL) end)
        
        if success and response and not string.find(response, "404: Not Found") then
            local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response) end)
            if decodeSuccess and data then
                MapConfigs = data
                local mapNames = {}
                for mapName, _ in pairs(MapConfigs) do
                    table.insert(mapNames, mapName)
                end
                
                if #mapNames > 0 then
                    CurrentMapName = mapNames[1]
                    CurrentTowers = MapConfigs[CurrentMapName]
                    MapDropdown:SetValue(CurrentMapName)
                    MapDropdown:Refresh(mapNames)
                    StatusLabel:SetDesc("🟢 Loaded " .. #mapNames .. " maps. Selected: " .. CurrentMapName)
                    Notify("Success", "Config Loaded!")
                else
                    StatusLabel:SetDesc("🔴 Config is empty.")
                end
            else
                StatusLabel:SetDesc("🔴 Failed to parse JSON.")
            end
        else
            StatusLabel:SetDesc("🔴 Failed to download config. Check URL.")
            Notify("Error", "Make sure CONFIG_URL is correct and public.")
        end
    end
})

MapDropdown = FarmTab:Dropdown({
    Title = "Select Map Strategy",
    Values = {"None"},
    Callback = function(option)
        if MapConfigs[option] then
            CurrentMapName = option
            CurrentTowers = MapConfigs[option]
            StatusLabel:SetDesc("🟢 Ready: " .. CurrentMapName .. " (" .. #CurrentTowers .. " towers)")
        end
    end
})

-- ==========================================
-- 🧠 CORE LOGIC (UI FINDER & CLICKER)
-- ==========================================
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
    return false
end

local function JoinGame(difficulty)
    StatusLabel:SetDesc("🟡 Joining " .. difficulty .. "...")
    local soloBtn = find_ui_element("solo")
    if soloBtn then click_ui_element(soloBtn) else return end
    task.wait(2)
    local survBtn = find_ui_element("survival")
    if survBtn then click_ui_element(survBtn) else return end
    task.wait(2)
    local diffBtn = find_ui_element(difficulty)
    if diffBtn then click_ui_element(diffBtn) else return end
end

-- ==========================================
-- 🚜 THE AUTO-FARM LOOP
-- ==========================================
FarmTab:Toggle({
    Title = "Start Auto-Farm",
    Desc = "Automatically joins, loads map config, and places.",
    Value = false,
    Callback = function(state)
        AutoFarmActive = state
        
        if AutoFarmActive then
            if CurrentMapName == "None" or #CurrentTowers == 0 then
                Notify("Error", "Load a config and select a map first!")
                return
            end

            Notify("Auto-Farm", "Started for " .. CurrentMapName)
            task.spawn(function()
                while AutoFarmActive do
                    local inLobby = find_ui_element("solo")
                    
                    if inLobby then
                        JoinGame(CurrentMapName)
                        StatusLabel:SetDesc("🟡 Waiting for map to load (20s)...")
                        task.wait(20) 
                    else
                        StatusLabel:SetDesc("🟢 In-Game: Placing " .. #CurrentTowers .. " towers")
                        
                        for i, tower in ipairs(CurrentTowers) do
                            if not AutoFarmActive then break end
                            
                            -- Select Tower
                            keypress(tower.key)
                            task.wait(0.2)
                            keyrelease(tower.key)
                            task.wait(0.3)

                            -- Place Tower (Hardware Click)
                            mousemoveabs(tower.x, tower.y)
                            task.wait(0.1)
                            mouse1press()
                            task.wait(0.1)
                            mouse1release()
                            task.wait(0.3)

                            -- Upgrade Tower
                            for u = 1, tower.upgrade do
                                keypress("e")
                                task.wait(0.1)
                                keyrelease("e")
                                task.wait(0.2)
                            end
                            
                            task.wait(0.5) -- Short wait before next tower
                        end
                        
                        StatusLabel:SetDesc("🟢 In-Game: Waiting for cash...")
                        task.wait(5) 
                    end
                end
            end)
        else
            StatusLabel:SetDesc("⚪ Bot is Idle")
            Notify("Auto-Farm", "Bot Stopped.")
        end
    end
})

-- ==========================================
-- ⌨️ PANIC KEYBIND
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.P then
        AutoFarmActive = false
        StatusLabel:SetDesc("⚪ Bot is Idle")
        Notify("PANIC", "Auto-Farm stopped.")
    end
end)

-- Auto-load config on startup
task.spawn(function()
    task.wait(1)
    pcall(function()
        local success, response = pcall(function() return game:HttpGet(CONFIG_URL) end)
        if success and response and not string.find(response, "404: Not Found") then
            local data = HttpService:JSONDecode(response)
            if data then
                MapConfigs = data
                local mapNames = {}
                for mapName, _ in pairs(MapConfigs) do table.insert(mapNames, mapName) end
                if #mapNames > 0 then
                    CurrentMapName = mapNames[1]
                    CurrentTowers = MapConfigs[CurrentMapName]
                    MapDropdown:SetValue(CurrentMapName)
                    MapDropdown:Refresh(mapNames)
                    StatusLabel:SetDesc("🟢 Loaded: " .. CurrentMapName)
                end
            end
        end
    end)
end)
