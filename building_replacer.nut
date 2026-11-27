// This is my library of functions. Just so I don't have to define things a bunch of imes in scripts.
IncludeScript("lib/clocksutils.nut")

// These are the constants. I'll explain them individually.

// This is one of the big things, a big tracker that keeps track of ALL buildings
// Technically, I could itterate through ALL buildings if I wanted to find them, but obviously this is much simpler to interact with and faster too!
// Also make sure this table doesn't already exist so it doesn't get wiped on accident, that would be bad...
if (!("playeractivebuildings" in getroottable())) {
	// Garbage I have to do, otherwise squirrel breaks and essentally unifies all players buildings
	playeractivebuildings <- []
	for (local i = 0; i < MaxPlayers(); i++)
	{
		playeractivebuildings.append([[],[],[],[],[],[]])
	}
	roundstart <- Time()
}

// An array of the class names of all of the buildings, self explanatory. Checked to determine building type index.
buildingtypes <- ["obj_sentrygun", "obj_dispenser", "obj_teleporter", "obj_jumppad"] // Its status as an entrance or exit is determined in GetBuilding

// A table that gets the "human readable" version of every object
buildingtypesconvert <- ["sentry","dispenser","entrance","exit","padA","padB"]

// The default health values of all buildings
buildingbasehealth <- [150,150,150,150,90,90]

// The default models of all buildings
buildingdefaults <- [
	["models/buildables/sentry1_blueprint.mdl", "models/buildables/sentry1_heavy.mdl", "models/buildables/sentry1.mdl", "models/buildables/sentry1_blueprint.mdl", "models/buildables/sentry2_heavy.mdl", "models/buildables/sentry2.mdl", "models/buildables/sentry1_blueprint.mdl", "models/buildables/sentry3_heavy.mdl", "models/buildables/sentry3.mdl"],
	["models/buildables/dispenser_blueprint.mdl", "models/buildables/dispenser.mdl", "models/buildables/dispenser_light.mdl", "models/buildables/dispenser_blueprint.mdl", "models/buildables/dispenser_lvl2.mdl", "models/buildables/dispenser_lvl2_light.mdl", "models/buildables/dispenser_blueprint.mdl", "models/buildables/dispenser_lvl3.mdl", "models/buildables/dispenser_lvl3_light.mdl"],
	["models/buildables/teleporter_blueprint_enter.mdl", "models/buildables/teleporter.mdl", "models/buildables/teleporter_light.mdl", "models/buildables/teleporter_blueprint_enter.mdl", "models/buildables/teleporter_light.mdl", "models/buildables/teleporter_light.mdl"],
	["models/buildables/teleporter_blueprint_exit.mdl", "models/buildables/teleporter.mdl", "models/buildables/teleporter_light.mdl", "models/buildables/teleporter_blueprint_exit.mdl", "models/buildables/teleporter_light.mdl", "models/buildables/teleporter_light.mdl"],
	["models/buildables/jumppad_blueprint.mdl", "models/buildables/jumppad.mdl", "models/buildables/jumppad_light.mdl"],
	["models/buildables/jumppad_blueprint.mdl", "models/buildables/jumppad.mdl", "models/buildables/jumppad_light.mdl"]
]

// Almost entirely useless and will break stuff so I'll leave these as non-implemented for now
//Convars.RegisterConvar("cvs_dispenser_limit", "1", "Max default dispensers a player can build by default, setting below default will have unexpected results.",0);
//Convars.RegisterConvar("cvs_sentry_limit", "1", "Max default dispensers a player can build by default, setting below default will have unexpected results.",0);
//Convars.RegisterConvar("cvs_jumppad_limit", "2", "Max default dispensers a player can build by default, setting below default will have unexpected results.",0);
// Extra unsupported, even the og plugin didn't implement this. (Although fun fact I do have a unreleased version of that plugin that is 90% compatable with teles)
//Convars.RegisterConvar("cvs_teleporter_limit", "2", "Max default teleporters a player can build by default, setting below default will have unexpected results. WARNING, THIS IS UNSUPPORTED AND WILL CAUSE ISSUES!");

Convars.RegisterConvar("cvs_icarus_level_limit", "1", "If buildings are above the max level cap allowed to the user, they will destroyed on resupply. I HIGHLY recommend not turning this off, but you may.",0);
Convars.RegisterConvar("cvs_enforce_level_limit", "1", "True/False. Whether or not buildings should lower their max level in accordance with the user.",0);
Convars.RegisterConvar("cvs_lax_level_limit", "1", "True/False. Whether or not buildings should raise their max level in accordance with the user.",0);
Convars.RegisterConvar("cvs_enforce_health_limit", "1", "True/False. Whether or not buildings should lower their max health in accordance with the user.",0);
Convars.RegisterConvar("cvs_enforce_health_limit_upgrade", "1", "True/False. If cvs_enforce_health_limit is false, should it still change upon upgrading?",0);
Convars.RegisterConvar("cvs_lax_health_limit", "0", "True/False. Whether or not buildings should raise their max health in accordance with the user.",0);
Convars.RegisterConvar("cvs_lax_health_limit_upgrade", "1", "True/False. If cvs_lax_health_limit is false, should it still change upon upgrading?",0);
//Convars.RegisterConvar("cvs_enforce_building_limit", "1", "True/False. Whether or not additional buildings should be destroyed in accordance with the user.",0); // Actually, this is non optional.

//
// These are the hooks !
//

// This one uses one of VScript's hooks to hook into the Creation of an entity. Ironically, this does not trigger when the sentry is actually placed, but for the blueprint!
Hooks.Add(this, "OnEntityCreated", function(entity)
{
	entity.SetContextThink("OnEntityCreatedBuilding", OnEntityCreatedBuilding, 0.01);
}, "Building" )

Entities.EnableEntityListening() // This is needed for CEntities hooks.

