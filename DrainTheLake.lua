-- Jawir Hub: Drain the Lake Automation Script
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local remotes = require(ReplicatedStorage.Verdant.Remotes)
local Events = require(ReplicatedStorage.Verdant.Events)
local SkillTreeLayouts = require(ReplicatedStorage.Shared.Registry.SkillTreeLayouts)

-- KEY SYSTEM CONFIGURATION
local USE_KEY_SYSTEM = false
local KEY_URL = "https://raw.githubusercontent.com/Nattalz/rblx/refs/heads/main/keys/key1.txt" -- Replace with your raw key URL
local DISCORD_INVITE = "https://discord.gg/gfqDhjMjtM"
local STATIC_BACKUP_KEY = "JawirOnTop"

-- Mouse unlock utility to override camera locking
local mouseUnlockConnection
local function setMouseUnlock(active)
    if active then
        if not mouseUnlockConnection then
            mouseUnlockConnection = RunService.RenderStepped:Connect(function()
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                UserInputService.MouseIconEnabled = true
            end)
        end
    else
        if mouseUnlockConnection then
            mouseUnlockConnection:Disconnect()
            mouseUnlockConnection = nil
        end
        -- Restore normal camera locking behavior immediately
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
end
setMouseUnlock(true)

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "JawirHubDrainTheLake"
ScreenGui.ResetOnSpawn = false

-- Clean up any existing instances of Jawir Hub
local existing = (gethui and gethui() or localPlayer.PlayerGui):FindFirstChild("JawirHubDrainTheLake")
if existing then
    existing:Destroy()
end
ScreenGui.Parent = gethui and gethui() or localPlayer.PlayerGui

-- MAIN WINDOW FRAME (Automation Features)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 340, 0, 480)
mainFrame.Position = UDim2.new(0.5, -170, 0.4, -240)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Visible = not USE_KEY_SYSTEM
mainFrame.Parent = ScreenGui

-- Corner styling for Main Frame
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = mainFrame

-- Neon cyan border styling
local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(0, 170, 255)
uiStroke.Thickness = 2
uiStroke.Transparency = 0.2
uiStroke.Parent = mainFrame

-- Dragging logic for Main Frame
local dragToggle, dragInput, dragStart, startPos
local function updateInput(input)
    local delta = input.Position - dragStart
    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragToggle = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragToggle = false
            end
        end)
    end
end)
mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragToggle then
        updateInput(input)
    end
end)

-- Main Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 10)
title.BackgroundTransparency = 1
title.Text = "JAWIR HUB"
title.TextColor3 = Color3.fromRGB(0, 170, 255)
title.TextSize = 24
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 20)
subtitle.Position = UDim2.new(0, 0, 0, 45)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Drain the Lake"
subtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
subtitle.TextSize = 13
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = mainFrame

-- Stats Layout
local statsFrame = Instance.new("Frame")
statsFrame.Name = "StatsFrame"
statsFrame.Size = UDim2.new(1, -40, 0, 100)
statsFrame.Position = UDim2.new(0, 20, 0, 80)
statsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
statsFrame.BackgroundTransparency = 0.5
statsFrame.BorderSizePixel = 0
statsFrame.Parent = mainFrame

local statsCorner = Instance.new("UICorner")
statsCorner.CornerRadius = UDim.new(0, 8)
statsCorner.Parent = statsFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 25)
statusLabel.Position = UDim2.new(0, 10, 0, 5)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Font = Enum.Font.GothamSemibold
statusLabel.Parent = statsFrame

local cpLabel = Instance.new("TextLabel")
cpLabel.Size = UDim2.new(1, -20, 0, 20)
cpLabel.Position = UDim2.new(0, 10, 0, 30)
cpLabel.BackgroundTransparency = 1
cpLabel.Text = "Active Checkpoint: 1"
cpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
cpLabel.TextSize = 13
cpLabel.TextXAlignment = Enum.TextXAlignment.Left
cpLabel.Font = Enum.Font.Gotham
cpLabel.Parent = statsFrame

