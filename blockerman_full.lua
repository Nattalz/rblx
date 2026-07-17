
-- Minesweeper Solver Bot & ESP (Rayfield UI Full Suite)
-- Mobile Compatible Edition with Dynamic Key Verification
-- Keysystem Key: Dynamic fetch from GitHub, fallback "JawirOnTop"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local autoFlagActive = false
local autoWalkActive = false
local espActive = false

-- Movement variables
local customWalkSpeed = 16
local customJumpPower = 50
local infiniteJump = false
local flying = false
local flySpeed = 50
local flyGyro, flyVelocity

-- Auto flag customization variables
local autoFlagDelayMs = 100
local autoFlagDelay = 0.1
local autoFlagDistance = 25
local lastFlagTime = 0

-- ESP customization variables
local espRefreshInterval = 0.5
local lastEspUpdateTime = 0
local espCleared = true

-- ESP Color configuration
local espSafeColor = Color3.fromRGB(0, 0, 255)
local espBombColor = Color3.fromRGB(255, 0, 0)
local espUncertainLow = Color3.fromRGB(255, 215, 0) -- Yellow
local espUncertainMed = Color3.fromRGB(255, 165, 0) -- Orange
local espUncertainHigh = Color3.fromRGB(220, 20, 60) -- Crimson

local grid = {}
local W, H = 0, 0
local xToCol, zToRow = {}, {}
local localFlags = {} -- Local tracking of flagged tiles to bypass client-server replication lag
local deducedBombs = {} -- Cache of deduced bombs to separate logic from physical flag placement range

-- Dynamic Key Configuration
local USE_KEY_SYSTEM = true
local KEY_URL = "https://raw.githubusercontent.com/Nattalz/rblx/refs/heads/main/keys/key1.txt"
local DISCORD_INVITE = "https://discord.gg/gfqDhjMjtM"
local STATIC_BACKUP_KEY = "JawirOnTop"
local dynamicKey = STATIC_BACKUP_KEY

-- UI References
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local AutoWalkToggle, AutoFlagToggle, ESPToggle, FlyToggle

-- Create or fetch ESP folder in workspace
local espFolder = workspace:FindFirstChild("BotESPFolder")
if not espFolder then
    espFolder = Instance.new("Folder")
    espFolder.Name = "BotESPFolder"
    espFolder.Parent = workspace
end

-- ============================================
-- DYNAMIC KEY FETCHING
-- ============================================

local function fetchDynamicKey()
    local success, result = pcall(function()
        return game:HttpGet(KEY_URL, true)
    end)
    
    if success and result then
        -- Clean whitespace/newlines
        local cleaned = result:gsub("^%s*(.-)%s*$", "%1")
        if #cleaned > 0 and cleaned ~= "404: Not Found" then
            dynamicKey = cleaned
            print("[KeySystem] Dynamic key fetched successfully: " .. cleaned)
            return cleaned
        end
    end
    
    print("[KeySystem] Failed to fetch dynamic key, using static fallback: " .. STATIC_BACKUP_KEY)
    return STATIC_BACKUP_KEY
end

-- Fetch key on load
fetchDynamicKey()

-- ============================================
-- RAYFIELD NOTIFICATION HELPER
-- ============================================

local function notify(title, content)
    pcall(function()
        Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = 3.5
        })
    end)
end

-- ============================================
-- DISCORD AUTO-COPY
-- ============================================

local function copyDiscord()
    local link = "https://discord.gg/gfqDhjMjtM"
    local success = pcall(function()
        if setclipboard then
            setclipboard(link)
        elseif toclipboard then
            toclipboard(link)
        end
    end)
    if success then
        notify("Discord Copied", "Discord link has been copied to your clipboard!")
    else
        notify("Copy Failed", "Please join: discord.gg/gfqDhjMjtM")
    end
end

-- Run auto-copy on load
copyDiscord()

-- ============================================
-- MOBILE-COMPATIBLE SECRET KEY SCANNER
-- ============================================

--[[
    Scans garbage collection and upvalues across execution boundaries.
    Optimized for Delta, Codex, Arceus X, and other Android executors.
    Uses pcall to prevent crashes when accessing protected core functions.
]]

