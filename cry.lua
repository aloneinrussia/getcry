local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Settings = {
	Key = "cry",

	Keybinds = {
		Aim = Enum.KeyCode.Q,
		ESP = Enum.KeyCode.E,
		Speed = Enum.KeyCode.V,
		Jump = Enum.KeyCode.B,
		PanicGround = Enum.KeyCode.G,
	},

	Aim = {
		Camlock = true,
		SilentAim = true,
		FOV = 150,
		HitboxMultiplier = 2,
		CurveBullets = true,
	},

	ESP = {
		Enabled = false,
		Color = Color3.fromRGB(255, 60, 60),
		Transparency = 0.7,
	},

	Speed = {
		Enabled = false,
		Value = 32,
		Minimum = 16,
		Maximum = 100,
	},

	Jump = {
		Enabled = false,
		Value = 100,
		Minimum = 50,
		Maximum = 150,
	},

	Weapon = {
		Enabled = true,
		Damage = 25,
		Range = 1000,
		FireRate = 0.12,
		BulletThickness = 0.08,
	}
}

local destroyed = false
local aimEnabled = false
local espEnabled = false
local speedEnabled = false
local jumpEnabled = false
local target = nil

local connections = {}
local espObjects = {}
local nameObjects = {}

local originalWalkSpeed = 16
local originalJumpPower = 50

local espExpanded = true
local speedExpanded = true
local jumpExpanded = true

local lastShot = 0

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local function getCharacter()
	return player.Character
end

local function getHumanoid(character)
	character = character or getCharacter()
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot(character)
	character = character or getCharacter()
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function validCharacter(character)
	local hum = getHumanoid(character)
	return character ~= nil and hum ~= nil and hum.Health > 0
end

local function destroyESP(character)
	if espObjects[character] then
		for _, object in ipairs(espObjects[character]) do
			if object then
				object:Destroy()
			end
		end

		espObjects[character] = nil
	end

	if nameObjects[character] then
		nameObjects[character]:Destroy()
		nameObjects[character] = nil
	end
end

local function createESP(otherPlayer)
	if not espEnabled or otherPlayer == player then
		return
	end

	local character = otherPlayer.Character

	if not validCharacter(character) then
		return
	end

	destroyESP(character)

	local objects = {}

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			local box = Instance.new("BoxHandleAdornment")
			box.Name = "CrysHitbox"
			box.Adornee = part
			box.Size = part.Size
			box.Color3 = Settings.ESP.Color
			box.Transparency = Settings.ESP.Transparency
			box.AlwaysOnTop = true
			box.ZIndex = 10
			box.Parent = part

			table.insert(objects, box)
		end
	end

	espObjects[character] = objects

	local head = character:FindFirstChild("Head") or getRoot(character)

	if head then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "CrysPlayerName"
		billboard.Adornee = head
		billboard.Size = UDim2.fromOffset(200, 30)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = playerGui

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = otherPlayer.DisplayName
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.TextStrokeTransparency = 0
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.Parent = billboard

		nameObjects[character] = billboard
	end
end

local function refreshESP()
	for character in pairs(espObjects) do
		destroyESP(character)
	end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			createESP(otherPlayer)
		end
	end
end

local function getClosestTarget()
	local camera = workspace.CurrentCamera

	if not camera then
		return nil
	end

	local viewport = camera.ViewportSize
	local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

	local closestPlayer = nil
	local closestDistance = math.huge

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and validCharacter(otherPlayer.Character) then
			local character = otherPlayer.Character
			local targetRoot =
				character:FindFirstChild("HumanoidRootPart")
				or character:FindFirstChild("Head")

			if targetRoot then
				local position, visible =
					camera:WorldToViewportPoint(targetRoot.Position)

				if visible and position.Z > 0 then
					local screenPosition =
						Vector2.new(position.X, position.Y)

					local distance =
						(screenPosition - center).Magnitude

					if distance <= Settings.Aim.FOV
						and distance < closestDistance then

						closestDistance = distance
						closestPlayer = otherPlayer
					end
				end
			end
		end
	end

	return closestPlayer
end

