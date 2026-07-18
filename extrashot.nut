// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

IncludeScript("lib/clocksutils.nut");

::ExtraShotEventTable <- {
	function OnGameEvent_player_shoot(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		local weapon = player.GetActiveWeapon()
		local extrashot = weapon.GetAttribute("extra shot", 0)
		if (extrashot)
		{
			EntFireByHandle(player, "CallScriptFunction", "ExtraShootThink", 0, player, null) // AUGH WHY WILL IT JUST NOT DO THE EFFECT!!!! AUGHHHHHHHHHHHHHHHHHHHHH
		}
	}
}

function ExtraShootThink()
{
	local firebullets = FireBulletsInfo_t()
	local weapon = self.GetActiveWeapon()
	firebullets.SetAmmoType(NetProps.GetPropInt(weapon, "m_iPrimaryAmmoType"))
	firebullets.SetDistance(weapon.GetAttribute("extra shot range", 0))
	firebullets.SetDamage(weapon.GetAttribute("extra shot damage", 0))
	firebullets.SetShots(weapon.GetAttribute("extra shot bullet", 0))
	firebullets.SetPrimaryAttack(true)
	firebullets.SetSource(self.Weapon_ShootPosition())
	firebullets.SetDirShooting(self.GetAutoaimVector(1))
	firebullets.SetTracerFreq(1)
	firebullets.SetAttacker(self)
	firebullets.SetSpread(Vector(weapon.GetAttribute("extra shot spread", 0),weapon.GetAttribute("extra shot spread", 0),weapon.GetAttribute("extra shot spread", 0)))
	weapon.FireBullets(firebullets)
}

__CollectGameEventCallbacks(ExtraShotEventTable)