function OnEntityCreatedBuilding(entity)
{
	if (!entity || !entity.IsValid())
	{
		return false
	}
	if (entity.GetClassname() == "tf_ammo_pack" && !entity.GetPhysicsObject())
	{
		switch (RandomInt(1,4))
		{
			case 1:
				entity.SetModelSimple("models/props_training/target_gibs01.mdl")
				break;
			case 2:
				entity.SetModelSimple("models/props_training/target_gibs02.mdl")
				break;
			case 3:
				entity.SetModelSimple("models/props_training/target_gibs03.mdl")
				break;
			case 4:
				entity.SetModelSimple("models/props_training/target_gibs04.mdl")
				break;
		}

		entity.PhysicsInitNormal(6,1,true)
		entity.ApplyAbsVelocityImpulse(Vector(RandomFloat( -0.5, 0.5 ),RandomFloat( -0.5, 0.5 ),RandomFloat( 0.75, 1.25 )) * RandomFloat( 100, 450 ))
		entity.ApplyLocalAngularVelocityImpulse(Vector(0,RandomFloat( 0, 100 ),0))
		entity.SetCollisionGroup(1)
	}
	if ((buildingtypes.find(entity.GetClassname())) != null)
	{
		local level = NetProps.GetPropInt(entity, "m_iUpgradeLevel")
		local owner = NetProps.GetPropEntity(entity, "m_hBuilder")
		if (!owner)
		{
			return
		}
		local scope = entity.GetOrCreatePrivateScriptScope()
		local buildstages = []
		local metallvls = []
		local currlevel = 1
		scope.mode <- NetProps.GetPropInt(entity, "m_iObjectMode")
		local buildingindex = GetBuilding(entity) - 1
		local buildingtype = GetBuildingShort(entity)

		// Before anything else
		NetProps.SetPropBool(entity, "m_bMiniBuilding", GetWearableAttribute(owner, "engy mini " + buildingtype, 0) ? true : false)
		local maxlevel = GetWearableAttribute(owner, buildingtype + " max level", 0) + GetWearableAttribute(owner, "buildings max level penalty", 0) + (buildingindex >= 4 || NetProps.GetPropBool(entity, "m_bMiniBuilding") == true || NetProps.GetPropBool(entity, "m_bDisposableBuilding") == true ? 1 : 3)
		local metaladjustment = GetWearableAttribute(owner, "buildings upgrade cost bonus", 0) + GetWearableAttribute(owner, "buildings upgrade cost penalty", 0)

		local blueprint = ""
		local contruction = ""
		local built = ""
		local level = ""

		for (local i = 1; i <= maxlevel; i++)
		{
			level = i.tostring()
			blueprint = GetWearableAttributeString(owner, buildingtype + " level " + level + " blueprint model", "")
			if (blueprint != "")
			{
				buildstages.append(blueprint)
			}
			else
			{
				buildstages.append(buildingdefaults[buildingindex][(3 * (min(i,buildingdefaults[buildingindex].len()/3) - 1))])
			}
			
			contruction = GetWearableAttributeString(owner, buildingtype + " level " + level + " contruction model", "")
			if (contruction != "")
			{
				buildstages.append(contruction)
			}
			else
			{
				buildstages.append(buildingdefaults[buildingindex][(3 * (min(i,buildingdefaults[buildingindex].len()/3) - 1)) + 1])
			}

			built = GetWearableAttributeString(owner, buildingtype + " level " + level + " model", "")
			if (built != "")
			{
				buildstages.append(built)
			}
			else
			{
				buildstages.append(buildingdefaults[buildingindex][(3 * (min(i,buildingdefaults[buildingindex].len()/3) - 1)) + 2])
			}

			metallvls.append(GetWearableAttribute(owner, buildingtype + " level " + level + " upgrade cost", 200) + metaladjustment)
		}

		local scale = GetWearableAttribute(owner, buildingtype + " scale", 1)


		local bboveride = ProcessStringAttrib(GetWearableAttributeString(owner, buildingtype + " BBox", ""))
		if (bboveride[0] != "")
		{
			scope.bboverride <- bboveride
		}
		else
		{
			scope.bboverride <- 0 // Not null because if I set it to null is just "forgets" it has this at all sometimes somehow
		}

		scope.scale <- scale 

		scope.currlevel <- 1
		scope.healthlvls <- GetBuildingHealthArray(owner, buildingindex, maxlevel)
		scope.metallvls <- metallvls

		scope.compat <- GetWearableAttribute(owner, buildingtype + " compatability", 0)

		if (scope.bboverride)
		{
			ReapeatingFunctionInTime(BBoxOrientBlueprint,0.015,[entity, owner])
		}

		if (buildingindex == 0) // Sentry
		{
			local gunslinger = GetWearableAttribute(owner, "mod wrench builds minisentry", 0)
			scope.minisentry <- NetProps.GetPropBool(entity, "m_bMiniBuilding") || gunslinger

			// bruh
			// Minis don't even do anything do anything that this plguin can't replicate on normal sentries, but for UI reasons it's for the best I support them
			if (scope.minisentry)
			{
				scope.scale *= 0.75
				if (buildstages[1] == "models/buildables/sentry1_heavy.mdl")
				{
					buildstages[1] = "models/buildables/sentry1_mini_4team_heavy.mdl"
				}
				if (buildstages[2] == "models/buildables/sentry1.mdl")
				{
					buildstages[2] = "models/buildables/sentry1_mini_4team.mdl"
				}
				if (gunslinger)
				{
					scope.healthlvls[0] *= 0.667
				}
			}

			scope.bullets <- GetWearableAttribute(owner, "engy sentry bullets mult", 1)
			scope.WF <- GetWearableAttribute(owner, "engy sentry wrangle firerate", 1)
			scope.WD <- GetWearableAttribute(owner, "engy sentry wrangle dmgtaken", 1) //Gaster
			scope.WS <- ProcessStringAttrib(GetWearableAttributeString(owner, "engy sentry wrangle spread mult levels", "1 1 1 1"))
			scope.spread <- ProcessStringAttrib(GetWearableAttributeString(owner, "engy sentry spread", ""))
			scope.enemyhitcond <- ProcessStringAttrib(GetWearableAttributeString(owner, "engy sentry cond", ""))
			scope.selfhitcond <- ProcessStringAttrib(GetWearableAttributeString(owner, "engy sentry self cond", ""))
			local range = GetWearableAttribute(owner, "engy sentry limited range", 0)
			if (range > 0)
			{
				scope.range <- range
			}
			else
			{
				scope.range <- null
			}
			scope.burst <- ProcessStringAttrib(GetWearableAttributeString(owner, "engy sentry burstfire", ""))
			scope.currburst <- 1
			scope.healingperhit <- GetWearableAttribute(owner, "engy sentry heal per hit", 0)
			scope.upgradeperhit <- GetWearableAttribute(owner, "engy sentry upgrade per hit", 0)
			scope.flags <- GetWearableAttribute(owner, "engy sentry bullet flags", 0)
			scope.tracerfreq <- GetWearableAttribute(owner, "engy sentry bullet tracer frequency mult", 1)
			scope.dmgtype <- GetWearableAttribute(owner, "engy sentry bullet damage type", 0)
			scope.secdmgtype <- GetWearableAttribute(owner, "engy sentry nonbullet damage type", 0)
			scope.MOOF <- GetWearableAttribute(owner, "engy sentry MOOF", 0)

			scope.PD <- ProcessStringAttrib(GetWearableAttributeString(owner, "engy sentry proj spread", ""))

			scope.dmglvls <- ProcessStringAttrib(GetWearableAttributeString(owner, "engy sentry bullet damage levels", "1 1 1 1"))
			scope.secdmglvls <- ProcessStringAttrib(GetWearableAttributeString(owner, "engy sentry nonbullet damage levels", "1 1 1 1"))
			scope.fireratelvls <- ProcessStringAttrib(GetWearableAttributeString(owner, "engy sentry fire rate levels", "1 1 1 1"))
			scope.spreadmultlvls <- ProcessStringAttrib(GetWearableAttributeString(owner, "engy sentry spread mult levels", "1 1 1 1"))

			scope.currshotcooldown <- Time()
			scope.minisentry <- NetProps.GetPropBool(entity, "m_bMiniBuilding")
		}
		if (buildingindex == 1) // Dispenser
		{	
			scope.rangelvls <- ProcessStringAttrib(GetWearableAttributeString(owner, "engy dispenser range levels", "1 1 1 1"))
			scope.ratelvls <- ProcessStringAttrib(GetWearableAttributeString(owner, "engy dispenser rate levels", "1 1 1 1"))
		}

		scope.maxlevel <- maxlevel
		scope.builder <- owner
		scope.placed <- false
		scope.active <- false
		scope.reversing <- false

		scope.minibuilding <- NetProps.GetPropBool(entity, "m_bMiniBuilding")

		local thinkscript = GetWearableAttributeString(owner, buildingtype + " think script", "")
		if (thinkscript != "")
		{
			try {
				entity.SetContextThink("BuildingThink",getroottable()[thinkscript],0.015)
			} catch (exception){
				printl(thinkscript + " IS NOT A VALID FUNCTION, CHECK YOUR SCRIPTS!")
			}
		}
		local setupscript = GetWearableAttributeString(owner, buildingtype + " setup script", "")
		if (setupscript != "")
		{
			try {
				getroottable()[setupscript](entity)
			} catch (exception){
				printl(setupscript + " IS NOT A VALID FUNCTION, CHECK YOUR SCRIPTS!")
			}
		}

		scope.buildstages <- buildstages

		AddToBuilt(owner, buildingindex, entity)

		SetBuildingModel(entity, 0)
	}
}

