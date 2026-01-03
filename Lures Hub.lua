
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

-- ==============================================================================
-- ⚡ OTIMIZAÇÃO E CONFIGURAÇÕES
-- ==============================================================================
local function OptimizeGame()
    pcall(function()
        settings().Rendering.QualityLevel = 1
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 0
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("BloomEffect") then
                v.Enabled = false
            end
        end
    end)
end
OptimizeGame()

local SaveFileName = "LuresHub_Original_V2.json"

-- Mantendo a velocidade alta do Ultimate (350)
local SETTINGS = {
    ChestNames = {"Chest1", "Chest2", "Chest3", "Chest4", "Chest5", "Chest6", "Chest"},
    Speed = 350, 
    AutoFarm = true,
    StopOnRare = true,
    CollectionRange = 15 -- Pega o baú antes de encostar (Pre-fire)
}

-- Estado interno para controlar movimento e morte
local STATE = {
    IsMoving = false,
    CurrentTarget = nil,
    MoveConnection = nil
}

-- ==============================================================================
-- 🧠 CACHE DE BAÚS (ZERO LAG)
-- ==============================================================================
local ChestCache = {} 

local function AddToCache(instance)
    if table.find(SETTINGS.ChestNames, instance.Name) then
        ChestCache[instance] = instance
    end
end

local function RemoveFromCache(instance)
    if ChestCache[instance] then
        ChestCache[instance] = nil
        if STATE.CurrentTarget == instance then
            STATE.CurrentTarget = nil
            STATE.IsMoving = false
            if STATE.MoveConnection then STATE.MoveConnection:Disconnect() end
        end
    end
end

-- Scan inicial e Listeners
for _, v in pairs(workspace:GetDescendants()) do AddToCache(v) end
workspace.DescendantAdded:Connect(AddToCache)
workspace.DescendantRemoving:Connect(RemoveFromCache)

-- ==============================================================================
-- 💾 SISTEMA DE SAVE
-- ==============================================================================
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
-- 🖥️ INTERFACE (VISUAL ORIGINAL RESTAURADO)
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

-- BOTÕES ORIGINAIS
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
-- 🔍 VERIFICAÇÃO DE ITENS E ANTI-AFK
-- ==============================================================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

local RareItems = {"Fist of Darkness", "God's Chalice"}
local function CheckRareItems()
    if not SETTINGS.StopOnRare then return false end
    local found = false
    for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do if table.find(RareItems, item.Name) then found = true; break end end  
    if not found and LocalPlayer.Character then for _, item in ipairs(LocalPlayer.Character:GetChildren()) do if table.find(RareItems, item.Name) then found = true; break end end end  
    return found
end

-- ==============================================================================
-- 🚀 SISTEMA DE MOVIMENTAÇÃO (BYPASS + RESET AO MORRER)
-- ==============================================================================
local function Collect(chest)
    if not chest or not chest.Parent then return end
    local function fire(target)
        if target:IsA("BasePart") then
            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, target, 0)
            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, target, 1)
        end
    end
    if chest:IsA("Model") then for _, v in pairs(chest:GetChildren()) do fire(v) end else fire(chest) end
    VirtualInputManager:SendMouseButtonEvent(443, 275, 0, true, game, 1)
    VirtualInputManager:SendMouseButtonEvent(443, 275, 0, false, game, 1)
end

