// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

// NOTE: THIS PLUGIN IS INTENDED TO BE USED WITH TASER ATTRIBUTE SELF SPLICING
// if you have no idea what that means, @theclockstealer in #modding-discussion in the TF2C discord server, because it's complicated!

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
		if("userid" in params && "priority" in params && params.priority == 5 && params.attacker == params.userid)
		{
			local healer = GetPlayerFromUserID(params.attacker)
			local weapon = healer.GetActiveWeapon()
			healer.SetHealth(params.health + params.damageamount - (params.damageamount * weapon.GetAttribute("add give health to teammate on hit self scale", 1)))
		}
	}
	function OnGameEvent_vip_boost(params)
	{
		// A fix for add civ boost to self and some additions
		// Yes, I know this should be a different plugin but idc
		local player = GetPlayerFromUserID(params.provider)
		local buffed = GetPlayerFromUserID(params.target)
		local weapon = player.GetActiveWeapon()

		local selfcond = weapon.GetAttribute("add civ boost to self fix", 0)
		if (selfcond)
		{
			player.AddCondEx(selfcond, weapon.GetAttribute("add civ boost to self fix time", 0), player)
		}

		local extracond = weapon.GetAttribute("civ boost extra cond", 0)
		if (extracond)
		{
			buffed.AddCondEx(selfcond, weapon.GetAttribute("civ boost extra cond time", 0), player)
		}
	}
	function OnGameEvent_player_healed(params)
	{
		// This check should only be true if this is a taser.
		if(!("priority" in params) && ("healer" in params) && ("patient" in params))
		{
			local healer = GetPlayerFromUserID(params.healer)
			local healed = GetPlayerFromUserID(params.patient)
			if (!healer || !healer.IsPlayer() || !healed || !healed.IsPlayer())
			{
				return
			}
			local weapon = healer.GetActiveWeapon()
			// For the enemy attributes
			weapon.AddContext("rechargestarttime", Time().tostring(), 0)
			// Cap the amount of healing this can do, since normally taser healing is completely uncapped.
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
		}
	}
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		// Get the wearable attribute
		local UBPOW = GetWearableAttribute(player, "ubercharge rate penalty on wearer", 1)
		// Apply the wearable attribute
		AddWearerAttribute(player, "ubercharge rate penalty VSCRIPT", UBPOW)
	}
}

__CollectGameEventCallbacks(TaserStuffEventTable)

function OnTakeDamage(self,info)
{
	if (!(self.GetClassname() == "player") || !self.IsPlayer() || !info.GetWeapon() || !(info.GetDamageType() & 134217728))
	{
		return true
	}
	local weapon = info.GetWeapon()
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
	// Reset charge start time
	weapon.AddContext("rechargestarttime", Time().tostring(), 0)
}

IncludeScript("lib/mapbasehookcollector.nut")