// These ones are listening to game events! Essentally, just things that the game finds nessesary to "broadcast"

::BuildingReplacerEventTable <- {
	// This one is for when the sentry is actually built.
	function OnGameEvent_player_builtobject(params)
	{
		local entity = EntIndexToHScript(params.index)
		local buildingtype
		if (IsScriptedBuilding(entity) && (buildingtype = GetBuilding(entity)))
		{
			local level = NetProps.GetPropInt(entity, "m_iUpgradeLevel")
			local builder = NetProps.GetPropEntity(entity, "m_hBuilder")
			local scope = entity.GetScriptScope()
			scope.placed <- true

			SetBuildingModel(entity, 1)
			entity.ResetSequence(entity.LookupSequence("ACT_OBJ_ASSEMBLING"))
			scope.currlevel <- level

			//entity.SetSequence(entity.LookupSequence("build")) // Doesn't like to play after being picked up and dropped sometimes otherwise. Weird, but alr ig.

			NetProps.SetPropInt(entity, "m_iMaxHealth", scope.healthlvls[NetProps.GetPropInt(entity, "m_iHighestUpgradeLevel")-1])
			entity.AcceptInput("AddHealth", "10000", null null) // Corrects the health

			if (GetBuilding(entity) > 1)
			{
				entity.SetContextThink("BuildingWaitForCompletion", BuildingWaitForCompletion, 0.015);
			}
		}
		else if (entity.GetClassname() == "obj_attachment_sapper")
		{
			local builder = NetProps.GetPropEntity(entity, "m_hBuilder")
			// For the most part, sappers are irrelevant, nothing we do really requires us to care much about them... with one small exception
			// The demon itself, the redtape-recorder.
			// (okay it's not actually that bad)
			local reverse = GetWearableAttribute(builder, "sapper degenerates buildings", 0)
			if (reverse)
			{
				local attachedbuilding = NetProps.GetPropEntity(entity, "m_hBuiltOnEntity")
				if (IsScriptedBuilding(attachedbuilding))
				{
					local scope = attachedbuilding.GetScriptScope()
					scope.reversing <- true
					scope.healthbuffer <- attachedbuilding.GetHealth()
					NetProps.SetPropBool(attachedbuilding, "m_bHasSapper", true) // It will say it ISN'T sapped otherwise? :bigredx:
					SetBuildingModel(attachedbuilding, (3 * (NetProps.GetPropInt(attachedbuilding, "m_iUpgradeLevel")-1)) + 1)
					attachedbuilding.SetContextThink("BuildingWaitForCompletion", BuildingWaitForCompletion, 0.015);
				}
			}
		}
	}

	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		// OnUser3 Is fired by the library whenever a weapon switch happens
		player.ConnectOutput("OnUser3" "WeaponSwitchPDACheck")
	}

	// This one is for when the building is actually built.
	function OnGameEvent_player_dropobject(params)
	{
		local entity = EntIndexToHScript(params.index)
		if (GetBuilding(entity) == 1 || IsScriptedBuilding(entity)) // No redundancy
		{
			entity.SetContextThink("BuildingWaitForCompletion", BuildingWaitForCompletion, 0.015);
		}
	}

	// This one is for when the building is actually built.
	function OnGameEvent_player_carryobject(params)
	{
		local entity = EntIndexToHScript(params.index)
		if (IsScriptedBuilding(entity))
		{
			local scope = entity.GetScriptScope()
			scope.placed <- false
			scope.active <- false

			FunctionInTime(SetBuildingModel, 0, [entity, (NetProps.GetPropInt(entity, "m_iUpgradeLevel")-1)*3])

			if (scope.bboverride)
			{
				ReapeatingFunctionInTime(BBoxOrientBlueprint,0.015,[entity, scope.builder])
			}
		}
	}
	// For some reason, multi buildings will crash the game if checked at round start, so keep track in a variable when the round starts
	function OnGameEvent_teamplay_restart_round(params)
	{
		roundstart <- Time()
	}
	function OnGameEvent_stats_resetround(params)
	{
		roundstart <- Time()
	}

	// Check stuff the we should be checking EVERY time the player resupplies
	function OnGameEvent_post_inventory_application(params)
	{
		if (roundstart == Time())
		{
			return // Prevents a game crash, and should never be nessesary.
		}
		local player = GetPlayerFromUserID(params.userid)
		local playerscope = player.GetScriptScope()
		playerscope.extrasentry <- GetWearableAttribute(player, "extra sentries", 0)
		playerscope.extradispenser <- GetWearableAttribute(player, "extra dispensers", 0)
		playerscope.extrapadA <- GetWearableAttribute(player, "extra padA", 0)
		playerscope.extrapadB <- GetWearableAttribute(player, "extra padB", 0)

		local buildings = GetPlayerActiveBuildings(player)
		// Looking at this gives me a headache but any comments here would just be redundant I think
		for (local i = 0; i < 6; i++)
		{
			local k = 0
			while (k < buildings[i].len())
			{
				local building = buildings[i][k]
				if (!building || !building.IsValid())
				{
					continue
				}
				local scope = building.GetScriptScope()
				if (!scope)
				{
					continue
				}
				if (scope.compat != GetWearableAttribute(player, buildingtypesconvert[i] + " compatability", 0) || k > GetBuildingExtra(player, i+1))
				{
					building.Kill()
					buildings[i].remove(buildings[i].find(building))
					// Overkill but works
					// TO DO: DO BETTER
					foreach (sentry in buildings[0])
					{
						NetProps.SetPropInt(sentry, "m_iObjectType", 2)
					}
					foreach (dispenser in buildings[1])
					{
						NetProps.SetPropInt(dispenser, "m_iObjectType", 0)
					}
					foreach (jumppad in buildings[4])
					{
						NetProps.SetPropInt(jumppad, "m_iObjectType", 4)
						NetProps.SetPropInt(jumppad, "m_iObjectMode", 0);
					}
					foreach (jumppad in buildings[5])
					{
						NetProps.SetPropInt(jumppad, "m_iObjectType", 4)
						NetProps.SetPropInt(jumppad, "m_iObjectMode", 1);
					}
				}
				else
				{
					local level = NetProps.GetPropInt(building, "m_iUpgradeLevel")
					local buildingtype = buildingtypesconvert[i]
					local maxlevel = GetWearableAttribute(player, buildingtype + " max level", 0) + GetWearableAttribute(player, "buildings max level penalty", 0) + (i >= 4 || NetProps.GetPropBool(building, "m_bMiniBuilding") == true || NetProps.GetPropBool(building, "m_bDisposableBuilding") == true ? 1 : 3)
					if (level > maxlevel && Convars.GetBool("cvs_icarus_level_limit"))
					{
						building.Kill()
						buildings[i].remove(buildings[i].find(building))
					}
					else
					{
						if (scope.maxlevel > maxlevel && Convars.GetBool("cvs_enforce_level_limit") || scope.maxlevel < maxlevel && Convars.GetBool("cvs_lax_level_limit"))
						{
							scope.maxlevel = maxlevel
						}
						local healtharray = GetBuildingHealthArray(player, i, scope.maxlevel)
						if ((healtharray[level-1] < scope.healthlvls[level-1] && Convars.GetBool("cvs_enforce_health_limit")) || (healtharray[level-1] > scope.healthlvls[level-1] && Convars.GetBool("cvs_lax_health_limit")))
						{
							NetProps.SetPropInt(building, "m_iMaxHealth", healtharray[level-1])
							if (NetProps.GetPropInt(building, "m_iHealth") > healtharray[level-1])
							{
								building.AcceptInput("AddHealth", "10000", null null) // Corrects the health
							}
						}
						for (local j = 0; j < healtharray.len(); j++)
						{
							// having code stacked this high should be a crime but I honestly don't care
							if ((healtharray[j] < scope.healthlvls[j] && (Convars.GetBool("cvs_enforce_health_limit") || Convars.GetBool("cvs_enforce_health_limit_upgrade"))) || (healtharray[j] > scope.healthlvls[j] && (Convars.GetBool("cvs_lax_health_limit") || Convars.GetBool("cvs_lax_health_limit_upgrade"))))
							{
								scope.healthlvls[j] = healtharray[j]
							}
						}
						k++
					}
				}
			}
		}
		
	}

	function OnGameEvent_sentry_on_go_active(params)
	{
		local entity = EntIndexToHScript(params.index)
		if (NetProps.GetPropInt(entity, "m_iState") != 3 && IsScriptedBuilding(entity)) 
		{
			BuildingDone(entity)
		}
	}

	function OnGameEvent_player_upgradedobject(params) {
		local building = EntIndexToHScript(params.index)
		if (IsScriptedBuilding(building))
		{
			local level = max(NetProps.GetPropInt(building, "m_iHighestUpgradeLevel"),NetProps.GetPropInt(building, "m_iUpgradeLevel"))
			local scope = building.GetScriptScope()
			
			
			scope.active <- false
			SetBuildingModel(building, (3 * (level-1)) + 1)
			building.ResetSequence(building.LookupSequence("ACT_OBJ_UPGRADING"))
			building.SetContextThink("PostUpgradedObject", PostUpgradedObject, 0.015);
		}
	}
}