local fillLabel = Instance.new("TextLabel")
fillLabel.Size = UDim2.new(1, -20, 0, 20)
fillLabel.Position = UDim2.new(0, 10, 0, 50)
fillLabel.BackgroundTransparency = 1
fillLabel.Text = "Bucket Fill: 0%"
fillLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
fillLabel.TextSize = 13
fillLabel.TextXAlignment = Enum.TextXAlignment.Left
fillLabel.Font = Enum.Font.Gotham
fillLabel.Parent = statsFrame

local tokensLabel = Instance.new("TextLabel")
tokensLabel.Size = UDim2.new(1, -20, 0, 20)
tokensLabel.Position = UDim2.new(0, 10, 0, 70)
tokensLabel.BackgroundTransparency = 1
tokensLabel.Text = "Tokens: 0"
tokensLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
tokensLabel.TextSize = 13
tokensLabel.TextXAlignment = Enum.TextXAlignment.Left
tokensLabel.Font = Enum.Font.Gotham
tokensLabel.Parent = statsFrame

-- Button Helper
local function createButton(text, yPos, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -40, 0, 40)
    button.Position = UDim2.new(0, 20, 0, yPos)
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 13
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.BorderSizePixel = 0
    button.Parent = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(50, 50, 70)
    stroke.Thickness = 1
    stroke.Parent = button

    button.MouseButton1Click:Connect(function()
        callback(button)
    end)
    return button
end

-- Helper to trigger ProximityPrompts
local function firePrompt(prompt)
    if fireproximityprompt then
        fireproximityprompt(prompt)
    else
        task.spawn(function()
            prompt:InputBegan(Enum.UserInputType.Keyboard)
            task.wait(prompt.HoldDuration + 0.1)
            prompt:InputEnded(Enum.UserInputType.Keyboard)
        end)
    end
end

-- Background thread to constantly clear leftover floating Token models in the workspace
task.spawn(function()
    while ScreenGui.Parent do
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name == "Token" and child:IsA("Model") then
                child:Destroy()
            end
        end
        task.wait(0.3)
    end
end)

-- State variables
local autoWaterActive = false
local autoPourActive = false
local autoCollectActive = false
local autoChestActive = false
local autoUpgradesActive = false

-- KEY GATE VERIFICATION SYSTEM REFERENCE
local keyFrame

-- Function to update button state visuals
local function updateButtonVisual(btn, active)
    if active then
        btn.BackgroundColor3 = Color3.fromRGB(0, 130, 200)
        btn.UIStroke.Color = Color3.fromRGB(0, 170, 255)
    else
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        btn.UIStroke.Color = Color3.fromRGB(50, 50, 70)
    end
end

-- Helper to dynamically get the player's scoop cooldown
local function getScoopDelay()
    local BucketController = require(ReplicatedStorage.Verdant).GetController("BucketController")
    if BucketController and BucketController._scoopInterval then
        return BucketController:_scoopInterval() + 0.015
    end
    return 0.52
end

