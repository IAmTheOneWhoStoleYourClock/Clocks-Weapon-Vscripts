// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// The bomblet attributes's implmentation is messy overall, they seemingly don't remember the entity or weapon that created them...
// This probably isn't very well optimised. Especallly "proj detonate with rocket radius fix".
// Brick and Baseball model replacements can still clip through walls. This is a vanilla issue I was unable to fix, but it gets really exagerated by huge projectiles.
// tf_weapon_compound_bow and tf2c_weapon_coilgun can't be compensated for right now
// 

local GRENADES = ["tf_weapon_grenade_mirv_projectile", "tf_weapon_grenade_mirv_bomb", "tf_projectile_pipe", "tf_projectile_pipe_remote", "tf2c_projectile_brick", "tf2c_projectile_grenade_cyclops", "tf_projectile_ball_attributed", "tf_projectile_ball_ornament", "tf_projectile_stun_ball"];
local GRENADEDETONATORS = ["tf_projectile_arrow", "tf_projectile_energy_ring", "tf_projectile_flare", "tf_projectile_healing_bolt", "tf_projectile_balloffire", "tf_projectile_rocket", "tf_projectile_syringe", "tf2c_projectile_arrow", "tf2c_projectile_coil", "tf2c_projectile_dart", "tf2c_projectile_nail"];
local NONEXPLODEYGRENADES = ["tf2c_projectile_brick","tf_projectile_ball_attributed", "tf_projectile_ball_ornament", "tf_projectile_stun_ball"]
local SNIPERRIFLES = ["tf_weapon_sniperrifle","tf_weapon_sniperrifle_classic", "tf_weapon_sniperrifle_decap"]
local WEAPONCLASSBASEDAMAGE=
{
    tf_weapon_cannon=100
    tf_weapon_charged_smg=8
	tf_weapon_cleaver=5
	tf_weapon_compound_bow=-1//25
	tf_weapon_crossbow=75
	tf_weapon_drg_pompson=6
	tf_weapon_flaregun=30
	tf_weapon_flaregun_revenge=30
	tf_weapon_grenade_mirv=180
	tf_weapon_grenadelauncher=100
	tf_weapon_handgun_scout_primary=12
	tf_weapon_handgun_scout_secondary=15
	tf_weapon_particle_cannon=90
	tf_weapon_pipebomblauncher=190
	tf_weapon_pistol=15
	tf_weapon_pistol_scout=15
	tf_weapon_raygun=6
	tf_weapon_revolver=40
	tf_weapon_rocketlauncher=90
	tf_weapon_rocketlauncher_airstrike=90
	tf_weapon_rocketlauncher_directhit=90
	tf_weapon_rocketlauncher_fireball=90
	tf_weapon_scattergun=6
	tf_weapon_sentry_revenge=6
	tf_weapon_shotgun_building_rescue=40
	tf_weapon_shotgun_hwg=6
	tf_weapon_shotgun_primary=6
	tf_weapon_shotgun_pyro=6
	tf_weapon_shotgun_soldier=6
	tf_weapon_smg=8
	tf_weapon_sniperrifle=50
	tf_weapon_sniperrifle_classic=50
	tf_weapon_sniperrifle_decap=50
	tf_weapon_soda_popper=6
	tf_weapon_syringegun_medic=10
	tf2c_weapon_aagun=60
	tf2c_weapon_brick=65
	tf2c_weapon_coilgun=-1//25
	tf2c_weapon_cyclops=100
	tf2c_weapon_doubleshotgun=4.005 //Why is it so specific?
	tf2c_weapon_hunting_revolver=40
	tf2c_weapon_nailgun=12
	tf2c_weapon_tranq=20
}
local HIGHEST_SOLID_FLAG = 1028

IncludeScript("lib/clocksutils.nut")

Convars.RegisterConvar("GFA_projdeteonatefrequency", "0.09", "How long the delay should be between every ''proj detonate with rocket radius fix'' check.", 1)

