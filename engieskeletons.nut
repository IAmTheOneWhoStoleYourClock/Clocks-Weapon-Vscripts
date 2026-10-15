// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// All of the things. This isn't done yet.
//

IncludeScript("lib/clocksutils.nut");

if (!("skeletonyPlayers" in getroottable())) {
	skeletonyPlayers <- []
	skeletonpoulation <- array(MaxPlayers(), [])
}

::EngieSkeletons <- {
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		local skeleton = GetWearableAttribute(player, "engie skeletons", 0)
		local playerindex = player.GetEntityIndex()
		if (skeleton > 0)
		{
			skeletonyPlayers.append(player)
		}
		else
		{
			local index = skeletonyPlayers.find(player)
			if (index != null)
			{
				skeletonyPlayers.remove(index)
			}
		}
	}
}

::CTFPlayer.GetSkeletons <- function()
{
	foreach (skeleton in skeletonpoulation[this.GetEntityIndex()])
	{
		if (!skeleton || !skeleton.IsValid())
		{
			skeletonpoulation[this.GetEntityIndex()].remove(skeletonpoulation[this.GetEntityIndex()].find(skeleton))
		}
	}
	return skeletonpoulation[this.GetEntityIndex()]
}
::CTFBot.GetSkeletons <- CTFPlayer.GetSkeletons

__CollectGameEventCallbacks(EngieSkeletons)

function Skeletons()
{
	foreach (player in skeletonyPlayers)
	{
		if (!player || !player.IsValid() || !player.IsPlayer() || !player.IsAlive())
		{
			skeletonyPlayers.remove(skeletonyPlayers.find(player))
		}
		else if (player.GetButtons() & 2048)
		{
			local weapon = player.GetActiveWeapon()
			local skeletoncap = weapon.GetAttribute("engie skeletons", 0)
			if (weapon.NextSecondaryAttack() <= Time() && weapon.NextPrimaryAttack() <= Time() && skeletoncap > 0)
			{
				weapon.SetNextSecondaryAttack(Time() + 1)
				local ammocount = player.GetAmmoCount(3)
				local skeletoncost = weapon.GetAttribute("engie skeleton metal cost", 0)
				local skeletonhealthcost = weapon.GetAttribute("engie skeleton health cost", 0)
				local skeletonubercost = weapon.GetAttribute("engie skeleton uber cost", 0)
				if (skeletonubercost)
				{
					local weapon = GetWeaponByClass(player, "tf_weapon_medigun")
					if (weapon == null)
					{
						weapon = GetWeaponByClass(player, "tf2c_weapon_heallauncher")
					}
					if (weapon == null)
					{
						EmitSoundOnClient("Player.UseDeny",player)
						continue
					}
					local uber = NetProps.GetPropFloat(weapon, "m_flChargeLevel")
					skeletonubercost *= weapon.GetAttribute("ubercharge rate bonus", 1) * weapon.GetAttribute("ubercharge rate penalty", 1) * weapon.GetAttribute("ubercharge rate penalty VSCRIPT", 1)
					if (uber >= skeletonubercost)
					{
						NetProps.SetPropFloat(weapon, "m_flChargeLevel", uber - skeletonubercost)
					}
					else
					{
						EmitSoundOnClient("Player.UseDeny",player)
						continue
					}
				}
				if (ammocount >= skeletoncost && skeletonhealthcost < player.GetHealth())
				{
					local ownerindex = player.GetEntityIndex()
					//Don't allow them to make too many skeletons
					if (player.GetSkeletons().len() < skeletoncap && !IsInFunc(player, "func_respawnroom"))
					{
						local spell = Entities.CreateByClassname("tf_projectile_spellspawnzombie")
						NetProps.SetPropInt(spell, "m_iType", 1)
						spell.SetOrigin(player.ShootPosition())
						spell.SetModel("models/props_mvm/mvm_human_skull_collide.mdl")
						spell.PhysicsInitNormal(2,8,false)
						local newphysics = spell.GetPhysicsObject()
						SetPhysVelocity(newphysics, player.GetEyeForward()*1000, Vector(RandomInt(-360, 360),RandomInt(-360, 360),RandomInt(-360, 360)))
						//NetProps.SetPropEntity(spell, "m_hLauncher", self)
						spell.SetThrower(player)
						spell.SetOwner(player)
						local ownerindex = player.GetEntityIndex()
						spell.AddContext("Cleared", "Yes", 0)
						spell.SetTeam(player.GetTeam())
						//newphysics.EnableGravity(true)
						spell.SetAbsAngles(player.GetAbsAngles())
						//spell.AcceptInput("detonate", "", spell, spell.GetThrower())
						EntFireByHandle(spell, "CallScriptFunction", "skeletonexplode", 2, null, null)

						weapon.SetNextPrimaryAttack(Time() + 1.5)

						local viewmodel = NetProps.GetPropEntity(player, "m_hViewModel")
						local animindex = viewmodel.LookupSequence(weapon.GetAttributeString("engie skeleton animation", ""))
						viewmodel.SetCycle(0)
						viewmodel.ResetSequence(1)
						viewmodel.SetCycle(0)
						viewmodel.ResetSequenceInfo()
						viewmodel.ResetSequence(animindex)
						viewmodel.SetCycle(0)
						local animtime = weapon.SequenceDuration(animindex) + Time()
						ReapeatingFunctionInTime(ForceWeaponAnim, 0, [viewmodel, animindex, Time(), animtime, viewmodel.LookupSequence(weapon.GetAttributeString("engie skeleton idle animation", ""))])
						NetProps.SetPropInt(player, "m_nSequence", weapon.GetPrimaryAttackActivity());

						weapon.SetNextPrimaryAttack(animtime + 0.3)
						weapon.SetNextSecondaryAttack(animtime + 0.3)

						skeletonpoulation[ownerindex].append(spell)

						weapon.EmitSound("Halloween.spell_fireball_cast")

						player.SetAmmoCount(3, ammocount - skeletoncost)
						if (skeletonhealthcost)
						{
							player.TakeDamageEx(weapon, player, weapon, Vector(0,0,0) player.GetOrigin() + Vector(0,0,50), skeletonhealthcost,2064);
						}
					}
					else
					{
						EmitSoundOnClient("Player.UseDeny",player)
					}
				}
				else
				{
					EmitSoundOnClient("Player.UseDeny",player)
				}
			}
		}
	}
}