local function getSecretKey()
    -- 1. Check workspace first in case it still exists
    local salasana = workspace:FindFirstChild("Salasana")
    if salasana and salasana:IsA("ValueObject") and salasana.Value ~= 0 then
        return tostring(salasana.Value)
    end

    -- 2. Scan garbage collection for MouseControl values
    if getgc then
        for _, v in pairs(getgc(true)) do
            if type(v) == "function" then
                local ok, info = pcall(debug.info, v, "s")
                info = ok and info or ""
                if info:find("MouseControl") then
                    local ok2, upvals = pcall(debug.getupvalues, v)
                    if ok2 and upvals then
                        local hasPlaceFlag = false
                        local potentialKey = nil
                        for _, uv in pairs(upvals) do
                            if typeof(uv) == "Instance" and (uv.Name == "PlaceFlag" or uv.Name == "FlagEvents" or uv.Name == "ReplicatedStorage") then
                                hasPlaceFlag = true
                            elseif type(uv) == "string" and #uv >= 10 and tonumber(uv) ~= nil then
                                potentialKey = uv
                            elseif type(uv) == "number" and uv > 1000 then
                                potentialKey = tostring(uv)
                            end
                        end
                        if hasPlaceFlag and potentialKey then
                            return potentialKey
                        end
                    end
                end
            end
        end

        -- Generic GC fallback scanning
        for _, v in pairs(getgc(true)) do
            if type(v) == "function" then
                local ok2, upvals = pcall(debug.getupvalues, v)
                if ok2 and upvals then
                    local hasPlaceFlag = false
                    local potentialKey = nil
                    for _, uv in pairs(upvals) do
                        if typeof(uv) == "Instance" and (uv.Name == "PlaceFlag" or uv.Name == "FlagEvents" or uv.Name == "ReplicatedStorage") then
                            hasPlaceFlag = true
                        elseif type(uv) == "string" and #uv >= 10 and tonumber(uv) ~= nil then
                            potentialKey = uv
                        elseif type(uv) == "number" and uv > 1000 then
                            potentialKey = tostring(uv)
                        end
                    end
                    if hasPlaceFlag and potentialKey then
                        return potentialKey
                    end
                end
            end
        end
    end

    -- 3. Fallback: standard connection scanning (for PC compatibility)
    local function scanUpvaluesForKey(func, depth, maxDepth)
        depth = depth or 0
        maxDepth = maxDepth or 3
        if depth > maxDepth then return nil end
        
        local ok, upvals = pcall(debug.getupvalues, func)
        if not ok or not upvals then return nil end
        
        for k, v in pairs(upvals) do
            if type(v) == "string" and (tonumber(v) ~= nil or #v > 10) then
                return v
            elseif type(v) == "number" then
                return tostring(v)
            elseif type(v) == "function" then
                local nested = scanUpvaluesForKey(v, depth + 1, maxDepth)
                if nested then return nested end
            end
        end
        return nil
    end

    local function getConnectionsForEvent(event)
        local connections = {}
        local success, conns = pcall(getconnections, event)
        if success and conns then
            for _, conn in ipairs(conns) do
                table.insert(connections, conn)
            end
        end
        return connections
    end

    local mouse = player:GetMouse()
    local mouseEvents = {mouse.Button1Down, mouse.Button2Down}
    for _, event in ipairs(mouseEvents) do
        for _, conn in ipairs(getConnectionsForEvent(event)) do
            local func = conn.Function
            if func then
                local key = scanUpvaluesForKey(func)
                if key then return key end
            end
        end
    end

    local touchEvents = {
        UserInputService.TouchTap, UserInputService.TouchTapInWorld,
        UserInputService.TouchLongPress, UserInputService.TouchMoved,
        UserInputService.TouchPan, UserInputService.TouchPinch,
        UserInputService.TouchRotate, UserInputService.TouchSwipe,
        UserInputService.TouchStarted, UserInputService.TouchEnded
    }
    for _, event in ipairs(touchEvents) do
        for _, conn in ipairs(getConnectionsForEvent(event)) do
            local func = conn.Function
            if func then
                local key = scanUpvaluesForKey(func)
                if key then return key end
            end
        end
    end

    local inputEvents = {UserInputService.InputBegan, UserInputService.InputEnded, UserInputService.InputChanged}
    for _, event in ipairs(inputEvents) do
        for _, conn in ipairs(getConnectionsForEvent(event)) do
            local func = conn.Function
            if func then
                local key = scanUpvaluesForKey(func)
                if key then return key end
            end
        end
    end

    return nil
end

-- ============================================
-- FLAG & BLOCK CHECKS
-- ============================================

local function hasServerFlag(part)
    if not part then return false end
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("Model") then
            return true
        end
    end
    return false
end

local function checkFlagged(part)
    if hasServerFlag(part) then
        localFlags[part] = nil
        return true
    end
    local localTime = localFlags[part]
    if localTime and (os.clock() - localTime < 1.5) then
        return true
    end
    return false
end

local function checkBlocked(part)
    return checkFlagged(part) or deducedBombs[part] == true
end

-- ============================================
-- ESP SYSTEM
-- ============================================

local function clearESP()
    espFolder:ClearAllChildren()
end

local function updateESP(safeTiles, borderProbabilities)
    clearESP()
    if not espActive then return end
    
    -- Deduced bombs
    for part in pairs(deducedBombs) do
        if part and part.Parent and not part:FindFirstChild("NumberGui") and not hasServerFlag(part) then
            local box = Instance.new("SelectionBox")
            box.Adornee = part
            box.Color3 = espBombColor
            box.LineThickness = 0.06
            box.SurfaceColor3 = espBombColor
            box.SurfaceTransparency = 0.45
            box.Parent = espFolder
        end
    end
    
    -- Deduced safe tiles
    for _, cell in pairs(safeTiles) do
        if cell.part and cell.part.Parent and not cell.part:FindFirstChild("NumberGui") and not hasServerFlag(cell.part) then
            local box = Instance.new("SelectionBox")
            box.Adornee = cell.part
            box.Color3 = espSafeColor
            box.LineThickness = 0.06
            box.SurfaceColor3 = espSafeColor
            box.SurfaceTransparency = 0.45
            box.Parent = espFolder
        end
    end
    
    -- Yellow/Orange outline + fill + BillboardGui percent text for uncertain tiles
    for part, P in pairs(borderProbabilities) do
        if part and part.Parent and not part:FindFirstChild("NumberGui") and not hasServerFlag(part) then
            local color = espUncertainMed
            if P < 0.35 then
                color = espUncertainLow
            elseif P > 0.65 then
                color = espUncertainHigh
            end
            
            local box = Instance.new("SelectionBox")
            box.Adornee = part
            box.Color3 = color
            box.LineThickness = 0.05
            box.SurfaceColor3 = color
            box.SurfaceTransparency = 0.6
            box.Parent = espFolder
            
            -- Floating percentage billboard GUI
            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 100, 0, 40)
            bb.AlwaysOnTop = true
            bb.Adornee = part
            bb.StudsOffset = Vector3.new(0, 3, 0)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextSize = 26
            label.TextColor3 = color
            label.Font = Enum.Font.GothamBold
            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            label.Text = string.format("%.0f%%", P * 100)
            label.Parent = bb
            
            bb.Parent = espFolder
        end
    end
end

-- ============================================
-- GRID INITIALIZATION
-- ============================================

local function initGrid()
    grid = {}
    xToCol = {}
    zToRow = {}
    localFlags = {}
    deducedBombs = {}
    clearESP()
    
    local flag = workspace:FindFirstChild("Flag")
    local partsFolder = flag and flag:FindFirstChild("Parts")
    local parts = partsFolder and partsFolder:GetChildren()
    if not parts then return end
    
    local xCoords = {}
    local zCoords = {}
    
    for _, p in ipairs(parts) do
        xCoords[math.floor(p.Position.X + 0.5)] = true
        zCoords[math.floor(p.Position.Z + 0.5)] = true
    end
    
    local sortedX = {}
    for x in pairs(xCoords) do table.insert(sortedX, x) end
    table.sort(sortedX)
    
    local sortedZ = {}
    for z in pairs(zCoords) do table.insert(sortedZ, z) end
    table.sort(sortedZ)
    
    for col, x in ipairs(sortedX) do xToCol[x] = col end
    for row, z in ipairs(sortedZ) do zToRow[z] = row end
    
    W = #sortedX
    H = #sortedZ
    
    for col = 1, W do
        grid[col] = {}
        for row = 1, H do
            grid[col][row] = {
                part = nil,
                isOpened = false,
                isFlagged = false,
                isBlocked = false,
                value = 0,
                col = col,
                row = row
            }
        end
    end
    
    for _, p in ipairs(parts) do
        local x = math.floor(p.Position.X + 0.5)
        local z = math.floor(p.Position.Z + 0.5)
        local col = xToCol[x]
        local row = zToRow[z]
        if col and row then
            grid[col][row].part = p
        end
    end
    
    -- Populate deducedBombs with existing flags on board at the start
    for col = 1, W do
        for row = 1, H do
            local cell = grid[col][row]
            if cell.part and hasServerFlag(cell.part) then
                deducedBombs[cell.part] = true
                cell.isFlagged = true
                cell.isBlocked = true
            end
        end
    end
    
    print("Grid mapped successfully: " .. W .. "x" .. H)