// Corrects the kill icon of brick explodes and the damage of the pipe
::MyEventTable1 <- {
	function OnScriptHook_OnTakeDamage(params)
	{
		if (params.inflictor == null)
		{
			return
		}
		else if (params.attacker == null)
		{
			return
		}
		else if (params.weapon == null)
		{
			return
		}
		else if (params.const_entity == params.attacker)
		{
			return
		}
		else if (params.inflictor.GetClassname() == "tf_projectile_pipe")
		{
			if (params.inflictor.GetContext("IsBrickExplodeFixPipe") == "yep")
			{
				params.inflictor = NetProps.GetPropEntity(params.inflictor, "m_hEffectEntity")
				params.damage_custom = 0
			}
		}
		if (params.inflictor.GetContext("BombExplodedByRocket") == "ye")
		{
			// TO DO: Should this apply to the user? As it stands it does...
			params.damage = params.damage * params.inflictor.GetContext("RocketDetonateDamage").tofloat()
		}
	}
}

__CollectGameEventCallbacks(MyEventTable1)

Entities.EnableEntityListening()
Hooks.Add(this, "OnEntitySpawned", function(entity)
{
	EntitySpawn(entity)
}, "Grenadefixandadditions" );

function EntitySpawn(entity)
{
	if (!entity.IsValid())
	{
		return
	}

	local classname = entity.GetClassname()

	if (GRENADES.find(classname) == null)
	{
		return
	}

	if (entity.GetThrower() == null) // Don't change grenades without an owner, whatever other source is spawning those can deal with that by itself.
	{
		return
	}

	local weapon = entity.GetThrower().GetActiveWeapon()

	if (NONEXPLODEYGRENADES.find(classname) != null)
	{
		weapon.AddAttribute("brick explodes", 0, 0) // Just in case people can't read
		local brickexplodesfix = weapon.GetAttribute("brick explodes fixed", 0)
		if (brickexplodesfix > 0)
		{
			EntFireByHandle(entity, "CallScriptFunction", "ExplodeNow", brickexplodesfix, null, null)
		}
		local brickreplace = weapon.GetAttribute("brick custom projectile", 0)
		if (brickreplace > 0)
		{
			local projectilename = ""
			if (brickreplace <= 1)
			{
				projectilename = weapon.GetWorldModel().slice(0,-4) + "_projectile.mdl"
			}
			else
			{
				projectilename = weapon.GetWorldModel()
			}

			entity.SetModel(projectilename)
		}
	}
	else if (classname == "tf_weapon_grenade_mirv_bomb")
	{
		// Unfortunately, bomblets do not remember their creators, so we have to keep track of which mirv this player most recently exploded.
		// I dont think it's possible to mess this up? Even if it is, it should require a level of precision that would only ever come up intentionally and in extremely neiche circumstances.
		local bomb = Entities.FindByClassnameNearest("tf_weapon_grenade_mirv_projectile", entity.GetOrigin(),10) // Interestingly, TF2 adds an additional 1 unit when spawning to the z axis, but TF2C seems to have removed this.
		if (bomb == null)
		{
			return
		}
		local weapondata = bomb.GetOrCreatePrivateScriptScope()
		local bombreplace = weapondata.customproj
		if (bombreplace > 0)
		{
			local projectilename = ""
			if (bombreplace <= 1)
			{
				projectilename = weapondata.modelname.slice(0,-4) + "_bomblet.mdl"
			}
			else if (bombreplace <= 2)
			{
				projectilename = weapondata.worldmodel.slice(0,-4) + "_bomblet.mdl"
			}
			else if (bombreplace <= 3)
			{
				projectilename = weapondata.modelname
			}
			else
			{
				projectilename = weapondata.worldmodel
			}

			entity.SetModel(projectilename)
			EntFireByHandle(entity, "CallScriptFunction", "ReplacePhysics", 0, null, null) // Wait a frame or it'll get overriden
		}

		// Bomblet versions of normal attribs go here
		local bombletdata = entity.GetOrCreatePrivateScriptScope()
		bombletdata.bombletfusemult <- weapondata.bombletfusemult
		bombletdata.bombletdamage <- weapondata.bombletdamage
		bombletdata.bombletradius <- weapondata.bombletfusemult
		bombletdata.bombletfuseadd <- weapondata.bombletradius
		bombletdata.bombletvelocity <- weapondata.bombletvelocity
		bombletdata.bombletvelocity <- weapondata.bombletvelocity
		bombletdata.weapon <- weapondata.weapon
		entity.AddContext("BombletAttributesGrenadesFix", bomb.GetContext("MirvLogWeaponDataGrenadeFix2"), 0.02)
		EntFireByHandle(entity, "CallScriptFunction", "BombletApplyAttribs", 0, null, null) // Wait a frame because it's not initalised yet

		return; // None of the rest of this is relevant to this and will just needlessly throw errors
	}
	else if (classname == "tf_weapon_grenade_mirv_projectile")
	{
		// TO DO: There's gotta be a better way of doing this...
		// Just incase this weapon gets removed, we still want to be able to access the data it had, so compile it all together now and add it as contexts to the MIRV
		local weapondata = entity.GetOrCreatePrivateScriptScope()
		weapondata.customproj <- weapon.GetAttribute("bomblet custom projectile", 0)
		weapondata.worldmodel <- weapon.GetWorldModel()
		weapondata.bombletfusemult <- weapon.GetAttribute("bomblet fuse bonus", 1)
		weapondata.bombletdamage <- weapon.GetAttribute("bomblet damage", 1)
		weapondata.bombletradius <- weapon.GetAttribute("bomblet blast radius", 1)
		weapondata.bombletfuseadd <- weapon.GetAttribute("bomblet fuse flat", 0)
		weapondata.bombletvelocity <- weapon.GetAttribute("mult bomblet velocity", 1)
		weapondata.modelname <- entity.GetModelName()
		weapondata.weapon <- weapon
		weapondata.fusemult <- weapon.GetAttribute("fuse bonus", 1)
		EntFireByHandle(entity, "CallScriptFunction", "MirvFuseFix", 0, null, null) // Wait a frame because it's not initalised yet

		// entity.ValidateScriptScope() // Should be unnessesary?
	}
	else if (classname == "tf_projectile_pipe_remote")
	{
	//	local playerstick = weapon.GetAttribute("stickies stick to players", 0) // Too complicated for me right now so this is scrapped, maybe a serperate plugin at some point?
	//	if (playerstick != 0){
	//		AddThinkToEnt(entity, "CheckStickyNearPlayer")
	//	}

		local stickyexplode = weapon.GetAttribute("stickybomb explode time", 0)
		if (stickyexplode != 0){
			NetProps.SetPropFloat(entity, "m_flDetonateTime", Time() + stickyexplode)
		}
	}

	local detonateradius = weapon.GetAttribute("proj detonate with rocket radius fix", 0)
	if (detonateradius != 0){
		EntFireByHandle(entity, "CallScriptFunction", "CheckBombNearRocket", 0, null, null) // I can't seem to set this as a think function properly (at least one that's not running unreasonably slow).
		entity.AddContext("CheckBombNearRocketTolerance", detonateradius.tostring(), 0)
		entity.AddContext("RocketDetonateDamage", weapon.GetAttribute("proj detonate with rocket radius dmg", 1).tostring(), 0)
	}

	local grenadetype = weapon.GetAttribute("override grenade type", 0)
	if (grenadetype != 0){
		NetProps.SetPropInt(entity, "m_iType", ceil(grenadetype) - 1)
	}

	local noexplode = weapon.GetAttribute("grenade not explode on impact true", 0)
	if (noexplode != 0){
		NetProps.SetPropInt(entity, "m_bTouched", 1)
	}

	local defensive = weapon.GetAttribute("defensive bomb", 0)
	if (defensive > 0){
		NetProps.SetPropInt(entity, "m_bDefensiveBomb", 1)
	}
	else if (defensive < 0){
		EntFireByHandle(entity, "CallScriptFunction", "NoDefense", 0, null, null)
	}

	local grenadescollide = weapon.GetAttribute("grenades collide", 0)
	if (grenadescollide != 0){
		entity.SetCollisionGroup(11)
	}

	local explodeonworldfixed = weapon.GetAttribute("explode on world", 0)
	if (explodeonworldfixed != 0){
		entity.AddContext("ExplodeOnWorld", "yeppers", 0)
	}

	local nograv = weapon.GetAttribute("no gravity", 0)
	if (nograv != 0){
		entity.AddContext("NoGravity", "thumbsup", 0)
	}

	local recalcbound = weapon.GetAttribute("scale bounding box", 0)
	if (recalcbound != 0)
	{
		if (recalcbound < 0)
		{
			entity.SetModelSimple(entity.GetModelName()) // Is there a better way to do this? Honestly, i'm not sure...
			recalcbound = -recalcbound
		}
		local maxvec = entity.GetBoundingMaxs()
		local minvec = entity.GetBoundingMins()

		if (recalcbound != 1)
		{
			maxvec *= recalcbound
			minvec *= recalcbound
		}

		local width = weapon.GetAttribute("BBoxWidth", 0)
		if (width != 0)
			maxvec.x = width
			maxvec.y = width
			minvec.x = width
			minvec.y = width
		local maxz = weapon.GetAttribute("BBoxMaxZ", 0)
		if (maxz != 0)
			maxvec.z = maxz
		local minz = weapon.GetAttribute("BBoxMinZ", 0)
		if (minz != 0)
			minvec.z = minz

		entity.SetSize(minvec, maxvec)
	}

	if (!weapon.GetAttribute("no physics fix", 0))
	{
		EntFireByHandle(entity, "CallScriptFunction", "ReplacePhysics", 0, null, null) // Wait a frame or it'll get overriden.
	}
}

