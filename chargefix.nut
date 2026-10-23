// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means I have made some grevious error.
//

IncludeScript("lib/clocksutils.nut");

if (!("chargingPlayers" in getroottable())) {
	chargingPlayers <- []
	playerJetDash <- array(PLAYERCAP, Vector(0,0,0))
	lastCharge <- array(PLAYERCAP, Time())
	lastScream <- array(PLAYERCAP, Time())
	isCharging <- array(PLAYERCAP, false)
	currCharge <- array(PLAYERCAP, 100)
	chargeEnd <- array(PLAYERCAP, 0)
}

//Convars.SetValue("tf_max_charge_speed", 10000)

PrecacheSound("weapons/demo_charge_windup1.wav")
PrecacheSound("weapons/demo_charge_windup2.wav")
PrecacheSound("weapons/demo_charge_windup3.wav")
PrecacheSound("weapons/demo_charge_hit_world1.wav")
PrecacheSound("weapons/demo_charge_hit_world2.wav")

local CHARGESOUNDS = ["Charge.Scout","Charge.Sniper","Charge.Soldier","Charge.Demo","Charge.Medic","Charge.Heavy","Charge.Pyro","Charge.Spy","Charge.Engineer","Charge.Civilian"]

::CTFPlayer.GetChargeTime <- function()
{
	return GetWearableAttribute(this,"charge time increased", 0) + GetWearableAttribute(this,"charge time decreased", 0) + 1.5
}
::CTFBot.GetChargeTime <- CTFPlayer.GetChargeTime

::CTFPlayer.GetChargeRechargeTime <- function()
{
	return GetWearableAttribute(this,"charge recharge rate increased", 1) * GetWearableAttribute(this,"charge recharge rate decreased", 1)
}
::CTFBot.GetChargeRechargeTime <- CTFPlayer.GetChargeRechargeTime

::CTFPlayer.GetChargePower <- function()
{
	return GetWearableAttribute(this,"charge speed increased", 1) * GetWearableAttribute(this,"charge speed decreased", 1)
}
::CTFBot.GetChargePower <- CTFPlayer.GetChargePower

