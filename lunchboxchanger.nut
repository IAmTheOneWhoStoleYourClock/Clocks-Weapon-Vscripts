// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, although with how much of a headache this gave me I'm sure there's something
//

//
// DETECTING SANDVICH CONSUMPTION, UNFORTUNATELY, IS RIDICULOUSLY INEFFICENT. SET THIS TO FALSE TO TURN IT OFF ENTIRELY!
//

local sandvichdetectionon = true

//
// Okay back to buisness
//

IncludeScript("lib/clocksutils.nut");

MOSTRECENTHEAL <- array(MaxPlayers(), 0)
PACKSTABLE <- {
	item_healthkit_small = 0.2
	item_healthkit_medium = 0.5
	item_healthkit_full = 1
	item_healthammokit = 0.5
}
PLAYERBOUNDMAX <- Vector(16,16,0)
PLAYERBOUNDMIN <- Vector(-16,-16,-72)

::DamageTypeOverrideEventTable <- {
	function OnGameEvent_weapon_equipped(params)
	{
		local weapon = EntIndexToHScript(params.entindex)
		weapon.ValidateScriptScope()
		if (weapon.GetAttribute("item_meter_resupply_denied", 0))
		{
			EntFireByHandle(weapon.GetOwner(), "CallScriptFunction", "RidMeters", 0, null, null)
		}
	}
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.RemoveCustomAttribute("disable weapon switch")
		if (GetWearableAttribute(player, "grenades1_resupply_denied", 0))
		{
			NetProps.SetPropIntArray(player, "m_iAmmo", 0, 4)
		}
		if (GetWearableAttribute(player, "special sandvich", 0) != 3) //There's definately a better way of doing this but I REALLY DON'T CARE RN
		{
			player.RemoveCustomAttribute("major move speed bonus")
		}
		if (GetWearableAttribute(player, "special sandvich", 0) != 6) //There's definately a better way of doing this but I REALLY DON'T CARE RN
		{
			player.RemoveCustomAttribute("swimming mastery")
		}
		if (GetWearableAttribute(player, "special sandvich", 0) != 20) //There's definately a better way of doing this but I REALLY DON'T CARE RN
		{
			player.RemoveCustomAttribute("regen bonus sandvichlander")
		}
	}
	function OnGameEvent_player_healonhit(params)
	{
		MOSTRECENTHEAL[params.entindex] = params.amount
	}
}

__CollectGameEventCallbacks(DamageTypeOverrideEventTable)

function RidMeters()
{
	for (local i = 0; i < 8; i++)
	{
		NetProps.SetPropFloatArray(self, "m_Shared.m_flItemChargeMeter", 0.1, i)
	}
}