local function MoveToTarget(target)
    if STATE.IsMoving then return end
    STATE.IsMoving = true
    STATE.CurrentTarget = target

    -- Limpa conexão antiga se existir
    if STATE.MoveConnection then STATE.MoveConnection:Disconnect() end

    -- Loop Super Rápido (Heartbeat)
    STATE.MoveConnection = RunService.Heartbeat:Connect(function(dt)
        if not SETTINGS.AutoFarm or CheckRareItems() then
            STATE.IsMoving = false
            STATE.MoveConnection:Disconnect()
            return
        end

        local Char = LocalPlayer.Character
        local Root = Char and Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char and Char:FindFirstChild("Humanoid")

        -- Correção do Bug da Morte: Se morreu, para tudo.
        if not Root or not Hum or Hum.Health <= 0 then
            STATE.IsMoving = false
            STATE.MoveConnection:Disconnect()
            return
        end

        if not target.Parent then
            STATE.IsMoving = false
            STATE.MoveConnection:Disconnect()
            return
        end

        local DestPos = (target:IsA("Model") and target:GetModelCFrame().Position) or target.Position
        local Dist = (DestPos - Root.Position).Magnitude

        -- Coleta Preditiva (Pega antes de encostar)
        if Dist <= SETTINGS.CollectionRange then
            Collect(target)
            STATE.IsMoving = false
            STATE.MoveConnection:Disconnect()
            ChestCache[target] = nil -- Tira do cache pra não voltar
            return
        end

        -- Movimento Linear
        local Dir = (DestPos - Root.Position).Unit
        local Velocity = Dir * SETTINGS.Speed * dt
        
        if Velocity.Magnitude >= Dist then
            Root.CFrame = CFrame.new(DestPos)
        else
            Root.CFrame = Root.CFrame + Velocity
        end
        Root.Velocity = Vector3.new(0,0,0) -- Evita cair
        
        -- Noclip
        for _, v in pairs(Char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end)
end

-- ==============================================================================
-- 💀 DETECÇÃO DE RENASCIMENTO (CRUCIAL PARA O FIX)
-- ==============================================================================
LocalPlayer.CharacterAdded:Connect(function(NewChar)
    -- Reseta o estado quando o personagem nasce
    SetStatus("Renascendo...")
    if STATE.MoveConnection then STATE.MoveConnection:Disconnect() end
    STATE.IsMoving = false
    STATE.CurrentTarget = nil
    
    task.wait(1) -- Pequeno delay para carregar o boneco
    -- Reativa o loop
end)

-- ==============================================================================
-- 🌐 SERVER HOP & PIRATES
-- ==============================================================================
local function JoinPirates()
    if LocalPlayer.Team and LocalPlayer.Team.Name == "Pirates" then return end
    task.spawn(function()
        local Start = tick()
        repeat
            if tick() - Start > 10 then break end
            pcall(function()
                local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
                local Remote = Net:WaitForChild("RE/OnEventServiceActivity")
                Remote:FireServer("TeamSelect/Team/Pirates")
            end)
            task.wait(1)
        until LocalPlayer.Team and LocalPlayer.Team.Name == "Pirates"
    end)
end

local function ServerHop()
    SetStatus("Trocando de Server...")
    local PlaceId = game.PlaceId
    local function ExecHop()
        local req = game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local data = HttpService:JSONDecode(req)
        local servers = {}
        for _, s in pairs(data.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then table.insert(servers, s.id) end
        end
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], LocalPlayer)
        else
            task.wait(1); ExecHop()
        end
    end
    pcall(ExecHop)
end

-- ==============================================================================
-- 🔄 LOOP PRINCIPAL
-- ==============================================================================
local function GetNearestChest()
    local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not Root then return nil end
    
    local Nearest = nil
    local MinDist = math.huge
    
    for chest, _ in pairs(ChestCache) do
        if chest and chest.Parent then
            local Pos = (chest:IsA("Model") and chest:GetModelCFrame().Position) or chest.Position
            local Dist = (Pos - Root.Position).Magnitude
            if Dist < MinDist then
                MinDist = Dist
                Nearest = chest
            end
        else
            ChestCache[chest] = nil
        end
    end
    return Nearest
end

task.spawn(function()
    while true do
        task.wait() -- Loop roda no máximo FPS
        
        if CheckRareItems() then
            SETTINGS.AutoFarm = false
            ToggleFarmBtn.Text = "STOP: ITEM RARO ENCONTRADO!"
            ToggleFarmBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
            SaveConfig()
            SetStatus("⚠️ ITENS NA MOCHILA! PARADO ⚠️")
            continue
        end

        if SETTINGS.AutoFarm then
            local Char = LocalPlayer.Character
            if not Char or not Char:FindFirstChild("HumanoidRootPart") or (Char:FindFirstChild("Humanoid") and Char.Humanoid.Health <= 0) then
                SetStatus("Esperando Personagem...")
                JoinPirates()
                task.wait(1)
                continue
            end
            
            if not STATE.IsMoving then
                local Chest = GetNearestChest()
                if Chest then
                    SetStatus("Indo até: " .. Chest.Name)
                    MoveToTarget(Chest)
                else
                    SetStatus("Sem baús. Trocando server...")
                    task.wait(1.5)
                    ServerHop()
                    task.wait(10)
                end
            end
        else
            SetStatus("Script Pausado")
            if STATE.MoveConnection then STATE.MoveConnection:Disconnect() end
            STATE.IsMoving = false
            task.wait(0.5)
        end
    end
end)

-- Click Spam (443, 275)
task.spawn(function()
    while true do
        if SETTINGS.AutoFarm then
            VirtualInputManager:SendMouseButtonEvent(443, 275, 0, true, game, 1)
            task.wait()
            VirtualInputManager:SendMouseButtonEvent(443, 275, 0, false, game, 1)
        end
        task.wait(0.05)
    end
end)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Lures Hub V2",
    Text = "Visual Original + Correção de Morte!",
    Duration = 5,
})

JoinPirates()
