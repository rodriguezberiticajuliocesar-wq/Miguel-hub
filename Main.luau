--[[
    Ml Main
    by Honen @𝔥𝔬𝔫𝔢𝔶
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

for _, connection in ipairs(_G.HonenxWhiteMainConnections or {}) do
	pcall(function() connection:Disconnect() end)
end
_G.HonenxWhiteMainConnections = {}
_G.HonenxWhiteMainGeneration = (_G.HonenxWhiteMainGeneration or 0) + 1
utils.Generation = _G.HonenxWhiteMainGeneration

function utils.isCurrent()
	return utils.Generation == _G.HonenxWhiteMainGeneration
end

function utils.connect(signal, callback, connection)
	connection = signal:Connect(callback)
	table.insert(_G.HonenxWhiteMainConnections, connection)
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

function utils.createPrivacyRedactor(player, key)
	local redactor = {
		NameEnabled = false,
		StatsEnabled = false,
		OriginalNames = setmetatable({}, {__mode = "k"}),
		OriginalStats = setmetatable({}, {__mode = "k"}),
		NameGuis = setmetatable({}, {__mode = "k"}),
	}
	_G.HonenxWhitePrivacyGenerations = _G.HonenxWhitePrivacyGenerations or {}
	_G.HonenxWhitePrivacyGenerations[key] = (_G.HonenxWhitePrivacyGenerations[key] or 0) + 1
	local generation = _G.HonenxWhitePrivacyGenerations[key]

	local function containsName(text)
		return string.find(text, player.Name, 1, true)
			or string.find(text, player.DisplayName, 1, true)
	end

	local function redact(storage, object, replacement)
		local saved = storage[object]
		if not saved or object.Text ~= saved.Redacted then
			saved = {Original = object.Text}
			storage[object] = saved
		end
		saved.Redacted = replacement
		object.Text = replacement
	end

	local function restore(storage, stillDisabled)
		local savedObjects = {}
		for object, saved in pairs(storage) do
			table.insert(savedObjects, {Object = object, Text = saved.Original})
		end
		table.clear(storage)
		task.spawn(function()
			for _ = 1, 5 do
				if not stillDisabled() then return end
				for _, saved in ipairs(savedObjects) do
					if saved.Object.Parent then saved.Object.Text = saved.Text end
				end
				task.wait(0.1)
			end
		end)
	end

	local function setNameGuiHidden(nameGui)
		if nameGui and nameGui:IsA("BillboardGui") then
			if redactor.NameGuis[nameGui] == nil then redactor.NameGuis[nameGui] = nameGui.Enabled end
			nameGui.Enabled = false
		end
	end

	local function showNameGui(nameGui)
		if not nameGui or not nameGui:IsA("BillboardGui") then return end
		nameGui.Enabled = true
	end

	local function isTopStat(object)
		if not string.find(object.Text, "%d") or object.AbsolutePosition.Y > 150 then return false end
		local current = object
		for _ = 1, 6 do
			if not current then break end
			local name = string.lower(current.Name)
			if string.find(name, "strength", 1, true) or string.find(name, "gem", 1, true) then return true end
			current = current.Parent
		end
		return false
	end

	local function redactLeaderboardStats(nameObject, coreGui)
		local nameCenterY = nameObject.AbsolutePosition.Y + nameObject.AbsoluteSize.Y / 2
		local minimumX = nameObject.AbsolutePosition.X + nameObject.AbsoluteSize.X * 0.5
		local tolerance = math.max(6, nameObject.AbsoluteSize.Y * 0.5)
		for _, valueObject in ipairs(coreGui:GetDescendants()) do
			if (valueObject:IsA("TextLabel") or valueObject:IsA("TextButton"))
				and valueObject ~= nameObject and string.find(valueObject.Text, "%d") then
				local valueCenterY = valueObject.AbsolutePosition.Y + valueObject.AbsoluteSize.Y / 2
				if valueObject.AbsolutePosition.X >= minimumX
					and math.abs(valueCenterY - nameCenterY) <= tolerance then
					redact(redactor.OriginalStats, valueObject, "####")
				end
			end
		end
	end

	local function update()
		local character = player.Character
		if redactor.NameEnabled and character then
			setNameGuiHidden(character:FindFirstChild("nameGui", true))
		end
		if redactor.NameEnabled then
			local namedCharacter = workspace:FindFirstChild("HenneZocktTV")
			local head = namedCharacter and namedCharacter:FindFirstChild("Head")
			setNameGuiHidden(head and head:FindFirstChild("nameGui"))
		end
		if redactor.StatsEnabled then
			for _, object in ipairs(player:WaitForChild("PlayerGui"):GetDescendants()) do
				if (object:IsA("TextLabel") or object:IsA("TextButton")) and isTopStat(object) then
					redact(redactor.OriginalStats, object, "####")
				end
			end
		end

		local coreGui = game:GetService("CoreGui")
		for _, object in ipairs(coreGui:GetDescendants()) do
			if object:IsA("TextLabel") or object:IsA("TextButton") then
				local saved = redactor.OriginalNames[object]
				if containsName(object.Text) or (saved and containsName(saved.Original)) then
					if redactor.StatsEnabled then redactLeaderboardStats(object, coreGui) end
					if redactor.NameEnabled then redact(redactor.OriginalNames, object, "########") end
				end
			end
		end
	end

	function redactor:SetNameEnabled(enabled)
		self.NameEnabled = enabled
		if not enabled then
			restore(self.OriginalNames, function() return not self.NameEnabled end)
			local savedNameGuis = {}
			for nameGui in pairs(self.NameGuis) do table.insert(savedNameGuis, nameGui) end
			table.clear(self.NameGuis)
			task.spawn(function()
				for _ = 1, 10 do
					if self.NameEnabled then return end
					local currentCharacter = player.Character
					local currentNameGui = currentCharacter and currentCharacter:FindFirstChild("nameGui", true)
					showNameGui(currentNameGui)
					local namedCharacter = workspace:FindFirstChild("HenneZocktTV")
					local head = namedCharacter and namedCharacter:FindFirstChild("Head")
					local explicitNameGui = head and head:FindFirstChild("nameGui")
					showNameGui(explicitNameGui)
					for _, nameGui in ipairs(savedNameGuis) do
						if nameGui.Parent then showNameGui(nameGui) end
					end
					task.wait(0.1)
				end
			end)
		end
		pcall(update)
	end

	function redactor:SetStatsEnabled(enabled)
		self.StatsEnabled = enabled
		if not enabled then restore(self.OriginalStats, function() return not self.StatsEnabled end) end
		pcall(update)
	end

	task.spawn(function()
		while _G.HonenxWhitePrivacyGenerations[key] == generation do
			if redactor.NameEnabled or redactor.StatsEnabled then pcall(update) end
			task.wait(1)
		end
	end)
	return redactor
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

utils.HonenxWhite = utils.library:AddWindow("HonenxWhite | Main - " .. utils.greeting(), {
	main_color = Color3.fromRGB(0, 120, 255),
	min_size = Vector2.new(1000, 1300),
	can_resize = true,
})

task.spawn(function()
	while utils.isCurrent() do
		task.wait(60)
		if utils.isCurrent() then
			utils.HonenxWhite:SetTitle("HonenxWhite | Main - " .. utils.greeting())
		end
	end
end)

utils.connect(utils.playerData.Player.Idled, function()
	pcall(function()
		services.VirtualUser:CaptureController()
		services.VirtualUser:ClickButton2(Vector2.new(0, 0))
		services.VirtualUser:ClickButton1(Vector2.new(0, 0))
	end)
end)

utils.connect(utils.playerData.Player.CharacterAdded, function(character)
	utils.playerData.Character = character
	utils.playerData.Humanoid = character:WaitForChild("Humanoid", 10)
	utils.playerData.Backpack = utils.playerData.Player:WaitForChild("Backpack")
end)

local tabs = {
	main = utils.HonenxWhite:AddTab("Main"),
	fast = utils.HonenxWhite:AddTab("⚡ Fast"),
	info = utils.HonenxWhite:AddTab("Info")
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
		task.wait(0.15)
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
		task.wait(0.15)
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
			task.wait(0.15)
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

tabs.main.RedactConfigPath = "HonenxWhite/MuscleLegendsMainConfig.json"
tabs.main.RedactConfig = {
	RedactName = false,
	RedactStats = false,
}

tabs.main.loadRedactConfig = function()
	if type(isfile) ~= "function" or type(readfile) ~= "function" then return end
	pcall(function()
		if not isfile(tabs.main.RedactConfigPath) then return end
		local savedConfig = services.HttpService:JSONDecode(readfile(tabs.main.RedactConfigPath))
		if typeof(savedConfig) == "table" then
			tabs.main.RedactConfig.RedactName = savedConfig.RedactName == true
			tabs.main.RedactConfig.RedactStats = savedConfig.RedactStats == true
		end
	end)
end

tabs.main.saveRedactConfig = function()
	if type(writefile) ~= "function" then return end
	pcall(function()
		if type(makefolder) == "function"
			and (type(isfolder) ~= "function" or not isfolder("HonenxWhite")) then
			pcall(makefolder, "HonenxWhite")
		end
		writefile(tabs.main.RedactConfigPath, services.HttpService:JSONEncode(tabs.main.RedactConfig))
	end)
end

tabs.main.loadRedactConfig()
tabs.main.PrivacyRedactor = utils.createPrivacyRedactor(utils.playerData.Player, "Main")
tabs.main.RedactNameSwitch = tabs.main:AddSwitch("Redact Name", function(state)
	tabs.main.PrivacyRedactor:SetNameEnabled(state)
	tabs.main.RedactConfig.RedactName = state
	tabs.main.saveRedactConfig()
end)
tabs.main.RedactNameSwitch:Set(tabs.main.RedactConfig.RedactName)
tabs.main.RedactStatsSwitch = tabs.main:AddSwitch("Redact Stats", function(state)
	tabs.main.PrivacyRedactor:SetStatsEnabled(state)
	tabs.main.RedactConfig.RedactStats = state
	tabs.main.saveRedactConfig()
end)
tabs.main.RedactStatsSwitch:Set(tabs.main.RedactConfig.RedactStats)

utils.connect(utils.playerData.Player.CharacterAdded, function(newChar)
	if tabs.main.Protection.PositionLock.Enabled and newChar:WaitForChild("HumanoidRootPart", 5) then
		tabs.main.Protection.PositionLock.Position = newChar.HumanoidRootPart.Position
		tabs.main.lockPosition()
	end
end)

task.spawn(function()
	while utils.isCurrent() and true do
		if tabs.main.Protection.PositionLock.Enabled then tabs.main.lockPosition() end
		task.wait(0.1)
	end
end)

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
-- ============================================
-- TAB FAST
-- ============================================

-- FAST REP - by cyanam1
tabs.fast:AddLabel("Fast Rep:")

tabs.fast.FastRepData = {
    Running = false,
    WorkerActive = false,
    SendRate = 800,
    MaxSendRate = 1500,
    MaxBurst = 64,
    CurrentPing = 0,
    LastPingCheck = 0,
    PingControl = false
}

local strengthStat = utils.playerData.Player:WaitForChild("leaderstats"):WaitForChild("Strength")
local durabilityStat = utils.playerData.Player:WaitForChild("Durability")
local networkStats = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]

tabs.fast.FastRepStatus = tabs.fast:AddLabel("Status: Inactive")
tabs.fast.FastRepStatus.TextColor3 = Color3.fromRGB(255, 80, 80)

tabs.fast.FastRepWorkerLoop = function()
    tabs.fast.FastRepData.WorkerActive = true
    
    while utils.isCurrent() and tabs.fast.FastRepData.Running do
        -- Actualizar ping cada 0.5s
        if tick() - tabs.fast.FastRepData.LastPingCheck > 0.5 then
            pcall(function()
                tabs.fast.FastRepData.CurrentPing = networkStats:GetValue()
            end)
            tabs.fast.FastRepData.LastPingCheck = tick()
            
            if tabs.fast.FastRepData.PingControl then
                local ping = tabs.fast.FastRepData.CurrentPing
                if ping < 80 then
                    tabs.fast.FastRepData.SendRate = 1000
                elseif ping < 150 then
                    tabs.fast.FastRepData.SendRate = 700
                elseif ping < 250 then
                    tabs.fast.FastRepData.SendRate = 450
                elseif ping < 400 then
                    tabs.fast.FastRepData.SendRate = 250
                else
                    tabs.fast.FastRepData.SendRate = 120
                end
            end
        end
        
        -- Enviar reps (un lote por frame)
        local repsToSend = math.floor(tabs.fast.FastRepData.SendRate / 60)
        if repsToSend < 1 then repsToSend = 1 end
        if repsToSend > 12 then
            repsToSend = 12
        end
        
        for i = 1, repsToSend do
            pcall(function()
                utils.remotes.MuscleEvent:FireServer("rep")
            end)
        end
        
        -- Actualizar status
        tabs.fast.FastRepStatus.Text = "Status: " .. tabs.fast.FastRepData.SendRate 
            .. " reps/s | " .. math.floor(tabs.fast.FastRepData.CurrentPing) .. " ms"
        tabs.fast.FastRepStatus.TextColor3 = Color3.fromRGB(80, 255, 120)
        
        services.RunService.Heartbeat:Wait()
    end
    
    tabs.fast.FastRepData.WorkerActive = false
end

tabs.fast:AddTextBox("Max reps/s: 1200", function(text)
    local num = tonumber(text)
    if num and num > 0 then
        tabs.fast.FastRepData.MaxSendRate = math.clamp(num, 100, 1200)
        tabs.fast.FastRepData.SendRate = math.min(tabs.fast.FastRepData.SendRate, tabs.fast.FastRepData.MaxSendRate)
    end
end, {clear = false})

tabs.fast:AddSwitch("Ping Control (Auto Speed)", function(state)
    tabs.fast.FastRepData.PingControl = state
end):Set(true)

tabs.fast.FastRepToggle = tabs.fast:AddSwitch("Fast Rep (No Lag)", function(state)
    tabs.fast.FastRepData.Running = state
    if state then
        tabs.fast.FastRepData.SendRate = 800
        tabs.fast.FastRepData.LastPingCheck = tick()
        tabs.fast.FastRepData.WorkerActive = false
        tabs.fast.FastRepStatus.Text = "Status: Activando..."
        tabs.fast.FastRepStatus.TextColor3 = Color3.fromRGB(255, 200, 80)
        task.wait(0.05)
        task.spawn(tabs.fast.FastRepWorkerLoop)
    else
        tabs.fast.FastRepStatus.Text = "Status: Inactive"
        tabs.fast.FastRepStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end)

tabs.fast:AddLabel("400-1500 reps/s | Ping auto-ajustado")

-- 🔄 FAST REBIRTH - by cyanam1
tabs.fast:AddLabel("🔄 Fast Rebirth:")

tabs.fast.FastRebirthData = {
    Running = false,
    WorkerActive = false,
    Rebirths = utils.playerData.Player.leaderstats:WaitForChild("Rebirths"),
    Strength = utils.playerData.Player.leaderstats:WaitForChild("Strength"),
    TargetRebirths = 0,
    RebirthsGained = 0,
    LastRebirthTime = 0,
    TotalRebirths = 0
}

tabs.fast.FastRebirthStatus = tabs.fast:AddLabel("Status: Inactive")
tabs.fast.FastRebirthStatus.TextColor3 = Color3.fromRGB(255, 80, 80)

tabs.fast.FastRebirthStats = tabs.fast:AddLabel("Rebirths: 0 | Gained: 0")
tabs.fast.FastRebirthSpeed = tabs.fast:AddLabel("Speed: --/min")

tabs.fast.FastRebirthWorker = function()
    local startRebirths = tabs.fast.FastRebirthData.Rebirths.Value
    tabs.fast.FastRebirthData.TotalRebirths = 0
    local lastCheck = tick()
    local lastRebirthCount = startRebirths
    
    while utils.isCurrent() and tabs.fast.FastRebirthData.Running do
        -- Verificar si llegamos al target
        if tabs.fast.FastRebirthData.TargetRebirths > 0 
            and tabs.fast.FastRebirthData.Rebirths.Value >= tabs.fast.FastRebirthData.TargetRebirths then
            tabs.fast.FastRebirthStatus.Text = "Status: ✅ Target alcanzado!"
            tabs.fast.FastRebirthStatus.TextColor3 = Color3.fromRGB(80, 255, 120)
            tabs.fast.FastRebirthData.Running = false
            break
        end
        
        -- 1. Equipar mascotas de repetición para farmear rápido
        pcall(function()
            local uniquePets = utils.playerData.Player.petsFolder.Unique
            -- Desequipar todas primero
            for _, folder in pairs(utils.playerData.Player.petsFolder:GetChildren()) do
                if folder:IsA("Folder") and folder.Name ~= "Unique" then
                    for _, pet in pairs(folder:GetChildren()) do
                        services.ReplicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
                    end
                end
            end
            task.wait(0.1)
            
            -- Equipar mascotas de repetición (prioridad a las de más reps)
            local repPets = {
                "Omega Overlord", "Swift Samurai", "Inferno Drake",
                "Common Boss Pet", "Rare Boss Pet", "Epic Boss Pet",
                "Rainbow Boss Pet", "Legendary Boss Pet", "Mythic Boss Pet"
            }
            
            local equippedCount = 0
            for _, petName in ipairs(repPets) do
                if equippedCount >= 12 then break end
                for _, pet in pairs(uniquePets:GetChildren()) do
                    if pet.Name == petName then
                        services.ReplicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
                        equippedCount = equippedCount + 1
                        task.wait(0.05)
                    end
                end
            end
        end)
        
        -- 2. Farmear strength hasta el target para el próximo rebirth
        local currentRebirths = tabs.fast.FastRebirthData.Rebirths.Value
        local targetStrength = 5000 + currentRebirths * 2550
        local repsPerBurst = utils.playerData.Player.MembershipType == Enum.MembershipType.Premium and 6 or 12
        
        tabs.fast.FastRebirthStatus.Text = "Status: 💪 Farmeando... " 
            .. utils.formatNumber(tabs.fast.FastRebirthData.Strength.Value) 
            .. " / " .. utils.formatNumber(targetStrength)
        tabs.fast.FastRebirthStatus.TextColor3 = Color3.fromRGB(80, 255, 120)
        
        -- Farmear hasta llegar al target
        while utils.isCurrent() and tabs.fast.FastRebirthData.Running 
            and tabs.fast.FastRebirthData.Strength.Value < targetStrength do
            
            for i = 1, repsPerBurst do
                pcall(function()
                    utils.remotes.MuscleEvent:FireServer("rep")
                end)
            end
            task.wait(0.02)
            
            -- Actualizar stats
            tabs.fast.FastRebirthStats.Text = "Rebirths: " 
                .. utils.formatWithCommas(tabs.fast.FastRebirthData.Rebirths.Value) 
                .. " | Gained: " 
                .. utils.formatWithCommas(tabs.fast.FastRebirthData.Rebirths.Value - startRebirths)
        end
        
        -- 3. Hacer el rebirth
        if utils.isCurrent() and tabs.fast.FastRebirthData.Running 
            and tabs.fast.FastRebirthData.Strength.Value >= targetStrength then
            
            tabs.fast.FastRebirthStatus.Text = "Status: 🔄 Haciendo rebirth..."
            tabs.fast.FastRebirthStatus.TextColor3 = Color3.fromRGB(255, 200, 80)
            
            local rebirthValueBefore = tabs.fast.FastRebirthData.Rebirths.Value
            local attempts = 0
            
            repeat
                pcall(function()
                    services.ReplicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
                end)
                task.wait(0.05)
                attempts = attempts + 1
            until not tabs.fast.FastRebirthData.Running 
                or tabs.fast.FastRebirthData.Rebirths.Value > rebirthValueBefore 
                or attempts >= 50
            
            if tabs.fast.FastRebirthData.Rebirths.Value > rebirthValueBefore then
                tabs.fast.FastRebirthData.TotalRebirths = tabs.fast.FastRebirthData.TotalRebirths + 
                    (tabs.fast.FastRebirthData.Rebirths.Value - rebirthValueBefore)
                tabs.fast.FastRebirthData.LastRebirthTime = tick()
            end
        end
        
        -- Calcular velocidad cada segundo
        if tick() - lastCheck >= 1 then
            local currentCount = tabs.fast.FastRebirthData.Rebirths.Value
            local gained = currentCount - lastRebirthCount
            tabs.fast.FastRebirthSpeed.Text = "Speed: " .. gained .. " rebirths/s"
            lastRebirthCount = currentCount
            lastCheck = tick()
        end
        
        task.wait(0.3)
    end
    
    tabs.fast.FastRebirthData.WorkerActive = false
end

tabs.fast:AddTextBox("Target rebirths (0 = infinito):", function(text)
    local num = tonumber(text)
    if num and num >= 0 then
        tabs.fast.FastRebirthData.TargetRebirths = math.floor(num)
    end
end, {clear = false})

tabs.fast.FastRebirthToggle = tabs.fast:AddSwitch("Fast Rebirth 🔄", function(state)
    tabs.fast.FastRebirthData.Running = state
    if state then
        tabs.fast.FastRebirthStatus.Text = "Status: 🔄 Iniciando..."
        tabs.fast.FastRebirthStatus.TextColor3 = Color3.fromRGB(80, 255, 120)
        
        if not tabs.fast.FastRebirthData.WorkerActive then
            tabs.fast.FastRebirthData.WorkerActive = true
            task.spawn(tabs.fast.FastRebirthWorker)
        end
    else
        tabs.fast.FastRebirthStatus.Text = "Status: Inactive"
        tabs.fast.FastRebirthStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end)

tabs.fast:AddLabel("🔄 Auto farmea + rebirth automático")
-- FAST REBIRTH V2 - 2 Apartados (Ultra Titans + Chaos Overlords) - RÁPIDO
tabs.fast:AddLabel("")
tabs.fast:AddLabel("Fast Rebirth V2:")
tabs.fast:AddLabel("")

-- =========================================
-- FUNCIONES AUXILIARES RÁPIDAS
-- =========================================
tabs.fast.desequipAll = function()
    local player = utils.playerData.Player
    local petsFolder = player.petsFolder
    
    -- Desequipar TODAS las mascotas en TODAS las carpetas
    for _, folder in pairs(petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                pcall(function()
                    services.ReplicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
                end)
            end
        end
    end
    
    -- Buscar en el Character también
    if player.Character then
        for _, obj in pairs(player.Character:GetChildren()) do
            if obj:IsA("StringValue") or obj:IsA("ObjectValue") then
                pcall(function()
                    services.ReplicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", obj)
                end)
            end
        end
    end
    
    task.wait(0.3)
end

tabs.fast.equipPets = function(petNames)
    local petsFolder = utils.playerData.Player.petsFolder
    local uniquePets = petsFolder.Unique
    
    -- Desequipar
    tabs.fast.desequipAll()
    task.wait(0.2)
    
    -- Equipar
    local equipped = 0
    for _, petName in ipairs(petNames) do
        for _, pet in pairs(uniquePets:GetChildren()) do
            if pet.Name == petName then
                pcall(function()
                    services.ReplicatedStorage.rEvents.equipPetEvent:FireServer("equipPet", pet)
                end)
                equipped = equipped + 1
                task.wait(0.05)
            end
        end
    end
    
    task.wait(0.3)
    return equipped
end

-- =========================================
-- APARTADO 1: ULTRA TITANS PACK
-- =========================================
tabs.fast:AddLabel("Ultra Titans Pack:")

tabs.fast.UltraData = {
    Running = false,
    WorkerActive = false,
    Rebirths = utils.playerData.Player.leaderstats:WaitForChild("Rebirths"),
    Strength = utils.playerData.Player.leaderstats:WaitForChild("Strength"),
    TargetRebirths = 0,
    TotalRebirths = 0,
    RepPets = {"Omega Overlord"},
    RebirthPets = {"Titanium Hydra"}
}

tabs.fast.UltraStatus = tabs.fast:AddLabel("Status: Inactive")
tabs.fast.UltraStatus.TextColor3 = Color3.fromRGB(255, 80, 80)

tabs.fast.UltraStats = tabs.fast:AddLabel("Rebirths: 0 | Gained: 0")

tabs.fast.UltraWorker = function()
    local startRebirths = tabs.fast.UltraData.Rebirths.Value

    while utils.isCurrent() and tabs.fast.UltraData.Running do
        if tabs.fast.UltraData.TargetRebirths > 0
            and tabs.fast.UltraData.Rebirths.Value >= tabs.fast.UltraData.TargetRebirths then
            tabs.fast.UltraStatus.Text = "Status: Target alcanzado"
            tabs.fast.UltraStatus.TextColor3 = Color3.fromRGB(80, 255, 120)
            tabs.fast.UltraData.Running = false
            break
        end

        -- PASO 1: EQUIPAR REP (rápido)
        tabs.fast.UltraStatus.Text = "Status: Equipando Rep..."
        tabs.fast.UltraStatus.TextColor3 = Color3.fromRGB(255, 200, 80)
        
        local equippedRep = 0
        pcall(function()
            equippedRep = tabs.fast.equipPets(tabs.fast.UltraData.RepPets)
        end)
        
        tabs.fast.UltraStatus.Text = "Status: " .. equippedRep .. " Rep equipados"

        -- PASO 2: FARMEAR
        local currentRebirths = tabs.fast.UltraData.Rebirths.Value
        local targetStrength = 5000 + currentRebirths * 2550
        local repsPerBurst = utils.playerData.Player.MembershipType == Enum.MembershipType.Premium and 6 or 12

        tabs.fast.UltraStatus.Text = "Status: Farmeando..."
        tabs.fast.UltraStatus.TextColor3 = Color3.fromRGB(80, 255, 120)

        while utils.isCurrent() and tabs.fast.UltraData.Running
            and tabs.fast.UltraData.Strength.Value < targetStrength do
            pcall(function()
                for i = 1, repsPerBurst do
                    utils.remotes.MuscleEvent:FireServer("rep")
                end
            end)
            task.wait(0.05)
            tabs.fast.UltraStats.Text = "Rebirths: "
                .. utils.formatWithCommas(tabs.fast.UltraData.Rebirths.Value)
                .. " | Gained: "
                .. utils.formatWithCommas(tabs.fast.UltraData.Rebirths.Value - startRebirths)
        end

        -- PASO 3: EQUIPAR REBIRTH PETS (rápido)
        if utils.isCurrent() and tabs.fast.UltraData.Running
            and tabs.fast.UltraData.Strength.Value >= targetStrength then

            tabs.fast.UltraStatus.Text = "Status: Equipando Hydra..."
            tabs.fast.UltraStatus.TextColor3 = Color3.fromRGB(255, 150, 255)
            
            local equippedReb = 0
            pcall(function()
                equippedReb = tabs.fast.equipPets(tabs.fast.UltraData.RebirthPets)
            end)
            
            tabs.fast.UltraStatus.Text = "Status: " .. equippedReb .. " Hydra equipadas"
            task.wait(0.5)

            -- PASO 4: REBIRTH
            tabs.fast.UltraStatus.Text = "Status: Haciendo Rebirth..."
            tabs.fast.UltraStatus.TextColor3 = Color3.fromRGB(255, 200, 80)

            local rebirthBefore = tabs.fast.UltraData.Rebirths.Value
            local attempts = 0

            repeat
                pcall(function()
                    services.ReplicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
                end)
                task.wait(0.05)
                attempts = attempts + 1
            until not tabs.fast.UltraData.Running
                or tabs.fast.UltraData.Rebirths.Value > rebirthBefore
                or attempts >= 50

            if tabs.fast.UltraData.Rebirths.Value > rebirthBefore then
                tabs.fast.UltraData.TotalRebirths = tabs.fast.UltraData.TotalRebirths +
                    (tabs.fast.UltraData.Rebirths.Value - rebirthBefore)
            end
            
            task.wait(0.5)
        end
        task.wait(0.1)
    end
    tabs.fast.UltraData.WorkerActive = false
end

tabs.fast:AddTextBox("Ultra - Target rebirths (0 = inf):", function(text)
    local num = tonumber(text)
    if num and num >= 0 then
        tabs.fast.UltraData.TargetRebirths = math.floor(num)
    end
end, {clear = false})

tabs.fast.UltraToggle = tabs.fast:AddSwitch("Fast Rebirth Ultra Titans", function(state)
    tabs.fast.UltraData.Running = state
    if state then
        tabs.fast.UltraStatus.Text = "Status: Iniciando Ultra..."
        tabs.fast.UltraStatus.TextColor3 = Color3.fromRGB(80, 255, 120)
        if not tabs.fast.UltraData.WorkerActive then
            tabs.fast.UltraData.WorkerActive = true
            task.spawn(tabs.fast.UltraWorker)
        end
    else
        tabs.fast.UltraStatus.Text = "Status: Inactive"
        tabs.fast.UltraStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end)

tabs.fast:AddLabel("Omega Overlord > Farm > Titanium Hydra > Rebirth")

-- =========================================
-- APARTADO 2: CHAOS OVERLORDS PACK
-- =========================================
tabs.fast:AddLabel("")
tabs.fast:AddLabel("Chaos Overlords Pack:")

tabs.fast.ChaosData = {
    Running = false,
    WorkerActive = false,
    Rebirths = utils.playerData.Player.leaderstats:WaitForChild("Rebirths"),
    Strength = utils.playerData.Player.leaderstats:WaitForChild("Strength"),
    TargetRebirths = 0,
    TotalRebirths = 0,
    RepPets = {"Swift Samurai"},
    RebirthPets = {"Tribal Overlord"}
}

tabs.fast.ChaosStatus = tabs.fast:AddLabel("Status: Inactive")
tabs.fast.ChaosStatus.TextColor3 = Color3.fromRGB(255, 80, 80)

tabs.fast.ChaosStats = tabs.fast:AddLabel("Rebirths: 0 | Gained: 0")

tabs.fast.ChaosWorker = function()
    local startRebirths = tabs.fast.ChaosData.Rebirths.Value

    while utils.isCurrent() and tabs.fast.ChaosData.Running do
        if tabs.fast.ChaosData.TargetRebirths > 0
            and tabs.fast.ChaosData.Rebirths.Value >= tabs.fast.ChaosData.TargetRebirths then
            tabs.fast.ChaosStatus.Text = "Status: Target alcanzado"
            tabs.fast.ChaosStatus.TextColor3 = Color3.fromRGB(80, 255, 120)
            tabs.fast.ChaosData.Running = false
            break
        end

        -- PASO 1: EQUIPAR REP (rápido)
        tabs.fast.ChaosStatus.Text = "Status: Equipando Rep..."
        tabs.fast.ChaosStatus.TextColor3 = Color3.fromRGB(255, 200, 80)
        
        local equippedRep = 0
        pcall(function()
            equippedRep = tabs.fast.equipPets(tabs.fast.ChaosData.RepPets)
        end)
        
        tabs.fast.ChaosStatus.Text = "Status: " .. equippedRep .. " Rep equipados"

        -- PASO 2: FARMEAR
        local currentRebirths = tabs.fast.ChaosData.Rebirths.Value
        local targetStrength = 5000 + currentRebirths * 2550
        local repsPerBurst = utils.playerData.Player.MembershipType == Enum.MembershipType.Premium and 6 or 12

        tabs.fast.ChaosStatus.Text = "Status: Farmeando..."
        tabs.fast.ChaosStatus.TextColor3 = Color3.fromRGB(80, 255, 120)

        while utils.isCurrent() and tabs.fast.ChaosData.Running
            and tabs.fast.ChaosData.Strength.Value < targetStrength do
            pcall(function()
                for i = 1, repsPerBurst do
                    utils.remotes.MuscleEvent:FireServer("rep")
                end
            end)
            task.wait(0.05)
            tabs.fast.ChaosStats.Text = "Rebirths: "
                .. utils.formatWithCommas(tabs.fast.ChaosData.Rebirths.Value)
                .. " | Gained: "
                .. utils.formatWithCommas(tabs.fast.ChaosData.Rebirths.Value - startRebirths)
        end

        -- PASO 3: EQUIPAR REBIRTH PETS (rápido)
        if utils.isCurrent() and tabs.fast.ChaosData.Running
            and tabs.fast.ChaosData.Strength.Value >= targetStrength then

            tabs.fast.ChaosStatus.Text = "Status: Equipando Tribal..."
            tabs.fast.ChaosStatus.TextColor3 = Color3.fromRGB(255, 150, 255)
            
            local equippedReb = 0
            pcall(function()
                equippedReb = tabs.fast.equipPets(tabs.fast.ChaosData.RebirthPets)
            end)
            
            tabs.fast.ChaosStatus.Text = "Status: " .. equippedReb .. " Tribal equipados"
            task.wait(0.5)

            -- PASO 4: REBIRTH
            tabs.fast.ChaosStatus.Text = "Status: Haciendo Rebirth..."
            tabs.fast.ChaosStatus.TextColor3 = Color3.fromRGB(255, 200, 80)

            local rebirthBefore = tabs.fast.ChaosData.Rebirths.Value
            local attempts = 0

            repeat
                pcall(function()
                    services.ReplicatedStorage.rEvents.rebirthRemote:InvokeServer("rebirthRequest")
                end)
                task.wait(0.05)
                attempts = attempts + 1
            until not tabs.fast.ChaosData.Running
                or tabs.fast.ChaosData.Rebirths.Value > rebirthBefore
                or attempts >= 50

            if tabs.fast.ChaosData.Rebirths.Value > rebirthBefore then
                tabs.fast.ChaosData.TotalRebirths = tabs.fast.ChaosData.TotalRebirths +
                    (tabs.fast.ChaosData.Rebirths.Value - rebirthBefore)
            end
            
            task.wait(0.5)
        end
        task.wait(0.1)
    end
    tabs.fast.ChaosData.WorkerActive = false
end

tabs.fast:AddTextBox("Chaos - Target rebirths (0 = inf):", function(text)
    local num = tonumber(text)
    if num and num >= 0 then
        tabs.fast.ChaosData.TargetRebirths = math.floor(num)
    end
end, {clear = false})

tabs.fast.ChaosToggle = tabs.fast:AddSwitch("Fast Rebirth Chaos Overlords", function(state)
    tabs.fast.ChaosData.Running = state
    if state then
        tabs.fast.ChaosStatus.Text = "Status: Iniciando Chaos..."
        tabs.fast.ChaosStatus.TextColor3 = Color3.fromRGB(80, 255, 120)
        if not tabs.fast.ChaosData.WorkerActive then
            tabs.fast.ChaosData.WorkerActive = true
            task.spawn(tabs.fast.ChaosWorker)
        end
    else
        tabs.fast.ChaosStatus.Text = "Status: Inactive"
        tabs.fast.ChaosStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end)

tabs.fast:AddLabel("Swift Samurai > Farm > Tribal Overlord > Rebirth")

-- ============================================
-- TAB INFO
-- ============================================

tabs.info:Show()
tabs.info:AddLabel("Made by Honen")
tabs.info:AddLabel("Any issues? Join our Discord")
tabs.info:AddLabel("Official Discord: discord.gg/bVDtwKF92")
tabs.info:AddButton("Copy Invite", function()
	if setclipboard then
		setclipboard("https://discord.gg/bVDtwKF92")
		game.StarterGui:SetCore("SendNotification", {Title = "Link Copied!", Text = "You can continue to Discord now.", Duration = 3})
	else
		game.StarterGui:SetCore("SendNotification", {Title = "Error!", Text = "Clipboard not Supported.", Duration = 3})
	end
end)
tabs.info:AddLabel("")
tabs.info:AddLabel("Contributors:").TextSize = 17
tabs.info:AddLabel("- cyanam1 (@𝔥𝔬𝔫𝔢𝔶)")
tabs.info:AddLabel("- White @chilin6369")
tabs.info:AddLabel("- Honen @Owner")
tabs.info:AddLabel("")
tabs.info:AddLabel("HonenxWhite is Open-Source!")
tabs.info:AddLabel("")
tabs.info.VersionLabel = tabs.info:AddLabel("Muscle Legends [V4.1.3]")
tabs.info.VersionLabel.TextSize = 20
tabs.info.VersionLabel.Font = Enum.Font.Arcade
