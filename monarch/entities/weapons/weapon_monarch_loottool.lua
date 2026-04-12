AddCSLuaFile()

SWEP.PrintName = "Loot Tool"
SWEP.Author = "Monarch"
SWEP.Category = "Monarch"
SWEP.Purpose = "Configure and persist loot crates"
SWEP.Instructions = "Primary: Configure loot | Reload: Unsave (remove) loot"

SWEP.Slot = 5
SWEP.SlotPos = 3
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
    util.AddNetworkString("Monarch.LootTool.OpenUI")
    util.AddNetworkString("Monarch.LootTool.Apply")
end

function SWEP:Initialize()
    self:SetHoldType("normal")
end

local function buildDefList()
    local list = {}
    if Monarch and Monarch.Loot and Monarch.Loot.Defs then
        for id,_ in pairs(Monarch.Loot.Defs) do table.insert(list, id) end
    end
    table.sort(list)
    return list
end

function SWEP:PrimaryAttack()
    if CLIENT then return end
    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    local tr = ply:GetEyeTrace()
    local ent = tr and tr.Entity
    if not IsValid(ent) then ply:Notify("Aim at a prop or loot entity.") return end

    local target = ent
    local isLoot = ent:GetClass() == "monarch_loot"

    net.Start("Monarch.LootTool.OpenUI")
        net.WriteEntity(ent)
        net.WriteBool(isLoot)
        net.WriteString(isLoot and (ent.GetLootDefID and ent:GetLootDefID() or "") or "")
        net.WriteString(isLoot and (ent.GetLootName and ent:GetLootName() or "") or "")
        net.WriteString(isLoot and (ent.GetCustomOpenSound and ent:GetCustomOpenSound() or "") or "")
        net.WriteString(ent:GetModel() or "")
        net.WriteUInt(isLoot and (ent.GetCapacityX and ent:GetCapacityX() or 5) or 5, 8)
        net.WriteUInt(isLoot and (ent.GetCapacityY and ent:GetCapacityY() or 2) or 2, 8)
        net.WriteBool(isLoot and (ent.GetStoreable and ent:GetStoreable() or true) or true)
        net.WriteUInt(isLoot and math.floor(((ent.GetRefillTime and ent:GetRefillTime()) or 300) / 60) or 5, 6) 
        net.WriteTable(buildDefList())
    net.Send(ply)
end

if SERVER then
    net.Receive("Monarch.LootTool.Apply", function(len, ply)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        local ent = net.ReadEntity()
        local name = string.Trim(net.ReadString() or "")
        local defid = string.Trim(net.ReadString() or "")
        local openSound = string.Trim(net.ReadString() or "")
        local capX = net.ReadUInt(8)
        local capY = net.ReadUInt(8)
        local storeable = net.ReadBool()
        local doSave = net.ReadBool()

        if not IsValid(ent) then return end

        local function freezeLootPhysics(lootEnt)
            if not IsValid(lootEnt) then return end
            local phys = lootEnt:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(false)
                phys:Sleep()
            end
        end

        local function ensureLoot(fromEnt)
            if IsValid(fromEnt) and fromEnt:GetClass() == "monarch_loot" then
                freezeLootPhysics(fromEnt)
                return fromEnt
            end

            local mdl = fromEnt:GetModel()
            local pos, ang = fromEnt:GetPos(), fromEnt:GetAngles()
            local loot = ents.Create("monarch_loot")
            if not IsValid(loot) then return nil end
            loot:SetPos(pos)
            loot:SetAngles(ang)
            loot:Spawn()
            freezeLootPhysics(loot)
            if loot.SetCustomModel and mdl and mdl ~= "" then loot:SetCustomModel(mdl) end
            if IsValid(fromEnt) and (fromEnt:GetClass():find("prop_") or fromEnt:GetClass():find("prop")) then
                fromEnt:Remove()
            end
            return loot
        end

        local loot = ensureLoot(ent)
        if not IsValid(loot) then return end

        if loot.SetLootDef then loot:SetLootDef(defid) end
        if loot.SetLootName and name ~= "" then loot:SetLootName(name) end
        if loot.SetCustomOpenSound then loot:SetCustomOpenSound(openSound) end
        if loot.SetCapacityX then loot:SetCapacityX(capX) end
        if loot.SetCapacityY then loot:SetCapacityY(capY) end
        if loot.SetStoreable then loot:SetStoreable(storeable) end
        if loot.SetPersistentID then
            local uid = loot:GetPersistentID()
            if not uid or uid == "" then loot:SetPersistentID("loot_" .. os.time() .. "_" .. loot:EntIndex()) end
        end

        ply:Notify("Loot configured: " .. (name ~= "" and name or defid))

        if doSave then

            ply:ConCommand("monarch_persist_save loot")
        end
    end)
end