end

local function checkGridValid()
    if W == 0 or H == 0 then return false end
    for col = 1, W do
        if not grid[col] then return false end
        for row = 1, H do
            local cell = grid[col][row]
            if not cell or not cell.part or not cell.part:IsDescendantOf(workspace) then
                return false
            end
        end
    end
    return true
end

-- ============================================
-- BOARD SCANNING
-- ============================================

local function scanBoard()
    local state = {}
    for col = 1, W do
        state[col] = {}
        for row = 1, H do
            local cell = grid[col][row]
            local isOpened = false
            local value = 0
            local isFlagged = false
            local isBlocked = false
            
            if cell.part then
                isOpened = cell.part:FindFirstChild("NumberGui") ~= nil
                if isOpened then
                    local label = cell.part.NumberGui:FindFirstChild("TextLabel")
                    local text = label and label.Text or ""
                    value = tonumber(text) or 0
                end
                isFlagged = checkFlagged(cell.part)
                isBlocked = checkBlocked(cell.part)
            end
            
            state[col][row] = {
                isOpened = isOpened,
                value = value,
                isFlagged = isFlagged,
                isBlocked = isBlocked
            }
        end
    end
    return state
end

-- ============================================
-- PATHFINDING
-- ============================================

local function getCurrentPlayerGrid()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil, nil end
    
    local nearestCol, nearestRow = nil, nil
    local minDist = math.huge
    
    for col = 1, W do
        for row = 1, H do
            local cell = grid[col][row]
            if cell.part then
                local dist = (cell.part.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearestCol = col
                    nearestRow = row
                end
            end
        end
    end
    return nearestCol, nearestRow
end

local function findPath(startCol, startRow, targetCol, targetRow)
    local queue = {{startCol, startRow, {}}}
    local visited = {}
    visited[startCol .. "_" .. startRow] = true
    
    while #queue > 0 do
        local curr = table.remove(queue, 1)
        local c, r, path = curr[1], curr[2], curr[3]
        
        if c == targetCol and r == targetRow then
            return path
        end
        
        local dirs = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
        for _, dir in ipairs(dirs) do
            local nc = c + dir[1]
            local nr = r + dir[2]
            local key = nc .. "_" .. nr
            
            if nc >= 1 and nc <= W and nr >= 1 and nr <= H and not visited[key] then
                local neighbor = grid[nc][nr]
                local isFlaggedOnServer = hasServerFlag(neighbor.part)
                if neighbor.isOpened or isFlaggedOnServer or (nc == targetCol and nr == targetRow) then
                    visited[key] = true
                    local newPath = {}
                    for _, p in ipairs(path) do table.insert(newPath, p) end
                    table.insert(newPath, neighbor.part)
                    table.insert(queue, {nc, nr, newPath})
                end
            end
        end
    end
    return nil
end

local function getConnectedComponent(startCol, startRow)
    local queue = {{startCol, startRow}}
    local visited = {}
    visited[startCol .. "_" .. startRow] = true
    local component = {}
    
    while #queue > 0 do
        local curr = table.remove(queue, 1)
        local c, r = curr[1], curr[2]
        table.insert(component, grid[c][r])
        
        local dirs = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}}
        for _, dir in ipairs(dirs) do
            local nc = c + dir[1]
            local nr = r + dir[2]
            local key = nc .. "_" .. nr
            
            if nc >= 1 and nc <= W and nr >= 1 and nr <= H and not visited[key] then
                local neighbor = grid[nc][nr]
                local isFlaggedOnServer = hasServerFlag(neighbor.part)
                if neighbor.isOpened or isFlaggedOnServer then
                    visited[key] = true
                    table.insert(queue, {nc, nr})
                end
            end
        end
    end
    return component
end

local function getLocalGuessCandidates(pCol, pRow)
    local component = getConnectedComponent(pCol, pRow)
    local candidates = {}
    local seen = {}
    
    for _, cell in ipairs(component) do
        local dirs = {
            {1, 0}, {-1, 0}, {0, 1}, {0, -1},
            {1, 1}, {-1, 1}, {1, -1}, {-1, -1}
        }
        for _, dir in ipairs(dirs) do
            local nc = cell.col + dir[1]
            local nr = cell.row + dir[2]
            if nc >= 1 and nc <= W and nr >= 1 and nr <= H then
                local neighbor = grid[nc][nr]
                if not neighbor.isOpened and not neighbor.isBlocked then
                    local key = nc .. "_" .. nr
                    if not seen[key] then
                        seen[key] = true
                        table.insert(candidates, neighbor)
                    end
                end
            end
        end
    end
    return candidates
end

-- ============================================
-- SOLVER ENGINE
-- ============================================

