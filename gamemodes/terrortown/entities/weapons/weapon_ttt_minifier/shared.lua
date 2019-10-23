if SERVER then
    AddCSLuaFile()

    resource.AddFile('sound/minifier_shrink.wav')

    resource.AddFile('materials/vgui/ttt/icon_minifier')
    resource.AddFile('materials/vgui/ttt/hud_icon_minified.png')
    resource.AddFile('materials/vgui/ttt/hud_icon_minify_disabled.png')
end

SWEP.Base = 'weapon_tttbase'

if CLIENT then
    hook.Add('Initialize', 'ttt2_minifier_init_language', function()
        LANG.AddToLanguage('English', 'ttt2_weapon_minifier', 'Minifier')
        LANG.AddToLanguage('Deutsch', 'ttt2_weapon_minifier', 'Verkleinerer')
        
        LANG.AddToLanguage('English', 'ttt2_weapon_minifier_desc', 'Use this item to shrink the size of your own body!')
        LANG.AddToLanguage('Deutsch', 'ttt2_weapon_minifier_desc', 'Nutze dieses Item um deine Körpergröße zu verringern!')
    end)

    SWEP.Author = 'Mineotopia'

    SWEP.ViewModelFOV = 54
    SWEP.ViewModelFlip = false

    SWEP.Category = 'Deagle'
    SWEP.Icon = 'vgui/ttt/icon_minifier'
    SWEP.EquipMenuData = {
        type = 'item_weapon',
        name = 'ttt2_weapon_minifier',
        desc = 'ttt2_weapon_minifier_desc'
    }

    sound.Add({
        name = 'minifing_player',
        channel = CHAN_STATIC,
        volume = 1.0,
        level = 130,
        sound = 'minifier_shrink.wav'
    })
end

SWEP.Spawnable = false
SWEP.AdminSpawnable = true
SWEP.HoldType = 'slam'
SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}
SWEP.ViewModelFlip = false
SWEP.ViewModel = 'models/weapons/c_slam.mdl'
SWEP.WorldModel = 'models/weapons/w_slam.mdl'
SWEP.UseHands = true

--- PRIMARY FIRE ---
SWEP.Primary.Delay = 0.1
SWEP.Primary.Recoil = 0
SWEP.Primary.Damage = 0
SWEP.Primary.NumShots = 1
SWEP.Primary.Cone = 0
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = 'none'
SWEP.NoSights = true

if SERVER then
    util.AddNetworkString('ttt2_minifier_update_state')

    local function SetUpMinifyTimeouts(ply)
        local time = GetConVar('ttt_minifier_use_time'):GetInt()

        STATUS:AddTimedStatus(ply, 'ttt2_minifier_active', time, true)

        ply.minifier_active_timer_id = 'minifier_active_timer_' .. tostring(CurTime())

        timer.Create(ply.minifier_active_timer_id, time, 1, function()
            if not ply or not IsValid(ply) then return end

            UnMinifyPlayer(ply)
        end)
    end

    local function SetUpUnMinifyTimeouts(ply)
        local time = GetConVar('ttt_minifier_cooldown_time'):GetInt()

        STATUS:RemoveStatus(ply, 'ttt2_minifier_active')
        STATUS:AddTimedStatus(ply, 'ttt2_minifier_cooldown', time, true)

        timer.Remove(ply.minifier_active_timer_id)

        ply.minifier_cooldown_timer_id = 'minifier_cooldown_timer_' .. tostring(CurTime())
        ply.minify_cooldown = true

        timer.Create(ply.minifier_cooldown_timer_id, time, 1, function()
            if not ply or not IsValid(ply) then return end

            STATUS:RemoveStatus(ply, 'ttt2_minifier_cooldown')
            ply.minify_cooldown = false
        end)
    end

    function MinifyPlayer(ply)
        if not ply or not IsValid(ply) then return end
        if ply.minified then return end

        ply.minified = true
        net.Start('ttt2_minifier_update_state')
        net.WriteBool(true)
        net.Send(ply)

        ply:SetHealth(ply:Health() * 0.5)
        ply:SetMaxHealth(ply:GetMaxHealth() * 0.5)

        ply:SetStepSize(ply:GetStepSize() * 0.5)
        ply:SetModelScale(ply:GetModelScale() * 0.5, 0.5)
        ply:SetViewOffset(ply:GetViewOffset() * 0.5)
        ply:SetViewOffsetDucked(ply:GetViewOffsetDucked() * 0.5)

        ply:SetGravity(1.75)

        local hull_min, hull_max = ply:GetHull()
        hull_max.z = hull_max.z * 0.5
        ply:SetHull(hull_min, hull_max)

        local hull_min_ducked, hull_max_ducked = ply:GetHullDuck()
        hull_max_ducked.z = hull_max_ducked.z * 0.5
        ply:SetHullDuck(hull_min_ducked, hull_max_ducked)

        SetUpMinifyTimeouts(ply)
    end

    function UnMinifyPlayer(ply)
        if not ply or not IsValid(ply) then return end
        if not ply.minified then return end

        ply.minified = false
        net.Start('ttt2_minifier_update_state')
        net.WriteBool(false)
        net.Send(ply)

        ply:SetHealth(ply:Health() * 2)
        ply:SetMaxHealth(ply:GetMaxHealth() * 2)

        ply:SetModelScale(ply:GetModelScale() * 2, 0.5)
        ply:SetStepSize(ply:GetStepSize() * 2)
        ply:SetViewOffset(ply:GetViewOffset() * 2)
        ply:SetViewOffsetDucked(ply:GetViewOffsetDucked() * 2)

        ply:SetGravity(1)

        ply:ResetHull()

        SetUpUnMinifyTimeouts(ply)
    end

    function ToggleMinifyPlayer(ply)
        if not ply or not IsValid(ply) then return end

        if ply.minified then
            UnMinifyPlayer(ply)
        else
            MinifyPlayer(ply)
        end
    end

    function SWEP:Initialize()
        self.BaseClass.Initialize(self)

        self:SetDeploySpeed(10)
    end

    function SWEP:PrimaryAttack()
        if self.Owner.minify_cooldown then return end

        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    
        ToggleMinifyPlayer(self.Owner)
    end
    
    function SWEP:PreDrop()
        UnMinifyPlayer(self.Owner)
    end
    
    hook.Add('TTTPrepareRound', 'ttt2_minifier_speed_reset_all', function()
        for _, p in pairs(player.GetAll()) do
            UnMinifyPlayer(p)
        end
    end)
end

if CLIENT then
    net.Receive('ttt2_minifier_update_state', function()
        local client = LocalPlayer()

        if not client or not IsValid(client) then return end

        client.minified = net.ReadBool()
        client:EmitSound('minifing_player', 80)
    end)

    hook.Add('Initialize', 'ttt2_dancegun_status_init', function() 
        STATUS:RegisterStatus('ttt2_minifier_active', {
            hud = Material('vgui/ttt/hud_icon_minified.png'),
            type = 'good'
        })
        STATUS:RegisterStatus('ttt2_minifier_cooldown', {
            hud = Material('vgui/ttt/hud_icon_minify_disabled.png'),
            type = 'bad'
        })
    end)
end

hook.Add('TTTPlayerSpeedModifier', 'ttt2_minifier_speed' , function(ply, _, _, noLag)
    if not ply or not IsValid(ply) then return end
    if not ply.minified then return end

    noLag[1] = noLag[1] * 0.5
end)