renderer:setShadowRadius(0)
vanilla_model.ARMOR:setVisible(false)
vanilla_model.CAPE:setVisible(false)
vanilla_model.ELYTRA:setVisible(false)
vanilla_model.PLAYER:setVisible(false)


local runLater = require("runLater")
local mainPage = action_wheel:newPage()
action_wheel:setPage(mainPage)

local lock = false
local commandBlock = false
function pings.lock(boo)
	lock = boo
	if not boo then
		commandBlock = false
	end
end

local locAct = mainPage:newAction()
	:onToggle(pings.lock)
	:item("minecraft:iron_block")
	:hoverColor(1, 0.8470588235294118, 0.00392156862745098)
	:title('[{"text":"Lock Block Shifting","color":"red"}]')
	:toggleTitle('[{"text":"Lock Block Shifting","color":"green"}]')

models.blockModel.block:setVisible(false)
models.blockModel.block:setScale(math.worldScale)
local blocktaskthing = models.blockModel.blockTask:newBlock("hi")
blocktaskthing:setScale(math.worldScale)
local blockScale = 1
function pings.scale(dirowo)
	if dirowo > 0 then blockScale = blockScale + 0.25 end
	if dirowo < 0 then blockScale = blockScale - 0.25 end
	blocktaskthing:setScale(blockScale)
	blockScale = math.clamp(blockScale, 0.25, 15)
	models.blockModel.block:setScale(blockScale)
end

function pings.scaleReset()
	blockScale = 1
	blocktaskthing:setScale(blockScale)
	models.blockModel.block:setScale(blockScale)
end

local snapped
function pings.enableSnap(bool)
	snapped = bool
end

local snapAct = mainPage:newAction()
	:onToggle(pings.enableSnap)
	:title('[{"text":"Toggle Snapping","color":"red"}]')
	:toggleTitle('[{"text":"Toggle Snapping","color":"green"}]')
	:hoverColor(0.365, 0.98, 0.847)
	:item("minecraft:waxed_oxidized_cut_copper_stairs")


local scaleAct = mainPage:newAction()
	:onScroll(function(dir, self)
		pings.scale(dir)
		runLater(1,
			function()
				self:setTitle('[{"text":"Scale Block (Scale: ' ..
					blockScale .. ')","color":"#affab8"}]')
			end)
	end)
	:onRightClick(function(self)
		pings.scaleReset()
		runLater(1,
			function()
				self:setTitle('[{"text":"Scale Block (Scale: ' ..
					blockScale .. ')","color":"#affab8"}]')
			end)
	end)
	:item("minecraft:bamboo")
	:hoverColor(0.19607843137, 0.80392156862, 0.19607843137)
	:title('[{"text":"Scale Block","color":"#affab8"}]')


function pings.lockBlock(message)
	if message:match("^/lockblock%s+%S+$") then
		if pcall(world.newBlock, "minecraft:" .. message:sub(12)) then
			locAct:setToggled(true)
			lock = true
			blocktaskthing:setBlock("minecraft:" .. message:sub(12))
			commandBlock = "minecraft:" .. message:sub(12)
			local blockname
			if pcall(function()
					local _ = world.newItem("minecraft:" .. message:sub(12)):getName()
				end) then
				blockname = world.newItem("minecraft:" .. message:sub(12)):getName()
			else
				blockname = "minecraft:" .. message:sub(12)
			end
			logJson('{"text":"Block locked to ' ..
				blockname ..
				'","color":"#32CD32"}')
			host:appendChatHistory(message)
			return nil
		else
			logJson('{"text":"Your provided block of ' ..
				message:sub(12) .. ' was invalid.","color":"#FF0000"}')
			commandBlock = false
			host:appendChatHistory(message)
			return nil
		end
	elseif message:match("^/lockblock%s*$") then
		locAct:setToggled(not lock)
		lock = not lock
		if lock then
			logJson('{"text":"Block locking enabled","color":"#32CD32"}')
		else
			logJson(
				'{"text":"Block locking disabled","color":"#32CD32"}')
		end
		host:appendChatHistory(message)
		return nil
	end
	return message
