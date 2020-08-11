if SERVER then
	AddCSLuaFile()

	resource.AddFile("sound/minifier_shrink.wav")

	resource.AddFile("materials/vgui/ttt/icon_minifier")
	resource.AddFile("materials/vgui/ttt/hud_icon_minified.png")
	resource.AddFile("materials/vgui/ttt/hud_icon_minify_disabled.png")
end

SWEP.Base = "weapon_tttbase"

if CLIENT then
	SWEP.Author = "Mineotopia"

	SWEP.ViewModelFOV = 54
	SWEP.ViewModelFlip = false

	SWEP.Category = "Deagle"
	SWEP.Icon = "vgui/ttt/icon_minifier"
	SWEP.EquipMenuData = {
		type = "item_weapon",
		name = "ttt2_weapon_minifier",
		desc = "ttt2_weapon_minifier_desc"
	}

	sound.Add({
		name = "minifing_player",
		channel = CHAN_STATIC,
		volume = 1.0,
		level = 130,
		sound = "minifier_shrink.wav"
	})
end

SWEP.Spawnable = false
SWEP.AdminSpawnable = true
SWEP.HoldType = "slam"
SWEP.Kind = WEAPON_EQUIP2
SWEP.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}
SWEP.ViewModelFlip = false
SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
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
SWEP.Primary.Ammo = "none"
SWEP.NoSights = true

