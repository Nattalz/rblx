-- Zombie Stories Rayfield GUI
-- Pass: jawir
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Zombie Stories - JawirHub",
    LoadingTitle = "Loading....",
    LoadingSubtitle = "by JawirHub",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = true,
    KeySystem = true,
    KeySettings = {
        Title = "Zombie Stories Hub",
        Subtitle = "Key System",
        Note = "Key is: jawir",
        FileName = "JawirHub",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"jawir"}
    }
})
local function notify(title, content)
    pcall(function()
        Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = 3
        })
    end)
end
-- Toggles & Variables
local aimbotEnabled = false
local espEnabled = false
local hitboxEnabled = false
local interactEnabled = false
local hitboxSize = 20
local espColor = Color3.fromRGB(50, 205, 50)
local zombiesFolder = Workspace:FindFirstChild("Zombies")
--------------------------------------------------------------------------------
-- SILENT AIMBOT
--------------------------------------------------------------------------------
local HitReg
pcall(function()
    HitReg = require(ReplicatedStorage.common.HitReg)
end)
if HitReg then
    local originalProcessHit = HitReg.ProcessHit
    local originalRegister = HitReg.Register
    local zombieValidators = {}
    HitReg.Register = function(self, mod)
        table.insert(zombieValidators, mod)
        return originalRegister(self, mod)
    end
    HitReg.ProcessHit = function(self, raycastResult, customHitData, ...)
        if (aimbotEnabled or hitboxEnabled) and zombiesFolder then
            local rayOrigin = type(customHitData) == "table" and customHitData.startPos or (Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame.Position)
            for _, zombie in ipairs(zombiesFolder:GetChildren()) do
                local head = zombie:FindFirstChild("Head") or zombie:FindFirstChild("HeadMesh")
                if head and head:IsA("BasePart") then
                    local shouldSpoof = false
                    if aimbotEnabled then
                        shouldSpoof = true
                    elseif hitboxEnabled and rayOrigin then
                        -- Check if the raycast origin is inside the expanded head
                        local rel = head.CFrame:PointToObjectSpace(rayOrigin)
                        local halfSize = head.Size / 2
                        if math.abs(rel.X) <= halfSize.X and math.abs(rel.Y) <= halfSize.Y and math.abs(rel.Z) <= halfSize.Z then
                            shouldSpoof = true
                        end
                    end
                    if shouldSpoof then
                        local spoofedResult = setmetatable({}, {
                            __index = function(t, k)
                                if k == "Instance" then return head
                                elseif k == "Position" then return head.Position
                                elseif k == "Normal" then return Vector3.new(0, 1, 0)
                                elseif k == "Material" then return Enum.Material.Plastic
                                elseif k == "Distance" then 
                                    return customHitData.startPos and (customHitData.startPos - head.Position).Magnitude or 0
                                end
                                return raycastResult and raycastResult[k] or nil
                            end
                        })
                        if type(customHitData) == "table" then
                            customHitData.raycastResult = spoofedResult
                            if type(customHitData.toNetwork) == "table" and customHitData.startPos then
                                local dist = string.format("%.2f", (customHitData.startPos - head.Position).Magnitude)
                                for i, v in ipairs(customHitData.toNetwork) do
                                    if type(v) == "string" and v:sub(1,1) == "r" then
                                        customHitData.toNetwork[i] = "r" .. dist
                                    elseif typeof(v) == "Vector3" and i > 1 and type(customHitData.toNetwork[i-1]) == "string" and customHitData.toNetwork[i-1]:sub(1,1) == "b" then
                                        customHitData.toNetwork[i] = head.Position
                                    end
                                end
                            end
                        end
                        return originalProcessHit(self, spoofedResult, customHitData, ...)
                    end
                end
            end
        end
        return originalProcessHit(self, raycastResult, customHitData, ...)
    end
end
--------------------------------------------------------------------------------
-- ZOMBIE ESP
--------------------------------------------------------------------------------
local activeZombies = {}
local function findHead(zombie)
    return zombie:FindFirstChild("Head") or zombie:FindFirstChild("HeadMesh")
