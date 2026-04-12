AddCSLuaFile()

if SERVER then
    util.AddNetworkString("Monarch_ZoneTool_Create")
end

SWEP.PrintName = "Zone Tool"
SWEP.Author = "Monarch"
SWEP.Category = "Monarch"
SWEP.Purpose = "Create and edit zones"
SWEP.Instructions = "Primary: Add corner | Secondary: Cancel | Reload: Clear corners"

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

local zoneColorCache = {}
local function getZoneRenderColor(zoneId)
    zoneId = tostring(zoneId or "")
    local cached = zoneColorCache[zoneId]
    if cached then return cached end

    local hash = 0
    for i = 1, #zoneId do
        hash = (hash * 33 + string.byte(zoneId, i)) % 360
    end

    local col = HSVToColor(hash, 0.75, 1)
    col.a = 220
    zoneColorCache[zoneId] = col
    return col
end

if CLIENT then
    language.Add("Tool_zone_tool_name", "Zone Tool")
    language.Add("Tool_zone_tool_desc", "Create and edit zones")
    language.Add("Tool_zone_tool_0", "Click to add a corner or finish zone")
    language.Add("Tool_zone_tool_1", "Reload to clear")

    surface.CreateFont("ZoneTool_Preview", {
        font = "Arial",
        size = 16,
        weight = 700,
        antialias = true,
    })
end

local Zones = Monarch.Zones

