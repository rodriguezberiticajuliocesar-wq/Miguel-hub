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
	main_color = Color3.fromRGB(180, 15, 15),
	min_size = Vector2.new(1000, 1300),
	can_resize = true,
})

-- Anti-AFK con switch manual
AntiAFKState = {Enabled = true}

utils.connect(utils.playerData.Player.Idled, function()
	if AntiAFKState.Enabled then
		pcall(function()
			services.VirtualUser:CaptureController()
			services.VirtualUser:ClickButton2(Vector2.new(0, 0))
			services.VirtualUser:ClickButton1(Vector2.new(0, 0))
		end)
	end
end)

utils.connect(utils.playerData.Player.CharacterAdded, function(character)
	utils.playerData.Character = character
	utils.playerData.Humanoid = character:WaitForChild("Humanoid", 10)
	utils.playerData.Backpack = utils.playerData.Player:WaitForChild("Backpack")
end)

local tabs = {
	main = utils.HonenxWhite:AddTab("Main"),
	killing = utils.HonenxWhite:AddTab("⚔️ Killing"),
	fast = utils.HonenxWhite:AddTab("⚡ Fast"),
	boss = utils.HonenxWhite:AddTab("👹 Boss"),
	estimates = utils.HonenxWhite:AddTab("📊 Estimates"),
	quests = utils.HonenxWhite:AddTab("📜 Quests")
}

for _, tab in pairs(tabs) do
	tab.runtime = {}
end
-- ============================================
-- MAIN TAB
-- ============================================

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

tabs.main:AddSwitch("Anti-AFK", function(bool)
	AntiAFKState.Enabled = bool
end):Set(true)

tabs.main.TimeDropdown = tabs.main:AddDropdown("Change Time", function(selection)
	services.Lighting.ClockTime = selection == "Night" and 0 or 9
end)
tabs.main.TimeDropdown:Add("Night")
tabs.main.TimeDropdown:Add("Day")
-- ============================================
-- KILLING TAB (mínimo para misiones de KOs)
-- ============================================

tabs.killing:AddLabel("Kill Aura (for Quest KOs):")

tabs.killing.KillState = {
	KillAura = false,
	Range = 25
}

tabs.killing:AddTextBox("Range:", function(text)
	text = string.gsub(text, "%s+", "")
	if tonumber(text) and tonumber(text) > 0 and tonumber(text) <= 100 then
		tabs.killing.KillState.Range = tonumber(text)
	end
end, {clear = false})

tabs.killing.KillAuraToggle = tabs.killing:AddSwitch("Kill Aura", function(bool)
	tabs.killing.KillState.KillAura = bool
	if bool then
		task.spawn(function()
			while utils.isCurrent() and tabs.killing.KillState.KillAura do
				pcall(function()
					local localChar = utils.playerData.Player.Character
					local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
					if not localRoot then return end

					for _, player in pairs(services.Players:GetPlayers()) do
						if player ~= utils.playerData.Player and player.Character then
							local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
							local targetHum = player.Character:FindFirstChildOfClass("Humanoid")

							if targetRoot and targetHum and targetHum.Health > 0 then
								local dist = (localRoot.Position - targetRoot.Position).Magnitude
								if dist <= tabs.killing.KillState.Range then
									local leftHand = localChar:FindFirstChild("LeftHand")
									local rightHand = localChar:FindFirstChild("RightHand")

									if leftHand and rightHand then
										pcall(function()
											firetouchinterest(targetRoot, leftHand, 0)
											firetouchinterest(targetRoot, leftHand, 1)
											firetouchinterest(targetRoot, rightHand, 0)
											firetouchinterest(targetRoot, rightHand, 1)
										end)
									end

									if utils.remotes.MuscleEvent then
										utils.remotes.MuscleEvent:FireServer("punch", "leftHand")
										utils.remotes.MuscleEvent:FireServer("punch", "rightHand")
									end
								end
							end
						end
					end
				end)
				task.wait(0.1)
			end
		end)
	end
end)

