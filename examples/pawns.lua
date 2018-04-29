-------------------------------------------------------
-- EXAMPLE VEK TEMPLATES
-------------------------------------------------------

Example1 =
	{
		Name = "Reflexer",
		Health = 3,
		MoveSpeed = 2,
		
		-- In your pawn definition, you must have this table.
		Overwatch = {
			Range = 3, -- range in tiles
			ShotsTotal = 1, -- total shots this unit can take per turn
			ShotsPerPawn = 1, -- how many shots on a single mech the unit can take each turn
			WeaponSlot = 1, -- the slot of the weapon that we want to fire
		},
		
		Image = "firefly", 
		ImageOffset = 0,
		SkillList = { "ExampleAtk1" },
		SoundLocation = "/enemy/firefly_1/",
		DefaultTeam = TEAM_ENEMY,
		ImpactMaterial = IMPACT_INSECT
	}
AddPawn("Example1")

---|||---

Example2 = Example1:new{
		Name = "Alpha Reflexer",
		Health = 5,
		MoveSpeed = 2,
		
		-- In your pawn definition, you must have this table.
		Overwatch = {
			Range = 5, -- range in tiles
			ShotsTotal = 2, -- total shots this unit can take per turn
			ShotsPerPawn = 1, -- how many shots on a single mech the unit can take each turn
			WeaponSlot = 1, -- the slot of the weapon that we want to fire
		},
		
		Image = "firefly", 
		ImageOffset = 1,
		SkillList = { "ExampleAtk2" },
		SoundLocation = "/enemy/firefly_2/",
		DefaultTeam = TEAM_ENEMY,
		ImpactMaterial = IMPACT_FLESH,
		Tier = TIER_ALPHA,
}
AddPawnName("Example2")
