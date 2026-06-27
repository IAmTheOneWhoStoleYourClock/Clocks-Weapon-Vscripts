// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

::WeaponGroupEventTable <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ValidateScriptScope()
	}
}

__CollectGameEventCallbacks(WeaponGroupEventTable)

function OnTakeDamage()
{
	if (!self.IsPlayer() || info.GetAttacker() == self)
	{
		return
	}
	local attackedweapon = self.GetActiveWeapon()
	if (!attackedweapon)
	{
		return
	}
	local group = attackedweapon.GetAttribute("weapon group", 0).tointeger()
	if (group)
	{
		local attackerweapon = info.GetWeapon()
		if (group & attackerweapon.GetAttribute("weapon group crit", 0).tointeger())
		{
			info.SetDamageType(info.GetDamageType() | Constants.FDmgType.DMG_ACID)
		}
		if (group & attackerweapon.GetAttribute("weapon group damage", 0).tointeger())
		{
			info.SetDamage(info.GetDamage() * attackerweapon.GetAttribute("weapon group damage mult", 1))
		}
		if (group & attackerweapon.GetAttribute("weapon group kill", 0).tointeger())
		{
			info.SetDamage((self.GetHealth() * 3) + 1000)
			info.SetDamageCustom(91)
		}
	}
}
