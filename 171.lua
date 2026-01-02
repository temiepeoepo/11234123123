local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

--// =======================
--// AUTO-FIRE ON MANUAL EQUIP
--// =======================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
-- Ensure Event exists
local Event = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/UseItem")
local currentTool = nil
local fireConnection = nil
local FIRE_INTERVAL = 0.1 -- firing speed
-- Function to fire the tool at a player
local function fireToolAtPlayer(tool, target)
    if not tool or not target or not target.Character then return end
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if tool.Name == "Laser Cape" or tool.Name == "Web Slinger" then
        Event:FireServer(hrp.Position, hrp)
    elseif tool.Name == "Taser Gun" then
        Event:FireServer(hrp)
    elseif tool.Name == "Bee Launcher" then
        Event:FireServer(target)
    end
end
-- Get the closest player
local function getClosestPlayer()
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local closest, closestDist = nil, math.huge
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and other.Character then
            local ohrp = other.Character:FindFirstChild("HumanoidRootPart")
            if ohrp then
                local dist = (hrp.Position - ohrp.Position).Magnitude
                if dist < closestDist then
                    closestDist, closest = dist, other
                end
            end
        end
    end
    return closest
end
-- Stop previous fire loop
local function stopAutoFire()
    if fireConnection then
        fireConnection:Disconnect()
        fireConnection = nil
    end
end
-- Start auto-fire for a tool
local function startAutoFire(tool)
    stopAutoFire()
    fireConnection = RunService.Heartbeat:Connect(function()
        if not tool or tool.Parent ~= player.Character then
            stopAutoFire()
            return
        end
        local target = getClosestPlayer()
        if target then
            fireToolAtPlayer(tool, target)
        end
    end)
end
-- Poll for currently equipped tool
RunService.Heartbeat:Connect(function()
    local char = player.Character
    if not char then return end
    local equippedTool = nil
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            equippedTool = item
            break
        end
    end
    if equippedTool ~= currentTool then
        currentTool = equippedTool
        if currentTool then
            startAutoFire(currentTool)
        else
            stopAutoFire()
        end
    end
end)
-- =======================
-- PLAYER AURA TRACKER (ESP BOX + NAME)
-- =======================
local visuals = {}
local BOX_COLOR = Color3.fromRGB(0, 200, 200)
local NAME_COLOR = Color3.fromRGB(100, 200, 255)
local BOX_TRANSPARENCY = 0.2
local function addVisuals(target)
    if visuals[target] then return end
    if target == player then return end
    local function setup(char)
        if not char then return end
        if visuals[target] then
            for _, obj in ipairs(visuals[target]) do
                if obj and obj.Parent then obj:Destroy() end
            end
        end
        local added = {}
        local box = Instance.new("SelectionBox")
        box.Name = "PlayerBox"
        box.Adornee = char
        box.LineThickness = 0.08
        box.Color3 = BOX_COLOR
        box.SurfaceTransparency = BOX_TRANSPARENCY
        box.Transparency = BOX_TRANSPARENCY
        box.Parent = char
        table.insert(added, box)
        local head = char:FindFirstChild("Head")
        if head then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "PlayerNameTag"
            billboard.Adornee = head
            billboard.Size = UDim2.new(0, 150, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 3, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = char
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 1, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = target.DisplayName or target.Name
            nameLabel.TextColor3 = NAME_COLOR
            nameLabel.Font = Enum.Font.SourceSansBold
            nameLabel.TextSize = 18
            nameLabel.TextStrokeTransparency = 0.3
            nameLabel.Parent = billboard
            table.insert(added, billboard)
        end
        visuals[target] = added
    end
    setup(target.Character)
    target.CharacterAdded:Connect(setup)
end
local function removeVisuals(target)
    if visuals[target] then
        for _, obj in ipairs(visuals[target]) do
            if obj and obj.Parent then obj:Destroy() end
        end
        visuals[target] = nil
    end
end
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player then addVisuals(plr) end
end
Players.PlayerAdded:Connect(addVisuals)
Players.PlayerRemoving:Connect(removeVisuals)
-- =======================
-- TIMER ESP
-- =======================
-- LocalScript: Filtered Timer ESP (with exclusions, no minutes)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local overlayFolder = Instance.new("Folder")
overlayFolder.Name = "TimerOverlays"
overlayFolder.Parent = player:WaitForChild("PlayerGui")
-- helper to create floating text
local function makeBillboard(target, sourceLabel)
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 1e6
    billboard.Name = "TimerESP"
    billboard.Parent = overlayFolder
    billboard.Adornee = target
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextScaled = true
    textLabel.Parent = billboard
    -- update text every frame from the original label
    RunService.RenderStepped:Connect(function()
        if sourceLabel.Parent and target then
            local text = sourceLabel.Text
            if text == "0s" or text == "0" then
                textLabel.Text = "Unlocked"
                textLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- green
            else
                textLabel.Text = text
                textLabel.TextColor3 = Color3.fromRGB(0, 200, 255) -- blue
            end
        else
            billboard.Enabled = false
        end
    end)
end
-- helper to check exclusions
local function isExcluded(text)
    text = string.lower(text or "")
    return text:find("free") or text:find("sentry") or text:find("!") or text:find("m") or text:find("J3sus777")
end
-- scan workspace for timer UIs
local function scanTimers()
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("TextLabel") and descendant.Text:match("%ds") and not isExcluded(descendant.Text) then
            local adornee = descendant:FindFirstAncestorWhichIsA("BasePart")
            if adornee and adornee.Position.Y <= 7 then
                makeBillboard(adornee, descendant)
            end
        end
    end
end
-- run once at start
scanTimers()
-- also watch for new ones
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("TextLabel") and obj.Text:match("%ds") and not isExcluded(obj.Text) then
        local adornee = obj:FindFirstAncestorWhichIsA("BasePart")
        if adorne and adornee.Position.Y <= 7 then
            makeBillboard(adornee, obj)
        end
    end
end)
--// =======================
--// BEST-EARNING PET TRACKER (Enhanced)
--// =======================
local VALUE_THRESHOLD = 1e7
local WHITELIST_NAMES = { "Nooo My Hotspot" }
local EXCLUSION_ZONE = Vector3.new(0.03246767607386970, 2.76837086677551270, -1.08126354217529300)
local EXCLUSION_RADIUS = 20

local function parseMoney(text)
    text = string.lower(text or "")
    if not text:find("/s") then
        return 0
    end
    local num = tonumber(text:match("[%d%.]+")) or 0
    if text:find("k") then
        num *= 1e3
    elseif text:find("m") then
        num *= 1e6
    elseif text:find("b") then
        num *= 1e9
    elseif text:find("t") then
        num *= 1e12
    end
    return num
end

local function abbreviate(n)
    local abs = math.abs(n)
    if abs >= 1e12 then return string.format("%.2ft", n/1e12):gsub("%.0t","t") end
    if abs >= 1e9 then return string.format("%.2fb", n/1e9):gsub("%.0b","b") end
    if abs >= 1e6 then return string.format("%.2fm", n/1e6):gsub("%.0m","m") end
    if abs >= 1e3 then return string.format("%.2fk", n/1e3):gsub("%.0k","k") end
    return tostring(math.floor(n))
end

local function findAllPets()
    local results = {}
    
    local debrisFolder = workspace:FindFirstChild("Debris")
    if not debrisFolder then
        return results
    end
    
    for _, obj in ipairs(debrisFolder:GetChildren()) do
        if obj:IsA("BasePart") then
            local distance = (obj.Position - EXCLUSION_ZONE).Magnitude
            if distance <= EXCLUSION_RADIUS then
                continue
            end
            
            local displayNameLabel = nil
            local generationLabel = nil
            
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
                    for _, label in ipairs(child:GetDescendants()) do
                        if label:IsA("TextLabel") then
                            local labelName = label.Name
                            local text = label.Text or ""
                            
                            if labelName == "DisplayName" then
                                displayNameLabel = label
                            elseif labelName == "Generation" and text:find("/s") then
                                generationLabel = label
                            end
                        end
                    end
                end
            end
            
            if displayNameLabel and generationLabel then
                local displayName = displayNameLabel.Text or "Unknown"
                local generation = generationLabel.Text or "0"
                local value = parseMoney(generation)
                
                if value > 0 then
                    table.insert(results, {
                        part = obj,
                        displayName = displayName,
                        generation = generation,
                        value = value
                    })
                end
            end
        end
    end
    
    return results
