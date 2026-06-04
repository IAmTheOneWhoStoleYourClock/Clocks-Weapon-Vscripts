// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed, except probably not in this case I mean come on it just multiplies the speed of the laser projectiles.
// 

Entities.EnableEntityListening()
Hooks.Add(this, "OnEntitySpawned", function(entity)
{
	entity.SetContextThink("OnEntityCreatedBLSC", EntitySpawnBLSC, 0.01);
}, "BLSC" );

function EntitySpawnBLSC(entity)
{
	if (!entity.IsValid())
	{
		return
	}

	local classname = entity.GetClassname()

	if (entity.GetClassname() != "tf_projectile_energy_ring")
	{
		return
	}

	local weapon = NetProps.GetPropEntity(entity, "m_hLauncher")

	if (weapon == null)
	{
		return
	}

	local projectilespeed = weapon.GetAttribute("Projectile speed secondary", 1) // Might as well use this one.

	if (projectilespeed != 1)
	{
		entity.SetAbsVelocity(entity.GetAbsVelocity() * projectilespeed)
	}
}