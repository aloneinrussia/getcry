local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Config = {
	Key = "cry",

	Keybinds = {
		Camlock = Enum.KeyCode.Q,
		SilentAim = Enum.KeyCode.Q,
		ESP = Enum.KeyCode.E,
		Speed = Enum.KeyCode.V,
		Jump = Enum.KeyCode.B,
		PanicGround = Enum.KeyCode.G
	},

	Camlock = {
		Enabled = true,
		TargetPart = "HumanoidRootPart",
		Smoothness = 0.18,
		FOV = 250
	},

	SilentAim = {
		Enabled = true,
		TargetPart = "HumanoidRootPart",
		HitboxSize = Vector3.new(8, 8, 8),
		ShowHitbox = true,
		Transparency = 0.65
	},

	ESP = {
		Enabled = false,
		Color = Color3.fromRGB(255, 60, 60),
		Transparency = 0.7,
		ShowNames = true
	},

	Speed = {
		Enabled = false,
		Value = 32,
		Minimum = 16,
		Maximum = 100
	},

	Jump = {
		Enabled = false,
		Value = 100,
		Minimum = 50,
		Maximum = 150
	},

	PanicGround = {
		Offset = 4
	}
}

local destroyed = false
local camlockEnabled = false
local silentAimEnabled = false
local espEnabled = false
local speedEnabled = false
local jumpEnabled = false

local target = nil

local connections = {}
local hitboxObjects = {}
local espObjects = {}
local nameObjects = {}

local originalWalkSpeed = 16
local originalJumpPower = 50

local espExpanded = true
local speedExpanded = true
local jumpExpanded = true

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local function getCharacter()
	return Player.Character
end

local function getHumanoid()
	local character = getCharacter()
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local character = getCharacter()
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function validCharacter(character)
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	return humanoid and humanoid.Health > 0
end

local function getTargetPart(character, requested)
	if not character then
		return nil
	end

	return character:FindFirstChild(requested)
		or character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("Head")
end

local function destroyHitbox(character)
	local object = hitboxObjects[character]

	if object then
		pcall(function()
			object:Destroy()
		end)

		hitboxObjects[character] = nil
	end
end

local function destroyESP(character)
	if espObjects[character] then
		for _, object in ipairs(espObjects[character]) do
			if object then
				pcall(function()
					object:Destroy()
				end)
			end
		end

		espObjects[character] = nil
	end

	if nameObjects[character] then
		pcall(function()
			nameObjects[character]:Destroy()
		end)

		nameObjects[character] = nil
	end
end

local function createHitbox(otherPlayer)
	if not silentAimEnabled or otherPlayer == Player then
		return
	end

	local character = otherPlayer.Character

	if not validCharacter(character) then
		return
	end

	local targetPart = getTargetPart(
		character,
		Config.SilentAim.TargetPart
	)

	if not targetPart or not targetPart:IsA("BasePart") then
		return
	end

	destroyHitbox(character)

	local hitbox = Instance.new("Part")
	hitbox.Name = "CrysSilentAimHitbox"
	hitbox.Size = Config.SilentAim.HitboxSize
	hitbox.CFrame = targetPart.CFrame
	hitbox.Transparency = Config.SilentAim.ShowHitbox
		and Config.SilentAim.Transparency
		or 1
	hitbox.Color = Config.ESP.Color
	hitbox.Material = Enum.Material.ForceField
	hitbox.CanCollide = false
	hitbox.CanTouch = false
	hitbox.CanQuery = true
	hitbox.Massless = true
	hitbox.CastShadow = false
	hitbox.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hitbox
	weld.Part1 = targetPart
	weld.Parent = hitbox

	hitboxObjects[character] = hitbox
end

local function refreshHitboxes()
	for character in pairs(hitboxObjects) do
		destroyHitbox(character)
	end

	if not silentAimEnabled then
		return
	end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= Player then
			createHitbox(otherPlayer)
		end
	end
end

