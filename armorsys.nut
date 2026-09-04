// This plugin was made without the assitance of AI, all stupidity is entirely on me.

IncludeScript("lib/clocksutils.nut");

armoredplayer <- []
playercurrarmor <- array(PLAYERCAP, [])

Convars.RegisterConvar("cvs_armor_base_protection", "0.8", "How much protection armor provides baseline", 0)
Convars.RegisterConvar("cvs_armor_base_ratio", "2", "How much damage it takes to consume an armor baseline", 0)
Convars.RegisterConvar("cvs_armor_explosive_weakness", "2", "How much more damage explosives do to armor", 0)

::ArmorEventTable <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ValidateScriptScope()
	}
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		local armor = GetWearableAttribute(player, "armor cap", 0)
		if (armor > 0)
		{
			NetProps.SetPropInt(player, "m_ArmorValue", armor)
			player.SetContextThink("NOMETAL", NOMETAL, 0.1)
			armoredplayer.append(player)
			if (player.GetPlayerClass() == 9) // Engineer get grenades 1 overriden instead... because he regenerates that from ammo for some reason.
			{
				player.AddCustomAttribute("maxammo grenades1 increased", 200, 0)
			}
		}
		else if (player in armoredplayer)
		{
			NetProps.SetPropInt(player, "m_ArmorValue", 0)
			local playerindex = armoredplayer.find(player)
			if (playerindex)
			{
				armoredplayer.remove(playerindex)
			}
		}
	}
	function OnGameEvent_item_pickup(params)
	{
		// The way replenishing super ammo types is handled.
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
			local player = GetPlayerFromUserID(params.userid)
			local cap = GetWearableAttribute(player, "armor cap", 0)
			if (cap > 0)
			{
				local newarmor = ceil(min(NetProps.GetPropInt(player, "m_ArmorValue") + (ammoregained * GetWearableAttribute(player, "mult armor ratio", 1)),cap))
				NetProps.SetPropInt(player, "m_ArmorValue", newarmor)
			}
			else
			{
				armoredplayer.remove(armoredplayers.find(player))
			}
		}
	}
	function OnGameEvent_teamplay_round_active(params)
	{
		local cart = Entities.FindByClassname(null, "mapobj_cart_dispenser")
		local prev = null
		while (cart && cart != prev)
		{
			EntFireByHandle(cart, "CallScriptFunction", "CartDispenserArmorCheck", generalstats[4], null, null)
			prev = cart
			cart = Entities.FindByClassname(null, "mapobj_cart_dispenser")
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
		local armor = playercurrarmor[player.GetEntityIndex()]
		if (armor > 0)
		{
			local damage = params.damageamount
			local scriptscope = player.GetOrCreatePrivateScriptScope()
			if (damage <= 0)
			{
				//Why?
				return false
			}
			local armorprotection = GetWearableAttribute(player, "mult armor protection", 1) * Convars.GetFloat("cvs_armor_base_protection")
			local armorratio = GetWearableAttribute(player, "mult armor damage ratio", 1) * 1/Convars.GetFloat("cvs_armor_base_ratio") // Doing the console command the other way around makes more sense... I think.
			
			// Man if only I had a switch type statement that worked with flags
			// Actually I probably do but I am too lazy to look for it
			if (scriptscope.damagetypebuffer & Constants.FDmgType.DMG_BLAST)
			{
				armorratio *= GetWearableAttribute(player, "mult armor blast ratio", 1) * Convars.GetFloat("cvs_armor_explosive_weakness")
				armorprotection *= GetWearableAttribute(player, "mult armor blast protection", 1)
			}
			if (scriptscope.damagetypebuffer & Constants.FDmgType.DMG_BULLET)
			{
				armorratio *= GetWearableAttribute(player, "mult armor bullet ratio", 1)
				armorprotection *= GetWearableAttribute(player, "mult armor bullet protection", 1)
			}
			if (scriptscope.damagetypebuffer & Constants.FDmgType.DMG_BURN)
			{
				armorratio *= GetWearableAttribute(player, "mult armor fire ratio", 1)
				armorprotection *= GetWearableAttribute(player, "mult armor fire protection", 1)
			}
			if (scriptscope.damagetypebuffer & Constants.FDmgType.DMG_CLUB)
			{
				armorratio *= GetWearableAttribute(player, "mult armor melee ratio", 1)
				armorprotection *= GetWearableAttribute(player, "mult armor melee protection", 1)
			}

			if (params.crit && !params.minicrit)
			{
				armorratio *= GetWearableAttribute(player, "mult armor crit ratio", 1)
				armorprotection *= GetWearableAttribute(player, "mult armor crit protection", 1)
			}
			else if (params.minicrit)
			{
				armorratio *= GetWearableAttribute(player, "mult armor minicrit ratio", 1)
				armorprotection *= GetWearableAttribute(player, "mult armor minicrit protection", 1)
			}

			if (scriptscope.weaponbuffer)
			{
				armorratio *= scriptscope.weaponbuffer.GetAttribute("mult damage to armor", 1)
				armorprotection *= scriptscope.weaponbuffer.GetAttribute("mult armor pierce", 1)
				armorprotection += scriptscope.weaponbuffer.GetAttribute("armor pierce flat", 0)
			}

			local damagereduced = floor(min(damage*armorprotection, armor/armorratio))
			local remaining = armor - (damagereduced*armorratio)

			// Deal negative damage so the attacker still gets the right damage number. Hopefully.
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
			// (hInflictor, hAttacker, hWeapon, vecDamageForce, vecDamagePosition, flDamage, nDamageType)
		}
	}
}

function NOMETAL(self)
{
	local pc = self.GetPlayerClass() - 1
	if (pc == 8)
	{
		NetProps.SetPropIntArray(self, "m_iAmmo", 0, 4)
		self.AddCustomAttribute("maxammo grenades1 increased", 200, 0)
	}
	else
	{
		NetProps.SetPropIntArray(self, "m_iAmmo", 0, 3)
		self.AddCustomAttribute("maxammo metal increased", 2, 0)
	}
}

__CollectGameEventCallbacks(ArmorEventTable)

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

function OnTakeDamage(self,info)
{
	if (self.GetClassname() == "player")
	{
		local scriptscope = self.GetOrCreatePrivateScriptScope()
		playercurrarmor[self.GetEntityIndex()] = NetProps.GetPropInt(self, "m_ArmorValue") // should probably just be in the script scope but uhhhhhh
		NetProps.SetPropInt(self, "m_ArmorValue", 0)
		scriptscope.hpbuffer <- self.GetHealth()
		scriptscope.inflictorbuffer <- info.GetAttacker()
		scriptscope.damagetypebuffer <- info.GetDamageType()
		scriptscope.weaponbuffer <- info.GetWeapon()
	}
}

IncludeScript("lib/mapbasehookcollector.nut");