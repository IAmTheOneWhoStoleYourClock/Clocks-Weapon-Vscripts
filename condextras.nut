// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

IncludeScript("lib/clocksutils.nut")

BUILDINGS <- ["obj_sentrygun", "obj_dispenser", "obj_teleporter"]

::CondExtrasEventTable <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ValidateScriptScope()
	}
	function OnGameEvent_player_death(params)
	{
		local player = GetPlayerFromUserID(params.attacker)
		if (!player || !player.IsPlayer() || !("weapon_def_index" in params))
		{
			return
		}
		local weapon = GetWeaponByDefIndex(player, params.weapon_def_index) // litterally just for this
		if (!weapon)
		{
			return
		}
		local extrakillcond = weapon.GetAttribute("add condition on kill extra", 0).tointeger()
		if (extrakillcond)
		{
			GetPlayerFromUserID(params.userid).AddCondEx(extrahitselfcond, weapon.GetAttribute("add condition on kill extra time", 0), player)
		}
	}
	function OnGameEvent_npc_hurt(params)
	{
		local player = GetPlayerFromUserID(params.attacker_player)
		local building = EntIndexToHScript(params.entindex)
		if (!player || !player.IsPlayer() || !building || (BUILDINGS.find(building.GetClassname()) == null))
		{
			return
		}
		local weapon = GetWeaponByClassID(player, params.weaponid)
		if (!weapon)
		{
			return
		}
		local disabletime = weapon.GetAttribute("disable buildings on hit", 0)
		if (disabletime)
		{
			NetProps.SetPropInt(building, "m_bDisabled", 1)
			local scriptscope = building.GetOrCreatePrivateScriptScope()
			if (!("disabletime" in scriptscope))
			{
				scriptscope.disabletime <- Time() + disabletime
			}
			else
			{
				scriptscope.disabletime <- max(scriptscope.disabletime, Time() + disabletime)
			}
			NetProps.SetPropInt(building, "m_bDisabled", 1)
			EntFireByHandle(building, "CallScriptFunction", "BuildingReenable", disabletime, null, null)
		}
	}
	function OnGameEvent_player_hurt(params)
	{
		local player = GetPlayerFromUserID(params.attacker)
		local self = GetPlayerFromUserID(params.userid)
		if (!player || !player.IsPlayer() || !self || !self.IsPlayer() || !("weaponid" in params))
		{
			return
		}
		local weapon = GetWeaponByClassID(player, params.weaponid)
		if (!weapon)
		{
			return
		}

		local extrahitcondscale = weapon.GetAttribute("add condition on hit weapon scale", 0).tointeger()
		if (extrahitcondscale)
		{
			local min = weapon.GetAttribute("add condition on hit weapon scale time min", 0)
			if (params.damageamount >= min)
			{
				local max = weapon.GetAttribute("add condition on hit weapon scale time max", 0)
				local scale = clamp((params.damageamount - min)/(max - min),0.25,1)
				self.AddCondEx(extrahitcondscale, weapon.GetAttribute("add condition on hit weapon scale time", 0)*scale, player)
			}
		}
		local extrahitselfcondscale = weapon.GetAttribute("add condition on hit self weapon scale", 0).tointeger()
		if (extrahitselfcondscale)
		{
			local min = weapon.GetAttribute("add condition on hit self weapon scale time min", 0)
			if (params.damageamount >= min)
			{
				local max = weapon.GetAttribute("add condition on hit self weapon scale time max", 0)
				local scale = clamp((params.damageamount - min)/(max - min),0.25,1)
				player.AddCondEx(extrahitselfcondscale, weapon.GetAttribute("add condition on hit self weapon scale time", 0) * scale, player)
			}
		}

		local extrahitcondscaleaccumulate = weapon.GetAttribute("add condition on hit weapon scale accumulate", 0)
		if (extrahitcondscaleaccumulate)
		{
			local mintime = weapon.GetAttribute("add condition on hit weapon scale accumulate time min", 0)
			if (params.damageamount >= mintime)
			{
				local maxtime = weapon.GetAttribute("add condition on hit weapon scale accumulate time max", 0)
				local scale = clamp((params.damageamount - mintime)/(maxtime - mintime),0.25,1)
				self.AddCondEx(extrahitcondscaleaccumulate, min(weapon.GetAttribute("add condition on hit weapon scale accumulate time", 0)*scale + self.GetCondDuration(extrahitcondscaleaccumulate), weapon.GetAttribute("add condition on hit weapon scale accumulate cap", 0)), player)
			}
		}
		local extrahitselfcondscaleaccumulate = weapon.GetAttribute("add condition on hit self weapon scale accumulate", 0)
		if (extrahitselfcondscaleaccumulate)
		{
			local mintime = weapon.GetAttribute("add condition on hit self weapon scale accumulate time min", 0)
			if (params.damageamount >= mintime)
			{
				local maxtime = weapon.GetAttribute("add condition on hit self weapon scale accumulate time max", 0)
				local scale = clamp((params.damageamount - mintime)/(maxtime - mintime),0.25,1)
				player.AddCondEx(extrahitselfcondscaleaccumulate, min(weapon.GetAttribute("add condition on hit self weapon scale accumulate time", 0)*scale + player.GetCondDuration(extrahitselfcondscaleaccumulate), weapon.GetAttribute("add condition on hit self weapon scale accumulate cap", 0)), player)
			}
		}
		
		local addcondcrit = weapon.GetAttribute("add condition on crit weapon", 0).tointeger()
		// params.bonuseffect is broken in TF2C it seems...
		if (addcondcrit && params.crit && !params.minicrit)
		{
			self.AddCondEx(addcondcrit, weapon.GetAttribute("add condition on crit time weapon", 0), player)
		}
		local addcondcritself = weapon.GetAttribute("add condition on crit self weapon", 0).tointeger()
		if (addcondcritself && params.crit && !params.minicrit)
		{
			player.AddCondEx(addcondcritself, weapon.GetAttribute("add condition on crit self time weapon", 0), player)
		}
		local addcondminicrit = weapon.GetAttribute("add condition on minicrit weapon", 0).tointeger()
		if (addcondminicrit && params.minicrit)
		{
			self.AddCondEx(addcondminicrit, weapon.GetAttribute("add condition on minicrit time weapon", 0), player)
		}
		local addcondminicritself = weapon.GetAttribute("add condition on minicrit self weapon", 0).tointeger()
		if (addcondminicritself && params.minicrit)
		{
			player.AddCondEx(addcondminicritself, weapon.GetAttribute("add condition on minicrit self time weapon", 0), player)
		}


		for (local i = 0; i < MAXWEAPONS; i++)
		{
			local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (held_weapon == null)
				continue
			PlayerHurtWearer(held_weapon,params)
		}
		local wd = 0
		for (local wearable = player.FirstMoveChild(); wearable != null && wd < 50; wearable = wearable.NextMovePeer())
		{
			wd += 1
			if (wearable.GetClassname() != "tf_wearable")
				continue
			PlayerHurtWearer(wearable,params)
		}
	}
}