local function solveEquations(safeTiles, borderProbabilities)
    local clues = {}
    local borderMap = {}
    local borderList = {}
    
    for col = 1, W do
        for row = 1, H do
            local cell = grid[col][row]
            if cell.isOpened and cell.value > 0 then
                local unopened = {}
                local flaggedCount = 0
                for dc = -1, 1 do
                    for dr = -1, 1 do
                        if not (dc == 0 and dr == 0) then
                            local nc = col + dc
                            local nr = row + dr
                            if nc >= 1 and nc <= W and nr >= 1 and nr <= H then
                                local nCell = grid[nc][nr]
                                if nCell.isFlagged then
                                    flaggedCount = flaggedCount + 1
                                elseif not nCell.isOpened then
                                    table.insert(unopened, nCell)
                                end
                            end
                        end
                    end
                end
                
                if #unopened > 0 then
                    table.insert(clues, {
                        cell = cell,
                        unopened = unopened,
                        target = cell.value - flaggedCount
                    })
                    for _, nCell in ipairs(unopened) do
                        if not borderMap[nCell] then
                            borderMap[nCell] = true
                            table.insert(borderList, nCell)
                        end
                    end
                end
            end
        end
    end
    
    if #borderList == 0 then return end
    
    -- Group equations and variables into independent connected components
    local components = {}
    local visitedClues = {}
    local visitedVars = {}
    
    for _, clue in ipairs(clues) do
        if not visitedClues[clue] then
            local compClues = {}
            local compVars = {}
            local queue = {clue}
            visitedClues[clue] = true
            
            while #queue > 0 do
                local currClue = table.remove(queue, 1)
                table.insert(compClues, currClue)
                
                for _, nCell in ipairs(currClue.unopened) do
                    if not visitedVars[nCell] then
                        visitedVars[nCell] = true
                        table.insert(compVars, nCell)
                        
                        for _, otherClue in ipairs(clues) do
                            if not visitedClues[otherClue] then
                                local contains = false
                                for _, c in ipairs(otherClue.unopened) do
                                    if c == nCell then contains = true break end
                                end
                                if contains then
                                    visitedClues[otherClue] = true
                                    table.insert(queue, otherClue)
                                end
                            end
                        end
                    end
                end
            end
            table.insert(components, {clues = compClues, vars = compVars})
        end
    end
    
    -- Solve each independent component
    for _, comp in ipairs(components) do
        local vars = comp.vars
        local compClues = comp.clues
        
        -- Cap variables to 20 to prevent performance lag
        if #vars <= 20 then
            local solutions = {}
            local currentAssignment = {}
            
            local function backtrack(varIndex)
                if varIndex > #vars then
                    -- Verify clues
                    for _, clue in ipairs(compClues) do
                        local sum = 0
                        for _, nCell in ipairs(clue.unopened) do
                            sum = sum + (currentAssignment[nCell] or 0)
                        end
                        if sum ~= clue.target then return end
                    end
                    -- Valid config found!
                    local sol = {}
                    for k, v in pairs(currentAssignment) do
                        sol[k] = v
                    end
                    table.insert(solutions, sol)
                    return
                end
                
                local currentVar = vars[varIndex]
                
                -- Backtracking Pruning
                for _, clue in ipairs(compClues) do
                    local sum = 0
                    local unassigned = 0
                    for _, nCell in ipairs(clue.unopened) do
                        local assign = currentAssignment[nCell]
                        if assign then
                            sum = sum + assign
                        else
                            unassigned = unassigned + 1
                        end
                    end
                    if sum > clue.target or sum + unassigned < clue.target then
                        return
                    end
                end
                
                -- Branch 0
                currentAssignment[currentVar] = 0
                backtrack(varIndex + 1)
                
                -- Branch 1
                currentAssignment[currentVar] = 1
                backtrack(varIndex + 1)
                
                currentAssignment[currentVar] = nil
            end
            
            backtrack(1)
            
            -- Process assignment probabilities across all valid configurations
            if #solutions > 0 then
                for _, var in ipairs(vars) do
                    local bombCount = 0
                    for _, sol in ipairs(solutions) do
                        if sol[var] == 1 then
                            bombCount = bombCount + 1
                        end
                    end
                    
                    local P = bombCount / #solutions
                    if P == 0 then
                        safeTiles[var.col .. "_" .. var.row] = var
                    elseif P == 1 then
                        deducedBombs[var.part] = true
                    else
                        borderProbabilities[var.part] = P
                    end
                end
            end
        end
    end
end

local function updateDeductions()
    -- Clear opened cells from bomb/flag caches
    for col = 1, W do
        for row = 1, H do
            local cell = grid[col][row]
            if cell.part then
                local isOpened = cell.part:FindFirstChild("NumberGui") ~= nil
                if isOpened then
                    deducedBombs[cell.part] = nil
                    localFlags[cell.part] = nil
                end
            end
        end
    end

    -- Double scan for consistency
    local state1 = scanBoard()
    task.wait(0.05)
    local state2 = scanBoard()
    
    local stable = true
    for col = 1, W do
        for row = 1, H do
            local c1 = state1[col][row]
            local c2 = state2[col][row]
            if c1.isOpened ~= c2.isOpened or c1.value ~= c2.value or c1.isFlagged ~= c2.isFlagged or c1.isBlocked ~= c2.isBlocked then
                stable = false
                break
            end
        end
        if not stable then break end
    end
    
    if not stable then
        return false
    end
    
    -- Apply stable state
    for col = 1, W do
        for row = 1, H do
            local cell = grid[col][row]
            local st = state1[col][row]
            cell.isOpened = st.isOpened
            cell.value = st.value
            cell.isFlagged = st.isFlagged
            cell.isBlocked = st.isBlocked
        end
    end
    
    local safeTiles = {}
    local borderProbabilities = {}
    local deducedNewBomb = false
    
    -- Global constraint solver
    local totalUnopened = {}
    local totalFlagged = 0
    for col = 1, W do
        for row = 1, H do
            local cell = grid[col][row]
            if cell.part then
                if cell.isFlagged then
                    totalFlagged = totalFlagged + 1
                elseif not cell.isOpened then
                    table.insert(totalUnopened, cell)
                end
            end
        end
    end
    
    local minesVal = ReplicatedStorage:FindFirstChild("Info") and ReplicatedStorage.Info:FindFirstChild("Mines") and ReplicatedStorage.Info.Mines.Value or 0
    local remainingMines = minesVal - totalFlagged
    
    if #totalUnopened > 0 then
        if #totalUnopened == remainingMines then
            for _, cell in ipairs(totalUnopened) do
                if not deducedBombs[cell.part] then
                    print("Global Constraint: Deduced bomb at (" .. cell.col .. ", " .. cell.row .. ")")
                    deducedBombs[cell.part] = true
                    cell.isFlagged = true
                    cell.isBlocked = true
                    deducedNewBomb = true
                end
            end
        elseif remainingMines == 0 then
            for _, cell in ipairs(totalUnopened) do
                safeTiles[cell.col .. "_" .. cell.row] = cell
            end
        end
    end
    
    -- Matrix & Probability Solver
    if not deducedNewBomb then
        solveEquations(safeTiles, borderProbabilities)
        
        -- Fallback single-cell rules
        for col = 1, W do
            for row = 1, H do
                local cell = grid[col][row]
                if cell.isOpened and cell.value > 0 then
                    local neighbors = {}
                    local flaggedNeighbors = 0
                    local unopenedNeighbors = {}
                    
                    for dc = -1, 1 do
                        for dr = -1, 1 do
                            if not (dc == 0 and dr == 0) then
                                import_nc = col + dc
                                import_nr = row + dr
                                if import_nc >= 1 and import_nc <= W and import_nr >= 1 and import_nr <= H then
                                    local nCell = grid[import_nc][import_nr]
                                    table.insert(neighbors, nCell)
                                    if nCell.isFlagged then
                                        flaggedNeighbors = flaggedNeighbors + 1
                                    elseif not nCell.isOpened then
                                        table.insert(unopenedNeighbors, nCell)
                                    end
                                end
                            end
                        end
                    end
                    
                    if cell.value - flaggedNeighbors == #unopenedNeighbors and #unopenedNeighbors > 0 then
                        for _, nCell in ipairs(unopenedNeighbors) do
                            if not deducedBombs[nCell.part] then
                                print("Deduced bomb at (" .. nCell.col .. ", " .. nCell.row .. ")")
                                deducedBombs[nCell.part] = true
                                nCell.isFlagged = true
                                nCell.isBlocked = true
                                deducedNewBomb = true
                            end
                        end
                    end
                    
                    if cell.value == flaggedNeighbors and #unopenedNeighbors > 0 then
                        for _, nCell in ipairs(unopenedNeighbors) do
                            if not nCell.isFlagged and not nCell.isOpened then
                                safeTiles[nCell.col .. "_" .. nCell.row] = nCell
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Render ESP
    if espActive then
        updateESP(safeTiles, borderProbabilities)
    end
    
    return true, safeTiles, borderProbabilities, deducedNewBomb
