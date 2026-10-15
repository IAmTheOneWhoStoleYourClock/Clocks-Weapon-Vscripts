// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None.
//
if (!("ATTRIBSTOBECLEAREDWEARER" in getroottable())) {
	MAXWEAPONS <- 8
	PLAYERCAP <- 100
	ATTRIBSTOBECLEAREDWEARER <- array(PLAYERCAP, [])
	ATTRIBSTOBECLEARED <- array(PLAYERCAP, [])
	ATTRIBSTOBEADDED <- array(PLAYERCAP, [])
	FLIGHTPROCS <- array(PLAYERCAP, [])
	CURRENTWEAPON <- array(PLAYERCAP, [])
	LASTATTACK <- array(PLAYERCAP, [])
	LASTHURT <- array(PLAYERCAP, 0)
	PLAYERITERATE <- []
	FUNCTIONTRACKER <- []
	REAPEATINGTRACKER <- []
	BUILDINGSPLAYER <- []
	NULLVECTOR <- Vector(0,0,0)
	BuildText <- null
	TimerText <- null
}

ticks <- 0

::LibraryTable <- {
	function OnGameEvent_player_spawn(params)
	{
		PLAYERITERATE.append(GetPlayerFromUserID(params.userid))
	}
	function OnGameEvent_player_hurt(params)
	{
		LASTHURT[GetPlayerFromUserID(params.userid).GetEntityIndex()] = Time()
	}
}

__CollectGameEventCallbacks(LibraryTable)

// What a laggy piece of work
// TO DO: OPTIMISE!
Entities.First().SetThinkFunction("TimerTracker", 0)

::TimerTracker <- function()
{
	local i = 0
	while (i < FUNCTIONTRACKER.len())
	{
		if (FUNCTIONTRACKER[i][0] <= Time())
		{
			if (FUNCTIONTRACKER[i][1].getinfos().name != null)
			{
				local params = clone FUNCTIONTRACKER[i][2]
				FUNCTIONTRACKER[i][1].acall([this].extend(params))
			}
			FUNCTIONTRACKER.remove(i)
		}
		else
		{
			if (FUNCTIONTRACKER[i][1].getinfos().name == null)
			{
				FUNCTIONTRACKER.remove(i)
			}
			else
			{
				i++
			}
		}
	}
	i = 0
	while (i < REAPEATINGTRACKER.len())
	{
		if (REAPEATINGTRACKER[i][0] <= Time())
		{
			REAPEATINGTRACKER[i][0] += REAPEATINGTRACKER[i][2]
			if (REAPEATINGTRACKER[i][0] < Time())
			{
				REAPEATINGTRACKER[i][0] = Time() + 0.01 // Not nessesary, but adds a bit of internal consistency
			}
			local params = clone REAPEATINGTRACKER[i][3]
			local removal = REAPEATINGTRACKER[i][1].acall([this].extend(params))
			if (removal == false)
			{
				REAPEATINGTRACKER.remove(i)
			}
			else
			{
				i += 1
			}
		}
		else
		{
			i += 1	
		}
	}

	return -1
}

::FunctionInTime <- function(timedfunction, time, params=[])
{
	if (time <= 0) // DON'T EXECUTE IT THIS FRAME OR IT COULD CAUSE AN INFINITE LOOP
	{
		time = 0.0001
	}
	FUNCTIONTRACKER.append([time + Time(), timedfunction, params])
}
::ReapeatingFunctionInTime <- function(timedfunction, time, params=[])
{
	if (time <= 0) // DON'T EXECUTE IT THIS FRAME OR IT COULD CAUSE AN INFINITE LOOP
	{
		time = 0.0001
	}
	REAPEATINGTRACKER.append([time + Time(), timedfunction, time, params])
}
::UniqueRepeatingFunctionInTime <- function(timedfunction, time, params=[])
{
	foreach (data in REAPEATINGTRACKER)
	{
		if (data[1].getinfos().name == timedfunction.getinfos().name)
		{
			data[1] = timedfunction
			return false
		}
	}
	if (time <= 0) // DON'T EXECUTE IT THIS FRAME OR IT COULD CAUSE AN INFINITE LOOP
	{
		time = 0.0001
	}
	REAPEATINGTRACKER.append([time + Time(), timedfunction, time, params])
	return true
}