function ChargePulse()
{
	foreach (player in chargingPlayers)
	{
		if (!player || !player.IsValid() || !player.IsPlayer())
		{
			chargingPlayers.remove(chargingPlayers.find(player))
			continue
		}
		local playerindex = player.GetEntityIndex()
		if (player.InCond(17))
		{
			isCharging[playerindex] = true
		}
		if (isCharging[playerindex])
		{	
			local chargecond = GetWearableAttribute(player,"charge cond", 0)
			if (chargecond)
			{
				player.AddCondEx(chargecond, 0.05, player)
			}
			if (player.InCond(17) && player.GetPlayerClass() == Constants.ETFClass.TF_CLASS_DEMOMAN)
			{
				currCharge[playerindex] = NetProps.GetPropFloat(player, "m_Shared.m_flChargeMeter")
			}
			else
			{
				currCharge[playerindex] = clamp(currCharge[playerindex] - (1.5/(player.GetChargeTime())),0,100)
			}
			if (currCharge[playerindex] <= chargeEnd[playerindex] || NetProps.GetPropFloat(player, "m_Shared.m_flChargeMeter") == 0)
			{
				isCharging[playerindex] = false
				currCharge[playerindex] = chargeEnd[playerindex]
				EndCharge(player)
			}

			if (player.InCond(17))
			{
				local isMelee = MeleeWeapons.find(player.GetActiveWeapon().GetClassname()) != null
				if (player.GetPlayerClass() != Constants.ETFClass.TF_CLASS_DEMOMAN)
				{
					player.AddCustomAttribute("major move speed bonus", 2.6881 * player.GetChargePower(), 0.1)
				}
				else
				{
					player.AddCustomAttribute("major move speed bonus", player.GetChargePower(), 0.1) //player.AddCustomAttribute("major move speed bonus", 0.075 * player.GetChargePower(), 0.1)
				}
				if (currCharge[playerindex] < 33 && isMelee && !GetWearableAttribute(player, "lose demo charge on damage when charging", 0))
				{
					AddTimedAttribute(player.GetActiveWeapon(), "crits vs class", 1023, 4)
				}
				else if (currCharge[playerindex] < 75 && isMelee)
				{
					AddTimedAttribute(player.GetActiveWeapon(), "minicrits vs class", 1023, 4)
				}

				if (!GetWearableAttribute(player,"no charge impact range", 0))
				{
					local center = player.GetOrigin() // Unlike base charge behaviour, we don't get shoot position. (Why did they get shoot position before?!?)
					center.z += player.GetBoundingMaxs().z * 0.6
					local endpos = center + (AngleVectors(player.EyeAngles()) * 48)
					local trace = TraceHullComplex(center, endpos, Vector(-24,-24,-24), Vector(24,24,24), player, 33571367,0)
					// Takes 2 points, min/max hull bounds, an ent to ignore, a trace mask, and a collision group to trace to a point using a hull. Returns a handle which can access all trace info.
					if (trace.Entity())
					{
						if (trace.Entity().IsPlayer())
						{
							local chargedmg = RemapValClamped(currCharge[playerindex], 90, 40, 15, 50) * GetWearableAttribute(player,"charge impact damage increased", 1) * GetWearableAttribute(player,"charge impact damage decreased", 1) * (1 + min(NetProps.GetPropInt(player, "m_Shared.m_iDecapitations") * 0.1, 0.5))
							if (chargedmg > 0)
							{
								local weapon = GetChargeWeapon(player)
								trace.Entity().ApplyAbsVelocityImpulse((player.GetAbsVelocity().Normalized() + Vector(0,0,2)) * chargedmg * 2)
								trace.Entity().TakeDamageCustom(weapon, player, weapon, (player.GetAbsVelocity().Normalized() * chargedmg), trace.EndPos() - Vector(0,0,-10), chargedmg, 4, 23)
								player.EmitSound("DemoCharge.HitFleshRange")
								// (hInflictor, hAttacker, hWeapon, vecDamageForce, vecDamagePosition, flDamage, nDamageType, nCustomDamageType)
							}
							else
							{
								player.EmitSound("DemoCharge.HitWorld")
							}
							isCharging[playerindex] = false
							currCharge[playerindex] = chargeEnd[playerindex]
							EndCharge(player)
						}
						else if (TraceHullComplex(center, endpos, Vector(-24,-24,-24), Vector(24,24,24), player, 16935,0).Entity() == trace.Entity()) //HACK BECAUSE THIS GAME IS AWFUL AND I HATE IT
						{
							player.EmitSound("DemoCharge.HitWorld")
							isCharging[playerindex] = false
							currCharge[playerindex] = chargeEnd[playerindex]
							EndCharge(player)
						}
					}
				}
			}
			//NetProps.SetPropFloat(player, "m_Shared.m_flChargeMeter", currCharge[playerindex])
		}
		else
		{
			currCharge[playerindex] = clamp(currCharge[playerindex] + (0.125 * player.GetChargeRechargeTime()),0,100)
			local chargecost = 100 * GetWearableAttribute(player, "charge cost", 1)
			if (currCharge[playerindex] >= chargecost && player.GetButtons() & 2048 && player.IsInValidState() && !player.GetGrapplingHookTarget() && player.GetContext("charge type") != "display")
			{
				currCharge[playerindex] = ExecuteCharge(player, player.GetContext("charge type"), currCharge[playerindex], chargecost)
			}
		}
	}
}

// In it's own less often updated function because it turns out it "lags" the game whenever it updates "m_Shared.m_flChargeMeter"? Weird but it doesn't need to be updated that often ig...
function ChargePulseUpdateUI()
{
	foreach (player in chargingPlayers)
	{
		if (!player || !player.IsValid() || !player.IsPlayer())
		{
			chargingPlayers.remove(chargingPlayers.find(player))
			continue
		}
		local playerindex = player.GetEntityIndex()
		NetProps.SetPropFloat(player, "m_Shared.m_flChargeMeter", currCharge[playerindex].tointeger())
	}
}