end

local tracked = {}

local function clearVisuals(part)
    if tracked[part] then
        for _, v in ipairs(tracked[part]) do
            if v and v.Destroy then v:Destroy() end
        end
        tracked[part] = nil
    end
end

local function setVisuals(part, name, value, kind)
    clearVisuals(part)
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "PetHighlight_Client"
    if kind == "top" then
        highlight.FillColor = Color3.fromRGB(0,255,0)
    elseif kind == "whitelist" then
        highlight.FillColor = Color3.fromRGB(0,128,255)
    else
        highlight.FillColor = Color3.fromRGB(255,215,0)
    end
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
    highlight.FillTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = part
    highlight.Parent = part
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "PetBillboard_Client"
    billboardGui.Adornee = part
    billboardGui.Size = UDim2.new(0, 240, 0, 30)
    billboardGui.StudsOffset = Vector3.new(0, 3.5, 0)  -- Moved down 2.5 studs (from 6 to 3.5)
    billboardGui.AlwaysOnTop = true
    billboardGui.MaxDistance = 1e6
    billboardGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextScaled = true
    textLabel.TextStrokeTransparency = 0
    textLabel.TextColor3 = highlight.FillColor
    textLabel.Parent = billboardGui
    
    if value then
        textLabel.Text = string.format("%s | $%s/s", name, abbreviate(value))
    else
        textLabel.Text = name
    end
    
    tracked[part] = { highlight, billboardGui, textLabel }
end

local function updateBest()
    local allPets = findAllPets()
    
    local bestValue = -math.huge
    local bestPet = nil
    local activeParts = {}
    
    -- Find the single best pet (highest value)
    for _, petData in ipairs(allPets) do
        activeParts[petData.part] = true
        
        if petData.value > bestValue then
            bestValue = petData.value
            bestPet = petData
        end
    end
    
    -- Clear all existing visuals first
    for part in pairs(tracked) do
        if not activeParts[part] or not part.Parent then
            clearVisuals(part)
        end
    end
    
    -- Only highlight the single best pet with green
    if bestPet and bestPet.part and bestPet.part.Parent then
        setVisuals(bestPet.part, bestPet.displayName, bestPet.value, "top")
    end
    
    -- Then highlight whitelist and threshold pets (but NOT the top pet)
    for _, petData in ipairs(allPets) do
        -- Skip if this is the top pet (already highlighted)
        if bestPet and petData.part == bestPet.part then
            continue
        end
        
        -- Check whitelist
        local isWhitelisted = false
        for _, w in ipairs(WHITELIST_NAMES) do
            if petData.displayName == w then
                isWhitelisted = true
                setVisuals(petData.part, petData.displayName, petData.value, "whitelist")
                break
            end
        end
        
        -- Check threshold (only if not whitelisted)
        if not isWhitelisted and petData.value >= VALUE_THRESHOLD then
            setVisuals(petData.part, petData.displayName, petData.value, "threshold")
        end
    end
end

spawn(function()
    while true do
        updateBest()
        task.wait(1)
    end
end)

-- =======================
-- INFINITE JUMP
-- =======================
local humanoid, rootPart
local function updateCharacter()
    local char = player.Character or player.CharacterAdded:Wait()
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
        if humanoid.Jump and rootPart then
            rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 50, rootPart.Velocity.Z)
        end
    end)
end
player.CharacterAdded:Connect(updateCharacter)
if player.Character then updateCharacter() end
--- =======================
-- AUTO-RELOAD ON TELEPORT (Lean & Session-Only)
-- =======================
local ADMIN_RAW_URL = "https://raw.githubusercontent.com/temiepeoepo/11234123123/refs/heads/main/17.lua" -- replace with your raw script URL
-- Use a session-only flag so it only queues if you already executed this session
if shared._AutoReloadQueued then
    return -- already queued this session, do nothing
end
shared._AutoReloadQueued = true
-- find queue_on_teleport function
local function find_queue()
    if type(queue_on_teleport) == "function" then return queue_on_teleport end
    if syn and type(syn.queue_on_teleport) == "function" then return syn.queue_on_teleport end
    if secure_load and type(secure_load.queue_on_teleport) == "function" then return secure_load.queue_on_teleport end
    if KRNL and type(KRNL.queue_on_teleport) == "function" then return KRNL.queue_on_teleport end
    for k,v in pairs(_G) do
        if type(v) == "function" and tostring(k):lower():find("queue_on_teleport") then
            return v
        end
    end
    return nil
end
local queue_func = find_queue()
if queue_func and ADMIN_RAW_URL and ADMIN_RAW_URL ~= "" then
    local queued_payload = [[
        local url = "]] .. ADMIN_RAW_URL .. [["
        local function safeGet(u)
            if syn and type(syn.request) == "function" then
                local ok,res = pcall(function() return syn.request({Url=u,Method="GET"}).Body end)
                if ok and res then return res end
            end
            if type(http_request)=="function" then
                local ok,res = pcall(function() return http_request({Url=u}).Body end)
                if ok and res then return res end
            end
            if type(request)=="function" then
                local ok,res = pcall(function() return request({Url=u}).Body end)
                if ok and res then return res end
            end
            if type(game.HttpGet)=="function" then
                local ok,res = pcall(function() return game:HttpGet(u) end)
                if ok and res then return res end
            end
            local HttpService = game:GetService("HttpService")
            local ok,res = pcall(function() return HttpService:GetAsync(u) end)
            if ok and res then return res end
            return nil
        end
        local code = safeGet(url)
        if code then
            local fn = loadstring(code)
            if fn then pcall(fn) end
        end
    ]]
    pcall(function() queue_func(queued_payload) end)
    print("[Auto-Reload] Script queued for teleport/rejoin.")
else
    warn("[Auto-Reload] queue_on_teleport API not available.")
end

--// =======================
--// CAMERA NOCLIP
--// =======================
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

-- Lower camera sensitivity
UserInputService.MouseDeltaSensitivity = 0.2

-- Disable camera occlusion
pcall(function()
    player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
end)

-- Set camera properties to allow noclip
RunService.RenderStepped:Connect(function()
    pcall(function()
        -- Keep camera in custom mode (not scriptable which locks it)
        if camera.CameraType ~= Enum.CameraType.Custom then
            camera.CameraType = Enum.CameraType.Custom
        end
        
        -- Set camera subject to humanoid to maintain control
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            camera.CameraSubject = player.Character.Humanoid
        end
        
        -- Disable camera collision
        sethiddenproperty(camera, "HeadScale", 0)
    end)
end)

-- Remove camera collision using zoom manipulation
player.CameraMaxZoomDistance = 50
player.CameraMinZoomDistance = 0.5


--// =======================
--// FULLBRIGHT + MATERIALS + DECORATIONS
--// =======================
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- FULLBRIGHT / balanced day
local function applyFullBright()
	Lighting.ClockTime = 12
	Lighting.TimeOfDay = "12:00:00"
	Lighting.Brightness = 1
	Lighting.ExposureCompensation = 0
	Lighting.Ambient = Color3.fromRGB(200,200,200)
	Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
	Lighting.FogEnd = 100000
	Lighting.GlobalShadows = false
end

applyFullBright()
RunService.RenderStepped:Connect(applyFullBright)

-- SmoothPlastic → Air
local function makeAir(part)
	if part:IsA("BasePart") and part.Material == Enum.Material.SmoothPlastic then
		part.Material = Enum.Material.Air
	end
