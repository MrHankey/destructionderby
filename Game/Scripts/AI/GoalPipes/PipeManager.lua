PipeManager =	 {

}


function PipeManager:OnInit()


	AI.LogEvent("PipeManager initialized");
	
	Script.ReloadScript("Scripts/AI/GoalPipes/PipeManagerShared.lua");
	Script.ReloadScript("Scripts/AI/GoalPipes/PipeManager2.lua");
	Script.ReloadScript("Scripts/AI/GoalPipes/PipeManagerJob.lua");
	Script.ReloadScript("Scripts/AI/GoalPipes/PipeManagerCombat.lua");
	Script.ReloadScript("Scripts/AI/GoalPipes/PMReusable.lua");
	Script.ReloadScript("Scripts/AI/GoalPipes/PipeManagerAlien.lua");
	Script.ReloadScript("Scripts/AI/GoalPipes/PipeManagerVehicle.lua");
	Script.ReloadScript("Scripts/AI/GoalPipes/PipeManagerTrooper.lua");
	Script.ReloadScript("Scripts/AI/GoalPipes/PMSingle.lua");	
	Script.ReloadScript("Scripts/AI/GoalPipes/PipeManagerCover2.lua");	
	Script.ReloadScript("Scripts/AI/GoalPipes/PipeManagerSquad.lua");	
	
	
	PipeManager:OnInitShared();
	PipeManager:OnInit2();
	PipeManager:InitReusable();
	PipeManager:OnInitJob();
	PipeManager:OnInitCombat();
	PipeManager:OnInitAlien();	
	PipeManager:OnInitVehicle();	
	PipeManager:OnInitTrooper();	
	PipeManager:OnInitSingle();
	PipeManager:OnInitCover2();
	PipeManager:InitSquad();
	

	-- goal pipe used as inserted pipe while executing actions. used to temporary suspend previous pipe.
	-- it never ends, but will be forced to end by AI Action system after action execution
	AI.CreateGoalPipe("_action_");
	AI.PushGoal("_action_","timeout",1,0.1);
	AI.PushGoal("_action_","branch",1,-1,BRANCH_ALWAYS);

	-- need this to let the AISystem know - all the later created pipes are dynamic, need to be saved
	AI.CreateGoalPipe("_last_");
	
	
end
