// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

local PROJECTILES = ["tf_weapon_grenade_mirv_projectile", "tf_weapon_grenade_mirv_bomb", "tf_projectile_pipe", "tf_projectile_pipe_remote", "tf2c_projectile_brick", "tf2c_projectile_grenade_cyclops", "tf_projectile_ball_attributed", "tf_projectile_ball_ornament", "tf_projectile_stun_ball","tf_projectile_arrow", "tf_projectile_energy_ring", "tf_projectile_flare", "tf_projectile_healing_bolt", "tf_projectile_balloffire", "tf_projectile_rocket", "tf_projectile_syringe", "tf2c_projectile_arrow", "tf2c_projectile_coil", "tf2c_projectile_dart", "tf2c_projectile_nail"];

Entities.EnableEntityListening()
Hooks.Add(this, "OnEntitySpawned", function(entity)
{
	FunctionInTime(EntitySpawnMOOF, 0, [entity]);
}, "EntitySpawnMOOF" );

function EntitySpawnMOOF(entity)
{
	if (!entity || !entity.IsValid() || !entity.GetOwner() || !entity.GetOwner().IsPlayer() || PROJECTILES.find(entity.GetClassname()) == null)
	{
		return
	}

	local classname = entity.GetClassname()

	local weapon = entity.GetOwner().GetActiveWeapon()

	if (weapon == null)
	{
		return
	}

	local MOOF = weapon.GetAttribute("MOOF", 0) // Might as well use this one.

	if (MOOF != 0)
	{
		entity.SetVelocity(entity.GetVelocity()+entity.GetOwner().GetEyeForward()*MOOF)
	}
}