end

for _, part in ipairs(Workspace:GetDescendants()) do
	makeAir(part)
end
Workspace.DescendantAdded:Connect(makeAir)

-- Decorations → 40% transparent (recursive)
local function applyDecorationsTransparency(parent)
	for _, obj in ipairs(parent:GetDescendants()) do
		if obj:IsA("Folder") and obj.Name == "Decorations" then
			for _, part in ipairs(obj:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 0.4
				end
			end
		end
	end
end

-- Apply to existing hierarchy
applyDecorationsTransparency(Workspace)

-- Monitor new folders or parts
Workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("Folder") and obj.Name == "Decorations" then
		for _, part in ipairs(obj:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Transparency = 0.4
			end
		end
	elseif obj:IsA("BasePart") then
		local parent = obj:FindFirstAncestorWhichIsA("Folder")
		while parent do
			if parent.Name == "Decorations" then
				obj.Transparency = 0.4
				break
			end
			parent = parent.Parent
		end
	end
end)

--------------------------------------------------------------------
-- REMOVE ALL CLOTHES & ACCESSORIES (merged)
--------------------------------------------------------------------
-- Function to strip clothing/accessories from a character
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Debounce table to prevent rapid tool equip spam
local equipDebounce = {}
local EQUIP_COOLDOWN = 0.5 -- seconds between tool equips

local function stripVisualItems(character)
    if not character then return end
    
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Accessory")
            or item:IsA("Clothing")
            or item:IsA("ShirtGraphic")
            or item:IsA("Pants")
            or item:IsA("Shirt")
            or item:IsA("LayeredClothing")
        then
            item:Destroy()
        end
    end
end

local function setupAntiLag(character)
    if not character then return end
    
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    
    -- Anti tool spam
    humanoid.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            local userId = Players:GetPlayerFromCharacter(character).UserId
            local currentTime = tick()
            
            if equipDebounce[userId] and (currentTime - equipDebounce[userId]) < EQUIP_COOLDOWN then
                child:Destroy()
                return
            end
            
            equipDebounce[userId] = currentTime
        end
    end)
end

local function handleCharacter(character)
    stripVisualItems(character)
    setupAntiLag(character)
end

-- Remove from every player already in game
for _, plr in ipairs(Players:GetPlayers()) do
    if plr.Character then
        handleCharacter(plr.Character)
    end
    
    -- Handle their future respawns
    plr.CharacterAdded:Connect(handleCharacter)
end

-- Handle new players that join
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(handleCharacter)
end)

-- Handle your own character (initial and respawns)
if player.Character then
    handleCharacter(player.Character)
end
player.CharacterAdded:Connect(handleCharacter)

--// =======================
--// GHOST PLAYERS / TRAP HANDLER
--// =======================

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local task      = task

-- Weak tables so parts can be GC'd
local tracked = {
    others = setmetatable({}, { __mode = "k" }),
    localp = setmetatable({}, { __mode = "k" }),
    trap   = setmetatable({}, { __mode = "k" }),
}
local conns = setmetatable({}, { __mode = "k" })

local function safeSet(part, prop, val)
    if not part or not part.Parent then return end
    pcall(function() part[prop] = val end)
end

local function safeGet(part, prop)
    if not part or not part.Parent then return nil end
    local ok, v = pcall(function() return part[prop] end)
    return ok and v or nil
end

-- Desired states
local function applyOtherSettings(part)
    safeSet(part, "CanCollide", false)
    safeSet(part, "CanQuery",   false)
    safeSet(part, "CanTouch",   false)
end

local function applyLocalSettings(part)
    -- FIXED: Keep CanTouch enabled so you can touch buttons/plates
    safeSet(part, "CanQuery", false)
    -- Don't modify CanTouch - leave it as default (true)
end

local function applyTrapSettings(part)
    safeSet(part, "CanCollide", false)
    safeSet(part, "CanQuery",   false)
    safeSet(part, "CanTouch",   false)
end

local function stopWatching(part)
    local list = conns[part]
    if list then
        for _, c in ipairs(list) do
            pcall(function() c:Disconnect() end)
        end
        conns[part] = nil
    end
    tracked.others[part] = nil
    tracked.localp[part] = nil
    tracked.trap[part] = nil
end

local function watchPart(part, category)
    if not part or not part:IsA("BasePart") then return end
    if conns[part] then return end
    conns[part] = {}
    
    if category == "others" then 
        tracked.others[part] = true 
        applyOtherSettings(part)
    elseif category == "local" then 
        tracked.localp[part] = true 
        applyLocalSettings(part)
    elseif category == "trap" then 
        tracked.trap[part] = true 
        applyTrapSettings(part) 
    end
    
    -- FIXED: Only watch CanQuery for local player, not CanTouch
    local props = {}
    if category == "others" then 
        props = {"CanCollide","CanQuery","CanTouch"}
    elseif category == "local" then 
        props = {"CanQuery"} -- Removed CanTouch from monitoring
    elseif category == "trap" then 
        props = {"CanCollide","CanQuery","CanTouch"} 
    end
    
    for _, prop in ipairs(props) do
        local ok, sig = pcall(function() return part:GetPropertyChangedSignal(prop) end)
        if ok and sig then
            table.insert(conns[part], sig:Connect(function()
                task.defer(function()
                    if not part or not part.Parent then return end
                    if category == "others" then applyOtherSettings(part)
                    elseif category == "local" then applyLocalSettings(part)
                    elseif category == "trap"   then applyTrapSettings(part) end
                end)
            end))
        end
    end
    
    table.insert(conns[part], part.AncestryChanged:Connect(function()
        if not part:IsDescendantOf(game) then
            stopWatching(part)
        end
    end))
end

local function applyToContainer(container, category)
    if not container then return end
    for _, obj in ipairs(container:GetDescendants()) do
        if obj:IsA("BasePart") then
            watchPart(obj, category)
        end
    end
    container.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            watchPart(desc, category)
        end
    end)
end

