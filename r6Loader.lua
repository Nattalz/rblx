-- Local Roblox Avatar Loader Script
-- Put this script in your auto-exec folder to load your saved avatar in any game.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function safeGetObjects(assetId)
    local success, result = pcall(function()
        return game:GetObjects("rbxassetid://" .. assetId)
    end)
    if success and result and #result > 0 then
        return result
    end
    return nil
end

local function applyClothing(character, clothingId, className)
    if not clothingId or clothingId == 0 then return end
    local assets = safeGetObjects(clothingId)
    if not assets then return end
    
    local asset = assets[1]
    if asset:IsA(className) then
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA(className) then
                child:Destroy()
            end
        end
        asset.Parent = character
    end
end

local function applyFace(character, faceId)
    if not faceId or faceId == 0 then return end
    local assets = safeGetObjects(faceId)
    if not assets then return end
    
    local asset = assets[1]
    local head = character:FindFirstChild("Head")
    if head then
        local currentFace = head:FindFirstChild("face")
        if currentFace then currentFace:Destroy() end
        
        local decal = nil
        if asset:IsA("Decal") then
            decal = asset
        elseif asset:IsA("Folder") or asset:IsA("Model") then
            decal = asset:FindFirstChildOfClass("Decal") or asset:FindFirstChild("face")
        end
        
        if decal then
            local newFace = decal:Clone()
            newFace.Name = "face"
            newFace.Parent = head
        end
    end
end

local function applyBodyPart(character, partId)
    if not partId or partId == 0 then return end
    local assets = safeGetObjects(partId)
    if not assets then return end
    
    local asset = assets[1]
    if asset:IsA("Folder") or asset:IsA("Model") then
        for _, child in ipairs(asset:GetChildren()) do
            if child:IsA("MeshPart") then
                local target = character:FindFirstChild(child.Name)
                if target and target:IsA("MeshPart") then
                    target.MeshId = child.MeshId
                    target.TextureID = child.TextureID
                end
            elseif child:IsA("CharacterMesh") then
                local existing = nil
                for _, mesh in ipairs(character:GetChildren()) do
                    if mesh:IsA("CharacterMesh") and mesh.BodyPart == child.BodyPart then
                        existing = mesh
                        break
                    end
                end
                if not existing then
                    existing = Instance.new("CharacterMesh")
                    existing.BodyPart = child.BodyPart
                    existing.Parent = character
                end
                existing.MeshId = child.MeshId
                existing.BaseTextureId = child.BaseTextureId
                existing.OverlayTextureId = child.OverlayTextureId
            end
        end
    elseif asset:IsA("CharacterMesh") then
        local existing = nil
        for _, mesh in ipairs(character:GetChildren()) do
            if mesh:IsA("CharacterMesh") and mesh.BodyPart == asset.BodyPart then
                existing = mesh
                break
            end
        end
        if not existing then
            existing = Instance.new("CharacterMesh")
            existing.BodyPart = asset.BodyPart
            existing.Parent = character
        end
        existing.MeshId = asset.MeshId
        existing.BaseTextureId = asset.BaseTextureId
        existing.OverlayTextureId = asset.OverlayTextureId
    end
end

local function applyBodyColors(character, colors)
    if not colors then return end
    local bc = character:FindFirstChildOfClass("BodyColors")
    if not bc then
        bc = Instance.new("BodyColors")
        bc.Parent = character
    end
    
    local colorMapping = {
        HeadColor = "HeadColor3",
        TorsoColor = "TorsoColor3",
        LeftArmColor = "LeftArmColor3",
        RightArmColor = "RightArmColor3",
        LeftLegColor = "LeftLegColor3",
        RightLegColor = "RightLegColor3"
    }
    
    for colName, propName in pairs(colorMapping) do
        local rgb = colors[colName]
        if rgb then
            bc[propName] = Color3.new(rgb[1], rgb[2], rgb[3])
        end
    end
end

