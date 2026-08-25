// This plugin was made without the assitance of AI, all stupidity is entirely on me.

IncludeScript("lib/clocksutils.nut");

armoredplayer <- []
playercurrarmor <- array(PLAYERCAP, [])

Convars.RegisterConvar("cvs_armor_base_protection", "0.8", "How much protection armor provides baseline", 0)
Convars.RegisterConvar("cvs_armor_base_ratio", "2", "How much damage it takes to consume an armor baseline", 0)

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
	function OnGameEvent_ammo_pickup(params)
	{
		// The way replenishing super ammo types is handled.
		foreach(player in armoredplayer)
		{
			if (player.IsValid())
			{
				local pc = player.GetPlayerClass() - 1
				local armorhyjack = pc != 9 ? 3 : 4
				local ammohyjack = player.GetAmmoCount(armorhyjack)
				if (params.ammo_index == armorhyjack && ammohyjack > 0)
				{
					local cap = GetWearableAttribute(player, "armor cap", 0)
					if (cap > 0)
					{
						local newarmor = min(NetProps.GetPropInt(player, "m_ArmorValue") + (ammohyjack * GetWearableAttribute(player, "mult armor ratio", 1)),cap)
						NetProps.SetPropInt(player, "m_ArmorValue", newarmor)
						NetProps.SetPropIntArray(player, "m_iAmmo", 0, 4)
					}
					else
					{
						armoredplayer.remove(armoredplayer.find(player))
					}
				}
			}
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
			printl(armorratio)
			
			// Man if only I had a switch type statement that worked with flags
			// Actually I probably do but I am too lazy to look for it
			if (scriptscope.damagetypebuffer & Constants.FDmgType.DMG_BLAST)
			{
				armorratio *= GetWearableAttribute(player, "mult armor blast ratio", 1) * 2
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
			player.TakeDamageEx(scriptscope.inflictorbuffer, params.attacker, null, NULLVECTOR, NULLVECTOR, -damagereduced - 1, 0) //Deal the negative amount of the damage we want to negate... plus -1. For some reason 1, just, gets added.
			NetProps.SetPropInt(player, "m_ArmorValue", armor - (damagereduced*armorratio))
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

function OnTakeDamage(self,info)
{
	if (self.GetClassname() == "player")
	{
		local scriptscope = self.GetOrCreatePrivateScriptScope()
		playercurrarmor[self.GetEntityIndex()] = NetProps.GetPropInt(self, "m_ArmorValue") // should probably just be in the script scope but uhhhhhh
		NetProps.SetPropInt(self, "m_ArmorValue", 0)
		scriptscope.hpbuffer <- self.GetHealth()
		scriptscope.inflictorbuffer <- info.GetInflictor()
		scriptscope.damagetypebuffer <- info.GetDamageType()
		scriptscope.weaponbuffer <- info.GetWeapon()
	}
}

IncludeScript("lib/mapbasehookcollector.nut");