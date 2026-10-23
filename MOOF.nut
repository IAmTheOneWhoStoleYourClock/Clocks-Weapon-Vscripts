// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

Entities.EnableEntityListening()
Hooks.Add(this, "OnEntitySpawned", function(entity)
{
	FunctionInTime(EntitySpawnMOOF, 0, [entity]);
}, "EntitySpawnMOOF" );

function EntitySpawnMOOF(entity)
{
	if (!entity || !entity.IsValid() || !entity.GetOwner())
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