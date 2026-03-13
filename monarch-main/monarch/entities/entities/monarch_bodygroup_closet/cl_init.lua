include("shared.lua")

net.Receive("Monarch_BodygroupCloset_Open", function()
    local bodygroupsJSON = net.ReadString()
    local currentBodygroups = util.JSONToTable(bodygroupsJSON) or {}

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local frame = vgui.Create("DFrame")
    frame:SetSize(700, 900)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame:MakePopup()
    function frame:Paint(w, h)
        surface.SetDrawColor(20, 20, 22, 240)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(60, 60, 65, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        surface.SetDrawColor(30, 30, 33, 255)
        surface.DrawRect(0, 0, w, 30)
        draw.SimpleText("Bodygroups Closet", "DermaDefault", w/2, 15, Color(220, 220, 225), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local modelPreview = vgui.Create("DModelPanel", frame)
    modelPreview:SetSize(450, 700)
    modelPreview:SetPos(15, 100)
    modelPreview:SetModel(ply:GetModel())
    modelPreview:SetFOV(45)

    local function FitPreviewToModel(panel)
        local ent = panel:GetEntity()
        if not IsValid(ent) then return end
        local mn, mx = ent:GetModelBounds()
        local size = (mx - mn):Length()
        local center = (mn + mx) * 0.5

        local dist = size * 0.6
        panel:SetCamPos(center + Vector(dist, dist * 0.25, dist * 0.35))
        panel:SetLookAt(center + Vector(0, 0, (mx.z - mn.z) * 0.1))

        panel:SetAmbientLight(Color(70, 70, 70))
        panel:SetDirectionalLight(BOX_TOP, Color(120, 120, 120))
        panel:SetDirectionalLight(BOX_FRONT, Color(100, 100, 100))
    end
    timer.Simple(0, function() if IsValid(modelPreview) then FitPreviewToModel(modelPreview) end end)

    local selectedBodygroups = {}
    local selectedSkin = tonumber(ply:GetSkin()) or 0
    for k, v in pairs(currentBodygroups) do
        selectedBodygroups[tonumber(k)] = tonumber(v)
    end

    function modelPreview:LayoutEntity(ent)
        if not IsValid(ent) then return end
        ent:SetPos(vector_origin)
        ent:SetAngles(Angle(0, 15, 0))
        ent:SetSkin(selectedSkin)
        for bgID, bgValue in pairs(selectedBodygroups) do
            ent:SetBodygroup(bgID, bgValue)
        end
        FitPreviewToModel(self)
        ent:SetRenderMode(RENDERMODE_NORMAL)
    end

    local bodygroupContainer = vgui.Create("DPanel", frame)
    bodygroupContainer:SetPos(375, 120)
    bodygroupContainer:SetSize(210, 350)
    function bodygroupContainer:Paint(w, h)
        surface.SetDrawColor(24, 24, 26, 240)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(55, 55, 60, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local bodygroupLabel = vgui.Create("DLabel", bodygroupContainer)
    bodygroupLabel:SetPos(10, 5)
    bodygroupLabel:SetFont("DermaDefault")
    bodygroupLabel:SetText("Bodygroups:")
    bodygroupLabel:SetTextColor(Color(200, 200, 200))
    bodygroupLabel:SizeToContents()

    local bodygroupScroll = vgui.Create("DScrollPanel", bodygroupContainer)
    bodygroupScroll:SetPos(5, 25)
    bodygroupScroll:SetSize(200, 320)
    function bodygroupScroll:Paint() end
    local bgSbar = bodygroupScroll:GetVBar()
    function bgSbar:Paint(w, h)
        surface.SetDrawColor(30, 30, 32, 255)
        surface.DrawRect(0, 0, w, h)
    end
    function bgSbar.btnGrip:Paint(w, h)
        surface.SetDrawColor(70, 70, 75, 255)
        surface.DrawRect(0, 0, w, h)
    end
    function bgSbar.btnUp:Paint(w, h) end
    function bgSbar.btnDown:Paint(w, h) end

    local bodygroupList = vgui.Create("DIconLayout", bodygroupScroll)
    bodygroupList:Dock(FILL)
    bodygroupList:SetSpaceY(5)

    local tempEnt = ClientsideModel(ply:GetModel())
    if IsValid(tempEnt) then

        local skinCount = (tempEnt.SkinCount and tempEnt:SkinCount()) or 1
        if skinCount > 1 then
            local skinPanel = vgui.Create("DPanel", bodygroupContainer)
            skinPanel:SetPos(10, 25)
            skinPanel:SetSize(190, 45)
            function skinPanel:Paint(w, h)
                surface.SetDrawColor(28, 28, 30, 240)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(55, 55, 60, 255)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end

            local skinLabel = vgui.Create("DLabel", skinPanel)
            skinLabel:SetPos(5, 5)
            skinLabel:SetFont("DermaDefaultBold")
            skinLabel:SetText("Skin")
            skinLabel:SetTextColor(Color(210, 210, 215))
            skinLabel:SizeToContents()

            local skinSlider = vgui.Create("DNumSlider", skinPanel)
            skinSlider:SetPos(5, 20)
            skinSlider:SetSize(180, 18)
            skinSlider:SetMin(0)
            skinSlider:SetMax(math.max(0, skinCount - 1))
            skinSlider:SetDecimals(0)
            skinSlider:SetValue(selectedSkin)
            skinSlider:SetText("")
            function skinSlider:Paint(w, h) end
            function skinSlider:OnValueChanged(val)
                selectedSkin = math.floor(val)
                local ent = modelPreview:GetEntity()
                if IsValid(ent) then ent:SetSkin(selectedSkin) end
            end
        end

        if skinCount > 1 then
            bodygroupScroll:SetPos(5, 75)
            bodygroupScroll:SetSize(200, 270)
        else
            bodygroupScroll:SetPos(5, 25)
            bodygroupScroll:SetSize(200, 320)
        end

        for i = 0, tempEnt:GetNumBodyGroups() - 1 do
            local bgName = tempEnt:GetBodygroupName(i)
            local bgCount = tempEnt:GetBodygroupCount(i)
            if Monarch and Monarch.IsBodygroupDisallowed and Monarch.IsBodygroupDisallowed(ply:GetModel(), i) then
                continue
            end
            if bgCount > 1 then
                selectedBodygroups[i] = selectedBodygroups[i] or 0
                local bgPanel = vgui.Create("DPanel")
                bgPanel:SetSize(190, 40)
                bodygroupList:Add(bgPanel)
                function bgPanel:Paint(w, h)
                    surface.SetDrawColor(28, 28, 30, 240)
                    surface.DrawRect(0, 0, w, h)
                    surface.SetDrawColor(55, 55, 60, 255)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end
                local bgLabel = vgui.Create("DLabel", bgPanel)
                bgLabel:SetPos(5, 5)
                bgLabel:SetFont("DermaDefaultBold")
                bgLabel:SetText(bgName:gsub("^%l", string.upper))
                bgLabel:SetTextColor(Color(210, 210, 215))
                bgLabel:SizeToContents()
                local bgSlider = vgui.Create("DNumSlider", bgPanel)
                bgSlider:SetPos(5, 15)
                bgSlider:SetSize(180, 20)
                bgSlider:SetMin(0)
                bgSlider:SetMax(bgCount - 1)
                bgSlider:SetDecimals(0)
                bgSlider:SetValue(selectedBodygroups[i])
                bgSlider:SetText("")
                function bgSlider:Paint(w, h) end
                function bgSlider:OnValueChanged(value)
                    local intValue = math.floor(value)
                    selectedBodygroups[i] = intValue
                    local ent = modelPreview:GetEntity()
                    if IsValid(ent) then
                        ent:SetBodygroup(i, intValue)
                    end
                end
            end
        end
        tempEnt:Remove()
    end

    local applyBtn = vgui.Create("DButton", frame)
    applyBtn:SetSize(200, 40)
    applyBtn:SetPos(frame:GetWide()/2 - 100, frame:GetTall() - 130)
    applyBtn:SetText("Apply Appearance")
    applyBtn:SetFont("DermaDefaultBold")
    function applyBtn:Paint(w, h)
        if self:IsDown() then
            surface.SetDrawColor(40, 90, 40, 255)
        elseif self:IsHovered() then
            surface.SetDrawColor(50, 110, 50, 255)
        else
            surface.SetDrawColor(45, 100, 45, 255)
        end
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(80, 160, 80, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end
    applyBtn:SetTextColor(Color(220, 230, 220))
    function applyBtn:DoClick()
        net.Start("Monarch_BodygroupCloset_Update")
        net.WriteUInt(math.floor(selectedSkin or 0), 8)
        net.WriteUInt(table.Count(selectedBodygroups), 8)
        for bgID, bgValue in pairs(selectedBodygroups) do
            net.WriteUInt(bgID, 8)
            net.WriteUInt(bgValue, 8)
        end
        net.SendToServer()
        frame:Close()
    end

    local resetBtn = vgui.Create("DButton", frame)
    resetBtn:SetSize(200, 35)
    resetBtn:SetPos(frame:GetWide()/2 - 100, frame:GetTall() - 80)
    resetBtn:SetText("Reset to Default")
    resetBtn:SetFont("DermaDefault")
    function resetBtn:Paint(w, h)
        if self:IsDown() then
            surface.SetDrawColor(40, 40, 42, 255)
        elseif self:IsHovered() then
            surface.SetDrawColor(50, 50, 52, 255)
        else
            surface.SetDrawColor(40, 40, 42, 255)
        end
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(65, 65, 70, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    resetBtn:SetTextColor(Color(220, 220, 225))
    function resetBtn:DoClick()
        selectedBodygroups = {}
        local ent = modelPreview:GetEntity()
        if IsValid(ent) then
            for i = 0, ent:GetNumBodyGroups() - 1 do
                ent:SetBodygroup(i, 0)
                selectedBodygroups[i] = 0
            end
            selectedSkin = 0
            ent:SetSkin(0)
        end
        for _, child in pairs(bodygroupList:GetChildren()) do
            if IsValid(child) then
                for _, subchild in pairs(child:GetChildren()) do
                    if subchild:GetClassName() == "DNumSlider" then
                        subchild:SetValue(0)
                    end
                end
            end
        end
    end
end)
