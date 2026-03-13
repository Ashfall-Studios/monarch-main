AddCSLuaFile()

SWEP.PrintName = "Handcuffs"
SWEP.Author = "Monarch"
SWEP.Instructions = "Left click to cuff, right click to uncuff"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.HoldType = "normal"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary = SWEP.Primary

local CUFF_USE_TIME = 3
local MAX_USE_DIST = 100
local DRAG_DIST = 70
local DRAG_PULL = 6
local DRAG_BREAK_DIST = 150
local HUD_W = 280
local HUD_H = 64

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

local function DoCuff(owner, target, cuffed)
    if not IsValid(target) or not target:IsPlayer() then return end
    target:SetNWBool("MonarchCuffed", cuffed)
    target:SetNWBool("MonarchCuffedBehind", cuffed)
    target._MonarchCuffedBy = cuffed and owner or nil

    if SERVER then
        print("[CUFF DEBUG] Setting cuff state for", target:Nick(), "to", cuffed)
        if cuffed and target.MonarchActiveChar then
            print("[CUFF DEBUG] Target charID:", target.MonarchActiveChar.id)
        end
    end

    if cuffed then
        if not target._MonarchOrigSpeeds then
            target._MonarchOrigSpeeds = {
                walk = target:GetWalkSpeed(),
                run = target:GetRunSpeed(),
            }
        end
        local walk = target._MonarchOrigSpeeds.walk or target:GetWalkSpeed()
        target:SetWalkSpeed(walk)
        target:SetRunSpeed(walk)
        target:Freeze(false)
    else
        if target._MonarchOrigSpeeds then
            if target._MonarchOrigSpeeds.walk then target:SetWalkSpeed(target._MonarchOrigSpeeds.walk) end
            if target._MonarchOrigSpeeds.run then target:SetRunSpeed(target._MonarchOrigSpeeds.run) end
        end
        target._MonarchOrigSpeeds = nil
        target._MonarchDraggedBy = nil
        target:SetNWBool("MonarchCuffedBehind", false)
        target:Freeze(false)
    end
end

local function TracePlayer(owner)
    if not IsValid(owner) then return end
    local tr = owner:GetEyeTrace()
    if not IsValid(tr.Entity) or not tr.Entity:IsPlayer() then return end
    if tr.HitPos:DistToSqr(owner:EyePos()) > (MAX_USE_DIST * MAX_USE_DIST) then return end
    return tr.Entity
end

local function ValidDragState(wep)
    if not IsValid(wep) or not IsValid(wep.Owner) then return false end
    if wep.Owner:GetActiveWeapon() ~= wep then return false end
    return true
end

local function CancelCuffProgress(wep)
    if not IsValid(wep) then return end
    if wep._cuffTimerName then
        timer.Remove(wep._cuffTimerName)
    end
    if IsValid(wep._cuffOverlay) then
        wep._cuffOverlay:Remove()
    end
    wep._cuffOverlay = nil
    wep._cuffEndTime = nil
    wep._cuffTarget = nil
    wep._cuffTimerName = nil
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + CUFF_USE_TIME)
    if not IsValid(self.Owner) then return end
    local target = TracePlayer(self.Owner)
    if not IsValid(target) then return end

    if target:GetNWBool("MonarchCuffed") then
        if self._dragTarget == target then
            target._MonarchDraggedBy = nil
            self._dragTarget = nil
        else
            self._dragTarget = target
            target._MonarchDraggedBy = self.Owner
        end
        self.Owner:EmitSound("npc/combine_soldier/zipline_clip1.wav")
        return
    end

    CancelCuffProgress(self)
    self._cuffTarget = target
    local owner = self.Owner
    if Monarch_ShowUseBar then
        self._cuffOverlay = Monarch_ShowUseBar(vgui.GetWorldPanel(), CUFF_USE_TIME, "Handcuffing...", function()
            if not IsValid(self) or not IsValid(owner) or not IsValid(target) then return end
            local stillTarget = TracePlayer(owner)
            if stillTarget ~= target then return end
            if owner:GetPos():DistToSqr(target:GetPos()) > (MAX_USE_DIST * MAX_USE_DIST) then return end
            if not owner:KeyDown(IN_ATTACK) then return end
            DoCuff(owner, target, true)
            owner:EmitSound("npc/combine_soldier/zipline_clip1.wav")
            CancelCuffProgress(self)
        end, true)
    else
        self._cuffTimerName = "monarch_cuff_start_" .. self:EntIndex()
        timer.Create(self._cuffTimerName, CUFF_USE_TIME, 1, function()
            if not IsValid(self) or not IsValid(owner) or not IsValid(target) then return end
            local stillTarget = TracePlayer(owner)
            if stillTarget ~= target then return end
            if owner:GetPos():DistToSqr(target:GetPos()) > (MAX_USE_DIST * MAX_USE_DIST) then return end
            if not owner:KeyDown(IN_ATTACK) then return end
            DoCuff(owner, target, true)
            owner:EmitSound("npc/combine_soldier/zipline_clip1.wav")
            CancelCuffProgress(self)
        end)
    end
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 1)
    if not IsValid(self.Owner) then return end
    local target = TracePlayer(self.Owner)
    if not IsValid(target) then return end
    DoCuff(self.Owner, target, false)
    self.Owner:EmitSound("npc/combine_soldier/zipline_clip1.wav")
end

