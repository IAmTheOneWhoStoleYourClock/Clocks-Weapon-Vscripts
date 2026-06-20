// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// Linked items still get removed and readded on resupply. Might be able to fix that, but for now I don't care.
// Preventing automatically swapping to new weapons may cause conflicts with other scripts.
//

::LinkedItemIdTable <- {
	function OnGameEvent_weapon_equipped(params)
	{
		local player = EntIndexToHScript(params.entindex).GetOwner() // So that you aren't forced to the weapon whenever you resupply
		if (player.GetActiveWeapon() == null)
		{
			player.AddContext("GlenQuagmireIDCNoClearContextNamesForYou", "g", 0.015)
		}
		else if (player.GetContext("GlenQuagmireIDCNoClearContextNamesForYou") == "")
		{
			player.AddCustomAttribute("disable weapon switch", 1, 0.015)
		}
	}
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.RemoveCustomAttribute("disable weapon switch")
		local linkedid
		local enabletactician = 0
		local tacticianbuffer = []
		local noswitchbuffer = []
		for (local i = 0; i < 8; i++)
		{
			local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (held_weapon == null)
				continue
			held_weapon.ValidateScriptScope()
			linkedid = held_weapon.GetAttribute("linked item id", 0)
			if (linkedid != 0)
			{
				GivePlayerWeapon(player, WeaponsClassesList[held_weapon.GetAttribute("linked item class", 0)], linkedid)
			}
			linkedid = held_weapon.GetAttribute("linked item id tactician", 0)
			if (linkedid != 0)
			{
				tacticianbuffer.append([linkedid, WeaponsClassesList[held_weapon.GetAttribute("linked item class", 0)]])
			}
			enabletactician += held_weapon.GetAttribute("tactician bonus enable", 0) // Do it like this in case a weapon wants to disable it for whatever reason
		}
		for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
		{
			if (wearable.GetClassname() != "tf_wearable")
				continue
			linkedid = wearable.GetAttribute("linked item id", 0)
			if (linkedid != 0)
			{
				GivePlayerWeapon(player, WeaponsClassesList[wearable.GetAttribute("linked item class", 0)], linkedid)
			}
			linkedid = wearable.GetAttribute("linked item id tactician", 0)
			if (linkedid != 0)
			{
				tacticianbuffer.append([linkedid, WeaponsClassesList[wearable.GetAttribute("linked item class", 0)]])
			}
			enabletactician += wearable.GetAttribute("tactician bonus enable", 0)
		}
		if (enabletactician > 0)
		{
			foreach (i in tacticianbuffer)
			{
				GivePlayerWeapon(player, i[1], i[0])
			}
		}
	}
}

Entities.EnableEntityListening()

__CollectGameEventCallbacks(LinkedItemIdTable)

function GivePlayerWeapon(player, classname, item_id)
{
	local weapon = Entities.CreateByClassname(classname)
	local instaswitch = false
	NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", item_id)
	NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
	NetProps.SetPropBool(weapon, "m_bValidatedAttachedEntity", true)
	weapon.SetTeam(player.GetTeam())
	weapon.DispatchSpawn()

	// remove existing weapon in same slot
	for (local i = 0; i < 8; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		if (held_weapon.GetSlot() != weapon.GetSlot())
			continue
		if (NetProps.GetPropInt(held_weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex") == item_id)
		{
			return false
		}
		if (held_weapon == player.GetActiveWeapon())
		{
			instaswitch = true
		}
		held_weapon.Destroy()
		NetProps.SetPropEntityArray(player, "m_hMyWeapons", null, i)
		break
	}

	player.Weapon_Equip(weapon)
	if (instaswitch)
	{
		player.AddCustomAttribute("deploy time decreased", 0, 0.015)
		player.Weapon_Switch(weapon)
	}

	return weapon
}

function GetWearableAttribute(player, attribname, basenum)
{
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

// organized in alphabetical order, NOTE THAT FUTURE WEAPON CLASSES WILL BE APPENDED TO THE END SO AS NOT TO BREAK EXISTING SCRIPTS!
::WeaponsClassesList <-
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