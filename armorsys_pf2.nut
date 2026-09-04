// This plugin was made without the assitance of AI, all stupidity is entirely on me.

IncludeScript("lib/clocksutils.nut");

//Config loader!
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
			arrayholder.append(value.slice(1).tofloat())
		}
		else if (endswith(value,"]"))
		{
			arraymode = false
			arrayholder.append(value.slice(0,-1).tofloat())
			finishedarray.append(arrayholder)
			arrayholder=[]
		}
		else if (arraymode)
		{
			arrayholder.append(value.tofloat())
		}
		else
		{
			finishedarray.append(value.tofloat())
		}
	}
	return finishedarray
}

if (!FileExists("armorsys_pf2.cfg"))
{
	durabiltylist <- [
		// Armor, Max health, Armor Protection, Armor Ratio, Armor Damage Ratio, Armor Damage Type Ratios [Crit, Minicrit, Blast, Bullet, Fire, Melee, Self damage, Unused], Armor Damage Type Protection [Crit, Minicrit, Blast, Bullet, Fire, Melee, Self damage, Unused], Armor Wrench Scaling, Health from packs multiplier, Armor regen, Currently Unused
		[50, 90, 0.25, 0.25, 1, [1,1,1,1,1,1,1], [1,1,1,1,1,1,1],1,1,0], //Scout
		[25, 95, 0.25, 0.25, 1, [1,1,1,1,1,1,1], [1,1,1,1,1,1,1],1,1,0], //Sniper
		[125, 100, 0.75, 0.625, 1, [1,1,1,1,1,1,1], [1,1,1,1,1,1,1],1,1,0], //Soldier
		[100, 90, 0.5, 0.5, 1, [1,1,1,1,1,1,1], [1,1,1,1,1,1,1],1,1,0], //Demoman
		[100, 90, 0.5, 0.5, 1, [1,1,1,1,1,1,1], [1,1,1,1,1,1,1],1,1,0],  //Medic
		[225, 100, 0.75, 1.125, 1, [1,1,1,1,1,1,1], [1,1,1,1,1,1,1],1,1,0],  //Heavy
		[150, 100, 0.5, 0.75, 1, [1,1,1,1,1,1,1], [1,1,1,1,1,1,1],1,1,0],  //Pyro
		[50, 90, 0.25, 0.25, 1, [1,1,1,1,1,1,1], [1,1,1,1,1,1,1],1,1,0],  //Spy
		[50, 90, 0.5, 0.25, 1, [1,1,1,1,1,1,1], [1,1,1,1,1,1,1],1,1,3],  //Engineer
		[100, 100, 0.75, 0.5, 1, [1,1,1,1,1,1,1], [1,1,1,1,1,1,1],1,1,0],  //Civilian
	]
	generalstats <- [50,0,0,0,1,12,1,1,1]
	local configgenerator = "// This is the config for armorsys_pf2, Do not add or remove any lines! In the event of an update, you may need to update this! (but hopefully not!)\n"
	configgenerator += "// The classes are organized in the order of: Scout, Sniper, Soldier, Demoman, Medic, Heavy, Pyro, Spy, Engineer, Civilian\n"
	configgenerator += "// Armor, Max health, Armor Protection, Armor Ratio, Armor Damage Ratio, Armor Damage Type Ratios [Crit, Minicrit, Blast, Bullet, Fire, Melee, Self damage], Armor Damage Type Protection [Crit, Minicrit, Blast, Bullet, Fire, Melee, Self damage], Armor Wrench Scaling, Health from packs multiplier, Armor Regeneration, Currently Unused"
	foreach (i in durabiltylist)
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
				configgenerator += "1], "
			}
			else
			{
				configgenerator += k.tostring() + ", "
			}
		}
		configgenerator += "1]"
	}
	configgenerator += "\n// Now for general stats: Armor healed by wrench, Armor given by wrench scales with Armor Protection, Metal cost for giving armor, bingus, Dispenser armor check interval (in seconds), Dispsenser armor, Armor given by dispenser scales with Armor Ratio, Precentage of max armor on spawn, Currently Unused\n"
	configgenerator += "50, 0, 0, 0, 1, 12, 1, 1, 1" // Lazy so I'm hardcoding this
	StringToFile("armorsys_pf2.cfg" configgenerator)
}
else
{
	local commentlines = [13,2,1,0]
	local file = split(FileToString("armorsys_pf2.cfg"), "\n")
	foreach (i in commentlines)
	{
		file.remove(i)
	}

	generalstats <- Handlefileline(file[10])
	file.remove(10)
	durabiltylist <- []
	foreach (i in file)
	{
		durabiltylist.append(Handlefileline(strip(i).slice(1,-1)))
	}
}

