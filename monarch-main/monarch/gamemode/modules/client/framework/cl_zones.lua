if CLIENT then

    local function GetZones()
        return Monarch and Monarch.Zones or nil
    end
    local currentZone = nil
    local previousZone = nil
    local zoneChangeTime = 0
    local fadeOutStartTime = 0
    local typewriterProgress = 0
    local typewriterSpeed = 0.13 
    local displayDuration = 6.5 
    local lastTypewriterChar = 0 
    local fadeOutDuration = 0.3 
    local zoneEndSoundPlayed = false

    hook.Add("Monarch_ZoneChanged", "Monarch_ZonesDisplay", function(zoneId)
        if currentZone and currentZone ~= zoneId then
            previousZone = currentZone
            fadeOutStartTime = CurTime()
        end
        currentZone = zoneId
        zoneChangeTime = CurTime() + (previousZone and fadeOutDuration or 0)
        typewriterProgress = 0
        lastTypewriterChar = 0 
        zoneEndSoundPlayed = false
    end)

    hook.Add("HUDPaint", "Monarch_ZoneDisplay_HUD", function()
        local now = CurTime()
        local Z = GetZones()
        if not Z or not Z.Registry then return end

        if previousZone then
            local fadeElapsed = now - fadeOutStartTime
            if fadeElapsed < fadeOutDuration then
                local zone = Z.Registry[previousZone]
                if zone then
                    local zoneName = zone.name or previousZone
                    local font = zone.illegal and "MonarchZone_TypeWriter" or "MonarchZone_TypeWriterNoItalic"
                    local textColor = zone.illegal and Color(220, 50, 50) or Color(180, 180, 180)

                    local fadeAlpha = math.floor(255 * (1 - (fadeElapsed / fadeOutDuration)))
                    textColor.a = fadeAlpha

                    local screenH = ScrH()
                    local yPos = screenH * 0.4

                    surface.SetFont(font)
                    local nameWidth = surface.GetTextSize(zoneName)
                    local nameXPos = ScrW() * 0.01

                    local padding = 20
                    nameXPos = math.max(padding + nameWidth * 0.5, nameXPos)
                    nameXPos = math.min(ScrW() - padding - nameWidth * 0.5, nameXPos)

                    draw.SimpleText(zoneName, font, nameXPos + 2, yPos + 2, Color(0, 0, 0, fadeAlpha * 0.8), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(zoneName, font, nameXPos, yPos, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                    surface.SetFont("MonarchZone_Time")
                    local frac = game.GetTimeScale() * (CurTime() % 3600) / 3600
                    local totalMinutes = frac * 24 * 60 * 1.5
                    local hours24 = math.floor(totalMinutes / 60)
                    local minutes = math.floor(totalMinutes % 60)
                    local hours12 = hours24 % 12
                    if hours12 == 0 then hours12 = 12 end
                    local am = hours24 < 12
                    local timeStr = string.format("%02d:%02d %s", hours12, minutes, am and "AM" or "PM")
                    local nameTextLeftClamped = nameXPos - (nameWidth * 0.5)

                    draw.SimpleText(timeStr, "MonarchZone_Time", nameTextLeftClamped + 2, yPos + 22, Color(0, 0, 0, fadeAlpha * 0.8), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    draw.SimpleText(timeStr, "MonarchZone_Time", nameTextLeftClamped, yPos + 20, Color(255, 255, 255, fadeAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            else
                previousZone = nil
            end
        end

        if not currentZone then return end
        if now < zoneChangeTime then return end

        local zone = Z.Registry[currentZone]
        if not zone then return end

        local elapsed = now - zoneChangeTime

        local zoneName = zone.name or currentZone
        local targetChars = #zoneName
        local typewriterChars = math.floor((elapsed / typewriterSpeed) + 1)

        local totalDisplayTime = (targetChars * typewriterSpeed) + displayDuration
        local fadeOutStart = totalDisplayTime - 0.5
        local alpha = 255

        if elapsed > fadeOutStart and elapsed < totalDisplayTime then
            alpha = math.floor(255 * ((totalDisplayTime - elapsed) / 0.5))
        elseif elapsed >= totalDisplayTime then
            currentZone = nil
            return
        end

        local displayText = string.sub(zoneName, 1, math.min(typewriterChars, targetChars))
        local font = "MonarchZone_TypeWriterNoItalic"

        local textColor = Color(180, 180, 180, alpha)
        if zone.illegal then
            textColor = Color(220, 50, 50, alpha)
            font = "MonarchZone_TypeWriter"
        end

        local screenW = ScrW()
        local screenH = ScrH()
        local yPos = screenH * 0.4 

        surface.SetFont("MonarchZone_TypeWriter")
        local nameWidth = surface.GetTextSize(displayText)

        surface.SetFont("MonarchZone_Time")
        local timeStr = ""
        do

            local frac = game.GetTimeScale() * (CurTime() % 3600) / 3600
            local totalMinutes = frac * 24 * 60 * 1.5
            local hours24 = math.floor(totalMinutes / 60)
            local minutes = math.floor(totalMinutes % 60)
            local hours12 = hours24 % 12
            if hours12 == 0 then hours12 = 12 end
            local am = hours24 < 12
            timeStr = string.format("%02d:%02d %s", hours12, minutes, am and "AM" or "PM")
        end
        local timeWidth = surface.GetTextSize(timeStr)

        local nameXPos = ScrW() * 0.01

        surface.SetFont("MonarchZone_TypeWriter")
        local nameTextLeft = nameXPos - (nameWidth * 0.5)

        local padding = 20
        nameXPos = math.max(padding + nameWidth * 0.5, nameXPos)
        nameXPos = math.min(ScrW() - padding - nameWidth * 0.5, nameXPos)
        local nameTextLeftClamped = nameXPos - (nameWidth * 0.5)

        draw.SimpleText(displayText, font, nameXPos + 2, yPos + 2, Color(0, 0, 0, alpha * 0.8), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(displayText, font, nameXPos, yPos, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        draw.SimpleText(timeStr, "MonarchZone_Time", nameTextLeftClamped + 2, yPos + 22, Color(0, 0, 0, alpha * 0.8), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(timeStr, "MonarchZone_Time", nameTextLeftClamped, yPos + 20, Color(255, 255, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local totalCharsShown = typewriterChars

        if totalCharsShown > lastTypewriterChar and totalCharsShown <= targetChars then
            lastTypewriterChar = totalCharsShown
            surface.PlaySound("ui/textline_"..math.random(1, 8)..".wav")

            if lastTypewriterChar >= targetChars and not zoneEndSoundPlayed then
                zoneEndSoundPlayed = true
                surface.PlaySound("ui/textline_end.wav")
            end
        end
    end)

    surface.CreateFont("ZoneManager_Title", {
        font = "Purista",
        size = 20,
        weight = 600,
        antialias = true,
    })

    surface.CreateFont("ZoneManager_Text", {
        font = "Purista",
        size = 16,
        weight = 400,
        antialias = true,
    })

    local function GetPalette()
        if Monarch and Monarch.Theme and Monarch.Theme.Get then
            return Monarch.Theme.Get()
        end
        return {
            panel = Color(28,28,30),
            outline = Color(55,57,63),
            titlebar = Color(30,30,32),
            divider = Color(80,82,88,160),
            text = Color(230,232,236),
            btn = Color(60,64,72),
            btnHover = Color(72,76,84),
            btnText = Color(240,242,245),
            primary = Color(88,88,88),
            primaryHover = Color(130,130,130),
            inputBg = Color(38,39,44),
            inputBorder = Color(70,73,79),
            inputText = Color(230,232,236),
            radius = 6,
        }
    end

    local function StyledButton(parent, text)
        local btn = vgui.Create("DButton", parent)
        btn:SetText("")
        btn.ButtonText = text or ""
        btn.Selected = false
        btn.Font = "InvMed"
        btn._hover = 0
        function btn:Paint(pw, ph)
            local P = GetPalette()
            local bg = P.btn
            if self:GetDisabled() then
                bg = Color(bg.r, bg.g, bg.b, 120)
            elseif self.Depressed or self:IsDown() or self.Selected or self:GetToggle() then
                bg = P.primary
            elseif self.Hovered then
                bg = P.btnHover
            end
            draw.RoundedBox(P.radius or 6, 0, 0, pw, ph, bg)
            surface.SetDrawColor(P.outline)
            surface.DrawOutlinedRect(0, 0, pw, ph, 1)
            surface.SetFont(self.Font or "InvMed")
            local label = self.ButtonText or ""
            local tw, th = surface.GetTextSize(label)
            surface.SetTextColor(P.btnText)
            surface.SetTextPos(math.floor(pw * 0.5 - tw * 0.5), math.floor(ph * 0.5 - th * 0.5))
            surface.DrawText(label)
        end
        function btn:OnCursorEntered() surface.PlaySound("menu/ui_click.mp3") end
        return btn
    end

    local function PanelControlButton(parent, text)
        local btn = vgui.Create("DButton", parent)
        btn:SetText("")
        btn.ButtonText = text or ""
        btn.Font = "InvSmall"
        function btn:Paint(pw, ph)
            local P = GetPalette()
            local bg = self.Hovered and P.btnHover or P.btn
            draw.RoundedBox(P.radius or 6, 0, 0, pw, ph, bg)
            surface.SetDrawColor(P.outline)
            surface.DrawOutlinedRect(0, 0, pw, ph, 1)
            surface.SetFont(self.Font)
            local tw, th = surface.GetTextSize(self.ButtonText)
            surface.SetTextColor(P.btnText)
            surface.SetTextPos(math.floor(pw * 0.5 - tw * 0.5), math.floor(ph * 0.5 - th * 0.5))
            surface.DrawText(self.ButtonText)
        end
        return btn
    end

    function Monarch.OpenZoneManager()
        if not LocalPlayer():IsAdmin() then
            chat.AddText(Color(255, 100, 100), "[Zones] You must be an admin to use this.")
            return
        end

        local frame = vgui.Create("DFrame")
        frame:SetSize(900, 600)
        frame:Center()
        frame:SetTitle("")
        frame:ShowCloseButton(false)
        frame:SetVisible(true)
        frame:SetDraggable(true)
        frame:MakePopup()
        frame.topBarH = 28

        frame.Paint = function(s, pw, ph)
            local P = GetPalette()

            surface.SetDrawColor(P.panel)
            surface.DrawRect(0, 0, pw, ph)
            surface.SetDrawColor(P.outline)
            surface.DrawOutlinedRect(0, 0, pw, ph, 1)

            surface.SetDrawColor(P.titlebar)
            surface.DrawRect(0, 0, pw, s.topBarH)
            surface.SetDrawColor(P.divider)
            surface.DrawLine(0, s.topBarH, pw, s.topBarH)
            draw.SimpleText("Zone Manager", "InvMed", 12, math.floor((s.topBarH - 24) * 0.5), P.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        local closeBtn = PanelControlButton(frame, "✕")
        closeBtn:SetSize(24, 20)
        closeBtn:SetPos(frame:GetWide() - 28, math.floor((frame.topBarH - 20) * 0.5))
        closeBtn.DoClick = function() frame:Close() end
        closeBtn.Think = function(s) s:SetPos(frame:GetWide() - 28, math.floor((frame.topBarH - 20) * 0.5)) end

        local content = vgui.Create("DPanel", frame)
        content:Dock(FILL)
        content:DockMargin(8, frame.topBarH + 8, 8, 8)
        content.Paint = nil

        local infoLabel = vgui.Create("DLabel", content)
        infoLabel:Dock(TOP)
        infoLabel:SetTall(20)
        infoLabel:SetText("Select a zone to teleport or delete it")
        infoLabel:SetFont("InvMed")
        infoLabel:SetTextColor(GetPalette().text)
        infoLabel:DockMargin(0, 0, 0, 8)

        local zoneList = vgui.Create("DListView", content)
        zoneList:Dock(FILL)
        zoneList:SetMultiSelect(false)
        zoneList:DockMargin(0, 0, 0, 8)
        zoneList:SetDataHeight(28)
        zoneList:AddColumn("ID"):SetFixedWidth(180)
        zoneList:AddColumn("Zone"):SetFixedWidth(260)
        zoneList:AddColumn("Flag"):SetFixedWidth(100)
        zoneList:AddColumn("Position"):SetFixedWidth(200)

        zoneList.Paint = function(self, w, h)
            local P = GetPalette()
            surface.SetDrawColor(P.inputBg)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(P.inputBorder)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end

        local function StyleHeader()
            if not zoneList.GetHeader then return end
            local header = zoneList:GetHeader()
            if not IsValid(header) then return end
            header:SetTall(26)
            if header.SetPaintBackground then header:SetPaintBackground(false) end
            if header.SetPaintBackgroundEnabled then header:SetPaintBackgroundEnabled(false) end
            header.Paint = function(self, w, h)
                local P = GetPalette()
                surface.SetDrawColor(P.titlebar)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(P.outline)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            for _, col in ipairs(zoneList.Columns or {}) do
                if IsValid(col.Header) then
                    col.Header:SetFont("InvMed")
                    col.Header:SetTextColor(GetPalette().text)
                    col.Header.Paint = function(self, w, h)
                        local P = GetPalette()
                        surface.SetDrawColor(P.titlebar)
                        surface.DrawRect(0, 0, w, h)
                        surface.SetDrawColor(P.divider)
                        surface.DrawLine(w - 1, 0, w - 1, h)
                        surface.SetTextColor(P.text)
                        surface.SetFont("InvMed")
                        local txt = self:GetText() or ""
                        local tw, th = surface.GetTextSize(txt)
                        surface.SetTextPos(math.floor((w - tw) * 0.5), math.floor((h - th) * 0.5))
                        surface.DrawText(txt)
                    end
                end
            end
        end
        StyleHeader()
        timer.Simple(0, function() if IsValid(zoneList) then StyleHeader() end end)

        local headerBar = vgui.Create("DPanel", content)
        headerBar:Dock(TOP)
        headerBar:SetTall(26)
        headerBar:DockMargin(0, 0, 0, 0)
        local columns = {
            { title = "ID", width = 180 },
            { title = "Zone", width = 260 },
            { title = "Flag", width = 100 },
            { title = "Position", width = 200 },
        }
        headerBar.Paint = function(self, w, h)
            local P = GetPalette()
            surface.SetDrawColor(P.titlebar)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(P.outline)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            local x = 0
            for i, col in ipairs(columns) do
                surface.SetDrawColor(P.divider)
                surface.DrawLine(x + col.width, 0, x + col.width, h)
                surface.SetFont("InvMed")
                local tw, th = surface.GetTextSize(col.title)
                surface.SetTextColor(GetPalette().text)
                surface.SetTextPos(x + math.floor(col.width * 0.5 - tw * 0.5), math.floor(h * 0.5 - th * 0.5))
                surface.DrawText(col.title)
                x = x + col.width
            end
        end

        local dvHeader = zoneList.GetHeader and zoneList:GetHeader()
        if IsValid(dvHeader) then
            dvHeader:SetVisible(false)
            dvHeader:SetTall(0)
            if dvHeader.SetPaintBackground then dvHeader:SetPaintBackground(false) end
            dvHeader.Paint = nil
        end

        if zoneList.Columns then
            for _, col in ipairs(zoneList.Columns) do
                if IsValid(col.Header) then
                    col.Header:SetVisible(false)
                    col.Header:SetTall(0)
                    col.Header.Paint = nil
                end
            end
        end

        zoneList:DockPadding(0, 0, 0, 0)
        zoneList:InvalidateLayout(true)

        local vbar = zoneList.VBar
        if IsValid(vbar) then
            vbar.Paint = function(self, w, h)
                local P = GetPalette()
                surface.SetDrawColor(P.panel)
                surface.DrawRect(0, 0, w, h)
            end
            vbar.btnGrip.Paint = function(self, w, h)
                local P = GetPalette()
                surface.SetDrawColor(P.btn)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(P.outline)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            vbar.btnUp.Paint = function(self, w, h)
                local P = GetPalette()
                surface.SetDrawColor(P.btn)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(P.outline)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            vbar.btnDown.Paint = vbar.btnUp.Paint
        end

        local function RefreshZoneList()
            zoneList:Clear()
            local Z = GetZones()
            if not Z or not Z.Registry then return end

            for zoneId, zone in pairs(Z.Registry) do
                local statusText = zone.illegal and "ILLEGAL" or "LEGAL"
                local posText = string.format("%.0f, %.0f, %.0f", zone.pos.x, zone.pos.y, zone.pos.z)
                local line = zoneList:AddLine(zoneId, zone.name or "Unnamed", statusText, posText)
                line.zoneId = zoneId

                local isIllegal = zone.illegal
                line.Paint = function(s, w, h)
                    local P = GetPalette()
                    local isHover = s.IsHovered and s:IsHovered()
                    local alt = s.IsAltLine and s:IsAltLine()
                    local isSelected = s.IsSelected and s:IsSelected()
                    local bg = (isSelected or isHover) and P.btnHover or (alt and Color(P.inputBg.r + 6, P.inputBg.g + 6, P.inputBg.b + 6, 255) or P.inputBg)
                    surface.SetDrawColor(bg)
                    surface.DrawRect(0, 0, w, h)
                    surface.SetDrawColor(P.divider)
                    surface.DrawLine(0, h - 1, w, h - 1)
                end

                local textCol = isIllegal and Color(220, 50, 50) or GetPalette().text
                for i = 1, #line.Columns do
                    line.Columns[i]:SetTextColor(textCol)
                end
            end
        end

        RefreshZoneList()

        local buttonPanel = vgui.Create("DPanel", content)
        buttonPanel:Dock(BOTTOM)
        buttonPanel:SetTall(40)
        buttonPanel.Paint = function(self, pw, ph)
            local P = GetPalette()
            surface.SetDrawColor(P.panel)
            surface.DrawRect(0, 0, pw, ph)
        end

        local teleportBtn = StyledButton(buttonPanel, "Teleport to Zone")
        teleportBtn:SetPos(10, 5)
        teleportBtn:SetSize(200, 30)
        teleportBtn.DoClick = function()
            local selected = zoneList:GetSelectedLine()
            if not selected then
                chat.AddText(Color(255, 100, 100), "[Zones] Please select a zone first.")
                return
            end

            local line = zoneList:GetLine(selected)
            if line and line.zoneId then
                net.Start("Monarch_ZoneTeleport")
                    net.WriteString(line.zoneId)
                net.SendToServer()

                chat.AddText(Color(100, 200, 255), "[Zones] Teleporting to zone: ", Color(255, 255, 255), line.zoneId)
            end
        end

        local deleteBtn = StyledButton(buttonPanel, "Delete Zone")
        deleteBtn:SetPos(220, 5)
        deleteBtn:SetSize(200, 30)
        deleteBtn.DoClick = function()
            local selected = zoneList:GetSelectedLine()
            if not selected then
                chat.AddText(Color(255, 100, 100), "[Zones] Please select a zone first.")
                return
            end

            local line = zoneList:GetLine(selected)
            if line and line.zoneId then

                local confirmFrame = vgui.Create("DFrame")
                confirmFrame:SetSize(400, 140)
                confirmFrame:Center()
                confirmFrame:SetTitle("")
                confirmFrame:ShowCloseButton(false)
                confirmFrame:SetDraggable(false)
                confirmFrame:MakePopup()
                confirmFrame.topBarH = 28

                confirmFrame.Paint = function(s, w, h)
                    local P = GetPalette()
                    surface.SetDrawColor(P.panel)
                    surface.DrawRect(0, 0, w, h)
                    surface.SetDrawColor(P.outline)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                    surface.SetDrawColor(P.titlebar)
                    surface.DrawRect(0, 0, w, s.topBarH)
                    surface.SetDrawColor(P.divider)
                    surface.DrawLine(0, s.topBarH, w, s.topBarH)
                    draw.SimpleText("Confirm Delete", "InvMed", 12, math.floor((s.topBarH - 24) * 0.5), P.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end

                local confirmContent = vgui.Create("DPanel", confirmFrame)
                confirmContent:Dock(FILL)
                confirmContent:DockMargin(8, confirmFrame.topBarH + 8, 8, 8)
                confirmContent.Paint = nil

                local confirmLabel = vgui.Create("DLabel", confirmContent)
                confirmLabel:Dock(TOP)
                confirmLabel:SetTall(50)
                confirmLabel:SetText("Are you sure you want to delete this zone?\n" .. line.zoneId)
                confirmLabel:SetFont("InvMed")
                confirmLabel:SetTextColor(GetPalette().text)
                confirmLabel:SetWrap(true)
                confirmLabel:SetAutoStretchVertical(true)

                local btnRow = vgui.Create("DPanel", confirmContent)
                btnRow:Dock(BOTTOM)
                btnRow:SetTall(36)
                btnRow.Paint = nil

                local yesBtn = StyledButton(btnRow, "Yes, Delete")
                yesBtn:Dock(LEFT)
                yesBtn:SetWide(150)
                yesBtn:DockMargin(0, 0, 10, 0)
                yesBtn.DoClick = function()
                    net.Start("Monarch_ZoneDelete")
                        net.WriteString(line.zoneId)
                    net.SendToServer()

                    chat.AddText(Color(255, 100, 100), "[Zones] Deleted zone: ", Color(255, 255, 255), line.zoneId)

                    timer.Simple(0.2, function()
                        if IsValid(zoneList) then
                            RefreshZoneList()
                        end
                    end)

                    confirmFrame:Close()
                end

                local noBtn = StyledButton(btnRow, "Cancel")
                noBtn:Dock(LEFT)
                noBtn:SetWide(150)
                noBtn.DoClick = function()
                    confirmFrame:Close()
                end
            end
        end

        local refreshBtn = StyledButton(buttonPanel, "Refresh List")
        refreshBtn:SetPos(430, 5)
        refreshBtn:SetSize(150, 30)
        refreshBtn.DoClick = function()
            RefreshZoneList()
            chat.AddText(Color(100, 200, 255), "[Zones] Zone list refreshed.")
        end

        local closeBottomBtn = StyledButton(buttonPanel, "Close")
        closeBottomBtn:SetPos(590, 5)
        closeBottomBtn:SetSize(120, 30)
        closeBottomBtn.DoClick = function()
            frame:Close()
        end
    end

    concommand.Add("monarch_zones", function()
        Monarch.OpenZoneManager()
    end)

    net.Receive("Monarch_ZonesSync", function()

        hook.Run("Monarch_ZonesUpdated")
    end)
end

