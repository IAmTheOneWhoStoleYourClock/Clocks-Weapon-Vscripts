// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

IncludeScript("lib/clocksutils.nut");

local FLOATSTUFF = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

function DeriveValue(value)
{
	if (value == "null")
	{
		return null
	}
	else if (FLOATSTUFF.find(value.slice(0,1)) != null) // Bad but I *clap* DON'T *clap* CARE *third unnessary clap*
	{
		return value.tofloat()
	}
	else 
	{
		return value
	}
}

function Handlefileline(string)
{
	local stringsplit = split(string, ",")
	local finishedarray = []
	local arrayholder = []
	local arraymode = false
	foreach (i in stringsplit)
	{
		local value = strip(i)
		if (startswith(value,"["))
		{
			arraymode = true
			arrayholder.append(DeriveValue(value.slice(1)))
		}
		else if (endswith(value,"]"))
		{
			arraymode = false
			arrayholder.append(DeriveValue(value.slice(0,-1)))
			finishedarray.append(arrayholder)
			arrayholder=[]
		}
		else if (arraymode)
		{
			arrayholder.append(DeriveValue(value))
		}
		else
		{
			finishedarray.append(DeriveValue(value))
		}
	}
	return finishedarray
}

if (!FileExists("fallbacklist.cfg"))
{
	fallbacklist <- [
		// Slot 1, Slot 2, Slot 3, Slot 4, Slot 5, Slot 6, Slot 7 (as Name)
		["TF_WEAPON_SCATTERGUN","TF_WEAPON_PISTOL_SCOUT","TF_WEAPON_BAT",null,null,null], //Scout
		["TF_WEAPON_SNIPERRIFLE","TF_WEAPON_SMG","TF_WEAPON_CLUB",null,null,null], //Sniper
		["TF_WEAPON_ROCKETLAUNCHER","TF_WEAPON_SHOTGUN_SOLDIER","TF_WEAPON_SHOVEL",null,null,null], //Soldier
		["TF_WEAPON_GRENADELAUNCHER","TF_WEAPON_PIPEBOMBLAUNCHER","TF_WEAPON_BOTTLE",null,null,null], //Demoman
		["TF_WEAPON_SYRINGEGUN_MEDIC","TF_WEAPON_MEDIGUN","TF_WEAPON_BONESAW",null,null,null],  //Medic
		["TF_WEAPON_MINIGUN","TF_WEAPON_SHOTGUN_HWG","TF_WEAPON_FISTS",null,null,null],  //Heavy
		["TF_WEAPON_FLAMETHROWER","TF_WEAPON_SHOTGUN_PYRO","TF_WEAPON_FIREAXE",null,null,null],  //Pyro
		["TF_WEAPON_REVOLVER","TF_WEAPON_BUILDER_SPY","TF_WEAPON_KNIFE","TF_WEAPON_PDA_SPY","TF_WEAPON_INVIS",null],  //Spy
		["TF_WEAPON_SHOTGUN_PRIMARY","TF_WEAPON_PISTOL","TF_WEAPON_WRENCH","TF_WEAPON_PDA_ENGINEER_BUILD","TF_WEAPON_PDA_ENGINEER_DESTROY","TF_WEAPON_BUILDER"],  //Engineer
		[null,null,"Umbrella",null,null,null],  //Civilian
	]
	local configgenerator = "// This is the config that track weapons to fallback to, Do not add or remove any lines! In the event of an update, you WILL need to update this!\n"
	configgenerator += "// Slot 1, Slot 2, Slot 3, Slot 4, Slot 5, Slot 6, Slot 7. In order of scout, sniper, soldier, demoman, medic, heavy, pyro, spy, engineer, civilian\n"
	configgenerator += "// Entries are ordered as Item Names, enter null instead to give nothing upon falling back."
	foreach (i in fallbacklist)
	{
		configgenerator += "\n["
		foreach (k in i)
		{
			if ((typeof k) == "array")
			{
				configgenerator += "["
				foreach (j in k)
				{
					configgenerator += j.tostring() + ","
				}
				configgenerator = configgenerator.slice(0,-1)
				configgenerator += "], "
			}
			else if (k == null)
			{
				configgenerator += "null, "
			}
			else
			{
				configgenerator += k.tostring() + ", "
			}
		}
		configgenerator += "null]"
	}
	StringToFile("fallbacklist.cfg" configgenerator)
}
else
{
	local commentlines = [2,1,0]
	local file = split(FileToString("fallbacklist.cfg"), "\n")
	foreach (i in commentlines)
	{
		file.remove(i)
	}

	fallbacklist <- []
	foreach (i in file)
	{
		fallbacklist.append(Handlefileline(strip(i).slice(1,-1)))
	}
}