-- Other players
local function onOtherPlayerAdded(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(function(char)
        applyToContainer(char, "others")
    end)
    if player.Character then applyToContainer(player.Character, "others") end
end

for _, p in ipairs(Players:GetPlayers()) do onOtherPlayerAdded(p) end
Players.PlayerAdded:Connect(onOtherPlayerAdded)

-- Local player
local function onLocalCharacter(char)
    if not char then return end
    applyToContainer(char, "local")
end

if LocalPlayer.Character then onLocalCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(onLocalCharacter)

-- Workspace traps
local function processWorkspacePart(p)
    if not p:IsA("BasePart") then return end
    local name = (p.Name or ""):lower()
    if name:find("trap") then
        watchPart(p, "trap")
    end
end

for _, obj in ipairs(Workspace:GetDescendants()) do processWorkspacePart(obj) end
Workspace.DescendantAdded:Connect(processWorkspacePart)

-- Periodic enforcer - FIXED: Don't enforce CanTouch on local parts
task.spawn(function()
    while true do
        task.wait(0.35)
        for part in pairs(tracked.others) do 
            if part and part.Parent then applyOtherSettings(part) end 
        end
        for part in pairs(tracked.localp) do 
            if part and part.Parent then applyLocalSettings(part) end 
        end
        for part in pairs(tracked.trap) do 
            if part and part.Parent then applyTrapSettings(part) end 
        end
    end
end)


--// =======================
--// GRAPPLE-HOOK SPEED 
--// =======================
do
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    -- Configuration
    local FIRE_INTERVAL = 0.1 -- Fire 10x/sec
    local SPEED_MULTIPLIER = 5 -- Movement boost multiplier
    local GRAPPLE_TOOL_NAME = "Grapple Hook" -- Tool name
    local Event = ReplicatedStorage.Packages.Net:WaitForChild("RE/UseItem")
    local movementConnection, fireConnection
    local isHoldingGrapple = false
    -- Check if player holds Grapple Hook
    local function checkForGrappleHook()
        if character then
            local tool = character:FindFirstChild(GRAPPLE_TOOL_NAME)
            return tool and tool:IsA("Tool")
        end
        return false
    end
    -- Apply speed boost using AssemblyLinearVelocity
    local function applyDirectVelocity()
        if character and character:FindFirstChild("HumanoidRootPart") and isHoldingGrapple then
            local rootPart = character.HumanoidRootPart
            local moveVector = humanoid.MoveDirection
            if moveVector.Magnitude > 0 then
                local currentVelocity = rootPart.AssemblyLinearVelocity
                rootPart.AssemblyLinearVelocity = Vector3.new(
                    moveVector.X * humanoid.WalkSpeed * SPEED_MULTIPLIER,
                    currentVelocity.Y,
                    moveVector.Z * humanoid.WalkSpeed * SPEED_MULTIPLIER
                )
            end
        end
    end
    -- Fire Grapple Hook remotely
    local function fireGrappleHook()
        if isHoldingGrapple then
            pcall(function()
                Event:FireServer(0.70743885040283)
            end)
        end
    end
    -- Loop auto-fire
    local function startFireLoop()
        if fireConnection then fireConnection:Disconnect() end
        fireConnection = spawn(function()
            while character and character.Parent do
                fireGrappleHook()
                wait(FIRE_INTERVAL)
            end
        end)
    end
    -- Loop movement speed
    local function startMovementLoop()
        if movementConnection then movementConnection:Disconnect() end
        movementConnection = RunService.Heartbeat:Connect(function()
            isHoldingGrapple = checkForGrappleHook()
            applyDirectVelocity()
        end)
    end
    -- Initialize loops
    local function initialize()
        startFireLoop()
        startMovementLoop()
        print("Grapple is on")
    end
    -- Handle respawn
    local function onCharacterAdded(newChar)
        character = newChar
        humanoid = character:WaitForChild("Humanoid")
        isHoldingGrapple = false
        if movementConnection then movementConnection:Disconnect() movementConnection = nil end
        if fireConnection then fireConnection:Disconnect() fireConnection = nil end
        task.wait(1)
        initialize()
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    if character and character.Parent then initialize() end
    -- Cleanup on leaving
    Players.PlayerRemoving:Connect(function(plr)
        if plr == player then
            if movementConnection then movementConnection:Disconnect() end
            if fireConnection then fireConnection:Disconnect() end
        end
    end)
end

--// =======================
--// BASE LINE + BLACK DECORATIONS
--// =======================

do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer

    -- Find the billboard that is VISIBLE
    local function findBaseBillboard()
        local visibleBillboards = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BillboardGui") and obj.Enabled then
                for _, child in ipairs(obj:GetDescendants()) do
                    if child:IsA("TextLabel") and child.Visible then
                        if string.upper(child.Text) == "YOUR BASE" and child.TextTransparency < 1 then
                            table.insert(visibleBillboards, obj)
                        end
                    end
                end
            end
        end
        if #visibleBillboards > 1 and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local closest, closestDist
                for _, billboard in ipairs(visibleBillboards) do
                    local pos
                    if billboard.Parent and billboard.Parent:IsA("BasePart") then
                        pos = billboard.Parent.Position
                    elseif billboard.Parent and billboard.Parent:IsA("Model") then
                        local part = billboard.Parent:FindFirstChildWhichIsA("BasePart", true)
                        if part then pos = part.Position end
                    end
                    if pos then
                        local dist = (pos - root.Position).Magnitude
                        if not closest or dist < closestDist then
                            closestDist = dist
                            closest = billboard
                        end
                    end
                end
                if closest then return closest end
            end
        end
        return visibleBillboards[1]
    end

    -- Create a simple line between two points
    local function createLine(startPos, endPos)
        local distance = (endPos - startPos).Magnitude
        local direction = (endPos - startPos).Unit
        local line = Instance.new("Part")
        line.Name = "BaseLine"
        line.Anchored = true
        line.CanCollide = false
        line.Size = Vector3.new(0.5, 0.5, distance)
        line.CFrame = CFrame.new(startPos + direction * distance / 2, endPos)
        line.Color = Color3.fromRGB(255, 140, 0)
        line.Material = Enum.Material.Neon
        line.Transparency = 0.3
        line.Parent = workspace
        return line
    end

    -- Find and color the Decorations folder black
    local function findAndColorDecorations(billboard)
        local baseModel = billboard.Parent
        if not baseModel then return end
        local parentModel = baseModel.Parent
        if not parentModel then return end
        local decorations = parentModel:FindFirstChild("Decorations")
        if not decorations then return end
        for _, obj in ipairs(decorations:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                obj.Color = Color3.fromRGB(0, 0, 0) -- Black
                obj.Material = Enum.Material.SmoothPlastic
            end
        end
    end

    -- Main
    local billboard = findBaseBillboard()
    if billboard then
        local targetPos
        if billboard.Adornee then
            targetPos = billboard.Adornee.Position
        elseif billboard.Parent and billboard.Parent:IsA("BasePart") then
            targetPos = billboard.Parent.Position
        elseif billboard.Parent and billboard.Parent:IsA("Model") then
            local part = billboard.Parent:FindFirstChildWhichIsA("BasePart", true)
            if part then targetPos = part.Position end
        end

        if targetPos then
            findAndColorDecorations(billboard)
            local currentLine
            RunService.Heartbeat:Connect(function()
                if not player.Character then return end
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if not root then return end
                if currentLine then currentLine:Destroy() end
                currentLine = createLine(root.Position, targetPos)
            end)
        end
    end
end

--// =======================
--// AUTO-KICK ON "YOU STOLE" DETECTION (CLEAN TEXT, NO RICHTEXT TAGS)
--// =======================
do
    local playerGui = player:WaitForChild("PlayerGui")

    -- Helper: remove <font>, <b>, <i>, etc. tags
    local function stripRichTextTags(text)
        if typeof(text) ~= "string" then
            return ""
        end
        return (text:gsub("<[^>]->", "")) -- removes all <...> tags
    end

    -- Helper: detect if text contains "you stole" (case-insensitive)
    local function getYouStoleText(text)
        if typeof(text) ~= "string" then
            return nil
        end
        local cleanText = stripRichTextTags(text)
        local lowerText = string.lower(cleanText)
        local startPos = string.find(lowerText, "you stole", 1, true)
        if startPos then
            return cleanText
        end
        return nil
    end

    -- Kick with the specific detected text
    local function triggerKick(foundText)
        local message = foundText or "you stole something!"
        player:Kick(message)
    end

    -- Scan a GuiObject and its descendants for "you stole"
    local function scanGuiObject(guiObj)
        if guiObj:IsA("TextLabel") or guiObj:IsA("TextButton") or guiObj:IsA("TextBox") then
            local foundText = getYouStoleText(guiObj.Text)
            if foundText then
                triggerKick(foundText)
                return
            end
        end

        for _, desc in ipairs(guiObj:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                local foundText = getYouStoleText(desc.Text)
                if foundText then
                    triggerKick(foundText)
                    return
                end
            end
        end
    end

    -- Watch for new GUIs appearing
    playerGui.ChildAdded:Connect(function(child)
        task.wait(0.05)
        scanGuiObject(child)

        child.DescendantAdded:Connect(function(desc)
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                local foundText = getYouStoleText(desc.Text)
                if foundText then
                    triggerKick(foundText)
                end
            end
        end)
    end)

    -- Also check existing GUIs at startup
    for _, child in ipairs(playerGui:GetChildren()) do
        scanGuiObject(child)
        child.DescendantAdded:Connect(function(desc)
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                local foundText = getYouStoleText(desc.Text)
                if foundText then
                    triggerKick(foundText)
                end
            end
        end)
    end
end


--// =======================
--// GRAVITY NORMALIZER
--// =======================

do
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local NORMAL_GRAVITY = 196.2 -- Roblox default

    RunService.Heartbeat:Connect(function()
        if Workspace.Gravity ~= NORMAL_GRAVITY then
            Workspace.Gravity = NORMAL_GRAVITY
        end
    end)
end

--// =======================
--// RAGDOLL MOVEMENT CONTROLS (PC + Mobile)
--// =======================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")
local camera = Workspace.CurrentCamera
local animator = humanoid:WaitForChild("Animator")

local connections = {}
local isActive = false
local isRagdolling = false
local boogieBlocked = false
local beeBlocked = false
local originalFOV = nil
local controlsReversed = false

-- Function to check if humanoid is in a bad state
local function isInBadState()
    local state = humanoid:GetState()
    return state == Enum.HumanoidStateType.Physics or 
           state == Enum.HumanoidStateType.Ragdoll or
           state == Enum.HumanoidStateType.FallingDown or
           state == Enum.HumanoidStateType.GettingUp
end

-- Function to enable player controls
local function enableControls()
    pcall(function()
        local playerModule = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
        require(playerModule):GetControls():Enable()
    end)
end

-- Function to clean up ragdoll constraints and animations
local function cleanupRagdoll()
    -- Remove ragdoll constraints
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("BallSocketConstraint") or 
           obj:IsA("NoCollisionConstraint") or 
           obj:IsA("HingeConstraint") or
           (obj:IsA("Attachment") and (obj.Name == "A" or obj.Name == "B")) then
            obj:Destroy()
        end
    end
    
    -- Re-enable Motor6Ds
    for _, obj in pairs(char:GetDescendants()) do
        if obj:IsA("Motor6D") then
            obj.Enabled = true
        end
    end
    
    -- Stop ragdoll animations
    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
        local animName = track.Animation and track.Animation.Name:lower() or ""
        if animName:find("rag") or animName:find("fall") or 
           animName:find("hurt") or animName:find("down") then
            track:Stop(0)
        end
    end
end

-- Function to handle ragdoll prevention
local function preventRagdoll()
    if not isInBadState() then return end
    
    isRagdolling = true
    
    -- Force character upright
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
    cleanupRagdoll()
    camera.CameraSubject = humanoid
    enableControls()
    
    -- Reset velocity immediately
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    
    -- Reset CFrame to be upright
    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, hrp.CFrame:ToOrientation(), 0)
    
    -- Keep velocity at 0 for 0.1 seconds
    local stopTime = tick() + 0.1
    local velocityConnection
    velocityConnection = RunService.Heartbeat:Connect(function()
        if tick() < stopTime then
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        else
            velocityConnection:Disconnect()
        end
    end)
    
    task.wait(0.1)
    isRagdolling = false
end

-- Function to remove camera effects
local function removeCameraEffects()
    -- Remove blur effects from camera
    for _, effect in pairs(camera:GetChildren()) do
        if effect:IsA("BlurEffect") or 
           effect:IsA("DepthOfFieldEffect") or
           effect:IsA("ColorCorrectionEffect") or
           effect:IsA("SunRaysEffect") or
           effect:IsA("BloomEffect") then
            effect:Destroy()
        end
    end
    
    -- Remove post effects from lighting
    local lighting = game:GetService("Lighting")
    for _, effect in pairs(lighting:GetChildren()) do
        if effect:IsA("BlurEffect") or 
           effect:IsA("ColorCorrectionEffect") or 
           effect:IsA("SunRaysEffect") or
           effect:IsA("BloomEffect") or
           effect:IsA("DepthOfFieldEffect") then
            effect:Destroy()
        end
    end
end

-- Function to prevent boogie effects
local function preventBoogie()
    if boogieBlocked then return end
    boogieBlocked = true
    
    print("[Anti-Ragdoll] Blocked boogie effect")
    
    -- Store original FOV if not already stored
    if not originalFOV then
        originalFOV = camera.FieldOfView
    end
    
    -- Remove any camera effects
    removeCameraEffects()
    
    -- Lock camera FOV and remove effects for 10 seconds
    local lockTime = tick() + 10
    local boogieConnection
    boogieConnection = RunService.RenderStepped:Connect(function()
        if tick() < lockTime then
            -- Keep FOV stable
            if math.abs(camera.FieldOfView - originalFOV) > 1 then
                camera.FieldOfView = originalFOV
            end
            
            -- Continuously remove effects
            removeCameraEffects()
        else
            boogieConnection:Disconnect()
            boogieBlocked = false
        end
    end)
    
    task.wait(10)
end

-- Function to prevent bee attack effects
local function preventBeeAttack()
    if beeBlocked then return end
    beeBlocked = true
    
    print("[Anti-Ragdoll] Blocked bee attack effect")
    
    -- Store original FOV if not already stored
    if not originalFOV then
        originalFOV = camera.FieldOfView
    end
    
    -- Remove any camera effects
    removeCameraEffects()
    
    -- Prevent control reversal
    controlsReversed = false
    
    -- Lock camera FOV, remove effects, and prevent control reversal for 10 seconds
    local lockTime = tick() + 10
    local beeConnection
    beeConnection = RunService.RenderStepped:Connect(function()
        if tick() < lockTime then
            -- Keep FOV stable (prevent zoom)
            if math.abs(camera.FieldOfView - originalFOV) > 1 then
                camera.FieldOfView = originalFOV
            end
            
            -- Continuously remove effects
            removeCameraEffects()
            
            -- Try to fix controls if they get reversed
            pcall(function()
                local playerModule = LocalPlayer:WaitForChild("PlayerScripts"):FindFirstChild("PlayerModule")
                if playerModule then
                    local controls = require(playerModule):GetControls()
                    if controls and controls.enabled then
                        controls:Enable()
                    end
                end
            end)
        else
            beeConnection:Disconnect()
            beeBlocked = false
        end
    end)
    
    task.wait(10)
end

-- Function to start anti-ragdoll
local function startAntiRagdoll()
    if isActive then return end
    isActive = true
    
    print("[Anti-Ragdoll] Started - Monitoring remote events")
    
    -- Find the Ragdoll folder
    local success, ragdollFolder = pcall(function()
        return ReplicatedStorage:WaitForChild("Packages", 5):WaitForChild("Ragdoll", 5)
    end)
    
    if not success or not ragdollFolder then
        warn("[Anti-Ragdoll] Could not find Ragdoll folder")
        return
    end
    
    -- Function to connect to a remote event
    local function connectToRemote(remote)
        if remote:IsA("RemoteEvent") then
            local conn = remote.OnClientEvent:Connect(function(...)
                local args = {...}
                local hasBoogie = false
                local hasBeeAttack = false
                
                -- Check if any argument contains "boogie" or "bee attack" (case insensitive)
                for _, arg in pairs(args) do
                    if type(arg) == "string" then
                        local lowerArg = arg:lower()
                        if lowerArg:find("boogie") then
                            hasBoogie = true
                            break
                        elseif lowerArg:find("bee") and lowerArg:find("attack") then
                            hasBeeAttack = true
                            break
                        end
                    end
                end
                
                if hasBoogie then
                    print("[Anti-Ragdoll] Blocked boogie effect from:", remote.Name)
                    preventBoogie()
                elseif hasBeeAttack then
                    print("[Anti-Ragdoll] Blocked bee attack from:", remote.Name)
                    preventBeeAttack()
                else
                    print("[Anti-Ragdoll] Blocked ragdoll event from:", remote.Name)
                    preventRagdoll()
                end
            end)
            table.insert(connections, conn)
            print("[Anti-Ragdoll] Now monitoring:", remote.Name)
        end
    end
    
    -- Monitor all RemoteEvents in ReplicatedStorage for boogie and bee attack effects
    local function monitorAllRemotes(parent)
        for _, obj in pairs(parent:GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local conn = obj.OnClientEvent:Connect(function(...)
                    local args = {...}
                    for _, arg in pairs(args) do
                        if type(arg) == "string" then
                            local lowerArg = arg:lower()
                            if lowerArg:find("boogie") then
                                print("[Anti-Ragdoll] Blocked boogie from global remote:", obj.Name)
                                preventBoogie()
                                break
                            elseif lowerArg:find("bee") and lowerArg:find("attack") then
                                print("[Anti-Ragdoll] Blocked bee attack from global remote:", obj.Name)
                                preventBeeAttack()
                                break
                            end
                        end
                    end
                end)
                table.insert(connections, conn)
            end
        end
    end
    
    -- Monitor all remotes in ReplicatedStorage
    pcall(function()
        monitorAllRemotes(ReplicatedStorage)
    end)
    
    -- Watch for new remotes being added anywhere
    table.insert(connections, ReplicatedStorage.DescendantAdded:Connect(function(obj)
        if obj:IsA("RemoteEvent") then
            task.wait()
            local conn = obj.OnClientEvent:Connect(function(...)
                local args = {...}
                for _, arg in pairs(args) do
                    if type(arg) == "string" then
                        local lowerArg = arg:lower()
                        if lowerArg:find("boogie") then
                            print("[Anti-Ragdoll] Blocked boogie from new remote:", obj.Name)
                            preventBoogie()
                            break
                        elseif lowerArg:find("bee") and lowerArg:find("attack") then
                            print("[Anti-Ragdoll] Blocked bee attack from new remote:", obj.Name)
                            preventBeeAttack()
                            break
                        end
                    end
                end
            end)
            table.insert(connections, conn)
        end
    end))
    
    -- Only connect to NEW remotes being added
    table.insert(connections, ragdollFolder.DescendantAdded:Connect(function(obj)
        if obj:IsA("RemoteEvent") then
            task.wait() -- Small delay to ensure remote is fully loaded
            connectToRemote(obj)
        end
    end))
    
    -- Monitor state changes continuously
    table.insert(connections, humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Physics or 
           newState == Enum.HumanoidStateType.Ragdoll or
           newState == Enum.HumanoidStateType.FallingDown or
           newState == Enum.HumanoidStateType.GettingUp then
            preventRagdoll()
        end
    end))
    
    -- Monitor for new constraints being added
    table.insert(connections, char.DescendantAdded:Connect(function(obj)
        if obj:IsA("BallSocketConstraint") or 
           obj:IsA("NoCollisionConstraint") or 
           obj:IsA("HingeConstraint") then
            obj:Destroy()
            if not isRagdolling then
                preventRagdoll()
            end
        end
    end))
    
    -- Continuous heartbeat check
    table.insert(connections, RunService.Heartbeat:Connect(function()
        if isInBadState() and not isRagdolling then
            cleanupRagdoll()
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end))
    
    -- Handle character respawn
    table.insert(connections, LocalPlayer.CharacterAdded:Connect(function(newChar)
        char = newChar
        humanoid = newChar:WaitForChild("Humanoid")
        hrp = newChar:WaitForChild("HumanoidRootPart")
        animator = humanoid:WaitForChild("Animator")
        camera.CameraSubject = humanoid
        enableControls()
    end))
    
    enableControls()
end

-- Function to stop anti-ragdoll
local function stopAntiRagdoll()
    isActive = false
    for _, conn in pairs(connections) do
        conn:Disconnect()
    end
    connections = {}
    print("[Anti-Ragdoll] Stopped")
end

-- Start the anti-ragdoll
startAntiRagdoll()

-- Optional: Return functions to toggle
return {
    Start = startAntiRagdoll,
    Stop = stopAntiRagdoll,
    IsActive = function() return isActive end
}


-- ======================= 
-- DESYNC/ANTI-HIT SCRIPT 
-- ======================= 
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Desync FFlags Configuration
local DesyncFFlags = {
    -- Core Desync Flags
    DisableDPIScale = true,
    S2PhysicsSenderRate = 1500,
    
    -- Bandwidth & Network
    PhysicsSenderMaxBandwidthBps = 100000,
    ServerMaxBandwith = 200,
    MaxDataPacketPerSend = 100000,
    
    -- Update Delay Tolerance
    MaxAcceptableUpdateDelay = 200,
    
    -- Velocity & Position Thresholds
    AngularVelociryLimit = 360,
    GameNetDontSendRedundantDeltaPositionMillionth = 200000,
    InterpolationFrameRotVelocityThresholdMillionth = 300000,
    InterpolationFramePositionThresholdMillionth = 300000,
    InterpolationFrameVelocityThresholdMillionth = 300000,
    
    -- Velocity Checks
    CheckPVLinearVelocityIntegrateVsDeltaPositionThresholdPercent = 200,
    CheckPVCachedVelThresholdPercent = 200,
    CheckPVCachedRotVelThresholdPercent = 200,
    CheckPVDifferencesForInterpolationMinVelThresholdStudsPerSecHundredth = 200,
    CheckPVDifferencesForInterpolationMinRotVelThresholdRadsPerSecHundredth = 200,
    
    -- Timestep & World Step
    TimestepArbiterOmegaThou = 500000,
    TimestepArbiterHumanoidTurningVelThreshold = 100,
    TimestepArbiterHumanoidLinearVelThreshold = 100,
    TimestepArbiterVelocityCriteriaThresholdTwoDt = 100000,
    MaxTimestepMultiplierAcceleration = 10000,
    MaxTimestepMultiplierContstraint = 10000,
    MaxTimestepMultiplierBuoyancy = 10000,
    SimExplicitlyCappedTimestepMultiplier = 10000,
    WorldStepMax = 60,
    
    -- Missed Steps & Redundancy
    MaxMissedWorldStepsRemembered = 300,
    GameNetDontSendRedundantNumTimes = 20,
    DebugSendDistInSteps = 200,
    
    -- Velocity Cutoffs
    GameNetPVHeaderRotationalVelocityZeroCutoffExponent = -5000,
    GameNetPVHeaderLinearVelocityZeroCutoffExponent = -5000,
    
    -- Replication & Streaming
    StreamJobNOUVolumeCap = 100000,
    StreamJobNOUVolumeLengthCap = 100000,
    SimOwnedNOUCountThresholdMillionth = 100000,
    ReplicationFocusNouExtentsSizeCutoffForPauseStuds = 100000,
    
    -- Large Replicator Flags
    LargeReplicatorEnabled9 = true,
    LargeReplicatorWrite5 = true,
    LargeReplicatorRead5 = true,
    LargeReplicatorSerializeWrite4 = true,
    LargeReplicatorSerializeRead3 = true,
    NextGenReplicatorEnabledWrite4 = true,
}

-- Create GUI
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "DesyncFlagsGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main Button
    local button = Instance.new("TextButton")
    button.Name = "ApplyButton"
    button.Size = UDim2.new(0, 120, 0, 40)
    button.Position = UDim2.new(0, 10, 0, 10)
    button.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
    button.Text = "APPLY FFLAGS"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 16
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.Parent = screenGui
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0, 120, 0, 25)
    statusLabel.Position = UDim2.new(0, 10, 0, 55)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = screenGui
    
    screenGui.Parent = game:GetService("CoreGui")
    
    return screenGui, button, statusLabel
end

local gui, applyBtn, statusLbl = createGUI()

-- Function to apply FFlags
local function applyDesyncFFlags()
    local success = 0
    local total = 0
    
    -- Check if setfflag exists
    if not setfflag then
        statusLbl.Text = "Error: setfflag not found!"
        statusLbl.TextColor3 = Color3.fromRGB(255, 0, 0)
        warn("setfflag function not available in this exploit")
        return
    end
    
    for flag, value in pairs(DesyncFFlags) do
        total = total + 1
        local ok, err = pcall(function()
            -- Convert boolean to string for FFlags that need it
            if type(value) == "boolean" then
                setfflag(flag, tostring(value))
            else
                setfflag(flag, value)
            end
        end)
        if ok then
            success = success + 1
        else
            warn("Failed to set FFlag:", flag, err)
        end
    end
    
    statusLbl.Text = string.format("Applied %d/%d", success, total)
    statusLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
    
    wait(1)
    
    applyBtn.Text = "APPLIED!"
    applyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    
    wait(2)
    
    -- Reset button
    applyBtn.Text = "APPLY FFLAGS"
    applyBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
    applyBtn.Visible = true
end

-- Main button click handler with character kill
applyBtn.MouseButton1Click:Connect(function()
    applyBtn.Text = "KILLING..."
    applyBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    statusLbl.Text = "Killing character..."
    statusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
    
    -- Kill the character
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
    end
    
    -- Immediately apply FFlags
    applyBtn.Text = "APPLYING..."
    applyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 0)
    statusLbl.Text = "Applying FFlags..."
    statusLbl.TextColor3 = Color3.fromRGB(255, 255, 0)
    
    applyDesyncFFlags()
end)

