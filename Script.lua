local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Создаем основной интерфейс
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeamTeleportGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 450)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- Переключатель команд
local teamSwitchFrame = Instance.new("Frame")
teamSwitchFrame.Size = UDim2.new(1, 0, 0, 40)
teamSwitchFrame.Position = UDim2.new(0, 0, 0, 0)
teamSwitchFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
teamSwitchFrame.BorderSizePixel = 0
teamSwitchFrame.Parent = frame

local teamSwitchCorner = Instance.new("UICorner")
teamSwitchCorner.CornerRadius = UDim.new(0, 8)
teamSwitchCorner.Parent = teamSwitchFrame

local sheriffsButton = Instance.new("TextButton")
sheriffsButton.Size = UDim2.new(0.5, -2, 1, 0)
sheriffsButton.Position = UDim2.new(0, 0, 0, 0)
sheriffsButton.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
sheriffsButton.Text = "SHERIFFS"
sheriffsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
sheriffsButton.Font = Enum.Font.GothamBold
sheriffsButton.TextSize = 14
sheriffsButton.Parent = teamSwitchFrame

local criminalsButton = Instance.new("TextButton")
criminalsButton.Size = UDim2.new(0.5, -2, 1, 0)
criminalsButton.Position = UDim2.new(0.5, 2, 0, 0)
criminalsButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
criminalsButton.Text = "CRIMINALS"
criminalsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
criminalsButton.Font = Enum.Font.GothamBold
criminalsButton.TextSize = 14
criminalsButton.Parent = teamSwitchFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = sheriffsButton
buttonCorner:Clone().Parent = criminalsButton

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 45)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "ШЕРИФЫ"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -140)
scrollFrame.Position = UDim2.new(0, 5, 0, 80)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
scrollFrame.BorderSizePixel = 0
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = frame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 5)
uiListLayout.Parent = scrollFrame

-- Переменные для управления
local activeButtons = {} -- Отслеживание активных кнопок
local currentTeam = "Sheriffs" -- Текущая выбранная команда

-- Переменные для системы телепортации
local selectedPlayer = nil
local savedPosition = nil
local isTeleported = false

-- Переменная для отслеживания видимости интерфейса
local isUIVisible = true

-- Кнопка обновления списка
local refreshButton = Instance.new("TextButton")
refreshButton.Size = UDim2.new(1, -10, 0, 35)
refreshButton.Position = UDim2.new(0, 5, 1, -90)
refreshButton.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshButton.Text = "ОБНОВИТЬ СПИСОК"
refreshButton.Font = Enum.Font.GothamBold
refreshButton.TextSize = 14
refreshButton.Parent = frame

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 6)
refreshCorner.Parent = refreshButton

-- Инструкция
local instruction = Instance.new("TextLabel")
instruction.Size = UDim2.new(1, -10, 0, 40)
instruction.Position = UDim2.new(0, 5, 1, -45)
instruction.BackgroundTransparency = 1
instruction.TextColor3 = Color3.fromRGB(200, 200, 200)
instruction.Text = "Выберите игрока и нажмите Q для телепортации\nH - скрыть/показать интерфейс"
instruction.Font = Enum.Font.Gotham
instruction.TextSize = 12
instruction.TextWrapped = true
instruction.Parent = frame

-- Функция для скрытия/показа интерфейса
local function toggleUI()
	isUIVisible = not isUIVisible
	frame.Visible = isUIVisible
end

-- Функция для загрузки аватара игрока
local function loadPlayerAvatar(targetPlayer, imageLabel)
	-- Не загружаем аватар для локального игрока
	if targetPlayer == player then
		imageLabel.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
		return
	end

	local success, result = pcall(function()
		local thumbnailType = Enum.ThumbnailType.AvatarThumbnail
		local thumbnailSize = Enum.ThumbnailSize.Size100x100
		local content, isReady = Players:GetUserThumbnailAsync(targetPlayer.UserId, thumbnailType, thumbnailSize)
		return content
	end)

	if success then
		imageLabel.Image = result
	else
		imageLabel.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	end
