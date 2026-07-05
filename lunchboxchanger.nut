// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

IncludeScript("lib/clocksutils.nut");

PrecacheParticleSystem("superrare_beams1")

::DamageTypeOverrideEventTable <- {
	function OnGameEvent_weapon_equipped(params)
	{
		local weapon = EntIndexToHScript(params.entindex)
		weapon.ValidateScriptScope()
	}
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.RemoveCustomAttribute("disable weapon switch")
		if (GetWearableAttribute(player, "item_meter_resupply_denied", 0))
		{
			for (local i = 0; i < 8; i++)
			{
				NetProps.SetPropFloatArray(player, "m_Shared.m_flItemChargeMeter", 0.1, i)
			}
		}
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
			player.RemoveCustomAttribute("major move speed bonus")
		}
	}
}

__CollectGameEventCallbacks(DamageTypeOverrideEventTable)

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
		case 9: // Regen Sandvich, gain 15 regen for 15 seconds. Also cancels the taunt early.
			hPlayer.AddCustomAttribute("CARD: health regen", 15, 15) 
			if (!triggered)
			{
				EntFireByHandle(self, "CallScriptFunction", "StopEatingEarly", 1.3, null, null)
				self.AddContext("triggered", "yes", 0)
			}
			break;
		case 10: // Cancels the taunt immediately
			NetProps.SetPropFloat(self, "m_flNextPrimaryAttack", Time()) // So you switch off immediately
			hPlayer.CancelTaunt()
			break;
		case 11: // Cancels the taunt slightly less than immediately, just in time to hear heavy say "nom", at normal speed.
			if (!triggered)
			{
				EntFireByHandle(self, "CallScriptFunction", "StopEatingEarly", 0.42, null, null)
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
	AddTimedWearerAttribute(owner,"CARD: damage bonus", 1.2, 8)
	//AddTimedWearerAttribute(owner,"attach particle effect static", 4, 12) Particles are bugging out and I can't be bothered
	owner.AddCondEx(36, 8, self)
}

function StopEatingEarly()
{
	self.AddContext("triggered", "", 0)
	NetProps.SetPropFloat(self, "m_flNextPrimaryAttack", Time()) // So you switch off immediately
	local owner = self.GetOwner()
	owner.CancelTaunt()

	owner.Weapon_Switch(owner.GetWeapon(0))
}