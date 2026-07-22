local player = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local sg = game:GetService("StarterGui")
local ws = workspace
local camera = ws.CurrentCamera
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

for _, v in pairs(player.PlayerGui:GetChildren()) do
    if v.Name:find("ShadowCore_MM2") then v:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "ShadowCore_MM2"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 340, 0, 380)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 0
mainFrame.Draggable = true
mainFrame.Parent = gui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "ShadowCore | MM2"
title.TextColor3 = Color3.fromRGB(255, 200, 100)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local function makeBtn(name, text, y, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 140, 0, 35)
    btn.Position = UDim2.new(0.5, -70, 0, y)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = mainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local espBtn = makeBtn("ESP", "ESP: OFF", 40, nil)
local aimBtn = makeBtn("AimBot", "AIMBOT: OFF", 85, nil)
local farmBtn = makeBtn("FarmCoins", "FARM: OFF", 130, nil)
local noclipBtn = makeBtn("Noclip", "NOCLIP: OFF", 175, nil)
local autoKillBtn = makeBtn("AutoKill", "AUTOKILL: OFF", 220, nil)
local infoBtn = makeBtn("Info", "INFO", 265, nil)

local espEnabled = false
local aimbotEnabled = false
local farmEnabled = false
local noclipEnabled = false
local autoKillEnabled = false
local espObjects = {}
local noclipConn = nil

-- GOD MODE
local godModeTasks = {}
local function startGodMode(character)
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid then return end
    local healthTask = rs.RenderStepped:Connect(function()
        if humanoid and humanoid.Parent then
            humanoid.Health = math.huge
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            humanoid.BreakJointsOnDeath = false
        end
    end)
    table.insert(godModeTasks, healthTask)
    local fallTask = rs.RenderStepped:Connect(function()
        if rootPart and rootPart.Parent then
            if rootPart.Position.Y < -50 then rootPart.CFrame = CFrame.new(0, 50, 0) end
        end
    end)
    table.insert(godModeTasks, fallTask)
    local diedConn = humanoid.Died:Connect(function()
        if humanoid and humanoid.Parent then
            humanoid.Health = math.huge
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
    table.insert(godModeTasks, diedConn)
end

local function stopGodMode()
    for _, task in ipairs(godModeTasks) do pcall(function() task:Disconnect() end) end
    godModeTasks = {}
end

local function applyGodModeToCharacter(character)
    stopGodMode()
    startGodMode(character)
end

player.CharacterAdded:Connect(applyGodModeToCharacter)
if player.Character then applyGodModeToCharacter(player.Character) end

-- ROLES
local function getPlayerRole(plr)
    local character = plr.Character
    if not character then return "Innocent" end
    for _, tool in pairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name:find("knife") or name:find("dagger") then return "Murderer"
            elseif name:find("gun") then return "Sheriff" end
        end
    end
    local backpack = plr.Backpack
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name:find("knife") or name:find("dagger") then return "Murderer"
                elseif name:find("gun") then return "Sheriff" end
            end
        end
    end
    return "Innocent"
end

local function getMurderer()
    for _, other in pairs(players:GetPlayers()) do
        if other ~= player and getPlayerRole(other) == "Murderer" then return other end
    end
    return nil
end

-- ESP
local function updateESP()
    if not espEnabled then
        for _, obj in pairs(espObjects) do obj:Destroy() end
        espObjects = {}
        return
    end
    for _, other in pairs(players:GetPlayers()) do
        if other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
            local role = getPlayerRole(other)
            local color = role == "Murderer" and Color3.fromRGB(255,0,0) or (role == "Sheriff" and Color3.fromRGB(0,100,255) or Color3.fromRGB(0,255,0))
            local pos = other.Character.HumanoidRootPart.Position
            local screenPos, onScreen = camera:WorldToScreenPoint(pos)
            if onScreen then
                local label = espObjects[other] and espObjects[other].label
                if not label then
                    label = Instance.new("TextLabel")
                    label.BackgroundTransparency = 1
                    label.TextStrokeTransparency = 0.5
                    label.TextSize = 14
                    label.Font = Enum.Font.GothamBold
                    label.Parent = gui
                    espObjects[other] = {label = label}
                end
                label.Text = string.format("%s\n[%s]", other.Name, role)
                label.Position = UDim2.new(0, screenPos.X - 50, 0, screenPos.Y - 20)
                label.Size = UDim2.new(0, 100, 0, 30)
                label.TextColor3 = color
                label.Visible = true
            else
                if espObjects[other] and espObjects[other].label then espObjects[other].label.Visible = false end
            end
        end
    end
    for plr, obj in pairs(espObjects) do
        if not plr.Parent then obj.label:Destroy(); espObjects[plr] = nil end
    end
end

-- AIMBOT
local function aimbot()
    if not aimbotEnabled then return end
    if getPlayerRole(player) ~= "Sheriff" then return end
    local murderer = getMurderer()
    if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
        camera.CFrame = CFrame.new(camera.CFrame.Position, murderer.Character.HumanoidRootPart.Position)
    end
end

uis.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.G then
        aimbotEnabled = not aimbotEnabled
        aimBtn.Text = aimbotEnabled and "AIMBOT: ON" or "AIMBOT: OFF"
        aimBtn.TextColor3 = aimbotEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
    end
end)

