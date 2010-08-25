-------------------------------------------------------------------------
--
--	Description: GameRules implementation for car based DestructionDerby
--
----------------------------------------------------------------------------------------------------
Script.LoadScript("scripts/gamerules/singleplayer.lua", 1, 1);
--------------------------------------------------------------------------
DestructionDerby = new(SinglePlayer);

----------------------------------------------------------------------------------------------------
Net.Expose {
	Class = DestructionDerby,
	ClientMethods = {},
	ServerMethods = {
		RequestRevive		 			= { RELIABLE_UNORDERED, POST_ATTACH, ENTITYID },
		RequestSuicide                  = { RELIABLE_UNORDERED, POST_ATTACH, ENTITYID }
	},
	ServerProperties = {},
};

DestructionDerby.TICK_TIMERID				= 1010;
DestructionDerby.TICK_TIME					= 1000;

DestructionDerby.SCORE_LAST_KEY 			= 100;	-- make sure this is always the last one

DestructionDerby.vehicleTable = {}

----------------------------------------------------------------------------------------------------
function DestructionDerby:IsMultiplayer()
	return true;
end

----------------------------------------------------------------------------------------------------
function DestructionDerby.Server:OnInit()
	SinglePlayer.Server.OnInit(self);

	self.isServer=CryAction.IsServer();
	self.isClient=CryAction.IsServer();

	self.killHit = {};

	self:Reset(true);

end

----------------------------------------------------------------------------------------------------
function DestructionDerby.Server:OnStartGame()
	Log("DestructionDerby.Server:OnStartGame");
	self:StartTicking();
end

----------------------------------------------------------------------------------------------------
function DestructionDerby:OnReset()
	if (self.isServer) then
		if (self.Server.OnReset) then
			self.Server.OnReset(self);
		end
	end

	if (self.isClient) then
		if (self.Client.OnReset) then
			self.Client.OnReset(self);
		end
	end
end

----------------------------------------------------------------------------------------------------
function DestructionDerby.Server:OnReset()
	self:Reset();
end


----------------------------------------------------------------------------------------------------
function DestructionDerby.Client:OnReset()
end

----------------------------------------------------------------------------------------------------
function DestructionDerby:Reset(forcePregame)
end

----------------------------------------------------------------------------------------------------
function DestructionDerby.Client:OnActorAction(player, action, activation, value)
	if ((action == "attack1") and (activation == "press")) then
		if (player:IsDead()) then
			self.server:RequestRevive(player.id);
			return false;
		end
	elseif ((action =="use") and (activation == "press")) then
		self.server:RequestSuicide(player.id)
		return false;
	end

	return true;
end

----------------------------------------------------------------------------------------------------
function DestructionDerby.Server:OnClientConnect(channelId, reset, name)
	local player = self:SetupPlayer(channelId, name);

	return player;
end

----------------------------------------------------------------------------------------------------
function DestructionDerby.Server:OnClientDisconnect(channelId)
end

----------------------------------------------------------------------------------------------------
function DestructionDerby.Server:OnClientEnteredGame(channelId, player, reset)
end

----------------------------------------------------------------------------------------------------
function DestructionDerby.Server:OnUpdate(frameTime)
end


----------------------------------------------------------------------------------------------------
function DestructionDerby:StartTicking(client)
	if ((not client) or (not self.isServer)) then
		self:SetTimer(self.TICK_TIMERID, self.TICK_TIME);
	end
end


----------------------------------------------------------------------------------------------------
function DestructionDerby.Server:OnTimer(timerId, msec)
	if (timerId==self.TICK_TIMERID) then
		if (self.OnTick) then
			self:OnTick();
			self:SetTimer(self.TICK_TIMERID, self.TICK_TIME);
		end
	end
end


----------------------------------------------------------------------------------------------------
function DestructionDerby.Client:OnTimer(timerId, msec)
	if (timerId == self.TICK_TIMERID) then
		self:OnClientTick();
		if (not self.isServer) then
			self:SetTimer(self.TICK_TIMERID, self.TICK_TIME);
		end
	end
end


----------------------------------------------------------------------------------------------------
function DestructionDerby.Client:OnUpdate(frameTime)
	SinglePlayer.Client.OnUpdate(self, frameTime);