::LoadoutEvents <- {
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		local hasloadout = false
		local removedslots = []
		local loadoutallow = 0
		for (local i = 0; i < MAXWEAPONS; i++)
		{
			local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (held_weapon == null)
				continue
			local loadout = held_weapon.GetAttribute("loadout weapon", 0).tointeger()
			if (!hasloadout && loadout)
			{
				loadoutallow = loadout
				hasloadout = true
			}
			else if (loadout)
			{
				loadoutallow = loadoutallow & loadout
			}
		}
		local wd = 0
		for (local wearable = player.FirstMoveChild(); wearable != null && wd < 50; wearable = wearable.NextMovePeer())
		{
			wd += 1
			if (!startswith(wearable.GetClassname(),"tf_wearable") || NetProps.GetPropInt(wearable, "m_bDisguiseWearable"))
				continue
			local loadout = wearable.GetAttribute("loadout weapon", 0).tointeger()
			if (!hasloadout && loadout)
			{
				loadoutallow = loadout
				hasloadout = true
			}
			else if (loadout)
			{
				loadoutallow = loadoutallow & loadout
			}
		}
		
		if (hasloadout)
		{
			for (local i = 0; i < MAXWEAPONS; i++)
			{
				local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
				if (held_weapon == null)
					continue
				local loadout = held_weapon.GetAttribute("loadout weapon", 0).tointeger()
				if (((loadoutallow & loadout) == 0) && loadout)
				{
					removedslots.append(held_weapon.GetSlot())
					local wearable = NetProps.GetPropEntity(held_weapon, "m_hExtraWearable")
					if (wearable)
					{
						wearable.Kill()
					}
					held_weapon.Kill()
				}
			}
			local wd = 0
			for (local wearable = player.FirstMoveChild(); wearable != null && wd < 50; wearable = wearable.NextMovePeer())
			{
				wd += 1
				if (!startswith(wearable.GetClassname(),"tf_wearable") || NetProps.GetPropInt(wearable, "m_bDisguiseWearable"))
					continue
				local loadout = wearable.GetAttribute("loadout weapon", 0).tointeger()
				if (((loadoutallow & loadout) == 0) && loadout)
				{
					for (local i = 1; i < 7 ; i++)
					{
						local slot = wearable.GetAttribute("wearable slot " + slot.tostring(), 0)
						if (slot)
						{
							removedslots.append(i)
						}
					}
					wearable.Kill()
				}
			}
		}

		if (removedslots.len() > 0)
		{
			foreach (slot in removedslots)
			{
				if (fallbacklist[player.GetPlayerClass() - 1][slot] != null)
				{
					player.GenerateAndWearItem(fallbacklist[player.GetPlayerClass() - 1][slot])
				}
			}
		}
	}
}

/*
function GivePlayerWeapon(player, classname, item_id)
{
	local weapon = Entities.CreateByClassname(classname)
	local instaswitch = false
	NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", item_id)
	NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
	NetProps.SetPropBool(weapon, "m_bValidatedAttachedEntity", true)
	weapon.SetTeam(player.GetTeam())
	if (classname == "tf_weapon_builder")
	{
		NetProps.SetPropInt(weapon, "m_iObjectType", 0)
		NetProps.SetPropInt(weapon, "m_iObjectMode", 0)
		for (local i = 0; i < 5; i++)
		{
			NetProps.SetPropBoolArray(weapon, "m_aBuildableObjectTypes", true, i)
		}
	}
	weapon.DispatchSpawn()
	weapon.SetOwner(player)
	if (classname == "tf_wearable")
	{
		weapon.SetParent(player, "")
	}

	player.Weapon_Equip(weapon)


	return weapon
}
*/

__CollectGameEventCallbacks(LoadoutEvents)