tabs.killing:AddLabel("Combat:")
tabs.killing:AddLabel("• Solo para misiones de Player KOs")
tabs.killing:AddLabel("• Rango recomendado: 20-30")
-- ============================================
-- FAST TAB
-- ============================================

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

        local repsToSend = math.floor(tabs.fast.FastRepData.SendRate / 60)
        if repsToSend < 1 then repsToSend = 1 end
        if repsToSend > 12 then repsToSend = 12 end

        for i = 1, repsToSend do
            pcall(function()
                utils.remotes.MuscleEvent:FireServer("rep")
            end)
        end

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
        if tabs.fast.FastRebirthData.TargetRebirths > 0
            and tabs.fast.FastRebirthData.Rebirths.Value >= tabs.fast.FastRebirthData.TargetRebirths then
            tabs.fast.FastRebirthStatus.Text = "Status: ✅ Target alcanzado!"
            tabs.fast.FastRebirthStatus.TextColor3 = Color3.fromRGB(80, 255, 120)
            tabs.fast.FastRebirthData.Running = false
            break
        end

        pcall(function()
            local uniquePets = utils.playerData.Player.petsFolder.Unique
            for _, folder in pairs(utils.playerData.Player.petsFolder:GetChildren()) do
                if folder:IsA("Folder") and folder.Name ~= "Unique" then
                    for _, pet in pairs(folder:GetChildren()) do
                        services.ReplicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
                    end
                end
            end
            task.wait(0.1)

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

        local currentRebirths = tabs.fast.FastRebirthData.Rebirths.Value
        local targetStrength = 5000 + currentRebirths * 2550
        local repsPerBurst = utils.playerData.Player.MembershipType == Enum.MembershipType.Premium and 6 or 12

        tabs.fast.FastRebirthStatus.Text = "Status: 💪 Farmeando... "
            .. utils.formatNumber(tabs.fast.FastRebirthData.Strength.Value)
            .. " / " .. utils.formatNumber(targetStrength)
        tabs.fast.FastRebirthStatus.TextColor3 = Color3.fromRGB(80, 255, 120)

        while utils.isCurrent() and tabs.fast.FastRebirthData.Running
            and tabs.fast.FastRebirthData.Strength.Value < targetStrength do

            for i = 1, repsPerBurst do
                pcall(function()
                    utils.remotes.MuscleEvent:FireServer("rep")
                end)
            end
            task.wait(0.02)

            tabs.fast.FastRebirthStats.Text = "Rebirths: "
                .. utils.formatWithCommas(tabs.fast.FastRebirthData.Rebirths.Value)
                .. " | Gained: "
                .. utils.formatWithCommas(tabs.fast.FastRebirthData.Rebirths.Value - startRebirths)
        end

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
-- ============================================
-- FAST REBIRTH V2
-- ============================================

tabs.fast:AddLabel("")
tabs.fast:AddLabel("Fast Rebirth V2:")
tabs.fast:AddLabel("")

tabs.fast.desequipAll = function()
    local player = utils.playerData.Player
    local petsFolder = player.petsFolder

    for _, folder in pairs(petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in pairs(folder:GetChildren()) do
                pcall(function()
                    services.ReplicatedStorage.rEvents.equipPetEvent:FireServer("unequipPet", pet)
                end)
            end
        end
    end

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

    tabs.fast.desequipAll()
    task.wait(0.2)

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

        tabs.fast.UltraStatus.Text = "Status: Equipando Rep..."
        tabs.fast.UltraStatus.TextColor3 = Color3.fromRGB(255, 200, 80)

        local equippedRep = 0
        pcall(function()
            equippedRep = tabs.fast.equipPets(tabs.fast.UltraData.RepPets)
        end)

        tabs.fast.UltraStatus.Text = "Status: " .. equippedRep .. " Rep equipados"

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

        tabs.fast.ChaosStatus.Text = "Status: Equipando Rep..."
        tabs.fast.ChaosStatus.TextColor3 = Color3.fromRGB(255, 200, 80)

        local equippedRep = 0
        pcall(function()
            equippedRep = tabs.fast.equipPets(tabs.fast.ChaosData.RepPets)
        end)

        tabs.fast.ChaosStatus.Text = "Status: " .. equippedRep .. " Rep equipados"

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
-- BOSS TAB
-- ============================================

tabs.boss:AddLabel("Boss Farming:")
tabs.boss.StatusLabel = tabs.boss:AddLabel("Status: Waiting for Boss")
tabs.boss.BossLabel = tabs.boss:AddLabel("Boss: None")
tabs.boss.HealthLabel = tabs.boss:AddLabel("Health: 0 / 0")
tabs.boss.NextBossLabel = tabs.boss:AddLabel("Next Boss: N/A")

tabs.boss.Data = {
	Running = false,
	Generation = 0,
	ContinueTraining = true,
	Phase = "Waiting",
	TrainingSnapshot = nil,
	PunchInterval = 0.3,
	LastPunch = 0,
	AttackSequence = nil,
	EvadeUntil = 0,
	EvadeDistance = 230,
	PunchBehindDistance = 45,
	StompHealthThreshold = 0.35,
	DodgeStomps = false,
	BossConfig = nil,
	Bosses = {},
	BossOrder = {},
	BossByDisplayName = {},
	SelectedBosses = {}
}

tabs.boss.SelectedBossesLabel = tabs.boss:AddLabel("Targeted Bosses: Detecting...")
tabs.boss.BossDropdown = tabs.boss:AddDropdown("Target specific Bosses", function(displayName)
	tabs.boss.runtime.bossModelName = tabs.boss.Data.BossByDisplayName[displayName]
	if tabs.boss.runtime.bossModelName then
		tabs.boss.Data.SelectedBosses[tabs.boss.runtime.bossModelName] = not tabs.boss.Data.SelectedBosses[tabs.boss.runtime.bossModelName]
		tabs.boss.updateSelectedBossesLabel()
	end
end)

tabs.boss.updateSelectedBossesLabel = function(selectedNames)
	selectedNames = {}
	for _, modelName in ipairs(tabs.boss.Data.BossOrder) do
		if tabs.boss.Data.SelectedBosses[modelName] then
			table.insert(selectedNames, (string.gsub(tabs.boss.Data.Bosses[modelName], "%s+[Bb][Oo][Ss][Ss]$", "")))
		end
	end
	tabs.boss.SelectedBossesLabel.Text = "Targeted Bosses: " .. (#selectedNames > 0 and table.concat(selectedNames, ", ") or "None")
end

tabs.boss.addBossChoice = function(modelName, displayName)
	modelName = tostring(modelName or "")
	displayName = tostring(displayName or modelName)
	if modelName == "" or tabs.boss.Data.Bosses[modelName] then return end
	tabs.boss.Data.Bosses[modelName] = displayName
	tabs.boss.Data.BossByDisplayName[displayName] = modelName
	tabs.boss.Data.SelectedBosses[modelName] = true
	table.insert(tabs.boss.Data.BossOrder, modelName)
	tabs.boss.BossDropdown:Add(displayName)
	tabs.boss.updateSelectedBossesLabel()
end

tabs.boss.runtime.configSuccess, tabs.boss.Data.BossConfig = pcall(function()
	return require(services.ReplicatedStorage:WaitForChild("shared"):WaitForChild("config"):WaitForChild("BossEventConfig"))
end)
if tabs.boss.runtime.configSuccess and tabs.boss.Data.BossConfig and tabs.boss.Data.BossConfig.RARITIES then
	for _, rarity in ipairs(tabs.boss.Data.BossConfig.RARITIES) do
		tabs.boss.addBossChoice(rarity.BossModel, rarity.DisplayName or rarity.Name or rarity.BossModel)
	end
else
	tabs.boss.SelectedBossesLabel.Text = "Farmed Bosses: Waiting for detection"
end

tabs.boss.shouldFarmBoss = function(model)
	if not tabs.boss.Data.Bosses[model.Name] then
		tabs.boss.addBossChoice(model.Name, services.Workspace:GetAttribute("BossDisplayName") or model.Name)
	end
	return tabs.boss.Data.SelectedBosses[model.Name] == true
end

tabs.boss.findActiveBoss = function(model, stats, health, maxHealth, hitbox)
	for _, candidate in ipairs(services.CollectionService:GetTagged("BossEventBoss")) do
		if candidate:IsA("Model") and candidate:IsDescendantOf(services.Workspace) then
			model = candidate
			break
		end
	end

	if not model then
		tabs.boss.runtime.events = services.Workspace:FindFirstChild("Events")
		tabs.boss.runtime.bossFolder = tabs.boss.runtime.events and (tabs.boss.runtime.events:FindFirstChild("BossEvent") or tabs.boss.runtime.events:FindFirstChild("BossArena"))
		if tabs.boss.runtime.bossFolder then
			for _, candidate in ipairs(tabs.boss.runtime.bossFolder:GetDescendants()) do
				if candidate:IsA("Model") and (candidate:FindFirstChild("BossDamageHitbox") or candidate:HasTag("BossEventBoss")) then
					model = candidate
					break
				end
			end
		end
	end

	if not model then return end
	stats = model:FindFirstChild("stats")
	health = stats and stats:FindFirstChild("Health")
	maxHealth = stats and stats:FindFirstChild("MaxHealth")
	hitbox = model:FindFirstChild("BossDamageHitbox", true)
	if not hitbox or not hitbox:IsA("BasePart") then return end
	tabs.boss.runtime.currentHealth = health and health.Value or services.Workspace:GetAttribute("BossHealth")
	if typeof(tabs.boss.runtime.currentHealth) == "number" and tabs.boss.runtime.currentHealth <= 0 then return end
	return model, health, maxHealth, hitbox
end

tabs.boss.getBossHealth = function(health)
	return health and health.Value or services.Workspace:GetAttribute("BossHealth") or 0
end

tabs.boss.getBossMaxHealth = function(maxHealth)
	return maxHealth and maxHealth.Value or services.Workspace:GetAttribute("BossMaxHealth") or 0
end

tabs.boss.formatCountdown = function(seconds, hours, minutes)
	seconds = math.max(0, math.floor(seconds or 0))
	hours = math.floor(seconds / 3600)
	minutes = math.floor(seconds % 3600 / 60)
	seconds = seconds % 60
	return string.format("%dh %dmin %ds", hours, minutes, seconds)
end

tabs.boss.getBossHeadPosition = function(model, hitbox, head)
	head = model:FindFirstChild("Head", true) or model:FindFirstChild("head", true)
	if head and head:IsA("BasePart") then return head.Position end
	if head and head:IsA("Bone") then return head.WorldPosition end
	return hitbox.Position + Vector3.new(0, hitbox.Size.Y * 0.35, 0)
end

tabs.boss.getAliveCharacter = function(generation, timeout, startedAt, character, root, humanoid)
	startedAt = os.clock()
	repeat
		character = utils.playerData.Player.Character
		root = character and character:FindFirstChild("HumanoidRootPart")
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			utils.playerData.Character = character
			utils.playerData.Humanoid = humanoid
			return character, root, humanoid
		end
		tabs.boss.StatusLabel.Text = "Status: Waiting for Respawn"
		task.wait(0.1)
	until not tabs.boss.Data.Running
		or tabs.boss.Data.Generation ~= generation
		or (timeout and os.clock() - startedAt >= timeout)
end

tabs.boss.evadeAttack = function(model, hitbox, root, humanoid, sequence, attackKind, attackCFrame, impactTime, direction, safePosition, center)
	sequence = model:GetAttribute("BossAttackSequence")
	attackKind = model:GetAttribute("BossAttackKind")
	attackCFrame = model:GetAttribute("BossAttackCFrame")
	impactTime = model:GetAttribute("BossAttackImpactTime")

	if typeof(sequence) == "number" and sequence ~= tabs.boss.Data.AttackSequence then
		tabs.boss.Data.AttackSequence = sequence
		if typeof(attackKind) == "string" and typeof(attackCFrame) == "CFrame" and typeof(impactTime) == "number" then
			tabs.boss.Data.EvadeUntil = impactTime + 0.6
		end
	end

	if typeof(attackCFrame) ~= "CFrame" or services.Workspace:GetServerTimeNow() > tabs.boss.Data.EvadeUntil then
		return
	end

	attackKind = string.lower(tostring(attackKind or ""))
	if string.find(attackKind, "punch", 1, true) then
		center = tabs.boss.getBossHeadPosition(model, hitbox)
		direction = Vector3.new(attackCFrame.LookVector.X, 0, attackCFrame.LookVector.Z)
		if direction.Magnitude < 1 then direction = Vector3.new(hitbox.CFrame.LookVector.X, 0, hitbox.CFrame.LookVector.Z) end
		if direction.Magnitude < 1 then direction = Vector3.new(0, 0, 1) end
		safePosition = center - direction.Unit * tabs.boss.Data.PunchBehindDistance
		root.CFrame = CFrame.lookAt(safePosition, center)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		tabs.boss.StatusLabel.Text = "Status: Dodging Punch"
		return "Punch"
	end

	if not string.find(attackKind, "stomp", 1, true) then return end
	if humanoid.Health / math.max(humanoid.MaxHealth, 1) <= tabs.boss.Data.StompHealthThreshold then
		tabs.boss.Data.DodgeStomps = true
	end
	if not tabs.boss.Data.DodgeStomps then return end

	direction = Vector3.new(root.Position.X - attackCFrame.Position.X, 0, root.Position.Z - attackCFrame.Position.Z)
	if direction.Magnitude < 1 then
		direction = Vector3.new(-attackCFrame.LookVector.X, 0, -attackCFrame.LookVector.Z)
	end
	if direction.Magnitude < 1 then direction = Vector3.new(1, 0, 0) end
	direction = direction.Unit
	safePosition = attackCFrame.Position + direction * tabs.boss.Data.EvadeDistance + Vector3.new(0, 18, 0)
	root.CFrame = CFrame.lookAt(safePosition, attackCFrame.Position)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	tabs.boss.StatusLabel.Text = "Status: Dodging Stomp"
	return "Stomp"
end

tabs.boss.attack = function(model, health, maxHealth, hitbox, character, root, humanoid, punch, leftHand, rightHand, center, position, evadeMode)
	character = utils.playerData.Player.Character
	root = character and character:FindFirstChild("HumanoidRootPart")
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return end
	evadeMode = tabs.boss.evadeAttack(model, hitbox, root, humanoid)
	if evadeMode == "Stomp" then return end
	punch = character:FindFirstChild("Punch") or utils.playerData.Backpack:FindFirstChild("Punch")
	if punch and punch.Parent ~= character then humanoid:EquipTool(punch) end
	leftHand = character:FindFirstChild("LeftHand")
	rightHand = character:FindFirstChild("RightHand")
	center = tabs.boss.getBossHeadPosition(model, hitbox)
	if evadeMode ~= "Punch" then
		position = center
		root.CFrame = CFrame.lookAt(position, position + hitbox.CFrame.LookVector)
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	pcall(function()
		if leftHand then
			firetouchinterest(hitbox, leftHand, 0)
			firetouchinterest(hitbox, leftHand, 1)
		end
		if rightHand then
			firetouchinterest(hitbox, rightHand, 0)
			firetouchinterest(hitbox, rightHand, 1)
		end
	end)

	if os.clock() - tabs.boss.Data.LastPunch >= tabs.boss.Data.PunchInterval then
		tabs.boss.Data.LastPunch = os.clock()
		pcall(function()
			utils.remotes.MuscleEvent:FireServer("punch", "leftHand")
			utils.remotes.MuscleEvent:FireServer("punch", "rightHand")
			if punch then punch:Activate() end
		end)
	end

	tabs.boss.BossLabel.Text = "Boss: " .. (services.Workspace:GetAttribute("BossDisplayName") or model.Name)
	tabs.boss.runtime.health = tabs.boss.getBossHealth(health)
	tabs.boss.runtime.maxHealth = tabs.boss.getBossMaxHealth(maxHealth)
	tabs.boss.HealthLabel.Text = "Health: " .. utils.formatNumber(tabs.boss.runtime.health) .. " / " .. utils.formatNumber(tabs.boss.runtime.maxHealth)
end

tabs.boss.findChest = function(chest, prompt, part)
	for _, candidate in ipairs(services.CollectionService:GetTagged("BossEventChest")) do
		if candidate:IsDescendantOf(services.Workspace) then chest = candidate break end
	end
	if not chest then chest = services.Workspace:FindFirstChild("BossChest", true) end
	if not chest then
		for _, candidate in ipairs(services.Workspace:GetDescendants()) do
			if candidate:IsA("ProximityPrompt") and candidate.Name == "bossChestPrompt" then
				chest = candidate.Parent
				break
			end
		end
	end
	if not chest then return end
	prompt = chest:FindFirstChild("bossChestPrompt", true)
	part = prompt and prompt.Parent or (chest:IsA("Model") and (chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart", true))) or chest
	if part and part:IsA("BasePart") then return chest, prompt, part end
end

tabs.boss.collectChest = function(generation, startedAt, chest, prompt, part, character, root)
	tabs.boss.StatusLabel.Text = "Status: Waiting for Chest"
	startedAt = os.clock()
	repeat
		chest, prompt, part = tabs.boss.findChest()
		if chest and chest:GetAttribute("BossChestEmerging") ~= true then break end
		task.wait(0.1)
	until not tabs.boss.Data.Running or tabs.boss.Data.Generation ~= generation or os.clock() - startedAt >= 12
	if not chest or not part then return end

	tabs.boss.StatusLabel.Text = "Status: Collecting Chest"
	startedAt = os.clock()
	repeat
		character, root = tabs.boss.getAliveCharacter(generation, 2)
		if character and root and chest.Parent and part.Parent then
			tabs.boss.StatusLabel.Text = "Status: Collecting Chest"
			pcall(function()
				root.CFrame = CFrame.lookAt(part.Position + Vector3.new(0, 3, 4), part.Position)
				root.AssemblyLinearVelocity = Vector3.zero
			end)
			task.wait(0.15)
			if prompt and prompt.Parent and fireproximityprompt then
				pcall(function() fireproximityprompt(prompt) end)
			else
				pcall(function()
					services.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
					task.wait(0.1)
					services.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
				end)
			end
		end
		task.wait(0.25)
	until not tabs.boss.Data.Running
		or tabs.boss.Data.Generation ~= generation
		or utils.playerData.Player:GetAttribute("BossChestPending") == false
		or not chest.Parent
		or os.clock() - startedAt >= 12
end

tabs.boss.ContinueSwitch = tabs.boss:AddSwitch("Continue Farming after Boss Kill", function(state)
	tabs.boss.Data.ContinueTraining = state
end)
tabs.boss.ContinueSwitch:Set(false)

task.spawn(function(model, health, maxHealth, hitbox, currentHealth, currentMaxHealth, nextTime)
	while utils.isCurrent() and true do
		model, health, maxHealth, hitbox = tabs.boss.findActiveBoss()
		if model then
			currentHealth = tabs.boss.getBossHealth(health)
			currentMaxHealth = tabs.boss.getBossMaxHealth(maxHealth)
			tabs.boss.BossLabel.Text = "Boss: " .. (services.Workspace:GetAttribute("BossDisplayName") or model.Name)
			tabs.boss.HealthLabel.Text = "Health: " .. utils.formatNumber(currentHealth) .. " / " .. utils.formatNumber(currentMaxHealth)
			tabs.boss.NextBossLabel.Text = "Next Boss: Current boss active"
		else
			tabs.boss.BossLabel.Text = "Boss: None"
			tabs.boss.HealthLabel.Text = "Health: 0 / 0"
			nextTime = services.Workspace:GetAttribute("BossSpawnNextTime")
			tabs.boss.NextBossLabel.Text = typeof(nextTime) == "number"
				and "Next Boss: " .. tabs.boss.formatCountdown(nextTime - services.Workspace:GetServerTimeNow())
				or "Next Boss: N/A"
		end
		task.wait(0.25)
	end
end)

tabs.boss.AutoFarmSwitch = tabs.boss:AddSwitch("Auto Farm Boss", function(state)
	tabs.boss.Data.Running = state
	tabs.boss.Data.Generation += 1
	tabs.boss.runtime.generation = tabs.boss.Data.Generation
	if not state then
		tabs.boss.Data.Phase = "Waiting"
		tabs.boss.StatusLabel.Text = "Status: Disabled"
		return
	end

	task.spawn(function(generation, wasFighting, model, health, maxHealth, hitbox, selected)
		while utils.isCurrent() and tabs.boss.Data.Running and tabs.boss.Data.Generation == generation do
			pcall(function()
				model, health, maxHealth, hitbox = tabs.boss.findActiveBoss()
				selected = model and tabs.boss.shouldFarmBoss(model)
				if model and not selected then
					if wasFighting then
						wasFighting = false
					end
					tabs.boss.Data.Phase = "Waiting"
					tabs.boss.StatusLabel.Text = "Status: Skipping " .. (services.Workspace:GetAttribute("BossDisplayName") or model.Name)
				elseif model then
					if not wasFighting then
						wasFighting = true
						tabs.boss.Data.Phase = "Fighting"
						tabs.boss.Data.AttackSequence = nil
						tabs.boss.Data.EvadeUntil = 0
						tabs.boss.Data.DodgeStomps = false
					end
					if utils.playerData.Player.Character
						and utils.playerData.Player.Character:FindFirstChildOfClass("Humanoid")
						and utils.playerData.Player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
						tabs.boss.StatusLabel.Text = "Status: Fighting"
						tabs.boss.attack(model, health, maxHealth, hitbox)
					else
						tabs.boss.StatusLabel.Text = "Status: Waiting for Respawn"
					end
				elseif wasFighting then
					wasFighting = false
					tabs.boss.Data.Phase = "Collecting"
					pcall(tabs.boss.collectChest, generation)
					tabs.boss.BossLabel.Text = "Boss: None"
					tabs.boss.HealthLabel.Text = "Health: 0 / 0"
					tabs.boss.Data.Phase = "Waiting"
					tabs.boss.StatusLabel.Text = "Status: Waiting for Boss"
				else
					tabs.boss.StatusLabel.Text = "Status: Waiting for Boss"
				end
			end)
			task.wait(model and selected and 0.03 or 0.25)
		end
	end, tabs.boss.runtime.generation)
end)
-- ============================================
-- ESTIMATES TAB
-- ============================================

tabs.estimates:AddLabel("📊 Gain Estimates")
tabs.estimates:AddLabel("Mide tu ritmo real durante 60 segundos")

tabs.estimates.Data = {
	Active = false,
	StartTime = 0,
	Calibrated = false,
	CalibrationTime = 60,
	LastUpdate = 0,
	StartStrength = 0,
	StartRebirths = 0,
	StrengthRate = 0,
	RebirthsRate = 0,
	WorkerActive = false,
	Generation = 0
}

tabs.estimates.StatusLabel = tabs.estimates:AddLabel("Status: Inactive")
tabs.estimates.StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)

tabs.estimates.CalibLabel = tabs.estimates:AddLabel("Calibración: --")
tabs.estimates.CalibLabel.TextColor3 = Color3.fromRGB(255, 200, 80)

tabs.estimates:AddLabel("— Strength —")

tabs.estimates.StrengthLabels = {
	Hour = tabs.estimates:AddLabel("1 Hora: 0"),
	Day = tabs.estimates:AddLabel("1 Día: 0"),
	Week = tabs.estimates:AddLabel("1 Semana: 0"),
	Month = tabs.estimates:AddLabel("1 Mes: 0"),
	Rate = tabs.estimates:AddLabel("Ritmo actual: 0 /s")
}

tabs.estimates:AddLabel("— Rebirths —")

tabs.estimates.RebirthsLabels = {
	Hour = tabs.estimates:AddLabel("1 Hora: 0"),
	Day = tabs.estimates:AddLabel("1 Día: 0"),
	Week = tabs.estimates:AddLabel("1 Semana: 0"),
	Month = tabs.estimates:AddLabel("1 Mes: 0"),
	Rate = tabs.estimates:AddLabel("Ritmo actual: 0 /s")
}

tabs.estimates.Worker = function()
	tabs.estimates.Data.WorkerActive = true

	while utils.isCurrent() and tabs.estimates.Data.Active do
		local elapsed = tick() - tabs.estimates.Data.StartTime

		if not tabs.estimates.Data.Calibrated then
			local remaining = tabs.estimates.Data.CalibrationTime - elapsed
			if remaining <= 0 then
				tabs.estimates.Data.Calibrated = true
				tabs.estimates.StatusLabel.Text = "Status: ✅ Calibrado"
				tabs.estimates.StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
				tabs.estimates.CalibLabel.Text = "Calibración completada"
				tabs.estimates.CalibLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
			else
				tabs.estimates.CalibLabel.Text = string.format("Calibrando... %ds restantes", math.floor(remaining))
			end
		end

		local currentStrength = strengthStat.Value
		local currentRebirths = utils.playerData.Player.leaderstats.Rebirths.Value

		local strengthGained = currentStrength - tabs.estimates.Data.StartStrength
		local rebirthsGained = currentRebirths - tabs.estimates.Data.StartRebirths

		if elapsed > 0 then
			tabs.estimates.Data.StrengthRate = strengthGained / elapsed
			tabs.estimates.Data.RebirthsRate = rebirthsGained / elapsed
		end

		local sRate = tabs.estimates.Data.StrengthRate
		local rRate = tabs.estimates.Data.RebirthsRate

		tabs.estimates.StrengthLabels.Rate.Text = "Ritmo actual: " .. utils.formatNumber(sRate) .. " /s"
		tabs.estimates.StrengthLabels.Hour.Text = "1 Hora: " .. utils.formatNumber(sRate * 3600)
		tabs.estimates.StrengthLabels.Day.Text = "1 Día: " .. utils.formatNumber(sRate * 86400)
		tabs.estimates.StrengthLabels.Week.Text = "1 Semana: " .. utils.formatNumber(sRate * 604800)
		tabs.estimates.StrengthLabels.Month.Text = "1 Mes: " .. utils.formatNumber(sRate * 2592000)

		tabs.estimates.RebirthsLabels.Rate.Text = "Ritmo actual: " .. string.format("%.2f", rRate) .. " /s"
		tabs.estimates.RebirthsLabels.Hour.Text = "1 Hora: " .. utils.formatNumber(rRate * 3600)
		tabs.estimates.RebirthsLabels.Day.Text = "1 Día: " .. utils.formatNumber(rRate * 86400)
		tabs.estimates.RebirthsLabels.Week.Text = "1 Semana: " .. utils.formatNumber(rRate * 604800)
		tabs.estimates.RebirthsLabels.Month.Text = "1 Mes: " .. utils.formatNumber(rRate * 2592000)

		task.wait(1)
	end

	tabs.estimates.Data.WorkerActive = false
end

tabs.estimates.Toggle = tabs.estimates:AddSwitch("Activar Estimates", function(state)
	tabs.estimates.Data.Active = state

	if state then
		tabs.estimates.Data.StartTime = tick()
		tabs.estimates.Data.Calibrated = false
		tabs.estimates.Data.StartStrength = strengthStat.Value
		tabs.estimates.Data.StartRebirths = utils.playerData.Player.leaderstats.Rebirths.Value

		tabs.estimates.StatusLabel.Text = "Status: 🟡 Calibrando..."
		tabs.estimates.StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
		tabs.estimates.CalibLabel.Text = "Calibrando... 60s restantes"
		tabs.estimates.CalibLabel.TextColor3 = Color3.fromRGB(255, 200, 80)

		if not tabs.estimates.Data.WorkerActive then
			task.spawn(tabs.estimates.Worker)
		end
	else
		tabs.estimates.StatusLabel.Text = "Status: Inactive"
		tabs.estimates.StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		tabs.estimates.CalibLabel.Text = "Calibración: --"
		tabs.estimates.CalibLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
	end
end)

tabs.estimates:AddButton("Resetear", function()
	tabs.estimates.Data.StartTime = tick()
	tabs.estimates.Data.Calibrated = false
	tabs.estimates.Data.StartStrength = strengthStat.Value
	tabs.estimates.Data.StartRebirths = utils.playerData.Player.leaderstats.Rebirths.Value
	tabs.estimates.CalibLabel.Text = "Calibrando... 60s restantes"
	tabs.estimates.CalibLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
	tabs.estimates.StatusLabel.Text = "Status: 🟡 Recalibrando..."
	tabs.estimates.StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
end)

tabs.estimates:AddLabel("")
tabs.estimates:AddLabel("Nota: Los primeros 60s son de calibración")
tabs.estimates:AddLabel("Después verás las proyecciones")
-- ============================================
-- QUESTS TAB
-- ============================================

tabs.quests:AddLabel("📜 Auto Quests")
tabs.quests:AddLabel("Selecciona una misión y actívala")

tabs.quests.Data = {
	SelectedQuest = nil,
	SelectedLevel = "1",
	Running = false,
	WorkerActive = false,
	Generation = 0,
	Quests = {},
	AllQuests = {},
	Status = "Idle"
}

tabs.quests.StatusLabel = tabs.quests:AddLabel("Status: Idle")
tabs.quests.StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)

tabs.quests.QuestLabel = tabs.quests:AddLabel("Misión: Ninguna")
tabs.quests.ObjectiveLabel = tabs.quests:AddLabel("Objetivo: --")
tabs.quests.ProgressLabel = tabs.quests:AddLabel("Progreso: -- / --")

tabs.quests.QuestDropdown = tabs.quests:AddDropdown("Selecciona Misión", function(selection)
	tabs.quests.Data.SelectedQuest = selection
	tabs.quests.QuestLabel.Text = "Misión: " .. selection

	local questFolder = game:GetService("ReplicatedStorage").shared.catalogs.Quests.Story:FindFirstChild(selection)
	if questFolder and questFolder:FindFirstChild("Quests") then
		local levels = {}
		for _, lvl in ipairs(questFolder.Quests:GetChildren()) do
			table.insert(levels, lvl.Name)
		end
		table.sort(levels)
		if tabs.quests.LevelDropdown then
			tabs.quests.LevelDropdown:Clear()
			for _, lvl in ipairs(levels) do
				tabs.quests.LevelDropdown:Add(lvl)
			end
		end
	end
end)

tabs.quests.LevelDropdown = tabs.quests:AddDropdown("Selecciona Nivel", function(selection)
	tabs.quests.Data.SelectedLevel = selection
end)

-- Cargar misiones
task.spawn(function()
	task.wait(1)
	local storyFolder = game:GetService("ReplicatedStorage").shared.catalogs.Quests:FindFirstChild("Story")
	if storyFolder then
		for _, quest in ipairs(storyFolder:GetChildren()) do
			if quest:FindFirstChild("Quests") then
				tabs.quests.Data.AllQuests[quest.Name] = quest
				pcall(function()
					tabs.quests.QuestDropdown:Add(quest.Name)
				end)
			end
		end
	end
end)

-- Función para leer requisitos de una misión
tabs.quests.getRequirements = function(questName, level)
	local questFolder = game:GetService("ReplicatedStorage").shared.catalogs.Quests.Story:FindFirstChild(questName)
	if not questFolder then return nil end
	local levelFolder = questFolder:FindFirstChild("Quests") and questFolder.Quests:FindFirstChild(tostring(level))
	if not levelFolder then return nil end
	local reqFolder = levelFolder:FindFirstChild("requirements")
	if not reqFolder then return nil end

	local reqs = {}
	for _, req in ipairs(reqFolder:GetChildren()) do
		reqs[req.Name] = req.Value
	end
	return reqs, levelFolder
end

-- Función para detectar el tipo de requisito
tabs.quests.getQuestType = function(reqs)
	if reqs["Strength"] then return "Strength", reqs["Strength"] end
	if reqs["Rebirths"] then return "Rebirths", reqs["Rebirths"] end
	if reqs["Agility"] then return "Agility", reqs["Agility"] end
	if reqs["Player KOs"] then return "KOs", reqs["Player KOs"] end
	if reqs["NPCs"] then return "NPCs", reqs["NPCs"] end
	return nil, nil
end

-- Activar función según tipo
tabs.quests.activateForType = function(questType, amount)
	if questType == "Strength" then
		if tabs.fast.FastRepToggle then tabs.fast.FastRepToggle:Set(true) end
	elseif questType == "Rebirths" then
		if tabs.fast.FastRebirthToggle then tabs.fast.FastRebirthToggle:Set(true) end
		if tabs.fast.FastRebirthData then tabs.fast.FastRebirthData.TargetRebirths = amount end
	elseif questType == "KOs" then
		if tabs.killing and tabs.killing.KillAuraToggle then
			tabs.killing.KillAuraToggle:Set(true)
		end
	end
end

tabs.quests.deactivateAll = function()
	if tabs.fast.FastRepToggle then pcall(function() tabs.fast.FastRepToggle:Set(false) end) end
	if tabs.fast.FastRebirthToggle then pcall(function() tabs.fast.FastRebirthToggle:Set(false) end) end
	if tabs.killing and tabs.killing.KillAuraToggle then pcall(function() tabs.killing.KillAuraToggle:Set(false) end) end
end

-- Worker principal
tabs.quests.Worker = function()
	tabs.quests.Data.WorkerActive = true
	tabs.quests.Data.Status = "Running"

	while utils.isCurrent() and tabs.quests.Data.Running do
		local questName = tabs.quests.Data.SelectedQuest
		local level = tabs.quests.Data.SelectedLevel

		if questName and level then
			local reqs, levelFolder = tabs.quests.getRequirements(questName, level)

			if reqs then
				local questType, amount = tabs.quests.getQuestType(reqs)

				if questType then
					tabs.quests.ObjectiveLabel.Text = "Objetivo: " .. questType .. " x" .. utils.formatWithCommas(amount)
					tabs.quests.StatusLabel.Text = "Status: Auto " .. questType
					tabs.quests.StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 120)

					tabs.quests.activateForType(questType, amount)

					-- Esperar a completar
					local completed = false
					local startTime = tick()

					while utils.isCurrent() and tabs.quests.Data.Running and not completed do
						if questType == "Strength" then
							if strengthStat.Value >= amount then completed = true end
							tabs.quests.ProgressLabel.Text = "Progreso: " .. utils.formatNumber(strengthStat.Value) .. " / " .. utils.formatNumber(amount)
						elseif questType == "Rebirths" then
							local cur = utils.playerData.Player.leaderstats.Rebirths.Value
							if cur >= amount then completed = true end
							tabs.quests.ProgressLabel.Text = "Progreso: " .. cur .. " / " .. amount
						elseif questType == "KOs" then
							local cur = utils.playerData.Player.leaderstats:FindFirstChild("Kills") and utils.playerData.Player.leaderstats.Kills.Value or 0
							if cur >= amount then completed = true end
							tabs.quests.ProgressLabel.Text = "Progreso: " .. cur .. " / " .. amount
						elseif questType == "Agility" then
							local cur = utils.playerData.Player:FindFirstChild("Agility") and utils.playerData.Player.Agility.Value or 0
							if cur >= amount then completed = true end
							tabs.quests.ProgressLabel.Text = "Progreso: " .. cur .. " / " .. amount
						else
							completed = true
						end

						task.wait(0.5)
					end

					if completed and tabs.quests.Data.Running then
						tabs.quests.StatusLabel.Text = "Status: ✅ Completado! Siguiente..."
						tabs.quests.StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
						tabs.quests.deactivateAll()
						task.wait(3)
					end
				else
					tabs.quests.StatusLabel.Text = "Status: Tipo no soportado"
					tabs.quests.StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
					task.wait(2)
				end
			else
				tabs.quests.StatusLabel.Text = "Status: Misión/Nivel no encontrado"
				tabs.quests.StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				task.wait(2)
			end
		else
			tabs.quests.StatusLabel.Text = "Status: Selecciona misión y nivel"
			tabs.quests.StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
			task.wait(1)
		end

		task.wait(1)
	end

	tabs.quests.Data.WorkerActive = false
	tabs.quests.deactivateAll()
end

tabs.quests.Toggle = tabs.quests:AddSwitch("Auto Quest 🎯", function(state)
	tabs.quests.Data.Running = state
	tabs.quests.Data.Generation += 1

	if state then
		if not tabs.quests.Data.SelectedQuest then
			tabs.quests.StatusLabel.Text = "Status: Selecciona una misión primero"
			tabs.quests.StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			return
		end

		tabs.quests.StatusLabel.Text = "Status: 🎯 Iniciando..."
		tabs.quests.StatusLabel.TextColor3 = Color3.fromRGB(80, 255, 120)

		if not tabs.quests.Data.WorkerActive then
			task.spawn(tabs.quests.Worker)
		end
	else
		tabs.quests.StatusLabel.Text = "Status: Inactive"
		tabs.quests.StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		tabs.quests.deactivateAll()
	end
end)

tabs.quests:AddLabel("")
tabs.quests:AddLabel("Cómo usar:")
tabs.quests:AddLabel("1. Selecciona la misión")
tabs.quests:AddLabel("2. Selecciona el nivel (1, 2, 3...)")
tabs.quests:AddLabel("3. Activa el switch")
tabs.quests:AddLabel("4. Espera a que complete")
tabs.quests:AddLabel("")
tabs.quests:AddLabel("⚠️ El script NO acepta la misión")
tabs.quests:AddLabel("por ti. Debes aceptarla en el juego")
tabs.quests:AddLabel("antes de activar el switch.")
