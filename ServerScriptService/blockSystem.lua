local BlockModificationModule = require(game.ServerStorage.BlockModificationModule)
local blockModifications = BlockModificationModule.blockModifications -- Shared data table

local replicated = game.ReplicatedStorage
local Remote = replicated.BlockBreak

Remote.OnServerEvent:Connect(function(player, Block)
	if Block and Block.Parent.Name:match("^Chunk_") then
		local chunkKey = Block.Parent.Name:match("^Chunk_(.+)")
		local blockKey = tostring(Block.Position)

		-- Track the block destruction
		blockModifications[chunkKey] = blockModifications[chunkKey] or {}
		blockModifications[chunkKey][blockKey] = true

		Block:Destroy()
	else
		return
	end
end)