// This is nessesary to make the above work. You can also place these functions inside of a table and collect said table, but i've done is this way because I feel like it.
__CollectGameEventCallbacks(BuildingReplacerEventTable)

//
// These are the think functions, while the special build ones are defined above, there's one here that is nessesary.
// Devs if you could just expose a hook for me to check on building 
//

function PostUpgradedObject(entity)
{
	local level = NetProps.GetPropInt(entity, "m_iUpgradeLevel") - 1
	local scope = entity.GetScriptScope()
	NetProps.SetPropInt(entity, "m_iMaxHealth", scope.healthlvls[level])
	entity.AcceptInput("AddHealth", "10000", null null) // Corrects the health
	SetBuildingModel(entity, (3 * (level)) + 1)
	entity.SetContextThink("BuildingWaitForCompletion", BuildingWaitForCompletion, 0.015);
}

function BuildingWaitForCompletion(self)
{
	if (!self || !self.IsValid() || !IsScriptedBuilding(self))
	{
		return -1
	}
	local buildingtype = GetBuilding(self)
	local level = NetProps.GetPropInt(self, "m_iUpgradeLevel")
	local leveldesired = NetProps.GetPropInt(self, "m_iHighestUpgradeLevel")
	local targetreached = level == leveldesired
	local scope = self.GetScriptScope()
	BBoxOrient(self) // TO DO: Find a way to prevent players from clipping into buildings WITHOUT having to do this!
	if (scope.reversing)
	{
		// Dumb Hack because this game is dumb
		if (scope.healthbuffer != self.GetHealth())
		{
			if (NetProps.GetPropInt(self, "m_iMaxHealth") == floor(scope.healthlvls[level-1]))
			{
				scope.healthbuffer <- self.GetHealth()
			}
			else
			{
				local health = scope.healthbuffer
				if (health > scope.healthlvls[level-1])
				{
					health = scope.healthlvls[level-1]
				}
				NetProps.SetPropInt(self, "m_iMaxHealth", health)
				self.AcceptInput("AddHealth", "10000", null null)
				NetProps.SetPropInt(self, "m_iMaxHealth", scope.healthlvls[level-1])
			}
		}
		if (scope.buildstages[(3 * (level-1)) + 1] != self.GetModelName())
		{
			SetBuildingModel(self, (3 * (level-1)) + 1)
			self.ResetSequence(self.LookupSequence("ACT_OBJ_UPGRADING"))
			self.SetCycle(1)
		}
		// Not Hack
		if (!NetProps.GetPropBool(self, "m_bHasSapper"))
		{
			scope.reversing <- false
		}
	}
	if (level != scope.currlevel)
	{
		NetProps.SetPropInt(self, "m_iMaxHealth", scope.healthlvls[level-1])
		SetBuildingModel(self, (3 * (level-1)) + 1)
		self.ResetSequence(self.LookupSequence("ACT_OBJ_UPGRADING"))
		scope.currlevel <- level
	}
	if (targetreached && !scope.reversing)
	{
		if (buildingtype == 1)
		{
			if (NetProps.GetPropInt(self, "m_iState") != 3 && NetProps.GetPropFloat(self, "m_flPercentageConstructed") == 1)
			{
				BuildingDone(self)
				return -1
			}
		}
		else if (buildingtype == 2)
		{
			if (NetProps.GetPropInt(self, "m_iState") == 0 && NetProps.GetPropFloat(self, "m_flPercentageConstructed") == 1)
			{
				BuildingDone(self)
				return -1
			}
		}
		else
		{
			local state = NetProps.GetPropInt(self, "m_iState")
			if (state != 0 && state != 7)
			{
				BuildingDone(self)
				return -1
			}
		}
	}
	return 0.015
}

