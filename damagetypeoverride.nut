// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

// No comments here, this should all be self explanatory tbh.

IncludeScript("lib/clocksutils.nut")

::DamageTypeOverrideEventTable <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ValidateScriptScope()
	}
}

__CollectGameEventCallbacks(DamageTypeOverrideEventTable)

// NEW CHANGE: MAPBASE HOOKS HAVE TO LIST THEIR PARAMETERS DUE TO THE HOOK COLLECTOR
function OnTakeDamage(self,info)
{
	if (self.IsPlayer() && info.GetAttacker() != self && info.GetWeapon())
	{
		local DTO = info.GetWeapon().GetAttribute("damadetypeoverride", 0).tointeger()
		if (DTO)
		{
			info.SetDamageType(DTO | (info.GetDamageType() & 1048576)) // Lets it keep a couple of important damage types
		}
		local CTO = info.GetWeapon().GetAttribute("customtypeoverride", 0).tointeger()
		if (CTO)
		{
			info.SetDamageCustom(CTO | (info.GetDamageCustom() & 1)) // Lets it keep a couple of important damage types
		}
	}
}

IncludeScript("lib/mapbasehookcollector.nut");