-- Checkpoint resolver using active position proximity
local function getActiveCheckpointPrompt()
    local cpPos = workspace:GetAttribute("CheckpointPosition")
    if not cpPos then return nil end

    local closestPrompt = nil
    local minDist = math.huge

    -- Search in workspace.Scripted.CheckpointParts
    for _, cpFolder in ipairs(workspace.Scripted.CheckpointParts:GetChildren()) do
        local drain = cpFolder:FindFirstChild("Drain")
        if drain then
            local prompt = drain:FindFirstChild("ProximityPrompt", true)
            if prompt then
                local dist = (prompt.Parent.Position - cpPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    closestPrompt = prompt
                end
            end
        end
    end

    -- Search in workspace.Scripted direct children named "Drain"
    for _, child in ipairs(workspace.Scripted:GetChildren()) do
        if child.Name == "Drain" then
            local prompt = child:FindFirstChild("ProximityPrompt", true)
            if prompt then
                local dist = (prompt.Parent.Position - cpPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    closestPrompt = prompt
                end
            end
        end
    end

    return closestPrompt
end

-- Wait for the pour to finish and tokens to be processed
local function waitForDrain(prompt, checkFlag)
    local takePrompt = prompt.Parent.Parent:FindFirstChild("TakeTokens")
    takePrompt = takePrompt and takePrompt:FindFirstChild("ProximityPrompt")
    
    -- 1. Wait for draining to finish (when takePrompt becomes enabled)
    local start = os.clock()
    while os.clock() - start < 4.5 and checkFlag() do
        if takePrompt and takePrompt.Enabled then
            break
        end
        task.wait(0.1)
    end

    -- 2. If takePrompt is enabled, it means we need to collect tokens (or wait for Direct Deposit to do it)
    if takePrompt and takePrompt.Enabled and checkFlag() then
        local profile = Events.Profile.Data.SkillTree
        local hasDirectDeposit = profile and profile.root and profile.root["-4,2"]
        if not hasDirectDeposit then
            statusLabel.Text = "Status: Collecting Tokens"
            -- Teleport next to the drain to satisfy server-side proximity checks
            local char = localPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = prompt.Parent.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.1)
            end
            
            remotes:Fire("Tokens.Take", prompt)
        end
        -- Wait for takePrompt to disable (meaning tokens collected/deposited)
        start = os.clock()
        while takePrompt.Enabled and os.clock() - start < 2 and checkFlag() do
            task.wait(0.1)
        end
    else
        task.wait(0.5)
    end
    task.wait(0.3) -- small safety buffer before next pour
end

-- Stats Loop
task.spawn(function()
    while ScreenGui.Parent do
        local cpNumber = workspace:GetAttribute("CheckpointNumber") or 1
        local fill = localPlayer:GetAttribute("BucketFill") or 0
        local tokens = localPlayer.leaderstats and localPlayer.leaderstats:FindFirstChild("Tokens")
        
        cpLabel.Text = "Active Checkpoint: " .. tostring(cpNumber)
        fillLabel.Text = string.format("Bucket Fill: %d%%", math.round(fill * 100))
        tokensLabel.Text = "Tokens: " .. (tokens and tostring(tokens.Value) or "0")
        task.wait(0.2)
    end
end)

-- Auto Water Loop
task.spawn(function()
    while ScreenGui.Parent do
        if autoWaterActive then
            local fill = localPlayer:GetAttribute("BucketFill") or 0
            if fill < 1 then
                statusLabel.Text = "Status: Auto Scooping"
                remotes:Fire("Bucket.Used")
                task.wait(getScoopDelay())
            else
                task.wait(0.1)
            end
        else
            task.wait(0.5)
        end
    end
end)

-- Auto Pour Loop
task.spawn(function()
    while ScreenGui.Parent do
        if autoPourActive then
            local fill = localPlayer:GetAttribute("BucketFill") or 0
            if fill >= 1 then
                statusLabel.Text = "Status: Auto Pouring"
                local prompt = getActiveCheckpointPrompt()
                if prompt then
                    local char = localPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.CFrame = prompt.Parent.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.1)
                    end
                    
                    if autoPourActive then
                        remotes:Fire("Bucket.Poured", prompt)
                        
                        -- Wait for bucket to empty (with timeout)
                        local start = os.clock()
                        while (localPlayer:GetAttribute("BucketFill") or 0) > 0 and os.clock() - start < 1.5 and autoPourActive do
                            task.wait(0.1)
                        end
                    end
                else
                    statusLabel.Text = "Status: No Active Drain"
                    task.wait(0.5)
                end
            else
                task.wait(0.1)
            end
        else
            task.wait(0.5)
        end
    end
end)