if (!("playercurrarmor" in getroottable())) {
	playercurrarmor <- array(PLAYERCAP, [])
	playerlastdamage <- array(PLAYERCAP, 0)
	playerlastregen <- array(PLAYERCAP, 0)
	basemaxhealth <- [125, 125, 200, 175, 150, 300, 175, 125, 125, 200]
}

::ArmorEventTable <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ConnectOutput("OnUser1" "ArmorWrench")
	}
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		local pc = player.GetPlayerClass() - 1
		local armor = GetWearableAttribute(player, "armor cap", 0) + durabiltylist[pc][0]
		if (armor > 0)
		{
			if (armor * generalstats[7] > player.GetArmor())
			{
				player.SetArmor(armor * generalstats[7])
			}
			player.SetContextThink("PF2NOMETAL", PF2NOMETAL, 0.1)
			if (durabiltylist[pc][8] > 0)
			{
				EntFireByHandle(player, "CallScriptFunction", "EngieArmorRegen", 1, null, null)
			}
			
			if (pc == 3)
			{
				// Add an invis watch since we can't hyjack charge on demoman
				local weapon = Entities.CreateByClassname("tf_weapon_invis")
				NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 30)
				NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
				NetProps.SetPropBool(weapon, "m_bValidatedAttachedEntity", true)
				weapon.SetTeam(player.GetTeam())
				weapon.DispatchSpawn()
				player.Weapon_Equip(weapon)
			}

			if (generalstats[7] >= 1)
			{
				ToggleArmor(player, false)
			}
			else
			{
				ToggleArmor(player, true)
			}
		}

		player.AddCustomAttribute("max health additive bonus", durabiltylist[pc][1] - basemaxhealth[pc], 0)
		player.AddCustomAttribute("health from packs increased", durabiltylist[pc][1], 0)
		player.ValidateScriptScope()
	}
	function OnGameEvent_teamplay_round_active(params)
	{
		if (generalstats[3] >= 1)
		{
			// You've made a grave mistake
			Bingus()
		}
		local cart = Entities.FindByClassname(null, "mapobj_cart_dispenser")
		local prev = null
		while (cart && cart != prev)
		{
			EntFireByHandle(cart, "CallScriptFunction", "CartDispenserArmorCheck", generalstats[4], null, null)
			prev = cart
			cart = Entities.FindByClassname(null, "mapobj_cart_dispenser")
		}
	}
	function OnGameEvent_item_pickup(params)
	{
		local ammoregained = 0
		local player = GetPlayerFromUserID(params.userid)
		// Heavy's sandwich doesn't trigger this event, so I don't need to make any explict check for it.
		switch (params.item)
		{
			// If it's these three I can be pretty sure about it in 90% of cases.
			case "ammopack_small":
				// Actually SHOULD be 40, but that's a really sad amount of armor to restore tbh. I really feel like this should just be 1/4 of the ammo poll anyways but that's different topic.
				ammoregained = 50
				break;
			case "ammopack_medium":
				ammoregained = 100
				break;
			case "ammopack_large":
				ammoregained = 200
				break;
			case "tf_ammo_pack":
				// Find which ammo pack it is
				local pack = Entities.FindByClassnameWithin(null, "tf_ammo_pack", player.GetOrigin(), 250)
				local i = 0
				while (pack && !TouchingBBox(pack, player) && i < 10)
				{
					pack = Entities.FindByClassnameWithin(pack, "tf_ammo_pack", player.GetOrigin(), 250)
					i += 1
				}
				// Unfortunately I don't really have any way of getting exactly what it's supposed to be, but there are a few catch alls that generally should work.
				if (pack)
				{
					local packname = pack.GetModelName()
					// As far as I'm aware the only difference between a dropped toolbox and a toolbox made by unmaking is that they have a different body group?
					if (packname == "models/weapons/w_models/w_toolbox.mdl" && pack.GetBodygroup(1) == 1)
					{
						// Building gibs restore no armor whatsoever.
						ammoregained = 0
					}
					else if (startswith(packname, "models/weapons"))
					{
						ammoregained = 100
					}
					else if (startswith(packname, "models/buildables/gibs"))
					{
						// Building gibs restore no armor whatsoever.
						ammoregained = 0
					}
					else if (startswith(packname, "models/items/ammopack_large"))
					{
						// Okay???? just assume these are the same as their normal items
						ammoregained = 200
					}
					else if (startswith(packname, "models/items/ammopack_medium"))
					{
						ammoregained = 100
					}
					else if (startswith(packname, "models/items/ammopack_small"))
					{
						ammoregained = 50
					}
					else
					{
						// By default assume small
						ammoregained = 50
					}
				}
				break;
		}
		if (ammoregained > 0)
		{
			local pc = player.GetPlayerClass() - 1
			local cap = GetWearableAttribute(player, "armor cap", 0) + durabiltylist[pc][0]
			if (cap > 0)
			{
				local newarmor = ceil(min(player.GetArmor() + (ammoregained * GetWearableAttribute(player, "mult armor ratio", 1) * durabiltylist[pc][3]),cap))
				if (newarmor > player.GetArmor())
				{
					player.SetArmor(newarmor)
				}
				if (newarmor >= cap)
				{
					ToggleArmor(player, false)
				}
				else
				{
					ToggleArmor(player, true)
				}
			}
		}
	}
	function OnGameEvent_player_builtobject(params)
	{
		if (params.object == 0)
		{
			local entity = EntIndexToHScript(params.index)
			EntFireByHandle(entity, "CallScriptFunction", "DispenserArmorCheck", generalstats[4], null, null)
		}
	}
	function OnGameEvent_player_hurt(params)
	{
		local player = GetPlayerFromUserID(params.userid)

		playerlastdamage[player.GetEntityIndex()] = Time()

		local armor = playercurrarmor[player.GetEntityIndex()]
		if (armor > 0 && "crit" in params)
		{
			local damage = params.damageamount
			if (damage <= 0)
			{
				//Ignore
				return true
			}
			ToggleArmor(player, true)
			local pc = player.GetPlayerClass() - 1
			local scriptscope = player.GetOrCreatePrivateScriptScope()
			local armorprotection = GetWearableAttribute(player, "mult armor protection", 1) * durabiltylist[pc][2]
			local armorratio = GetWearableAttribute(player, "mult armor damage ratio", 1) * durabiltylist[pc][4]

			if (params.crit && !params.minicrit)
			{
				armorratio *= GetWearableAttribute(player, "mult armor crit ratio", 1) * durabiltylist[pc][5][0]
				armorprotection *= GetWearableAttribute(player, "mult armor crit protection", 1) * durabiltylist[pc][6][0]
			}
			else if (params.minicrit)
			{
				armorratio *= GetWearableAttribute(player, "mult armor minicrit ratio", 1) * durabiltylist[pc][5][1]
				armorprotection *= GetWearableAttribute(player, "mult armor minicrit protection", 1) * durabiltylist[pc][6][1]
			}
			
			// Man if only I had a switch type statement that worked with flags
			// Actually I probably do but I am too lazy to look for it
			if (scriptscope.damagetypebuffer & Constants.FDmgType.DMG_BLAST)
			{
				armorratio *= GetWearableAttribute(player, "mult armor blast ratio", 1) * durabiltylist[pc][5][2]
				armorprotection *= GetWearableAttribute(player, "mult armor blast protection", 1) * durabiltylist[pc][6][2]
			}
			if (scriptscope.damagetypebuffer & Constants.FDmgType.DMG_BULLET)
			{
				armorratio *= GetWearableAttribute(player, "mult armor bullet ratio", 1) * durabiltylist[pc][5][3]
				armorprotection *= GetWearableAttribute(player, "mult armor bullet protection", 1) * durabiltylist[pc][6][3]
			}
			if (scriptscope.damagetypebuffer & Constants.FDmgType.DMG_BURN)
			{
				armorratio *= GetWearableAttribute(player, "mult armor fire ratio", 1) * durabiltylist[pc][5][4]
				armorprotection *= GetWearableAttribute(player, "mult armor fire protection", 1) * durabiltylist[pc][6][4]
			}
			if (scriptscope.damagetypebuffer & Constants.FDmgType.DMG_CLUB)
			{
				armorratio *= GetWearableAttribute(player, "mult armor melee ratio", 1) * durabiltylist[pc][5][5]
				armorprotection *= GetWearableAttribute(player, "mult armor melee protection", 1) * durabiltylist[pc][6][5]
			}

			if (GetPlayerFromUserID(params.attacker) == player)
			{
				armorratio *= GetWearableAttribute(player, "mult armor self ratio", 1) * durabiltylist[pc][5][6]
				armorprotection *= GetWearableAttribute(player, "mult armor self protection", 1) * durabiltylist[pc][6][6]
			}

			if (scriptscope.weaponbuffer)
			{
				armorratio *= scriptscope.weaponbuffer.GetAttribute("mult damage to armor", 1)
				armorprotection *= scriptscope.weaponbuffer.GetAttribute("mult armor pierce", 1)
				armorprotection += scriptscope.weaponbuffer.GetAttribute("armor pierce flat", 0)
			}

			local damagereduced = floor(min(damage*armorprotection, armor/armorratio))
			local remaining = armor - (damagereduced*armorratio)
			if ((scriptscope.hpbuffer - (damage - damagereduced)) > 0) // If false, we are dead regardless of the armor. RIP.
			{
				// Deal negative damage so the attacker still gets the right damage number. Hopefully.
				player.TakeDamageEx(scriptscope.inflictorbuffer, params.attacker, null, NULLVECTOR, player.GetOrigin() + Vector(0,0,16), -damagereduced - 1, 0) //Deal the negative amount of the damage we want to negate... plus -1. For some reason 1, just, gets added.
				player.SetArmor(armor - (damagereduced*armorratio))
				// (hInflictor, hAttacker, hWeapon, vecDamageForce, vecDamagePosition, flDamage, nDamageType)
			}
			else // In that case, do this to prevent death weirdness.
			{
				player.SetHealth(100)
				NetProps.SetPropInt(player, "m_lifeState", 0)
				player.TakeDamageCustom(scriptscope.inflictorbuffer, params.attacker, null, NULLVECTOR, player.GetOrigin() + Vector(0,0,16), -damagereduced - 1, 0, 27) // Do Rune Reflect Type Damage. Don't question it, this works.
				player.SetHealth(0)
				NetProps.SetPropInt(player, "m_lifeState", 2)
			}
		}
		else if (!("crit" in params))
		{
			player.SetArmor(armor)
		}
	}
}