function FrameCheck()
{
	foreach (player in PLAYERITERATE)
	{
		if (!player || !player.IsValid())
		{
			PLAYERITERATE.remove(PLAYERITERATE.find(player))
			continue
		}
		local weapon = player.GetActiveWeapon()

		// stupid hack fix
		if (NetProps.GetPropEntity(player, "m_hGroundEntity") != null)
		{
			FLIGHTPROCS[player.GetEntityIndex()] = 0
		}
		if (player.GetActiveWeapon() != CURRENTWEAPON[player.GetEntityIndex()] && weapon)
		{
			player.AcceptInput("fireuser3", "", null, null)
			CURRENTWEAPON[player.GetEntityIndex()] = player.GetActiveWeapon()
		}

		if (!weapon)
		{
			continue
		}
		// when melee smacks, m_iNextMeleeCrit is 0
		if (NetProps.GetPropInt(player, "m_Shared.m_iNextMeleeCrit") == 0)
		{
			// when switching away from melee, m_iNextMeleeCrit will also be 0 so check for that case
			if (player.GetActiveWeapon() == weapon)
			{
				player.AcceptInput("fireuser1", "", null, null)
			}

			// continue smack detection
			NetProps.SetPropInt(player, "m_Shared.m_iNextMeleeCrit", -2)
		}
		local attacktime = NetProps.GetPropFloat(weapon, "m_flLastFireTime")
		if (attacktime == Time())
		{
			player.AcceptInput("fireuser2", "", null, null)
		}
		else
		{
			local attacktime = max(NetProps.GetPropFloat(weapon, "m_flNextPrimaryAttack"), NetProps.GetPropFloat(weapon, "m_flNextSecondaryAttack"))
			if (attacktime > Time() && (LASTATTACK[player.GetEntityIndex()] != attacktime && weapon.FireDuration()))
			{
				player.AcceptInput("fireuser2", "", null, null)
				LASTATTACK[player.GetEntityIndex()] = attacktime
			}
			else if (!weapon.FireDuration())
			{
				LASTATTACK[player.GetEntityIndex()] = -1 // Likely unnessesary, but I'd like to be sure.
			}
		}
	}

	return -1
}

UniqueRepeatingFunctionInTime(FrameCheck, 0)

::DebugFunc <- function()
{
	null
}

::GetWearableAttribute <- function(player, attribname, basenum)
{
	if (player == null || !player.IsPlayer())
	{
		return basenum
	}
	if (basenum != 0)
	{
		local returnvalue = basenum
		for (local i = 0; i < MAXWEAPONS; i++)
		{
			local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (held_weapon == null)
				continue
			returnvalue *= held_weapon.GetAttribute(attribname, 1)
		}
		local wd = 0
		for (local wearable = player.FirstMoveChild(); wearable != null && wd < 50; wearable = wearable.NextMovePeer())
		{
			wd += 1
			if (!startswith(wearable.GetClassname(),"tf_wearable") || NetProps.GetPropInt(wearable, "m_bDisguiseWearable"))
				continue
			returnvalue *= wearable.GetAttribute(attribname, 1)
		}
		returnvalue *= player.GetCustomAttribute(attribname, 1)
		return returnvalue
	}
	else
	{
		local returnvalue = 0
		for (local i = 0; i < MAXWEAPONS; i++)
		{
			local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (held_weapon == null)
				continue
			returnvalue += held_weapon.GetAttribute(attribname, 0)
		}
		local wd = 0
		for (local wearable = player.FirstMoveChild(); wearable != null && wd < 50; wearable = wearable.NextMovePeer())
		{
			wd += 1
			if (!startswith(wearable.GetClassname(),"tf_wearable") || NetProps.GetPropInt(wearable, "m_bDisguiseWearable"))
				continue
			returnvalue += wearable.GetAttribute(attribname, 0)
		}
		returnvalue += player.GetCustomAttribute(attribname, 0)
		return returnvalue
	}
}

::GetWearableAttributeString <- function(player, attribname, fallback)
{
	if (player == null || !player.IsPlayer())
	{
		return fallback
	}
	local returnvalue = fallback
	for (local i = 0; i < MAXWEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		returnvalue = held_weapon.GetAttributeString(attribname, returnvalue)
	}
	local wd = 0
	for (local wearable = player.FirstMoveChild(); wearable != null && wd < 50; wearable = wearable.NextMovePeer())
	{
		wd += 1
		if (!startswith(wearable.GetClassname(),"tf_wearable") || NetProps.GetPropInt(wearable, "m_bDisguiseWearable"))
			continue
		returnvalue = wearable.GetAttributeString(attribname, returnvalue)
	}
	return returnvalue
}

::AddWearerAttribute <- function(player, attribname, value)
{
	for (local i = 0; i < MAXWEAPONS; i++) // Doesn't bother with wearables atm, have no reason to.
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		held_weapon.AddAttribute(attribname, value, 0)
	}
}

