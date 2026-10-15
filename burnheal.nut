// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

IncludeScript("lib/clocksutils.nut")

function OnTakeDamage(self,info)
{
	local player = info.GetAttacker()
	if (!player || !player.IsPlayer() || !self || !self.IsPlayer() || player == self || !(info.GetDamageType() & 8))
	{
		return
	}
	local weapon = info.GetWeapon()
	if (!weapon)
	{
		return
	}
	local healonburn = weapon.GetAttribute("heal on afterburn", 0)
	if (healonburn > 0)
	{
		player.TakeHealth(healonburn, 0)
	}
	local healonburnwearer = GetWearableAttribute(player, "heal on afterburn wearer", 0)
	if (healonburnwearer > 0)
	{
		player.TakeHealth(healonburnwearer, 0)
	}
}

IncludeScript("lib/mapbasehookcollector.nut")