//
// These are the mapbase hooks. They basically listen into various going on inside of entities and let us have a peek.
//

local PROJECTILES = ["tf_weapon_grenade_mirv_projectile", "tf_weapon_grenade_mirv_bomb", "tf_projectile_pipe", "tf_projectile_pipe_remote", "tf2c_projectile_brick", "tf2c_projectile_grenade_cyclops", "tf_projectile_ball_attributed", "tf_projectile_ball_ornament", "tf_projectile_stun_ball","tf_projectile_arrow", "tf_projectile_energy_ring", "tf_projectile_flare", "tf_projectile_healing_bolt", "tf_projectile_balloffire", "tf_projectile_rocket", "tf_projectile_syringe", "tf2c_projectile_arrow", "tf2c_projectile_coil", "tf2c_projectile_dart", "tf2c_projectile_nail"];

Entities.EnableEntityListening()
Hooks.Add(this, "OnEntitySpawned", function(entity)
{
	EntitySpawnBuildingMOOF(entity)
}, "EntitySpawnBuildingMOOF" );

function EntitySpawnBuildingMOOF(entity)
{
	if (!entity || !entity.IsValid() || PROJECTILES.find(entity.GetClassname()) == null)
	{
		return
	}

	local isgrenade = "GetThrower" in entity
	local owner
	if (isgrenade)
	{
		owner = NetProps.GetPropEntity(entity, "m_hOriginalLauncher")
	}
	else
	{
		owner = entity.GetOwner()
	}

	if (!owner || owner.GetClassname() != "obj_sentrygun" || !IsScriptedBuilding(owner))
	{
		return
	}

	local scope = owner.GetScriptScope()

	local MOOF = scope.MOOF
	local PD = scope.PD
	if (MOOF != 0 && PD[0] != "")
	{
		FunctionInTime(ApplyBuildingProjVelAndSpread, 0, [entity, MOOF, PD, isgrenade])
	}
	else if (MOOF != 0)
	{
		FunctionInTime(ApplyBuildingProjVel, 0, [entity, MOOF, isgrenade])
	}
	else if (PD[0] != "")
	{
		FunctionInTime(ApplyBuildingProjSpread, 0, [entity, PD, isgrenade])
	}
}

function ApplyBuildingProjVel(entity, MOOF, isgrenade)
{
	local initvel
	initvel = NetProps.GetPropVector(entity, "m_vInitialVelocity")
	local gleep = (initvel*(1/initvel.Length())) * MOOF
	if (isgrenade)
	{
		entity.ApplyAbsVelocityImpulse(gleep)
	}
	else
	{
		entity.SetAbsVelocity(initvel + gleep)
	}
}

function ApplyBuildingProjSpread(entity, PD, isgrenade)
{
	local initvel = NetProps.GetPropVector(entity, "m_vInitialVelocity")
	local modvel = initvel
	modvel.x = modvel.x * (1 + RandomFloat(-PD[0],PD[0]))
	modvel.y = modvel.y * (1 + RandomFloat(-PD[1],PD[1]))
	modvel.z = modvel.z * (1 + RandomFloat(-PD[2],PD[2]))
	if (isgrenade)
	{
		entity.ApplyAbsVelocityImpulse(initvel - modvel)
	}
	else
	{
		entity.SetAbsVelocity(modvel)
	}
}

