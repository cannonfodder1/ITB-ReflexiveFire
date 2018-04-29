--======================================================
--		DON'T YOU DARE MESS ANYTHING UP IN HERE
--		LEARN LUA SCRIPTING BEFORE SCREWING AROUND
--======================================================

Location["combat/tile_icon/reflexmark.png"] = Point(-27,2)
TILE_TOOLTIPS["reflex_mark"] = { "Reflexive Fire", "Mechs that get pushed or move into this tile will be attacked!" }

local update = true --If this is true, we will update overwatch tiles next frame, and set it to false again.
local moveDone = true
local reflexReady = false
local targetMech = nil

local function onLoad()
	update = true
	moveDone = true
	undoMove = false
	reflexReady = false
	targetMech = nil
end

--The system stores variables in GAME.Overwatch and GAME.OverwatchUndo. No other script should overwrite those variables.
local function missionStartHook()
	GAME.Overwatch = {}
	GAME.OverwatchUndo = {}
end

--Refresh a pawn's remaining shots
local function pawnRefreshOverwatch(pawn)
	update = true
	local id = pawn:GetId()
	local pawnDefaults = _G[pawn:GetType()].Overwatch
	GAME.Overwatch[id].markedTiles = {}
	GAME.Overwatch[id].remainingShots = pawnDefaults.ShotsTotal or INT_MAX
	GAME.Overwatch[id].shotPawnIds = {}
end

local function newTurnHook(self)
	GAME.OverwatchUndo = {}
	for id, _ in pairs(GAME.Overwatch) do
		pawnRefreshOverwatch(Board:GetPawn(id))
	end
end

--Set overwatch values for a pawn to it's default values defined in Pawn.
local function pawnTrackedHook(mission, pawn)
	update = true
	--LOG("(".. pawn:GetId() ..") ".. _G[pawn:GetType()].Name .." just appeared on tile (".. pawn:GetSpace().x ..", ".. pawn:GetSpace().y ..")")
	
	if _G[pawn:GetType()].Overwatch ~= nil then
		local id = pawn:GetId()
		local pawnDefaults = _G[pawn:GetType()].Overwatch
		GAME.Overwatch[id] = {}
		GAME.Overwatch[id].range = pawnDefaults.Range or INT_MAX
		GAME.Overwatch[id].shotsPerPawn = pawnDefaults.ShotsPerPawn or INT_MAX
		GAME.Overwatch[id].weaponSlot = pawnDefaults.WeaponSlot or 1
		pawnRefreshOverwatch(pawn)
	end
end

local function pawnUntrackedHook(mission, pawn)
	update = true
	--LOG("(".. pawn:GetId() ..") ".. _G[pawn:GetType()].Name .." just disappeared from tile (".. pawn:GetSpace().x ..", ".. pawn:GetSpace().y ..")")
	GAME.Overwatch[pawn:GetId()] = nil
end

local function pawnMoveStartHook(mission, defender)
	moveDone = false
end

local function pawnMoveEndHook(mission, defender)
	moveDone = true
	--LOG("(".. defender:GetId() ..") ".. _G[defender:GetType()].Name .." ended it's move in (".. defender:GetSpace().x ..", ".. defender:GetSpace().y ..")")
	update = true
end

local function pawnUndoMoveHook(mission, defender, oldPosition)
	local def_id = defender:GetId()
	local att_id = GAME.OverwatchUndo[def_id]
	undoMove = true
	--Give back ammunition if this pawn was shot by an overwatch shot during it's movement.
	if att_id ~= nil then
		local attacker = Board:GetPawn(att_id)
		if attacker ~= nil then
			local defaults = _G[attacker:GetType()].Overwatch
			GAME.Overwatch[att_id].remainingShots = math.min(GAME.Overwatch[att_id].remainingShots + 1, defaults.ShotsTotal)
			GAME.Overwatch[att_id].shotPawnIds[def_id] = GAME.Overwatch[att_id].shotPawnIds[def_id] - 1
			--LOG("(".. def_id ..") ".. _G[Board:GetPawn(def_id):GetType()].Name .." undid movement, and gave back ammo to ".. _G[Board:GetPawn(att_id):GetType()].Name)
		end
	end
end

-- Call for an update if a pawn changes position.
-- If a mech moves three tiles, this triggers three times. So we need the moveDone flag to check if the move is over.
local function pawnPositionChangedHook(mission, defender, oldPosition)
	--LOG("(".. defender:GetId() ..") ".. _G[defender:GetType()].Name .." changed position from (".. oldPosition.x ..", ".. oldPosition.y ..") to (".. defender:GetSpace().x ..", ".. defender:GetSpace().y ..")")
	if defender:GetTeam() == TEAM_PLAYER and Game:GetTeamTurn() == TEAM_PLAYER and moveDone and not undoMove then
		targetMech = defender
		reflexReady = true
		update = true
	end
	if moveDone then update = true end
