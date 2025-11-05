local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Создаем основной интерфейс
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SheriffTeleportGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 400)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "ШЕРИФЫ"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

-- Заменяем ScrollingFrame на обычный Frame для контента
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -10, 1, -90)
contentFrame.Position = UDim2.new(0, 5, 0, 35)
contentFrame.BackgroundTransparency = 1
contentFrame.ClipsDescendants = true
contentFrame.Parent = frame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 5)
uiListLayout.Parent = contentFrame

-- Полностью переработанная система управления кнопками
local currentSheriffButtons = {} -- Только текущие кнопки
local selectedSheriff = nil
local savedPosition = nil
local isTeleported = false
local isUIVisible = true

-- Функция для расчета позиции за спиной игрока
local function getPositionBehind(targetCharacter, distance)
	if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then
		return nil
	end

	local rootPart = targetCharacter.HumanoidRootPart
	local lookVector = rootPart.CFrame.LookVector

	return rootPart.CFrame - lookVector * distance
end

-- Функция для получения аватара игрока
local function getPlayerAvatar(userId)
	local thumbnailType = Enum.ThumbnailType.HeadShot
	local thumbnailSize = Enum.ThumbnailSize.Size100x100
	
	local success, result = pcall(function()
		return Players:GetUserThumbnailAsync(userId, thumbnailType, thumbnailSize)
	end)
	
	if success then
		return result
	else
		return "rbxasset://textures/ui/GuiImagePlaceholder.png"
	end
end

-- Функция для телепортации к выбранному шерифу
local function teleportToSheriff()
	if not selectedSheriff then
		return
	end

	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	if not selectedSheriff.Character or not selectedSheriff.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	if not isTeleported then
		-- Телепортация к шерифу
		savedPosition = player.Character.HumanoidRootPart.CFrame
		local targetPosition = getPositionBehind(selectedSheriff.Character, 4)
		if targetPosition then
			player.Character.HumanoidRootPart.CFrame = targetPosition
			isTeleported = true
		end
	else
		-- Возврат на исходную позицию
		if savedPosition then
			player.Character.HumanoidRootPart.CFrame = savedPosition
			isTeleported = false
			savedPosition = nil
		end
	end
end

-- Функция для полной очистки всех кнопок
local function clearAllButtons()
	-- Удаляем все кнопки из контентного фрейма
	for _, child in ipairs(contentFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	
	-- Очищаем таблицу кнопок
	currentSheriffButtons = {}
end

-- Функция для создания кнопки игрока с аватаром
local function createPlayerButton(sheriff)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 60)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	button.Text = ""
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.Gotham
	button.TextSize = 12
	button.AutoButtonColor = true
	button.Parent = contentFrame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = button

	-- Контейнер для содержимого кнопки
	local buttonContent = Instance.new("Frame")
	buttonContent.Size = UDim2.new(1, 0, 1, 0)
	buttonContent.BackgroundTransparency = 1
	buttonContent.Name = "ButtonContent"
	buttonContent.Parent = button

	-- Аватар игрока
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0, 40, 0, 40)
	avatar.Position = UDim2.new(0, 10, 0.5, -20)
	avatar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	avatar.BorderSizePixel = 0
	avatar.Image = getPlayerAvatar(sheriff.UserId)
	avatar.Name = "Avatar"
	avatar.Parent = buttonContent

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0, 20)
	avatarCorner.Parent = avatar

	-- Имя игрока
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -60, 0, 20)
	nameLabel.Position = UDim2.new(0, 60, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Text = sheriff.Name
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Name = "NameLabel"
	nameLabel.Parent = buttonContent

	-- Статус
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -60, 0, 15)
	statusLabel.Position = UDim2.new(0, 60, 0, 35)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statusLabel.Text = "Выберите для телепортации"
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 10
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Name = "StatusLabel"
	statusLabel.Parent = buttonContent

	button.MouseButton1Click:Connect(function()
		-- Снимаем выделение с предыдущего шерифа
		for _, btn in pairs(currentSheriffButtons) do
			if btn ~= button then
				btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				local btnContent = btn:FindFirstChild("ButtonContent")
				if btnContent then
					local lbl = btnContent:FindFirstChild("StatusLabel")
					if lbl then
						lbl.Text = "Выберите для телепортации"
					end
				end
			end
		end

		-- Выделяем текущего шерифа
		if selectedSheriff == sheriff then
			-- Снимаем выделение при повторном нажатии
			selectedSheriff = nil
			button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			statusLabel.Text = "Выберите для телепортации"
			isTeleported = false
			savedPosition = nil
		else
			-- Выделяем нового шерифа
			selectedSheriff = sheriff
			button.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
			statusLabel.Text = "Выбран - нажмите Q для телепортации"
			isTeleported = false
			savedPosition = nil
		end
	end)

	return button