::AddWearerAttributeString <- function(player, attribname, value)
{
	for (local i = 0; i < MAXWEAPONS; i++) // Doesn't bother with wearables atm, have no reason to.
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		held_weapon.AddAttributeString(attribname, value)
	}
}

::RemoveWearerAttribute <- function(player, attribname)
{
	for (local i = 0; i < MAXWEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		held_weapon.RemoveAttribute(attribname)
	}
	local wd = 0
	for (local wearable = player.FirstMoveChild(); wearable != null && wd < 50; wearable = wearable.NextMovePeer())
	{
		wd += 1
		if (!startswith(wearable.GetClassname(),"tf_wearable")) // It really shouldn't matter if attributes get removed from disguise wearables should it?
			continue
		wearable.RemoveAttribute(attribname)
	}
}

::RemoveWearerAttributeString <- function(player, attribname)
{
	for (local i = 0; i < MAXWEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		held_weapon.AddAttributeString(attribname, "")
	}
	local wd = 0
	for (local wearable = player.FirstMoveChild(); wearable != null && wd < 50; wearable = wearable.NextMovePeer())
	{
		wd += 1
		if (!startswith(wearable.GetClassname(),"tf_wearable")) // It really shouldn't matter if attributes get removed from disguise wearables should it?
			continue
		wearable.AddAttributeString(attribname, "")
	}
}

::GetWeaponInSlot <- function(player, slot)
{
	for (local i = 0; i < MAXWEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		if (held_weapon.GetSlot() == slot)
		{
			return held_weapon
		}
	}
	local wd = 0
	for (local wearable = player.FirstMoveChild(); wearable != null && wd < 50; wearable = wearable.NextMovePeer())
	{
		wd += 1
		if (!startswith(wearable.GetClassname(),"tf_wearable") || NetProps.GetPropInt(wearable, "m_bDisguiseWearable"))
			continue
		if (wearable.GetAttribute("wearable slot " + slot.tostring(), 0))
		{
			return wearable
		}
	}
	return null
}

::AttributeWeaponInSlot <- function(player, slot, attrib, value)
{
	local weapon = GetWeaponInSlot(player, slot)
	if (weapon)
	{
		weapon.AddAttribute(attrib, value, 0)
		return true
	}
	else
	{
		return false
	}
}

::RemoveWeaponInSlot <- function(player, slot)
{
	for (local i = 0; i < MAXWEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		if (held_weapon.GetSlot() == slot)
		{
			NetProps.SetPropEntityArray(player, "m_hMyWeapons", null, i)
			if (player.GetActiveWeapon() == held_weapon)
			{
				local newweap
				local j = 0
				while (!(newweap = NetProps.GetPropEntityArray(player, "m_hMyWeapons", j)))
				{
					j += 1
				}
				player.Weapon_Switch(newweap)
			}
			held_weapon.Destroy()
		}
	}
	local wd = 0
	for (local wearable = player.FirstMoveChild(); wearable != null && wd < 50; wearable = wearable.NextMovePeer())
	{
		wd += 1
		if (!startswith(wearable.GetClassname(),"tf_wearable") || NetProps.GetPropInt(wearable, "m_bDisguiseWearable"))
			continue
		if (wearable.GetAttribute("wearable slot " + slot.tostring(), 0))
		{
			wearable.Destroy()
		}
	}
	return null
}

// Suprisingly a pain
::AddTimedWearerAttribute <- function(player, attribname, value, time)
{
	local truetime = time + Time()
	AddWearerAttribute(player, attribname, value) //Sadly, the float that's supposed to determine how long it lasts does not, infact, do that.
	// "Wait the amount of time and then run the function" SHOULD NOT BE THIS MUCH OF A PAIN.
	local playerarray = ATTRIBSTOBECLEAREDWEARER[player.GetEntityIndex()]
	local i = 0
	foreach (waiting in playerarray)
	{
		if (waiting[0] == attribname)
		{
			if (waiting[1] >= time + Time())
			{
				return
			}
			else
			{
				playerarray.remove(playerarray.find(waiting))
			}
		}
	}
	playerarray.append([attribname, truetime])
	FunctionInTime(RemoveTimedWearerAttribute, time, [player, [attribname, truetime]])
}

function RemoveTimedWearerAttribute(player,array)
{
	local playerarray = ATTRIBSTOBECLEAREDWEARER[player.GetEntityIndex()]
	foreach (array2 in playerarray)
	{
		if (array2[0] == array[0] && array2[1] == array[1])
		{
			RemoveWearerAttribute(player, array[0])
			playerarray.remove(playerarray.find(array2))
		}
	}
}

