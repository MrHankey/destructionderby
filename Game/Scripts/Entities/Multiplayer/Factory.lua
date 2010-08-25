----------------------------------------------------------------------------------------------------
--  Crytek Source File.
--  Copyright (C), Crytek Studios, 2001-2006.
----------------------------------------------------------------------------------------------------
--  $Id$
--  $DateTime$
--  Description: Factory Entity for Power Struggle
--
----------------------------------------------------------------------------------------------------
--  History:
--  - 13:6:2006   12:12 : Created by Márcio Martins
--
----------------------------------------------------------------------------------------------------
Script.ReloadScript("scripts/gamerules/powerstruggle.lua");
----------------------------------------------------------------------------------------------------

HELPER_WORLD = 0;
HELPER_LOCAL = 1;


Factory =
{
	Client = {};
	Server = {};
	
	Editor={
		Model="Editor/Objects/Factory.cgf",
	},
	
	Properties =
	{
		objModel 						= "objects/default.cgf",
		nQueueSize					= 5,
		Vehicles						= "us4wd,nk4wd,nktruck,ustank,ustactank,usgausstank,usapc,nktank,nktactank,nkgausstank,nkboat",
		RestrictedWeapons		= "",
		
		bGeneratePower			= 0,
		nPowerIndex					= 1,
		
		basePowerLevel			= 0;

		serviceAreaId				= 0,
		szName							= "",
		
		bPowerStorage				= 0,
		
		Sounds=
		{
			sndIdle 		= "",
			sndBusy			= "",
			sndSlotOpen	= "",
			sndSlotClose= "",
			sndSlotReady= "",
			sndSlotStart= "",
		},
	},
};


Factory.NetSetup={
	Class = Factory,
	ClientMethods =	{
		ClOpenSlot = { RELIABLE_UNORDERED, POST_ATTACH, INT8, BOOL, BOOL, },

		ClVehicleBuildStart			= { RELIABLE_ORDERED, POST_ATTACH, STRING, ENTITYID, INT8, INT8, FLOAT },
		ClVehicleBuilt					= { RELIABLE_ORDERED, NO_ATTACH, STRING, DEPENTITYID, ENTITYID, INT8, INT8 },
		
		ClVehicleQueued					= { RELIABLE_ORDERED, POST_ATTACH, STRING, },
		ClVehicleCancel					= { RELIABLE_ORDERED, POST_ATTACH, STRING, },
		
		ClSetBuyFlags						= { RELIABLE_ORDERED, NO_ATTACH, DEPENTITYID, INT16 };
	},
	ServerMethods = {
	},
	ServerProperties = {
		busy 	= BOOL,
	}
};


----------------------------------------------------------------------------------------------------
function Factory:OnPreFreeze(freeze, vapor)
	if (freeze) then
		return false; -- don't allow freezing
	end
end


----------------------------------------------------------------------------------------------------
function Factory:CanShatter()
	return 0;
end


----------------------------------------------------------------------------------------------------
function Factory:PlayFactorySound(snd, loop)
	local sound=self.sounds[snd];
	if (sound) then
	  local sndFlags = SOUND_DEFAULT_3D;
	  sndFlags = band(sndFlags, bnot(SOUND_OBSTRUCTION));
	  sndFlags = bor(sndFlags, SOUND_LOAD_SYNCHRONOUSLY);
	  if (loop) then
	  	sndFlags = bor(sndFlags, SOUND_LOOP);
	  end
	  
	  local pos=g_Vectors.temp_v1;
	  local dir=g_Vectors.temp_v2;
	  if (not slot) then
	  	pos.x=0;
	  	pos.y=0;
	  	pos.z=5;
	  	
	  	dir.x=0;
	  	dir.y=1;
	  	dir.z=0;
	  end

		local id = self:PlaySoundEvent(sound, pos, dir, sndFlags, SOUND_SEMANTIC_MECHANIC_ENTITY);
		self.soundIds[snd]=id;
	end
end


----------------------------------------------------------------------------------------------------
function Factory:StopFactorySound(snd)
	if (not self.soundIds) then
		return;
	end
	
	local id=self.soundIds[snd];
	if (id) then
		self:StopSound(id);
		self.soundIds[snd]=nil;
	end
end