function ApplyBiteEffects()
{
	if (!hPlayer.IsPlayer())
	{
		return
	}
	local triggered = self.GetContext("triggered") != ""
	switch (self.GetAttribute("special sandvich", 0))
	{
		case 1: // Dalokohs Bar, you know what this one does.
			hPlayer.AddCustomAttribute("hidden maxhealth non buffed", 50, 30) //Fun fact! This is just how the normal dalokohs bar works internally.
			break;
		case 2: // Buffalo steak sandvich, you know what this one does.
			if (!triggered)
			{
				EntFireByHandle(self, "CallScriptFunction", "FinishedEatingBuffalo", hPlayer.GetTauntRemoveTime() - Time(), null, null)
				self.AddContext("triggered", "yes", 0)
			}
			break;
		case 3: // Sandvichlander! Every time you eat it, gain more movespeed.
			if (!triggered)
			{
				EntFireByHandle(self, "CallScriptFunction", "FinishedEatingSandvichlander", hPlayer.GetTauntRemoveTime() - Time(), null, null)
				self.AddContext("triggered", "yes", 0)
			}
			break;
		case 4: // You jump twice as high for 10 seconds after eating this. Why? It's funny. That's why.
			hPlayer.AddCustomAttribute("major increased jump height", 2, 10)
			hPlayer.AddCustomAttribute("dmg taken from fall reduced", 0, 10) // Also cancel fall damage
			hPlayer.AddCustomAttribute("boots falling stomp", 1, 10) // For the fun of it
			break;
		case 5: // Bunny hop for 15 seconds. Again, cause it's funny.
			hPlayer.AddCustomAttribute("auto jumping", 1, 15) 
			hPlayer.AddCustomAttribute("duck jumping", 1, 15)
			hPlayer.AddCustomAttribute("increased air control", 1.5, 15)
			break;
		case 6: // Swim in air sandvich, fairly typical. Lasts for 12 seconds.
			hPlayer.AddCondEx(107, 12, self)
			hPlayer.AddCustomAttribute("swimming mastery", 1, 12) 
			break;
		case 7: // Eating the sandvich gives you a 20% damage bonus on all of your weapons for 8 seconds. (No special boosts for melee, use the buffalo if you want that!)
			if (!triggered)
			{
				EntFireByHandle(self, "CallScriptFunction", "FinishedEatingBuffFood", hPlayer.GetTauntRemoveTime() - Time(), null, null)
				self.AddContext("triggered", "yes", 0)
			}
			break;
		case 8: // Buffed Buffalo Steak Sandvich, it makes you move 5% faster than before, swing 10% faster with your melee, and take half the knockback force!
			if (!triggered)
			{
				EntFireByHandle(self, "CallScriptFunction", "FinishedEatingBuffBuffalo", hPlayer.GetTauntRemoveTime() - Time(), null, null)
				self.AddContext("triggered", "yes", 0)
			}
			break;
		case 9: // Regen Sandvich, gain 15 regen for 20 seconds. Also cancels the taunt early.
			hPlayer.AddCustomAttribute("CARD: health regen", 15, 20) 
			if (!triggered)
			{
				EntFireByHandle(self, "CallScriptFunction", "StopEatingEarly", 1.3, null, null)
				self.AddContext("triggered", "yes", 0)
			}
			break;
		case 10: // Cancels the taunt immediately
			NetProps.SetPropFloat(self, "m_flNextPrimaryAttack", Time() + 0.1) // So you switch off immediately
			hPlayer.CancelTaunt()
			break;
		case 11: // Cancels the taunt slightly less than immediately, just in time to hear heavy say "nom", at normal speed.
			if (!triggered)
			{
				EntFireByHandle(self, "CallScriptFunction", "StopEatingEarly", 0.42, null, null)
				self.AddContext("triggered", "yes", 0)
			}
			break;
		case 12: // Eat glass.
			hPlayer.BleedPlayer(8)
			if (!triggered)
			{
				EntFireByHandle(self, "CallScriptFunction", "FinishedEatingGlass", hPlayer.GetTauntRemoveTime() - Time(), null, null)
				self.AddContext("triggered", "yes", 0)
			}
			break;
		case 13: // Lifesteal sandvich. Gain the conchereror buff, but have the speed boost from it removed. Lasts 16 seconds.
			if (!triggered)
			{
				EntFireByHandle(self, "CallScriptFunction", "FinishedLifestealSandvich", hPlayer.GetTauntRemoveTime() - Time(), null, null)
				self.AddContext("triggered", "yes", 0)
			}
			break;
		case 14: // Team Support Sandvich, heals allies.
			hPlayer.AddCondEx(55, 1, self)
			hPlayer.AddCustomAttribute("medigun healing received penalty", 0, 1) // Disable the healing from the effect itself, but keep healing from everything but mediguns. Good enough.
			break;
		case 15: // Big Sandvich, tranqs you and increases the ammount of damage you take by 15%.
			hPlayer.AddCondEx(136, 8, self)
			hPlayer.AddCustomAttribute("dmg taken increased", 1.15, 8)
			break;
		case 16: // Team Support Sandvich 2, your sandviches heal more for 2 seconds after using them. USE "custom lunchbox throwable type" "1" ON THE SANDVICH ITSELF!
			if (!triggered) // TO DO: ADD A WAY TO HAVE MULTIPLE SANDVICHES AT ONCE TO GO WITH THIS!
			{
				self.AddAttribute("custom lunchbox throwable type", 2, 0)
				AddAttributeAfterTime(self, "custom lunchbox throwable type", 1, 10)
				EntFireByHandle(self, "CallScriptFunction", "Untrigger", hPlayer.GetTauntRemoveTime() - Time(), null, null)
				self.AddContext("triggered", "yes", 0)
			}
			break;
		case 17: // Glass Sandvich 2, take lots of damage (150 total) to move VERY fast for 8 seconds. USE "self dmg push force decreased"	"0" ON THE SANDVICH BECAUSE I CAN'T BE BOTHERED TO MAKE IT DO NO SELF KB!
			hPlayer.BleedPlayerEx(8, 5, false, 0)
			hPlayer.AddCustomAttribute("dmg taken increased", 1.15, 8)
			hPlayer.AddCustomAttribute("major move speed bonus", 1.5, 8)
			if (!triggered) // (hInflictor, hAttacker, hWeapon, vecDamageForce, vecDamagePosition, flDamage, nDamageType, nCustomDamageType)
			{
				hPlayer.TakeDamageCustom(self,hPlayer,self,hPlayer.GetOrigin(),hPlayer.GetOrigin(),16,0,0)
				self.AddContext("triggered", "yes", 0)
				EntFireByHandle(self, "CallScriptFunction", "Untrigger", hPlayer.GetTauntRemoveTime() - Time(), null, null)
			}
			break;
		case 18: // Overhealing sandvich. Normal healing still applies, incase you want it to heal more damage than overheal. (And other technical reasons.)
			local newhealth = min(hPlayer.GetHealth() + 30 * self.GetAttribute("lunchbox healing overheal",1), hPlayer.GetMaxHealth() * self.GetAttribute("lunchbox healing overheal cap",0) + self.GetAttribute("lunchbox healing overheal cap additive",0))
			hPlayer.SetHealth(newhealth)
		case 19: // Overhealing sandvich + Dalokohs Bar, like the good ol' days.
			local newhealth = min(hPlayer.GetHealth() + 30 * self.GetAttribute("lunchbox healing overheal",1), hPlayer.GetMaxHealth() * self.GetAttribute("lunchbox healing overheal cap",0) + self.GetAttribute("lunchbox healing overheal cap additive",0))
			hPlayer.AddCustomAttribute("hidden maxhealth non buffed", 50, 30) //Fun fact! This is just how the normal dalokohs bar works internally.
			hPlayer.SetHealth(newhealth)
		case 20: // Sandvichlander 2! Every time you eat it, gain more health regen. Also overheals.
			local newhealth = min(hPlayer.GetHealth() + 30 * self.GetAttribute("lunchbox healing overheal",1), hPlayer.GetMaxHealth() * self.GetAttribute("lunchbox healing overheal cap",0) + self.GetAttribute("lunchbox healing overheal cap additive",0))
			hPlayer.SetHealth(newhealth)
			if (!triggered)
			{
				EntFireByHandle(self, "CallScriptFunction", "FinishedEatingSandvichlander2", hPlayer.GetTauntRemoveTime() - Time(), null, null)
				self.AddContext("triggered", "yes", 0)
			}
			break;
	}
}