end

function events.CHAT_SEND_MESSAGE(message)
	if message:match("^/lockblock") then
		message = pings.lockBlock(message)
	end
	return message
end

local oldCoords
local blockTimer = 0
function events.tick()
	-- initialize useful variables
	local blockPos = player:getPos().y - 0.001
	local fullBlockPos = vec(player:getPos().x, blockPos, player:getPos().z)
	local biomeType = world.getBiome(fullBlockPos)
	local grassColor = biomeType:getGrassColor()
	local id = commandBlock and commandBlock or world.getBlockState(fullBlockPos).id
	local flooredCoords = vec((player:getPos():floor()):unpack())

	-- handle increasing and resetting blockTimer for snapping
	if oldCoords ~= flooredCoords then blockTimer = 0 end
	if oldCoords == flooredCoords then blockTimer = blockTimer + 1 end
	oldCoords = flooredCoords
	if id == "minecraft:grass_block" then -- apply grass coloring in case they locked it without a command and moved biomes
		models.blockModel.block.upCube:setColor(grassColor)
		models.blockModel.block.northOverlay:setColor(grassColor)
		models.blockModel.block.southOverlay:setColor(grassColor)
		models.blockModel.block.westOverlay:setColor(grassColor)
		models.blockModel.block.eastOverlay:setColor(grassColor)
	end
	if id ~= "minecraft:grass_block" and not id:find("leaves") then -- they have a block that is not grass or leaves
		blocktaskthing:setLight(world.getBlockLightLevel(player:getPos()),
			world.getSkyLightLevel(player:getPos()))
		if id == "minecraft:air" or id == "minecraft:water" or id == "minecraft:lava" or id == "minecraft:light" or id == "minecraft:void_air" or id == "minecraft:cave_air" or lock then return end

		models.blockModel.block:setVisible(false)
		blocktaskthing:setVisible(true)
		blocktaskthing:setBlock(id)
	else -- they have a non /lockblock block that is grass or leaves
		if id == "minecraft:air" or id == "minecraft:water" or id == "minecraft:lava" or id == "minecraft:light" or id == "minecraft:void_air" or id == "minecraft:cave_air" or (lock and not commandBlock) then return end
		if not commandBlock then
			blocktaskthing:setVisible(false)
			models.blockModel.block:setVisible(true)
			-- create and apply base block textures
			local upTexture = world.getBlockState(fullBlockPos):getTextures().UP[1] .. ".png"
			local westTexture = world.getBlockState(fullBlockPos):getTextures().WEST[1] .. ".png"
			local downTexture = world.getBlockState(fullBlockPos):getTextures().DOWN[1] .. ".png"
			local eastTexture = world.getBlockState(fullBlockPos):getTextures().EAST[1] .. ".png"
			local northTexture = world.getBlockState(fullBlockPos):getTextures().NORTH[1] ..
				".png"
			local southTexture = world.getBlockState(fullBlockPos):getTextures().SOUTH[1] ..
				".png"

			models.blockModel.block.upCube:setPrimaryTexture("RESOURCE", upTexture)
			models.blockModel.block.westCube:setPrimaryTexture("RESOURCE", westTexture)
			models.blockModel.block.downCube:setPrimaryTexture("RESOURCE", downTexture)
			models.blockModel.block.eastCube:setPrimaryTexture("RESOURCE", eastTexture)
			models.blockModel.block.northCube:setPrimaryTexture("RESOURCE", northTexture)
			models.blockModel.block.southCube:setPrimaryTexture("RESOURCE", southTexture)

			local northOVTexture, southOVTexture, westOVTexture, eastOVTexture
			if id == "minecraft:grass_block" then -- apply grass overlays and color
				northOVTexture = world.getBlockState(fullBlockPos):getTextures().NORTH[2] .. ".png"
				southOVTexture = world.getBlockState(fullBlockPos):getTextures().SOUTH[2] .. ".png"
				westOVTexture = world.getBlockState(fullBlockPos):getTextures().WEST[2] .. ".png"
				eastOVTexture = world.getBlockState(fullBlockPos):getTextures().EAST[2] .. ".png"
				models.blockModel.block.eastOverlay:setPrimaryTexture("RESOURCE", eastOVTexture)
				models.blockModel.block.westOverlay:setPrimaryTexture("RESOURCE", westOVTexture)
				models.blockModel.block.southOverlay:setPrimaryTexture("RESOURCE", southOVTexture)
				models.blockModel.block.northOverlay:setPrimaryTexture("RESOURCE", northOVTexture)
				models.blockModel.block.eastOverlay:setVisible(true)
				models.blockModel.block.westOverlay:setVisible(true)
				models.blockModel.block.southOverlay:setVisible(true)
				models.blockModel.block.northOverlay:setVisible(true)
				models.blockModel.block.upCube:setColor(grassColor)
				models.blockModel.block.northOverlay:setColor(grassColor)
				models.blockModel.block.southOverlay:setColor(grassColor)
				models.blockModel.block.westOverlay:setColor(grassColor)
				models.blockModel.block.eastOverlay:setColor(grassColor)
			else
				models.blockModel.block.eastOverlay:setVisible(false)
				models.blockModel.block.westOverlay:setVisible(false)
				models.blockModel.block.southOverlay:setVisible(false)
				models.blockModel.block.northOverlay:setVisible(false)
				models.blockModel.block.upCube:setColor(1)
				models.blockModel.block.northOverlay:setColor(1)
				models.blockModel.block.southOverlay:setColor(1)
				models.blockModel.block.westOverlay:setColor(1)
				models.blockModel.block.eastOverlay:setColor(1)
			end
			-- correctly color leaves
			if id:find("leaves") and id ~= "minecraft:birch_leaves" and id ~= "minecraft:spruce_leaves" and id ~= "minecraft:cherry_leaves" and not id:find("azalea_leaves") then
				models.blockModel.block:setColor(biomeType:getFoliageColor())
			else
				models.blockModel.block:setColor(1)
			end
			if id == "minecraft:birch_leaves" then
				models.blockModel.block:setColor(0.5019607843137255, 0.6549019607843137,
					0.3333333333333333)
			end
			if id == "minecraft:spruce_leaves" then
				models.blockModel.block:setColor(0.3803921568627451, 0.6, 0.3803921568627451)
			end

		else -- they have a locked block from the /lockblock command that is grass or leaves
			blocktaskthing:setVisible(false)
			models.blockModel.block:setVisible(true)
			local lockedBlock = world.newBlock(id, player:getPos())
			-- create and apply base block textures
			local upTexture2 = lockedBlock:getTextures().UP[1] .. ".png"
			local westTexture2 = lockedBlock:getTextures().WEST[1] .. ".png"
			local downTexture2 = lockedBlock:getTextures().DOWN[1] .. ".png"
			local eastTexture2 = lockedBlock:getTextures().EAST[1] .. ".png"
			local northTexture2 = lockedBlock:getTextures().NORTH[1] .. ".png"
			local southTexture2 = lockedBlock:getTextures().SOUTH[1] .. ".png"

			models.blockModel.block.upCube:setPrimaryTexture("RESOURCE", upTexture2)
			models.blockModel.block.westCube:setPrimaryTexture("RESOURCE", westTexture2)
			models.blockModel.block.downCube:setPrimaryTexture("RESOURCE", downTexture2)
			models.blockModel.block.eastCube:setPrimaryTexture("RESOURCE", eastTexture2)
			models.blockModel.block.northCube:setPrimaryTexture("RESOURCE", northTexture2)
			models.blockModel.block.southCube:setPrimaryTexture("RESOURCE", southTexture2)

			local northOVTexture2, southOVTexture2, westOVTexture2, eastOVTexture2
			if id == "minecraft:grass_block" then -- apply grass overlays and color
				northOVTexture2 = lockedBlock:getTextures().NORTH[2] .. ".png"
				southOVTexture2 = lockedBlock:getTextures().SOUTH[2] .. ".png"
				westOVTexture2 = lockedBlock:getTextures().WEST[2] .. ".png"
				eastOVTexture2 = lockedBlock:getTextures().EAST[2] .. ".png"
				models.blockModel.block.eastOverlay:setPrimaryTexture("RESOURCE", eastOVTexture2)
				models.blockModel.block.westOverlay:setPrimaryTexture("RESOURCE", westOVTexture2)
				models.blockModel.block.southOverlay:setPrimaryTexture("RESOURCE", southOVTexture2)
				models.blockModel.block.northOverlay:setPrimaryTexture("RESOURCE", northOVTexture2)
				models.blockModel.block.eastOverlay:setVisible(true)
				models.blockModel.block.westOverlay:setVisible(true)
				models.blockModel.block.southOverlay:setVisible(true)
				models.blockModel.block.northOverlay:setVisible(true)
				models.blockModel.block.upCube:setColor(grassColor)
				models.blockModel.block.northOverlay:setColor(grassColor)
				models.blockModel.block.southOverlay:setColor(grassColor)
				models.blockModel.block.westOverlay:setColor(grassColor)
				models.blockModel.block.eastOverlay:setColor(grassColor)
			else
				models.blockModel.block.eastOverlay:setVisible(false)
				models.blockModel.block.westOverlay:setVisible(false)
				models.blockModel.block.southOverlay:setVisible(false)
				models.blockModel.block.northOverlay:setVisible(false)
				models.blockModel.block.upCube:setColor(1)
				models.blockModel.block.northOverlay:setColor(1)
				models.blockModel.block.southOverlay:setColor(1)
				models.blockModel.block.westOverlay:setColor(1)
				models.blockModel.block.eastOverlay:setColor(1)
			end
			-- correctly color leaves
			if id:find("leaves") and id ~= "minecraft:birch_leaves" and id ~= "minecraft:spruce_leaves" and id ~= "minecraft:cherry_leaves" and not id:find("azalea_leaves") then
				models.blockModel.block:setColor(biomeType:getFoliageColor())
			else
				models.blockModel.block:setColor(1)
			end
			if id == "minecraft:birch_leaves" then
				models.blockModel.block:setColor(0.5019607843137255, 0.6549019607843137,
					0.3333333333333333)
			end
			if id == "minecraft:spruce_leaves" then
				models.blockModel.block:setColor(0.3803921568627451, 0.6, 0.3803921568627451)
			end
		end
	end
