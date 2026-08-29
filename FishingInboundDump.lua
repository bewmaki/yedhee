local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Fish = ReplicatedStorage:WaitForChild("RemoteEvent_Solf"):WaitForChild("RemoteEventA"):WaitForChild("Fish")

local env = _G
if type(getgenv) == "function" then
    env = getgenv()
end

if env.FishingInboundDump then
    env.FishingInboundDump.Enabled = false
    for _, connection in ipairs(env.FishingInboundDump.Connections or {}) do
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local State = {
    Enabled = true,
    Connections = {},
    Lines = {},
}
env.FishingInboundDump = State

local Folder = "ValenHub_Dumps/FishingInbound"
local Path = Folder .. "/FishingInbound_" .. os.date("%Y%m%d_%H%M%S") .. ".lua"

pcall(function()
    makefolder("ValenHub_Dumps")
end)
pcall(function()
    makefolder(Folder)
end)

local function notify(text)
    print("[Fishing Inbound] " .. text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Fishing Inbound Dump",
            Text = text,
            Duration = 5,
        })
    end)
end

local function numberText(value)
    if value ~= value then
        return "0/0"
    end
    if value == math.huge then
        return "math.huge"
    end
    if value == -math.huge then
        return "-math.huge"
    end
    return tostring(value)
end

local function serialize(value, seen, depth)
    local kind = typeof(value)
    if kind == "nil" then
        return "nil"
    end
    if kind == "string" then
        return string.format("%q", value)
    end
    if kind == "number" then
        return numberText(value)
    end
    if kind == "boolean" then
        return tostring(value)
    end
    if kind == "Vector2" then
        return string.format("Vector2.new(%s, %s)", numberText(value.X), numberText(value.Y))
    end
    if kind == "Vector3" then
        return string.format("Vector3.new(%s, %s, %s)", numberText(value.X), numberText(value.Y), numberText(value.Z))
    end
    if kind == "UDim2" then
        return string.format("UDim2.new(%s, %s, %s, %s)", numberText(value.X.Scale), numberText(value.X.Offset), numberText(value.Y.Scale), numberText(value.Y.Offset))
    end
    if kind == "Color3" then
        return string.format("Color3.new(%s, %s, %s)", numberText(value.R), numberText(value.G), numberText(value.B))
    end
    if kind == "CFrame" then
        local components = {value:GetComponents()}
        for index, component in ipairs(components) do
            components[index] = numberText(component)
        end
        return "CFrame.new(" .. table.concat(components, ", ") .. ")"
    end
    if kind == "EnumItem" then
        return tostring(value)
    end
    if kind == "Instance" then
        return string.format("Instance(%q)", value:GetFullName())
    end
    if kind ~= "table" then
        return string.format("%q", "<" .. kind .. "> " .. tostring(value))
    end

    seen = seen or {}
    depth = depth or 0
    if seen[value] then
        return string.format("%q", "<cycle>")
    end
    if depth >= 10 then
        return string.format("%q", "<max-depth>")
    end
    seen[value] = true

    local entries = {}
    for key, child in pairs(value) do
        local keyText = "[" .. serialize(key, seen, depth + 1) .. "]"
        entries[#entries + 1] = keyText .. " = " .. serialize(child, seen, depth + 1)
    end
    seen[value] = nil
    table.sort(entries)
    return "{ " .. table.concat(entries, ", ") .. " }"
end

local function save()
    if type(writefile) ~= "function" then
        return false
    end
    return pcall(function()
        writefile(Path, table.concat(State.Lines, "\n"))
    end)
end

local function addLine(text)
    State.Lines[#State.Lines + 1] = text
end

local function recordEvent(remote, ...)
    local args = table.pack(...)
    local values = {}
    for index = 1, args.n do
        values[#values + 1] = serialize(args[index], {}, 0)
    end
    addLine(string.format("-- [%.3f] %s.OnClientEvent", os.clock(), remote.Name))
    addLine(string.format("Fish.%s.OnClientEvent(%s)", remote.Name, table.concat(values, ", ")))
    addLine("")
    save()
    print("[Fishing Inbound] captured " .. remote.Name)
end

local Keywords = {
    "fish",
    "mini",
    "ring",
    "needle",
    "pointer",
    "target",
    "zone",
    "bar",
    "hook",
}

local function relevantGui(object)
    if not object:IsA("GuiObject") then
        return false
    end
    local path = object:GetFullName():lower()
    for _, keyword in ipairs(Keywords) do
        if path:find(keyword, 1, true) then
            return true
        end
    end
    return false
end

local function property(object, name)
    local ok, value = pcall(function()
        return object[name]
    end)
    if ok then
        return serialize(value, {}, 0)
    end
    return "<unavailable>"
end

local function snapshotUi(label)
    addLine("-- UI SNAPSHOT: " .. label)
    local count = 0
    for _, object in ipairs(PlayerGui:GetDescendants()) do
        if relevantGui(object) then
            count = count + 1
            addLine(string.format(
                "-- %s | Class=%s Visible=%s Rotation=%s Position=%s Size=%s AbsolutePosition=%s AbsoluteSize=%s Text=%s Image=%s",
                object:GetFullName(),
                object.ClassName,
                property(object, "Visible"),
                property(object, "Rotation"),
                property(object, "Position"),
                property(object, "Size"),
                property(object, "AbsolutePosition"),
                property(object, "AbsoluteSize"),
                property(object, "Text"),
                property(object, "Image")
            ))
            if count >= 400 then
                addLine("-- UI snapshot stopped at 400 matching objects")
                break
            end
        end
    end
    addLine("")
    save()
end

addLine("-- Never Town fishing inbound dump")
addLine("-- PlaceId: " .. tostring(game.PlaceId))
addLine("-- Started: " .. os.date("%Y-%m-%d %H:%M:%S"))
addLine("")
save()

for _, remote in ipairs(Fish:GetChildren()) do
    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
        local connection = remote.OnClientEvent:Connect(function(...)
            if not State.Enabled then
                return
            end
            recordEvent(remote, ...)
            if remote.Name == "MiniGameStart" then
                task.defer(function()
                    snapshotUi("MiniGameStart immediate")
                end)
                task.delay(0.25, function()
                    snapshotUi("MiniGameStart +0.25s")
                end)
            end
        end)
        State.Connections[#State.Connections + 1] = connection
    end
end

notify("Ready. Fish once, finish the minigame, then send me the newest dump.")
notify("Saving to " .. Path)
