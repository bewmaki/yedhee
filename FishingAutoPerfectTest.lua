local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Fish = ReplicatedStorage:WaitForChild("RemoteEvent_Solf"):WaitForChild("RemoteEventA"):WaitForChild("Fish")
local Feedback = Fish:WaitForChild("MiniGameFeedback")
local FishingEvent = Fish:WaitForChild("FishingEvent")

local env = _G
if type(getgenv) == "function" then
    env = getgenv()
end

local function stopOldState(key)
    local oldState = env[key]
    if type(oldState) ~= "table" then
        return
    end
    oldState.Enabled = false
    oldState.Sending = false
    oldState.Running = false
    oldState.RunningRoundId = nil
    for _, connection in ipairs(oldState.Connections or {}) do
        pcall(function()
            connection:Disconnect()
        end)
    end
end

stopOldState("FishingSkipTest")
stopOldState("NeverTownFishingSkip")
stopOldState("FishingAutoPerfect")

local State = {
    Enabled = true,
    ReadyToClick = true,
    Clicking = false,
    WaitingFeedback = false,
    MinigameVisible = false,
    MinigameStartedAt = 0,
    InitialDashRotation = 0,
    DashStartedMoving = false,
    LastClickAt = 0,
    Hits = 0,
    Tolerance = 9,
    Connections = {},
}
env.FishingAutoPerfect = State

local function notify(text)
    print("[Fishing Auto Perfect] " .. text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Fishing Auto Perfect",
            Text = text,
            Duration = 4,
        })
    end)
end

local function actuallyVisible(object)
    local current = object
    while current and current ~= PlayerGui do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        end
        current = current.Parent
    end
    return current == PlayerGui
end

local function findFishingUi()
    local system = PlayerGui:FindFirstChild("System")
    local minigame = system and system:FindFirstChild("MINIGAME")
    local fishing = minigame and minigame:FindFirstChild("MiniGameFishing")
    if not fishing then
        return nil
    end

    local ring = fishing:FindFirstChild("ImageLabel")
    local dash = ring and ring:FindFirstChild("dash")
    local target = ring and ring:FindFirstChild("target")
    if not ring or not dash or not target then
        return nil
    end
    if not actuallyVisible(ring) or ring.AbsoluteSize.X <= 0 or ring.AbsoluteSize.Y <= 0 then
        return nil
    end
    return ring, dash, target
end

local function angleDistance(first, second)
    return math.abs(((first - second + 180) % 360) - 180)
end

local function clickRing(ring)
    if State.Clicking or not State.Enabled then
        return
    end
    State.Clicking = true
    State.ReadyToClick = false
    State.WaitingFeedback = true
    State.LastClickAt = os.clock()

    task.spawn(function()
        local position = ring.AbsolutePosition + (ring.AbsoluteSize / 2)
        local sent = pcall(function()
            VirtualInputManager:SendMouseButtonEvent(position.X, position.Y, 0, true, game, 0)
            task.wait()
            VirtualInputManager:SendMouseButtonEvent(position.X, position.Y, 0, false, game, 0)
        end)

        if not sent then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(position)
            end)
        end

        State.Clicking = false
    end)
end

local renderConnection = RunService.RenderStepped:Connect(function()
    if not State.Enabled then
        return
    end

    local ring, dash, target = findFishingUi()
    if not ring then
        if State.MinigameVisible then
            State.MinigameVisible = false
            State.ReadyToClick = true
            State.Clicking = false
            State.WaitingFeedback = false
            State.DashStartedMoving = false
            State.Hits = 0
        end
        return
    end

    if not State.MinigameVisible then
        State.MinigameVisible = true
        State.ReadyToClick = false
        State.Clicking = false
        State.WaitingFeedback = false
        State.MinigameStartedAt = os.clock()
        State.InitialDashRotation = dash.Rotation
        State.DashStartedMoving = false
        State.Hits = 0
        notify("Minigame detected")
    end

    -- The UI is inserted before the server round and its rotations are fully
    -- initialized. Do not accept the initial 0/0 overlap as a real target.
    if not State.DashStartedMoving then
        local elapsed = os.clock() - State.MinigameStartedAt
        local moved = angleDistance(dash.Rotation, State.InitialDashRotation)
        if elapsed >= 0.05 and moved >= 1.5 then
            State.DashStartedMoving = true
            State.ReadyToClick = true
        else
            return
        end
    end

    -- If a synthetic click was ignored by the client, allow another attempt
    -- on the next pass instead of waiting forever for feedback.
    if State.WaitingFeedback and not State.Clicking then
        if os.clock() - State.LastClickAt >= 0.75 then
            State.WaitingFeedback = false
            State.ReadyToClick = true
        end
    end

    if State.ReadyToClick and not State.Clicking and not State.WaitingFeedback then
        local difference = angleDistance(dash.Rotation, target.Rotation)
        if difference <= State.Tolerance then
            clickRing(ring)
        end
    end
end)
State.Connections[#State.Connections + 1] = renderConnection

local feedbackConnection = Feedback.OnClientEvent:Connect(function(payload)
    if not State.Enabled or type(payload) ~= "table" then
        return
    end

    if payload.hit == true then
        State.WaitingFeedback = false
        State.Hits = State.Hits + 1
        if payload.final == true then
            State.ReadyToClick = false
            notify("Perfect complete")
        else
            notify("Perfect hit " .. tostring(State.Hits) .. "/4")
            task.delay(0.08, function()
                if State.Enabled and State.MinigameVisible then
                    State.ReadyToClick = true
                end
            end)
        end
    else
        State.WaitingFeedback = false
        notify("Miss detected; waiting for the next rotation")
        task.delay(0.15, function()
            if State.Enabled and State.MinigameVisible then
                State.ReadyToClick = true
            end
        end)
    end
end)
State.Connections[#State.Connections + 1] = feedbackConnection

local fishingConnection = FishingEvent.OnClientEvent:Connect(function(action, itemName)
    if action == "FinishFishing" then
        State.ReadyToClick = false
        State.WaitingFeedback = false
        State.MinigameVisible = false
        notify("Caught " .. tostring(itemName))
    elseif action == "Canceled" then
        State.ReadyToClick = false
        State.WaitingFeedback = false
        State.MinigameVisible = false
        notify("Fishing canceled")
    end
end)
State.Connections[#State.Connections + 1] = fishingConnection

notify("Ready - start fishing normally")