//Cursed function because the one that's supposed to do this does not exist
function GetSolidFlags(entity)
{
	local solidflags = 0

	for(local i = 1; i <= HIGHEST_SOLID_FLAG; i*=2)
    {
        if (entity.IsSolidFlagSet(i))
		{
			solidflags += i
		}
    }

	return solidflags
}

function BombletApplyAttribs()
{
	local bombletdata = self.GetOrCreatePrivateScriptScope()
	local fuse = NetProps.GetPropFloat(self, "m_flDetonateTime") - Time()
	local fuseadjust = bombletdata.bombletfusemult
	local fuseflat = bombletdata.bombletfuseadd
	NetProps.SetPropFloat(self, "m_flDetonateTime", Time() + (fuse * fuseadjust) + fuseflat)

	local damageadjust = bombletdata.bombletdamage
	if (damageadjust != 1)
	{
		self.SetDamage(self.GetDamage()*damageadjust)
	}

	local radiusadjust = bombletdata.bombletradius
	
	// mult_explosion_radius affects this on wearer for some reason, which gets done inside self.GetDamageRadius() (I think) during the explosion process,
	// but since it multiplies with this I can just remove it now since doing self.GetDamageRadius() now gives me what it will be.
	NetProps.SetPropFloat(self, "m_DmgRadius", ((1369/(self.GetDamageRadius()))*radiusadjust)) // 37/(self.GetDamageRadius()/37)
	// NetProps.SetPropFloat(self, "m_DmgRadius", (37*radiusadjust))

	if (bombletdata.bombletvelocity != 1)
	{
		local velocity = GetPhysVelocity(self.GetPhysicsObject())
		velocity.x = velocity.x * bombletdata.bombletvelocity
		velocity.y = velocity.y * bombletdata.bombletvelocity
		velocity.z = velocity.z * bombletdata.bombletvelocity
		self.SetPhysVelocity(velocity)
	}
}