end

function events.render(delta) -- snapping logic
	if blockTimer > 30 and snapped then -- change 30 to the number of ticks you desire before snapping happens
		models.blockModel.blockTask:setParentType("WORLD")
		models.blockModel.blockTask:setPos(
			(math.floor(player:getPos(delta).x) * 16) + ((blockScale - 1) * -8),
			player:getPos(delta).y * 16,
			(math.floor(player:getPos(delta).z) * 16) + ((blockScale - 1) * -8))
		blocktaskthing:setPos(0, 0, 0)
		blocktaskthing:setScale(blockScale)

		models.blockModel.block:setParentType("WORLD")
		models.blockModel.block:setPos((math.floor(player:getPos(delta).x) * 16) + 8,
			(player:getPos(delta).y * 16) + 0.001, (math.floor(player:getPos(delta).z) * 16) + 8)
		models.blockModel.block:setScale(blockScale - 0.0001)
	else
		models.blockModel.blockTask:setParentType("NONE")
		models.blockModel.blockTask:setPos(0, 0, 0)

		models.blockModel.block:setParentType("NONE")
		models.blockModel.block:setPos(0, 0, 0)
	end
	if models.blockModel.blockTask:getParentType() == "None" then
		blocktaskthing:setPos(blockScale * -8, 0, blockScale * -8)
		blocktaskthing:setScale(blockScale * math.worldScale)
		models.blockModel.block:setScale(blockScale * math.worldScale)
	end
end
