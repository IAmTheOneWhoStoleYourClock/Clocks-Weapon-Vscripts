// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// No known issues.
//

IncludeScript("lib/clocksutils.nut")

if (!("currentmodel" in getroottable())) {
	currentmodel <- array(PLAYERCAP, [])
}

BASEMODELS <- [
	"models/player/scout.mdl", //Scout
	"models/player/sniper.mdl", //Sniper
	"models/player/soldier.mdl", //Soldier
	"models/player/demo.mdl", //Demoman
	"models/player/medic.mdl",  //Medic
	"models/player/heavy.mdl",  //Heavy
	"models/player/pyro.mdl",  //Pyro
	"models/player/spy.mdl",  //Spy
	"models/player/engineer.mdl",  //Engineer
	"models/player/civilian.mdl",  //Civilian
]

::ModelOverrideTable <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ConnectOutput("OnUser3" "SwitchModelCheck")
	}
	function OnGameEvent_weapon_equipped(params)
	{
		local weapon = EntIndexToHScript(params.entindex)
		local player = weapon.GetOwner()
		if (!player)
		{
			return
		}
		local model = weapon.GetAttributeString("player model override", "")
		if (model != "")
		{
			player.SetCustomModelWithClassAnimations(model) // The "with class animations" version for some reason applies the animations of the model, whereas the normal one leaves them with no animations whatsoever?
			currentmodel[owner.GetEntityIndex()] = model
		}
	}
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		local model = GetWearableAttributeString(player, "player model override", "")
		if (model == "")
		{
			local activemodel = player.GetActiveWeapon().GetAttributeString("player model override active", "")
			if (activemodel != "")
			{
				player.SetCustomModelWithClassAnimations(activemodel) // The "with class animations" version for some reason applies the animations of the model, whereas the normal one leaves them with no animations whatsoever?
				currentmodel[player.GetEntityIndex()] = BASEMODELS[player.GetPlayerClass() - 1]
			}
			else
			{
				player.SetCustomModelWithClassAnimations(BASEMODELS[player.GetPlayerClass() - 1]) // The "with class animations" version for some reason applies the animations of the model, whereas the normal one leaves them with no animations whatsoever?
				currentmodel[player.GetEntityIndex()] = BASEMODELS[player.GetPlayerClass() - 1]
			}
		}
	}
}

function SwitchModelCheck()
{
	local activeoverride = self.GetActiveWeapon().GetAttributeString("player model override active", "")
	if (activeoverride != "")
	{
		self.SetCustomModelWithClassAnimations(activeoverride)
	}
	else
	{
		self.SetCustomModelWithClassAnimations(currentmodel[self.GetEntityIndex()])
	}
}

__CollectGameEventCallbacks(ModelOverrideTable)