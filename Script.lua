local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- Основные переменные
local teleportingTo = nil
local lastPosition = nil
local connections = {}
local selectedPlayerFrame = nil
local selectedPlayer = nil
local guiVisible = true
local movementConnection = nil

-- Создание GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeamTeleportGUI"
screenGui.Parent = PlayerGui
screenGui.ResetOnSpawn = false -- Сохраняем GUI после смерти

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 530) -- Увеличили высоту для статуса
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BackgroundTransparency = 0.1
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleBar.Parent = mainFrame

local titleBarCorner = Instance.new("UICorner")
titleBarCorner.CornerRadius = UDim.new(0, 8)
titleBarCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Sheriffs"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.Parent = titleBar

-- Список игроков
local playerList = Instance.new("ScrollingFrame")
playerList.Size = UDim2.new(1, -10, 1, -150) -- Уменьшили высоту для статуса
playerList.Position = UDim2.new(0, 5, 0, 45)
playerList.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerList.ScrollBarThickness = 5
playerList.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = playerList

-- Панель статуса выбранного игрока
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, -10, 0, 40)
statusBar.Position = UDim2.new(0, 5, 0, 405)
statusBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
statusBar.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusBar

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Выберите игрока для отображения статуса"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextWrapped = true
statusLabel.Parent = statusBar

-- Панель обновления
local bottomBar = Instance.new("Frame")
bottomBar.Size = UDim2.new(1, 0, 0, 40)
bottomBar.Position = UDim2.new(0, 0, 1, -40)
bottomBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
bottomBar.Parent = mainFrame

local bottomBarCorner = Instance.new("UICorner")
bottomBarCorner.CornerRadius = UDim.new(0, 8)
bottomBarCorner.Parent = bottomBar

local refreshButton = Instance.new("TextButton")
refreshButton.Size = UDim2.new(1, -20, 1, -10)
refreshButton.Position = UDim2.new(0, 10, 0, 5)
refreshButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshButton.Text = "Обновить список"
refreshButton.Parent = bottomBar

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 6)
refreshCorner.Parent = refreshButton

-- Функции
local function getSheriffsPlayers()
    local sheriffsPlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Player and player.Team and player.Team.Name == "Sheriffs" then
            table.insert(sheriffsPlayers, player)
        end
    end
    return sheriffsPlayers
end

local function getLeaderstatsString(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return "Нет статистики"
    end
    
    local stats = {}
    for _, stat in ipairs(leaderstats:GetChildren()) do
        if stat:IsA("IntValue") or stat:IsA("NumberValue") or stat:IsA("StringValue") then
            table.insert(stats, stat.Name .. ": " .. tostring(stat.Value))
        end
    end
    
    if #stats > 0 then
        return table.concat(stats, " | ")
    else
        return "Нет статистики"
    end
end

-- Функция для отслеживания движения игрока
local function trackPlayerMovement(player)
    if movementConnection then
        movementConnection:Disconnect()
        movementConnection = nil
    end
    
    movementConnection = RunService.Heartbeat:Connect(function()
        if not player or not player.Parent or not selectedPlayer then
            if movementConnection then
                movementConnection:Disconnect()
                movementConnection = nil
            end
            statusLabel.Text = "Игрок недоступен"
            return
        end
        
        local character = player.Character
        if not character then
            statusLabel.Text = "Персонаж не найден"
            return
        end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            statusLabel.Text = "Нет корневой части"
            return
        end
        
        -- Проверяем движение по скорости
        local velocity = humanoidRootPart.Velocity
        local speed = math.sqrt(velocity.X * velocity.X + velocity.Y * velocity.Y + velocity.Z * velocity.Z)
        
        -- Проверяем стоит ли игрок (скорость меньше 0.1)
        if speed < 0.1 then
            statusLabel.Text = "Статус: Стоит на месте"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100) -- Зеленый
        else
            statusLabel.Text = "Статус: Двигается (скорость: " .. math.floor(speed * 10) / 10 .. ")"
            statusLabel.TextColor3 = Color3.fromRGB(255, 150, 100) -- Оранжевый
        end
    end)