-- Auto Collect Loop
task.spawn(function()
    while ScreenGui.Parent do
        if autoCollectActive then
            local prompt = getActiveCheckpointPrompt()
            if prompt then
                local takePrompt = prompt.Parent.Parent:FindFirstChild("TakeTokens")
                takePrompt = takePrompt and takePrompt:FindFirstChild("ProximityPrompt")
                
                if takePrompt and takePrompt.Enabled then
                    statusLabel.Text = "Status: Auto Collecting"
                    
                    -- Teleport next to the drain to satisfy server-side proximity checks
                    local char = localPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.CFrame = prompt.Parent.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.1)
                    end
                    
                    remotes:Fire("Tokens.Take", prompt)
                    
                    -- Wait for it to disable or timeout
                    local start = os.clock()
                    while takePrompt.Enabled and os.clock() - start < 1.5 and autoCollectActive do
                        task.wait(0.1)
                    end
                end
            end
            task.wait(0.2)
        else
            task.wait(0.5)
        end
    end
end)

-- Auto Chest Loop
task.spawn(function()
    while ScreenGui.Parent do
        if autoChestActive then
            local openedAny = false
            for _, chest in ipairs(workspace.Scripted.Chests:GetChildren()) do
                local prompt = chest:FindFirstChild("ProximityPrompt", true)
                if prompt and prompt.Enabled then
                    statusLabel.Text = "Status: Opening Chest"
                    local char = localPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.CFrame = chest:GetPivot() + Vector3.new(0, 3, 0)
                        task.wait(0.2)
                    end
                    -- Trigger the actual ProximityPrompt interaction to open the chest physically
                    firePrompt(prompt)
                    task.wait(0.8) -- Quicker wait time (~1s total per chest)
                    openedAny = true
                    break
                end
            end
            if not openedAny then
                statusLabel.Text = "Status: All Chests Opened!"
                autoChestActive = false
                local btn = mainFrame:FindFirstChild("Toggle Auto Chest")
                if btn then
                    updateButtonVisual(btn, false)
                end
            end
            task.wait(0.5)
        else
            task.wait(0.5)
        end
    end
end)

-- Upgrade Priority Queue (Sorted by purchase priority)
local upgradeQueue = {
  -- Root Starters & Tree Unlocks
  {category = "root", q = 0, r = 0, name = "Bigger Bucket I"},
  {category = "root", q = 1, r = -1, name = "Richer Gems I"},

  -- Buckets Capacity Progression
  {category = "buckets", q = 1, r = 0, name = "Bigger Bucket II"},
  {category = "buckets", q = 2, r = 0, name = "Bigger Bucket III"},
  {category = "buckets", q = 2, r = -1, name = "Bigger Bucket IV"},
  {category = "buckets", q = 1, r = -1, name = "Roomy Bucket I"},
  {category = "buckets", q = 2, r = -2, name = "Roomy Bucket II"},
  {category = "buckets", q = 3, r = -1, name = "Roomy Bucket III"},
  {category = "buckets", q = 3, r = -2, name = "Roomy Bucket IV"},
  {category = "buckets", q = 3, r = 0, name = "Cavernous Bucket I"},
  {category = "buckets", q = 4, r = -1, name = "Cavernous Bucket II"},
  {category = "buckets", q = 3, r = -3, name = "Cavernous Bucket III"},
  {category = "buckets", q = 4, r = -2, name = "Prospector's Bucket"},

  -- Richer Gems & Loose Change
  {category = "root", q = 1, r = -2, name = "Richer Gems II"},
  {category = "root", q = 0, r = -2, name = "Richer Gems III"},
  {category = "root", q = 2, r = -3, name = "Loose Change I"},
  {category = "root", q = 2, r = -4, name = "Loose Change II"},

  -- Token Boosts
  {category = "root", q = 1, r = -3, name = "Token Boost I"},
  {category = "root", q = 0, r = -3, name = "Token Boost II"},
  {category = "root", q = -1, r = -1, name = "Token Boost III"},
  {category = "root", q = -1, r = -2, name = "Jackpot"},
  {category = "root", q = -4, r = 3, name = "Lucky Pour"},

  -- Steady Hands & Swift Scoop (Fill Speed)
  {category = "buckets", q = 0, r = 1, name = "Steady Hands I"},
  {category = "buckets", q = -1, r = 1, name = "Steady Hands II"},
  {category = "buckets", q = 0, r = 2, name = "Steady Hands III"},
  {category = "buckets", q = -1, r = 2, name = "Swift Scoop I"},
  {category = "buckets", q = 1, r = 1, name = "Swift Scoop II"},
  {category = "buckets", q = 0, r = 3, name = "Swift Scoop III"},
  {category = "buckets", q = -1, r = 3, name = "Swift Scoop IV"}
}