function PF2NOMETAL(self)
{
	local pc = self.GetPlayerClass() - 1
	self.AddCustomAttribute("max health additive bonus", durabiltylist[pc][1] - basemaxhealth[pc], 0)
	ToggleArmor(self, true)
}

function ToggleArmor(player, state)
{
	local pc = player.GetPlayerClass() - 1
	if (state)
	{
		if (pc == 3)
		{
			player.SetSpyCloakMeter(99)
		}
		else
		{
			player.AddCustomAttribute("ammo gives charge", 1, 0)
			NetProps.SetPropFloat(player, "m_Shared.m_flChargeMeter", 99)
		}
	}
	else
	{
		if (pc == 3)
		{
			player.SetSpyCloakMeter(100)
		}
		else
		{
			player.AddCustomAttribute("ammo gives charge", 0, 0)
			NetProps.SetPropFloat(player, "m_Shared.m_flChargeMeter", 99)
		}
	}
}

__CollectGameEventCallbacks(ArmorEventTable)

function OnTakeDamage(self,info)
{
	info.GetDamageCustom()
	if (self.GetClassname() == "player")
	{
		local scriptscope = self.GetOrCreatePrivateScriptScope()
		playercurrarmor[self.GetEntityIndex()] = self.GetArmor() // should probably just be in the script scope but uhhhhhh
		self.SetArmor(0)
		scriptscope.hpbuffer <- self.GetHealth()
		scriptscope.inflictorbuffer <- info.GetAttacker()
		scriptscope.damagetypebuffer <- info.GetDamageType()
		scriptscope.weaponbuffer <- info.GetWeapon()
	}
}

