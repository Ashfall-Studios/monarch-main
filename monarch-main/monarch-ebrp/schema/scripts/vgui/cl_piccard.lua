
if SERVER then return end

local PANEL = {}

surface.CreateFont("PIC_Title", {font="Purista", size=28, weight=700})
surface.CreateFont("PIC_Sub", {font="Purista", size=18, weight=600})
surface.CreateFont("PIC_Row", {font="Purista", size=16})
surface.CreateFont("PIC_Label", {font="Purista", size=14, weight=600})

local function Field(parent, label, value, x, y, w)
    local pnl = vgui.Create("DPanel", parent)
    pnl:SetPos(x, y)
    pnl:SetSize(w, 44)
    pnl.Paint = function(s, pw, ph)
        draw.SimpleText(label, "PIC_Label", 10, 6, Color(180,180,180), TEXT_ALIGN_LEFT)
        draw.SimpleText(value or "-", "PIC_Row", 10, 22, Color(240,240,240), TEXT_ALIGN_LEFT)
    end
    return pnl
end

function PANEL:Init()
    self:SetSize(620, 420)
    self:Center()
    self:MakePopup()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self._rowsY = 70
end

function PANEL:Populate(data)
    if not istable(data) then return end
    PrintTable(data)
    self.PlayerName = data.name or "Unknown"
    self.Occupation = data.occupation or ""; self.SteamID = data.steamid or ""; self.CharID = data.charid or 0
    self.Health = data.health or 0
    self.Height = data.height or "Unknown"
    self.Weight = data.weight or "Unknown"
    self.Hair   = data.hair or "Unknown"
    self.Eye    = data.eye or "Unknown"
    self.Age    = data.age or 0
    self.LoyaltyTier = data.loyalty_tier or 0
    self.PartyTier = data.party_tier or 0

    self.Paint = function(s,w,h)
        Derma_DrawBackgroundBlur(s, s.startTime or CurTime())

        surface.SetDrawColor(40,40,40,250)
        surface.DrawRect(0,0,w,h)

        surface.SetDrawColor(255,255,255,10)
        surface.SetMaterial(Material("icons/player_factions/faction_star.png", "smooth"))
        surface.DrawTexturedRect(w/2 - 128, h/2 - 128, 256, 256)

        surface.SetDrawColor(30,30,30,255)
        surface.DrawRect(0,0,w,36)

        surface.SetDrawColor(50,50,50,255)
        surface.DrawOutlinedRect(0,0,w,h,2)

        draw.SimpleText("PERSONAL IDENTIFICATION CARD", "PIC_Title", 14, 8, Color(235,240,255), TEXT_ALIGN_LEFT)
    end

    local facePanel = vgui.Create("DModelPanel", self)
    facePanel:SetPos(16, 46)
    facePanel:SetSize(120, 120)
    facePanel:SetModel(LocalPlayer():GetModel() or "models/Humans/Group01/Male_07.mdl")
    facePanel.LayoutEntity = function() end
    local _origFacePaint = facePanel.Paint
    facePanel.Paint = function(s,w,h)
        if _origFacePaint then _origFacePaint(s,w,h) end
        surface.SetDrawColor(20,20,20,180)
        surface.DrawOutlinedRect(0,0,w,h,2)
    end

    function facePanel:SetupHead()
        local ent = self:GetEntity()
        if not IsValid(ent) then return end
        local seq = ent:LookupSequence("idle_all") or ent:LookupSequence("idle_subtle") or ent:LookupSequence("idle") or ent:GetSequence()
        if seq and seq >= 0 then ent:ResetSequence(seq) end
        ent:SetCycle(0)
        ent:SetPlaybackRate(0)
        ent:SetAngles(Angle(0,0,0))

        local headBone = ent:LookupBone("ValveBiped.Bip01_Head1") or ent:LookupBone("ValveBiped.Bip01_Head")
        local headPos
        if headBone then
            local m = ent:GetBoneMatrix(headBone)
            if m then headPos = m:GetTranslation() end
        end
        if not headPos then
            headPos = ent:LocalToWorld(ent:OBBCenter()) + Vector(0,0,60 * (ent:GetModelScale() or 1))
        end

        local forward = ent:GetForward()
        local up = ent:GetUp()
        local lookAt = headPos + Vector(0,0,2)
        local camPos = headPos + (forward * 34) + (up * 2)
        self:SetLookAt(lookAt)
        self:SetCamPos(camPos)
        self:SetFOV(30)
    end

    facePanel:SetupHead()
    timer.Simple(0, function() if IsValid(facePanel) then facePanel:SetupHead() end end)
    timer.Simple(0.1, function() if IsValid(facePanel) then facePanel:SetupHead() end end)
    timer.Simple(0.25, function() if IsValid(facePanel) then facePanel:SetupHead() end end)

    local namePanel = vgui.Create("DPanel", self)
    namePanel:SetPos(146, 52)
    namePanel:SetSize(self:GetWide() - 162, 60)
    namePanel.Paint = function(s,w,h)
        draw.SimpleText(self.PlayerName or "Unknown", "PIC_Sub", 8, 8, Color(230,230,230), TEXT_ALIGN_LEFT)
        draw.SimpleText((self.Occupation or "Unknown"), "PIC_Row", 8, 30, Color(180,205,240), TEXT_ALIGN_LEFT)
    end

    local leftX, rightX = 16, math.floor(self:GetWide()/2)+8
    local topY = 160
    local colW = math.floor(self:GetWide()/2) - 24

    Field(self, "Height", tostring(self.Height), leftX, topY, colW)
    Field(self, "Weight (lbs)", tostring(self.Weight), rightX, topY, colW)
    Field(self, "Hair Color", tostring(self.Hair), leftX, topY + 48, colW)
    Field(self, "Eye Color", tostring(self.Eye), rightX, topY + 48, colW)
    Field(self, "Age", tostring(self.Age), leftX, topY + 96, colW)
    Field(self, "Loyalty Tier", tostring(self.LoyaltyTier), rightX, topY + 96, colW)
    Field(self, "Party Membership", tostring(self.PartyTier), leftX, topY + 144, colW)

    local closeBtn = vgui.Create("DButton", self)
    closeBtn:SetSize(120, 32)
    closeBtn:SetPos(self:GetWide() - 136, self:GetTall() - 50)
    closeBtn:SetText("Close")
    closeBtn:SetFont("PIC_Sub")
    closeBtn:SetTextColor(color_white)
    closeBtn.Paint = function(s,w,h)
        local hov = s:IsHovered()
        surface.SetDrawColor(hov and Color(250,90,90, 150) or Color(250,50,50, 50))
        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(250,50,50, 50)
        surface.DrawOutlinedRect(0,0,w,h,1)
    end
    closeBtn.DoClick = function() self:Remove() end
end

vgui.Register("MonarchPICCard", PANEL, "DFrame")

net.Receive("Monarch_ShowPIC", function()
    local data = {}
    data.name = net.ReadString()
    data.occupation = net.ReadString()
    data.steamid = net.ReadString()
    data.charid = net.ReadUInt(32)
    data.health = net.ReadInt(16)
    data.height = net.ReadString()
    data.weight = net.ReadString()
    data.hair = net.ReadString()
    data.eye = net.ReadString()
    data.age = net.ReadInt(16)
    data.loyalty_tier = net.ReadInt(16)
    data.party_tier = net.ReadInt(16)

    if IsValid(Monarch.PICPanel) then Monarch.PICPanel:Remove() end
    Monarch.PICPanel = vgui.Create("MonarchPICCard")
    Monarch.PICPanel:Populate(data)
end)