// Suprisingly a pain
CTFPlayer.AddTimedWearerAttributeString <- function(attribname, value, time)
{
	local truetime = time + Time()
	AddWearerAttributeString(this, attribname, value) //Sadly, the float that's supposed to determine how long it lasts does not, infact, do that.
	// "Wait the amount of time and then run the function" SHOULD NOT BE THIS MUCH OF A PAIN.
	local playerarray = ATTRIBSTOBECLEAREDWEARER[this.GetEntityIndex()]
	foreach (waiting in playerarray)
	{
		if (waiting[0] == attribname)
		{
			if (waiting[1] >= time + Time())
			{
				return
			}
			else
			{
				playerarray.remove(playerarray.find(waiting))
			}
		}
	}
	playerarray.append([attribname, truetime])
	FunctionInTime(RemoveTimedWearerAttributeString, time, [attribname, truetime])
}
CTFBot.AddTimedWearerAttributeString <- CTFPlayer.AddTimedWearerAttributeString

function RemoveTimedWearerAttributeString(array)
{
	local playerarray = ATTRIBSTOBECLEAREDWEARER[player.GetEntityIndex()]
	foreach (array2 in playerarray)
	{
		if (array2[0] == array[0] && array2[1] == array[1])
		{
			RemoveWearerAttributeString(player, array[0])
			playerarray.remove(playerarray.find(array2))
		}
	}
}

::AddTimedAttribute <- function(weapon, attribname, value, time)
{
	local truetime = time + Time()
	local player = weapon.GetOwner()
	weapon.AddAttribute(attribname, value, 0) //Sadly, the float that's supposed to determine how long it lasts, does not, infact, do that.
	// "Wait the amount of time and then run the function" SHOULD NOT BE THIS MUCH OF A PAIN.
	local playerarray = ATTRIBSTOBECLEARED[player.GetEntityIndex()]
	foreach (waiting in playerarray)
	{
		if (waiting[0] == attribname && waiting[3] == weapon)
		{
			if (waiting[1] >= time + Time())
			{
				return
			}
			else
			{
				playerarray.remove(playerarray.find(waiting))
			}
		}
	}
	playerarray.append([attribname, truetime, weapon])
	FunctionInTime(RemoveTimedAttribute, time, [player, [attribname, truetime, weapon]])
}

function RemoveTimedAttribute(player, array)
{
	local playerarray = ATTRIBSTOBECLEARED[player.GetEntityIndex()]
	foreach (array2 in playerarray)
	{
		if (array2[0] == array[0] && array2[1] == array[1] && array2[2] == array[2])
		{
			array[2].RemoveAttribute(array[0])
			playerarray.remove(playerarray.find(array2))
		}
	}
}

::AddAttributeAfterTime <- function(weapon, attribname, value, time)
{
	local truetime = time + Time()
	local player = weapon.GetOwner()
	// "Wait the amount of time and then run the function" SHOULD NOT BE THIS MUCH OF A PAIN.
	local playerarray = ATTRIBSTOBEADDED[player.GetEntityIndex()]
	// We don't actually really care if they overlap here, so I just won't even check.
	playerarray.append([attribname, truetime, weapon, value])
	FunctionInTime(AddAttributeAfterTime, time, [player, [attribname, truetime, weapon, value]])
}

function AddAttributeAfterTime(player, array)
{
	local playerarray = ATTRIBSTOBEADDED[player.GetEntityIndex()]
	foreach (array2 in playerarray)
	{
		if (array2[0] == array[0] && array2[1] == array[1] && array2[2] == array[2] && array2[3] == array[3])
		{
			array[2].AddAttribute(array[0], array[3], 0)
			playerarray.remove(playerarray.find(array2))
		}
	}
}

::GetWeaponByDefIndex <- function(player, index)
{
	for (local i = 0; i < MAXWEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		if (NetProps.GetPropInt(held_weapon,"m_AttributeManager.m_Item.m_iItemDefinitionIndex") == index)
		{
			return held_weapon
		}
	}
	return null
}

::GetWeaponByClassID <- function(player, index)
{
	for (local i = 0; i < MAXWEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		if (held_weapon.GetClassname() == WeaponsClassesListCode[index] || (index == 64 && held_weapon.GetClassname() == "tf_weapon_katana"))
		{
			return held_weapon
		}
	}
	return null
}


::GetWeaponByClass <- function(player, weaponclass)
{
	for (local i = 0; i < MAXWEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		if (held_weapon.GetClassname() == weaponclass)
		{
			return held_weapon
		}
	}
	local wd = 0
	for (local wearable = player.FirstMoveChild(); wearable != null && wd < 50; wearable = wearable.NextMovePeer())
	{
		wd += 1
		if (!startswith(wearable.GetClassname(),"tf_wearable") || NetProps.GetPropInt(wearable, "m_bDisguiseWearable"))
			continue
		if (wearable.GetClassname() == weaponclass)
		{
			return wearable
		}
	}
	return null
}

