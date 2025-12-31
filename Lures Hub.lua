--[[ 
    💙 LURES HUB V6 - CYBERPUNK EDITION 💙
    Autor: Gemini AI
    Tema: Neon Blue & Dark Gradient
]]

--// SERVIÇOS
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

--// CONFIGURAÇÕES GLOBAIS
getgenv().Settings = {
    FarmChests = false,
    InstantTeleport = false, -- false = Voo (Tween), true = TP Instantâneo
    ChestNames = {"Chest1", "Chest2", "Chest3", "Chest4", "Chest5", "Chest6", "Chest"},
    VisitedChests = {} 
}

local IMAGE_ID = "rbxassetid://119959180684937"

--// PROTEÇÃO DE GUI
local Viewport = (gethui and gethui()) or (getgenv().protect_gui and protect_gui()) or CoreGui
if Viewport:FindFirstChild("LuresHubV6") then Viewport.LuresHubV6:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LuresHubV6"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Viewport

--// 🎨 TEMA & ESTILOS
local THEME = {
    Bg = Color3.fromRGB(12, 12, 18),
    Gradient1 = Color3.fromRGB(10, 15, 25),
    Gradient2 = Color3.fromRGB(20, 30, 50),
    Accent = Color3.fromRGB(0, 230, 255), -- Azul Cyan Neon
    Text = Color3.fromRGB(255, 255, 255),
    Status = Color3.fromRGB(255, 180, 50) -- Laranja Amarelado
}

--// 🔧 FUNÇÃO DRAGGABLE (ARRASTAR)
local function MakeDraggable(Frame)
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    Frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then update(input) end
        end
    end)
end

--// 🖥️ INTERFACE PRINCIPAL
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 450, 0, 280)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -140)
MainFrame.BackgroundColor3 = THEME.Bg
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Arredondamento e Gradiente
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, THEME.Gradient1), 
    ColorSequenceKeypoint.new(1, THEME.Gradient2)
}
MainGradient.Rotation = 45
MainGradient.Parent = MainFrame

-- Borda Brilhante (Glow)
local Glow = Instance.new("UIStroke")
Glow.Color = THEME.Accent
Glow.Thickness = 1.5
Glow.Transparency = 0.3
Glow.Parent = MainFrame

MakeDraggable(MainFrame)

-- TOPO (HEADER)
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Text = "LURES <font color=\"rgb(0,230,255)\">HUB</font>"
Title.RichText = true
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = THEME.Text
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 24
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Botão Minimizar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "-"
CloseBtn.TextColor3 = THEME.Accent
CloseBtn.BackgroundTransparency = 1
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 30
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -45, 0, 5)
CloseBtn.Parent = Header

-- Ícone Flutuante (Botão Abrir)
local OpenBtn = Instance.new("ImageButton")
OpenBtn.Name = "OpenButton"
OpenBtn.Image = IMAGE_ID
OpenBtn.BackgroundColor3 = THEME.Bg
OpenBtn.Size = UDim2.new(0, 60, 0, 60)
OpenBtn.Position = UDim2.new(0.1, 0, 0.1, 0) -- Começa no canto
OpenBtn.Visible = false
OpenBtn.Parent = ScreenGui
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 16)
local OpenStroke = Instance.new("UIStroke"); OpenStroke.Color = THEME.Accent; OpenStroke.Thickness = 2; OpenStroke.Parent = OpenBtn
MakeDraggable(OpenBtn)

-- Lógica Minimizar/Maximizar
CloseBtn.MouseButton1Click:Connect(function() 
    MainFrame.Visible = false 
    OpenBtn.Visible = true 
end)
OpenBtn.MouseButton1Click:Connect(function() 
    OpenBtn.Visible = false 
    MainFrame.Visible = true 
end)

-- LINHA DIVISÓRIA
local Line = Instance.new("Frame")
Line.Size = UDim2.new(1, 0, 0, 1)
Line.Position = UDim2.new(0, 0, 0, 50)
Line.BackgroundColor3 = THEME.Accent
Line.BorderSizePixel = 0
Line.Transparency = 0.5
Line.Parent = MainFrame

