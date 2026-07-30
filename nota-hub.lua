local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local successRayfield, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not successRayfield or not Rayfield then
    warn("Failed to load Rayfield UI!")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "Nota Hub",
    LoadingTitle = "Nota Hub Loading...",
    LoadingSubtitle = "by user",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false, 
})

local TabFarm = Window:CreateTab("Farm", 4483362458)
local TabUnits = Window:CreateTab("Units", 4483362458)
local TabPlayer = Window:CreateTab("Player", 4483362458)
local TabBoss = Window:CreateTab("Boss", 4483362458)

local isCollectEnabled = false
local isBagEnabled = false
local isFarmEnabled = false
local isUpgradeEnabled = false
local isRebirthEnabled = false
local isBossEnabled = false
local isBossFighting = false
local targetSpeed = nil
local isNoclipEnabled = false
local isFlyEnabled = false

-- Очистка VFX
PlayerGui.DescendantAdded:Connect(function(obj)
    local name = obj.Name:lower()
    if name:find("confetti") or name:find("cashout") or name:find("pop") or name:find("effect") then
        pcall(function() obj:Destroy() end)
    end
end)

-- Noclip
local noclipConnection = RunService.Stepped:Connect(function()
    if isNoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

-- Walkspeed
local speedConnection = RunService.Stepped:Connect(function()
    if targetSpeed then
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.WalkSpeed ~= targetSpeed then
            humanoid.WalkSpeed = targetSpeed
        end
    end
end)

-- Fly
local flySpeed = 50
local flyConnection = RunService.RenderStepped:Connect(function(dt)
    if isFlyEnabled then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local cam = workspace.CurrentCamera
        
        if hrp and cam then
            if humanoid then
                humanoid.PlatformStand = true
            end
            
            local moveDir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDir = moveDir + cam.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDir = moveDir - cam.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDir = moveDir - cam.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDir = moveDir + cam.CFrame.RightVector
            end
            
            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit
            end
            
            hrp.AssemblyLinearVelocity = moveDir * flySpeed
            hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
        end
    else
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.PlatformStand then
            humanoid.PlatformStand = false
        end
    end
end)

local function clickActiveGoBack()
    local hud = PlayerGui:FindFirstChild("HUD")
    local upFrame = hud and hud:FindFirstChild("UpFrame")

    if upFrame then
        for _, child in ipairs(upFrame:GetChildren()) do
            if child.Name == "GoBackButton" and child:IsA("GuiObject") then
                local isActiveAttr = child:GetAttribute("Active")
                local isActiveProp = child.Active

                if isActiveAttr == true or isActiveProp == true then
                    pcall(function()
                        if firesignal then
                            firesignal(child.MouseButton1Click)
                            firesignal(child.Activated)
                        elseif getconnections then
                            for _, con in ipairs(getconnections(child.MouseButton1Click)) do con:Fire() end
                            for _, con in ipairs(getconnections(child.Activated)) do con:Fire() end
                        end
                    end)
                    break
                end
            end
        end
    end
end

-- Auto Farm с проверкой позиции и кулдауном 4.8 секунд
local lastGoBackClick = 0
task.spawn(function()
    local farmTargetPos = Vector3.new(137, 87, -1)
    while true do
        if isFarmEnabled and not isBossFighting then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if (hrp.Position - farmTargetPos).Magnitude > 10 then
                        task.wait(5)
                        if isFarmEnabled and not isBossFighting then
                            hrp.CFrame = CFrame.new(farmTargetPos)
                        end
                    end
                end
            end)

            if os.clock() - lastGoBackClick >= 4 then
                clickActiveGoBack()
                lastGoBackClick = os.clock()
            end
        end
        task.wait(0.2)
    end
end)

local function getMyPlot()
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then return nil end
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        local ownerId = plot:GetAttribute("OwnerUserId")
        if ownerId and tostring(ownerId) == tostring(LocalPlayer.UserId) then
            return plot
        end
    end
    return nil
end