UniqueRepeatingFunctionInTime(ChargePulse, 0)
UniqueRepeatingFunctionInTime(ChargePulseUpdateUI, 0.1)

function ExecuteCharge(player, type, charge, cost)
{
	if (endswith(type, "_active"))
	{
		if (player.GetActiveWeapon().GetAttributeString("has charge", "") == type)
		{
			type = type.slice(0,-7)
		}
		else
		{
			return charge
		}
	}
	local chargetime = player.GetChargeTime()
	local chargepower = player.GetChargePower()
	local playerindex = player.GetEntityIndex()
	// Cap screaming at a maximum of once every 4 seconds.
	if (lastScream[playerindex] + 4 < Time())
	{
		player.EmitSound(CHARGESOUNDS[player.GetPlayerClass() - 1])
		lastScream[playerindex] = Time()
	}
	switch (type)
	{
		case "regular":
			StartCharge(player, cost)
			break;
		case "leap":
			local eyeangle = AngleVectors(player.EyeAngles())
			if (eyeangle.z < 0.4) // To ensure the leap works even if the player is looking too low
			{
				eyeangle.z = 0
				eyeangle = eyeangle * (1/eyeangle.Length() * 0.91652)
				eyeangle.z = 0.4
			}
			local velocity = player.GetAbsVelocity()
			if (velocity.z < 0) // Cancel downwards vertical momentum
			{
				velocity.z = 0
				player.SetAbsVelocity(velocity)
			}
			player.ApplyAbsVelocityImpulse(eyeangle * 1000 * chargepower)
			charge -= cost
			break;
		case "leap_omni":
			local eyeangle = AngleVectors(player.EyeAngles())
			if (eyeangle.z < 0.4 && NetProps.GetPropEntity(player, "m_hGroundEntity") != null) // To ensure the leap works even if the player is looking too low
			{
				eyeangle.z = 0
				eyeangle = eyeangle * (1/eyeangle.Length() * 0.91652)
				eyeangle.z = 0.4
			}
			local velocity = player.GetAbsVelocity()
			if (velocity.z < 0 && eyeangle.z > 0) // Cancel downwards vertical momentum
			{
				velocity.z = 0
				player.SetAbsVelocity(velocity)
			}
			player.ApplyAbsVelocityImpulse(eyeangle * 1000 * chargepower)
			charge -= cost
			break;
		case "leap_charge":
			StartCharge(player, cost)
			isCharging[playerindex] = true
			chargeEnd[playerindex] = currCharge[playerindex] - cost
			local eyeangle = AngleVectors(player.EyeAngles())
			if (eyeangle.z < 0.4) // To ensure the leap works even if the player is looking too low
			{
				eyeangle.z = 0
				eyeangle = eyeangle * (1/eyeangle.Length() * 0.91652)
				eyeangle.z = 0.4
			}
			local velocity = player.GetAbsVelocity()
			if (velocity.z < 0) // Cancel downwards vertical momentum
			{
				velocity.z = 0
				player.SetAbsVelocity(velocity)
			}
			player.ApplyAbsVelocityImpulse(eyeangle * 1000 * chargepower)
			break;
		case "leap_omni_charge":
			StartCharge(player, cost)
			isCharging[playerindex] = true
			chargeEnd[playerindex] = currCharge[playerindex] - cost
			local eyeangle = AngleVectors(player.EyeAngles())
			if (eyeangle.z < 0.4 && NetProps.GetPropEntity(player, "m_hGroundEntity") != null) // To ensure the leap works even if the player is looking too low
			{
				eyeangle.z = 0
				eyeangle = eyeangle * (1/eyeangle.Length() * 0.91652)
				eyeangle.z = 0.4
			}
			local velocity = player.GetAbsVelocity()
			if (velocity.z < 0 && eyeangle.z > 0) // Cancel downwards vertical momentum
			{
				velocity.z = 0
				player.SetAbsVelocity(velocity)
			}
			player.ApplyAbsVelocityImpulse(eyeangle * 1000 * chargepower)
			break;
		case "gravdash":
			local dashvector = AngleVectors(player.EyeAngles()) * 700 * chargepower
			player.SetAbsVelocity(dashvector)
			playerJetDash[player.GetEntityIndex()] = dashvector
			ReapeatingFunctionInTime(GravityDash, 0.1, [player])
			isCharging[playerindex] = true
			chargeEnd[playerindex] = currCharge[playerindex] - cost
			break;
		case "gravdash_charge":
			StartCharge(player, cost)
			local dashvector = AngleVectors(player.EyeAngles()) * 700 * chargepower
			player.SetAbsVelocity(dashvector)
			playerJetDash[player.GetEntityIndex()] = dashvector
			ReapeatingFunctionInTime(GravityDash, 0.1, [player])
			isCharging[playerindex] = true
			chargeEnd[playerindex] = currCharge[playerindex] - cost
			break;
		case "gravdash_hold":
			local dashvector = AngleVectors(player.EyeAngles()) * 700 * chargepower
			player.SetAbsVelocity(dashvector)
			playerJetDash[player.GetEntityIndex()] = dashvector
			ReapeatingFunctionInTime(GravityDashHold, 0.1, [player])
			isCharging[playerindex] = true
			chargeEnd[playerindex] = currCharge[playerindex] - cost
			break;
		case "jetdash":
			player.SetAbsVelocity(AngleVectors(player.EyeAngles()) * 700 * chargepower)
			ReapeatingFunctionInTime(JetpackDash, 0.1, [player])
			isCharging[playerindex] = true
			chargeEnd[playerindex] = currCharge[playerindex] - cost
			break;
		case "jetdash_charge":
			StartCharge(player, cost)
			player.SetAbsVelocity(AngleVectors(player.EyeAngles()) * 700 * chargepower)
			ReapeatingFunctionInTime(JetpackDash, 0.1, [player])
			isCharging[playerindex] = true
			chargeEnd[playerindex] = currCharge[playerindex] - cost
			break;
		case "jetdash_hold":
			player.SetAbsVelocity(AngleVectors(player.EyeAngles()) * 700 * chargepower)
			ReapeatingFunctionInTime(JetpackDashHold, 0.1, [player])
			isCharging[playerindex] = true
			chargeEnd[playerindex] = currCharge[playerindex] - cost
			break;
		case "skywards":
			player.ApplyAbsVelocityImpulse(Vector(0,0,1000 * chargepower))
			charge -= cost
			break;
		case "skywards_charge":
			StartCharge(player, cost)
			player.ApplyAbsVelocityImpulse(Vector(0,0,1000 * chargepower))
			isCharging[playerindex] = true
			chargeEnd[playerindex] = currCharge[playerindex] - cost
			break;
	}
	lastCharge[playerindex] = Time()
	chargeEnd[playerindex] = max(currCharge[playerindex] - cost, 0)
	return charge
}

