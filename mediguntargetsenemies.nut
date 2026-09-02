// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// mult_dmgtaken I think breaks this. mult_dmgtaken_active also might.
//

LOSDISCONNECTTIME <- 0.2 // Very short compared to teammates
LASTHEAL <- array(2048, 0)

IncludeScript("lib/clocksutils.nut")

::MediguntargetEnemiesEventTable <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ValidateScriptScope()
	}
}

__CollectGameEventCallbacks(MediguntargetEnemiesEventTable)

Entities.EnableEntityListening()
Hooks.Add(this, "OnEntityCreated", function(entity)
{
	entity.SetContextThink("EntitySpawnMedigunDamager", EntitySpawnMedigunDamager, 0.01) // I'm having issues with it just not recogizing the attribute otherwise?
}, "EntitySpawnMedigunDamager" );

Hooks.Add(this, "OnEntityCreated", function(entity)
{
	EntitySpawnGeneratorCheck(entity)
}, "EntitySpawnGeneratorCheck" );

function EntitySpawnMedigunDamager(entity)
{
	if (!entity || !entity.IsValid())
	{
		return
	}

	if (entity.GetClassname() == "tf_weapon_medigun")
	{
		if (entity.GetAttribute("medigun targets special", 0) <= 0)
			return
		local medigunscope = entity.GetOrCreatePrivateScriptScope()

		// Attributes put in the scope because I am lazy
		medigunscope.damage <- entity.GetAttribute("medigun targets enemies rework", 0) // Simply, how much damage this does.
		medigunscope.buildings <- entity.GetAttribute("medigun targets buildings", 0) // How much this heals buildings.
		medigunscope.uberdamagemult <- entity.GetAttribute("medigun targets enemies uber damage mult", 1) // How much more (or less ig) damage this deal while ubered.
		medigunscope.uberbuildingsmult <- entity.GetAttribute("medigun targets buildings uber mult", 1) // How much more (or less ig) damage this heals buildings while ubered.
		medigunscope.range <- 450 * entity.GetAttribute("mod set beam range", 1) // How long is the connection range for this (disconnection is handled via the vanilla way)
		medigunscope.ROF <- entity.GetAttribute("medigun targets fire rate", 0) // The attack interval
		medigunscope.lockondelay <- entity.GetAttribute("medigun targets lockon delay", 0) // How long after connecting to an enemy it take for this to deal it's first "tick" of damage
		medigunscope.condnormal <- entity.GetAttribute("medigun targets enemies cond", 0) // What condition are we passively applying to the enemy
		medigunscope.condnormaltime <- entity.GetAttribute("medigun targets enemies cond time", 0)  // How long does the condition linger for after disconection
		medigunscope.conduber <- entity.GetAttribute("medigun targets enemies cond uber", 0) // What condition are we passively applying to the enemy while ubered
		medigunscope.condubertime <- entity.GetAttribute("medigun targets enemies cond uber time", 0) // How long does the uber caused condition linger for after disconection
		medigunscope.uberhitrate <- entity.GetAttribute("medigun targets enemies uber per hit", 0) // How much of your ubercharge does this give every hit (NOTE THAT 1 IS 100%!)
		medigunscope.uberrateenemies <- entity.GetAttribute("medigun targets enemies uber rate enemies", 1) // How fast uber should build while "healing" an enemy
		medigunscope.uberratebuildings <- entity.GetAttribute("medigun targets buildings uber rate buildings", 1) // How fast uber should build while "healing" a building
		medigunscope.condwhileubered <- entity.GetAttribute("cond while ubered", 0) // A condition to apply while ubered
		medigunscope.healmultduringuber <- entity.GetAttribute("heal mult during uber", 1) // How much more to heal while using uber
		medigunscope.ammogive <- entity.GetAttribute("medigun give ammo", 0)
		medigunscope.ammogivebuildings <- entity.GetAttribute("medigun give ammo buildings", 0)
		medigunscope.ammogiveuber <- entity.GetAttribute("medigun give ammo uber mult", 1)
		medigunscope.ammogivebuildingsuber <- entity.GetAttribute("medigun give ammo buildings uber mult", 1)
		medigunscope.upgradegive <- entity.GetAttribute("medigun give upgrade buildings", 0)
		medigunscope.upgradegiveuber <- entity.GetAttribute("medigun give upgrade buildings uber mult", 1)
		medigunscope.fovcap <- (entity.GetAttribute("medigun targets enemies fov cap", 0)/360)*PI // How far from where you are looking the medibeam can be, in degrees (although we convert it to radians here)
		medigunscope.fling <- entity.GetAttribute("medigun fling enable", 0)
		if (medigunscope.fling)
		{
			medigunscope.flingair <- entity.GetAttribute("medigun fling air only", 0)
			medigunscope.flingpowerenemy <- entity.GetAttribute("medigun fling enemy power mult", 1)
			medigunscope.flingpowerfriendly <- entity.GetAttribute("medigun fling friendly power mult", 1)
			medigunscope.flingpoweruber <- entity.GetAttribute("medigun fling uber power mult", 1)
			medigunscope.flingreel <- entity.GetAttribute("medigun fling reel", 0)
			medigunscope.flingreelconst <- entity.GetAttribute("medigun fling constant reel", 0)
			medigunscope.flingspeed <- entity.GetAttribute("medigun fling speed", 1)
			medigunscope.flingtargetdistance <- entity.GetAttribute("medigun fling target distance", 1)
		}

		// Actually relevant stuff
		medigunscope.target <- null // Who this is targeting?
		medigunscope.targetingenemy <- false // Are we targeting an enemy?
		medigunscope.LOStime <- 0 // How long has it been since a LOS check has succeeded? (Note that this only updates when we are healing an enemy)
		medigunscope.holding <- false // Is the button being held? (We shouldn't swap targets while it is)
		medigunscope.uber <- 0 // What's our uber?
		medigunscope.lastattack <- 0 // When did we last "hit"
		medigunscope.isusinguber <- false // Are we using ubercharge?

		AddThinkToEnt(entity, "MedigunEnemyChecker")
	}
	else if (entity.GetClassname() == "tf2c_projectile_healgrenade")
	{
		local owner = entity.GetOwner()
		if (owner && owner.IsPlayer())
		{
			local weapon = owner.GetActiveWeapon()
			if (!weapon)
			{
				return
			}
			local damage = weapon.GetAttribute("medigun targets enemies rework", 0)
			local usinguber = NetProps.GetPropBool(weapon, "m_bChargeRelease")
			if (damage)
			{
				local bombscope = entity.GetOrCreatePrivateScriptScope()
				bombscope.explodinghealgrenade <- true
				entity.SetThinkFunction("MedibombEnemyChecker", 0.01)
				bombscope.damage <- damage
				if (usinguber)
				{
					bombscope.damage *= weapon.GetAttribute("medigun targets enemies uber damage mult", 1)
				}
				bombscope.weapon <- owner.GetActiveWeapon()
				bombscope.owner <- owner
			}
			local healmultduringuber = owner.GetActiveWeapon().GetAttribute("heal mult during uber", 1)
			if (healmultduringuber != 1 && usinguber)
			{
				entity.SetDamage(entity.GetDamage()*healmultduringuber)
			}
			local healmult = owner.GetActiveWeapon().GetAttribute("heal grenade hit heal mult", 1)
			if (healmult != 1)
			{
				entity.SetDamage(entity.GetDamage()*healmult)
			}
		}
	}
	else if (entity.GetClassname() == "tf2c_projectile_ubergenerator")
	{
		local owner = entity.GetOwner()
		if (owner && owner.IsPlayer())
		{
			local generatorscope = entity.GetOrCreatePrivateScriptScope()
			generatorscope.weapon <- owner.GetActiveWeapon()
			local damage = owner.GetActiveWeapon().GetAttribute("medigun targets enemies generator damage", 0)
			if (damage)
			{
				local generatorscope = entity.GetOrCreatePrivateScriptScope()
				if (damage > 0)
				{
					generatorscope.damage <- damage
				}
				else
				{
					generatorscope.damage <- 0
				}
				generatorscope.cond <- owner.GetActiveWeapon().GetAttribute("medigun targets enemies cond uber", 0)
				generatorscope.condtime <- owner.GetActiveWeapon().GetAttribute("medigun targets enemies cond uber time", 0)
				generatorscope.ROF <- owner.GetActiveWeapon().GetAttribute("medigun targets enemies generator ROF", 0)
				entity.SetThinkFunction("GeneratorEnemyChecker", generatorscope.ROF)
			}
		}
	}
	else if (entity.GetClassname() == "tf_weapon_generator_uber_shield")
	{
		local weapon = entity.GetOwner().GetOrCreatePrivateScriptScope().weapon // Our owner is the generator.
		switch (weapon.GetAttribute("special generator", 0))
		{
			case 1:
				entity.SetModelSimple("models/items/shield_bubble/shield_bubble_colourable_v2.mdl")
				local colordecimal = 0
				switch (weapon.GetTeam() -2)
				{
					case 0:
						colordecimal = weapon.GetAttribute("generator red", 0)
						break;
					case 1:
						colordecimal = weapon.GetAttribute("generator blu", 0)
						break;
					case 2:
						colordecimal = weapon.GetAttribute("generator grn", 0)
						break;
					case 3:
						colordecimal = weapon.GetAttribute("generator ylw", 0)
						break;
				}
				entity.SetRenderColor(colordecimal/65536,(colordecimal%65536)/256,colordecimal%256)
				break;
			case 2:
				entity.SetModelSimple("models/items/shield_bubble/shield_bubble_rainbow_v2.mdl")
				local colordecimal = 0
				switch (weapon.GetTeam() -2)
				{
					case 0:
						colordecimal = weapon.GetAttribute("generator red", 0)
						break;
					case 1:
						colordecimal = weapon.GetAttribute("generator blu", 0)
						break;
					case 2:
						colordecimal = weapon.GetAttribute("generator grn", 0)
						break;
					case 3:
						colordecimal = weapon.GetAttribute("generator ylw", 0)
						break;
				}
				entity.SetRenderColor(colordecimal/65536,(colordecimal%65536)/256,colordecimal%256)
				break;
		}
	}
}

