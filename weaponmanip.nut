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
		local medievalmymode = GetWearableAttribute(player,"medieval my mode", 0)
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
		if (medievalmymode)
			MedievalMyMode(player)
	}
}

function MedievalMyMode(player)
{
	for (local i = 0; i < MAXWEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		local medieval = false
		if (MeleeWeapons.find(held_weapon.GetClassname()) != null && !held_weapon.GetAttribute("banned in medieval mode", 0))
		{
			medieval = true
		}
		else if (held_weapon.GetAttribute("allowed in medieval mode", 0))
		{
			medieval = true
		}

		if (!medieval)
		{
			NetProps.SetPropEntityArray(player, "m_hMyWeapons", null, i)
			if (player.GetActiveWeapon() == held_weapon)
			{
				local newweap
				local j = 0
				while (!(newweap = NetProps.GetPropEntityArray(player, "m_hMyWeapons", j)))
				{
					j += 1
				}
				player.Weapon_Switch(newweap)
			}
			held_weapon.Destroy()
		}
	}
	for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
	{
		if (wearable.GetClassname() != "tf_wearable")
			continue
		if (!wearable.GetAttribute("allowed in medieval mode", 0) && NetProps.GetPropInt(wearable, "m_AttributeManager.m_Item.m_iItemDefinitionIndex") != 65535)
		{
			wearable.Destroy()
		}
	}
}

__CollectGameEventCallbacks(WeaponManipTable)
