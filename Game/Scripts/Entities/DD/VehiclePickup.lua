Script.ReloadScript("Scripts/Entities/Vehicles/VehicleSystem.lua");

VehicleSpawn = {

	Properties = {
        
        sType           = "repair"
		fRespawnTime    = 0
        object_Model    = "Editor/Objects/repair.cgf"
	},
    
    LastVehicle = "",
    
	Editor = { Icon= "VehicleSpawn.bmp" },
    
    Client = {},
	Server = {},
}

Net.Expose {
	Class = VehiclePickup,
	ClientMethods = {},
	ServerMethods = {},
	ServerProperties = {},
};

function VehicleSpawn:OnInit()
	self:OnReset();
end

function VehicleSpawn:OnSpawn()	
	self:OnReset();
end

function VehicleSpawn:OnReset()
	if (self.Properties.sType == "repair") then
        if model then
            self:LoadObject(0, model);
        else
            Log ( "Invalid vehicle name specified!" )
        end
	end
end

function VehicleSpawn:OnPropertyChange()
	self:OnReset();
end
