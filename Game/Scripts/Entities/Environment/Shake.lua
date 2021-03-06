Shake = {
	type = "Shake",
	Properties = {
		Radius = 30.0,
		Shake = 0.05,
	},
	
	Editor={
		--Model="Editor/Objects/T.cgf",
		--Icon="Tornado.bmp",
	},
}


function Shake:OnInit()
	self:OnReset();
end

function Shake:OnPropertyChange()
	self:OnReset();
end

function Shake:OnReset()
end

function Shake:OnSave(tbl)
end

function Shake:OnLoad(tbl)
end

function Shake:OnShutDown()
end

function Shake:Event_Enable( sender )
end

function Shake:Event_Disable( sender )
end

Shake.FlowEvents =
{
	Inputs =
	{
		Disable = { Shake.Event_Disable, "bool" },
		Enable = { Shake.Event_Enable, "bool" },
	},
	Outputs =
	{
		Disable = "bool",
		Enable = "bool",
	},
}
