local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Создаем основной интерфейс
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SheriffTeleportGUI"
screenGui.ResetOnSpawn = false -- Важно: отключаем сброс при возрождении
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 350)
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

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -40)
scrollFrame.Position = UDim2.new(0, 5, 0, 35)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
scrollFrame.BorderSizePixel = 0
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 4
scrollFrame.Parent = frame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 5)
uiListLayout.Parent = scrollFrame

local activeButtons = {} -- Отслеживание активных кнопок
local lastUpdate = 0
local updateInterval = 1 -- Обновление каждую секунду

-- Переменные для системы телепортации
local selectedSheriff = nil
local savedPosition = nil
local isTeleported = false

-- Функция для расчета позиции за спиной игрока
local function getPositionBehind(targetCharacter, distance)
	if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then
		return nil
	end

	local rootPart = targetCharacter.HumanoidRootPart
	local lookVector = rootPart.CFrame.LookVector

	-- Позиция за спиной игрока (противоположно направлению взгляда)
	return rootPart.CFrame - lookVector * distance
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

-- Функция для создания кнопки игрока
local function createPlayerButton(sheriff)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 50)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	button.Text = sheriff.Name
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.Gotham
	button.TextSize = 12
	button.AutoButtonColor = true
	button.Parent = scrollFrame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 6)
	buttonCorner.Parent = button

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -10, 0, 15)
	statusLabel.Position = UDim2.new(0, 5, 0, 30)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	statusLabel.Text = "Выберите для телепортации"
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 10
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = button

	button.MouseButton1Click:Connect(function()
		-- Снимаем выделение с предыдущего шерифа
		for userId, btn in pairs(activeButtons) do
			if userId ~= sheriff.UserId then
				btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				local lbl = btn:FindFirstChildOfClass("TextLabel")
				if lbl then
					lbl.Text = "Выберите для телепортации"
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

-- Функция обновления списка игроков
local function updatePlayerList()
	local sheriffs = {}

	-- Ищем всех игроков в команде Sheriffs
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer.Team and otherPlayer.Team.Name:lower() == "sheriffs" and otherPlayer ~= player then
			table.insert(sheriffs, otherPlayer)
		end
	end

	-- Удаляем кнопки игроков, которые больше не шерифы или вышли
	for userId, button in pairs(activeButtons) do
		local sheriffPlayer = Players:GetPlayerByUserId(userId)
		local shouldRemove = true

		for _, sheriff in ipairs(sheriffs) do
			if sheriff.UserId == userId then
				shouldRemove = false
				break
			end
		end

		if shouldRemove then
			button:Destroy()
			activeButtons[userId] = nil

			-- Если удаленный игрок был выбранным шерифом
			if selectedSheriff and selectedSheriff.UserId == userId then
				selectedSheriff = nil
				isTeleported = false
				savedPosition = nil
			end
		end
	end

	-- Создаем кнопки для новых шерифов
	for _, sheriff in ipairs(sheriffs) do
		if not activeButtons[sheriff.UserId] then
			activeButtons[sheriff.UserId] = createPlayerButton(sheriff)
		end
	end

	-- Обновляем размер контента
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, uiListLayout.AbsoluteContentSize.Y)

	-- Обновляем заголовок с количеством шерифов
	title.Text = "ШЕРИФЫ (" .. #sheriffs .. ")"
end

-- Обработчик нажатия клавиши Q
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Q then
		teleportToSheriff()

		-- Обновляем статус кнопки
		if selectedSheriff and activeButtons[selectedSheriff.UserId] then
			local button = activeButtons[selectedSheriff.UserId]
			local statusLabel = button:FindFirstChildOfClass("TextLabel")
			if statusLabel then
				if isTeleported then
					statusLabel.Text = "Телепортирован - нажмите Q для возврата"
				else
					statusLabel.Text = "Выбран - нажмите Q для телепортации"
				end
			end
		end
	end
end)

-- Обработчики событий для мгновенного обновления
Players.PlayerAdded:Connect(function()
	updatePlayerList()
end)

Players.PlayerRemoving:Connect(function()
	updatePlayerList()
end)

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

-- Постоянное обновление через RunService
RunService.Heartbeat:Connect(function()
	lastUpdate = lastUpdate + 1/60
	if lastUpdate >= updateInterval then
		updatePlayerList()
		lastUpdate = 0
	end
end)

-- Также обновляем при появлении новых игроков
Players.PlayerAdded:Connect(function(newPlayer)
	if newPlayer:FindFirstChild("Team") then
		newPlayer.TeamChanged:Connect(onTeamChanged)
	end
	updatePlayerList()
end)

-- Добавляем инструкцию
local instruction = Instance.new("TextLabel")
instruction.Size = UDim2.new(1, 0, 0, 40)
instruction.Position = UDim2.new(0, 0, 1, 5)
instruction.BackgroundTransparency = 1
instruction.TextColor3 = Color3.fromRGB(200, 200, 200)
instruction.Text = "Выберите шерифа и нажмите Q для телепортации"
instruction.Font = Enum.Font.Gotham
instruction.TextSize = 12
instruction.TextWrapped = true
instruction.Parent = frame