CTFPlayer.IsInValidState <- function()
{
	if (GetRoundState == 3)
	{
		return false
	}
	else if (GetWinningTeam() != 0 && GetWinningTeam() != this.GetTeam())
	{
		return false
	}
	else if (this.InCond(15))
	{
		return false
	}
	else if (this.IsTaunting())
	{
		return false
	}
	return true
}
CTFBot.IsInValidState <- CTFPlayer.IsInValidState

::DisplayStackBuildText <- function(player, text)
{
	if (!BuildText || !BuildText.IsValid())
	{
		BuildText <- SpawnEntityFromTable("game_text", {
			message = "If you're seeing this, something's gone wrong",
			x = 0.9,
			y = 0.8,
			effect = 0,
			color = "12 255 12",
			fadein = 0.5,
			holdtime = 9999.0
		});	
	}
	BuildText.AcceptInput("settext", text,player,null)
	BuildText.AcceptInput("Display", "",player,null)
}

// Just reuse the timer text for this one.
::DisplayRageBuildText <- function(player, text)
{
	if (!TimerText || !TimerText.IsValid())
	{
		TimerText <- SpawnEntityFromTable("game_text", {
			message = "If you're seeing this, something's gone wrong",
			x = 0.885,
			y = 0.8,
			effect = 0,
			color = "100 12 12",
			fadein = 0.2,
			holdtime = 9999.0
		});
	}
	TimerText.AcceptInput("settext", text,player,null)
	TimerText.AcceptInput("Display", "",player,null)
}

// Display a timer
::DisplayTimer <- function(player, time)
{
	if (!TimerText || !TimerText.IsValid())
	{
		TimerText <- SpawnEntityFromTable("game_text", {
			message = "If you're seeing this, something's gone wrong",
			x = 0.885,
			y = 0.8,
			effect = 0,
			color = "100 12 12",
			fadein = 0.2,
			holdtime = 9999.0
		});
	}
	TimerText.AcceptInput("settext", "▢▢▢▢▢▢▢▢▢▢",player,null)
	TimerText.AcceptInput("Display", "",player,null)
	// I don't think there's a better way of doing this.
	EntFireByHandle(player, "CallScriptFunction", "__TimeInterval0", time*(1/11.0), player, null)
	EntFireByHandle(player, "CallScriptFunction", "__TimeInterval1", time*(2/11.0), player, null)
	EntFireByHandle(player, "CallScriptFunction", "__TimeInterval2", time*(3/11.0), player, null)
	EntFireByHandle(player, "CallScriptFunction", "__TimeInterval3", time*(4/11.0), player, null)
	EntFireByHandle(player, "CallScriptFunction", "__TimeInterval4", time*(5/11.0), player, null)
	EntFireByHandle(player, "CallScriptFunction", "__TimeInterval5", time*(6/11.0), player, null)
	EntFireByHandle(player, "CallScriptFunction", "__TimeInterval6", time*(7/11.0), player, null)
	EntFireByHandle(player, "CallScriptFunction", "__TimeInterval7", time*(8/11.0), player, null)
	EntFireByHandle(player, "CallScriptFunction", "__TimeInterval8", time*(9/11.0), player, null)
	EntFireByHandle(player, "CallScriptFunction", "__TimeInterval9", time*(10/11.0), player, null)
	EntFireByHandle(player, "CallScriptFunction", "__TimeInterval10", time*(11/11.0), player, null)
}

::__TimeInterval0 <- function()
{
	TimerText.AcceptInput("settext", "▣▢▢▢▢▢▢▢▢▢",self,null)
	TimerText.AcceptInput("Display", "",self,null)
}

::__TimeInterval1 <- function()
{
	TimerText.AcceptInput("settext", "▣▣▢▢▢▢▢▢▢▢",self,null)
	TimerText.AcceptInput("Display", "",self,null)
}

::__TimeInterval2 <- function()
{
	TimerText.AcceptInput("settext", "▣▣▣▢▢▢▢▢▢▢",self,null)
	TimerText.AcceptInput("Display", "",self,null)
}

::__TimeInterval3 <- function()
{
	TimerText.AcceptInput("settext", "▣▣▣▣▢▢▢▢▢▢",self,null)
	TimerText.AcceptInput("Display", "",self,null)
}

::__TimeInterval4 <- function()
{
	TimerText.AcceptInput("settext", "▣▣▣▣▣▢▢▢▢▢",self,null)
	TimerText.AcceptInput("Display", "",self,null)
}

