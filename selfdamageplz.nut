// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

IncludeScript("lib/clocksutils.nut")

::SelfDamagePlzEventTable <- {
	function OnGameEvent_player_hurt(params)
	{
		local player = GetPlayerFromUserID(params.attacker)
		local self = GetPlayerFromUserID(params.userid)
		if (!player || !player.IsPlayer() || !self || !self.IsPlayer() || player == self || params.custom == 34 || params.custom == 3 || !("weaponid" in params))
		{
			return
		}
		local weapon = GetWeaponByClassID(player, params.weaponid)
		if (!weapon)
		{
			return
		}
		local selfdmg = weapon.GetAttribute("selfdmg on hit", 0)
		if (selfdmg < 0)
		{
			player.TakeDamageEx(weapon, player, null, Vector(0,0,0) player.GetOrigin() + Vector(0,0,50), -selfdmg, 2064);
		}
	}
}

__CollectGameEventCallbacks(SelfDamagePlzEventTable)

IncludeScript("lib/mapbasehookcollector.nut")