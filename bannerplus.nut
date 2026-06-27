// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None.
//

PrecacheModel("models/weapons/c_models/c_samurai_soldier_arms.mdl")
PrecacheModel("models/weapons/c_models/c_chest_buffbanner/c_chest_buffbanner.mdl")
PrecacheModel("models/weapons/c_models/c_seige_buffbanner/c_seige_buffbanner.mdl")
PrecacheModel("models/weapons/c_models/c_backrack_buffbanner/c_backrack_buffbanner.mdl")
PrecacheScriptSound(")player/pl_scout_dodge_can_drink.wav")

MAXWEAPONS <- 8
BannerBoomOffset <- Vector(0, 0, 30)

::BuffBannerEventTable <- {
	function OnGameEvent_round_start(params)
	{
		LootText <- SpawnEntityFromTable("game_text", {
			message = "If you're seeing this, something's gone wrong",
			x = 0.9,
			y = 0.8,
			effect = 0,
			color = "255 255 255",
			fadein = 0.5,
			holdtime = 9999.0
		});
	}
	function OnGameEvent_deploy_buff_banner(params)
	{
		local player = GetPlayerFromUserID(params.buff_owner)
		local weapon = player.GetActiveWeapon()
		local bannertime = (GetWearableAttribute(player,"increase buff duration", 1) * 10 * GetWearableAttribute(player,"decrease buff duration", 1)) + 0.5
		local speedup = GetWearableAttribute(player,"banner speed", 1)
		if (speedup != 1)
		{
			player.AddCustomAttribute("major move speed bonus", speedup, bannertime)
		}
		local condition = weapon.GetAttribute("banner effect", 0)
		if (condition != 0)
		{
			player.AddCondEx(condition, bannertime, player)
		}
		local meleebuff = weapon.GetAttribute("display duck leaderboard", 0)
		if (meleebuff != 0)
		{
			for (local i = 0; i < MAXWEAPONS; i++)
			{
				local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
				if (held_weapon == null)
					continue
				local classname = held_weapon.GetClassname()
				if (classname == "tf_weapon_shovel" || classname == "tf_weapon_sword")
				{
					held_weapon.AddAttribute("CARD: damage bonus", 1.538, bannertime - 0.5) // The time limiter doesn't work. Shame.
					held_weapon.AddAttribute("melee attack rate bonus", 0.8, bannertime - 0.5)
					EntFireByHandle(held_weapon, "CallScriptFunction", "RemoveMeleeRageBuff", bannertime - 0.5, null, null) // Be more stringent on time here since a random melee crit at the end with the effect will nearly ENTIRELY fill up the meter.
				}
			}
		}
		local duckrating = weapon.GetAttribute("banner heads", 0)
		local loot = player.GetContext("Loot").tointeger()
		local headcount = weapon.GetAttribute("banner heads cap", 0)
		if (duckrating != 0 && loot < headcount)
		{
			loot += 1
			local boostperloot = pow(duckrating,1/headcount)
			player.AddContext("Loot", loot.tostring(), 0)
			LootText.AcceptInput("settext", "Loot: " + loot.tostring(),player,null)
			LootText.AcceptInput("Display", "",player,null)
			player.AddCustomAttribute("halloween fire rate bonus", pow(boostperloot, loot), 0)
			player.AddCustomAttribute("halloween reload time decreased", pow(boostperloot, loot), 0)
			for (local i = 0; i < MAXWEAPONS; i++)
			{
				local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
				if (held_weapon == null)
					continue
				local classname = held_weapon.GetClassname()
				if (classname == "tf_weapon_shovel" || classname == "tf_weapon_sword")
				{
					held_weapon.AddAttribute("melee attack rate bonus", pow(pow(duckrating/1.25,1/headcount),loot), 0)
					held_weapon.AddAttribute("mult melee smack delay VSCRIPT", pow(boostperloot,loot), 0) // Originally this was boosted the same amount as the atack rate was boosted, but that felt weird.
				}
			}
		}
		local explodedummy = weapon.GetAttribute("brick explodes", 0)
		if (explodedummy != 0)
		{
			EntFireByHandle(weapon, "CallScriptFunction", "ExplodeThink2", 0, player, null) // AUGH WHY WILL IT JUST NOT DO THE EFFECT!!!! AUGHHHHHHHHHHHHHHHHHHHHH
		}
	}
	function OnGameEvent_player_hurt(params)
	{
		local player = GetPlayerFromUserID(params.attacker)
		if (!player || !player.IsValid() || !player.IsPlayer() || player.IsRageDraining())
		{
			return
		}
		player.AddContext("BannerCurr", player.GetRageMeter().tostring(), 0)
		player.SetContextThink("RageThink", RageThink, 0.0015)
	}
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		local duckrating = GetWearableAttribute(player,"banner heads", 0)
		if (duckrating == 0)
		{
			if (player.GetContext("Loot") == "0")
			{
				player.RemoveCustomAttribute("halloween fire rate bonus")
				player.RemoveCustomAttribute("halloween reload time decreased")
				for (local i = 0; i < MAXWEAPONS; i++)
				{
					local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
					if (held_weapon == null)
						continue
					local classname = held_weapon.GetClassname()
					if (classname == "tf_weapon_shovel" || classname == "tf_weapon_sword")
					{
						held_weapon.RemoveAttribute("melee attack rate bonus")
						held_weapon.RemoveAttribute("mult melee smack delay VSCRIPT")
					}
				}
				LootText.AcceptInput("settext", "",player,null)
				LootText.AcceptInput("Display", "",player,null)
				player.AddContext("Loot", "0", 0)
			}
		}
		else if (player.GetContext("Loot") != "0")
		{
			local loot = player.GetContext("Loot").tointeger()
			local headcount = GetWearableAttribute(player,"banner heads cap", 0)
			local boostperloot = pow(duckrating,1/headcount)
			player.AddCustomAttribute("halloween fire rate bonus", pow(boostperloot, loot), 0)
			player.AddCustomAttribute("halloween reload time decreased", pow(boostperloot, loot), 0)
			for (local i = 0; i < MAXWEAPONS; i++)
			{
				local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
				if (held_weapon == null)
					continue
				local classname = held_weapon.GetClassname()
				if (classname == "tf_weapon_shovel" || classname == "tf_weapon_sword")
				{
					held_weapon.AddAttribute("melee attack rate bonus", pow(pow(duckrating/1.25,1/headcount),loot), 0)
					held_weapon.AddAttribute("mult melee smack delay VSCRIPT", pow(boostperloot,loot), 0)
				}
			}
		}
	}
	function OnGameEvent_player_buff(params)
	{
		if (params.buff_owner == null)
		{
			return
		}
		if (params.buff_type == null)
		{
			return
		}
		local player = GetPlayerFromUserID(params.userid)
		local owner = GetPlayerFromUserID(params.buff_owner)
		if (!player || !player.IsValid() || !player.IsPlayer() || !owner || !owner.IsValid() || !owner.IsPlayer() || !owner.IsRageDraining())
		{
			return
		}
		if (player.InCond(113))
		{
			player.AddCondEx(139, 1, owner) // So that there's a visual identifier!
		}
		local bannerammo = GetWearableAttribute(player,	"banner ammo", 0)
		if (bannerammo)
		{
			local i = 1
			local playedsound = false
			while (i < 4)
			{
				local ammoprev = player.GetAmmoCount(i)
				local k = 1
				while (k != 0)
				{
					k = player.GiveAmmo(1, i, true)
				}
				local max = player.GetAmmoCount(i)
				player.SetAmmoCount(i, 0)
				if (!playedsound && ammoprev != max)
				{
					player.GiveAmmo(floor(min(ammoprev + max * bannerammo, max)), i, false)
					playedsound = true
				}
				else
				{
					player.GiveAmmo(floor(min(ammoprev + max * bannerammo, max)), i, true)
				}
				i += 1
			}
		}
	}
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		if (player.GetContext("Loot") != "")
		{
			player.AddContext("Loot", "0", 0)
		}
		player.PrecacheModel("models/weapons/c_models/c_samurai_soldier_arms.mdl") //Grand design arm model. I'm just going to pull a Volvo and manually hard code this.
		player.PrecacheModel("models/weapons/c_models/c_chest_buffbanner/c_chest_buffbanner.mdl")
		player.PrecacheModel("models/weapons/c_models/c_seige_buffbanner/c_seige_buffbanner.mdl")
		player.PrecacheModel("models/weapons/c_models/c_backrack_buffbanner/c_backrack_buffbanner.mdl")
	}
	function OnGameEvent_player_death(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.AddContext("Loot", "0", 0)
	}
}

