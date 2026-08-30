// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// No known issues.
//

IncludeScript("lib/clocksutils.nut")

::ModelOverrideTable <- {
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		local model = GetWearableAttributeString(player, "player model override", "")
		if (model != "")
		{
			player.SetCustomModelWithClassAnimations(model) // The "with class animations" version for some reason applies the animations of the model, whereas the normal one leaves them with no animations whatsoever?
		}
	}
}

__CollectGameEventCallbacks(ModelOverrideTable)