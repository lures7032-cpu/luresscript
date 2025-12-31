local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==============================================================================
-- ⚡ OTIMIZAÇÃO (ANTI-LAG)
-- ==============================================================================
local function OptimizeGame()
    pcall(function()
        settings().Rendering.QualityLevel = 1
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 0
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then
                v.Enabled = false
            end
        end
    end)
end
OptimizeGame()

-- ==============================================================================
-- 💾 SISTEMA DE SAVE
-- ==============================================================================
local SaveFileName = "LuresHub_Release_Config.json"

local SETTINGS = {
    ChestNames = {"Chest1", "Chest2", "Chest3", "Chest4", "Chest5", "Chest6", "Chest"},
    Speed = 300,
    VisitedChests = {},
    AutoFarm = true,       
    StopOnRare = true      
}

local function SaveConfig()
    local data = { AutoFarm = SETTINGS.AutoFarm, StopOnRare = SETTINGS.StopOnRare }
    writefile(SaveFileName, HttpService:JSONEncode(data))
end

local function LoadConfig()
    if isfile(SaveFileName) then
        local success, result = pcall(function() return HttpService:JSONDecode(readfile(SaveFileName)) end)
        if success and result then
            if result.AutoFarm ~= nil then SETTINGS.AutoFarm = result.AutoFarm end
            if result.StopOnRare ~= nil then SETTINGS.StopOnRare = result.StopOnRare end
        end
    end
end
LoadConfig()

-- ==============================================================================
-- 🛡️ ANTI-AFK
-- ==============================================================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ==============================================================================
-- 🔍 VERIFICAÇÃO DE ITENS
-- ==============================================================================
local RareItems = {"Fist of Darkness", "God's Chalice"}

local function CheckRareItems()
    if not SETTINGS.StopOnRare then return false end 
    local found = false
    
    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if table.find(RareItems, item.Name) then found = true; break end
    end
    if not found and LocalPlayer.Character then
        for _, item in ipairs(LocalPlayer.Character:GetChildren()) do
            if table.find(RareItems, item.Name) then found = true; break end
        end
    end
    return found
end

-- ==============================================================================
-- 🖥️ INTERFACE
-- ==============================================================================
local Viewport = (gethui and gethui()) or (getgenv().protect_gui and protect_gui()) or CoreGui
if Viewport:FindFirstChild("LuresHubAuto") then Viewport.LuresHubAuto:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LuresHubAuto"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Viewport

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 165)
MainFrame.Position = UDim2.new(0.5, -150, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true 

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 230, 255)
Stroke.Thickness = 2
Stroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Text = "LURES HUB - BAÚS" 
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(0, 230, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 15
Title.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Text = "Aguardando..."
StatusLabel.Size = UDim2.new(1, 0, 0, 25)
StatusLabel.Position = UDim2.new(0, 0, 0, 25)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 13
StatusLabel.Parent = MainFrame

local function SetStatus(text)
    StatusLabel.Text = text
end

-- BOTÕES
local ToggleFarmBtn = Instance.new("TextButton")
ToggleFarmBtn.Parent = MainFrame
ToggleFarmBtn.Size = UDim2.new(0.9, 0, 0, 32)
ToggleFarmBtn.Position = UDim2.new(0.05, 0, 0.38, 0)
ToggleFarmBtn.BackgroundColor3 = SETTINGS.AutoFarm and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 50, 50)
ToggleFarmBtn.Text = SETTINGS.AutoFarm and "FARM: LIGADO" or "FARM: DESLIGADO"
ToggleFarmBtn.Font = Enum.Font.GothamBold
ToggleFarmBtn.TextColor3 = Color3.new(1,1,1)
ToggleFarmBtn.TextSize = 14
Instance.new("UICorner", ToggleFarmBtn).CornerRadius = UDim.new(0, 6)

ToggleFarmBtn.MouseButton1Click:Connect(function()
    SETTINGS.AutoFarm = not SETTINGS.AutoFarm
    ToggleFarmBtn.Text = SETTINGS.AutoFarm and "FARM: LIGADO" or "FARM: DESLIGADO"
    ToggleFarmBtn.BackgroundColor3 = SETTINGS.AutoFarm and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 50, 50)
    SaveConfig()
