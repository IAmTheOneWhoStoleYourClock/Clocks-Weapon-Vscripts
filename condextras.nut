// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

IncludeScript("lib/clocksutils.nut");

::DamageTypeOverrideEventTable <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ValidateScriptScope()
	}
	function OnGameEvent_player_death(params)
	{
		local player = GetPlayerFromUserID(params.attacker)
		if (!player || !player.IsPlayer() || !("weapon_def_index" in params))
		{
			return
		}
		local weapon = GetWeaponByDefIndex(player, params.weapon_def_index) // litterally just for this
		local extrakillcond = weapon.GetAttribute("add condition on kill extra", 0).tointeger()
		if (extrakillcond)
		{
			GetPlayerFromUserID(params.userid).AddCondEx(extrahitselfcond, weapon.GetAttribute("add condition on kill extra time", 0), player)
		}
	}
	function OnGameEvent_player_hurt(params)
	{
		local player = GetPlayerFromUserID(params.attacker)
		local self = GetPlayerFromUserID(params.userid)
		if (!player || !player.IsPlayer() || !self || !self.IsPlayer() || !("weaponid" in params))
		{
			return
		}
		local weapon = GetWeaponByClassID(player, params.weaponid) // litterally just for this

		local extrahitcondscale = weapon.GetAttribute("add condition on hit weapon scale", 0).tointeger()
		if (extrahitcondscale)
		{
			local min = weapon.GetAttribute("add condition on hit weapon scale time min", 0)
			local max = weapon.GetAttribute("add condition on hit weapon scale time max", 0)
			local scale = clamp((params.damageamount - min)/(max - min),0,1)
			self.AddCondEx(extrahitcondscale, weapon.GetAttribute("add condition on hit weapon scale time", 0)*scale, player)
		}
		local extrahitselfcondscale = weapon.GetAttribute("add condition on hit self weapon scale", 0).tointeger()
		if (extrahitselfcondscale)
		{
			local min = weapon.GetAttribute("add condition on hit self weapon scale time min", 0)
			local max = weapon.GetAttribute("add condition on hit self weapon scale time max", 0)
			local scale = clamp((params.damageamount - min)/(max - min),0,1)
			player.AddCondEx(extrahitselfcondscale, weapon.GetAttribute("add condition on hit self weapon scale time", 0) * scale, player)
		}
	}
}

__CollectGameEventCallbacks(DamageTypeOverrideEventTable)

function OnTakeDamage()
{
	if (!self.IsPlayer() || info.GetAttacker() == self || !info.GetWeapon())
	{
		return
	}
	local weapon = info.GetWeapon()
	local extrahitcond = weapon.GetAttribute("add condition on hit weapon extra", 0).tointeger()
	if (extrahitcond)
	{
		self.AddCondEx(extrahitcond, weapon.GetAttribute("add condition on hit weapon extra time", 0), info.GetAttacker())
	}
	local extrahitselfcond = weapon.GetAttribute("add condition on hit self weapon extra", 0).tointeger()
	if (extrahitselfcond)
	{
		info.GetAttacker().AddCondEx(extrahitselfcond, weapon.GetAttribute("add condition on hit self weapon extra time", 0), info.GetAttacker())
	}
}
