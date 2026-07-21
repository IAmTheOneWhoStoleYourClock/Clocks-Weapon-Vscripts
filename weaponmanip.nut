// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// Linked items still get removed and readded on resupply. Might be able to fix that, but for now I don't care.
// Preventing automatically swapping to new weapons may cause conflicts with other scripts.
//

IncludeScript("lib/clocksutils.nut");

::WeaponManipTable <- {
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)

		local noprimary = GetWearableAttribute(player,"no primary", 0)
		local nosecondary = GetWearableAttribute(player,"no secondary", 0)
		local nomelee = GetWearableAttribute(player,"no melee", 0) // Would really advise you NOT to do that but who am I to stop you I guess.
		local nopda = GetWearableAttribute(player,"no pda", 0)
		local nopda2 = GetWearableAttribute(player,"no pda2", 0)
		local noutility = GetWearableAttribute(player,"no utility", 0)
		if (noprimary)
			RemoveWeaponInSlot(player, 0)
		if (nosecondary)
			RemoveWeaponInSlot(player, 1)
		if (nomelee)
			RemoveWeaponInSlot(player, 2)
		if (nopda)
			RemoveWeaponInSlot(player, 3)
		if (nopda2)
			RemoveWeaponInSlot(player, 4)
		if (noutility)
			RemoveWeaponInSlot(player, 5)
	}
}

__CollectGameEventCallbacks(WeaponManipTable)