function ArmorWrench()
{
	local weapon = self.GetActiveWeapon()
	local armorhit = generalstats[0] + weapon.GetAttribute("armor wrench", 0) 
	if (armorhit && weapon.GetClassname() == "tf_weapon_wrench")
	{
		local eyeangles = AngleVectors(self.EyeAngles())
		local boxmin = Vector(-18,-18,-18) * weapon.GetAttribute("melee bounds multiplier", 1)
		local boxmax = Vector(18,18,18) * weapon.GetAttribute("melee bounds multiplier", 1)
		local trace = TraceHullComplex(self.ShootPosition(), self.ShootPosition() + (eyeangles * 48 * weapon.GetAttribute("melee range multiplier", 1)), boxmin, boxmax, self, MASK_SOLID, 0)
		if (trace.Entity() && trace.Entity().GetClassname() == "player" && trace.Entity().GetTeam() == self.GetTeam())
		{
			local hitplayer = trace.Entity()
			local pc = hitplayer.GetPlayerClass() - 1
			if (generalstats[1])
			{
				armorhit *=  GetWearableAttribute(hitplayer, "mult armor protection", 1) * durabiltylist[pc][2]
			}
			local oldarmor = hitplayer.GetArmor()
			local newarmor = min(oldarmor + (armorhit * durabiltylist[pc][7]), GetWearableAttribute(hitplayer, "armor cap", 0) + durabiltylist[pc][0])
			local metalperarmor = generalstats[2] * GetWearableAttribute(self, "armor wrench ratio", 1)
			if (newarmor > oldarmor)
			{
				hitplayer.SetArmor(newarmor)
				if (metalperarmor > 0)
				{
					NetProps.SetPropIntArray(self, "m_iAmmo", floor(NetProps.GetPropIntArray(self, "m_iAmmo", 3) - ((newarmor-oldarmor) * metalperarmor)), 3)
				}
			}
		}
	}
}