end

-- ============================================
-- MOVEMENT & WALKING
-- ============================================

local function walkTo(part, isFinalTarget)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    
    hum.WalkSpeed = customWalkSpeed
    local targetPos = Vector3.new(part.Position.X, root.Position.Y, part.Position.Z)
    
    hum:MoveTo(targetPos)
    
    local startT = os.clock()
    local targetDist = isFinalTarget and 1.2 or 3.5
    
    -- Loop to wait until close enough, updating MoveTo only occasionally to prevent robotic stuttering
    local lastMoveToUpdate = os.clock()
    while autoWalkActive do
        if not root or not root.Parent then break end
        local dist = (root.Position - targetPos).Magnitude
        if dist <= targetDist then
            break
        end
        if os.clock() - startT > 2.5 then -- Timeout fallback
            break
        end
        
        -- Refresh MoveTo occasionally (e.g. every 0.3s) just in case character got blocked
        if os.clock() - lastMoveToUpdate >= 0.3 then
            hum:MoveTo(targetPos)
            lastMoveToUpdate = os.clock()
        end
        task.wait(0.02)
    end
end

local function walkPath(path)
    local len = #path
    for i, part in ipairs(path) do
        if not autoWalkActive then break end
        local isFinalTarget = (i == len)
        walkTo(part, isFinalTarget)
    end
end

-- ============================================
-- CONSOLIDATED BOARD MANAGER & EVENT SYSTEM
-- ============================================

-- Unified task manager to eliminate race conditions between auto flag, auto walk, and ESP
task.spawn(function()
    while true do
        task.wait(0.02)
        
        -- Keep grid mapped and synchronized if any active feature is enabled
        if autoWalkActive or autoFlagActive or espActive then
            local gameRunningVal = ReplicatedStorage:FindFirstChild("Info") and ReplicatedStorage.Info:FindFirstChild("GameRunning") and ReplicatedStorage.Info.GameRunning.Value
            if not gameRunningVal then
                localFlags = {}
                deducedBombs = {}
                clearESP()
                task.wait(0.5)
                continue
            end

            -- Safely load grid map
            if not checkGridValid() then
                initGrid()
                task.wait(0.1)
                continue
            end

            -- Only calculate deductions if autoWalkActive/autoFlagActive are on, or ESP is active and enough time has elapsed
            local shouldUpdate = autoWalkActive or autoFlagActive or (espActive and (os.clock() - lastEspUpdateTime >= espRefreshInterval))
            
            if shouldUpdate then
                if espActive then
                    lastEspUpdateTime = os.clock() -- Update immediately to prevent tight-loop scanning on calculation errors
                    espCleared = false
                end
                local success, safeTiles, borderProbabilities, deducedNewBomb = updateDeductions()
                if success then

                    -- Auto Flag Logic
                    if autoFlagActive then
                        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        local key = getSecretKey()
                        if root and key then
                            for part in pairs(deducedBombs) do
                                if not checkFlagged(part) then
                                    local dist = (part.Position - root.Position).Magnitude
                                    if dist < autoFlagDistance then
                                        if autoFlagDelay == 0 then
                                            ReplicatedStorage.Events.FlagEvents.PlaceFlag:FireServer(part, key, true)
                                            localFlags[part] = os.clock()
                                        elseif os.clock() - lastFlagTime >= autoFlagDelay then
                                            ReplicatedStorage.Events.FlagEvents.PlaceFlag:FireServer(part, key, true)
                                            localFlags[part] = os.clock()
                                            lastFlagTime = os.clock()
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end

                    -- Auto Walk Logic
                    if autoWalkActive and not deducedNewBomb then
                        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        local pCol, pRow = getCurrentPlayerGrid()
                        if root and pCol and pRow then
                            local openedCount = 0
                            for col = 1, W do
                                for row = 1, H do
                                    if grid[col][row].isOpened then
                                        openedCount = openedCount + 1
                                    end
                                end
                            end

                            -- Start the game by clicking center
                            if openedCount == 0 then
                                local midCol = math.floor(W / 2) + 1
                                local midRow = math.floor(H / 2) + 1
                                local targetPart = grid[midCol][midRow].part
                                if targetPart then
                                    walkTo(targetPart, true)
                                    task.wait(0.3)
                                end
                            else
                                local key = getSecretKey()
                                if key then
                                    -- Walk to safe tile
                                    local targetCell = nil
                                    local bestPath = nil
                                    local minPathLen = math.huge
                                    
                                    for _, cell in pairs(safeTiles) do
                                        local path = findPath(pCol, pRow, cell.col, cell.row)
                                        if path and #path < minPathLen then
                                            minPathLen = #path
                                            targetCell = cell
                                            bestPath = path
                                        end
                                    end
                                    
                                    if bestPath and targetCell then
                                        walkPath(bestPath)
                                        -- Wait briefly for the stepped tile to register open
                                        local startWait = os.clock()
                                        while not targetCell.part:FindFirstChild("NumberGui") and os.clock() - startWait < 1.0 and autoWalkActive do
                                            task.wait(0.05)
                                        end
                                    else
                                        -- Handle stuck states: calculate optimal probability guess
                                        local bestGuessCell = nil
                                        local minProb = math.huge
                                        
                                        for part, P in pairs(borderProbabilities) do
                                            local x = math.floor(part.Position.X + 0.5)
                                            local z = math.floor(part.Position.Z + 0.5)
                                            local col = xToCol[x]
                                            local row = zToRow[z]
                                            if col and row then
                                                local cell = grid[col][row]
                                                if P < minProb then
                                                    minProb = P
                                                    bestGuessCell = cell
                                                end
                                            end
                                        end
                                        
                                        if bestGuessCell then
                                            local path = findPath(pCol, pRow, bestGuessCell.col, bestGuessCell.row)
                                            if path then
                                                walkPath(path)
                                            else
                                                walkTo(bestGuessCell.part, true)
                                            end
                                            local startWait = os.clock()
                                            while not bestGuessCell.part:FindFirstChild("NumberGui") and os.clock() - startWait < 1.0 and autoWalkActive do
                                                task.wait(0.05)
                                            end
                                        else
                                            -- Final fallback: local random guess candidates
                                            local candidates = getLocalGuessCandidates(pCol, pRow)
                                            if #candidates > 0 then
                                                local guessCell = candidates[math.random(1, #candidates)]
                                                local path = findPath(pCol, pRow, guessCell.col, guessCell.row)
                                                if path then
                                                    walkPath(path)
                                                else
                                                    walkTo(guessCell.part, true)
                                                end
                                                local startWait = os.clock()
                                                while not guessCell.part:FindFirstChild("NumberGui") and os.clock() - startWait < 1.0 and autoWalkActive do
                                                    task.wait(0.05)
                                                end
                                            else
                                                -- No possible steps found
                                                autoWalkActive = false
                                                if AutoWalkToggle then AutoWalkToggle:Set(false) end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            if not espCleared then
                clearESP()
                espCleared = true
            end
            task.wait(0.25)
        end
    end
end)

-- ============================================
-- MOBILE-COMPATIBLE FLOAT TOGGLE BUTTON
-- ============================================

local mobileGui = Instance.new("ScreenGui")
mobileGui.Name = "MinesweeperMobileToggle"
mobileGui.ResetOnSpawn = false

local function parentToGui(gui)
    local success = pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end)
    if not success then
        gui.Parent = player:WaitForChild("PlayerGui")
    end
end
parentToGui(mobileGui)

local mainButton = Instance.new("TextButton")
mainButton.Name = "ToggleButton"
mainButton.Size = UDim2.new(0, 55, 0, 55)
mainButton.Position = UDim2.new(0.05, 0, 0.25, 0)
mainButton.BackgroundColor3 = Color3.fromRGB(24, 24, 37)
mainButton.Text = "Menu"
mainButton.TextColor3 = Color3.fromRGB(205, 214, 244)
mainButton.Font = Enum.Font.GothamBold
mainButton.TextSize = 13
mainButton.BorderSizePixel = 0
mainButton.Parent = mobileGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.5, 0)
corner.Parent = mainButton

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(137, 180, 250)
stroke.Thickness = 2
stroke.Parent = mainButton

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 46)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(17, 17, 27))
})
gradient.Rotation = 45
gradient.Parent = mainButton