-- NOCLIP
local function enableNoclip()
    if noclipEnabled then
        if noclipConn then noclipConn:Disconnect() end
        noclipConn = rs.RenderStepped:Connect(function()
            local char = player.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local char = player.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

-- FARM COINS (МЕДЛЕННЫЙ)
local function findCoins()
    local coins = {}
    for _, obj in pairs(ws:GetDescendants()) do
        if obj:IsA("BasePart") then
            local nameLower = obj.Name:lower()
            if nameLower:find("coin") or nameLower:find("money") or nameLower:find("cash") then
                table.insert(coins, obj)
            end
        end
    end
    return coins
end

local farming = false
local function collectCoins()
    if not farmEnabled or farming then return end
    farming = true
    local character = player.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local coins = findCoins()
            if #coins > 0 then
                table.sort(coins, function(a,b) return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude end)
                for _, coin in ipairs(coins) do
                    if not farmEnabled then break end
                    if coin and coin.Parent and character and character.Parent then
                        local targetPos = coin.Position + Vector3.new(0, 3, 0)
                        if targetPos.Y < 0 then targetPos = Vector3.new(targetPos.X, 3, targetPos.Z) end
                        hrp.CFrame = CFrame.new(targetPos)
                        rs.RenderStepped:Wait()
                    else break end
                    wait(0.5)
                end
            end
        end
    end
    farming = false
end

coroutine.wrap(function()
    while true do
        if farmEnabled then collectCoins() end
        wait(1)
    end
end)()

-- AUTOKILL
local function autoKill()
    if not autoKillEnabled then return end
    local myRole = getPlayerRole(player)
    if myRole == "Murderer" then
        for _, other in pairs(players:GetPlayers()) do
            if other ~= player and other.Character and other.Character:FindFirstChild("Humanoid") then
                local knife = player.Character and player.Character:FindFirstChildOfClass("Tool")
                if knife and knife.Name:find("Knife") then
                    local hrp = player.Character.HumanoidRootPart
                    local targetHrp = other.Character.HumanoidRootPart
                    if hrp and targetHrp then
                        hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 2)
                        wait(0.1)
                        knife:Activate()
                    end
                end
            end
        end
    elseif myRole == "Sheriff" then
        local murderer = getMurderer()
        if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
            local gun = player.Character and player.Character:FindFirstChildOfClass("Tool")
            if gun and gun.Name:find("Gun") then
                local hrp = player.Character.HumanoidRootPart
                local targetHrp = murderer.Character.HumanoidRootPart
                if hrp and targetHrp then
                    hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3)
                    wait(0.05)
                    camera.CFrame = CFrame.new(camera.CFrame.Position, targetHrp.Position)
                    gun:Activate()
                end
            end
        end
    end
end

-- LOOPS
rs.RenderStepped:Connect(function()
    updateESP()
    aimbot()
    if autoKillEnabled then autoKill() end
end)

-- BUTTONS
espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
    espBtn.TextColor3 = espEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
end)

aimBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    aimBtn.Text = aimbotEnabled and "AIMBOT: ON" or "AIMBOT: OFF"
    aimBtn.TextColor3 = aimbotEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
end)

farmBtn.MouseButton1Click:Connect(function()
    farmEnabled = not farmEnabled
    farmBtn.Text = farmEnabled and "FARM: ON" or "FARM: OFF"
    farmBtn.TextColor3 = farmEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
end)

noclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    noclipBtn.Text = noclipEnabled and "NOCLIP: ON" or "NOCLIP: OFF"
    noclipBtn.TextColor3 = noclipEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
    enableNoclip()
end)

autoKillBtn.MouseButton1Click:Connect(function()
    autoKillEnabled = not autoKillEnabled
    autoKillBtn.Text = autoKillEnabled and "AUTOKILL: ON" or "AUTOKILL: OFF"
    autoKillBtn.TextColor3 = autoKillEnabled and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
end)

-- INFO
local infoFrame = nil
infoBtn.MouseButton1Click:Connect(function()
    if infoFrame and infoFrame.Parent then infoFrame:Destroy(); infoFrame = nil; return end
    infoFrame = Instance.new("Frame")
    infoFrame.Size = UDim2.new(0, 380, 0, 340)
    infoFrame.Position = UDim2.new(0.5, -190, 0.5, -170)
    infoFrame.BackgroundColor3 = Color3.fromRGB(30,30,45)
    infoFrame.BackgroundTransparency = 0.1
    infoFrame.BorderSizePixel = 0
    infoFrame.Parent = gui
    Instance.new("UICorner", infoFrame).CornerRadius = UDim.new(0, 12)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.Text = "X"
    closeBtn.BackgroundColor3 = Color3.fromRGB(80,80,100)
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Parent = infoFrame
    closeBtn.MouseButton1Click:Connect(function() infoFrame:Destroy(); infoFrame = nil end)
    
    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, -20, 1, -40)
    infoText.Position = UDim2.new(0, 10, 0, 40)
    infoText.BackgroundTransparency = 1
    infoText.TextColor3 = Color3.fromRGB(220,220,255)
    infoText.TextSize = 13
    infoText.Font = Enum.Font.Gotham
    infoText.TextWrapped = true
    infoText.Text = [[=== ShadowCore | MM2 ===
ESP - player names/roles
AimBot - aims at murderer (G)
Farm Coins - collects coins
Noclip - walk through walls
AutoKill - auto kills
God Mode - always on]]
    infoText.Parent = infoFrame
end)

print("ShadowCore loaded!")
