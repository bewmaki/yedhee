local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local LockerPosition = Vector3.new(4188.2, 14.9, 4644.4)
local Folder = "ValenHub_Dumps/DepositTest"
local Path = Folder .. "/DepositTest_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
local Lines = {
    "SeedCandy Deposit Test",
    "Started: " .. os.date("%Y-%m-%d %H:%M:%S"),
    "PlaceId: " .. tostring(game.PlaceId),
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

local function log(text)
    Lines[#Lines + 1] = string.format("[%.3f] %s", os.clock(), tostring(text))
    save()
    print("[Deposit Test] " .. tostring(text))
end

local function notify(text)
    log(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "SeedCandy Deposit Test",
            Text = text,
            Duration = 5,
        })
    end)
end

local function visible(gui)
    if not gui or not gui:IsA("GuiObject") then
        return false
    end
    local node = gui
    while node do
        if node:IsA("GuiObject") and not node.Visible then
            return false
        end
        if node:IsA("CanvasGroup") and node.GroupTransparency >= 0.99 then
            return false
        end
        if node:IsA("ScreenGui") and not node.Enabled then
            return false
        end
        node = node.Parent
    end
    return gui.AbsoluteSize.X > 0 and gui.AbsoluteSize.Y > 0
end

local function waitFor(callback, timeout)
    local finish = os.clock() + timeout
    repeat
        local ok, result = pcall(callback)
        if ok and result then
            return result
        end
        task.wait(0.1)
    until os.clock() >= finish
    return nil
end

local function exact(root, wanted)
    if not root then
        return nil
    end
    for _, object in ipairs(root:GetDescendants()) do
        if object.Name == wanted then
            return object
        end
        if (object:IsA("TextLabel") or object:IsA("TextButton")) and object.Text == wanted then
            return object
        end
    end
    return nil
end

local function parseCount(text)
    text = tostring(text or ""):gsub("<[^>]->", ""):gsub(",", "")
    local current = text:match("(%d+)%s*[/|]%s*%d+")
    if current then
        return tonumber(current)
    end
    return tonumber(text:match("^%s*(%d+)%s*$"))
end

local function itemCount(root, itemName)
    local item = exact(root, itemName)
    if not item then
        return 0, true
    end
    local branch = item
    for _ = 1, 5 do
        if not branch or branch == root then
            break
        end
        local amount = branch:FindFirstChild("Amount", true)
        if amount and (amount:IsA("TextLabel") or amount:IsA("TextButton") or amount:IsA("TextBox")) then
            local count = parseCount(amount.Text)
            if count ~= nil then
                return count, true
            end
        end
        for _, object in ipairs(branch:GetDescendants()) do
            if object:IsA("TextLabel") or object:IsA("TextButton") then
                local count = parseCount(object.Text)
                if count ~= nil then
                    return count, true
                end
            end
        end
        branch = branch.Parent
    end
    return 0, false
end

local function lockerPanels()
    local playerGui = Player:FindFirstChildOfClass("PlayerGui")
    local locker = playerGui and playerGui:FindFirstChild("LockerUI")
    local ui = locker and locker:FindFirstChild("ui")
    local left = ui and ui:FindFirstChild("Left")
    local right = ui and (ui:FindFirstChild("Right") or ui:FindFirstChild("Safe"))
    if ui and left and right and visible(ui) then
        return ui, left, right
    end
    return nil
end

local function promptPosition(prompt)
    local parent = prompt.Parent
    if parent:IsA("Attachment") then
        return parent.WorldPosition
    end
    if parent:IsA("BasePart") then
        return parent.Position
    end
    local part = parent:FindFirstAncestorWhichIsA("BasePart")
    return part and part.Position or nil
end

