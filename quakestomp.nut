// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None, which probably means it has some grevious issue I missed.
//

IncludeScript("lib/clocksutils.nut");

::QuakeStompEventTable <- {
	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		// Get the wearable attribute
		local AEW = GetWearableAttributeString(player, "anchor earthquake wearer", "")
		// Apply the wearable attribute
		if (AEW != "")
		{
			AddWearerAttributeString(player, "anchor earthquake VSCRIPT", AEW)
		}
		else
		{
			RemoveWearerAttribute(player, "anchor earthquake VSCRIPT")
		}
		local AEWM = GetWearableAttributeString(player, "anchor earthquake mins wearer", "")
		// Apply the wearable attribute
		if (AEWM != "")
		{
			AddWearerAttributeString(player, "anchor earthquake mins VSCRIPT", AEWM)
		}
		else
		{
			RemoveWearerAttribute(player, "anchor earthquake mins VSCRIPT")
		}
	}
}

__CollectGameEventCallbacks(QuakeStompEventTable)

function OnTakeDamage(self,info)
{
	if (!self.IsPlayer() || !info.GetAttacker())
	{
		return
	}
	local player = info.GetAttacker()
	if (!player || !player.IsPlayer())
	{
		return
	}
	if (info.GetDamageCustom() == 87 && NetProps.GetPropEntity(player, "m_hGroundEntity") == self)
	{
		local weapon = player.GetActiveWeapon()
		if (!weapon)
		{
			return
		}
		local quakemult = GetWearableAttribute(player, "anchor stomp mult", 1) * weapon.GetAttribute("anchor stomp mult weapon", 1)
		if (quakemult != 1)
		{
			info.SetDamage(info.GetDamage() * quakemult)
		}
	}
}

IncludeScript("lib/mapbasehookcollector.nut")