----------------------------------------------------------------------------------------------------
function Factory:PlaySlotSound(slot, snd, loop)
	local sound=self.sounds[snd];
	if (sound) then
	  local sndFlags = SOUND_DEFAULT_3D;
	  sndFlags = band(sndFlags, bnot(SOUND_OBSTRUCTION));
	  sndFlags = bor(sndFlags, SOUND_LOAD_SYNCHRONOUSLY);
	  if (loop) then
	  	sndFlags = bor(sndFlags, SOUND_LOOP);
	  end
	  
	  local pos=g_Vectors.temp_v1;
	  local dir=g_Vectors.temp_v2;

	  pos=self:GetHelperPos(slot.props.SpawnHelperName, HELPER_LOCAL, pos);
	  dir=self:GetHelperDir(slot.props.SpawnHelperName, HELPER_LOCAL, dir);

		local id = self:PlaySoundEvent(sound, pos, dir, sndFlags, SOUND_SEMANTIC_MECHANIC_ENTITY);
		slot.soundIds[snd]=id;
	end
end


----------------------------------------------------------------------------------------------------
function Factory:StopSlotSound(slot, snd)
	if (not self.soundIds) then
		return;
	end
	
	local id=slot.soundIds[snd];
	if (id) then
		self:StopSound(id);
		slot.soundIds[snd]=nil;
	end
end


----------------------------------------------------------------------------------------------------
function Factory:GetResourceIndex()
	return self.Properties.nResourceIndex;
end


----------------------------------------------------------------------------------------------------
function Factory:IsBusy()
	return self.synched.busy and (self.synched.busy~=0);
end


----------------------------------------------------------------------------------------------------
function Factory:SetBusy(busy)
	self.synched.busy=busy;
end


----------------------------------------------------------------------------------------------------
function Factory:GetPowerLevel()
	if(self.Properties.buyOptions and self.Properties.buyOptions.bPrototypes==1) then
		if ((self:GetTeamId()~=0) and (g_gameRules.GetTeamPower))then
			return g_gameRules:GetTeamPower(self:GetTeamId());
		end
	end
	return 0;
end


----------------------------------------------------------------------------------------------------
function Factory:AddSlotProperty(n)
	self.Properties["Slot"..n]={
		bEnabled=1,
		SpawnHelperName="",
		OpenAnimation="",
		CloseAnimation="",
		AreaId=11,
		VehicleAreaId=11,
	}
end


----------------------------------------------------------------------------------------------------
Factory.slotCount = 6;
Factory.queueUpdateTimer = 2.5;
for i=1,Factory.slotCount do
	Factory:AddSlotProperty(i);
end


----------------------------------------------------------------------------------------------------
function Factory:OnSpawn()
	self:Activate(1);

	local model = self.Properties.objModel;
	if (string.len(model) > 0) then
		local ext = string.lower(string.sub(model, -4));

		if ((ext == ".chr") or (ext == ".cdf") or (ext == ".cga")) then
			self:LoadCharacter(0, model);
		else
			self:LoadObject(0, model);
		end
		
		if (ext == ".chr") then
			self:Physicalize(0, PE_STATIC, {mass=0});
		else
			self:Physicalize(0, PE_ARTICULATED, {mass=0});
		end
		self:AwakePhysics(0);
	end
	
	self.queueCount = tonumber(self.Properties.nQueueSize);	
	self.spawnparams={properties={Respawn={},},};
	
	local mn=g_Vectors.temp_v1;
	local mx=g_Vectors.temp_v2;
	
	self:GetLocalBBox(mn, mx);
	
	local _abs=math.abs; local _min=math.min; local _max=math.max;
	
	local maxx=_max(_abs(mn.x), _abs(mx.x));
	local maxy=_max(_abs(mn.y), _abs(mx.y));
	local maxz=_max(_abs(mn.z), _abs(mx.z));

	self.radius=2*_max(maxz, _max(maxx, maxy));
	
	Log("Factory '%s' radius: %g", self:GetName(), self.radius);
end