local function toggleAim()
	aimEnabled = not aimEnabled

	if aimEnabled then
		target = getClosestTarget()
	else
		target = nil
	end

	if aimLabel then
		aimLabel.TextColor3 = aimEnabled
			and Color3.fromRGB(80, 255, 120)
			or Color3.fromRGB(255, 255, 255)
	end
end

local function getAimPoint(otherPlayer)
	if not otherPlayer or not validCharacter(otherPlayer.Character) then
		return nil
	end

	local character = otherPlayer.Character
	local root = getRoot(character)
	local head = character:FindFirstChild("Head")

	if not root then
		return nil
	end

	local point = head and head.Position or root.Position

	if Settings.Aim.HitboxMultiplier > 1 then
		local offset = point - root.Position
		point = root.Position + offset * Settings.Aim.HitboxMultiplier
	end

	if Settings.Aim.CurveBullets then
		local velocity = root.AssemblyLinearVelocity
		local distance = (root.Position - getRoot().Position).Magnitude
		local prediction = math.clamp(distance / 1000, 0, 0.25)

		point += velocity * prediction
	end

	return point
end

local function createBullet(origin, destination)
	local distance = (destination - origin).Magnitude

	local bullet = Instance.new("Part")
	bullet.Name = "CrysBullet"
	bullet.Anchored = true
	bullet.CanCollide = false
	bullet.CanTouch = false
	bullet.CanQuery = false
	bullet.Material = Enum.Material.Neon
	bullet.Size = Vector3.new(
		Settings.Weapon.BulletThickness,
		Settings.Weapon.BulletThickness,
		distance
	)
	bullet.CFrame = CFrame.lookAt(
		(origin + destination) / 2,
		destination
	)
	bullet.Parent = workspace

	task.delay(0.06, function()
		if bullet and bullet.Parent then
			bullet:Destroy()
		end
	end)
end

local function findHitCharacter(instance)
	if not instance then
		return nil
	end

	local model = instance:FindFirstAncestorOfClass("Model")

	if not model then
		return nil
	end

	local hum = model:FindFirstChildOfClass("Humanoid")

	if not hum then
		return nil
	end

	return model
end

local function fireWeapon()
	if destroyed or not Settings.Weapon.Enabled then
		return
	end

	local now = os.clock()

	if now - lastShot < Settings.Weapon.FireRate then
		return
	end

	lastShot = now

	local character = getCharacter()
	local root = getRoot(character)

	if not root then
		return
	end

	local camera = workspace.CurrentCamera

	if not camera then
		return
	end

	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector

	local destination = origin + direction * Settings.Weapon.Range

	if aimEnabled and Settings.Aim.SilentAim then
		if not target or not validCharacter(target.Character) then
			target = getClosestTarget()
		end

		local aimPoint = getAimPoint(target)

		if aimPoint then
			destination = aimPoint
		end
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		character
	}

	local result = workspace:Raycast(
		origin,
		(destination - origin).Unit * Settings.Weapon.Range,
		params
	)

	if result then
		destination = result.Position

		local hitCharacter = findHitCharacter(result.Instance)

		if hitCharacter then
			local hum = hitCharacter:FindFirstChildOfClass("Humanoid")

			if hum and hum.Health > 0 then
				hum:TakeDamage(Settings.Weapon.Damage)
			end
		end
	end

	createBullet(origin, destination)
end

local loadingGui = Instance.new("ScreenGui")
loadingGui.Name = "CrysLoading"
loadingGui.IgnoreGuiInset = true
loadingGui.ResetOnSpawn = false
loadingGui.DisplayOrder = 999
loadingGui.Parent = playerGui

local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 0.25
background.BorderSizePixel = 0
background.Parent = loadingGui

local loadingContainer = Instance.new("Frame")
loadingContainer.AnchorPoint = Vector2.new(0.5, 0.5)
loadingContainer.Position = UDim2.fromScale(0.5, 0.53)
loadingContainer.Size = UDim2.fromOffset(420, 230)
loadingContainer.BackgroundTransparency = 1
loadingContainer.Parent = background

local loadingTitle = Instance.new("TextLabel")
loadingTitle.Size = UDim2.new(1, 0, 0, 45)
loadingTitle.BackgroundTransparency = 1
loadingTitle.Text = "LOADING"
loadingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
loadingTitle.Font = Enum.Font.GothamBold
loadingTitle.TextSize = 30
loadingTitle.Parent = loadingContainer

