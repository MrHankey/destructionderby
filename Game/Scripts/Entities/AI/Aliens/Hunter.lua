Script.ReloadScript( "SCRIPTS/Entities/AI/Aliens/Hunter_x.lua");

CreateAlien(Hunter_x);
Hunter = CreateAI(Hunter_x)
Hunter:Expose();