end

-- Функция для снятия выделения со всех игроков
local function clearAllHighlights()
    for _, child in ipairs(playerList:GetChildren()) do
        if child:IsA("Frame") then
            child.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            local highlight = child:FindFirstChild("Highlight")
            if highlight then
                highlight.Visible = false
            end
        end
    end
    
    -- Останавливаем отслеживание движения
    if movementConnection then
        movementConnection:Disconnect()
        movementConnection = nil
    end
    
    statusLabel.Text = "Выберите игрока для отображения статуса"
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
end

local function createPlayerEntry(player)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 6)
    frameCorner.Parent = frame
    
    -- Аватар игрока
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 50, 0, 50)
    avatar.Position = UDim2.new(0, 10, 0, 15)
    avatar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    avatar.BorderSizePixel = 0
    
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(0, 25)
    avatarCorner.Parent = avatar
    
    -- Загрузка аватара
    spawn(function()
        local success, result = pcall(function()
            return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        
        if success then
            avatar.Image = result
        else
            avatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        end
    end)
    
    avatar.Parent = frame
    
    -- Информация об игроке
    local infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(1, -70, 1, 0)
    infoFrame.Position = UDim2.new(0, 65, 0, 0)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Parent = frame
    
    local displayName = Instance.new("TextLabel")
    displayName.Size = UDim2.new(1, 0, 0, 20)
    displayName.Position = UDim2.new(0, 5, 0, 10)
    displayName.BackgroundTransparency = 1
    displayName.Text = player.DisplayName
    displayName.TextColor3 = Color3.fromRGB(255, 255, 255)
    displayName.TextXAlignment = Enum.TextXAlignment.Left
    displayName.Font = Enum.Font.GothamBold
    displayName.TextSize = 14
    displayName.Parent = infoFrame
    
    local username = Instance.new("TextLabel")
    username.Size = UDim2.new(1, 0, 0, 16)
    username.Position = UDim2.new(0, 5, 0, 30)
    username.BackgroundTransparency = 1
    username.Text = "@" .. player.Name
    username.TextColor3 = Color3.fromRGB(200, 200, 200)
    username.TextXAlignment = Enum.TextXAlignment.Left
    username.Font = Enum.Font.Gotham
    username.TextSize = 12
    username.Parent = infoFrame
    
    local leaderstats = Instance.new("TextLabel")
    leaderstats.Size = UDim2.new(1, -10, 0, 16)
    leaderstats.Position = UDim2.new(0, 5, 0, 50)
    leaderstats.BackgroundTransparency = 1
    leaderstats.Text = getLeaderstatsString(player)
    leaderstats.TextColor3 = Color3.fromRGB(150, 200, 255)
    leaderstats.TextXAlignment = Enum.TextXAlignment.Left
    leaderstats.Font = Enum.Font.Gotham
    leaderstats.TextSize = 11
    leaderstats.TextWrapped = true
    leaderstats.Parent = infoFrame
    
    -- Подсветка выбранного игрока
    local highlight = Instance.new("Frame")
    highlight.Name = "Highlight" -- Добавляем имя для поиска
    highlight.Size = UDim2.new(1, 0, 0, 4)
    highlight.Position = UDim2.new(0, 0, 1, -4)
    highlight.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    highlight.Visible = false
    highlight.Parent = frame
    
    local highlightCorner = Instance.new("UICorner")
    highlightCorner.CornerRadius = UDim.new(0, 6)
    highlightCorner.Parent = highlight
    
    -- Проверяем, является ли этот игрок выбранным
    if selectedPlayer == player then
        frame.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
        highlight.Visible = true
        selectedPlayerFrame = frame
    end
    
    frame.MouseEnter:Connect(function()
        if frame ~= selectedPlayerFrame then
            frame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        end
    end)
    
    frame.MouseLeave:Connect(function()
        if frame ~= selectedPlayerFrame then
            frame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
    end)
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Если кликаем на уже выбранного игрока, снимаем выделение
            if selectedPlayer == player then
                clearAllHighlights()
                selectedPlayerFrame = nil
                selectedPlayer = nil
                teleportingTo = nil
            else
                -- Снимаем выделение со всех игроков
                clearAllHighlights()
                
                -- Выделяем нового игрока
                frame.BackgroundColor3 = Color3.fromRGB(100, 100, 150)
                highlight.Visible = true
                selectedPlayerFrame = frame
                selectedPlayer = player
                teleportingTo = player
                
                -- Начинаем отслеживать движение выбранного игрока
                trackPlayerMovement(player)
            end
        end
    end)
    
    return frame
