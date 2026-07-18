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
		local weapon = info.GetWeapon()
		local COD = weapon.GetAttribute("cond on damagetype", 0).tointeger()
		if (COD & info.GetDamageType())
		{
			self.AddCondEx(weapon.GetAttribute("cond on damagetype cond", 0),weapon.GetAttribute("cond on damagetype time", 0),info.GetAttacker())
		}
		local SCOD = weapon.GetAttribute("self cond on damagetype", 0).tointeger()
		if (SCOD & info.GetDamageType())
		{
			info.GetAttacker().AddCondEx(weapon.GetAttribute("self cond on damagetype cond", 0),weapon.GetAttribute("self cond on damagetype time", 0),info.GetAttacker())
		}
		local COC = weapon.GetAttribute("cond on customtype", 0).tointeger()
		if (COC & info.GetDamageCustom())
		{
			self.AddCondEx(weapon.GetAttribute("cond on customtype cond", 0),weapon.GetAttribute("cond on customtype time", 0),info.GetAttacker())
		}
		local SCOC = weapon.GetAttribute("self cond on customtype", 0).tointeger()
		if (SCOC & info.GetDamageCustom())
		{
			info.GetAttacker().AddCondEx(weapon.GetAttribute("self cond on customtype cond", 0),weapon.GetAttribute("self cond on customtype time", 0),info.GetAttacker())
		}
		local DTO = weapon.GetAttribute("damagetypeoverride", 0).tointeger()
		if (DTO)
		{
			info.SetDamageType(DTO | (info.GetDamageType() & 1048576)) // Lets it keep a couple of important damage types
		}
		local CTO = weapon.GetAttribute("customtypeoverride", 0).tointeger()
		if (CTO)
		{
			info.SetDamageCustom(CTO | (info.GetDamageCustom() & 1)) // Lets it keep a couple of important damage types
		}
		if (weapon.GetAttribute("no headshot", 0) && info.GetDamageCustom() & 1)
		{
			if (!info.GetAttacker().IsCritBoosted() && info.GetDamageType() & 1048576)
			{
				info.SetDamageType(info.GetDamageType() - 1048576)
			}
			info.SetDamageCustom(info.GetDamageCustom() - 1)
		}
		if (weapon.GetAttribute("no crits", 0) && info.GetDamageType() & 1048576)
		{
			info.SetDamageType(info.GetDamageType() - 1048576)
		}
	}
}

IncludeScript("lib/mapbasehookcollector.nut");