::__TimeInterval5 <- function()
{
	TimerText.AcceptInput("settext", "▣▣▣▣▣▣▢▢▢▢",self,null)
	TimerText.AcceptInput("Display", "",self,null)
}

::__TimeInterval6 <- function()
{
	TimerText.AcceptInput("settext", "▣▣▣▣▣▣▣▢▢▢",self,null)
	TimerText.AcceptInput("Display", "",self,null)
}

::__TimeInterval7 <- function()
{
	TimerText.AcceptInput("settext", "▣▣▣▣▣▣▣▣▢▢",self,null)
	TimerText.AcceptInput("Display", "",self,null)
}

::__TimeInterval8 <- function()
{
	TimerText.AcceptInput("settext", "▣▣▣▣▣▣▣▣▣▢",self,null)
	TimerText.AcceptInput("Display", "",self,null)
}

::__TimeInterval9 <- function()
{
	TimerText.AcceptInput("settext", "▣▣▣▣▣▣▣▣▣▣",self,null)
	TimerText.AcceptInput("Display", "",self,null)
}

::__TimeInterval10 <- function()
{
	TimerText.AcceptInput("settext", "",self,null)
	TimerText.AcceptInput("Display", "",self,null)
}

::StartsWithList <- function(value, list)
{
	foreach (i in list)
	{
		if (startswith(value,i))
		{
			return true
		}
	}
	return false
}

CEntities.GetAllClassnameInRadius <- function(classname, origin, radius)
{
	local ents = []
	local iterate = Entities.FindByClassnameWithin(null, classname, origin, radius)
	local wd = 0
	while (iterate && ents.find(iterate) == null && wd < 50)
	{
		ents.append(iterate)
		wd++
		iterate = Entities.FindByClassnameWithin(iterate, classname, origin, radius)
	}
	return ents
}

::ProcessStringAttrib <- function(string)
{
	local split = split(string, " ");
	foreach (text in split)
	{
		if (text == "")
		{
			split.remove(split.find(text))
		}
		if (startswith(text,"'"))
		{
			local recomp = text.slice(1) + " "
			local found = false
			local place = split.find(text)
			split.remove(place)
			while (place < split.len() && !found)
			{
				if (!endswith(split[place],"'"))
				{
					recomp = recomp + split[place] + " "
				}
				else
				{
					recomp = recomp + split[place].slice(0,-1)
					found = true
				}
				split.remove(place)
			}
			split.insert(place, recomp)
		}
		if (["1", "2", "3", "4", "5", "6", "7", "8", "9"].find(text.slice(0,1)) != null) // Lazy check ik but it'll be correct in 99.9% of senarios.
		{
			local index = split.find(text)
			split.remove(split.find(text))
			split.insert(index, text.tofloat())
		}
	}
	if (split.len() == 0)
	{
		return [""]
	}
	else
	{
		return split
	}
}

::Bingus <- function()
{
	EntFireByHandle(Entities.First(), "CallScriptFunction", "BingusHours", 60, null, null)
}

::BingusHours <- function()
{
	local player = Entities.FindByClassname(null, "player")
	while (player)
	{
		if (player.IsAlive())
		{
			printl("bingus hours")
			local infront = player.EyeAngles()
			infront.z = 0
			SpawnEntityFromTable("headless_hatman", { origin = player.GetOrigin() + infront })
		}
		player = Entities.FindByClassname(player, "player")
	}
	EntFireByHandle(Entities.First(), "CallScriptFunction", "BingusHours", 60, null, null)
}

