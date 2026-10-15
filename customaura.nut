// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// Condition 78 is PERMENANTLY occupied by this. DO NOT USE IT ON ANY CW!!!!!
//

IncludeScript("lib/clocksutils.nut");

if (!("auras" in getroottable())) {
	auras <- []
	healpulse <- array(PLAYERCAP, 0)
}

::AurasTable <- {
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		local scriptscope = player.GetOrCreatePrivateScriptScope()

		foreach (aura in auras)
		{
			if (player == aura[0])
			{
				auras.remove(auras.find(aura))
			}
		}

		local auraradius = GetWearableAttribute(player,"custom aura", 0)
		if (auraradius <= 0)
		{
			return
		}
		local auracond = GetWearableAttribute(player,"custom aura cond", 0)
		local auraplayerattrib = GetWearableAttributeString(player,"custom aura player attrib", "")
		local auraweaponattrib = GetWearableAttributeString(player,"custom aura weapon attrib", "")
		local auraheal = GetWearableAttribute(player,"custom aura heal", 0)
		local aurahealtime = GetWearableAttribute(player,"custom aura heal time", 0)
		local selfeffect = GetWearableAttribute(player,"custom aura affect self", 0)
		if (aurahealtime < 0.5)
		{
			aurahealtime = 0.5
		}
		auras.append([player, auraradius, auracond, ProcessStringAttrib(auraplayerattrib), ProcessStringAttrib(auraweaponattrib), auraheal, aurahealtime, selfeffect])
	}
}

__CollectGameEventCallbacks(AurasTable)

function CivCheck()
{
	foreach (aura in auras)
	{
		local player = aura[0]
		if (!player || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
		{
			aura.remove(aura.find(aura))
			continue
		}
		local targets = Entities.GetAllClassnameInRadius("player", player.GetOrigin(), aura[1])
		foreach (target in targets)
		{
			if ((target != player && target.GetTeam() == player.GetTeam() && TraceLine(target.EyePosition(), player.EyePosition(), player) == 1) || (aura[7] && target == player))
			{
				if (aura[2] > 0)
				{
					target.AddCondEx(aura[2], 0.55, player)
				}
				if (aura[3][0] != "")
				{
					target.AddCustomAttribute(aura[3][0], aura[3][1], 0.55)
				}
				if (aura[4][0] != "")
				{
					AddTimedWearerAttribute(target, aura[4][0], aura[4][1], 0.55)
				}
				if (aura[5] > 0 && healpulse[player.GetEntityIndex()] <= Time())
				{
					local healamount = aura[5]
					if (Time() - LASTHURT[target.GetEntityIndex()] > 10)
					{
						healamount = healamount * ((min(Time() - LASTHURT[target.GetEntityIndex()] - 10, 5) * (2.0/5.0)) + 1)
					}
					local healed = target.TakeHealth(healamount, 0)
					SendGlobalGameEvent("player_healed", { patient = target.GetUserID(), healer = player.GetUserID(), amount = healed })
				}
			}
		}
		if (healpulse[player.GetEntityIndex()] <= Time())
		{
			healpulse[player.GetEntityIndex()] = Time() + aura[6]
		}
	}
}

UniqueRepeatingFunctionInTime(CivCheck, 0.5)

IncludeScript("lib/mapbasehookcollector.nut")