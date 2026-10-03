// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// Linked items still get removed and readded on resupply. Might be able to fix that, but for now I don't care.
// Preventing automatically swapping to new weapons may cause conflicts with other scripts.
//

IncludeScript("lib/clocksutils.nut");

if (!("currentWeaponSlot" in getroottable())) {
	currentWeaponSlot <- array(PLAYERCAP, null)
}

::LinkedItemIdTable <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ConnectOutput("OnUser3" "CurrWeaponTrack")
	}
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		for (local i = 0; i < MAXWEAPONS; i++)
		{
			local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (held_weapon == null)
				continue
			EntitySpawnLinkedEquipStuff(held_weapon)
		}
		printl(player.GetActiveWeapon())
		if (player.GetActiveWeapon() == null)
		{
			printl("ran")
			player.Weapon_Switch(NetProps.GetPropEntityArray(player, "m_hMyWeapons", 0))
		}
	}
}

Entities.EnableEntityListening()

__CollectGameEventCallbacks(LinkedItemIdTable)

Entities.EnableEntityListening()
Hooks.Add(this, "OnEntityCreated", function(entity)
{
	entity.SetContextThink("EntitySpawnLinkedIDWearablesCatch", EntitySpawnLinkedIDWearablesCatch, 0.01); // Sadly there has to be a small delay here to let it initalize. This does mean that wearables finish processing after everything else.
}, "EntitySpawnLinkedIDWearablesCatch" );

function EntitySpawnLinkedIDWearablesCatch(entity)
{
	if (!entity || !entity.IsValid())
	{
		return
	}
	if (entity.GetClassname() == "tf_dropped_weapon")
	{
		EntFireByHandle(entity, "Kill", "", 0, null, null)
	}
	if (startswith(wearable.GetClassname(),"tf_wearable") && NetProps.GetPropInt(entity, "m_AttributeManager.m_Item.m_iItemDefinitionIndex") != 65535) // The later is succifient to check if this is an extra wearable.
	{
		local eventable = { entindex = entity.GetEntityIndex() }
		eventable.rawset("class", "tf_wearable") // Need to do it this way since I can't just put it in the table normally because class is a reserved keyword by squirrel
		SendGlobalGameEvent("weapon_equipped", eventable)
	}
}

function EntitySpawnLinkedEquipStuff(weapon)
{
	if (!weapon || !weapon.IsValid() || !weapon.IsWeapon())
	{
		return
	}
	local linkedid
	local player = weapon.GetOwner()
	local enabletactician = GetWearableAttribute(player, "tactician bonus enable", 0)
	linkedid = weapon.GetAttribute("linked item id", 0)

	// Ugh, if the weapon with tactian bonus is spawned AFTER (either via resupply or because you put it on a lower slot) we have to go through ALL OF THE WEAPONS AGAIN just to make sure we didn't miss anything.
	if (weapon.GetAttribute("tactician bonus enable", 0))
	{
		for (local i = 0; i < 8; i++)
		{
			local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (held_weapon != null && held_weapon.GetAttribute("linked item id tactician", 0))
			{
				EntitySpawnLinkedEquipStuff(held_weapon)
			}
		}
		for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
		{
			if (wearable.GetClassname() == "tf_wearable" && wearable.GetAttribute("linked item id tactician", 0))
			{
				EntitySpawnLinkedEquipStuff(wearable)
			}
		}
	}

	if (linkedid != 0)
	{
		GivePlayerWeapon(player, weapon.GetAttributeString("linked item class", ""), linkedid)
		return
	}
	linkedid = weapon.GetAttribute("linked item id tactician", 0)
	if (linkedid != 0 && enabletactician > 0)
	{
		GivePlayerWeapon(player, weapon.GetAttributeString("linked item class", ""), linkedid)
		return
	}
}

function GivePlayerWeapon(player, classname, item_id)
{
	local weapon = Entities.CreateByClassname(classname)
	local instaswitch = false
	NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", item_id)
	NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
	NetProps.SetPropBool(weapon, "m_bValidatedAttachedEntity", true)
	weapon.SetTeam(player.GetTeam())
	if (classname == "tf_weapon_builder")
	{
		NetProps.SetPropInt(weapon, "m_iObjectType", 0)
		NetProps.SetPropInt(weapon, "m_iObjectMode", 0)
		for (local i = 0; i < 5; i++)
		{
			NetProps.SetPropBoolArray(weapon, "m_aBuildableObjectTypes", true, i)
		}
	}
	weapon.DispatchSpawn()

	// remove existing weapon in same slot
	for (local i = 0; i < 8; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		if (held_weapon.GetSlot() != weapon.GetSlot())
			continue
		if (NetProps.GetPropInt(held_weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex") == item_id)
		{
			return false
		}
		instaswitch = true
		held_weapon.Destroy()
		NetProps.SetPropEntityArray(player, "m_hMyWeapons", null, i)
	}

	player.Weapon_Equip(weapon)
	printl(currentWeaponSlot[player.GetEntityIndex()])
	FunctionInTime(ForceSwitch, 0, [player, currentWeaponSlot[player.GetEntityIndex()]])
	player.AddCustomAttribute("deploy time decreased", -1, 0.015)

	return weapon
}

function ForceSwitch(player, slot)
{
	local weapon = GetWeaponInSlot(player, slot)
	if (weapon)
	{
		player.Weapon_Switch(weapon)
	}
	else
	{
		player.Weapon_Switch(NetProps.GetPropEntityArray(player, "m_hMyWeapons", 0))
	}
}

function CurrWeaponTrack()
{
	currentWeaponSlot[self.GetEntityIndex()] = self.GetActiveWeapon().GetSlot()
}