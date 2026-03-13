AddCSLuaFile()

SWEP.PrintName = "Bench Tool"
SWEP.Author = "Monarch"
SWEP.Category = "Monarch"
SWEP.Purpose = "Tag props/entities as crafting benches"
SWEP.Instructions = "Primary: Configure crafting benches | Reload: Clear bench tag"

SWEP.Slot = 5
SWEP.SlotPos = 4
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

if SERVER then
    util.AddNetworkString("Monarch.BenchTool.OpenUI")
    util.AddNetworkString("Monarch.BenchTool.Apply")
end

function SWEP:Initialize()
    self:SetHoldType("normal")
end

local function buildBenchList()
    local out = {}
    for id, def in pairs((Monarch and Monarch.Crafting and Monarch.Crafting.Benches) or {}) do
        out[#out + 1] = {
            id = id,
            name = tostring((def and def.Name) or id)
        }
    end
    table.sort(out, function(a, b)
        return string.lower(a.name or a.id or "") < string.lower(b.name or b.id or "")
    end)
    return out
end

local function getMapCreationID(ent)
    if not IsValid(ent) then return -1 end
    return tonumber(ent:MapCreationID() or -1) or -1
end

function SWEP:PrimaryAttack()
    if CLIENT then return end

    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    local tr = ply:GetEyeTrace()
    local ent = tr and tr.Entity
    if not IsValid(ent) or ent:IsPlayer() then
        if ply.Notify then ply:Notify("Aim at a prop/entity.") end
        return
    end

    local mapId = getMapCreationID(ent)
    local isPersistent = mapId > 0

    local current = {}
    local rec, _, recPersistent = Monarch.GetCraftingPropBenchRecord and Monarch.GetCraftingPropBenchRecord(ent) or nil
    if rec and istable(rec.benches) then
        for id, allowed in pairs(rec.benches) do
            if allowed then current[#current + 1] = id end
        end
    end
    if recPersistent ~= nil then
        isPersistent = recPersistent == true
    end

    net.Start("Monarch.BenchTool.OpenUI")
        net.WriteEntity(ent)
        net.WriteInt(mapId, 16)
        net.WriteBool(isPersistent)
        net.WriteString(ent:GetClass() or "")
        net.WriteString(ent:GetModel() or "")
        net.WriteTable(buildBenchList())
        net.WriteTable(current)
    net.Send(ply)
end

if SERVER then
    net.Receive("Monarch.BenchTool.Apply", function(_, ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end

        local ent = net.ReadEntity()
        local selected = net.ReadTable() or {}
        local persist = net.ReadBool()

        if not IsValid(ent) or ent:IsPlayer() then return end

        local validBenches = (Monarch and Monarch.Crafting and Monarch.Crafting.Benches) or {}
        local set = {}
        for _, benchId in ipairs(selected) do
            if type(benchId) == "string" and benchId ~= "" and validBenches[benchId] then
                set[benchId] = true
            end
        end

        local ok, msg = Monarch.SetCraftingPropBenches and Monarch.SetCraftingPropBenches(ent, set, { persist = persist })
        if ply.Notify then
            ply:Notify((ok and "Bench Tool: " or "Bench Tool error: ") .. tostring(msg or "Unknown result."))
        end
    end)
end

function SWEP:Reload()
    if CLIENT then return end

    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    local tr = ply:GetEyeTrace()
    local ent = tr and tr.Entity
    if not IsValid(ent) or ent:IsPlayer() then
        if ply.Notify then ply:Notify("Aim at a prop/entity to clear bench tag.") end
        return
    end

    local ok, msg = Monarch.SetCraftingPropBenches and Monarch.SetCraftingPropBenches(ent, nil)
    if ply.Notify then
        ply:Notify((ok and "Bench Tool: " or "Bench Tool error: ") .. tostring(msg or "Unknown result."))
    end
end

if CLIENT then
    local uiBg = Color(18, 18, 18, 240)
    local uiPanel = Color(30, 30, 30, 240)
    local uiText = Color(235, 235, 235)
    local uiMuted = Color(160, 160, 160)
    local uiAccent = Color(95, 95, 95)

    local function StyleFrame(frame, title)
        frame:SetTitle("")
        frame:ShowCloseButton(false)
        frame.Paint = function(_, w, h)
            draw.RoundedBox(6, 0, 0, w, h, uiBg)
            draw.RoundedBox(6, 0, 0, w, 34, Color(24, 24, 24, 250))
            surface.SetDrawColor(uiAccent)
            surface.DrawRect(0, 33, w, 2)
            draw.SimpleText(title, "DermaDefaultBold", 12, 17, uiText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(55, 55, 55, 220)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        local closeBtn = vgui.Create("DButton", frame)
        closeBtn:SetSize(28, 24)
        closeBtn:SetPos(frame:GetWide() - 34, 5)
        closeBtn:SetText("")
        closeBtn.Paint = function(self, w, h)
            draw.SimpleText("✕", "DermaDefaultBold", w * 0.5, h * 0.5, self:IsHovered() and uiAccent or uiMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        closeBtn.DoClick = function() frame:Close() end
    end

    local function StyleButton(btn, label)
        btn:SetText("")
        btn.Paint = function(self, w, h)
            local bg = self:IsHovered() and Color(36, 36, 36, 240) or uiPanel
            if not self:IsEnabled() then
                bg = Color(24, 24, 24, 240)
            end
            draw.RoundedBox(4, 0, 0, w, h, bg)
            surface.SetDrawColor(self:IsEnabled() and uiAccent or Color(70, 70, 70))
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(label, "DermaDefaultBold", w * 0.5, h * 0.5, self:IsEnabled() and uiText or uiMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    net.Receive("Monarch.BenchTool.OpenUI", function()
        local ent = net.ReadEntity()
        local mapId = net.ReadInt(16)
        local isPersistent = net.ReadBool()
        local className = net.ReadString()
        local modelPath = net.ReadString()
        local benchList = net.ReadTable() or {}
        local selected = net.ReadTable() or {}

        if not IsValid(ent) then return end

        local selectedSet = {}
        for _, id in ipairs(selected) do
            selectedSet[id] = true
        end

        local frame = vgui.Create("DFrame")
        frame:SetSize(460, 410)
        frame:Center()
        frame:MakePopup()
        StyleFrame(frame, "Bench Tool")

        local scroll = vgui.Create("DScrollPanel", frame)
        scroll:SetPos(20, 36)
        scroll:SetSize(420, 330)

        local checks = {}
        for _, row in ipairs(benchList) do
            local pnl = scroll:Add("DPanel")
            pnl:Dock(TOP)
            pnl:SetTall(28)
            pnl:DockMargin(0, 0, 0, 4)
            pnl.Paint = function(_, w, h)
                draw.RoundedBox(3, 0, 0, w, h, uiPanel)
            end

            local chk = vgui.Create("DCheckBoxLabel", pnl)
            chk:Dock(LEFT)
            chk:SetWide(390)
            chk:SetText(tostring(row.name or row.id))
            chk:SetValue(selectedSet[row.id] and 1 or 0)
            chk:SetTextColor(uiText)
            chk:SizeToContents()
            checks[#checks + 1] = { id = row.id, ctrl = chk }
        end

        local function hasSelection()
            for _, rec in ipairs(checks) do
                if IsValid(rec.ctrl) and rec.ctrl:GetChecked() then
                    return true
                end
            end
            return false
        end

        local function collectPicked()
            local picked = {}
            for _, rec in ipairs(checks) do
                if IsValid(rec.ctrl) and rec.ctrl:GetChecked() then
                    picked[#picked + 1] = rec.id
                end
            end
            return picked
        end

        local persistBtn = vgui.Create("DButton", frame)
        persistBtn:SetPos(20, 374)
        persistBtn:SetSize(420, 26)
        StyleButton(persistBtn, "Create & Persist")
        persistBtn:SetEnabled(false)

        local function updatePersistButtonState()
            if not IsValid(persistBtn) then return end
            persistBtn:SetEnabled(hasSelection())
        end

        for _, rec in ipairs(checks) do
            if IsValid(rec.ctrl) then
                local oldOnChange = rec.ctrl.OnChange
                rec.ctrl.OnChange = function(ctrl, val)
                    if oldOnChange then
                        oldOnChange(ctrl, val)
                    end
                    updatePersistButtonState()
                end
            end
        end

        updatePersistButtonState()

        persistBtn.DoClick = function()
            if not persistBtn:IsEnabled() then return end
            local picked = collectPicked()
            net.Start("Monarch.BenchTool.Apply")
                net.WriteEntity(ent)
                net.WriteTable(picked)
                net.WriteBool(true)
            net.SendToServer()
            frame:Close()
        end

    end)

    function SWEP:DrawHUD()
        local ply = LocalPlayer()
        local tr = ply:GetEyeTrace()
        local ent = tr and tr.Entity
        if not IsValid(ent) or tr.HitPos:Distance(ply:GetShootPos()) > 120 then return end

        local mapId = tonumber(ent:MapCreationID() or -1) or -1
        local tag = ent:GetNWBool("MonarchCraftingBenchProp", false)
        local benchList = ent:GetNWString("MonarchCraftingBenchList", "")

        local text = "Bench Tool: Left=Configure  R=Clear"
        if tag then
            text = "Bench Tool: Tagged (" .. benchList .. ")"
        elseif mapId <= 0 then
            text = "Bench Tool: Runtime prop (tags are temporary)"
        end

        surface.SetFont("DermaDefaultBold")
        local textW = surface.GetTextSize(text)
        local boxW = textW + 26
        local boxH = 28
        local centerX = ScrW() * 0.5
        local centerY = (ScrH() * 0.5) + 60
        local boxX = centerX - (boxW * 0.5)
        local boxY = centerY - (boxH * 0.5)
        draw.RoundedBox(4, boxX, boxY, boxW, boxH, Color(18, 18, 18, 220))
        surface.SetDrawColor(Color(95, 95, 95))
        surface.DrawRect(boxX, boxY, boxW, 2)
        draw.SimpleText(text, "DermaDefaultBold", centerX, centerY, Color(235, 235, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end
