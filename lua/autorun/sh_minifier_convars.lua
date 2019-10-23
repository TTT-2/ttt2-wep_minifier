CreateConVar('ttt_minifier_use_time', 25, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar('ttt_minifier_cooldown_time', 15, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
CreateConVar('ttt_minifier_factor', 0.5, {FCVAR_NOTIFY, FCVAR_ARCHIVE})

hook.Add('TTTUlxInitCustomCVar', 'ttt2_minifier_replicate_convars', function(name)
    ULib.replicatedWritableCvar('ttt_minifier_use_time', 'rep_ttt_minifier_use_time', GetConVar('ttt_minifier_use_time'):GetInt(), true, false, name)
    ULib.replicatedWritableCvar('ttt_minifier_cooldown_time', 'rep_ttt_minifier_cooldown_time', GetConVar('ttt_minifier_cooldown_time'):GetInt(), true, false, name)
    ULib.replicatedWritableCvar('ttt_minifier_factor', 'rep_ttt_minifier_factor', GetConVar('ttt_minifier_factor'):GetFloat(), true, false, name)
end)

if SERVER then
    -- ConVar replication is broken in GMod, so we do this, at least Alf added a hook!
    -- I don't like it any more than you do, dear reader. Copycat!
    hook.Add('TTT2SyncGlobals', 'ttt2_supersoda_sync_convars', function()
        SetGlobalFloat('ttt_minifier_factor', GetConVar('ttt_minifier_factor'):GetFloat())
        SetGlobalFloat('ttt_minifier_factor_inv', 1 / GetConVar('ttt_minifier_factor'):GetFloat())
    end)

    -- sync convars on change
    cvars.AddChangeCallback('ttt_minifier_factor', function(cv, old, new)
        SetGlobalFloat('ttt_minifier_factor', tonumber(new))
        SetGlobalFloat('ttt_minifier_factor_inv', 1 / tonumber(new))
    end)
end

-- add to ULX
if CLIENT then
    hook.Add('TTTUlxModifyAddonSettings', 'ttt2_minifier_add_to_ulx', function(name)
        local tttrspnl = xlib.makelistlayout{w = 415, h = 318, parent = xgui.null}

        -- Basic Settings
        local tttrsclp = vgui.Create('DCollapsibleCategory', tttrspnl)
        tttrsclp:SetSize(390, 75)
        tttrsclp:SetExpanded(1)
        tttrsclp:SetLabel('Basic Settings')

        local tttrslst = vgui.Create('DPanelList', tttrsclp)
        tttrslst:SetPos(5, 25)
        tttrslst:SetSize(390, 75)
        tttrslst:SetSpacing(5)

        local tttslid1 = xlib.makeslider{label = 'ttt_minifier_use_time (def. 25)', repconvar = 'rep_ttt_minifier_use_time', min = 0, max = 100, decimal = 0, parent = tttrslst}
        tttrslst:AddItem(tttslid1)

        local tttslid2 = xlib.makeslider{label = 'ttt_minifier_cooldown_time (def. 15)', repconvar = 'rep_ttt_minifier_cooldown_time', min = 0, max = 100, decimal = 0, parent = tttrslst}
        tttrslst:AddItem(tttslid2)

        local tttslid3 = xlib.makeslider{label = 'ttt_minifier_factor (def. 0.5)', repconvar = 'rep_ttt_minifier_factor', min = 0.01, max = 2, decimal = 2, parent = tttrslst}
        tttrslst:AddItem(tttslid3)

        -- add to ULX
        xgui.hookEvent('onProcessModules', nil, tttrspnl.processModules)
        xgui.addSubModule('Minifier', tttrspnl, nil, name)
    end)
end