local function parseCurrency(val)
    if typeof(val) == "number" then
        return val
    elseif typeof(val) == "string" then
        local cleanVal = val:gsub("[%$,]", "")
        local numPart = tonumber(cleanVal)
        if numPart then return numPart end

        local number, suffix = cleanVal:match("([%d%.]+)%s*([a-zA-Z]+)")
        number = tonumber(number)
        if not number then return 0 end

        local multipliers = {
            K = 1e3, M = 1e6, B = 1e9, T = 1e12, 
            Qa = 1e15, Qi = 1e18, Sx = 1e21, Sp = 1e24, 
            Oc = 1e27, No = 1e30, Dc = 1e33, UnD = 1e36,
            DDc = 1e39, TDc = 1e42, QaDc = 1e45, QiDc = 1e48,
            SxDc = 1e51, SpDc = 1e54, OcDc = 1e57, NoDc = 1e60, Vg = 1e63
        }
        
        for k, mult in pairs(multipliers) do
            if suffix:lower() == k:lower() then
                return number * mult
            end
        end
        return number
    end
    return 0
end

local function getPlayerMoney()
    local success, val = pcall(function()
        return LocalPlayer.leaderstats.Money.Value
    end)
    if not success or val == nil then return math.huge end
    return parseCurrency(val)
end

-- Auto Collect
task.spawn(function()
    while true do
        if isCollectEnabled then
            local myPlot = getMyPlot()
            if myPlot then
                local runtimeSlots = myPlot:FindFirstChild("RuntimeUnitSlots")
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")

                if runtimeSlots and hrp then
                    for _, slot in ipairs(runtimeSlots:GetChildren()) do
                        if not isCollectEnabled then break end
                        local button = slot:FindFirstChild("SlotTemplate")
                            and slot.SlotTemplate:FindFirstChild("CashOut")
                            and slot.SlotTemplate.CashOut:FindFirstChild("Button")

                        if button then
                            pcall(function()
                                firetouchinterest(hrp, button, 0)
                                task.wait(0.05)
                                firetouchinterest(hrp, button, 1)
                            end)
                        end
                    end
                end
            end
        end
        task.wait(2)
    end
end)

-- Auto Bag
task.spawn(function()
    local success, attackEvent = pcall(function()
        return ReplicatedStorage:WaitForChild("Network"):WaitForChild("Combat"):WaitForChild("RequestPrimaryAttack")
    end)
    while true do
        if isBagEnabled and success and attackEvent then
            pcall(function()
                attackEvent:FireServer()
            end)
        end
        task.wait(0.1)
    end
end)

-- Auto Upgrade
task.spawn(function()
    while true do
        if isUpgradeEnabled then
            local myPlot = getMyPlot()
            if myPlot then
                local runtimeSlots = myPlot:FindFirstChild("RuntimeUnitSlots")
                if runtimeSlots then
                    local cheapestBtn = nil
                    local lowestCost = math.huge
                    local currentMoney = getPlayerMoney()

                    for _, slot in ipairs(runtimeSlots:GetChildren()) do
                        local hasUnit = slot:GetAttribute("PlotHasUnit")
                        if hasUnit == true then
                            for _, gui in ipairs(PlayerGui:GetChildren()) do
                                if (gui:IsA("BillboardGui") or gui:IsA("SurfaceGui")) and gui.Adornee then
                                    if gui.Adornee == slot or gui.Adornee:IsDescendantOf(slot) then
                                        local btn = gui:FindFirstChild("UpgradeButton", true) 
                                            or gui:FindFirstChild("Button", true) 
                                            or gui:FindFirstChildOfClass("TextButton") 
                                            or gui:FindFirstChildOfClass("ImageButton")
                                        
                                        if btn and btn:IsA("GuiButton") then
                                            local costText = ""
                                            for _, textChild in ipairs(btn:GetDescendants()) do
                                                if textChild:IsA("TextLabel") and textChild.Text ~= "" then
                                                    costText = textChild.Text
                                                    break
                                                end
                                            end
                                            if costText == "" and btn.Text ~= "" then
                                                costText = btn.Text
                                            end

                                            local cost = parseCurrency(costText)
                                            if cost > 0 and cost <= currentMoney and cost < lowestCost then
                                                lowestCost = cost
                                                cheapestBtn = btn
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    if cheapestBtn then
                        pcall(function()
                            if firesignal then
                                firesignal(cheapestBtn.MouseButton1Click)
                                firesignal(cheapestBtn.Activated)
                            elseif getconnections then
                                for _, con in ipairs(getconnections(cheapestBtn.MouseButton1Click)) do con:Fire() end
                                for _, con in ipairs(getconnections(cheapestBtn.Activated)) do con:Fire() end
                            end
                        end)
                    end
                end
            end
        end
        task.wait(0.4)
    end
end)

