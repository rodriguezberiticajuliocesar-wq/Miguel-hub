--[[
    Miguel HUB
    by cyanam1 (@𝔥𝔬𝔫𝔢𝔶)
]]

local services = {
	Players = game:GetService("Players"),
	ReplicatedStorage = game:GetService("ReplicatedStorage"),
	VirtualUser = game:GetService("VirtualUser"),
	Workspace = workspace,
	Lighting = game:GetService("Lighting"),
	UserInputService = game:GetService("UserInputService"),
	VirtualInputManager = game:GetService("VirtualInputManager"),
	RunService = game:GetService("RunService"),
	CollectionService = game:GetService("CollectionService"),
	HttpService = game:GetService("HttpService")
}

local utils = {}
utils.runtime = {}

for _, connection in ipairs(_G.MiguelHubMainConnections or {}) do
	pcall(function() connection:Disconnect() end)
end
_G.MiguelHubMainConnections = {}
_G.MiguelHubMainGeneration = (_G.MiguelHubMainGeneration or 0) + 1
utils.Generation = _G.MiguelHubMainGeneration

function utils.isCurrent()
	return utils.Generation == _G.MiguelHubMainGeneration
end

function utils.connect(signal, callback, connection)
	connection = signal:Connect(callback)
	table.insert(_G.MiguelHubMainConnections, connection)
	return connection
end

utils.playerData = {
	Player = services.Players.LocalPlayer,
	DisplayName = services.Players.LocalPlayer.DisplayName,
	Character = services.Players.LocalPlayer.Character,
	Humanoid = nil,
	Camera = services.Workspace.CurrentCamera,
	Backpack = services.Players.LocalPlayer:WaitForChild("Backpack")
}

utils.playerData.Humanoid = utils.playerData.Character and utils.playerData.Character:FindFirstChildOfClass("Humanoid")

utils.remotes = {
	ChangeSpeedSize = services.ReplicatedStorage.rEvents.changeSpeedSizeRemote,
	MuscleEvent = utils.playerData.Player.muscleEvent
}

function utils.formatNumber(n)
	if n >= 1e18 then return string.format("%.1fqi", n / 1e18)
	elseif n >= 1e15 then return string.format("%.1fqa", n / 1e15)
	elseif n >= 1e12 then return string.format("%.1ft", n / 1e12)
	elseif n >= 1e9 then return string.format("%.1fb", n / 1e9)
	elseif n >= 1e6 then return string.format("%.1fm", n / 1e6)
	elseif n >= 1e3 then return string.format("%.1fk", n / 1e3)
	else return tostring(n) end
end

function utils.formatWithCommas(n, formatted, separatorCount)
	formatted = tostring(math.floor(n))
	while true do
		formatted, separatorCount = formatted:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
		if separatorCount == 0 then break end
	end
	return formatted
end

function utils.greeting(hour)
	hour = hour or os.date("*t").hour
	if hour >= 6 and hour < 12 then return "Good Morning!"
	elseif hour >= 12 and hour < 13 then return "Good Noon!"
	elseif hour >= 13 and hour < 19 then return "Good Afternoon!"
	elseif hour >= 19 and hour < 22 then return "Good Evening!"
	else return "Good Night!" end
end

