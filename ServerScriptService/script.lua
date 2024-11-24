-- Constants
local CHUNK_SIZE = 4        -- Number of blocks per chunk (width/length)
local BLOCK_SIZE = 4         -- Size of each block
local HEIGHT_SCALE = 5      -- Maximum height variation
local PERLIN_SCALE = 0.2     -- Controls terrain smoothness
local GROUND_LEVEL = 0       -- Base level for the flat ground
local LOAD_RADIUS = 3        -- How many chunks to load around the player
local STRUCTURE_SPAWN_CHANCE = 0 -- 0% chance for a structure in a chunk
local CurrentBiome = "Plain"

-- Seed for world generation
local WORLD_SEED = math.random(0, 999999)

-- Parent folder for blocks and structures
local WorldFolder = Instance.new("Folder")
WorldFolder.Name = "GeneratedWorld"
WorldFolder.Parent = workspace

-- Structure library
local StructureLibrary = {
	House = game.ServerStorage:WaitForChild("House") -- Example structure
}

-- Biomes
local Biomes = {
	["Plain"] = {
		HEIGHT_SCALE = 5
	},
	["Mountains"] = {
		HEIGHT_SCALE = 10
	},
}

-- Store loaded chunks
local loadedChunks = {}

local BlockModificationModule = require(game.ServerStorage.BlockModificationModule)
local blockModifications = BlockModificationModule.blockModifications -- Shared data table

-- Function to calculate height using Perlin noise
local function getHeight(x, z)
	local noiseValue = math.noise((x + WORLD_SEED) * PERLIN_SCALE, (z + WORLD_SEED) * PERLIN_SCALE)
	return math.floor(noiseValue * HEIGHT_SCALE + 0.5) -- Rounded for consistent heights
end

-- Function to create a block
local function createBlock(x, y, z, parent)
	local block = Instance.new("Part")
	block.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
	block.Position = Vector3.new(x, y, z)
	block.Anchored = true
	block.TopSurface = Enum.SurfaceType.Smooth
	block.BottomSurface = Enum.SurfaceType.Smooth
	block.BrickColor = BrickColor.Green()
	block.Material = Enum.Material.Grass
	block.Parent = parent
end

-- Function to place a structure
local function placeStructure(structureName, x, z, parent)
	local structureModel = StructureLibrary[structureName]:Clone()
	local height = getHeight(x / BLOCK_SIZE, z / BLOCK_SIZE) * BLOCK_SIZE

	structureModel:SetPrimaryPartCFrame(CFrame.new(x, height, z))
	structureModel.Parent = parent
end

-- Function to generate a chunk
local function generateChunk(chunkX, chunkZ)
	local chunkKey = chunkX .. "," .. chunkZ
	if loadedChunks[chunkKey] then return end -- Skip if already generated

	-- Create a folder for the chunk
	local chunkFolder = Instance.new("Folder")
	chunkFolder.Name = "Chunk_" .. chunkKey
	chunkFolder.Parent = WorldFolder

	-- Generate the flat ground layer for this chunk
	for x = 0, CHUNK_SIZE - 1 do
		for z = 0, CHUNK_SIZE - 1 do
			local worldX = (chunkX * CHUNK_SIZE + x) * BLOCK_SIZE
			local worldZ = (chunkZ * CHUNK_SIZE + z) * BLOCK_SIZE

			-- Check if this block was destroyed
			local blockKey = tostring(Vector3.new(worldX, GROUND_LEVEL, worldZ))
			if blockModifications[chunkKey] and blockModifications[chunkKey][blockKey] then
				continue -- Skip creation if the block was destroyed
			end

			-- Create the ground block
			createBlock(worldX, GROUND_LEVEL, worldZ, chunkFolder)

			-- Calculate surface height
			local surfaceHeight = getHeight(worldX / BLOCK_SIZE, worldZ / BLOCK_SIZE) * BLOCK_SIZE

			-- Fill blocks up to the surface
			for y = GROUND_LEVEL + BLOCK_SIZE, surfaceHeight, BLOCK_SIZE do
				local blockYKey = tostring(Vector3.new(worldX, y, worldZ))
				if blockModifications[chunkKey] and blockModifications[chunkKey][blockYKey] then
					continue -- Skip creation if the block was destroyed
				end
				createBlock(worldX, y, worldZ, chunkFolder)
			end
		end
	end

	-- Spawn a structure (random chance)
	if math.random() < STRUCTURE_SPAWN_CHANCE then
		local structureType = "House" -- Example: use "House" structure
		local structureX = chunkX * CHUNK_SIZE * BLOCK_SIZE + math.random(0, CHUNK_SIZE - 1) * BLOCK_SIZE
		local structureZ = chunkZ * CHUNK_SIZE * BLOCK_SIZE + math.random(0, CHUNK_SIZE - 1) * BLOCK_SIZE
		placeStructure(structureType, structureX, structureZ, chunkFolder)
	end

	-- Mark the chunk as loaded
	loadedChunks[chunkKey] = chunkFolder
end

-- Function to unload chunks outside the radius
local function unloadChunks(playerChunkX, playerChunkZ)
	for chunkKey, chunkFolder in pairs(loadedChunks) do
		local chunkX, chunkZ = chunkKey:match("([^,]+),([^,]+)")
		chunkX = tonumber(chunkX)
		chunkZ = tonumber(chunkZ)

		local distance = math.sqrt((chunkX - playerChunkX)^2 + (chunkZ - playerChunkZ)^2)
		if distance > LOAD_RADIUS then
			chunkFolder:Destroy()
			loadedChunks[chunkKey] = nil
		end
	end
end

-- Function to update chunks around the player
local function updateChunks(playerPosition)
	local playerChunkX = math.floor(playerPosition.X / (CHUNK_SIZE * BLOCK_SIZE))
	local playerChunkZ = math.floor(playerPosition.Z / (CHUNK_SIZE * BLOCK_SIZE))

	-- Load chunks within the radius
	for x = -LOAD_RADIUS, LOAD_RADIUS do
		for z = -LOAD_RADIUS, LOAD_RADIUS do
			generateChunk(playerChunkX + x, playerChunkZ + z)
		end
	end

	-- Unload distant chunks
	unloadChunks(playerChunkX, playerChunkZ)
end

-- Main loop: monitor player position and generate chunks
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

		while true do
			-- Update chunks based on the player's position
			updateChunks(humanoidRootPart.Position)
			wait(0.5) -- Adjust as needed for performance
		end
	end)
end)
