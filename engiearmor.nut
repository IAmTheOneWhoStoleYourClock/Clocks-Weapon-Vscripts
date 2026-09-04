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

PrecacheModel("models/weapons/c_models/c_engineer_arms_iron_fist.mdl") //Grand design arm model. I'm just going to pull a Volvo and manually hard code this.

IncludeScript("lib/clocksutils.nut")

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
		local player = GetPlayerFromUserID(params.userid)
		if (player.GetContext("damageping") == "yes")
		{
			player.AddContext("damageping", "no", 0.1)
			local damage = params.damageamount
			if (damage <= 0)
			{
				//Why?
				return false
			}
			local scriptscope = player.GetOrCreatePrivateScriptScope()
			local armor = player.GetAmmoCount(3)
			local armorprotection = GetWearableAttribute(player, "engie armor", 0)
			local armorratio = GetWearableAttribute(player, "engie armor ratio", 1)
			local damagereduced = floor(min(damage*armorprotection, armor/armorratio))
			local remaining = armor - (damagereduced*armorratio)
			if ((scriptscope.hpbuffer - (damage - damagereduced)) > 0) // If false, we are dead regardless of the armor. RIP.
			{
				// Deal negative damage so the attacker still gets the right damage number. Hopefully.
				player.TakeDamageEx(scriptscope.inflictorbuffer, params.attacker, null, NULLVECTOR, player.GetOrigin() + Vector(0,0,16), -damagereduced - 1, 0) //Deal the negative amount of the damage we want to negate... plus -1. For some reason 1, just, gets added.
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
			else // In that case, do this to prevent death weirdness.
			{
				player.SetHealth(100)
				NetProps.SetPropInt(player, "m_lifeState", 0)
				player.TakeDamageCustom(scriptscope.inflictorbuffer, params.attacker, null, NULLVECTOR, player.GetOrigin() + Vector(0,0,16), -damagereduced - 1, 0, 27) // Do Rune Reflect Type Damage. Don't question it, this works.
				player.SetHealth(0)
				NetProps.SetPropInt(player, "m_lifeState", 2)
			}
		}
	}
}

__CollectGameEventCallbacks(MyEventTable2)

function OnTakeDamage(self,info)
{
	if (self.GetClassname() == "player")
	{
		local armorprotection = GetWearableAttribute(self, "engie armor", 0)
		// Don't run this if we don't have armor, It's a damage source we shouldn't be touching (and stomps), or if it's fall damage, drowning damage, train damage, and sawblade damage.
		if (!damageping && armorprotection > 0 && IGNOREDDAMAGE.find(info.GetDamageCustom()) == null && !(info.GetDamageType() & 606256) && self.GetAmmoCount(3) != 0 && info.GetInflictor() && (info.GetWeapon() || info.GetInflictor().GetClassname() == "obj_sentrygun"))
		{
			// This is janky, but after much testing, I've found this to be the best way to get this working.
			// Might still have some bugs. Oh well. Too bad ig. ¯\_(ツ)_/¯
			self.AddContext("damageping", "yes", 0.1)
			local scriptscope = self.GetOrCreatePrivateScriptScope()
			scriptscope.hpbuffer <- self.GetHealth()
			scriptscope.inflictorbuffer <- info.GetAttacker()
			DispatchParticleEffect("arm_detonate_sparks", info.GetDamagePosition(), nullvector, self)
		}
	}
	return
}

IncludeScript("lib/mapbasehookcollector.nut")