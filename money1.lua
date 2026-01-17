local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local coreGui = game:GetService("CoreGui")

-- Create toggle GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "XenNotifierToggle"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 150, 0, 40)
toggleButton.Position = UDim2.new(0.75, -75, 0, 10)
toggleButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Text = "XenNotifier: OFF"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 14
toggleButton.Active = true
toggleButton.Draggable = true
toggleButton.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = toggleButton

-- State
local notifierEnabled = false
local xenNotifier = nil

-- Function to wait for XenNotifier (non-laggy)
local function waitForXenNotifier()
    spawn(function()
        while not xenNotifier do
            xenNotifier = coreGui:FindFirstChild("XenNotifier")
            if xenNotifier then
                print("XenNotifier found!")
                -- Start with it disabled
                xenNotifier.Enabled = false
            end
            wait(0.5)
        end
    end)
end

-- Toggle button functionality
toggleButton.MouseButton1Click:Connect(function()
    if not xenNotifier then
        warn("XenNotifier not found yet!")
        return
    end
    
    notifierEnabled = not notifierEnabled
    
    if notifierEnabled then
        toggleButton.Text = "XenNotifier: ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
        xenNotifier.Enabled = true
    else
        toggleButton.Text = "XenNotifier: OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        xenNotifier.Enabled = false
    end
end)

-- Start searching
waitForXenNotifier()

print("XenNotifier Toggle Active")
print("Button is draggable - position it wherever you want!")
print("Starts OFF (red) - Click to turn ON (green)")