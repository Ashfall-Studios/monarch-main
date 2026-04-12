AddCSLuaFile()

SWEP.PrintName = "Door Tool"
SWEP.Author = "Monarch"
SWEP.Category = "Monarch"
SWEP.Purpose = "Name and configure doors"
SWEP.Instructions = "Primary: Set door name | Secondary: Set door group | Reload: Set price"

SWEP.Slot = 5
SWEP.SlotPos = 1
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

function SWEP:Deploy()
    return true
end

function SWEP:Holster()
    return true
end

function SWEP:PrimaryAttack()
    if CLIENT then return end

    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if not IsValid(ent) or not Monarch.Doors.IsDoor(ent) then
        ply:Notify("You must aim at a door.")
        return
    end

    net.Start("Monarch.Doors.OpenNamingUI")
    net.WriteEntity(ent)
    net.WriteString(ent:GetNWString("DoorName", ""))
    net.Send(ply)
end

function SWEP:SecondaryAttack()
    if CLIENT then return end

    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if not IsValid(ent) or not Monarch.Doors.IsDoor(ent) then
        ply:Notify("You must aim at a door.")
        return
    end

    net.Start("Monarch.Doors.OpenGroupUI")
    net.WriteEntity(ent)
    net.WriteString(ent:GetNWString(Monarch.Doors.NW.GROUP, ""))
    net.Send(ply)
end

function SWEP:Reload()
    if CLIENT then return end

    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if not IsValid(ent) or not Monarch.Doors.IsDoor(ent) then
        ply:Notify("You must aim at a door.")
        return
    end

    net.Start("Monarch.Doors.OpenPriceUI")
    net.WriteEntity(ent)
    net.WriteInt(ent:GetNWInt(Monarch.Doors.NW.PRICE, 0), 32)
    net.Send(ply)
end

