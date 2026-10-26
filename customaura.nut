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
	ammopulse <- array(PLAYERCAP, 0)
}

::AurasTable <- {
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)

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
		local auragroup = GetWearableAttribute(player,"custom aura group", 0).tointeger()
		local aurapriority = GetWearableAttribute(player,"custom aura priority", 0).tointeger()
		local auraammo = GetWearableAttribute(player,"custom aura ammo", 0)
		local auraammotime = GetWearableAttribute(player,"custom aura ammo time", 0)
		if (aurahealtime < 0.5)
		{
			aurahealtime = 0.5
		}
		auras.append([player, auraradius, auracond, ProcessStringAttrib(auraplayerattrib), ProcessStringAttrib(auraweaponattrib), auraheal, aurahealtime, selfeffect, auragroup, aurapriority, auraammo, auraammotime])
	}
}

__CollectGameEventCallbacks(AurasTable)

function CivCheck()
{
	local auraeffects = []
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
				local found = false
				if (aura[8] != 0)
				{
					foreach (effect in auraeffects)
					{
						printl(effect[2][8] & aura[8])
						if (effect[0] == target && effect[2][8] & aura[8] && effect[2][9] <= aura[9])
						{
							local length = (target.EyePosition() - player.EyePosition()).Length()
							printl(effect[2][9] < aura[9])
							if (effect[1] > length || effect[2][9] < aura[9])
							{
								auraeffects.remove(auraeffects.find(effect))
								auraeffects.append([target, length, aura, player])
							}
							found = true
						}
						else if (effect[0] == target && effect[2][8] & aura[8] && effect[2][9] > aura[9])
						{
							found = true
						}
					}
				}
				if (!found)
				{
					auraeffects.append([target, (target.EyePosition() - player.EyePosition()).Length(), aura, player])
				}
			}
		}
	}
	foreach (effect in auraeffects)
	{
		local target = effect[0]
		local aura = effect[2]
		local player = effect[3]
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
		if (aura[5] > 0 && healpulse[target.GetEntityIndex()] <= Time())
		{
			local healamount = aura[5]
			if (Time() - LASTHURT[target.GetEntityIndex()] > 10)
			{
				healamount = healamount * ((min(Time() - LASTHURT[target.GetEntityIndex()] - 10, 5) * (2.0/5.0)) + 1)
			}
			local healed = target.TakeHealth(healamount, 0)
			if (healed > 0)
			{
				SendGlobalGameEvent("player_healed", { patient = target.GetUserID(), healer = player.GetUserID(), amount = healed })
			}
			healpulse[target.GetEntityIndex()] = Time() + aura[6]
		}
		if (aura[10] > 0 && ammopulse[target.GetEntityIndex()] <= Time())
		{
			target.GiveAllAmmoPercent(aura[10])
			ammopulse[target.GetEntityIndex()] = Time() + aura[11]
		}
	}
}

UniqueRepeatingFunctionInTime(CivCheck, 0.5)

IncludeScript("lib/mapbasehookcollector.nut")