-- Make the floating button draggable
local dragToggle = nil
local dragSpeed = 0.15
local dragStart = nil
local startPos = nil

local function updateInput(input)
    local delta = input.Position - dragStart
    local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    TweenService:Create(mainButton, TweenInfo.new(dragSpeed), {Position = position}):Play()
end

mainButton.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragToggle = true
        dragStart = input.Position
        startPos = mainButton.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragToggle = false
            end
        end)
    end
end)

mainButton.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        if dragToggle then
            updateInput(input)
        end
    end
end)

local function toggleRayfieldVisible()
    local found = false
    local robloxGui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
    if robloxGui then
        local rayfield = robloxGui:FindFirstChild("Rayfield")
        if rayfield and rayfield:IsA("ScreenGui") then
            rayfield.Enabled = not rayfield.Enabled
            found = true
        end
    end
    if not found then
        local targets = {game:GetService("CoreGui"), player:FindFirstChild("PlayerGui")}
        for _, target in ipairs(targets) do
            if target then
                local ray = target:FindFirstChild("Rayfield", true)
                if ray and ray:IsA("ScreenGui") then
                    ray.Enabled = not ray.Enabled
                    found = true
                    break
                end
            end
        end
    end
    return found
end

mainButton.MouseButton1Click:Connect(function()
    local originalSize = mainButton.Size
    TweenService:Create(mainButton, TweenInfo.new(0.08), {Size = UDim2.new(0, 48, 0, 48)}):Play()
    task.wait(0.08)
    TweenService:Create(mainButton, TweenInfo.new(0.08), {Size = originalSize}):Play()
    toggleRayfieldVisible()
end)

-- ============================================
-- MOBILE-COMPATIBLE FLY MODE WITH ON-SCREEN CONTROLS
-- ============================================

local upButton = Instance.new("TextButton")
local downButton = Instance.new("TextButton")
local flyControlsActive = false
local verticalInput = 0 -- -1 for down, 1 for up, 0 for hover/none

local function createFlyControls()
    if flyControlsActive then return end
    flyControlsActive = true
    
    upButton.Name = "FlyUp"
    upButton.Size = UDim2.new(0, 50, 0, 50)
    upButton.Position = UDim2.new(0.85, 0, 0.5, -60)
    upButton.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
    upButton.Text = "▲"
    upButton.TextColor3 = Color3.fromRGB(205, 214, 244)
    upButton.Font = Enum.Font.GothamBold
    upButton.TextSize = 20
    upButton.BorderSizePixel = 0
    upButton.Parent = mobileGui
    
    local c1 = Instance.new("UICorner")
    c1.CornerRadius = UDim.new(0.3, 0)
    c1.Parent = upButton
    
    local s1 = Instance.new("UIStroke")
    s1.Color = Color3.fromRGB(137, 220, 143)
    s1.Thickness = 1.5
    s1.Parent = upButton

    downButton.Name = "FlyDown"
    downButton.Size = UDim2.new(0, 50, 0, 50)
    downButton.Position = UDim2.new(0.85, 0, 0.5, 10)
    downButton.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
    downButton.Text = "▼"
    downButton.TextColor3 = Color3.fromRGB(205, 214, 244)
    downButton.Font = Enum.Font.GothamBold
    downButton.TextSize = 20
    downButton.BorderSizePixel = 0
    downButton.Parent = mobileGui
    
    local c2 = Instance.new("UICorner")
    c2.CornerRadius = UDim.new(0.3, 0)
    c2.Parent = downButton
    
    local s2 = Instance.new("UIStroke")
    s2.Color = Color3.fromRGB(243, 139, 168)
    s2.Thickness = 1.5
    s2.Parent = downButton
    
    upButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            verticalInput = 1
            upButton.BackgroundColor3 = Color3.fromRGB(137, 220, 143)
            upButton.TextColor3 = Color3.fromRGB(17, 17, 27)
        end
    end)
    
    upButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if verticalInput == 1 then verticalInput = 0 end
            upButton.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
            upButton.TextColor3 = Color3.fromRGB(205, 214, 244)
        end
    end)

    downButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            verticalInput = -1
            downButton.BackgroundColor3 = Color3.fromRGB(243, 139, 168)
            downButton.TextColor3 = Color3.fromRGB(17, 17, 27)
        end
    end)
    
    downButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if verticalInput == -1 then verticalInput = 0 end
            downButton.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
            downButton.TextColor3 = Color3.fromRGB(205, 214, 244)
        end
    end)
