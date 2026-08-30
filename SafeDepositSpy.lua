local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local SafeRemotes = ReplicatedStorage:WaitForChild("Game_Modules"):WaitForChild("RemoteEventSafe")
local DepositItem = SafeRemotes:WaitForChild("DepositItem")
local SyncValueDeposit = SafeRemotes:WaitForChild("SyncValueDeposit")

local Folder = "ValenHub_Dumps/SafeSpy"
local Path = Folder .. "/SafeSpy_" .. os.date("%Y%m%d_%H%M%S") .. ".lua"
local Lines = {
    "-- Safe Deposit Spy",
    "-- Started: " .. os.date("%Y-%m-%d %H:%M:%S"),
    "-- PlaceId: " .. tostring(game.PlaceId),
    "",
}

pcall(function()
    makefolder("ValenHub_Dumps")
end)
pcall(function()
    makefolder(Folder)
end)

local function save()
    if type(writefile) == "function" then
        pcall(function()
            writefile(Path, table.concat(Lines, "\n"))
        end)
    end
end

local function notify(text)
    print("[Safe Spy] " .. text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Safe Deposit Spy",
            Text = text,
            Duration = 6,
        })
    end)
end

local function numberText(value)
    if value ~= value then return "0/0" end
    if value == math.huge then return "math.huge" end
    if value == -math.huge then return "-math.huge" end
    return tostring(value)
end

local function serialize(value, seen, depth)
    local kind = typeof(value)
    if kind == "nil" then return "nil" end
    if kind == "string" then return string.format("%q", value) end
    if kind == "number" then return numberText(value) end
    if kind == "boolean" then return tostring(value) end
    if kind == "Vector2" then
        return string.format("Vector2.new(%s, %s)", numberText(value.X), numberText(value.Y))
    end
    if kind == "Vector3" then
        return string.format("Vector3.new(%s, %s, %s)", numberText(value.X), numberText(value.Y), numberText(value.Z))
    end
    if kind == "CFrame" then
        local values = {value:GetComponents()}
        for index, component in ipairs(values) do
            values[index] = numberText(component)
        end
        return "CFrame.new(" .. table.concat(values, ", ") .. ")"
    end
    if kind == "EnumItem" then return tostring(value) end
    if kind == "Instance" then
        return string.format("Instance(%q, %q)", value:GetFullName(), value.ClassName)
    end
    if kind ~= "table" then
        return string.format("%q", "<" .. kind .. "> " .. tostring(value))
    end

    seen = seen or {}
    depth = depth or 0
    if seen[value] then return string.format("%q", "<cycle>") end
    if depth >= 10 then return string.format("%q", "<max-depth>") end
    seen[value] = true
    local entries = {}
    for key, child in pairs(value) do
        entries[#entries + 1] = "[" .. serialize(key, seen, depth + 1) .. "] = " .. serialize(child, seen, depth + 1)
    end
    seen[value] = nil
    table.sort(entries)
    return "{ " .. table.concat(entries, ", ") .. " }"
end

local function record(label, ...)
    local args = table.pack(...)
    local values = {}
    for index = 1, args.n do
        values[#values + 1] = serialize(args[index], {}, 0)
    end
    Lines[#Lines + 1] = string.format("-- [%.3f] %s", os.clock(), label)
    Lines[#Lines + 1] = label .. "(" .. table.concat(values, ", ") .. ")"
    Lines[#Lines + 1] = ""
    save()
    print("[Safe Spy] captured " .. label)
end

local function relevant(text)
    text = tostring(text or ""):lower()
    return text:find("seed", 1, true)
        or text:find("candy", 1, true)
        or text:find("inventory", 1, true)
        or text:find("item", 1, true)
        or text:find("safe", 1, true)
        or text:find("storage", 1, true)
        or text:find("bag", 1, true)
end

local function dumpPlayerData(label)
    Lines[#Lines + 1] = "-- PLAYER DATA: " .. label
    for key, value in pairs(Player:GetAttributes()) do
        if relevant(key) or relevant(value) then
            Lines[#Lines + 1] = string.format("Player.Attribute[%q] = %s", tostring(key), serialize(value, {}, 0))
        end
    end

    for _, object in ipairs(Player:GetDescendants()) do
        local include = relevant(object:GetFullName()) or relevant(object.Name)
        local value
        if object:IsA("ValueBase") then
            local ok, result = pcall(function() return object.Value end)
            if ok then
                value = result
                include = include or relevant(result)
            end
        end
        local attributes = object:GetAttributes()
        for key, attribute in pairs(attributes) do
            if relevant(key) or relevant(attribute) then
                include = true
            end
        end
        if include then
            Lines[#Lines + 1] = string.format("PlayerObject(%q, %q, %s, %s)",
                object:GetFullName(),
                object.ClassName,
                serialize(value, {}, 0),
                serialize(attributes, {}, 0)
            )
        end
    end
    Lines[#Lines + 1] = ""
    save()
end

dumpPlayerData("BEFORE")

DepositItem.OnClientEvent:Connect(function(...)
    record("DepositItem.OnClientEvent", ...)
    task.delay(0.2, function()
        dumpPlayerData("AFTER DepositItem.OnClientEvent")
    end)
end)

SyncValueDeposit.OnClientEvent:Connect(function(...)
    record("SyncValueDeposit.OnClientEvent", ...)
    task.delay(0.2, function()
        dumpPlayerData("AFTER SyncValueDeposit")
    end)
end)

local env = _G
if type(getgenv) == "function" then
    env = getgenv()
end
if type(env.SafeDepositSpyState) == "table" then
    env.SafeDepositSpyState.Enabled = false
end
local State = {Enabled = true}
env.SafeDepositSpyState = State

if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" then
    local oldNamecall
    local function namecallHook(self, ...)
        local method = getnamecallmethod()
        if State.Enabled and self == DepositItem and method == "FireServer" then
            local args = table.pack(...)
            task.defer(function()
                record("DepositItem.FireServer", table.unpack(args, 1, args.n))
                task.delay(0.2, function()
                    dumpPlayerData("AFTER DepositItem.FireServer")
                end)
            end)
        end
        return oldNamecall(self, ...)
    end
    local callback = namecallHook
    if type(newcclosure) == "function" then
        callback = newcclosure(namecallHook)
    end
    oldNamecall = hookmetamethod(game, "__namecall", callback)
else
    Lines[#Lines + 1] = "-- ERROR: hookmetamethod unavailable"
    save()
end

notify("Ready. Open the locker and manually deposit one SeedCandy.")
notify("Saving to " .. Path)
