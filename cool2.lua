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