end
local function hookZombieESP(zombie)
    if not zombie:IsA("Model") then return end
    if activeZombies[zombie] then return end
    
    local head = findHead(zombie)
    if not head then
        task.spawn(function()
            local start = os.clock()
            while not findHead(zombie) and os.clock() - start < 5 do
                task.wait(0.1)
            end
            local h = findHead(zombie)
            if h then hookZombieESP(zombie) end
        end)
        return
    end
    
    local hl = Instance.new("Highlight")
    hl.FillTransparency = 1
    hl.OutlineColor = espColor
    hl.OutlineTransparency = 0
    hl.Enabled = espEnabled
    hl.Parent = head
    
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 100, 0, 30)
    bb.AlwaysOnTop = true
    bb.Adornee = head
    bb.Enabled = espEnabled
    bb.ExtentsOffset = Vector3.new(0, 2, 0)
    bb.Parent = head
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = espColor
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Code
    lbl.TextStrokeTransparency = 0
    lbl.Parent = bb
    
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not zombie or not zombie.Parent then
            connection:Disconnect()
            activeZombies[zombie] = nil
            return
        end
        local hpVal = zombie:FindFirstChild("HP") or zombie:FindFirstChild("Health")
        local health = hpVal and (hpVal:IsA("ValueBase") and hpVal.Value or zombie:GetAttribute("Health")) or 100
        lbl.Text = string.format("%s\nHP: %s", head.Name, tostring(health))
    end)
    
    activeZombies[zombie] = {
        highlight = hl,
        billboard = bb,
        connection = connection,
        label = lbl
    }
end
local function updateESPState()
    for _, data in pairs(activeZombies) do
        if data.highlight then data.highlight.Enabled = espEnabled end
        if data.billboard then data.billboard.Enabled = espEnabled end
    end
end
local function updateESPColor()
    for _, data in pairs(activeZombies) do
        if data.highlight then data.highlight.OutlineColor = espColor end
        if data.label then data.label.TextColor3 = espColor end
    end
end
--------------------------------------------------------------------------------
-- HITBOX EXPANDER
--------------------------------------------------------------------------------
local originalHeadProps = {}
local function expandHead(zombieModel)
    task.spawn(function()
        local head = zombieModel:WaitForChild("Head", 3) or zombieModel:WaitForChild("HeadMesh", 3)
        if head and head:IsA("BasePart") then
            if not originalHeadProps[head] then
                originalHeadProps[head] = {
                    Size = head.Size,
                    Transparency = head.Transparency,
                    BrickColor = head.BrickColor,
                    CanCollide = head.CanCollide,
                    Massless = head.Massless
                }
            end
            
            if hitboxEnabled then
                head.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                head.Transparency = 0.7
                head.BrickColor = BrickColor.new("Bright green")
                head.CanCollide = false
                head.Massless = true 
            else
                local props = originalHeadProps[head]
                if props then
                    head.Size = props.Size
                    head.Transparency = props.Transparency
                    head.BrickColor = props.BrickColor
                    head.CanCollide = props.CanCollide
                    head.Massless = props.Massless
                end
            end
        end
    end)
end
local function updateHitboxes()
    if zombiesFolder then
        for _, zombie in ipairs(zombiesFolder:GetChildren()) do
            if zombie:IsA("Model") then
                expandHead(zombie)
            end
        end
    end
end
if zombiesFolder then
    for _, z in ipairs(zombiesFolder:GetChildren()) do
        hookZombieESP(z)
    end
    zombiesFolder.ChildAdded:Connect(function(child)
        hookZombieESP(child)
        if hitboxEnabled then
            expandHead(child)
        end
    end)
end
--------------------------------------------------------------------------------
-- INSTANT INTERACT
--------------------------------------------------------------------------------
local ProximityPromptZS
local promptsT
pcall(function()
    ProximityPromptZS = require(ReplicatedStorage.common.ProximityPromptZS)
    for _, val in pairs(debug.getupvalues(ProximityPromptZS.GetPromptByIdentifier)) do
        if type(val) == "table" then
            promptsT = val
            break
        end
    end
end)
--------------------------------------------------------------------------------
-- INFINITE STAMINA & WEAPON BUFF (Functions)
--------------------------------------------------------------------------------
local function enableInfiniteStamina()
    local success = pcall(function()
        local LocalPlayerController = require(ReplicatedStorage.common.ZS_Framework.Modules.Controllers.LocalPlayerController)
        debug.setupvalue(LocalPlayerController.InfiniteStamina, 4, 0)
        
        local fenv = getfenv(LocalPlayerController.DrainStamina)
        if fenv and fenv.DrainStamina then
            fenv.DrainStamina = function() end
        end
        
        debug.setupvalue(LocalPlayerController.GetStamina, 1, 100)
    end)
    
    if success then
        notify("Stamina Buff", "Infinite Stamina activated successfully!")
    else
        notify("Stamina Buff", "Failed to activate infinite stamina.")
    end
end
local function enableWeaponBuff()
    local success = pcall(function()
        local WeaponController = require(ReplicatedStorage.common.ZS_Framework.Modules.Controllers.WeaponController)
        local u196 = debug.getupvalues(WeaponController.SwapWeapon)[4]
        
        if u196 then
            for slotIndex, weaponsList in pairs(u196) do
                if typeof(weaponsList) == "table" then
                    for _, wep in ipairs(weaponsList) do
                        if wep.Config then
                            wep.Config.BaseSpread = 0 
                            wep.Config.VerticalRecoil = 0 
                            wep.Config.HorizontalRecoil = 0 
                            wep.Config.DelayPerShot = 0.1
                            wep.Config.FireMode = {"Auto", "Semi"} 
                            wep.SelFireMode = 1 
                            wep.FireMode = "Auto" 
                        end
                    end
                end
            end
        end
    end)
    
    if success then
        notify("Weapon Buff", "All weapons buffed (No Recoil, Auto, Fast Fire)!")
    else
        notify("Weapon Buff", "Failed to patch weapon stats.")
    end
