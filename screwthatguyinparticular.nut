// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// I am way more tired than I should be. I had like 6 butter tarts and it's 6 I have no reason to be this beat.
// No known plugin issues though.
//

function Handlefileline(string)
{
	local stringsplit = split(string, ",")
	local finishedarray = []
	local arrayholder = []
	local arraymode = false
	foreach (i in stringsplit)
	{
		local value = strip(i)
		printl(value)
		if (startswith(value,"["))
		{
			arraymode = true
			arrayholder.append(Handlefilevariable(value.slice(1)))
		}
		else if (endswith(value,"]"))
		{
			arraymode = false
			arrayholder.append(Handlefilevariable(value.slice(0,-1)))
			finishedarray.append(arrayholder)
			arrayholder=[]
		}
		else if (arraymode)
		{
			arrayholder.append(Handlefilevariable(value))
		}
		else
		{
			finishedarray.append(Handlefilevariable(value))
		}
	}
	return finishedarray
}

function Handlefilevariable(string)
{
	if (string == "true")
	{
		return true
	}
	else if (string == "false")
	{
		return false
	}
	try {
    	return string.tofloat()
	} catch (e) {
		return string
	}
}

if (!FileExists("screwthatguyinparticular.cfg"))
{
	nerflist <- [
		// Person, [Nerf, nerf value, weaponlocked, additive]
		["U:1:169802", ["dmg taken from bullets increased", 1.2, false, false], ["no crit boost", 1, true, true]], //Scout
		["U:1:0", ["dmg taken from bullets increased", 1.2, false, false]]
	]
	// I am lazy so I will write this out manually
	local configgenerator = "// This is the config for screwthatguyinparticular, Do not add or remove any lines! In the event of an update, you may need to update this! (but hopefully not!)\n"
	configgenerator += "// Nerfs are called by ''header'' (ex. dmg taken from bullets increased instead of mult_dmgtaken_from_bullets) NOTE THAT WEAPON LOCKED ATTRIBUTES WILL APPEAR ON THE WEAPON!\n"
	configgenerator += "// Person, [Nerf, nerf value, weaponlocked, additive]\n"
	configgenerator += "U:1:169802, [dmg taken from bullets increased, 1.2, false, false], [no crit boost, 1, true, true]\n"
	configgenerator += "U:1:0, [dmg taken from bullets increased, 1.2, false, false]"
	StringToFile("screwthatguyinparticular.cfg" configgenerator)
}
else
{
	local commentlines = [1,0]
	local file = split(FileToString("screwthatguyinparticular.cfg"), "\n")
	nerflist <- []
	foreach (i in commentlines)
	{
		file.remove(i)
	}
	foreach (i in file)
	{
		nerflist.append(Handlefileline(strip(i)))
	}
}

::ScrewThatGuyTable <- {
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		local ID = NetProps.GetPropString(player, "m_szNetworkIDString")
		foreach (i in nerflist)
		{
			if (i[0] == ID.slice(1,-1))
			{
				// I am tried it's time for utter GARBAGE
				local k = 1
				while (k < i.len())
				{
					if (i[k][2] && i[k][3])
					{
						AddWearerAttribute(player, i[k][0], i[k][1], 1)
					}
					else if (i[k][2])
					{
						AddWearerAttribute(player, i[k][0], i[k][1], 0)
					}
					else
					{
						player.AddCustomAttribute(i[k][0], i[k][1], 0)
					}
					k += 1
				}
			}
		}
	}
}

__CollectGameEventCallbacks(ScrewThatGuyTable)