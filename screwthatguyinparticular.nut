// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None.
//

// Enter the SteamID3(s) of any user you want to be auotmaically nerfed.
NERFEDSTEAMIDS <- ["U:1:169802"]
// Atribute to add.
nerf <- "dmg taken from bullets increased"
// Value of the attribute
nerfamount <- 1.2
// True if the attribute is weapon locked
// (NOTE: THIS WILL SHOW UP ON THE WEAPON IF IT HAS DISPLAY TEXT!)
weaponlocked <- false
////////////////////////////////////////
IncludeScript("lib/clocksutils.nut");

::ScrewThatGuyTable <- {
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		local ID = NetProps.GetPropString(player, "m_szNetworkIDString")
		if (true)
		{
			if (weaponlocked)
			{
				AddWearerAttribute(player,nerf,nerfamount)
			}
			else
			{
				player.AddCustomAttribute(nerf, nerfamount, 0)
			}
		}
	}
}

__CollectGameEventCallbacks(ScrewThatGuyTable)