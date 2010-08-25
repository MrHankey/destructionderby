--------------------------------------------------------------------------
--	Crytek Source File.
-- 	Copyright (C), Crytek Studios, 2001-2005.
--------------------------------------------------------------------------
--	$Id$
--	$DateTime$
--	Description: FlowGraph node which performs a camera shake
--  
--------------------------------------------------------------------------
--  History:
--  - 30/09/2005   : Created by Sascha Gundlach
--
--------------------------------------------------------------------------

CameraShake = {
	Category = "legacy",
	Inputs = {{"t_Activate","bool"},{"Position","vec3"}, {"Radius","float"}, {"Strength","float"}, {"Duration","float"}, {"Frequency","float"}},
	Outputs = {{"Done","bool"}},
	Implementation=function(bActivate,vPosition,fRadius,fStrength,fDuration,fFrequency)
		g_gameRules:ClientViewShake(vPosition,fRadius,fStrength,fDuration,fFrequency);
		Script.SetTimer(fDuration*1000,function() return 1;end);
	end;
} 


