-- Local Roblox Avatar Saver Script
-- Run this inside Catalog Avatar Creator to save your custom look to saved_avatar.json
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character
if not character then
    warn("No character found. Spawn first.")
    return
end

local humanoid = character:FindFirstChildOfClass("Humanoid")
if not humanoid then
    warn("No humanoid found in character.")
    return
end

local desc = humanoid:GetAppliedDescription()
if not desc then
    warn("Failed to get HumanoidDescription from humanoid.")
    return
end

-- Get accessories list from description
local accs = {}
local success, descAccs = pcall(function() return desc:GetAccessories(true) end)
if success and descAccs then
    accs = descAccs
else
    warn("Failed to get accessories from HumanoidDescription.")
end

-- Helper to clean and normalize mesh IDs
local function normalizeMeshId(meshId)
    if not meshId then return "" end
    return meshId:lower()
        :gsub("http://www.roblox.com/asset/%?id=", "")
        :gsub("rbxassetid://", "")
        :gsub("https://assetdelivery.roblox.com/v1/asset/%?id=", "")
        :gsub("%s+", "")
end

-- Collect active character accessories
local characterAccs = {}
for _, child in ipairs(character:GetChildren()) do
    if child:IsA("Accessory") then
        local handle = child:FindFirstChild("Handle")
        if handle then
            local meshId = ""
            local mesh = handle:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                meshId = mesh.MeshId
            elseif handle:IsA("MeshPart") then
                meshId = handle.MeshId
            end
            table.insert(characterAccs, {
                Instance = child,
                MeshId = normalizeMeshId(meshId)
            })
        end
    end
end

-- Find weld targets
local function getWeldTarget(acc)
    local handle = acc:FindFirstChild("Handle")
    if not handle then return nil end
    
    -- Check welds in handle
    for _, child in ipairs(handle:GetChildren()) do
        if child:IsA("Weld") or child:IsA("ManualWeld") then
            if child.Part1 and child.Part1:IsDescendantOf(character) then
                return child.Part1
            end
        end
    end
    
    -- Check matching attachments
    local attachment = handle:FindFirstChildOfClass("Attachment")
    if attachment then
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") and part:FindFirstChild(attachment.Name) then
                return part
            end
        end
    end
    
    return character:FindFirstChild("Head")
end

-- Match character accessories to description asset IDs using MeshId comparison
local savedAccessories = {}
for _, descAcc in ipairs(accs) do
    local id = descAcc.AssetId
    local matchedCharAcc = nil
    local matchedIndex = nil
    
    -- Load asset to get its default mesh ID
    local loadSuccess, assets = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
    if loadSuccess and assets and assets[1] then
        local loadedAcc = assets[1]
        local loadedHandle = loadedAcc:FindFirstChild("Handle")
        if loadedHandle then
            local loadedMeshId = ""
            local mesh = loadedHandle:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                loadedMeshId = mesh.MeshId
            elseif loadedHandle:IsA("MeshPart") then
                loadedMeshId = loadedHandle.MeshId
            end
            loadedMeshId = normalizeMeshId(loadedMeshId)
            
            for i, charAcc in ipairs(characterAccs) do
                if charAcc.MeshId == loadedMeshId then
                    matchedCharAcc = charAcc.Instance
                    matchedIndex = i
                    break
                end
            end
        end
    end
    
    -- Fallback: if no mesh match, match by name or type order
    if not matchedCharAcc and #characterAccs > 0 then
        for i, charAcc in ipairs(characterAccs) do
            matchedCharAcc = charAcc.Instance
            matchedIndex = i
            break
        end
    end
    
    if matchedCharAcc then
        local handle = matchedCharAcc:FindFirstChild("Handle")
        local target = getWeldTarget(matchedCharAcc)
        
        if handle and target then
            local rel = target.CFrame:Inverse() * handle.CFrame
            
            -- Calculate scale ratio
            local meshScale = {1, 1, 1}
            local mesh = handle:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                meshScale = {mesh.Scale.X, mesh.Scale.Y, mesh.Scale.Z}
            elseif handle:IsA("MeshPart") then
                local loadedHandle = loadSuccess and assets and assets[1] and assets[1]:FindFirstChild("Handle")
                if loadedHandle then
                    meshScale = {
                        handle.Size.X / loadedHandle.Size.X,
                        handle.Size.Y / loadedHandle.Size.Y,
                        handle.Size.Z / loadedHandle.Size.Z
                    }
                end
            end
            
            table.insert(savedAccessories, {
                AssetId = id,
                TargetPart = target.Name,
                RelCFrame = {rel:GetComponents()},
                Scale = meshScale,
                IsLayered = descAcc.IsLayered
            })
            
            if matchedIndex then
                table.remove(characterAccs, matchedIndex)
            end
        end
    end
end

-- Collect clothing and properties
local props = {
    "Shirt", "Pants", "GraphicTShirt",
    "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Face",
    "HeightScale", "WidthScale", "DepthScale", "HeadScale", "ProportionScale", "BodyTypeScale"
}

local colors = {
    "HeadColor", "TorsoColor", "LeftArmColor", "RightArmColor", "LeftLegColor", "RightLegColor"
}

local data = {
    Accessories = savedAccessories,
    Properties = {},
    Colors = {}
}

for _, prop in ipairs(props) do
    local s, v = pcall(function() return desc[prop] end)
    if s and v then
        data.Properties[prop] = v
    end
end

for _, col in ipairs(colors) do
    local s, v = pcall(function() return desc[col] end)
    if s and typeof(v) == "Color3" then
        data.Colors[col] = {v.R, v.G, v.B}
    end
end

local jsonData = HttpService:JSONEncode(data)
writefile("saved_avatar.json", jsonData)
print("[Avatar Saver] Synchronized avatar configuration saved to 'saved_avatar.json'!")