local loadingStatus = Instance.new("TextLabel")
loadingStatus.Position = UDim2.fromOffset(0, 65)
loadingStatus.Size = UDim2.new(1, 0, 0, 30)
loadingStatus.BackgroundTransparency = 1
loadingStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
loadingStatus.Font = Enum.Font.Gotham
loadingStatus.TextSize = 15
loadingStatus.Parent = loadingContainer

local loadingBarBackground = Instance.new("Frame")
loadingBarBackground.Position = UDim2.fromOffset(60, 115)
loadingBarBackground.Size = UDim2.fromOffset(300, 4)
loadingBarBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
loadingBarBackground.BorderSizePixel = 0
loadingBarBackground.Parent = loadingContainer

local loadingBar = Instance.new("Frame")
loadingBar.Size = UDim2.fromScale(0, 1)
loadingBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
loadingBar.BorderSizePixel = 0
loadingBar.Parent = loadingBarBackground

local loadingDiscord = Instance.new("TextLabel")
loadingDiscord.Position = UDim2.fromOffset(0, 150)
loadingDiscord.Size = UDim2.new(1, 0, 0, 25)
loadingDiscord.BackgroundTransparency = 1
loadingDiscord.Text = "discord.gg/NGQu84rQNr"
loadingDiscord.TextColor3 = Color3.fromRGB(130, 130, 130)
loadingDiscord.Font = Enum.Font.GothamMedium
loadingDiscord.TextSize = 13
loadingDiscord.Parent = loadingContainer

local messages = {
	"loading storage",
	"loading scripts",
	"loading cheats"
}

for index, message in ipairs(messages) do
	if destroyed then
		return
	end

	loadingStatus.Text = message

	TweenService:Create(
		loadingBar,
		TweenInfo.new(0.8, Enum.EasingStyle.Quint),
		{
			Size = UDim2.fromScale(index / #messages, 1)
		}
	):Play()

	task.wait(0.9)
end

task.wait(0.25)

for _, object in ipairs({
	background,
	loadingTitle,
	loadingStatus,
	loadingBarBackground,
	loadingBar,
	loadingDiscord
}) do
	if object:IsA("Frame") then
		TweenService:Create(
			object,
			TweenInfo.new(0.7),
			{
				BackgroundTransparency = 1
			}
		):Play()
	else
		TweenService:Create(
			object,
			TweenInfo.new(0.7),
			{
				TextTransparency = 1
			}
		):Play()
	end
end

task.wait(0.8)

loadingGui:Destroy()

local keyGui = Instance.new("ScreenGui")
keyGui.Name = "CrysKeySystem"
keyGui.IgnoreGuiInset = true
keyGui.ResetOnSpawn = false
keyGui.DisplayOrder = 100
keyGui.Parent = playerGui

local keyBackground = Instance.new("Frame")
keyBackground.Size = UDim2.fromScale(1, 1)
keyBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
keyBackground.BackgroundTransparency = 0.25
keyBackground.BorderSizePixel = 0
keyBackground.Parent = keyGui

local keyPanel = Instance.new("Frame")
keyPanel.AnchorPoint = Vector2.new(0.5, 0.5)
keyPanel.Position = UDim2.fromScale(0.5, 0.55)
keyPanel.Size = UDim2.fromOffset(430, 300)
keyPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
keyPanel.BorderSizePixel = 0
keyPanel.Parent = keyBackground

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0, 12)
keyCorner.Parent = keyPanel

local keyStroke = Instance.new("UIStroke")
keyStroke.Color = Color3.fromRGB(35, 35, 35)
keyStroke.Parent = keyPanel

local keyTitle = Instance.new("TextLabel")
keyTitle.Position = UDim2.fromOffset(20, 25)
keyTitle.Size = UDim2.new(1, -40, 0, 35)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "KEY SYSTEM"
keyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
keyTitle.Font = Enum.Font.GothamBold
keyTitle.TextSize = 25
keyTitle.Parent = keyPanel