Entities.EnableEntityListening()
Hooks.Add(this, "OnEntitySpawned", function(entity)
{
	EntitySpawnValidateBanner(entity)
}, "ValidateBanner" )

function EntitySpawnValidateBanner(entity)
{
	if (!entity || !entity.IsValid())
	{
		return
	}

	local classname = entity.GetClassname()

	if (classname == "tf_weapon_buff_item")
	{
		entity.ValidateScriptScope()
	}
}

function ModifyEmitSoundParams() // Unfortunately being able to hold it is a quirk of how it is implemented itself, so I have to manually diable the ability to hold the button myself.
{
	if (self.IsValid() && self.GetClassname() == "tf_weapon_buff_item" && self.GetAttribute("no banner hold", 0) != 0 && params.GetSoundName() != "Weapon_BuffBanner.Flag" && !startswith(params.GetSoundName(), "player/footsteps")) // Why is the BANNER making FOOTSTEP sounds!?!?!?!?!?
	{
		self.SetContextThink("NoHold", NoHold, 0.5)
	}
}

function NoHold(self)
{
	if (self.GetOwner().GetActiveWeapon() == self)
	{
		self.GetOwner().DisableButtons(1)
		self.GetOwner().SetContextThink("Reenable", Reenable, 2.1)
	}
}

