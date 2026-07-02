// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None.
//

::GetWearableAttribute <- function(player, attribname, basenum)
{
	if (basenum != 0)
	{
		local returnvalue = basenum
		for (local i = 0; i < MAXWEAPONS; i++)
		{
			local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (held_weapon == null)
				continue
			returnvalue *= held_weapon.GetAttribute(attribname, 1)
		}
		for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
		{
			if (wearable.GetClassname() != "tf_wearable")
				continue
			returnvalue *= wearable.GetAttribute(attribname, 1)
		}
		returnvalue *= player.GetCustomAttribute(attribname, 1)
		return returnvalue
	}
	else
	{
		local returnvalue = 0
		for (local i = 0; i < MAXWEAPONS; i++)
		{
			local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (held_weapon == null)
				continue
			returnvalue += held_weapon.GetAttribute(attribname, 0)
		}
		for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
		{
			if (wearable.GetClassname() != "tf_wearable")
				continue
			returnvalue += wearable.GetAttribute(attribname, 0)
		}
		returnvalue += player.GetCustomAttribute(attribname, 0)
		return returnvalue
	}
}

::AddWearerAttribute <- function(player, attribname, value)
{
	for (local i = 0; i < MAXWEAPONS; i++) // Doesn't bother with wearables atm, have no reason to.
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		held_weapon.AddAttribute(attribname, value, 0)
	}
}

::RemoveWearerAttribute <- function(player, attribname)
{
	for (local i = 0; i < MAXWEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		held_weapon.RemoveAttribute(attribname)
	}
	for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
	{
		if (wearable.GetClassname() != "tf_wearable")
			continue
		wearable.RemoveAttribute(attribname)
	}
}