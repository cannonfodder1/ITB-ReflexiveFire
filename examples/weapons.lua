-------------------------------------------------------
-- EXAMPLE WEAPON TEMPLATES
-------------------------------------------------------

ExampleAtk1 = Skill:new{
	Damage = 1,
	PathSize = 1,
	Push = 0,
	Fire = 0,
	Freeze = 0,
	Acid = 0,
	
	-- We don't want this weapon firing automatically, only manually through hooks.lua
	ScoreEnemy = -25,
	ScoreFriendlyDamage = -25,
	ScoreBuilding = -25,
	ScoreNothing = -25,
	-- If an enemy's weapon fires instantly with no queue, and the target score is below 20,
	-- the AI won't fire the weapon. Thus -25 on all target scores
	
	Class = "Enemy",
	Icon = "weapons/enemy_firefly1.png",
	Explosion = "ExploFirefly1",
	ImpactSound = "/impact/dynamic/enemy_projectile",
	Projectile = "effects/shot_firefly",
	TipImage = {
		Unit = Point(2,3),
		Enemy = Point(2,1),
		Target = Point(2,2),
		CustomPawn = "Example1"
	}
}

function ExampleAtk1:GetTargetArea(point)
	local ret = PointList()
	for dir = DIR_START, DIR_END do
		for k = 1, INT_MAX do
			local curr = point + DIR_VECTORS[dir]*k
			if not Board:IsValid(curr) then
				break
			end
			ret:push_back(curr)
			if Board:IsBlocked(curr, PATH_PROJECTILE) then
				break
			end
		end
	end
	return ret
end

-- This is just a copy of the Firefly attack but it fires instantly without waiting for the enemy turn
-- I also included Fire, Freeze, Acid, and Push plugins for easy editing of characteristics
function ExampleAtk1:GetSkillEffect(p1,p2)
	local ret = SkillEffect()
	local direction = GetDirection(p2 - p1)
	local target = GetProjectileEnd(p1, p2)
	local damage
	
	-- In the weapon definitions you can change Push, Fire, Freeze, or Acid to 1 instead of 0 to enable
	if self.Push == 1 then
		damage = SpaceDamage(target, self.Damage, direction)
	else
		damage = SpaceDamage(target, self.Damage)
	end
	damage.iFire = self.Fire
	damage.iFrozen = self.Freeze
	damage.iAcid = self.Acid
	
	-- AddProjectile instead of AddQueuedProjectile like other Vek ranged weapons
	ret:AddProjectile(damage, self.Projectile)
	
	return ret
end

----------|||------------

ExampleAtk2 = ExampleAtk1:new{
	Damage = 2,
	Push = 0,
	Fire = 0,
	Freeze = 0,
	Acid = 0,
	
	-- We don't want this weapon firing automatically, only manually through hooks.lua
	ScoreEnemy = -25,
	ScoreFriendlyDamage = -25,
	ScoreBuilding = -25,
	ScoreNothing = -25,
	-- If an enemy's weapon fires instantly with no queue, and the target score is below 20,
	-- the AI won't fire the weapon. Thus -25 on all target scores
	
	Class = "Enemy",
	Icon = "weapons/enemy_firefly2.png",
	Explosion = "ExploFirefly2",
	Projectile = "effects/shot_firefly2",
	TipImage = {
		Unit = Point(2,3),
		Enemy = Point(2,1),
		Target = Point(2,2),
		CustomPawn = "Example2"
	}
}
