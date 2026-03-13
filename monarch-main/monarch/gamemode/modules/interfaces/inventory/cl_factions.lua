

if CLIENT then
    Monarch = Monarch or {}
    Monarch.Factions = Monarch.Factions or {}

    local function ShowFactionNotification(message, isError)
        local invPanel = Monarch.InventoryPanel
        if IsValid(invPanel) and invPanel.ShowNotification then
            local color = isError and Color(255, 100, 100) or Color(100, 255, 100)
            invPanel:ShowNotification(message, color, 3)
        end

    end

    Monarch.Factions.PlayerFaction = nil
    Monarch.Factions.AllFactions = {}

    if not Monarch.Factions._ListReceiverAdded then
        net.Receive("Monarch_Faction_List", function()
            local publicList = net.ReadTable() or {}
            if istable(publicList) then
                Monarch.Factions.AllFactions = publicList
            end
        end)
        Monarch.Factions._ListReceiverAdded = true
    end

    if not Monarch.Factions._CreateResponseAdded then
        net.Receive("Monarch_Faction_CreateResponse", function()
            local success = net.ReadBool()
            if success then
                local faction = net.ReadTable()
                Monarch.Factions.PlayerFaction = faction
                Monarch.Factions.AllFactions[faction.id] = {
                    id = faction.id,
                    name = faction.name,
                    founderCharID = faction.founderCharID,
                    color = faction.color,
                    logoIndex = faction.logoIndex,
                    memberCount = table.Count(faction.members or {}),
                    createdAt = faction.createdAt
                }
                ShowFactionNotification("Faction created successfully!")

                net.Start("Monarch_Faction_RequestPlayerFaction")
                net.SendToServer()
            else
                local err = net.ReadString()
                ShowFactionNotification("Error: " .. err, true)
            end
        end)
        Monarch.Factions._CreateResponseAdded = true
    end

    if not Monarch.Factions._EditResponseAdded then
        net.Receive("Monarch_Faction_EditResponse", function()
            local success = net.ReadBool()
            if success then
                ShowFactionNotification("Faction updated successfully!")

                net.Start("Monarch_Faction_RequestPlayerFaction")
                net.SendToServer()
            else
                local err = net.ReadString()
                ShowFactionNotification("Error: " .. err, true)
            end
        end)
        Monarch.Factions._EditResponseAdded = true
    end

    if not Monarch.Factions._JoinResponseAdded then
        net.Receive("Monarch_Faction_JoinResponse", function()
            local success = net.ReadBool()
            if success then
                ShowFactionNotification("Successfully joined faction!")
                net.Start("Monarch_Faction_RequestPlayerFaction")
                net.SendToServer()
            else
                local err = net.ReadString()
                ShowFactionNotification("Error: " .. err, true)
            end
        end)
        Monarch.Factions._JoinResponseAdded = true
    end

    if not Monarch.Factions._LeaveResponseAdded then
        net.Receive("Monarch_Faction_LeaveResponse", function()
            local success = net.ReadBool()
            if success then
                Monarch.Factions.PlayerFaction = nil
                ShowFactionNotification("Successfully left faction!")
            else
                local err = net.ReadString()
                ShowFactionNotification("Error: " .. err, true)
            end
        end)
        Monarch.Factions._LeaveResponseAdded = true
    end

    Monarch.Factions.RegisteredPermissions = {}
    if not Monarch.Factions._PermissionsListAdded then
        net.Receive("Monarch_Faction_PermissionsList", function()
            Monarch.Factions.RegisteredPermissions = net.ReadTable() or {}
        end)
        Monarch.Factions._PermissionsListAdded = true
    end

    if not Monarch.Factions._PlayerDataAdded then
        net.Receive("Monarch_Faction_PlayerData", function()
            local hasFaction = net.ReadBool()
            if hasFaction then
                local faction = net.ReadTable()
                Monarch.Factions.PlayerFaction = faction

                if Monarch.Factions.OnRoleListUpdate then
                    Monarch.Factions.OnRoleListUpdate()
                end
            else
                Monarch.Factions.PlayerFaction = nil
            end
        end)
        Monarch.Factions._PlayerDataAdded = true
    end

    if not Monarch.Factions._FactionUpdatedAdded then
        net.Receive("Monarch_Faction_Updated", function()
            local faction = net.ReadTable()

            if Monarch.Factions.PlayerFaction and Monarch.Factions.PlayerFaction.id == faction.id then
                Monarch.Factions.PlayerFaction = faction

                if Monarch.Factions.OnRoleListUpdate then
                    Monarch.Factions.OnRoleListUpdate()
                end
            end
        end)
        Monarch.Factions._FactionUpdatedAdded = true
    end

    if not Monarch.Factions._InvitePromptAdded then
        net.Receive("Monarch_FactionInvite_Prompt", function()
            local inviteID = net.ReadString()
            local inviter = net.ReadEntity()
            local factionName = net.ReadString()
            local expiresIn = net.ReadUInt(8)

            local inviterName = IsValid(inviter) and (inviter.GetRPName and inviter:GetRPName() or inviter:Nick()) or "Unknown"

            local frame = UI_CreateFullscreenOverlay and UI_CreateFullscreenOverlay() or vgui.Create("DFrame")
            if not IsValid(frame) then return end

            frame:SetSize(620, 290)
            frame:Center()
            if frame.SetTitle then frame:SetTitle("") end
            if frame.ShowCloseButton then frame:ShowCloseButton(false) end
            if frame.SetDraggable then frame:SetDraggable(false) end
            if frame.MakePopup then frame:MakePopup() end

            if frame.Paint then
                local oldPaint = frame.Paint
                frame.Paint = function(s, w, h)
                    if oldPaint then oldPaint(s, w, h) end
                    draw.RoundedBox(0, 0, 0, w, h, Color(22, 22, 24, 245))
                    surface.SetDrawColor(80, 80, 80, 200)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end
            end

            local title = vgui.Create("DLabel", frame)
            title:SetText("Faction Invitation")
            title:SetFont("DinProLarge")
            title:SetTextColor(color_white)
            title:SetContentAlignment(5)
            title:Dock(TOP)
            title:DockMargin(0, 18, 0, 14)
            title:SetTall(36)

            local message = vgui.Create("DLabel", frame)
            message:SetFont("DinPro")
            message:SetTextColor(Color(220, 220, 220))
            message:SetContentAlignment(5)
            message:SetWrap(true)
            message:SetText(string.format("%s invited you to join '%s'.\nThis invite expires in %d seconds.", inviterName, factionName, expiresIn))
            message:SetSize(560, 90)
            message:SetPos(30, 85)

            local acceptBtn = vgui.Create("DButton", frame)
            acceptBtn:SetText("Accept")
            acceptBtn:SetFont("DinPro")
            acceptBtn:SetSize(190, 42)
            acceptBtn:SetPos(120, 220)
            acceptBtn:SetTextColor(color_white)
            acceptBtn.Paint = UI_PaintBasicDialogButton

            local declineBtn = vgui.Create("DButton", frame)
            declineBtn:SetText("Decline")
            declineBtn:SetFont("DinPro")
            declineBtn:SetSize(190, 42)
            declineBtn:SetPos(310, 220)
            declineBtn:SetTextColor(color_white)
            declineBtn.Paint = UI_PaintBasicDialogButton

            local responded = false
            local function sendResponse(accept)
                if responded then return end
                responded = true
                net.Start("Monarch_FactionInvite_Response")
                net.WriteString(inviteID)
                net.WriteBool(accept)
                net.SendToServer()
                if IsValid(frame) then frame:Close() end
            end

            acceptBtn.DoClick = function() sendResponse(true) end
            declineBtn.DoClick = function() sendResponse(false) end

            timer.Simple(expiresIn, function()
                if not IsValid(frame) or responded then return end
                sendResponse(false)
            end)
        end)
        Monarch.Factions._InvitePromptAdded = true
    end

    if not Monarch.Factions._InviteResultAdded then
        net.Receive("Monarch_FactionInvite_Result", function()
            local message = net.ReadString()
            local isError = net.ReadBool()
            local refreshFaction = net.ReadBool()

            ShowFactionNotification(message, isError)

            if refreshFaction then
                net.Start("Monarch_Faction_RequestPlayerFaction")
                net.SendToServer()
            end
        end)
        Monarch.Factions._InviteResultAdded = true
    end

    if not Monarch.Factions._SetMemberRoleResponseAdded then
        net.Receive("Monarch_Faction_SetMemberRoleResponse", function()
            local success = net.ReadBool()
            local message = net.ReadString()
            ShowFactionNotification(message ~= "" and message or (success and "Member role updated." or "Failed to update member role."), not success)

            if success then
                net.Start("Monarch_Faction_RequestPlayerFaction")
                net.SendToServer()
            end
        end)
        Monarch.Factions._SetMemberRoleResponseAdded = true
    end

    function Monarch.Factions.RequestList()
        net.Start("Monarch_Faction_RequestList")
        net.SendToServer()
    end

    function Monarch.Factions.RequestPlayerFaction()
        net.Start("Monarch_Faction_RequestPlayerFaction")
        net.SendToServer()
    end

    function Monarch.Factions.Create(name, founderRole, r, g, b, logoIndex)
        if not (isstring(name) and name ~= "") then
            ShowFactionNotification("Invalid faction name", true)
            return
        end

        net.Start("Monarch_Faction_Create")
        net.WriteString(name)
        net.WriteString(founderRole or "Founder")
        net.WriteUInt(math.Clamp(tonumber(r) or 100, 0, 255), 8)
        net.WriteUInt(math.Clamp(tonumber(g) or 100, 0, 255), 8)
        net.WriteUInt(math.Clamp(tonumber(b) or 100, 0, 255), 8)
        net.WriteUInt(math.Clamp(tonumber(logoIndex) or 1, 1, 17), 8)
        net.SendToServer()
    end

    function Monarch.Factions.Edit(factionID, field, value)
        if not (isnumber(factionID) and isstring(field)) then return end

        net.Start("Monarch_Faction_Edit")
        net.WriteUInt(factionID, 16)
        net.WriteString(field)

        if field == "name" then
            net.WriteString(value or "")
        elseif field == "color" then
            net.WriteUInt(math.Clamp(tonumber(value.r) or 100, 0, 255), 8)
            net.WriteUInt(math.Clamp(tonumber(value.g) or 100, 0, 255), 8)
            net.WriteUInt(math.Clamp(tonumber(value.b) or 100, 0, 255), 8)
        elseif field == "logoIndex" then
            net.WriteUInt(math.Clamp(tonumber(value) or 1, 1, 17), 8)
        end

        net.SendToServer()
    end

    function Monarch.Factions.Join(factionID)
        if not isnumber(factionID) then return end

        net.Start("Monarch_Faction_Join")
        net.WriteUInt(factionID, 16)
        net.SendToServer()
    end

    function Monarch.Factions.Leave()
        net.Start("Monarch_Faction_Leave")
        net.SendToServer()
    end

    function Monarch.Factions.SetMemberRole(memberKey, roleName)
        local key = tostring(memberKey or "")
        if key == "" then return end

        net.Start("Monarch_Faction_SetMemberRole")
        net.WriteString(key)
        net.WriteString(tostring(roleName or "Member"))
        net.SendToServer()
    end

    if not Monarch.Factions._AnnouncementReceiverAdded then
        net.Receive("Monarch_Faction_ShowAnnouncement", function()
            local factionName = net.ReadString()
            local factionLogoIndex = net.ReadUInt(8)
            local factionColor = Color(net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8))
            local senderName = net.ReadString()
            local message = net.ReadString()
            local timestamp = net.ReadString()

            local fadeIn, fadeOut = 0.2, 0.15

            local frame = vgui.Create("DFrame")
            frame:SetSize(ScrW(), ScrH())
            frame:Center()
            frame:SetTitle("")
            frame:ShowCloseButton(false)
            frame:SetDraggable(false)
            frame:SetBackgroundBlur(true)
            frame:SetDrawOnTop(true)
            frame:MakePopup()
            frame:SetDeleteOnClose(true)
            frame:SetAlpha(0)
            frame:AlphaTo(255, fadeIn, 0)
            frame.Paint = function(s, pw, ph)
                Derma_DrawBackgroundBlur(s)
            end

            local container = vgui.Create("DPanel", frame)
            container:SetSize(700, 600)
            container:Center()
            container:SetAlpha(0)
            container:AlphaTo(255, fadeIn, 0)
            container.Paint = function(s, w, h)
            end

            local logoSize = 150
            local logoPath = Config and Config.FactionIcons and Config.FactionIcons[factionLogoIndex] or "icons/player_factions/legacy/crew_crown.png"
            local logoMat = Material(logoPath, "smooth mips")

            local logo = vgui.Create("DPanel", container)
            logo:SetSize(logoSize, logoSize)
            logo:SetPos((container:GetWide() - logoSize) * 0.5, 40)
            logo.Paint = function(_, w, h)
                if logoMat and not logoMat:IsError() then
                    surface.SetMaterial(logoMat)
                    surface.SetDrawColor(factionColor.r, factionColor.g, factionColor.b, 255)
                    surface.DrawTexturedRect(0, 0, w, h)
                end
            end

            local factionNameLabel = vgui.Create("DLabel", container)
            factionNameLabel:SetFont("DinProLarge")
            factionNameLabel:SetTextColor(Color(factionColor.r, factionColor.g, factionColor.b, 255))
            factionNameLabel:SetText(factionName)
            factionNameLabel:SizeToContents()
            factionNameLabel:SetPos((container:GetWide() - factionNameLabel:GetWide()) * 0.5, 200)

            local timestampLabel = vgui.Create("DLabel", container)
            timestampLabel:SetFont("DinPro")
            timestampLabel:SetTextColor(Color(180, 180, 180))
            timestampLabel:SetText(timestamp)
            timestampLabel:SizeToContents()
            timestampLabel:SetPos((container:GetWide() - timestampLabel:GetWide()) * 0.5, 245)

            local fromLabel = vgui.Create("DLabel", container)
            fromLabel:SetFont("DinPro")
            fromLabel:SetTextColor(Color(200, 200, 200))
            fromLabel:SetText("New announcement from:")
            fromLabel:SizeToContents()
            fromLabel:SetPos((container:GetWide() - fromLabel:GetWide()) * 0.5, 290)

            local senderLabel = vgui.Create("DLabel", container)
            senderLabel:SetFont("DinProLarge")
            senderLabel:SetTextColor(color_white)
            senderLabel:SetText(senderName)
            senderLabel:SizeToContents()
            senderLabel:SetPos((container:GetWide() - senderLabel:GetWide()) * 0.5, 320)

            local function BuildCenteredWrapLines(text, font, maxWidth)
                surface.SetFont(font)

                local words = string.Explode(" ", tostring(text or ""), false)
                local lines = {}
                local current = ""

                for i = 1, #words do
                    local word = words[i]
                    local candidate = (current == "") and word or (current .. " " .. word)
                    local candidateW = surface.GetTextSize(candidate)

                    if candidateW <= maxWidth or current == "" then
                        current = candidate
                    else
                        lines[#lines + 1] = current
                        current = word
                    end
                end

                if current ~= "" then
                    lines[#lines + 1] = current
                end

                return lines
            end

            local messagePanel = vgui.Create("DPanel", container)
            messagePanel:SetPos((container:GetWide() - 600) * 0.5, 360)
            messagePanel:SetSize(600, 130)
            messagePanel:SetPaintBackground(false)

            local wrappedLines = BuildCenteredWrapLines("\"" .. message .. "\"", "DinPro", 600)
            messagePanel.Paint = function(_, w, h)
                local lineHeight = draw.GetFontHeight("DinPro") + 2
                local totalHeight = #wrappedLines * lineHeight
                local startY = math.max(0, (h - totalHeight) * 0.5)

                for i = 1, #wrappedLines do
                    draw.SimpleText(wrappedLines[i], "DinPro", w * 0.5, startY + ((i - 1) * lineHeight), Color(220, 220, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                end
            end

            local closeBtn
            local divider

            local function fadeOutAndRemove()
                if not IsValid(frame) then return end
                if IsValid(container) then container:AlphaTo(0, fadeOut, 0) end
                if IsValid(divider) then divider:AlphaTo(0, fadeOut, 0) end
                if IsValid(closeBtn) then closeBtn:AlphaTo(0, fadeOut, 0) end
                frame:AlphaTo(0, fadeOut + 0.05, 0, function()
                    if IsValid(frame) then frame:Close() end
                end)
            end

            divider = vgui.Create("DPanel", frame)
            divider:SetSize(ScrW(), 2)
            divider:SetPos(0, ScrH() - 110)
            divider:SetAlpha(0)
            divider:AlphaTo(255, fadeIn, 0)
            divider.Paint = function(s, w, h)
                local gradientStart = 50
                local gradientEnd = w - 50

                for x = 0, w - 1 do
                    local alpha = 100
                    if x < gradientStart then
                        alpha = math.floor((x / gradientStart) * 100)
                    elseif x > gradientEnd then
                        alpha = math.floor(((w - x) / gradientStart) * 100)
                    end

                    surface.SetDrawColor(80, 80, 80, alpha)
                    surface.DrawRect(x, 0, 1, h)
                end
            end

            closeBtn = vgui.Create("DButton", frame)
            closeBtn:SetText("CLOSE X")
            closeBtn:SetFont("DinPro")
            closeBtn:SetTextColor(Color(200, 200, 200))
            closeBtn:SetSize(240, 44)
            closeBtn:SetPos((ScrW() - 240) / 2, ScrH() - 55)
            closeBtn:SetAlpha(0)
            closeBtn:AlphaTo(255, fadeIn, 0)
            closeBtn.Paint = function(s, w, h)
                local bgColor = s:IsHovered() and Color(40, 40, 40, 220) or Color(30, 30, 30, 190)
                surface.SetDrawColor(bgColor)
                surface.DrawRect(0, 0, w, h)

                surface.SetDrawColor(s:IsHovered() and Color(160, 160, 160) or Color(110, 110, 110))
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            closeBtn.DoClick = fadeOutAndRemove

            frame.OnKeyCodePressed = function(_, key)
                if key == KEY_ESCAPE then
                    fadeOutAndRemove()
                end
            end
        end)
        Monarch.Factions._AnnouncementReceiverAdded = true
    end
end