-- Recreate GUI if removed
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "DesyncFlagsGUI" then
        gui, applyBtn, statusLbl = createGUI()
        
        -- Reconnect button
        applyBtn.MouseButton1Click:Connect(function()
            applyBtn.Text = "KILLING..."
            applyBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            statusLbl.Text = "Killing character..."
            statusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
            
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                end
            end
            
            applyBtn.Text = "APPLYING..."
            applyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 0)
            statusLbl.Text = "Applying FFlags..."
            statusLbl.TextColor3 = Color3.fromRGB(255, 255, 0)
            
            applyDesyncFFlags()
        end)
    end
end)

--// =======================
--// LOCKED TOOL BUTTON (Top-Left)
--// =======================
do
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local TOOL_NAME = "All Seeing Sentry"
    local Event = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/UseItem")

    local screenGui = Instance.new("ScreenGui", playerGui)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 150, 0, 35)
    button.Position = UDim2.new(0, 140, 0, 20) -- top-left, slightly right
    button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.Text = "Defense"
    button.Parent = screenGui
    button.AutoButtonColor = true
    button.MouseEnter:Connect(function() button.BackgroundColor3 = Color3.fromRGB(60, 60, 60) end)
    button.MouseLeave:Connect(function() button.BackgroundColor3 = Color3.fromRGB(40, 40, 40) end)

    local lockedTool = nil
    local lockEnabled = false
    local active = false

    local function equipTool()
        local character = player.Character
        if not character then return end
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end

        local tool = character:FindFirstChild(TOOL_NAME) or player.Backpack:FindFirstChild(TOOL_NAME)
        if tool then
            tool.Parent = character
            humanoid:EquipTool(tool)
            lockedTool = tool
            lockEnabled = true
        end
    end

    local function forceEquipLoop()
        spawn(function()
            while active and lockedTool do
                local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid:FindFirstChildOfClass("Tool") ~= lockedTool then
                    lockedTool.Parent = player.Character
                    humanoid:EquipTool(lockedTool)
                end
                task.wait(0.01)
            end
        end)
    end

    local function monitorSentry()
        local conn
        conn = workspace.ChildAdded:Connect(function(child)
            if child.Name == "Sentry_"..player.UserId then
                active = false
                lockEnabled = false
                lockedTool = nil
                button.Text = "Defense"
                conn:Disconnect()
            end
        end)
    end

    local function startAutoUse()
        active = true
        equipTool()
        monitorSentry()
        forceEquipLoop()

        spawn(function()
            while active do
                Event:FireServer()
                task.wait(0)
            end
        end)
    end

    button.MouseButton1Click:Connect(function()
        if not active then
            button.Text = "Running..."
            startAutoUse()
        else
            active = false
            lockEnabled = false
            lockedTool = nil
            button.Text = "Defense"
        end
    end)
