// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

// NOTE: THIS PLUGIN IS INTENDED TO BE USED WITH TASER ATTRIBUTE SELF SPLICING
// if you have no idea what that means, @theclockstealer in #modding-discussion in the TF2C discord server, because it's complicated!

Convars.RegisterConvar("cvs_notasercharge_default", "0", "Should the taser not start with boost by default?", 0)

IncludeScript("lib/clocksutils.nut");

::TaserStuffEventTable <- {
	function OnGameEvent_weapon_equipped(params)
	{
		local weapon = EntIndexToHScript(params.entindex)
		if (weapon.GetClassname() == "tf2c_weapon_taser")
		{
			// For the enemy attributes
			weapon.AddContext("rechargestarttime", Time().tostring(), 0)
		}
	}
	function OnGameEvent_player_hurt(params)
	{
		// add give health to teammate on hit stuff. I know that's not technically taser stuff but where else would it go.
		// For some reason it's exclusively like this for this specific attribute.
		if("userid" in params && "priority" in params && "bonuseffect" in params && "weaponid" in params && params.priority == 5 && params.attacker == params.userid && false)
		{
			local healer = GetPlayerFromUserID(params.attacker)
			local weapon = healer.GetActiveWeapon()
			healer.SetHealth(params.health + params.damageamount - (params.damageamount * weapon.GetAttribute("add give health to teammate on hit self scale", 1)))
		}
		
		// shamelessly copypasted from civboostgeist
		local player = GetPlayerFromUserID(params.attacker)
		local self = GetPlayerFromUserID(params.userid)
		if (!player || !player.IsPlayer() || !self || !self.IsPlayer() || !("weaponid" in params))
		{
			return
		}
		local weapon = GetWeaponByClassID(player, params.weaponid)
		if (!weapon)
		{
			return
		}
		local taser = GetWeaponByClass(player, "tf2c_weapon_taser")
		if (!taser)
		{
			return
		}

		local boostamount = weapon.GetAttribute("taser charge on hit add", 0) + (params.damageamount * weapon.GetAttribute("taser charge on hit percent", 0) * GetWearableAttribute(player, "taser charge on hit percent wearer", 0))
		if (boostamount)
		{
			AddTaserTime(taser, -boostamount)
		}
	}
	function OnGameEvent_player_healed(params)
	{
		// This check should only be true if this is a taser.
		if(!("priority" in params) && ("healer" in params) && ("patient" in params) && params.healer != params.patient)
		{
			local healer = GetPlayerFromUserID(params.healer)
			local healed = GetPlayerFromUserID(params.patient)
			if (!healer || !healer.IsPlayer() || !healed || !healed.IsPlayer())
			{
				return
			}
			local weapon = healer.GetActiveWeapon()
			// For the enemy attributes
			if (!weapon || weapon.GetClassname() != "tf2c_weapon_taser")
			{
				return false
			}
			weapon.AddContext("rechargestarttime", Time().tostring(), 0)
			// Cap the amount of healing this can do, since normally taser healing is completely uncapped.
			local selfcond = ProcessStringAttrib(weapon.GetAttributeString("taser cond to self", ""))
			if (selfcond[0] != "")
			{
				healer.AddCondEx(selfcond[0], selfcond[1], player)
			}

			local selfplayerattrib = ProcessStringAttrib(weapon.GetAttributeString("taser player attrib to self", ""))
			if (selfplayerattrib[0] != "")
			{
				healer.AddCustomAttribute(selfplayerattrib[0], selfplayerattrib[1], selfplayerattrib[2])
			}

			local selfweaponattrib = ProcessStringAttrib(weapon.GetAttributeString("taser weapon attrib to self", ""))
			if (selfweaponattrib[0] != "")
			{
				AddTimedWearerAttribute(healer, selfweaponattrib[0], selfweaponattrib[1], selfweaponattrib[2])
			}

			local weaponattrib = ProcessStringAttrib(weapon.GetAttributeString("taser weapon attrib to taser", ""))
			if (weaponattrib[0] != "")
			{
				AddTimedAttribute(weapon, weaponattrib[0], weaponattrib[1], weaponattrib[2])
			}

			local cap = weapon.GetAttribute("taser cap", 0)
			if (cap)
			{
				local healed = GetPlayerFromUserID(params.patient)
				local maxallowed = healed.GetMaxHealth() + min(healed.GetMaxHealth() * GetWearableAttribute(healed, "patient overheal penalty", 1) * (cap-1), healed.GetMaxHealth() * (cap-1))
				local currenthealth = healed.GetHealth()
				if (currenthealth > maxallowed)
				{
					healed.SetHealth(max(maxallowed, currenthealth - params.amount))
				}
			}
			// Apply a condition if desired
			local cond = weapon.GetAttribute("taser cond", 0)
			if (cond)
			{
				healed.AddCondEx(cond, weapon.GetAttribute("taser cond duration", 0), healer)
			}

			local playerattrib = ProcessStringAttrib(weapon.GetAttributeString("taser ally player attrib", ""))
			if (playerattrib[0] != "")
			{
				buffed.AddCustomAttribute(playerattrib[0], playerattrib[1], playerattrib[2])
			}

			local weaponattrib = ProcessStringAttrib(weapon.GetAttributeString("taser ally weapon attrib", ""))
			if (weaponattrib[0] != "")
			{
				AddTimedWearerAttribute(buffed, weaponattrib[0], weaponattrib[1], weaponattrib[2])
			}
		}
	}
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		// Get the wearable attribute
		local UBPOW = GetWearableAttribute(player, "ubercharge rate penalty on wearer", 1)
		// Apply the wearable attribute
		AddWearerAttribute(player, "ubercharge rate penalty VSCRIPT", UBPOW)

		local taser = GetWeaponByClass(player, "tf2c_weapon_taser")
		if (taser)
		{
			taser.AddAttribute("effect bar recharge rate VSCRIPT", GetWearableAttribute(player, "taser recharge rate wearer", 1), 0)
			local nocharge = taser.GetAttribute("taser starts uncharged", 0)
			if (nocharge || Convars.GetBool("cvs_notasercharge_default"))
			{
				local chargetime = 30 * taser.GetAttribute("effect bar recharge rate VSCRIPT", 1) * taser.GetAttribute("effect bar recharge rate increased", 1) * taser.GetAttribute("effect bar recharge rate decreased", 1)
				local expendedtime = Time() - taser.GetContext("rechargestarttime").tofloat()
				if (chargetime > expendedtime)
				{
					NetProps.SetPropIntArray(taser, "m_iAmmo", 0, taser.GetPrimaryAmmoType())
					FunctionInTime(SetTaserTime, 0, [player, taser, chargetime - expendedtime + Time()])
				}
			}
		}
	}
}

