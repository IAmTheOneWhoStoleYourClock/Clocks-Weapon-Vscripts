// This plugin was made without the assitance of AI, all stupidity is entirely on me.

IncludeScript("lib/clocksutils.nut");


if (!("durabiltylist" in getroottable())) {
	armoredplayers <- []
	engineerplayers <- []
	playercurrarmor <- array(PLAYERCAP, [])
	playerlastdamage <- array(PLAYERCAP, 0)
	playerlastregen <- array(PLAYERCAP, 0)
	basemaxhealth <- [125, 125, 200, 175, 150, 300, 175, 125, 125, 200]
	durabiltylist <- [
		// Armor, Max health, Armor Protection, Armor Ratio, Armor Damage Ratio, Armor Damage Type Ratios [Crit, Minicrit, Blast, Bullet, Fire, Melee], Armor Damage Type Protection [Crit, Minicrit, Blast, Bullet, Fire, Melee], Armor Wrench Scaling
		[50, 90, 0.25, 0.25, 1, [1,1,1,1,1,1], [1,1,1,1,1,1],1], //Scout
		[25, 95, 0.25, 0.25, 1, [1,1,1,1,1,1], [1,1,1,1,1,1],1], //Sniper
		[125, 100, 0.75, 0.625, 1, [1,1,1,1,1,1], [1,1,1,1,1,1],1], //Soldier
		[100, 90, 0.5, 0.5, 1, [1,1,1,1,1,1], [1,1,1,1,1,1],1], //Demoman
		[100, 90, 0.5, 0.5, 1, [1,1,1,1,1,1], [1,1,1,1,1,1],1],  //Medic
		[225, 100, 0.75, 1.125, 1, [1,1,1,1,1,1], [1,1,1,1,1,1],1],  //Heavy
		[150, 100, 0.5, 0.75, 1, [1,1,1,1,1,1], [1,1,1,1,1,1],1],  //Pyro
		[50, 90, 0.25, 0.25, 1, [1,1,1,1,1,1], [1,1,1,1,1,1],1],  //Spy
		[50, 90, 0.5, 0.25, 1, [1,1,1,1,1,1], [1,1,1,1,1,1],1],  //Engineer
		[100, 100, 0.75, 0.5, 1, [1,1,1,1,1,1], [1,1,1,1,1,1],1],  //Civilian
	]
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
			NetProps.SetPropInt(player, "m_ArmorValue", armor)
			player.SetContextThink("PF2NOMETAL", PF2NOMETAL, 0.1)
			armoredplayers.append(player)
		}
		else if (player in armoredplayers)
		{
			NetProps.SetPropInt(player, "m_ArmorValue", 0)
			local playerindex = armoredplayers.find(player)
			if (playerindex)
			{
				armoredplayers.remove(playerindex)
			}
		}

		player.AddCustomAttribute("max health additive bonus", durabiltylist[pc][1] - basemaxhealth[pc], 0)
		if (pc == 8)
		{
			player.AddCustomAttribute("maxammo grenades1 increased", 200, 0)
			EntFireByHandle(player, "CallScriptFunction", "EngieArmorRegen", 1, null, null)
		}
		player.ValidateScriptScope()
	}
	function OnGameEvent_ammo_pickup(params)
	{
		// The way replenishing super ammo types is handled.
		foreach(player in armoredplayers)
		{
			if (player.IsValid())
			{
				local pc = player.GetPlayerClass() - 1
				local armorhyjack = pc == 8 ? 4 : 3
				local ammohyjack = player.GetAmmoCount(armorhyjack)
				if (params.ammo_index == armorhyjack && ammohyjack > 0)
				{
					local cap = GetWearableAttribute(player, "armor cap", 0) + durabiltylist[pc][0]
					if (cap > 0)
					{
						local newarmor = ceil(min(NetProps.GetPropInt(player, "m_ArmorValue") + (ammohyjack * GetWearableAttribute(player, "mult armor ratio", 1) * durabiltylist[pc][3]),cap))
						NetProps.SetPropInt(player, "m_ArmorValue", newarmor)
						NetProps.SetPropIntArray(player, "m_iAmmo", 0, armorhyjack)
					}
					else
					{
						armoredplayers.remove(armoredplayers.find(player))
					}
				}
			}
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
				player.TakeDamageEx(scriptscope.inflictorbuffer, params.attacker, null, NULLVECTOR, NULLVECTOR, -damagereduced - 1, 0) //Deal the negative amount of the damage we want to negate... plus -1. For some reason 1, just, gets added.
				NetProps.SetPropInt(player, "m_ArmorValue", armor - (damagereduced*armorratio))
				// (hInflictor, hAttacker, hWeapon, vecDamageForce, vecDamagePosition, flDamage, nDamageType)
			}
			else // In that case, do this to prevent death weirdness.
			{
				player.SetHealth(1)
				player.TakeDamageEx(scriptscope.inflictorbuffer, params.attacker, null, NULLVECTOR, NULLVECTOR, -damagereduced - 1, 0) //Deal the negative amount of the damage we want to negate... plus -1. For some reason 1, just, gets added.
				player.SetHealth(-1)
			}
		}
		else if (!("crit" in params))
		{
			NetProps.SetPropInt(player, "m_ArmorValue", armor)
		}
	}
}