end

-- Функция для расчета позиции за спиной игрока
local function getPositionBehind(targetCharacter, distance)
	if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then
		return nil
	end

	local rootPart = targetCharacter.HumanoidRootPart
	local lookVector = rootPart.CFrame.LookVector

	return rootPart.CFrame - lookVector * distance
end

-- Функция для телепортации к выбранному игроку
local function teleportToPlayer()
	if not selectedPlayer then
		return
	end

	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	if not selectedPlayer.Character or not selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	if not isTeleported then
		savedPosition = player.Character.HumanoidRootPart.CFrame
		local targetPosition = getPositionBehind(selectedPlayer.Character, 4)
		if targetPosition then
			player.Character.HumanoidRootPart.CFrame = targetPosition
			isTeleported = true
		end
	else
		if savedPosition then
			player.Character.HumanoidRootPart.CFrame = savedPosition
			isTeleported = false
			savedPosition = nil
		end
	end
end

-- Функция для создания кнопки игрока
local function createPlayerButton(targetPlayer)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 60)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	button.Text = ""
	button.AutoButtonColor = true
	button.Parent = scrollFrame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = button

	-- Аватар игрока
	local avatarFrame = Instance.new("Frame")
	avatarFrame.Size = UDim2.new(0, 50, 0, 50)
	avatarFrame.Position = UDim2.new(0, 5, 0, 5)
	avatarFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	avatarFrame.Parent = button

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0, 6)
	avatarCorner.Parent = avatarFrame

	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Size = UDim2.new(1, 0, 1, 0)
	avatarImage.BackgroundTransparency = 1
	avatarImage.Parent = avatarFrame

	local avatarCornerInner = Instance.new("UICorner")
	avatarCornerInner.CornerRadius = UDim.new(0, 6)
	avatarCornerInner.Parent = avatarImage

	-- Загружаем аватар игрока
	loadPlayerAvatar(targetPlayer, avatarImage)

	-- Информация об игроке
	local infoFrame = Instance.new("Frame")
	infoFrame.Size = UDim2.new(1, -65, 1, 0)
	infoFrame.Position = UDim2.new(0, 60, 0, 0)
	infoFrame.BackgroundTransparency = 1
	infoFrame.Name = "InfoFrame"
	infoFrame.Parent = button

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 25)
	nameLabel.Position = UDim2.new(0, 0, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Text = targetPlayer.Name
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = infoFrame

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, 0, 0, 20)
	statusLabel.Position = UDim2.new(0, 0, 0, 30)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statusLabel.Text = "Выберите для телепортации"
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 10
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Name = "StatusLabel"
	statusLabel.Parent = infoFrame

	-- Индикатор онлайн статуса
	local onlineIndicator = Instance.new("Frame")
	onlineIndicator.Size = UDim2.new(0, 8, 0, 8)
	onlineIndicator.Position = UDim2.new(1, -15, 0, 10)
	onlineIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	onlineIndicator.Parent = infoFrame

	local onlineCorner = Instance.new("UICorner")
	onlineCorner.CornerRadius = UDim.new(1, 0)
	onlineCorner.Parent = onlineIndicator

	button.MouseButton1Click:Connect(function()
		-- Снимаем выделение с предыдущего игрока
		for userId, btn in pairs(activeButtons) do
			if userId ~= targetPlayer.UserId then
				btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				local btnInfoFrame = btn:FindFirstChild("InfoFrame")
				if btnInfoFrame then
					local btnStatusLabel = btnInfoFrame:FindFirstChild("StatusLabel")
					if btnStatusLabel then
						btnStatusLabel.Text = "Выберите для телепортации"
					end
				end
			end
		end

		-- Выделяем текущего игрока
		if selectedPlayer == targetPlayer then
			selectedPlayer = nil
			button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			statusLabel.Text = "Выберите для телепортации"
			isTeleported = false
			savedPosition = nil
		else
			selectedPlayer = targetPlayer
			button.BackgroundColor3 = currentTeam == "Sheriffs" and Color3.fromRGB(80, 120, 80) or Color3.fromRGB(120, 80, 80)
			statusLabel.Text = "Выбран - нажмите Q для телепортации"
			isTeleported = false
			savedPosition = nil
		end
	end)

	return button