function DispenserArmorCheck()
{
	EntFireByHandle(self, "CallScriptFunction", "DispenserArmorCheck", generalstats[4], null, null)
	if (NetProps.GetPropFloat(self,"m_flPercentageConstructed") >= 1 && NetProps.GetPropFloat(self,"m_flUpgradeCompleteTime") < Time() && NetProps.GetPropFloat(self,"m_flUpgradeCompleteTime"))
	{
		local rangescale = GetWearableAttribute(NetProps.GetPropEntity(self,"m_hBuilder"), "engy dispenser radius increased", 1)
		local BBox = Vector(64,64,64) * rangescale
		local player = Entities.FindByClassnameWithinBox(null, "player", -BBox + self.GetOrigin(), BBox + self.GetOrigin())
		local prev = null
		while (player && player != prev)
		{
			if (player.GetTeam() == self.GetTeam())
			{
				local pc = player.GetPlayerClass() - 1
				local cap = GetWearableAttribute(player, "armor cap", 0) + durabiltylist[pc][0]
				if (cap > 0)
				{
					local newarmor = 0
					if (generalstats[5])
					{
						newarmor = ceil(min(player.GetArmor() + (generalstats[5] * GetWearableAttribute(player, "mult armor ratio", 1) * durabiltylist[pc][3]),cap))
					}
					else
					{
						newarmor = ceil(min(player.GetArmor() + (generalstats[5]),cap))
					}
					if (newarmor > player.GetArmor())
					{
						player.SetArmor(newarmor)
					}
					if (newarmor >= cap)
					{
						ToggleArmor(player, false)
					}
					else
					{
						ToggleArmor(player, true)
					}
				}
			}
			prev = player
			player = Entities.FindByClassnameWithinBox(player, "player", -BBox + self.GetOrigin(), BBox + self.GetOrigin())
		}
	}
}

