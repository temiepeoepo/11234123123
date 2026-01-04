local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local isPlaying = false
local bestPetModel = nil

local detectedPets = {}

local originalSizes = {}

-- Saved Positions (8 total)
local savedPositions = {
	Vector3.new(-340.85, 14.90, 6.69),
	Vector3.new(-341.14, 14.90, 113.76),
	Vector3.new(-341.25, 14.96, 221.40),
	Vector3.new(-478.53, 14.90, 220.10),
	Vector3.new(-478.29, 14.90, 113.33),
	Vector3.new(-478.81, 14.90, 6.43),
	Vector3.new(-478.45, 14.96, -100.71),
	Vector3.new(-341.11, 14.90, -99.67)
}

local UPPER_FLOOR_Y_THRESHOLD = 10

local function crunchBody()
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part ~= humanoidRootPart then
			originalSizes[part] = part.Size
			part.Size = Vector3.new(0.1, 0.1, 0.1)
		end
	end
end

local function restoreBody()
	for part, originalSize in pairs(originalSizes) do
		if part and part.Parent then
			part.Size = originalSize
		end
	end
	originalSizes = {}
end

local function findClosestGreenPart(fromPosition)
	local closestPart = nil
	local closestDistance = math.huge
	
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			local color = obj.Color
			if math.floor(color.R * 255) == 0 and math.floor(color.G * 255) == 195 and math.floor(color.B * 255) == 0 then
				local distance = (obj.Position - fromPosition).Magnitude
				if distance < closestDistance then
					closestDistance = distance
					closestPart = obj
				end
			end
		end
	end
	
	return closestPart
end

local function createGreenPartESP(greenPart)
	local existing = greenPart:FindFirstChild("GreenPartESP")
	if existing then
		existing:Destroy()
	end
	
	local highlight = Instance.new("Highlight")
	highlight.Name = "GreenPartESP"
	highlight.Adornee = greenPart
	highlight.FillColor = Color3.fromRGB(0, 255, 0)
	highlight.OutlineColor = Color3.fromRGB(0, 195, 0)
	highlight.FillTransparency = 0.3
	highlight.OutlineTransparency = 0
	highlight.Parent = greenPart
	
	return highlight
end

local function createPetESP(petPart, petName, petValue)
	local existing = petPart:FindFirstChild("PetESP")
	if existing then
		existing:Destroy()
	end
	
	local highlight = Instance.new("Highlight")
	highlight.Name = "PetESP"
	highlight.Adornee = petPart
	highlight.FillColor = Color3.fromRGB(255, 215, 0)
	highlight.OutlineColor = Color3.fromRGB(255, 165, 0)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.Parent = petPart
	
	return highlight
end

local function findClosestSavedPosition(fromPosition)
	local closestPos = nil
	local closestDistance = math.huge
	
	for _, pos in ipairs(savedPositions) do
		local distance = (pos - fromPosition).Magnitude
		if distance < closestDistance then
			closestDistance = distance
			closestPos = pos
		end
	end
	
	return closestPos
end

local function getCardinalDirection(fromPos, toPos)
	local direction = (toPos - fromPos).Unit
	local angle = math.atan2(direction.X, direction.Z)
	
	-- Convert to degrees
	local degrees = math.deg(angle)
	
	-- Normalize to 0-360
	if degrees < 0 then
		degrees = degrees + 360
	end
	
	-- Determine cardinal direction (N, S, E, W)
	-- North = 0째, East = 90째, South = 180째, West = 270째
	if degrees >= 315 or degrees < 45 then
		return 0 -- North
	elseif degrees >= 45 and degrees < 135 then
		return 90 -- East
	elseif degrees >= 135 and degrees < 225 then
		return 180 -- South
	else
		return 270 -- West
	end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleSkyLaunch"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local launchButton = Instance.new("TextButton")
launchButton.Name = "LaunchButton"
launchButton.Size = UDim2.new(0, isMobile and 100 or 120, 0, isMobile and 35 or 40)
launchButton.Position = UDim2.new(1, isMobile and -110 or -130, 0, 10)
launchButton.BackgroundColor3 = Color3.fromRGB(255, 127, 80)
launchButton.BorderSizePixel = 0
launchButton.Text = isMobile and "Launch" or "Sky Launch"
launchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
launchButton.TextSize = isMobile and 12 or 14
launchButton.Font = Enum.Font.GothamBold
launchButton.AutoButtonColor = false
launchButton.Parent = screenGui