function SetTaserTime(player, taser, amount)
{
	if (amount > Time())
	{
		NetProps.SetPropIntArray(player, "m_iAmmo", 0, taser.GetPrimaryAmmoType())
	}
	else
	{
		NetProps.SetPropIntArray(player, "m_iAmmo", 1, taser.GetPrimaryAmmoType())
	}
	NetProps.SetPropFloat(taser,"m_flEffectBarRegenTime", amount)
}

function AddTaserTime(taser, amount)
{
	NetProps.SetPropFloat(weapon,"m_flEffectBarRegenTime", NetProps.GetPropFloat(weapon,"m_flEffectBarRegenTime") + amount)
}

__CollectGameEventCallbacks(TaserStuffEventTable)

function OnTakeDamage(self,info)
{
	if (!(self.GetClassname() == "player") || !self.IsPlayer() || !info.GetAttacker() || !info.GetWeapon() || info.GetWeapon().GetClassname() != "tf2c_weapon_taser" || !(info.GetDamageType() & 134217728)) // Why do I even need that last condition?
	{
		return true
	}
	local weapon = info.GetWeapon()
	local nochargedecay = weapon.GetAttribute("taser enemy no charge decay", 0)
	if (nochargedecay)
	{
		local chargetime = 30 * weapon.GetAttribute("effect bar recharge rate VSCRIPT", 1) * weapon.GetAttribute("effect bar recharge rate increased", 1) * weapon.GetAttribute("effect bar recharge rate decreased", 1)
		local expendedtime = Time() - weapon.GetContext("rechargestarttime").tofloat()
		FunctionInTime(SetTaserTime, 0, [info.GetAttacker(), weapon, chargetime - expendedtime + Time()])
	}
	local cond = weapon.GetAttribute("taser cond apply", 0)
	if (cond)
	{
		local condtime = weapon.GetAttribute("taser cond apply duration", 0)
		// Get the time the weapon will recharge at.
		local chargetime = NetProps.GetPropFloat(weapon,"m_flEffectBarRegenTime")
		local chargestarttime = weapon.GetContext("rechargestarttime").tofloat()

		// The amount of time it'll take to charge / the amount of time it's charged.
		local effectpercent = (Time() - chargestarttime.tofloat()) / (chargetime - chargestarttime.tofloat())

		if (Time() >= chargetime)
		{
			self.AddCondEx(cond, condtime, info.GetAttacker())
		}
		// Only apply the effect if it's more than 25% recharged. (Having it for a fraction of a second would be dumb.)
		// TO DO: Add more options for scaling.
		else if (effectpercent > 0.25)
		{
			self.AddCondEx(cond, condtime * effectpercent, info.GetAttacker())
		}
	}
	local condfullonly = weapon.GetAttribute("taser cond apply full only", 0)
	if (cond)
	{
		local condtime = weapon.GetAttribute("taser cond apply full only duration", 0)
		// Could also check if it has ammo, but this works fine.
		local chargetime = NetProps.GetPropFloat(weapon,"m_flEffectBarRegenTime")
		if (Time() > chargetime)
		{
			self.AddCondEx(cond, condtime, info.GetAttacker())
		}
	}

	local attribute = ProcessStringAttrib(weapon.GetAttributeString("taser enemy player attrib", ""))
	if (attribute[0] != "")
	{
		local condtime = weapon.GetAttribute("taser cond apply duration", 0)
		// Get the time the weapon will recharge at.
		local chargetime = NetProps.GetPropFloat(weapon,"m_flEffectBarRegenTime")
		local chargestarttime = weapon.GetContext("rechargestarttime").tofloat()

		// The amount of time it'll take to charge / the amount of time it's charged.
		local effectpercent = (Time() - chargestarttime.tofloat()) / (chargetime - chargestarttime.tofloat())

		if (Time() >= chargetime)
		{
			self.AddCondEx(cond, condtime, info.GetAttacker())
		}
		// Only apply the effect if it's more than 25% recharged. (Having it for a fraction of a second would be dumb.)
		// TO DO: Add more options for scaling.
		else if (effectpercent > 0.25)
		{
			player.AddCustomAttribute(attribute[0], attribute[1], attribute[2])
		}
	}
	local attributefullonly = ProcessStringAttrib(weapon.GetAttributeString("taser enemy weapon attrib", ""))
	if (attributefullonly[0] != "")
	{
		// Could also check if it has ammo, but this works fine.
		local chargetime = NetProps.GetPropFloat(weapon,"m_flEffectBarRegenTime")
		if (Time() > chargetime)
		{
			player.AddCustomAttribute(attributefullonly[0], attributefullonly[1], attributefullonly[2])
		}
	}

	local attributeweapon = ProcessStringAttrib(weapon.GetAttributeString("taser enemy player attrib", ""))
	if (attributeweapon[0] != "")
	{
		local condtime = weapon.GetAttribute("taser cond apply duration", 0)
		// Get the time the weapon will recharge at.
		local chargetime = NetProps.GetPropFloat(weapon,"m_flEffectBarRegenTime")
		local chargestarttime = weapon.GetContext("rechargestarttime").tofloat()

		// The amount of time it'll take to charge / the amount of time it's charged.
		local effectpercent = (Time() - chargestarttime.tofloat()) / (chargetime - chargestarttime.tofloat())

		if (Time() >= chargetime)
		{
			self.AddCondEx(cond, condtime, info.GetAttacker())
		}
		// Only apply the effect if it's more than 25% recharged. (Having it for a fraction of a second would be dumb.)
		// TO DO: Add more options for scaling.
		else if (effectpercent > 0.25)
		{
			AddTimedWearerAttribute(player, attribute[0], attribute[1], attribute[2] * effectpercent)
		}
	}
	local attributeweaponfullonly = ProcessStringAttrib(weapon.GetAttributeString("taser enemy weapon attrib", ""))
	if (attributeweaponfullonly[0] != "")
	{
		// Could also check if it has ammo, but this works fine.
		local chargetime = NetProps.GetPropFloat(weapon,"m_flEffectBarRegenTime")
		if (Time() > chargetime)
		{
			AddTimedWearerAttribute(player, attributeweaponfullonly[0], attributeweaponfullonly[1], attributeweaponfullonly[2])
		}
	}
	// Reset charge start time
	if (!nochargedecay)
	{
		weapon.AddContext("rechargestarttime", Time().tostring(), 0)
	}
}

IncludeScript("lib/mapbasehookcollector.nut")