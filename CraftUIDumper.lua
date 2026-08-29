-- A-RAI full Item/Craft/Locker diagnostic dumper.
-- Run it, open the Craft/Locker UI, manually click SeedCandy once, then press
-- SNAPSHOT and FINISH. Files are written inside the executor workspace.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CollectionService = game:GetService("CollectionService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local env = getgenv()

if env.AraiUIDumper and type(env.AraiUIDumper.Stop) == "function" then
	pcall(env.AraiUIDumper.Stop)
	if env.AraiUIDumper.Gui then pcall(function() env.AraiUIDumper.Gui:Destroy() end) end
end

local stamp = os.date("%Y%m%d_%H%M%S")
local folder = string.format("AraiUIDump_%s_%s", tostring(game.PlaceId), stamp)
local snapshotFolder = folder .. "/Snapshots"
local moduleFolder = folder .. "/Modules"
local runtimeFile = folder .. "/Runtime_UI_Events.txt"
local clickFile = folder .. "/Click_Targets.txt"
local remoteCallFile = folder .. "/Remote_Calls.txt"
local running = true
local snapshotBusy = false
local snapshotIndex = 0
local connections = {}
local ownGui
local statusLabel
local fallbackFiles = {}

local keywords = {
	"item", "craft", "recipe", "material", "inventory", "locker", "safe",
	"storage", "candy", "seed", "farm", "category", "itlist", "itemname",
	"amount", "quantity", "fertilizer", "corn", "grape", "cauliflower",
	"orange", "peach",
}

local function clean(value)
	return tostring(value or ""):gsub("\r", "\\r"):gsub("\n", "\\n"):gsub("|", "\\|")
end

local function fileSafe(value)
	return tostring(value):gsub("[^%w%-%._]", "_"):sub(1, 180)
end

local function ensureFolder(path)
	if type(makefolder) ~= "function" then return end
	if type(isfolder) == "function" then
		local ok, exists = pcall(isfolder, path)
		if ok and exists then return end
	end
	pcall(makefolder, path)
end

ensureFolder(folder)
ensureFolder(snapshotFolder)
ensureFolder(moduleFolder)

local function writeText(path, body)
	if type(writefile) == "function" then
		local ok = pcall(writefile, path, body)
		if ok then return true end
	end
	fallbackFiles[path] = body
	return false
end

local function appendText(path, line)
	line = tostring(line) .. "\n"
	if type(appendfile) == "function" then
		local ok = pcall(appendfile, path, line)
		if ok then return end
	end
	local previous = fallbackFiles[path]
	if previous == nil and type(readfile) == "function" then
		local ok, body = pcall(readfile, path)
		if ok then previous = body end
	end
	fallbackFiles[path] = (previous or "") .. line
	writeText(path, fallbackFiles[path])
end

local function pathOf(object)
	if typeof(object) ~= "Instance" then return tostring(object) end
	local parts = {}
	local node = object
	while node do
		table.insert(parts, 1, node.Name)
		if node == game then break end
		node = node.Parent
	end
	return table.concat(parts, "/")
end

local function isOwn(object)
	return ownGui and object and (object == ownGui or object:IsDescendantOf(ownGui))
end

local function effectiveVisible(object)
	local node = object
	while node and node ~= game do
		if node:IsA("GuiObject") and not node.Visible then return false end
		if node:IsA("CanvasGroup") and node.GroupTransparency >= 0.99 then return false end
		if node:IsA("LayerCollector") and not node.Enabled then return false end
		node = node.Parent
	end
	return true
end

local function textOf(object)
	if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then return object.Text end
	return ""
end

local function imageOf(object)
	if object:IsA("ImageLabel") or object:IsA("ImageButton") then return object.Image end
	return ""
end

local function attributesOf(object)
	local ok, attributes = pcall(function() return object:GetAttributes() end)
	if not ok or type(attributes) ~= "table" then return "" end
	local keys, values = {}, {}
	for key in pairs(attributes) do table.insert(keys, key) end
	table.sort(keys)
	for _, key in ipairs(keys) do table.insert(values, key .. "=" .. clean(attributes[key])) end
	return table.concat(values, ";")
end

local function tagsOf(object)
	local ok, tags = pcall(CollectionService.GetTags, CollectionService, object)
	if not ok then return "" end
	table.sort(tags)
	return table.concat(tags, ",")
end

local function connectionCounts(object)
	if type(getconnections) ~= "function" or not object:IsA("GuiButton") then return "" end
	local counts = {}
	for _, eventName in ipairs({"Activated", "MouseButton1Click", "TouchTap"}) do
		local ok, found = pcall(getconnections, object[eventName])
		if ok then table.insert(counts, eventName .. "=" .. tostring(#found)) end
	end
	return table.concat(counts, ",")
end

local function relevant(object)
	local haystack = string.lower(object.Name .. " " .. pathOf(object) .. " " .. textOf(object))
	for _, keyword in ipairs(keywords) do
		if string.find(haystack, keyword, 1, true) then return true end
	end
	return object:IsA("RemoteEvent") or object:IsA("RemoteFunction")
end

local header = table.concat({
	"Class", "Path", "Name", "Parent", "Visible", "EffectiveVisible", "Active",
	"Interactable", "Selectable", "AbsPos", "AbsSize", "Position", "Size",
	"ZIndex", "LayoutOrder", "Text", "Image", "CanvasPosition", "CanvasSize",
	"Connections", "Attributes", "Tags",
}, " | ")

local function objectLine(object)
	local fields = {
		clean(object.ClassName), clean(pathOf(object)), clean(object.Name),
		clean(object.Parent and pathOf(object.Parent) or ""), "", "", "", "", "",
		"", "", "", "", "", "", clean(textOf(object)), clean(imageOf(object)),
		"", "", clean(connectionCounts(object)), clean(attributesOf(object)), clean(tagsOf(object)),
	}
	if object:IsA("GuiObject") then
		fields[5] = tostring(object.Visible)
		fields[6] = tostring(effectiveVisible(object))
		fields[7] = tostring(object.Active)
		pcall(function() fields[8] = tostring(object.Interactable) end)
		pcall(function() fields[9] = tostring(object.Selectable) end)
		fields[10] = string.format("%.1f,%.1f", object.AbsolutePosition.X, object.AbsolutePosition.Y)
		fields[11] = string.format("%.1f,%.1f", object.AbsoluteSize.X, object.AbsoluteSize.Y)
		fields[12] = clean(object.Position)
		fields[13] = clean(object.Size)
		fields[14] = tostring(object.ZIndex)
		fields[15] = tostring(object.LayoutOrder)
		if object:IsA("ScrollingFrame") then
			fields[18] = clean(object.CanvasPosition)
			fields[19] = clean(object.CanvasSize)
		end
	end
	return table.concat(fields, " | ")
end

local function collect(root, onlyRelevant)
	local objects = {root}
	for _, object in ipairs(root:GetDescendants()) do
		if not isOwn(object) then table.insert(objects, object) end
	end
	table.sort(objects, function(a, b) return pathOf(a) < pathOf(b) end)
	local lines = {header}
	for _, object in ipairs(objects) do
		if not onlyRelevant or relevant(object) then table.insert(lines, objectLine(object)) end
	end
	return table.concat(lines, "\n"), #objects
end

local function selectedLine()
	local selected = GuiService.SelectedObject
	return selected and objectLine(selected) or "SelectedObject=nil"
end

local function snapshot(reason)
	if not running or snapshotBusy then return end
	snapshotBusy = true
	snapshotIndex += 1
	local index = string.format("%03d", snapshotIndex)
	local label = fileSafe(reason or "manual")
	local full, count = collect(playerGui, false)
	local hits = collect(playerGui, true)
	local prefix = snapshotFolder .. "/" .. index .. "_" .. label
	writeText(prefix .. "_PlayerGui_FULL.txt", full)
	writeText(prefix .. "_ItemCraft_HITS.txt", hits .. "\n\n" .. selectedLine())
	writeText(folder .. "/LATEST_PlayerGui_FULL.txt", full)
	writeText(folder .. "/LATEST_ItemCraft_HITS.txt", hits .. "\n\n" .. selectedLine())
	appendText(runtimeFile, string.format("%.3f | SNAPSHOT | %s | objects=%d", os.clock(), prefix, count))
	if statusLabel then statusLabel.Text = "Saved #" .. index .. " (" .. tostring(count) .. " objects)" end
	snapshotBusy = false
end

local function serialize(value, depth, seen)
	depth = depth or 0
	seen = seen or {}
	local kind = typeof(value)
	if kind == "Instance" then return "Instance<" .. pathOf(value) .. ">" end
	if kind == "string" then return string.format("%q", value:sub(1, 1000)) end
	if kind ~= "table" then return clean(value) end
	if depth >= 4 then return "{...}" end
	if seen[value] then return "{cycle}" end
	seen[value] = true
	local parts, total = {}, 0
	for key, item in pairs(value) do
		total += 1
		if total > 60 then table.insert(parts, "..."); break end
		table.insert(parts, "[" .. serialize(key, depth + 1, seen) .. "]=" .. serialize(item, depth + 1, seen))
	end
	seen[value] = nil
	return "{" .. table.concat(parts, ",") .. "}"
end

local function dumpReplicatedStorage()
	local relevantBody = collect(ReplicatedStorage, true)
	writeText(folder .. "/ReplicatedStorage_ItemCraft_Remotes.txt", relevantBody)
	local remoteLines = {"Class | Path | Name"}
	local modules = {}
	for _, object in ipairs(ReplicatedStorage:GetDescendants()) do
		if object:IsA("RemoteEvent") or object:IsA("RemoteFunction") then
			table.insert(remoteLines, object.ClassName .. " | " .. pathOf(object) .. " | " .. clean(object.Name))
		elseif object:IsA("ModuleScript") and relevant(object) then
			table.insert(modules, object)
		end
	end
	writeText(folder .. "/All_Remotes.txt", table.concat(remoteLines, "\n"))
	if type(getloadedmodules) == "function" then
		local ok, loaded = pcall(getloadedmodules)
		if ok then
			for _, module in ipairs(loaded) do
				if relevant(module) and not table.find(modules, module) then table.insert(modules, module) end
			end
		end
	end
	local moduleIndex = {"Path | DumpFile | Result"}
	for index, module in ipairs(modules) do
		local outputName = string.format("%03d_%s.lua", index, fileSafe(pathOf(module)))
		local result = "decompile unavailable"
		if type(decompile) == "function" then
			local ok, source = pcall(decompile, module)
			if ok and type(source) == "string" then
				writeText(moduleFolder .. "/" .. outputName, source)
				result = "decompiled"
			else
				result = "decompile failed: " .. clean(source)
			end
		end
		table.insert(moduleIndex, pathOf(module) .. " | " .. outputName .. " | " .. result)
	end
	writeText(folder .. "/Module_Index.txt", table.concat(moduleIndex, "\n"))
end

local function logGuiStack(position, inputType)
	local ok, objects = pcall(GuiService.GetGuiObjectsAtPosition, GuiService, math.floor(position.X), math.floor(position.Y))
	if not ok then return false end
	local lines = {string.format("\n%.3f | INPUT=%s | POS=%.1f,%.1f | STACK=%d", os.clock(), tostring(inputType), position.X, position.Y, #objects)}
	local hitRelevant = false
	for index, object in ipairs(objects) do
		if not isOwn(object) then
			table.insert(lines, tostring(index) .. " | " .. objectLine(object))
			hitRelevant = hitRelevant or relevant(object)
		end
	end
	appendText(clickFile, table.concat(lines, "\n"))
	return hitRelevant
end

local function watchObject(object)
	if isOwn(object) or not (object:IsA("GuiObject") or object:IsA("LayerCollector")) or not relevant(object) then return end
	appendText(runtimeFile, string.format("%.3f | ADDED/WATCH | %s | %s", os.clock(), object.ClassName, pathOf(object)))
	if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
		table.insert(connections, object:GetPropertyChangedSignal("Text"):Connect(function()
			if running then appendText(runtimeFile, string.format("%.3f | TEXT | %s | %s", os.clock(), pathOf(object), clean(object.Text))) end
		end))
	end
	if object:IsA("GuiObject") then
		table.insert(connections, object:GetPropertyChangedSignal("Visible"):Connect(function()
			if running then appendText(runtimeFile, string.format("%.3f | VISIBLE | %s | %s", os.clock(), pathOf(object), tostring(object.Visible))) end
		end))
	end
end

writeText(folder .. "/00_README.txt", table.concat({
	"A-RAI Item/Craft/Locker UI diagnostic dump",
	"PlaceId=" .. tostring(game.PlaceId),
	"JobId=" .. tostring(game.JobId),
	"Generated=" .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
	"Open Craft, click SeedCandy once, set quantity, click CRAFT, open Locker, click SeedCandy, then press SNAPSHOT and FINISH.",
	"Send the whole folder back for analysis.",
}, "\n"))
writeText(runtimeFile, "Time | Event | Path | Value\n")
writeText(clickFile, "Click/touch GUI stacks (topmost first)\n")
writeText(remoteCallFile, "Time | Method | RemotePath | Arguments\n")
dumpReplicatedStorage()

if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" and type(newcclosure) == "function" then
	local oldNamecall
	local ok, err = pcall(function()
		oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
			local method = getnamecallmethod()
			local args = table.pack(...)
			if running and (method == "FireServer" or method == "InvokeServer") then
				task.defer(function()
					local values = {}
					for index = 1, args.n do values[index] = serialize(args[index]) end
					appendText(remoteCallFile, string.format("%.3f | %s | %s | %s", os.clock(), method, pathOf(self), table.concat(values, ", ")))
				end)
			end
			return oldNamecall(self, table.unpack(args, 1, args.n))
		end))
	end)
	appendText(remoteCallFile, ok and "HOOK=enabled" or ("HOOK=failed | " .. clean(err)))
else
	appendText(remoteCallFile, "HOOK=unavailable in this executor")
end

ownGui = Instance.new("ScreenGui")
ownGui.Name = "AraiUIDumper"
ownGui.ResetOnSpawn = false
ownGui.IgnoreGuiInset = true
ownGui.DisplayOrder = 2147483647
local parentOk = false
if type(gethui) == "function" then parentOk = pcall(function() ownGui.Parent = gethui() end) end
if not parentOk then parentOk = pcall(function() ownGui.Parent = CoreGui end) end
if not parentOk then ownGui.Parent = playerGui end

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -16, 0, 80)
panel.Size = UDim2.fromOffset(260, 146)
panel.BackgroundColor3 = Color3.fromRGB(9, 9, 13)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = ownGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(12, 8)
title.Size = UDim2.new(1, -24, 0, 24)
title.Font = Enum.Font.GothamBold
title.Text = "A-RAI UI DUMPER"
title.TextColor3 = Color3.fromRGB(190, 95, 255)
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.fromOffset(12, 35)
statusLabel.Size = UDim2.new(1, -24, 0, 34)
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "Recording clicks, UI and remotes"
statusLabel.TextColor3 = Color3.fromRGB(225, 225, 230)
statusLabel.TextSize = 12
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = panel

local function makeButton(name, text, x, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = UDim2.fromOffset(x, 79)
	button.Size = UDim2.fromOffset(112, 38)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 13
	button.Parent = panel
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
	return button
end

local snapshotButton = makeButton("Snapshot", "SNAPSHOT", 12, Color3.fromRGB(121, 42, 210))
local finishButton = makeButton("Finish", "FINISH", 136, Color3.fromRGB(55, 58, 68))
local pathLabel = Instance.new("TextLabel")
pathLabel.BackgroundTransparency = 1
pathLabel.Position = UDim2.fromOffset(12, 121)
pathLabel.Size = UDim2.new(1, -24, 0, 18)
pathLabel.Font = Enum.Font.Code
pathLabel.Text = folder
pathLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
pathLabel.TextSize = 10
pathLabel.TextTruncate = Enum.TextTruncate.AtEnd
pathLabel.TextXAlignment = Enum.TextXAlignment.Left
pathLabel.Parent = panel

local function stop()
	if not running then return end
	snapshot("finish")
	running = false
	for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
	if type(setclipboard) == "function" then pcall(setclipboard, folder) end
	if statusLabel then statusLabel.Text = "FINISHED - folder path copied" end
	if snapshotButton then snapshotButton.Active = false; snapshotButton.AutoButtonColor = false end
	if finishButton then finishButton.Text = "DONE"; finishButton.Active = false; finishButton.AutoButtonColor = false end
	print("[A-RAI UI Dumper] Saved: " .. folder)
end

table.insert(connections, snapshotButton.Activated:Connect(function() snapshot("manual") end))
table.insert(connections, finishButton.Activated:Connect(stop))
table.insert(connections, playerGui.DescendantAdded:Connect(function(object)
	if running then watchObject(object) end
end))
table.insert(connections, playerGui.DescendantRemoving:Connect(function(object)
	if running and not isOwn(object) and relevant(object) then
		appendText(runtimeFile, string.format("%.3f | REMOVING | %s | %s", os.clock(), object.ClassName, pathOf(object)))
	end
end))
table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
	if not running then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local important = logGuiStack(input.Position, input.UserInputType)
	if important then task.delay(0.35, function() snapshot("after_relevant_click") end) end
end))
for _, object in ipairs(playerGui:GetDescendants()) do watchObject(object) end

env.AraiUIDumper = {Folder = folder, Snapshot = snapshot, Stop = stop, Gui = ownGui}
task.defer(function() snapshot("startup") end)
print("[A-RAI UI Dumper] Recording. Output: " .. folder)
return env.AraiUIDumper
