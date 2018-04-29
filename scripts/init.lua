local function init(self)
	-- Load up the Mod API Extension
	if modApiExt then
		-- modApiExt already defined. This means that the user has the complete
		-- ModUtils package installed. Use that instead of loading our own one.
		ReflexiveFire_modApiExt = modApiExt
	else
		-- modApiExt was not found. Load our inbuilt version
		local extDir = self.scriptPath.."modApiExt/"
		ReflexiveFire_modApiExt = require(extDir.."modApiExt")
		ReflexiveFire_modApiExt:init(extDir)
	end
	
	-- Add the tile marker sprite with the Fully Unified Resource Loader
	FURL = require(self.scriptPath.."FURL")
	FURL(self, {
	{
        Type = "base",
        Filename = "reflexmark",
		Path = "resources/icons", 
		ResourcePath = "combat/tile_icon",
	}
	});
end

local function load(self,options,version)
	ReflexiveFire_modApiExt:load(self, options, version)
	ReflexiveFire_IsInstalled = true
	-- Create the code hooks needed for the reflex shot
	-- We need a variety of hooks from both the Mod Loader and the Mod API Extension
	local overwatch = require(self.scriptPath.."overwatch")
	overwatch.onLoad()
	modApi:addNextTurnHook(overwatch.newTurnHook)
	modApi:addMissionStartHook(overwatch.missionStartHook)
	modApi:addMissionUpdateHook(overwatch.missionUpdateHook)
	ReflexiveFire_modApiExt:addPawnTrackedHook(overwatch.pawnTrackedHook)
	ReflexiveFire_modApiExt:addPawnUntrackedHook(overwatch.pawnUntrackedHook)
	ReflexiveFire_modApiExt:addPawnMoveStartHook(overwatch.pawnMoveStartHook)
	ReflexiveFire_modApiExt:addPawnMoveEndHook(overwatch.pawnMoveEndHook)
	ReflexiveFire_modApiExt:addPawnUndoMoveHook(overwatch.pawnUndoMoveHook)
	ReflexiveFire_modApiExt:addPawnPositionChangedHook(overwatch.pawnPositionChangedHook)
	ReflexiveFire_modApiExt:addSkillEndHook(overwatch.skillEndHook)
end

return {
	id = "Wolf_ReflexiveFire",
	name = "Reflexive Fire",
	version = "1.0.0",
	requirements = {},
	init = init,
	load = load,
}