// in alphabetical order, makes things readable
::WeaponsClassesListAlpha <-
[
	0,
	"tf_weapon_bat", // 1
	"tf_weapon_bat_fish",  // 2
	"tf_weapon_bat_giftwrap",  // 3
	"tf_weapon_bat_wood",  // 4
	"tf_weapon_bonesaw",  // 5
	"tf_weapon_bottle",  // 6
	"tf_weapon_breakable_sign",  // 7
	"tf_weapon_buff_item",  // 8
	"tf_weapon_builder", // 9
	"tf_weapon_cannon", // 10
	"tf_weapon_charged_smg", // 11
	"tf_weapon_cleaver", // 12
	"tf_weapon_club", // 13
	"tf_weapon_compound_bow", // 14
	"tf_weapon_crossbow", // 15
	"tf_weapon_drg_pomson", // 16
	"tf_weapon_fireaxe", // 17
	"tf_weapon_fists", // 18
	"tf_weapon_flamethrower", // 19
	"tf_weapon_flaregun", // 20
	"tf_weapon_flaregun_revenge", // 21
	"tf_weapon_grapplinghook", // 22
	"tf_weapon_grenade_mirv", // 23
	"tf_weapon_grenadelauncher", // 24
	"tf_weapon_handgun_scout_primary", // 25
	"tf_weapon_handgun_scout_secondary", // 26
	"tf_weapon_invis", // 27
	"tf_weapon_jar", // 28
	"tf_weapon_jar_milk", // 29
	"tf_weapon_jar_gas", // 30
	"tf_weapon_katana", // 31
	"tf_weapon_knife", // 32
	"tf_weapon_laser_pointer", // 33
	"tf_weapon_lunchbox", // 34
	"tf_weapon_lunchbox_drink", // 35
	"tf_weapon_mechanical_arm", // 36
	"tf_weapon_medigun", // 37
	"tf_weapon_minigun", // 38
	"tf_weapon_parachute", // 39
	"tf_weapon_parachute_primary", // 40
	"tf_weapon_parachute_secondary", // 41
	"tf_weapon_particle_cannon", // 42
	"tf_weapon_passtime_gun", // 43
	"tf_weapon_pda_engineer_build", // 44
	"tf_weapon_pda_engineer_destroy", // 45
	"tf_weapon_pda_spy", // 46
	"tf_weapon_pep_brawler_blaster", // 47
	"tf_weapon_pipebomblauncher", // 48
	"tf_weapon_pistol", // 49
	"tf_weapon_pistol_scout", // 50
	"tf_weapon_raygun", // 51
	"tf_weapon_revolver", // 52
	"tf_weapon_robot_arm", // 53
	"tf_weapon_rocketlauncher", // 54
	"tf_weapon_rocketlauncher_airstrike", // 55
	"tf_weapon_rocketlauncher_directhit", // 56
	"tf_weapon_rocketlauncher_fireball", // 57
	"tf_weapon_rocketpack", // 58
	"tf_weapon_sapper", // 59
	"tf_weapon_scattergun", // 60
	"tf_weapon_sentry_revenge", // 61
	"tf_weapon_shotgun_hwg", // 62
	"tf_weapon_shotgun_primary", // 63
	"tf_weapon_shotgun_pyro", // 64
	"tf_weapon_shotgun_building_rescue", // 65
	"tf_weapon_shotgun_soldier", // 66
	"tf_weapon_shovel", // 67
	"tf_weapon_slap", // 68
	"tf_weapon_smg", // 69
	"tf_weapon_sniperrifle", // 70
	"tf_weapon_sniperrifle_classic", // 71
	"tf_weapon_sniperrifle_decap", // 72
	"tf_weapon_soda_popper", // 73
	"tf_weapon_spellbook", // 74
	"tf_weapon_stickbomb", // 75
	"tf_weapon_sword", // 76
	"tf_weapon_syringegun_medic", // 77
	"tf_weapon_wrench", // 78
	"tf2c_weapon_aagun", // 79
	"tf2c_weapon_anchor", // 80
	"tf2c_weapon_brick", // 81
	"tf2c_weapon_chains", // 82
	"tf2c_weapon_coilgun", // 83
	"tf2c_weapon_cyclops", // 84
	"tf2c_weapon_doubleshotgun", // 85
	"tf2c_weapon_heallauncher", // 86
	"tf2c_weapon_hunting_revolver", // 87
	"tf2c_weapon_nailgun", // 88
	"tf2c_weapon_sycthe", // 89
	"tf2c_weapon_taser", // 90
	"tf2c_weapon_tranq", // 91
	"tf2c_weapon_umbrella", // 92
	"custom_weapon_scripted1", // 93
]

