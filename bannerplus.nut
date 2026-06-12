// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None.
//

MAXWEAPONS <- 8

::BuffBannerEventTable <- {
	function OnGameEvent_deploy_buff_banner(params)
	{
		local player = GetPlayerFromUserID(params.buff_owner)
		local weapon = player.GetActiveWeapon()
		local bannertime = GetWearableAttribute(player,"increase buff duration", 10)
		local speedup = weapon.GetAttribute("banner speed", 1)
		if (speedup != 1)
		{
			player.AddCustomAttribute("major move speed bonus", speedup, bannertime)
		}
		local condition = weapon.GetAttribute("strange restriction user type 1", 0)
		if (condition != 0)
		{
			player.AddCondEx(condition, bannertime, player)
		}
	}
	function OnGameEvent_player_hurt(params)
	{
		local player = GetPlayerFromUserID(params.attacker)
		if (!player || !player.IsValid() || !player.IsPlayer() || player.IsRageDraining())
		{
			return
		}
		player.AddContext("BannerCurr", player.GetRageMeter().tostring(), 0)
		player.SetContextThink("RageThink", RageThink, 0.0015)
	}
}


function RageThink(player)
{
	if (player.GetRageMeter() == 0)
	{
		return
	}
	local bannerrate =  GetWearableAttribute(player, "banner rate", 1)
	if (bannerrate == 1)
	{
		return
	}
	local hasbanner = false
	for (local i = 0; i < MAXWEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		if (held_weapon.GetClassname() == "tf_weapon_buff_item")
		{
			hasbanner = true
			break
		}
	}
	if (hasbanner)
	{
		local bannercurr = player.GetContext("BannerCurr").tofloat()
		local banneradjust = max(((player.GetRageMeter() - bannercurr) * bannerrate) + bannercurr, 100)
		player.SetRageMeter(banneradjust)
	}
}
__CollectGameEventCallbacks(BuffBannerEventTable)

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