end

-- =======================
-- SENTRY PULLER
-- =======================
do
    local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local handledSentries = {}
local distanceInFront = 4
local activeSentries = {}
local swinging = false
local followConnection
local isActive = false

-- Create GUI
local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SentryPullerGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main Button
    local button = Instance.new("TextButton")
    button.Name = "PullButton"
    button.Size = UDim2.new(0, 140, 0, 50)
    button.Position = UDim2.new(1, -150, 0, 10)
    button.AnchorPoint = Vector2.new(0, 0)
    button.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    button.Text = "PULL SENTRIES"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 18
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.Parent = screenGui
    
    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button
    
    -- Gradient effect
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 40, 40))
    }
    gradient.Rotation = 90
    gradient.Parent = button
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(0, 140, 0, 25)
    statusLabel.Position = UDim2.new(1, -150, 0, 65)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Ready"
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.Parent = screenGui
    
    -- Shadow effect for status
    local shadow = Instance.new("UIStroke")
    shadow.Color = Color3.fromRGB(0, 0, 0)
    shadow.Thickness = 2
    shadow.Transparency = 0.5
    shadow.Parent = statusLabel
    
    screenGui.Parent = game:GetService("CoreGui")
    
    return screenGui, button, statusLabel
end

local gui, pullBtn, statusLbl = createGUI()