function SWEP:Reload()
    if CLIENT then return end
    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    local tr = ply:GetEyeTrace()
    local ent = tr and tr.Entity
    if not IsValid(ent) or ent:GetClass() ~= "monarch_loot" then
        ply:Notify("Aim at a loot entity to unsave (remove).")
        return
    end

    local uid = ent.GetPersistentID and ent:GetPersistentID() or ""
    if uid ~= "" and Monarch and Monarch._lootPersist and Monarch._lootPersist[uid] then
        Monarch._lootPersist[uid] = nil
        local map = game.GetMap()
        local out = {}
        for _, data in pairs(Monarch._lootPersist) do
            table.insert(out, data)
        end
        file.CreateDir("monarch")
        file.Write("monarch/loot_" .. map .. ".json", util.TableToJSON(out, false))
    end

    ent:Remove()
    ply:ConCommand("monarch_persist_save loot")
    ply:Notify("Loot box removed.")
end

if CLIENT then
    local uiBg = Color(18, 18, 18, 240)
    local uiPanel = Color(30, 30, 30, 240)
    local uiText = Color(235, 235, 235)
    local uiMuted = Color(160, 160, 160)
    local uiAccent = Color(95, 95, 95)

    local function StyleToolFrame(frame, title)
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
            local c = self:IsHovered() and uiAccent or uiMuted
            draw.SimpleText("✕", "DermaDefaultBold", w * 0.5, h * 0.5, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        closeBtn.DoClick = function() frame:Close() end
    end

    local function StyleTextEntry(entry)
        entry:SetFont("DermaDefault")
        entry:SetTextColor(uiText)
        entry.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, uiPanel)
            self:DrawTextEntryText(uiText, uiAccent, uiText)
            surface.SetDrawColor(60, 60, 60, 220)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
    end

    local function StyleButton(btn, accent)
        btn:SetText("")
        btn.Paint = function(self, w, h)
            local hovered = self:IsHovered()
            local bg = hovered and Color(36, 36, 36, 240) or uiPanel
            local col = accent or uiAccent
            draw.RoundedBox(4, 0, 0, w, h, bg)
            surface.SetDrawColor(col)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(btn._label or "Button", "DermaDefaultBold", w * 0.5, h * 0.5, hovered and color_white or uiText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    net.Receive("Monarch.LootTool.OpenUI", function()
        local ent = net.ReadEntity()
        local isLoot = net.ReadBool()
        local currentDef = net.ReadString()
        local currentName = net.ReadString()
        local currentOpenSound = net.ReadString()
        local model = net.ReadString()
        local currentCapX = net.ReadUInt(8)
        local currentCapY = net.ReadUInt(8)
        local currentStoreable = net.ReadBool()
        local currentMinutes = net.ReadUInt(6)
        local defList = net.ReadTable() or {}

        if not IsValid(ent) then return end

        local frame = vgui.Create("DFrame")
        frame:SetSize(420, 420)
        frame:Center()
        frame:MakePopup()
        StyleToolFrame(frame, "Configure Loot")

        local nameLbl = vgui.Create("DLabel", frame)
        nameLbl:SetPos(20, 40)
        nameLbl:SetText("Name:")
        nameLbl:SetTextColor(uiText)
        nameLbl:SizeToContents()

        local nameEntry = vgui.Create("DTextEntry", frame)
        nameEntry:SetPos(80, 38)
        nameEntry:SetSize(300, 22)
        nameEntry:SetText(currentName ~= "" and currentName or "")
        StyleTextEntry(nameEntry)

        local typeLbl = vgui.Create("DLabel", frame)
        typeLbl:SetPos(20, 75)
        typeLbl:SetText("Loot Type:")
        typeLbl:SetTextColor(uiText)
        typeLbl:SizeToContents()

        local combo = vgui.Create("DComboBox", frame)
        combo:SetPos(80, 72)
        combo:SetSize(300, 24)
        combo:SetSortItems(true)
        combo:SetTextColor(uiText)
        combo.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, uiPanel)
            draw.SimpleText(tostring(self:GetValue() or ""), "DermaDefault", 8, h * 0.5, uiText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(60, 60, 60, 220)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        for _, id in ipairs(defList) do combo:AddChoice(id) end
        if currentDef ~= "" then
            combo:SetValue(currentDef)
        elseif #defList > 0 then
            combo:SetValue(defList[1])
        end

        local soundLbl = vgui.Create("DLabel", frame)
        soundLbl:SetPos(20, 110)
        soundLbl:SetText("Open Sound:")
        soundLbl:SetTextColor(uiText)
        soundLbl:SizeToContents()

        local soundEntry = vgui.Create("DTextEntry", frame)
        soundEntry:SetPos(95, 108)
        soundEntry:SetSize(285, 22)
        soundEntry:SetText(currentOpenSound ~= "" and currentOpenSound or "")
        soundEntry:SetPlaceholderText("Leave empty to use default")
        StyleTextEntry(soundEntry)

        local capXLbl = vgui.Create("DLabel", frame)
        capXLbl:SetPos(20, 145)
        capXLbl:SetText("Columns:")
        capXLbl:SetTextColor(uiText)
        capXLbl:SizeToContents()

        local capXEntry = vgui.Create("DNumberWang", frame)
        capXEntry:SetPos(95, 143)
        capXEntry:SetSize(60, 22)
        capXEntry:SetMin(1)
        capXEntry:SetMax(20)
        capXEntry:SetValue(currentCapX)
        StyleTextEntry(capXEntry)

        local capYLbl = vgui.Create("DLabel", frame)
        capYLbl:SetPos(180, 145)
        capYLbl:SetText("Rows:")
        capYLbl:SetTextColor(uiText)
        capYLbl:SizeToContents()

        local capYEntry = vgui.Create("DNumberWang", frame)
        capYEntry:SetPos(220, 143)
        capYEntry:SetSize(60, 22)
        capYEntry:SetMin(1)
        capYEntry:SetMax(20)
        capYEntry:SetValue(currentCapY)
        StyleTextEntry(capYEntry)

        local storeableCheck = vgui.Create("DCheckBoxLabel", frame)
        storeableCheck:SetPos(20, 180)
        storeableCheck:SetText("Allow Storing Items")
        storeableCheck:SetValue(currentStoreable)
        storeableCheck:SetTextColor(uiText)
        storeableCheck:SizeToContents()

        local refillLbl = vgui.Create("DLabel", frame)
        refillLbl:SetPos(20, 210)
        refillLbl:SetText("Restock Time (minutes):")
        refillLbl:SetTextColor(uiText)
        refillLbl:SizeToContents()

        local refillSlider = vgui.Create("DNumSlider", frame)
        refillSlider:SetPos(20, 230)
        refillSlider:SetSize(380, 28)
        refillSlider:SetMin(5)
        refillSlider:SetMax(30)
        refillSlider:SetDecimals(0)
        refillSlider:SetValue(math.Clamp(currentMinutes or 5, 5, 30))
        if IsValid(refillSlider.Label) then
            refillSlider.Label:SetTextColor(uiText)
        end
        if IsValid(refillSlider.TextArea) then
            refillSlider.TextArea:SetTextColor(uiText)
        end
        refillSlider.OnValueChanged = function(_, val)
            local mins = math.floor(val or currentMinutes or 5)
            mins = math.Clamp(mins, 5, 30)
            net.Start("Monarch_Loot_SetRefillTime")
                net.WriteEntity(ent)
                net.WriteUInt(mins, 6)
            net.SendToServer()
        end

        local saveBtn = vgui.Create("DButton", frame)
        saveBtn:SetPos(20, 270)
        saveBtn:SetSize(360, 28)
        saveBtn._label = "Save"
        StyleButton(saveBtn, uiAccent)
        saveBtn.DoClick = function()
            local sel = tostring(combo:GetValue() or "")
            if sel == "" then
                Derma_Message("Please select a loot type.", "Loot Tool", "OK")
                return
            end
            net.Start("Monarch.LootTool.Apply")
                net.WriteEntity(ent)
                net.WriteString(string.Trim(nameEntry:GetValue() or ""))
                net.WriteString(sel)
                net.WriteString(string.Trim(soundEntry:GetValue() or ""))
                net.WriteUInt(math.Clamp(capXEntry:GetValue(), 1, 20), 8)
                net.WriteUInt(math.Clamp(capYEntry:GetValue(), 1, 20), 8)
                net.WriteBool(storeableCheck:GetChecked())
                net.WriteBool(true) 
            net.SendToServer()
            frame:Close()
        end

        local info = vgui.Create("DLabel", frame)
        info:SetPos(20, 310)
        info:SetText("Reload (R) while aiming at loot to unsave (remove).")
        info:SetTextColor(uiText)
        info:SizeToContents()
    end)

    function SWEP:DrawHUD()
        local ply = LocalPlayer()
        local tr = ply:GetEyeTrace()
        local ent = tr.Entity
        if IsValid(ent) and tr.HitPos:Distance(ply:GetShootPos()) < 120 then
            local isLoot = ent:GetClass() == "monarch_loot"
            local text = isLoot and "Loot: Left = Configure, R = Unsave" or "Prop: Left = Make Loot"
            local boxW = 200
            local boxH = 28
            local boxX = (ScrW() * 0.5) - (boxW * 0.5)
            local boxY = (ScrH() * 0.5) + 46
            draw.RoundedBox(4, boxX, boxY, boxW, boxH, Color(18, 18, 18, 220))
            surface.SetDrawColor(uiAccent)
            surface.DrawRect(boxX, boxY, boxW, 2)
            draw.SimpleText(text, "DermaDefaultBold", ScrW() * 0.5, boxY + (boxH * 0.5), uiText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end