function ExplodeNow()
{
	local pipe = Entities.CreateByClassname("tf_projectile_pipe")
	self.AcceptInput("detonate", "", null, null)
	NetProps.SetPropEntity(pipe, "m_hLauncher", NetProps.GetPropEntity(self,"m_hLauncher")) //Makes the following work correctly.
	pipe.SetOrigin(self.GetOrigin()) // Set its position to that of the brick.
	pipe.SetOwner(self.GetOwner()) // Set its owner to that of the brick.
	pipe.SetThrower(self.GetThrower()) // Set its owner to that of the brick, again.
	//pipe.GetDamage() // Not sure if this does anything, but i'm also not sure it doesn't do anything?
	pipe.SetDamage(self.GetDamage()) // Corrects the damage.
	pipe.GetDamageRadius() // Corrects the radius. For some reason brick doesn't calculate its stat correctly but doing it like this does calculate it correctly since m_hLauncher is correct.
	NetProps.SetPropEntity(pipe, "m_hOriginalLauncher", NetProps.GetPropEntity(self,"m_hOriginalLauncher")) // Gives it the correct explosion effect.
	NetProps.SetPropEntity(pipe, "m_hDeflectOwner", NetProps.GetPropEntity(self,"m_hDeflectOwner")) // Deflect checks.
	NetProps.SetPropInt(pipe, "m_iDeflected", NetProps.GetPropInt(self,"m_iDeflected"))
	pipe.AddContext("IsBrickExplodeFixPipe", "yep", 0.1) // So we know that this is the brick explode pipe in damage calculations 
	NetProps.SetPropEntity(pipe, "m_hEffectEntity", self) // So the icon icon can be corrected
	pipe.AcceptInput("detonate", "", self, self.GetThrower())
	self.Destroy()
}