function FinishedEatingBuffalo()
{
	self.AddContext("triggered", "", 0) // Remove context just straight up doesn't work...
	local owner = self.GetOwner()
	if (!owner.IsPlayer || !owner.IsAlive())
	{
		return
	}
	owner.AddCondEx(19, 16, self)
	owner.AddCondEx(41, 16, self)
	owner.Weapon_Switch(owner.GetWeapon(2))
	owner.AddCustomAttribute("disable weapon switch", 1, 16) // The condition will already do this for all normal weapons, but non melee-weapons or melees in other slots will mess with it, so do this as well.
}

function FinishedEatingSandvichlander()
{
	self.AddContext("triggered", "", 0)
	local owner = self.GetOwner()
	if (!owner || !owner.IsValid() || !owner.IsPlayer() || !owner.IsAlive())
	{
		return
	}
	local eatcap = self.GetAttribute("sandvichlander eat cap", 0)
	local speedcap = self.GetAttribute("sandvichlander speed cap", 1)
	owner.AddCustomAttribute("move speed bonus sandvichlander", min(owner.GetCustomAttribute("move speed bonus sandvichlander", 1) * pow(speedcap, 1/eatcap),speedcap), 0)
}

function FinishedEatingBuffBuffalo()
{
	self.AddContext("triggered", "", 0)
	local owner = self.GetOwner()
	if (!owner.IsPlayer || !owner.IsAlive())
	{
		return
	}
	owner.AddCondEx(19, 16, self)
	owner.AddCondEx(41, 16, self)
	owner.Weapon_Switch(owner.GetWeapon(2))
	AddTimedAttribute(owner.GetWeapon(2),"melee attack rate bonus", 0.9, 16)
	owner.AddCustomAttribute("damage force reduction", 0.5, 16)
	owner.AddCustomAttribute("major move speed bonus", 1.05, 16)
	owner.AddCustomAttribute("disable weapon switch", 1, 16) // The condition will already do this for all normal weapons, but non melee-weapons or melees in other slots will mess with it, so do this as well.
}