----------------------------------------------------------------------------------------------------
function Factory:OnReset()
	CryAction.ForceGameObjectUpdate(self.id, true);
	CryAction.DontSyncPhysics(self.id);
	
	self.isServer = CryAction.IsServer();
	self.isClient = CryAction.IsClient();

	self:ResetAnimation(0, 0);
	for i=1,self.slotCount do
		self:ResetAnimation(0, i);
	end
	
	self:RedirectAnimationToLayer0(0, true);

	if (self.slots) then	
		for i=1,self.slotCount do
			local slot=self.slots[i];
			if (slot.soundIds) then
				for name,id in pairs(slot.soundIds) do
					self:StopSlotSound(slot, name);
				end
			end
		end
	end	
	
	self.slots={};
	for i=1,self.slotCount do
		local slotProperties=self.Properties["Slot"..i];
		local slot={};
		slot.id=i;
		self:ResetSlot(slot);
		slot.props=slotProperties;

		self.slots[i]=slot;
		self:OpenSlot(slot, true, true);
	end
	
	self.vehicles={};
	for def in string.gfind(self.Properties.Vehicles, "([%w_%-]+:*%d*)") do
		local _,_,v=string.find(def, "([%w_%-]+):*(%d*)");
		if (v) then
			self.vehicles[v]=true;
		end
	end
	
	self.restricted={};
	for def in string.gfind(self.Properties.RestrictedWeapons, "([%w_%-]+:*%d*)") do
		local _,_,v=string.find(def, "([%w_%-]+):*(%d*)");
		if (v) then
			self.restricted[v]=true;
		end
	end
	
	self.queue={};
	
	self.queueTimer=self.queueUpdateTimer;
	
	self.building=0;
	
	self:StopFactorySound("idle");
	self:StopFactorySound("busy");

	self.sounds={
		idle=self.Properties.Sounds.sndIdle~="" and self.Properties.Sounds.sndIdle,
		busy=self.Properties.Sounds.sndBusy~="" and self.Properties.Sounds.sndBusy,
		open=self.Properties.Sounds.sndSlotOpen~="" and self.Properties.Sounds.sndSlotOpen,
		close=self.Properties.Sounds.sndSlotClose~="" and self.Properties.Sounds.sndSlotClose,
		ready=self.Properties.Sounds.sndSlotReady~="" and self.Properties.Sounds.sndSlotReady,
		start=self.Properties.Sounds.sndSlotStart~="" and self.Properties.Sounds.sndSlotStart,
	}
	self.soundIds={};

	self:PlayFactorySound("idle", true);

	self:SetBusy(false);
end


----------------------------------------------------------------------------------------------------
function Factory:ResetSlot(slot)
	slot.enabled=false;
	slot.areaId=-1;
	slot.vehicleAreaId=-1;
	slot.building=false;
	slot.open=false;
	slot.buildTimer=0;
	slot.buildVehicle=0;
	slot.opening=false;
	slot.closing=false;
	slot.openTimer=0;	
	slot.builtVehicleId=nil;

	slot.soundIds={};
	
	if (tonumber(self.Properties["Slot"..slot.id].bEnabled) ~= 0) then
		slot.enabled=true;
		slot.areaId=self.Properties["Slot"..slot.id].AreaId;
		slot.vehicleAreaId=self.Properties["Slot"..slot.id].VehicleAreaId;
	end	
end


----------------------------------------------------------------------------------------------------
function Factory:OnPropertyChange()
	self:OnReset();
end


----------------------------------------------------------------------------------------------------
function Factory:OnDestroy()
end


----------------------------------------------------------------------------------------------------
function Factory:OnSave(save)
end


----------------------------------------------------------------------------------------------------
function Factory:OnLoad(saved)
end


----------------------------------------------------------------------------------------------------
function Factory:Message(playerId, type, msg, ...)
	if (playerId) then
		g_gameRules.game:SendTextMessage(type, msg, TextMessageToClient, playerId, ...);
	else
		g_gameRules.game:SendTextMessage(type, msg, TextMessageToAll, ...);
	end
end


----------------------------------------------------------------------------------------------------
function Factory:CanBuild(vehicle)
	return self.vehicles[vehicle] or false;
end


----------------------------------------------------------------------------------------------------
function Factory:CanBuy(class)
	if (self.restricted[class] and self.restricted[class]==true) then
		return false;
	end
	return true;
end


----------------------------------------------------------------------------------------------------
function Factory:StartBuilding(slot, time, class, ownerId, teamId)
	Log("Vehicle Factory %s - Building %s... ready in %d seconds at door %d...", self:GetName(), class, time, slot.id);

	if (g_gameRules.Server.OnVehicleBuildStart) then
		g_gameRules.Server.OnVehicleBuildStart(g_gameRules, self, class, ownerId, teamId, slot.id, time);
	end

	self.allClients:ClVehicleBuildStart(class, ownerId, teamId, slot.id, time);

	slot.building=true;
	slot.buildTimer=time;
	slot.buildVehicle=class;
	slot.buildOwnerId=ownerId;
	slot.buildTeamId=teamId;

	self.building=self.building+1;
	if (self.building==1) then
		self:SetBusy(true);
	end
	
	slot.closing=true;
	slot.closeTimer=2.0;
