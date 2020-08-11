CreateConVar("ttt_minifier_use_time", 30, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
CreateConVar("ttt_minifier_cooldown_time", 10, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
CreateConVar("ttt_minifier_factor", 0.5, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})

hook.Add("TTTUlxInitCustomCVar", "ttt2_minifier_replicate_convars", function(name)
	ULib.replicatedWritableCvar("ttt_minifier_use_time", "rep_ttt_minifier_use_time", GetConVar("ttt_minifier_use_time"):GetInt(), true, false, name)
	ULib.replicatedWritableCvar("ttt_minifier_cooldown_time", "rep_ttt_minifier_cooldown_time", GetConVar("ttt_minifier_cooldown_time"):GetInt(), true, false, name)
	ULib.replicatedWritableCvar("ttt_minifier_factor", "rep_ttt_minifier_factor", GetConVar("ttt_minifier_factor"):GetFloat(), true, false, name)
end)

-- add to ULX
if CLIENT then
	hook.Add("TTTUlxModifyAddonSettings", "ttt2_minifier_add_to_ulx", function(name)
		local tttrspnl = xlib.makelistlayout{w = 415, h = 318, parent = xgui.null}

		-- Basic Settings
		local tttrsclp = vgui.Create("DCollapsibleCategory", tttrspnl)
		tttrsclp:SetSize(390, 75)
		tttrsclp:SetExpanded(1)
		tttrsclp:SetLabel("Basic Settings")

		local tttrslst = vgui.Create("DPanelList", tttrsclp)
		tttrslst:SetPos(5, 25)
		tttrslst:SetSize(390, 75)
		tttrslst:SetSpacing(5)

		tttrslst:AddItem(xlib.makeslider{
			label = "ttt_minifier_use_time (def. 25)",
			repconvar = "rep_ttt_minifier_use_time",
			min = 0,
			max = 100,
			decimal = 0,
			parent = tttrslst
		})

		tttrslst:AddItem(xlib.makeslider{
			label = "ttt_minifier_cooldown_time (def. 15)",
			repconvar = "rep_ttt_minifier_cooldown_time",
			min = 0,
			max = 100,
			decimal = 0,
			parent = tttrslst
		})

		tttrslst:AddItem(xlib.makeslider{
			label = "ttt_minifier_factor (def. 0.5)",
			repconvar = "rep_ttt_minifier_factor",
			min = 0.01,
			max = 2,
			decimal = 2,
			parent = tttrslst
		})

		-- add to ULX
		xgui.hookEvent("onProcessModules", nil, tttrspnl.processModules)
		xgui.addSubModule("Minifier", tttrspnl, nil, name)
	end)
end
