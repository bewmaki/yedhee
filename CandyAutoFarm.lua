-- CandyAutoFarm.lua
-- Luau port of the External Candy flow. Uses Roblox instances/UI, not memory access.

local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local Library = getgenv().Library
if not Library then
	local ok, result = pcall(function()
		if type(isfile) == "function" and isfile("UILIB.lua") then
			return loadstring(readfile("UILIB.lua"))()
		end
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/bewmaki/yedhee/main/UILIB.lua"))()
	end)
	if not ok or not result then
		error("CandyAutoFarm: UILIB load failed: " .. tostring(result))
	end
	Library = result
end

local old = getgenv().SolixCandyFarm
if type(old) == "table" and type(old.Stop) == "function" then pcall(old.Stop, old) end

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
getgenv().SolixCandyFarm = Farm
for _, crop in ipairs(CROPS) do Farm.Counts[crop[1]] = 0 end

local statusLabel, craftedLabel
local countLabels = {}

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

local function click(gui)
	if not gui or not gui:IsA("GuiObject") then return false end
	if type(firesignal) == "function" then
		local ok, signal = pcall(function() return gui.Activated end)
		if ok and signal and pcall(firesignal, signal) then return true end
	end
	local point = gui.AbsolutePosition + gui.AbsoluteSize / 2
	VIM:SendMouseButtonEvent(point.X, point.Y, 0, true, game, 0)
	task.wait(0.04)
	VIM:SendMouseButtonEvent(point.X, point.Y, 0, false, game, 0)
	return true
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
	if Farm.Settings.MoveCamera and Workspace.CurrentCamera then
		Workspace.CurrentCamera.CFrame = CFrame.lookAt(point[3], point[3] + point[4])
	end
	local prompt = waitFor(function() return findPrompt(point) end, 1.5, id)
	if prompt and type(fireproximityprompt) == "function" and pcall(fireproximityprompt, prompt, prompt.HoldDuration) then
		return waitActive(0.5, id)
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
	text = tostring(text or ""):gsub(",", "")
	local a, b = text:match("(%d+)%s*/%s*(%d+)")
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
	if not item then return 0, false end
	local branch = item
	for _ = 1, 4 do
		local count = branchCount(branch)
		if count ~= nil then return count, true end
		if branch == root then break end
		branch = branch.Parent
	end
	return 1, true
end

local function inventoryPanel()
	local gui = player:FindFirstChildOfClass("PlayerGui")

	-- Current Some Town inventory:
	-- PlayerGui/Inventory/CanvasGroup/Main/Body/<Item>/Main/Amount
	local inventory = gui and gui:FindFirstChild("Inventory")
	local canvas = inventory and inventory:FindFirstChild("CanvasGroup")
	local modernMain = canvas and canvas:FindFirstChild("Main")
	local modernBody = modernMain and modernMain:FindFirstChild("Body")
	if modernBody and modernBody:IsA("ScrollingFrame") and visible(modernBody) then
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
	local main = card and card:FindFirstChild("Main")
	local amount = main and main:FindFirstChild("Amount")
	if not amount or not (amount:IsA("TextLabel") or amount:IsA("TextButton")) then
		return 0, false
	end
	local current = parseCount(amount.Text)
	return current or 0, current ~= nil
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

local function scanInventory(id)
	stage(2)
	local opened = inventoryPanel() == nil
	if opened then key(Enum.KeyCode.T) end
	local panel = waitFor(function()
		local root = inventoryPanel()
		return root
	end, 5, id)
	if not panel then return false end
	local _, mode = inventoryPanel()
	if mode == "modern" then
		selectModernInventoryAll()
		if not waitActive(0.5, id) then return false end
	end
	if not waitInventoryCards(panel, id) then return false end
	if not waitActive(0.5, id) then return false end

	local observed = {}
	for scan = 1, 3 do
		for _, crop in ipairs(CROPS) do
			local count, found
			if mode == "modern" then
				count, found = modernItemCount(panel, crop[1])
			else
				count, found = itemCount(panel, crop[1])
			end
			if found then observed[crop[1]] = math.max(observed[crop[1]] or 0, count) end
		end
		if scan < 3 and not waitActive(0.35, id) then return false end
	end

	-- Commit the scan only after all polling passes. Missing cards in the fully
	-- populated modern inventory mean a real zero, not "GUI still loading".
	for _, crop in ipairs(CROPS) do Farm.Counts[crop[1]] = observed[crop[1]] or 0 end
	updateStatus("Inventory checked: " .. (mode or "unknown"))
	if opened and inventoryPanel() then key(Enum.KeyCode.T); waitActive(0.3, id) end
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
	local exit = bg and (bg:FindFirstChild("Exit") or exact(bg, "Exit") or exact(bg, "Close"))
	if exit then click(exit) else key(Enum.KeyCode.Escape) end
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
		node = node.Parent
	end
	if object then
		for _, child in ipairs(object:GetDescendants()) do
			if child:IsA("GuiButton") and visible(child) then return child end
		end
	end
	return object
end