local function findLockerPrompt()
    local candidates = {}
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("ProximityPrompt") and object.Enabled then
            local position = promptPosition(object)
            if position and (position - LockerPosition).Magnitude <= 220 then
                candidates[#candidates + 1] = {Prompt = object, Distance = (position - LockerPosition).Magnitude}
            end
        end
    end
    table.sort(candidates, function(left, right)
        return left.Distance < right.Distance
    end)
    return candidates[1] and candidates[1].Prompt or nil
end

local function openLocker()
    local existing = {lockerPanels()}
    if existing[1] then
        return existing
    end

    local character = Player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not root then
        return nil
    end
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    character:PivotTo(CFrame.new(LockerPosition))
    task.wait(0.5)

    for attempt = 1, 3 do
        local prompt = findLockerPrompt()
        log("Open attempt " .. tostring(attempt) .. " prompt=" .. tostring(prompt and prompt:GetFullName() or "nil"))
        local fired = false
        if prompt and type(fireproximityprompt) == "function" then
            fired = pcall(function()
                fireproximityprompt(prompt, prompt.HoldDuration)
            end)
        end
        if not fired then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(1.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
        local panels = {waitFor(function()
            local ui, left, right = lockerPanels()
            if ui then
                return {ui, left, right}
            end
            return nil
        end, 4)}
        if panels[1] and type(panels[1]) == "table" then
            return panels[1]
        end
    end
    return nil
end

local function itemTargets(panel)
    local targets = {}
    local seen = {}
    for _, object in ipairs(panel:GetDescendants()) do
        local matches = object.Name == "SeedCandy"
        if (object:IsA("TextLabel") or object:IsA("TextButton")) and object.Text == "SeedCandy" then
            matches = true
        end
        if matches then
            local node = object
            local fallback = object:IsA("GuiObject") and object or nil
            while node and node ~= panel do
                if node:IsA("GuiButton") and visible(node) then
                    fallback = node
                    break
                end
                if node:IsA("GuiObject") and visible(node) then
                    fallback = node
                end
                node = node.Parent
            end
            if fallback and not seen[fallback] then
                seen[fallback] = true
                targets[#targets + 1] = fallback
            end
        end
    end
    table.sort(targets, function(left, right)
        local leftButton = left:IsA("GuiButton") and 0 or 1
        local rightButton = right:IsA("GuiButton") and 0 or 1
        if leftButton ~= rightButton then
            return leftButton < rightButton
        end
        return left.AbsoluteSize.X * left.AbsoluteSize.Y < right.AbsoluteSize.X * right.AbsoluteSize.Y
    end)
    return targets
end

local function snapshot(panel, label)
    log("SNAPSHOT " .. label)
    for _, object in ipairs(panel:GetDescendants()) do
        local text = ""
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            text = object.Text
        end
        if object.Name:lower():find("seed", 1, true) or text:lower():find("seedcandy", 1, true) then
            local position = object:IsA("GuiObject") and tostring(object.AbsolutePosition) or "-"
            local size = object:IsA("GuiObject") and tostring(object.AbsoluteSize) or "-"
            log(table.concat({object:GetFullName(), object.ClassName, "Text=" .. text, "Pos=" .. position, "Size=" .. size}, " | "))
        end
    end
end

local function pointerClick(gui, doubleClick)
    local point = gui.AbsolutePosition + gui.AbsoluteSize / 2
    local repeats = doubleClick and 2 or 1
    for _ = 1, repeats do
        VirtualInputManager:SendMouseMoveEvent(point.X, point.Y, game)
        task.wait(0.04)
        VirtualInputManager:SendMouseButtonEvent(point.X, point.Y, 0, true, game, 0)
        task.wait(0.07)
        VirtualInputManager:SendMouseButtonEvent(point.X, point.Y, 0, false, game, 0)
        task.wait(0.10)
    end
end

local function directActivate(gui)
    if not gui:IsA("GuiButton") or type(getconnections) ~= "function" then
        return false
    end
    local invoked = false
    for _, signalName in ipairs({"Activated", "MouseButton1Click", "TouchTap"}) do
        local ok, connections = pcall(getconnections, gui[signalName])
        if ok then
            for _, connection in ipairs(connections) do
                local fired = pcall(function()
                    if type(connection.Fire) == "function" then
                        connection:Fire()
                    elseif type(connection.Function) == "function" then
                        connection.Function()
                    end
                end)
                invoked = invoked or fired
            end
        end
    end
    return invoked
end

local function closeLocker(ui)
    local candidates = {}
    for _, object in ipairs(ui:GetDescendants()) do
        if object:IsA("GuiButton") and visible(object) then
            local name = object.Name:lower()
            local text = object:IsA("TextButton") and object.Text:lower() or ""
            if name == "exit" or name == "close" or name == "x" or text == "x" then
                candidates[#candidates + 1] = object
            end
        end
    end
    local corner = ui.AbsolutePosition + Vector2.new(ui.AbsoluteSize.X, 0)
    table.sort(candidates, function(left, right)
        local a = left.AbsolutePosition + left.AbsoluteSize / 2
        local b = right.AbsolutePosition + right.AbsoluteSize / 2
        return (a - corner).Magnitude < (b - corner).Magnitude
    end)
    if candidates[1] then
        pcall(pointerClick, candidates[1], false)
    end
end

local function run()
    notify("Opening locker")
    local panels = openLocker()
    if not panels then
        notify("FAILED: LockerUI was not found")
        return
    end

    local ui, inventory, safe = panels[1], panels[2], panels[3]
    snapshot(inventory, "INVENTORY BEFORE")
    snapshot(safe, "SAFE BEFORE")

    local movedAny = false
    for transfer = 1, 8 do
        local targets = itemTargets(inventory)
        if #targets == 0 then
            break
        end

        local target = targets[1]
        local beforeInventory, inventoryKnown = itemCount(inventory, "SeedCandy")
        local beforeSafe, safeKnown = itemCount(safe, "SeedCandy")
        log(string.format("Transfer %d target=%s class=%s inv=%s safe=%s", transfer, target:GetFullName(), target.ClassName, tostring(beforeInventory), tostring(beforeSafe)))

        local function transferred()
            if not target.Parent or not target:IsDescendantOf(inventory) then
                return true
            end
            if exact(inventory, "SeedCandy") == nil then
                return true
            end
            local inventoryNow, inventoryKnownNow = itemCount(inventory, "SeedCandy")
            local safeNow, safeKnownNow = itemCount(safe, "SeedCandy")
            if inventoryKnown and inventoryKnownNow and inventoryNow < beforeInventory then
                return true
            end
            if safeKnown and safeKnownNow and safeNow > beforeSafe then
                return true
            end
            return false
        end

        local methods = {
            {"pointer", function() pointerClick(target, false) end},
            {"direct", function() directActivate(target) end},
            {"double", function() pointerClick(target, true) end},
            {"virtual-user", function()
                local point = target.AbsolutePosition + target.AbsoluteSize / 2
                VirtualUser:ClickButton1(point, Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new())
            end},
        }

        local moved = false
        for _, method in ipairs(methods) do
            log("Trying " .. method[1])
            pcall(method[2])
            if waitFor(transferred, 1.2) then
                moved = true
                movedAny = true
                log("Confirmed by " .. method[1])
                break
            end
        end

        if not moved then
            log("No transfer was confirmed")
            break
        end
        task.wait(0.2)
    end

    snapshot(inventory, "INVENTORY AFTER")
    snapshot(safe, "SAFE AFTER")
    closeLocker(ui)
    if movedAny then
        notify("SUCCESS: SeedCandy moved to locker")
    else
        notify("FAILED: SeedCandy was not moved")
    end
end

save()
task.spawn(run)