if CLIENT then
    local uiBg = Color(18, 18, 18, 240)
    local uiPanel = Color(30, 30, 30, 240)
    local uiText = Color(235, 235, 235)
    local uiMuted = Color(160, 160, 160)
    local uiAccent = Color(95, 95, 95)
    local activeDoorPriceFrame = nil

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

    local function StyleTextEntry(entry)
        entry:SetTextColor(uiText)
        entry.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, uiPanel)
            self:DrawTextEntryText(uiText, uiAccent, uiText)
            surface.SetDrawColor(60, 60, 60, 220)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
    end

    local function StyleButton(btn, label, accent)
        btn:SetText("")
        btn.Paint = function(self, w, h)
            local bg = self:IsHovered() and Color(36, 36, 36, 240) or uiPanel
            draw.RoundedBox(4, 0, 0, w, h, bg)
            surface.SetDrawColor(accent or uiAccent)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(label, "DermaDefaultBold", w * 0.5, h * 0.5, uiText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    net.Receive("Monarch.Doors.OpenNamingUI", function()
        local ent = net.ReadEntity()
        local currentName = net.ReadString()

        if not IsValid(ent) then return end

        local frame = vgui.Create("DFrame")
        frame:SetSize(400, 150)
        frame:Center()
        frame:MakePopup()
        StyleFrame(frame, "Set Door Name")

        local label = vgui.Create("DLabel", frame)
        label:SetPos(20, 40)
        label:SetText("Door Name:")
        label:SetTextColor(uiText)
        label:SizeToContents()

        local entry = vgui.Create("DTextEntry", frame)
        entry:SetPos(20, 65)
        entry:SetSize(360, 25)
        entry:SetText(currentName ~= "" and currentName or "Door")
        entry:RequestFocus()
        entry:SelectAllText()
        StyleTextEntry(entry)

        local submit = vgui.Create("DButton", frame)
        submit:SetPos(20, 100)
        submit:SetSize(360, 30)
        StyleButton(submit, "Set Name", uiAccent)
        submit.DoClick = function()
            local name = string.Trim(entry:GetValue() or "")

            net.Start("Monarch.Doors.SetName")
            net.WriteEntity(ent)
            net.WriteString(name)
            net.SendToServer()

            frame:Close()
        end

        entry.OnEnter = function()
            submit:DoClick()
        end
    end)

    net.Receive("Monarch.Doors.OpenGroupUI", function()
        local ent = net.ReadEntity()
        local currentGroup = net.ReadString()

        if not IsValid(ent) then return end

        local frame = vgui.Create("DFrame")
        frame:SetSize(400, 200)
        frame:Center()
        frame:MakePopup()
        StyleFrame(frame, "Set Door Group")

        local label = vgui.Create("DLabel", frame)
        label:SetPos(20, 40)
        label:SetText("Select a Door Group:")
        label:SetTextColor(uiText)
        label:SizeToContents()

        local combo = vgui.Create("DComboBox", frame)
        combo:SetPos(20, 65)
        combo:SetSize(360, 25)
        combo:SetSortItems(false)
        combo:SetTextColor(uiText)
        combo.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, uiPanel)
            draw.SimpleText(tostring(self:GetValue() or ""), "DermaDefault", 8, h * 0.5, uiText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(60, 60, 60, 220)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        local preferred = {"Commerce", "Citizens", "PMCs", "Military"}
        local added = {}
        for _, name in ipairs(preferred) do
            if Monarch and Monarch.Doors and Monarch.Doors.Groups and Monarch.Doors.Groups[name] then
                combo:AddChoice(name)
                added[name] = true
            end
        end

        if Monarch and Monarch.Doors and Monarch.Doors.Groups then
            for name, _ in pairs(Monarch.Doors.Groups) do
                if not added[name] then
                    combo:AddChoice(name)
                end
            end
        end

        combo:AddChoice("(None)")

        if currentGroup ~= nil and currentGroup ~= "" then
            combo:SetValue(currentGroup)
        else
            combo:SetValue("(None)")
        end
        local submit = vgui.Create("DButton", frame)
        submit:SetPos(20, 130)
        submit:SetSize(360, 30)
        StyleButton(submit, "Apply Group", uiAccent)
        submit.DoClick = function()

            local sel = tostring(combo:GetValue() or "")
            local group = (sel == "(None)") and "" or sel

            net.Start("Monarch.Doors.SetGroup")
            net.WriteEntity(ent)
            net.WriteString(group)
            net.SendToServer()

            frame:Close()
        end
    end)

    net.Receive("Monarch.Doors.OpenPriceUI", function()
        local ent = net.ReadEntity()
        local currentPrice = net.ReadInt(32)

        if not IsValid(ent) then return end

        if IsValid(activeDoorPriceFrame) then
            activeDoorPriceFrame:MakePopup()
            activeDoorPriceFrame:MoveToFront()
            if IsValid(activeDoorPriceFrame._priceEntry) then
                activeDoorPriceFrame._priceEntry:SetText(tostring(currentPrice))
                activeDoorPriceFrame._priceEntry:RequestFocus()
                activeDoorPriceFrame._priceEntry:SelectAllText()
            end
            return
        end

        local frame = vgui.Create("DFrame")
        frame:SetSize(400, 180)
        frame:Center()
        frame:MakePopup()
        StyleFrame(frame, "Set Door Price")
        activeDoorPriceFrame = frame
        frame.OnRemove = function()
            if activeDoorPriceFrame == frame then
                activeDoorPriceFrame = nil
            end
        end

        local label = vgui.Create("DLabel", frame)
        label:SetPos(20, 40)
        label:SetText("Door Price (amount charged on purchase):")
        label:SetTextColor(uiText)
        label:SizeToContents()

        local entry = vgui.Create("DTextEntry", frame)
        entry:SetPos(20, 65)
        entry:SetSize(360, 25)
        entry:SetText(tostring(currentPrice))
        entry:SetNumeric(true)
        entry:RequestFocus()
        entry:SelectAllText()
        StyleTextEntry(entry)
        frame._priceEntry = entry


        local submit = vgui.Create("DButton", frame)
        submit:SetPos(20, 125)
        submit:SetSize(360, 30)
        StyleButton(submit, "Set Price", uiAccent)
        submit.DoClick = function()
            local price = math.max(tonumber(entry:GetValue()) or 0, 0)

            net.Start("Monarch.Doors.SetPrice")
            net.WriteEntity(ent)
            net.WriteInt(price, 32)
            net.SendToServer()

            frame:Close()
        end

        entry.OnEnter = function()
            submit:DoClick()
        end
    end)
end

function SWEP:DrawHUD()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTrace()
    local ent = tr.Entity

    if IsValid(ent) and Monarch.Doors.IsDoor(ent) and tr.HitPos:Distance(ply:GetShootPos()) < 100 then
        local uiText = Color(235, 235, 235)
        local uiMuted = Color(160, 160, 160)
        local uiAccent = Color(95, 95, 95)

        local doorName = ent:GetNWString("DoorName", "")
        if doorName == "" then doorName = "Door" end

        local doorGroup = ent:GetNWString(Monarch.Doors.NW.GROUP, "")
        local doorPrice = ent:GetNWInt(Monarch.Doors.NW.PRICE, 0)

        local text = "Door: " .. doorName
        if doorGroup ~= "" then
            text = text .. " [" .. doorGroup .. "]"
        end
        if doorPrice > 0 then
            text = text .. " ($" .. doorPrice .. ")"
        end

        local line2 = "Left Click to rename"
        local line3 = "Right Click to set group"
        local line4 = "Reload to set price"

        surface.SetFont("DermaDefault")
        local w1 = surface.GetTextSize(text)
        local w2 = surface.GetTextSize(line2)
        local w3 = surface.GetTextSize(line3)
        local w4 = surface.GetTextSize(line4)
        local maxW = math.max(w1, w2, w3, w4)

        local x = ScrW() / 2
        local y = ScrH() / 2 + 50

        local padX = 12
        local padY = 10
        local lineStep = 16
        local boxW = maxW + (padX * 2)
        local boxH = (padY * 2) + (lineStep * 4)
        local boxX = x - (boxW * 0.5)
        local boxY = y - padY
        draw.RoundedBox(4, boxX, boxY, boxW, boxH, Color(18, 18, 18, 220))
        surface.SetDrawColor(uiAccent)
        surface.DrawRect(boxX, boxY, boxW, 2)

        draw.SimpleText(text, "DermaDefaultBold", x, y, uiText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(line2, "DermaDefault", x, y + lineStep, uiMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(line3, "DermaDefault", x, y + (lineStep * 2), uiMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(line4, "DermaDefault", x, y + (lineStep * 3), uiMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end