local keyDescription = Instance.new("TextLabel")
keyDescription.Position = UDim2.fromOffset(20, 65)
keyDescription.Size = UDim2.new(1, -40, 0, 30)
keyDescription.BackgroundTransparency = 1
keyDescription.Text = "Enter your key below to continue."
keyDescription.TextColor3 = Color3.fromRGB(140, 140, 140)
keyDescription.Font = Enum.Font.Gotham
keyDescription.TextSize = 14
keyDescription.Parent = keyPanel

local keyBox = Instance.new("TextBox")
keyBox.Position = UDim2.fromOffset(45, 110)
keyBox.Size = UDim2.new(1, -90, 0, 45)
keyBox.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
keyBox.BorderSizePixel = 0
keyBox.PlaceholderText = "Enter key..."
keyBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
keyBox.Text = ""
keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
keyBox.Font = Enum.Font.Gotham
keyBox.TextSize = 14
keyBox.ClearTextOnFocus = false
keyBox.Parent = keyPanel

local keyBoxCorner = Instance.new("UICorner")
keyBoxCorner.CornerRadius = UDim.new(0, 8)
keyBoxCorner.Parent = keyBox

local checkButton = Instance.new("TextButton")
checkButton.Position = UDim2.fromOffset(45, 165)
checkButton.Size = UDim2.new(1, -90, 0, 45)
checkButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
checkButton.BorderSizePixel = 0
checkButton.Text = "CHECK KEY"
checkButton.TextColor3 = Color3.fromRGB(0, 0, 0)
checkButton.Font = Enum.Font.GothamBold
checkButton.TextSize = 14
checkButton.Parent = keyPanel

local checkCorner = Instance.new("UICorner")
checkCorner.CornerRadius = UDim.new(0, 8)
checkCorner.Parent = checkButton

local keyStatus = Instance.new("TextLabel")
keyStatus.Position = UDim2.fromOffset(45, 215)
keyStatus.Size = UDim2.new(1, -90, 0, 25)
keyStatus.BackgroundTransparency = 1
keyStatus.Text = ""
keyStatus.Font = Enum.Font.Gotham
keyStatus.TextSize = 13
keyStatus.Parent = keyPanel

local keyDiscord = Instance.new("TextLabel")
keyDiscord.Position = UDim2.fromOffset(45, 250)
keyDiscord.Size = UDim2.new(1, -90, 0, 20)
keyDiscord.BackgroundTransparency = 1
keyDiscord.Text = "discord.gg/NGQu84rQNr"
keyDiscord.TextColor3 = Color3.fromRGB(100, 100, 100)
keyDiscord.Font = Enum.Font.Gotham
keyDiscord.TextSize = 12
keyDiscord.Parent = keyPanel

