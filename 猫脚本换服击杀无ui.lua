local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

_G.airStrike = true
_G.autoPunch = true
_G.switchServers = true

local startTime = tick()
local isHopping = false

local function immediateServerHop(force)
    if not force and isHopping then return end
    if force then isHopping = false end
    isHopping = true

    local methods = {
        { name = "Teleport", func = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end },
        { name = "TeleportAsync", func = function() TeleportService:TeleportAsync(game.PlaceId, {LocalPlayer}) end },
        { name = "TeleportWithOptions", func = function()
            local options = Instance.new("TeleportOptions")
            options:SetShouldReserveServer(true)
            TeleportService:Teleport(game.PlaceId, LocalPlayer, options)
        end }
    }

    local methodIndex = 1
    while true do
        local method = methods[methodIndex]
        local success, err = pcall(method.func)
        if success then
            isHopping = false
            print("换服成功！")
            return
        else
            warn(string.format("换服失败 [%s]: %s", method.name, err))
            methodIndex = (methodIndex % #methods) + 1
        end
    end
end

local function onCharacterAdded(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        if _G.switchServers then
            print("玩家死亡，强制立即换服...")
            immediateServerHop(true)
        end
    end)
end

if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

local function ensurePunchEquipped()
    local character = LocalPlayer.Character
    local backpack = LocalPlayer.Backpack
    if character and backpack then
        local punchTool = backpack:FindFirstChild("Punch")
        if punchTool then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                local currentTool = character:FindFirstChildOfClass("Tool")
                if not currentTool or currentTool.Name ~= "Punch" then
                    humanoid:EquipTool(punchTool)
                end
            end
        end
    end
end

local function touchPlayer(targetPlayer)
    pcall(function()
        local targetChar = targetPlayer.Character
        if not targetChar then return end
        local head = targetChar:FindFirstChild("Head")
        if not head then return end

        local myChar = LocalPlayer.Character
        if not myChar then return end
        local leftHand = myChar:FindFirstChild("LeftHand")
        if not leftHand then return end

        if head and leftHand and head.Parent and leftHand.Parent then
            firetouchinterest(head, leftHand, 0)
            firetouchinterest(head, leftHand, 1)
        end
    end)
end

task.spawn(function()
    while true do
        if _G.airStrike then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    touchPlayer(player)
                end
            end
        end
        task.wait(0.001)
    end
end)

local function autoPunchAction()
    if _G.autoPunch then
        pcall(function()
            ensurePunchEquipped()
            if LocalPlayer:FindFirstChild("muscleEvent") then
                LocalPlayer.muscleEvent:FireServer("punch", "leftHand")
            end
        end)
    end
end
RunService.Heartbeat:Connect(autoPunchAction)

task.spawn(function()
    while true do
        if _G.switchServers then
            if tick() - startTime >= 180 and not isHopping then
                print("定时换服...")
                immediateServerHop()
                startTime = tick()
            end
            if #Players:GetPlayers() == 1 and not isHopping then
                print("服务器只剩一人，换服...")
                immediateServerHop()
            end
        end
        task.wait(1)
    end
end)

local function teleportToPosition()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(2.039604425430298, 85.11581420898438, 245.0113525390625)
    else
        local conn
        conn = LocalPlayer.CharacterAdded:Connect(function(newChar)
            local rootPart = newChar:WaitForChild("HumanoidRootPart", 5)
            if rootPart then
                rootPart.CFrame = CFrame.new(2.039604425430298, 85.11581420898438, 245.0113525390625)
            end
            conn:Disconnect()
        end)
    end
end
teleportToPosition()

pcall(function()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Sound") then
            obj:Stop()
            obj:Destroy()
        end
    end
    print("[音乐清除] 已强制删除所有音乐")
end)

local function createKillsUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "KillsDisplayGUI"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn = false
    gui.Parent = game.CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 180, 0, 60)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 165, 0)
    frame.ClipsDescendants = true
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 22)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "击杀数"
    title.TextColor3 = Color3.fromRGB(255, 200, 100)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = frame

    local killsLabel = Instance.new("TextLabel")
    killsLabel.Size = UDim2.new(1, 0, 0, 32)
    killsLabel.Position = UDim2.new(0, 0, 0, 22)
    killsLabel.BackgroundTransparency = 1
    killsLabel.Text = "0"
    killsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    killsLabel.TextSize = 28
    killsLabel.Font = Enum.Font.GothamBlack
    killsLabel.TextXAlignment = Enum.TextXAlignment.Center
    killsLabel.TextYAlignment = Enum.TextYAlignment.Center
    killsLabel.Parent = frame

    local function updateDisplay(value)
        killsLabel.Text = tostring(value)
    end

    local function setupListener()
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            local kills = leaderstats:FindFirstChild("Kills")
            if kills then
                updateDisplay(kills.Value)
                kills:GetPropertyChangedSignal("Value"):Connect(function()
                    updateDisplay(kills.Value)
                end)
            else
                local killsAddedConn
                killsAddedConn = leaderstats.ChildAdded:Connect(function(child)
                    if child.Name == "Kills" and (child:IsA("IntValue") or child:IsA("NumberValue")) then
                        updateDisplay(child.Value)
                        child:GetPropertyChangedSignal("Value"):Connect(function()
                            updateDisplay(child.Value)
                        end)
                        killsAddedConn:Disconnect()
                    end
                end)
            end
        else
            local lsAddedConn
            lsAddedConn = LocalPlayer.ChildAdded:Connect(function(child)
                if child.Name == "leaderstats" then
                    setupListener()
                    lsAddedConn:Disconnect()
                end
            end)
        end
    end

    setupListener()

    local dragging = false
    local dragStart, startPos

    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    title.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    frame.Active = true
    frame.Draggable = true

    frame.BackgroundTransparency = 0.6
    local tween = TweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency = 0.4})
    tween:Play()
end

pcall(createKillsUI)