end)

local ToggleRareBtn = Instance.new("TextButton")
ToggleRareBtn.Parent = MainFrame
ToggleRareBtn.Size = UDim2.new(0.9, 0, 0, 32)
ToggleRareBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
ToggleRareBtn.BackgroundColor3 = SETTINGS.StopOnRare and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(80, 80, 80)
ToggleRareBtn.Text = SETTINGS.StopOnRare and "PARAR AO PEGAR ITEM AMALDIÇOADO: ON" or "PARAR AO PEGAR ITEM AMALDIÇOADO: OFF"
ToggleRareBtn.Font = Enum.Font.GothamBold
ToggleRareBtn.TextColor3 = Color3.new(1,1,1)
ToggleRareBtn.TextSize = 11 
Instance.new("UICorner", ToggleRareBtn).CornerRadius = UDim.new(0, 6)

local DescLabel = Instance.new("TextLabel")
DescLabel.Parent = MainFrame
DescLabel.Size = UDim2.new(1, 0, 0, 20)
DescLabel.Position = UDim2.new(0, 0, 0.88, 0)
DescLabel.BackgroundTransparency = 1
DescLabel.Text = "God's Chalice e Fist of Darkness" 
DescLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
DescLabel.Font = Enum.Font.SourceSansItalic
DescLabel.TextSize = 13

ToggleRareBtn.MouseButton1Click:Connect(function()
    SETTINGS.StopOnRare = not SETTINGS.StopOnRare
    ToggleRareBtn.Text = SETTINGS.StopOnRare and "PARAR AO PEGAR ITEM AMALDIÇOADO: ON" or "PARAR AO PEGAR ITEM AMALDIÇOADO: OFF"
    ToggleRareBtn.BackgroundColor3 = SETTINGS.StopOnRare and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(80, 80, 80)
    SaveConfig()
end)

-- ==============================================================================
-- 🌐 SERVER HOP (LÓGICA DO SCRIPT REFERÊNCIA)
-- ==============================================================================
local function ServerHop()
    SetStatus("Trocando de Server...")
    local PlaceId = game.PlaceId
    
    -- Lógica exata do script que você enviou
    local servers = {}
    local success, req = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
    end)

    if success then
        local data = HttpService:JSONDecode(req)
        for _, server in pairs(data.data) do
            if type(server) == "table" and server.playing and server.maxPlayers then
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
        end

        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], LocalPlayer)
        else
            SetStatus("Nenhum server disponível. Tentando dnv...")
            task.wait(1.5)
            ServerHop()
        end
    else
        SetStatus("Erro na API. Tentando dnv...")
        task.wait(1.5)
        ServerHop()
    end
end

-- ==============================================================================
-- 🖱️ CLIQUE COORDENADO (443x275) - 11 SEGUNDOS
-- ==============================================================================
local function SpamClickScreen()
    task.spawn(function()
        local StartTime = tick()
        while tick() - StartTime < 11 do
            if not SETTINGS.AutoFarm then break end 
            
            -- Clica exatamente nas coordenadas solicitadas
            VirtualInputManager:SendMouseButtonEvent(443, 275, 0, true, game, 1)
            task.wait()
            VirtualInputManager:SendMouseButtonEvent(443, 275, 0, false, game, 1)
            task.wait(0.05) 
        end
    end)
end

-- ==============================================================================
-- 🏴‍☠️ JOIN TEAM
-- ==============================================================================
local function JoinPirates()
    if LocalPlayer.Team and LocalPlayer.Team.Name == "Pirates" then return end
    task.spawn(function()
        local Start = tick()
        repeat
            if tick() - Start > 20 then break end
            pcall(function()
                local Net = ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Net", 5)
                local Remote = Net:WaitForChild("RE/OnEventServiceActivity", 5)
                Remote:FireServer("TeamSelect/Team/Pirates")
            end)
            task.wait(1)
        until LocalPlayer.Team and LocalPlayer.Team.Name == "Pirates"
    end)