end


----------------------------------------------------------------------------------------------------
function Factory:OpenSlot(slot, open, instant)
	local speed = (instant and 100.0) or 1.25;
	if (open) then
		if (((not slot.open) or instant) and slot.props.OpenAnimation ~= "") then
			self:StartAnimation(0, slot.props.OpenAnimation, slot.id, 0, speed, false, false, true);
			self:ForceCharacterUpdate(0, true);
			
			if (self.isClient and not instant) then
				self:PlaySlotSound(slot, "open");
			end
		end
	else
		if ((slot.open or instant) and slot.props.CloseAnimation ~= "") then
			self:StartAnimation(0, slot.props.CloseAnimation, slot.id, 0, speed, false, false, true);
			self:ForceCharacterUpdate(0, true);

			if (self.isClient and not instant) then
				self:PlaySlotSound(slot, "close");
			end			
		end
	end
	slot.open=open;
end


----------------------------------------------------------------------------------------------------
function Factory:StopBuilding(slot, open)
	slot.building=false;
	
	self:UpdateQueue();

	if (open) then	
		slot.opening=true;
		slot.openTimer=2.0;
	end
	
	self.building=self.building-1;
	if (self.building==0) then
		self:SetBusy(false);
	end
end


----------------------------------------------------------------------------------------------------
function Factory:CancelJobForPlayer(playerId)
	local player=System.GetEntity(playerId);
	if (not player) then
		return;
	end
	
	for i=1,self.slotCount do
		local slot=self.slots[i];
		if (slot and slot.buildOwnerId==playerId and slot.building) then
			self:StopBuilding(slot, true);
			
			if (g_gameRules and g_gameRules.OnPurchaseCancelled) then
				g_gameRules:OnPurchaseCancelled(slot.buildOwnerId, slot.buildTeamId, slot.buildVehicle);
			end		
			
			self.onClient:ClVehicleCancel(player.actor:GetChannel(), slot.buildVehicle);
		end
	end

	local n=table.getn(self.queue);
	if (n>0) then
		for i,queued in pairs(self.queue) do
			if (queued.ownerId==playerId) then
				table.remove(self.queue, i);
				
				if (g_gameRules and g_gameRules.OnPurchaseCancelled) then
					g_gameRules:OnPurchaseCancelled(queued.ownerId, queued.teamId, queued.class);
				end
				
				self.onClient:ClVehicleCancel(player.actor:GetChannel(), queued.class);
				return;
			end
		end
	end
end


----------------------------------------------------------------------------------------------------
function Factory:UpdateSlot(slot, frameTime)
	if (not slot.enabled) then
		return;
	end
	
	if (slot.building) then
		slot.buildTimer=slot.buildTimer-frameTime;

		if (slot.buildTimer<=0) then
			local vehicle=self:BuildVehicle(slot);
			self:StopBuilding(slot, true);
			
			if (g_gameRules.Server.OnVehicleBuilt) then
				g_gameRules.Server.OnVehicleBuilt(g_gameRules, self, slot.buildVehicle, vehicle.id, slot.buildOwnerId, slot.buildTeamId, slot.id);
			end

			self.allClients:ClVehicleBuilt(slot.buildVehicle, vehicle.id, slot.buildOwnerId, slot.buildTeamId, slot.id);
			slot.builtVehicleId=vehicle.id;
		end
	end

	if (slot.opening) then
		slot.openTimer=slot.openTimer-frameTime;
		if (slot.openTimer<=0) then
			
			if (not self.isClient) then
				self:OpenSlot(slot, true, false);
			end
			
			-- need to tell the clients that this is a buy zone
			if (slot.builtVehicleId) then
				local def=g_gameRules:GetItemDef(slot.buildVehicle);
				if (def.buyzoneradius and def.buyzoneflags) then
					self.allClients:ClSetBuyFlags(slot.builtVehicleId, def.buyzoneflags);
				end
			end
			
			self.allClients:ClOpenSlot(slot.id, true, false);
			slot.opening=false;
			slot.builtVehicleId=nil;
		end
	elseif(slot.closing) then
		self:KillPlayers(slot);
		slot.closeTimer=slot.closeTimer-frameTime;

		if (slot.closeTimer<=0) then
			if (not self.isClient) then
				self:OpenSlot(slot, false, false);
			end

			self.allClients:ClOpenSlot(slot.id, false, false);	
			slot.closing=false;
		end
	end
end


