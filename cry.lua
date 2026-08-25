local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local VALID_KEY = "cry"

local destroyed = false
local camlockEnabled = false
local espEnabled = false
local speedEnabled = false
local jumpEnabled = false
local target = nil

local connections = {}
local espObjects = {}
local nameObjects = {}

local originalWalkSpeed = 16
local originalJumpPower = 50

local speedValue = 32
local jumpValue = 100
local espColor = Color3.fromRGB(255, 60, 60)

local espExpanded = true
local speedExpanded = true
local jumpExpanded = true

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local function getHumanoid()
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
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

local function shutdown()
	if destroyed then
		return
	end

	destroyed = true
	camlockEnabled = false
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

	for character in pairs(nameObjects) do
		destroyESP(character)
	end

	local humanoid = getHumanoid()

	if humanoid then
		humanoid.WalkSpeed = originalWalkSpeed
		humanoid.JumpPower = originalJumpPower
	end

	for _, connection in ipairs(connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end

	table.clear(connections)
	table.clear(espObjects)
	table.clear(nameObjects)

	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui.Name == "LoadingScreen"
			or gui.Name == "KeySystem"
			or gui.Name == "ControlMenu" then
			gui:Destroy()
		end
	end
end

connect(UserInputService.InputBegan, function(input)
	if input.KeyCode == Enum.KeyCode.F8 then
		shutdown()
	end
end)

local loadingGui = Instance.new("ScreenGui")
loadingGui.Name = "LoadingScreen"
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

local container = Instance.new("Frame")
container.AnchorPoint = Vector2.new(0.5, 0.5)
container.Position = UDim2.fromScale(0.5, 0.53)
container.Size = UDim2.fromOffset(420, 230)
container.BackgroundTransparency = 1
container.Parent = background

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.fromScale(0.5, 0)
title.Size = UDim2.fromOffset(420, 50)
title.BackgroundTransparency = 1
title.Text = "LOADING"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 30
title.Parent = container

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.fromScale(0.5, 0.30)
status.Size = UDim2.fromOffset(420, 35)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(210, 210, 210)
status.Font = Enum.Font.Gotham
status.TextSize = 17
status.Parent = container

local barBackground = Instance.new("Frame")
barBackground.AnchorPoint = Vector2.new(0.5, 0)
barBackground.Position = UDim2.fromScale(0.5, 0.52)
barBackground.Size = UDim2.fromOffset(300, 4)
barBackground.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
barBackground.BackgroundTransparency = 0.25
barBackground.BorderSizePixel = 0
barBackground.Parent = container

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = barBackground

local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(0, 1)
bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
bar.BorderSizePixel = 0
bar.Parent = barBackground

local barCorner2 = Instance.new("UICorner")
barCorner2.CornerRadius = UDim.new(1, 0)
barCorner2.Parent = bar

local discord = Instance.new("TextLabel")
discord.AnchorPoint = Vector2.new(0.5, 0)
discord.Position = UDim2.fromScale(0.5, 0.68)
discord.Size = UDim2.fromOffset(420, 30)
discord.BackgroundTransparency = 1
discord.Text = "discord.gg/NGQu84rQNr"
discord.TextColor3 = Color3.fromRGB(150, 150, 150)
discord.Font = Enum.Font.GothamMedium
discord.TextSize = 14
discord.Parent = container

TweenService:Create(
	container,
	TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	{Position = UDim2.fromScale(0.5, 0.5)}
):Play()

local messages = {
	"loading storage",
	"loading scripts",
	"loading cheats"
}

for i, message in ipairs(messages) do
	status.Text = message
	status.TextTransparency = 1

	local textIn = TweenService:Create(
		status,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	)

	textIn:Play()
	textIn.Completed:Wait()

	local progress = TweenService:Create(
		bar,
		TweenInfo.new(1.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{Size = UDim2.fromScale(i / #messages, 1)}
	)

	progress:Play()
	progress.Completed:Wait()

	if i < #messages then
		local textOut = TweenService:Create(
			status,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{TextTransparency = 1}
		)

		textOut:Play()
		textOut.Completed:Wait()
	end
end

task.wait(0.4)

local fadeInfo = TweenInfo.new(
	1.2,
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out
)

TweenService:Create(background, fadeInfo, {
	BackgroundTransparency = 1
}):Play()

TweenService:Create(title, fadeInfo, {
	TextTransparency = 1
}):Play()

TweenService:Create(status, fadeInfo, {
	TextTransparency = 1
}):Play()

TweenService:Create(discord, fadeInfo, {
	TextTransparency = 1
}):Play()

TweenService:Create(barBackground, fadeInfo, {
	BackgroundTransparency = 1
}):Play()

TweenService:Create(bar, fadeInfo, {
	BackgroundTransparency = 1
}):Play()

task.wait(1.3)
loadingGui:Destroy()

local keyGui = Instance.new("ScreenGui")
keyGui.Name = "KeySystem"
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

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.55)
panel.Size = UDim2.fromOffset(430, 300)
panel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
panel.BackgroundTransparency = 1
panel.BorderSizePixel = 0
panel.Parent = keyBackground

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(30, 30, 30)
panelStroke.Thickness = 1
panelStroke.Transparency = 1
panelStroke.Parent = panel

local keyTitle = Instance.new("TextLabel")
keyTitle.AnchorPoint = Vector2.new(0.5, 0)
keyTitle.Position = UDim2.fromScale(0.5, 0.08)
keyTitle.Size = UDim2.fromOffset(380, 40)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "KEY SYSTEM"
keyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
keyTitle.TextTransparency = 1
keyTitle.Font = Enum.Font.GothamBold
keyTitle.TextSize = 26
keyTitle.Parent = panel

local description = Instance.new("TextLabel")
description.AnchorPoint = Vector2.new(0.5, 0)
description.Position = UDim2.fromScale(0.5, 0.23)
description.Size = UDim2.fromOffset(360, 35)
description.BackgroundTransparency = 1
description.Text = "Enter your key below to continue."
description.TextColor3 = Color3.fromRGB(140, 140, 140)
description.TextTransparency = 1
description.Font = Enum.Font.Gotham
description.TextSize = 14
description.Parent = panel

local keyBox = Instance.new("TextBox")
keyBox.AnchorPoint = Vector2.new(0.5, 0)
keyBox.Position = UDim2.fromScale(0.5, 0.39)
keyBox.Size = UDim2.fromOffset(340, 45)
keyBox.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
keyBox.BackgroundTransparency = 1
keyBox.BorderSizePixel = 0
keyBox.PlaceholderText = "Enter key..."
keyBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
keyBox.Text = ""
keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
keyBox.Font = Enum.Font.Gotham
keyBox.TextSize = 14
keyBox.ClearTextOnFocus = false
keyBox.Parent = panel

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 8)
boxCorner.Parent = keyBox

local boxStroke = Instance.new("UIStroke")
boxStroke.Color = Color3.fromRGB(35, 35, 35)
boxStroke.Thickness = 1
boxStroke.Transparency = 1
boxStroke.Parent = keyBox

local checkButton = Instance.new("TextButton")
checkButton.AnchorPoint = Vector2.new(0.5, 0)
checkButton.Position = UDim2.fromScale(0.5, 0.58)
checkButton.Size = UDim2.fromOffset(340, 45)
checkButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
checkButton.BackgroundTransparency = 1
checkButton.BorderSizePixel = 0
checkButton.Text = "CHECK KEY"
checkButton.TextColor3 = Color3.fromRGB(0, 0, 0)
checkButton.TextTransparency = 1
checkButton.Font = Enum.Font.GothamBold
checkButton.TextSize = 14
checkButton.Parent = panel

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = checkButton

local keyStatus = Instance.new("TextLabel")
keyStatus.AnchorPoint = Vector2.new(0.5, 0)
keyStatus.Position = UDim2.fromScale(0.5, 0.76)
keyStatus.Size = UDim2.fromOffset(340, 25)
keyStatus.BackgroundTransparency = 1
keyStatus.Text = ""
keyStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
keyStatus.Font = Enum.Font.Gotham
keyStatus.TextSize = 13
keyStatus.Parent = panel

local keyDiscord = Instance.new("TextLabel")
keyDiscord.AnchorPoint = Vector2.new(0.5, 0)
keyDiscord.Position = UDim2.fromScale(0.5, 0.88)
keyDiscord.Size = UDim2.fromOffset(340, 25)
keyDiscord.BackgroundTransparency = 1
keyDiscord.Text = "discord.gg/NGQu84rQNr"
keyDiscord.TextColor3 = Color3.fromRGB(100, 100, 100)
keyDiscord.TextTransparency = 1
keyDiscord.Font = Enum.Font.Gotham
keyDiscord.TextSize = 12
keyDiscord.Parent = panel

TweenService:Create(
	panel,
	TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	{
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 0
	}
):Play()

TweenService:Create(panelStroke, TweenInfo.new(0.6), {
	Transparency = 0.15
}):Play()

TweenService:Create(keyTitle, TweenInfo.new(0.5), {
	TextTransparency = 0
}):Play()

TweenService:Create(description, TweenInfo.new(0.6), {
	TextTransparency = 0
}):Play()

TweenService:Create(keyBox, TweenInfo.new(0.6), {
	BackgroundTransparency = 0
}):Play()

TweenService:Create(boxStroke, TweenInfo.new(0.6), {
	Transparency = 0
}):Play()

TweenService:Create(checkButton, TweenInfo.new(0.6), {
	BackgroundTransparency = 0,
	TextTransparency = 0
}):Play()

TweenService:Create(keyDiscord, TweenInfo.new(0.7), {
	TextTransparency = 0
}):Play()

connect(checkButton.MouseEnter, function()
	TweenService:Create(
		checkButton,
		TweenInfo.new(0.2),
		{BackgroundColor3 = Color3.fromRGB(220, 220, 220)}
	):Play()
end)

connect(checkButton.MouseLeave, function()
	TweenService:Create(
		checkButton,
		TweenInfo.new(0.2),
		{BackgroundColor3 = Color3.fromRGB(255, 255, 255)}
	):Play()
end)

connect(checkButton.MouseButton1Click, function()
	local enteredKey = keyBox.Text

	if enteredKey == "" then
		keyStatus.Text = "Please enter a key."
		keyStatus.TextColor3 = Color3.fromRGB(255, 90, 90)
		return
	end

	keyStatus.Text = "Checking key..."
	keyStatus.TextColor3 = Color3.fromRGB(180, 180, 180)
	checkButton.Active = false

	task.wait(0.7)

	if enteredKey ~= VALID_KEY then
		keyStatus.Text = "Invalid key."
		keyStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
		checkButton.Active = true
		return
	end

	keyStatus.Text = "Key accepted!"
	keyStatus.TextColor3 = Color3.fromRGB(100, 255, 140)

	task.wait(0.5)

	keyGui:Destroy()

	local controlGui = Instance.new("ScreenGui")
	controlGui.Name = "ControlMenu"
	controlGui.IgnoreGuiInset = true
	controlGui.ResetOnSpawn = false
	controlGui.DisplayOrder = 9999
	controlGui.Parent = playerGui

	local controlFrame = Instance.new("Frame")
	controlFrame.AnchorPoint = Vector2.new(0.5, 1)
	controlFrame.Position = UDim2.new(0.5, 0, 1, -15)
	controlFrame.Size = UDim2.fromOffset(350, 180)
	controlFrame.BackgroundTransparency = 1
	controlFrame.BorderSizePixel = 0
	controlFrame.Parent = controlGui

	local menuTitle = Instance.new("TextLabel")
	menuTitle.Size = UDim2.new(1, 0, 0, 25)
	menuTitle.BackgroundTransparency = 1
	menuTitle.Text = "crys cheats"
	menuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	menuTitle.Font = Enum.Font.GothamBold
	menuTitle.TextSize = 15
	menuTitle.Parent = controlFrame

	local function createControl(name, key, y)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromOffset(170, 20)
		label.Position = UDim2.new(0, 10, 0, y)
		label.BackgroundTransparency = 1
		label.Text = name .. " = " .. key
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = controlFrame
		return label
	end

	local camlockLabel = createControl("camlock", "Q", 30)
	local espLabel = createControl("esp", "E", 54)
	local speedLabel = createControl("speed walk", "V", 78)
	local jumpLabel = createControl("jump power", "B", 102)
	local panicLabel = createControl("panic ground", "G", 126)

	local function setState(label, enabled)
		label.TextColor3 = enabled
			and Color3.fromRGB(80, 255, 120)
			or Color3.fromRGB(255, 255, 255)
	end

	local function makeButton(text, x, y)
		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(22, 22)
		button.Position = UDim2.new(1, x, 0, y)
		button.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
		button.BorderSizePixel = 0
		button.Text = text
		button.TextColor3 = Color3.fromRGB(220, 220, 220)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 13
		button.Visible = false
		button.Parent = controlFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = button

		return button
	end

	local colorButton = makeButton("", -48, 53)
	colorButton.BackgroundColor3 = espColor

	local colorStroke = Instance.new("UIStroke")
	colorStroke.Color = Color3.fromRGB(255, 255, 255)
	colorStroke.Transparency = 0.5
	colorStroke.Parent = colorButton

	local espMin = makeButton("−", -75, 53)
	local speedMin = makeButton("−", -75, 77)
	local jumpMin = makeButton("−", -75, 101)

	local function createSlider(y, minimum, maximum, initial, callback)
		local slider = Instance.new("Frame")
		slider.Size = UDim2.fromOffset(120, 4)
		slider.Position = UDim2.new(1, -165, 0, y + 8)
		slider.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		slider.BorderSizePixel = 0
		slider.Visible = false
		slider.Active = true
		slider.Parent = controlFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = slider

		local fill = Instance.new("Frame")
		local initialPosition = (initial - minimum) / (maximum - minimum)

		fill.Size = UDim2.fromScale(initialPosition, 1)
		fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		fill.BorderSizePixel = 0
		fill.Parent = slider

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = fill

		local knob = Instance.new("Frame")
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.Size = UDim2.fromOffset(10, 10)
		knob.Position = UDim2.new(initialPosition, 0, 0.5, 0)
		knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		knob.BorderSizePixel = 0
		knob.Parent = slider

		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = UDim.new(1, 0)
		knobCorner.Parent = knob

		local dragging = false

		local function update(x)
			local percent = math.clamp(
				(x - slider.AbsolutePosition.X) / slider.AbsoluteSize.X,
				0,
				1
			)

			local value = math.floor(
				minimum + (maximum - minimum) * percent + 0.5
			)

			fill.Size = UDim2.fromScale(percent, 1)
			knob.Position = UDim2.new(percent, 0, 0.5, 0)

			callback(value)
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
	speedValueLabel.Size = UDim2.fromOffset(40, 20)
	speedValueLabel.Position = UDim2.new(1, -43, 0, 69)
	speedValueLabel.BackgroundTransparency = 1
	speedValueLabel.Text = tostring(speedValue)
	speedValueLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	speedValueLabel.Font = Enum.Font.Gotham
	speedValueLabel.TextSize = 11
	speedValueLabel.Visible = false
	speedValueLabel.Parent = controlFrame

	local jumpValueLabel = Instance.new("TextLabel")
	jumpValueLabel.Size = UDim2.fromOffset(40, 20)
	jumpValueLabel.Position = UDim2.new(1, -43, 0, 93)
	jumpValueLabel.BackgroundTransparency = 1
	jumpValueLabel.Text = tostring(jumpValue)
	jumpValueLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	jumpValueLabel.Font = Enum.Font.Gotham
	jumpValueLabel.TextSize = 11
	jumpValueLabel.Visible = false
	jumpValueLabel.Parent = controlFrame

	local speedSlider = createSlider(78, 16, 100, speedValue, function(value)
		speedValue = value
		speedValueLabel.Text = tostring(value)

		if speedEnabled then
			local humanoid = getHumanoid()
			if humanoid then
				humanoid.WalkSpeed = value
			end
		end
	end)

	local jumpSlider = createSlider(102, 50, 150, jumpValue, function(value)
		jumpValue = value
		jumpValueLabel.Text = tostring(value)

		if jumpEnabled then
			local humanoid = getHumanoid()
			if humanoid then
				humanoid.JumpPower = value
			end
		end
	end)

	local picker = Instance.new("Frame")
	picker.Size = UDim2.fromOffset(210, 125)
	picker.Position = UDim2.new(1, -265, 0, -100)
	picker.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
	picker.BorderSizePixel = 0
	picker.Visible = false
	picker.Parent = controlFrame

	local pickerCorner = Instance.new("UICorner")
	pickerCorner.CornerRadius = UDim.new(0, 8)
	pickerCorner.Parent = picker

	local pickerStroke = Instance.new("UIStroke")
	pickerStroke.Color = Color3.fromRGB(35, 35, 35)
	pickerStroke.Parent = picker

	local pickerTitle = Instance.new("TextLabel")
	pickerTitle.Size = UDim2.new(1, -20, 0, 25)
	pickerTitle.Position = UDim2.fromOffset(10, 5)
	pickerTitle.BackgroundTransparency = 1
	pickerTitle.Text = "ESP COLOR"
	pickerTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	pickerTitle.Font = Enum.Font.GothamBold
	pickerTitle.TextSize = 12
	pickerTitle.TextXAlignment = Enum.TextXAlignment.Left
	pickerTitle.Parent = picker

	local function rgbBox(letter, value, y)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromOffset(20, 22)
		label.Position = UDim2.fromOffset(10, y)
		label.BackgroundTransparency = 1
		label.Text = letter
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 11
		label.Parent = picker

		local box = Instance.new("TextBox")
		box.Size = UDim2.fromOffset(155, 22)
		box.Position = UDim2.fromOffset(35, y)
		box.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
		box.BorderSizePixel = 0
		box.Text = tostring(value)
		box.TextColor3 = Color3.fromRGB(255, 255, 255)
		box.Font = Enum.Font.Gotham
		box.TextSize = 11
		box.ClearTextOnFocus = false
		box.Parent = picker

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = box

		return box
	end

	local redBox = rgbBox("R", 255, 32)
	local greenBox = rgbBox("G", 60, 60)
	local blueBox = rgbBox("B", 60, 88)

	local function updateESPColor()
		local r = math.clamp(tonumber(redBox.Text) or 255, 0, 255)
		local g = math.clamp(tonumber(greenBox.Text) or 60, 0, 255)
		local b = math.clamp(tonumber(blueBox.Text) or 60, 0, 255)

		espColor = Color3.fromRGB(r, g, b)
		colorButton.BackgroundColor3 = espColor

		if espEnabled then
			for character in pairs(espObjects) do
				destroyESP(character)
			end

			for _, otherPlayer in ipairs(Players:GetPlayers()) do
				if otherPlayer ~= player then
					createESP(otherPlayer)
				end
			end
		end
	end

	connect(redBox.FocusLost, updateESPColor)
	connect(greenBox.FocusLost, updateESPColor)
	connect(blueBox.FocusLost, updateESPColor)

	connect(colorButton.MouseButton1Click, function()
		picker.Visible = not picker.Visible
	end)

	local function validCharacter(character)
		if not character then
			return false
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")

		return humanoid and humanoid.Health > 0
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
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				local box = Instance.new("BoxHandleAdornment")
				box.Name = "CrysHitbox"
				box.Adornee = part
				box.Size = part.Size
				box.Color3 = espColor
				box.Transparency = 0.7
				box.AlwaysOnTop = true
				box.ZIndex = 10
				box.Parent = part

				table.insert(objects, box)
			end
		end

		espObjects[character] = objects

		local head = character:FindFirstChild("Head")
			or character:FindFirstChild("HumanoidRootPart")

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

	local function getClosestToCrosshair()
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

				local root =
					character:FindFirstChild("HumanoidRootPart")
					or character:FindFirstChild("Head")

				if root then
					local position, visible =
						camera:WorldToViewportPoint(root.Position)

					if visible and position.Z > 0 then
						local screenPosition = Vector2.new(
							position.X,
							position.Y
						)

						local distance =
							(screenPosition - center).Magnitude

						if distance < closestDistance then
							closestDistance = distance
							closestPlayer = otherPlayer
						end
					end
				end
			end
		end

		return closestPlayer
	end

	local function toggleCamlock()
		camlockEnabled = not camlockEnabled

		if camlockEnabled then
			target = getClosestToCrosshair()

			if target then
				setState(camlockLabel, true)
			else
				camlockEnabled = false
				setState(camlockLabel, false)
			end
		else
			target = nil
			setState(camlockLabel, false)
		end
	end

	local function toggleESP()
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
	end

	local function toggleSpeed()
		speedEnabled = not speedEnabled
		setState(speedLabel, speedEnabled)

		speedSlider.Visible = speedEnabled and speedExpanded
		speedValueLabel.Visible = speedEnabled and speedExpanded
		speedMin.Visible = speedEnabled

		local humanoid = getHumanoid()

		if humanoid then
			humanoid.WalkSpeed = speedEnabled
				and speedValue
				or originalWalkSpeed
		end
	end

	local function toggleJump()
		jumpEnabled = not jumpEnabled
		setState(jumpLabel, jumpEnabled)

		jumpSlider.Visible = jumpEnabled and jumpExpanded
		jumpValueLabel.Visible = jumpEnabled and jumpExpanded
		jumpMin.Visible = jumpEnabled

		local humanoid = getHumanoid()

		if humanoid then
			humanoid.JumpPower = jumpEnabled
				and jumpValue
				or originalJumpPower
		end
	end

	local function panicGround()
		local root = getRoot()

		if not root then
			return
		end

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {player.Character}

		local result = workspace:Raycast(
			root.Position,
			Vector3.new(0, -10000, 0),
			params
		)

		if result and player.Character then
			player.Character:PivotTo(
				CFrame.new(result.Position + Vector3.new(0, 4, 0))
			)

			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end

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

		if input.KeyCode == Enum.KeyCode.Q then
			toggleCamlock()
		elseif input.KeyCode == Enum.KeyCode.E then
			toggleESP()
		elseif input.KeyCode == Enum.KeyCode.V then
			toggleSpeed()
		elseif input.KeyCode == Enum.KeyCode.B then
			toggleJump()
		elseif input.KeyCode == Enum.KeyCode.G then
			panicGround()
		end
	end)

	connect(player.CharacterAdded, function()
		task.wait(0.5)

		local humanoid = getHumanoid()

		if humanoid then
			if speedEnabled then
				humanoid.WalkSpeed = speedValue
			end

			if jumpEnabled then
				humanoid.JumpPower = jumpValue
			end
		end
	end)

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

			if camlockEnabled then
				target = getClosestToCrosshair()

				if not target then
					camlockEnabled = false
					setState(camlockLabel, false)
				end
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

	RunService:BindToRenderStep(
		"CrysCamlock",
		Enum.RenderPriority.Camera.Value + 1,
		function()
			if destroyed or not camlockEnabled then
				return
			end

			if not target
				or not target.Character
				or not validCharacter(target.Character) then

				target = getClosestToCrosshair()
			end

			if not target then
				camlockEnabled = false
				setState(camlockLabel, false)
				return
			end

			local character = target.Character

			local root =
				character:FindFirstChild("HumanoidRootPart")
				or character:FindFirstChild("Head")

			local camera = workspace.CurrentCamera

			if root and camera then
				camera.CFrame = CFrame.lookAt(
					camera.CFrame.Position,
					root.Position
				)
			end
		end
	)

	TweenService:Create(
		controlFrame,
		TweenInfo.new(
			0.7,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		),
		{
			Position = UDim2.new(0.5, 0, 1, -15)
		}
	):Play()
end)
