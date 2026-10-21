// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

IncludeScript("lib/clocksutils.nut")

function OnTakeDamage(self,info)
{
	local player = info.GetAttacker()
	if (!player || !player.IsPlayer() || !self || !self.IsPlayer() || player == self)
	{
		return
	}
	local weapon = info.GetWeapon()
	if (!weapon || !weapon.IsWeapon())
	{
		return
	}

	if (!(info.GetDamageType() & 8))
	{
		local healvsburning = weapon.GetAttribute("heal on hit vs burning", 0)
		if (healvsburning > 0 && self.InCond(22))
		{
			local healed = player.TakeHealth(healvsburning, 0)
			if (healed > 0)
			{
				local userid = player.GetUserID()
				SendGlobalGameEvent("player_healed", { patient = userid, healer = userid, amount = healed })
				SendGlobalGameEvent("player_healonhit", { weapon_def_index = GetWeaponDefIndex(weapon), entindex = player.GetEntityIndex(), amount = healed })
			}
		}
		return
	}

	local weaponclass = weapon.GetClassname()
	local healonburn = weapon.GetAttribute("heal on afterburn", 0)
	if (healonburn > 0)
	{
		local healed = player.TakeHealth(healonburn, 0)
		if (healed > 0)
		{
			local userid = player.GetUserID()
			SendGlobalGameEvent("player_healed", { patient = userid, healer = userid, amount = healed })
			SendGlobalGameEvent("player_healonhit", { weapon_def_index = GetWeaponDefIndex(weapon), entindex = player.GetEntityIndex(), amount = healed })
		}
	}
	local healonburnwearer = GetWearableAttribute(player, "heal on afterburn wearer", 0)
	if (healonburnwearer > 0)
	{
		local healed = player.TakeHealth(healonburnwearer, 0)
		if (healed > 0)
		{
			local userid = player.GetUserID()
			SendGlobalGameEvent("player_healed", { patient = userid, healer = userid, amount = healed })
			SendGlobalGameEvent("player_healonhit", { weapon_def_index = GetWeaponDefIndex(weapon), entindex = player.GetEntityIndex(), amount = healed })
		}
	}
	local activeweapon = player.GetActiveWeapon()
	if (activeweapon)
	{
		local healburnactive = activeweapon.GetAttribute("flat heal on afterburn on active", 0)
		if (healburnactive > 0 && activeweapon.GetClassname() != "tf2c_weapon_scythe")
		{
			local healed = player.TakeHealth(healburnactive, 0)
			if (healed > 0)
			{
				local userid = player.GetUserID()
				SendGlobalGameEvent("player_healed", { patient = userid, healer = userid, amount = healed })
				SendGlobalGameEvent("player_healonhit", { weapon_def_index = GetWeaponDefIndex(activeweapon), entindex = player.GetEntityIndex(), amount = healed })
			}
		}
	}
}

IncludeScript("lib/mapbasehookcollector.nut")