----------------------------------------------------------------------------------------------------
function Factory:GetParkingLocation(slot)
	local pos=self:GetHelperPos(slot.props.SpawnHelperName, HELPER_WORLD, g_Vectors.temp_v1);
	local dir=self:GetHelperDir(slot.props.SpawnHelperName, HELPER_WORLD, g_Vectors.temp_v2);

	return pos, dir;
end


----------------------------------------------------------------------------------------------------
function Factory:AdjustVehicleLocation(vehicle)
	self.v_bbox_min,self.v_bbox_max=vehicle:GetLocalBBox(self.v_bbox_min, self.v_bbox_max);
	self.v_opos=vehicle:GetWorldPos(self.v_opos);
	
	local np=g_Vectors.temp_v1;	
	np.x=(self.v_bbox_min.x+self.v_bbox_max.x)*0.5;
	np.y=(self.v_bbox_min.y+self.v_bbox_max.y)*0.5;
	np.z=self.v_bbox_min.z;
	
	self.v_npos=vehicle:ToGlobal(-1, np, self.v_npos);
	
	self.v_npos.x=self.v_opos.x+(self.v_opos.x-self.v_npos.x);
	self.v_npos.y=self.v_opos.y+(self.v_opos.y-self.v_npos.y);
	self.v_npos.z=self.v_opos.z+(self.v_opos.z-self.v_npos.z);
	
	vehicle:SetWorldPos(self.v_npos);
end


----------------------------------------------------------------------------------------------------
function Factory:BuildVehicle(slot)
	local def=g_gameRules:GetItemDef(slot.buildVehicle);
	if ((not def) or (not def.vehicle)) then
		return;
	end
	
	local pos,dir=self:GetParkingLocation(slot);

	if (def.modification) then
		self.spawnparams.properties.Modification=def.modification;
	else
		self.spawnparams.properties.Modification=nil;
	end

	if (def.abandon) then
		if (def.abandon>0) then
			self.spawnparams.properties.Respawn.bAbandon=1;
			self.spawnparams.properties.Respawn.nAbandonTimer=def.abandon;
		else
			self.spawnparams.properties.Respawn.bAbandon=0;
		end
	else
		self.spawnparams.properties.Respawn.bAbandon=1;
		self.spawnparams.properties.Respawn.nAbandonTimer=300;	
	end
	
	self.spawnparams.position=pos;
	self.spawnparams.orientation=dir;
	self.spawnparams.name=slot.buildVehicle.."_built";	
	self.spawnparams.class=def.class;
	self.spawnparams.position.z=pos.z;
	
	if (self:GetTeamId()~=0 and g_gameRules.VehiclePaint) then
		self.spawnparams.properties.Paint = g_gameRules.VehiclePaint[g_gameRules.game:GetTeamName(self:GetTeamId())] or "";
	end
	
	local vehicle=System.SpawnEntity(self.spawnparams);

	if (vehicle) then
		Log("Vehicle Factory %s - Built %s at door %s...", self:GetName(), slot.buildVehicle, slot.id);

		vehicle.builtas=slot.buildVehicle;
		
		vehicle.vehicle:SetOwnerId(slot.buildOwnerId);
		g_gameRules.game:SetTeam(slot.buildTeamId, vehicle.id);
		
		self:AdjustVehicleLocation(vehicle); -- adjust the position of the vehicle so that the vehicle is centered in the spawn helper,
																				 -- using the center of the bounding box
																				 
		vehicle:AwakePhysics(1);
	end
	
	if (def.buyzoneradius) then
		self:MakeBuyZone(vehicle, def.buyzoneradius*1.15, def.buyzoneflags);
		
		if (not def.spawngroup) then
			g_gameRules.game:AddMinimapEntity(vehicle.id, 1, 0);
		end
	end

	if (def.servicezoneradius) then
		self:MakeServiceZone(vehicle, def.servicezoneradius*1.15);
	end

	if (def.spawngroup) then
		g_gameRules.game:AddSpawnGroup(vehicle.id);
	end

	return vehicle;
end


----------------------------------------------------------------------------------------------------
function Factory:GetFreeSlot()
	for i,slot in pairs(self.slots) do	
		local free=self:IsSlotReady(slot);
		if (free) then
			return slot;
		end
	end
	return nil;
end


----------------------------------------------------------------------------------------------------
function Factory:GetBuildTime(class)
	local def=g_gameRules:GetItemDef(class);
	if (def and def.buildtime) then
		return def.buildtime;
	end
	return 30;
end


