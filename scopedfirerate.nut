// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

IncludeScript("lib/clocksutils.nut");

::ScopedFirerateEventTable <- {
	function OnGameEvent_player_shoot(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		EntFireByHandle(player, "CallScriptFunction", "Scopeshootthink", 0, player, null) // AUGH WHY WILL IT JUST NOT DO THE EFFECT!!!! AUGHHHHHHHHHHHHHHHHHHHHH
	}
}

function Scopeshootthink()
{
	if (self.InCond(1))
	{
		local weapon = self.GetActiveWeapon()
		local fireratemod = weapon.GetAttribute("scoped firerate penalty", 1)
		if (fireratemod != 1 && weapon.GetClassname() == "tf2c_weapon_hunting_revolver")
		{
			local nextattack = NetProps.GetPropFloat(weapon,"m_flNextPrimaryAttack")
			NetProps.SetPropFloat(weapon,"m_flNextPrimaryAttack", Time() + ((nextattack - Time()) * fireratemod))
		}
	}
}

__CollectGameEventCallbacks(ScopedFirerateEventTable)
