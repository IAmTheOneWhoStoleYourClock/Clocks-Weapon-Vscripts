// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// This hyjacks the metal count in order to replenish replenishable super ammo types, meaning this breaks on engie. Not much to be done about that.
//

::SuperAmmoEventTable <- {
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		for (local i = 0; i < 8; i++)
		{
			local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (held_weapon == null)
				continue
			local superammotype = held_weapon.GetAttribute("super mod use custom ammo type", 0)
			if (superammotype != 0)
			{
				local superammomult = held_weapon.GetAttribute("super ammo mult", 1)
				player.SetAmmoCount(superammotype, 200 * superammomult)
				player.GiveAmmo(superammotype, 200 * superammomult, false)
				if (held_weapon.GetAttribute("super ammo replenish", 0) != 0)
				{
					player.SetContextThink("NOMETAL", NOMETAL, 0.1)
				}
			}
		}
	}
	function OnGameEvent_ammo_pickup(params)
	{
		// The way replenishing super ammo types is handled.
		if (params.ammo_index != 3)
		{
			return
		}
		foreach(weapon in superammoweapons)
		{
			local owner = weapon.GetOwner()
			local metal = owner.GetAmmoCount(3)
			local superammotype = weapon.GetAttribute("super mod use custom ammo type", 0)
			local newammo = min(owner.GetAmmoCount(superammotype) + metal, 200) * weapon.GetAttribute("super ammo mult", 1)
			NetProps.SetPropIntArray(owner, "m_iAmmo", newammo, superammotype)
		}
		foreach(weapon in superammoweapons)
		{
			local owner = weapon.GetOwner()
			NetProps.SetPropIntArray(owner, "m_iAmmo", 0, 3)
		}
	}
}

function NOMETAL(self)
{
	NetProps.SetPropIntArray(self, "m_iAmmo", 0, 3)
	player.SetAmmoCount(3, 200)
}

__CollectGameEventCallbacks(SuperAmmoEventTable)

superammoweapons <- []

Entities.EnableEntityListening()
Hooks.Add(this, "OnEntitySpawned", function(entity)
{
	EntitySpawnedSuperAmmo(entity)
}, "OnEntitySpawnedSuperAmmo" );

function EntitySpawnedSuperAmmo(entity)
{
	if (!entity || !entity.IsValid() || !entity.IsWeapon())
	{
		return
	}

	local superammotype = entity.GetAttribute("super mod use custom ammo type", 0)
	if (superammotype != 0)
	{
		NetProps.SetPropInt(entity, "m_iPrimaryAmmoType", superammotype)
		if (entity.GetAttribute("super ammo replenish", 0) != 0)
		{
			superammoweapons.append(entity)
		}
	}
}

Hooks.Add(this, "OnEntityDeleted", function(entity)
{
	OnEntityDeletedSuperAmmo(entity)
}, "OnEntityDeletedSuperAmmo" );

function OnEntityDeletedSuperAmmo(entity)
{
	local value = superammoweapons.find(entity)
	if (value != null)
	{
		superammoweapons.remove(value)
	}
}