if SERVER then
	util.AddNetworkString("ttt2_minifier_update_state")

	-- helperfuncrion to start the use timer
	local function SetUpMinifyTimeouts(ply)
		local time = GetConVar("ttt_minifier_use_time"):GetInt()

		STATUS:AddTimedStatus(ply, "ttt2_minifier_active", time, true)

		ply.minifier_active_timer_id = "minifier_active_timer_" .. tostring(CurTime())

		timer.Create(ply.minifier_active_timer_id, time, 1, function()
			if not ply or not IsValid(ply) then return end

			UnMinifyPlayer(ply)
		end)
	end

	-- helperfunction to start the cooldown timer
	local function SetUpUnMinifyTimeouts(ply)
		local time = GetConVar("ttt_minifier_cooldown_time"):GetInt()

		STATUS:RemoveStatus(ply, "ttt2_minifier_active")
		STATUS:AddTimedStatus(ply, "ttt2_minifier_cooldown", time, true)

		if ply.minifier_active_timer_id then
			timer.Remove(ply.minifier_active_timer_id)
		end

		ply.minifier_cooldown_timer_id = "minifier_cooldown_timer_" .. tostring(CurTime())
		ply.minify_cooldown = true

		timer.Create(ply.minifier_cooldown_timer_id, time, 1, function()
			if not ply or not IsValid(ply) then return end

			STATUS:RemoveStatus(ply, "ttt2_minifier_cooldown")

			ply.minify_cooldown = false
		end)
	end

	function MinifyPlayer(ply)
		if not IsValid(ply) or ply.minified then return end

		-- set state variable
		ply.minified = true

		-- sync state variable to client
		net.Start("ttt2_minifier_update_state")
		net.WriteBool(true)
		net.Send(ply)

		-- create original data table
		local data = {
			stepSize = ply:GetStepSize(),
			modelScale = ply:GetModelScale(),
			viewOffset = ply:GetViewOffset(),
			viewOffsetDucked = ply:GetViewOffsetDucked()
		}

		ply.minifierData = data

		-- change player health when minified
		ply:SetHealth(ply:Health() * GetConVar("ttt_minifier_factor"):GetFloat())
		ply:SetMaxHealth(ply:GetMaxHealth() * GetConVar("ttt_minifier_factor"):GetFloat())

		-- change the model and first person view cam
		ply:SetStepSize(data.stepSize * GetConVar("ttt_minifier_factor"):GetFloat())
		ply:SetModelScale(data.modelScale * GetConVar("ttt_minifier_factor"):GetFloat())
		ply:SetViewOffset(data.viewOffset * GetConVar("ttt_minifier_factor"):GetFloat())
		ply:SetViewOffsetDucked(data.viewOffsetDucked * GetConVar("ttt_minifier_factor"):GetFloat())

		-- increase gravity to decrease jumpheight
		ply:SetGravity(ply:GetGravity() * 1.75)

		-- change the hull of the player, this is needed since the model scaling only affects
		-- the player-player hitbox, not the player-prop hitbox
		-- only the z direction is changed to prevent glitching in walls when walking close to walls
		local hull_min, hull_max = ply:GetHull()
		hull_max.z = hull_max.z * GetConVar("ttt_minifier_factor"):GetFloat()
		ply:SetHull(hull_min, hull_max)

		local hull_min_ducked, hull_max_ducked = ply:GetHullDuck()
		hull_max_ducked.z = hull_max_ducked.z * GetConVar("ttt_minifier_factor"):GetFloat()
		ply:SetHullDuck(hull_min_ducked, hull_max_ducked)

		-- set timer to stop minier after a certain amount of time
		SetUpMinifyTimeouts(ply)
	end

	-- reset the minifaction
	function UnMinifyPlayer(ply)
		if not IsValid(ply) or not ply.minified then return end

		-- set state variable
		ply.minified = false

		-- sync state variable to client
		net.Start("ttt2_minifier_update_state")
		net.WriteBool(false)
		net.Send(ply)

		-- reset the health of the player
		ply:SetHealth(ply:Health() / GetConVar("ttt_minifier_factor"):GetFloat())
		ply:SetMaxHealth(ply:GetMaxHealth() / GetConVar("ttt_minifier_factor"):GetFloat())

		-- reset player model
		ply:SetModelScale(ply.minifierData.modelScale)
		ply:SetStepSize(ply.minifierData.stepSize)
		ply:SetViewOffset(ply.minifierData.viewOffset)
		ply:SetViewOffsetDucked(ply.minifierData.viewOffsetDucked)

		-- reset gravity
		ply:SetGravity(ply:GetGravity() / 1.75)

		-- reset player hitbox
		ply:ResetHull()

		-- start timer for charge time
		SetUpUnMinifyTimeouts(ply)
	end

	-- helperfunction to toggle between model size modes
	function ToggleMinifyPlayer(ply)
		if not IsValid(ply) then return end

		if ply.minified then
			UnMinifyPlayer(ply)
		else
			MinifyPlayer(ply)
		end
	end

	function SWEP:Initialize()
		self.BaseClass.Initialize(self)

		-- set speed multiplier to let players use the minifier instantly
		self:SetDeploySpeed(10)
	end

	function SWEP:PrimaryAttack()
		-- disable minifier when cooldown is active
		if self.Owner.minify_cooldown then return end

		-- set primary fire blocking time to prevent button spamming
		self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

		-- minify player
		ToggleMinifyPlayer(self.Owner)
	end

	-- stop minification when minifier is dropped
	function SWEP:PreDrop()
		UnMinifyPlayer(self.Owner)
	end

	-- make sure that all player models are reset in the next round
	hook.Add("TTTPrepareRound", "ttt2_minifier_speed_reset_all", function()
		local plys = player.GetAll()

		for i = 1, #plys do
			UnMinifyPlayer(plys[i])
		end
	end)
end

if CLIENT then
	function SWEP:Initialize()
		self:AddTTT2HUDHelp("ttt2_weapon_minifier_help_msb1")
	end

	-- update minified state variable on the client as well since it is used for the SpeedMod hook
	net.Receive("ttt2_minifier_update_state", function()
		local client = LocalPlayer()

		if not IsValid(client) then return end

		client.minified = net.ReadBool()
		client:EmitSound("minifing_player", 80)
	end)

	-- register status icons
	hook.Add("Initialize", "ttt2_dancegun_status_init", function()
		STATUS:RegisterStatus("ttt2_minifier_active", {
			hud = Material("vgui/ttt/hud_icon_minified.png"),
			type = "good"
		})
		STATUS:RegisterStatus("ttt2_minifier_cooldown", {
			hud = Material("vgui/ttt/hud_icon_minify_disabled.png"),
			type = "bad"
		})
	end)
end

-- change walk speed of minified players
hook.Add("TTTPlayerSpeedModifier", "ttt2_minifier_speed" , function(ply, _, _, noLag)
	if not IsValid(ply) or not ply.minified then return end

	noLag[1] = noLag[1] * GetConVar("ttt_minifier_factor"):GetFloat()
end)