local function createESP(otherPlayer)
	if not espEnabled or otherPlayer == Player then
		return
	end

	local character = otherPlayer.Character

	if not validCharacter(character) then
		return
	end

	destroyESP(character)

	local objects = {}

	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local box = Instance.new("BoxHandleAdornment")
			box.Name = "CrysESP"
			box.Adornee = part
			box.Size = part.Size
			box.Color3 = Config.ESP.Color
			box.Transparency = Config.ESP.Transparency
			box.AlwaysOnTop = true
			box.ZIndex = 10
			box.Parent = part

			table.insert(objects, box)
		end
	end

	espObjects[character] = objects

	if Config.ESP.ShowNames then
		local head = character:FindFirstChild("Head")
			or character:FindFirstChild("HumanoidRootPart")

		if head then
			local billboard = Instance.new("BillboardGui")
			billboard.Name = "CrysName"
			billboard.Adornee = head
			billboard.Size = UDim2.fromOffset(200, 30)
			billboard.StudsOffset = Vector3.new(0, 3, 0)
			billboard.AlwaysOnTop = true
			billboard.Parent = PlayerGui

			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Text = otherPlayer.DisplayName
			label.TextColor3 = Config.ESP.Color
			label.TextStrokeColor3 = Color3.new(0, 0, 0)
			label.TextStrokeTransparency = 0
			label.Font = Enum.Font.GothamBold
			label.TextSize = 14
			label.Parent = billboard

			nameObjects[character] = billboard
		end
	end
end

local function refreshESP()
	for character in pairs(espObjects) do
		destroyESP(character)
	end

	for character in pairs(nameObjects) do
		destroyESP(character)
	end

	if not espEnabled then
		return
	end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= Player then
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
	local center = Vector2.new(
		viewport.X / 2,
		viewport.Y / 2
	)

	local closest = nil
	local closestDistance = Config.Camlock.FOV

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= Player then
			local character = otherPlayer.Character

			if validCharacter(character) then
				local part = getTargetPart(
					character,
					Config.Camlock.TargetPart
				)

				if part then
					local screenPosition, visible =
						camera:WorldToViewportPoint(part.Position)

					if visible and screenPosition.Z > 0 then
						local distance = (
							Vector2.new(
								screenPosition.X,
								screenPosition.Y
							) - center
						).Magnitude

						if distance < closestDistance then
							closestDistance = distance
							closest = otherPlayer
						end
					end
				end
			end
		end
	end

	return closest
end

local function toggleCamlock()
	camlockEnabled = not camlockEnabled

	if camlockEnabled then
		target = getClosestTarget()

		if not target then
			camlockEnabled = false
		end
	else
		target = nil
	end
end

local function toggleSilentAim()
	silentAimEnabled = not silentAimEnabled
	refreshHitboxes()
end

local function toggleESP()
	espEnabled = not espEnabled
	refreshESP()
end

local function toggleSpeed()
	speedEnabled = not speedEnabled

	local humanoid = getHumanoid()

	if humanoid then
		humanoid.WalkSpeed =
			speedEnabled
			and Config.Speed.Value
			or originalWalkSpeed
	end
end

local function toggleJump()
	jumpEnabled = not jumpEnabled

	local humanoid = getHumanoid()

	if humanoid then
		humanoid.JumpPower =
			jumpEnabled
			and Config.Jump.Value
			or originalJumpPower
	end
end

local function panicGround()
	local character = getCharacter()
	local root = getRoot()

	if not character or not root then
		return
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {character}

	local result = workspace:Raycast(
		root.Position,
		Vector3.new(0, -10000, 0),
		params
	)

	if result then
		character:PivotTo(
			CFrame.new(
				result.Position
					+ Vector3.new(
						0,
						Config.PanicGround.Offset,
						0
					)
			)
		)

		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
end