function ApplyBuildingProjVelAndSpread(entity, MOOF, PD, isgrenade)
{
	local initvel = NetProps.GetPropVector(entity, "m_vInitialVelocity")
	local gleep = (initvel*(1/initvel.Length())) * MOOF
	local prevel = initvel + gleep
	local modvel = initvel + gleep
	local xmult = RandomFloat(-PD[0],PD[0])
	local ymult = RandomFloat(-PD[1],PD[1])
	local zmult = RandomFloat(-PD[2],PD[2])
	local length = modvel.Length()
	modvel.x += pow(pow(prevel.y,2) + pow(prevel.z,2), 1/2) * xmult * length
	modvel.y += pow(pow(prevel.x,2) + pow(prevel.z,2), 1/2) * ymult * length
	modvel.z += pow(pow(prevel.x,2) + pow(prevel.y,2), 1/2) * zmult * length
	if (isgrenade)
	{
		entity.ApplyAbsVelocityImpulse(initvel - modvel)
	}
	else
	{
		entity.SetAbsVelocity(modvel)
	}
}

function FireBullets()
{
	if (self.GetClassname() != "obj_sentrygun" && IsScriptedBuilding(self)) // Is there anything else that even runs this in tf2?
	{
		return true
	}
	local scope = self.GetScriptScope()

	if (scope.currshotcooldown > Time())
	{
		return false // Do not allow it to fire, it will still play the visual but it will not fire.
	}

	info.SetShots(scope.bullets)
	
	local spreadmod = scope.spreadmultlvls[scope.currlevel-1]

	if (scope.range)
	{
		info.SetDistance(scope.range)
	}

	info.SetFlags(scope.flags)

	info.SetTracerFreq(scope.tracerfreq * info.GetTracerFreq())

	info.SetDamage(info.GetDamage() * scope.dmglvls[scope.currlevel-1])

	local fireratemod = 1 * scope.fireratelvls[scope.currlevel-1]

	scope.currshotcooldown = 0.1

	if (scope.burst[0] != "")
	{
		if (scope.currburst < scope.burst[0])
		{
			scope.currburst += 1
		}
		else
		{
			scope.currburst = 1
			fireratemod *= scope.burst[1]
		}
	}

	if (NetProps.GetPropInt(self, "m_bPlayerControlled"))
	{
		scope.currshotcooldown *= 0.5
		fireratemod *= scope.WF
		spreadmod *= scope.WS[scope.currlevel]
	}

	if (scope.spread[0] != "")
	{
		info.SetSpread(Vector(scope.spread[0],scope.spread[1],scope.spread[2]) * spreadmod)
	}

	scope.builder.AddCustomAttribute("engy sentry fire rate VSCRIPT", fireratemod, 0.015)

	scope.currshotcooldown *= (scope.builder.InCond(34) ? 0.4 : 1) * (scope.minisentry ? 0.75 : 1) * (scope.currlevel == 1 ? 2 : 1) * GetWearableAttribute(scope.builder, "engy sentry fire rate increased", 1) * GetWearableAttribute(scope.builder, "engy sentry fire rate decreased", 1)
	scope.currshotcooldown += Time() - 0.02 // Just a bit of forgiveness
	return true
}

function OnTakeDamage(self,info)
{
	local building
	local scope
	local owner
	if (self.IsPlayer() && info.GetAttacker() && info.GetAttacker().IsPlayer() && info.GetInflictor() && info.GetInflictor().GetClassname() == "obj_sentrygun" && IsScriptedBuilding(info.GetInflictor()))
	{
		building = info.GetInflictor()
		scope = building.GetScriptScope()
		owner = info.GetAttacker()
	}
	else if (info.GetAttacker() && info.GetAttacker().GetClassname() == "obj_sentrygun" && IsScriptedBuilding(info.GetAttacker()))
	{
		building = info.GetAttacker()
		scope = building.GetScriptScope()
		owner = scope.builder
		info.SetAttacker(owner)
		info.SetInflictor(building)
	}
	if (building && IsScriptedBuilding(building))
	{
		if (owner == self)
		{
			return true
		}
		if (scope.enemyhitcond[0] != "")
		{
			self.AddCondEx(scope.enemyhitcond[(scope.currlevel-1)*2], scope.enemyhitcond[((scope.currlevel-1)*2)+1], owner)
		}
		if (scope.selfhitcond[0] != "")
		{
			owner.AddCondEx(scope.selfhitcond[(scope.currlevel-1)*2], scope.selfhitcond[((scope.currlevel-1)*2)+1], info.GetAttacker())
		}
		if (scope.healingperhit)
		{
			building.AcceptInput("AddHealth", scope.healingperhit, null null) // Corrects the health
		}
		if (scope.upgradeperhit)
		{
			GiveUpgradeMetal(building, scope.upgradeperhit)
		}
		if (!(info.GetDamageType() == 2232322))
		{
			info.SetDamage(info.GetDamage() * scope.secdmglvls[scope.currlevel-1])
			if (scope.secdmgtype)
			{
				info.SetDamageType(scope.secdmgtype)
			}
		}
		else
		{
			if (scope.dmgtype)
			{
				info.SetDamageType(scope.dmgtype)
			}
		}
	}
	if (self.GetClassname() == "obj_sentrygun" && IsScriptedBuilding(self))
	{
		scope = self.GetScriptScope()
		if (NetProps.GetPropInt(self, "m_bPlayerControlled"))
		{
			info.SetDamage(info.GetDamage() * scope.WD) // Hopwfully should be a much more reliable thing to do on buildings, since they aren't usually effected by this nonsense.
		}
	}
}

//
// These are the handler functions, if something is done by multiple functions, usually it will defer to these.
//

// The function that actually sets the building model. Looks in the table for the correct offset, and gives it its model depending on the situation.
function SetBuildingModel(building, stage)
{
	local scope = building.GetScriptScope()
	building.SetModel(scope.buildstages[stage])
	building.SetModelScale(scope.scale, 0)
	building.SetSkin(building.GetTeam()-2)
	FunctionInTime(HitWithHammer, 0, [building, building.GetTeam()-2])
	BBoxOrient(building)
}

function HitWithHammer(building, team)
{
	if (!building || !building.IsValid())
	{
		return false
	}
	building.SetSkin(team)
}