end

-- ==============================================================================
-- 🚀 LOOP PRINCIPAL
-- ==============================================================================
local function GetNextChest()
    local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return nil end
    local Nearest = nil
    local MinDist = math.huge
    
    local items = workspace:GetDescendants()
    for i, obj in ipairs(items) do
        if i % 300 == 0 then task.wait() end 
        if table.find(SETTINGS.ChestNames, obj.Name) and (obj:IsA("Model") or obj:IsA("BasePart")) then
            if not SETTINGS.VisitedChests[obj] then
                local Pos = (obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position) or (obj:IsA("BasePart") and obj.Position)
                if Pos then
                    local Dist = (Pos - MyRoot.Position).Magnitude
                    if Dist < MinDist then
                        MinDist = Dist
                        Nearest = obj
                    end
                end
            end
        end
    end
    return Nearest
end

local function Collect(Chest)
    SetStatus("Pegando: " .. Chest.Name)
    local function TouchParts(target)
        if target:IsA("BasePart") then
            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, target, 0)
            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, target, 1)
        end
    end
    if Chest:IsA("Model") then
        for _, v in pairs(Chest:GetChildren()) do TouchParts(v) end
    else
        TouchParts(Chest)
    end
    
    -- Clica na posição 443, 275 também ao coletar para garantir
    VirtualInputManager:SendMouseButtonEvent(443, 275, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(443, 275, 0, false, game, 1)
end

task.spawn(function()
    while true do
        if CheckRareItems() then
            SETTINGS.AutoFarm = false 
            ToggleFarmBtn.Text = "STOP: ITEM RARO ENCONTRADO!"
            ToggleFarmBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0) 
            SaveConfig() 
            SetStatus("⚠️ ITENS NA MOCHILA! PARADO ⚠️")
            while not SETTINGS.AutoFarm do task.wait(1) end
        end

        if SETTINGS.AutoFarm then
            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                SetStatus("Carregando Personagem...")
                JoinPirates()
                task.wait(2)
                continue
            end

            if LocalPlayer.Character then
                for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end

            local Chest = GetNextChest()

            if Chest then
                SetStatus("Indo até: " .. Chest.Name)
                local DestCFrame = (Chest:IsA("Model") and Chest:GetModelCFrame()) or Chest.CFrame
                local MyRoot = LocalPlayer.Character.HumanoidRootPart
                local Dist = (DestCFrame.Position - MyRoot.Position).Magnitude
                
                if Dist > 5 then
                    local Time = Dist / SETTINGS.Speed
                    local Tween = TweenService:Create(MyRoot, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = DestCFrame})
                    Tween:Play()
                    
                    local Elapsed = 0
                    while Elapsed < Time do
                        if not SETTINGS.AutoFarm then Tween:Cancel(); break end
                        if not Chest.Parent then Tween:Cancel(); break end
                        if CheckRareItems() then Tween:Cancel(); break end 
                        if (DestCFrame.Position - MyRoot.Position).Magnitude < 4 then Tween:Cancel(); break end
                        
                        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                            if v:IsA("BasePart") then v.CanCollide = false end
                        end
                        Elapsed = Elapsed + 0.1
                        task.wait(0.1)
                    end
                else
                    MyRoot.CFrame = DestCFrame
                end

                if Chest and Chest.Parent and SETTINGS.AutoFarm and not CheckRareItems() then
                    Collect(Chest)
                    SETTINGS.VisitedChests[Chest] = true
                    task.wait(0.3)
                end
            else
                SetStatus("Trocando Server...")
                task.wait(1)
                if SETTINGS.AutoFarm and not CheckRareItems() then
                    ServerHop()
                end
                task.wait(5)
            end
        else
            SetStatus("Script Pausado")
            task.wait(1)
        end
        task.wait(0.1)
    end
end)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Lures Hub V1",
    Text = "Script carregado com sucesso!",
    Duration = 5,
})

if SETTINGS.AutoFarm then
    SpamClickScreen()
end
JoinPirates()