function Reenable(self)
{
	self.EnableButtons(1)
}

function RageThink(player)
{
	if (player.GetRageMeter() == 0)
	{
		return
	}
	local bannerrate =  GetWearableAttribute(player, "banner rate", 1)
	if (bannerrate == 1)
	{
		return
	}
	local hasbanner = false
	for (local i = 0; i < MAXWEAPONS; i++)
	{
		local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if (held_weapon == null)
			continue
		if (held_weapon.GetClassname() == "tf_weapon_buff_item")
		{
			hasbanner = true
			break
		}
	}
	if (hasbanner)
	{
		local bannercurr = player.GetContext("BannerCurr").tofloat()
		local banneradjust = min(((player.GetRageMeter() - bannercurr) * bannerrate) + bannercurr, 100)
		if (banneradjust + (10/bannerrate - 10) >= 100) // Stops banners with slower charge rates from getting "stuck"... hopefully.
		{
			banneradjust = 100
		}
		player.SetRageMeter(banneradjust)
	}
}

function RemoveMeleeRageBuff()
{
	self.RemoveAttribute("CARD: damage bonus")
	self.RemoveAttribute("melee attack rate bonus")
}

function ExplodeThink2()
{
	DispatchParticleEffect( "explosionTrail_seeds_mvm", self.GetOrigin(), self.GetAbsAngles(), self)
	DispatchParticleEffect( "fluidSmokeExpl_ring_mvm", self.GetOrigin(), self.GetAbsAngles(), self)
	ExplodeNowBanner(self, activator)
}
__CollectGameEventCallbacks(BuffBannerEventTable)

function GetWearableAttribute(player, attribname, basenum)
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

PrecacheParticleSystem("explosionTrail_seeds_mvm")
PrecacheParticleSystem("fluidSmokeExpl_ring_mvm")

function ExplodeNowBanner(banner, owner)
{
	local pipe = Entities.CreateByClassname("tf_projectile_pipe")
	NetProps.SetPropEntity(pipe, "m_hLauncher", banner)
	pipe.SetOrigin(owner.GetOrigin() + BannerBoomOffset)
	pipe.SetOwner(owner)
	pipe.SetThrower(owner)
	//pipe.GetDamage() // Not sure if this does anything, but i'm also not sure it doesn't do anything?
	pipe.SetDamage(300)
	pipe.GetDamageRadius()
	NetProps.SetPropEntity(pipe, "m_hOriginalLauncher", owner) // Gives it the correct explosion effect.
	pipe.AcceptInput("detonate", "", banner, owner)
}

::GivePlayerWeapon <- function(player, classname, item_id)
{
	local weapon = Entities.CreateByClassname(classname)
	NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", item_id)
	NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
	NetProps.SetPropBool(weapon, "m_bValidatedAttachedEntity", true)
	weapon.SetTeam(player.GetTeam())
	weapon.DispatchSpawn()

	player.Weapon_Equip(weapon)

	return weapon
}