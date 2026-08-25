// This plugin was made without the assitance of AI, all stupidity is entirely on me.

IncludeScript("lib/clocksutils.nut");

armoredplayer <- []

::ArmorEventTable <- {
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		local armor = GetWearableAttribute(player, "armor cap", 0)
		if (armor > 0)
		{
			NetProps.SetPropInt(player, "m_ArmorValue", armor)
			player.SetContextThink("NOMETAL", NOMETAL, 0.1)
			armoredplayer.append(player)
		}
		else if (player in armoredplayer)
		{
			NetProps.SetPropInt(player, "m_ArmorValue", 0)
			local playerindex = armoredplayer.find(player)
			if (playerindex)
			{
				armoredplayer.remove(playerindex)
			}
		}
	}
	function OnGameEvent_ammo_pickup(params)
	{
		// The way replenishing super ammo types is handled.
		if (params.ammo_index != 3)
		{
			return
		}
		foreach(player in armoredplayer)
		{
			if (player.IsValid())
			{
				local cap = GetWearableAttribute(player, "armor cap", 0)
				if (cap > 0)
				{
					local metal = player.GetAmmoCount(3)
					local newarmor = min(NetProps.GetPropInt(player, "m_ArmorValue") + (metal * GetWearableAttribute(player, "armor ratio", 1)),cap)
					NetProps.SetPropInt(player, "m_ArmorValue", newarmor)
					NetProps.SetPropIntArray(player, "m_iAmmo", 0, 3)
				}
				else
				{
					armoredplayer.remove(armoredplayer.find(player))
				}
			}
		}
	}
}

function NOMETAL(self)
{
	NetProps.SetPropIntArray(self, "m_iAmmo", 0, 3)
	self.SetAmmoCount(3, 200)
}

__CollectGameEventCallbacks(ArmorEventTable)