UniqueRepeatingFunctionInTime(Skeletons, 0)

function ForceWeaponAnim(entity, animationindex, starttime, endtime, idleanim)
{
	local completion = (Time() - starttime)/(endtime - starttime)
	if (completion > 1)
	{
		entity.ResetSequence(idleanim)
		return false
	}
	else if (entity.GetSequence() != animationindex)
	{
		entity.SetSequence(animationindex)
		entity.SetCycle(completion - 0.04)
	}
}

function skeletonexplode()
{
	self.AcceptInput("detonate", "", self, self.GetThrower())
}

Entities.EnableEntityListening()

Hooks.Add(this, "OnEntitySpawned", function(entity)
{
	entity.SetContextThink("OnEntitySpawnedSkeletons", OnEntitySpawnedSkeletons, 0.01);
}, "Skeletonsoffun" )

function OnEntitySpawnedSkeletons(entity)
{
	if (!entity || !entity.IsValid())
	{
		return
	}
	if (entity.GetClassname() == "tf_zombie")
	{
		if (entity.GetOwner() && skeletonyPlayers.find(entity.GetOwner()) != null)
		{
			if (IsInFunc(entity, "func_respawnroom")) //Prevent them from spawning in people's spawn rooms, because they just don't work there for some reason?
			{
				entity.Kill()
			}
			else
			{
				entity.ValidateScriptScope()
				entity.AddContext("NoChildren", "Yes", 0)
				skeletonpoulation[entity.GetOwner().GetEntityIndex()].append(entity)
			}
		}
	}
	else if (entity.GetClassname() == "tf_projectile_spellspawnzombie")
	{
		entity.AddContext("Cleared", "Yes", 0)
	}
}

function UpdateOnRemove(self)
{
	if (self.GetContext("NoChildren") == "Yes")
	{
		local skelebaby = Entities.FindByClassnameWithin(null, "tf_projectile_spellspawnzombie", self.GetOrigin(),100)
		local wd = 0
		while (skelebaby && wd < 50)
		{
			local buffer = Entities.FindByClassnameWithin(skelebaby, "tf_projectile_spellspawnzombie", self.GetOrigin(),100)
			if (self.GetOwner() == skelebaby.GetOwner() && skelebaby.GetContext("Cleared") != "Yes") // The latter should only ever be true of projectiles just created
			{
				skelebaby.Kill()
			}
			skelebaby = buffer
			wd++
		}
	}
	else if (self.GetClassname() == "tf_zombie")
	{
		local skelebaby = Entities.FindByClassnameWithin(null, "tf_projectile_spellspawnzombie", self.GetOrigin(),100)
		local wd = 0
		while (skelebaby && wd < 50)
		{
			local buffer = Entities.FindByClassnameWithin(skelebaby, "tf_projectile_spellspawnzombie", self.GetOrigin(),100)
			if (self.GetOwner() == skelebaby.GetOwner() && skelebaby.GetContext("Cleared") != "Yes") // The latter two should only ever be true of projectiles just created
			{
				skelebaby.AddContext("Cleared", "Yes", 0)
			}
			skelebaby = buffer
			wd++
		}
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

IncludeScript("lib/mapbasehookcollector.nut")