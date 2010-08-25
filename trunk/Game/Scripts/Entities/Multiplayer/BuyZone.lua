----------------------------------------------------------------------------------------------------
--  Crytek Source File.
--  Copyright (C), Crytek Studios, 2001-2006.
----------------------------------------------------------------------------------------------------
--  $Id$
--  $DateTime$
--  Description: Buy Zone Entity for Power Struggle
--
----------------------------------------------------------------------------------------------------
--  History:
--  - 13:6:2006   12:12 : Created by Márcio Martins
--
----------------------------------------------------------------------------------------------------
Script.ReloadScript("scripts/gamerules/powerstruggle.lua");
----------------------------------------------------------------------------------------------------
BuyZone=
{
	Server={},
	Client={},

	Editor={
		Model="Editor/Objects/BuyZone.cgf",
	},
	
	type = "BuyZone",

	Properties=
	{
		bEnabled=1,
		teamName="",
	},	
}


----------------------------------------------------------------------------------------------------
function BuyZone:OnPropertyChange()
	self:OnReset();
end


----------------------------------------------------------------------------------------------------
function BuyZone.Server:OnInit()
	self:OnReset();
end


----------------------------------------------------------------------------------------------------
function BuyZone:OnReset()
	self:Enable(tonumber(self.Properties.bEnabled)~=0);
	
	self.isServer = CryAction.IsServer();
	--self.isClient = CryAction.IsClient();

	if (self.isServer) then
		local teamId=g_gameRules.game:GetTeamId(self.Properties.teamName);
		if (teamId and teamId~=0) then
			self:SetTeamId(teamId);
		else
			self:SetTeamId(0);
		end
	end
end


----------------------------------------------------------------------------------------------------
function BuyZone:GetTeamId()
	return g_gameRules.game:GetTeam(self.id) or 0;
end


----------------------------------------------------------------------------------------------------
function BuyZone:SetTeamId(teamId)
	g_gameRules.game:SetTeam(teamId, self.id);
end


----------------------------------------------------------------------------------------------------
function BuyZone:Enable(enable)
	self.enabled=enable;
end


----------------------------------------------------------------------------------------------------
MakeBuyZone(BuyZone, bor(bor(PowerStruggle.BUY_WEAPON,PowerStruggle.BUY_AMMO), PowerStruggle.BUY_EQUIPMENT));