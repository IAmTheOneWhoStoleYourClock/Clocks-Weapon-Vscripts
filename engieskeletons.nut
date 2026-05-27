::EngieSkeletonsEventTable <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ValidateScriptScope()
		player.ForceButtons(4096)
	}
}

__CollectGameEventCallbacks(EngieSkeletonsEventTable)

local firepoint = Vector(0,0,-26)
local skeletonsoffun = null
local skeletonspos = null
local heretickill = false

function PlayerRunCommand()
{
	if (HasMatchingFlags(self.GetButtons(), 2048))
	{
		local weapon = self.GetActiveWeapon()
		if (weapon.NextSecondaryAttack() <= Time())
		{
			weapon.SetNextSecondaryAttack(Time() + 2)
			local ammocount = self.GetAmmoCount(3)
			if (ammocount >= 50)
			{
				self.SetAmmoCount(3, ammocount - 50)
				local spell = Entities.CreateByClassname("tf_projectile_spellspawnzombie")
				NetProps.SetPropInt(spell, "m_iType", 1)
				spell.SetOrigin(self.ShootPosition())
				spell.SetModel("models/props_mvm/mvm_human_skull_collide.mdl")
				spell.PhysicsInitNormal(2,8,false)
				local newphysics = spell.GetPhysicsObject()
				SetPhysVelocity(newphysics, self.GetEyeForward()*1000, firepoint)
				//NetProps.SetPropEntity(spell, "m_hLauncher", self)
				spell.SetThrower(self)
				spell.SetOwner(self)
				spell.AddContext("Owner", self.GetEntityIndex().tostring(), 0)
				spell.SetTeam(self.GetTeam())
				newphysics.EnableGravity(true)
				printl(spell.GetOrigin())
				//spell.AcceptInput("detonate", "", spell, spell.GetThrower())
				EntFireByHandle(spell, "CallScriptFunction", "skeletonexplode", 2, null, null)
				weapon.SendWeaponAnim(1)
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
	OnEntityCreated(entity)
}, "Skeletonsoffun" )

function OnEntityCreated(entity)
{
	if (entity.GetClassname() == "tf_zombie")
	{
		if (skeletonsoffun && skeletonsoffun.GetContext("Owner") != "")
		{
			entity.SetOwner(EntIndexToHScript(skeletonsoffun.GetContext("Owner").tointeger()))
			entity.AddContext("EngieSkele", "Yes", 0)
			entity.ValidateScriptScope()
			skeletonsoffun = null
		}
	}
	else if (entity.GetClassname() == "tf_projectile_spellspawnzombie")
	{
		if (heretickill)
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
		}
		else
		{
			heretickill = false
		}
	}
}