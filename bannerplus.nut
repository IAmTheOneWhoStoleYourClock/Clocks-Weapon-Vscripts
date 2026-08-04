// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None.
//

IncludeScript("lib/clocksutils.nut");

PrecacheModel("models/weapons/c_models/c_samurai_soldier_arms.mdl")
PrecacheModel("models/weapons/c_models/c_chest_buffbanner/c_chest_buffbanner.mdl")
PrecacheModel("models/weapons/c_models/c_seige_buffbanner/c_seige_buffbanner.mdl")
PrecacheModel("models/weapons/c_models/c_backrack_buffbanner/c_backrack_buffbanner.mdl")
PrecacheScriptSound(")player/pl_scout_dodge_can_drink.wav")

MAXWEAPONS <- 8
BannerBoomOffset <- Vector(0, 0, 30)

::BuffBannerEventTable <- {
	// Event that runs whenever a banner activiates. Conveinent!
	function OnGameEvent_deploy_buff_banner(params)
	{
		local player = GetPlayerFromUserID(params.buff_owner)
		local scriptscope = player.GetOrCreatePrivateScriptScope()
		local weapon = player.GetActiveWeapon()
		local bannertime = (GetWearableAttribute(player,"increase buff duration", 1) * 10 * GetWearableAttribute(player,"decrease buff duration", 1))
		local speedup = GetWearableAttribute(player,"banner speed", 1)
		if (speedup != 1)
		{
			// Some of these will have bannertime + 1, because the effect actually ends in bannertime + 1 seconds, where as the banner itself stops at bannertime
			player.AddCustomAttribute("major move speed bonus", speedup, bannertime + 1)
		}
		local condition = weapon.GetAttribute("banner effect", 0)
		if (condition != 0)
		{
			player.AddCondEx(condition, bannertime + 1, player)
		}
		// Why did I make it "display duck leaderboard"? Whatever, i'll just keep it like that.
		// Anyways, for whatever reason, condition 72 doesn't buff melees at all? This fixes that.
		local meleebuff = weapon.GetAttribute("display duck leaderboard", 0)
		if (meleebuff != 0)
		{
			// TO DO: Make this give a particle effect to the player!
			// Go through all of our weapons.
			for (local i = 0; i < MAXWEAPONS; i++)
			{
				local held_weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
				if (held_weapon == null)
					continue
				local classname = held_weapon.GetClassname()
				// If it's a melee, apply the effect
				if (MeleeWeapons.find(classname) != null)
				{
					// Be more stringent on time here since a random melee crit at the end with the effect will nearly ENTIRELY fill up the meter.
					held_weapon.AddAttribute("CARD: damage bonus", 1.538, bannertime)
					held_weapon.AddAttribute("melee attack rate bonus", 0.8, bannertime)
					EntFireByHandle(held_weapon, "CallScriptFunction", "RemoveMeleeRageBuff", bannertime, null, null)
				}
			}
		}
		local maxheads = weapon.GetAttribute("banner heads", 0)
		local loot = scriptscope.loot
		local headcount = weapon.GetAttribute("banner heads cap", 0)
		if (maxheads != 0 && loot < headcount)
		{
			scriptscope.loot += 1
			local boostperloot = pow(maxheads,1/headcount)
			DisplayStackBuildText(player, "Loot: " + loot.tostring())
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
					held_weapon.AddAttribute("melee attack rate bonus", pow(pow(maxheads/1.25,1/headcount),loot), 0)
					held_weapon.AddAttribute("mult melee smack delay VSCRIPT", pow(boostperloot,loot), 0) // Originally this was boosted the same amount as the atack rate was boosted, but that felt weird.
				}
			}
		}
		local explodedummy = weapon.GetAttribute("brick explodes", 0)
		if (explodedummy != 0)
		{
			EntFireByHandle(weapon, "CallScriptFunction", "ExplodeThink2", 0, player, null) // AUGH WHY WILL IT JUST NOT DO THE EFFECT!!!! AUGHHHHHHHHHHHHHHHHHHHHH
		}

		if (player.GetPlayerClass() != Constants.ETFClass.TF_CLASS_SOLDIER)
		{
			// TO DO: Is there a better way to do this?
			DisplayTimer(player, bannertime)
		}
	}
	// Event that runs whenever a player is hurt. Hooking into this to alter rage.
	function OnGameEvent_player_hurt(params)
	{
		local player = GetPlayerFromUserID(params.attacker)
		if (!player || !player.IsValid() || !player.IsPlayer() || !player.IsAlive() || player.IsRageDraining())
		{
			return
		}

		// Grab the banner. If we don't have a banner, or we don't need to adjust the rage rate anyways, ignore this.
		local banner = GetWeaponByClass(player, "tf_weapon_buff_item")
		local bannerate = GetWearableAttribute(player, "banner rate", 1)
		if (!banner || bannerate == 1)
		{
			return
		}
		
		// Grab the damaging weapon, if the weapon is even valid.
		local weapon
		if (params.weaponid != null && params.weaponid < 2000)
		{
			weapon = GetWeaponByClassID(player, params.weaponid)
		}
		else
		{
			weapon = null
		}

		// How much rage it'll be before the change takes effect. Since it hasn't yet, we can just grab the rage normally.
		local rage = player.GetRageMeter()

		// Calcuate how much the rage is going to be given after the damage. Fairly trival, since there's only 2 things that can effect it.
		local newrage = rage + (params.damageamount / (banner.GetAttribute("mod soldier buff type",0) != 3 ? 6.0 : 4.8))
		// rage_on_hit does not scale with rage rate scaling in the base game, but I've decided that it should here.
		if (weapon)
		{
			newrage += weapon.GetAttribute("mod rage on hit bonus",0) + weapon.GetAttribute("mod rage on hit penalty",0) // Whatever was the penalty version of this for?
		}
		
		// The amount of rage we want is simply the additional rage times our build rate.
		local desiredrage = ((newrage - rage) * bannerate) + rage

		// Now to actually set the rage. If this is soldier, we need to do a different calculation
		if (player.GetPlayerClass() == Constants.ETFClass.TF_CLASS_SOLDIER)
		{
			// Set the Rage Meter in a way to compensate for the upcoming increase it is about to receive.
			// Note that there is NO lower cap to this! This is to make sure it works with slower build rates when they are at low rage, but will break the game if the charge rate goes to the negatives somehow!
			player.SetRageMeter(min(rage + desiredrage - newrage,100))
		}
		else
		{
			// For everybody else, just set the meter to what we're looking for.
			desiredrage = min(desiredrage,100)
			player.SetRageMeter(min(desiredrage,100))
			// TO DO: Is there a better way to do this?
			DisplayRageBuildText(player, "Rage: " + format("%.1f", desiredrage).tostring())
		}
	}
	// Event that runs whenever there's the potential for an item change
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		local scriptscope = player.GetOrCreatePrivateScriptScope()

		// If the player can't loot, get rid of the stuff
		local maxheads = GetWearableAttribute(player,"banner heads", 0)
		if (maxheads == 0)
		{
			if (scriptscope.loot != 0)
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

				DisplayStackBuildText(player, "")
				scriptscope.loot = 0
			}
		}
		// If they can, reapply their current boost
		else if (scriptscope.loot != 0)
		{
			local loot = scriptscope.loot
			local headcount = GetWearableAttribute(player,"banner heads cap", 0)
			local boostperloot = pow(maxheads,1/headcount)
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
					held_weapon.AddAttribute("melee attack rate bonus", pow(pow(maxheads/1.25,1/headcount),loot), 0)
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

		// If this is a banner that gives minihaste-
		if (params.buff_type == 113)
		{
			player.AddCondEx(139, 1, owner) // Give it this condition so that there's a visual identifier!
		}

		local bannerdefense = GetWearableAttribute(owner,"banner defense", 1)
		if (bannerdefense)
		{
			player.AddCustomAttribute("dmg taken increased", bannerdefense, 1)
		}

		// If this a banner that gives ammo, give it now.
		local bannerammo = GetWearableAttribute(owner,"banner ammo", 0)
		if (bannerammo)
		{
			local i = 1
			local playedsound = false
			// For the three main ammo types
			while (i < 4)
			{
				// Get their current ammo
				local ammoprev = player.GetAmmoCount(i)
				// Fill up their ammo to the maximum
				local k = 4096
				while (k >= 1)
				{
					medigunscope.target.GiveAmmo(k, i, true)
					k *= 0.5
				}
				// Get the maximum
				local max = player.GetAmmoCount(i)
				// Set the ammo to 0
				player.SetAmmoCount(i, 0)
				// Give them back their ammo + their maximum ammo times the banner ammount. Also play the sound if we haven't yet.
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
		// Scriptscopes are pretty much what they sound like, just storing what the entity is in the scope of this script. Also, they allow for things to be mapbase hooked.
		// Honestly storing it in script scope is fairly interchangable with contexts from a coding perspective, but I'm just doing it like this... because I feel like it.
		// No idea which is more efficent, don't really care.
		local scriptscope = player.GetOrCreatePrivateScriptScope()
		scriptscope.loot <- 0
		player.PrecacheModel("models/weapons/c_models/c_samurai_soldier_arms.mdl") //Grand design arm model. I'm just going to pull a Volvo and manually hard code this.
		player.PrecacheModel("models/weapons/c_models/c_chest_buffbanner/c_chest_buffbanner.mdl")
		player.PrecacheModel("models/weapons/c_models/c_seige_buffbanner/c_seige_buffbanner.mdl")
		player.PrecacheModel("models/weapons/c_models/c_backrack_buffbanner/c_backrack_buffbanner.mdl")
	}
	function OnGameEvent_player_death(params)
	{
		// If the player dies, remove all loot. Ripperonie.
		local player = GetPlayerFromUserID(params.userid)
		local scriptscope = player.GetOrCreatePrivateScriptScope()
		scriptscope.loot <- 0
	}
}

// Actually gets the events to work.
__CollectGameEventCallbacks(BuffBannerEventTable)

//
// Prevent the user from holding down certain banners
//

// Unfortunately being able to hold it is a quirk of how it is implemented itself, so I have to manually disable the ability to hold the button myself.
// Add script scope to any banners
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

	if (entity.GetClassname() == "tf_weapon_buff_item")
	{
		entity.ValidateScriptScope()
	}
}

