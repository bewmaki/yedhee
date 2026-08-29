-- CandyAutoFarm.lua
-- Luau port of the External Candy flow. Uses Roblox instances/UI, not memory access.

local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local platformOk, platform = pcall(function() return UserInputService:GetPlatform() end)
local mobilePlatform = platformOk and (platform == Enum.Platform.Android or platform == Enum.Platform.IOS)
local IS_MOBILE = getgenv().AraiForceMobile == true
	or getgenv().SolixForceMobile == true
	or mobilePlatform
	or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)

local function cleanupOldAraiWindows()
	local roots, knownRoots = {}, {}
	local function addRoot(root)
		if typeof(root) == "Instance" and not knownRoots[root] then
			knownRoots[root] = true
			roots[#roots + 1] = root
		end
	end

	if type(gethui) == "function" then
		local ok, hiddenUI = pcall(gethui)
		if ok then addRoot(hiddenUI) end
	end
	local okCore, coreGui = pcall(function() return game:GetService("CoreGui") end)
	if okCore then addRoot(coreGui) end
	addRoot(player:FindFirstChildOfClass("PlayerGui"))

	local oldScreens = {}
	for _, root in ipairs(roots) do
		for _, object in ipairs(root:GetDescendants()) do
			if (object:IsA("TextLabel") or object:IsA("TextButton"))
				and string.find(object.Text, "A-RAI HUB | Never Town", 1, true) then
				local screen = object:FindFirstAncestorOfClass("ScreenGui")
				if screen then oldScreens[screen] = true end
			end
		end
	end
	for screen in pairs(oldScreens) do pcall(function() screen:Destroy() end) end
end

cleanupOldAraiWindows()

local previousLibrary = getgenv().Library
if type(previousLibrary) == "table" and type(previousLibrary.Unload) == "function" then
	pcall(previousLibrary.Unload, previousLibrary)
end
getgenv().Library = nil

local ok, Library = pcall(function()
	if getgenv().AraiUseLocalUILib == true and type(isfile) == "function" and isfile("UILIB.lua") then
		return loadstring(readfile("UILIB.lua"))()
	end
	local cacheBust = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
	local url = "https://raw.githubusercontent.com/bewmaki/yedhee/main/UILIB.lua?cb=" .. cacheBust
	return loadstring(game:HttpGet(url, true))()
end)
if not ok or not Library then
	error("CandyAutoFarm: UILIB load failed: " .. tostring(Library))
end

local old = getgenv().AraiCandyFarm or getgenv().SolixCandyFarm
if type(old) == "table" then
	if type(old.Stop) == "function" then pcall(old.Stop, old) end
	if type(old.Consume) == "table" and type(old.Consume.Stop) == "function" then
		pcall(old.Consume.Stop, old.Consume)
	end
end
local previousESP = getgenv().AraiESP
if type(previousESP) == "table" and type(previousESP.Stop) == "function" then
	pcall(previousESP.Stop, previousESP)
end
getgenv().AraiESP = nil
local previousSpectate = getgenv().AraiSpectate
if type(previousSpectate) == "table" then
	if type(previousSpectate.Shutdown) == "function" then
		pcall(previousSpectate.Shutdown, previousSpectate)
	elseif type(previousSpectate.Stop) == "function" then
		pcall(previousSpectate.Stop, previousSpectate)
	end
end
getgenv().AraiSpectate = nil
local previousGPS = getgenv().AraiGPS
if type(previousGPS) == "table" and type(previousGPS.Stop) == "function" then
	pcall(previousGPS.Stop, previousGPS)
end
getgenv().AraiGPS = nil
local previousInvisible = getgenv().AraiInvisible
if type(previousInvisible) == "table" and type(previousInvisible.Stop) == "function" then
	pcall(previousInvisible.Stop, previousInvisible, true)
end
getgenv().AraiInvisible = nil
local previousAntiAFK = getgenv().AraiAntiAFK
if type(previousAntiAFK) == "table" and type(previousAntiAFK.Stop) == "function" then
	pcall(previousAntiAFK.Stop, previousAntiAFK)
end
getgenv().AraiAntiAFK = nil

local CROPS = {
	{ "Cauliflower", Vector3.new(-4167.1, 74.5, 1250.2), Vector3.new(-4145.3, 84.5, 1253.4), Vector3.new(-0.922, -0.363, -0.136) },
	{ "Peach",       Vector3.new(-5279.7, 97.4, -261.4), Vector3.new(-5289.9, 107.5, -248.7), Vector3.new(0.552, -0.472, -0.687) },
	{ "Orange",      Vector3.new(-4615.1, 122.3, -787.3), Vector3.new(-4618.1, 130.7, -799.4), Vector3.new(0.208, -0.489, 0.847) },
	{ "Corn",        Vector3.new(-4528.1, 117.1, 416.0), Vector3.new(-4539.6, 125.5, 421.1), Vector3.new(0.796, -0.487, -0.358) },
	{ "Grape",       Vector3.new(-5215.9, 97.4, -543.3), Vector3.new(-5227.5, 105.9, -548.1), Vector3.new(0.803, -0.496, 0.331) },
}
local IMAGE_BASE = "https://raw.githubusercontent.com/bewmaki/yedhee/main/assets/candy/"
local CANDY_ICONS = {
	Cauliflower = IMAGE_BASE .. "cauliflower.png",
	Peach = IMAGE_BASE .. "peach.png",
	Orange = IMAGE_BASE .. "orange.png",
	Corn = IMAGE_BASE .. "corn.png",
	Grape = IMAGE_BASE .. "grape.png",
	SeedCandy = IMAGE_BASE .. "seed-candy.png",
}
local REBEL = { nil, Vector3.new(4188.2, 14.9, 4644.4), Vector3.new(4172.4, 25.7, 4642.4), Vector3.new(0.854, -0.508, 0.109) }
local CRAFT = { nil, Vector3.new(-329.9, 2.2, 485.6), Vector3.new(-321.0, 7.5, 484.8), Vector3.new(-0.911, -0.403, 0.085) }
local STAGES = { [0]="Idle", "Opening locker", "Scanning inventory", "Farming", "Farm cooldown", "Crafting SeedCandy x5", "Depositing SeedCandy", "Retrying" }

local Farm = {
	Enabled = false, RunId = 0, Stage = 0, NextCrop = nil, Cooldown = 0, Crafted = 0,
	Counts = {},
	Settings = { Cooldown = 30, Timeout = 720, YOffset = 0, MoveCamera = true },
}
getgenv().AraiCandyFarm = Farm
getgenv().SolixCandyFarm = Farm -- legacy alias for already-running copies
for _, crop in ipairs(CROPS) do Farm.Counts[crop[1]] = 0 end

local statusLabel, craftedLabel, espStatusLabel, spectateStatusLabel, spectateReadyLabel
local gpsStatusLabel, gpsCoordinateLabel
local spectateDropdown
local invisibleToggle
local countLabels = {}
local consumeBusy = false

local function attachIcon(label, url)
	if not label or not label.UI or not label.UI.Framework then return end
	local icon = Instance.new("ImageLabel")
	icon.Name = "CandyIcon"
	icon.AnchorPoint = Vector2.new(1, 0.5)
	icon.Position = UDim2.new(1, -4, 0.5, 0)
	icon.Size = UDim2.fromOffset(34, 34)
	icon.BackgroundTransparency = 1
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 4
	icon.Parent = label.UI.Framework
	task.spawn(function()
		local ok, asset = pcall(function()
			return Library:ResolveImageTextboxPreview(url)
		end)
		if ok and type(asset) == "string" and asset ~= "" and icon.Parent then
			icon.Image = asset
		end
	end)
end

local function updateStatus(note)
	local text = "Status: " .. (STAGES[Farm.Stage] or "Unknown")
	if Farm.NextCrop then text ..= " | " .. Farm.NextCrop end
	if Farm.Cooldown > 0 then text ..= " | " .. Farm.Cooldown .. "s" end
	if note then text ..= " | " .. tostring(note) end
	if statusLabel then statusLabel:SetText(text) end
	for _, crop in ipairs(CROPS) do
		local label = countLabels[crop[1]]
		if label then label:SetText(string.format("%s: %d / 100", crop[1], Farm.Counts[crop[1]] or 0)) end
	end
	if craftedLabel then craftedLabel:SetText("SeedCandy crafted: " .. Farm.Crafted) end
end

local function stage(number, crop, note)
	Farm.Stage, Farm.NextCrop = number, crop
	updateStatus(note)
end

local function active(id) return Farm.Enabled and Farm.RunId == id end
local function waitActive(seconds, id)
	local finish = os.clock() + seconds
	repeat
		if not active(id) then return false end
		task.wait(math.min(0.1, math.max(0, finish - os.clock())))
	until os.clock() >= finish
	return active(id)
end

local function waitFor(callback, seconds, id)
	local finish = os.clock() + seconds
	repeat
		if id and not active(id) then return nil end
		local ok, result = pcall(callback)
		if ok and result then return result end
		task.wait(0.1)
	until os.clock() >= finish
	return nil
end

local function characterRoot()
	local character = player.Character
	return character, character and character:FindFirstChild("HumanoidRootPart")
end

local function near(position)
	local _, root = characterRoot()
	return root and (root.Position - position).Magnitude <= 18
end

local function warp(position, id)
	local character, root = characterRoot()
	if not character or not root or not active(id) then return false end
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	character:PivotTo(CFrame.new(position + Vector3.new(0, Farm.Settings.YOffset, 0)))
	return waitActive(0.4, id)
end

local function visible(gui)
	if not gui or not gui:IsA("GuiObject") then return false end
	local node = gui
	while node do
		if node:IsA("GuiObject") and not node.Visible then return false end
		if node:IsA("CanvasGroup") and node.GroupTransparency >= 0.99 then return false end
		if node:IsA("ScreenGui") and not node.Enabled then return false end
		node = node.Parent
	end
	return gui.AbsoluteSize.X > 0 and gui.AbsoluteSize.Y > 0
end

local function key(code, hold)
	VIM:SendKeyEvent(true, code, false, game)
	task.wait(hold or 0.08)
	VIM:SendKeyEvent(false, code, false, game)
end

local function touchGui(gui)
	if not gui or not gui:IsA("GuiObject") then return false end
	local point = gui.AbsolutePosition + gui.AbsoluteSize / 2
	local ok = pcall(function()
		VIM:SendTouchEvent(0, Enum.UserInputState.Begin, point.X, point.Y)
		task.wait(0.08)
		VIM:SendTouchEvent(0, Enum.UserInputState.End, point.X, point.Y)
	end)
	if ok then return true end

	-- Executors without SendTouchEvent can still invoke the unified mobile
	-- GuiButton event without needing a mouse or keyboard.
	if gui:IsA("GuiButton") and type(firesignal) == "function" then
		return pcall(function() firesignal(gui.Activated) end)
	end
	return false
end

local function activateGuiDirect(gui)
	if not gui or not gui:IsA("GuiObject") then return false end
	if gui:IsA("GuiButton") and type(getconnections) == "function" then
		for _, signalName in ipairs({ "Activated", "MouseButton1Click", "TouchTap" }) do
			local ok, connections = pcall(getconnections, gui[signalName])
			if ok and type(connections) == "table" and #connections > 0 then
				local invoked = false
				for _, connection in ipairs(connections) do
					local fired = pcall(function()
						if type(connection.Fire) == "function" then
							connection:Fire()
						elseif type(connection.Function) == "function" then
							connection.Function()
						else
							error("unsupported connection")
						end
					end)
					invoked = invoked or fired
				end
				if invoked then return true end
			end
		end
	end
	if gui:IsA("GuiButton") and type(firesignal) == "function" then
		local ok = pcall(function() firesignal(gui.MouseButton1Click) end)
		if ok then return true end
	end
	return touchGui(gui)
end

local function click(gui)
	if not gui or not gui:IsA("GuiObject") then return false end
	if IS_MOBILE then return touchGui(gui) end
	-- Use a real pointer click for game-owned UI. Some executors return success
	-- from firesignal without Roblox's crafting controller receiving the action.
	local point = gui.AbsolutePosition + gui.AbsoluteSize / 2
	VIM:SendMouseMoveEvent(point.X, point.Y, game)
	task.wait(0.05)
	VIM:SendMouseButtonEvent(point.X, point.Y, 0, true, game, 0)
	task.wait(0.08)
	VIM:SendMouseButtonEvent(point.X, point.Y, 0, false, game, 0)
	return true
end

local function clickAndConfirm(gui, confirm, id, confirmWait)
	if not gui or not confirm then return false end
	confirmWait = confirmWait or 0.85
	local point = gui.AbsolutePosition + gui.AbsoluteSize / 2
	local camera = Workspace.CurrentCamera

	local methods = {
		function() click(gui) end,
		function()
			if IS_MOBILE then
				touchGui(gui)
			else
				VirtualUser:ClickButton1(point, camera and camera.CFrame or CFrame.new())
			end
		end,
		function() click(gui) end,
	}

	for _, method in ipairs(methods) do
		pcall(method)
		if waitFor(confirm, confirmWait, id) then return true end
	end
	return false
end

local function activateAndConfirm(gui, confirm, id, confirmWait)
	if not gui or not confirm then return false end
	confirmWait = confirmWait or 0.85
	-- Volt exposes one MouseButton1Click connection on the dumped Craft card,
	-- U/D controls and CRAFT button. Invoke that exact game connection first.
	pcall(activateGuiDirect, gui)
	if waitFor(confirm, confirmWait, id) then return true end
	-- Keep pointer/touch injection for executors that block connection access.
	return clickAndConfirm(gui, confirm, id, confirmWait)
end

local function promptPosition(prompt)
	local parent = prompt.Parent
	if parent:IsA("Attachment") then return parent.WorldPosition end
	if parent:IsA("BasePart") then return parent.Position end
	local part = parent:FindFirstAncestorWhichIsA("BasePart")
	return part and part.Position
end

local function findPrompt(point)
	local found = {}
	local cropName = point[1]
	local farmRoot = Workspace:FindFirstChild("Farm")
	local cropRoot = farmRoot and cropName and farmRoot:FindFirstChild(cropName)
	local root = cropRoot or Workspace
	for _, object in ipairs(root:GetDescendants()) do
		if object:IsA("ProximityPrompt") and object.Enabled then
			local position = promptPosition(object)
			if cropRoot or (position and (position - point[2]).Magnitude <= 220) then table.insert(found, object) end
		end
	end
	table.sort(found, function(a, b)
		local pa, pb = promptPosition(a), promptPosition(b)
		return (pa and (pa-point[2]).Magnitude or math.huge) < (pb and (pb-point[2]).Magnitude or math.huge)
	end)
	return found[1]
end

local function interact(point, id)
	while consumeBusy and active(id) do task.wait(0.1) end
	if not active(id) then return false end
	if Farm.Settings.MoveCamera and Workspace.CurrentCamera then
		Workspace.CurrentCamera.CFrame = CFrame.lookAt(point[3], point[3] + point[4])
	end
	local prompt = waitFor(function() return findPrompt(point) end, 1.5, id)
	if prompt and type(fireproximityprompt) == "function" and pcall(fireproximityprompt, prompt, prompt.HoldDuration) then
		return waitActive(0.5, id)
	end
	if prompt and IS_MOBILE then
		local began = pcall(function() prompt:InputHoldBegin() end)
		if began then
			if not waitActive(math.max(0.1, prompt.HoldDuration), id) then return false end
			pcall(function() prompt:InputHoldEnd() end)
			return waitActive(0.5, id)
		end
		return false
	end
	key(Enum.KeyCode.E, 1.1)
	return waitActive(0.5, id)
end

local function exact(root, name)
	if not root then return nil end
	for _, object in ipairs(root:GetDescendants()) do
		if object.Name == name then return object end
		if (object:IsA("TextLabel") or object:IsA("TextButton")) and object.Text == name then return object end
	end
end

local function parseCount(text)
	text = tostring(text or ""):gsub("<[^>]->", ""):gsub(",", "")
	-- Current Inventory renders stacks as 100|100; older UI uses 100/100.
	local a, b = text:match("(%d+)%s*[/|]%s*(%d+)")
	if a then return tonumber(a), tonumber(b) end
	local n = text:match("^%s*(%d+)%s*$")
	return n and tonumber(n) or nil, nil
end

local function branchCount(root)
	for _, object in ipairs(root:GetDescendants()) do
		if object:IsA("TextLabel") or object:IsA("TextButton") then
			local current, maximum = parseCount(object.Text)
			if current then return current, maximum end
		end
	end
end

local function itemCount(root, itemName)
	local item = exact(root, itemName)
	if not item then return 0, false, false end
	local branch = item
	for _ = 1, 4 do
		if branch == root then break end
		-- Bind the count to this exact item card. Never fall through to another
		-- card's plain number (for example BonusCoins=31).
		local amount = branch:FindFirstChild("Amount", true)
		if amount and (amount:IsA("TextLabel") or amount:IsA("TextButton") or amount:IsA("TextBox")) then
			local current = parseCount(amount.Text)
			if current ~= nil then return current, true end
		end
		local count = branchCount(branch)
		if count ~= nil then return count, true end
		branch = branch.Parent
	end
	return 0, false, true
end

local function inventoryPanel(allowHidden)
	local gui = player:FindFirstChildOfClass("PlayerGui")

	-- Current Some Town inventory:
	-- PlayerGui/Inventory/CanvasGroup/Main/Body/<Item>/Main/Amount
	local inventory = gui and gui:FindFirstChild("Inventory")
	local canvas = inventory and inventory:FindFirstChild("CanvasGroup")
	local modernMain = canvas and canvas:FindFirstChild("Main")
	local modernBody = modernMain and modernMain:FindFirstChild("Body")
	if modernBody and modernBody:IsA("ScrollingFrame") and (allowHidden or visible(modernBody)) then
		return modernBody, "modern"
	end

	-- Older inventory used by the original External implementation.
	local backpack = gui and gui:FindFirstChild("Backpack_Never")
	local bg = backpack and backpack:FindFirstChild("BG")
	local items = bg and bg:FindFirstChild("item")
	local scrolling = items and items:FindFirstChild("Scrollingitem")
	if bg and visible(bg) and scrolling then return scrolling, "legacy" end
	return nil, nil
end

local function waitInventoryCards(panel, id)
	local lastCount, stableSamples = -1, 0
	for _ = 1, 40 do
		if not active(id) then return false end
		local count = 0
		for _, child in ipairs(panel:GetChildren()) do
			if child:IsA("Frame") then count += 1 end
		end
		if count > 0 and count == lastCount then
			stableSamples += 1
		else
			stableSamples = 0
		end
		if stableSamples >= 3 then return true end
		lastCount = count
		task.wait(0.15)
	end
	return false
end

local function modernItemCount(panel, itemName)
	local card = panel:FindFirstChild(itemName)
	if not card then return 0, false, false end
	local main = card and card:FindFirstChild("Main")
	local amount = main and main:FindFirstChild("Amount")
	if not amount or not (amount:IsA("TextLabel") or amount:IsA("TextButton")) then
		return 0, false, true
	end
	local current = parseCount(amount.Text)
	return current or 0, current ~= nil, current == nil
end

local function selectModernInventoryAll()
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local inventory = gui and gui:FindFirstChild("Inventory")
	local canvas = inventory and inventory:FindFirstChild("CanvasGroup")
	local main = canvas and canvas:FindFirstChild("Main")
	local header = main and main:FindFirstChild("Header")
	local category = header and header:FindFirstChild("Category")
	local allButton = category and category:FindFirstChild("All")
	if allButton and allButton:IsA("GuiObject") then
		return click(allButton)
	end
	return false
end

local function findMobileInventoryButton()
	local gui = player:FindFirstChildOfClass("PlayerGui")
	if not gui then return nil end
	local best, bestScore
	for _, object in ipairs(gui:GetDescendants()) do
		if object:IsA("GuiButton") and visible(object) then
			local text = object:IsA("TextButton") and object.Text or ""
			for _, child in ipairs(object:GetDescendants()) do
				if child:IsA("TextLabel") then text ..= " " .. child.Text end
			end
			local haystack = string.lower(object.Name .. " " .. text):gsub("<.->", "")
			local score = 0
			if haystack:find("inventory", 1, true) then score = 4
			elseif haystack:find("backpack", 1, true) then score = 3
			elseif haystack:match("%f[%a]bag%f[%A]") then score = 2 end
			if object:FindFirstAncestor("Inventory") then score -= 1 end
			if score > 0 and (not bestScore or score > bestScore) then
				best, bestScore = object, score
			end
		end
	end
	return best
end

local function scanInventory(id)
	stage(2)
	local panel, mode = inventoryPanel()
	local opened = false
	local mobileInventoryButton
	if not panel and IS_MOBILE then
		-- Mobile has no T key. The custom inventory keeps its item cards loaded
		-- under CanvasGroup even while the full panel is hidden.
		panel, mode = inventoryPanel(true)
	end
	if not panel then
		opened = true
		if IS_MOBILE then
			mobileInventoryButton = findMobileInventoryButton()
			if not mobileInventoryButton or not activateGuiDirect(mobileInventoryButton) then return false end
		else
			key(Enum.KeyCode.T)
		end
		panel = waitFor(function()
			local root = inventoryPanel()
			return root
		end, 5, id)
	end
	if not panel then return false end
	if not mode then
		local _, detectedMode = inventoryPanel(true)
		mode = detectedMode
	end
	if mode == "modern" then
		if visible(panel) then
			selectModernInventoryAll()
			if not waitActive(0.5, id) then return false end
		end
	end
	if not waitInventoryCards(panel, id) then return false end
	if not waitActive(0.5, id) then return false end

	local observed = {}
	for scan = 1, 3 do
		for _, crop in ipairs(CROPS) do
			local count, found, invalid
			if mode == "modern" then
				count, found, invalid = modernItemCount(panel, crop[1])
			else
				count, found, invalid = itemCount(panel, crop[1])
			end
			if invalid then
				updateStatus("Invalid Amount: " .. crop[1])
				if opened and inventoryPanel() then
					if IS_MOBILE and mobileInventoryButton then activateGuiDirect(mobileInventoryButton) else key(Enum.KeyCode.T) end
				end
				return false
			end
			if found then observed[crop[1]] = math.max(observed[crop[1]] or 0, count) end
		end
		if scan < 3 and not waitActive(0.35, id) then return false end
	end

	-- Commit the scan only after all polling passes. Missing cards in the fully
	-- populated modern inventory mean a real zero, not "GUI still loading".
	for _, crop in ipairs(CROPS) do Farm.Counts[crop[1]] = observed[crop[1]] or 0 end
	updateStatus("Inventory checked: " .. (mode or "unknown"))
	if opened and inventoryPanel() then
		if IS_MOBILE and mobileInventoryButton then activateGuiDirect(mobileInventoryButton) else key(Enum.KeyCode.T) end
		waitActive(0.3, id)
	end
	return active(id)
end

local function hudCount(cropName)
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local auto = gui and gui:FindFirstChild("AutoUi")
	local frame = auto and auto:FindFirstChild("Frame")
	local group = frame and frame:FindFirstChild("GFrame")
	local rows = group and group:FindFirstChild("FFrame")
	if not rows then return nil end
	for i = 1, 6 do
		local name = rows:FindFirstChild("ItemNameLabel"..i)
		local amount = rows:FindFirstChild("MaxItem"..i)
		if name and amount and name.Text == cropName then return parseCount(amount.Text) end
	end
end

local function cooldown(id)
	stage(4, Farm.NextCrop)
	for remaining = Farm.Settings.Cooldown, 1, -1 do
		Farm.Cooldown = remaining; updateStatus()
		if not waitActive(1, id) then return false end
	end
	Farm.Cooldown = 0; updateStatus()
	return true
end

local function farmCrop(crop, id)
	for attempt = 1, 3 do
		stage(3, crop[1], "Attempt "..attempt.."/3")
		if not near(crop[2]) and not warp(crop[2], id) then return false end
		if not interact(crop, id) then return false end
		local started, hudSeen, missingSince = os.clock(), false, nil
		local lastCurrent, lastMaximum = -1, -1
		while active(id) and os.clock()-started < Farm.Settings.Timeout do
			local current, maximum = hudCount(crop[1])
			if current then
				hudSeen, missingSince = true, nil
				lastCurrent, lastMaximum = current, maximum or 100
				Farm.Counts[crop[1]] = current; updateStatus()
				if current >= 100 and (maximum or 100) >= 100 then return true end
			else
				local elapsed = os.clock()-started
				if not hudSeen and elapsed >= 3 and attempt < 3 and near(crop[2]) then break end
				if hudSeen and not missingSince then missingSince = os.clock() end
				if (missingSince and os.clock()-missingSince >= 3) or (not hudSeen and elapsed >= 8) then
					if scanInventory(id) and Farm.Counts[crop[1]] >= 100 then return true end
					if hudSeen and lastMaximum >= 100 and lastCurrent >= 95 then Farm.Counts[crop[1]]=100; return true end
					if not cooldown(id) then return false end
					break
				end
			end
			if not waitActive(0.25, id) then return false end
		end
	end
	return false
end

local function closeGui(bg)
	if not bg then return true end
	local function closed()
		if not bg.Parent or not visible(bg) then return true end
		-- Never Town closes panels by tweening them outside the viewport while
		-- keeping Visible=true. Treat that final position as closed as well.
		local camera = Workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize
		if viewport then
			local position, size = bg.AbsolutePosition, bg.AbsoluteSize
			return position.X + size.X <= 0 or position.Y + size.Y <= 0
				or position.X >= viewport.X or position.Y >= viewport.Y
		end
		return false
	end
	if closed() then return true end

	-- The dump exposes this exact control with one MouseButton1Click listener:
	-- PlayerGui/System/Craft/BG/Exit. Invoke it before any fuzzy fallback.
	local exactExit = bg:FindFirstChild("Exit")
	if exactExit and exactExit:IsA("GuiButton") and visible(exactExit) then
		if activateAndConfirm(exactExit, closed, nil, 1.25) then return true end
	end

	local candidates, seen = {}, {}
	local function addCandidate(object)
		if not object or seen[object] then return end
		local button = object
		while button and button ~= bg do
			if button:IsA("GuiButton") then break end
			button = button.Parent
		end
		if not button or button == bg or not button:IsA("GuiButton") then
			button = nil
			for _, descendant in ipairs(object:GetDescendants()) do
				if descendant:IsA("GuiButton") and visible(descendant) then button = descendant; break end
			end
		end
		if button and visible(button) and not seen[button] then
			seen[button] = true
			candidates[#candidates + 1] = button
		end
	end

	for _, object in ipairs(bg:GetDescendants()) do
		local name = string.lower(object.Name)
		local text = (object:IsA("TextButton") or object:IsA("TextLabel")) and string.lower(object.Text) or ""
		if name == "exit" or name == "close" or name == "closebutton" or name == "x"
			or text == "x" or text == "close" then
			addCandidate(object)
		end
	end

	local topRight = bg.AbsolutePosition + Vector2.new(bg.AbsoluteSize.X, 0)
	table.sort(candidates, function(left, right)
		local leftCenter = left.AbsolutePosition + left.AbsoluteSize / 2
		local rightCenter = right.AbsolutePosition + right.AbsoluteSize / 2
		return (leftCenter - topRight).Magnitude < (rightCenter - topRight).Magnitude
	end)
	for _, button in ipairs(candidates) do
		if button ~= exactExit and activateAndConfirm(button, closed, nil, 1.25) then return true end
	end

	-- Never use Escape as a close fallback: it opens Roblox's system menu when
	-- the game-owned X button has not closed the current panel.
	return closed()
end

local function craftUI()
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local system = gui and gui:FindFirstChild("System")
	local craft = system and system:FindFirstChild("Craft")
	local bg = craft and craft:FindFirstChild("BG")
	return bg and visible(bg) and bg or nil
end

local function visibleText(root, wanted)
	wanted = string.lower(tostring(wanted))
	for _, object in ipairs(root:GetDescendants()) do
		if (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox"))
			and visible(object) and string.lower(object.Text) == wanted then
			return object
		end
	end
end

local function clickableFrom(object, boundary)
	local node = object
	while node and node ~= boundary do
		if node:IsA("GuiButton") then return node end
		-- New craft cards keep ItemName beside a child Main/ImageButton rather
		-- than inside it. Search each enclosing card before moving upward.
		for _, child in ipairs(node:GetDescendants()) do
			if child:IsA("GuiButton") and visible(child) then return child end
		end
		node = node.Parent
	end
	return object
end

local function findQuantityLabel(bg)
	local frame = bg:FindFirstChild("Frame")
	-- The live dump contains two BG/Frame children both named ImageLabel.
	-- Select the one that owns the exact A/U/D controls instead of relying on
	-- FindFirstChild returning them in a particular replication order.
	if frame then
		for _, image in ipairs(frame:GetChildren()) do
			if image.Name == "ImageLabel" then
				local amount = image:FindFirstChild("A")
				local up = image:FindFirstChild("U")
				local down = image:FindFirstChild("D")
				if amount and up and down and tonumber(amount.Text) then
					return amount, image
				end
			end
		end
	end

	local center = bg.AbsolutePosition + bg.AbsoluteSize / 2
	local best, bestDistance
	for _, object in ipairs(bg:GetDescendants()) do
		if (object:IsA("TextLabel") or object:IsA("TextBox") or object:IsA("TextButton")) and visible(object) then
			local quantity = tonumber(object.Text:match("^%s*(%d+)%s*$"))
			if quantity and quantity >= 1 and quantity <= 5 then
				local objectCenter = object.AbsolutePosition + object.AbsoluteSize / 2
				local distance = (objectCenter - center).Magnitude
				if not bestDistance or distance < bestDistance then
					best, bestDistance = object, distance
				end
			end
		end
	end
	return best, best and best.Parent or nil
end

local function selectedCraftName(bg)
	local frame = bg:FindFirstChild("Frame")
	if not frame then return nil end
	for _, image in ipairs(frame:GetChildren()) do
		local label = image.Name == "ImageLabel" and image:FindFirstChild("CraftText")
		if label and (label:IsA("TextLabel") or label:IsA("TextButton")) then
			return label.Text
		end
	end
end

local function seedCandyCard(listFrame)
	if not listFrame then return nil end
	for _, card in ipairs(listFrame:GetChildren()) do
		local itemName = card:FindFirstChild("ItemName")
		if itemName and itemName:IsA("TextLabel") and itemName.Text == "SeedCandy" then
			-- Confirmed by the live dump: each recipe card is the ImageButton
			-- PlayerGui/System/Craft/BG/ITlist/Frame/Craft itself.
			return card:IsA("ImageButton") and visible(card) and card or nil
		end
	end
end

local function craftCardSelected(card)
	local frame1 = card and card:FindFirstChild("Frame1")
	local frame2 = card and card:FindFirstChild("Frame2")
	-- Confirmed by snapshot #002: both side frames are visible only on the
	-- selected SeedCandy recipe card.
	return frame1 and frame2 and frame1.Visible and frame2.Visible
end

local function findQuantityButton(bg, amount, container, increase)
	for _, name in ipairs(increase and {"U", "Up", "Increase", "Plus", "+"} or {"D", "Down", "Decrease", "Minus", "-"}) do
		local button = container and container:FindFirstChild(name, true)
		if button and button:IsA("GuiObject") and visible(button) then return clickableFrom(button, bg) end
	end

	-- New UI has an arrow immediately to the right/left of the numeric amount.
	local amountCenter = amount.AbsolutePosition + amount.AbsoluteSize / 2
	local best, bestDistance
	for _, object in ipairs(bg:GetDescendants()) do
		if object:IsA("GuiButton") and visible(object) then
			local objectCenter = object.AbsolutePosition + object.AbsoluteSize / 2
			local dx, dy = objectCenter.X - amountCenter.X, math.abs(objectCenter.Y - amountCenter.Y)
			local correctSide = increase and dx > 5 or (not increase and dx < -5)
			if correctSide and math.abs(dx) <= 150 and dy <= 80 then
				local distance = math.abs(dx) + dy
				if not bestDistance or distance < bestDistance then best, bestDistance = object, distance end
			end
		end
	end
	return best
end

local function requirementsReady(bg)
	local main = bg:FindFirstChild("Main")
	local materials = main and main:FindFirstChild("MATERIALS")
	local scrolling = materials and materials:FindFirstChild("ScrollingFrame")
	local ready = 0
	for _, crop in ipairs(CROPS) do
		local current, required
		local row = scrolling and scrolling:FindFirstChild(crop[1])
		local amount = row and row:FindFirstChild("Amount")
		if amount then current, required = parseCount(amount.Text) end

		if not current then
			local nameObject = visibleText(bg, crop[1])
			local branch = nameObject and nameObject.Parent
			for _ = 1, 4 do
				if not branch or branch == bg then break end
				for _, object in ipairs(branch:GetDescendants()) do
					if (object:IsA("TextLabel") or object:IsA("TextButton")) and visible(object) then
						local a, b = parseCount(object.Text)
						if a and b then current, required = a, b; break end
					end
				end
				if current then break end
				branch = branch.Parent
			end
		end

		if current and required and current >= required and required >= 100 then ready += 1 end
	end
	return ready == #CROPS
end

local function craftSeedCandy(id)
	stage(5, nil, "Opening Craft UI")
	if not near(CRAFT[2]) and not warp(CRAFT[2], id) then return false end
	local bg
	for _ = 1, 3 do
		if not interact(CRAFT, id) then return false end
		bg = waitFor(craftUI, 5, id)
		if bg then break end
	end
	if not bg then return false end
	local select = bg:FindFirstChild("Select")
	local tableButton = select and select:FindFirstChild("ButtonTable")
	if tableButton then
		activateGuiDirect(tableButton); waitActive(0.35, id)
		local category = exact(select, "Category_CategoryCandy")
		if category then activateGuiDirect(category); waitActive(0.5, id) end
	end
	local list = bg:FindFirstChild("ITlist")
	local listFrame = list and list:FindFirstChild("Frame")
	local card = seedCandyCard(listFrame)
	if not card then closeGui(bg); return false end
	stage(5, nil, "Selecting SeedCandy")
	-- Always activate the exact dumped card. CraftText can already say
	-- SeedCandy, so verify the two selection frames instead of that text.
	if not activateAndConfirm(card, function()
		return craftCardSelected(card)
	end, id, 0.65) then
		closeGui(bg); return false
	end
	if selectedCraftName(bg) ~= "SeedCandy" then closeGui(bg); return false end
	local amount, quantityContainer = findQuantityLabel(bg)
	if not amount then closeGui(bg); return false end
	for _ = 1, 8 do
		local quantity = tonumber(amount.Text)
		if quantity == 5 then break end
		stage(5, nil, "Quantity " .. tostring(quantity or "?") .. " -> 5")
		local adjust = findQuantityButton(bg, amount, quantityContainer, (quantity or 0) < 5)
		if not adjust then closeGui(bg); return false end
		if not activateAndConfirm(adjust, function()
			local refreshed = findQuantityLabel(bg)
			return refreshed and tonumber(refreshed.Text) ~= quantity
		end, id) then
			closeGui(bg); return false
		end
		amount, quantityContainer = findQuantityLabel(bg)
		if not amount then closeGui(bg); return false end
	end
	if tonumber(amount.Text) ~= 5 then closeGui(bg); return false end
	if not waitFor(function() return requirementsReady(bg) end, 2, id) then closeGui(bg); return false end
	local main = bg:FindFirstChild("Main")
	local craftText = visibleText(bg, "CRAFT")
	local craftButton = (main and main:FindFirstChild("Craft")) or clickableFrom(craftText, bg)
	stage(5, nil, "Clicking CRAFT")
	local loading = main and main:FindFirstChild("Loading")
	local loadingBefore = loading and loading.Text
	if not craftButton or not activateAndConfirm(craftButton, function()
		return (loading and loading.Text ~= loadingBefore)
			or not visible(craftButton)
			or not craftButton.Active
	end, id, 1.5) then
		closeGui(bg); return false
	end
	if not waitActive(12, id) then closeGui(bg); return false end
	if not closeGui(bg) then
		task.wait(0.25)
		closeGui(bg)
	end
	Farm.Crafted += 5
	for _, crop in ipairs(CROPS) do Farm.Counts[crop[1]] = math.max(0, Farm.Counts[crop[1]]-100) end
	updateStatus(); return true
end

local function lockerPanels()
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local locker = gui and gui:FindFirstChild("LockerUI")
	local ui = locker and locker:FindFirstChild("ui")
	local left = ui and ui:FindFirstChild("Left")
	local right = ui and (ui:FindFirstChild("Right") or ui:FindFirstChild("Safe"))
	return ui and left and right and visible(ui) and {ui, left, right} or nil
end

local function lockerItemTarget(panel, itemName)
	local item = exact(panel, itemName)
	if not item then return nil end
	-- The External clicks the exact item object in the panel, not its outer
	-- inventory frame. This matters because the outer frame can cover most of
	-- the locker and its centre is not on the SeedCandy card.
	if item:IsA("GuiObject") and visible(item) then return item end
	local button = clickableFrom(item, panel)
	return button and button:IsA("GuiObject") and visible(button) and button or nil
end

local function deposit(id)
	stage(6)
	if not near(REBEL[2]) and not warp(REBEL[2], id) then return false end
	local panels
	for _ = 1, 3 do
		if not interact(REBEL, id) then return false end
		panels = waitFor(lockerPanels, 4, id)
		if panels then break end
	end
	if not panels then return false end
	local ui, inventory, safe = panels[1], panels[2], panels[3]
	local beforeInventory, inventoryCountKnown = itemCount(inventory, "SeedCandy")
	local beforeSafe, safeCountKnown = itemCount(safe, "SeedCandy")
	local function transferred()
		if exact(inventory, "SeedCandy") == nil then return true end
		local inventoryNow, inventoryKnownNow = itemCount(inventory, "SeedCandy")
		if inventoryCountKnown and inventoryKnownNow and inventoryNow < beforeInventory then return true end
		local safeNow, safeKnownNow = itemCount(safe, "SeedCandy")
		return safeCountKnown and safeKnownNow and safeNow > beforeSafe
	end

	local moved = false
	for attempt = 1, 3 do
		if not active(id) then break end
		local seed = lockerItemTarget(inventory, "SeedCandy")
		if not seed then
			moved = transferred()
			break
		end
		stage(6, nil, "Depositing SeedCandy ("..attempt.."/3)")
		if clickAndConfirm(seed, transferred, id, 1.15) then
			moved = true
			break
		end
		task.wait(0.2)
	end
	if not moved then moved = transferred() end
	closeGui(ui); return moved and active(id)
end

local function cycle(id)
	if not scanInventory(id) then return false, "Inventory scan failed" end
	for _, crop in ipairs(CROPS) do
		if not active(id) then return false, "Stopped" end
		if Farm.Counts[crop[1]] < 100 then
			if not farmCrop(crop, id) then return false, "Farm failed: "..crop[1] end
			if not cooldown(id) then return false, "Stopped" end
		end
	end
	for _, crop in ipairs(CROPS) do if Farm.Counts[crop[1]] < 100 then return false, crop[1].." below 100" end end
	if not craftSeedCandy(id) then return false, "Craft failed" end
	if not deposit(id) then return false, "Deposit failed" end
	return true
end

function Farm:Start()
	if self.Enabled then return end
	self.Enabled, self.Crafted = true, 0
	self.RunId += 1
	local id = self.RunId
	task.spawn(function()
		while active(id) do
			local ok, success, reason = pcall(cycle, id)
			if not active(id) then break end
			if not ok then reason, success = tostring(success), false end
			if success then
				stage(0, nil, "Cycle complete")
				if not waitActive(0.75, id) then break end
			else
				stage(7, nil, reason or "Retrying")
				if not waitActive(8, id) then break end
			end
		end
		if self.RunId == id then self.Enabled=false; self.Stage=0; self.Cooldown=0; updateStatus("Stopped") end
	end)
end

function Farm:Stop()
	self.Enabled=false; self.RunId+=1; self.Stage=0; self.NextCrop=nil; self.Cooldown=0
	local openCraft = craftUI()
	if openCraft then task.spawn(function() closeGui(openCraft) end) end
	updateStatus("Stopped")
end

-- Auto Eat / Drink ---------------------------------------------------------
-- Dump paths:
--   PlayerGui/Status/Main/Status/Hunger/Bar
--   PlayerGui/Status/Main/Status/Thirsty/Bar
--   PlayerGui/UIList/Main/Progress/In/InOn/Bar
local Consume = {
	Enabled = false,
	RunId = 0,
	Hunger = -1,
	Thirst = -1,
	HungerThreshold = 30,
	ThirstThreshold = 30,
	FoodSlot = 6,
	WaterSlot = 7,
	Status = "Disabled",
	Progress = -1,
}
Farm.Consume = Consume

local consumeStatusLabel, hungerLabel, thirstLabel, consumeProgressLabel

local function updateConsumeUI(status)
	if status then Consume.Status = status end
	local function valueText(value)
		return value >= 0 and string.format("%d%%", math.floor(value + 0.5)) or "Unknown"
	end
	if consumeStatusLabel then consumeStatusLabel:SetText("Consume: " .. Consume.Status) end
	if hungerLabel then
		hungerLabel:SetText(string.format("Hunger: %s | eat below %d%%", valueText(Consume.Hunger), Consume.HungerThreshold))
	end
	if thirstLabel then
		thirstLabel:SetText(string.format("Thirst: %s | drink below %d%%", valueText(Consume.Thirst), Consume.ThirstThreshold))
	end
	if consumeProgressLabel then
		consumeProgressLabel:SetText(Consume.Progress >= 0
			and string.format("Consume progress: %d%%", math.floor(Consume.Progress + 0.5))
			or "Consume progress: Idle")
	end
end

local function consumeActive(id)
	return Consume.Enabled and Consume.RunId == id
end

local function waitConsume(seconds, id)
	local finish = os.clock() + seconds
	repeat
		if not consumeActive(id) then return false end
		task.wait(math.min(0.1, math.max(0, finish - os.clock())))
	until os.clock() >= finish
	return consumeActive(id)
end

local function statusBarValue(name)
	local gui = player:FindFirstChildOfClass("PlayerGui")
	-- Legacy/text HUD used by some servers.
	local controler = gui and gui:FindFirstChild("controler")
	local legacyStatus = controler and controler:FindFirstChild("Status")
	local legacyHud = legacyStatus and legacyStatus:FindFirstChild("Hud")
	local legacyName = name == "Hunger" and "hunger" or "thirst"
	local legacyGroup = legacyHud and legacyHud:FindFirstChild(legacyName)
	local legacyAmount = legacyGroup and legacyGroup:FindFirstChild("Amount")
	if legacyAmount and (legacyAmount:IsA("TextLabel") or legacyAmount:IsA("TextButton")) then
		local value = tonumber(legacyAmount.Text:match("(%d+%.?%d*)"))
		if value then return math.clamp(value, 0, 100) end
	end

	local statusGui = gui and gui:FindFirstChild("Status")
	local main = statusGui and statusGui:FindFirstChild("Main")
	local statuses = main and main:FindFirstChild("Status")
	local group = statuses and statuses:FindFirstChild(name)
	local bar = group and group:FindFirstChild("Bar")
	if not group then return -1 end

	-- The current HUD draws 28/26 as text inside the circular status widgets.
	-- Prefer that authoritative value when it exists.
	for _, object in ipairs(group:GetDescendants()) do
		if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
			local plain = object.Text:gsub("<.->", "")
			local value = tonumber(plain:match("^%s*(%d+%.?%d*)%%?%s*$"))
			if value and value >= 0 and value <= 100 then return value end
		end
	end

	if not bar or not bar:IsA("GuiObject") then return -1 end
	local ratio = bar.Size.Y.Scale
	if ratio < -0.01 or ratio > 1.01 then
		local parentHeight = group.AbsoluteSize.Y
		ratio = parentHeight > 0 and bar.AbsoluteSize.Y / parentHeight or -1
	end
	return ratio >= 0 and math.clamp(ratio * 100, 0, 100) or -1
end

local function consumeProgress()
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local uiList = gui and gui:FindFirstChild("UIList")
	local main = uiList and uiList:FindFirstChild("Main")
	local progress = main and main:FindFirstChild("Progress")
	if not progress or not visible(progress) then return false, -1 end
	local inside = progress:FindFirstChild("In")
	local insideOn = inside and inside:FindFirstChild("InOn")
	local bar = insideOn and insideOn:FindFirstChild("Bar")
	local ratio = bar and bar.Size.X.Scale or -1
	if bar and (ratio < -0.01 or ratio > 1.01) and insideOn.AbsoluteSize.X > 0 then
		ratio = bar.AbsoluteSize.X / insideOn.AbsoluteSize.X
	end
	return true, ratio >= 0 and math.clamp(ratio * 100, 0, 100) or -1
end

local SLOT_KEYS = {
	[1]=Enum.KeyCode.One, [2]=Enum.KeyCode.Two, [3]=Enum.KeyCode.Three,
	[4]=Enum.KeyCode.Four, [5]=Enum.KeyCode.Five, [6]=Enum.KeyCode.Six,
	[7]=Enum.KeyCode.Seven, [8]=Enum.KeyCode.Eight, [9]=Enum.KeyCode.Nine,
}

local function hotbarSlotObject(slot)
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local inventory = gui and gui:FindFirstChild("Inventory")
	local uiList = inventory and inventory:FindFirstChild("UIList")
	local slots = uiList and uiList:FindFirstChild("Slot")
	return slots and slots:FindFirstChild("Slot" .. tostring(slot)) or nil, slots ~= nil
end

local function pressSlot(slot)
	if IS_MOBILE then
		local slotObject = hotbarSlotObject(slot)
		return slotObject ~= nil and visible(slotObject) and activateGuiDirect(slotObject)
	end
	local code = SLOT_KEYS[slot]
	if not code then return false end
	key(code, 0.08)
	return true
end

local function refreshConsumeValues()
	Consume.Hunger = statusBarValue("Hunger")
	Consume.Thirst = statusBarValue("Thirsty")
	local progressing, progress = consumeProgress()
	Consume.Progress = progressing and progress or -1
	updateConsumeUI()
	return progressing
end

local function consumeGuiBusy()
	if Farm.Stage == 1 or Farm.Stage == 2 or Farm.Stage == 5 or Farm.Stage == 6 then return true end
	return craftUI() ~= nil or inventoryPanel() ~= nil or lockerPanels() ~= nil
end

local function hotbarSlotReady(slot)
	local slotObject, layoutKnown = hotbarSlotObject(slot)
	if not layoutKnown then return true end -- Unknown layout: let the key/check flow decide.
	return slotObject ~= nil and visible(slotObject)
end

local function consumeSlot(slot, statusName, id)
	local initial = statusName == "Hunger" and Consume.Hunger or Consume.Thirst
	if initial < 0 or consumeGuiBusy() then return false, false end
	if not hotbarSlotReady(slot) then
		updateConsumeUI("No item in slot " .. tostring(slot))
		return false, false
	end

	consumeBusy = true
	updateConsumeUI(statusName == "Hunger" and "Pressing top-row 6" or "Pressing top-row 7")
	if not pressSlot(slot) or not waitConsume(0.5, id) then
		consumeBusy = false
		return false, false
	end

	-- In SOME TOWN, selecting food/water with the top number row starts the
	-- consume action by itself. Do not send any mouse click.
	local started = true

	local completed = false
	if started then
		updateConsumeUI(statusName == "Hunger" and "Eating" or "Drinking")
		local finish = os.clock() + 35
		local sawProgress, missingSamples = false, 0
		repeat
			if not consumeActive(id) then break end
			local progressing = refreshConsumeValues()
			local current = statusName == "Hunger" and Consume.Hunger or Consume.Thirst
			if progressing then
				sawProgress, missingSamples = true, 0
			elseif sawProgress then
				missingSamples += 1
			end
			if current >= 0 and current > initial + 0.1 and (not sawProgress or missingSamples >= 3) then
				completed = true; break
			end
			task.wait(0.1)
		until os.clock() >= finish or (sawProgress and missingSamples >= 3)
		local final = statusName == "Hunger" and Consume.Hunger or Consume.Thirst
		completed = completed or (final >= 0 and final > initial + 0.1)
	end

	consumeBusy = false
	Consume.Progress = -1
	updateConsumeUI(completed and "Cooldown" or (started and "Use unverified" or "No item/action in slot"))
	return started, completed
end

function Consume:Start()
	if self.Enabled then return end
	self.Enabled = true
	self.RunId += 1
	local id = self.RunId
	task.spawn(function()
		local foodSamples, waterSamples = 0, 0
		local nextFood, nextWater = 0, 0
		local preferFood = true
		while consumeActive(id) do
			local progressing = refreshConsumeValues()
			if not consumeBusy and not progressing and not consumeGuiBusy() then
				foodSamples = self.Hunger >= 0 and self.Hunger < self.HungerThreshold - 1 and foodSamples + 1 or 0
				waterSamples = self.Thirst >= 0 and self.Thirst < self.ThirstThreshold - 1 and waterSamples + 1 or 0
				local now = os.clock()
				local needFood = foodSamples >= 4 and now >= nextFood
				local needWater = waterSamples >= 4 and now >= nextWater
				local useFood = needFood and (not needWater or preferFood)
				local useWater = needWater and not useFood
				if useFood then
					foodSamples = 0
					local started, completed = consumeSlot(self.FoodSlot, "Hunger", id)
					nextFood = os.clock() + (completed and 60 or (started and 45 or 15))
					preferFood = false
				elseif useWater then
					waterSamples = 0
					local started, completed = consumeSlot(self.WaterSlot, "Thirsty", id)
					nextWater = os.clock() + (completed and 60 or (started and 45 or 15))
					preferFood = true
				else
					updateConsumeUI("Monitoring slots 6/7")
				end
			elseif progressing then
				updateConsumeUI("Waiting for active progress")
			end
			if not waitConsume(0.25, id) then break end
		end
		if self.RunId == id then self.Enabled = false end
		consumeBusy = false
		self.Progress = -1
		updateConsumeUI("Disabled")
	end)
end

function Consume:Stop()
	self.Enabled = false
	self.RunId += 1
	consumeBusy = false
	self.Progress = -1
	updateConsumeUI("Disabled")
end

local ESP = {
	Enabled = false,
	ShowName = true,
	ShowDistance = true,
	ShowHealth = true,
	ShowArmor = true,
	ShowBox = true,
	MaxDistance = 1000,
	MaxRendered = IS_MOBILE and 10 or 18,
	Objects = {},
	Connection = nil,
	RenderConnection = nil,
	Accumulator = 0,
	RenderAccumulator = 0,
	RenderInterval = IS_MOBILE and (1 / 30) or (1 / 60),
	UpdateInterval = IS_MOBILE and 0.24 or 0.16,
	StatsInterval = IS_MOBILE and 1.0 or 0.7,
	ProxyCharacters = {},
	NextProxyScan = {},
	RootGui = nil,
	NextStatusUpdate = 0,
	WorldModels = {},
	BestWorldByName = {},
	NextWorldSelection = 0,
	WorldAddedConnection = nil,
	WorldRemovedConnection = nil,
	ArmorAddedConnection = nil,
	LocalCharacter = nil,
	LocalRoot = nil,
}

local ARMOR_NAMES = { "AmmorHeal", "Armor", "Armour", "ArmorValue", "ArmourValue", "Shield", "Vest", "Protection" }
local MAX_ARMOR_NAMES = { "AmmorMax", "AmmorHealMax", "MaxArmor", "MaxArmour", "ArmorMax", "ArmourMax", "MaxShield", "MaxVest", "MaxProtection" }

local function readReplicatedNumber(containers, names)
	for _, container in ipairs(containers) do
		if container then
			for _, name in ipairs(names) do
				local ok, attribute = pcall(container.GetAttribute, container, name)
				if ok and type(attribute) == "number" then return attribute end
				local valueObject = container:FindFirstChild(name)
				if valueObject then
					local valueOk, value = pcall(function() return valueObject.Value end)
					if valueOk and type(value) == "number" then return value end
				end
			end
		end
	end
	return nil
end

local function findCharacterRoot(character)
	if not character then return nil end
	for _, name in ipairs({ "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso", "Head" }) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then return part end
	end
	return nil
end

local function usableCharacter(character)
	local root = findCharacterRoot(character)
	if not root then return false end
	local position = root.Position
	return math.abs(position.X) < 1000000
		and math.abs(position.Y) < 1000000
		and math.abs(position.Z) < 1000000
		and (math.abs(position.X) >= 0.1 or math.abs(position.Y) >= 0.1 or math.abs(position.Z) >= 0.1)
end

function ESP:ResolveWorkspaceProxy(target, force)
	if not target then return nil end
	local best = self.BestWorldByName[target.Name]
	if best and best.Parent then
		self.ProxyCharacters[target] = best
		return best
	end
	local cached = self.ProxyCharacters[target]
	if cached and cached.Parent then return cached end

	local now = os.clock()
	if not force and now < (self.NextProxyScan[target] or 0) then return nil end
	-- A direct child lookup is cheap; retry quickly because Never Town replaces
	-- the proxy instance when streaming range changes.
	self.NextProxyScan[target] = now + 0.5

	-- Never Town's dump exposes live player proxies as direct Workspace children:
	-- Workspace.<player name>. Avoid every recursive lookup in the render loop.
	local candidate = Workspace:FindFirstChild(target.Name)
	if candidate and candidate:IsA("Model") and usableCharacter(candidate) then
		self.ProxyCharacters[target] = candidate
		return candidate
	end
	self.ProxyCharacters[target] = nil
	return nil
end

local function resolvePlayerCharacter(target)
	if not target then return nil end
	if typeof(target) == "Instance" and target:IsA("Model") then
		return target.Parent and target or nil
	end
	-- Match Never Town external cache order: the live Workspace proxy wins over
	-- Player.Character. At close range Player.Character may become a usable but
	-- non-rendered streaming replica, which made the ESP switch away and vanish.
	local proxy = ESP:ResolveWorkspaceProxy(target, false)
	if proxy then return proxy end
	local character = target.Character
	if character and character.Parent and usableCharacter(character) then return character end
	return nil
end

local function addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function makeVerticalESPBar(parent, color, leftSide)
	local back = Instance.new("Frame")
	back.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	back.BackgroundTransparency = 0.08
	back.BorderSizePixel = 0
	back.Position = UDim2.fromOffset(leftSide and -9 or 0, 0)
	back.Size = UDim2.fromOffset(IS_MOBILE and 7 or 5, 60)
	back.Parent = parent
	addCorner(back, 3)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.AnchorPoint = Vector2.new(0, 1)
	fill.Position = UDim2.fromScale(0, 1)
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = back
	addCorner(fill, 3)

	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.AnchorPoint = Vector2.new(leftSide and 1 or 0, 0)
	text.Position = UDim2.new(leftSide and 0 or 1, leftSide and -3 or 3, 0, 0)
	text.Size = UDim2.fromOffset(IS_MOBILE and 48 or 42, IS_MOBILE and 17 or 14)
	text.Font = Enum.Font.GothamBold
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextSize = IS_MOBILE and 11 or 9
	text.TextXAlignment = leftSide and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
	text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	text.TextStrokeTransparency = 0.25
	text.ZIndex = 3
	text.Parent = back

	return back, fill, text
end

function ESP:DestroyPlayer(target)
	local object = self.Objects[target]
	if object and object.Gui then pcall(object.Gui.Destroy, object.Gui) end
	self.Objects[target] = nil
end

function ESP:EnsureRootGui()
	if self.RootGui and self.RootGui.Parent then return self.RootGui end
	local gui = Instance.new("ScreenGui")
	gui.Name = "AraiScreenESP"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	local parent = player:WaitForChild("PlayerGui")
	if type(gethui) == "function" then
		local ok, hidden = pcall(gethui)
		if ok and hidden then parent = hidden end
	end
	gui.Parent = parent
	self.RootGui = gui
	return gui
end

function ESP:CreatePlayer(target)
	self:DestroyPlayer(target)
	local gui = Instance.new("Frame")
	gui.Name = "AraiPlayerESP"
	gui.Size = UDim2.fromOffset(55, 100)
	gui.AnchorPoint = Vector2.new(0, 0)
	gui.BackgroundTransparency = 1
	gui.Visible = false
	gui.ZIndex = 20
	gui.Parent = self:EnsureRootGui()

	local box = Instance.new("Frame")
	box.Name = "Box"
	box.BackgroundTransparency = 1
	box.Size = UDim2.fromScale(1, 1)
	box.Parent = gui
	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = Color3.fromRGB(205, 170, 255)
	boxStroke.Thickness = IS_MOBILE and 2 or 1.5
	boxStroke.Transparency = 0.05
	boxStroke.Parent = box

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.AnchorPoint = Vector2.new(0.5, 1)
	name.Position = UDim2.new(0.5, 0, 0, -3)
	name.Size = UDim2.fromOffset(IS_MOBILE and 210 or 180, IS_MOBILE and 19 or 16)
	name.Font = Enum.Font.GothamBold
	name.TextColor3 = Color3.fromRGB(255, 255, 255)
	name.TextSize = IS_MOBILE and 14 or 12
	name.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	name.TextStrokeTransparency = 0.15
	name.Parent = gui

	local distance = Instance.new("TextLabel")
	distance.BackgroundTransparency = 1
	distance.AnchorPoint = Vector2.new(0.5, 0)
	distance.Position = UDim2.new(0.5, 0, 1, 3)
	distance.Size = UDim2.fromOffset(100, IS_MOBILE and 17 or 14)
	distance.Font = Enum.Font.GothamSemibold
	distance.TextColor3 = Color3.fromRGB(205, 170, 255)
	distance.TextSize = IS_MOBILE and 12 or 10
	distance.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	distance.TextStrokeTransparency = 0.2
	distance.Parent = gui

	local healthBack, healthFill, healthText = makeVerticalESPBar(gui, Color3.fromRGB(72, 235, 112), true)
	local armorBack, armorFill, armorText = makeVerticalESPBar(gui, Color3.fromRGB(116, 91, 255), false)
	local object = {
		Gui = gui, Box = box, BoxStroke = boxStroke, Name = name, Distance = distance,
		HealthBack = healthBack, HealthFill = healthFill, HealthText = healthText,
		ArmorBack = armorBack, ArmorFill = armorFill, ArmorText = armorText,
		NextStatsUpdate = 0,
		Active = false,
	}
	self.Objects[target] = object
	return object
end

function ESP:GetArmor(target, character, humanoid, object)
	local dumpedArmor = object and object.ArmorValue
	if not dumpedArmor or dumpedArmor.Parent ~= character then
		dumpedArmor = character and character:FindFirstChild("AmmorHeal")
		if object then object.ArmorValue = dumpedArmor end
	end
	if dumpedArmor then
		local valueOk, value = pcall(function() return dumpedArmor.Value end)
		if valueOk and type(value) == "number" then
			local maxOk, maxValue = pcall(function() return dumpedArmor.MaxValue end)
			if not maxOk or type(maxValue) ~= "number" or maxValue <= 0 then maxValue = 1 end
			if maxValue <= 1 then return math.clamp(value, 0, maxValue) * 100, 100 end
			return math.clamp(value, 0, maxValue), maxValue
		end
	end
	local containers = { character, humanoid, target }
	local armor = readReplicatedNumber(containers, ARMOR_NAMES) or 0
	local maximum = readReplicatedNumber(containers, MAX_ARMOR_NAMES) or 100
	maximum = math.max(1, maximum)
	return math.clamp(armor, 0, maximum), maximum
end

local function projectESPBox(camera, root, cameraDistance)
	local viewport = camera.ViewportSize
	local centre = camera:WorldToViewportPoint(root.Position)
	local centreX, centreY
	if centre.Z > 0.05 then
		centreX, centreY = centre.X, centre.Y
	elseif cameraDistance <= 32 then
		centreX, centreY = viewport.X * 0.5, viewport.Y * 0.48
	else
		return nil
	end

	-- One projection per target. Screen height is derived from distance to avoid
	-- two extra W2S calls and expensive UI spikes on mobile executors.
	local height = math.clamp(1800 / math.max(cameraDistance, 1), IS_MOBILE and 58 or 45, viewport.Y * 0.82)
	local width = math.clamp(height * 0.56, IS_MOBILE and 36 or 30, viewport.X * 0.35)
	local sideMargin = IS_MOBILE and 68 or 55
	local topMargin = IS_MOBILE and 30 or 24
	local left = math.clamp(centreX - width * 0.5, sideMargin, math.max(sideMargin, viewport.X - width - sideMargin))
	local y = math.clamp(centreY - height * 0.5, topMargin, math.max(topMargin, viewport.Y - height - topMargin))
	return left, y, width, height
end

function ESP:UpdateObjectPosition(object, camera)
	local root = object and object.Root
	local humanoid = object and object.Humanoid
	if not self.Enabled or not object.Active or not camera or not root
		or not root.Parent or not humanoid or humanoid.Health <= 0 then
		if object and object.Gui and object.Gui.Visible then object.Gui.Visible = false end
		return false, math.huge
	end

	local cameraDistance = (root.Position - camera.CFrame.Position).Magnitude
	local left, top, boxWidth, boxHeight = projectESPBox(camera, root, cameraDistance)
	local onRange = left ~= nil and cameraDistance <= self.MaxDistance
	if object.Gui.Visible ~= onRange then object.Gui.Visible = onRange end
	if not onRange then return false, cameraDistance end

	local pixelThreshold = IS_MOBILE and 0.35 or 0.2
	if not object.LastLeft or math.abs(left - object.LastLeft) >= pixelThreshold
		or math.abs(top - object.LastTop) >= pixelThreshold then
		object.LastLeft, object.LastTop = left, top
		object.Gui.Position = UDim2.fromOffset(left, top)
	end
	if not object.LastWidth or math.abs(boxWidth - object.LastWidth) >= 0.5
		or math.abs(boxHeight - object.LastHeight) >= 0.5 then
		object.LastWidth, object.LastHeight = boxWidth, boxHeight
		object.Gui.Size = UDim2.fromOffset(boxWidth, boxHeight)
		local barWidth = IS_MOBILE and 7 or 5
		object.HealthBack.Position = UDim2.fromOffset(-barWidth - 4, 0)
		object.HealthBack.Size = UDim2.fromOffset(barWidth, boxHeight)
		object.ArmorBack.Position = UDim2.fromOffset(boxWidth + 4, 0)
		object.ArmorBack.Size = UDim2.fromOffset(barWidth, boxHeight)
	end
	return true, cameraDistance
end

function ESP:RefreshPlayer(target, localRoot)
	if target == player then return end
	local character = resolvePlayerCharacter(target)
	local object = self.Objects[target]
	local humanoid, root
	if object and object.Character == character
		and object.Humanoid and object.Humanoid.Parent == character
		and object.Root and object.Root.Parent == character then
		humanoid, root = object.Humanoid, object.Root
	else
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		root = findCharacterRoot(character)
	end
	if not humanoid or not root or humanoid.Health <= 0 then
		local stale = object
		if stale and stale.Gui then stale.Gui.Visible = false end
		return
	end

	if not object or not object.Gui or not object.Gui.Parent then
		object = self:CreatePlayer(target)
	end
	if object.Character ~= character or object.Humanoid ~= humanoid or object.Root ~= root then
		local characterChanged = object.Character ~= character
		object.Character = character
		object.Humanoid = humanoid
		object.Root = root
		if characterChanged then object.ArmorValue = nil end
		object.NextStatsUpdate = 0
	end

	object.Active = true
	local distance = localRoot and (root.Position - localRoot.Position).Magnitude or math.huge
	local onRange, cameraDistance = self:UpdateObjectPosition(object, Workspace.CurrentCamera)
	if not onRange then return character end

	if object.Name.Visible ~= self.ShowName then object.Name.Visible = self.ShowName end
	if object.Distance.Visible ~= self.ShowDistance then object.Distance.Visible = self.ShowDistance end
	if object.Box.Visible ~= self.ShowBox then object.Box.Visible = self.ShowBox end
	if object.HealthBack.Visible ~= self.ShowHealth then object.HealthBack.Visible = self.ShowHealth end
	if object.ArmorBack.Visible ~= self.ShowArmor then object.ArmorBack.Visible = self.ShowArmor end

	local now = os.clock()
	if now >= (object.NextStatsUpdate or 0) then
		object.NextStatsUpdate = now + self.StatsInterval
		local isPlayerTarget = typeof(target) == "Instance" and target:IsA("Player")
		local displayName = isPlayerTarget and target.DisplayName or target.Name
		object.Name.Text = displayName ~= target.Name and (displayName .. "  @" .. target.Name) or target.Name
		local displayedDistance = distance < math.huge and distance or cameraDistance
		object.Distance.Text = tostring(math.floor(displayedDistance + 0.5)) .. "m"

		local maxHealth = math.max(1, humanoid.MaxHealth)
		local health = math.clamp(humanoid.Health, 0, maxHealth)
		local healthRatio = health / maxHealth
		object.HealthFill.Size = UDim2.fromScale(1, healthRatio)
		object.HealthFill.BackgroundColor3 = Color3.fromRGB(math.floor(255 * (1 - healthRatio)), math.floor(220 * healthRatio + 35), 75)
		object.HealthText.Text = string.format("HP %d%%", math.floor(healthRatio * 100 + 0.5))

		local armor, maxArmor = self:GetArmor(target, character, humanoid, object)
		local armorRatio = armor / maxArmor
		object.ArmorFill.Size = UDim2.fromScale(1, armorRatio)
		object.ArmorText.Text = string.format("AR %d%%", math.floor(armorRatio * 100 + 0.5))
	end
	return character
end

function ESP:TrackWorldModel(instance)
	if instance and instance:IsA("Model") and instance.Parent == Workspace
		and instance:FindFirstChild("AmmorHeal") then
		self.WorldModels[instance] = self.WorldModels[instance] or {}
	end
end

function ESP:BuildBestWorldModels(camera)
	local now = os.clock()
	if now < self.NextWorldSelection then return end
	self.NextWorldSelection = now + 0.5
	local best, bestDistance = {}, {}
	local cameraPosition = camera and camera.CFrame.Position
	for model, record in pairs(self.WorldModels) do
		if model.Parent ~= Workspace then
			self.WorldModels[model] = nil
		else
			local root = record.Root
			if not root or root.Parent ~= model then
				root = findCharacterRoot(model)
				record.Root = root
			end
			if root and cameraPosition then
				local position = root.Position
				local usable = math.abs(position.X) < 1000000
					and math.abs(position.Y) < 1000000 and math.abs(position.Z) < 1000000
				if usable then
					local distance = (position - cameraPosition).Magnitude
					local name = model.Name
					if not bestDistance[name] or distance < bestDistance[name] then
						bestDistance[name] = distance
						best[name] = model
					end
				end
			end
		end
	end
	self.BestWorldByName = best
end

function ESP:RefreshAll()
	local camera = Workspace.CurrentCamera
	self:BuildBestWorldModels(camera)
	local localCharacter = resolvePlayerCharacter(player)
	local localRoot = self.LocalRoot
	if self.LocalCharacter ~= localCharacter or not localRoot or localRoot.Parent ~= localCharacter then
		localRoot = findCharacterRoot(localCharacter)
		self.LocalCharacter, self.LocalRoot = localCharacter, localRoot
	end
	local localReference = localRoot or (camera and { Position = camera.CFrame.Position })
	local present = {}
	for _, object in pairs(self.Objects) do object.Active = false end
	local playerNames = { [player.Name] = true }
	local candidates = {}
	local cameraPosition = camera and camera.CFrame.Position
	local function addCandidate(target, model)
		local root
		local record = model and self.WorldModels[model]
		if record then root = record.Root end
		if not root or root.Parent ~= model then root = findCharacterRoot(model) end
		local distance = root and cameraPosition and (root.Position - cameraPosition).Magnitude or math.huge
		candidates[#candidates + 1] = { Target = target, Distance = distance }
	end
	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= player then
			playerNames[target.Name] = true
			addCandidate(target, self.BestWorldByName[target.Name] or target.Character)
		end
	end
	-- Streaming fallback from the dump: live Never Town characters are direct
	-- Workspace models with AmmorHeal. This catches a close-range replacement
	-- even when Player.Character still references the parked proxy.
	for modelName, model in pairs(self.BestWorldByName) do
		if not playerNames[modelName] and model.Parent == Workspace
			and model ~= localCharacter and model ~= player.Character
		then
			addCandidate(model, model)
		end
	end
	table.sort(candidates, function(a, b) return a.Distance < b.Distance end)
	local total = #candidates
	for index, candidate in ipairs(candidates) do
		local target = candidate.Target
		present[target] = true
		if index <= self.MaxRendered then
			self:RefreshPlayer(target, localReference)
		else
			local object = self.Objects[target]
			if object and object.Gui.Visible then object.Gui.Visible = false end
		end
	end
	for target in pairs(self.Objects) do
		if not present[target] then self:DestroyPlayer(target) end
	end
	local rendered = 0
	for _, object in pairs(self.Objects) do
		if object.Gui and object.Gui.Visible then rendered += 1 end
	end
	if espStatusLabel and os.clock() >= self.NextStatusUpdate then
		self.NextStatusUpdate = os.clock() + 1
		espStatusLabel:SetText(string.format("ESP: %s | players: %d | rendered: %d", self.Enabled and "ON" or "OFF", total, rendered))
	end
end

function ESP:Start()
	if self.Enabled and self.Connection then return end
	self.Enabled = true
	self.Accumulator = 0
	self.RenderAccumulator = 0
	self.NextStatusUpdate = 0
	self.WorldModels = {}
	self.BestWorldByName = {}
	self.NextWorldSelection = 0
	self.LocalCharacter, self.LocalRoot = nil, nil
	for _, child in ipairs(Workspace:GetChildren()) do self:TrackWorldModel(child) end
	if self.WorldAddedConnection then self.WorldAddedConnection:Disconnect() end
	self.WorldAddedConnection = Workspace.ChildAdded:Connect(function(child)
		task.delay(0.5, function()
			if self.Enabled then self:TrackWorldModel(child) end
		end)
	end)
	if self.WorldRemovedConnection then self.WorldRemovedConnection:Disconnect() end
	self.WorldRemovedConnection = Workspace.ChildRemoved:Connect(function(child)
		self.WorldModels[child] = nil
	end)
	if self.ArmorAddedConnection then self.ArmorAddedConnection:Disconnect() end
	self.ArmorAddedConnection = Workspace.DescendantAdded:Connect(function(descendant)
		if descendant.Name == "AmmorHeal" then
			local model = descendant.Parent
			if model and model:IsA("Model") and model.Parent == Workspace then
				self:TrackWorldModel(model)
			end
		end
	end)
	self:RefreshAll()
	if self.Connection then self.Connection:Disconnect() end
	self.Connection = RunService.Heartbeat:Connect(function(delta)
		self.Accumulator += delta
		if self.Accumulator < self.UpdateInterval then return end
		self.Accumulator = 0
		self:RefreshAll()
	end)
	if self.RenderConnection then self.RenderConnection:Disconnect() end
	self.RenderConnection = RunService.RenderStepped:Connect(function(delta)
		self.RenderAccumulator += delta
		if self.RenderAccumulator < self.RenderInterval then return end
		self.RenderAccumulator = 0
		local camera = Workspace.CurrentCamera
		for _, object in pairs(self.Objects) do
			if object.Active then self:UpdateObjectPosition(object, camera) end
		end
	end)
end

function ESP:Stop()
	self.Enabled = false
	if self.Connection then self.Connection:Disconnect(); self.Connection = nil end
	if self.RenderConnection then self.RenderConnection:Disconnect(); self.RenderConnection = nil end
	if self.WorldAddedConnection then self.WorldAddedConnection:Disconnect(); self.WorldAddedConnection = nil end
	if self.WorldRemovedConnection then self.WorldRemovedConnection:Disconnect(); self.WorldRemovedConnection = nil end
	if self.ArmorAddedConnection then self.ArmorAddedConnection:Disconnect(); self.ArmorAddedConnection = nil end
	local targets = {}
	for target in pairs(self.Objects) do targets[#targets + 1] = target end
	for _, target in ipairs(targets) do self:DestroyPlayer(target) end
	if self.RootGui then pcall(self.RootGui.Destroy, self.RootGui); self.RootGui = nil end
	self.ProxyCharacters = {}
	self.NextProxyScan = {}
	self.WorldModels = {}
	self.BestWorldByName = {}
	self.NextWorldSelection = 0
	self.LocalCharacter, self.LocalRoot = nil, nil
	if espStatusLabel then espStatusLabel:SetText("ESP: OFF") end
end

local Spectate = {
	Range = 500,
	SelectedLabel = nil,
	SelectedTarget = nil,
	Target = nil,
	TargetSubject = nil,
	OriginalSubject = nil,
	OriginalCameraType = nil,
	OptionMap = {},
	Connection = nil,
	Accumulator = 0,
	NextListRefresh = 0,
	OutOfRangeSince = nil,
	Page = nil,
}

function Spectate:SetStatus(text)
	if spectateStatusLabel then spectateStatusLabel:SetText("Status: " .. text) end
end

function Spectate:GetLocalRoot()
	local character = resolvePlayerCharacter(player)
	return character, findCharacterRoot(character)
end

function Spectate:RefreshPlayers()
	if not spectateDropdown then return end
	local _, localRoot = self:GetLocalRoot()
	local options, optionMap = {}, {}
	local selectedUpdatedLabel
	for _, target in ipairs(Players:GetPlayers()) do
		if target ~= player then
			local character = resolvePlayerCharacter(target)
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = findCharacterRoot(character)
			if humanoid and root and humanoid.Health > 0 and localRoot then
				local distance = (root.Position - localRoot.Position).Magnitude
				if distance <= self.Range then
					local shownName = target.DisplayName ~= target.Name
						and (target.DisplayName .. " @" .. target.Name) or target.Name
					local label = string.format("%s | %d studs", shownName, math.floor(distance + 0.5))
					options[#options + 1] = { Label = label, Target = target, Distance = distance }
				end
			end
		end
	end
	table.sort(options, function(a, b)
		if math.abs(a.Distance - b.Distance) > 0.01 then return a.Distance < b.Distance end
		return a.Label < b.Label
	end)
	local labels = {}
	for _, option in ipairs(options) do
		labels[#labels + 1] = option.Label
		optionMap[option.Label] = option.Target
		if option.Target == self.SelectedTarget then selectedUpdatedLabel = option.Label end
	end
	if #labels == 0 then labels[1] = "No nearby players in range" end
	self.OptionMap = optionMap
	spectateDropdown:Refresh(labels)
	if selectedUpdatedLabel then
		self.SelectedLabel = selectedUpdatedLabel
		spectateDropdown:SetValue(selectedUpdatedLabel, true)
	else
		self.SelectedLabel = nil
		self.SelectedTarget = nil
	end
	if spectateReadyLabel then
		spectateReadyLabel:SetText(string.format("Players ready: %d / %d", #options, math.max(0, #Players:GetPlayers() - 1)))
	end
end

function Spectate:Watch()
	local target = self.SelectedTarget or (self.SelectedLabel and self.OptionMap[self.SelectedLabel])
	if not target or not target.Parent then
		self:SetStatus("Select a ready player")
		self:RefreshPlayers()
		return
	end
	local character = resolvePlayerCharacter(target)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = findCharacterRoot(character)
	local _, localRoot = self:GetLocalRoot()
	local subject = humanoid or root
	if not subject or not root or not localRoot or (root.Position - localRoot.Position).Magnitude > self.Range then
		self:SetStatus("Target is not ready or out of range")
		self:RefreshPlayers()
		return
	end

	local camera = Workspace.CurrentCamera
	if not camera then self:SetStatus("Camera unavailable"); return end
	if not self.Target then
		self.OriginalSubject = camera.CameraSubject
		self.OriginalCameraType = camera.CameraType
	end
	self.Target = target
	self.TargetSubject = subject
	self.OutOfRangeSince = nil
	camera.CameraSubject = subject
	camera.CameraType = Enum.CameraType.Custom
	self:SetStatus("Watching " .. target.Name)
end

function Spectate:Stop(quiet)
	local camera = Workspace.CurrentCamera
	if camera then
		local localCharacter = resolvePlayerCharacter(player)
		local localHumanoid = localCharacter and localCharacter:FindFirstChildOfClass("Humanoid")
		local localRoot = findCharacterRoot(localCharacter)
		local restoreSubject = localHumanoid or localRoot or self.OriginalSubject
		if restoreSubject then pcall(function() camera.CameraSubject = restoreSubject end) end
		if self.OriginalCameraType then
			pcall(function() camera.CameraType = self.OriginalCameraType end)
		else
			pcall(function() camera.CameraType = Enum.CameraType.Custom end)
		end
	end
	self.Target = nil
	self.TargetSubject = nil
	self.OriginalSubject = nil
	self.OriginalCameraType = nil
	self.OutOfRangeSince = nil
	if not quiet then self:SetStatus("Idle") end
end

function Spectate:UpdateTarget()
	local target = self.Target
	if not target then return end
	if not target.Parent then self:Stop(); return end
	local character = resolvePlayerCharacter(target)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = findCharacterRoot(character)
	local _, localRoot = self:GetLocalRoot()
	local subject = humanoid or root
	if not subject or not root or not localRoot or humanoid and humanoid.Health <= 0 then
		self:Stop()
		return
	end
	local distance = (root.Position - localRoot.Position).Magnitude
	if distance > self.Range then
		self.OutOfRangeSince = self.OutOfRangeSince or os.clock()
		if os.clock() - self.OutOfRangeSince >= 0.25 then self:Stop() end
		return
	end
	self.OutOfRangeSince = nil
	local camera = Workspace.CurrentCamera
	if camera and camera.CameraSubject ~= subject then
		camera.CameraSubject = subject
		camera.CameraType = Enum.CameraType.Custom
	end
	self.TargetSubject = subject
end

function Spectate:StartMonitor()
	if self.Connection then self.Connection:Disconnect() end
	self.Accumulator = 0
	self.Connection = RunService.Heartbeat:Connect(function(delta)
		self.Accumulator += delta
		if self.Accumulator < 0.2 then return end
		self.Accumulator = 0
		if self.Target then self:UpdateTarget() end
		if self.Page and self.Page.Active and os.clock() >= self.NextListRefresh then
			self.NextListRefresh = os.clock() + 1.5
			if not spectateDropdown or not spectateDropdown.IsOpen then self:RefreshPlayers() end
		end
	end)
end

function Spectate:Shutdown()
	if self.Connection then self.Connection:Disconnect(); self.Connection = nil end
	self:Stop(true)
end

local GPS = {
	MapScale = 7.26191,
	MaxDistance = 25000,
	YOffset = 0,
	Target = nil,
	Status = "Place a marker on the in-game map",
	Connection = nil,
	Accumulator = 0,
	Page = nil,
}

function GPS:SetStatus(text)
	self.Status = text
	if gpsStatusLabel then gpsStatusLabel:SetText("GPS: " .. text) end
	if gpsCoordinateLabel then
		if self.Target then
			gpsCoordinateLabel:SetText(string.format("Target: X %.1f | Y %.1f | Z %.1f", self.Target.X, self.Target.Y, self.Target.Z))
		else
			gpsCoordinateLabel:SetText("Target: Not detected")
		end
	end
end

function GPS:FindMapObjects()
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then return nil, "PlayerGui is not ready" end

	-- Never Town keeps the full map under PlayerGui/MiniMap.  Resolve this
	-- path first so another unrelated MapFrame cannot be selected on mobile or
	-- after the UI has been recreated.
	local miniMap = playerGui:FindFirstChild("MiniMap")
	local mapFrame = miniMap and miniMap:FindFirstChild("MapFrame", true)
		or playerGui:FindFirstChild("MapFrame", true)
	if not mapFrame then return nil, "Open the in-game map once" end
	local viewport = mapFrame:FindFirstChild("ViewportFrame", true)
	if not viewport or not viewport:IsA("ViewportFrame") then
		return nil, "ViewportFrame was not found"
	end

	local userMarker = viewport:FindFirstChild("UserMarker", true)
	local mapMarker = viewport:FindFirstChild("MapMarker", true)
	local mapCamera = viewport.CurrentCamera or viewport:FindFirstChild("Camera", true)
	local mapBase = viewport:FindFirstChild("MapBase", true)
	if not userMarker or not userMarker:IsA("GuiObject") then return nil, "UserMarker was not found" end
	if not mapMarker or not mapMarker:IsA("GuiObject") then return nil, "Place a GPS marker on the map" end
	if not mapMarker.Visible then return nil, "Place a GPS marker on the map" end
	if not mapCamera or not mapCamera:IsA("Camera") then return nil, "Map camera was not found" end
	if not mapBase or not mapBase:IsA("BasePart") then return nil, "MapBase was not found" end

	return {
		Viewport = viewport,
		UserMarker = userMarker,
		MapMarker = mapMarker,
		Camera = mapCamera,
		MapBase = mapBase,
	}
end

function GPS:UnprojectMarker(marker, mapObjects)
	local viewport = mapObjects.Viewport
	local viewportPosition = viewport.AbsolutePosition
	local viewportSize = viewport.AbsoluteSize
	if viewportSize.X <= 1 or viewportSize.Y <= 1 then return nil end

	local markerCenter = marker.AbsolutePosition + marker.AbsoluteSize / 2
	local ndcX = ((markerCenter.X - viewportPosition.X) / viewportSize.X) * 2 - 1
	local ndcY = 1 - ((markerCenter.Y - viewportPosition.Y) / viewportSize.Y) * 2
	local camera = mapObjects.Camera
	local cameraCFrame = camera.CFrame
	local fieldOfView = math.rad(camera.FieldOfView)
	if fieldOfView <= 0.01 or fieldOfView >= math.rad(179) then return nil end

	local tanHalfFov = math.tan(fieldOfView * 0.5)
	local aspect = viewportSize.X / viewportSize.Y
	-- ViewportFrame cameras store the back/Z vector in CFrame.LookVector for
	-- this map.  The world ray therefore starts in the inverse direction.
	local rayDirection = -cameraCFrame.LookVector
		+ cameraCFrame.RightVector * (ndcX * aspect * tanHalfFov)
		+ cameraCFrame.UpVector * (ndcY * tanHalfFov)
	if math.abs(rayDirection.Y) < 0.0001 then return nil end

	local distance = (mapObjects.MapBase.Position.Y - cameraCFrame.Position.Y) / rayDirection.Y
	if distance <= 0 or distance ~= distance or distance == math.huge then return nil end
	local point = cameraCFrame.Position + rayDirection * distance
	return Vector2.new(point.X, point.Z)
end

function GPS:ResolveTarget(updateUI)
	local character, root = characterRoot()
	if not character or not root then
		self.Target = nil
		if updateUI ~= false then self:SetStatus("Character is not ready") end
		return nil
	end

	local mapObjects, failure = self:FindMapObjects()
	if not mapObjects then
		self.Target = nil
		if updateUI ~= false then self:SetStatus(failure) end
		return nil
	end

	local playerMapPoint = self:UnprojectMarker(mapObjects.UserMarker, mapObjects)
	local targetMapPoint = self:UnprojectMarker(mapObjects.MapMarker, mapObjects)
	if not playerMapPoint or not targetMapPoint then
		self.Target = nil
		if updateUI ~= false then self:SetStatus("Map marker conversion failed") end
		return nil
	end

	-- Same Never Town conversion used by the External: the viewport map is
	-- rotated 90 degrees and calibrated to 7.26191 world studs per map unit.
	local target = Vector3.new(
		root.Position.X - (targetMapPoint.Y - playerMapPoint.Y) * self.MapScale,
		root.Position.Y + self.YOffset,
		root.Position.Z + (targetMapPoint.X - playerMapPoint.X) * self.MapScale
	)
	local distance = (Vector3.new(target.X, root.Position.Y, target.Z) - root.Position).Magnitude
	if distance > self.MaxDistance or distance ~= distance then
		self.Target = nil
		if updateUI ~= false then self:SetStatus("Marker is outside the safe range") end
		return nil
	end

	self.Target = target
	if updateUI ~= false then self:SetStatus(string.format("Marker ready | %.0f studs", distance)) end
	return target
end

function GPS:Teleport()
	if Farm.Enabled then self:SetStatus("Disable Auto Farm Candy first"); return false end
	local target = self:ResolveTarget(true)
	if not target then return false end
	local character, root = characterRoot()
	if not character or not root then self:SetStatus("Character is not ready"); return false end

	Spectate:Stop(true)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	local offset = target - root.Position
	local ok = pcall(function() character:PivotTo(character:GetPivot() + offset) end)
	if not ok then self:SetStatus("Teleport failed"); return false end
	task.wait(0.2)
	self:SetStatus("Teleport complete")
	return true
end

function GPS:Start()
	if self.Connection then self.Connection:Disconnect() end
	self.Accumulator = 0
	self.Connection = RunService.Heartbeat:Connect(function(delta)
		self.Accumulator += delta
		if self.Accumulator < 0.75 then return end
		self.Accumulator = 0
		if self.Page and self.Page.Active then self:ResolveTarget(true) end
	end)
end

function GPS:Stop()
	if self.Connection then self.Connection:Disconnect(); self.Connection = nil end
	self.Target = nil
end

local Invisible = {
	Enabled = false,
	Depth = 30,
	RealCharacter = nil,
	FakeCharacter = nil,
	FollowConnection = nil,
	DeathConnections = {},
	CollisionState = {},
	OriginalArchivable = nil,
}

function Invisible:DisconnectRuntime()
	if self.FollowConnection then
		self.FollowConnection:Disconnect()
		self.FollowConnection = nil
	end
	for _, connection in ipairs(self.DeathConnections) do
		pcall(connection.Disconnect, connection)
	end
	table.clear(self.DeathConnections)
end

function Invisible:SetRealCollision(enabled)
	local realCharacter = self.RealCharacter
	if not realCharacter then return end
	if not enabled then
		table.clear(self.CollisionState)
		for _, object in ipairs(realCharacter:GetDescendants()) do
			if object:IsA("BasePart") then
				self.CollisionState[object] = {
					CanCollide = object.CanCollide,
					CanTouch = object.CanTouch,
					CanQuery = object.CanQuery,
				}
				object.CanCollide = false
				object.CanTouch = false
				object.CanQuery = false
			end
		end
		return
	end
	for object, state in pairs(self.CollisionState) do
		if object and object.Parent then
			pcall(function()
				object.CanCollide = state.CanCollide
				object.CanTouch = state.CanTouch
				object.CanQuery = state.CanQuery
			end)
		end
	end
	table.clear(self.CollisionState)
end

function Invisible:Start()
	if self.Enabled then return true end
	local realCharacter = player.Character
	local realRoot = realCharacter and realCharacter:FindFirstChild("HumanoidRootPart")
	local realHumanoid = realCharacter and realCharacter:FindFirstChildOfClass("Humanoid")
	if not realCharacter or not realRoot or not realHumanoid or realHumanoid.Health <= 0 then
		return false
	end

	Spectate:Stop(true)
	if Farm.Enabled then Farm:Stop() end

	self.RealCharacter = realCharacter
	self.OriginalArchivable = realCharacter.Archivable
	realCharacter.Archivable = true
	local ok, fakeCharacter = pcall(function() return realCharacter:Clone() end)
	if not ok or not fakeCharacter then
		realCharacter.Archivable = self.OriginalArchivable == true
		self.RealCharacter = nil
		self.OriginalArchivable = nil
		return false
	end

	fakeCharacter.Name = "AraiInvisibleCharacter"
	fakeCharacter:SetAttribute("AraiInvisibleClone", true)
	fakeCharacter.Parent = Workspace
	fakeCharacter:PivotTo(realCharacter:GetPivot())
	local fakeRoot = fakeCharacter:FindFirstChild("HumanoidRootPart")
	local fakeHumanoid = fakeCharacter:FindFirstChildOfClass("Humanoid")
	if not fakeRoot or not fakeHumanoid then
		fakeCharacter:Destroy()
		realCharacter.Archivable = self.OriginalArchivable == true
		self.RealCharacter = nil
		self.OriginalArchivable = nil
		return false
	end

	self.FakeCharacter = fakeCharacter
	self:SetRealCollision(false)
	realRoot.CFrame = fakeRoot.CFrame * CFrame.new(0, -self.Depth, 0)
	realRoot.AssemblyLinearVelocity = Vector3.zero
	realRoot.AssemblyAngularVelocity = Vector3.zero
	player.Character = fakeCharacter
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraSubject = fakeHumanoid
		camera.CameraType = Enum.CameraType.Custom
	end
	self.Enabled = true

	self.FollowConnection = RunService.Heartbeat:Connect(function()
		if not self.Enabled then return end
		local currentRealRoot = self.RealCharacter and self.RealCharacter:FindFirstChild("HumanoidRootPart")
		local currentFakeRoot = self.FakeCharacter and self.FakeCharacter:FindFirstChild("HumanoidRootPart")
		if not currentRealRoot or not currentFakeRoot then
			task.defer(function() self:Stop() end)
			return
		end
		currentRealRoot.CFrame = currentFakeRoot.CFrame * CFrame.new(0, -self.Depth, 0)
		currentRealRoot.AssemblyLinearVelocity = Vector3.zero
		currentRealRoot.AssemblyAngularVelocity = Vector3.zero
	end)

	self.DeathConnections[#self.DeathConnections + 1] = fakeHumanoid.Died:Connect(function()
		task.defer(function() self:Stop() end)
	end)
	self.DeathConnections[#self.DeathConnections + 1] = realHumanoid.Died:Connect(function()
		task.defer(function() self:Stop() end)
	end)
	return true
end

function Invisible:Stop(quiet)
	local wasEnabled = self.Enabled
	self.Enabled = false
	self:DisconnectRuntime()

	local realCharacter = self.RealCharacter
	local fakeCharacter = self.FakeCharacter
	local returnCFrame
	if fakeCharacter and fakeCharacter.Parent then
		local fakeRoot = fakeCharacter:FindFirstChild("HumanoidRootPart")
		if fakeRoot then returnCFrame = fakeRoot.CFrame end
	end

	self:SetRealCollision(true)
	if realCharacter and realCharacter.Parent then
		if returnCFrame then
			pcall(function()
				realCharacter:PivotTo(returnCFrame)
				local realRoot = realCharacter:FindFirstChild("HumanoidRootPart")
				if realRoot then
					realRoot.AssemblyLinearVelocity = Vector3.zero
					realRoot.AssemblyAngularVelocity = Vector3.zero
				end
			end)
		end
		pcall(function() realCharacter.Archivable = self.OriginalArchivable == true end)
		pcall(function() player.Character = realCharacter end)
		local realHumanoid = realCharacter:FindFirstChildOfClass("Humanoid")
		local camera = Workspace.CurrentCamera
		if camera and realHumanoid then
			pcall(function()
				camera.CameraSubject = realHumanoid
				camera.CameraType = Enum.CameraType.Custom
			end)
		end
	end
	if fakeCharacter then pcall(fakeCharacter.Destroy, fakeCharacter) end

	self.RealCharacter = nil
	self.FakeCharacter = nil
	self.OriginalArchivable = nil
	if wasEnabled and not quiet and invisibleToggle and invisibleToggle.Value then
		invisibleToggle:SetValue(false, true)
	end
end

local AntiAFK = {
	Enabled = false,
	Connection = nil,
	Busy = false,
}

function AntiAFK:Pulse()
	if not self.Enabled or self.Busy then return end
	self.Busy = true
	task.spawn(function()
		local camera = Workspace.CurrentCamera
		local cameraCFrame = camera and camera.CFrame or CFrame.new()
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:Button2Down(Vector2.zero, cameraCFrame)
			task.wait(0.1)
			VirtualUser:Button2Up(Vector2.zero, cameraCFrame)
		end)
		self.Busy = false
	end)
end

function AntiAFK:Start()
	if self.Connection then self.Connection:Disconnect(); self.Connection = nil end
	self.Enabled = true
	self.Connection = player.Idled:Connect(function() self:Pulse() end)
end

function AntiAFK:Stop()
	self.Enabled = false
	self.Busy = false
	if self.Connection then self.Connection:Disconnect(); self.Connection = nil end
end

getgenv().AraiSpectate = Spectate
getgenv().AraiGPS = GPS
getgenv().AraiInvisible = Invisible
getgenv().AraiAntiAFK = AntiAFK

Farm.ESP = ESP
Farm.Spectate = Spectate
Farm.GPS = GPS
Farm.Invisible = Invisible
Farm.AntiAFK = AntiAFK
getgenv().AraiESP = ESP

local Window = Library:Window({ Name="A-RAI HUB | Never Town", Game="Never Town" })
local FarmPage = Window:CreatePage({ Name="FARM" })
local Controls = FarmPage:CreateSection({ Name="AUTOMATION", Side=1, Collapsed=false })
local Monitor = FarmPage:CreateSection({ Name="FARM STATUS", Side=2, Collapsed=false })

local PlayerPage = Window:CreatePage({ Name="PLAYER" })
local SpectateControls = PlayerPage:CreateSection({ Name="SPECTATE", Side=1, Collapsed=false })
local GPSControls = PlayerPage:CreateSection({ Name="GPS TELEPORT", Side=1, Collapsed=false })
local Survival = PlayerPage:CreateSection({ Name="AUTO EAT / DRINK", Side=1, Collapsed=false })
local SpectateInfo = PlayerPage:CreateSection({ Name="SPECTATE STATUS", Side=2, Collapsed=false })
local InvisibleControls = PlayerPage:CreateSection({ Name="INVISIBLE", Side=2, Collapsed=false })

local ESPPage = Window:CreatePage({ Name="ESP" })
local ESPControls = ESPPage:CreateSection({ Name="ESP CONTROLS", Side=1, Collapsed=false })

local SettingsPage = Library:CreateSettingsPage(Window)
SettingsPage.Name = "SETTINGS"
if SettingsPage.UI and SettingsPage.UI.Label then SettingsPage.UI.Label.Text = SettingsPage.Name end
local HubSettings = SettingsPage:CreateSubPage({ Name="A-RAI" })
local DeviceSettings = HubSettings:CreateSection({ Name="DEVICE & PERFORMANCE", Side=1, Collapsed=false })
Spectate.Page = PlayerPage
GPS.Page = PlayerPage

Controls:Toggle({ Name="Auto Farm Candy", Flag="AraiAutoCandy", Default=false,
	Callback=function(value) if value then Farm:Start() else Farm:Stop() end end })
Controls:Toggle({ Name="Move Camera To Prompt", Flag="AraiCandyCamera", Default=true,
	Callback=function(value) Farm.Settings.MoveCamera=value end })
Controls:Slider({ Name="Server Cooldown", Flag="AraiCandyCooldown", Min=20, Max=60, Default=30, Suffix="s", Compact=true,
	Callback=function(value) Farm.Settings.Cooldown=math.floor(value) end })
Controls:Slider({ Name="Teleport Y Offset", Flag="AraiCandyYOffset", Min=0, Max=8, Default=0, Suffix=" studs", Compact=true,
	Callback=function(value) Farm.Settings.YOffset=value end })

SpectateControls:Slider({ Name="Spectate Range", Flag="AraiSpectateRange", Min=50, Max=1500, Default=500, Suffix=" studs", Compact=true,
	Callback=function(value)
		Spectate.Range = math.floor(value)
		Spectate.NextListRefresh = 0
		Spectate:RefreshPlayers()
	end })
spectateDropdown = SpectateControls:CreateDropdown({
	Name="Select Player", Items={"No nearby players in range"},
	Callback=function(value)
		if Spectate.OptionMap[value] then
			Spectate.SelectedLabel = value
			Spectate.SelectedTarget = Spectate.OptionMap[value]
			Spectate:SetStatus("Target ready")
		else
			Spectate.SelectedLabel = nil
			Spectate.SelectedTarget = nil
		end
	end,
})
local spectateButtons = SpectateControls:CreateButton({})
spectateButtons:Add("SPECTATE PLAYER", function() Spectate:Watch() end)
spectateButtons:Add("STOP SPECTATE", function() Spectate:Stop() end)
SpectateControls:CreateButton({ Name="REFRESH PLAYERS", Callback=function() Spectate:RefreshPlayers() end })

GPSControls:CreateButton({ Name="READ GPS MARKER", Callback=function() GPS:ResolveTarget(true) end })
GPSControls:Slider({ Name="Landing Y Offset", Flag="AraiGPSYOffset", Min=-5, Max=15, Default=0, Suffix=" studs", Compact=true,
	Callback=function(value) GPS.YOffset=value; GPS:ResolveTarget(true) end })
GPSControls:CreateButton({ Name="TELEPORT TO GPS", Callback=function() GPS:Teleport() end })

invisibleToggle = InvisibleControls:Toggle({ Name="Underground Invisible", Flag="AraiUndergroundInvisible", Default=false,
	Callback=function(value)
		if value then
			if not Invisible:Start() then
				task.defer(function()
					if invisibleToggle then invisibleToggle:SetValue(false, true) end
				end)
			end
		else
			Invisible:Stop(true)
		end
	end })

Survival:Toggle({ Name="Auto Eat / Drink", Flag="AraiAutoConsume", Default=false,
	Callback=function(value) if value then Consume:Start() else Consume:Stop() end end })
Survival:Slider({ Name="Eat Below", Flag="AraiHungerThreshold", Min=10, Max=90, Default=30, Suffix="%", Compact=true,
	Callback=function(value) Consume.HungerThreshold=math.floor(value); updateConsumeUI() end })
Survival:Slider({ Name="Drink Below", Flag="AraiThirstThreshold", Min=10, Max=90, Default=30, Suffix="%", Compact=true,
	Callback=function(value) Consume.ThirstThreshold=math.floor(value); updateConsumeUI() end })
Survival:Label({ Name="Food Slot: 6" })
Survival:Label({ Name="Water Slot: 7" })

ESPControls:Toggle({ Name="Enable ESP", Flag="AraiESPEnabled", Default=false,
	Callback=function(value) if value then ESP:Start() else ESP:Stop() end end })
ESPControls:Toggle({ Name="Name", Flag="AraiESPName", Default=true,
	Callback=function(value) ESP.ShowName=value; if ESP.Enabled then ESP:RefreshAll() end end })
ESPControls:Toggle({ Name="Distance", Flag="AraiESPDistance", Default=true,
	Callback=function(value) ESP.ShowDistance=value; if ESP.Enabled then ESP:RefreshAll() end end })
ESPControls:Toggle({ Name="Box", Flag="AraiESPBox", Default=true,
	Callback=function(value) ESP.ShowBox=value; if ESP.Enabled then ESP:RefreshAll() end end })
ESPControls:Toggle({ Name="Health", Flag="AraiESPHealth", Default=true,
	Callback=function(value) ESP.ShowHealth=value; if ESP.Enabled then ESP:RefreshAll() end end })
ESPControls:Toggle({ Name="Armor", Flag="AraiESPArmor", Default=true,
	Callback=function(value) ESP.ShowArmor=value; if ESP.Enabled then ESP:RefreshAll() end end })
ESPControls:Slider({ Name="Max Distance", Flag="AraiESPMaxDistance", Min=100, Max=5000, Default=1000, Suffix="m", Compact=true,
	Callback=function(value) ESP.MaxDistance=math.floor(value); if ESP.Enabled then ESP:RefreshAll() end end })
ESPControls:Slider({ Name="Max Players", Flag="AraiESPMaxPlayers", Min=5, Max=30, Default=IS_MOBILE and 10 or 18, Suffix="", Compact=true,
	Callback=function(value) ESP.MaxRendered=math.floor(value); if ESP.Enabled then ESP:RefreshAll() end end })
espStatusLabel = ESPControls:Label({ Name="ESP: OFF" })

statusLabel = Monitor:Label("Status: Idle")
spectateReadyLabel = SpectateInfo:Label({ Name="Players ready: 0 / 0" })
spectateStatusLabel = SpectateInfo:Label({ Name="Status: Idle" })
for _, crop in ipairs(CROPS) do
	local label = Monitor:Label({ Name=crop[1]..": 0 / 100" })
	countLabels[crop[1]] = label
	attachIcon(label, CANDY_ICONS[crop[1]])
end
craftedLabel = Monitor:Label({ Name="SeedCandy crafted: 0" })
attachIcon(craftedLabel, CANDY_ICONS.SeedCandy)

local antiAFKToggle = DeviceSettings:Toggle({ Name="Anti AFK", Flag="AraiAntiAFKEnabled", Default=true,
	Callback=function(value) if value then AntiAFK:Start() else AntiAFK:Stop() end end })

local baseLibraryUnload = Library.Unload
function Library:Unload(...)
	AntiAFK:Stop()
	Invisible:Stop(true)
	Spectate:Shutdown()
	GPS:Stop()
	ESP:Stop()
	Consume:Stop()
	Farm:Stop()
	return baseLibraryUnload(self, ...)
end

Spectate:StartMonitor()
Spectate:RefreshPlayers()
GPS:Start()
if antiAFKToggle.Value then AntiAFK:Start() end

Window:SetOpen(true)
updateStatus()
refreshConsumeValues()
updateConsumeUI()
GPS:SetStatus(GPS.Status)
return Farm