function ExplodeNowRocketDetonate(self)
{
	local pipe = Entities.CreateByClassname("tf_projectile_pipe") // Some changes to accomidate
	self.AcceptInput("detonate", "", null, null)
	NetProps.SetPropEntity(pipe, "m_hLauncher", NetProps.GetPropEntity(self,"m_hLauncher"))
	pipe.SetOrigin(self.GetOrigin())
	pipe.SetOwner(self.GetOwner())
	pipe.SetThrower(self.GetThrower())
	//pipe.GetDamage()
	pipe.SetDamage(self.GetDamage())
	pipe.SetDamageRadius(146) // Should be unnesesary but I had issues with the radius being really small with the baseballs.
	pipe.GetDamageRadius()
	NetProps.SetPropEntity(pipe, "m_hOriginalLauncher", NetProps.GetPropEntity(self,"m_hOriginalLauncher"))
	NetProps.SetPropEntity(pipe, "m_hDeflectOwner", NetProps.GetPropEntity(self,"m_hDeflectOwner"))
	NetProps.SetPropInt(pipe, "m_iDeflected", NetProps.GetPropInt(self,"m_iDeflected"))
	pipe.AddContext("IsBrickExplodeFixPipe", "yep", 0.1)
	NetProps.SetPropEntity(pipe, "m_hEffectEntity", self)

	pipe.AddContext("BombExplodedByRocket", "ye", 0.1) // Add the Rocket Detonate Damage back (There's probably a better way to do this, but I prefer this pathway for now)
	pipe.AddContext("RocketDetonateDamage", self.GetContext("RocketDetonateDamage"), 0.1)
	pipe.AcceptInput("detonate", "", self, self.GetThrower())
	self.Destroy()
}

function ReplacePhysics()
{
	local oldphysics = self.GetPhysicsObject()

	self.AddContext("CurrentDamageForFix", self.GetDamage().tostring(), 0) // To fix grenade damage, feel free to remove if that's now fixed.

	if (oldphysics.GetName() == self.GetName())
		return; //We have nothing more to do here

	oldphysics.EnableCollisions(false)
	local oldvelocity = GetPhysVelocity(oldphysics)
	local angle = self.GetAbsAngles()
	local oldavelocity = self.GetPhysAngularVelocity()
	local solid = self.GetSolid()
	local solidflags = GetSolidFlags(self)
	self.PhysicsDestroyObject()
	self.PhysicsInitNormal(solid,solidflags,false)
	local newphysics = self.GetPhysicsObject()
	SetPhysVelocity(newphysics, oldvelocity, oldavelocity)
	self.SetAbsAngles(angle)
	
	if (self.GetContext("NoGravity") == "thumbsup")
	{
		newphysics.EnableGravity(false)
	}
}