local launchCorner = Instance.new("UICorner")
launchCorner.CornerRadius = UDim.new(0, 8)
launchCorner.Parent = launchButton

local function parseMoney(text)
	text = string.lower(text or "")
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

local plotsCache = {}
local plotsCacheTime = 0

local function findAllPlots()
	if tick() - plotsCacheTime < 30 and #plotsCache > 0 then
		return plotsCache
	end
	
	plotsCache = {}
	
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and (obj.Name:lower():find("plot") or obj.Name:lower():find("base")) then
			for _, part in ipairs(obj:GetDescendants()) do
				if part:IsA("BasePart") then
					table.insert(plotsCache, part)
				end
			end
		end
	end
	
	plotsCacheTime = tick()
	return plotsCache
end

local playerBaseModel = nil
local playerBaseCached = false

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
					if part then
						pos = part.Position
					end
				end
				
				if pos then
					local dist = (pos - root.Position).Magnitude
					if not closest or dist < closestDist then
						closestDist = dist
						closest = billboard
					end
				end
			end
			
			if closest then
				return closest
			end
		end
	end
	
	return visibleBillboards[1]
end

local function findPlayerBase()
	if playerBaseCached then return end
	
	local billboard = findBaseBillboard()
	if billboard then
		local baseModel = billboard.Parent
		if baseModel then
			local parentModel = baseModel.Parent
			if parentModel and (parentModel:IsA("Model") or parentModel:IsA("Folder")) then
				playerBaseModel = parentModel
				playerBaseCached = true
				return
			end
			if baseModel:IsA("Model") or baseModel:IsA("Folder") then
				playerBaseModel = baseModel
				playerBaseCached = true
				return
			end
		end
	end
end

local function isPetNearPlayerBase(petPart)
	if not petPart or not playerBaseModel then return false end
	
	if petPart:IsDescendantOf(playerBaseModel) then
		return true
	end
	
	for _, basePart in ipairs(playerBaseModel:GetDescendants()) do
		if basePart:IsA("BasePart") then
			local distance = (basePart.Position - petPart.Position).Magnitude
			if distance <= 15 then
				return true
			end
		end
	end
	
	return false
end

local function isPetNearAnyPlot(petPart)
	if not petPart then return false end
	
	local allPlots = findAllPlots()
	
	for _, plotPart in ipairs(allPlots) do
		local distance = (plotPart.Position - petPart.Position).Magnitude
		if distance <= 23 then
			return true
		end
	end
	
	return false
end

local function findAllPetsInDebris()
	local results = {}
	
	local debrisFolder = workspace:FindFirstChild("Debris")
	if not debrisFolder then
		return results
	end
	
	for _, obj in ipairs(debrisFolder:GetChildren()) do
		if obj:IsA("BasePart") then
			local displayNameLabel = nil
			local generationLabel = nil
			
			for _, child in ipairs(obj:GetChildren()) do
				if child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
					for _, label in ipairs(child:GetChildren()) do
						if label:IsA("TextLabel") then
							local labelName = label.Name
							if labelName == "DisplayName" then
								displayNameLabel = label
							elseif labelName == "Generation" then
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
				
				if not isPetNearPlayerBase(obj) and isPetNearAnyPlot(obj) then
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

local function updateBestPet()
	-- Clear old ESPs
	for oldPart, _ in pairs(detectedPets) do
		if oldPart then
			local oldHighlight = oldPart:FindFirstChild("PetESP")
			if oldHighlight then
				oldHighlight:Destroy()
			end
		end
	end
	
	detectedPets = {}
	local allPets = findAllPetsInDebris()
	
	local bestValue = -math.huge
	bestPetModel = nil
	
	for _, petData in ipairs(allPets) do
		detectedPets[petData.part] = {
			name = petData.displayName,
			value = petData.value,
			part = petData.part
		}
		
		-- Create ESP for all detected pets
		createPetESP(petData.part, petData.displayName, petData.generation)
		
		if petData.value > bestValue then
			bestValue = petData.value
			bestPetModel = petData.part
		end
	end
end