local function createMainGui()
	keyGui:Destroy()

	local gui = Instance.new("ScreenGui")
	gui.Name = "ControlMenu"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 9999
	gui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -15)
	frame.Size = UDim2.fromOffset(390, 205)
	frame.BackgroundTransparency = 1
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromOffset(10, 0)
	title.Size = UDim2.new(1, -20, 0, 25)
	title.BackgroundTransparency = 1
	title.Text = "crys cheats"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.Parent = frame

	local function createLabel(text, y)
		local label = Instance.new("TextLabel")
		label.Position = UDim2.fromOffset(10, y)
		label.Size = UDim2.fromOffset(180, 22)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = frame
		return label
	end

	local aimLabel = createLabel(
		"aim = " .. Settings.Keybinds.Aim.Name,
		32
	)

	local espLabel = createLabel(
		"esp = " .. Settings.Keybinds.ESP.Name,
		57
	)

	local speedLabel = createLabel(
		"speed walk = " .. Settings.Keybinds.Speed.Name,
		82
	)

	local jumpLabel = createLabel(
		"jump power = " .. Settings.Keybinds.Jump.Name,
		107
	)

	local panicLabel = createLabel(
		"panic ground = " .. Settings.Keybinds.PanicGround.Name,
		132
	)

	local function setState(label, enabled)
		label.TextColor3 = enabled
			and Color3.fromRGB(80, 255, 120)
			or Color3.fromRGB(255, 255, 255)
	end

	local function makeSmallButton(text, x, y)
		local button = Instance.new("TextButton")
		button.Position = UDim2.fromOffset(x, y)
		button.Size = UDim2.fromOffset(22, 22)
		button.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
		button.BorderSizePixel = 0
		button.Text = text
		button.TextColor3 = Color3.fromRGB(220, 220, 220)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 13
		button.Parent = frame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = button

		return button
	end

	local espMin = makeSmallButton("−", 275, 57)
	local speedMin = makeSmallButton("−", 275, 82)
	local jumpMin = makeSmallButton("−", 275, 107)

	local colorButton = makeSmallButton("", 305, 57)
	colorButton.BackgroundColor3 = Settings.ESP.Color

	local function createSlider(y, minimum, maximum, value, callback)
		local slider = Instance.new("Frame")
		slider.Position = UDim2.fromOffset(145, y + 8)
		slider.Size = UDim2.fromOffset(120, 4)
		slider.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		slider.BorderSizePixel = 0
		slider.Visible = false
		slider.Active = true
		slider.Parent = frame

		local fill = Instance.new("Frame")
		fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		fill.BorderSizePixel = 0
		fill.Parent = slider

		local knob = Instance.new("Frame")
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.Size = UDim2.fromOffset(10, 10)
		knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		knob.BorderSizePixel = 0
		knob.Parent = slider

		local percent = (value - minimum) / (maximum - minimum)

		fill.Size = UDim2.fromScale(percent, 1)
		knob.Position = UDim2.new(percent, 0, 0.5, 0)

		local dragging = false

		local function update(x)
			local p = math.clamp(
				(x - slider.AbsolutePosition.X) /
				slider.AbsoluteSize.X,
				0,
				1
			)

			local newValue = math.floor(
				minimum + (maximum - minimum) * p + 0.5
			)

			fill.Size = UDim2.fromScale(p, 1)
			knob.Position = UDim2.new(p, 0, 0.5, 0)

			callback(newValue)
		end

		connect(slider.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				update(input.Position.X)
			end
		end)

		connect(UserInputService.InputChanged, function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				update(input.Position.X)
			end
		end)

		connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)

		return slider
	end

	local speedValueLabel = Instance.new("TextLabel")
	speedValueLabel.Position = UDim2.fromOffset(270, 77)
	speedValueLabel.Size = UDim2.fromOffset(45, 20)
	speedValueLabel.BackgroundTransparency = 1
	speedValueLabel.Text = tostring(Settings.Speed.Value)
	speedValueLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	speedValueLabel.Font = Enum.Font.Gotham
	speedValueLabel.TextSize = 11
	speedValueLabel.Visible = false
	speedValueLabel.Parent = frame

	local jumpValueLabel = Instance.new("TextLabel")
	jumpValueLabel.Position = UDim2.fromOffset(270, 102)
	jumpValueLabel.Size = UDim2.fromOffset(45, 20)
	jumpValueLabel.BackgroundTransparency = 1
	jumpValueLabel.Text = tostring(Settings.Jump.Value)
	jumpValueLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	jumpValueLabel.Font = Enum.Font.Gotham
	jumpValueLabel.TextSize = 11
	jumpValueLabel.Visible = false
	jumpValueLabel.Parent = frame

	local speedSlider = createSlider(
		82,
		Settings.Speed.Minimum,
		Settings.Speed.Maximum,
		Settings.Speed.Value,
		function(value)
			Settings.Speed.Value = value
			speedValueLabel.Text = tostring(value)

			if speedEnabled then
				local hum = getHumanoid()

				if hum then
					hum.WalkSpeed = value
				end
			end
		end
	)

	local jumpSlider = createSlider(
		107,
		Settings.Jump.Minimum,
		Settings.Jump.Maximum,
		Settings.Jump.Value,
		function(value)
			Settings.Jump.Value = value
			jumpValueLabel.Text = tostring(value)

			if jumpEnabled then
				local hum = getHumanoid()

				if hum then
					hum.JumpPower = value
				end
			end
		end
	)

	local picker = Instance.new("Frame")
	picker.Position = UDim2.fromOffset(90, -105)
	picker.Size = UDim2.fromOffset(210, 130)
	picker.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
	picker.BorderSizePixel = 0
	picker.Visible = false
	picker.Parent = frame

	local pickerCorner = Instance.new("UICorner")
	pickerCorner.CornerRadius = UDim.new(0, 8)
	pickerCorner.Parent = picker

	local pickerTitle = Instance.new("TextLabel")
	picker.Position = UDim2.fromOffset(10, 8)
	picker.Size = UDim2.new(1, -20, 0, 20)
	picker.BackgroundTransparency = 1
	picker.Text = "ESP COLOR"
	picker.TextColor3 = Color3.fromRGB(255, 255, 255)
	picker.Font = Enum.Font.GothamBold
	picker.TextSize = 12
	picker.TextXAlignment = Enum.TextXAlignment.Left
	picker.Parent = picker

	local boxes = {}

	local function createRGBBox(letter, value, y)
		local label = Instance.new("TextLabel")
		label.Position = UDim2.fromOffset(10, y)
		label.Size = UDim2.fromOffset(20, 20)
		label.BackgroundTransparency = 1
		label.Text = letter
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 11
		label.Parent = picker

		local box = Instance.new("TextBox")
		box.Position = UDim2.fromOffset(35, y)
		box.Size = UDim2.fromOffset(155, 20)
		box.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
		box.BorderSizePixel = 0
		box.Text = tostring(value)
		box.TextColor3 = Color3.fromRGB(255, 255, 255)
		box.Font = Enum.Font.Gotham
		box.TextSize = 11
		box.ClearTextOnFocus = false
		box.Parent = picker

		boxes[letter] = box
	end

	createRGBBox("R", 255, 34)
	createRGBBox("G", 60, 59)
	createRGBBox("B", 60, 84)

	local function updateColor()
		local r = math.clamp(tonumber(boxes.R.Text) or 255, 0, 255)
		local g = math.clamp(tonumber(boxes.G.Text) or 60, 0, 255)
		local b = math.clamp(tonumber(boxes.B.Text) or 60, 0, 255)

		Settings.ESP.Color = Color3.fromRGB(r, g, b)
		colorButton.BackgroundColor3 = Settings.ESP.Color

		if espEnabled then
			refreshESP()
		end
	end

	connect(boxes.R.FocusLost, updateColor)
	connect(boxes.G.FocusLost, updateColor)
	connect(boxes.B.FocusLost, updateColor)

	connect(colorButton.MouseButton1Click, function()
		picker.Visible = not picker.Visible
	end)

	connect(espMin.MouseButton1Click, function()
		espExpanded = not espExpanded
		espMin.Text = espExpanded and "−" or "+"

		colorButton.Visible = espEnabled and espExpanded

		if not espExpanded then
			picker.Visible = false
		end
	end)

	connect(speedMin.MouseButton1Click, function()
		speedExpanded = not speedExpanded
		speedMin.Text = speedExpanded and "−" or "+"

		speedSlider.Visible = speedEnabled and speedExpanded
		speedValueLabel.Visible = speedEnabled and speedExpanded
	end)

	connect(jumpMin.MouseButton1Click, function()
		jumpExpanded = not jumpExpanded
		jumpMin.Text = jumpExpanded and "−" or "+"

		jumpSlider.Visible = jumpEnabled and jumpExpanded
		jumpValueLabel.Visible = jumpEnabled and jumpExpanded
	end)

	connect(UserInputService.InputBegan, function(input, gameProcessed)
		if destroyed or gameProcessed then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			fireWeapon()
			return
		end

		if input.KeyCode == Settings.Keybinds.Aim then
			toggleAim()

		elseif input.KeyCode == Settings.Keybinds.ESP then
			espEnabled = not espEnabled
			setState(espLabel, espEnabled)

			colorButton.Visible = espEnabled and espExpanded
			espMin.Visible = espEnabled

			if espEnabled then
				refreshESP()
			else
				picker.Visible = false

				for character in pairs(espObjects) do
					destroyESP(character)
				end
			end

		elseif input.KeyCode == Settings.Keybinds.Speed then
			speedEnabled = not speedEnabled
			setState(speedLabel, speedEnabled)

			speedSlider.Visible = speedEnabled and speedExpanded
			speedValueLabel.Visible = speedEnabled and speedExpanded

			local hum = getHumanoid()

			if hum then
				hum.WalkSpeed = speedEnabled
					and Settings.Speed.Value
					or originalWalkSpeed
			end

		elseif input.KeyCode == Settings.Keybinds.Jump then
			jumpEnabled = not jumpEnabled
			setState(jumpLabel, jumpEnabled)

			jumpSlider.Visible = jumpEnabled and jumpExpanded
			jumpValueLabel.Visible = jumpEnabled and jumpExpanded

			local hum = getHumanoid()

			if hum then
				hum.JumpPower = jumpEnabled
					and Settings.Jump.Value
					or originalJumpPower
			end

		elseif input.KeyCode == Settings.Keybinds.PanicGround then
			local rootPart = getRoot()

			if rootPart then
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = {
					getCharacter()
				}

				local result = workspace:Raycast(
					rootPart.Position,
					Vector3.new(0, -10000, 0),
					params
				)

				if result then
					getCharacter():PivotTo(
						CFrame.new(
							result.Position + Vector3.new(0, 4, 0)
						)
					)

					rootPart.AssemblyLinearVelocity = Vector3.zero
					rootPart.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end
	end)

	connect(player.CharacterAdded, function(character)
		task.wait(0.5)

		local hum = getHumanoid(character)

		if hum then
			if speedEnabled then
				hum.WalkSpeed = Settings.Speed.Value
			end

			if jumpEnabled then
				hum.JumpPower = Settings.Jump.Value
			end
		end
	end)

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			connect(otherPlayer.CharacterAdded, function()
				task.wait(0.5)

				if espEnabled then
					createESP(otherPlayer)
				end
			end)
		end
	end

	connect(Players.PlayerAdded, function(otherPlayer)
		connect(otherPlayer.CharacterAdded, function()
			task.wait(0.5)

			if espEnabled then
				createESP(otherPlayer)
			end
		end)
	end)

	connect(Players.PlayerRemoving, function(otherPlayer)
		if target == otherPlayer then
			target = nil
		end
	end)

	connect(UserInputService.InputBegan, function(input)
		if input.KeyCode ~= Enum.KeyCode.F8 or destroyed then
			return
		end

		destroyed = true
		aimEnabled = false
		espEnabled = false
		speedEnabled = false
		jumpEnabled = false
		target = nil

		pcall(function()
			RunService:UnbindFromRenderStep("CrysCamlock")
		end)

		for character in pairs(espObjects) do
			destroyESP(character)
		end

		for _, connection in ipairs(connections) do
			pcall(function()
				connection:Disconnect()
			end)
		end

		local hum = getHumanoid()

		if hum then
			hum.WalkSpeed = originalWalkSpeed
			hum.JumpPower = originalJumpPower
		end

		if gui and gui.Parent then
			gui:Destroy()
		end
	end)

	RunService:BindToRenderStep(
		"CrysCamlock",
		Enum.RenderPriority.Camera.Value + 1,
		function()
			if destroyed or not aimEnabled or not Settings.Aim.Camlock then
				return
			end

			if not target or not validCharacter(target.Character) then
				target = getClosestTarget()
			end

			if not target then
				return
			end

			local targetRoot =
				target.Character:FindFirstChild("HumanoidRootPart")
				or target.Character:FindFirstChild("Head")

			local camera = workspace.CurrentCamera

			if targetRoot and camera then
				camera.CFrame = CFrame.lookAt(
					camera.CFrame.Position,
					targetRoot.Position
				)
			end
		end
	)

	setState(aimLabel, false)
	setState(espLabel, false)
	setState(speedLabel, false)
	setState(jumpLabel, false)

	espMin.Visible = false
	speedMin.Visible = false
	jumpMin.Visible = false
	colorButton.Visible = false

	return gui
end

connect(checkButton.MouseButton1Click, function()
	if keyBox.Text ~= Settings.Key then
		keyStatus.Text = "Invalid key."
		keyStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
		return
	end

	keyStatus.Text = "Key accepted!"
	keyStatus.TextColor3 = Color3.fromRGB(80, 255, 120)

	task.wait(0.4)

	if not destroyed then
		createMainGui()
	end
end)