function FinishedEatingBuffFood()
{
	self.AddContext("triggered", "", 0)
	local owner = self.GetOwner()
	if (!owner.IsPlayer() || !owner.IsAlive())
	{
		return
	}
	AddTimedWearerAttribute(owner,"CARD: damage bonus", 1.2, 8)
	//AddTimedWearerAttribute(owner,"attach particle effect static", 4, 12) Particles are bugging out and I can't be bothered
	owner.AddCondEx(36, 8, self)
}

function StopEatingEarly()
{
	self.AddContext("triggered", "", 0)
	NetProps.SetPropFloat(self, "m_flNextPrimaryAttack", Time() + 0.1) // So you switch off immediately
	local owner = self.GetOwner()
	owner.CancelTaunt()

	owner.Weapon_Switch(owner.GetWeapon(0))
}

function FinishedEatingGlass()
{
	self.AddContext("triggered", "", 0)
	local owner = self.GetOwner()
	if (!owner.IsPlayer() || !owner.IsAlive())
	{
		return
	}
	AddTimedWearerAttribute(owner,"bleeding duration", 8, 8)
	owner.BleedPlayer(8)
}

function FinishedLifestealSandvich()
{
	self.AddContext("triggered", "", 0)
	local owner = self.GetOwner()
	if (!owner.IsPlayer || !owner.IsAlive())
	{
		return
	}
	owner.AddCondEx(29, 16, self)
	owner.AddCustomAttribute("major move speed bonus", 0.7142857, 16)
}

function FinishedEatingSandvichlander2()
{
	self.AddContext("triggered", "", 0)
	local owner = self.GetOwner()
	if (!owner || !owner.IsValid() || !owner.IsPlayer() || !owner.IsAlive())
	{
		return
	}
	local regen = self.GetAttribute("sandvichlander regen", 0)
	local regencap = self.GetAttribute("sandvichlander regen cap", 1)
	owner.AddCustomAttribute("regen bonus sandvichlander", min(owner.GetCustomAttribute("regen bonus sandvichlander", 0) + regen,regencap), 0)
}

function Untrigger()
{
	self.AddContext("triggered", "", 0)
}

//
// This part handles the thrown sandvich. Nothing too out of the ordinary here.
//


Entities.EnableEntityListening()
Hooks.Add(this, "OnEntitySpawned", function(entity)
{
	entity.SetContextThink("EntitySpawnSandvichThrow", EntitySpawnSandvichThrow, 0.01);
}, "EntitySpawnSandvichThrow" );

function EntitySpawnSandvichThrow(entity)
{
	if (!entity || !entity.IsValid())
	{
		return
	}

	if (!startswith(entity.GetClassname(),"item_health"))
	{
		return
	}

	local owner = entity.GetOwner()
	if(owner != null && owner.IsPlayer())
	{
		entity.SetSkin(owner.GetTeam() - 2)
		// If it has this stat, allow the user to eat their own thrown sandvich.
		if (GetWearableAttribute(owner, "eat thrown sandviches", 0) > 0)
		{
			entity.AddContext("TrueOwner", owner.GetEntityIndex().tostring(), 0)
			entity.SetOwner(null)
		}
		entity.AddContext("IsSandvich", "yer", 0)
		if (sandvichdetectionon)
		{
			entity.SetThinkFunction("AreWeThereYet", 0)
		}
		entity.ValidateScriptScope()
		entity.SetOrigin(entity.GetOrigin())
	}
}

// Run this a mere EVERY. SINGLE. FRAME. No, there is not a better way to do this. (I think)
// The reason we need to do this is because otherwise the visual feedback for healing gets messed up, and we can't properly detect getting picked up by somebody standing on us.
function AreWeThereYet()
{
	if (!self || !self.IsValid())
	{
		return 9
	}
	local pickeruper = Entities.FindByClassname(null, "player")
	while (pickeruper != null && (!TouchingBBox(self, pickeruper) || pickeruper == self.GetOwner() || !CanBeHealedByHealthKits(pickeruper)))
	{
		pickeruper = Entities.FindByClassname(pickeruper, "player")
	}

	// If we have a valid player, we can leave this nightmare. THANK GOODNESS.
	if (pickeruper)
	{
		ThrownLunchboxAcquired(self, pickeruper)
	}
	// The nightmare continues.
	else
	{
		return 0
	}
}