----------------------------------------------------------------------------------------------------
function Factory:Queue(class, ownerId)
	local slot=self:GetFreeSlot();
	if (slot) then
		local time=self:GetBuildTime(class);
		if (not time) then
			Log("Vehicle Factory %s - Can't build that!", self:GetName());

			return false;
		end
		self:StartBuilding(slot, time, class, ownerId, g_gameRules.game:GetTeam(ownerId));
		
		return true;
	end
	
	if (self:AddToQueue(class, ownerId)) then
		return true;
	else
		Log("Vehicle Factory %s - No free factory slots available and queue is full!", self:GetName());

		return false;
	end
end


----------------------------------------------------------------------------------------------------
function Factory:AddToQueue(class, ownerId)
	local n = table.getn(self.queue);
	if (n<self.queueCount) then
		Log("Vehicle Factory %s - Queuing %s...", self:GetName(), class);
		
		local player=System.GetEntity(ownerId);
		if (player) then
			self.onClient:ClVehicleQueued(player.actor:GetChannel(), class);
		end

		local teamId=g_gameRules.game:GetTeam(ownerId);
		table.insert(self.queue, {["class"]=class, ["ownerId"]=ownerId, ["teamId"]=teamId});
		return true;
	end
	
	return false;
end


----------------------------------------------------------------------------------------------------
function Factory:UpdateQueue()
	local n=table.getn(self.queue);
	if (n>0) then
		local slot = self:GetFreeSlot();
		if (slot) then
			local queued=self.queue[1];
			self:StartBuilding(slot, self:GetBuildTime(queued.class), queued.class, queued.ownerId, queued.teamId);
			table.remove(self.queue, 1);
		end
	end
end


----------------------------------------------------------------------------------------------------
function Factory:GetSlotETA(n)
	local slot=self.slots[n];
	if (slot.building and slot.enabled) then
		return self.slots[n].buildTimer;
	else
		return 0;
	end
end


----------------------------------------------------------------------------------------------------
function Factory:GetNearbyEntities(players, vehicles, all)
	local pos=self:GetWorldPos(g_Vectors.temp_v1);
	if (all) then
		return System.GetPhysicalEntitiesInBox(pos, self.radius);
	else
		local entities=System.GetPhysicalEntitiesInBox(pos, self.radius);
		if (not self.temp_entities) then
			self.temp_entities={};
		end
		local newentities=self.temp_entities;
		
		for i,v in pairs(newentities) do
			newentities[i]=nil;
		end
		
		for i,v in pairs(entities) do
			if (players and v.actor) then
				table.insert(newentities, v);
			elseif (vehicles and v.vehicle) then
				table.insert(newentities, v);
			end
		end
		
		return newentities;
	end
end


----------------------------------------------------------------------------------------------------
function Factory:IsSlotReady(slot)
	if ((not slot.opening) and (not slot.building) and slot.enabled) then
		local entities=self:GetNearbyEntities(false, true);
		if (entities) then
			local areaId=slot.vehicleAreaId;
			
			for i,entity in pairs(entities) do
				if (self:IsEntityInsideArea(areaId, entity.id)) then
					return false;
				end
			end
		end

		return true;
	end
	return false;
end


----------------------------------------------------------------------------------------------------
function Factory:Uncapture(teamId)
	if (self.captured) then
		for i=1,self.slotCount do
			local slot=self.slots[i];

			if (slot.enabled and slot.building) then
				if (g_gameRules and g_gameRules.OnPurchaseCancelled) then
					g_gameRules:OnPurchaseCancelled(slot.buildOwnerId, slot.buildVehicle);
				end		
				
				local player=System.GetEntity(slot.buildOwnerId);
				if (player) then
					self.onClient:ClVehicleCancel(player.actor:GetChannel(), slot.buildVehicle);
				end
			end

			self:ResetSlot(slot);

			if (slot.enabled) then
				if (not self.isClient) then
					self:OpenSlot(slot, true, false);
				end

				self.allClients:ClOpenSlot(slot.id, true, false);
			end
		end
		
		if (tonumber(self.Properties.bGeneratePower)~=0) then
			g_gameRules:RemovePowerPoint(self.id);
		end
	end
end


----------------------------------------------------------------------------------------------------
function Factory:Capture(teamId)
	if (tonumber(self.Properties.bGeneratePower)~=0) then
		g_gameRules:AddPowerPoint(self.id);
	end
end


