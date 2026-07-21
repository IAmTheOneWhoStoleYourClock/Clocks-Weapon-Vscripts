// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

IncludeScript("lib/clocksutils.nut")

::WearerModEventTable <- {
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ValidateScriptScope()

		// GetWearableAttribute
		AttributeWeaponInSlot(player, 0, "clip size VSCRIPT", GetWearableAttribute(player, "primary clip size",1))
		AttributeWeaponInSlot(player, 1, "clip size VSCRIPT", GetWearableAttribute(player, "secondary clip size",1))
		AttributeWeaponInSlot(player, 2, "clip size VSCRIPT", GetWearableAttribute(player, "melee clip size",1)) // ?
		AttributeWeaponInSlot(player, 3, "clip size VSCRIPT", GetWearableAttribute(player, "pda clip size",1))
		AttributeWeaponInSlot(player, 4, "clip size VSCRIPT", GetWearableAttribute(player, "pda2 clip size",1))
		AttributeWeaponInSlot(player, 5, "clip size VSCRIPT", GetWearableAttribute(player, "utility clip size",1))

		AttributeWeaponInSlot(player, 0, "damage VSCRIPT", GetWearableAttribute(player, "primary damage",1))
		AttributeWeaponInSlot(player, 1, "damage VSCRIPT", GetWearableAttribute(player, "secondary damage",1))
		AttributeWeaponInSlot(player, 2, "damage VSCRIPT", GetWearableAttribute(player, "melee damage",1))
		AttributeWeaponInSlot(player, 3, "damage VSCRIPT", GetWearableAttribute(player, "pda damage",1))
		AttributeWeaponInSlot(player, 4, "damage VSCRIPT", GetWearableAttribute(player, "pda2 damage",1))
		AttributeWeaponInSlot(player, 5, "damage VSCRIPT", GetWearableAttribute(player, "utility damage",1))

		AttributeWeaponInSlot(player, 2, "swing speed VSCRIPT", GetWearableAttribute(player, "melee swing speed",1))

		local wearerhealonkill = GetWearableAttribute(player, "heal on kill wearer", 0)
		if (wearerhealonkill)
		{
			AddWearerAttribute(player, "heal on kill VSCRIPT", wearerhealonkill)
		}
	}
}

__CollectGameEventCallbacks(WearerModEventTable)

IncludeScript("lib/mapbasehookcollector.nut")