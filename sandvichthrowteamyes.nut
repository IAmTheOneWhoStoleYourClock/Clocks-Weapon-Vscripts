// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

IncludeScript("lib/clocksutils.nut");

MAXWEAPONS <- 8

Entities.EnableEntityListening()
Hooks.Add(this, "OnEntitySpawned", function(entity)
{
	entity.SetContextThink("EntitySpawnSandvichThrowTeamYes", EntitySpawnSandvichThrowTeamYes, 0.01);
}, "EntitySpawnSandvichThrowTeamYes" );

function EntitySpawnSandvichThrowTeamYes(entity)
{
	if (!entity || !entity.IsValid())
	{
		return
	}

	if (!startswith(entity.GetClassname(),"item_health"))
	{
		return
	}


	if(entity.GetOwner() != null && entity.GetOwner().IsPlayer())
	{
		entity.SetSkin(entity.GetOwner().GetTeam() - 2)
		if (GetWearableAttribute(entity.GetOwner(), "Revolutionary unique stat", 0) > 0)
		{
			entity.SetOwner(Entities.First())
		}
	}
}