-- Auto Rebirth
task.spawn(function()
    while true do
        if isRebirthEnabled then
            pcall(function()
                local rbPanel = PlayerGui:FindFirstChild("RebirthPanel")
                if rbPanel then
                    local rbBtn = rbPanel:FindFirstChild("RebirthFrame", true)
                        and rbPanel.RebirthFrame:FindFirstChild("RebirthFrame", true)
                        and rbPanel.RebirthFrame.RebirthFrame:FindFirstChild("ButtonsFrame", true)
                        and rbPanel.RebirthFrame.RebirthFrame.ButtonsFrame:FindFirstChild("RebirthButton")

                    if rbBtn then
                        if firesignal then
                            firesignal(rbBtn.MouseButton1Click)
                            firesignal(rbBtn.Activated)
                        elseif getconnections then
                            for _, con in ipairs(getconnections(rbBtn.MouseButton1Click)) do con:Fire() end
                            for _, con in ipairs(getconnections(rbBtn.Activated)) do con:Fire() end
                        end
                    end
                end
            end)
        end
        task.wait(1.5)
    end
end)

-- Auto Boss
task.spawn(function()
    while true do
        if isBossEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    local boss = nil
                    for _, obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
                            local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                            local humanoid = obj:FindFirstChildOfClass("Humanoid")
                            if root and humanoid and humanoid.Health > 0 then
                                local dist = (root.Position - Vector3.new(-240, 90, -3)).Magnitude
                                if dist < 150 and humanoid.MaxHealth > 10000 then
                                    boss = obj
                                    break
                                end
                            end
                        end
                    end

                    if boss then
                        local bossRoot = boss:FindFirstChild("HumanoidRootPart") or boss.PrimaryPart
                        if bossRoot then
                            isBossFighting = true
                            local oldPos = hrp.CFrame
                            hrp.CFrame = bossRoot.CFrame + Vector3.new(0, 3, 0)

                            while isBossEnabled and boss and boss.Parent and boss:FindFirstChildOfClass("Humanoid") and boss:FindFirstChildOfClass("Humanoid").Health > 0 do
                                task.wait(1)
                            end

                            if isBossEnabled and hrp then
                                hrp.CFrame = oldPos
                            end
                            isBossFighting = false
                        end
                    end
                end
            end)
        end
        task.wait(5)
    end
end)

-- Интерфейс (UI)
TabFarm:CreateToggle({
    Name = "Auto Collect",
    CurrentValue = false,
    Callback = function(Value)
        isCollectEnabled = Value
    end,
})

TabFarm:CreateToggle({
    Name = "Auto Bag",
    CurrentValue = false,
    Callback = function(Value)
        isBagEnabled = Value
    end,
})

TabUnits:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Callback = function(Value)
        isFarmEnabled = Value
        if Value and not isBossFighting then
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(137, 87, -1)
                end
            end)
        end
    end,
})

TabUnits:CreateToggle({
    Name = "Auto Upgrade",
    CurrentValue = false,
    Callback = function(Value)
        isUpgradeEnabled = Value
    end,
})

TabPlayer:CreateToggle({
    Name = "Auto Rebirth",
    CurrentValue = false,
    Callback = function(Value)
        isRebirthEnabled = Value
    end,
})

TabPlayer:CreateInput({
    Name = "Walkspeed",
    PlaceholderText = "16",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num and num > 0 then
            targetSpeed = num
        else
            targetSpeed = nil
        end
    end,
})

TabPlayer:CreateToggle({
    Name = "Noclip (No Ragdoll)",
    CurrentValue = false,
    Callback = function(Value)
        isNoclipEnabled = Value
    end,
})

TabPlayer:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(Value)
        isFlyEnabled = Value
    end,
})

TabBoss:CreateToggle({
    Name = "Auto Boss",
    CurrentValue = false,
    Callback = function(Value)
        isBossEnabled = Value
        if not Value then isBossFighting = false end
    end,
})