----------------------------------------------------------------------------------------------------
function Factory:KillPlayers(slot)
	local entities=self:GetNearbyEntities(true, false);
	if (entities) then
		local areaId=slot.areaId;
		for i,entity in pairs(entities) do
			if (self:IsPointInsideArea(areaId, entity:GetWorldPos(g_Vectors.temp_v1))) then
				if (entity.actor and (not entity:IsDead())) then
					g_gameRules:CreateHit(entity.id, entity.id, NULL_ENTITY, 1000);
				end
			end
		end
	end
end


----------------------------------------------------------------------------------------------------
function Factory.Server:OnInit()
	self:OnReset();	
end


----------------------------------------------------------------------------------------------------
function Factory.Server:OnShutDown()
	if (g_gameRules) then
		g_gameRules.game:RemoveMinimapEntity(self.id);
	end
end


----------------------------------------------------------------------------------------------------
function Factory.Server:OnUpdate(frameTime)
	if (self.captured) then
		for i,slot in pairs(self.slots) do
			self:UpdateSlot(slot, frameTime);
		end
		
		if (self.queueTimer>0) then
			self.queueTimer = self.queueTimer-frameTime;
			if (self.queueTimer<=0) then
				self:UpdateQueue();
				self.queueTimer = self.queueTimer+self.queueUpdateTimer;
			end
		end
	end
	
	if (self.isClient) then
		local busy=self:IsBusy();
		if ((self.wasbusy==nil) or (self.wasbusy~=busy)) then
			if (busy) then
				self:PlayFactorySound("busy", true);
			elseif (self.soundIds["busy"]) then
				self:StopFactorySound("busy");
			end
		end
		self.wasbusy=busy;
	end
end


----------------------------------------------------------------------------------------------------
function Factory.Server:OnPostInitClient(channelId)
	for i=1,self.slotCount do
		self.onClient:ClOpenSlot(channelId, self.slots[i].id, self.slots[i].open, true);
	end
end


----------------------------------------------------------------------------------------------------
function Factory.Server:OnEnterArea(entity, areaId)
	if (areaId == self.Properties.serviceAreaId) then
		if (g_gameRules.OnEnterServiceZone) then
			g_gameRules.OnEnterServiceZone(g_gameRules, self, entity);
		end
	end
end


----------------------------------------------------------------------------------------------------
function Factory.Server:OnLeaveArea(entity, areaId)
	if (areaId == self.Properties.serviceAreaId) then
		if (g_gameRules.OnLeaveServiceZone) then
			g_gameRules.OnLeaveServiceZone(g_gameRules, self, entity);
		end
	end
end


----------------------------------------------------------------------------------------------------
function Factory:Buy(playerId, class)
	if (self:CanBuild(class)) then
		return self:Queue(class, playerId);
	else
		self:Message(playerId, TextMessageError, "@mp_CannotBuild!");
	end
	
	return false;
end


----------------------------------------------------------------------------------------------------
function Factory.Client:OnInit()
	self:OnReset();
end


----------------------------------------------------------------------------------------------------
function Factory.Client:ClOpenSlot(slotId, open, instant)
	--Log("Factory::ClOpenSlot: %s open=%s wasopen=%s", slotId, tostring(open), tostring(self.slots[slotId].open));
	self:OpenSlot(self.slots[slotId], open, instant);
end


----------------------------------------------------------------------------------------------------
function Factory.Client:ClVehicleBuildStart(vehicleName, ownerId, teamId, gateId, time)
	if (g_gameRules.Client.OnVehicleBuildStart) then
		g_gameRules.Client.OnVehicleBuildStart(g_gameRules, self, vehicleName, ownerId, teamId, gateId, time);
	end
	
	local slot=self.slots[gateId];
	if (slot) then
		self:PlaySlotSound(slot, "start");
	end
end


----------------------------------------------------------------------------------------------------
function Factory.Client:ClVehicleQueued(vehicleName)
	if (g_gameRules.Client.OnVehicleQueued) then
		g_gameRules.Client.OnVehicleQueued(g_gameRules, self, vehicleName);
	end
end


----------------------------------------------------------------------------------------------------
function Factory.Client:ClVehicleCancel(vehicleName)
	if (g_gameRules.Client.OnVehicleCancel) then
		g_gameRules.Client.OnVehicleCancel(g_gameRules, self, vehicleName);
	end
end


----------------------------------------------------------------------------------------------------
function Factory.Client:ClVehicleBuilt(vehicleName, vehicleId, ownerId, teamId, gateId)
	if (g_gameRules.Client.OnVehicleBuilt) then
		g_gameRules.Client.OnVehicleBuilt(g_gameRules, self, vehicleName, vehicleId, ownerId, teamId, gateId);
	end

	local slot=self.slots[gateId];
	if (slot) then
		self:PlaySlotSound(slot, "ready");
	end