__CollectGameEventCallbacks(CondExtrasEventTable)

function PlayerHurtWearer(weapon,params)
{
	local player = GetPlayerFromUserID(params.attacker)
	local self = GetPlayerFromUserID(params.userid)
	local extrahitcondscale = weapon.GetAttribute("add condition on hit scale", 0).tointeger()
	if (extrahitcondscale)
	{
		local min = weapon.GetAttribute("add condition on hit scale time min", 0)
		if (params.damageamount >= min)
		{
			local max = weapon.GetAttribute("add condition on hit scale time max", 0)
			local scale = clamp((params.damageamount - min)/(max - min),0.25,1)
			self.AddCondEx(extrahitcondscale, weapon.GetAttribute("add condition on hit scale time", 0)*scale, player)
		}
	}
	local extrahitselfcondscale = weapon.GetAttribute("add condition on hit self scale", 0).tointeger()
	if (extrahitselfcondscale)
	{
		local min = weapon.GetAttribute("add condition on hit self scale time min", 0)
		if (params.damageamount >= min)
		{
			local max = weapon.GetAttribute("add condition on hit self scale time max", 0)
			local scale = clamp((params.damageamount - min)/(max - min),0.25,1)
			player.AddCondEx(extrahitselfcondscale, weapon.GetAttribute("add condition on hit self scale time", 0) * scale, player)
		}
	}

	local extrahitcondscaleaccumulate = weapon.GetAttribute("add condition on hit scale accumulate", 0)
	if (extrahitcondscaleaccumulate)
	{
		local mintime = weapon.GetAttribute("add condition on hit scale accumulate time min", 0)
		if (params.damageamount >= mintime)
		{
			local maxtime = weapon.GetAttribute("add condition on hit scale accumulate time max", 0)
			local scale = clamp((params.damageamount - mintime)/(maxtime - mintime),0.25,1)
			self.AddCondEx(extrahitcondscaleaccumulate, min(weapon.GetAttribute("add condition on hit scale accumulate time", 0)*scale + self.GetCondDuration(extrahitcondscaleaccumulate), weapon.GetAttribute("add condition on hit scale accumulate cap", 0)), player)
		}
	}
	local extrahitselfcondscaleaccumulate = weapon.GetAttribute("add condition on hit self scale accumulate", 0)
	if (extrahitselfcondscaleaccumulate)
	{
		local mintime = weapon.GetAttribute("add condition on hit self scale accumulate time min", 0)
		if (params.damageamount >= mintime)
		{
			local maxtime = weapon.GetAttribute("add condition on hit self scale accumulate time max", 0)
			local scale = clamp((params.damageamount - mintime)/(maxtime - mintime),0.25,1)
			player.AddCondEx(extrahitselfcondscaleaccumulate, min(weapon.GetAttribute("add condition on hit self scale accumulate time", 0)*scale + player.GetCondDuration(extrahitselfcondscaleaccumulate), weapon.GetAttribute("add condition on hit self scale accumulate cap", 0)), player)
		}
	}
	
	local addcondcrit = weapon.GetAttribute("add condition on crit weapon", 0).tointeger()
	// params.bonuseffect is broken in TF2C it seems...
	if (addcondcrit && params.crit && !params.minicrit)
	{
		self.AddCondEx(addcondcrit, weapon.GetAttribute("add condition on crit weapon time", 0), player)
	}
	local addcondcritself = weapon.GetAttribute("add condition on crit self weapon", 0).tointeger()
	if (addcondcritself && params.crit && !params.minicrit)
	{
		player.AddCondEx(addcondcritself, weapon.GetAttribute("add condition on crit self weapon time", 0), player)
	}
	local addcondminicrit = weapon.GetAttribute("add condition on minicrit weapon", 0).tointeger()
	if (addcondminicrit && params.minicrit)
	{
		self.AddCondEx(addcondminicrit, weapon.GetAttribute("add condition on minicrit weapon time", 0), player)
	}
	local addcondminicritself = weapon.GetAttribute("add condition on minicrit self weapon", 0).tointeger()
	if (addcondminicritself && params.minicrit)
	{
		player.AddCondEx(addcondminicritself, weapon.GetAttribute("add condition on minicrit self weapon time", 0), player)
	}
}

