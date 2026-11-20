// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

Convars.RegisterConvar("cvs_noboost_default", "0", "Should the umbrella not start with boost by default?", 0)

IncludeScript("lib/clocksutils.nut");

::CivBoostGiestEventTable <- {
	function OnGameEvent_weapon_equipped(params)
	{
		if (params.rawget("class") != "tf2c_weapon_umbrella")
		{
			return
		}
		local weapon = EntIndexToHScript(params.entindex)
		local owner = EntIndexToHScript(params.owner_entindex)
		if (Convars.GetBool("cvs_noboost_default") || weapon.GetAttribute("boost starts uncharged", 0))
		{
			local delay = Convars.GetFloat("tf2c_vip_boost_cooldown") * weapon.GetAttribute("umbrella recharge rate increased", 1) * weapon.GetAttribute("umbrella recharge rate decreased", 1) * weapon.GetAttribute("umbrella recharge rate VSCRIPT", 1)
			FunctionInTime(SetDelay, 0, [weapon, delay])
		}
	}
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		local umbrella = GetWeaponByClass(player, "tf2c_weapon_umbrella")
		if (!umbrella || !umbrella.IsValid())
		{
			return
		}
		umbrella.AddAttribute("umbrella recharge rate VSCRIPT", GetWearableAttribute(player, "umbrella recharge rate wearer", 1), 0)
	}
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

		local selfplayerattrib = ProcessStringAttrib(weapon.GetAttributeString("add civ boost to self player attrib", ""))
		if (selfplayerattrib[0] != "")
		{
			player.AddCustomAttribute(selfplayerattrib[0], selfplayerattrib[1], selfplayerattrib[2])
		}

		local selfweaponattrib = ProcessStringAttrib(weapon.GetAttributeString("add civ boost to self weapon attrib", ""))
		if (selfweaponattrib[0] != "")
		{
			AddTimedWearerAttribute(player, selfweaponattrib[0], selfweaponattrib[1], selfweaponattrib[2])
		}

		local weaponattrib = ProcessStringAttrib(weapon.GetAttributeString("civ boost umbrella attrib", ""))
		if (weaponattrib[0] != "")
		{
			AddTimedAttribute(weapon, weaponattrib[0], weaponattrib[1], weaponattrib[2])
		}

		local extracond = ProcessStringAttrib(weapon.GetAttributeString("civ boost extra cond", ""))
		if (extracond[0] != "")
		{
			buffed.AddCondEx(extracond[0], extracond[1], player)
		}

		local playerattrib = ProcessStringAttrib(weapon.GetAttributeString("civ boost player attrib", ""))
		if (playerattrib[0] != "")
		{
			buffed.AddCustomAttribute(playerattrib[0], playerattrib[1], playerattrib[2])
		}

		local weaponattrib = ProcessStringAttrib(weapon.GetAttributeString("civ boost weapon attrib", ""))
		if (weaponattrib[0] != "")
		{
			AddTimedWearerAttribute(buffed, weaponattrib[0], weaponattrib[1], weaponattrib[2])
		}

		local heal = weapon.GetAttribute("civ boost heal", 0)
		if (heal > 0)
		{
			if (Time() - LASTHURT[buffed.GetEntityIndex()] > 10)
			{
				heal = heal * ((min(Time() - LASTHURT[buffed.GetEntityIndex()] - 10, 5) * (2.0/5.0)) + 1)
			}
			local overhealpercentage = weapon.GetAttribute("civ boost heal overheal", 1)
			if (overhealpercentage != 1)
			{
				overhealpercentage = 1 + ((overhealpercentage - 1) * GetWearableAttribute(buffed, "patient overheal penalty", 1) * GetWearableAttribute(buffed, "patient overheal bonus", 1))
				buffed.AddCustomAttribute("max health percent VSCRIPT", overhealpercentage, 0.015)
			}
			local healed = buffed.TakeHealth(heal, 0)
			if (healed > 0)
			{
				SendGlobalGameEvent("player_healed", { patient = buffed.GetUserID(), healer = player.GetUserID(), amount = healed })
			}
			if (overhealpercentage != 1)
			{
				buffed.RemoveCustomAttribute("max health percent VSCRIPT")
			}
		}
		else if (heal < 0)
		{
			buffed.TakeDamageEx(weapon, player, weapon, NULLVECTOR, player.GetOrigin(), -heal, 2048)
		}

		local ammo = weapon.GetAttribute("civ boost ammo", 0)
		if (ammo > 0)
		{
			buffed.GiveAllAmmoPercent(ammo)
		}
	}
	function OnGameEvent_player_hurt(params)
	{
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
		local umbrella = GetWeaponByClass(player, "tf2c_weapon_umbrella")
		if (!umbrella)
		{
			return
		}

		local boostamount = weapon.GetAttribute("umbrella boost on hit add", 0) + (params.damageamount * weapon.GetAttribute("umbrella boost on hit percent", 0) * GetWearableAttribute(player, "umbrella boost on hit percent wearer", 0))
		if (boostamount)
		{
			DelayMod(umbrella, -boostamount)
		}
	}
}

function SetDelay(weapon, delay)
{
	NetProps.SetPropFloat(weapon,"m_flNextBoostAttack", Time() + delay)
}

function DelayMod(weapon, delay)
{
	NetProps.SetPropFloat(weapon,"m_flNextBoostAttack", NetProps.GetPropFloat(weapon,"m_flNextBoostAttack") + delay)
}


__CollectGameEventCallbacks(CivBoostGiestEventTable)

IncludeScript("lib/mapbasehookcollector.nut")