end

----------------------------------------------------------------------------------------------------
function DestructionDerby:SetupPlayer(channelId, name)
	if (not self.dudeCount) then self.dudeCount = 0; end;

	local pos = g_Vectors.temp_v1;
	local angles = g_Vectors.temp_v2;
	ZeroVector(pos);
	ZeroVector(angles);

	local spawn = self:GetRandomSpawnpoint()
	if (spawn) then
		pos     = spawn:GetWorldPos(pos)
		pos.z = pos.z+10 --spawn above vehicle so it doesn't kill us when being spawned
		angles  = spawn:GetWorldAngles(angles)
	end

	local player = self.game:SpawnPlayer(channelId, name or "Nomad", "Player", pos, angles);

	self:SpawnPlayer ( player.id, spawn )

	return player;
end

----------------------------------------------------------------------------------------------------
function DestructionDerby:SpawnPlayer ( playerId, spawn )

	Log ("DD:SpawnPlayer")

	local player = System.GetEntity ( playerId )

	if ( player:IsDead() ) then
		local teamId = self.game:GetTeam(playerId);
		self.game:RevivePlayer(player.id, spawn:GetPos(), g_Vectors.temp, teamId, true);
		--player.actor:SetPhysicalizationProfile("alive");
	end
	local vehicle = {};
	vehicle.class = spawn.Properties.sVehicle;
	vehicle.position = spawn:GetPos();
	vehicle.name = "MyVeh";

	Script.SetTimer(1, function()
    	local vehicle = System.SpawnEntity(vehicle);

    	if (vehicle) then
    		vehicle:AwakePhysics(1);
			vehicle:SetDirectionVector(spawn:GetDirectionVector());
			vehicle:EnterVehicle ( playerId, 1, false )
    	end
    end);

	return true;
end

----------------------------------------------------------------------------------------------------
function DestructionDerby:GetRandomSpawnpoint ()
	local spawnPoints = System.GetEntitiesByClass ( "VehicleSpawn" )
	local randomSpawn = spawnPoints[math.random(1,#spawnPoints)]

	if randomSpawn then
		return randomSpawn
	else
		Log ("No spawn found")
		return false
	end
end

----------------------------------------------------------------------------------------------------
function DestructionDerby.Server:RequestSuicide ( playerId )
	self:KillPlayer ( System.GetEntity(playerId) )
end

----------------------------------------------------------------------------------------------------
function DestructionDerby:KillPlayer(player)
	Log("KillPlayer")
	local hit = {};
	hit.pos=player:GetWorldPos();
	hit.dir=g_Vectors.v000;
	hit.radius = 0;
	hit.partId = -1;
	hit.target = player;
	hit.targetId = player.id;
	hit.weapon = player;
	hit.weaponId = player.id
	hit.shooter = player;
	hit.shooterId = player.id
	hit.materialId = 0;
	hit.damage = 0;
	hit.typeId = self.game:GetHitTypeId("normal");
	hit.type = "normal";

	self:ProcessDeath(hit);
end

----------------------------------------------------------------------------------------------------
function DestructionDerby:ProcessDeath(hit)
	Log("ProcessDeath")
	self.Server.OnPlayerKilled(self, hit);
end

----------------------------------------------------------------------------------------------------
function DestructionDerby.Server:OnPlayerKilled(hit)
	Log("OnPlayerKilled")

	local target=hit.target;
	target.death_time=_time;
	target.death_pos=target:GetWorldPos(target.death_pos);

	self.game:KillPlayer(hit.targetId, true, true, hit.shooterId, hit.weaponId, hit.damage, hit.materialId, hit.typeId, hit.dir);
end

----------------------------------------------------------------------------------------------------
function DestructionDerby.Server:RequestRevive(entityId)

	Log("DD.Server:RequestRevive");
	local player = System.GetEntity(entityId);

	if (player) then
		Log( "IsDead: "..tostring(player:IsDead()) )
		if ( player:IsDead() ) then

			local spawn = self:GetRandomSpawnpoint()
			Log("DD.Server:RequestRevive->spawn: "..tostring(spawn))
			self:SpawnPlayer(player.id, spawn);
		end
	end
end