-- Hexagonal grid math helper
local function hexDistance(q, r)
    local v6 = math.abs(q)
    local v7 = math.abs(r)
    local v8 = q + r
    local v9 = math.abs(v8)
    return math.max(v6, v7, v9)
end

-- Checks if a node is currently unlockable (either an entry node or adjacent to an owned node)
local function isNodeBuyable(category, q, r, profile)
    local catData = profile and profile[category]
    local key = string.format("%d,%d", q, r)
    
    -- Already unlocked
    if catData and catData[key] then
        return false
    end
    
    -- If the category is completely missing or empty, entry nodes (distance <= 1) are buyable
    if not catData or next(catData) == nil then
        return hexDistance(q, r) <= 1
    end
    
    -- Root category central node is always buyable
    if q == 0 and r == 0 then
        return true
    end
    
    -- Adjacent neighbors check
    local neighbors = {
        {q = 1, r = 0},
        {q = -1, r = 0},
        {q = 0, r = 1},
        {q = 0, r = -1},
        {q = 1, r = -1},
        {q = -1, r = 1}
    }
    
    for _, offset in ipairs(neighbors) do
        local nKey = string.format("%d,%d", q + offset.q, r + offset.r)
        if catData[nKey] then
            return true
        end
    end
    
    return false
end

-- Layout lookup helper
local function getNodeObject(category, q, r)
    local layout = SkillTreeLayouts.LAYOUTS[category]
    if layout then
        for _, node in ipairs(layout) do
            if node.q == q and node.r == r then
                return node
            end
        end
    end
    return nil
end

-- Local base cost calculations (removes Yielding dependancies)
local function baseCostFor(node)
    if node.cost then
        return node.cost
    else
        return 10 * (hexDistance(node.q, node.r) + 1)
    end
end

local function calculateNodeCost(node)
    local base = baseCostFor(node)
    if node.q == 0 and node.r == 0 then
        return base
    end
    return math.round(base)
end

local function getUpgradeCost(category, q, r)
    local node = getNodeObject(category, q, r)
    if node then
        return calculateNodeCost(node)
    end
    return 10
end

-- Auto Upgrades Loop
task.spawn(function()
    while ScreenGui.Parent do
        if autoUpgradesActive then
            local currentTokens = localPlayer.leaderstats and localPlayer.leaderstats:FindFirstChild("Tokens")
            local tokensVal = currentTokens and currentTokens.Value or 0
            local profile = Events.Profile.Data.SkillTree
            
            if profile then
                for _, upgrade in ipairs(upgradeQueue) do
                    local category = upgrade.category
                    local key = string.format("%d,%d", upgrade.q, upgrade.r)
                    local alreadyOwned = profile[category] and profile[category][key]
                    
                    if not alreadyOwned then
                        -- Verify if we can afford the upgrade and if its parent node has been unlocked
                        local cost = getUpgradeCost(category, upgrade.q, upgrade.r)
                        if tokensVal >= cost and isNodeBuyable(category, upgrade.q, upgrade.r, profile) then
                            local ok = remotes:Invoke("SkillTree.Purchase", category, upgrade.q, upgrade.r)
                            if ok and ok.ok then
                                warn("[Jawir Hub] Auto-Purchased: " .. upgrade.name .. " in category " .. category)
                                task.wait(1)
                                break
                            else
                                -- Failed (e.g. some server verification check). Break to prevent remote spamming
                                task.wait(1)
                                break
                            end
                        end
                    end
                end
            end
            task.wait(2)
        else
            task.wait(0.5)
        end
    end
end)