function SWEP:PrimaryAttack()
    if not IsValid(self:GetOwner()) or not self:GetOwner():IsAdmin() then
        if IsValid(self:GetOwner()) then
            self:GetOwner():Notify("Admin only!")
        end
        return
    end

    if CLIENT then return end

    local trace = self:GetOwner():GetEyeTrace()
    if not trace.Hit then return end

    self.zoneCorners = self.zoneCorners or {}
    table.insert(self.zoneCorners, trace.HitPos)

    self:GetOwner():Notify("Corner " .. #self.zoneCorners .. " set at " .. tostring(trace.HitPos))

    if #self.zoneCorners == 2 then

        net.Start("Monarch_ZoneTool_Create")
            net.WriteBool(true) 
            net.WriteVector(self.zoneCorners[1])
            net.WriteVector(self.zoneCorners[2])
        net.Send(self:GetOwner())

        self:GetOwner():Notify("Opening zone creation dialog...")
    end

end

function SWEP:SecondaryAttack()
    if not IsValid(self:GetOwner()) or not self:GetOwner():IsAdmin() then
        return
    end

    if CLIENT then return end

    self.zoneCorners = {}
    self:GetOwner():Notify("Zone creation cancelled.")
end

function SWEP:Reload()
    if not IsValid(self:GetOwner()) or not self:GetOwner():IsAdmin() then
        return
    end

    self.zoneCorners = {}

    if SERVER then
        self:GetOwner():Notify("Zone corners cleared.")
    end
end

function SWEP:CreateZone(zoneName, zoneDesc, isIllegal, pos1, pos2)
    if CLIENT then return end

    local ply = self:GetOwner()
    if not IsValid(ply) or not ply:IsAdmin() then return end

    if not pos1 or not pos2 then return end

    local minPos = Vector(math.min(pos1.x, pos2.x), math.min(pos1.y, pos2.y), math.min(pos1.z, pos2.z))
    local maxPos = Vector(math.max(pos1.x, pos2.x), math.max(pos1.y, pos2.y), math.max(pos1.z, pos2.z))

    local center = (minPos + maxPos) * 0.5
    local size = maxPos - minPos

    local mapName = game.GetMap()
    local maxNum = 0
    for existingId, _ in pairs(Zones.Registry) do
        local num = tonumber(string.match(tostring(existingId), "_zone_(%d+)$"))
        if num and num > maxNum then
            maxNum = num
        end
    end
    local zoneId = mapName .. "_zone_" .. (maxNum + 1)

    Zones.Register(zoneId, {
        name = zoneName or ("Zone " .. (zoneCount + 1)),
        description = zoneDesc or "",
        pos = center,
        size = size,
        illegal = isIllegal or false,
    })

    Zones.Save()

    for _, p in player.Iterator() do
        Zones.SyncToClient(p)
    end

    local statusText = isIllegal and "[ILLEGAL]" or "[LEGAL]"
    ply:ChatPrint("Zone created: " .. statusText .. " " .. zoneName .. " (" .. zoneId .. ")")

    self.zoneCorners = {}
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

    net.Receive("Monarch_ZoneTool_Create", function()
        local shouldOpenDialog = net.ReadBool()
        if not shouldOpenDialog then return end

        local pos1 = net.ReadVector()
        local pos2 = net.ReadVector()

        local frame = vgui.Create("DFrame")
        frame:SetSize(400, 270)
        frame:Center()
        frame:SetVisible(true)
        frame:SetDraggable(true)
        frame:MakePopup()
        StyleFrame(frame, "Create Zone")

        local nameLabel = vgui.Create("DLabel", frame)
        nameLabel:SetPos(20, 40)
        nameLabel:SetSize(100, 20)
        nameLabel:SetText("Zone Name:")
        nameLabel:SetTextColor(uiText)

        local nameEntry = vgui.Create("DTextEntry", frame)
        nameEntry:SetPos(120, 40)
        nameEntry:SetSize(260, 25)
        nameEntry:SetPlaceholderText("Enter zone name...")
        nameEntry:RequestFocus()
        StyleTextEntry(nameEntry)

        local descLabel = vgui.Create("DLabel", frame)
        descLabel:SetPos(20, 80)
        descLabel:SetSize(100, 20)
        descLabel:SetText("Description:")
        descLabel:SetTextColor(uiText)

        local descEntry = vgui.Create("DTextEntry", frame)
        descEntry:SetPos(120, 80)
        descEntry:SetSize(260, 25)
        descEntry:SetPlaceholderText("Enter zone description (optional)...")
        StyleTextEntry(descEntry)

        local statusLabel = vgui.Create("DLabel", frame)
        statusLabel:SetPos(20, 120)
        statusLabel:SetSize(100, 20)
        statusLabel:SetText("Zone Status:")
        statusLabel:SetTextColor(uiText)

        local illegalCheckbox = vgui.Create("DCheckBoxLabel", frame)
        illegalCheckbox:SetPos(120, 120)
        illegalCheckbox:SetText("Mark as ILLEGAL (Red)")
        illegalCheckbox:SetValue(false)
        illegalCheckbox:SetTextColor(uiMuted)
        illegalCheckbox:SizeToContents()

        local createBtn = vgui.Create("DButton", frame)
        createBtn:SetPos(120, 170)
        createBtn:SetSize(150, 30)
        StyleButton(createBtn, "Create Zone", uiAccent)
        createBtn.DoClick = function()
            local zoneName = nameEntry:GetValue()
            if zoneName == "" then
                zoneName = "Unnamed Zone"
            end

            local zoneDesc = descEntry:GetValue()
            local isIllegal = illegalCheckbox:GetChecked()

            net.Start("Monarch_ZoneTool_Create")
                net.WriteBool(false) 
                net.WriteString(zoneName)
                net.WriteString(zoneDesc)
                net.WriteBool(isIllegal)
                net.WriteVector(pos1)
                net.WriteVector(pos2)
            net.SendToServer()

            frame:Close()

            if IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon().zoneCorners then
                LocalPlayer():GetActiveWeapon().zoneCorners = {}
            end
        end

        local cancelBtn = vgui.Create("DButton", frame)
        cancelBtn:SetPos(280, 170)
        cancelBtn:SetSize(100, 30)
        StyleButton(cancelBtn, "Cancel", Color(110, 110, 110))
        cancelBtn.DoClick = function()
            frame:Close()

            if IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon().zoneCorners then
                LocalPlayer():GetActiveWeapon().zoneCorners = {}
            end
        end
    end)

    function SWEP:DrawHUD()
        local x, y = 10, 10
        surface.SetFont("ZoneTool_Preview")

        self.zoneCorners = self.zoneCorners or {}
        local hintHeader = "Zone Tool"
        local hintLines = {
            "Corners: " .. #self.zoneCorners .. "/2",
            (#self.zoneCorners > 0) and ("Corner 1: " .. string.format("(%.0f, %.0f, %.0f)", self.zoneCorners[1].x, self.zoneCorners[1].y, self.zoneCorners[1].z)) or nil,
            (#self.zoneCorners > 1) and ("Corner 2: " .. string.format("(%.0f, %.0f, %.0f)", self.zoneCorners[2].x, self.zoneCorners[2].y, self.zoneCorners[2].z)) or nil,
            "Left Click: Add corner | Right Click: Cancel | Reload: Clear"
        }

        local maxTextW = surface.GetTextSize(hintHeader)
        for _, line in ipairs(hintLines) do
            if line and line ~= "" then
                local w = surface.GetTextSize(line)
                if w > maxTextW then
                    maxTextW = w
                end
            end
        end

        local padX, padY = 12, 10
        local lineStep = 18
        local lineCount = 0
        for _, line in ipairs(hintLines) do
            if line and line ~= "" then lineCount = lineCount + 1 end
        end

        local hintW = maxTextW + (padX * 2)
        local hintH = padY + lineStep + (lineCount * lineStep) + 4
        draw.RoundedBox(4, x - padX, y - padY, hintW, hintH, Color(18, 18, 18, 220))
        surface.SetDrawColor(uiAccent)
        surface.DrawRect(x - padX, y - padY, hintW, 2)

        draw.SimpleText(hintHeader, "ZoneTool_Preview", x, y, uiAccent)
        y = y + 20

        draw.SimpleText("Corners: " .. #self.zoneCorners .. "/2", "ZoneTool_Preview", x, y, uiText)
        y = y + 20

        if #self.zoneCorners > 0 then
            local cornerStr = string.format("(%.0f, %.0f, %.0f)", self.zoneCorners[1].x, self.zoneCorners[1].y, self.zoneCorners[1].z)
            draw.SimpleText("Corner 1: " .. cornerStr, "ZoneTool_Preview", x, y, uiText)
            y = y + 16
        end

        if #self.zoneCorners > 1 then
            local cornerStr = string.format("(%.0f, %.0f, %.0f)", self.zoneCorners[2].x, self.zoneCorners[2].y, self.zoneCorners[2].z)
            draw.SimpleText("Corner 2: " .. cornerStr, "ZoneTool_Preview", x, y, uiText)
            y = y + 16
        end

        y = y + 10
        draw.SimpleText("Left Click: Add corner | Right Click: Cancel | Reload: Clear", "ZoneTool_Preview", x, y, uiMuted)

        local Zones = Monarch.Zones
        if Zones and Zones.Registry then
            for zoneId, zone in pairs(Zones.Registry) do
                if zone.pos and zone.size then
                    local zpos = isvector(zone.pos) and zone.pos or Vector(zone.pos.x or 0, zone.pos.y or 0, zone.pos.z or 0)
                    local zsize = isvector(zone.size) and zone.size or Vector(zone.size.x or 16, zone.size.y or 16, zone.size.z or 16)

                    local minPos = zpos - zsize * 0.5
                    local maxPos = zpos + zsize * 0.5

                    local zoneCorners = {
                        Vector(minPos.x, minPos.y, minPos.z),
                        Vector(maxPos.x, minPos.y, minPos.z),
                        Vector(maxPos.x, maxPos.y, minPos.z),
                        Vector(minPos.x, maxPos.y, minPos.z),
                        Vector(minPos.x, minPos.y, maxPos.z),
                        Vector(maxPos.x, minPos.y, maxPos.z),
                        Vector(maxPos.x, maxPos.y, maxPos.z),
                        Vector(minPos.x, maxPos.y, maxPos.z),
                    }

                    local zoneEdges = {
                        {1,2}, {2,3}, {3,4}, {4,1}, 
                        {5,6}, {6,7}, {7,8}, {8,5}, 
                        {1,5}, {2,6}, {3,7}, {4,8}, 
                    }

                    for _, edge in ipairs(zoneEdges) do
                        local p1 = zoneCorners[edge[1]]:ToScreen()
                        local p2 = zoneCorners[edge[2]]:ToScreen()
                        if p1.visible and p2.visible then
                            local zoneCol = getZoneRenderColor(zoneId)
                            surface.SetDrawColor(zoneCol.r, zoneCol.g, zoneCol.b, zoneCol.a or 200)
                            surface.DrawLine(p1.x, p1.y, p2.x, p2.y)
                        end
                    end

                    local centerScreen = zpos:ToScreen()
                    if centerScreen.visible then
                        local zoneCol = getZoneRenderColor(zoneId)
                        draw.SimpleText(zone.name or zoneId, "ZoneTool_Preview", centerScreen.x, centerScreen.y - 8, zoneCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        draw.SimpleText("ZoneID: " .. tostring(zoneId), "ZoneTool_Preview", centerScreen.x, centerScreen.y + 10, Color(235, 235, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end
            end
        end

        if #self.zoneCorners > 0 then
            for i, corner in ipairs(self.zoneCorners) do
                local screenPos = corner:ToScreen()
                if screenPos.visible then
                    draw.SimpleText("#" .. i, "ZoneTool_Preview", screenPos.x, screenPos.y, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end

            if #self.zoneCorners == 2 then
                local pos1 = self.zoneCorners[1]
                local pos2 = self.zoneCorners[2]
                local minPos = Vector(math.min(pos1.x, pos2.x), math.min(pos1.y, pos2.y), math.min(pos1.z, pos2.z))
                local maxPos = Vector(math.max(pos1.x, pos2.x), math.max(pos1.y, pos2.y), math.max(pos1.z, pos2.z))

                local corners = {
                    Vector(minPos.x, minPos.y, minPos.z),
                    Vector(maxPos.x, minPos.y, minPos.z),
                    Vector(maxPos.x, maxPos.y, minPos.z),
                    Vector(minPos.x, maxPos.y, minPos.z),
                    Vector(minPos.x, minPos.y, maxPos.z),
                    Vector(maxPos.x, minPos.y, maxPos.z),
                    Vector(maxPos.x, maxPos.y, maxPos.z),
                    Vector(minPos.x, maxPos.y, maxPos.z),
                }

                local edges = {
                    {1,2}, {2,3}, {3,4}, {4,1}, 
                    {5,6}, {6,7}, {7,8}, {8,5}, 
                    {1,5}, {2,6}, {3,7}, {4,8}, 
                }

                for _, edge in ipairs(edges) do
                    local p1 = corners[edge[1]]:ToScreen()
                    local p2 = corners[edge[2]]:ToScreen()
                    if p1.visible and p2.visible then
                        surface.SetDrawColor(100, 200, 255, 150)
                        surface.DrawLine(p1.x, p1.y, p2.x, p2.y)
                    end
                end
            end
        end
    end
end

if SERVER then

    net.Receive("Monarch_ZoneTool_Create", function(len, ply)
        if not IsValid(ply) or not ply:IsAdmin() then return end

        local isDialog = net.ReadBool()
        if isDialog then return end 

        local zoneName = net.ReadString()
        local zoneDesc = net.ReadString()
        local isIllegal = net.ReadBool()
        local pos1 = net.ReadVector()
        local pos2 = net.ReadVector()

        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "weapon_monarch_zonestool" then return end

        wep:CreateZone(zoneName, zoneDesc, isIllegal, pos1, pos2)
    end)
end
