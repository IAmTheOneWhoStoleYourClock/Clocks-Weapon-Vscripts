// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// mult_dmgtaken I think breaks this. mult_dmgtaken_active also might.
//

// Ignores: All taunt damage, Stomp Damage (this is no spring loaded headgear), Map elements, and Killbinding
local IGNOREDDAMAGE = [Constants.ETFDmgCustom.TF_DMG_CUSTOM_TAUNTATK_HADOUKEN, Constants.ETFDmgCustom.TF_DMG_CUSTOM_TAUNTATK_HIGH_NOON,
Constants.ETFDmgCustom.TF_DMG_CUSTOM_TAUNTATK_GRAND_SLAM, Constants.ETFDmgCustom.TF_DMG_CUSTOM_TAUNTATK_FENCING, Constants.ETFDmgCustom.TF_DMG_CUSTOM_TAUNTATK_ARROW_STAB,
Constants.ETFDmgCustom.TF_DMG_CUSTOM_TAUNTATK_GRENADE, Constants.ETFDmgCustom.TF_DMG_CUSTOM_TAUNTATK_BARBARIAN_SWING, Constants.ETFDmgCustom.TF_DMG_CUSTOM_TAUNTATK_UBERSLICE,
Constants.ETFDmgCustom.TF_DMG_CUSTOM_TAUNTATK_ENGINEER_GUITAR_SMASH, Constants.ETFDmgCustom.TF_DMG_CUSTOM_TAUNTATK_ENGINEER_ARM_KILL, Constants.ETFDmgCustom.TF_DMG_CUSTOM_TRIGGER_HURT,
Constants.ETFDmgCustom.TF_DMG_CUSTOM_CROC, Constants.ETFDmgCustom.TF_DMG_CUSTOM_TAUNTATK_GASBLAST, Constants.ETFDmgCustom.TF_DMG_CUSTOM_TAUNTATK_TRICKSHOT,
Constants.ETFDmgCustom.TF_DMG_CUSTOM_SUICIDE]

//PrecacheModel("models/weapons/c_models/c_engineer_arms_iron_fist.mdl") //Grand design arm model. I'm just going to pull a Volvo and manually hard code this.

damageping <- false
inflictorbuffer <- null
hpbuffer <- 0
nullvector <- Vector(0,0,0)
MAXWEAPONS <- 8

::MyEventTable2 <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ValidateScriptScope()
		player.PrecacheSoundScript("EngieArmor.ImpactHard")
		player.PrecacheSoundScript("EngieArmor.ImpactSoft")
		player.PrecacheSoundScript("EngieArmor.Break")
		player.PrecacheModel("models/weapons/c_models/c_engineer_arms_iron_fist.mdl") //Grand design arm model. I'm just going to pull a Volvo and manually hard code this.
	}
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ValidateScriptScope()
		if (GetWearableAttribute(player, "no sentry", 0) != 0)
		{
			local sentry = Entities.FindByClassname(null, "obj_sentrygun")
			while (sentry != null)
			{
				if (NetProps.GetPropEntity(sentry, "m_hBuilder") == player)
				{
					sentry.Kill()
				}
				sentry = Entities.FindByClassname(sentry, "obj_sentrygun")
			}
		}
		if (GetWearableAttribute(player, "no dispenser", 0) != 0)
		{
			local dispenser = Entities.FindByClassname(null, "obj_dispenser")
			while (dispenser != null)
			{
				if (NetProps.GetPropEntity(dispenser, "m_hBuilder") == player)
				{
					dispenser.Kill()
				}
				dispenser = Entities.FindByClassname(dispenser, "obj_dispenser")
			}
		}
		if (GetWearableAttribute(player, "no teleporters", 0) != 0)
		{
			local teleporter = Entities.FindByClassname(null, "obj_teleporter")
			while (teleporter != null)
			{
				if (NetProps.GetPropEntity(teleporter, "m_hBuilder") == player)
				{
					teleporter.Kill()
				}
				teleporter = Entities.FindByClassname(teleporter, "obj_teleporter")
			}
			local jumppad = Entities.FindByClassname(null, "obj_jumppad")
			while (jumppad != null)
			{
				if (NetProps.GetPropEntity(jumppad, "m_hBuilder") == player)
				{
					jumppad.Kill()
				}
				jumppad = Entities.FindByClassname(jumppad, "obj_jumppad")
			}
		}
		if (GetWearableAttribute(player, "no metal from dispenser", 0) != 0)
		{
			AddWearerAttribute(player, "no metal from dispensers hidden VSCRIPT", 1)
		}
		else
		{
			RemoveWearerAttribute(player, "no metal from dispensers hidden VSCRIPT")
		}
	}
	function OnGameEvent_player_hurt(params)
	{
		if (damageping)
		{
			local player = GetPlayerFromUserID(params.userid)
			damageping = false
			local damage = params.damageamount
			if (damage <= 0)
			{
				//Why?
				return false
			}
			local armor = player.GetAmmoCount(3)
			local armorprotection = GetWearableAttribute(player, "engie armor", 0)
			local armorratio = GetWearableAttribute(player, "engie armor ratio", 1)
			local damagereduced = floor(min(damage*armorprotection, armor/armorratio))
			local remaining = armor - (damagereduced*armorratio)
			if ((hpbuffer - (damage - damagereduced)) > 0) // If false, we are dead regardless of the armor. RIP. Don't deal the negative damage at all in this senario since it tends to mess up death stuff.
			{
				printl("ran")
				// Deal negative damage so the attacker still gets the right damage number. Hopefully.
				player.TakeDamageEx(inflictorbuffer, params.attacker, null, nullvector, nullvector, -damagereduced - 1, 0) //Deal the negative amount of the damage we want to negate... plus -1. For some reason 1, just, gets added.
				// (hInflictor, hAttacker, hWeapon, vecDamageForce, vecDamagePosition, flDamage, nDamageType)
			
				if (remaining >= ceil(1*armorratio - 1))
				{
					player.SetAmmoCount(3,remaining)
					if (damage > 50) //Arbitrary.
					{
						player.EmitSound("EngieArmor.ImpactHard")
					}
					else
					{
						player.EmitSound("EngieArmor.ImpactSoft")
					}
				}
				else if (damagereduced > 0) //It should never be... but just in case.
				{
					player.SetAmmoCount(3,0)
					player.EmitSound("EngieArmor.Break")
				}
			}
			hpbuffer = 0
		}
	}
}