function TouchingBBox(ent1, ent2)
{
	// Okay so, let me be clear. THIS IS HORRENDOUS!
	// DO. NOT. DO. THIS.
	// Unfortunately, due to, persumably, an issue in how the origin is reported, this is, in fact, 100% nessesary. FOR THIS SPECIFIC SENARIO.
	// THIS IS THE WRONG WAY TO DO THIS!
	// BIG RED X!
	// Okay anyways

	local bboxmax1 = ent1.GetBoundingMaxs()
	local bboxmin1 = ent1.GetBoundingMins()

	local bboxmax2 = ent2.GetBoundingMaxs()
	local bboxmin2 = ent2.GetBoundingMins()
	
	// Look back through all of the entities to find one that's in a bounding box created like... that.
	// The math reason i'm doing that is because if a box calculated as such contains the origin, the boxes should intersect.
	local entity = Entities.FindByClassnameWithinBox(null, "player", bboxmin1 - bboxmax2 + ent1.GetOrigin(), bboxmax1 - bboxmin2 + ent1.GetOrigin())
	local start = entity
	local ran = false
	while (entity != null && entity != ent2 && (entity != start || !ran))
	{
		entity = Entities.FindByClassnameWithinBox(entity, "player", bboxmin1 - bboxmax2 + ent1.GetOrigin(), bboxmax1 - bboxmin2 + ent1.GetOrigin())
		ran = true
	}

	// If we've found an entity in that box that is the one we are looking for, great job! It's in it!
	if (entity == ent2)
	{
		return true
	}
	// Otherwise we didn't find it. Did I mention we need to repeat through this for every single player?
	else
	{
		return false
	}
}

// Can the player be healed by healthkits?
function CanBeHealedByHealthKits(player)
{
	local activeweapon = player.GetActiveWeapon()
	local overheal = GetWearableAttribute(player, "health kits can overheal on wearer", 0) + activeweapon.GetAttribute("health kits can overheal on active", 0)

	local owner
	if (self.GetContext("TrueOwner") != "")
	{
		owner = EntIndexToHScript(self.GetContext("TrueOwner").tointeger())
	}
	else
	{
		owner = self.GetOwner()
	}

	local enemy = false
	if (owner == player)
	{
		overheal += GetWearableAttribute(owner, "sandvich can overheal self", 0)
	}
	else if (owner.GetTeam() != player.GetTeam())
	{
		overheal += GetWearableAttribute(owner, "sandvich can overheal enemy", 0)
		enemy = true
	}
	else
	{
		overheal += GetWearableAttribute(owner, "sandvich can overheal friend", 0)
	}

	if (GetWearableAttribute(player, "health from packs decreased", 1) == 0 || activeweapon.GetAttribute("health from packs decreased on active", 1) == 0)
	{
		return false
	}

	return (
		(player.GetMaxHealth() > player.GetHealth()) ||
		(overheal > 0 && player.GetMaxHealth() * 1.5 * GetWearableAttribute(player, "patient overheal penalty", 1) > player.GetHealth()) ||
		// This entire last condition is purely so that sandviches that deal damage to enemies are allowed through. Hopefully shouldn't decrease efficency TOO much?
		(enemy && overheal > 0 && ((player.GetMaxHealth() * PACKSTABLE[self.GetClassname()] * GetWearableAttribute(owner, "sandvich enemy healing", 1)) + GetWearableAttribute(owner, "sandvich enemy healing additive", 0)) < 0)
	)
}