-- Buttons inside Main Frame
local btnWater = createButton("Toggle Auto Water", 190, function(btn)
    autoWaterActive = not autoWaterActive
    updateButtonVisual(btn, autoWaterActive)
end)
btnWater.Name = "Toggle Auto Water"

local btnPour = createButton("Toggle Auto Pour", 240, function(btn)
    autoPourActive = not autoPourActive
    updateButtonVisual(btn, autoPourActive)
end)
btnPour.Name = "Toggle Auto Pour"

local btnCollect = createButton("Toggle Auto Collect", 290, function(btn)
    autoCollectActive = not autoCollectActive
    updateButtonVisual(btn, autoCollectActive)
end)
btnCollect.Name = "Toggle Auto Collect"

local btnChest = createButton("Toggle Auto Chest", 340, function(btn)
    autoChestActive = not autoChestActive
    updateButtonVisual(btn, autoChestActive)
end)
btnChest.Name = "Toggle Auto Chest"

local btnUpgrades = createButton("Toggle Auto Upgrades", 390, function(btn)
    autoUpgradesActive = not autoUpgradesActive
    updateButtonVisual(btn, autoUpgradesActive)
end)
btnUpgrades.Name = "Toggle Auto Upgrades"

-- Footer/Credit
local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, 0, 0, 20)
footer.Position = UDim2.new(0, 0, 1, -25)
footer.BackgroundTransparency = 1
footer.Text = "Join our DC discord.gg/gfqDhjMjtM (JAWIR HUB)"
footer.TextColor3 = Color3.fromRGB(100, 100, 120)
footer.TextSize = 11
footer.Font = Enum.Font.Gotham
footer.Parent = mainFrame

-- MOBILE FLOATING TOGGLE BUTTON (Draggable, Toggles UI)
local MobileToggle = Instance.new("TextButton")
MobileToggle.Name = "JawirHubMobileToggle"
MobileToggle.Size = UDim2.new(0, 55, 0, 55)
MobileToggle.Position = UDim2.new(0.05, 0, 0.15, 0)
MobileToggle.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MobileToggle.BackgroundTransparency = 0.1
MobileToggle.TextColor3 = Color3.fromRGB(0, 170, 255)
MobileToggle.Text = "JH"
MobileToggle.TextSize = 18
MobileToggle.Font = Enum.Font.GothamBold
MobileToggle.Active = true
MobileToggle.Visible = not USE_KEY_SYSTEM
MobileToggle.Parent = ScreenGui

local mCorner = Instance.new("UICorner")
mCorner.CornerRadius = UDim.new(0.5, 0) -- Circular
mCorner.Parent = MobileToggle

local mStroke = Instance.new("UIStroke")
mStroke.Color = Color3.fromRGB(0, 170, 255)
mStroke.Thickness = 2
mStroke.Transparency = 0.3
mStroke.Parent = MobileToggle

-- Dragging logic for Mobile Toggle Button (touch-friendly)
local mDragToggle, mDragInput, mDragStart, mStartPos
local function updateMobileInput(input)
    local delta = input.Position - mDragStart
    MobileToggle.Position = UDim2.new(mStartPos.X.Scale, mStartPos.X.Offset + delta.X, mStartPos.Y.Scale, mStartPos.Y.Offset + delta.Y)
end
MobileToggle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        mDragToggle = true
        mDragStart = input.Position
        mStartPos = MobileToggle.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                mDragToggle = false
            end
        end)
    end
end)
MobileToggle.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        mDragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == mDragInput and mDragToggle then
        updateMobileInput(input)
    end
end)

-- Toggle UI Action
local function toggleUI()
    if keyFrame and keyFrame.Visible then return end
    mainFrame.Visible = not mainFrame.Visible
    setMouseUnlock(mainFrame.Visible)
