// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// Linked items still get removed and readded on resupply. Might be able to fix that, but for now I don't care.
// Preventing automatically swapping to new weapons may cause conflicts with other scripts.
//

IncludeScript("lib/clocksutils.nut");

if (!("lockedplayers" in getroottable())) {
	lockedplayers <- array(PLAYERCAP, false)
}

::LinkedItemIdTable <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ConnectOutput("OnUser3" "CurrWeaponTrack")
	}
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		if (lockedplayers[player.GetEntityIndex()] == false)
		{
			lockedplayers[player.GetEntityIndex()] = true
			for (local i = 0; i < 8; i++)
			{
				local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
				if (held_weapon == null)
					continue
				WeaponParseLinked(player,held_weapon)
			}
			local wd = 0
			for (local wearable = player.FirstMoveChild(); wearable != null && wd < 50; wearable = wearable.NextMovePeer())
			{
				wd += 1
				if (!startswith(wearable.GetClassname(),"tf_wearable") || NetProps.GetPropInt(wearable, "m_bDisguiseWearable"))
					continue
				WeaponParseLinked(player,held_weapon)
			}
			lockedplayers[player.GetEntityIndex()] = false
		}
	}
}

__CollectGameEventCallbacks(LinkedItemIdTable)

function WeaponParseLinked(player, weapon)
{
	local enabletactician = GetWearableAttribute(player, "tactician bonus enable", 0)
	local linkedname = weapon.GetAttributeString("linked item name", "")
	local tacticianlinkedname = weapon.GetAttributeString("linked item tactician name", "")

	if (linkedname != "")
	{
		player.GenerateAndWearItem(linkedname)
		return true
	}
	else if (tacticianlinkedname != "" && enabletactician > 0)
	{
		player.GenerateAndWearItem(linkedname)
		return true
	}
	else
	{
		return false
	}
}