end
--------------------------------------------------------------------------------
-- UI TABS & ELEMENTS
--------------------------------------------------------------------------------
local CombatTab = Window:CreateTab("Combat", "swords")
local VisualsTab = Window:CreateTab("Visuals", "eye")
local MiscTab = Window:CreateTab("Misc", "settings")
-- COMBAT
CombatTab:CreateToggle({
    Name = "Always Headshot hit",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(Value)
        aimbotEnabled = Value
        if Value then 
            notify("Combat", "Silent Aimbot Enabled") 
        else 
            notify("Combat", "Silent Aimbot Disabled") 
        end
    end
})
CombatTab:CreateToggle({
    Name = "Hitbox Expander",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(Value)
        hitboxEnabled = Value
        updateHitboxes()
        if Value then 
            notify("Combat", "Hitbox Expander Enabled") 
        else 
            notify("Combat", "Hitbox Expander Reverted") 
        end
    end
})
CombatTab:CreateButton({
    Name = "Buff Weapons (Click when wpn loaded)",
    Callback = function()
        enableWeaponBuff()
    end
})
-- VISUALS
VisualsTab:CreateToggle({
    Name = "Zombie ESP",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(Value)
        espEnabled = Value
        updateESPState()
        if Value then 
            notify("Visuals", "Zombie ESP Enabled") 
        else 
            notify("Visuals", "Zombie ESP Disabled") 
        end
    end
})
VisualsTab:CreateToggle({
    Name = "Night Vision",
    CurrentValue = false,
    Flag = "NVGToggle",
    Callback = function(Value)
        local success = pcall(function()
            local NVGs = require(ReplicatedStorage.common.ZS_Framework.Modules.Classes.Viewmodel.ViewmodelUtils.NVGs)
            -- Bypass gamepass check (upvalue 1)
            debug.setupvalue(NVGs.ToggleActivate, 1, true)
            -- Check current state (upvalue 2)
            local isActive = debug.getupvalue(NVGs.ToggleActivate, 2)
            
            -- Only toggle if state differs from the UI
            if (Value and not isActive) or (not Value and isActive) then
                NVGs.ToggleActivate()
            end
        end)
        
        if success then
            notify("Visuals", Value and "Night Vision Enabled" or "Night Vision Disabled")
        else
            notify("Visuals", "Failed to toggle Night Vision")
        end
    end
})
VisualsTab:CreateColorPicker({
    Name = "ESP Color",
    Color = espColor,
    Flag = "ESPColorPicker",
    Callback = function(Value)
        espColor = Value
        updateESPColor()
    end
})
-- MISC / ADJUST SETTINGS
MiscTab:CreateButton({
    Name = "Infinite Stamina",
    Callback = function()
        enableInfiniteStamina()
    end
})
MiscTab:CreateToggle({
    Name = "Instant Interact",
    CurrentValue = false,
    Flag = "InteractToggle",
    Callback = function(Value)
        interactEnabled = Value
        if Value then 
            notify("Misc", "Instant Interact Enabled (Press Keybind)") 
        else 
            notify("Misc", "Instant Interact Disabled") 
        end
    end
})
MiscTab:CreateKeybind({
    Name = "Hotkey Instant Interact",
    CurrentKeybind = "T",
    HoldToInteract = false,
    Flag = "InteractKeybind",
    Callback = function()
        if not interactEnabled or not promptsT then return end
        
        local count = 0
        for id, prompt in pairs(promptsT) do
            local properties = prompt.Properties
            if properties and properties.Enabled and properties.ActionText ~= "REFILL" then
                pcall(function()
                    prompt.Triggered:Fire(Players.LocalPlayer)
                end)
                count = count + 1
            end
        end
    end
})
MiscTab:CreateSlider({
    Name = "Hitbox Expand Size",
    Range = {1, 50},
    Increment = 1,
    CurrentValue = 20,
    Flag = "HitboxSizeSlider",
    Callback = function(Value)
        hitboxSize = Value
        if hitboxEnabled then
            updateHitboxes()
        end
    end
})
-- Cleanup the UI cleanly if user closes
local function killUI()
    espEnabled = false
    hitboxEnabled = false
    aimbotEnabled = false
    interactEnabled = false
    updateESPState()
    updateHitboxes()
    Rayfield:Destroy()
end
MiscTab:CreateButton({
    Name = "Close GUI (Kill Switch)",
    Callback = function()
        killUI()
    end
})
