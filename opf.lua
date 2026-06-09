local Players = game:GetService("Players")
if not game:IsLoaded() then game.Loaded:Wait() end
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- ดึง Whitelist + HWID จาก GitHub
local WhitelistHWID = {}
local AdminList = {}
local ok, data = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/chanami2019-png/Whitelist/main/whitelist.txt")
end)
if ok and data then
    local section = "USER"
    for line in data:gmatch("[^\r\n]+") do
        if line:match("^%[ADMIN%]") then section = "ADMIN"
        elseif line:match("^%[USER%]") then section = "USER"
        elseif not line:match("^#") and line:match("%S") then
            if section == "ADMIN" then
                local uid, hwid = line:match("^(%d+):(.+)$")
                if uid then
                    WhitelistHWID[hwid] = true
                    AdminList[tonumber(uid)] = hwid
                end
            else
                local hwid = line:match("^(.+)$")
                if hwid then WhitelistHWID[hwid] = true end
            end
        end
    end
end

local myUserId = LocalPlayer.UserId
local myHWID = ""
pcall(function() myHWID = gethwid() end)
local isAdmin = false

if WhitelistHWID[myHWID] then
    if AdminList[myUserId] then isAdmin = true end
else
    pcall(function()
        local http = game:GetService("HttpService")
        local body = http:JSONEncode({
            content = "**HWID Register**\nUserID: `" .. tostring(myUserId) .. "`\nUsername: `" .. LocalPlayer.Name .. "`\nHWID: `" .. myHWID .. "`"
        })
        local req = (syn and syn.request) or (http_request) or (fluxus and fluxus.request) or request or http.RequestAsync
        req({
            Url = "https://discord.com/api/webhooks/1513103719821217885/8yWhIK91brRZOlvETFfSFlRVWEjojcFdfxHu14xYtKGDKWqjzjf9BRA7p5_g3qt_0H_d",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = body
        })
    end)
    task.wait(1)
    LocalPlayer:Kick("รอรับ Hwid ไอโง่ ส่งชื่อในเกมไปในดิสได้เลย")
    return
end