task.spawn(function()
	findPlayerBase()
	
	while true do
		task.wait(10)
		if not playerBaseCached then
			findPlayerBase()
		end
	end
end)

task.spawn(function()
	while true do
		updateBestPet()
		task.wait(2)
	end
end)

local function doLaunch()
	if isPlaying then return end
	
	local targetPet = bestPetModel
	
	if not targetPet then
		warn("Launch failed: No target found!")
		return
	end
	
	local targetPart = targetPet
	if not targetPart then
		warn("Launch failed: Can't find pet location!")
		return
	end
	
	isPlaying = true
	launchButton.BackgroundColor3 = Color3.fromRGB(180, 90, 50)
	launchButton.Text = "Launching..."
	
	-- Equip carpet
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		local carpet = backpack:FindFirstChild("Flying Carpet")
		if carpet and character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid:EquipTool(carpet)
			end
		end
	end
	
	-- Crunch body for safety
	crunchBody()
	
	-- Disable ragdoll/falling
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	end
	
	-- Check if pet is on upper floor
	local isUpperFloor = targetPart.Position.Y > UPPER_FLOOR_Y_THRESHOLD
	
	if isUpperFloor then
		print("Pet detected on upper floor! Teleporting to closest saved position...")
		
		-- Find closest saved position
		local closestPos = findClosestSavedPosition(targetPart.Position)
		
		if closestPos then
			-- Phase 1: Launch upward with velocity
			print("Phase 1: Launching upward...")
			humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 200, 0)
			task.wait(0.2)
			
			-- Stop all velocity
			humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			
			-- Phase 2: Teleport to closest saved position
			print("Phase 2: Teleporting to saved position...")
			humanoidRootPart.CFrame = CFrame.new(closestPos)
			humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			
			task.wait(0.3)
		else
			warn("No saved position found!")
		end
	else
		-- Original ground floor logic
		-- Find the green part closest to the pet
		local greenPart = findClosestGreenPart(targetPart.Position)
		
		if not greenPart then
			warn("Launch failed: No green part found near target!")
			restoreBody()
			isPlaying = false
			launchButton.BackgroundColor3 = Color3.fromRGB(255, 127, 80)
			launchButton.Text = isMobile and "Launch" or "Sky Launch"
			if humanoid then
				humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
			end
			return
		end
		
		-- Create ESP for the green part
		local greenESP = createGreenPartESP(greenPart)
		
		local greenTargetPos = greenPart.Position + Vector3.new(0, math.min(9, greenPart.Size.Y/2 + 5), 0)
		
		-- Phase 1: Launch upward with velocity
		print("Phase 1: Launching upward...")
		humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 200, 0)
		task.wait(0.2)
		
		-- Stop all velocity
		humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		
		-- Phase 2: Teleport to green part
		print("Phase 2: Teleporting to green part...")
		humanoidRootPart.CFrame = CFrame.new(greenTargetPos)
		humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		
		task.wait(0.3)
		
		if greenESP then
			greenESP:Destroy()
		end
	end
	
	-- Cleanup
	restoreBody()
	
	task.wait(0.1)
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
	end
	
	isPlaying = false
	launchButton.BackgroundColor3 = Color3.fromRGB(255, 127, 80)
	launchButton.Text = isMobile and "Launch" or "Sky Launch"
	print("Launch complete!")
end

launchButton.MouseButton1Click:Connect(function()
	doLaunch()
end)

launchButton.MouseEnter:Connect(function()
	if not isPlaying then
		launchButton.BackgroundColor3 = Color3.fromRGB(255, 150, 110)
	end
end)

launchButton.MouseLeave:Connect(function()
	if not isPlaying then
		launchButton.BackgroundColor3 = Color3.fromRGB(255, 127, 80)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	local focusedTextBox = UserInputService:GetFocusedTextBox()
	if focusedTextBox then return end
	
	if input.KeyCode == Enum.KeyCode.X then
		doLaunch()
	end
end)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	originalSizes = {}
end)

-- Auto-launch on script start after finding the highest value pet
task.spawn(function()
	print("Scanning for best pet...")
	updateBestPet()
	
	if bestPetModel then
		print("Best pet found! Auto-launching...")
		doLaunch()
	else
		print("No pets detected on startup.")
	end
end)
