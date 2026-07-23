// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

IncludeScript("lib/clocksutils.nut")

hitStreak <- {};
ignoreWallClimb <- [
    "player",
    "tf_bot",
    "obj_",
    "tf_projectile",
    "func_button",
	"tf_weapon",
	"tf2c_weapon",
	"tf_ammo",
	"item"
]

::ThatOneWallClimbEventTable <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ConnectOutput("OnUser1" "ThatOneWallClimb")
	}
}
__CollectGameEventCallbacks(ThatOneWallClimbEventTable)

function ThatOneWallClimb()
{
	local weapon = self.GetActiveWeapon()
	local climb = weapon.GetAttribute("wall climb", 0)
	if (climb)
	{
		local eyeangles = AngleVectors(self.EyeAngles())
		local boxmin = Vector(-18,-18,-18) * weapon.GetAttribute("melee bounds multiplier", 1)
		local boxmax = Vector(18,18,18) * weapon.GetAttribute("melee bounds multiplier", 1)
		local trace = TraceHullComplex(self.ShootPosition(), self.ShootPosition() + (eyeangles * 48 * weapon.GetAttribute("melee range multiplier", 1)), boxmin, boxmax, self, MASK_SOLID, 0)
		if (trace.DidHitWorld() || (trace.Entity() &&!StartsWithList(trace.Entity().GetClassname(),ignoreWallClimb)))
		{
			NetProps.SetPropEntity(self, "m_hGroundEntity", null)
			local decay = weapon.GetAttribute("wall climb decay", 1)
			local velocity = self.GetAbsVelocity()
			if (velocity.z < 0)
			{
				velocity.z = min(0,climb*(pow(decay,FLIGHTPROCS[self.GetEntityIndex()])))
			}

			self.SetAbsVelocity(velocity + Vector(0,0,climb*(pow(decay,FLIGHTPROCS[self.GetEntityIndex()]))))
			FLIGHTPROCS[self.GetEntityIndex()] += 1
		}
	}
}