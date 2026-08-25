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

::ArmorWrenchEventTable <- {
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		player.ConnectOutput("OnUser1" "ArmorWrench")
	}
}
__CollectGameEventCallbacks(ArmorWrenchEventTable)

function ArmorWrench()
{
	local weapon = self.GetActiveWeapon()
	local armorhit = weapon.GetAttribute("armor wrench", 0)
	if (armorhit)
	{
		local eyeangles = AngleVectors(self.EyeAngles())
		local boxmin = Vector(-18,-18,-18) * weapon.GetAttribute("melee bounds multiplier", 1)
		local boxmax = Vector(18,18,18) * weapon.GetAttribute("melee bounds multiplier", 1)
		local trace = TraceHullComplex(self.ShootPosition(), self.ShootPosition() + (eyeangles * 48 * weapon.GetAttribute("melee range multiplier", 1)), boxmin, boxmax, self, MASK_SOLID, 0)
		if (trace.Entity() && trace.Entity().GetClassname() == "player" && trace.Entity().GetTeam() == self.GetTeam())
		{
			local metal = NetProps.GetPropIntArray(self, "m_iAmmo", 3)
			local oldarmor = NetProps.GetPropInt(trace.Entity(), "m_ArmorValue")
			local newarmor = floor(min(oldarmor + min((metal / GetWearableAttribute(self, "armor wrench ratio", 1)), armorhit),max(GetWearableAttribute(self, "armor wrench cap", 0), GetWearableAttribute(trace.Entity(), "armor cap", 0))))
			if (newarmor > oldarmor)
			{
				NetProps.SetPropInt(trace.Entity(), "m_ArmorValue", newarmor)
				NetProps.SetPropIntArray(self, "m_iAmmo", NetProps.GetPropIntArray(self, "m_iAmmo", 3) - ((newarmor-oldarmor) * GetWearableAttribute(self, "armor wrench ratio", 1)), 3)
			}
		}
	}
}