local function applyScales(humanoid, props)
    if not props then return end
    local scaleNames = {
        HeightScale = "HeightScale",
        WidthScale = "WidthScale",
        DepthScale = "DepthScale",
        HeadScale = "HeadScale",
        ProportionScale = "ProportionScale",
        BodyTypeScale = "BodyTypeScale"
    }
    for prop, scaleName in pairs(scaleNames) do
        local val = props[prop]
        if val then
            local scaleValue = humanoid:FindFirstChild(scaleName)
            if not scaleValue then
                scaleValue = Instance.new("NumberValue")
                scaleValue.Name = scaleName
                scaleValue.Parent = humanoid
            end
            scaleValue.Value = val
        end
    end
end

local function applyAccessory(character, humanoid, acc)
    if not acc.AssetId or acc.AssetId == 0 then return end
    local assets = safeGetObjects(acc.AssetId)
    if not assets then return end
    
    local asset = assets[1]
    if asset:IsA("Accessory") then
        -- Recursively strip collision and mass before parenting
        for _, child in ipairs(asset:GetDescendants()) do
            if child:IsA("BasePart") then
                child.CanCollide = false
                child.Massless = true
                child.CanTouch = false
                child.CanQuery = false
            end
        end
        
        asset.Parent = character
        
        local handle = asset:FindFirstChild("Handle")
        if not handle or not handle:IsA("BasePart") then return end
        
        -- Apply scale
        local mesh = handle:FindFirstChildOfClass("SpecialMesh")
        if mesh and acc.Scale then
            mesh.Scale = Vector3.new(acc.Scale[1], acc.Scale[2], acc.Scale[3])
        elseif handle:IsA("MeshPart") and acc.Scale then
            pcall(function()
                handle.Size = handle.Size * Vector3.new(acc.Scale[1], acc.Scale[2], acc.Scale[3])
            end)
        end
        
        -- Apply exact relative CFrame positioning
        local targetPartName = acc.TargetPart or "Head"
        local targetPart = character:WaitForChild(targetPartName, 5) or character:FindFirstChild("Head")
        
        if targetPart then
            local weld = Instance.new("Weld")
            weld.Name = "AccessoryWeld"
            weld.Part0 = handle
            weld.Part1 = targetPart
            weld.C0 = CFrame.new()
            
            local c = acc.RelCFrame
            if c and #c == 12 then
                weld.C1 = CFrame.new(c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12])
            else
                weld.C1 = CFrame.new(0, 0.5, 0) -- fallback
            end
            weld.Parent = handle
        end
    end
end

local function loadAvatar(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 10)
    if not humanoid then return end
    
    if not isfile("saved_avatar.json") then
        warn("[Avatar Loader] No saved avatar file found ('saved_avatar.json').")
        return
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile("saved_avatar.json"))
    end)
    if not success or not data then
        warn("[Avatar Loader] Failed to parse 'saved_avatar.json'.")
        return
    end
    
    -- Strip existing accessories and clothing
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then
            child:Destroy()
        end
    end
    
    local props = data.Properties or {}
    
    -- Apply Body Parts (Packages)
    local bodyParts = {"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}
    for _, part in ipairs(bodyParts) do
        applyBodyPart(character, props[part])
    end
    
    -- Apply Clothing
    applyClothing(character, props.Shirt, "Shirt")
    applyClothing(character, props.Pants, "Pants")
    applyClothing(character, props.GraphicTShirt, "ShirtGraphic")
    
    -- Apply Face
    applyFace(character, props.Face)
    
    -- Apply Body Colors
    applyBodyColors(character, data.Colors)
    
    -- Apply Scales (R15)
    applyScales(humanoid, props)
    
    -- Apply Accessories
    if data.Accessories then
        for _, acc in ipairs(data.Accessories) do
            applyAccessory(character, humanoid, acc)
        end
    end
    
    print("[Avatar Loader] Saved avatar applied successfully!")
end

if player.Character then
    task.spawn(loadAvatar, player.Character)
end
player.CharacterAdded:Connect(function(char)
    task.spawn(loadAvatar, char)
end)
