--[[
    🟩 TDX MACRO HUB V29 - AUTONOMOUS SCANNER
    Auto-detects valid tower spots by reading your cash.
--]]

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local Window = WindUI:CreateWindow({
    Title = "🟩 TDX Scanner", 
    Folder = "TDXAuto", 
    Size = UDim2.fromOffset(650, 500),
    Transparent = true, Theme = "Dark", SideBarWidth = 170, HasOutline = false, ToggleKey = "RightShift",
})

local function Notify(title, text)
    pcall(function() Window:Notify({ Title = title, Content = text, Duration = 3 }) end)
end

-- ==========================================
-- 🧠 SCANNER LOGIC
-- ==========================================
local ScanTab = Window:Tab({ Title = "Auto-Scanner", Icon = "search" })
local isScanning = false
local foundSpots = {}

local StatusLabel = ScanTab:Paragraph({ Title = "Status", Desc = "⚪ Ready to scan." })

-- Function to get current cash safely
local function getCash()
    local stats = player:FindFirstChild("leaderstats")
    if stats and stats:FindFirstChild("Cash") then
        return stats.Cash.Value
    end
    return 0
end

ScanTab:Button({
    Title = "🔍 Start Auto-Scan (Needs 10k+ Cash)",
    Callback = function()
        if isScanning then return end
        isScanning = true
        foundSpots = {}
        StatusLabel:SetDesc("🟡 Scanning... Do not move your mouse!")
        
        task.spawn(function()
            -- Wait for player to be fully loaded
            task.wait(2)
            
            -- Grid Settings (Adjust these based on your resolution)
            local startX, endX, stepX = 400, 1000, 60
            local startY, endY, stepY = 300, 650, 60
            
            for y = startY, endY, stepY do
                for x = startX, endX, stepX do
                    if not isScanning then break end
                    
                    -- Select Farm
                    keypress("1")
                    task.wait(0.1)
                    keyrelease("1")
                    task.wait(0.1)
                    
                    local oldCash = getCash()
                    
                    -- Move mouse and click
                    mousemoveabs(x, y)
                    task.wait(0.1)
                    mouse1press()
                    task.wait(0.1)
                    mouse1release()
                    task.wait(0.2) -- Wait for server to register
                    
                    local newCash = getCash()
                    
                    if newCash < oldCash then
                        -- CASH DROPPED! It's a valid spot.
                        table.insert(foundSpots, {x = x, y = y})
                        StatusLabel:SetDesc("🟢 Found " .. #foundSpots .. " spots!")
                        
                        -- Upgrade it twice to secure it
                        keypress("e")
                        task.wait(0.1)
                        keyrelease("e")
                        task.wait(0.1)
                        keypress("e")
                        task.wait(0.1)
                        keyrelease("e")
                    end
                    task.wait(0.1)
                end
                if not isScanning then break end
            end
            
            isScanning = false
            StatusLabel:SetDesc("✅ Scan complete! Found " .. #foundSpots .. " spots.")
            Notify("Scanner", "Scan finished. Check the JSON box.")
            
            -- Generate JSON
            local jsonOutput = "{\n  \"MyMap\": [\n"
            for i, spot in ipairs(foundSpots) do
                jsonOutput = jsonOutput .. string.format('    {"key": "1", "x": %d, "y": %d, "upgrade": 2}', spot.x, spot.y)
                if i < #foundSpots then jsonOutput = jsonOutput .. ",\n" else jsonOutput = jsonOutput .. "\n" end
            end
            jsonOutput = jsonOutput .. "  ]\n}"
            
            _G.JsonOutputBox:SetValue(jsonOutput)
        end)
    end
})

ScanTab:Button({
    Title = "⏹ Stop Scan",
    Callback = function()
        isScanning = false
        StatusLabel:SetDesc("🔴 Scan stopped.")
    end
})

ScanTab:Divider()

ScanTab:Paragraph({ Title = "Output", Desc = "Copy this JSON and paste it into your maps.json on GitHub." })
_G.JsonOutputBox = ScanTab:Input({ Title = "Generated JSON", Placeholder = "Found spots will appear here...", Callback = function() end })

-- ==========================================
-- 🚜 AUTO-FARM TAB (From V28)
-- ==========================================
local FarmTab = Window:Tab({ Title = "Auto-Farm", Icon = "tractor" })
local CONFIG_URL = "https://raw.githubusercontent.com/Charlili-Blyte/TDX/main/maps.json"
local MapConfigs = {}
local CurrentTowers = {}
local AutoFarmActive = false

local FarmStatus = FarmTab:Paragraph({ Title = "Status", Desc = "⚪ Idle" })
local MapDropdown

FarmTab:Button({
    Title = "🔄 Load Config from GitHub",
    Callback = function()
        local success, response = pcall(function() return game:HttpGet(CONFIG_URL) end)
        if success and response and not string.find(response, "404: Not Found") then
            local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(response) end)
            if decodeSuccess and data then
                MapConfigs = data
                local mapNames = {}
                for mapName, _ in pairs(MapConfigs) do table.insert(mapNames, mapName) end
                if #mapNames > 0 then
                    CurrentTowers = MapConfigs[mapNames[1]]
                    MapDropdown:Refresh(mapNames)
                    MapDropdown:SetValue(mapNames[1])
                    FarmStatus:SetDesc("🟢 Config Loaded!")
                end
            end
        end
    end
})

MapDropdown = FarmTab:Dropdown({
    Title = "Select Map",
    Values = {"None"},
    Callback = function(option)
        if MapConfigs[option] then CurrentTowers = MapConfigs[option] end
    end
})

FarmTab:Toggle({
    Title = "Start Auto-Farm",
    Value = false,
    Callback = function(state)
        AutoFarmActive = state
        if AutoFarmActive then
            task.spawn(function()
                while AutoFarmActive do
                    local soloBtn = nil
                    for _, obj in ipairs(playerGui:GetDescendants()) do
                        if obj.Name == "PlaySolo" then soloBtn = obj break end
                    end
                    
                    if soloBtn then
                        -- Need to join (use V28 logic here)
                        FarmStatus:SetDesc("🟡 Joining...")
                        task.wait(20)
                    else
                        FarmStatus:SetDesc("🟢 Farming...")
                        for i, tower in ipairs(CurrentTowers) do
                            if not AutoFarmActive then break end
                            keypress(tower.key)
                            task.wait(0.1)
                            keyrelease(tower.key)
                            mousemoveabs(tower.x, tower.y)
                            task.wait(0.1)
                            mouse1press()
                            task.wait(0.1)
                            mouse1release()
                            for u = 1, tower.upgrade do
                                keypress("e")
                                task.wait(0.1)
                                keyrelease("e")
                                task.wait(0.1)
                            end
                            task.wait(0.5)
                        end
                        task.wait(5)
                    end
                end
            end)
        end
    end
})
