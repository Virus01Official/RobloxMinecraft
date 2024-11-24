local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Create a new model for the viewmodel
local ViewModel = script.Viewmodel
ViewModel.Parent = Camera

-- Function to update the viewmodel position and orientation
local function updateViewModel()
    -- Example: Position the viewmodel in front of the camera
    local cameraCFrame = Camera.CFrame
	ViewModel:SetPrimaryPartCFrame(cameraCFrame * CFrame.new(2, -1, -2))
	ViewModel:SetPrimaryPartCFrame(ViewModel:GetPrimaryPartCFrame() * CFrame.Angles(math.rad(-90), 0, 0))
end

-- Connect the update function to the RenderStepped event
RunService.RenderStepped:Connect(updateViewModel)

