AddCSLuaFile()

SWEP.PrintName = "Persistence Tool"
SWEP.Author = "Monarch"
SWEP.Category = "Monarch"
SWEP.Purpose = "Mark/unmark props/entities for persistence"
SWEP.Instructions = "Primary: Mark entity | Secondary: Toggle persist on aimed entity | Reload: Save props"

SWEP.Slot = 5
SWEP.SlotPos = 2
SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

function SWEP:Initialize()
    self:SetHoldType("normal")
end

local function captureBodygroups(ent)
    local out = {}
    local n = ent:GetNumBodyGroups() or 0
    for i = 0, n - 1 do
        out[i] = ent:GetBodygroup(i)
    end
    return out
end

local function makeRecord(ent)
    if not IsValid(ent) then return nil end
    if ent:IsPlayer() then return nil end
    local pos = ent:GetPos()
    local ang = ent:GetAngles()
    local col = ent:GetColor() or Color(255,255,255)
    local rec = {
        uid = ent._persistUID or string.format("prop_%d_%d", os.time(), ent:EntIndex()),
        class = ent:GetClass() or "",
        pos = { x = pos.x, y = pos.y, z = pos.z },
        ang = { p = ang.p, y = ang.y, r = ang.r },
        model = ent:GetModel() or "",
        skin = ent:GetSkin() or 0,
        color = { r = col.r, g = col.g, b = col.b, a = col.a },
        material = ent:GetMaterial() or "",
        bodygroups = captureBodygroups(ent),
        collisiongroup = ent:GetCollisionGroup() or COLLISION_GROUP_NONE,
        frozen = false
    }
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then rec.frozen = phys:IsMotionEnabled() == false end
    return rec
end

if SERVER then
    Monarch = Monarch or {}
    Monarch._persistMarkedProps = Monarch._persistMarkedProps or {}
end

function SWEP:PrimaryAttack()
    if CLIENT then return end
    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    local tr = ply:GetEyeTrace()
    local ent = tr and tr.Entity
    if not IsValid(ent) then ply:Notify("No entity targeted.") return end
    if ent:IsPlayer() then ply:Notify("Cannot mark players.") return end

    Monarch._persistMarkedProps = Monarch._persistMarkedProps or {}
    local rec = makeRecord(ent)
    if not rec then return end

    table.insert(Monarch._persistMarkedProps, rec)

    if IsValid(ent) then 
        ent:SetNWBool("MonarchPersistMarked", true)
        ent._persistUID = rec.uid
    end
    ply:Notify("Marked entity for persistence (" .. (rec.class or "") .. ")")
end

function SWEP:SecondaryAttack()
    if CLIENT then return end
    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    Monarch._persistMarkedProps = Monarch._persistMarkedProps or {}

    local tr = ply:GetEyeTrace()
    local ent = tr and tr.Entity
    if not IsValid(ent) or ent:IsPlayer() then
        ply:Notify("Aim at a non-player entity to toggle persistence.")
        return
    end

    local idxToRemove = nil
    local pos = ent:GetPos()
    local class = ent:GetClass()
    local model = ent:GetModel()
    local threshold = (12 * 12) 
    for i, rec in ipairs(Monarch._persistMarkedProps) do
        if rec and rec.pos and rec.class then
            if rec.class == class and (not model or rec.model == model) then

                local recPos = Vector(rec.pos.x or 0, rec.pos.y or 0, rec.pos.z or 0)
                local d = recPos:DistToSqr(pos)
                if d <= threshold then
                    idxToRemove = i
                    break
                end
            end
        end
    end

    if idxToRemove then
        table.remove(Monarch._persistMarkedProps, idxToRemove)
        if IsValid(ent) then ent:SetNWBool("MonarchPersistMarked", false) end
        ply:Notify("Unmarked this entity from persistence.")
        return
    end

    local rec = makeRecord(ent)
    if not rec then return end
    table.insert(Monarch._persistMarkedProps, rec)
    if IsValid(ent) then 
        ent:SetNWBool("MonarchPersistMarked", true)
        ent._persistUID = rec.uid
    end
    ply:Notify("Marked this entity for persistence (toggle).")
end

function SWEP:Reload()
    if CLIENT then return end
    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    ply:ConCommand("monarch_persist_save props")
    if ply.Notify then ply:Notify("Persisted props saved to disk.") end
end

function SWEP:DrawHUD()
    local ply = LocalPlayer()
    local tr = ply:GetEyeTrace()
    local ent = tr.Entity
    if IsValid(ent) and not ent:IsPlayer() and tr.HitPos:Distance(ply:GetShootPos()) < 120 then
        local text = "Persistence: Left=Mark  Right=Toggle  R=Save"
        draw.SimpleText(text, "DermaDefault", ScrW()/2, ScrH()/2 + 60, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        if ent:GetNWBool("MonarchPersistMarked", false) then

            local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
            local top = Vector(0, 0, maxs.z + 4)
            local pos = ent:LocalToWorld(top)
            local ang = Angle(0, ply:EyeAngles().y - 90, 90)
            cam.Start3D2D(pos, ang, 0.1)
                draw.RoundedBox(4, -40, -28, 80, 20, Color(0, 120, 255, 160))
                draw.SimpleText("Persisted", "DermaDefaultBold", 0, -18, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end
end