function PF2NOMETAL(self)
{
	local pc = self.GetPlayerClass() - 1
	if (pc == 8)
	{
		NetProps.SetPropIntArray(self, "m_iAmmo", 0, 4)
		self.AddCustomAttribute("maxammo grenades1 increased", 200, 0)
		if (!(self in engineerplayers))
		{
			engineerplayers.append(self)
		}
	}
	else
	{
		NetProps.SetPropIntArray(self, "m_iAmmo", 0, 3)
		self.AddCustomAttribute("maxammo metal increased", 2, 0)
		if (!(self in engineerplayers))
		{
			engineerplayers.append(self)
		}
	}
	self.AddCustomAttribute("max health additive bonus", durabiltylist[pc][1] - basemaxhealth[pc], 0)
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

function ArmorWrench()
{
	local weapon = self.GetActiveWeapon()
	local armorhit = 50 + weapon.GetAttribute("armor wrench", 0) 
	if (armorhit)
	{
		local eyeangles = AngleVectors(self.EyeAngles())
		local boxmin = Vector(-18,-18,-18) * weapon.GetAttribute("melee bounds multiplier", 1)
		local boxmax = Vector(18,18,18) * weapon.GetAttribute("melee bounds multiplier", 1)
		local trace = TraceHullComplex(self.ShootPosition(), self.ShootPosition() + (eyeangles * 48 * weapon.GetAttribute("melee range multiplier", 1)), boxmin, boxmax, self, MASK_SOLID, 0)
		if (trace.Entity() && trace.Entity().GetClassname() == "player" && trace.Entity().GetTeam() == self.GetTeam())
		{
			NetProps.SetPropInt(trace.Entity(), "m_ArmorValue", min(NetProps.GetPropInt(trace.Entity(), "m_ArmorValue") + armorhit, GetWearableAttribute(trace.Entity(), "armor cap", 0) + durabiltylist[trace.Entity().GetPlayerClass() - 1][0]))
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
	local healammount = 1
	if (Time() - lastdamage > 10)
	{
		healammount = 3
	}
	else if (Time() - lastdamage > 5)
	{
		healammount = 2
	}
	local cap = GetWearableAttribute(self, "armor cap", 0) + durabiltylist[8][0]
	local newarmor = min(NetProps.GetPropInt(self, "m_ArmorValue") + (healammount),cap)
	NetProps.SetPropInt(self, "m_ArmorValue", newarmor)
	playerlastregen[self.GetEntityIndex()] = Time()
	EntFireByHandle(self, "CallScriptFunction", "EngieArmorRegen", 1, null, null)
}

IncludeScript("lib/mapbasehookcollector.nut");