// If this makes its sound (meaning it is being used) and we're not allowed to hold it, set a think that will remove the ability to hold it.
function ModifyEmitSoundParams(self,params)
{
	if (self.IsValid() && self.GetClassname() == "tf_weapon_buff_item" && self.GetAttribute("no banner hold", 0) != 0 && params.GetSoundName() != "Weapon_BuffBanner.Flag" && !startswith(params.GetSoundName(), "player/footsteps")) // Why is the BANNER making FOOTSTEP sounds!?!?!?!?!?
	{
		self.SetContextThink("NoHold", NoHold, 0.5)
	}
}

// Then set a second think that will reenable the ability to press the button.
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

// Removes the buff to the melees.
function RemoveMeleeRageBuff()
{
	self.RemoveAttribute("CARD: damage bonus")
	self.RemoveAttribute("melee attack rate bonus")
}

// I don't think the particles here work correctly tbh but good enough.
function ExplodeThink2()
{
	DispatchParticleEffect( "explosionTrail_seeds_mvm", self.GetOrigin(), self.GetAbsAngles(), self)
	DispatchParticleEffect( "fluidSmokeExpl_ring_mvm", self.GetOrigin(), self.GetAbsAngles(), self)
	ExplodeNowBanner(self, activator)
}

PrecacheParticleSystem("explosionTrail_seeds_mvm")
PrecacheParticleSystem("fluidSmokeExpl_ring_mvm")

// Just summon a pipe and immediately blow it up.
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

IncludeScript("lib/mapbasehookcollector.nut")