// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

IncludeScript("lib/clocksutils.nut");

::CivBoostGiestEventTable <- {
	function OnGameEvent_vip_boost(params)
	{
		// A fix for add civ boost to self and some additions
		local player = GetPlayerFromUserID(params.provider)
		local buffed = GetPlayerFromUserID(params.target)
		local weapon = player.GetActiveWeapon()

		local selfcond = weapon.GetAttribute("add civ boost to self fix", 0)
		if (selfcond)
		{
			player.AddCondEx(selfcond, weapon.GetAttribute("add civ boost to self fix time", 0), player)
		}

		local extracond = ProcessStringAttrib(weapon.GetAttributeString("civ boost extra cond", ""))
		if (extracond[0] != "")
		{
			buffed.AddCondEx(extracond[0], extracond[1], player)
		}

		local auraplayerattrib = ProcessStringAttrib(weapon.GetAttributeString("civ boost player attrib", ""))
		if (auraplayerattrib[0] != "")
		{
			buffed.AddCustomAttribute(auraplayerattrib[0], auraplayerattrib[1], auraplayerattrib[2])
		}

		local auraweaponattrib = ProcessStringAttrib(weapon.GetAttributeString("civ boost weapon attrib", ""))
		if (auraweaponattrib[0] != "")
		{
			AddTimedWearerAttribute(buffed, auraweaponattrib[0], auraweaponattrib[1], auraweaponattrib[2])
		}

		local heal = weapon.GetAttribute("civ boost heal", 0)
		if (heal > 0)
		{
			if (Time() - LASTHURT[buffed.GetEntityIndex()] > 10)
			{
				heal = heal * ((min(Time() - LASTHURT[buffed.GetEntityIndex()] - 10, 5) * (2.0/5.0)) + 1)
			}
			local healed = buffed.TakeHealth(heal, 0)
			if (healed > 0)
			{
				SendGlobalGameEvent("player_healed", { patient = buffed.GetUserID(), healer = player.GetUserID(), amount = healed })
			}
		}

		local ammo = weapon.GetAttribute("civ boost ammo", 0)
		if (ammo > 0)
		{
			buffed.GiveAllAmmoPercent(ammo)
		}
	}
}

__CollectGameEventCallbacks(CivBoostGiestEventTable)

IncludeScript("lib/mapbasehookcollector.nut")