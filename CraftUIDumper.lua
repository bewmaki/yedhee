-- Open the Crafting Table UI first, then run this script.
-- The dump is written to the executor workspace as CraftUIDump_*.txt.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function clean(value)
	return tostring(value or ""):gsub("\r", "\\r"):gsub("\n", "\\n"):gsub("|", "\\|")
end

local function pathOf(object)
	local parts = {}
	local node = object
	while node and node ~= playerGui.Parent do
		table.insert(parts, 1, node.Name)
		if node == playerGui then break end
		node = node.Parent
	end
	return table.concat(parts, "/")
end

local function effectiveVisible(object)
	local node = object
	while node and node ~= playerGui do
		if node:IsA("GuiObject") and not node.Visible then return false end
		if node:IsA("CanvasGroup") and node.GroupTransparency >= 0.99 then return false end
		if node:IsA("LayerCollector") and not node.Enabled then return false end
		node = node.Parent
	end
	return true
end

local function findCraftRoot()
	local system = playerGui:FindFirstChild("System")
	local exact = system and system:FindFirstChild("Craft")
	if exact then return exact end

	for _, object in ipairs(playerGui:GetDescendants()) do
		if (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox"))
			and string.find(string.lower(object.Text), "crafting table", 1, true) then
			local node = object
			while node.Parent and node.Parent ~= playerGui do
				if node:IsA("ScreenGui") then return node end
				node = node.Parent
			end
			return node
		end
	end
end

local craftRoot
for _ = 1, 150 do
	craftRoot = findCraftRoot()
	if craftRoot then break end
	task.wait(0.1)
end

if not craftRoot then
	error("Craft UI not found. Open the Crafting Table screen, then run CraftUIDumper.lua again.")
end

local lines = {
	"Craft UI focused dump",
	"PlaceId=" .. tostring(game.PlaceId),
	"JobId=" .. tostring(game.JobId),
	"Root=" .. pathOf(craftRoot),
	"Generated=" .. os.date("!%Y-%m-%dT%H:%M:%SZ"),
	"",
	"Class | Path | Name | Visible | EffectiveVisible | Active | Interactable | AbsPos | AbsSize | ZIndex | LayoutOrder | Text | Image",
}

local objects = { craftRoot }
for _, object in ipairs(craftRoot:GetDescendants()) do
	table.insert(objects, object)
end

for _, object in ipairs(objects) do
	local fields = {
		clean(object.ClassName),
		clean(pathOf(object)),
		clean(object.Name),
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
		"",
	}

	if object:IsA("GuiObject") then
		fields[4] = tostring(object.Visible)
		fields[5] = tostring(effectiveVisible(object))
		fields[6] = tostring(object.Active)
		pcall(function() fields[7] = tostring(object.Interactable) end)
		fields[8] = string.format("%.1f,%.1f", object.AbsolutePosition.X, object.AbsolutePosition.Y)
		fields[9] = string.format("%.1f,%.1f", object.AbsoluteSize.X, object.AbsoluteSize.Y)
		fields[10] = tostring(object.ZIndex)
		fields[11] = tostring(object.LayoutOrder)
	end
	if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
		fields[12] = clean(object.Text)
	end
	if object:IsA("ImageLabel") or object:IsA("ImageButton") then
		fields[13] = clean(object.Image)
	end
	table.insert(lines, table.concat(fields, " | "))
end

local body = table.concat(lines, "\n")
local filename = string.format("CraftUIDump_%s_%s.txt", tostring(game.PlaceId), os.date("%Y%m%d_%H%M%S"))

if type(writefile) == "function" then
	writefile(filename, body)
	print("[CraftUIDumper] Saved: " .. filename)
else
	if type(setclipboard) == "function" then setclipboard(body) end
	warn("[CraftUIDumper] writefile is unavailable; dump copied to clipboard when supported.")
end

getgenv().CraftUIDumpResult = {
	File = filename,
	Root = pathOf(craftRoot),
	Count = #objects,
	Text = body,
}

return getgenv().CraftUIDumpResult