function EntitySpawnGeneratorCheck(entity)
{
	if (!entity || !entity.IsValid())
	{
		return
	}
	if (entity.GetClassname() == "tf2c_projectile_ubergenerator")
	{
		local owner = entity.GetOwner()
		if (owner && owner.IsPlayer())
		{
			local condwhileubered = owner.GetActiveWeapon().GetAttribute("cond while ubered", 0)
			if (condwhileubered)
			{
				local medigunscope = owner.GetActiveWeapon().GetOrCreatePrivateScriptScope()
				medigunscope.condwhileubered <- condwhileubered
				AddThinkToEnt(owner.GetActiveWeapon(), "MedigunUberChecker")
			}
			local nogenerator = owner.GetActiveWeapon().GetAttribute("medigun targets enemies no generator", 0)
			if (nogenerator)
			{
				entity.Destroy()
			}
		}
	}
}

local medigun = null
while (medigun = Entities.FindByClassname(medigun, "tf_weapon_medigun"))
{
	EntitySpawnMedigunDamager(medigun)
}

function MedigunEnemyChecker()
{
	// Will always be false? Rather not risk it.
	if (!self || !self.IsValid())
		return

	local medigunscope = self.GetScriptScope()
	local owner = self.GetOwner()

	if (!owner || !owner.IsValid())
	{
		return
	}
	local buttons = owner.GetButtons();

	// Are we using uber?
	medigunscope.isusinguber = NetProps.GetPropBool(self, "m_bChargeRelease")

	if (medigunscope.isusinguber && medigunscope.condwhileubered)
	{
		owner.AddCondEx(medigunscope.condwhileubered, 1, owner)
	}

	// Is this the active weapon? If not, clear our targeting and skip everything else.
	if (owner.GetActiveWeapon() != self)
	{
		medigunscope.target = null
		medigunscope.targetingenemy = false
		return 0.1
	}

	if (medigunscope.isusinguber && medigunscope.healmultduringuber != 1)
	{
		owner.AddCustomAttribute("heal rate VSCRIPT", medigunscope.healmultduringuber, 1)
	}

	medigunscope.target = NetProps.GetPropEntity(self, "m_hHealingTarget")

	if (buttons & IN.ATTACK && (!medigunscope.target || !medigunscope.holding))
	{
		medigunscope.holding = true
		local eyepos = owner.EyePosition()
		local trace = TraceLineComplex(eyepos, eyepos + (AngleVectors(owner.EyeAngles()) * medigunscope.range), owner, MASK_SHOT, 0)
		local hitEnt = trace.Entity()
		local hitEntspacecenter
		if (hitEnt)
		{
			hitEntspacecenter = hitEnt.GetOrigin()
			hitEntspacecenter.z += hitEnt.GetBoundingMaxs().z / 2 //Shouldn't need to consider Mins since that's always 0... I think.
		}
		if (trace.DidHit() && !trace.DidHitWorld() && !trace.StartSolid() && hitEnt && hitEnt.IsAlive() &&
		(medigunscope.damage && hitEnt.IsPlayer() && hitEnt.GetTeam() != owner.GetTeam() && !RestrictedConds(hitEnt, self) || 
		medigunscope.buildings && IsBuilding(hitEnt) && hitEnt.GetTeam() == owner.GetTeam() ||
		medigunscope.buildings && medigunscope.damage && IsBuilding(hitEnt)) &&
		(TraceLine(owner.ShootPosition(), hitEntspacecenter, null) == 1 || TraceLine(owner.ShootPosition(), hitEnt.EyePosition(), null) == 1))
		{
			medigunscope.target = hitEnt
			NetProps.SetPropEntity(self, "m_hHealingTarget", hitEnt)
			NetProps.SetPropInt(self, "m_bAttacking", 1) // Not sure this is needed
			medigunscope.targetingenemy = true // Yes, this does mean friendly buildings set this to true. Hopefully shouldn't be a problem?
			// Do the maximum so they can't just spam attack or switch opponents to fire faster if the lock on delay is shorter than the fire rate.
			medigunscope.lastattack = max(Time() + medigunscope.lockondelay - medigunscope.ROF,medigunscope.lastattack)
			medigunscope.LOStime = Time()
		}
		else
		{
			medigunscope.targetingenemy = false
		}
	}
	else if (!(buttons & IN.ATTACK))
	{
		medigunscope.holding = false
	}

	// "Healing" the target is still valid
	if (medigunscope.targetingenemy && medigunscope.target && (!target.IsAlive() || (target.GetTeam() == owner.GetTeam() ) || (!IsBuilding(target) && RestrictedConds(target, self))))
	{
		medigunscope.target = null
		medigunscope.targetingenemy = false
	}

	// Handles disconnects due to range and those not using continue healing without holding the button for some reason.
	if (!medigunscope.holding && medigunscope.targetingenemy && NetProps.GetPropEntity(self, "m_hHealingTarget") == null)
	{
		medigunscope.target = null
		medigunscope.targetingenemy = false
	}

	// Not even sure why this is happening but okay
	if (medigunscope.target == null && medigunscope.targetingenemy)
	{
		medigunscope.targetingenemy = false
	}

	// Checks for LOS.
	if (medigunscope.targetingenemy)
	{
		if (!medigunscope.fovcap)
		{
			// Calculate it in the same way the medigun does, check if we have a clear path from our eyes to either the target's eyes or centre.
			local targetspacecenter = medigunscope.target.GetOrigin()
			targetspacecenter.z += medigunscope.target.GetBoundingMaxs().z / 2 //Shouldn't need to consider mins since that's always 0... I think.
			if (TraceLine(owner.ShootPosition(), targetspacecenter, null) != 1 && TraceLine(owner.ShootPosition(), target.EyePosition(), null) != 1)
			{
				// If we don't have LOS, check if we haven't had LOS for over the amount of time we are allowed.
				if (Time() - medigunscope.LOStime > LOSDISCONNECTTIME)
				{
					// If so, the connection is severed.
					medigunscope.target = null
					medigunscope.targetingenemy = false
					NetProps.SetPropEntity(self, "m_hHealingTarget", null)
				}
			}
			// If the LOS check does succeed, update LOStime.
			else
			{
				medigunscope.LOStime = Time()
			}
		}
		else
		{
			// Calculate it in the same way the medigun does, check if we have a clear path from our eyes to either the target's eyes or centre.
			local targetspacecenter = medigunscope.target.GetOrigin()
			targetspacecenter.z += medigunscope.target.GetBoundingMaxs().z / 2 //Shouldn't need to consider mins since that's always 0... I think.
			local shoootpos = owner.ShootPosition()
			if ((TraceLine(shoootpos, targetspacecenter, null) != 1 && TraceLine(shoootpos, target.EyePosition(), null) != 1) || 
			(medigunscope.fovcap < acos(AngleVectors(owner.EyeAngles()).Dot(targetspacecenter-owner.EyePosition())/((targetspacecenter-owner.EyePosition()).Length() * (AngleVectors(owner.EyeAngles()).Length())))
			&& medigunscope.fovcap < acos(AngleVectors(owner.EyeAngles()).Dot(target.EyePosition()-owner.EyePosition())/((target.EyePosition()-owner.EyePosition()).Length() * (AngleVectors(owner.EyeAngles()).Length())))))
			{
				// If we don't have LOS, check if we haven't had LOS for over the amount of time we are allowed.
				if (Time() - medigunscope.LOStime > LOSDISCONNECTTIME)
				{
					// If so, the connection is severed.
					medigunscope.target = null
					medigunscope.targetingenemy = false
					NetProps.SetPropEntity(self, "m_hHealingTarget", null)
				}
			}
			// If the LOS check does succeed, update LOStime.
			else
			{
				medigunscope.LOStime = Time()
			}
		}
	}

	// MEDIGUN FLINGING
	if (medigunscope.target && medigunscope.fling && (!medigunscope.flingair || owner.GetAbsVelocity()["z"] != 0))
	{
		local powerMult = 1
		if (medigunscope.targetingenemy) { powerMult *= medigunscope.flingpowerenemy } // power mult when flinging from an enemy
		else { powerMult *= medigunscope.flingpowerfriendly } // power mult when flinging from a teammate
		if (medigunscope.isusinguber) { powerMult *= medigunscope.flingpoweruber } // power mult during ubercharge
		if (powerMult != 0)
		{
			// below: reel into the target
			local reelSpeed = medigunscope.flingreel * powerMult
			if (reelSpeed != 0)
			{
				if (!medigunscope.flingreelconst)
				{
					owner.SetAbsVelocity(owner.GetAbsVelocity() - (owner.GetOrigin() - medigunscope.target.GetOrigin()) * reelSpeed)
				}
				else
				{
					owner.SetAbsVelocity(owner.GetAbsVelocity() - (owner.GetOrigin() - medigunscope.target.GetOrigin()).Normalized() * reelSpeed)
				}
			}
			
			// below: maintain a set distance from the target (unused, kinda weird)
			//local hoverDistance = medigunscope.range * 0.7;
			//local hoverCorrectionForce = 80;
			//local desiredPosition = target.GetOrigin() + (owner.GetOrigin() - target.GetOrigin()).Normalized() * hoverDistance
			//local correctionVelocity = (desiredPosition - owner.GetOrigin()).Normalized() * hoverCorrectionForce
			//owner.SetAbsVelocity(owner.GetAbsVelocity() + correctionVelocity)
			// below: travel towards a set spot decided by look direction
			local flingForce = medigunscope.flingspeed  * powerMult
			if (flingForce != 0)
			{
				local flingDistance = medigunscope.range * medigunscope.flingtargetdistance
				local viewDotProduct = 1 + (AngleVectors(owner.EyeAngles()).Dot((medigunscope.target.GetOrigin() - owner.GetOrigin()).Normalized())) // when looking away from the target, it pulls less because the beam gets all bent out of shape.
				if (viewDotProduct > 1) { viewDotProduct = 1 }
				local desiredPosition2 = medigunscope.target.GetOrigin() - (AngleVectors(owner.EyeAngles()) * flingDistance)
				local correctionVelocity2 = (desiredPosition2 - owner.GetOrigin()) * flingForce * viewDotProduct // I think this feels better NOT normalized. A lot less rubber-banding around one spot really fast, and a lot more power when you flick your camera, making it snappier to use.
				owner.SetAbsVelocity(owner.GetAbsVelocity() + correctionVelocity2)
			}
		}
	}

	if (medigunscope.target && IsBuilding(medigunscope.target) && !medigunscope.isusinguber) // For enemy buildings, just use the building rate.
	{
		self.AddAttribute("ubercharge rate penalty VSCRIPT", 0, 0)
		NetProps.SetPropFloat(self, "m_flChargeLevel", min(medigunscope.uber + (medigunscope.uberratebuildings)/381,1)) // 381 is a magic number
		medigunscope.uber += (medigunscope.uberratebuildings)/381
	}
	else if (medigunscope.targetingenemy && !medigunscope.isusinguber)
	{
		self.AddAttribute("ubercharge rate penalty VSCRIPT", medigunscope.uberrateenemies, 0)
		medigunscope.uber <- NetProps.GetPropFloat(self, "m_flChargeLevel")
	}
	else
	{
		self.RemoveAttribute("ubercharge rate penalty VSCRIPT")
		medigunscope.uber <- NetProps.GetPropFloat(self, "m_flChargeLevel")
	}

	if (medigunscope.target && IsBuilding(medigunscope.target) && medigunscope.target.GetTeam() == owner.GetTeam() && (Time() - medigunscope.lastattack >= medigunscope.ROF))
	{
		local healthgiven = medigunscope.buildings
		if (NetProps.GetPropInt(medigunscope.target, "m_nShieldLevel"))
		{
			healthgiven *= 0.34
		}
		if (LASTHEAL[medigunscope.target.GetEntityIndex()] > medigunscope.lastattack)
		{
			healthgiven *= pow((Time() - LASTHEAL[medigunscope.target.GetEntityIndex()]) / (Time() - medigunscope.lastattack), 0.7)
		}
		if (medigunscope.isusinguber)
		{
			healthgiven *= medigunscope.uberbuildingsmult
			// Need to use the "AddHealth" input for buildings for some reason.
			medigunscope.target.AcceptInput("AddHealth", healthgiven.tostring(), null null)
			if (medigunscope.ammogivebuildings && medigunscope.target.GetClassname() == "obj_sentrygun")
			{
				local maxammo = (NetProps.GetPropInt(medigunscope.target, "m_iUpgradeLevel") - 1 ? 200 : 150) * GetWearableAttribute(medigunscope.target.GetOwner(), "mvm sentry ammo", 1)
				NetProps.SetPropInt(medigunscope.target, "m_iAmmoShells", min(NetProps.GetPropInt(medigunscope.target, "m_iAmmoShells") + (medigunscope.ammogivebuildings * medigunscope.ammogivebuildingsuber),maxammo))
				NetProps.SetPropInt(medigunscope.target, "m_iAmmoRockets", min(NetProps.GetPropInt(medigunscope.target, "m_iAmmoRockets") + (medigunscope.ammogivebuildings * medigunscope.ammogivebuildingsuber),20))
			}
			
			if (medigunscope.upgradegive && NetProps.GetPropInt(medigunscope.target, "m_bMiniBuilding") != 1 && NetProps.GetPropInt(medigunscope.target, "m_iUpgradeLevel") < 3)
			{
				local upgrade = NetProps.GetPropInt(medigunscope.target, "m_iUpgradeMetal")
				local upgraderequire = NetProps.GetPropInt(medigunscope.target, "m_iUpgradeMetalRequired")
				if (upgrade + (medigunscope.upgradegive * medigunscope.upgradegiveuber) >= upgraderequire)
				{
					NetProps.SetPropInt(medigunscope.target, "m_iHighestUpgradeLevel", min(NetProps.GetPropInt(medigunscope.target, "m_iUpgradeLevel") + 1,3))
					NetProps.SetPropInt(medigunscope.target, "m_iUpgradeMetal", 0)
				}
				else
				{
					NetProps.SetPropInt(medigunscope.target, "m_iUpgradeMetal", upgrade + (medigunscope.upgradegive * medigunscope.upgradegiveuber))
				}
			}
		}
		else
		{
			medigunscope.target.AcceptInput("AddHealth", healthgiven.tostring(), null null)
			if (medigunscope.ammogivebuildings && medigunscope.target.GetClassname() == "obj_sentrygun")
			{
				local maxammo = (NetProps.GetPropInt(medigunscope.target, "m_iUpgradeLevel") - 1 ? 200 : 150) * GetWearableAttribute(medigunscope.target.GetOwner(), "mvm sentry ammo", 1)
				NetProps.SetPropInt(medigunscope.target, "m_iAmmoShells", min(NetProps.GetPropInt(medigunscope.target, "m_iAmmoShells") + (medigunscope.ammogivebuildings),maxammo))
				NetProps.SetPropInt(medigunscope.target, "m_iAmmoRockets", min(NetProps.GetPropInt(medigunscope.target, "m_iAmmoRockets") + (medigunscope.ammogivebuildings),20)) // I don't think max rockets should ever change?
			}

			if (medigunscope.upgradegive && NetProps.GetPropInt(medigunscope.target, "m_bMiniBuilding") != 1 && NetProps.GetPropInt(medigunscope.target, "m_iUpgradeLevel") < 3)
			{
				local upgrade = NetProps.GetPropInt(medigunscope.target, "m_iUpgradeMetal")
				local upgraderequire = NetProps.GetPropInt(medigunscope.target, "m_iUpgradeMetalRequired")
				if (upgrade + (medigunscope.upgradegive) >= upgraderequire)
				{
					NetProps.SetPropInt(medigunscope.target, "m_iHighestUpgradeLevel", min(NetProps.GetPropInt(medigunscope.target, "m_iUpgradeLevel") + 1,3))
					NetProps.SetPropInt(medigunscope.target, "m_iUpgradeMetal", 0)
				}
				else
				{
					NetProps.SetPropInt(medigunscope.target, "m_iUpgradeMetal", upgrade + (medigunscope.upgradegive))
				}
			}
		}
		LASTHEAL[medigunscope.target.GetEntityIndex()] = Time()
		medigunscope.lastattack = Time()
	}
	// Actually do the attack
	else if (medigunscope.targetingenemy && (Time() - medigunscope.lastattack >= medigunscope.ROF))
	{
		local target = medigunscope.target
		NetProps.SetPropEntity(self, "m_hHealingTarget", target)
		local damagetype = 0
		local customtype = 0
		if (owner.IsCritBoosted())
		{
			damagetype = Constants.FDmgType.DMG_ACID // Crit damage
			customtype = 47 // Gib disintegrate. Also very helpfully makes this do minicrits, even though it missed the memo and it already should do crits.
		}
		// Did the TF2C team seriously not add their conditions into the constants. BRUH.
		else if (owner.InCond(Constants.ETFCond.TF_COND_OFFENSEBUFF) || owner.InCond(Constants.ETFCond.TF_COND_ENERGY_BUFF) || owner.InCond(Constants.ETFCond.TF_COND_NOHEALINGDAMAGEBUFF) || owner.InCond(143))
		{
			customtype = 47 // Gib disintegrate. Also very helpfully makes this do minicrits, even though it missed the memo and it already should do minicrits.
		}
		else
		{
			customtype = 46 // Disintegrate
		}

		medigunscope.lastattack = Time()

		// So the blood splatter happens in the centre of the enemy rather than on the ground.
		local targetspacecenter = target.GetOrigin()
		targetspacecenter.z += target.GetBoundingMaxs().z / 2 //Shouldn't need to consider mins since that's always 0... I think.
		
		// Split into five catagories to help handle uber.
		if (medigunscope.isusinguber && IsBuilding(target))
		{
			// Do not deal the custom damage type to buildings, since apperently they take less damage from these custom damage types? They wouldn't do anything anyways.
			target.TakeDamageCustom(self, owner, self, Vector(0, 0, 0), targetspacecenter, medigunscope.damage * medigunscope.uberdamagemult, damagetype, 0);
		}
		else if (IsBuilding(target))
		{
			target.TakeDamageCustom(self, owner, self, Vector(0, 0, 0), targetspacecenter, medigunscope.damage, damagetype, 0);
		}
		else if (medigunscope.isusinguber)
		{
			target.TakeDamageCustom(self, owner, self, Vector(0, 0, 0), targetspacecenter, medigunscope.damage * medigunscope.uberdamagemult, damagetype, customtype);
			if (medigunscope.conduber != 0)
			{
				// Apply the uber condition for the ROF + linger time.
				target.AddCondEx(medigunscope.conduber, medigunscope.ROF + medigunscope.condubertime, owner)
			}
		}
		else if (customtype == 47)
		{
			target.TakeDamageCustom(self, owner, self, Vector(0, 0, 0), targetspacecenter, medigunscope.damage, damagetype, customtype);
			// Normally this wouldn't apply to being crit boosted but i think that it applying to critboosting is fine in this case.
			if (medigunscope.uberhitrate)
			{
				NetProps.SetPropFloat(self, "m_flChargeLevel", min(NetProps.GetPropFloat(self, "m_flChargeLevel") + medigunscope.uberhitrate * 1.35,1))
			}
		}
		else
		{
			target.TakeDamageCustom(self, owner, self, Vector(0, 0, 0), targetspacecenter, medigunscope.damage, damagetype, customtype);
			if (medigunscope.uberhitrate)
			{
				NetProps.SetPropFloat(self, "m_flChargeLevel", min(NetProps.GetPropFloat(self, "m_flChargeLevel") + medigunscope.uberhitrate,1))
			}
		}

		if (medigunscope.condnormal != 0 && !IsBuilding(target))
		{
			// Apply the condition for the ROF + linger time.
			target.AddCondEx(medigunscope.condnormal, medigunscope.ROF + medigunscope.condnormaltime, owner)
		}
	}
	// So that medic doesn't stop "healing" the enemy if the ROF check fails
	else if (medigunscope.targetingenemy)
	{
		NetProps.SetPropEntity(self, "m_hHealingTarget", target)
	}
	else if (medigunscope.target && medigunscope.target.IsPlayer() && medigunscope.ammogive && Time() - medigunscope.lastattack >= medigunscope.ROF && !medigunscope.target.GetActiveWeapon().GetAttribute("no metal from dispensers while active", 0) && !medigunscope.target.GetActiveWeapon().GetAttribute("no metal from dispensers hidden VSCRIPT", 0))
	{
		local i = (medigunscope.target.GetActiveWeapon().GetAttribute("no primary ammo from dispensers while active", 0) ? 2 : 1)
		local playedsound = false
		// For the three main ammo types
		while (i < 4)
		{
			// Get their current ammo
			local ammoprev = medigunscope.target.GetAmmoCount(i)
			// Fill up their ammo to the maximum
			local k = 4096
			while (k >= 1)
			{
				medigunscope.target.GiveAmmo(k, i, true)
				k *= 0.5
			}
			// Get the maximum
			local max = medigunscope.target.GetAmmoCount(i)
			// Give them back their ammo + their maximum ammo times the banner ammount. Also play the sound if we haven't yet.
			if (ammoprev != max)
			{
				medigunscope.target.SetAmmoCount(i, ammoprev)
				if (!playedsound)
				{
					medigunscope.target.GiveAmmo(floor(min(max * medigunscope.ammogive, max - ammoprev)), i, false)
					playedsound = true
				}
				else
				{
					medigunscope.target.GiveAmmo(floor(min(max * medigunscope.ammogive, max - ammoprev)), i, true)
				}
			}
			i += 1
		}
		medigunscope.lastattack = Time()
	}

	return 0.1
}

