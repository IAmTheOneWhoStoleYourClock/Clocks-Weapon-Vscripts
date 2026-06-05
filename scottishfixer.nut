// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
// 

Entities.EnableEntityListening()
Hooks.Add(this, "OnEntitySpawned", function(entity)
{
	entity.SetContextThink("EntitySpawnScottishFixer", EntitySpawnScottishFixer, 0.01);
}, "Scottishfixer" );

function EntitySpawnScottishFixer(entity)
{
	if (!entity.IsValid())
	{
		return
	}

	if (entity.GetClassname() != "tf_projectile_pipe_remote")
	{
		return
	}

	if (entity.GetModelName() == "models/weapons/w_models/w_stickybomb_d.mdl")
	{
		entity.SetModelSimple("models/weapons/w_models/w_stickybomb_d_tf2c.mdl")
	}
}