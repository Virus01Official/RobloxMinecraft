-- Constants
local CHUNK_SIZE = 16       -- Number of blocks per chunk (width/length)
local BLOCK_SIZE = 4        -- Size of each block
local HEIGHT_SCALE = 20     -- Maximum height variation
local PERLIN_SCALE = 0.1    -- Controls the frequency of terrain variation
local GROUND_LEVEL = 0      -- Flat ground level
local LOAD_RADIUS = 3       -- How many chunks to load around the player
local UNLOAD_RADIUS = LOAD_RADIUS + 1 -- Unload chunks slightly farther away

-- Parent folder for blocks
local BlocksFolder = Instance.new("Folder")
BlocksFolder.Name = "GeneratedWorld"
BlocksFolder.Parent = workspace

-- Store generated chunks
local loadedChunks = {}

-- Function to create a block
local function createBlock(x, y, z, parent)
	local block = Instance.new("Part")
	block.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
	block.Position = Vector3.new(x, y, z)
	block.Anchored = true
	block.TopSurface = Enum.SurfaceType.Smooth
	block.BottomSurface = Enum.SurfaceType.Smooth
	block.Parent = parent
end

-- Function to calculate Perlin noise height, aligned to grid
local function getHeight(x, z)
	-- Ensure x and z are grid-aligned to avoid floating-point mismatches
	local noiseValue = math.noise(x * PERLIN_SCALE, z * PERLIN_SCALE)
	return math.floor(noiseValue * HEIGHT_SCALE + 0.5) -- Rounded height for consistency
end

-- Function to generate a chunk
local function generateChunk(chunkX, chunkZ)
	local chunkKey = chunkX .. "," .. chunkZ
	if loadedChunks[chunkKey] then return end -- Skip if already generated

	-- Create a folder for the chunk
	local chunkFolder = Instance.new("Folder")
	chunkFolder.Name = "Chunk_" .. chunkKey
	chunkFolder.Parent = BlocksFolder

	-- Generate the flat ground layer for this chunk
	for x = 0, CHUNK_SIZE - 1 do
		for z = 0, CHUNK_SIZE - 1 do
			-- Grid-aligned positions
			local worldX = (chunkX * CHUNK_SIZE + x) * BLOCK_SIZE
			local worldZ = (chunkZ * CHUNK_SIZE + z) * BLOCK_SIZE

			-- Create the flat ground layer
			createBlock(worldX, GROUND_LEVEL, worldZ, chunkFolder)

			-- Calculate height (align height generation to grid)
			local surfaceHeight = getHeight(worldX / BLOCK_SIZE, worldZ / BLOCK_SIZE) * BLOCK_SIZE

			-- Fill blocks from the ground to the surface
			for y = GROUND_LEVEL + BLOCK_SIZE, surfaceHeight, BLOCK_SIZE do
				createBlock(worldX, y, worldZ, chunkFolder)
			end
		end
	end

	-- Mark this chunk as loaded
	loadedChunks[chunkKey] = chunkFolder
end

-- Function to unload chunks outside the radius
local function unloadChunks(playerChunkX, playerChunkZ)
	for chunkKey, chunkFolder in pairs(loadedChunks) do
		local chunkX, chunkZ = chunkKey:match("([^,]+),([^,]+)")
		chunkX = tonumber(chunkX)
		chunkZ = tonumber(chunkZ)

		local distance = math.sqrt((chunkX - playerChunkX)^2 + (chunkZ - playerChunkZ)^2)
		if distance > UNLOAD_RADIUS then
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