end

local function updatePlayerList()
    -- Очистка предыдущих подключек
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    connections = {}
    
    -- Очистка списка
    for _, child in ipairs(playerList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Сохраняем выделение только если игрок все еще в команде
    if selectedPlayer then
        local sheriffsPlayers = getSheriffsPlayers()
        local playerStillInTeam = false
        for _, player in ipairs(sheriffsPlayers) do
            if player == selectedPlayer then
                playerStillInTeam = true
                break
            end
        end
        
        if not playerStillInTeam then
            clearAllHighlights()
            selectedPlayerFrame = nil
            selectedPlayer = nil
            teleportingTo = nil
        else
            -- Продолжаем отслеживать движение, если игрок все еще выбран
            trackPlayerMovement(selectedPlayer)
        end
    end
    
    -- Добавление игроков
    local sheriffsPlayers = getSheriffsPlayers()
    for _, player in ipairs(sheriffsPlayers) do
        local entry = createPlayerEntry(player)
        entry.Parent = playerList
        
        -- Отслеживание покидания игры
        table.insert(connections, player.AncestryChanged:Connect(function()
            if not player.Parent then
                if selectedPlayer == player then
                    clearAllHighlights()
                    selectedPlayerFrame = nil
                    selectedPlayer = nil
                    teleportingTo = nil
                end
                entry:Destroy()
            end
        end))
    end
end

-- Функция скрытия/показа GUI
local function toggleGUI()
    guiVisible = not guiVisible
    mainFrame.Visible = guiVisible
end

-- Обработчик обновления списка
refreshButton.MouseButton1Click:Connect(updatePlayerList)

-- Функция телепортации за спину (ближе)
local function teleportToPlayer(targetPlayer)
    local character = Player.Character
    local targetCharacter = targetPlayer.Character
    
    if not character or not targetCharacter then 
        return 
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not targetRoot or not humanoidRootPart then 
        return 
    end
    
    if not lastPosition then
        -- Сохраняем позицию для возврата
        lastPosition = humanoidRootPart.CFrame
        
        -- Телепортируемся за спину целевого игрока (ближе - 2.5 единицы вместо 5)
        local targetCFrame = targetRoot.CFrame
        local offset = targetCFrame.LookVector * -2.5 -- Ближе к игроку
        local newPosition = targetCFrame.Position + offset + Vector3.new(0, 2, 0) -- Меньше подъема
        
        humanoidRootPart.CFrame = CFrame.new(newPosition, targetCFrame.Position)
    else
        -- Возврат на исходную позицию
        humanoidRootPart.CFrame = lastPosition
        lastPosition = nil
    end
end

-- Обработка нажатия Q (телепортация) и H (скрытие/показа GUI)
local function onInput(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Q and teleportingTo then
        teleportToPlayer(teleportingTo)
    elseif input.KeyCode == Enum.KeyCode.H then
        toggleGUI()
    end
end

UserInputService.InputBegan:Connect(onInput)

-- Первоначальное обновление
updatePlayerList()
