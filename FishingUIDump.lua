local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local Fish = ReplicatedStorage:WaitForChild("RemoteEvent_Solf"):WaitForChild("RemoteEventA"):WaitForChild("Fish")
local Feedback = Fish:WaitForChild("MiniGameFeedback")

local Folder = "ValenHub_Dumps/FishingUI"
local Path = Folder .. "/FishingUI_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
local Lines = {
    "Fishing UI Dump v1",
    "Started: " .. os.date("%Y-%m-%d %H:%M:%S"),
    "PlaceId: " .. tostring(game.PlaceId),
    "",
}
local Captured = false

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
    print("[Fishing UI Dump] " .. text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Fishing UI Dump v1",
            Text = text,
            Duration = 5,
        })
    end)
end

local function valueOf(object, property)
    local ok, value = pcall(function()
        return object[property]
    end)
    if not ok then
        return "<unavailable>"
    end
    if typeof(value) == "Vector2" then
        return string.format("(%.3f, %.3f)", value.X, value.Y)
    end
    if typeof(value) == "UDim2" then
        return string.format("(%g,%g,%g,%g)", value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
    end
    if typeof(value) == "Color3" then
        return string.format("(%.4f, %.4f, %.4f)", value.R, value.G, value.B)
    end
    return tostring(value)
end

local function isShown(object)
    local current = object
    while current and current ~= PlayerGui do
        if current:IsA("GuiObject") then
            local ok, visible = pcall(function()
                return current.Visible
            end)
            if ok and not visible then
                return false
            end
        end
        current = current.Parent
    end
    return true
end

local function snapshot(label)
    Lines[#Lines + 1] = "===== " .. label .. " | " .. string.format("%.3f", os.clock()) .. " ====="
    local count = 0

    for _, object in ipairs(PlayerGui:GetDescendants()) do
        local include = false
        if object:IsA("GuiObject") and isShown(object) then
            include = true
        elseif object:IsA("UIGradient") then
            local parent = object.Parent
            include = parent and parent:IsA("GuiObject") and isShown(parent)
        end

        if include then
            count = count + 1
            Lines[#Lines + 1] = table.concat({
                object:GetFullName(),
                "Class=" .. object.ClassName,
                "Rotation=" .. valueOf(object, "Rotation"),
                "Position=" .. valueOf(object, "Position"),
                "Size=" .. valueOf(object, "Size"),
                "AbsPos=" .. valueOf(object, "AbsolutePosition"),
                "AbsSize=" .. valueOf(object, "AbsoluteSize"),
                "Color=" .. valueOf(object, "BackgroundColor3"),
                "ImageColor=" .. valueOf(object, "ImageColor3"),
                "Text=" .. valueOf(object, "Text"),
                "Image=" .. valueOf(object, "Image"),
            }, " | ")

            if count >= 1500 then
                Lines[#Lines + 1] = "Stopped at 1500 visible UI objects"
                break
            end
        end
    end

    Lines[#Lines + 1] = "Objects=" .. tostring(count)
    Lines[#Lines + 1] = ""
    save()
end

save()

Feedback.OnClientEvent:Connect(function(payload)
    if Captured or type(payload) ~= "table" or payload.hit ~= true then
        return
    end
    Captured = true
    Lines[#Lines + 1] = "First hit roundId=" .. tostring(payload.roundId) .. " targetAngle=" .. tostring(payload.targetAngle)
    save()

    task.spawn(function()
        local ok, message = pcall(function()
            snapshot("FIRST HIT +0.00")
            task.wait(0.10)
            snapshot("FIRST HIT +0.10")
            task.wait(0.10)
            snapshot("FIRST HIT +0.20")
        end)
        if not ok then
            Lines[#Lines + 1] = "SNAPSHOT ERROR: " .. tostring(message)
            save()
        end
        notify("Captured three UI snapshots. Finish fishing, then ask Codex to check.")
    end)
end)

notify("Ready. Play the minigame manually until the first correct hit.")
notify("Saving to " .. Path)
