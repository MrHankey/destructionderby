Script.ReloadScript("Scripts/Entities/Vehicles/VehicleSystem.lua");

VehicleSpawn = {

	Properties = {
		sVehicle = "Civ_car1"
	},

    LastVehicle = "",

	Editor = { Icon= "VehicleSpawn.bmp" },

    Client = {},
	Server = {},
}

Net.Expose {
	Class = VehicleSpawn,
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
	if (self.Properties.sVehicle ~= "") then
        local model = self:GetModelFromName ( self.Properties.sVehicle )
        if ( model ) and ( not g_gameRules:IsMultiplayer() ) then
            self:LoadObject(0, model);
        else
            Log ( "Invalid vehicle name specified!" )
        end
	end
end

function VehicleSpawn:OnPropertyChange()
	self:OnReset();
end

function VehicleSpawn:GetModelFromName( name )
    local xmlTable = VehicleSystem.LoadXML ( name )
    return xmlTable.Parts[1].Animated.filename
end

function testenter()
    local nextSpawn = System.GetNearestEntityByClass(g_localActor:GetPos(), 50, "VehicleSpawn");
    dump (nextSpawn)
    local myEnt = {};
    myEnt.class = nextSpawn.Properties.sVehicle;
    myEnt.position = nextSpawn:GetPos();
    --myEnt.dir = nextSpawn:GetDirectionVector();
    myEnt.name = "MyVeh";
    local myEnt = System.SpawnEntity(myEnt);
    myEnt:SetDirectionVector(nextSpawn:GetDirectionVector());

    Log ( tostring(myEntId).." "..tostring(nextSpawn) )

    myEnt:EnterVehicle ( g_localActor.id, 1, false )
end

System.AddCCommand("enter", "testenter()", "blubb")