function RestrictedConds(entity, comp)
{
	return (entity.InCond(3) && entity.GetDisguiseTeam() == comp.GetTeam()) || entity.InCond(4)
}

function MedibombEnemyChecker()
{
	local entity = null
	entity = Entities.FindByClassnameNearest("player", self.GetOrigin(), 100)
	while (entity)
	{
		if (TouchingBBoxes(entity, self) && entity.GetTeam() != self.GetTeam() && entity.IsAlive())
		{
			local bombscope = self.GetOrCreatePrivateScriptScope()
			bombscope.fulldamageent <- entity
			self.AcceptInput("detonate", "", entity, entity)
			return
		}
		entity = Entities.FindByClassnameWithin(entity, "player", self.GetOrigin(), 100)
	}
	return 0.01 // An acceptable time I think
}

function UpdateOnRemove(self)
{
	local bombscope = self.GetScriptScope()

	if ("explodinghealgrenade" in bombscope && bombscope.explodinghealgrenade)
	{
		local pipe = Entities.CreateByClassname("tf_projectile_pipe")
		//self.AcceptInput("detonate", "", null, null)
		NetProps.SetPropEntity(pipe, "m_hLauncher", NetProps.GetPropEntity(self,"m_hLauncher")) //Makes the following work correctly.
		pipe.SetOrigin(self.GetOrigin()) // Set its position to that of the brick.
		pipe.SetOwner(self.GetOwner()) // Set its owner to that of the brick.
		pipe.SetThrower(self.GetThrower()) // Set its owner to that of the brick, again.
		//pipe.GetDamage() // Not sure if this does anything, but i'm also not sure it doesn't do anything?
		pipe.SetDamage(bombscope.damage) // Corrects the damage.
		pipe.GetDamageRadius() // Corrects the radius. For some reason brick doesn't calculate its stat correctly but doing it like this does calculate it correctly since m_hLauncher is correct.
		NetProps.SetPropEntity(pipe, "m_hOriginalLauncher", NetProps.GetPropEntity(self,"m_hOriginalLauncher")) // Gives it the correct explosion effect.
		NetProps.SetPropEntity(pipe, "m_hDeflectOwner", NetProps.GetPropEntity(self,"m_hDeflectOwner")) // Deflect checks.
		NetProps.SetPropInt(pipe, "m_iDeflected", NetProps.GetPropInt(self,"m_iDeflected"))
		pipe.AddContext("IsBrickExplodeFixPipe", "yep", 0.1) // So we know that this is the brick explode pipe in damage calculations
		pipe.AddContext("IsMedigunBomb", "yep", 0.1) // So we know that this is the brick explode pipe in damage calculations
		if ("fulldamageent" in bombscope)
		{
			pipe.AddContext("FullDamageEnt", bombscope.fulldamageent.GetEntityIndex().tostring(), 0.1) // So we know that this is the brick explode pipe in damage calculations
		}
		NetProps.SetPropEntity(pipe, "m_hEffectEntity", self.GetThrower()) // So the icon icon can be corrected
		pipe.AcceptInput("detonate", "", self, self.GetThrower())
		self.Destroy()
	}
}