function ThrownLunchboxAcquired(self, pickeruper)
{
	if (self.GetContext("IsSandvich") != "yer")
	{
		return
	}

	local owner
	if (self.GetContext("TrueOwner") != "")
	{
		owner = EntIndexToHScript(self.GetContext("TrueOwner").tointeger())
	}
	else
	{
		owner = self.GetOwner()
	}

	// We actually don't check this for much, pretty much everything we care about should be on wearer
	local weapon = GetWeaponByClass(owner,"tf_weapon_lunchbox")

	// However, if it's the same as our true owner, that means this is a thrown sandvich. Apply the thing. I guess.
	local healtotal
	if (pickeruper == owner)
	{
		healtotal = (pickeruper.GetMaxHealth() * PACKSTABLE[self.GetClassname()] * GetWearableAttribute(owner, "sandvich self healing", 1)) + GetWearableAttribute(owner, "sandvich self healing additive", 0)

		if (healtotal > 0)
		{
			pickeruper.AddCustomAttribute("sandvich VSCRIPT", GetWearableAttribute(owner, "sandvich self healing", 1), 0.00001)
			pickeruper.AddCustomAttribute("sandvich additive VSCRIPT", GetWearableAttribute(owner, "sandvich self healing additive", 0), 0.00001)
			pickeruper.AddCustomAttribute("health kits can overheal on wearer", GetWearableAttribute(owner, "sandvich can overheal self", 0), 0.00001)
		}
		else
		{
			pickeruper.AddCustomAttribute("sandvich VSCRIPT", 0, 0.00001)
		}

		local cond = GetWearableAttribute(owner, "sandvich self cond", 0)
		if (cond)
		{
			pickeruper.AddCondEx(cond, GetWearableAttribute(owner, "sandvich self cond time", 0), self)
		}
	}
	// If the teams differ, an opponent has stolen the precious sandvich!
	else if (pickeruper.GetTeam() != owner.GetTeam())
	{
		healtotal = (pickeruper.GetMaxHealth() * PACKSTABLE[self.GetClassname()] * GetWearableAttribute(owner, "sandvich enemy healing", 1)) + GetWearableAttribute(owner, "sandvich enemy healing additive", 0)

		if (healtotal > 0)
		{
			pickeruper.AddCustomAttribute("sandvich VSCRIPT", GetWearableAttribute(owner, "sandvich enemy healing", 1), 0.00001)
			pickeruper.AddCustomAttribute("sandvich additive VSCRIPT", GetWearableAttribute(owner, "sandvich enemy healing additive", 0), 0.00001)
			pickeruper.AddCustomAttribute("health kits can overheal on wearer", GetWearableAttribute(owner, "sandvich can overheal enemy", 0), 0.00001)
		}
		else
		{
			pickeruper.AddCustomAttribute("sandvich VSCRIPT", 0, 0.1)
		}

		local cond = GetWearableAttribute(owner, "sandvich enemy cond", 0)
		if (cond)
		{
			pickeruper.AddCondEx(cond, GetWearableAttribute(owner, "sandvich enemy cond time", 0), self)
		}
	}
	// Then our allies have recieved the food. As is right.
	else
	{
		healtotal = (pickeruper.GetMaxHealth() * PACKSTABLE[self.GetClassname()] * GetWearableAttribute(owner, "sandvich friend healing", 1)) + GetWearableAttribute(owner, "sandvich friend healing additive", 0)

		if (healtotal > 0)
		{
			pickeruper.AddCustomAttribute("sandvich VSCRIPT", GetWearableAttribute(owner, "sandvich friend healing", 1), 0.00001)
			pickeruper.AddCustomAttribute("sandvich additive VSCRIPT", GetWearableAttribute(owner, "sandvich friend healing additive", 0), 0.00001)
			pickeruper.AddCustomAttribute("health kits can overheal on wearer", GetWearableAttribute(owner, "sandvich can overheal friend", 0), 0.00001)
		}
		else
		{
			pickeruper.AddCustomAttribute("sandvich VSCRIPT", 0, 0.1)
		}

		local cond = GetWearableAttribute(owner, "sandvich friend cond", 0)
		if (cond)
		{
			pickeruper.AddCondEx(cond, GetWearableAttribute(owner, "sandvich friend cond time", 0), self)
		}

		switch (weapon.GetAttribute("special sandvich", 0))
		{
			case 9: // Regen Sandvich, gain 0.05 of max health in regen for 10 seconds.
				pickeruper.AddCustomAttribute("CARD: health regen", ceil(pickeruper.GetMaxHealth() * 0.05), 10) 
				break;
		}
	}

	if (healtotal < 0)
	{
		pickeruper.TakeDamageEx(self, owner, GetWeaponByClass(owner,"tf_weapon_lunchbox"), NULLVECTOR, pickeruper.GetOrigin(), -healtotal, 0)
		self.Destroy()
	}
	else if (healtotal == 0)
	{
		self.Destroy()
	}
}