// how it actually is ingame. Oh JOY
::WeaponsClassesListCode <-
[
	0,
	"tf_weapon_bat",
	"tf_weapon_bat_wood",
	"tf_weapon_bottle",
	"tf_weapon_fireaxe",
	"tf_weapon_club",
	0,
	"tf_weapon_knife",
	"tf_weapon_fists",
	"tf_weapon_shovel",
	"tf_weapon_wrench",
	//"tf_weapon_robot_arm",
	"tf_weapon_bonesaw",
	"tf_weapon_shotgun_primary",
	"tf_weapon_shotgun_soldier",
	"tf_weapon_shotgun_hwg",
	"tf_weapon_shotgun_pyro",
	"tf_weapon_scattergun",
	"tf_weapon_sniperrifle",
	"tf_weapon_minigun",
	"tf_weapon_smg",
	"tf_weapon_syringegun_medic",
	"tf2c_weapon_tranq",
	"tf_weapon_rocketlauncher",
	"tf_weapon_grenadelauncher",
	"tf_weapon_pipebomblauncher",
	"tf_weapon_flamethrower",
	1,
	2,
	3,
	"tf_weapon_grenade_mirv",
	5,
	6,
	7,
	8,
	9,
	10,
	11,
	12,
	13,
	14,
	15,
	"tf_weapon_pistol",
	"tf_weapon_pistol_scout",
	"tf_weapon_revolver",
	"tf2c_weapon_nailgun"
	"tf_weapon_pda_engineer_build",
	"tf_weapon_pda_engineer_destroy",
	"tf_weapon_pda_spy",
	"tf_weapon_builder",
	"tf_weapon_sapper",
	"tf_weapon_medigun",
	1,
	2,
	3,
	4,
	5,
	6,
	"tf_weapon_invis",
	"tf_weapon_flaregun",
	"tf_weapon_lunchbox",
	//"tf_weapon_lunchbox_drink",
	"tf_weapon_jar",
	"tf_weapon_compound_bow",
	"tf_weapon_buff_item",
	0,
	"tf_weapon_sword",
	"tf_rocketlauncher_directhit",
	0,
	"tf_weapon_laser_pointer",
	0,
	"tf_weapon_sentry_revenge",
	"tf_weapon_jar_milk",
	"tf_weapon_handgun_scout_primary",
	"tf_weapon_bat_fish",
	"tf_weapon_crossbow",
	"tf_weapon_stickbomb",
	"tf_weapon_handgun_scout_secondary",
	"tf_weapon_soda_popper",
	"tf_weapon_sniperrifle_decap",
	"tf_weapon_raygun",
	"tf_weapon_particle_cannon",
	"tf_weapon_mechanical_arm",
	"tf_weapon_drg_pomson",
	"tf_weapon_bat_giftwrap",
	0,
	"tf_weapon_flaregun_revenge",
	"tf_weapon_pep_brawler_blaster",
	"tf_weapon_cleaver",
	1,
	2,
	3,
	"tf_weapon_shotgun_building_rescue",
	"tf_weapon_cannon",
	1,
	2,
	3,
	4,
	5,
	"tf_weapon_spellbook",
	0,
	"tf_weapon_sniperrifle_classic",
	"tf_weapon_parachute",
	"tf_weapon_grapplinghook",
	0, //passtime thing? no idea what class if any that is.
	"tf_weapon_charged_smg",
	"tf_weapon_breakable_sign",
	"tf_weapon_rocketpack",
	"tf_weapon_slap",
	"tf_weapon_jar_gas",
	0,
	"tf_weapon_rocketlauncher_fireball",
	"tf2c_weapon_brick",
	"tf2c_weapon_anchor",
	"tf2c_weapon_hunting_revolver",
	"tf2c_weapon_doubleshotgun",
	"tf2c_weapon_sycthe",
	"tf2c_weapon_aagun",
	"tf2c_weapon_umbrella",
	"tf2c_weapon_chains",
	"tf2c_weapon_coilgun",
	"tf2c_weapon_cyclops",
	0, // no idea
	"tf2c_weapon_heallauncher",
	"tf2c_weapon_taser",
]

::MeleeWeapons <-
[
	"tf_weapon_bat",
	"tf_weapon_bat_wood",
	"tf_weapon_bottle",
	"tf_weapon_fireaxe",
	"tf_weapon_club",
	"tf_weapon_knife",
	"tf_weapon_fists",
	"tf_weapon_shovel",
	"tf_weapon_wrench",
	"tf_weapon_robot_arm",
	"tf_weapon_bonesaw",
	"tf_weapon_katana"
	"tf_weapon_sword",
	"tf_weapon_bat_fish",
	"tf_weapon_breakable_sign",
	"tf_weapon_slap",
	"tf2c_weapon_anchor",
	"tf2c_weapon_sycthe",
	"tf2c_weapon_umbrella",
	"tf2c_weapon_chains",
	"tf2c_weapon_taser"
]

::MedievalWeapons <-
[
	"tf_weapon_bat",
	"tf_weapon_bat_wood",
	"tf_weapon_bottle",
	"tf_weapon_fireaxe",
	"tf_weapon_club",
	"tf_weapon_knife",
	"tf_weapon_fists",
	"tf_weapon_shovel",
	"tf_weapon_wrench",
	"tf_weapon_robot_arm",
	"tf_weapon_bonesaw",
	"tf_weapon_katana"
	"tf_weapon_sword",
	"tf_weapon_bat_fish",
	"tf_weapon_breakable_sign",
	"tf_weapon_slap",
	"tf2c_weapon_anchor",
	"tf2c_weapon_sycthe",
	"tf2c_weapon_umbrella",
	"tf2c_weapon_chains",
	"tf2c_weapon_taser",
	"tf_weapon_spellbook",
	"tf_weapon_grapplinghook",
	"tf_weapon_builder"
]