function utils.toggleSelection(selected, selectedList, value, label, prefix)
	if selected[value] then
		selected[value] = nil
		for index = #selectedList, 1, -1 do
			if selectedList[index] == value then table.remove(selectedList, index) end
		end
	else
		selected[value] = true
		table.insert(selectedList, value)
	end
	label.Text = prefix .. (#selectedList > 0 and table.concat(selectedList, ", ") or "None")
end

function utils.deleteAds()
	for _, portal in pairs(game:GetDescendants()) do
		if portal.Name == "RobloxForwardPortals" then
			portal:Destroy()
		end
	end
	if _G.ads then
		_G.ads:Disconnect()
	end
	_G.ads = game.DescendantAdded:Connect(function(descendant)
		if descendant.Name == "RobloxForwardPortals" then
			descendant:Destroy()
		end
	end)
end
utils.deleteAds()

utils.library = loadstring(game:HttpGet("https://raw.githubusercontent.com/rodriguezberiticajuliocesar-wq/SilenceScripts/refs/heads/main/libraries/eleriumv2.luau?cache=" .. tostring(os.time()), true))()

utils.MiguelHub = utils.library:AddWindow("Miguel HUB - " .. utils.greeting(), {
	main_color = Color3.fromRGB(15, 15, 15),
	min_size = Vector2.new(1000, 1300),
	can_resize = true,
})

task.spawn(function()
	while utils.isCurrent() do
		task.wait(60)
		if utils.isCurrent() then
			utils.MiguelHub:SetTitle("Miguel HUB - " .. utils.greeting())
		end
	end
end)

utils.connect(utils.playerData.Player.Idled, function()
	services.VirtualUser:CaptureController()
	services.VirtualUser:ClickButton2(Vector2.new())
end)

utils.connect(utils.playerData.Player.CharacterAdded, function(character)
	utils.playerData.Character = character
	utils.playerData.Humanoid = character:WaitForChild("Humanoid", 10)
	utils.playerData.Backpack = utils.playerData.Player:WaitForChild("Backpack")
end)

local tabs = {
	main = utils.MiguelHub:AddTab("Main"),
	killing = utils.MiguelHub:AddTab("Killing"),
	specs = utils.MiguelHub:AddTab("Specs"),
	farming = utils.MiguelHub:AddTab("Farming"),
	fast = utils.MiguelHub:AddTab("Fast"),
	boss = utils.MiguelHub:AddTab("Boss"),
	inventory = utils.MiguelHub:AddTab("Pets"),
	boosts = utils.MiguelHub:AddTab("Boosts"),
	teleport = utils.MiguelHub:AddTab("Teleports"),
	stats = utils.MiguelHub:AddTab("Stats"),
	info = utils.MiguelHub:AddTab("Info")
}

for _, tab in pairs(tabs) do
	tab.runtime = {}
end

tabs.main:AddLabel("User Settings:")

tabs.main.Settings = {
	Size = {Value = 2, Enabled = false},
	Speed = {Value = 120, Enabled = false},
	FOV = {Value = 70, Enabled = false}
}

tabs.main:AddTextBox("Size:", function(text)
	text = string.gsub(text, "%s+", "")
	if tonumber(text) and tonumber(text) > 0 then
		tabs.main.Settings.Size.Value = tonumber(text)
	end
end, {clear = false})

tabs.main:AddSwitch("Set Size", function(bool)
	tabs.main.Settings.Size.Enabled = bool
end)

task.spawn(function()
	while utils.isCurrent() and true do
		if tabs.main.Settings.Size.Enabled and utils.playerData.Character and utils.playerData.Humanoid then
			utils.remotes.ChangeSpeedSize:InvokeServer("changeSize", tabs.main.Settings.Size.Value)
		end
		task.wait(0.01)
	end
end)

tabs.main:AddTextBox("Speed:", function(text)
	text = string.gsub(text, "%s+", "")
	if tonumber(text) and tonumber(text) > 0 then
		tabs.main.Settings.Speed.Value = tonumber(text)
	end
end, {clear = false})

tabs.main:AddSwitch("Set Speed", function(bool)
	tabs.main.Settings.Speed.Enabled = bool
end)

task.spawn(function()
	while utils.isCurrent() and true do
		if tabs.main.Settings.Speed.Enabled and utils.playerData.Character and utils.playerData.Humanoid then
			utils.remotes.ChangeSpeedSize:InvokeServer("changeSpeed", tabs.main.Settings.Speed.Value)
		end
		task.wait(0.01)
	end
end)

if utils.playerData.Camera then
	tabs.main:AddTextBox("FOV:", function(text)
		text = string.gsub(text, "%s+", "")
		if tonumber(text) and tonumber(text) >= 1 and tonumber(text) <= 120 then
			tabs.main.Settings.FOV.Value = tonumber(text)
		end
	end, {clear = false})

	tabs.main:AddSwitch("Set FOV", function(bool)
		tabs.main.Settings.FOV.Enabled = bool
		utils.playerData.Camera.FieldOfView = bool and tabs.main.Settings.FOV.Value or 70
	end)

	task.spawn(function()
		while utils.isCurrent() and true do
			if tabs.main.Settings.FOV.Enabled and utils.playerData.Camera then
				utils.playerData.Camera.FieldOfView = tabs.main.Settings.FOV.Value
			end
			task.wait(0.01)
		end
	end)
end

tabs.main:AddLabel("Protection and Visuals:")

tabs.main.Protection = {
	AntiFling = {Enabled = false},
	PositionLock = {Enabled = false, Position = nil}
}

tabs.main.enableAntiFling = function()
	if not tabs.main.Protection.AntiFling.Enabled or not utils.playerData.Player.Character then return end
	if not utils.playerData.Player.Character:FindFirstChild("HumanoidRootPart") then return end
	if utils.playerData.Player.Character.HumanoidRootPart:FindFirstChild("BodyVelocity") and
	   utils.playerData.Player.Character.HumanoidRootPart.BodyVelocity.MaxForce == Vector3.new(100000, 0, 100000) then
		utils.playerData.Player.Character.HumanoidRootPart.BodyVelocity:Destroy()
	end
	tabs.main.runtime.bv = Instance.new("BodyVelocity")
	tabs.main.runtime.bv.MaxForce = Vector3.new(100000, 0, 100000)
	tabs.main.runtime.bv.Velocity = Vector3.new(0, 0, 0)
	tabs.main.runtime.bv.P = 1250
	tabs.main.runtime.bv.Parent = utils.playerData.Player.Character.HumanoidRootPart
end

tabs.main.disableAntiFling = function()
	if not utils.playerData.Player.Character or not utils.playerData.Player.Character:FindFirstChild("HumanoidRootPart") then return end
	if utils.playerData.Player.Character.HumanoidRootPart:FindFirstChild("BodyVelocity") and
	   utils.playerData.Player.Character.HumanoidRootPart.BodyVelocity.MaxForce == Vector3.new(100000, 0, 100000) then
		utils.playerData.Player.Character.HumanoidRootPart.BodyVelocity:Destroy()
	end
end

tabs.main:AddSwitch("Anti Fling", function(bool)
	tabs.main.Protection.AntiFling.Enabled = bool
	if bool then tabs.main.enableAntiFling() else tabs.main.disableAntiFling() end
end):Set(false)

utils.connect(utils.playerData.Player.CharacterAdded, function(newChar)
	newChar:WaitForChild("HumanoidRootPart", 5)
	if tabs.main.Protection.AntiFling.Enabled then tabs.main.enableAntiFling() end
end)

tabs.main.lockPosition = function()
	tabs.main.enableAntiFling()
	if not tabs.main.Protection.PositionLock.Enabled or not tabs.main.Protection.PositionLock.Position or not utils.playerData.Player.Character then return end
	if not utils.playerData.Player.Character:FindFirstChild("HumanoidRootPart") then return end
	if utils.playerData.Player.Character.HumanoidRootPart:FindFirstChild("PositionLocker") then
		utils.playerData.Player.Character.HumanoidRootPart.PositionLocker.Position = tabs.main.Protection.PositionLock.Position
	else
		tabs.main.disableAntiFling()
		tabs.main.runtime.bp = Instance.new("BodyPosition")
		tabs.main.runtime.bp.Name = "PositionLocker"
		tabs.main.runtime.bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		tabs.main.runtime.bp.Position = tabs.main.Protection.PositionLock.Position
		tabs.main.runtime.bp.P = 100000
		tabs.main.runtime.bp.Parent = utils.playerData.Player.Character.HumanoidRootPart
	end
end

tabs.main.unlockPosition = function()
	if utils.playerData.Player.Character and utils.playerData.Player.Character:FindFirstChild("HumanoidRootPart") then
		if utils.playerData.Player.Character.HumanoidRootPart:FindFirstChild("PositionLocker") then
			utils.playerData.Player.Character.HumanoidRootPart.PositionLocker:Destroy()
		end
	end
	tabs.main.Protection.PositionLock.Position = nil
end

tabs.main:AddSwitch("Lock Position", function(bool)
	tabs.main.Protection.PositionLock.Enabled = bool
	if bool then
		if utils.playerData.Player.Character and utils.playerData.Player.Character:FindFirstChild("HumanoidRootPart") then
			tabs.main.Protection.PositionLock.Position = utils.playerData.Player.Character.HumanoidRootPart.Position
		end
		tabs.main.lockPosition()
	else
		tabs.main.unlockPosition()
	end
end)

tabs.main.VisibilitySettings = {
	HidePets = false,
	HidePopups = true,
	ShowPetsEvent = services.ReplicatedStorage.rEvents:WaitForChild("showPetsEvent"),
	SavePlayerSizeEvent = services.ReplicatedStorage.rEvents:WaitForChild("savePlayerSizeEvent")
}

tabs.main:AddSwitch("Hide Pets", function(state)
	tabs.main.VisibilitySettings.HidePets = state
	tabs.main.VisibilitySettings.ShowPetsEvent:FireServer(state and "hidePets" or "showPets")
end):Set(false)

tabs.main.VisibilitySettings.HidePopupsSwitch = tabs.main:AddSwitch("Hide Popups", function(state)
	tabs.main.VisibilitySettings.HidePopups = state
	tabs.main.VisibilitySettings.SavePlayerSizeEvent:FireServer("showPopupsOption")
end)
tabs.main.VisibilitySettings.HidePopupsSwitch:Set(false)

tabs.main.WaterParts = {
	Parts = {},
	PartSize = 2048,
	TotalDistance = 50000,
	StartPosition = Vector3.new(-2, -9.5, -2)
}

task.spawn(function()
	for x = 0, math.ceil(tabs.main.WaterParts.TotalDistance / tabs.main.WaterParts.PartSize) - 1 do
		for z = 0, math.ceil(tabs.main.WaterParts.TotalDistance / tabs.main.WaterParts.PartSize) - 1 do
			for i, offset in ipairs({
				{x * tabs.main.WaterParts.PartSize, z * tabs.main.WaterParts.PartSize, "Side_" .. x .. "_" .. z},
				{-x * tabs.main.WaterParts.PartSize, z * tabs.main.WaterParts.PartSize, "LeftRight_" .. x .. "_" .. z},
				{-x * tabs.main.WaterParts.PartSize, -z * tabs.main.WaterParts.PartSize, "UpLeft_" .. x .. "_" .. z},
				{x * tabs.main.WaterParts.PartSize, -z * tabs.main.WaterParts.PartSize, "UpRight_" .. x .. "_" .. z}
			}) do
				tabs.main.runtime.part = Instance.new("Part")
				tabs.main.runtime.part.Size = Vector3.new(tabs.main.WaterParts.PartSize, 1, tabs.main.WaterParts.PartSize)
				tabs.main.runtime.part.Position = tabs.main.WaterParts.StartPosition + Vector3.new(offset[1], 0, offset[2])
				tabs.main.runtime.part.Anchored = true
				tabs.main.runtime.part.Transparency = 1
				tabs.main.runtime.part.CanCollide = true
				tabs.main.runtime.part.Name = "Part_" .. offset[3]
				tabs.main.runtime.part.Parent = services.Workspace
				table.insert(tabs.main.WaterParts.Parts, tabs.main.runtime.part)
			end
		end
	end
end)

tabs.main.WalkOnWaterSwitch = tabs.main:AddSwitch("Walk on Water", function(bool)
	for _, part in ipairs(tabs.main.WaterParts.Parts) do
		if part and part.Parent then part.CanCollide = bool end
	end
end)
tabs.main.WalkOnWaterSwitch:Set(false)

tabs.main:AddLabel("Other:")

tabs.main:AddSwitch("Infinite Jump", function(bool)
	_G.InfiniteJump = bool
	if bool then
		utils.connect(services.UserInputService.JumpRequest, function()
			if _G.InfiniteJump then
				services.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
			end
		end)
	end
end)

tabs.main.FortuneWheelData = {
	Running = false,
	Generation = 0,
	Remote = services.ReplicatedStorage.rEvents:WaitForChild("openFortuneWheelRemote"),
	Chances = services.ReplicatedStorage
		:WaitForChild("shared")
		:WaitForChild("catalogs")
		:WaitForChild("fortuneWheelChances")
		:WaitForChild("Fortune Wheel")
}

tabs.main.spinFortuneWheel = function()
	pcall(function()
		tabs.main.FortuneWheelData.Remote:InvokeServer(
			"openFortuneWheel",
			tabs.main.FortuneWheelData.Chances
		)
	end)
end

tabs.main:AddSwitch("Spin Fortune Wheel", function(state)
	tabs.main.FortuneWheelData.Running = state
	tabs.main.FortuneWheelData.Generation += 1
	tabs.main.runtime.generation = tabs.main.FortuneWheelData.Generation

	if not state then return end

	task.spawn(function()
		while utils.isCurrent() and tabs.main.FortuneWheelData.Running and tabs.main.FortuneWheelData.Generation == tabs.main.runtime.generation do
			tabs.main.spinFortuneWheel()
			task.wait(1)
		end
	end)
end)

tabs.main.TimeDropdown = tabs.main:AddDropdown("Change Time", function(selection)
	services.Lighting.ClockTime = selection == "Night" and 0 or 9
end)
tabs.main.TimeDropdown:Add("Night")
tabs.main.TimeDropdown:Add("Day")

tabs.killing.getTool = function()
	for _, v in pairs(services.Players.LocalPlayer.Backpack:GetChildren()) do
		if v.Name == "Punch" and services.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
			services.Players.LocalPlayer.Character.Humanoid:EquipTool(v)
		end
	end
	services.Players.LocalPlayer.muscleEvent:FireServer("punch", "leftHand")
	services.Players.LocalPlayer.muscleEvent:FireServer("punch", "rightHand")
end

tabs.killing.isPlayerAlive = function(player)
	return player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and
		player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
end

tabs.killing.isSpawnProtected = function(player)
	if not player or not player.Character then return false end
	if player.Character:FindFirstChildOfClass("ForceField")
		or player.Character:FindFirstChild("spawnProtectionHighlight") then
		return true
	end
	tabs.killing.runtime.protectedUntil = player.Character:GetAttribute("SpawnProtectedUntil")
	return typeof(tabs.killing.runtime.protectedUntil) == "number" and services.Workspace:GetServerTimeNow() < tabs.killing.runtime.protectedUntil
end

tabs.killing.getLocalCombatCharacter = function()
	tabs.killing.runtime.character_416 = services.Players.LocalPlayer.Character
	tabs.killing.runtime.humanoid_417 = tabs.killing.runtime.character_416 and tabs.killing.runtime.character_416:FindFirstChildOfClass("Humanoid")
	tabs.killing.runtime.humanoidRootPart = tabs.killing.runtime.character_416 and tabs.killing.runtime.character_416:FindFirstChild("HumanoidRootPart")
	if not tabs.killing.runtime.character_416 or not tabs.killing.runtime.humanoid_417 or tabs.killing.runtime.humanoid_417.Health <= 0 or not tabs.killing.runtime.humanoidRootPart then return end
	return tabs.killing.runtime.character_416, tabs.killing.runtime.humanoid_417, tabs.killing.runtime.humanoidRootPart
end

tabs.killing.positionNearTarget = function(target, heightOffset)
	if not tabs.killing.isPlayerAlive(target)
		or tabs.killing.isSpawnProtected(target)
		or tabs.killing.isSpawnProtected(services.Players.LocalPlayer) then
		return false
	end
	tabs.killing.runtime.discardCharacter_localRoot_429, tabs.killing.runtime.discardHumanoid_localRoot_429, tabs.killing.runtime.localRoot_429 = tabs.killing.getLocalCombatCharacter()
	tabs.killing.runtime.targetRoot_430 = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not tabs.killing.runtime.localRoot_429 or not tabs.killing.runtime.targetRoot_430 then return false end

	tabs.killing.runtime.localRoot_429.CFrame = tabs.killing.runtime.targetRoot_430.CFrame * CFrame.new(0, heightOffset, 0)
	tabs.killing.runtime.localRoot_429.AssemblyLinearVelocity = Vector3.zero
	tabs.killing.runtime.localRoot_429.AssemblyAngularVelocity = Vector3.zero
	return true
end

tabs.killing.touchAndPunchTarget = function(target, heightOffset)
	if not tabs.killing.positionNearTarget(target, heightOffset) then return false, false end
	services.RunService.Heartbeat:Wait()
	if not tabs.killing.positionNearTarget(target, heightOffset) then return false, false end

	tabs.killing.runtime.character_444 = tabs.killing.getLocalCombatCharacter()
	tabs.killing.runtime.targetRoot_445 = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	tabs.killing.runtime.targetHumanoid_446 = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if not tabs.killing.runtime.character_444 or not tabs.killing.runtime.targetRoot_445 or not tabs.killing.runtime.targetHumanoid_446 or tabs.killing.isSpawnProtected(target) then return false, false end

	tabs.killing.runtime.hand = tabs.killing.runtime.character_444:FindFirstChild("LeftHand") or tabs.killing.runtime.character_444:FindFirstChild("RightHand")
	if not tabs.killing.runtime.hand then return false, false end

	tabs.killing.runtime.punchTool = tabs.killing.runtime.character_444:FindFirstChild("Punch") or services.Players.LocalPlayer.Backpack:FindFirstChild("Punch")
	tabs.killing.runtime.humanoid_453 = tabs.killing.runtime.character_444:FindFirstChildOfClass("Humanoid")
	if tabs.killing.runtime.punchTool and tabs.killing.runtime.punchTool.Parent ~= tabs.killing.runtime.character_444 and tabs.killing.runtime.humanoid_453 then
		tabs.killing.runtime.humanoid_453:EquipTool(tabs.killing.runtime.punchTool)
	end

	tabs.killing.runtime.healthBefore = tabs.killing.runtime.targetHumanoid_446.Health
	tabs.killing.runtime.attempted_459 = pcall(function()
		firetouchinterest(tabs.killing.runtime.targetRoot_445, tabs.killing.runtime.hand, 0)
		firetouchinterest(tabs.killing.runtime.targetRoot_445, tabs.killing.runtime.hand, 1)
		services.Players.LocalPlayer.muscleEvent:FireServer("punch", tabs.killing.runtime.hand.Name == "LeftHand" and "leftHand" or "rightHand")
	end)
	if not tabs.killing.runtime.attempted_459 then return false, false end

	for _ = 1, 4 do
		services.RunService.Heartbeat:Wait()
		if not tabs.killing.isPlayerAlive(target) or tabs.killing.runtime.targetHumanoid_446.Health < tabs.killing.runtime.healthBefore then
			return true, true
		end
		if tabs.killing.isSpawnProtected(target) then
			return false, false
		end
	end

	return false, true
end

tabs.killing.attackPlayerWithLimit = function(target, hitLimit, shouldContinue, heightOffset, countAttempts, hits, hitRegistered, attempted)
	hits = 0
	while utils.isCurrent() and hits < hitLimit and shouldContinue() and tabs.killing.isPlayerAlive(target) and not tabs.killing.isSpawnProtected(target) do
		hitRegistered, attempted = tabs.killing.touchAndPunchTarget(target, heightOffset)
		if countAttempts or hitRegistered then hits = hits + 1 end
		if not attempted and not countAttempts then break end
		if not hitRegistered then task.wait(0.05) end
	end
	return hits
end

tabs.killing.attackPlayerForDuration = function(target, duration, shouldContinue, heightOffset, startedAt, character, targetRoot, leftHand, rightHand, punchTool, humanoid)
	startedAt = os.clock()
	while utils.isCurrent() and os.clock() - startedAt < duration
		and shouldContinue()
		and tabs.killing.isPlayerAlive(target)
		and not tabs.killing.isSpawnProtected(target) do
		if tabs.killing.positionNearTarget(target, heightOffset) then
			character = services.Players.LocalPlayer.Character
			targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
			leftHand = character and character:FindFirstChild("LeftHand")
			rightHand = character and character:FindFirstChild("RightHand")
			punchTool = character and character:FindFirstChild("Punch") or services.Players.LocalPlayer.Backpack:FindFirstChild("Punch")
			humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if punchTool and humanoid and punchTool.Parent ~= character then humanoid:EquipTool(punchTool) end

			if targetRoot and leftHand and rightHand then
				pcall(function()
					firetouchinterest(targetRoot, leftHand, 0)
					firetouchinterest(targetRoot, leftHand, 1)
					firetouchinterest(targetRoot, rightHand, 0)
					firetouchinterest(targetRoot, rightHand, 1)
					services.Players.LocalPlayer.muscleEvent:FireServer("punch", "leftHand")
					services.Players.LocalPlayer.muscleEvent:FireServer("punch", "rightHand")
				end)
			end
		end
		services.RunService.Heartbeat:Wait()
	end
end

tabs.killing:AddLabel("Misc:")

tabs.killing.equipBestStatPets = function(priority)
	for _, folder in pairs(services.Players.LocalPlayer.petsFolder:GetChildren()) do
		if folder:IsA("Folder") then
			for _, pet in pairs(folder:GetChildren()) do
				services.ReplicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
			end
		end
	end

	task.wait(0.2)
	tabs.killing.runtime.petsByName = {}
	for _, petName in ipairs(priority) do tabs.killing.runtime.petsByName[petName] = {} end

	for _, pet in pairs(services.Players.LocalPlayer.petsFolder.Unique:GetChildren()) do
		if tabs.killing.runtime.petsByName[pet.Name] then table.insert(tabs.killing.runtime.petsByName[pet.Name], pet) end
	end

	tabs.killing.runtime.equippedCount = 0
	for _, petName in ipairs(priority) do
		for _, pet in ipairs(tabs.killing.runtime.petsByName[petName]) do
			if tabs.killing.runtime.equippedCount >= 9 then return end
			services.ReplicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
			tabs.killing.runtime.equippedCount += 1
			task.wait(0.1)
		end
	end
end

tabs.killing:AddButton("Equip Best Damage", function()
	tabs.killing.equipBestStatPets({"Wild Wizard", "Chaos Sorcerer", "Mighty Monster", "Small Fry"})
end)

tabs.killing:AddButton("Equip Best Health", function()
	tabs.killing.equipBestStatPets({"Mighty Monster", "Small Fry", "Wild Wizard", "Chaos Sorcerer"})
end)

tabs.killing:AddSwitch("Remove Attack Animations", function(bool)
	if bool then
		tabs.killing.runtime.blockedAnimations = {
			["3638729053"] = true,
			["3638767427"] = true,
			["507768375"] = true,
			["522635514"] = true,
			["522638767"] = true,
			["182393478"] = true,
			["129967390"] = true,
			["129967478"] = true
		}

		tabs.killing.runtime.shouldBlockAnimation = function(track)
			if not track or not track.Animation then return false end
			tabs.killing.runtime.animationId = tostring(track.Animation.AnimationId):match("%d+")
			tabs.killing.runtime.animationName = string.lower((track.Name or "") .. " " .. (track.Animation.Name or ""))
			return tabs.killing.runtime.blockedAnimations[tabs.killing.runtime.animationId] == true
				or string.find(tabs.killing.runtime.animationName, "punch", 1, true) ~= nil
				or string.find(tabs.killing.runtime.animationName, "attack", 1, true) ~= nil
				or string.find(tabs.killing.runtime.animationName, "right", 1, true) ~= nil
				or string.find(tabs.killing.runtime.animationName, "equip", 1, true) ~= nil
				or string.find(tabs.killing.runtime.animationName, "tool", 1, true) ~= nil
				or string.find(tabs.killing.runtime.animationName, "hold", 1, true) ~= nil
		end

		tabs.killing.runtime.isAttackTool = function(tool)
			if not tool or not tool:IsA("Tool") then return false end
			tabs.killing.runtime.name = string.lower(tool.Name)
			return string.find(tabs.killing.runtime.name, "punch", 1, true) ~= nil
				or string.find(tabs.killing.runtime.name, "attack", 1, true) ~= nil
				or string.find(tabs.killing.runtime.name, "right", 1, true) ~= nil
		end

		tabs.killing.runtime.hasAttackToolEquipped = function(character)
			if not character then return false end
			for _, child in ipairs(character:GetChildren()) do
				if tabs.killing.runtime.isAttackTool(child) then return true end
			end
			return false
		end

		tabs.killing.runtime.isMovementAnimation = function(track, character)
			tabs.killing.runtime.animation = track and track.Animation
			tabs.killing.runtime.animate = character and character:FindFirstChild("Animate")
			if not tabs.killing.runtime.animation or not tabs.killing.runtime.animate or not tabs.killing.runtime.animation:IsDescendantOf(tabs.killing.runtime.animate) then
				return false
			end

			tabs.killing.runtime.path = ""
			tabs.killing.runtime.current = tabs.killing.runtime.animation
			while utils.isCurrent() and tabs.killing.runtime.current and tabs.killing.runtime.current ~= tabs.killing.runtime.animate.Parent do
				tabs.killing.runtime.path = tabs.killing.runtime.path .. " " .. string.lower(tabs.killing.runtime.current.Name)
				if tabs.killing.runtime.current == tabs.killing.runtime.animate then break end
				tabs.killing.runtime.current = tabs.killing.runtime.current.Parent
			end

			if string.find(tabs.killing.runtime.path, "tool", 1, true)
				or string.find(tabs.killing.runtime.path, "punch", 1, true)
				or string.find(tabs.killing.runtime.path, "attack", 1, true)
				or string.find(tabs.killing.runtime.path, "equip", 1, true)
				or string.find(tabs.killing.runtime.path, "hold", 1, true) then
				return false
			end

			for _, movementName in ipairs({"idle", "walk", "run", "jump", "fall", "climb", "swim", "sit"}) do
				if string.find(tabs.killing.runtime.path, movementName, 1, true) then return true end
			end
			return false
		end

		tabs.killing.runtime.stopBlockedAnimations = function(character)
			tabs.killing.runtime.humanoid_603 = character and character:FindFirstChildOfClass("Humanoid")
			if not tabs.killing.runtime.humanoid_603 then return end
			for _, track in ipairs(tabs.killing.runtime.humanoid_603:GetPlayingAnimationTracks()) do
				if tabs.killing.runtime.shouldBlockAnimation(track) then track:Stop(0) end
			end
		end

		tabs.killing.runtime.stopEquipAnimations = function(character)
			tabs.killing.runtime.humanoid_611 = character and character:FindFirstChildOfClass("Humanoid")
			if not tabs.killing.runtime.humanoid_611 then return end
			for _, track in ipairs(tabs.killing.runtime.humanoid_611:GetPlayingAnimationTracks()) do
				tabs.killing.runtime.priority = track.Priority
				if tabs.killing.runtime.shouldBlockAnimation(track)
					or not tabs.killing.runtime.isMovementAnimation(track, character)
					or tabs.killing.runtime.priority == Enum.AnimationPriority.Action
					or tabs.killing.runtime.priority == Enum.AnimationPriority.Action2
					or tabs.killing.runtime.priority == Enum.AnimationPriority.Action3
					or tabs.killing.runtime.priority == Enum.AnimationPriority.Action4 then
					track:Stop(0)
				end
			end