function CartDispenserArmorCheck()
{
	EntFireByHandle(self, "CallScriptFunction", "CartDispenserArmorCheck", generalstats[4], null, null)
	if (PointsMayBeCaptured && !NetProps.GetPropInt(self,"m_bDisabled"))
	{
		local BBox = Vector(128,128,64)
		local player = Entities.FindByClassnameWithinBox(null, "player", -BBox + self.GetOrigin(), BBox + self.GetOrigin())
		local prev = null
		while (player && player != prev)
		{
			// Assume The map maker isn't doing cursed garbage cause I CAN'T ACCOUNT FOR THAT!!!!
			if (player.GetTeam() == self.GetTeam() && Entities.FindByClassnameNearest("trigger_capture_area", self.GetOrigin(), 100000000000).IsTouching(player))
			{
				local pc = player.GetPlayerClass() - 1
				local cap = GetWearableAttribute(player, "armor cap", 0) + durabiltylist[pc][0]
				if (cap > 0)
				{
					local newarmor = 0
					if (generalstats[5])
					{
						newarmor = ceil(min(player.GetArmor() + (generalstats[5] * GetWearableAttribute(player, "mult armor ratio", 1) * durabiltylist[pc][3]),cap))
					}
					else
					{
						newarmor = ceil(min(player.GetArmor() + (generalstats[5]),cap))
					}
					if (newarmor > player.GetArmor())
					{
						player.SetArmor(newarmor)
					}
					if (newarmor >= cap)
					{
						ToggleArmor(player, false)
					}
					else
					{
						ToggleArmor(player, true)
					}
				}
			}
			prev = player
			player = Entities.FindByClassnameWithinBox(player, "player", -BBox + self.GetOrigin(), BBox + self.GetOrigin())
		}
	}
}

function EngieArmorRegen()
{
	if (!self.IsValid() || !self.IsAlive() || self.GetPlayerClass() != 9 || Time() - playerlastregen[self.GetEntityIndex()] < 1)
	{
		return
	}
	local lastdamage = playerlastdamage[self.GetEntityIndex()]
	local healammount = 0
	local pc = self.GetPlayerClass() - 1
	if (Time() - lastdamage > 12)
	{
		healammount = durabiltylist[pc][8]
	}
	else if (Time() - lastdamage > 7)
	{
		healammount = ceil(durabiltylist[pc][8] / 2)
	}
	else if (Time() - lastdamage > 2)
	{
		healammount = ceil(durabiltylist[pc][8] / 3)
	}
	if (healammount > 0)
	{
		local cap = GetWearableAttribute(self, "armor cap", 0) + durabiltylist[pc][0]
		local newarmor = min(NetProps.GetPropInt(self, "m_ArmorValue") + (healammount),cap)
		NetProps.SetPropInt(self, "m_ArmorValue", newarmor)
		playerlastregen[self.GetEntityIndex()] = Time()
	}
	EntFireByHandle(self, "CallScriptFunction", "EngieArmorRegen", 1, null, null)
}

function TouchingBBox(ent1, ent2)
{
	// Okay so, let me be clear. THIS IS HORRENDOUS!
	// DO. NOT. DO. THIS.
	// Unfortunately, due to, persumably, an issue in how the origin is reported, this is, in fact, 100% nessesary. FOR THIS SPECIFIC SENARIO.
	// THIS IS THE WRONG WAY TO DO THIS!
	// BIG RED X!
	// Yes I need this again yes I hate it again I HATE IT HERE!
	// Okay anyways

	local bboxmax1 = ent1.GetBoundingMaxs()
	local bboxmin1 = ent1.GetBoundingMins()

	local bboxmax2 = ent2.GetBoundingMaxs()
	local bboxmin2 = ent2.GetBoundingMins()
	
	// Look back through all of the entities to find one that's in a bounding box created like... that.
	// The math reason i'm doing that is because if a box calculated as such contains the origin, the boxes should intersect.
	local entity = Entities.FindByClassnameWithinBox(null, "player", bboxmin1 - bboxmax2 + ent1.GetOrigin(), bboxmax1 - bboxmin2 + ent1.GetOrigin())
	local start = entity
	local ran = false
	while (entity != null && entity != ent2 && (entity != start || !ran))
	{
		entity = Entities.FindByClassnameWithinBox(entity, "player", bboxmin1 - bboxmax2 + ent1.GetOrigin(), bboxmax1 - bboxmin2 + ent1.GetOrigin())
		ran = true
	}

	// If we've found an entity in that box that is the one we are looking for, great job! It's in it!
	if (entity == ent2)
	{
		return true
	}

	else
	{
		return false
	}
}

IncludeScript("lib/mapbasehookcollector.nut");