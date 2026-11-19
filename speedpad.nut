// This plugin was made without the assitance of AI, all stupidity is entirely on me.

IncludeScript("lib/clocksutils.nut")

PrecacheScriptSound("DisciplineDevice.PowerUp")

function SpeedPadSetup(self)
{
	local scope = self.GetScriptScope()
	scope.cooldown <- Time()
}

function SpeedPadCheck(self)
{
	if (!self || !self.IsValid() || !self.GetScriptScope())
	{
		return -1
	}
	local scope = self.GetScriptScope()
	local disabled = NetProps.GetPropBool(self, "m_bPlasmaDisable") || NetProps.GetPropBool(self, "m_bHasSapper")
	if (scope.active && !disabled)
	{
		NetProps.SetPropBool(self, "m_bDisabled", true)
		self.ResetSequence(self.LookupSequence("ACT_OBJ_RUNNING"))
		self.SetPlaybackRate(min(0.6,self.GetPlaybackRate()+0.05))
		if (scope.cooldown <= Time())
		{
			local player = Entities.FindByClassnameWithinBox(null, "player", Vector(-30,-30,0) + self.GetOrigin(), Vector(30,30,20) + self.GetOrigin())
			while (player && (player.GetCondDuration(32) > 1 || player.GetTeam() != self.GetTeam()))
			{
				player = Entities.FindByClassnameWithinBox(player, "player", Vector(-30,-30,0) + self.GetOrigin(), Vector(30,30,20) + self.GetOrigin())
			}
			if (player)
			{
				if (player.InCond(32))
				{
					EmitSoundOnClient("DisciplineDevice.PowerUp", player) // If we are reapplying it, play the sound anyways.
				}
				player.AddCondEx(32, 5, self)
				NetProps.SetPropInt(self, "m_iTimesUsed", NetProps.GetPropInt(self, "m_iTimesUsed") + 1)
				scope.cooldown <- Time() + 1
			}
		}
	}
	return 0.05
}