end

-- Функция для скрытия/показа интерфейса
local function toggleUI()
	isUIVisible = not isUIVisible
	
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	
	if isUIVisible then
		-- Показываем интерфейс
		local tween = TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0, 10, 0, 10)})
		tween:Play()
	else
		-- Скрываем интерфейс (сдвигаем за левый край)
		local tween = TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0, -frame.Size.X.Offset - 10, 0, 10)})
		tween:Play()
	end
end

-- Полностью переработанная функция обновления списка игроков
local function updatePlayerList()
	-- Получаем текущих шерифов
	local currentSheriffs = {}
	
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer.Team and otherPlayer.Team.Name:lower() == "sheriffs" and otherPlayer ~= player then
			table.insert(currentSheriffs, otherPlayer)
		end
	end
	
	-- Полностью очищаем старые кнопки
	clearAllButtons()
	
	-- Создаем новые кнопки для текущих шерифов
	for _, sheriff in ipairs(currentSheriffs) do
		local button = createPlayerButton(sheriff)
		table.insert(currentSheriffButtons, button)
	end
	
	-- Проверяем, остался ли выбранный шериф в списке
	if selectedSheriff then
		local sheriffStillExists = false
		for _, sheriff in ipairs(currentSheriffs) do
			if sheriff == selectedSheriff then
				sheriffStillExists = true
				break
			end
		end
		
		if not sheriffStillExists then
			selectedSheriff = nil
			isTeleported = false
			savedPosition = nil
		end
	end
	
	-- Обновляем заголовок с количеством шерифов
	title.Text = "ШЕРИФЫ (" .. #currentSheriffs .. ")"
end

-- Обработчик нажатия клавиши Q для телепортации
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Q then
		teleportToSheriff()

		-- Обновляем статус всех кнопок
		for _, button in pairs(currentSheriffButtons) do
			local buttonContent = button:FindFirstChild("ButtonContent")
			if buttonContent then
				local statusLabel = buttonContent:FindFirstChild("StatusLabel")
				local nameLabel = buttonContent:FindFirstChild("NameLabel")
				
				if statusLabel and nameLabel then
					if selectedSheriff and nameLabel.Text == selectedSheriff.Name then
						if isTeleported then
							statusLabel.Text = "Телепортирован - нажмите Q для возврата"
						else
							statusLabel.Text = "Выбран - нажмите Q для телепортации"
						end
					else
						statusLabel.Text = "Выберите для телепортации"
					end
				end
			end
		end
	end
end)

-- Обработчик нажатия клавиши H для скрытия/показа интерфейса
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.H then
		toggleUI()
	end
end)

-- Функция для обработки смены команды
local function onTeamChanged()
	updatePlayerList()
end

-- Подписываемся на событие смены команды у всех игроков
local function setupTeamTracking()
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		otherPlayer:GetPropertyChangedSignal("Team"):Connect(onTeamChanged)
	end
end

-- Начальная настройка
setupTeamTracking()
updatePlayerList()

-- Постоянное обновление через RunService (каждые 2 секунды для надежности)
local lastUpdate = 0
local updateInterval = 2

RunService.Heartbeat:Connect(function(deltaTime)
	lastUpdate = lastUpdate + deltaTime
	if lastUpdate >= updateInterval then
		updatePlayerList()
		lastUpdate = 0
	end
end)

-- Обработчики для новых игроков
Players.PlayerAdded:Connect(function(newPlayer)
	newPlayer:GetPropertyChangedSignal("Team"):Connect(function()
		onTeamChanged()
	end)
	updatePlayerList()
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
	-- Если выходящий игрок был выбранным шерифом
	if selectedSheriff and selectedSheriff == leavingPlayer then
		selectedSheriff = nil
		isTeleported = false
		savedPosition = nil
	end
	updatePlayerList()
end)

-- Обработчик изменения команды у локального игрока
player:GetPropertyChangedSignal("Team"):Connect(function()
	onTeamChanged()
end)

-- Добавляем инструкцию
local instruction = Instance.new("TextLabel")
instruction.Size = UDim2.new(1, 0, 0, 50)
instruction.Position = UDim2.new(0, 0, 1, 5)
instruction.BackgroundTransparency = 1
instruction.TextColor3 = Color3.fromRGB(200, 200, 200)
instruction.Text = "Q - телепортация/возврат\nH - скрыть/показать меню"
instruction.Font = Enum.Font.Gotham
instruction.TextSize = 11
instruction.TextWrapped = true
instruction.Parent = frame