function VPhysicsCollision()
{
	if (self.GetContext("ExplodeOnWorld") == "yeppers")
	{
		if (NONEXPLODEYGRENADES.find(self.GetClassname()) == null)
		{
			self.AcceptInput("detonate", "", self, null)
		}
		else
		{
			ExplodeNow(self)
		}
	}
}

function NoDefense()
{
	NetProps.SetPropInt(self, "m_bDefensiveBomb", 0)
}

function MirvFuseFix()
{
	local weapondata = self.GetOrCreatePrivateScriptScope()
	NetProps.SetPropFloat(self, "m_flDetonateTime",((NetProps.GetPropFloat(self, "m_flDetonateTime") - Time()) * weapondata.fusemult)+Time())
}

function CheckBombNearRocket()
{
	// Have mercy on me
	if (!(self && self.IsValid()))
	{
		return
	}

	local selforigin = self.GetOrigin()
	local selfowner = self.GetThrower()
	local tolerance = self.GetContext("CheckBombNearRocketTolerance").tofloat()
	local entity
	for(local i = 0; i < GRENADEDETONATORS.len(); i++)
    {
        while(entity = Entities.FindByClassname(entity, GRENADEDETONATORS[i]))
		{
			if (entity.GetOwner() == selfowner)
			{
				if ((selforigin - entity.GetOrigin()).Length() <= tolerance)
				{
					self.AddContext("BombExplodedByRocket", "ye", 0.1)
					if (entity.GetClassname() == "tf_projectile_rocket") // If this is a rocket, blow it up.
					{
						entity.SetOrigin(self.GetOrigin())
						entity.AcceptInput("touch", "worldspawn", self, self.GetThrower())
					}
					else // Otherwise just remove it.
					{
						entity.Kill()
					}

					// Blow this up
					if (NONEXPLODEYGRENADES.find(self.GetClassname()) == null)
					{
						self.AcceptInput("detonate", "", self, null)
					}
					else
					{
						ExplodeNowRocketDetonate(self)
					}
					return // If this isn't done the rocket will explode twice... for some reason.
				}
			}
		}
    }

	if (self && self.IsValid())
	{
		EntFireByHandle(self, "CallScriptFunction", "CheckBombNearRocket", Convars.GetFloat("GFAprojdeteonatefrequency"), null, null) //TO DO: Does it need to check this fast, or can this be dialed back more?
	}
}

// SCRAPPED
function CheckStickyNearPlayer()
{
	if (NetProps.GetPropInt(self, "m_bTouched") == 0)
	{
		local nearbyplayer = Entities.FindByClassnameNearest("player", self.GetOrigin(),9999)
		if (nearbyplayer != null)
		{
			if (nearbyplayer.GetTeam() == self.GetTeam())
			{
				return
			}
			local selforigin = self.GetOrigin()
			local playerorigin = nearbyplayer.GetOrigin()
			if (IsWithinBounds(selforigin, playerorigin))
			{
				if (TraceLine(selforigin, playerorigin, self) == 1)
				{
					local physics = self.GetPhysicsObject()
					// Exactly as Volvo did it: https://github.com/ValveSoftware/source-sdk-2013/blob/3300848d8a25ef6403c91f82a4cd97d6daefbc06/src/game/shared/tf/tf_weapon_grenade_pipebomb.cpp#L699
					// ...and it doesn't even work! Thanks Volvo.
					physics.EnableMotion(false)
					self.SetParent(nearbyplayer, "")
					NetProps.SetPropInt(self, "m_bTouched", 1)
					AddThinkToEnt(self, "")
				}
			}
		}
	}
}

function IsWithinBounds(entity1, entity2)
{
	if (abs(entity1.x - entity2.x) > 36)
	{
		return false
	}
	else if (abs(entity1.y - entity2.y) > 36)
	{
		return false
	}
	else if (abs(entity1.z - entity2.z) > 80)
	{
		return false
	}
	else
	{
		return true
	}
}

IncludeScript("lib/mapbasehookcollector.nut")