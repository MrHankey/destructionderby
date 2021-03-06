Script.ReloadScript( "Scripts/Entities/Boids/Chickens.lua" );

Turtles = {
	Properties = {
	},
	Sounds = 
	{
                          "Sounds/environment:random_oneshots_natural:turtle_idle",   -- idle
                          "Sounds/environment:random_oneshots_natural:turtle_scared",  -- scared
                          "Sounds/environment:random_oneshots_natural:turtle_scared",    -- die
                          "Sounds/environment:random_oneshots_natural:turtle_scared",  -- pickup
                          "Sounds/environment:random_oneshots_natural:turtle_scared",  -- throw
	},
	Animations = 
	{
		"walk_loop",   -- walking
		"idle01",      -- idle1
		"idle01",      -- scared anim
		"idle01",      -- idle3
		"idle01",      -- pickup
		"idle01",      -- throw
	},
	Editor = {
		Icon = "Bird.bmp"
	},
}

MakeDerivedEntity( Turtles,Chickens )


function Turtles:OnSpawn()
	self:SetFlags(ENTITY_FLAG_CLIENT_ONLY, 0);
end

function Turtles:GetFlockType()
	return Boids.FLOCK_TURTLES;
end