function GravityDash(player)
{
	local playerindex = player.GetEntityIndex()
	if (isCharging[playerindex])
	{
		local tracerbottompoint = player.GetOrigin() + Vector(0,0,-2)
		local tracertoppoint = player.GetOrigin()
		tracertoppoint.z += player.GetBoundingMaxs().z + 2
		local trace = TraceHullComplex(tracerbottompoint, tracertoppoint, player.GetBoundingMins() + Vector(-10,-10,-10), player.GetBoundingMaxs() + Vector(10,10,10), player, 1107492995,1)
		if (!trace.DidHit())
		{
			player.SetAbsVelocity(playerJetDash[player.GetEntityIndex()])
		}
		else
		{
			local playerindex = player.GetEntityIndex()
			isCharging[playerindex] = false
			currCharge[playerindex] = chargeEnd[playerindex]
			EndCharge(player)
		}
	}
	else
	{
		return false
	}
}

function StartCharge(player, cost)
{
	local playerindex = player.GetEntityIndex()
	if (player.GetPlayerClass() != Constants.ETFClass.TF_CLASS_DEMOMAN)
	{
		player.AddCustomAttribute("major move speed bonus", 2.6881 * player.GetChargePower(), 0.1)
		player.AddCond(17)	
	}
	else
	{
		player.AddCond(17) //FunctionInTime(StartChargeDemo, 0, [player])
	}
	isCharging[playerindex] = true
	chargeEnd[playerindex] = currCharge[playerindex] - cost
}