// The function that's run when construction/upgrading is finished, either when the think function says it is for dispensers, teleporters, and jumppads (I hate that this is how I have to do this)
function BuildingDone(building)
{
	if (!building || !building.IsValid())
	{
		// How
		return false
	}
	local level = NetProps.GetPropInt(building, "m_iUpgradeLevel")
	local scope = building.GetScriptScope()
	NetProps.SetPropInt(building, "m_bIsUpgradable", scope.maxlevel > level ? 1 : 0)
	NetProps.SetPropInt(building, "m_iUpgradeMetalRequired", scope.metallvls[level-1])
	scope.active <- true
	SetBuildingModel(building, ((3 * (level - 1)) + 2))
	if ("rangelvls" in scope)
	{
		scope.builder.AddCustomAttribute("engy dispenser radius VSCRIPT", scope.rangelvls[level-1], 0)
		scope.builder.AddCustomAttribute("engy dispenser rate VSCRIPT", scope.ratelvls[level-1], 0)
	}
}

// This function determines if the player has switched to a PDA, If they have, run the multiple buildings checks!
function WeaponSwitchPDACheck()
{
	local wepaone = self.GetActiveWeapon()
	if (!wepaone)
	{
		return false
	}
	local playerscope = self.GetScriptScope()
	local activebuildings = GetPlayerActiveBuildings(self)
	local weaponclass = wepaone.GetClassname()
	if (weaponclass == "tf_weapon_pda_engineer_build" || weaponclass == "tf_weapon_builder")
	{
		if (playerscope.extrasentry > 0 && activebuildings[0].len() <= playerscope.extrasentry)
		{
			foreach (sentry in activebuildings[0])
			{
				if (sentry.GetScriptScope().placed)
				{
					NetProps.SetPropInt(sentry, "m_iObjectType", 3)
				}
			}
		}

		if (playerscope.extradispenser > 0 && activebuildings[1].len() <= playerscope.extradispenser)
		{
			foreach (dispenser in activebuildings[1])
			{
				if (dispenser.GetScriptScope().placed)
				{
					NetProps.SetPropInt(dispenser, "m_iObjectType", 3)
				}
			}
		}

		if (playerscope.extrapadA > 0 && activebuildings[4].len() <= playerscope.extrapadA)
		{
			foreach (jumppad in activebuildings[4])
			{
				if (jumppad.GetScriptScope().placed)
				{
					NetProps.SetPropInt(jumppad, "m_iObjectType", 3)
				}
			}
		}

		if (playerscope.extrapadB > 0 && activebuildings[5].len() <= playerscope.extrapadB)
		{
			foreach (jumppad in activebuildings[5])
			{
				if (jumppad.GetScriptScope().placed)
				{
					NetProps.SetPropInt(jumppad, "m_iObjectType", 3)
				}
			}
		}
	}
	else
	{
		if (playerscope.extrasentry > 0)
		{
			foreach (sentry in activebuildings[0])
			{
				NetProps.SetPropInt(sentry, "m_iObjectType", 2)
			}
		}
		if (playerscope.extradispenser > 0)
		{
			foreach (dispenser in activebuildings[1])
			{
				NetProps.SetPropInt(dispenser, "m_iObjectType", 0)
			}
		}
		if (playerscope.extrapadA > 0)
		{
			foreach (jumppad in activebuildings[4])
			{
				NetProps.SetPropInt(jumppad, "m_iObjectType", 4)
				NetProps.SetPropInt(jumppad, "m_iObjectMode", 0);
			}
		}
		if (playerscope.extrapadB > 0)
		{
			foreach (jumppad in activebuildings[5])
			{
				NetProps.SetPropInt(jumppad, "m_iObjectType", 4)
				NetProps.SetPropInt(jumppad, "m_iObjectMode", 1);
			}
		}
	}
}

// This function is run to check which building type the building is. 1 for sentries, 2 for dispensers, 3 for teleporters, and 4 for jumppads
function GetBuilding(building)
{
	if (!IsScriptedBuilding(building))
	{
		return null
	}
	local buildingtype = buildingtypes.find(building.GetClassname())
	local scope = building.GetScriptScope()
	if (buildingtype != null)
	{
		if (buildingtype == 2)
		{
			buildingtype = 2 + scope.mode
		}
		else if (buildingtype == 3)
		{
			buildingtype = 4 + scope.mode
		}
		return buildingtype + 1 //Because we don't want it to start from 0
	}
	else
	{
		return null
	}
}

// Similar to the one above it, but this time more human readable for outputted stuff (sentry rather than obj_sentrygun)
function GetBuildingShort(building)
{
	local buildingtype = GetBuilding(building)
	if (buildingtype != null)
	{
		return buildingtypesconvert[buildingtype-1]
	}
	else
	{
		return null
	}
}

// Similar to returns the max number of buildings of its type the player can have
function GetBuildingExtra(player, buildingtype)
{
	local scope = player.GetScriptScope()
	switch (buildingtype) {
		case 1:
        	return scope.extrasentry
        	break
		case 2:
			return scope.extradispenser
			break
		case 5:
        	return scope.extrapadA
        	break
		case 6:
			return scope.extrapadB
			break
		default:
			return 0
			break
	}
	return 0
}

// Get all of the player's active buildings, if some are no longer valid, remove them.
function GetPlayerActiveBuildings(player)
{
	local index = player.GetEntityIndex()
	foreach (i in playeractivebuildings[index-1])
	{
		foreach (k in i)
		{
			if (!k || !k.IsValid() || !IsScriptedBuilding(k)) 
			{
				i.remove(i.find(k))
			}
		}
	}
	return playeractivebuildings[index-1]
}

// Add a building to the list of buildings the the player has built
function AddToBuilt(player, buildingtype, building)
{
	playeractivebuildings[player.GetEntityIndex()-1][buildingtype].append(building)
}

// Get how much health a building should have
function GetBuildingHealthArray(player, buildingtype, maxlevel)
{
	local buildingname = buildingtypesconvert[buildingtype]
	local health = buildingbasehealth[buildingtype] * GetWearableAttribute(player, "engy building health bonus", 1) * GetWearableAttribute(player, "engy building health penalty", 1) * GetWearableAttribute(player, buildingname + " health mult", 1)
	local healtharray = [health]
	for (local i = 1; i < maxlevel; i++)
	{
		health *= 1.2
		healtharray.append(health)
	}

	for (local i = 1; i <= maxlevel; i++)
	{
		healtharray[i-1] *= GetWearableAttribute(player, buildingname + " level " + i.tostring() + " health mult", 1)
	}

	return healtharray
}

