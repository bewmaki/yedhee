local RS = game:GetService("ReplicatedStorage")
local SG = game:GetService("StarterGui")
local VIM = game:GetService("VirtualInputManager")
local VU = game:GetService("VirtualUser")

local Fish = RS:WaitForChild("RemoteEvent_Solf"):WaitForChild("RemoteEventA"):WaitForChild("Fish")
local Attempt = Fish:WaitForChild("MiniGameAttempt")

local env = _G
if type(getgenv) == "function" then
    env = getgenv()
end

if env.FishingSkipTest then
    env.FishingSkipTest.Enabled = false
    for _, connection in ipairs(env.FishingSkipTest.Connections or {}) do
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local State = {
    Enabled = true,
    Sending = false,
    Running = false,
    AutoClickBusy = false,
    LastRoundId = nil,
    Connections = {},
}
env.FishingSkipTest = State

local function notify(text)
    print("[Fishing Skip] " .. text)
    pcall(function()
        SG:SetCore("SendNotification", {
            Title = "Fishing Skip",
            Text = text,
            Duration = 4,
        })
    end)
end

local function isRoundId(value)
    if type(value) ~= "string" then
        return false
    end
    return value:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

local function findRoundId(value, seen, depth)
    if isRoundId(value) then
        return value
    end
    if type(value) ~= "table" or depth >= 8 then
        return nil
    end
    if seen[value] then
        return nil
    end
    seen[value] = true

    if isRoundId(value.roundId) then
        return value.roundId
    end
    if isRoundId(value.RoundId) then
        return value.RoundId
    end

    for _, child in pairs(value) do
        local found = findRoundId(child, seen, depth + 1)
        if found then
            return found
        end
    end
    return nil
end

local function extractRoundId(...)
    local values = table.pack(...)
    for index = 1, values.n do
        local found = findRoundId(values[index], {}, 0)
        if found then
            return found
        end
    end
    return nil
end

local function skipRound(roundId, source)
    if not State.Enabled or State.Running or State.LastRoundId == roundId then
        return
    end
    State.Running = true
    State.LastRoundId = roundId
    notify("Captured round from " .. source)

    task.spawn(function()
        for _ = 1, 24 do
            if not State.Enabled then
                break
            end
            State.Sending = true
            pcall(function()
                Attempt:FireServer({roundId = roundId})
            end)
            State.Sending = false
            task.wait(0.02)
        end
        State.Sending = false
        State.Running = false
        notify("Sent all attempts")
    end)
end

local function automaticFirstClick()
    if State.AutoClickBusy or State.Running or not State.Enabled then
        return
    end
    State.AutoClickBusy = true
    task.delay(0.15, function()
        local camera = workspace.CurrentCamera
        local size = camera and camera.ViewportSize or Vector2.new(800, 600)
        local x = math.floor(size.X * 0.5)
        local y = math.floor(size.Y * 0.5)
        local sent = pcall(function()
            VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait()
            VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)
        if not sent then
            pcall(function()
                VU:CaptureController()
                VU:ClickButton1(Vector2.new(x, y))
            end)
        end
        State.AutoClickBusy = false
        notify("Minigame detected")
    end)
end

for _, remote in ipairs(Fish:GetChildren()) do
    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
        local connection = remote.OnClientEvent:Connect(function(...)
            local roundId = extractRoundId(...)
            if roundId then
                skipRound(roundId, remote.Name)
            elseif remote.Name == "MiniGameStart" then
                automaticFirstClick()
            end
        end)
        State.Connections[#State.Connections + 1] = connection
    end
end

local oldNamecall
local function namecallHook(self, ...)
    local method = getnamecallmethod()
    if State.Enabled and not State.Sending and not State.Running then
        if self == Attempt and method == "FireServer" then
            local roundId = extractRoundId(...)
            if roundId then
                task.defer(function()
                    skipRound(roundId, "first attempt")
                end)
            end
        end
    end
    return oldNamecall(self, ...)
end

if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" then
    local callback = namecallHook
    if type(newcclosure) == "function" then
        callback = newcclosure(namecallHook)
    end
    oldNamecall = hookmetamethod(game, "__namecall", callback)
else
    notify("hookmetamethod is unavailable")
end

notify("Ready - start fishing")