end

-- Функция очистки всех кнопок
local function clearAllButtons()
	for userId, button in pairs(activeButtons) do
		if button and button.Parent then
			button:Destroy()
		end
	end
	activeButtons = {}
end

-- Функция обновления списка игроков
local function updatePlayerList()
	-- Очищаем текущие кнопки
	clearAllButtons()

	local targetPlayers = {}

	-- Ищем всех игроков в выбранной команде
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer.Team and otherPlayer.Team.Name:lower() == currentTeam:lower() and otherPlayer ~= player then
			table.insert(targetPlayers, otherPlayer)
		end
	end

	-- Создаем кнопки для игроков в команде
	for _, targetPlayer in ipairs(targetPlayers) do
		activeButtons[targetPlayer.UserId] = createPlayerButton(targetPlayer)
	end

	-- Обновляем размер контента
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, uiListLayout.AbsoluteContentSize.Y)

	-- Обновляем заголовок с количеством игроков
	title.Text = currentTeam:upper() .. " (" .. #targetPlayers .. ")"

	-- Сбрасываем выбранного игрока при обновлении, если его больше нет в списке
	if selectedPlayer and not activeButtons[selectedPlayer.UserId] then
		selectedPlayer = nil
		isTeleported = false
		savedPosition = nil
	end
end

-- Функция переключения команды
local function switchTeam(newTeam)
	if currentTeam == newTeam then return end

	currentTeam = newTeam

	-- Обновляем цвета кнопок переключателя
	if newTeam == "Sheriffs" then
		sheriffsButton.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
		criminalsButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	else
		sheriffsButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		criminalsButton.BackgroundColor3 = Color3.fromRGB(120, 80, 80)
	end

	-- Обновляем список игроков
	updatePlayerList()
end

-- Обработчики для кнопок переключателя команды
sheriffsButton.MouseButton1Click:Connect(function()
	switchTeam("Sheriffs")
end)

criminalsButton.MouseButton1Click:Connect(function()
	switchTeam("Criminals")
end)

-- Обработчик для кнопки обновления
refreshButton.MouseButton1Click:Connect(function()
	updatePlayerList()
end)

-- Обработчик нажатия клавиши Q
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Q then
		teleportToPlayer()

		-- Обновляем статус кнопки
		if selectedPlayer and activeButtons[selectedPlayer.UserId] then
			local button = activeButtons[selectedPlayer.UserId]
			local infoFrame = button:FindFirstChild("InfoFrame")
			if infoFrame then
				local statusLabel = infoFrame:FindFirstChild("StatusLabel")
				if statusLabel then
					if isTeleported then
						statusLabel.Text = "Телепортирован к игроку - Q для возврата"
					else
						statusLabel.Text = "Выбран - Q для телепортации"
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

-- Обработчики событий для обновления при добавлении/удалении игроков
local function onPlayerAdded()
	updatePlayerList()
end

local function onPlayerRemoved()
	updatePlayerList()
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoved)

-- Функция для обработки смены команды
local function onTeamChanged()
	updatePlayerList()
end

-- Подписываемся на событие смены команды у всех игроков
local function setupTeamTracking()
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer:FindFirstChild("Team") then
			otherPlayer.TeamChanged:Connect(onTeamChanged)
		end
	end
end

-- Начальная настройка
setupTeamTracking()
updatePlayerList()
