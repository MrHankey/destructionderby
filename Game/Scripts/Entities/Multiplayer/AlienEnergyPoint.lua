----------------------------------------------------------------------------------------------------
--  Crytek Source File.
--  Copyright (C), Crytek Studios, 2001-2006.
----------------------------------------------------------------------------------------------------
--  $Id$
--  $DateTime$
--  Description: AlienEnergy Entity for Power Struggle
--
----------------------------------------------------------------------------------------------------
--  History:
--  - 30:06:2006: Created by Márcio Martins
--
----------------------------------------------------------------------------------------------------
Script.ReloadScript("scripts/gamerules/powerstruggle.lua");
----------------------------------------------------------------------------------------------------
AlienEnergyPoint =
{
	Client = {};
	Server = {};
	
	Editor={
		Model="Editor/Objects/AlienEnergyPoint.cgf",
	},

	Properties =
	{
		objModel 							= "objects/default.cgf",
		
		bGeneratePower				= 1,
		nPowerIndex						= 1,
	},
};


----------------------------------------------------------------------------------------------------
AlienEnergyPoint.NetSetup={
	Class = AlienEnergyPoint,
	ClientMethods = {
	},
	ServerMethods = {
	},
	ServerProperties = {
	},
}


----------------------------------------------------------------------------------------------------
function AlienEnergyPoint:OnPreFreeze(freeze, vapor)
	if (freeze) then
		return false; -- don't allow freezing
	end
end


----------------------------------------------------------------------------------------------------
function AlienEnergyPoint:CanShatter()
	return 0;
end


----------------------------------------------------------------------------------------------------
function AlienEnergyPoint:OnSpawn()
	self.isServer=CryAction.IsServer();

	local model = self.Properties.objModel;
	if (string.len(model) > 0) then
		local ext = string.lower(string.sub(model, -4));
		if ((ext == ".chr") or (ext == ".cdf") or (ext == ".cga")) then
			self:LoadCharacter(0, model);
		else
			self:LoadObject(0, model);
		end
		
		self:Physicalize(0, PE_STATIC, {mass=0});
	end
	
	self:Activate(1);
end


----------------------------------------------------------------------------------------------------
function AlienEnergyPoint:OnReset()
	self.powerStorageId=nil;
end


----------------------------------------------------------------------------------------------------
function AlienEnergyPoint.Server:OnInit()
end


----------------------------------------------------------------------------------------------------
function AlienEnergyPoint:OnPropertyChange()
end


----------------------------------------------------------------------------------------------------
function AlienEnergyPoint:Capture(teamId)
	if (g_gameRules.AddPowerPoint) then
		g_gameRules:AddPowerPoint(self.id);
	end
end


----------------------------------------------------------------------------------------------------
function AlienEnergyPoint:Uncapture(teamId)
	if (g_gameRules.RemovePowerPoint) then
		g_gameRules:RemovePowerPoint(self.id);
	end
end


----------------------------------------------------------------------------------------------------
function AlienEnergyPoint:GetPowerStorage()
	if (not self.powerStorageId) then
		local entities=System.GetEntitiesByClass("Factory");
		if (entities) then
			for i,factory in pairs(entities) do
				if (tonumber(factory.Properties.bPowerStorage)~=0) then
					self.powerStorageId=factory.id;
					return factory;
				end
			end
		end
	else
		return System.GetEntity(self.powerStorageId);
	end
end


----------------------------------------------------------------------------------------------------
function AlienEnergyPoint:GetPowerIndex()
	if (tonumber(self.Properties.bGeneratePower)~=0) then
		local storage=self:GetPowerStorage();
		if (storage and g_gameRules.game:GetTeam(storage.id)==g_gameRules.game:GetTeam(self.id)) then -- only generate power if the team owns a factory
			return self.Properties.nPowerIndex or 0;
		end
	end

	return 0;
end


----------------------------------------------------------------------------------------------------
MakeCapturable(AlienEnergyPoint);
Net.Expose(AlienEnergyPoint.NetSetup);