-- ÁREA DE STATUS (Real-time)
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(1, -30, 0, 35)
StatusFrame.Position = UDim2.new(0, 15, 0, 65)
StatusFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
StatusFrame.BackgroundTransparency = 0.5
StatusFrame.Parent = MainFrame
Instance.new("UICorner", StatusFrame).CornerRadius = UDim.new(0, 6)
local StatusStroke = Instance.new("UIStroke"); StatusStroke.Color = THEME.Accent; StatusStroke.Transparency = 0.7; StatusStroke.Parent = StatusFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Text = "Status: Aguardando Início..."
StatusLabel.Size = UDim2.new(1, 0, 1, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = THEME.Status
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 14
StatusLabel.Parent = StatusFrame

local function SetStatus(text)
    StatusLabel.Text = "Status: " .. text
end

-- CONTAINER DE BOTÕES
local Container = Instance.new("ScrollingFrame")
Container.Size = UDim2.new(1, -30, 1, -120)
Container.Position = UDim2.new(0, 15, 0, 110)
Container.BackgroundTransparency = 1
Container.BorderSizePixel = 0
Container.ScrollBarThickness = 2
Container.Parent = MainFrame
local UIList = Instance.new("UIListLayout", Container)
UIList.Padding = UDim.new(0, 10)
UIList.SortOrder = Enum.SortOrder.LayoutOrder

--// FUNÇÃO CRIAR TOGGLE
local function CreateToggle(Text, Default, Callback)
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(1, 0, 0, 45)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    ToggleBtn.Text = ""
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.Parent = Container
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)
    
    local TTitle = Instance.new("TextLabel")
    TTitle.Text = Text
    TTitle.Size = UDim2.new(1, -60, 1, 0)
    TTitle.Position = UDim2.new(0, 15, 0, 0)
    TTitle.BackgroundTransparency = 1
    TTitle.TextColor3 = THEME.Text
    TTitle.Font = Enum.Font.GothamSemibold
    TTitle.TextSize = 14
    TTitle.TextXAlignment = Enum.TextXAlignment.Left
    TTitle.Parent = ToggleBtn
    
    local Switch = Instance.new("Frame")
    Switch.Size = UDim2.new(0, 40, 0, 20)
    Switch.Position = UDim2.new(1, -50, 0.5, -10)
    Switch.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    Switch.Parent = ToggleBtn
    Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)
    
    local Dot = Instance.new("Frame")
    Dot.Size = UDim2.new(0, 16, 0, 16)
    Dot.Position = UDim2.new(0, 2, 0.5, -8)
    Dot.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    Dot.Parent = Switch
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
    
    local Enabled = Default
    
    local function UpdateVisual()
        if Enabled then
            TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = THEME.Accent}):Play()
            TweenService:Create(Dot, TweenInfo.new(0.2), {Position = UDim2.new(1, -18, 0.5, -8)}):Play()
        else
            TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}):Play()
            TweenService:Create(Dot, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -8)}):Play()
        end
    end
    
    ToggleBtn.MouseButton1Click:Connect(function()
        Enabled = not Enabled
        UpdateVisual()
        Callback(Enabled)
    end)
    UpdateVisual() -- Init state
end

--// 🧠 LÓGICA DE FARM

