::EngieSkeletonsEventTable <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ValidateScriptScope()
		player.ForceButtons(4096)
	}
}

__CollectGameEventCallbacks(EngieSkeletonsEventTable)

firepoint <- Vector(0,100,0)
local skeletonsoffun = null
local skeletonspos = null
local heretickill = false
local skeletonpoulation = array(MaxPlayers(), 0)
local summoning = false
local table = {}

function PlayerRunCommand()
{
	if (HasMatchingFlags(self.GetButtons(), 2048))
	{
		local weapon = self.GetActiveWeapon()
		local skeletoncap = weapon.GetAttribute("engie skeletons", 0)
		if (weapon.NextSecondaryAttack() <= Time() && skeletoncap > 0)
		{
			weapon.SetNextSecondaryAttack(Time() + 2)
			local ammocount = self.GetAmmoCount(3)
			local skeletoncost = weapon.GetAttribute("engie skeleton cost", 60)
			if (ammocount >= skeletoncost)
			{
				local ownerindex = self.GetEntityIndex()
				//Don't allow them to make too many skeletons
				if (skeletonpoulation[ownerindex] < skeletoncap && !IsInFunc(self, "func_respawnroom"))
				{
					summoning = true
					self.SetAmmoCount(3, ammocount - 60)
					local spell = Entities.CreateByClassname("tf_projectile_spellspawnzombie")
					NetProps.SetPropInt(spell, "m_iType", 1)
					spell.SetOrigin(self.ShootPosition())
					spell.SetModel("models/props_mvm/mvm_human_skull_collide.mdl")
					spell.PhysicsInitNormal(2,8,false)
					local newphysics = spell.GetPhysicsObject()
					SetPhysVelocity(newphysics, self.GetEyeForward()*1000, self.GetEyeForward())
					//NetProps.SetPropEntity(spell, "m_hLauncher", self)
					spell.SetThrower(self)
					spell.SetOwner(self)
					local ownerindex = self.GetEntityIndex()
					spell.AddContext("Owner", ownerindex.tostring(), 0)
					spell.AddContext("Cost", skeletoncost.tostring(), 0)
					spell.SetTeam(self.GetTeam())
					//newphysics.EnableGravity(true)
					spell.SetAbsAngles(self.GetAbsAngles())
					//spell.AcceptInput("detonate", "", spell, spell.GetThrower())
					EntFireByHandle(spell, "CallScriptFunction", "skeletonexplode", 2, null, null)
					local viewmodel = NetProps.GetPropEntity(self, "m_hViewModel")
					viewmodel.ResetSequence(8)
					viewmodel.ResetSequence(11)
					viewmodel.ResetSequenceInfo()
					weapon.SetNextPrimaryAttack(Time() + 2)
					summoning = false
				}
				else
				{
					EmitSoundOnClient("Player.UseDeny",self)
				}
			}
			else
			{
				EmitSoundOnClient("Player.UseDeny",self)
			}
		}
	}
}

function skeletonexplode()
{
	skeletonsoffun = self
	self.AcceptInput("detonate", "", self, self.GetThrower())
}

function HasMatchingFlags(a,b)
{
	local current = 1
	local match = false
	while (current < a || current < b)
	{
		current *= 2
	}
	while (current >= 1 && !match)
	{
		if ((a % current*2) - current >= 0)
		{
			if ((b % current*2) - current >= 0)
			{
				match = true
			}
		}
		current *= 0.5
	}

	return match
}

Entities.EnableEntityListening()

Hooks.Add(this, "OnEntityCreated", function(entity)
{
	OnEntityCreated(entity)
}, "Skeletonsoffun" )

Hooks.Add(this, "OnEntityCreated", function(entity)
{
	entity.SetContextThink("OnEntityCreated", OnEntityCreated, 0.01);
}, "Skeletonsoffun" )

function OnEntityCreated(entity)
{
	if (entity.GetClassname() == "tf_zombie")
	{
		if (skeletonsoffun && skeletonsoffun.GetContext("Owner") != "")
		{
			if (IsInFunc(entity, "func_respawnroom")) //Prevent them from spawning in people's spawn rooms, because they just don't work there for some reason?
			{
				entity.Kill()
			}
		}
	}
	else if (entity.GetClassname() == "tf_projectile_spellspawnzombie")
	{
		if (heretickill && entity.GetOwner())
		{
			entity.Kill()
		}
	}
}

function OnDeath()
{
	if (self.GetClassname() == "tf_zombie")
	{
		if (self.GetContext("EngieSkele") == "Yes")
		{
			heretickill = true
			skeletonpoulation[self.GetContext("Owner").tointeger()] -= 1
			self.AddContext("Counted", "yes", 0.1)
		}
		else
		{
			heretickill = false
		}
	}
}

function UpdateOnRemove() //Seperate from the other check just so that heretickill gets done at the right time.
{
	if (self.GetClassname() == "tf_zombie")
	{
		if (self.GetContext("EngieSkele") == "Yes" && self.GetContext("Counted") == "")
		{
			skeletonpoulation[self.GetContext("Owner").tointeger()] -= 1
		}
	}
}

function GetWearableAttribute(player, attribname, basenum)
{
	if (basenum != 0)
	{
		local returnvalue = basenum
		for (local i = 0; i < 8; i++)
		{
			local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (held_weapon == null)
				continue
			returnvalue = held_weapon.GetAttribute(attribname, returnvalue)
		}
		for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
		{
			if (wearable.GetClassname() != "tf_wearable")
				continue
			returnvalue = wearable.GetAttribute(attribname, returnvalue)
		}
		returnvalue = player.GetCustomAttribute(attribname, returnvalue)
		return returnvalue
	}
	else
	{
		local returnvalue = 0
		for (local i = 0; i < 8; i++)
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

function IsInFunc(entity, funcname)
{
	local inside = false
	local func = null
	while ((func = Entities.FindByClassname(func, funcname)) && !inside)
	{
		if (func.IsTouching(entity))
		{
			inside = true
		}
	}
	return inside
}