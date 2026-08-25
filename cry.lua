local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CONFIG = {
	Key = "cry",

	Discord = "discord.gg/NGQu84rQNr",

	Binds = {
		Camlock = Enum.KeyCode.Q,
		ESP = Enum.KeyCode.E,
		Speed = Enum.KeyCode.V,
		Jump = Enum.KeyCode.B,
		PanicGround = Enum.KeyCode.G,
		KillSwitch = Enum.KeyCode.F8
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

	ESP = {
		Enabled = false,
		Color = Color3.fromRGB(255, 60, 60),
		Transparency = 0.7
	},

	Camlock = {
		Enabled = false
	}
}

local destroyed = false
local camlockEnabled = CONFIG.Camlock.Enabled
local espEnabled = CONFIG.ESP.Enabled
local speedEnabled = CONFIG.Speed.Enabled
local jumpEnabled = CONFIG.Jump.Enabled
local target = nil

local connections = {}
local espObjects = {}
local nameObjects = {}

local speedValue = CONFIG.Speed.Value
local jumpValue = CONFIG.Jump.Value
local espColor = CONFIG.ESP.Color

local espExpanded = true
local speedExpanded = true
local jumpExpanded = true

local character = player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")

local originalWalkSpeed = humanoid and humanoid.WalkSpeed or 16
local originalJumpPower = humanoid and humanoid.JumpPower or 50

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local function getHumanoid()
	local currentCharacter = player.Character
	return currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local currentCharacter = player.Character
	return currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
end

local function validCharacter(currentCharacter)
	if not currentCharacter then
		return false
	end

	local currentHumanoid = currentCharacter:FindFirstChildOfClass("Humanoid")

	return currentHumanoid and currentHumanoid.Health > 0
end

local function destroyESP(currentCharacter)
	if espObjects[currentCharacter] then
		for _, object in ipairs(espObjects[currentCharacter]) do
			if object then
				object:Destroy()
			end
		end

		espObjects[currentCharacter] = nil
	end

	if nameObjects[currentCharacter] then
		nameObjects[currentCharacter]:Destroy()
		nameObjects[currentCharacter] = nil
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

	for currentCharacter in pairs(espObjects) do
		destroyESP(currentCharacter)
	end

	for currentCharacter in pairs(nameObjects) do
		destroyESP(currentCharacter)
	end

	local currentHumanoid = getHumanoid()

	if currentHumanoid then
		currentHumanoid.WalkSpeed = originalWalkSpeed
		currentHumanoid.JumpPower = originalJumpPower
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
	if input.KeyCode == CONFIG.Binds.KillSwitch then
		shutdown()
	end
end)

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
			local currentCharacter = otherPlayer.Character

			local root =
				currentCharacter:FindFirstChild("HumanoidRootPart")
				or currentCharacter:FindFirstChild("Head")

			if root then
				local position, visible =
					camera:WorldToViewportPoint(root.Position)

				if visible and position.Z > 0 then
					local screenPosition =
						Vector2.new(position.X, position.Y)

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

local function createESP(otherPlayer)
	if not espEnabled or otherPlayer == player then
		return
	end

	local currentCharacter = otherPlayer.Character

	if not validCharacter(currentCharacter) then
		return
	end

	destroyESP(currentCharacter)

	local objects = {}

	for _, part in ipairs(currentCharacter:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local box = Instance.new("BoxHandleAdornment")

			box.Name = "CrysHitbox"
			box.Adornee = part
			box.Size = part.Size
			box.Color3 = espColor
			box.Transparency = CONFIG.ESP.Transparency
			box.AlwaysOnTop = true
			box.ZIndex = 10
			box.Parent = part

			table.insert(objects, box)
		end
	end

	espObjects[currentCharacter] = objects

	local head =
		currentCharacter:FindFirstChild("Head")
		or currentCharacter:FindFirstChild("HumanoidRootPart")

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

		nameObjects[currentCharacter] = billboard
	end
end

local function refreshESP()
	for currentCharacter in pairs(espObjects) do
		destroyESP(currentCharacter)
	end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			createESP(otherPlayer)
		end
	end
end

local function toggleCamlock()
	camlockEnabled = not camlockEnabled

	if camlockEnabled then
		target = getClosestToCrosshair()

		if not target then
			camlockEnabled = false
		end
	else
		target = nil
	end
end

local function toggleESP()
	espEnabled = not espEnabled

	if espEnabled then
		refreshESP()
	else
		for currentCharacter in pairs(espObjects) do
			destroyESP(currentCharacter)
		end
	end
end

local function toggleSpeed()
	speedEnabled = not speedEnabled

	local currentHumanoid = getHumanoid()

	if currentHumanoid then
		currentHumanoid.WalkSpeed =
			speedEnabled and speedValue or originalWalkSpeed
	end
end

local function toggleJump()
	jumpEnabled = not jumpEnabled

	local currentHumanoid = getHumanoid()

	if currentHumanoid then
		currentHumanoid.JumpPower =
			jumpEnabled and jumpValue or originalJumpPower
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

connect(UserInputService.InputBegan, function(input, gameProcessed)
	if destroyed or gameProcessed then
		return
	end

	if input.KeyCode == CONFIG.Binds.Camlock then
		toggleCamlock()
	elseif input.KeyCode == CONFIG.Binds.ESP then
		toggleESP()
	elseif input.KeyCode == CONFIG.Binds.Speed then
		toggleSpeed()
	elseif input.KeyCode == CONFIG.Binds.Jump then
		toggleJump()
	elseif input.KeyCode == CONFIG.Binds.PanicGround then
		panicGround()
	end
end)

connect(player.CharacterAdded, function(newCharacter)
	task.wait(0.5)

	local currentHumanoid =
		newCharacter:FindFirstChildOfClass("Humanoid")

	if currentHumanoid then
		originalWalkSpeed = currentHumanoid.WalkSpeed
		originalJumpPower = currentHumanoid.JumpPower

		if speedEnabled then
			currentHumanoid.WalkSpeed = speedValue
		end

		if jumpEnabled then
			currentHumanoid.JumpPower = jumpValue
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
		camlockEnabled = false
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
			or not target.Character
			or not validCharacter(target.Character) then

			target = getClosestToCrosshair()
		end

		if not target then
			camlockEnabled = false
			return
		end

		local currentCharacter = target.Character

		local root =
			currentCharacter:FindFirstChild("HumanoidRootPart")
			or currentCharacter:FindFirstChild("Head")

		local camera = workspace.CurrentCamera

		if root and camera then
			camera.CFrame = CFrame.lookAt(
				camera.CFrame.Position,
				root.Position
			)
		end
	end
)
