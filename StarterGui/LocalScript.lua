local player = game.Players.LocalPlayer
local UIS = game:GetService('UserInputService')

UIS.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		--raycast from the camera, if it hits a part then send it to the remote
		local mouse = game.Players.LocalPlayer:GetMouse()
		local ray = Ray.new(mouse.UnitRay.Origin, mouse.UnitRay.Direction * 15)
		local part, position = workspace:FindPartOnRay(ray, player.Character)
		if part then
			game.ReplicatedStorage.BlockBreak:FireServer(part, player)
		end
	end
end)