// Rotate a building's bounding box based on position compared to the player. This is dumb...
function BBoxOrientBlueprint(building, player)
{
	if (building == null || !building || !building.IsValid())
	{
		return false
	}
	local scope = building.GetScriptScope()
	if (!scope.placed)
	{
		return false
	}
	local angle = building.GetLocalAngles().y // from -180 to 180
	local facingangle = (angle / 180) * PI // degress -> radians, goes into negatives. sin takes radians here.

	// 0-1, multipliers to the given dimensions.
	local sin = sin(facingangle)
	local cos = cos(facingangle)

	local scale = scope.scale

	// given x/y mins/maxes, flipped when facing a different way.
	local gxmin = scope.bboverride[0]
	local gxmax = scope.bboverride[3]
	local gymin = scope.bboverride[1]
	local gymax = scope.bboverride[4]

	local vxmin = (gxmin * cos) - (gymin * sin) // MIN/MIN
	local vymin = (gxmin * sin) + (gymin * cos)
	local vxmax = (gxmax * cos) - (gymax * sin) // MAX/MAX
	local vymax = (gxmax * sin) + (gymax * cos)

	local v2xmin = (gxmin * cos) - (gymax * sin) // MIN/MAX
	local v2ymin = (gxmin * sin) + (gymax * cos)
	local v2xmax = (gxmax * cos) - (gymin * sin) // MAX/MIN
	local v2ymax = (gxmax * sin) + (gymin * cos)

	local fxmin = min(min(vxmin, vxmax), min(v2xmin, v2xmax)) / pow(fabs(sin)+fabs(cos),0.8)
	local fxmax = max(max(vxmin, vxmax), max(v2xmin, v2xmax)) / pow(fabs(sin)+fabs(cos),0.8)
	local fymin = min(min(vymin, vymax), min(v2ymin, v2ymax)) / pow(fabs(sin)+fabs(cos),0.8)
	local fymax = max(max(vymin, vymax), max(v2ymin, v2ymax)) / pow(fabs(sin)+fabs(cos),0.8)

	/*if (abs(angle) < 45 || abs(angle) > 135)
	{
		local buffer = xmin
		xmin = ymin
		ymin = buffer
		buffer = xmax
		xmax = ymax
		ymax = buffer
	}*/

	local vecmin = Vector(fxmin,fymin,scope.bboverride[2])
	local vecmax = Vector(fxmax,fymax,scope.bboverride[5])

	// series of checks to fix max REQUIRING being higher than min makes the aobve step much simpler
	/*if (vecmin.x > vecmax.x)
	{
		local buffer = vecmax.x
		vecmax.x = vecmin.x
		vecmin.x = buffer
	}

	if (vecmin.y > vecmax.y)
	{
		local buffer = vecmax.y
		vecmax.y = vecmin.y
		vecmin.y = buffer
	}

	if (vecmin.z > vecmax.z)
	{
		local buffer = vecmax.z
		vecmax.z = vecmin.z
		vecmin.z = buffer
	}*/

	building.SetSize(vecmin,vecmax)
}

// Rotate a building's bounding box based on orientation... this is dumb...
function BBoxOrient(building)
{
	local scope = building.GetScriptScope()
	if (!scope.bboverride)
	{
		return false
	}
	local angle = building.GetLocalAngles().y // from -180 to 180
	local facingangle = (angle / 180) * PI // degress -> radians, goes into negatives. sin takes radians here.

	// 0-1, multipliers to the given dimensions.
	local sin = sin(facingangle)
	local cos = cos(facingangle)

	// given x/y mins/maxes, flipped when facing a different way.
	local gxmin = scope.bboverride[0]
	local gxmax = scope.bboverride[3]
	local gymin = scope.bboverride[1]
	local gymax = scope.bboverride[4]

	local vxmin = (gxmin * cos) - (gymin * sin) // MIN/MIN
	local vymin = (gxmin * sin) + (gymin * cos)
	local vxmax = (gxmax * cos) - (gymax * sin) // MAX/MAX
	local vymax = (gxmax * sin) + (gymax * cos)

	local v2xmin = (gxmin * cos) - (gymax * sin) // MIN/MAX
	local v2ymin = (gxmin * sin) + (gymax * cos)
	local v2xmax = (gxmax * cos) - (gymin * sin) // MAX/MIN
	local v2ymax = (gxmax * sin) + (gymin * cos)

	local fxmin = min(min(vxmin, vxmax), min(v2xmin, v2xmax)) / pow(fabs(sin)+fabs(cos),0.8)
	local fxmax = max(max(vxmin, vxmax), max(v2xmin, v2xmax)) / pow(fabs(sin)+fabs(cos),0.8)
	local fymin = min(min(vymin, vymax), min(v2ymin, v2ymax)) / pow(fabs(sin)+fabs(cos),0.8)
	local fymax = max(max(vymin, vymax), max(v2ymin, v2ymax)) / pow(fabs(sin)+fabs(cos),0.8)

	/*if (abs(angle) < 45 || abs(angle) > 135)
	{
		local buffer = xmin
		xmin = ymin
		ymin = buffer
		buffer = xmax
		xmax = ymax
		ymax = buffer
	}*/

	local vecmin = Vector(fxmin,fymin,scope.bboverride[2])
	local vecmax = Vector(fxmax,fymax,scope.bboverride[5])

	// series of checks to fix max REQUIRING being higher than min makes the aobve step much simpler
	/*if (vecmin.x > vecmax.x)
	{
		local buffer = vecmax.x
		vecmax.x = vecmin.x
		vecmin.x = buffer
	}

	if (vecmin.y > vecmax.y)
	{
		local buffer = vecmax.y
		vecmax.y = vecmin.y
		vecmin.y = buffer
	}

	if (vecmin.z > vecmax.z)
	{
		local buffer = vecmax.z
		vecmax.z = vecmin.z
		vecmin.z = buffer
	}*/

	building.SetSize(vecmin,vecmax)
}

//
// These are the runtime scripts! These get run when the script starts running. That's all there's to it, really.
//

IncludeScript("lib/mapbasehookcollector.nut");