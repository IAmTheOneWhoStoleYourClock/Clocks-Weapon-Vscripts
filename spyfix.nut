// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

IncludeScript("lib/clocksutils.nut")

::SpyFixEventTable <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ConnectOutput("OnUser2" "MeleeSwingSpyFix")
	}
}

__CollectGameEventCallbacks(SpyFixEventTable)

function MeleeSwingSpyFix()
{
	if (!self.GetActiveWeapon() || !(self.GetActiveWeapon().GetAttribute("keep disguise on attack", 0)))
	{
		self.RemoveCond(3)
	}
}