-- Find all unhandled sentries (excluding player's own)
local function findAllSentries()
    local sentries = {}
    local playerUserId = tostring(player.UserId)
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name:lower():match("^sentry_") and (obj:IsA("BasePart") or obj:IsA("Model")) then
            -- Exclude sentries with player's UserId
            if not obj.Name:lower():find(playerUserId:lower()) and not handledSentries[obj] then
                table.insert(sentries, obj)
            end
        end
    end
    return sentries
end

-- Disable sentry scripts
local function disableSentryTargeting(sentry)
    for _, scr in pairs(sentry:GetDescendants()) do
        if scr:IsA("Script") or scr:IsA("LocalScript") then
            scr.Disabled = true
        end
    end
end

-- Make sentry parts non-collidable
local function makeNonCollidable(sentry)
    for _, part in pairs(sentry:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

-- Equip Bat and swing once (with longer duration)
local function equipAndSwingBat()
    if swinging then return end
    swinging = true
    spawn(function()
        local backpack = player:FindFirstChildOfClass("Backpack")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not (backpack and humanoid) then 
            swinging = false 
            return 
        end
        local bat = backpack:FindFirstChild("Bat") or character:FindFirstChild("Bat")
        if bat then
            humanoid:EquipTool(bat)
            task.wait(0.15)
            if bat.Activate then bat:Activate() end
            task.wait(2.5) -- Increased from 0.9 to 2.5 seconds
            humanoid:UnequipTools()
        end
        swinging = false
    end)
end

-- Wait for 60s label
local function waitFor60sLabel(sentry)
    local timeout, elapsed = 10, 0
    while elapsed < timeout and sentry.Parent do
        for _, d in pairs(sentry:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextButton") then
                local txt = string.lower(d.Text or "")
                if txt:find("60s") then
                    return true
                end
            end
        end
        task.wait(0.3)
        elapsed += 0.3
    end
    return false
end

-- Pull sentries to player and follow perfectly
local function pullSentriesToPlayer(sentries)
    if not humanoidRootPart then return end
    activeSentries = sentries
    
    -- Make all sentries non-collidable and position them
    for _, sentry in ipairs(sentries) do
        makeNonCollidable(sentry)
        local frontCFrame = humanoidRootPart.CFrame * CFrame.new(0, 0, -distanceInFront)
        if sentry:IsA("Model") and sentry.PrimaryPart then
            sentry:SetPrimaryPartCFrame(frontCFrame)
        elseif sentry:IsA("BasePart") then
            sentry.CFrame = frontCFrame
        end
    end
    
    -- Swing bat immediately
    equipAndSwingBat()
    
    -- Follow sentries every frame
    if followConnection then followConnection:Disconnect() end
    followConnection = RunService.RenderStepped:Connect(function()
        if not isActive or not humanoidRootPart.Parent then
            if followConnection then followConnection:Disconnect() end
            return
        end
        
        for _, sentry in ipairs(activeSentries) do
            if sentry and sentry.Parent then
                local targetCFrame = humanoidRootPart.CFrame * CFrame.new(0, 0, -distanceInFront)
                if sentry:IsA("Model") and sentry.PrimaryPart then
                    sentry:SetPrimaryPartCFrame(targetCFrame)
                elseif sentry:IsA("BasePart") then
                    sentry.CFrame = targetCFrame
                end
            end
        end
    end)
end

-- Main pull function
local function pullAllSentries()
    if isActive then
        -- Stop pulling
        isActive = false
        if followConnection then 
            followConnection:Disconnect() 
        end
        pullBtn.Text = "PULL SENTRIES"
        pullBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        statusLbl.Text = "Stopped"
        statusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    isActive = true
    pullBtn.Text = "STOP"
    pullBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
    statusLbl.Text = "Finding sentries..."
    statusLbl.TextColor3 = Color3.fromRGB(255, 255, 100)
    
    local sentries = findAllSentries()
    
    if #sentries == 0 then
        statusLbl.Text = "No sentries found"
        statusLbl.TextColor3 = Color3.fromRGB(255, 150, 50)
        isActive = false
        pullBtn.Text = "PULL SENTRIES"
        pullBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        return
    end
    
    statusLbl.Text = string.format("Found %d sentries", #sentries)
    statusLbl.TextColor3 = Color3.fromRGB(100, 255, 100)
    
    -- Mark as handled and disable targeting
    for _, sentry in ipairs(sentries) do
        handledSentries[sentry] = true
        disableSentryTargeting(sentry)
    end
    
    -- Wait for 60s labels on all sentries
    task.spawn(function()
        local validSentries = {}
        for _, sentry in ipairs(sentries) do
            if waitFor60sLabel(sentry) then
                table.insert(validSentries, sentry)
            end
        end
        
        if #validSentries > 0 then
            statusLbl.Text = string.format("Pulling %d sentries", #validSentries)
            pullSentriesToPlayer(validSentries)
        else
            statusLbl.Text = "No valid sentries"
            isActive = false
            pullBtn.Text = "PULL SENTRIES"
            pullBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        end
    end)
end

-- Button click handler
pullBtn.MouseButton1Click:Connect(function()
    pullAllSentries()
end)

-- Recreate GUI if removed
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "SentryPullerGUI" then
        gui, pullBtn, statusLbl = createGUI()
        
        pullBtn.MouseButton1Click:Connect(function()
            pullAllSentries()
        end)
    end
end)

-- Update character reference on respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
end)

-- =======================
-- PROXIMITY PROMPT BUTTONS
-- =======================
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local yCoordinates = {
    [1] = -3.73539066,
    [2] = 15.672575,
    [3] = 22.9842033
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProximityPromptGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Container positioned above toolbar (horizontal layout)
local container = Instance.new("Frame")
container.Size = UDim2.new(0, 210, 0, 50)
container.Position = UDim2.new(0.5, -105, 1, -120) -- Centered above toolbar, slightly higher
container.BackgroundTransparency = 1
container.Parent = screenGui

local function createButton(number)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 60, 0, 40)
    button.Position = UDim2.new(0, (number - 1) * 70 + 5, 0, 5)
    button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    button.Text = tostring(number)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 20
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 2
    button.BorderColor3 = Color3.fromRGB(255, 255, 255)
    button.Parent = container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(230, 40, 40)
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    end)
    
    return button
end

local buttons = {}
for i = 1, 3 do
    buttons[i] = createButton(i)
end

local currentLine = nil

local function createLineToPrompt(promptPosition)
    if currentLine then
        currentLine:Destroy()
    end
    
    local character = player.Character
    if not character then return end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local line = Instance.new("Part")
    line.Anchored = true
    line.CanCollide = false
    line.Material = Enum.Material.Neon
    line.Color = Color3.fromRGB(0, 255, 0)
    line.TopSurface = Enum.SurfaceType.Smooth
    line.BottomSurface = Enum.SurfaceType.Smooth
    
    local startPos = humanoidRootPart.Position
    local endPos = promptPosition
    local distance = (endPos - startPos).Magnitude
    
    line.Size = Vector3.new(0.2, 0.2, distance)
    line.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -distance / 2)
    line.Parent = workspace
    
    currentLine = line
    
    task.delay(3, function()
        if line and line.Parent then
            line:Destroy()
        end
    end)
end

local function getAllProximityPrompts()
    local prompts = {}
    
    for _, descendant in pairs(workspace:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            local parent = descendant.Parent
            while parent do
                if parent:IsA("Folder") and parent.Name == "Unlock" then
                    table.insert(prompts, descendant)
                    break
                end
                parent = parent.Parent
            end
        end
    end
    
    return prompts
end

local function findNearestPromptAtY(prompts, targetY)
    local character = player.Character
    if not character then return nil end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local nearestPrompt = nil
    local shortestDistance = math.huge
    local playerPosition = humanoidRootPart.Position
    
    local yTolerance = 5
    
    for _, prompt in pairs(prompts) do
        if prompt.Enabled and prompt.Parent then
            local promptPosition = prompt.Parent.Position
            local yDifference = math.abs(promptPosition.Y - targetY)
            
            if yDifference <= yTolerance then
                local distance = (playerPosition - promptPosition).Magnitude
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestPrompt = prompt
                end
            end
        end
    end
    
    return nearestPrompt, shortestDistance
end

local function activatePromptAtY(buttonNumber)
    local button = buttons[buttonNumber]
    local targetY = yCoordinates[buttonNumber]
    
    button.Text = "..."
    button.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    
    wait(0.1)
    
    local prompts = getAllProximityPrompts()
    
    if #prompts == 0 then
        button.Text = "X"
        wait(1)
        button.Text = tostring(buttonNumber)
        button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        return
    end
    
    -- Store original values with proper cleanup tracking
    local originalValues = {}
    for _, prompt in pairs(prompts) do
        if prompt and prompt.Parent then
            originalValues[prompt] = {
                MaxActivationDistance = prompt.MaxActivationDistance,
                HoldDuration = prompt.HoldDuration,
                RequiresLineOfSight = prompt.RequiresLineOfSight
            }
        end
    end
    
    -- Modify prompts
    for _, prompt in pairs(prompts) do
        if prompt and prompt.Parent then
            prompt.MaxActivationDistance = 999999
            prompt.HoldDuration = 0
            prompt.RequiresLineOfSight = false
        end
    end
    
    local nearestPrompt, distance = findNearestPromptAtY(prompts, targetY)
    
    if nearestPrompt then
        local promptPosition = nearestPrompt.Parent.Position
        createLineToPrompt(promptPosition)
        
        local success = false
        
        pcall(function()
            nearestPrompt.Triggered:Fire(player)
            success = true
        end)
        
        if not success then
            pcall(function()
                nearestPrompt.Triggered:Fire()
                success = true
            end)
        end
        
        if not success and fireproximityprompt then
            pcall(function()
                fireproximityprompt(nearestPrompt, 0)
                success = true
            end)
        end
        
        if success then
            button.Text = "✓"
            button.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
        else
            button.Text = "X"
            button.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        end
        
        wait(1)
        button.Text = tostring(buttonNumber)
        button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    else
        button.Text = "X"
        wait(1)
        button.Text = tostring(buttonNumber)
        button.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    end
    
    -- ALWAYS restore original values, even if prompt was destroyed
    task.spawn(function()
        wait(0.5) -- Small delay to ensure activation completed
        for prompt, values in pairs(originalValues) do
            -- Check if prompt still exists before restoring
            if prompt and prompt.Parent then
                pcall(function()
                    prompt.MaxActivationDistance = values.MaxActivationDistance
                    prompt.HoldDuration = values.HoldDuration
                    prompt.RequiresLineOfSight = values.RequiresLineOfSight
                end)
            end
        end
    end)
end

for i = 1, 3 do
    buttons[i].MouseButton1Click:Connect(function()
        activatePromptAtY(i)
    end)
end