function SWEP:Think()
    if IsValid(self._dragTarget) then
        local tgt = self._dragTarget
        local owner = self.Owner
        if not tgt:GetNWBool("MonarchCuffed") or not ValidDragState(self) then
            tgt._MonarchDraggedBy = nil
            self._dragTarget = nil
        else
            local distSqr = owner:GetPos():DistToSqr(tgt:GetPos())
            if distSqr > (DRAG_BREAK_DIST * DRAG_BREAK_DIST) then
                tgt._MonarchDraggedBy = nil
                self._dragTarget = nil
                return
            end
            local dist = math.sqrt(distSqr)
            if dist > DRAG_DIST then
                local dir = (owner:GetPos() - tgt:GetPos())
                dir.z = 0
                dir:Normalize()
                local pull = dir * math.min((dist - DRAG_DIST) * DRAG_PULL, 300)
                tgt:SetVelocity(pull)
            end
        end
    end

    if self._cuffTarget then
        local owner = self.Owner
        local tgt = self._cuffTarget
        if (not IsValid(owner)) or (not IsValid(tgt)) or owner:GetPos():DistToSqr(tgt:GetPos()) > (MAX_USE_DIST * MAX_USE_DIST) or TracePlayer(owner) ~= tgt or not owner:KeyDown(IN_ATTACK) then
            CancelCuffProgress(self)
        end
    end
end

function SWEP:Holster()
    if IsValid(self._dragTarget) then
        self._dragTarget._MonarchDraggedBy = nil
        self._dragTarget = nil
    end
    CancelCuffProgress(self)
    return true
end

function SWEP:OnRemove()
    if not IsValid(self.Owner) then return end
    if self._dragTarget then
        self._dragTarget._MonarchDraggedBy = nil
        self._dragTarget = nil
    end
    CancelCuffProgress(self)
end

if CLIENT then
    local HUD_COLOR = Color(255, 255, 255)
    local HUD_ACCENT = Color(255, 120, 60)
    function SWEP:DrawHUD()
        local ply = LocalPlayer()
        if not IsValid(ply) or ply:GetActiveWeapon() ~= self then return end
        local tr = ply:GetEyeTrace()
        local lookingTarget = IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.HitPos:DistToSqr(ply:EyePos()) <= (MAX_USE_DIST * MAX_USE_DIST) and tr.Entity or nil
        local cx, cy = ScrW() * 0.5, ScrH() * 0.78

        if lookingTarget then
            local dragging = (self._dragTarget == lookingTarget)
            local isCuffed = lookingTarget:GetNWBool("MonarchCuffed")
            local lines = {}
            if not isCuffed then
                table.insert(lines, "Press and hold LMB to handcuff someone.")
            elseif dragging then
                table.insert(lines, "Press LMB to stop dragging.")
            else
                table.insert(lines, "Press RMB to release or press LMB to start dragging.")
            end

            local shadowCol = Color(0, 0, 0, 160)
            local startY = cy - 6
            surface.SetFont("DispLgr")
            for i = 1, #lines do
                local text = lines[i]
                if text and text ~= "" then
                    local y = startY + (i - 1) * 22
                    draw.SimpleText(text, "DispMedBlur", cx, y, shadowCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(text, "DispLgr", cx, y, HUD_COLOR, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
        end
    end
end

hook.Add("CalcMainActivity", "MonarchCuffedPose", function(ply, vel)
    if not ply:GetNWBool("MonarchCuffedBehind") then return end
    local speed2 = vel:Length2DSqr()
    if speed2 < 4 then
        return ACT_HL2MP_IDLE_PASSIVE, -1
    else
        return ACT_HL2MP_WALK_PASSIVE, -1
    end
end)

if CLIENT then
    local BONE_POSE = {
        { name = "ValveBiped.Bip01_L_UpperArm", ang = Angle(0, 0, 0) },
        { name = "ValveBiped.Bip01_L_Forearm",  ang = Angle(80, 70, 0) },
        { name = "ValveBiped.Bip01_R_UpperArm", ang = Angle(0, 0, 0) },
        { name = "ValveBiped.Bip01_R_Forearm",  ang = Angle(-80, 70, 0) },
    }

    local boneCache = setmetatable({}, { __mode = "k" })
    local function GetBoneCache(ply)
        local cache = boneCache[ply]
        if cache then return cache end
        cache = {}
        for _, data in ipairs(BONE_POSE) do
            local idx = ply:LookupBone(data.name)
            if idx and idx >= 0 then
                table.insert(cache, { idx = idx, ang = data.ang })
            end
        end
        boneCache[ply] = cache
        return cache
    end

    local function ApplyPose(ply)
        local cache = GetBoneCache(ply)
        for i = 1, #cache do
            ply:ManipulateBoneAngles(cache[i].idx, cache[i].ang)
        end
    end

    local function ClearPose(ply)
        local cache = GetBoneCache(ply)
        for i = 1, #cache do
            ply:ManipulateBoneAngles(cache[i].idx, Angle(0, 0, 0))
        end
    end

    hook.Add("Think", "MonarchCuffedBonePose", function()
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetNWBool("MonarchCuffedBehind") then
                ApplyPose(ply)
            else
                ClearPose(ply)
            end
        end
    end)
end

hook.Add("PlayerDeath", "MonarchCuffRemoveOnDeath", function(victim, inflictor, attacker)
    if IsValid(victim) and victim:GetNWBool("MonarchCuffed") then
        DoCuff(nil, victim, false)
    end
end)