-- Anti Afk
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Finzer " .. Fluent.Version,
    SubTitle = "by Saintswiz",
    TabWidth = 120,
    Size = UDim2.fromOffset(420, 360),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftAlt
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Main4 = Window:AddTab({ Title = "Sam", Icon = "" }),
    Island = Window:AddTab({ Title = "Island", Icon = "" }),
    Npc = Window:AddTab({ Title = "Npc", Icon = "" }),
    Affinity = Window:AddTab({ Title = "Affinity", Icon = "" }),
    Alert = Window:AddTab({ Title = "Hunter Fruit", Icon = "" }),
    PlayerTab = Window:AddTab({ Title = "Players", Icon = "" }),
    Quest = Window:AddTab({ Title = "Quest", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Haki tab เฉพาะแอดมินเท่านั้น
if isAdmin then
    Tabs.Haki = Window:AddTab({ Title = "Haki", Icon = "" })
end

local Options = Fluent.Options

-- =============================================
-- SERVICES
-- =============================================
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- =============================================
-- HELPER FUNCTIONS (ใช้ร่วมกันทุกที่)
-- =============================================
local function getconnect(targetButton)
    local events = { "Activated", "MouseButton1Down", "MouseButton1Click", "MouseButton1Up" }
    for _, eventName in next, events do
        pcall(function()
            for _, connection in next, getconnections(targetButton[eventName]) do
                pcall(function() connection.Function() end)
            end
        end)
    end
end

local function warpToNPC(character, npc)
    if character:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
    end
end

local function interactNPC(npc)
    for _, v in pairs(npc:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            pcall(function()
                v.MaxActivationDistance = math.huge
                v.HoldDuration = 0
                v.RequiresLineOfSight = false
                fireproximityprompt(v)
            end)
        end
        if v:IsA("ClickDetector") then
            pcall(function() fireclickdetector(v) end)
        end
    end
end

local function clickDialogue(gui)
    local dialogue = gui:FindFirstChild("QuestGui") and gui.QuestGui:FindFirstChild("Dialogue")
    if dialogue and dialogue.Visible then
        pcall(function()
            local option = dialogue.Options:FindFirstChild("Option")
            if option and option.Visible then
                getconnect(option) task.wait(0.2)
                getconnect(option) task.wait(0.2)
                getconnect(option)
            end
        end)
        task.wait(0.3)
        pcall(function()
            local leave = dialogue.Options:FindFirstChild("Leave")
            if leave then getconnect(leave) end
        end)
    end
end

local function receiveQuest(character, gui, npc, globalFlag, questName)
    warpToNPC(character, npc)
    task.wait(0.5)
    repeat
        if not _G[globalFlag] then break end
        interactNPC(npc)
        clickDialogue(gui)
        task.wait(0.5)
    until (pcall(function() return gui.QuestGui.QuestsFrame.QuestName.Text == questName end) and gui.QuestGui.QuestsFrame.QuestName.Text == questName) or not _G[globalFlag]
end

local function hasQuest(gui, questName)
    local ok, result = pcall(function() return gui.QuestGui.QuestsFrame.QuestName.Text end)
    return ok and result == questName
end

local function questScrollText(gui, index)
    local ok, result = pcall(function()
        return gui.QuestGui.QuestsFrame.QuestsScroll:GetChildren()[index].Text
    end)
    return ok and result or ""
end

local function fightMob(character, mobNamePattern, globalFlag, doneFunc)
    local HRP = character:FindFirstChild("HumanoidRootPart")
    local Humanoid = character:FindFirstChildOfClass("Humanoid")
    local Backpack = LocalPlayer:FindFirstChild("Backpack")

    local Tool = character:FindFirstChild("Kogatana") or Backpack:FindFirstChild("Kogatana")
    if Tool then pcall(function() Humanoid:EquipTool(Tool) end) end

    local aliveFolder = workspace:FindFirstChild("Alive")
    if not aliveFolder then task.wait(1) return end

    for _, mob in ipairs(aliveFolder:GetChildren()) do
        if not _G[globalFlag] or doneFunc() then break end
        if mob and mob.Parent and string.find(mob.Name, mobNamePattern) then
            local mobHum = mob:FindFirstChildOfClass("Humanoid")
            local mobHRP = mob:FindFirstChild("HumanoidRootPart")
            if mobHum and mobHRP and mobHum.Health > 0 then
                while _G[globalFlag] and not doneFunc() and mob.Parent and mobHum and mobHRP and mobHum.Health > 0 do
                    if not mobHRP.Parent then break end
                    if mobHum.Health <= (mobHum.MaxHealth * 0.7) then
                        mobHum.Health = 0
                        break
                    end
                    local behindPos = mobHRP.Position - (mobHRP.CFrame.LookVector * 1) + Vector3.new(0, 1, 0)
                    pcall(function() HRP.CFrame = CFrame.new(behindPos) * (mobHRP.CFrame - mobHRP.Position) end)
                    local equipped = character:FindFirstChild("Kogatana")
                    if not equipped then
                        local inBag = Backpack:FindFirstChild("Kogatana")
                        if inBag then pcall(function() Humanoid:EquipTool(inBag) end) end
                    end
                    pcall(function()
                        local t = character:FindFirstChild("Kogatana")
                        if t then t:Activate() end
                    end)
                    task.wait()
                    mobHum = mob:FindFirstChildOfClass("Humanoid")
                    mobHRP = mob:FindFirstChild("HumanoidRootPart")
                    if not mobHum or not mobHRP then break end
                end
                task.wait()
            end
        end
    end
end

-- =============================================
-- MOBILE CTRL BUTTON
-- =============================================
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MobileControlButton"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Button = Instance.new("TextButton")
Button.Parent = ScreenGui
Button.Size = UDim2.fromOffset(55, 55)
Button.AnchorPoint = Vector2.new(1, 0)
Button.Position = UDim2.new(1, -20, 0, 80)
Button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Button.BackgroundTransparency = 0.2
Button.BorderSizePixel = 0
Button.Text = "Alt"
Button.TextScaled = true
Button.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", Button).CornerRadius = UDim.new(1, 0)

Button.MouseButton1Click:Connect(function()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftAlt, false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftAlt, false, game)
end)

-- =============================================
-- BLACKLIST & MOB FILTER
-- =============================================
local blacklist = { ["Lv2000 Crocodile"] = true, ["Lv20000 Whitebeard"] = true, ["Lv8000 Gunner Captain"] = true, ["Lv2000 Vokun"] = true }

local function isTargetMob(name)
    if blacklist[name] then return false end
    local level = tonumber(string.match(name, "^Lv(%d+)"))
    return level and level >= 19
end

-- =============================================
-- MAIN TAB
-- =============================================
Tabs.Main:AddParagraph({ Title = "Tool & Combat", Content = "" })

-- Auto Equip Tool
_G.AutoEquipTool = false
_G.SelectedToolName = nil

local function GetToolList()
    local tools = {}
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    local Character = LocalPlayer.Character
    if Backpack then
        for _, item in ipairs(Backpack:GetChildren()) do
            if item:IsA("Tool") then table.insert(tools, item.Name) end
        end
    end
    if Character then
        for _, item in ipairs(Character:GetChildren()) do
            if item:IsA("Tool") then table.insert(tools, item.Name) end
        end
    end
    if #tools == 0 then table.insert(tools, "No Tools") end
    return tools
end

local ToolDropdown = Tabs.Main:AddDropdown("ToolDropdown", {
    Title = "Select Tool",
    Values = GetToolList(),
    Multi = false,
    Default = 1,
})
_G.SelectedToolName = ToolDropdown.Value
ToolDropdown:OnChanged(function(value) _G.SelectedToolName = value end)

Tabs.Main:AddButton({
    Title = "Refresh Tools",
    Description = "Refresh Backpack & Character tools",
    Callback = function()
        local newList = GetToolList()
        ToolDropdown:SetValues(newList)
        ToolDropdown:SetValue(newList[1])
        _G.SelectedToolName = newList[1]
    end
})

local AutoEquipToggle = Tabs.Main:AddToggle("AutoEquipTool", { Title = "Auto Equip Tool", Default = false })
AutoEquipToggle:OnChanged(function(state)
    _G.AutoEquipTool = state
    if state then
        task.spawn(function()
            while _G.AutoEquipTool do
                local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local Humanoid = Character:FindFirstChildOfClass("Humanoid")
                local Backpack = LocalPlayer:FindFirstChild("Backpack")
                if _G.SelectedToolName and _G.SelectedToolName ~= "No Tools" and Humanoid and Backpack then
                    local Tool = Backpack:FindFirstChild(_G.SelectedToolName) or Character:FindFirstChild(_G.SelectedToolName)
                    if Tool and Tool:IsA("Tool") then pcall(function() Humanoid:EquipTool(Tool) end) end
                end
                task.wait(0.3)
            end
        end)
    end
end)
AutoEquipToggle:SetValue(false)

-- Auto Click
_G.AutoClick = false
local ClickToggle = Tabs.Main:AddToggle("AutoClick", { Title = "Auto Click", Default = false })
ClickToggle:OnChanged(function(state)
    _G.AutoClick = state
    if state then
        task.spawn(function()
            while _G.AutoClick do
                local camera = workspace.CurrentCamera
                if camera then
                    local x, y = camera.ViewportSize.X / 4, camera.ViewportSize.Y / 4
                    pcall(function()
                        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
                        task.wait()
                        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
                    end)
                end
                task.wait(0.2)
            end
        end)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    local newList = GetToolList()
    ToolDropdown:SetValues(newList)
    if _G.SelectedToolName then ToolDropdown:SetValue(_G.SelectedToolName) end
end)

-- Auto R (Observation) — Main tab copy
local MainAutoRToggle = Tabs.Main:AddToggle("MainAutoR", { Title = "Auto R (Observation)", Default = false })
MainAutoRToggle:OnChanged(function(state)
    _G.AutoR = state
    if state then
        task.spawn(function()
            while _G.AutoR do
                if not isObservationActive() and getHakiPercent() >= 80 then
                    repeat
                        if not _G.AutoR then break end
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
                        task.wait(0.2)
                    until isObservationActive() or not _G.AutoR
                end
                task.wait(0.5)
            end
        end)
    end
end)

-- Auto Q (Haki) — Main tab copy
local MainAutoQToggle = Tabs.Main:AddToggle("MainAutoQ", { Title = "Auto Q (Haki)", Default = false })
MainAutoQToggle:OnChanged(function(state)
    _G.AutoQ = state
    if state then
        task.spawn(function()
            while _G.AutoQ do
                if not isHakiActive() and getHakiPercent() >= 80 then
                    repeat
                        if not _G.AutoQ then break end
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                        task.wait(0.2)
                    until isHakiActive() or not _G.AutoQ
                end
                task.wait(0.5)
            end
        end)
    end
end)

Tabs.Main:AddParagraph({ Title = "Farm", Content = "" })

-- Auto Farm
_G.AutoFarm = false
local FarmToggle = Tabs.Main:AddToggle("AutoFarm", { Title = "Auto Farm", Default = false })
FarmToggle:OnChanged(function(state)
    _G.AutoFarm = state
    if state then
        task.spawn(function()
            while _G.AutoFarm do
                local Character = LocalPlayer.Character
                if not Character then LocalPlayer.CharacterAdded:Wait() Character = LocalPlayer.Character end
                local HRP = Character:FindFirstChild("HumanoidRootPart")
                local Humanoid = Character:FindFirstChildOfClass("Humanoid")
                if not HRP or not Humanoid then task.wait(0.5) continue end

                local aliveFolder = workspace:FindFirstChild("Alive")
                if aliveFolder then
                    for _, mob in ipairs(aliveFolder:GetChildren()) do
                        if not _G.AutoFarm or _G.FightingBoss then break end
                        if mob and mob.Parent and isTargetMob(mob.Name) then
                            local mobHum = mob:FindFirstChildOfClass("Humanoid")
                            local mobHRP = mob:FindFirstChild("HumanoidRootPart")
                            if mobHum and mobHRP and mobHum.Health > 0 then
                                while _G.AutoFarm and Character.Parent and mob.Parent and mobHum and mobHRP and mobHum.Health > 0 do
                                    if not mobHRP.Parent then break end
                                    if mobHum.Health <= (mobHum.MaxHealth * 0.7) then mobHum.Health = 0 break end
                                    local behindPos = mobHRP.Position - (mobHRP.CFrame.LookVector * 2)
                                    HRP.CFrame = CFrame.new(behindPos) * (mobHRP.CFrame - mobHRP.Position)
                                    task.wait()
                                    mobHum = mob:FindFirstChildOfClass("Humanoid")
                                    mobHRP = mob:FindFirstChild("HumanoidRootPart")
                                    if not mobHum or not mobHRP then break end
                                end
                                task.wait()
                            end
                        end
                    end
                end
                task.wait()
            end
        end)
    end
end)
FarmToggle:SetValue(false)

-- Auto Boss
_G.AutoBoss = false
_G.SelectedBosses = {}
_G.FightingBoss = false

local BossNames = { "Lv2000 Crocodile", "Lv20000 Whitebeard", "Lv8000 Gunner Captain", "Lv2000 Vokun" }

local BossDropdown = Tabs.Main:AddDropdown("BossSelect", {
    Title = "Select Boss",
    Values = BossNames,
    Multi = true,
    Default = {},
})
BossDropdown:OnChanged(function(val)
    local selected = {}
    for k, v in pairs(val) do
        if v then table.insert(selected, k) end
    end
    _G.SelectedBosses = selected
end)

local BossToggle = Tabs.Main:AddToggle("AutoBoss", { Title = "Auto Boss", Default = false })
BossToggle:OnChanged(function(state)
    _G.AutoBoss = state
    if not state then _G.FightingBoss = false return end
    task.spawn(function()
        while _G.AutoBoss do
            -- รอให้ตัวละครมีชีวิตก่อน (ถ้าตายอยู่จะรอจนเกิดใหม่)
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local myHum = Character:FindFirstChildOfClass("Humanoid")
            if not myHum or myHum.Health <= 0 then
                LocalPlayer.CharacterAdded:Wait()
                task.wait(2)
                Character = LocalPlayer.Character
                myHum = Character and Character:FindFirstChildOfClass("Humanoid")
            end

            if Character and myHum and myHum.Health > 0 then
                local aliveFolder = workspace:FindFirstChild("Alive")
                if aliveFolder and #_G.SelectedBosses > 0 then
                    for _, bossName in ipairs(_G.SelectedBosses) do
                        if not _G.AutoBoss then break end
                        local boss = aliveFolder:FindFirstChild(bossName)
                        if boss then
                            local bossHum = boss:FindFirstChildOfClass("Humanoid")
                            local bossHRP = boss:FindFirstChild("HumanoidRootPart")
                            if bossHum and bossHRP and bossHum.Health > 0 then
                                local wasFarming = _G.AutoFarm
                                if wasFarming then _G.AutoFarm = false task.wait(0.3) end
                                _G.FightingBoss = true

                                Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                                local HRP = Character:FindFirstChild("HumanoidRootPart")
                                if HRP then
                                    while _G.AutoBoss and boss and boss.Parent and bossHum and bossHRP and bossHum.Health > 0 do
                                        if not bossHRP.Parent then break end
                                        -- เช็คว่าตัวเองตายไหม ถ้าตายก็ break ออกไปรอเกิดใหม่
                                        local myChar = LocalPlayer.Character
                                        local myH = myChar and myChar:FindFirstChildOfClass("Humanoid")
                                        if not myH or myH.Health <= 0 then break end
                                        HRP = myChar:FindFirstChild("HumanoidRootPart")
                                        if not HRP then break end

                                        if bossHum.Health <= (bossHum.MaxHealth * 0.7) then bossHum.Health = 0 break end
                                        local behindPos = bossHRP.Position - (bossHRP.CFrame.LookVector * 2)
                                        pcall(function() HRP.CFrame = CFrame.new(behindPos) * (bossHRP.CFrame - bossHRP.Position) end)
                                        task.wait()
                                        bossHum = boss:FindFirstChildOfClass("Humanoid")
                                        bossHRP = boss:FindFirstChild("HumanoidRootPart")
                                        if not bossHum or not bossHRP then break end
                                    end
                                end

                                _G.FightingBoss = false
                                if wasFarming then FarmToggle:SetValue(true) end
                            end
                        end
                    end
                end
            end
            task.wait(1)
        end
    end)
end)

-- Find Refruit (Auto ตี Vokun)
_G.FindRefruit = false
local RefruitToggle = Tabs.Main:AddToggle("FindRefruit", { Title = "Find Refruit", Default = false })
RefruitToggle:OnChanged(function(state)
    _G.FindRefruit = state
    if state then
        task.spawn(function()
            while _G.FindRefruit do
                -- รอให้ตัวละครมีชีวิตก่อน
                local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local myHum = Character:FindFirstChildOfClass("Humanoid")
                if not myHum or myHum.Health <= 0 then
                    LocalPlayer.CharacterAdded:Wait()
                    task.wait(2)
                    Character = LocalPlayer.Character
                    myHum = Character and Character:FindFirstChildOfClass("Humanoid")
                end

                if Character and myHum and myHum.Health > 0 then
                    local aliveFolder = workspace:FindFirstChild("Alive")
                    if aliveFolder then
                        local vokun = aliveFolder:FindFirstChild("Lv2000 Vokun")
                        if vokun then
                            local bossHum = vokun:FindFirstChildOfClass("Humanoid")
                            local bossHRP = vokun:FindFirstChild("HumanoidRootPart")
                            if bossHum and bossHRP and bossHum.Health > 0 then
                                _G.FightingBoss = true

                                Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                                local HRP = Character:FindFirstChild("HumanoidRootPart")
                                if HRP then
                                    while _G.FindRefruit and vokun and vokun.Parent and bossHum and bossHRP and bossHum.Health > 0 do
                                        if not bossHRP.Parent then break end
                                        -- เช็คว่าตัวเองตายไหม
                                        local myChar = LocalPlayer.Character
                                        local myH = myChar and myChar:FindFirstChildOfClass("Humanoid")
                                        if not myH or myH.Health <= 0 then break end
                                        HRP = myChar:FindFirstChild("HumanoidRootPart")
                                        if not HRP then break end

                                        if bossHum.Health <= (bossHum.MaxHealth * 0.7) then bossHum.Health = 0 break end
                                        -- วาปไปบนหัวบอส หน้าหันลง
                                        local abovePos = bossHRP.Position + Vector3.new(0, 10, 0)
                                        HRP.CFrame = CFrame.new(abovePos, bossHRP.Position)
                                        task.wait()
                                        bossHum = vokun:FindFirstChildOfClass("Humanoid")
                                        bossHRP = vokun:FindFirstChild("HumanoidRootPart")
                                        if not bossHum or not bossHRP then break end
                                    end
                                end

                                -- เช็คว่า Vokun ตายจริงไหม (พาทหายไปจาก Alive)
                                while _G.FindRefruit and vokun and vokun.Parent do
                                    task.wait(0.5)
                                end
                                -- ตายจริงแล้ว (พาทหายแล้ว) → รอเกิดใหม่
                                _G.FightingBoss = false
                            end
                        end
                    end
                end
                task.wait(1)
            end
            _G.FightingBoss = false
        end)
    end
end)
RefruitToggle:SetValue(false)

Tabs.Main:AddParagraph({ Title = "Spawn & Movement", Content = "" })

-- Auto Spawn (ลูปรันตลอด ไม่ต้องรอ toggle เปิดใหม่)
_G.AutoPressLoad = false
local SpawnToggle = Tabs.Main:AddToggle("AutoPressLoad", { Title = "Auto Spawn", Default = false })
SpawnToggle:OnChanged(function(state)
    _G.AutoPressLoad = state
end)
SpawnToggle:SetValue(false)

task.spawn(function()
    while true do
        if _G.AutoPressLoad then
            pcall(function()
                local loadGui = LocalPlayer.PlayerGui:FindFirstChild("Load")
                if loadGui and loadGui.Enabled then
                    local loadButton = loadGui.Frame:FindFirstChild("Load")
                    if loadButton then
                        local func = nil
                        for _, con in pairs(getconnections(loadButton.Activated)) do func = con.Function break end
                        if func then pcall(func) end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- Haki helper functions (ใช้ใน Haki tab)
local function getHakiPercent()
    local ok, result = pcall(function()
        local f = LocalPlayer.PlayerGui.HealthBar.Frame.Haki.Frame
        return (f.AbsoluteSize.X / 150) * 100
    end)
    return ok and result or 0
end
local function isObservationActive()
    local ok, result = pcall(function()
        local obs = LocalPlayer.PlayerGui.HealthBar.Frame.Status.Observation
        return obs and obs.Visible
    end)
    return ok and result
end
local function isHakiActive()
    local ok, result = pcall(function()
        return LocalPlayer.PlayerGui.HealthBar.Frame.Status:FindFirstChild("Haki") ~= nil
    end)
    return ok and result
end

Tabs.Main:AddParagraph({ Title = "Items", Content = "" })

-- Tp ChestSpawner
_G.AutoWarpChestSpawner = false
local ChestToggle = Tabs.Main:AddToggle("AutoWarpChestSpawner", { Title = "Tp ChestSpawner", Default = false })
ChestToggle:OnChanged(function()
    _G.AutoWarpChestSpawner = ChestToggle.Value
    if _G.AutoWarpChestSpawner then
        task.spawn(function()
            while _G.AutoWarpChestSpawner do
                local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local HRP = Character:WaitForChild("HumanoidRootPart")
                local chestsFolder = workspace:FindFirstChild("Chests")
                if chestsFolder then
                    local targets = {}
                    for _, obj in ipairs(chestsFolder:GetChildren()) do
                        if obj.Name == "ChestSpawner" then
                            if obj:IsA("Model") then
                                local tc = obj:FindFirstChild("TreasureChest")
                                if tc then
                                    local p = tc:IsA("BasePart") and tc or (tc:IsA("Model") and tc.PrimaryPart)
                                    if p then table.insert(targets, p) end
                                end
                            elseif obj:IsA("BasePart") then
                                table.insert(targets, obj)
                            end
                        end
                    end
                    for _, targetPart in ipairs(targets) do
                        if not _G.AutoWarpChestSpawner then break end
                        if targetPart and targetPart.Parent then
                            pcall(function()
                                HRP.CFrame = CFrame.new(targetPart.Position + targetPart.CFrame.LookVector, targetPart.Position)
                            end)
                            task.wait(0.2)
                        end
                    end
                else
                    task.wait(1)
                end
                task.wait(0.2)
            end
        end)
    end
end)

-- Barrels
_G.Barrels = false
local BarrelsToggle = Tabs.Main:AddToggle("BarrelsCratesJuicingToggle", { Title = "Barrels", Default = false })
BarrelsToggle:OnChanged(function()
    _G.Barrels = BarrelsToggle.Value
    if _G.Barrels then
        task.spawn(function()
            local juicingCD = nil
            pcall(function()
                local kitchen = workspace.MapFolder.Island8.Kitchen:GetChildren()
                if kitchen[2] then
                    local bowl = kitchen[2].JuicingBowl:FindFirstChild("Bowl")
                    if bowl then juicingCD = bowl:FindFirstChildWhichIsA("ClickDetector") end
                end
            end)
            local lastJuice = 0
            while _G.Barrels do
                local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local HRP = Character:WaitForChild("HumanoidRootPart")
                local barrelsFolder = workspace:FindFirstChild("Barrels")
                local targets = {}
                if barrelsFolder then
                    for _, folder in ipairs({ barrelsFolder:FindFirstChild("Barrels"), barrelsFolder:FindFirstChild("Crates") }) do
                        if folder then
                            for _, obj in ipairs(folder:GetChildren()) do
                                if obj:IsA("BasePart") then table.insert(targets, obj) end
                            end
                        end
                    end
                end
                for _, target in ipairs(targets) do
                    if not _G.Barrels then break end
                    if target and target.Parent then
                        pcall(function() HRP.CFrame = CFrame.new(target.Position + target.CFrame.LookVector * 3 + Vector3.new(0, 2, 0)) end)
                        task.wait(0.12)
                        local cd = target:FindFirstChildWhichIsA("ClickDetector", true)
                        if cd then
                            for i = 1, 20 do
                                if not _G.Barrels then break end
                                pcall(function() fireclickdetector(cd) end)
                                task.wait()
                            end
                        end
                        task.wait()
                    end
                end
                if juicingCD and os.clock() - lastJuice >= 60 then
                    pcall(function() fireclickdetector(juicingCD) end)
                    lastJuice = os.clock()
                end
                task.wait()
            end
        end)
    end
end)

-- Auto Eat Juice
_G.AutoEatJuiceFast = false
local JuiceToggle = Tabs.Main:AddToggle("AutoEatJuiceFast", { Title = "Auto Eat Juice", Default = false })
JuiceToggle:OnChanged(function(state)
    _G.AutoEatJuiceFast = state
    if state then
        task.spawn(function()
            while _G.AutoEatJuiceFast do
                local Character = LocalPlayer.Character
                local Backpack = LocalPlayer:FindFirstChild("Backpack")
                if Character and Backpack then
                    local juiceItems = {}
                    for _, src in ipairs({ Backpack:GetChildren(), Character:GetChildren() }) do
                        for _, v in ipairs(src) do
                            if v:IsA("Tool") then
                                local n = string.lower(v.Name)
                                if string.find(n, "juice") or string.find(n, "milk") then
                                    table.insert(juiceItems, v)
                                end
                            end
                        end
                    end
                    for _, Tool in ipairs(juiceItems) do
                        if not _G.AutoEatJuiceFast then break end
                        if Tool and Tool.Parent then
                            local Humanoid = Character:FindFirstChildOfClass("Humanoid")
                            if Humanoid then
                                pcall(function() Humanoid:EquipTool(Tool) end) task.wait(0.03)
                                pcall(function() Tool:Activate() end) task.wait(0.03)
                                local cam = workspace.CurrentCamera
                                if cam then
                                    VirtualInputManager:SendMouseButtonEvent(cam.ViewportSize.X/2, cam.ViewportSize.Y/2, 0, true, game, 0)
                                    task.wait()
                                    VirtualInputManager:SendMouseButtonEvent(cam.ViewportSize.X/2, cam.ViewportSize.Y/2, 0, false, game, 0)
                                end
                                task.wait(0.05)
                                pcall(function() Humanoid:UnequipTools() end)
                            end
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end)
JuiceToggle:SetValue(false)

-- Auto Golden Apple
_G.AutoGoldenApple = false
local AppleToggle = Tabs.Main:AddToggle("AutoGoldenApple", { Title = "Auto Golden Apple", Default = false })
AppleToggle:OnChanged(function()
    _G.AutoGoldenApple = Options.AutoGoldenApple.Value
    if _G.AutoGoldenApple then
        task.spawn(function()
            while _G.AutoGoldenApple do
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local apple = nil
                for _, src in ipairs({ char, LocalPlayer:FindFirstChild("Backpack") }) do
                    if src then
                        for _, v in pairs(src:GetChildren()) do
                            if v:IsA("Tool") and v.Name == "Golden Apple" then apple = v break end
                        end
                    end
                    if apple then break end
                end
                if apple then
                    apple.Parent = char
                    task.wait(0.1)
                    pcall(function() apple:Activate() end)
                end
                task.wait(0.2)
            end
        end)
        LocalPlayer.CharacterAdded:Connect(function() task.wait(1) end)
    end
end)

-- ปุ่มลบ Pirate Seats
Tabs.Main:AddButton({
    Title = "Delete Pirate Seats",
    Callback = function()
        pcall(function()
            workspace.MapFolder.IslandPirate.Station.Seats:Destroy()
        end)
    end
})

-- Fly
_G.Flying = false
_G.FlySpeed = 50
local flyBV, flyBG

local FlyToggle = Tabs.Main:AddToggle("Flying", { Title = "Fly", Default = false })
FlyToggle:OnChanged(function(state)
    _G.Flying = state
    local Character = LocalPlayer.Character
    local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if not HRP or not Humanoid then return end
    if state then
        -- สร้าง BodyGyro + BodyVelocity
        flyBV = Instance.new("BodyVelocity")
        flyBV.Name = "FlyVelocity"
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.Velocity = Vector3.new(0, 0, 0)
        flyBV.Parent = HRP
        flyBG = Instance.new("BodyGyro")
        flyBG.Name = "FlyGyro"
        flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyBG.P = 9e4
        flyBG.Parent = HRP
        Humanoid.PlatformStand = true
        task.spawn(function()
            while _G.Flying and HRP and HRP.Parent do
                local camera = workspace.CurrentCamera
                flyBG.CFrame = camera.CFrame
                local moveDir = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                if moveDir.Magnitude > 0 then
                    flyBV.Velocity = moveDir.Unit * _G.FlySpeed
                else
                    flyBV.Velocity = Vector3.new(0, 0, 0)
                end
                RunService.RenderStepped:Wait()
            end
        end)
    else
        Humanoid.PlatformStand = false
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyBG then flyBG:Destroy() flyBG = nil end
    end
end)

local FlySpeedSlider = Tabs.Main:AddSlider("FlySpeed", {
    Title = "Fly Speed",
    Min = 1,
    Max = 10,
    Default = 5,
    Rounding = 1,
})
FlySpeedSlider:OnChanged(function(val) _G.FlySpeed = val * 50 end)
_G.FlySpeed = 250

-- Walk Speed
_G.WalkSpeedEnabled = false
_G.WalkSpeedMultiplier = 5
local WalkSpeedToggle = Tabs.Main:AddToggle("WalkSpeedToggle", { Title = "Walk Speed", Default = false })
WalkSpeedToggle:OnChanged(function(state)
    _G.WalkSpeedEnabled = state
    if state then
        task.spawn(function()
            while _G.WalkSpeedEnabled do
                local Character = LocalPlayer.Character
                local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                if Humanoid then Humanoid.WalkSpeed = _G.WalkSpeedMultiplier * 50 end
                task.wait(0.3)
            end
        end)
    else
        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then Humanoid.WalkSpeed = 16 end
    end
end)

local WalkSpeedSlider = Tabs.Main:AddSlider("WalkSpeedSlider", {
    Title = "Walk Speed",
    Min = 1,
    Max = 10,
    Default = 5,
    Rounding = 1,
})
WalkSpeedSlider:OnChanged(function(val) _G.WalkSpeedMultiplier = val end)

-- Infinite Jump (x2.5)
_G.InfiniteJump = false
local InfJumpToggle = Tabs.Main:AddToggle("InfiniteJump", { Title = "Infinite Jump", Default = false })
InfJumpToggle:OnChanged(function(state)
    _G.InfiniteJump = state
    if state then
        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then Humanoid.JumpHeight = Humanoid.JumpHeight * 2.5 end
    else
        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then Humanoid.JumpHeight = Humanoid.JumpHeight / 2.5 end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if _G.InfiniteJump then
        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

Tabs.Main:AddParagraph({ Title = "Fishing", Content = "" })

-- =============================================
-- AUTO FISH (Main Tab)
-- =============================================
_G.AutoFish = false
local fishRodNames = {"Super Rod", "Sturdy Rod", "Santa Bag", "Wood Rod"}

local function getFishRod()
    local char = LocalPlayer.Character
    if not char then return nil end
    -- เช็คในมือก่อน
    for _, name in ipairs(fishRodNames) do
        local tool = char:FindFirstChild(name)
        if tool and tool:IsA("Tool") then return tool end
    end
    -- หาใน Backpack → Equip ให้
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            for _, name in ipairs(fishRodNames) do
                local tool = bp:FindFirstChild(name)
                if tool and tool:IsA("Tool") then
                    humanoid:EquipTool(tool)
                    task.wait(0.5)
                    return char:FindFirstChild(name)
                end
            end
        end
    end
    return nil
end

local AutoFishToggle = Tabs.Main:AddToggle("AutoFish", { Title = "Auto Fish", Default = false })
AutoFishToggle:OnChanged(function(state)
    _G.AutoFish = state
    if not state then return end
    task.spawn(function()
        local fishGui = LocalPlayer.PlayerGui:FindFirstChild("FishingMinigame")
        local ropeKey = "FishingRope_" .. LocalPlayer.UserId

        -- เช็คว่าตกปลาอยู่ไหม (มี RopeConstraint = ตกอยู่)
        local function isFishing()
            local ok, result = pcall(function()
                local rope = workspace:FindFirstChild(ropeKey)
                return rope and rope:FindFirstChild("RopeConstraint") ~= nil
            end)
            return ok and result
        end

        -- เช็ค Sparkles (ปลากิน)
        local function hasSparkles()
            local ok, result = pcall(function()
                local rope = workspace:FindFirstChild(ropeKey)
                if rope then
                    local bobber = rope:FindFirstChild("Bobber")
                    return bobber and bobber:FindFirstChild("Sparkles") ~= nil
                end
                return false
            end)
            return ok and result
        end

        while _G.AutoFish do
            -- 1. ถือเบ็ดให้
            local rod = getFishRod()
            if not rod then task.wait(0.5) end

            -- 2. ถ้าไม่ได้ตกอยู่ → กดตก
            if rod and not isFishing() then
                pcall(function() rod:Activate() end)
                task.wait(0.5)
            end

            -- 3. ถ้าตกอยู่ → เช็ค Sparkles
            if isFishing() and hasSparkles() then
                -- ปลากิน → กดดึง
                pcall(function()
                    local r = getFishRod()
                    if r then r:Activate() end
                end)

                -- รอมินิเกม
                local mgWait = 0
                while _G.AutoFish and mgWait < 2 do
                    if fishGui and fishGui.Enabled then break end
                    task.wait()
                    mgWait = mgWait + 0.03
                end

                -- เล่นมินิเกม
                if fishGui and fishGui.Enabled then
                    while _G.AutoFish and fishGui.Enabled do
                        pcall(function()
                            for _, btn in ipairs(fishGui:GetDescendants()) do
                                if btn:IsA("TextButton") and btn.BackgroundColor3.R > 0.5 then
                                    for _, con in pairs(getconnections(btn.Activated)) do
                                        pcall(function() con.Function() end)
                                    end
                                    for _, con in pairs(getconnections(btn.MouseButton1Down)) do
                                        pcall(function() con.Function() end)
                                    end
                                    for _, con in pairs(getconnections(btn.MouseButton1Click)) do
                                        pcall(function() con.Function() end)
                                    end
                                end
                            end
                        end)
                        task.wait(0.3)
                    end
                end
            end

            task.wait(0.2)
        end
    end)
end)

-- =============================================
-- SAM TAB
-- =============================================
Tabs.Main4:AddParagraph({ Title = "Quest", Content = "" })

-- Auto Sam Quest
_G.AutoSamQuest = false
local SamToggle = Tabs.Main4:AddToggle("AutoSamQuest", { Title = "Auto Sam Quest", Default = false })
SamToggle:OnChanged(function()
    _G.AutoSamQuest = SamToggle.Value
    if _G.AutoSamQuest then
        task.spawn(function()
            while _G.AutoSamQuest do
                local player = LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                while humanoid and humanoid.Health <= 0 do
                    task.wait()
                    character = player.Character or player.CharacterAdded:Wait()
                    humanoid = character:FindFirstChildOfClass("Humanoid")
                end
                local gui = player:WaitForChild("PlayerGui")

                -- เช็คจำนวนเข็ม (X/Y)
                local compassCount = 0
                repeat
                    compassCount = 0
                    pcall(function()
                        local timer = gui.Menu.Frame.MenuList.Stats.Frame.A.Sam.SamTimer
                        local num = string.match(timer.Text, "%((%d+)/")
                        if num then compassCount = tonumber(num) end
                    end)
                    if compassCount > 0 then break end
                    task.wait()
                until not _G.AutoSamQuest
                if not _G.AutoSamQuest then break end

                -- หยุด AutoFarm ชั่วคราว
                local wasFarming = _G.AutoFarm
                if wasFarming then _G.AutoFarm = false task.wait(0.5) end

                -- ไปส่ง Sam ตามจำนวนเข็มที่มี
                for i = 1, compassCount do
                    if not _G.AutoSamQuest then break end
                    local sam = workspace.Ignore.NPCs.DailyQuest:FindFirstChild("Sam")
                    if sam then
                        warpToNPC(character, sam)
                        task.wait()
                    end

                    local dialogue = gui:FindFirstChild("QuestGui") and gui.QuestGui:FindFirstChild("Dialogue")
                    if dialogue and dialogue.Visible then
                        clickDialogue(gui)
                    else
                        if sam then interactNPC(sam) end
                    end
                    task.wait()
                end

                if wasFarming then FarmToggle:SetValue(true) end
                task.wait()
            end
        end)
    end
end)
Options.AutoSamQuest:SetValue(false)

local AutoDropCompass = false
local DropToggle = Tabs.Main4:AddToggle("AutoDropCompass", { Title = "Auto Drop Compass", Default = false })
DropToggle:OnChanged(function(state)
    AutoDropCompass = state
    if state then
        task.spawn(function()
            while AutoDropCompass do
                local Character = LocalPlayer.Character
                local Backpack = LocalPlayer:FindFirstChild("Backpack")
                -- หา Compass / Golden Compass
                local Compass = nil
                if Character then
                    for _, child in pairs(Character:GetChildren()) do
                        if child:IsA("Tool") and string.find(child.Name, "Compass") then
                            Compass = child
                            break
                        end
                    end
                end
                if not Compass and Backpack then
                    for _, child in pairs(Backpack:GetChildren()) do
                        if child:IsA("Tool") and string.find(child.Name, "Compass") then
                            Compass = child
                            break
                        end
                    end
                end
                if Compass then
                    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                    if Humanoid then pcall(function() Humanoid:EquipTool(Compass) end) end
                    task.wait(0.2)
                    pcall(function() Compass.Parent = workspace end)
                end
                task.wait(0.5)
            end
        end)
    end
end)
DropToggle:SetValue(false)

Tabs.Main4:AddParagraph({ Title = "Loot", Content = "" })

_G.AutoPickupCompass = false
local PickupToggle = Tabs.Main4:AddToggle("AutoPickupCompass", { Title = "Auto Loot Compass", Default = false })

local function isInsidePlayerCharacter(obj)
    local current = obj
    while current and current ~= workspace do
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character and current == plr.Character then return true end
        end
        current = current.Parent
    end
    return false
end

PickupToggle:OnChanged(function(state)
    _G.AutoPickupCompass = state
    if state then
        task.spawn(function()
            while _G.AutoPickupCompass do
                local Character = LocalPlayer.Character
                local HRP = Character and Character:FindFirstChild("HumanoidRootPart")
                if HRP then
                    for _, obj in ipairs(workspace:GetChildren()) do
                        if not _G.AutoPickupCompass then break end
                        if string.find(obj.Name, "Compass") and not isInsidePlayerCharacter(obj) then
                            local part = obj:IsA("BasePart") and obj
                                or (obj:IsA("Tool") and (obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart", true)))
                                or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)))
                            if part then
                                pcall(function()
                                    part.CanCollide = false
                                    part.CFrame = HRP.CFrame
                                end)
                            end
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    end
end)
PickupToggle:SetValue(false)

local function longRangePickup(obj)
    local cd = obj:FindFirstChildWhichIsA("ClickDetector", true)
    if cd then
        pcall(function() cd.MaxActivationDistance = math.huge end)
        for i = 1, 5 do pcall(function() fireclickdetector(cd) end) end
    end
    for _, v in ipairs(obj:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            pcall(function()
                v.MaxActivationDistance = math.huge
                v.HoldDuration = 0
                v.RequiresLineOfSight = false
                fireproximityprompt(v)
            end)
        end
    end
end

_G.AutoPickupAllFruit = false
local AllFruitNames = {
    "Spin Fruit", "Luck Fruit", "Clear Fruit", "Chop Fruit", "Clone Fruit",
    "Float Fruit", "Hot Fruit", "Swim Fruit", "Spring Fruit", "Slip Fruit",
    "Barrier Fruit", "Love Fruit", "Smelt Fruit", "Order Fruit", "Diamond Fruit",
    "Bomb Fruit", "Slow Fruit",
    "Candy Fruit", "Chilly Fruit", "Flare Fruit", "Sand Fruit", "Magma Fruit",
    "Rumble Fruit", "Light Fruit", "Ope Fruit", "Plasma Fruit", "Snow Fruit",
    "Gravity Fruit", "Gas Fruit", "Gum Fruit", "String Fruit",
    "Dark Fruit", "Buddha Fruit", "Quake Fruit", "Phoenix Fruit",
}
local function isFruitName(name)
    for _, fruitName in ipairs(AllFruitNames) do
        if string.find(name, fruitName) then return true end
    end
    return false
end

local PickupAllFruitToggle = Tabs.Main4:AddToggle("AutoPickupAllFruit", { Title = "Auto Loot Fruit", Default = false })
PickupAllFruitToggle:OnChanged(function(state)
    _G.AutoPickupAllFruit = state
    if not state then return end
    task.spawn(function()
        while _G.AutoPickupAllFruit do
            for _, child in ipairs(workspace:GetChildren()) do
                if not _G.AutoPickupAllFruit then break end
                if isFruitName(child.Name) then longRangePickup(child) end
            end
            task.wait()
        end
    end)
end)

-- =============================================
-- ISLAND TAB
-- =============================================
local Islands = {
    { name = "Sam",             cf = CFrame.new(-1303.00, 217.00, -1272.21) },
    { name = "Island Town",     cf = CFrame.new(-200.01,  225.12, -1038.50) },
    { name = "Vokun Field",     cf = CFrame.new(4590.82,  216.99,  4959.73) },
    { name = "Strange Tent",    cf = CFrame.new(1256.88,  224.00, -3282.47) },
    { name = "Rocky Islands",   cf = CFrame.new(4371.24,  318.81, -3234.06) },
    { name = "Jail Islands",    cf = CFrame.new(-2756.56, 216.00,  -991.36) },
    { name = "Island Tree A",   cf = CFrame.new(1097.95,  217.00,  3315.32) },
    { name = "Snowy Mountains", cf = CFrame.new(6601.46,  302.67, -1551.53) },
    { name = "Island Snowy",    cf = CFrame.new(-1899.04, 222.00,  3351.54) },
    { name = "Sand Castle",     cf = CFrame.new(1021.73,  224.00, -3334.99) },
    { name = "Island Rocky",    cf = CFrame.new(-31.82,   229.00,  2158.42) },
    { name = "Island Mountain", cf = CFrame.new(2053.00,  490.00,  -666.88) },
    { name = "Island Grassy",   cf = CFrame.new(704.03,   241.20,  1194.62) },
    { name = "Island Forest",   cf = CFrame.new(-6015.06, 402.00,    21.62) },
    { name = "Island Evil",     cf = CFrame.new(-5273.38, 519.50, -7846.25) },
    { name = "Island Crescent", cf = CFrame.new(3396.06,  217.00,  1611.94) },
    { name = "Snipers",         cf = CFrame.new(-1042.94, 355.99,  1681.47) },
    { name = "Bar",             cf = CFrame.new(1512.06,  259.39,  2171.05) },
    { name = "Pyramid",         cf = CFrame.new(859.67,   238.69,  5255.51) },
    { name = "Crabs",           cf = CFrame.new(1154.78,  253.00,  -220.35) },
    { name = "Marine Ford",     cf = CFrame.new(-2822.19, 299.75, -3631.12) },
    { name = "Island 22",       cf = CFrame.new(-5425.64, 220.00, -7708.75) },
    { name = "Cooker Island",   cf = CFrame.new(1946.09,  217.00,   626.30) },
    { name = "Island 24",       cf = CFrame.new(-2788.51, 251.56,  1008.30) },
}

for _, island in ipairs(Islands) do
    Tabs.Island:AddButton({
        Title = island.name,
        Callback = function()
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local HRP = Character:FindFirstChild("HumanoidRootPart")
            if HRP then pcall(function() HRP.CFrame = island.cf end) end
        end
    })
end

-- =============================================
-- ALERT TAB (สแกนผลแร/กล่องแร แจ้ง Discord)
-- =============================================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1513103719821217885/8yWhIK91brRZOlvETFfSFlRVWEjojcFdfxHu14xYtKGDKWqjzjf9BRA7p5_g3qt_0H_d"
local HttpService = game:GetService("HttpService")

local RareFruits = {
    ["Candy"] = "Rare", ["Chilly"] = "Rare", ["Flare"] = "Rare", ["Sand"] = "Rare",
    ["Magma"] = "Rare", ["Rumble"] = "Rare", ["Light"] = "Rare", ["Ope"] = "Rare",
    ["Plasma"] = "Rare", ["Snow"] = "Rare", ["Gravity"] = "Rare", ["Gas"] = "Rare",
    ["Gum"] = "Rare", ["String"] = "Rare",
    ["Dark"] = "Ultra Rare", ["Buddha"] = "Ultra Rare", ["Quake"] = "Ultra Rare", ["Phoenix"] = "Ultra Rare",
}

local BoxNames = {
    ["Rare Box"] = "Rare",
    ["Ultra Rare Box"] = "Ultra Rare",
}

local function isRareItem(name)
    for k, v in pairs(RareFruits) do if string.find(name, k) and string.find(name, "Fruit") then return v, "fruit" end end
    for k, v in pairs(BoxNames) do if string.find(name, k) then return v, "box" end end
    return nil
end

local function getAllItems(char, player)
    local items = {}
    for _, c in ipairs(char:GetChildren()) do table.insert(items, c) end
    pcall(function()
        if player:FindFirstChild("Backpack") then
            for _, b in ipairs(player.Backpack:GetChildren()) do table.insert(items, b) end
        end
    end)
    return items
end

local alertedItems = {}

local function sendDiscordAlert(title, description, color)
    pcall(function()
        local data = HttpService:JSONEncode({
            content = "<@1074965293685821480>",
            embeds = {{
                title = title,
                description = description,
                color = color,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            }}
        })
        local req = request or http_request or (syn and syn.request)
        if req then
            req({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = data,
            })
        end
    end)
end

local function alertRareItem(child, key, rarity, itemType, ownerName, ownerId)
    if alertedItems[key] then return false end
    alertedItems[key] = true
    local color = rarity == "Ultra Rare" and 16711680 or 16776960
    local icon = itemType == "box" and "📦" or "🍎"
    local status = itemType == "box" and "ยังไม่เปิด (กล่อง)" or "ผล (เปิดแล้ว)"
    local joinCmd = "```\ngame:GetService(\"ReplicatedStorage\").__ServerBrowser:InvokeServer(\"teleport\", \"" .. game.JobId .. "\")\n```"
    if ownerName then
        sendDiscordAlert("ระดับ: " .. rarity, icon .. " **" .. child.Name .. "!**\n**สถานะ:** " .. status .. "\n**อยู่ในตัว:** " .. ownerName .. "\n**ID:** `" .. ownerId .. "`\n**Job-Id:** `" .. game.JobId .. "`\n**จอยเซิฟ:**\n" .. joinCmd, color)
    else
        sendDiscordAlert("ระดับ: " .. rarity, icon .. " **" .. child.Name .. " บนพื้น!**\n**สถานะ:** " .. status .. "\n**อยู่:** บนพื้น\n**Job-Id:** `" .. game.JobId .. "`\n**จอยเซิฟ:**\n" .. joinCmd, color)
    end
    return true
end

local function scanForRares()
    local found = false
    local alive = workspace:FindFirstChild("Alive")
    if alive then
        for _, char in ipairs(alive:GetChildren()) do
            local player = Players:FindFirstChild(char.Name)
            if player then
                for _, child in ipairs(getAllItems(char, player)) do
                    local rarity, itemType = isRareItem(child.Name)
                    if rarity and alertRareItem(child, char.Name .. "_" .. child.Name, rarity, itemType, char.Name, player.UserId) then
                        found = true
                    end
                end
            end
        end
    end
    for _, child in ipairs(workspace:GetChildren()) do
        local rarity, itemType = isRareItem(child.Name)
        if rarity and alertRareItem(child, "ground_" .. child.Name .. "_" .. tostring(child), rarity, itemType, nil, nil) then
            found = true
        end
    end
    return found
end

Tabs.Alert:AddParagraph({ Title = "Alert & ESP", Content = "" })

-- Toggle สแกนผลแร (แจ้งทุก 2 วิ + แจ้งตอนหาย)
_G.AutoRareAlert = false
local previousRares = {} -- เก็บของที่เจอรอบก่อน

local function getCurrentRares()
    local current = {}
    local alive = workspace:FindFirstChild("Alive")
    if alive then
        for _, char in ipairs(alive:GetChildren()) do
            local player = Players:FindFirstChild(char.Name)
            if player then
                for _, child in ipairs(getAllItems(char, player)) do
                    local rarity, itemType = isRareItem(child.Name)
                    if rarity then
                        table.insert(current, { name = child.Name, rarity = rarity, type = itemType, owner = char.Name, id = player.UserId, location = "player" })
                    end
                end
            end
        end
    end
    for _, child in ipairs(workspace:GetChildren()) do
        local rarity, itemType = isRareItem(child.Name)
        if rarity then
            table.insert(current, { name = child.Name, rarity = rarity, type = itemType, owner = "", id = "", location = "ground" })
        end
    end
    return current
end

local RareAlertToggle = Tabs.Alert:AddToggle("AutoRareAlert", { Title = "Webhooks", Default = false })
RareAlertToggle:OnChanged(function(state)
    _G.AutoRareAlert = state
    if not state then previousRares = {} return end
    task.spawn(function()
        while _G.AutoRareAlert do
            local current = getCurrentRares()
            local joinCmd = "```\ngame:GetService(\"ReplicatedStorage\").__ServerBrowser:InvokeServer(\"teleport\", \"" .. game.JobId .. "\")\n```"
            for _, item in ipairs(current) do
                local color = item.rarity == "Ultra Rare" and 16711680 or 16776960
                local icon = item.type == "box" and "📦" or "🍎"
                local status = item.type == "box" and "ยังไม่เปิด (กล่อง)" or "ผล (เปิดแล้ว)"
                if item.location == "player" then
                    sendDiscordAlert("ระดับ: " .. item.rarity, icon .. " **" .. item.name .. "!**\n**สถานะ:** " .. status .. "\n**อยู่ในตัว:** " .. item.owner .. "\n**ID:** `" .. item.id .. "`\n**Job-Id:** `" .. game.JobId .. "`\n**จอยเซิฟ:**\n" .. joinCmd, color)
                else
                    sendDiscordAlert("ระดับ: " .. item.rarity, icon .. " **" .. item.name .. " บนพื้น!**\n**สถานะ:** " .. status .. "\n**อยู่:** บนพื้น\n**Job-Id:** `" .. game.JobId .. "`\n**จอยเซิฟ:**\n" .. joinCmd, color)
                end
            end

            -- เช็คของที่หายไป
            for _, prev in ipairs(previousRares) do
                local stillExists = false
                for _, cur in ipairs(current) do
                    if cur.name == prev.name and cur.owner == prev.owner then
                        stillExists = true
                        break
                    end
                end
                if not stillExists then
                    sendDiscordAlert(
                        "❌ ผลหายไปแล้ว!",
                        "**" .. prev.name .. "** หายไปจาก **" .. (prev.owner ~= "" and prev.owner or "พื้น") .. "**\nอาจถูกเก็บใส่ช่องเก็บผล หรือโดนกินไป",
                        8421504
                    )
                end
            end

            previousRares = current
            task.wait(2)
        end
    end)
end)

-- Toggle Esc มองทะลุคนถือผลแร
_G.EscRarePlayer = false
local espFolder = Instance.new("Folder")
espFolder.Name = "RareESP"
espFolder.Parent = game.CoreGui

local function clearAllESP()
    for _, v in ipairs(espFolder:GetChildren()) do v:Destroy() end
    -- ลบ Highlight ที่ติดตัวคนด้วย
    local alive = workspace:FindFirstChild("Alive")
    if alive then
        for _, char in ipairs(alive:GetChildren()) do
            pcall(function()
                local hl = char:FindFirstChild("RareHighlight")
                if hl then hl:Destroy() end
            end)
        end
    end
end

local function updateESP()
    clearAllESP()
    local rareHolders = getCurrentRares()
    for _, item in ipairs(rareHolders) do
        if item.location == "player" then
            local alive = workspace:FindFirstChild("Alive")
            if alive then
                local targetChar = alive:FindFirstChild(item.owner)
                if targetChar and not targetChar:FindFirstChild("RareHighlight") then
                    pcall(function()
                        -- Highlight มองทะลุ
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "RareHighlight"
                        highlight.Adornee = targetChar
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.FillColor = item.rarity == "Ultra Rare" and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 0)
                        highlight.FillTransparency = 0.3
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.Parent = targetChar

                        -- ชื่อ + ผล ลอยหัว
                        local billboard = Instance.new("BillboardGui")
                        billboard.Name = "RareNameTag"
                        billboard.Size = UDim2.new(0, 250, 0, 50)
                        billboard.AlwaysOnTop = true
                        billboard.StudsOffset = Vector3.new(0, 3, 0)
                        billboard.Adornee = targetChar:FindFirstChild("Head")
                        billboard.Parent = espFolder

                        local tag = Instance.new("TextLabel", billboard)
                        tag.BackgroundTransparency = 1
                        tag.Size = UDim2.new(1, 0, 1, 0)
                        tag.TextSize = 14
                        tag.Font = Enum.Font.SourceSansBold
                        tag.TextColor3 = item.rarity == "Ultra Rare" and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 0)
                        tag.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        tag.TextStrokeTransparency = 0.3
                        tag.Text = item.owner .. " [" .. item.name .. "]"
                    end)
                end
            end
        end
    end
end

local EscToggle = Tabs.Alert:AddToggle("EscRarePlayer", { Title = "Esc Fruit Player", Default = false })
EscToggle:OnChanged(function(state)
    _G.EscRarePlayer = state
    if not state then clearAllESP() return end
    task.spawn(function()
        while _G.EscRarePlayer do
            updateESP()
            task.wait(2)
        end
        clearAllESP()
    end)
end)

-- Toggle Tp ค้างข้างหลังคนถือผลแร (ตาย/หาย → วาปไป Vokun)
_G.TpRarePlayer = false
local lastTpTarget = nil -- จำคนที่กำลังตามอยู่
local TpRareToggle = Tabs.Alert:AddToggle("TpRarePlayer", { Title = "Tp Fruit Player", Default = false })
TpRareToggle:OnChanged(function(state)
    _G.TpRarePlayer = state
    if not state then lastTpTarget = nil return end
    task.spawn(function()
        while _G.TpRarePlayer do
            local rareHolders = getCurrentRares()
            local foundTarget = false
            for _, item in ipairs(rareHolders) do
                if item.location == "player" then
                    local alive = workspace:FindFirstChild("Alive")
                    if alive then
                        local targetChar = alive:FindFirstChild(item.owner)
                        if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                            local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
                            if targetHum and targetHum.Health > 0 then
                                lastTpTarget = item.owner
                                -- วาปค้างข้างหลัง
                                local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                                local myHRP = myChar:FindFirstChild("HumanoidRootPart")
                                if myHRP then
                                    local targetHRP = targetChar.HumanoidRootPart
                                    local behindPos = targetHRP.Position - (targetHRP.CFrame.LookVector * 1)
                                    myHRP.CFrame = CFrame.new(behindPos, targetHRP.Position)
                                end
                                foundTarget = true
                                break
                            end
                        end
                    end
                end
            end
            -- คนที่ตามอยู่หาย/ตาย → วาปไป Vokun
            if not foundTarget and lastTpTarget then
                local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local myHRP = myChar:FindFirstChild("HumanoidRootPart")
                if myHRP then
                    myHRP.CFrame = CFrame.new(4590.82, 216.99, 4959.73)
                    Fluent:Notify({ Title = "คนถือผลตาย!", Content = lastTpTarget .. " หายไป → วาปไป Vokun", Duration = 3 })
                end
                lastTpTarget = nil
                _G.TpRarePlayer = false
                pcall(function() Options.TpRarePlayer:SetValue(false) end)
                break
            end
            -- ไม่เคยเจอใครเลย
            if not foundTarget and not lastTpTarget then
                Fluent:Notify({ Title = "ไม่พบ", Content = "ไม่มีใครถือผลแร", Duration = 2 })
                _G.TpRarePlayer = false
                pcall(function() Options.TpRarePlayer:SetValue(false) end)
                break
            end
            task.wait()
        end
    end)
end)

-- Toggle มองมุมมองคนถือผลแร
_G.ViewRarePlayer = false
local savedCameraCF = nil
local ViewRareToggle = Tabs.Alert:AddToggle("ViewRarePlayer", { Title = "Spectate Fruit Player", Default = false })
ViewRareToggle:OnChanged(function(state)
    _G.ViewRarePlayer = state
    local camera = workspace.CurrentCamera
    if not state then
        -- กลับมามองตัวเอง
        camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") or nil
        camera.CameraType = Enum.CameraType.Custom
        return
    end
    task.spawn(function()
        while _G.ViewRarePlayer do
            local rareHolders = getCurrentRares()
            local foundTarget = false
            for _, item in ipairs(rareHolders) do
                if item.location == "player" then
                    local alive = workspace:FindFirstChild("Alive")
                    if alive then
                        local targetChar = alive:FindFirstChild(item.owner)
                        if targetChar then
                            local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
                            if targetHum then
                                camera.CameraSubject = targetHum
                                camera.CameraType = Enum.CameraType.Custom
                                foundTarget = true
                                break
                            end
                        end
                    end
                end
            end
            if not foundTarget then
                camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") or nil
                camera.CameraType = Enum.CameraType.Custom
            end
            task.wait(1)
        end
    end)
end)

Tabs.Alert:AddParagraph({ Title = "Loot & Server", Content = "" })

_G.AutoPickupFruit = false
local PickupFruitToggle = Tabs.Alert:AddToggle("AutoPickupFruit", { Title = "Auto Loot Rare Fruit", Default = false })
PickupFruitToggle:OnChanged(function(state)
    _G.AutoPickupFruit = state
    if not state then return end
    task.spawn(function()
        while _G.AutoPickupFruit do
            for _, child in ipairs(workspace:GetChildren()) do
                if not _G.AutoPickupFruit then break end
                if isRareItem(child.Name) then
                    task.wait(0.2)
                    longRangePickup(child)
                end
            end
            task.wait()
        end
    end)
end)

-- เช็คว่ามีของแรอยู่ไหม (ไม่สน alertedItems)
local function hasRaresInServer()
    local alive = workspace:FindFirstChild("Alive")
    if alive then
        for _, char in ipairs(alive:GetChildren()) do
            local player = Players:FindFirstChild(char.Name)
            if player then
                for _, child in ipairs(getAllItems(char, player)) do
                    if isRareItem(child.Name) then return true end
                end
            end
        end
    end
    for _, child in ipairs(workspace:GetChildren()) do
        if isRareItem(child.Name) then return true end
    end
    return false
end

-- Toggle Server Hop (เซฟคอนฟิกได้)
_G.AutoServerHop = false
local HopToggle = Tabs.Alert:AddToggle("AutoServerHop", { Title = "Auto Server Hop", Default = false })
HopToggle:OnChanged(function(state)
    _G.AutoServerHop = state
    if not state then return end
    task.spawn(function()
        task.wait(5) -- รอเกมโหลด
        -- สแกนจนกว่าของจะหาย
        while _G.AutoServerHop do
            if hasRaresInServer() then
                Fluent:Notify({ Title = "พบของแร!", Content = "รออยู่เซิฟนี้...", Duration = 3 })
                -- รอจนกว่าของจะหายหมด
                while _G.AutoServerHop and hasRaresInServer() do
                    task.wait(3)
                end
                if not _G.AutoServerHop then return end
            end
            -- ไม่มีของแร → Hop
            Fluent:Notify({ Title = "ไม่พบของแร", Content = "กำลังย้ายเซิฟ...", Duration = 2 })
            task.wait(1)
            pcall(function()
                game:GetService("TeleportService"):Teleport(game.PlaceId)
            end)
            task.wait(15)
        end
    end)
end)

-- =============================================
-- SHOP NPC TELEPORT (วาปไปหา NPC ร้านค้า)
-- =============================================
local ShopNPCs = {
    "Anna",
    "Better Drink Merchant",
    "Dancer",
    "Drink Merchant",
    "Fred The Blacksmith",
    "Lucy",
    "Mad Scientist",
    "Sniper Merchant",
    "Sword Merchant",
    "Water&Sand",
}

for _, npcName in ipairs(ShopNPCs) do
    Tabs.Npc:AddButton({
        Title = "Tp " .. npcName,
        Callback = function()
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local HRP = Character:FindFirstChild("HumanoidRootPart")
            if not HRP then return end
            local shopFolder = workspace:FindFirstChild("Ignore")
                and workspace.Ignore:FindFirstChild("NPCs")
                and workspace.Ignore.NPCs:FindFirstChild("Shop")
            if not shopFolder then return end
            local npc = shopFolder:FindFirstChild(npcName)
            if npc and npc:FindFirstChild("HumanoidRootPart") then
                HRP.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
            end
        end
    })
end

Tabs.Npc:AddButton({
    Title = "Tp Secret Dealer",
    Callback = function()
        local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local HRP = Character:FindFirstChild("HumanoidRootPart")
        if not HRP then return end
        pcall(function()
            local npc = workspace.Ignore.NPCs.Secret["Secret Dealer"]
            if npc and npc:FindFirstChild("HumanoidRootPart") then
                HRP.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
            end
        end)
    end
})

Tabs.Npc:AddButton({
    Title = "Tp Rayleigh",
    Callback = function()
        local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local HRP = Character:FindFirstChild("HumanoidRootPart")
        if not HRP then return end
        pcall(function()
            local npc = workspace.Ignore.NPCs.Quest.Rayleigh
            if npc and npc:FindFirstChild("HumanoidRootPart") then
                HRP.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
            end
        end)
    end
})

-- =============================================
-- AFFINITY TAB
-- =============================================
local AffinityToggle = Tabs.Affinity:AddToggle("OpenAffinity", { Title = "Open Affinity", Default = false })
AffinityToggle:OnChanged(function(state)
    pcall(function()
        local affinityUI = LocalPlayer.PlayerGui:FindFirstChild("MerchantsFolder")
            and LocalPlayer.PlayerGui.MerchantsFolder:FindFirstChild("AffinityUI")
        if affinityUI then
            affinityUI.Enabled = state
        end
    end)
end)

-- Auto Reroll Affinity
local affinityNames = {"Sword", "Sniper", "Melee", "Defense"}
_G.SelectedAffinities = {}
_G.RerollTarget = 10
_G.AutoRerollMoney = false
_G.AutoRerollGem = false
_G.SelectedFruit = "Fruit 1"

local function getAffinityPath()
    local path = nil
    pcall(function()
        if _G.SelectedFruit == "Fruit 1" or _G.SelectedFruit == "ผลที่1" then
            path = LocalPlayer.PlayerGui.MerchantsFolder.AffinityUI.Frame.Affinities2b
        else
            path = LocalPlayer.PlayerGui.MerchantsFolder.AffinityUI.Frame.Affinities2a
        end
    end)
    return path
end

local function getBarCount(statName)
    local count = 0
    pcall(function()
        local circle = getAffinityPath()[statName].Circle
        count = math.floor(circle.Size.X.Scale / 0.2 + 0.5)
    end)
    return count
end

local function isAffinityLocked(statName)
    local locked = false
    pcall(function()
        local lock = getAffinityPath()[statName].Lock
        locked = lock.ImageTransparency < 0.5
    end)
    return locked
end

local function clickOnce(btn)
    local events = {"Activated", "MouseButton1Down", "MouseButton1Click", "MouseButton1Up"}
    for _, eventName in next, events do
        local conns = nil
        pcall(function()
            conns = getconnections(btn[eventName])
        end)
        if conns then
            for _, connection in next, conns do
                pcall(function() connection.Function() end)
                return
            end
        end
    end
end

local function toggleAffinityLock(statName, shouldLock)
    pcall(function()
        local lock = getAffinityPath()[statName].Lock
        local currentlyLocked = lock.ImageTransparency < 0.5
        if shouldLock and not currentlyLocked then
            clickOnce(lock)
        elseif not shouldLock and currentlyLocked then
            clickOnce(lock)
        end
    end)
end

local function waitForRerollAnimation()
    task.wait(0.5)
    while true do
        local sizes = {}
        for _, name in ipairs(affinityNames) do
            pcall(function()
                sizes[name] = getAffinityPath()[name].Circle.Size.X.Scale
            end)
        end
        task.wait(0.3)
        local changed = false
        for _, name in ipairs(affinityNames) do
            pcall(function()
                local current = getAffinityPath()[name].Circle.Size.X.Scale
                if math.abs(current - (sizes[name] or 0)) > 0.01 then
                    changed = true
                end
            end)
        end
        if not changed then break end
    end
    task.wait(0.3)
end

local function doAutoReroll(rerollType)
    local rerollName = rerollType == "money" and "Reroll1" or "Reroll2"
    local globalName = rerollType == "money" and "AutoRerollMoney" or "AutoRerollGem"

    while _G[globalName] do
        local ok, err = pcall(function()
            local affinityUI = getAffinityPath()
            if not affinityUI then task.wait(1) return end

            -- เช็คเฉพาะตัวที่เลือกไว้
            local allDone = true
            for _, statName in ipairs(affinityNames) do
                if not _G[globalName] then return end
                local isSelected = _G.SelectedAffinities[statName] == true

                if isSelected then
                    local bars = getBarCount(statName)
                    if bars >= _G.RerollTarget then
                        -- ได้ตามเป้าแล้ว → ล็อกตัวนี้
                        if not isAffinityLocked(statName) then
                            toggleAffinityLock(statName, true)
                            task.wait(0.3)
                        end
                    else
                        -- ยังไม่ถึง → ปลดล็อกให้สุ่มต่อ
                        if isAffinityLocked(statName) then
                            toggleAffinityLock(statName, false)
                            task.wait(0.3)
                        end
                        allDone = false
                    end
                end
            end

            -- ครบหมดแล้ว → หยุด
            if allDone then
                _G[globalName] = false
                return
            end

            task.wait(0.3)

            -- กดสุ่ม (ครั้งเดียว)
            pcall(function()
                local rerollBtn = affinityUI[rerollName]
                clickOnce(rerollBtn)
            end)

            -- รอแอนิเมชั่นเสร็จ
            waitForRerollAnimation()
        end)

        if not ok then
            task.wait(1)
        end
    end
end

-- Dropdown เลือกผล
local FruitDropdown = Tabs.Affinity:AddDropdown("SelectFruit", {
    Title = "Select Fruit",
    Values = {"Fruit 1", "Fruit 2"},
    Multi = false,
    Default = "Fruit 1",
})
FruitDropdown:OnChanged(function(val)
    _G.SelectedFruit = val
end)

-- Dropdown เลือกพลัง
local AffinityDropdown = Tabs.Affinity:AddDropdown("SelectAffinity", {
    Title = "Select Stats",
    Values = affinityNames,
    Multi = true,
    Default = {},
})
AffinityDropdown:OnChanged(function(selected)
    -- แปลงให้เป็น {Sword = true, Melee = true, ...} ทุกกรณี
    local result = {}
    if type(selected) == "table" then
        for k, v in pairs(selected) do
            if type(v) == "string" then
                result[v] = true
            elseif v == true and type(k) == "string" then
                result[k] = true
            end
        end
    elseif type(selected) == "string" then
        result[selected] = true
    end
    _G.SelectedAffinities = result
end)

-- Dropdown เลือกจำนวนขีด
local BarDropdown = Tabs.Affinity:AddDropdown("TargetBars", {
    Title = "Target Bars",
    Values = {"1","2","3","4","5","6","7","8","9","10"},
    Multi = false,
    Default = "10",
})
BarDropdown:OnChanged(function(val)
    _G.RerollTarget = tonumber(val) or 10
end)

-- Toggle สุ่มด้วยเงิน
local MoneyRerollToggle = Tabs.Affinity:AddToggle("AutoRerollMoney", { Title = "Auto Reroll (Beri $100,000)", Default = false })
MoneyRerollToggle:OnChanged(function(state)
    _G.AutoRerollMoney = state
    if state then
        task.spawn(function()
            doAutoReroll("money")
            MoneyRerollToggle:SetValue(false)
        end)
    end
end)
MoneyRerollToggle:SetValue(false)

-- Toggle สุ่มด้วยเพชร
local GemRerollToggle = Tabs.Affinity:AddToggle("AutoRerollGem", { Title = "Auto Reroll (10 Gems)", Default = false })
GemRerollToggle:OnChanged(function(state)
    _G.AutoRerollGem = state
    if state then
        task.spawn(function()
            doAutoReroll("gem")
            GemRerollToggle:SetValue(false)
        end)
    end
end)
GemRerollToggle:SetValue(false)

-- =============================================
-- PLAYERS TAB
-- =============================================
Tabs.PlayerTab:AddParagraph({ Title = "Select", Content = "" })

local function getPlayerList()
    local list = {}
    local alive = workspace:FindFirstChild("Alive")
    if alive then
        for _, char in ipairs(alive:GetChildren()) do
            if Players:FindFirstChild(char.Name) and char.Name ~= LocalPlayer.Name then
                table.insert(list, char.Name)
            end
        end
    end
    if #list == 0 then table.insert(list, "No Players") end
    return list
end

local selectedPlayer = nil

-- Dropdown เลือกผู้เล่น
local PlayerDropdown = Tabs.PlayerTab:AddDropdown("PlayerSelect", {
    Title = "Select Player",
    Values = getPlayerList(),
    Multi = false,
    Default = 1,
})
PlayerDropdown:OnChanged(function(val)
    selectedPlayer = val
end)
selectedPlayer = PlayerDropdown.Value

-- ปุ่ม Refresh รายชื่อ
Tabs.PlayerTab:AddButton({
    Title = "Refresh",
    Callback = function()
        PlayerDropdown:SetValues(getPlayerList())
        Fluent:Notify({ Title = "Refreshed!", Content = "Player list updated", Duration = 2 })
    end
})

Tabs.PlayerTab:AddParagraph({ Title = "Teleport & View", Content = "" })

-- Toggle Tp ค้างไปหาผู้เล่น (เช็ค spawn เหมือน Haki tab)
_G.TpToPlayer = false
local TpPlayerToggle = Tabs.PlayerTab:AddToggle("TpToPlayer", { Title = "Tp to Player", Default = false })
TpPlayerToggle:OnChanged(function(state)
    _G.TpToPlayer = state
    if not state then return end
    task.spawn(function()
        while _G.TpToPlayer do
            pcall(function()
                if not selectedPlayer or selectedPlayer == "No Players" then return end

                local myChar = LocalPlayer.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not myHRP then return end

                local alive = workspace:FindFirstChild("Alive")
                if not alive then return end
                local targetChar = alive:FindFirstChild(selectedPlayer)
                if not targetChar then return end

                local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                if not targetHRP then return end
                local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
                if not targetHum or targetHum.Health <= 0 then return end
                if targetHRP.Position.Y < 0 then return end

                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
            end)
            task.wait()
        end
    end)
end)

-- Toggle View มองมุมมองผู้เล่น
_G.ViewPlayer = false
local ViewPlayerToggle = Tabs.PlayerTab:AddToggle("ViewPlayer", { Title = "View Player", Default = false })
ViewPlayerToggle:OnChanged(function(state)
    _G.ViewPlayer = state
    local camera = workspace.CurrentCamera
    if not state then
        camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") or nil
        camera.CameraType = Enum.CameraType.Custom
        return
    end
    task.spawn(function()
        while _G.ViewPlayer do
            if selectedPlayer and selectedPlayer ~= "No Players" then
                local alive = workspace:FindFirstChild("Alive")
                if alive then
                    local targetChar = alive:FindFirstChild(selectedPlayer)
                    if targetChar then
                        local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
                        if targetHum then
                            camera.CameraSubject = targetHum
                            camera.CameraType = Enum.CameraType.Custom
                        end
                    end
                end
            end
            task.wait(1)
        end
    end)
end)

-- Toggle ESP ผู้เล่นทุกคน
_G.EspPlayer = false
local playerEspFolder = Instance.new("Folder")
playerEspFolder.Name = "PlayerESP"
playerEspFolder.Parent = game.CoreGui

local function clearPlayerESP()
    playerEspFolder:ClearAllChildren()
    local alive = workspace:FindFirstChild("Alive")
    if alive then
        for _, char in ipairs(alive:GetChildren()) do
            pcall(function()
                local hl = char:FindFirstChild("PlayerHighlight")
                if hl then hl:Destroy() end
            end)
        end
    end
end

local EspPlayerToggle = Tabs.PlayerTab:AddToggle("EspPlayer", { Title = "ESP All Players", Default = false })
EspPlayerToggle:OnChanged(function(state)
    _G.EspPlayer = state
    if not state then clearPlayerESP() return end
    task.spawn(function()
        while _G.EspPlayer do
            local alive = workspace:FindFirstChild("Alive")
            if alive then
                for _, char in ipairs(alive:GetChildren()) do
                    local player = Players:FindFirstChild(char.Name)
                    if player and char.Name ~= LocalPlayer.Name and not char:FindFirstChild("PlayerHighlight") then
                        pcall(function()
                            local highlight = Instance.new("Highlight")
                            highlight.Name = "PlayerHighlight"
                            highlight.Adornee = char
                            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            highlight.FillColor = Color3.fromRGB(0, 255, 0)
                            highlight.FillTransparency = 0.3
                            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                            highlight.Parent = char

                            local billboard = Instance.new("BillboardGui")
                            billboard.Name = char.Name .. "_NameTag"
                            billboard.Size = UDim2.new(0, 250, 0, 50)
                            billboard.AlwaysOnTop = true
                            billboard.StudsOffset = Vector3.new(0, 3, 0)
                            billboard.Adornee = char:FindFirstChild("Head")
                            billboard.Parent = playerEspFolder

                            local tag = Instance.new("TextLabel", billboard)
                            tag.BackgroundTransparency = 1
                            tag.Size = UDim2.new(1, 0, 1, 0)
                            tag.TextSize = 14
                            tag.Font = Enum.Font.SourceSansBold
                            tag.TextColor3 = Color3.fromRGB(0, 255, 0)
                            tag.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            tag.TextStrokeTransparency = 0.3
                            tag.Text = char.Name
                        end)
                    end
                end
            end
            task.wait(2)
        end
        clearPlayerESP()
    end)
end)

Tabs.PlayerTab:AddParagraph({ Title = "Combat", Content = "" })

-- =============================================
-- HITBOX EXPANDER (Players Tab)
-- =============================================
_G.HitboxEnabled = false
local HitboxSize = 50

local HitboxSlider = Tabs.PlayerTab:AddSlider("HitboxSize", {
    Title = "Hitbox Size",
    Min = 1,
    Max = 100,
    Default = 50,
    Rounding = 0,
})
HitboxSlider:OnChanged(function(val)
    HitboxSize = val
end)

local hitboxConnection = nil
local HitboxToggle = Tabs.PlayerTab:AddToggle("HitboxExpand", { Title = "Hitbox Expander", Default = false })
HitboxToggle:OnChanged(function(state)
    _G.HitboxEnabled = state
    if not state then
        if hitboxConnection then hitboxConnection:Disconnect() hitboxConnection = nil end
        -- reset ขนาดเดิม
        pcall(function()
            local alive = workspace:FindFirstChild("Alive")
            if alive then
                for _, char in ipairs(alive:GetChildren()) do
                    pcall(function()
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.Size = Vector3.new(2, 2, 1)
                            hrp.Transparency = 1
                            hrp.Material = Enum.Material.SmoothPlastic
                        end
                    end)
                end
            end
        end)
        return
    end
    hitboxConnection = game:GetService("RunService").RenderStepped:Connect(function()
        if not _G.HitboxEnabled then return end
        local alive = workspace:FindFirstChild("Alive")
        if not alive then return end
        for _, char in ipairs(alive:GetChildren()) do
            if char.Name ~= LocalPlayer.Name and Players:FindFirstChild(char.Name) then
                pcall(function()
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                        hrp.Transparency = 0.7
                        hrp.BrickColor = BrickColor.new("Really red")
                        hrp.Material = Enum.Material.Neon
                        hrp.CanCollide = false
                    end
                end)
            end
        end
    end)
end)
-- =============================================
-- QUEST TAB
-- =============================================

-- Auto Gemologist Quest
_G.AutoGemologist = false
local GemologistToggle = Tabs.Quest:AddToggle("AutoGemologist", { Title = "Auto Buy Gem 50", Default = false })
GemologistToggle:OnChanged(function(state)
    _G.AutoGemologist = state
    if state then
        task.spawn(function()
            while _G.AutoGemologist do
                local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local gui = LocalPlayer:WaitForChild("PlayerGui")
                if not _G.AutoGemologist then break end

                -- วาปไปหา Gemologist
                local npc = nil
                pcall(function() npc = workspace.Ignore.NPCs.DailyQuest.Gemologist end)
                if npc then
                    warpToNPC(character, npc)
                    task.wait(0.3)
                    interactNPC(npc)
                    task.wait(0.5)
                end

                -- กด Option (Buy Gems)
                pcall(function()
                    local optionBtn = gui.QuestGui.Dialogue.Options.Option
                    getconnect(optionBtn)
                end)
                task.wait(0.3)

                -- อ่านจำนวนที่ซื้อได้จาก OptionName เช่น [49/50 today]
                local buyAmount = 0
                pcall(function()
                    local optionText = gui.QuestGui.Dialogue.Options.Option.OptionName.Text
                    local num = string.match(optionText, "%[(%d+)/%d+ today%]")
                    if num then buyAmount = tonumber(num) end
                end)

                -- ใส่จำนวนใน NumberInput
                if buyAmount > 0 then
                    pcall(function()
                        gui.QuestGui.Dialogue.Options.NumberInput.Text = tostring(buyAmount)
                    end)
                    task.wait(0.3)

                    -- กด Option2 (ยืนยัน)
                    pcall(function()
                        local option2Btn = gui.QuestGui.Dialogue.Options.Option2
                        getconnect(option2Btn)
                    end)
                    task.wait(0.3)
                end

                -- กด Leave (ออก)
                pcall(function()
                    local leaveBtn = gui.QuestGui.Dialogue.Options.Leave
                    getconnect(leaveBtn)
                end)
                task.wait(1)
            end
        end)
    end
end)
GemologistToggle:SetValue(false)

-- Auto Traceur Quest
_G.AutoTraceurQuest = false
local TraceurToggle = Tabs.Quest:AddToggle("AutoTraceurQuest", { Title = "Auto Traceur Quest", Default = false })
TraceurToggle:OnChanged(function(state)
    _G.AutoTraceurQuest = state
    if state then
        task.spawn(function()
            while _G.AutoTraceurQuest do
                local player = LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                while humanoid and humanoid.Health <= 0 do
                    task.wait()
                    character = player.Character or player.CharacterAdded:Wait()
                    humanoid = character:FindFirstChildOfClass("Humanoid")
                end
                local gui = player:WaitForChild("PlayerGui")

                if not hasQuest(gui, "Bridge Challenge") then
                    local npc = workspace.Ignore.NPCs.Quest:FindFirstChild("Traceur")
                    if npc then
                        warpToNPC(character, npc)
                        task.wait(0.5)
                        repeat
                            if not _G.AutoTraceurQuest then break end
                            interactNPC(npc)
                            clickDialogue(gui)
                            task.wait(0.5)
                        until hasQuest(gui, "Bridge Challenge") or not _G.AutoTraceurQuest
                    end
                    if not _G.AutoTraceurQuest then break end
                end

                task.wait(1)
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() hrp.CFrame = CFrame.new(-291.17, 306.12, -597.45) end) end
                task.wait(1)
                if hrp then pcall(function() hrp.CFrame = CFrame.new(-290.09, 306.12, -577.72) end) end

                repeat task.wait(0.5)
                until (string.find(questScrollText(gui, 5), "1/1")) or not _G.AutoTraceurQuest
                if not _G.AutoTraceurQuest then break end

                task.wait(0.5)
                local npc = workspace.Ignore.NPCs.Quest:FindFirstChild("Traceur")
                if npc then
                    warpToNPC(character, npc)
                    task.wait(0.5)
                    interactNPC(npc)
                    task.wait(0.5)
                end
                pcall(function()
                    local option = gui.QuestGui.Dialogue.Options:FindFirstChild("Option")
                    if option and option.Visible then getconnect(option) end
                end)
                task.wait(0.3)
                pcall(function()
                    local leave = gui.QuestGui.Dialogue.Options:FindFirstChild("Leave")
                    if leave then getconnect(leave) end
                end)
                task.wait(1)
            end
        end)
    end
end)
TraceurToggle:SetValue(false)

-- Auto Humble Man #1
_G.AutoHumbleMan1 = false
local HumbleToggle = Tabs.Quest:AddToggle("AutoHumbleMan1", { Title = "Auto Humble Man #1", Default = false })
HumbleToggle:OnChanged(function(state)
    _G.AutoHumbleMan1 = state
    if state then
        task.spawn(function()
            while _G.AutoHumbleMan1 do
                local player = LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                local gui = player:WaitForChild("PlayerGui")

                local requiredItems = {
                    { name = "Pumpkin",      amount = 20 },
                    { name = "Golden Apple", amount = 1  },
                    { name = "Melon",        amount = 20 },
                    { name = "Coconut",      amount = 20 },
                    { name = "Apple",        amount = 20 },
                    { name = "Cantaloupe",   amount = 20 },
                    { name = "Green Apple",  amount = 20 },
                    { name = "Banana",       amount = 20 },
                }

                local function countItem(itemName)
                    local count = 0
                    for _, src in ipairs({ player:FindFirstChild("Backpack"), player.Character }) do
                        if src then
                            for _, v in ipairs(src:GetChildren()) do
                                if v.Name == itemName then count += 1 end
                            end
                        end
                    end
                    return count
                end

                local function allItemsDone()
                    for _, item in ipairs(requiredItems) do
                        if countItem(item.name) < item.amount then return false end
                    end
                    return true
                end

                if not hasQuest(gui, "Humble Man #1") then
                    local npc = workspace.Ignore.NPCs.Quest:FindFirstChild("Old Beggar")
                    if npc then
                        warpToNPC(character, npc)
                        task.wait(0.5)
                        repeat
                            if not _G.AutoHumbleMan1 then break end
                            interactNPC(npc)
                            clickDialogue(gui)
                            task.wait(0.5)
                        until hasQuest(gui, "Humble Man #1") or not _G.AutoHumbleMan1
                    end
                    if not _G.AutoHumbleMan1 then break end
                end

                task.wait(1)

                while _G.AutoHumbleMan1 and not allItemsDone() do
                    character = player.Character or player.CharacterAdded:Wait()
                    local HRP = character:FindFirstChild("HumanoidRootPart")
                    local barrelsFolder = workspace:FindFirstChild("Barrels")
                    local targets = {}
                    if barrelsFolder then
                        for _, folder in ipairs({ barrelsFolder:FindFirstChild("Barrels"), barrelsFolder:FindFirstChild("Crates") }) do
                            if folder then
                                for _, obj in ipairs(folder:GetChildren()) do
                                    if obj:IsA("BasePart") then table.insert(targets, obj) end
                                end
                            end
                        end
                    end
                    for _, target in ipairs(targets) do
                        if not _G.AutoHumbleMan1 or allItemsDone() then break end
                        if target and target.Parent then
                            pcall(function() HRP.CFrame = CFrame.new(target.Position + target.CFrame.LookVector * 3 + Vector3.new(0, 2, 0)) end)
                            task.wait(0.12)
                            local cd = target:FindFirstChildWhichIsA("ClickDetector", true)
                            if cd then
                                for i = 1, 20 do
                                    if not _G.AutoHumbleMan1 or allItemsDone() then break end
                                    pcall(function() fireclickdetector(cd) end)
                                    task.wait()
                                end
                            end
                            task.wait()
                        end
                    end
                    task.wait()
                end

                if not _G.AutoHumbleMan1 then break end
                task.wait(0.5)

                local npc = workspace.Ignore.NPCs.Quest:FindFirstChild("Old Beggar")
                if npc then
                    warpToNPC(character, npc)
                    task.wait(0.5)
                    interactNPC(npc)
                    task.wait(0.5)
                end
                pcall(function()
                    local opt2 = gui.QuestGui.Dialogue.Options:FindFirstChild("Option2")
                    if opt2 and opt2.Visible then getconnect(opt2) end
                end)
                task.wait(0.3)
                if npc then interactNPC(npc) task.wait(0.5) end
                pcall(function()
                    local opt = gui.QuestGui.Dialogue.Options:FindFirstChild("Option")
                    if opt and opt.Visible then getconnect(opt) end
                end)
                task.wait(0.3)
                pcall(function()
                    local leave = gui.QuestGui.Dialogue.Options:FindFirstChild("Leave")
                    if leave then getconnect(leave) end
                end)
                task.wait(1)
                task.wait(6)
            end
        end)
    end
end)
HumbleToggle:SetValue(false)

-- Auto Marge Quest
_G.AutoMargeQuest = false
local MargeToggle = Tabs.Quest:AddToggle("AutoMargeQuest", { Title = "Auto Marge Quest", Default = false })
MargeToggle:OnChanged(function(state)
    _G.AutoMargeQuest = state
    if state then
        task.spawn(function()
            while _G.AutoMargeQuest do
                local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                local gui = LocalPlayer:WaitForChild("PlayerGui")
                local marge = workspace.Ignore.NPCs.Quest:FindFirstChild("Marge Nospmis")
                local bart = workspace.Ignore.NPCs.Information:FindFirstChild("Bart Nospmis")

                if marge then warpToNPC(character, marge) task.wait(0.5) interactNPC(marge) task.wait(0.5) clickDialogue(gui) task.wait(0.5) end
                if bart then warpToNPC(character, bart) task.wait(0.5) interactNPC(bart) task.wait(0.5) clickDialogue(gui) task.wait(0.5) end
                if marge then warpToNPC(character, marge) task.wait(0.5) interactNPC(marge) task.wait(0.5) clickDialogue(gui) task.wait(0.5) end

                task.wait(1)
            end
        end)
    end
end)
MargeToggle:SetValue(false)

-- Auto Thief Beater
_G.AutoThiefBeater = false
local ThiefToggle = Tabs.Quest:AddToggle("AutoThiefBeater", { Title = "Auto Thief Beater", Default = false })
ThiefToggle:OnChanged(function(state)
    _G.AutoThiefBeater = state
    if state then
        task.spawn(function()
            while _G.AutoThiefBeater do
                local player = LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                local gui = player:WaitForChild("PlayerGui")
                local doneFunc = function() return string.find(questScrollText(gui, 5), "10/10") ~= nil end

                if not hasQuest(gui, "Thief Beater") then
                    local npc = workspace.Ignore.NPCs.Quest:FindFirstChild("Guard Captain")
                    if npc then
                        warpToNPC(character, npc) task.wait(0.5)
                        repeat
                            if not _G.AutoThiefBeater then break end
                            interactNPC(npc) clickDialogue(gui) task.wait(0.5)
                        until hasQuest(gui, "Thief Beater") or not _G.AutoThiefBeater
                    end
                    if not _G.AutoThiefBeater then break end
                end

                while _G.AutoThiefBeater and not doneFunc() do
                    character = player.Character or player.CharacterAdded:Wait()
                    fightMob(character, "Thief", "AutoThiefBeater", doneFunc)
                    task.wait()
                end

                if not _G.AutoThiefBeater then break end
                local npc = workspace.Ignore.NPCs.Quest:FindFirstChild("Guard Captain")
                if npc then warpToNPC(character, npc) task.wait(0.5) interactNPC(npc) task.wait(0.5) clickDialogue(gui) end
                task.wait(1) task.wait(6)
            end
        end)
    end
end)
ThiefToggle:SetValue(false)

-- Auto Fallen Captain's Savior
_G.AutoFallenCaptain = false
local FallenToggle = Tabs.Quest:AddToggle("AutoFallenCaptain", { Title = "Auto Fallen Captain's Savior", Default = false })
FallenToggle:OnChanged(function(state)
    _G.AutoFallenCaptain = state
    if state then
        task.spawn(function()
            while _G.AutoFallenCaptain do
                local player = LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                local gui = player:WaitForChild("PlayerGui")
                local banditDone = function() return string.find(questScrollText(gui, 5), "3/3") ~= nil end
                local treasureDone = function() return string.find(questScrollText(gui, 6), "1/1") ~= nil end

                if not hasQuest(gui, "Fallen Captain's Savior") then
                    local npc = workspace.Ignore.NPCs.Quest:FindFirstChild("Fallen Captain")
                    if npc then
                        warpToNPC(character, npc) task.wait(0.5)
                        repeat
                            if not _G.AutoFallenCaptain then break end
                            interactNPC(npc) clickDialogue(gui) task.wait(0.5)
                        until hasQuest(gui, "Fallen Captain's Savior") or not _G.AutoFallenCaptain
                    end
                    if not _G.AutoFallenCaptain then break end
                end

                task.wait(1)

                while _G.AutoFallenCaptain and not banditDone() do
                    character = player.Character or player.CharacterAdded:Wait()
                    fightMob(character, "Bandit", "AutoFallenCaptain", banditDone)
                    task.wait()
                end

                if not _G.AutoFallenCaptain then break end

                while _G.AutoFallenCaptain and not treasureDone() do
                    character = player.Character or player.CharacterAdded:Wait()
                    local HRP = character:FindFirstChild("HumanoidRootPart")
                    pcall(function()
                        local part = workspace.Chests["Fallen Captain"].TreasureChest.PrimaryPart
                            or workspace.Chests["Fallen Captain"].TreasureChest:FindFirstChildWhichIsA("BasePart", true)
                        if part and HRP then HRP.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0)) end
                    end)
                    task.wait(0.2)
                end

                if not _G.AutoFallenCaptain then break end
                local npc = workspace.Ignore.NPCs.Quest:FindFirstChild("Fallen Captain")
                if npc then warpToNPC(character, npc) task.wait(0.5) interactNPC(npc) task.wait(0.5) clickDialogue(gui) end
                task.wait(1) task.wait(6)
            end
        end)
    end
end)
FallenToggle:SetValue(false)

-- Auto Explorer Quest
_G.AutoExplorerQuest = false
local ExplorerToggle = Tabs.Quest:AddToggle("AutoExplorerQuest", { Title = "Auto Explorer Quest", Default = false })
ExplorerToggle:OnChanged(function(state)
    _G.AutoExplorerQuest = state
    if state then
        task.spawn(function()
            local islandCFrames = {}
            for _, island in ipairs(Islands) do table.insert(islandCFrames, island.cf) end

            while _G.AutoExplorerQuest do
                local player = LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                local gui = player:WaitForChild("PlayerGui")

                local function allIslandsDone()
                    local children = gui.QuestGui.QuestsFrame.QuestsScroll:GetChildren()
                    for i = 5, 20 do
                        local ok, text = pcall(function() return children[i].Text end)
                        if not ok or not string.find(text, "1/1") then return false end
                    end
                    return true
                end

                if not hasQuest(gui, "Adventures") then
                    local npc = workspace.Ignore.NPCs.Quest:FindFirstChild("Explorer")
                    if npc then
                        warpToNPC(character, npc) task.wait(0.5)
                        repeat
                            if not _G.AutoExplorerQuest then break end
                            interactNPC(npc) clickDialogue(gui) task.wait(0.5)
                        until hasQuest(gui, "Adventures") or not _G.AutoExplorerQuest
                    end
                    if not _G.AutoExplorerQuest then break end
                end

                task.wait(1)

                while _G.AutoExplorerQuest and not allIslandsDone() do
                    character = player.Character or player.CharacterAdded:Wait()
                    local HRP = character:FindFirstChild("HumanoidRootPart")
                    for _, cf in ipairs(islandCFrames) do
                        if not _G.AutoExplorerQuest then break end
                        if HRP then pcall(function() HRP.CFrame = cf end) end
                        task.wait(0.5)
                    end
                    task.wait(0.5)
                end

                if not _G.AutoExplorerQuest then break end
                local npc = workspace.Ignore.NPCs.Quest:FindFirstChild("Explorer")
                if npc then warpToNPC(character, npc) task.wait(0.5) interactNPC(npc) task.wait(0.5) clickDialogue(gui) end
                task.wait(1)
            end
        end)
    end
end)
ExplorerToggle:SetValue(false)

-- Auto Make'em Chill
_G.AutoMakeEmChill = false
local ChillToggle = Tabs.Quest:AddToggle("AutoMakeEmChill", { Title = "Auto Make'em Chill", Default = false })
ChillToggle:OnChanged(function(state)
    _G.AutoMakeEmChill = state
    if state then
        task.spawn(function()
            while _G.AutoMakeEmChill do
                local player = LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                local gui = player:WaitForChild("PlayerGui")
                local doneFunc = function()
                    local children = gui.QuestGui.QuestsFrame.QuestsScroll:GetChildren()
                    local ok, t5, t6 = pcall(function() return children[5].Text, children[6].Text end)
                    return ok and string.find(t5 or "", "1/1") and string.find(t6 or "", "1/1")
                end

                if not hasQuest(gui, "Make'em Chill") then
                    local npc = workspace.Ignore.NPCs.Quest:FindFirstChild("Chill Billy")
                    if npc then
                        warpToNPC(character, npc) task.wait(0.5)
                        repeat
                            if not _G.AutoMakeEmChill then break end
                            interactNPC(npc) clickDialogue(gui) task.wait(0.5)
                        until hasQuest(gui, "Make'em Chill") or not _G.AutoMakeEmChill
                    end
                    if not _G.AutoMakeEmChill then break end
                end

                task.wait(1)
                while _G.AutoMakeEmChill and not doneFunc() do
                    character = player.Character or player.CharacterAdded:Wait()
                    fightMob(character, "Angry Bob", "AutoMakeEmChill", doneFunc)
                    fightMob(character, "Angry Freddy", "AutoMakeEmChill", doneFunc)
                    task.wait()
                end

                if not _G.AutoMakeEmChill then break end
                local npc = workspace.Ignore.NPCs.Quest:FindFirstChild("Chill Billy")
                if npc then warpToNPC(character, npc) task.wait(0.5) interactNPC(npc) task.wait(0.5) clickDialogue(gui) end
                task.wait(1) task.wait(6)
            end
        end)
    end
end)
ChillToggle:SetValue(false)

-- Auto No Good Time for Traitors
_G.AutoTraitorQuest = false
local TraitorToggle = Tabs.Quest:AddToggle("AutoTraitorQuest", { Title = "Auto No Good Time for Traitors", Default = false })
TraitorToggle:OnChanged(function(state)
    _G.AutoTraitorQuest = state
    if state then
        task.spawn(function()
            while _G.AutoTraitorQuest do
                local player = LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                local gui = player:WaitForChild("PlayerGui")
                local doneFunc = function() return string.find(questScrollText(gui, 5), "1/1") ~= nil end

                if not hasQuest(gui, "No Good Time for Traitors") then
                    local npc = workspace.Ignore.NPCs.Quest:FindFirstChild("Bandits Leader")
                    if npc then
                        warpToNPC(character, npc) task.wait(0.5)
                        repeat
                            if not _G.AutoTraitorQuest then break end
                            interactNPC(npc) clickDialogue(gui) task.wait(0.5)
                        until hasQuest(gui, "No Good Time for Traitors") or not _G.AutoTraitorQuest
                    end
                    if not _G.AutoTraitorQuest then break end
                end

                task.wait(1)
                while _G.AutoTraitorQuest and not doneFunc() do
                    character = player.Character or player.CharacterAdded:Wait()
                    fightMob(character, "Bandit Traitor", "AutoTraitorQuest", doneFunc)
                    task.wait()
                end

                if not _G.AutoTraitorQuest then break end
                local npc = workspace.Ignore.NPCs.Quest:FindFirstChild("Bandits Leader")
                if npc then warpToNPC(character, npc) task.wait(0.5) interactNPC(npc) task.wait(0.5) clickDialogue(gui) end
                task.wait(1) task.wait(6)
            end
        end)
    end
end)
TraitorToggle:SetValue(false)

-- Auto Gem Hunter
_G.AutoGemHunter = false
local GemToggle = Tabs.Quest:AddToggle("AutoGemHunter", { Title = "Auto Gem Hunter", Default = false })
GemToggle:OnChanged(function(state)
    _G.AutoGemHunter = state
    if state then
        task.spawn(function()
            while _G.AutoGemHunter do
                local player = LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                local gui = player:WaitForChild("PlayerGui")
                local doneFunc = function() return string.find(questScrollText(gui, 5), "1/1") ~= nil end

                if not hasQuest(gui, "Gem Hunter") then
                    local npc = workspace.Ignore.NPCs.DailyQuest:FindFirstChild("Gemologist")
                    if npc then
                        warpToNPC(character, npc) task.wait(0.5)
                        repeat
                            if not _G.AutoGemHunter then break end
                            interactNPC(npc) clickDialogue(gui) task.wait(0.5)
                        until hasQuest(gui, "Gem Hunter") or not _G.AutoGemHunter
                    end
                    if not _G.AutoGemHunter then break end
                end

                task.wait(1)
                while _G.AutoGemHunter and not doneFunc() do
                    character = player.Character or player.CharacterAdded:Wait()
                    local HRP = character:FindFirstChild("HumanoidRootPart")
                    pcall(function()
                        local gem = workspace.Chests.Gemologist.TreasureChest:FindFirstChild("Gem")
                        if gem and HRP then HRP.CFrame = CFrame.new(gem.Position + Vector3.new(0, 3, 0)) end
                    end)
                    task.wait(0.2)
                end

                if not _G.AutoGemHunter then break end
                local npc = workspace.Ignore.NPCs.DailyQuest:FindFirstChild("Gemologist")
                if npc then warpToNPC(character, npc) task.wait(0.5) interactNPC(npc) task.wait(0.5) clickDialogue(gui) end
                task.wait(1) task.wait(6)
            end
        end)
    end
end)
GemToggle:SetValue(false)


_G.StayCFrame = false

local StayToggle = Tabs.Quest:AddToggle("StayCFrame", {
    Title = "Stay CFrame",
    Default = false
})

local TargetCFrame = CFrame.new(
    -1278.33044, 217.999985, -1352.63416,
    0.0182099547, -2.76895769e-08, 0.99983418,
    8.89186769e-09, 1, 2.75322218e-08,
    -0.99983418, 8.38903258e-09, 0.0182099547
)

_G.BountyPause = false
_G.BountyNextTry = 0 -- เวลาที่จะลองรับเควสครั้งต่อไป

local function doBountyHunt()
    local player = LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local gui = player:WaitForChild("PlayerGui")

    local npc = workspace.Ignore.NPCs.DailyQuest:FindFirstChild("C0")
    if not npc then return end

    warpToNPC(character, npc)
    task.wait(0.5)
    interactNPC(npc)
    task.wait(0.5)

    -- เช็ค cooldown
    local hasCooldown = false
    pcall(function()
        local optionName = gui.QuestGui.Dialogue.Options.Option.OptionName
        if optionName and string.find(optionName.Text, "When can I hunt again") then
            hasCooldown = true
        end
    end)

    if hasCooldown then
        pcall(function()
            local leave = gui.QuestGui.Dialogue.Options:FindFirstChild("Leave")
            if leave then getconnect(leave) end
        end)
        -- ดึงเวลา cooldown จากข้อความ เช่น "When can I hunt again? (54 min)"
        pcall(function()
            local optionName = gui.QuestGui.Dialogue.Options.Option.OptionName
            local minutes = tonumber(string.match(optionName.Text, "(%d+) min"))
            if minutes then
                _G.BountyNextTry = os.clock() + (minutes * 60)
            else
                _G.BountyNextTry = os.clock() + 300 -- ถ้าอ่านเวลาไม่ได้ รอ 5 นาที
            end
        end)
        return false -- ยังไม่พร้อม
    end

    -- กด Option (คนที่ 1)
    local dialogue = gui:FindFirstChild("QuestGui") and gui.QuestGui:FindFirstChild("Dialogue")
    if dialogue and dialogue.Visible then
        pcall(function()
            local option = dialogue.Options:FindFirstChild("Option")
            if option and option.Visible then
                getconnect(option) task.wait() getconnect(option) task.wait() getconnect(option)
            end
        end)
        task.wait(0.5)
        pcall(function()
            local leave = gui.QuestGui.Dialogue.Options:FindFirstChild("Leave")
            if leave then getconnect(leave) end
        end)
    end

    task.wait(0.5)

    local questAccepted = false
    pcall(function()
        local questName = gui.QuestGui.QuestsFrame.QuestName.Text
        if string.find(questName, "Bounty Hunt") then questAccepted = true end
    end)

    if not questAccepted then
        -- กด Option2 (คนที่ 2)
        warpToNPC(character, npc)
        task.wait(0.5)
        interactNPC(npc)
        task.wait(0.5)

        local dialogue2 = gui:FindFirstChild("QuestGui") and gui.QuestGui:FindFirstChild("Dialogue")
        if dialogue2 and dialogue2.Visible then
            pcall(function()
                local option2 = dialogue2.Options:FindFirstChild("Option2")
                if option2 and option2.Visible then
                    getconnect(option2) task.wait() getconnect(option2) task.wait() getconnect(option2)
                end
            end)
            task.wait(0.5)
            pcall(function()
                local leave = gui.QuestGui.Dialogue.Options:FindFirstChild("Leave")
                if leave then getconnect(leave) end
            end)
        end

        task.wait(0.5)
        pcall(function()
            local questName = gui.QuestGui.QuestsFrame.QuestName.Text
            if string.find(questName, "Bounty Hunt") then questAccepted = true end
        end)
    end

    return questAccepted
end

StayToggle:OnChanged(function(state)
    _G.StayCFrame = state

    if state then
        task.spawn(function()
            while _G.StayCFrame do
                -- เช็คว่าต้องไปรับ Bounty Hunt ไหม
                if _G.AutoBountyHunt and not _G.BountyPause then
                    local gui = LocalPlayer:WaitForChild("PlayerGui")
                    local needBounty = true

                    -- เช็คว่ามีเควส Bounty Hunt อยู่แล้วหรือยัง
                    pcall(function()
                        local questName = gui.QuestGui.QuestsFrame.QuestName.Text
                        if string.find(questName, "Bounty Hunt") then
                            needBounty = false
                        end
                    end)

                    -- เช็คว่าถึงเวลาไปรับหรือยัง
                    if needBounty and os.clock() < _G.BountyNextTry then
                        needBounty = false -- ยังไม่ถึงเวลา ไม่ต้องไป
                    end

                    if needBounty then
                        _G.BountyPause = true -- พัก Stay CFrame

                        local success = doBountyHunt()

                        if success then
                            -- รับเสร็จ → กลับไปอ่านเวลา cooldown จาก NPC เลย
                            task.wait(1)
                            local npc = workspace.Ignore.NPCs.DailyQuest:FindFirstChild("C0")
                            if npc then
                                character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                                warpToNPC(character, npc)
                                task.wait(0.5)
                                interactNPC(npc)
                                task.wait(0.5)
                                pcall(function()
                                    local optionName = gui.QuestGui.Dialogue.Options.Option.OptionName
                                    local minutes = tonumber(string.match(optionName.Text, "(%d+) min"))
                                    if minutes then
                                        _G.BountyNextTry = os.clock() + (minutes * 60)
                                    else
                                        _G.BountyNextTry = os.clock() + 3600
                                    end
                                end)
                                pcall(function()
                                    local leave = gui.QuestGui.Dialogue.Options:FindFirstChild("Leave")
                                    if leave then getconnect(leave) end
                                end)
                            else
                                _G.BountyNextTry = os.clock() + 3600
                            end
                        else
                            -- รับไม่ได้ → ตั้ง cooldown 5 นาที
                            if _G.BountyNextTry <= os.clock() then
                                _G.BountyNextTry = os.clock() + 300
                            end
                        end

                        _G.BountyPause = false -- กลับมาทำ Stay CFrame ต่อ
                    end
                end

                -- Stay CFrame ปกติ (หยุดถ้ากำลังตีบอสอยู่)
                if not _G.BountyPause and not _G.FightingBoss then
                    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    local HRP = character:FindFirstChild("HumanoidRootPart")
                    if HRP then
                        HRP.CFrame = TargetCFrame
                    end
                end

                task.wait(0.2)
            end
        end)
    end
end)

StayToggle:SetValue(false)


_G.AutoBountyHunt = false
local BountyToggle = Tabs.Quest:AddToggle("AutoBountyHunt", { Title = "Auto Bounty Hunt", Default = false })
BountyToggle:OnChanged(function(state)
    _G.AutoBountyHunt = state
    if state then
        task.spawn(function()
            while _G.AutoBountyHunt do
                local player = LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                local humanoid = character:FindFirstChildOfClass("Humanoid")

                while humanoid and humanoid.Health <= 0 do
                    task.wait(1)
                    character = player.Character or player.CharacterAdded:Wait()
                    humanoid = character:FindFirstChildOfClass("Humanoid")
                end

                local gui = player:WaitForChild("PlayerGui")

                -- วาร์ปไปหา NPC C0
                local npc = workspace.Ignore.NPCs.DailyQuest:FindFirstChild("C0")
                if npc then
                    warpToNPC(character, npc)
                    task.wait(0.5)
                    interactNPC(npc)
                    task.wait(0.5)

                    -- เช็ค cooldown
                    local hasCooldown = false
                    pcall(function()
                        local optionName = gui.QuestGui.Dialogue.Options.Option.OptionName
                        if optionName and string.find(optionName.Text, "When can I hunt again") then
                            hasCooldown = true
                        end
                    end)

                    if hasCooldown then
                        pcall(function()
                            local leave = gui.QuestGui.Dialogue.Options:FindFirstChild("Leave")
                            if leave then getconnect(leave) end
                        end)
                        task.wait(60)
                    else
                        -- กดรับเควส Option (คนที่ 1)
                        local dialogue = gui:FindFirstChild("QuestGui") and gui.QuestGui:FindFirstChild("Dialogue")
                        if dialogue and dialogue.Visible then
                            pcall(function()
                                local option = dialogue.Options:FindFirstChild("Option")
                                if option and option.Visible then
                                    getconnect(option)
                                    task.wait()
                                    getconnect(option)
                                    task.wait()
                                    getconnect(option)
                                end
                            end)
                            task.wait(0.5)
                            pcall(function()
                                local leave = gui.QuestGui.Dialogue.Options:FindFirstChild("Leave")
                                if leave then getconnect(leave) end
                            end)
                        end

                        task.wait(0.5)

                        -- วนกดคนที่ 1 → คนที่ 2 → Next → คนที่ 1 → ... จนกว่าจะรับเควสได้
                        local questAccepted = false
                        pcall(function()
                            local questName = gui.QuestGui.QuestsFrame.QuestName.Text
                            if string.find(questName, "Bounty Hunt") then
                                questAccepted = true
                            end
                        end)

                        while not questAccepted and _G.AutoBountyHunt do
                            -- คนที่ 1 ไม่ได้ → กด Option2 (คนที่ 2)
                            warpToNPC(character, npc)
                            task.wait(0.5)
                            interactNPC(npc)
                            task.wait(0.5)

                            local dialogue2 = gui:FindFirstChild("QuestGui") and gui.QuestGui:FindFirstChild("Dialogue")
                            if dialogue2 and dialogue2.Visible then
                                pcall(function()
                                    local option2 = dialogue2.Options:FindFirstChild("Option2")
                                    if option2 and option2.Visible then
                                        getconnect(option2)
                                        task.wait()
                                        getconnect(option2)
                                        task.wait()
                                        getconnect(option2)
                                    end
                                end)
                                task.wait(0.5)
                                pcall(function()
                                    local leave = gui.QuestGui.Dialogue.Options:FindFirstChild("Leave")
                                    if leave then getconnect(leave) end
                                end)
                            end

                            task.wait(0.5)

                            -- เช็คว่ารับได้ยัง
                            pcall(function()
                                local questName = gui.QuestGui.QuestsFrame.QuestName.Text
                                if string.find(questName, "Bounty Hunt") then
                                    questAccepted = true
                                end
                            end)
                            if questAccepted then break end

                            -- คนที่ 2 ก็ไม่ได้ → กด Next แล้ววนใหม่
                            warpToNPC(character, npc)
                            task.wait(0.5)
                            interactNPC(npc)
                            task.wait(0.5)
                            pcall(function()
                                local nextBtn = gui.QuestGui.Dialogue.Options:FindFirstChild("Next")
                                if nextBtn then getconnect(nextBtn) end
                            end)
                            task.wait(0.5)
                            pcall(function()
                                local leave = gui.QuestGui.Dialogue.Options:FindFirstChild("Leave")
                                if leave then getconnect(leave) end
                            end)
                            task.wait(0.5)

                            -- วนกลับไปกดคนที่ 1
                            warpToNPC(character, npc)
                            task.wait(0.5)
                            interactNPC(npc)
                            task.wait(0.5)

                            local dialogue3 = gui:FindFirstChild("QuestGui") and gui.QuestGui:FindFirstChild("Dialogue")
                            if dialogue3 and dialogue3.Visible then
                                pcall(function()
                                    local option = dialogue3.Options:FindFirstChild("Option")
                                    if option and option.Visible then
                                        getconnect(option)
                                        task.wait()
                                        getconnect(option)
                                        task.wait()
                                        getconnect(option)
                                    end
                                end)
                                task.wait(0.5)
                                pcall(function()
                                    local leave = gui.QuestGui.Dialogue.Options:FindFirstChild("Leave")
                                    if leave then getconnect(leave) end
                                end)
                            end

                            task.wait(0.5)

                            -- เช็คอีกรอบ
                            pcall(function()
                                local questName = gui.QuestGui.QuestsFrame.QuestName.Text
                                if string.find(questName, "Bounty Hunt") then
                                    questAccepted = true
                                end
                            end)
                        end
                    end
                end

                task.wait(1)
            end
        end)
    end
end)
BountyToggle:SetValue(false)

-- =============================================
-- AUTO RAYLEIGH QUEST (Strange Powers #1 → #2 → #3)
-- =============================================
_G.AutoRayleighQuest = false
local RayleighToggle = Tabs.Quest:AddToggle("AutoRayleighQuest", { Title = "Auto Rayleigh Quest", Default = false })
RayleighToggle:OnChanged(function(state)
    _G.AutoRayleighQuest = state
    if state then
        task.spawn(function()
            while _G.AutoRayleighQuest do
                local ok, err = pcall(function()
                    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                    local gui = LocalPlayer.PlayerGui
                    local HRP = character:FindFirstChild("HumanoidRootPart")
                    if not HRP then return end

                    local npc = workspace.Ignore.NPCs.Quest.Rayleigh

                    -- เช็คว่ามีเควสไหม
                    local questName = ""
                    pcall(function() questName = gui.QuestGui.QuestsFrame.QuestName.Text end)

                    local scrollText = ""
                    pcall(function() scrollText = gui.QuestGui.QuestsFrame.QuestsScroll:GetChildren()[5].Text end)

                    -- ==========================================
                    -- ไม่มีเควส → ไปรับเควสจาก Rayleigh
                    -- ==========================================
                    if questName == "" or (questName ~= "Strange Powers #1" and questName ~= "Strange Powers #2" and questName ~= "Strange Powers #3") then
                        warpToNPC(character, npc)
                        task.wait(0.5)
                        interactNPC(npc)
                        task.wait(0.5)
                        clickDialogue(gui)
                        task.wait(1)
                        return
                    end

                    -- ==========================================
                    -- Strange Powers #1: หา Old Book
                    -- ==========================================
                    if questName == "Strange Powers #1" and string.find(scrollText, "Old Book") then
                        if string.find(scrollText, "0/1") then
                            -- เช็คว่ามี Old Book ในตัวไหม
                            local hasBook = false
                            pcall(function()
                                local backpack = LocalPlayer:FindFirstChild("Backpack")
                                if backpack then
                                    for _, item in pairs(backpack:GetChildren()) do
                                        if string.find(item.Name, "Old Book") then hasBook = true break end
                                    end
                                end
                                for _, item in pairs(character:GetChildren()) do
                                    if string.find(item.Name, "Old Book") then hasBook = true break end
                                end
                            end)

                            if hasBook then
                                -- มี Old Book แล้ว → ไปคุย Rayleigh
                                warpToNPC(character, npc)
                                task.wait(0.5)
                                interactNPC(npc)
                                task.wait(0.5)
                                -- กด Option2
                                pcall(function()
                                    local opt2 = gui.QuestGui.Dialogue.Options.Option2
                                    if opt2 and opt2.Visible then getconnect(opt2) end
                                end)
                                task.wait(0.5)
                                pcall(function()
                                    local leave = gui.QuestGui.Dialogue.Options:FindFirstChild("Leave")
                                    if leave then getconnect(leave) end
                                end)
                            else
                                -- ไม่มี Old Book → วาปเก็บกล่อง
                                local chestsFolder = workspace:FindFirstChild("Chests")
                                if chestsFolder then
                                    for _, obj in ipairs(chestsFolder:GetChildren()) do
                                        if not _G.AutoRayleighQuest then break end
                                        if obj.Name == "ChestSpawner" then
                                            local tc = nil
                                            if obj:IsA("Model") then
                                                tc = obj:FindFirstChild("TreasureChest")
                                            end
                                            local p = nil
                                            if tc then
                                                p = tc:IsA("BasePart") and tc or (tc:IsA("Model") and tc.PrimaryPart)
                                            elseif obj:IsA("BasePart") then
                                                p = obj
                                            end
                                            if p then
                                                pcall(function()
                                                    HRP.CFrame = CFrame.new(p.Position + p.CFrame.LookVector, p.Position)
                                                end)
                                                task.wait(0.3)
                                            end
                                        end
                                    end
                                end
                            end
                        else
                            -- Old Book 1/1 → ไปส่งเควส
                            warpToNPC(character, npc)
                            task.wait(0.5)
                            interactNPC(npc)
                            task.wait(0.5)
                            pcall(function()
                                local opt2 = gui.QuestGui.Dialogue.Options.Option2
                                if opt2 and opt2.Visible then getconnect(opt2) end
                            end)
                            task.wait(0.5)
                            pcall(function()
                                local leave = gui.QuestGui.Dialogue.Options:FindFirstChild("Leave")
                                if leave then getconnect(leave) end
                            end)
                        end
                    end

                    -- ==========================================
                    -- Strange Powers #2: Meditate
                    -- ==========================================
                    if questName == "Strange Powers #2" and string.find(scrollText, "Meditate") then
                        if string.find(scrollText, "0/1") then
                            -- กด Meditate
                            pcall(function()
                                local medBtn = gui.Menu.Emotes.Frame.Frame.Meditate
                                if medBtn then getconnect(medBtn) end
                            end)
                            task.wait(2)
                        else
                            -- Meditate 1/1 → ไปส่งเควส
                            warpToNPC(character, npc)
                            task.wait(0.5)
                            interactNPC(npc)
                            task.wait(0.5)
                            clickDialogue(gui)
                            task.wait(0.5)
                        end
                    end

                    -- ==========================================
                    -- Strange Powers #3: Ring 0/8
                    -- ==========================================
                    if questName == "Strange Powers #3" and string.find(scrollText, "Ring") then
                        if string.find(scrollText, "8/8") then
                            -- ครบ 8 แล้ว → ไปส่งเควส
                            warpToNPC(character, npc)
                            task.wait(0.5)
                            interactNPC(npc)
                            task.wait(0.5)
                            clickDialogue(gui)
                            task.wait(0.5)
                        else
                            -- วาปไปหา Rings
                            pcall(function()
                                local ringsFolder = workspace.MapFolder.Rings
                                for i = 1, 8 do
                                    if not _G.AutoRayleighQuest then break end
                                    local ring = ringsFolder:FindFirstChild("Rayleigh Ring " .. i)
                                    if ring then
                                        local part = ring:IsA("BasePart") and ring or ring:FindFirstChildWhichIsA("BasePart", true)
                                        if part then
                                            HRP.CFrame = part.CFrame
                                            task.wait(0.5)
                                        end
                                    end
                                end
                            end)
                        end
                    end
                end)

                if not ok then
                    task.wait(1)
                end
                task.wait(0.5)
            end
        end)
    end
end)
RayleighToggle:SetValue(false)

-- =============================================
-- HAKI FARM TAB (Admin Only)
-- =============================================
if isAdmin then

Tabs.Haki:AddParagraph({ Title = "Target", Content = "" })

-- Dropdown เลือกผู้เล่น (ทุกคนในเซิฟ)
local hakiTarget = nil
local HakiDropdown = Tabs.Haki:AddDropdown("HakiPlayerSelect", {
    Title = "Select Target",
    Values = getPlayerList(),
    Multi = false,
    Default = 1,
})
HakiDropdown:OnChanged(function(val)
    hakiTarget = val
end)
hakiTarget = HakiDropdown.Value

-- ปุ่ม Refresh รายชื่อ
Tabs.Haki:AddButton({
    Title = "Refresh",
    Callback = function()
        HakiDropdown:SetValues(getPlayerList())
        Fluent:Notify({ Title = "Refreshed!", Content = "Player list updated", Duration = 2 })
    end
})

-- =============================================
-- Tp หาเป้า (วาปไปหาคนที่เลือก รอ spawn ก่อน)
-- =============================================
_G.HakiTpTarget = false
local HakiTpToggle = Tabs.Haki:AddToggle("HakiTpTarget", { Title = "Tp to Target", Default = false })
HakiTpToggle:OnChanged(function(state)
    _G.HakiTpTarget = state
    if not state then return end
    task.spawn(function()
        while _G.HakiTpTarget do
            pcall(function()
                if not hakiTarget or hakiTarget == "No Players" then return end

                -- เช็คตัวเราก่อน
                local myChar = LocalPlayer.Character
                local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if not myHRP then return end

                -- หาเป้าใน Alive
                local alive = workspace:FindFirstChild("Alive")
                if not alive then return end
                local targetChar = alive:FindFirstChild(hakiTarget)
                if not targetChar then return end

                -- เช็คว่าเขา spawn แล้วจริง
                local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                if not targetHRP then return end
                local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
                if not targetHum or targetHum.Health <= 0 then return end
                -- ถ้า Y ต่ำกว่า 0 = ยังอยู่จุดเกิด ยังไม่ spawn ลงเกาะ
                if targetHRP.Position.Y < 0 then return end

                -- วาปไปหา
                myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
            end)
            task.wait()
        end
    end)
end)

-- =============================================
-- Rejoin เมื่อฮาคิ < 5%
-- =============================================
_G.HakiRejoin = false
local HakiRejoinToggle = Tabs.Haki:AddToggle("HakiRejoin", { Title = "Rejoin Haki < 5%", Default = false })
HakiRejoinToggle:OnChanged(function(state)
    _G.HakiRejoin = state
    if state then
        task.spawn(function()
            while _G.HakiRejoin do
                if getHakiPercent() < 5 then
                    print("⚡ ฮาคิ < 5% → รีจอย")
                    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                    return
                end
                task.wait(0.5)
            end
        end)
    end
end)

Tabs.Haki:AddParagraph({ Title = "Auto", Content = "" })

-- =============================================
-- Auto Click (Haki tab)
-- =============================================
_G.HakiAutoClick = false
local HakiClickToggle = Tabs.Haki:AddToggle("HakiAutoClick", { Title = "Auto Click", Default = false })
HakiClickToggle:OnChanged(function(state)
    _G.HakiAutoClick = state
    if state then
        task.spawn(function()
            while _G.HakiAutoClick do
                local camera = workspace.CurrentCamera
                if camera then
                    local x, y = camera.ViewportSize.X / 4, camera.ViewportSize.Y / 4
                    pcall(function()
                        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
                        task.wait()
                        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
                    end)
                end
                task.wait(0.2)
            end
        end)
    end
end)

-- Auto R (Observation) — Haki tab
_G.AutoR = false
local HakiToggle = Tabs.Haki:AddToggle("AutoRHakiToggle", { Title = "Auto R (Observation)", Default = false })
HakiToggle:OnChanged(function(state)
    _G.AutoR = state
    if state then
        task.spawn(function()
            while _G.AutoR do
                if not isObservationActive() and getHakiPercent() >= 80 then
                    repeat
                        if not _G.AutoR then break end
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
                        task.wait(0.2)
                    until isObservationActive() or not _G.AutoR
                end
                task.wait(0.5)
            end
        end)
    end
end)
HakiToggle:SetValue(false)

-- Auto Q (Haki) — Haki tab
_G.AutoQ = false
local HakiQToggle = Tabs.Haki:AddToggle("AutoQHakiToggle", { Title = "Auto Q (Haki)", Default = false })
HakiQToggle:OnChanged(function(state)
    _G.AutoQ = state
    if state then
        task.spawn(function()
            while _G.AutoQ do
                if not isHakiActive() and getHakiPercent() >= 80 then
                    repeat
                        if not _G.AutoQ then break end
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                        task.wait(0.2)
                    until isHakiActive() or not _G.AutoQ
                end
                task.wait(0.5)
            end
        end)
    end
end)
HakiQToggle:SetValue(false)

end -- if isAdmin (Haki tab)

-- =============================================
-- SETTINGS TAB
-- =============================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "AutoServerHop" })
InterfaceManager:SetFolder("FinzerHub")
SaveManager:SetFolder("FinzerHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
Fluent:Notify({ Title = "Fluent", Content = "The script has been loaded.", Duration = 8 })
SaveManager:LoadAutoloadConfig()