// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// Deathmatch medkit behaviour, use it 4 times to gain 4 health. Once it's out of ammo, it's done!
//

IncludeScript("lib/clocksutils.nut");

::TaserStuffEventTable <- {
	function OnGameEvent_weapon_equipped(params)
	{
		local weapon = EntIndexToHScript(params.entindex)
		if (weapon.GetClassname() == "tf2c_weapon_taser")
		{
			weapon.AddContext("rechargestarttime", Time().tostring(), 0)
		}
	}
	function OnGameEvent_player_hurt(params)
	{
		if("userid" in params && "priority" in params && params.priority == 5 && params.attacker == params.userid) //For some reason it's exclusively like this for this specific attribute.
		{
			local healer = GetPlayerFromUserID(params.attacker)
			local weapon = healer.GetActiveWeapon()
			healer.SetHealth(params.health + params.damageamount - (params.damageamount * weapon.GetAttribute("add give health to teammate on hit self scale", 1)))
		}
	}
	function OnGameEvent_player_healed(params)
	{
		if(!("priority" in params))
		{
			local healer = GetPlayerFromUserID(params.healer)
			local healed = GetPlayerFromUserID(params.patient)
			if (!healer || !healer.IsPlayer() || !healed || !healed.IsPlayer())
			{
				return
			}
			local weapon = healer.GetActiveWeapon()
			weapon.AddContext("rechargestarttime", Time().tostring(), 0)
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
		local UBPOW = GetWearableAttribute(player, "ubercharge rate penalty on wearer", 1)
		AddWearerAttribute(player, "ubercharge rate penalty VSCRIPT", UBPOW)
	}
}

__CollectGameEventCallbacks(TaserStuffEventTable)

function OnTakeDamage()
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
		local chargetime = NetProps.GetPropFloat(weapon,"m_flEffectBarRegenTime")
		local chargestarttime = weapon.GetContext("rechargestarttime").tofloat()
		if (Time() < chargetime)
		{
			self.AddCondEx(cond, condtime * (Time() - chargestarttime.tofloat()) / (chargetime - chargestarttime.tofloat()), info.GetAttacker())
		}
		else
		{
			self.AddCondEx(cond, condtime, info.GetAttacker())
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
	weapon.AddContext("rechargestarttime", Time().tostring(), 0)
}