function OnTakeDamage(self,info)
{
	if (!self.IsPlayer() || !info.GetInflictor() || !info.GetAttacker() || self.GetTeam() == info.GetAttacker().GetTeam())
	{
		return true
	}

	local fulldamage = info.GetInflictor().GetContext("FullDamageEnt")
	if (fulldamage != "" && EntIndexToHScript(fulldamage.tointeger()) == self)
	{
		info.SetDamage(info.GetInflictor().GetDamage())
	}
	local medigunbomb = info.GetInflictor().GetContext("IsMedigunBomb")
	if (medigunbomb != "")
	{
		local weapon = info.GetWeapon()
		if (!NetProps.GetPropBool(weapon, "m_bChargeRelease"))
		{
			NetProps.SetPropFloat(weapon, "m_flChargeLevel", min(NetProps.GetPropFloat(weapon, "m_flChargeLevel") + weapon.GetAttribute("medigun targets enemies uber per hit", 0)*(info.GetDamage()/weapon.GetAttribute("medigun targets enemies rework", 0)), 1))
		}
		else
		{
			local cond = weapon.GetAttribute("medigun targets enemies cond uber hit", 0)
			if (cond)
			{
				self.AddCondEx(cond, weapon.GetAttribute("medigun targets enemies cond uber hit time", 0), info.GetAttacker())
			}
			local extrahitcondscale = weapon.GetAttribute("medigun targets enemies cond uber hit scale", 0).tointeger()
			if (extrahitcondscale)
			{
				local min = weapon.GetAttribute("medigun targets enemies cond uber hit scale min", 0)
				if (info.GetDamage() >= min)
				{
					local max = weapon.GetAttribute("medigun targets enemies cond uber hit scale max", 0)
					local scale = clamp((info.GetDamage() - min)/(max - min),0.25,1)
					self.AddCondEx(extrahitcondscale, weapon.GetAttribute("medigun targets enemies cond uber hit scale time", 0)*scale, info.GetAttacker())
				}
			}
		}
	}
}