local function findQuantityLabel(bg)
	local frame = bg:FindFirstChild("Frame")
	local image = frame and frame:FindFirstChild("ImageLabel")
	local legacy = image and image:FindFirstChild("A")
	if legacy and tonumber(legacy.Text) then return legacy, image end

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
	stage(5)
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
		click(tableButton); waitActive(0.35, id)
		local category = exact(select, "Category_CategoryCandy")
		if category then click(category); waitActive(0.5, id) end
	end
	local list = bg:FindFirstChild("ITlist")
	local listFrame = list and list:FindFirstChild("Frame")
	local seed = (listFrame and exact(listFrame, "SeedCandy")) or visibleText(bg, "SeedCandy")
	if not seed then closeGui(bg); return false end
	local card = clickableFrom(seed, bg)
	click(card); if not waitActive(0.6, id) then return false end
	local amount, quantityContainer = findQuantityLabel(bg)
	if not amount then closeGui(bg); return false end
	for _ = 1, 8 do
		local quantity = tonumber(amount.Text)
		if quantity == 5 then break end
		local adjust = findQuantityButton(bg, amount, quantityContainer, (quantity or 0) < 5)
		if not adjust then closeGui(bg); return false end
		click(adjust); waitActive(0.4, id)
		amount, quantityContainer = findQuantityLabel(bg)
		if not amount then closeGui(bg); return false end
	end
	if tonumber(amount.Text) ~= 5 then closeGui(bg); return false end
	if not waitFor(function() return requirementsReady(bg) end, 2, id) then closeGui(bg); return false end
	local main = bg:FindFirstChild("Main")
	local craftText = visibleText(bg, "CRAFT")
	local craftButton = (main and main:FindFirstChild("Craft")) or clickableFrom(craftText, bg)
	if not craftButton or not click(craftButton) then closeGui(bg); return false end
	if not waitActive(12, id) then return false end
	closeGui(bg); Farm.Crafted += 5
	for _, crop in ipairs(CROPS) do Farm.Counts[crop[1]] = math.max(0, Farm.Counts[crop[1]]-100) end
	updateStatus(); return true
end

local function lockerPanels()
	local gui = player:FindFirstChildOfClass("PlayerGui")
	local locker = gui and gui:FindFirstChild("LockerUI")
	local ui = locker and locker:FindFirstChild("ui")
	local left = ui and ui:FindFirstChild("Left")
	local right = ui and (ui:FindFirstChild("Right") or ui:FindFirstChild("Safe"))
	return ui and left and right and visible(ui) and {ui, left} or nil
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
	local ui, inventory = panels[1], panels[2]
	local seed = exact(inventory, "SeedCandy")
	if not seed then closeGui(ui); return false end
	local card = seed
	while card.Parent and card.Parent ~= inventory and not card:IsA("GuiButton") do card = card.Parent end
	click(card); waitActive(0.85, id)
	local removed = exact(inventory, "SeedCandy") == nil
	closeGui(ui); return removed and active(id)
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
	updateStatus("Stopped")
end

local Window = Library:Window({ Name="Solix Hub | Candy Farm", Game="Some Town" })
local Page = Window:CreatePage({ Name="Candy Farm" })
local Controls = Page:CreateSection({ Name="Automation", Side=1, Collapsed=false })
local Monitor = Page:CreateSection({ Name="Monitor", Side=2, Collapsed=false })

Controls:Toggle({ Name="Auto Farm Candy", Flag="SolixAutoCandy", Default=false,
	Tooltip="Farm 5 ingredients, craft SeedCandy x5 and deposit it at REBEL.",
	Callback=function(value) if value then Farm:Start() else Farm:Stop() end end })
Controls:Toggle({ Name="Move Camera To Prompt", Flag="SolixCandyCamera", Default=true,
	Callback=function(value) Farm.Settings.MoveCamera=value end })
Controls:Slider({ Name="Server Cooldown", Flag="SolixCandyCooldown", Min=20, Max=60, Default=30, Suffix="s", Compact=true,
	Callback=function(value) Farm.Settings.Cooldown=math.floor(value) end })
Controls:Slider({ Name="Teleport Y Offset", Flag="SolixCandyYOffset", Min=0, Max=8, Default=0, Suffix=" studs", Compact=true,
	Callback=function(value) Farm.Settings.YOffset=value end })

statusLabel = Monitor:Label("Status: Idle")
for _, crop in ipairs(CROPS) do
	local label = Monitor:Label({ Name=crop[1]..": 0 / 100", Description="Candy ingredient" })
	countLabels[crop[1]] = label
	attachIcon(label, CANDY_ICONS[crop[1]])
end
craftedLabel = Monitor:Label({ Name="SeedCandy crafted: 0", Description="Output produced this run" })
attachIcon(craftedLabel, CANDY_ICONS.SeedCandy)
Monitor:Label({ Name="External flow", Description="Cauliflower > Peach > Orange > Corn > Grape; 100 each, 30-second cooldown, craft SeedCandy x5, then deposit at REBEL." })

Library:CreateSettingsPage(Window)
Window:SetOpen(true)
updateStatus()
return Farm
