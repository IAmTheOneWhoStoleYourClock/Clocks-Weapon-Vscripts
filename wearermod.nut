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

		for (local i = 0; i < MAXWEAPONS; i++)
		{
			local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (held_weapon == null)
				continue
			AttribMod(player, held_weapon)
		}
		local wd = 0
		for (local wearable = player.FirstMoveChild(); wearable != null && wd < 50; wearable = wearable.NextMovePeer())
		{
			wd += 1
			if (!startswith(wearable.GetClassname(),"tf_wearable") || NetProps.GetPropInt(wearable, "m_bDisguiseWearable"))
				continue
			AttribMod(player, wearable)
		}
	}
}

function AttribMod(player, weapon)
{
	local primaryattribs = ProcessStringAttrib(weapon.GetAttributeString(player, "primary attributes",""))
	if (primaryattribs[0] != "")
	{
		for (local i = 0; i < primaryattribs.len(); i += 2)
		{
			AttributeWeaponInSlot(player, 0, primaryattribs[i], primaryattribs[i+1])
		}
	}
	local secondaryattribs = ProcessStringAttrib(weapon.GetAttributeString(player, "secondary attributes",""))
	if (secondaryattribs[0] != "")
	{
		for (local i = 0; i < secondaryattribs.len(); i += 2)
		{
			AttributeWeaponInSlot(player, 1, secondaryattribs[i], secondaryattribs[i+1])
		}
	}
	local meleeattribs = ProcessStringAttrib(weapon.GetAttributeString(player, "melee attributes",""))
	if (meleeattribs[0] != "")
	{
		for (local i = 0; i < meleeattribs.len(); i += 2)
		{
			AttributeWeaponInSlot(player, 2, meleeattribs[i], meleeattribs[i+1])
		}
	}
	local pdaattribs = ProcessStringAttrib(weapon.GetAttributeString(player, "pda attributes",""))
	if (pdaattribs[0] != "")
	{
		for (local i = 0; i < pdaattribs.len(); i += 2)
		{
			AttributeWeaponInSlot(player, 3, pdaattribs[i], pdaattribs[i+1])
		}
	}
	local pda2attribs = ProcessStringAttrib(weapon.GetAttributeString(player, "pda2 attributes",""))
	if (pda2attribs[0] != "")
	{
		for (local i = 0; i < pda2attribs.len(); i += 2)
		{
			AttributeWeaponInSlot(player, 4, pda2attribs[i], pda2attribs[i+1])
		}
	}
	local utilityattribs = ProcessStringAttrib(weapon.GetAttributeString(player, "utility attributes",""))
	if (utilityattribs[0] != "")
	{
		for (local i = 0; i < utilityattribs.len(); i += 2)
		{
			AttributeWeaponInSlot(player, 5, utilityattribs[i], utilityattribs[i+1])
		}
	}
}

__CollectGameEventCallbacks(WearerModEventTable)

IncludeScript("lib/mapbasehookcollector.nut")