end
MobileToggle.MouseButton1Click:Connect(toggleUI)

-- Toggle UI via Keyboard Hotkeys
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and (input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.Insert) then
        toggleUI()
    end
end)

-- KEY GATE VERIFICATION SYSTEM
keyFrame = Instance.new("Frame")
keyFrame.Name = "KeyFrame"
keyFrame.Size = UDim2.new(0, 320, 0, 250)
keyFrame.Position = UDim2.new(0.5, -160, 0.4, -125)
keyFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
keyFrame.BackgroundTransparency = 0.15
keyFrame.BorderSizePixel = 0
keyFrame.Active = true
keyFrame.Visible = USE_KEY_SYSTEM
keyFrame.Parent = ScreenGui

local kCorner = Instance.new("UICorner")
kCorner.CornerRadius = UDim.new(0, 12)
kCorner.Parent = keyFrame

local kStroke = Instance.new("UIStroke")
kStroke.Color = Color3.fromRGB(0, 170, 255)
kStroke.Thickness = 2
kStroke.Transparency = 0.2
kStroke.Parent = keyFrame

local kTitle = Instance.new("TextLabel")
kTitle.Size = UDim2.new(1, 0, 0, 35)
kTitle.Position = UDim2.new(0, 0, 0, 15)
kTitle.BackgroundTransparency = 1
kTitle.Text = "JAWIR HUB"
kTitle.TextColor3 = Color3.fromRGB(0, 170, 255)
kTitle.TextSize = 22
kTitle.Font = Enum.Font.GothamBold
kTitle.Parent = keyFrame

local kSubtitle = Instance.new("TextLabel")
kSubtitle.Size = UDim2.new(1, 0, 0, 20)
kSubtitle.Position = UDim2.new(0, 0, 0, 48)
kSubtitle.BackgroundTransparency = 1
kSubtitle.Text = "Key Verification Required"
kSubtitle.TextColor3 = Color3.fromRGB(160, 160, 160)
kSubtitle.TextSize = 12
kSubtitle.Font = Enum.Font.Gotham
kSubtitle.Parent = keyFrame

-- Key Input TextBox
local keyInput = Instance.new("TextBox")
keyInput.Size = UDim2.new(1, -40, 0, 40)
keyInput.Position = UDim2.new(0, 20, 0, 80)
keyInput.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
keyInput.PlaceholderText = "Paste Key Here..."
keyInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
keyInput.Text = ""
keyInput.TextSize = 13
keyInput.Font = Enum.Font.Gotham
keyInput.BorderSizePixel = 0
keyInput.Parent = keyFrame

local kiCorner = Instance.new("UICorner")
kiCorner.CornerRadius = UDim.new(0, 6)
kiCorner.Parent = keyInput

local kiStroke = Instance.new("UIStroke")
kiStroke.Color = Color3.fromRGB(50, 50, 70)
kiStroke.Thickness = 1
kiStroke.Parent = keyInput

-- Verify Button
local btnVerify = Instance.new("TextButton")
btnVerify.Size = UDim2.new(0.5, -25, 0, 40)
btnVerify.Position = UDim2.new(0, 20, 0, 135)
btnVerify.BackgroundColor3 = Color3.fromRGB(0, 130, 200)
btnVerify.TextColor3 = Color3.fromRGB(255, 255, 255)
btnVerify.Text = "Verify Key"
btnVerify.TextSize = 13
btnVerify.Font = Enum.Font.GothamBold
btnVerify.BorderSizePixel = 0
btnVerify.Parent = keyFrame

local kvCorner = Instance.new("UICorner")
kvCorner.CornerRadius = UDim.new(0, 6)
kvCorner.Parent = btnVerify

local kvStroke = Instance.new("UIStroke")
kvStroke.Color = Color3.fromRGB(0, 170, 255)
kvStroke.Thickness = 1
kvStroke.Parent = btnVerify