__CollectGameEventCallbacks(MyEventTable2)

Entities.EnableEntityListening() //Don't know if this is needed but whatever.

function OnTakeDamage()
{
	if (!(self.GetClassname() == "player") && self.IsPlayer())
	{
		return true
	}
	local armorprotection = GetWearableAttribute(self, "engie armor", 0)
	// Don't run this if we don't have armor, It's a damage source we shouldn't be touching (and stomps), or if it's fall damage, drowning damage, train damage, and sawblade damage.
	if (!damageping && armorprotection > 0 && IGNOREDDAMAGE.find(info.GetDamageCustom()) == null && !(info.GetDamageType() & 606256) && self.GetAmmoCount(3) != 0 && info.GetWeapon())
	{
		// This is janky, but after much testing, I've found this to be the best way to get this working.
		// Might still have some bugs. Oh well. Too bad ig. ¯\_(ツ)_/¯
		damageping = true
		hpbuffer = self.GetHealth()
		inflictorbuffer = info.GetInflictor()
		DispatchParticleEffect("arm_detonate_sparks", info.GetDamagePosition(), nullvector, self)
	}
}

function GetWearableAttribute(player, attribname, basenum)
{
	if (basenum != 0)
	{
		local returnvalue = basenum
		for (local i = 0; i < MAXWEAPONS; i++)
		{
			local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (held_weapon == null)
				continue
			returnvalue = held_weapon.GetAttribute(attribname, returnvalue)
		}
		for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
		{
			if (wearable.GetClassname() != "tf_wearable")
				continue
			returnvalue = wearable.GetAttribute(attribname, returnvalue)
		}
		returnvalue = player.GetCustomAttribute(attribname, returnvalue)
		return returnvalue
	}
	else
	{
		local returnvalue = 0
		for (local i = 0; i < MAXWEAPONS; i++)
		{
			local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (held_weapon == null)
				continue
			returnvalue += held_weapon.GetAttribute(attribname, 0)
		}
		for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
		{
			if (wearable.GetClassname() != "tf_wearable")
				continue
			returnvalue += wearable.GetAttribute(attribname, 0)
		}
		returnvalue += player.GetCustomAttribute(attribname, 0)
		return returnvalue
	}
}

function AddWearerAttribute(player, attribname, value)
{
	for (local i = 0; i < MAXWEAPONS8; i++) // Doesn't bother with wearables atm, have no reason to.
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		held_weapon.AddAttribute(attribname, value, 0)
	}
}

function RemoveWearerAttribute(player, attribname)
{
	for (local i = 0; i < MAXWEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		held_weapon.RemoveAttribute(attribname)
	}
	for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
	{
		if (wearable.GetClassname() != "tf_wearable")
			continue
		wearable.RemoveAttribute(attribname)
	}
}