local function createGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "CrysCheats"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 9999
	gui.Parent = PlayerGui

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -15)
	frame.Size = UDim2.fromOffset(380, 220)
	frame.BackgroundTransparency = 1
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 28)
	title.BackgroundTransparency = 1
	title.Text = "crys cheats"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.Parent = frame

	local function makeLabel(text, y)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromOffset(180, 22)
		label.Position = UDim2.fromOffset(10, y)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = frame
		return label
	end

	local camlockLabel = makeLabel(
		"camlock = " .. Config.Keybinds.Camlock.Name,
		35
	)

	local silentLabel = makeLabel(
		"silent aim = " .. Config.Keybinds.SilentAim.Name,
		59
	)

	local espLabel = makeLabel(
		"esp = " .. Config.Keybinds.ESP.Name,
		83
	)

	local speedLabel = makeLabel(
		"speed walk = " .. Config.Keybinds.Speed.Name,
		107
	)

	local jumpLabel = makeLabel(
		"jump power = " .. Config.Keybinds.Jump.Name,
		131
	)

	local panicLabel = makeLabel(
		"panic ground = " .. Config.Keybinds.PanicGround.Name,
		155
	)

	local function setState(label, state)
		label.TextColor3 = state
			and Color3.fromRGB(80, 255, 120)
			or Color3.new(1, 1, 1)
	end

	local function makeMiniButton(text, y)
		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(22, 22)
		button.Position = UDim2.new(1, -28, 0, y)
		button.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
		button.BorderSizePixel = 0
		button.Text = text
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 13
		button.Parent = frame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = button

		return button
	end

	local espMin = makeMiniButton("−", 83)
	local speedMin = makeMiniButton("−", 107)
	local jumpMin = makeMiniButton("−", 131)

	local colorButton = makeMiniButton("", 83)
	colorButton.Position = UDim2.new(1, -55, 0, 83)
	colorButton.BackgroundColor3 = Config.ESP.Color

	local function makeSlider(y, config, callback)
		local slider = Instance.new("Frame")
		slider.Size = UDim2.fromOffset(120, 4)
		slider.Position = UDim2.new(1, -160, 0, y + 9)
		slider.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
		slider.BorderSizePixel = 0
		slider.Visible = false
		slider.Active = true
		slider.Parent = frame

		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(
			(config.Value - config.Minimum)
				/ (config.Maximum - config.Minimum),
			1
		)
		fill.BackgroundColor3 = Color3.new(1, 1, 1)
		fill.BorderSizePixel = 0
		fill.Parent = slider

		local knob = Instance.new("Frame")
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.Size = UDim2.fromOffset(10, 10)
		knob.Position = UDim2.new(
			(config.Value - config.Minimum)
				/ (config.Maximum - config.Minimum),
			0,
			0.5,
			0
		)
		knob.BackgroundColor3 = Color3.new(1, 1, 1)
		knob.BorderSizePixel = 0
		knob.Parent = slider

		local dragging = false

		local function update(x)
			local percent = math.clamp(
				(x - slider.AbsolutePosition.X)
					/ slider.AbsoluteSize.X,
				0,
				1
			)

			local value = math.floor(
				config.Minimum
					+ (config.Maximum - config.Minimum)
					* percent
					+ 0.5
			)

			config.Value = value
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
			if dragging
				and input.UserInputType
					== Enum.UserInputType.MouseMovement then
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

	local speedValue = Instance.new("TextLabel")
	speedValue.Size = UDim2.fromOffset(35, 20)
	speedValue.Position = UDim2.new(1, -40, 0, 102)
	speedValue.BackgroundTransparency = 1
	speedValue.Text = tostring(Config.Speed.Value)
	speedValue.TextColor3 = Color3.fromRGB(160, 160, 160)
	speedValue.Font = Enum.Font.Gotham
	speedValue.TextSize = 11
	speedValue.Visible = false
	speedValue.Parent = frame

	local jumpValue = Instance.new("TextLabel")
	jumpValue.Size = UDim2.fromOffset(35, 20)
	jumpValue.Position = UDim2.new(1, -40, 0, 126)
	jumpValue.BackgroundTransparency = 1
	jumpValue.Text = tostring(Config.Jump.Value)
	jumpValue.TextColor3 = Color3.fromRGB(160, 160, 160)
	jumpValue.Font = Enum.Font.Gotham
	jumpValue.TextSize = 11
	jumpValue.Visible = false
	jumpValue.Parent = frame

	local speedSlider = makeSlider(
		107,
		Config.Speed,
		function(value)
			speedValue.Text = tostring(value)

			if speedEnabled then
				local humanoid = getHumanoid()

				if humanoid then
					humanoid.WalkSpeed = value
				end
			end
		end
	)

	local jumpSlider = makeSlider(
		131,
		Config.Jump,
		function(value)
			jumpValue.Text = tostring(value)

			if jumpEnabled then
				local humanoid = getHumanoid()

				if humanoid then
					humanoid.JumpPower = value
				end
			end
		end
	)

	local colorPicker = Instance.new("Frame")
	colorPicker.Size = UDim2.fromOffset(210, 130)
	colorPicker.Position = UDim2.new(1, -265, 0, -105)
	colorPicker.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
	colorPicker.BorderSizePixel = 0
	colorPicker.Visible = false
	colorPicker.Parent = frame

	local pickerCorner = Instance.new("UICorner")
	pickerCorner.CornerRadius = UDim.new(0, 8)
	pickerCorner.Parent = colorPicker

	local pickerTitle = Instance.new("TextLabel")
	pickerTitle.Size = UDim2.new(1, -20, 0, 25)
	pickerTitle.Position = UDim2.fromOffset(10, 5)
	pickerTitle.BackgroundTransparency = 1
	pickerTitle.Text = "ESP / HITBOX COLOR"
	pickerTitle.TextColor3 = Color3.new(1, 1, 1)
	pickerTitle.Font = Enum.Font.GothamBold
	pickerTitle.TextSize = 12
	pickerTitle.TextXAlignment = Enum.TextXAlignment.Left
	pickerTitle.Parent = colorPicker

	local function createRGBBox(letter, value, y)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromOffset(20, 22)
		label.Position = UDim2.fromOffset(10, y)
		label.BackgroundTransparency = 1
		label.Text = letter
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 11
		label.Parent = colorPicker

		local box = Instance.new("TextBox")
		box.Size = UDim2.fromOffset(155, 22)
		box.Position = UDim2.fromOffset(35, y)
		box.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
		box.BorderSizePixel = 0
		box.Text = tostring(value)
		box.TextColor3 = Color3.new(1, 1, 1)
		box.Font = Enum.Font.Gotham
		box.TextSize = 11
		box.ClearTextOnFocus = false
		box.Parent = colorPicker

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = box

		return box
	end

	local redBox = createRGBBox("R", 255, 35)
	local greenBox = createRGBBox("G", 60, 63)
	local blueBox = createRGBBox("B", 60, 91)

	local function updateColor()
		local r = math.clamp(
			tonumber(redBox.Text) or 255,
			0,
			255
		)

		local g = math.clamp(
			tonumber(greenBox.Text) or 60,
			0,
			255
		)

		local b = math.clamp(
			tonumber(blueBox.Text) or 60,
			0,
			255
		)

		Config.ESP.Color = Color3.fromRGB(r, g, b)
		colorButton.BackgroundColor3 = Config.ESP.Color

		refreshESP()
		refreshHitboxes()
	end

	connect(redBox.FocusLost, updateColor)
	connect(greenBox.FocusLost, updateColor)
	connect(blueBox.FocusLost, updateColor)

	connect(colorButton.MouseButton1Click, function()
		colorPicker.Visible = not colorPicker.Visible
	end)

	connect(espMin.MouseButton1Click, function()
		espExpanded = not espExpanded
		espMin.Text = espExpanded and "−" or "+"

		colorButton.Visible =
			espEnabled and espExpanded

		if not espExpanded then
			colorPicker.Visible = false
		end
	end)

	connect(speedMin.MouseButton1Click, function()
		speedExpanded = not speedExpanded
		speedMin.Text = speedExpanded and "−" or "+"

		speedSlider.Visible =
			speedEnabled and speedExpanded

		speedValue.Visible =
			speedEnabled and speedExpanded
	end)

	connect(jumpMin.MouseButton1Click, function()
		jumpExpanded = not jumpExpanded
		jumpMin.Text = jumpExpanded and "−" or "+"

		jumpSlider.Visible =
			jumpEnabled and jumpExpanded

		jumpValue.Visible =
			jumpEnabled and jumpExpanded
	end)

	connect(UserInputService.InputBegan, function(input, processed)
		if destroyed or processed then
			return
		end

		if input.KeyCode == Config.Keybinds.Camlock then
			toggleCamlock()
		end

		if input.KeyCode == Config.Keybinds.SilentAim then
			toggleSilentAim()
		end

		if input.KeyCode == Config.Keybinds.ESP then
			toggleESP()
		end

		if input.KeyCode == Config.Keybinds.Speed then
			toggleSpeed()
		end

		if input.KeyCode == Config.Keybinds.Jump then
			toggleJump()
		end

		if input.KeyCode == Config.Keybinds.PanicGround then
			panicGround()
		end

		if input.KeyCode == Enum.KeyCode.F8 then
			destroyed = true
		end
	end)

	connect(Player.CharacterAdded, function()
		task.wait(0.5)

		local humanoid = getHumanoid()

		if humanoid then
			if speedEnabled then
				humanoid.WalkSpeed = Config.Speed.Value
			else
				originalWalkSpeed = humanoid.WalkSpeed
			end

			if jumpEnabled then
				humanoid.JumpPower = Config.Jump.Value
			else
				originalJumpPower = humanoid.JumpPower
			end
		end

		refreshHitboxes()
	end)

	connect(Players.PlayerAdded, function(otherPlayer)
		connect(otherPlayer.CharacterAdded, function()
			task.wait(0.5)

			if espEnabled then
				createESP(otherPlayer)
			end

			if silentAimEnabled then
				createHitbox(otherPlayer)
			end
		end)
	end)

	connect(Players.PlayerRemoving, function(otherPlayer)
		if otherPlayer.Character then
			destroyESP(otherPlayer.Character)
			destroyHitbox(otherPlayer.Character)
		end

		if target == otherPlayer then
			target = nil
		end
	end)

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= Player then
			connect(otherPlayer.CharacterAdded, function()
				task.wait(0.5)

				if espEnabled then
					createESP(otherPlayer)
				end

				if silentAimEnabled then
					createHitbox(otherPlayer)
				end
			end)
		end
	end

	task.spawn(function()
		while not destroyed do
			task.wait(0.15)

			if silentAimEnabled then
				for _, otherPlayer in ipairs(Players:GetPlayers()) do
					if otherPlayer ~= Player then
						local character = otherPlayer.Character

						if validCharacter(character) then
							local hitbox = hitboxObjects[character]

							if not hitbox then
								createHitbox(otherPlayer)
							end
						end
					end
				end
			end
		end
	end)

	RunService:BindToRenderStep(
		"CrysCamlock",
		Enum.RenderPriority.Camera.Value + 1,
		function()
			if destroyed or not camlockEnabled then
				return
			end

			if not target
				or not validCharacter(target.Character) then
				target = getClosestTarget()
			end

			if not target then
				camlockEnabled = false
				return
			end

			local character = target.Character
			local part = getTargetPart(
				character,
				Config.Camlock.TargetPart
			)

			local camera = workspace.CurrentCamera

			if part and camera then
				local desired = CFrame.lookAt(
					camera.CFrame.Position,
					part.Position
				)

				camera.CFrame =
					camera.CFrame:Lerp(
						desired,
						Config.Camlock.Smoothness
					)
			end
		end
	)

	return gui
end

local humanoid = getHumanoid()

if humanoid then
	originalWalkSpeed = humanoid.WalkSpeed
	originalJumpPower = humanoid.JumpPower
end

local gui = createGui()

local function updateLabels()
	local frame = gui:FindFirstChildOfClass("Frame")

	if not frame then
		return
	end

	for _, object in ipairs(frame:GetChildren()) do
		if object:IsA("TextLabel") then
			if object.Text:match("^camlock") then
				object.Text =
					"camlock = "
					.. Config.Keybinds.Camlock.Name
			elseif object.Text:match("^silent aim") then
				object.Text =
					"silent aim = "
					.. Config.Keybinds.SilentAim.Name
			elseif object.Text:match("^esp") then
				object.Text =
					"esp = "
					.. Config.Keybinds.ESP.Name
			elseif object.Text:match("^speed walk") then
				object.Text =
					"speed walk = "
					.. Config.Keybinds.Speed.Name
			elseif object.Text:match("^jump power") then
				object.Text =
					"jump power = "
					.. Config.Keybinds.Jump.Name
			elseif object.Text:match("^panic ground") then
				object.Text =
					"panic ground = "
					.. Config.Keybinds.PanicGround.Name
			end
		end
	end
end

updateLabels()