end

-- We need a skillEndHook to update the marked tiles when weapons fire
-- For example, smoke drop or rock accelerator can block sightlines
local function skillEndHook(mission, pawn, weaponId, p1, p2)
	update = true
end

local function missionUpdateHook()
	--Continuously mark reflex tiles.
	for id, _ in pairs(GAME.Overwatch) do
		for _, mark in ipairs(GAME.Overwatch[id].markedTiles) do
			if not Board:IsItem(mark) then
				Board:MarkSpaceImage(mark, "combat/tile_icon/reflexmark.png", GL_Color(60,110,220,0.75))
				Board:MarkSpaceDesc(mark, "reflex_mark")
			end
		end
	end
	
	if reflexReady then
		reflexReady = false
		local def_id = targetMech:GetId()
		local curr = targetMech:GetSpace()
		for att_id, _ in pairs(GAME.Overwatch) do
			if GAME.Overwatch[att_id].remainingShots > 0 then
				local attacker = Board:GetPawn(att_id)
				local shotfrom = attacker:GetSpace()
				local shotPawnIds = GAME.Overwatch[att_id].shotPawnIds
				local WeaponSlot = GAME.Overwatch[att_id].weaponSlot
				shotPawnIds[def_id] = shotPawnIds[def_id] or 0
				--LOG("Preparing reflex shot using weapon in slot "..WeaponSlot.."!")
				for _, mark in ipairs(GAME.Overwatch[att_id].markedTiles) do
					if curr == mark and shotPawnIds[def_id] < GAME.Overwatch[att_id].shotsPerPawn then
						if not Board:IsSmoke(shotfrom) and Board:GetTerrain(shotfrom) ~= TERRAIN_WATER then
							attacker:FireWeapon(curr, WeaponSlot)
							shotPawnIds[def_id] = shotPawnIds[def_id] + 1
							GAME.Overwatch[att_id].remainingShots = GAME.Overwatch[att_id].remainingShots - 1
							Board:AddAlert(shotfrom, "Reflex Firing!")
						end
						--LOGGING---------------------------------------------------------------------
						--LOG("(".. att_id ..") ".. _G[attacker:GetType()].Name .." shoots at (".. def_id ..") ".. _G[targetMech:GetType()].Name)
						for id, _ in pairs(GAME.Overwatch[att_id].shotPawnIds) do
							--LOG("(".. id ..") ".. _G[Board:GetPawn(id):GetType()].Name .." has been shot ".. GAME.Overwatch[att_id].shotPawnIds[id] .." times.")
						end
						------------------------------------------------------------------------------
					
						--Store information about the shot in case movement is undone.
						--This would have to be done better if the system should be expanded
						--in a way that allows more than one overwatch shot to be taken in a single move action.
						if targetMech:IsUndoPossible() then
							GAME.OverwatchUndo[def_id] = att_id
						end
						--If undo is not done, we won't bother to clear this until next turn.
					end
				end
			end
		end
	end
	
	if update == false then return end
	update = false
	undoMove = false
	
	for id, _ in pairs(GAME.Overwatch) do --Unusable until we can detect ResetTurn/undoturn
		--Clear markedTiles and rebuild the tables.
		GAME.Overwatch[id].markedTiles = {}
		local pawn = Board:GetPawn(id)
		local pawnPos = pawn:GetSpace()
		GAME.Overwatch[id].pos = pawnPos
		if not pawn:IsFrozen() and not Board:IsSmoke(pawnPos) and Board:GetTerrain(pawnPos) ~= TERRAIN_WATER then
			for dir = DIR_START, DIR_END do
				for k = 1, GAME.Overwatch[id].range do
					local curr = DIR_VECTORS[dir]*k + pawnPos
				
					if not Board:IsValid(curr) then
						break
					end
					if Board:IsBlocked(curr, PATH_PROJECTILE) then
						break
					end
					if Board:IsSmoke(curr) then
						break
					end
					table.insert(GAME.Overwatch[id].markedTiles, curr)
				end
			end
		end
	end
end

return {
	onLoad = onLoad,
	newTurnHook = newTurnHook,
	missionStartHook = missionStartHook,
	missionUpdateHook = missionUpdateHook,
	pawnTrackedHook = pawnTrackedHook,
	pawnUntrackedHook = pawnUntrackedHook,
	pawnMoveStartHook = pawnMoveStartHook,
	pawnMoveEndHook = pawnMoveEndHook,
	pawnUndoMoveHook = pawnUndoMoveHook,
	pawnPositionChangedHook = pawnPositionChangedHook,
	skillEndHook = skillEndHook,
}