-- Get Key Button (Discord invite link copy)
local btnGetKey = Instance.new("TextButton")
btnGetKey.Size = UDim2.new(0.5, -25, 0, 40)
btnGetKey.Position = UDim2.new(0.5, 5, 0, 135)
btnGetKey.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
btnGetKey.TextColor3 = Color3.fromRGB(0, 170, 255)
btnGetKey.Text = "Get Key"
btnGetKey.TextSize = 13
btnGetKey.Font = Enum.Font.GothamBold
btnGetKey.BorderSizePixel = 0
btnGetKey.Parent = keyFrame

local gkCorner = Instance.new("UICorner")
gkCorner.CornerRadius = UDim.new(0, 6)
gkCorner.Parent = btnGetKey

local gkStroke = Instance.new("UIStroke")
gkStroke.Color = Color3.fromRGB(50, 50, 70)
gkStroke.Thickness = 1
gkStroke.Parent = btnGetKey

-- Feedback Message Label
local feedbackLabel = Instance.new("TextLabel")
feedbackLabel.Size = UDim2.new(1, -40, 0, 20)
feedbackLabel.Position = UDim2.new(0, 20, 0, 185)
feedbackLabel.BackgroundTransparency = 1
feedbackLabel.Text = "Join our Discord for the key!"
feedbackLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
feedbackLabel.TextSize = 11
feedbackLabel.Font = Enum.Font.Gotham
feedbackLabel.Parent = keyFrame

-- Key System functions
local function getActiveKey()
    local success, key = pcall(function()
        local req = (syn and syn.request) or (http and http.request) or request or http_request
        if req then
            local res = req({
                Url = KEY_URL,
                Method = "GET"
            })
            if res and res.StatusCode == 200 then
                local body = res.Body
                if body and not string.find(body, "404") and not string.find(body, "Not Found") then
                    return string.gsub(body, "%s+", "")
                end
            end
        else
            local body = game:HttpGet(KEY_URL)
            if body and not string.find(body, "404") and not string.find(body, "Not Found") then
                return string.gsub(body, "%s+", "")
            end
        end
    end)
    if success and key and #key > 0 then
        return key
    end
    return STATIC_BACKUP_KEY
end

local function getSavedKey()
    if readfile then
        local ok, content = pcall(readfile, "JawirHubKey.txt")
        if ok and content then
            return string.gsub(content, "%s+", "")
        end
    end
    return nil
end

local function saveKey(key)
    if writefile then
        pcall(writefile, "JawirHubKey.txt", key)
    end
end

-- Verify logic
local function verify(inputKey)
    feedbackLabel.Text = "Checking key..."
    feedbackLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    task.wait(0.5)
    
    local activeKey = getActiveKey()
    if inputKey == activeKey then
        feedbackLabel.Text = "Key Verified! Loading..."
        feedbackLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
        saveKey(inputKey)
        task.wait(0.8)
        
        -- Unlock Menu
        keyFrame.Visible = false
        mainFrame.Visible = true
        MobileToggle.Visible = true
        setMouseUnlock(true)
    else
        feedbackLabel.Text = "Invalid Key! Please check our Discord."
        feedbackLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end

btnVerify.MouseButton1Click:Connect(function()
    verify(string.gsub(keyInput.Text, "%s+", ""))
end)

btnGetKey.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(DISCORD_INVITE)
        btnGetKey.Text = "Copied!"
        task.wait(1.5)
        btnGetKey.Text = "Get Key"
    else
        feedbackLabel.Text = "Invite link: " .. DISCORD_INVITE
        feedbackLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
    end
end)

-- Check saved key upon injection
task.spawn(function()
    if USE_KEY_SYSTEM then
        local saved = getSavedKey()
        if saved then
            local active = getActiveKey()
            if saved == active then
                keyFrame.Visible = false
                mainFrame.Visible = true
                MobileToggle.Visible = true
                setMouseUnlock(true)
            end
        end
    end
end)

ScreenGui.Destroying:Connect(function()
    setMouseUnlock(false)
end)

warn("[Jawir Hub] Loaded successfully!")