local function ServerHop()
    -- Contagem Regressiva Visual
    for i = 3, 1, -1 do
        SetStatus("Trocando de Server em " .. i .. "...")
        task.wait(1)
    end
    SetStatus("Iniciando Teleporte de Servidor...")
    
    local PlaceId = game.PlaceId
    local Success, Result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    end)
    
    if Success and Result and Result.data then
        for _, s in ipairs(Result.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(PlaceId, s.id, LocalPlayer)
                return
            end
        end
    end
    SetStatus("Falha ao achar server, tentando novamente...")
end

local function GetNextChest()
    local MyRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return nil end

    local Nearest = nil
    local MinDist = math.huge

    for _, obj in pairs(workspace:GetDescendants()) do
        if table.find(getgenv().Settings.ChestNames, obj.Name) and (obj:IsA("Model") or obj:IsA("BasePart")) then
            -- Verifica se já fomos lá
            if not getgenv().Settings.VisitedChests[obj] then
                -- Pega posição
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
    SetStatus("Interagindo com " .. Chest.Name .. "...")
    
    -- Método Touch
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
    
    -- Método Click (Interação Virtual)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

local function StartFarmLogic()
    task.spawn(function()
        while getgenv().Settings.FarmChests do
            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                task.wait(1)
                continue
            end
            
            local Chest = GetNextChest()
            
            if Chest then
                SetStatus("Alvo encontrado: " .. Chest.Name)
                
                local DestCFrame = nil
                if Chest:IsA("Model") then 
                    if Chest.PrimaryPart then DestCFrame = Chest.GetModelCFrame(Chest) else DestCFrame = CFrame.new(Chest:GetPivot().Position) end
                else 
                    DestCFrame = Chest.CFrame 
                end
                
                local MyRoot = LocalPlayer.Character.HumanoidRootPart
                
                -- DECISÃO DE MOVIMENTO
                if getgenv().Settings.InstantTeleport then
                    -- TP Instantâneo
                    MyRoot.CFrame = DestCFrame
                    task.wait(0.1)
                else
                    -- Voo (Tween)
                    local Dist = (DestCFrame.Position - MyRoot.Position).Magnitude
                    if Dist > 10 then -- Só voa se estiver longe
                        SetStatus("Voando para " .. Chest.Name .. "...")
                        local Speed = 300 
                        local Time = Dist / Speed
                        
                        local Tween = TweenService:Create(MyRoot, TweenInfo.new(Time, Enum.EasingStyle.Linear), {CFrame = DestCFrame})
                        Tween:Play()
                        
                        -- Loop de espera do voo
                        local Elapsed = 0
                        while Elapsed < Time do
                            if not getgenv().Settings.FarmChests then Tween:Cancel(); break end
                            -- Se chegar muito perto, para o tween
                            if (DestCFrame.Position - MyRoot.Position).Magnitude < 5 then Tween:Cancel(); break end
                            
                            Elapsed = Elapsed + 0.1
                            task.wait(0.1)
                        end
                    end
                end

                -- Coleta
                if getgenv().Settings.FarmChests then
                    Collect(Chest)
                    getgenv().Settings.VisitedChests[Chest] = true
                    task.wait(0.8) -- Delay natural
                end
                
            else
                -- Nenhum baú encontrado -> Server Hop
                SetStatus("Mapa limpo! Preparando Server Hop...")
                ServerHop()
                task.wait(5) -- Evita spam se falhar
            end
            task.wait(0.1)
        end
        SetStatus("Script Parado.")
    end)
end

--// NOCLIP (Evita bater em paredes)
RunService.Stepped:Connect(function()
    if getgenv().Settings.FarmChests and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide == true then
                v.CanCollide = false
            end
        end
    end
end)

--// BINDING DOS BOTÕES
CreateToggle("ATIVAR AUTO FARM", false, function(Val)
    getgenv().Settings.FarmChests = Val
    if Val then
        getgenv().Settings.VisitedChests = {} -- Limpa a memória ao reiniciar
        StartFarmLogic()
    else
        SetStatus("Parando script...")
    end
end)

CreateToggle("MODO TP INSTANTÂNEO", false, function(Val)
    getgenv().Settings.InstantTeleport = Val
    if Val then
        SetStatus("Modo alterado para: TELEPORTE (Risco)")
    else
        SetStatus("Modo alterado para: VOO (Seguro)")
    end
end)

-- Notificação Inicial
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Lures Hub V6",
    Text = "Carregado com Sucesso!",
    Duration = 5,
    Icon = IMAGE_ID
})