end


----------------------------------------------------------------------------------------------------
function Factory.Client:ClSetBuyFlags(entityId, flags)
	local entity=System.GetEntity(entityId);
	if (not entity) then
		Log("%s.Client:ClSetBuyFlags() failed. Unknown entity", self:GetName());
		return;
	end
	
	--Log("%s.Client:ClSetBuyFlags(%s, %d)", self:GetName(), entity:GetName(), flags);
	
	if (entity.GetBuyFlags) then
		entity.buyFlags=flags;
	else
		entity.buyFlags=flags;
		entity.GetBuyFlags=function(self)
			return self.buyFlags;
		end
	end
	
	if (g_gameRules.Client.OnSetBuyFlags) then
		g_gameRules.Client.OnSetBuyFlags(g_gameRules, entityId, flags);
	end
end


----------------------------------------------------------------------------------------------------
function Factory:MakeBuyZone(vehicle, radius, flags)
	vehicle.OnEnterArea=replace_pre(vehicle.OnEnterArea, function(self, entity, areaId)
		if (entity.actor and (not self.State.destroyed)) then
			if (g_gameRules.OnEnterBuyZone) then
				g_gameRules.OnEnterBuyZone(g_gameRules, self, entity);
			end
		end
	end);

	vehicle.OnLeaveArea=replace_pre(vehicle.OnLeaveArea, function(self, entity, areaId)
		if (entity.actor) then
			if (g_gameRules.OnLeaveBuyZone) then
				g_gameRules.OnLeaveBuyZone(g_gameRules, self, entity);
			end
		end	
	end);

	vehicle.GetBuyFlags=function(self)
		return self.buyFlags;
	end

	vehicle.buyFlags=flags or PowerStruggle.BUY_AMMO;
	--[[
 	local Min = { x=-radius, y=-radius, z=-radius };
	local Max = { x=radius, y=radius, z=radius };
	vehicle:SetTriggerBBox(Min, Max);	~
	]]--
	
	local dim=2*radius;
	
	local trigger=System.SpawnEntity{
		class="ProximityTrigger",
		flags=ENTITY_FLAG_SERVER_ONLY,
		position={x=0, y=0, z=0},
		name=vehicle:GetName().."_buy_zone_trigger",
		
		
		properties={
			DimX=dim,
			DimY=dim,
			DimZ=dim,
			bOnlyPlayer=0,
		},
	};
	vehicle:AttachChild(trigger.id, 0);
	trigger:ForwardTriggerEventsTo(vehicle.id);	
end


----------------------------------------------------------------------------------------------------
function Factory:MakeServiceZone(vehicle, radius)
	vehicle.OnEnterArea=replace_pre(vehicle.OnEnterArea, function(self, entity, areaId)
		if (entity.actor and (not self.State.destroyed)) then
			if (g_gameRules.OnEnterServiceZone) then
				g_gameRules.OnEnterServiceZone(g_gameRules, self, entity);
			end
		end
	end);

	vehicle.OnLeaveArea=replace_pre(vehicle.OnLeaveArea, function(self, entity, areaId)
		if (entity.actor) then
			if (g_gameRules.OnLeaveServiceZone) then
				g_gameRules.OnLeaveServiceZone(g_gameRules, self, entity);
			end
		end	
	end);
	--[[
 	local Min = { x=-radius, y=-radius, z=-radius };
	local Max = { x=radius, y=radius, z=radius };
	vehicle:SetTriggerBBox(Min, Max);
	
	]]--
	
	local dim=2*radius;
	
	local trigger=System.SpawnEntity{
		class="ProximityTrigger",
		flags=ENTITY_FLAG_SERVER_ONLY,
		position={x=0, y=0, z=0},
		name=vehicle:GetName().."_service_zone_trigger",
		
		
		properties={
			DimX=dim,
			DimY=dim,
			DimZ=dim,
			bOnlyPlayer=0,
		},
	};
	vehicle:AttachChild(trigger.id, 0);
	trigger:ForwardTriggerEventsTo(vehicle.id);
end


----------------------------------------------------------------------------------------------------
MakeCapturable(Factory);
MakeBuyZone(Factory, bor(PowerStruggle.BUY_VEHICLE,PowerStruggle.BUY_AMMO));
Net.Expose(Factory.NetSetup);
