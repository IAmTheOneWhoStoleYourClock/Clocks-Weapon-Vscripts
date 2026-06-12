// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None. I mean. How could there even be. Look at it. The code is 18 lines long.
// For those that don't make vscript, just know it isn't usually this simple lol.
//

::BuffBannerEventTable <- {
	function OnGameEvent_deploy_buff_banner(params)
	{
		local player = GetPlayerFromUserID(params.buff_owner)
		local bannertime = player.GetActiveWeapon().GetAttribute("increase buff duration", 10)
		if (player.GetActiveWeapon().GetAttribute("elevate quality", 0) != 0)
		{
			player.AddCustomAttribute("major move speed bonus", 1.15, bannertime)
		}
		local condition = player.GetActiveWeapon().GetAttribute("strange restriction user type 1", 0)
		if (condition != 0)
		{
			player.AddCondEx(condition, bannertime, player)
		}
	}
}

__CollectGameEventCallbacks(BuffBannerEventTable)