//function StartChargeDemo(player)
//{
//	player.AddCond(17)
//}

function GravityDashHold(player)
{
	local playerindex = player.GetEntityIndex()
	if (isCharging[playerindex])
	{
		local tracerbottompoint = player.GetOrigin() + Vector(0,0,-2)
		local tracertoppoint = player.GetOrigin()
		tracertoppoint.z += player.GetBoundingMaxs().z + 2
		local trace = TraceHullComplex(tracerbottompoint, tracertoppoint, player.GetBoundingMins() + Vector(-10,-10,-10), player.GetBoundingMaxs() + Vector(10,10,10), player, 1107492995,1)
		if (!trace.DidHit() && player.GetButtons() & 2048)
		{
			player.SetAbsVelocity(playerJetDash[player.GetEntityIndex()])
		}
		else
		{
			local playerindex = player.GetEntityIndex()
			isCharging[playerindex] = false
			currCharge[playerindex] = chargeEnd[playerindex]
			EndCharge(player)
		}
	}
	else
	{
		return false
	}
}

function JetpackDash(player)
{
	local playerindex = player.GetEntityIndex()
	if (isCharging[playerindex])
	{
		player.SetAbsVelocity(AngleVectors(player.EyeAngles()) * 700 * player.GetChargePower())
	}
	else
	{
		return false
	}
}

function JetpackDashHold(player)
{
	local playerindex = player.GetEntityIndex()
	if (isCharging[playerindex])
	{
		if (player.GetButtons() & 2048)
		{
			player.SetAbsVelocity(AngleVectors(player.EyeAngles()) * 700 * player.GetChargePower())
		}
		else
		{
			isCharging[playerindex] = false
			currCharge[playerindex] = chargeEnd[playerindex]
			EndCharge(player)
			return false
		}
	}
}

function GetChargeWeapon(player)
{
	local weapon = null
	for (local i = 0; i < MAXWEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null || !held_weapon.GetAttributeString("has charge", ""))
			continue
		weapon = held_weapon
	}
	local wd = 0
	for (local wearable = player.FirstMoveChild(); wearable != null && wd < 50; wearable = wearable.NextMovePeer())
	{
		wd += 1
		if (!startswith(wearable.GetClassname(),"tf_wearable") || NetProps.GetPropInt(wearable, "m_bDisguiseWearable") || !wearable.GetAttributeString("has charge", ""))
			continue
		weapon = wearable
	}
	return weapon
}

