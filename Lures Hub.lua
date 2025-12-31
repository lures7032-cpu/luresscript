local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==============================================================================
-- CONFIGURAÇÕES (AUTOMÁTICAS)
-- ==============================================================================
local SETTINGS = {
    ChestNames = {"Chest1", "Chest2", "Chest3", "Chest4", "Chest5", "Chest6", "Chest"},
    -- InstantTeleport REMOVIDO. Agora é apenas Voo (Tween).
    Speed = 300, -- Velocidade do voo (aumente se quiser mais rápido)
    VisitedChests = {}
}

-- ==============================================================================
-- UI SIMPLIFICADA (STATUS)
-- ==============================================================================
local Viewport = (gethui and gethui()) or (getgenv().protect_gui and protect_gui()) or CoreGui
if Viewport:FindFirstChild("LuresHubAuto") then Viewport.LuresHubAuto:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LuresHubAuto"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Viewport

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 60)
MainFrame.Position = UDim2.new(0.5, -150, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0, 230, 255)
Stroke.Thickness = 2
Stroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Text = "LURES HUB - AUTO FARM (VOO)"
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(0, 230, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 14
Title.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Text = "Iniciando..."
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Position = UDim2.new(0, 0, 0, 25)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 12
StatusLabel.Parent = MainFrame

local function SetStatus(text)
    StatusLabel.Text = text
end

-- ==============================================================================
-- FUNÇÕES DE SUPORTE
-- ==============================================================================

local function SpamClickScreen()
    task.spawn(function()
        local StartTime = tick()
        while tick() - StartTime < 6 do
            local ViewportSize = Camera.ViewportSize
            local RandX = math.random(0, ViewportSize.X)
            local RandY = math.random(0, ViewportSize.Y)
            VirtualInputManager:SendMouseButtonEvent(RandX, RandY, 0, true, game, 1)
            task.wait()
            VirtualInputManager:SendMouseButtonEvent(RandX, RandY, 0, false, game, 1)
            task.wait(0.01)
        end
    end)
end

local function JoinPirates()
    if LocalPlayer.Team and LocalPlayer.Team.Name == "Pirates" then return end
    task.spawn(function()
        local Start = tick()
        repeat
            if tick() - Start > 20 then break end
            pcall(function()
                local Net = ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Net", 5)
                local Remote = Net:WaitForChild("RE/OnEventServiceActivity", 5)
                local args = { "TeamSelect/Team/Pirates" }
                Remote:FireServer(unpack(args))
            end)
            task.wait(0.8)
        until LocalPlayer.Team and LocalPlayer.Team.Name == "Pirates"
    end)
end

local function ServerHop()
    SetStatus("Trocando de Server...")
    local PlaceId = game.PlaceId
    local Success, Result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Desc&limit=100"))
    end)
    local Found = false
    if Success and Result and Result.data then
        local Servers = Result.data
        for i = #Servers, 2, -1 do
            local j = math.random(i)
            Servers[i], Servers[j] = Servers[j], Servers[i]
        end
        for _, s in ipairs(Servers) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                SetStatus("Entrando: " .. s.playing .. "/" .. s.maxPlayers)
                TeleportService:TeleportToPlaceInstance(PlaceId, s.id, LocalPlayer)
                Found = true
                break
            end
        end
    end
    if not Found then
        SetStatus("Nenhum server. Tentando novamente...")
        task.wait(1.5)
        ServerHop()
    end
end

-- ==============================================================================
-- LÓGICA DE FARM (SOMENTE VOO/TWEEN)
-- ==============================================================================

local function GetNextChest()
    local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return nil end
    local Nearest = nil
    local MinDist = math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
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
    SetStatus("Coletando: " .. Chest.Name)
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
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

local function MainLoop()
    task.spawn(function()
        while true do
            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                SetStatus("Aguardando Personagem...")
                JoinPirates()
                task.wait(1)
                continue
            end

            -- Noclip (Atravessa Paredes)
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
            
            local Chest = GetNextChest()
            
            if Chest then
                SetStatus("Voando para: " .. Chest.Name)
                
                local DestCFrame = nil
                if Chest:IsA("Model") then 
                    if Chest.PrimaryPart then DestCFrame = Chest.GetModelCFrame(Chest) else DestCFrame = CFrame.new(Chest:GetPivot().Position) end
                else 
                    DestCFrame = Chest.CFrame 
                end
                
                local MyRoot = LocalPlayer.Character.HumanoidRootPart
                local Dist = (DestCFrame.Position - MyRoot.Position).Magnitude
                
                -- LÓGICA DE VOO (TWEEN) APENAS
                if Dist > 5 then
                    local Time = Dist / SETTINGS.Speed
                    local Tween = TweenService:Create(MyRoot, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = DestCFrame})
                    Tween:Play()
                    
                    local Elapsed = 0
                    while Elapsed < Time do
                        -- Se o baú sumir ou chegar perto, para
                        if not Chest.Parent then Tween:Cancel(); break end
                        if (DestCFrame.Position - MyRoot.Position).Magnitude < 4 then Tween:Cancel(); break end
                        
                        -- Mantém noclip durante o voo
                        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                            if v:IsA("BasePart") then v.CanCollide = false end
                        end
                        
                        Elapsed = Elapsed + 0.1
                        task.wait(0.1)
                    end
                else
                    MyRoot.CFrame = DestCFrame -- Ajuste final
                end

                if Chest and Chest.Parent then
                    Collect(Chest)
                    SETTINGS.VisitedChests[Chest] = true
                    task.wait(0.5)
                end
            else
                SetStatus("Baús acabaram. Trocando Server...")
                task.wait(1)
                ServerHop()
                task.wait(5)
            end
            task.wait(0.1)
        end
    end)
end

-- ==============================================================================
-- EXECUÇÃO
-- ==============================================================================
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Lures Auto Farm",
    Text = "Modo Voo Ativado...",
    Duration = 3,
})

SpamClickScreen()
JoinPirates()
MainLoop()