end

local function destroyFlyControls()
    if not flyControlsActive then return end
    flyControlsActive = false
    upButton.Parent = nil
    downButton.Parent = nil
    verticalInput = 0
end

local function startFlying()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    
    if flyGyro then flyGyro:Destroy() end
    if flyVelocity then flyVelocity:Destroy() end
    
    flyGyro = Instance.new("BodyGyro")
    flyGyro.P = 9e4
    flyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyGyro.cframe = root.CFrame
    flyGyro.Parent = root
    
    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.velocity = Vector3.new(0, 0.1, 0)
    flyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
    flyVelocity.Parent = root
    
    hum.PlatformStand = true
    
    -- Spawn floating vertical buttons for touch compatibility
    createFlyControls()
    
    task.spawn(function()
        while flying and player.Character and root and hum do
            local camera = workspace.CurrentCamera
            local moveDir = Vector3.new(0, 0, 0)
            
            -- Mobile virtual thumbstick direction
            local joystickDir = hum.MoveDirection
            if joystickDir.Magnitude > 0.1 then
                moveDir = joystickDir
            else
                -- Keyboard fallback
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDir = moveDir + camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDir = moveDir - camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDir = moveDir - camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDir = moveDir + camera.CFrame.RightVector
                end
            end
            
            -- Constrain movement to XZ plane relative to the camera face
            moveDir = Vector3.new(moveDir.X, 0, moveDir.Z)
            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit
            end
            
            -- Ascend / Descend controls (from physical keys or touch overlay buttons)
            local currentVertical = verticalInput
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                currentVertical = 1
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                currentVertical = -1
            end
            
            local targetVelocity = moveDir * flySpeed
            if currentVertical ~= 0 then
                targetVelocity = targetVelocity + Vector3.new(0, currentVertical * flySpeed, 0)
            end
            
            if targetVelocity.Magnitude > 0 then
                flyVelocity.velocity = targetVelocity
            else
                flyVelocity.velocity = Vector3.new(0, 0.1, 0)
            end
            
            flyGyro.cframe = camera.CFrame
            task.wait()
        end
        
        if flyGyro then flyGyro:Destroy(); flyGyro = nil end
        if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
        if hum then hum.PlatformStand = false end
        destroyFlyControls()
    end)
end

local function stopFlying()
    if flyGyro then flyGyro:Destroy(); flyGyro = nil end
    if flyVelocity then flyVelocity:Destroy(); flyVelocity = nil end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
    destroyFlyControls()
end

local function toggleFly(val)
    flying = val
    if flying then
        if autoWalkActive then
            autoWalkActive = false
            if AutoWalkToggle then AutoWalkToggle:Set(false) end
        end
        startFlying()
        notify("Fly Mode", "Flying ON")
    else
        stopFlying()
        notify("Fly Mode", "Flying OFF")
    end
end

-- ============================================
-- INFINITE JUMP & CHARACTER HANDLING
-- ============================================

