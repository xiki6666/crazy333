local Players = game:GetService("Players")
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
frame.Size = UDim2.new(0, 300, 0, 450)
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

-- Фрейм для списка игроков
local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -10, 1, -140)
contentFrame.Position = UDim2.new(0, 5, 0, 35)
contentFrame.BackgroundTransparency = 1
contentFrame.ClipsDescendants = true
contentFrame.Parent = frame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 5)
uiListLayout.Parent = contentFrame

-- Таблицы для управления кнопками и игроками
local currentSheriffButtons = {} -- [UserId] = button
local selectedSheriffUserId = nil -- Храним ID выбранного игрока
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
	if not selectedSheriffUserId then
		return
	end

	local sheriff = Players:GetPlayerByUserId(selectedSheriffUserId)
	if not sheriff then
		return
	end

	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	if not sheriff.Character or not sheriff.Character:FindFirstChild("HumanoidRootPart") then
		return
	end

	if not isTeleported then
		-- Телепортация к шерифу
		savedPosition = player.Character.HumanoidRootPart.CFrame
		local targetPosition = getPositionBehind(sheriff.Character, 4)
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
	
	-- Обновляем статус кнопки
	updateButtonStatus(selectedSheriffUserId)
end

-- Функция для обновления статуса кнопки
local function updateButtonStatus(userId)
	local button = currentSheriffButtons[userId]
	if not button then return end
	
	local buttonContent = button:FindFirstChild("ButtonContent")
	if not buttonContent then return end
	
	local statusLabel = buttonContent:FindFirstChild("StatusLabel")
	if not statusLabel then return end
	
	if selectedSheriffUserId == userId then
		if isTeleported then
			statusLabel.Text = "Телепортирован - нажмите Q для возврата"
			button.BackgroundColor3 = Color3.fromRGB(120, 80, 80)
		else
			statusLabel.Text = "Выбран - нажмите Q для телепортации"
			button.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
		end
	else
		statusLabel.Text = "Выберите для телепортации"
		button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	end
end

-- Функция для создания кнопки игрока с аватаром
local function createPlayerButton(sheriff)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 70) -- Увеличили высоту для отображения двух имен
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

	-- Display Name (видимое имя)
	local displayNameLabel = Instance.new("TextLabel")
	displayNameLabel.Size = UDim2.new(1, -60, 0, 18)
	displayNameLabel.Position = UDim2.new(0, 60, 0, 10)
	displayNameLabel.BackgroundTransparency = 1
	displayNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	displayNameLabel.Text = sheriff.DisplayName
	displayNameLabel.Font = Enum.Font.GothamBold
	displayNameLabel.TextSize = 12
	displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	displayNameLabel.Name = "DisplayNameLabel"
	displayNameLabel.Parent = buttonContent

	-- Username (никнейм)
	local usernameLabel = Instance.new("TextLabel")
	usernameLabel.Size = UDim2.new(1, -60, 0, 15)
	usernameLabel.Position = UDim2.new(0, 60, 0, 30)
	usernameLabel.BackgroundTransparency = 1
	usernameLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	usernameLabel.Text = "@" .. sheriff.Name
	usernameLabel.Font = Enum.Font.Gotham
	usernameLabel.TextSize = 10
	usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
	usernameLabel.Name = "UsernameLabel"
	usernameLabel.Parent = buttonContent

	-- Статус
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -60, 0, 15)
	statusLabel.Position = UDim2.new(0, 60, 0, 50)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statusLabel.Text = "Выберите для телепортации"
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 10
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Name = "StatusLabel"
	statusLabel.Parent = buttonContent

	button.MouseButton1Click:Connect(function()
		-- Если уже выбран этот же игрок, снимаем выделение
		if selectedSheriffUserId == sheriff.UserId then
			selectedSheriffUserId = nil
			isTeleported = false
			savedPosition = nil
			updateButtonStatus(sheriff.UserId)
		else
			-- Снимаем выделение с предыдущего шерифа
			if selectedSheriffUserId then
				updateButtonStatus(selectedSheriffUserId)
			end
			
			-- Выделяем нового шерифа
			selectedSheriffUserId = sheriff.UserId
			updateButtonStatus(selectedSheriffUserId)
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

-- Функция обновления списка игроков
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
		currentSheriffButtons[sheriff.UserId] = createPlayerButton(sheriff)
	end
	
	-- Проверяем, остался ли выбранный шериф в списке
	if selectedSheriffUserId then
		local sheriffStillExists = false
		for _, sheriff in ipairs(currentSheriffs) do
			if sheriff.UserId == selectedSheriffUserId then
				sheriffStillExists = true
				break
			end
		end
		
		if not sheriffStillExists then
			selectedSheriffUserId = nil
			isTeleported = false
			savedPosition = nil
		else
			-- Обновляем статус кнопки выбранного игрока
			updateButtonStatus(selectedSheriffUserId)
		end
	end
	
	-- Обновляем заголовок с количеством шерифов
	title.Text = "ШЕРИФЫ (" .. #currentSheriffs .. ")"
end

-- Создаем кнопку обновления
local updateButton = Instance.new("TextButton")
updateButton.Size = UDim2.new(1, -10, 0, 30)
updateButton.Position = UDim2.new(0, 5, 1, -85)
updateButton.BackgroundColor3 = Color3.fromRGB(70, 70, 120)
updateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
updateButton.Text = "ОБНОВИТЬ СПИСОК"
updateButton.Font = Enum.Font.GothamBold
updateButton.TextSize = 12
updateButton.Parent = frame

local updateButtonCorner = Instance.new("UICorner")
updateButtonCorner.CornerRadius = UDim.new(0, 6)
updateButtonCorner.Parent = updateButton

-- Обработчик нажатия клавиши Q для телепортации
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Q then
		teleportToSheriff()
	end
end)

-- Обработчик нажатия клавиши H для скрытия/показа интерфейса
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.H then
		toggleUI()
	end
end)

-- Обработчик нажатия на кнопку обновления
updateButton.MouseButton1Click:Connect(function()
	updatePlayerList()
end)

-- Добавляем инструкцию
local instruction = Instance.new("TextLabel")
instruction.Size = UDim2.new(1, -10, 0, 40)
instruction.Position = UDim2.new(0, 5, 1, -40)
instruction.BackgroundTransparency = 1
instruction.TextColor3 = Color3.fromRGB(200, 200, 200)
instruction.Text = "Q - телепортация/возврат\nH - скрыть/показать меню"
instruction.Font = Enum.Font.Gotham
instruction.TextSize = 11
instruction.TextWrapped = true
instruction.Parent = frame

-- Начальная загрузка списка
updatePlayerList()