function OnTakeDamage(self,info)
{
	if (!self.IsPlayer() || info.GetAttacker() == self || !info.GetWeapon())
	{
		return
	}
	local weapon = info.GetWeapon()
	// The cooldown conds share a timer
	local lastcond = weapon.GetContext("LastCond")
	if (lastcond == "")
	{
		lastcond = 0
	}
	else
	{
		lastcond = lastcond.tofloat()
	}
	local extrahitcond = weapon.GetAttribute("add condition on hit weapon extra", 0).tointeger()
	if (extrahitcond)
	{
		self.AddCondEx(extrahitcond, weapon.GetAttribute("add condition on hit weapon extra time", 0), info.GetAttacker())
	}
	local extrahitselfcond = weapon.GetAttribute("add condition on hit self weapon extra", 0).tointeger()
	if (extrahitselfcond)
	{
		info.GetAttacker().AddCondEx(extrahitselfcond, weapon.GetAttribute("add condition on hit self weapon extra time", 0), info.GetAttacker())
	}

	local hitcondcooldown = weapon.GetAttribute("add condition on hit weapon cooldown", 0)
	if (hitcondcooldown && Time() > lastcond + hitcondcooldown)
	{
		self.AddCondEx(weapon.GetAttribute("add condition on hit weapon cooldown cond", 0).tointeger(), weapon.GetAttribute("add condition on hit weapon cooldown time", 0), info.GetAttacker())
		weapon.AddContext("LastCond", Time().tostring(), 0)
	}
	local hitselfcondcooldown = weapon.GetAttribute("add condition on hit self weapon cooldown", 0)
	if (hitselfcondcooldown && Time() > lastcond + hitselfcondcooldown)
	{
		self.AddCondEx(weapon.GetAttribute("add condition on hit self weapon cooldown cond", 0).tointeger(), weapon.GetAttribute("add condition on hit self weapon cooldown time", 0), info.GetAttacker())
		weapon.AddContext("LastCond", Time().tostring(), 0)
	}
	local wet = weapon.GetAttribute("moisten on hit weapon", 0)
	if (wet && NetProps.GetPropInt(self, "m_nWaterLevel") ==  0)
	{
		NetProps.SetPropInt(self, "m_nWaterLevel", wet)
	}

	local accumulatehitcond = weapon.GetAttribute("add condition on hit weapon accumulate", 0).tointeger()
	if (accumulatehitcond)
	{
		self.AddCondEx(accumulatehitcond, max(weapon.GetAttribute("add condition on hit weapon accumulate time", 0) + self.GetCondDuration(accumulatehitcond), weapon.GetAttribute("add condition on hit weapon accumulate cap", 0)), info.GetAttacker())
	}
	local accumulateselfcond = weapon.GetAttribute("add condition on hit self weapon accumulate", 0).tointeger()
	if (accumulateselfcond)
	{
		info.GetAttacker().AddCondEx(accumulateselfcond, max(weapon.GetAttribute("add condition on hit self weapon accumulate time", 0) + self.GetCondDuration(accumulateselfcond), weapon.GetAttribute("add condition on hit self weapon accumulate cap", 0)), info.GetAttacker())
	}

	local accumulatehitbleed = weapon.GetAttribute("bleed on hit weapon accumulate cap", 0)
	if (accumulatehitbleed && info.GetDamageCustom() != 34)
	{
		local duration = (min(weapon.GetAttribute("bleed on hit weapon accumulate time", 0) + self.GetCondDuration(25), accumulatehitbleed))
		weapon.AddAttribute("bleeding duration",duration,0)
		self.AddCondEx(25, duration, info.GetAttacker())
	}
	else if (accumulatehitbleed)
	{
		weapon.AddAttribute("bleeding duration",0,0)
	}

	for (local i = 0; i < MAXWEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(info.GetAttacker(), "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		OnTakeDamageWearer(self,info,held_weapon)
	}
	local wd = 0
	for (local wearable = self.FirstMoveChild(); wearable != null && wd < 50; wearable = wearable.NextMovePeer())
	{
		wd += 1
		if (wearable.GetClassname() != "tf_wearable")
			continue
		OnTakeDamageWearer(self,info,wearable)
	}
}

function OnTakeDamageWearer(self,info,weapon)
{
	// The cooldown conds share a timer
	local lastcond = weapon.GetContext("LastCondWearer")
	if (lastcond == "")
	{
		lastcond = 0
	}
	else
	{
		lastcond = lastcond.tofloat()
	}
	local extrahitcond = weapon.GetAttribute("add condition on hit extra", 0).tointeger()
	if (extrahitcond)
	{
		self.AddCondEx(extrahitcond, weapon.GetAttribute("add condition on hit extra time", 0), info.GetAttacker())
	}
	local extrahitselfcond = weapon.GetAttribute("add condition on hit self extra", 0).tointeger()
	if (extrahitselfcond)
	{
		info.GetAttacker().AddCondEx(extrahitselfcond, weapon.GetAttribute("add condition on hit self extra time", 0), info.GetAttacker())
	}

	local hitcondcooldown = weapon.GetAttribute("add condition on hit cooldown", 0)
	if (hitcondcooldown && Time() > lastcond + hitcondcooldown)
	{
		self.AddCondEx(weapon.GetAttribute("add condition on hit cooldown cond", 0).tointeger(), weapon.GetAttribute("add condition on hit cooldown time", 0), info.GetAttacker())
		weapon.AddContext("LastCondWearer", Time().tostring(), 0)
	}
	local hitselfcondcooldown = weapon.GetAttribute("add condition on hit self cooldown", 0)
	if (hitselfcondcooldown && Time() > lastcond + hitselfcondcooldown)
	{
		self.AddCondEx(weapon.GetAttribute("add condition on hit self cooldown cond", 0).tointeger(), weapon.GetAttribute("add condition on hit self cooldown time", 0), info.GetAttacker())
		weapon.AddContext("LastCondWearer", Time().tostring(), 0)
	}
	local wet = weapon.GetAttribute("moisten on hit", 0)
	if (wet && NetProps.GetPropInt(self, "m_nWaterLevel") ==  0)
	{
		NetProps.SetPropInt(self, "m_nWaterLevel", wet)
	}

	local accumulatehitcond = weapon.GetAttribute("add condition on hit accumulate", 0).tointeger()
	if (accumulatehitcond)
	{
		self.AddCondEx(accumulatehitcond, max(weapon.GetAttribute("add condition on hit accumulate time", 0) + self.GetCondDuration(accumulatehitcond), weapon.GetAttribute("add condition on hit accumulate cap", 0)), info.GetAttacker())
	}
	local accumulateselfcond = weapon.GetAttribute("add condition on hit self accumulate", 0).tointeger()
	if (accumulateselfcond)
	{
		info.GetAttacker().AddCondEx(accumulateselfcond, max(weapon.GetAttribute("add condition on hit self accumulate time", 0) + self.GetCondDuration(accumulateselfcond), weapon.GetAttribute("add condition on hit self accumulate cap", 0)), info.GetAttacker())
	}

	local accumulatehitbleed = weapon.GetAttribute("bleed on hit accumulate cap", 0)
	if (accumulatehitbleed && info.GetDamageCustom() != 34)
	{
		local duration = (min(weapon.GetAttribute("bleed on hit accumulate time", 0) + self.GetCondDuration(25), accumulatehitbleed))
		weapon.AddAttribute("bleeding duration",duration,0)
		self.AddCondEx(25, duration, info.GetAttacker())
	}
	else if (accumulatehitbleed)
	{
		weapon.AddAttribute("bleeding duration",0,0)
	}
}

function BuildingReenable()
{
	local scriptscope = self.GetOrCreatePrivateScriptScope()
	if(!NetProps.GetPropInt(self, "m_bPlasmaDisable") && scriptscope.disabletime <= Time())
	{
		EntFireByHandle(self, "Enable", "", 0, null, null)
	}
}

IncludeScript("lib/mapbasehookcollector.nut")