function GeneratorEnemyChecker()
{
	local generatorscope = self.GetOrCreatePrivateScriptScope()
	if (!NetProps.GetPropBool(self, "m_bEnabled"))
	{
		return generatorscope.ROF
	}
	local entity = Entities.FindByClassnameWithin(null, "player", self.GetOrigin(), NetProps.GetPropFloat(self, "m_flRadius")*1.05)
	while (entity)
	{
		if (entity.GetTeam() != self.GetTeam() && entity.IsAlive())
		{
			local targetspacecenter = entity.GetOrigin()
			targetspacecenter.z += entity.GetBoundingMaxs().z / 2 //Shouldn't need to consider mins since that's always 0... I think.
			if (generatorscope.damage > 0)
			{
				entity.TakeDamageCustom(self, self.GetOwner(), generatorscope.weapon, Vector(0, 0, 0), targetspacecenter, generatorscope.damage, 0, 0);
			}
			if (generatorscope.cond != 0)
			{
				entity.AddCondEx(generatorscope.cond, generatorscope.condtime, self.GetOwner())
			}
		}
		entity = Entities.FindByClassnameWithin(entity, "player", self.GetOrigin(), NetProps.GetPropFloat(self, "m_flRadius")*1.05)
	}
	return generatorscope.ROF
}

function MedigunUberChecker()
{
	local medigunscope = self.GetOrCreatePrivateScriptScope()
	if (NetProps.GetPropBool(self, "m_bChargeRelease"))
	{
		self.GetOwner().AddCondEx(medigunscope.condwhileubered, 0.15, self.GetOwner())
	}
	else
	{
		AddThinkToEnt(self, "")
	}
}

function IsBuilding(entity)
{
	local classname = entity.GetClassname()
	return classname == "obj_sentrygun" || classname == "obj_dispenser" || classname == "obj_jumppad" || classname == "obj_teleporter"
}

function TouchingBBoxes(ent1, ent2)
{
	local max = ent1.GetBoundingMaxs() - ent2.GetBoundingMins() + ent1.GetOrigin()
	local min = ent1.GetBoundingMins() - ent2.GetBoundingMaxs() + ent1.GetOrigin()
	local origin = ent2.GetOrigin()
	if (max.x >= origin.x && min.x <= origin.x && max.y >= origin.y && min.y <= origin.y && max.z >= origin.z && min.z <= origin.z)
	{
		return true
	}
	else
	{
		return false
	}
}

IncludeScript("lib/mapbasehookcollector.nut")