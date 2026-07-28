// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None.
//
if (!("ATTRIBSTOBECLEAREDWEARER" in getroottable())) {
	MAXWEAPONS <- 8
	ATTRIBSTOBECLEAREDWEARER <- array(MaxPlayers(), [])
	ATTRIBSTOBECLEARED <- array(MaxPlayers(), [])
	ATTRIBSTOBEADDED <- array(MaxPlayers(), [])
	FLIGHTPROCS <- array(MaxPlayers(), [])
	NULLVECTOR <- Vector(0,0,0)
}

BuildText <- SpawnEntityFromTable("game_text", {
	message = "If you're seeing this, something's gone wrong",
	x = 0.9,
	y = 0.8,
	effect = 0,
	color = "12 255 12",
	fadein = 0.5,
	holdtime = 9999.0
});

TimerText <- SpawnEntityFromTable("game_text", {
	message = "If you're seeing this, something's gone wrong",
	x = 0.885,
	y = 0.8,
	effect = 0,
	color = "100 12 12",
	fadein = 0.2,
	holdtime = 9999.0
});

::PlayerCleanup <- {
	function OnGameEvent_player_disconnect(params)
	{
		local index = GetPlayerFromUserID(params.userid).GetEntityIndex()
		ATTRIBSTOBECLEAREDWEARER[index] = []
		ATTRIBSTOBECLEARED[index] = []
	}
}

__CollectGameEventCallbacks(PlayerCleanup)

// What a laggy piece of work
// TO DO: OPTIMISE!
Entities.First().SetThinkFunction("CheckMeleeSmack", 0)

function CheckMeleeSmack()
{
	local entity = Entities.First()
	local last = entity
	entity = Entities.Next(entity)
	while (entity != null && last != entity)
	{
		local owner = entity.GetOwner()
		if (entity.IsWeapon() && MeleeWeapons.find(entity.GetClassname()) != null && owner)
		{
			local scriptscope = entity.GetOrCreatePrivateScriptScope()
			// when melee smacks, m_iNextMeleeCrit is 0
			if (NetProps.GetPropInt(owner, "m_Shared.m_iNextMeleeCrit") == 0)
			{
				// when switching away from melee, m_iNextMeleeCrit will also be 0 so check for that case
				if (owner.GetActiveWeapon() == entity)
				{
					owner.AcceptInput("fireuser1", "", null, null)
				}

				// continue smack detection
				NetProps.SetPropInt(owner, "m_Shared.m_iNextMeleeCrit", -2)
			}
			local attacktime = NetProps.GetPropFloat(entity, "m_flNextPrimaryAttack")
			if (attacktime > Time() && (!("swingtime" in scriptscope) || scriptscope.swingtime < attacktime) && entity.FireDuration())
			{
				// when switching away from melee, m_iNextMeleeCrit will also be 0 so check for that case
				owner.AcceptInput("fireuser2", "", null, null)
				scriptscope.swingtime <- attacktime
			}
		}
		if (entity.IsPlayer() && NetProps.GetPropEntity(entity, "m_hGroundEntity") != null)
		{
			// stupid hack fix
			FLIGHTPROCS[entity.GetEntityIndex()] = 0
		}
		
		// Why does it not, just, like, return null when it's done. Stupid language. Stupid VScript.
		last = entity
		entity = Entities.Next(entity)
	}

	return -1
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
		for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
		{
			if (wearable.GetClassname() != "tf_wearable")
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
		for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
		{
			if (wearable.GetClassname() != "tf_wearable")
				continue
			returnvalue += wearable.GetAttribute(attribname, 0)
		}
		returnvalue += player.GetCustomAttribute(attribname, 0)
		return returnvalue
	}
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

::RemoveWearerAttribute <- function(player, attribname)
{
	for (local i = 0; i < MAXWEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		held_weapon.RemoveAttribute(attribname)
	}
	for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
	{
		if (wearable.GetClassname() != "tf_wearable")
			continue
		wearable.RemoveAttribute(attribname)
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
	for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
	{
		if (wearable.GetClassname() != "tf_wearable")
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
	for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
	{
		if (wearable.GetClassname() != "tf_wearable")
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
	while (i < playerarray.len() && playerarray[i][1] < truetime)
	{
		i += 1
	}
	playerarray.insert(i,[attribname, truetime])
	EntFireByHandle(player, "CallScriptFunction", "__RemoveTimedWearerAttribute", time, null, null)
}

// For those unfamiliar, __ before a functions means "DON'T USE THIS", so like, don't use this.
::__RemoveTimedWearerAttribute <- function()
{
	local playerarray = ATTRIBSTOBECLEAREDWEARER[self.GetEntityIndex()]
	local attribname = playerarray.remove(0)[0]
	RemoveWearerAttribute(self, attribname)
}

::AddTimedAttribute <- function(weapon, attribname, value, time)
{
	local truetime = time + Time()
	local player = weapon.GetOwner()
	weapon.AddAttribute(attribname, value, 0) //Sadly, the float that's supposed to determine how long it lasts, does not, infact, do that.
	// "Wait the amount of time and then run the function" SHOULD NOT BE THIS MUCH OF A PAIN.
	local playerarray = ATTRIBSTOBECLEARED[player.GetEntityIndex()]
	local i = 0
	while (i < playerarray.len() && playerarray[i][1] < truetime)
	{
		i += 1
	}
	ATTRIBSTOBECLEARED[player.GetEntityIndex()].insert(i,[attribname, truetime])
	EntFireByHandle(player, "CallScriptFunction", "__RemoveTimedAttribute", time, weapon, null)
}

// For those unfamiliar, __ before a functions means "DON'T USE THIS", so like, don't use this.
::__RemoveTimedAttribute <- function()
{
	local attribname = ATTRIBSTOBECLEARED[self.GetEntityIndex()].remove(0)[0]
	if (activator && activator.IsValid() && activator.IsWeapon())
	{
		activator.RemoveAttribute(attribname)
	}
}

::AddAttributeAfterTime <- function(weapon, attribname, value, time)
{
	local truetime = time + Time()
	local player = weapon.GetOwner()
	// "Wait the amount of time and then run the function" SHOULD NOT BE THIS MUCH OF A PAIN.
	local playerarray = ATTRIBSTOBEADDED[player.GetEntityIndex()]
	local i = 0
	while (i < playerarray.len() && playerarray[i][1] < truetime)
	{
		i += 1
	}
	ATTRIBSTOBEADDED[player.GetEntityIndex()].insert(i,[attribname, truetime, value])
	EntFireByHandle(player, "CallScriptFunction", "__AddAttributeAfterTime", time, weapon, null)
}

// For those unfamiliar, __ before a functions means "DON'T USE THIS", so like, don't use this.
::__AddAttributeAfterTime <- function()
{
	local attrib = ATTRIBSTOBEADDED[self.GetEntityIndex()].remove(0)

	if (activator && activator.IsValid() && activator.IsWeapon())
	{
		activator.AddAttribute(attrib[0],attrib[2],0)
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
	return null
}

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
	"tf2c_weapon_taser",
]