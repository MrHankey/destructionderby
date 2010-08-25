-- Paste this line into the console window to reload the tweaks file.
-- #Script.ReloadScript("Scripts/Tweaks.lua")

Tweaks = 
{
	RELOAD = true,   				-- True signals the Tweak menu to be reconstructed
	SAVECHANGES = false, 	-- True signals that changes should be found and saved to disk
	--- ItemTweaks menu - for modifying first person camera offsets
	{
		MENU = "ItemTweaks", 
		{
			NAME = "Item offset (right direction)",
			CVAR = "i_offset_right",
			DELTA = "0.01",
		},
		{
			NAME = "Item offset (up direction)",
			CVAR = "i_offset_up",
			DELTA = "0.01",
		},
		{
			NAME = "Item offset (front direction)",
			CVAR = "i_offset_front",
			DELTA = "0.01",
		},
	},
	--- Debug menu - Handy debug console vars
	{
		MENU = "Debug",
		{
			NAME = "time_scale - slow the game down or speed it up",
			CVAR = "time_scale",
			DELTA = "0.125",
		},	
		{
			NAME = "set p_draw_helpers from the console to show physics helpers",
			CVAR = "p_draw_helpers",
		},
		{
			MENU = "AI Debug",
			{
				NAME = "Enable AI debug drawing",
				CVAR = "ai_DebugDraw",
				DELTA = "1"
			},
			{
				NAME = "set ai_drawpath to an entity name to draw its path",
				CVAR = "ai_DrawPath",
			},
			{
				NAME = "set ai_stats_target to the name of the entity to track, or all",
				CVAR = "ai_StatsTarget",
			},
		},
	},
	-- Reload the Tweak file
	{		
		NAME = " * Reload Tweak Menu *",
		LUA = "MTJ.Test",
		INCREMENTER = function()
			Script.ReloadScript("Scripts/Tweaks.lua")
		end,
	},	
		
	-- Save LUA changes
	{		
		NAME = " * Save LUA Tweak changes *",
		LUA = "Tweaks.SAVECHANGES",
	},	
}


Script.ReloadScript("Scripts/TweaksSave.lua")
Script.ReloadScript("Scripts/SaveUtils.lua")