// This plugin was made without the assitance of AI, all stupidity is entirely on me.

//
// Known issues:
// 
// None.
//

// TO DO: EXPAND TO ALL MAPBASE HOOKS!
// I'm sure somebody already has a way to do this "properly" but for a (hopefully) temporary hack fix this is good enough...

if (!("OnTakeDamageFUNCTIONS" in getroottable())) {
	OnTakeDamageFUNCTIONS <- []
	UpdateOnRemoveFUNCTIONS <- []
	ModifyEmitSoundParamsFUNCTIONS <- []
}

function HFFS(source, files)
{
	local count = 0
	foreach (i in files)
	{
		if (i[0] == source)
		{
			return count
		}
		count += 1
	}
	return -1
}

// ONE PER FILE
// Remove any pervious entries we have related to that file, so that the function actually gets reloaded when we, you know, reload the function.
if ("OnTakeDamage" in getroottable())
{
	local funcremove = HFFS(OnTakeDamage.getinfos()["src"], OnTakeDamageFUNCTIONS)
	if (funcremove != -1)
	{
		OnTakeDamageFUNCTIONS.remove(funcremove)
	}
	if (OnTakeDamage.getinfos()["parameters"].len() > 1)
	{
		OnTakeDamageFUNCTIONS.append([OnTakeDamage.getinfos()["src"],OnTakeDamage])
	}
}

if ("UpdateOnRemove" in getroottable())
{
	local funcremove = HFFS(UpdateOnRemove.getinfos()["src"], UpdateOnRemoveFUNCTIONS)
	if (funcremove != -1)
	{
		UpdateOnRemoveFUNCTIONS.remove(funcremove)
	}
	if (UpdateOnRemove.getinfos()["parameters"].len() > 1)
	{
		UpdateOnRemoveFUNCTIONS.append([UpdateOnRemove.getinfos()["src"],UpdateOnRemove])
	}
}

if ("ModifyEmitSoundParams" in getroottable())
{
	local funcremove = HFFS(ModifyEmitSoundParams.getinfos()["src"], ModifyEmitSoundParamsFUNCTIONS)
	if (funcremove != -1)
	{
		ModifyEmitSoundParamsFUNCTIONS.remove(funcremove)
	}
	if (ModifyEmitSoundParams.getinfos()["parameters"].len() > 1)
	{
		ModifyEmitSoundParamsFUNCTIONS.append([ModifyEmitSoundParams.getinfos()["src"],ModifyEmitSoundParams])
	}
}

function OnTakeDamage()
{
	// Hack fix for bomblets.
	// TO DO: ESTABLISH A PROPER SYSTEM FOR PREORDER FUNCTIONS FOR THINGS LIKE THIS!
	if (info.GetWeapon() && info.GetWeapon().IsPlayer() && info.GetInflictor() && info.GetInflictor().GetClassname() == "tf_weapon_grenade_mirv_bomb")
	{
		local scriptscope = info.GetInflictor().GetOrCreatePrivateScriptScope()
		if ("weapon" in scriptscope)
		{
			info.SetWeapon(scriptscope.weapon)
		}
	}
	if (OnTakeDamageFUNCTIONS == [])
	{
		return
	}
	local work = true
	foreach (func in OnTakeDamageFUNCTIONS)
	{
		// The variable already exists, so these can modify it without any input from me.
		// In cases where what we return matters, try our best to keep track of that?
		local result = func[1](self,info)
		if (result == false)
		{
			work = false
		}
	}
	return work
}

function UpdateOnRemove()
{
	if (UpdateOnRemoveFUNCTIONS == [])
	{
		return
	}
	foreach (func in UpdateOnRemoveFUNCTIONS)
	{
		func[1](self)
	}
}

function ModifyEmitSoundParams()
{
	if (ModifyEmitSoundParamsFUNCTIONS == [])
	{
		return
	}
	foreach (func in ModifyEmitSoundParamsFUNCTIONS)
	{
		func[1](self, params)
	}
	return true
}