function EndCharge(player)
{
	local blast = GetWearableAttribute(player, "charge explode", 0)
	if (GetWearableAttribute(player, "charge explode", 0))
	{
		local weapon = null
		for (local i = 0; i < MAXWEAPONS; i++)
		{
			local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (held_weapon == null || !held_weapon.GetAttribute("charge explode", 0))
				continue
			weapon = held_weapon
		}
		local wd = 0
		for (local wearable = player.FirstMoveChild(); wearable != null && wd < 50; wearable = wearable.NextMovePeer())
		{
			wd += 1
			if (!startswith(wearable.GetClassname(),"tf_wearable") || NetProps.GetPropInt(wearable, "m_bDisguiseWearable") || !wearable.GetAttribute("charge explode", 0))
				continue
			weapon = wearable
		}
		local pipe = Entities.CreateByClassname("tf_projectile_pipe")
		NetProps.SetPropEntity(pipe, "m_hLauncher", player) //Makes the following work correctly.
		pipe.SetOrigin(player.GetOrigin() + Vector(0,0,36) + player.GetAbsVelocity() * 0.1) // Set its position to that of the brick.
		pipe.SetOwner(player) // Set its owner to that of the brick.
		pipe.SetThrower(weapon) // Set its owner to that of the brick, again.
		//pipe.GetDamage() // Not sure if this does anything, but i'm also not sure it doesn't do anything?
		pipe.SetDamage(100 * weapon.GetAttribute("blast splash damage decreased", 1) * weapon.GetAttribute("blast splash damage increased", 1))
		pipe.SetDamageRadius(146 * weapon.GetAttribute("Blast radius increased", 1) * weapon.GetAttribute("Blast radius decreased", 1))
		NetProps.SetPropEntity(pipe, "m_hOriginalLauncher", weapon) // Gives it the correct explosion effect.
		pipe.AddContext("IsBrickExplodeFixPipe", "yep", 0.1) // So we know that this is the brick explode pipe in damage calculations 
		NetProps.SetPropEntity(pipe, "m_hEffectEntity", player) // So the icon can be corrected
		pipe.AcceptInput("detonate", "", weapon, player)
	}
	if (GetWearableAttribute(player, "charge slam", 0))
	{
		player.ApplyAbsVelocityImpulse(Vector(0,0,-1000))
		player.AddTimedWearerAttributeString("anchor earthquake", "192.0 0.0 4.0", 1.5)
	}
	player.RemoveCond(17)
}

::ChargeFixEvents2 <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ConnectOutput("OnUser1" "MeleeSwingCharge2")
		player.ConnectOutput("OnUser2" "MeleeSwingCharge")
		player.ConnectOutput("OnUser3" "MeleeSwingCharge2")
	}
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		local charge = GetWearableAttributeString(player, "has charge", "")
		local playerindex = player.GetEntityIndex()
		player.RemoveCond(17)
		NetProps.SetPropFloat(player, "m_Shared.m_flChargeMeter", 100)
		isCharging[playerindex] = false
		chargeEnd[playerindex] = 100
		currCharge[playerindex] = 100
		if (charge != "")
		{
			player.AddContext("charge type", charge, 0)
			NetProps.SetPropInt(player, "m_Shared.m_bShieldEquipped", 1)
			if (chargingPlayers.find(player) == null)
			{
				chargingPlayers.append(player)
			}
		}
		else if (GetWeaponByClass(player, "tf_wearable_demoshield") == null)
		{
			player.AddContext("charge type", "", 0)
			NetProps.SetPropInt(player, "m_Shared.m_bShieldEquipped", 0)
			local index = chargingPlayers.find(player)
			if (index != null)
			{
				chargingPlayers.remove(index)
			}
		}
		else
		{
			player.AddContext("charge type", "", 0)
			local index = chargingPlayers.find(player)
			if (index != null)
			{
				chargingPlayers.remove(index)
			}
		}
		player.ValidateScriptScope()
	}
}

function MeleeSwingCharge()
{
	local playerindex = self.GetEntityIndex()
	if (isCharging[playerindex] && self.InCond(17) && (!self.GetActiveWeapon() || !self.GetActiveWeapon().GetAttribute("Attack not cancel charge", 0)))
	{
		isCharging[playerindex] = false
		currCharge[playerindex] = chargeEnd[playerindex]
		EndCharge(self)
		self.RemoveCustomAttribute("major move speed bonus")
	}
}

function MeleeSwingCharge2()
{
	if (self.GetActiveWeapon())
	{
		self.GetActiveWeapon().RemoveAttribute("crits vs class")
		self.GetActiveWeapon().RemoveAttribute("minicrits vs class")
	}
}

__CollectGameEventCallbacks(ChargeFixEvents2)

IncludeScript("lib/mapbasehookcollector.nut")