UserInputService.JumpRequest:Connect(function()
    if infiniteJump then
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

local function onCharacterAdded(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.UseJumpPower = true
        hum.WalkSpeed = customWalkSpeed
        hum.JumpPower = customJumpPower
    end
    if flying then
        task.spawn(startFlying)
    end
end

if player.Character then
    task.spawn(onCharacterAdded, player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- ============================================
-- RAYFIELD UI SETUP
-- ============================================

-- Build key array with dynamic + static variants
local keyArray = {STATIC_BACKUP_KEY, STATIC_BACKUP_KEY:lower()}
if dynamicKey and dynamicKey ~= STATIC_BACKUP_KEY then
    table.insert(keyArray, dynamicKey)
    table.insert(keyArray, dynamicKey:lower())
end

local Window = Rayfield:CreateWindow({
    Name = "Minesweeper Bot & ESP",
    LoadingTitle = "Minesweeper Suite",
    LoadingSubtitle = "by JawirHub",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = true,
    
    Discord = {
        Enabled = true,
        Invite = "gfqDhjMjtM",
        RememberJoins = false
    },
    
    KeySystem = USE_KEY_SYSTEM,
    KeySettings = {
        Title = "Minesweeper Bot Key",
        Subtitle = "Verification Screen",
        Note = "Key is in discord.gg/gfqDhjMjtM (copied to clipboard automatically!)",
        FileName = "MinesweeperBotKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = keyArray
    }
})

-- Show immediate invite copied notification on verification success
notify("Welcome!", "Key verified. Join discord.gg/gfqDhjMjtM to support!")

-- Tab 1: Home
local HomeTab = Window:CreateTab("Home", "home")

HomeTab:CreateParagraph({
    Title = "Minesweeper Solver Suite",
    Content = "Full Solver Bot & ESP edition using Rayfield UI. Press RightShift or tap the floating 'Menu' button to toggle UI visibility. Mobile thumbstick fully supported!"
})

HomeTab:CreateButton({
    Name = "Copy Discord Invite Link",
    Callback = copyDiscord
})

-- Refresh dynamic key button
HomeTab:CreateButton({
    Name = "Refresh Dynamic Key",
    Callback = function()
        local newKey = fetchDynamicKey()
        notify("Key Refreshed", "New key: " .. newKey:sub(1, 10) .. "...")
    end
})

-- Shut down UI completely
local function killUI()
    autoWalkActive = false
    autoFlagActive = false
    espActive = false
    flying = false
    infiniteJump = false
    stopFlying()
    clearESP()
    
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
        hum.UseJumpPower = false
    end
    
    if espFolder then
        espFolder:Destroy()
    end

    if mobileGui then
        mobileGui:Destroy()
    end
    
    Rayfield:Destroy()
end

HomeTab:CreateButton({
    Name = "Kill UI / Close Script",
    Callback = killUI
})

-- Tab 2: Autobot
local BotTab = Window:CreateTab("Auto Bot", "bot")

local function setAutoWalk(val)
    autoWalkActive = val
    if autoWalkActive then
        if flying then
            flying = false
            stopFlying()
            if FlyToggle then FlyToggle:Set(false) end
        end
        initGrid()
        notify("Auto Walk", "Auto Walk toggled ON")
    else
        notify("Auto Walk", "Auto Walk toggled OFF")
    end
end

local function setAutoFlag(val)
    autoFlagActive = val
    if autoFlagActive then
        initGrid()
        notify("Auto Flag", "Auto Flag toggled ON")
    else
        notify("Auto Flag", "Auto Flag toggled OFF")
    end
end

AutoWalkToggle = BotTab:CreateToggle({
    Name = "Auto Walk",
    CurrentValue = false,
    Flag = "AutoWalkToggleVal",
    Callback = setAutoWalk
})

BotTab:CreateKeybind({
    Name = "Auto Walk Keybind",
    CurrentKeybind = "L",
    HoldToInteract = false,
    Flag = "AutoWalkKeybindVal",
    Callback = function()
        AutoWalkToggle:Set(not autoWalkActive)
    end
})

AutoFlagToggle = BotTab:CreateToggle({
    Name = "Auto Flag",
    CurrentValue = false,
    Flag = "AutoFlagToggleVal",
    Callback = setAutoFlag
})

BotTab:CreateKeybind({
    Name = "Auto Flag Keybind",
    CurrentKeybind = "P",
    HoldToInteract = false,
    Flag = "AutoFlagKeybindVal",
    Callback = function()
        AutoFlagToggle:Set(not autoFlagActive)
    end
})

BotTab:CreateSection("Auto Flag Customization")

BotTab:CreateSlider({
    Name = "Flag Delay (Milliseconds)",
    Range = {0, 2000},
    Increment = 50,
    CurrentValue = autoFlagDelayMs,
    Flag = "FlagDelayMsVal",
    Callback = function(val)
        autoFlagDelayMs = val
        autoFlagDelay = val / 1000
    end
})

BotTab:CreateSlider({
    Name = "Flag Distance (Studs) [Server Cap: 30]",
    Range = {5, 30},
    Increment = 1,
    CurrentValue = autoFlagDistance,
    Flag = "FlagDistanceStudsVal",
    Callback = function(val)
        autoFlagDistance = val
    end
})

-- Tab 3: ESP
local EspTab = Window:CreateTab("ESP", "eye")

ESPToggle = EspTab:CreateToggle({
    Name = "ESP Active",
    CurrentValue = false,
    Flag = "ESPActiveToggle",
    Callback = function(val)
        espActive = val
        if espActive then
            initGrid()
            notify("ESP Toggled", "ESP is now ACTIVE")
        else
            clearESP()
            notify("ESP Toggled", "ESP is now DISABLED")
        end
    end
})

EspTab:CreateKeybind({
    Name = "Toggle ESP Bind",
    CurrentKeybind = "M",
    HoldToInteract = false,
    Flag = "ESPKeybind",
    Callback = function()
        ESPToggle:Set(not espActive)
    end
})

EspTab:CreateSection("ESP Customization")

EspTab:CreateSlider({
    Name = "ESP Refresh Interval (Seconds)",
    Range = {0.1, 3},
    Increment = 0.1,
    CurrentValue = espRefreshInterval,
    Flag = "EspRefreshSecondsVal",
    Callback = function(val)
        espRefreshInterval = val
    end
})

EspTab:CreateSection("ESP Colors")

EspTab:CreateColorPicker({
    Name = "Safe Tile Color",
    Color = espSafeColor,
    Flag = "ColorSafePicker",
    Callback = function(color)
        espSafeColor = color
    end
})

EspTab:CreateColorPicker({
    Name = "Bomb Tile Color",
    Color = espBombColor,
    Flag = "ColorBombPicker",
    Callback = function(color)
        espBombColor = color
    end
})

EspTab:CreateColorPicker({
    Name = "Uncertain Low Risk Color (Yellow)",
    Color = espUncertainLow,
    Flag = "ColorLowPicker",
    Callback = function(color)
        espUncertainLow = color
    end
})

EspTab:CreateColorPicker({
    Name = "Uncertain Medium Risk Color (Orange)",
    Color = espUncertainMed,
    Flag = "ColorMedPicker",
    Callback = function(color)
        espUncertainMed = color
    end
})

EspTab:CreateColorPicker({
    Name = "Uncertain High Risk Color (Crimson)",
    Color = espUncertainHigh,
    Flag = "ColorHighPicker",
    Callback = function(color)
        espUncertainHigh = color
    end
})

-- Tab 4: Movement
local MoveTab = Window:CreateTab("Movement", "zap")

MoveTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 150},
    Increment = 1,
    CurrentValue = customWalkSpeed,
    Flag = "WalkSpeedVal",
    Callback = function(val)
        customWalkSpeed = val
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = customWalkSpeed
        end
    end
})

MoveTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = customJumpPower,
    Flag = "JumpPowerVal",
    Callback = function(val)
        customJumpPower = val
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = customJumpPower
        end
    end
})

MoveTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJumpToggle",
    Callback = function(val)
        infiniteJump = val
    end
})

MoveTab:CreateSection("Flight Utilities")

FlyToggle = MoveTab:CreateToggle({
    Name = "Fly Mode",
    CurrentValue = false,
    Flag = "FlyToggleVal",
    Callback = toggleFly
})

MoveTab:CreateKeybind({
    Name = "Fly Keybind",
    CurrentKeybind = "F",
    HoldToInteract = false,
    Flag = "FlyKeybindVal",
    Callback = function()
        FlyToggle:Set(not flying)
    end
})

MoveTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 150},
    Increment = 5,
    CurrentValue = flySpeed,
    Flag = "FlySpeedVal",
    Callback = function(val)
        flySpeed = val
    end
})

print("Minesweeper Full Suite Script with Mobile Support & Dynamic Keys Loaded!")
