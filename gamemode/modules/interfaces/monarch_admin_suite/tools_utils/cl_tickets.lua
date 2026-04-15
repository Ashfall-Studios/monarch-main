return function(ctx)
    local frame = ctx.frame
    local right = ctx.right
    local StyledButton = ctx.StyledButton
    local PanelControlButton = ctx.PanelControlButton
    local GetPalette = ctx.GetPalette
    local RoundedOutlinedBox = ctx.RoundedOutlinedBox
    local SetBreadcrumb = ctx.SetBreadcrumb
    local ClearRight = ctx.ClearRight
    local OpenCreateTicket = ctx.OpenCreateTicket
    local BuildTicketsView, BuildToolsView, BuildCustomToolsView, BuildPlayersView, BuildCharsView, BuildStaffView

    local function DrawModernPanel(P, radius, x, y, w, h, fill, outline, borderW)
        if isfunction(RoundedOutlinedBox) then
            RoundedOutlinedBox(radius, x, y, w, h, fill, outline, borderW)
            return
        end
        borderW = borderW or 1
        draw.RoundedBox(radius, x, y, w, h, outline)
        draw.RoundedBox(math.max(0, radius - borderW), x + borderW, y + borderW, w - (borderW * 2), h - (borderW * 2), fill)
    end

    BuildTicketsView = function()
        if isfunction(SetBreadcrumb) then
            SetBreadcrumb({ "Admin Hub", "Tickets" })
        end
        ClearRight()
        local container = vgui.Create("DPanel", right)
        container:Dock(FILL)
        container.Paint = nil

        local notifDivider = vgui.Create("DPanel", container)
        notifDivider:Dock(RIGHT)
        notifDivider:SetWide(6)
        notifDivider.Paint = function(self, pw, ph)
            local P = GetPalette()
            DrawModernPanel(P, (P.radius or 6), 0, 0, pw, ph, P.divider, P.outline, 1)
        end
        local notifWrap = vgui.Create("DPanel", container)
        notifWrap:Dock(RIGHT)
        notifWrap:SetWide(260)
        notifWrap.Paint = function(self, pw, ph)
            local P = GetPalette()
            DrawModernPanel(P, (P.radius or 6), 0, 0, pw, ph, P.panel, P.outline, 1)
        end

        local contentWrap = vgui.Create("DPanel", container)
        contentWrap:Dock(FILL)
        contentWrap.Paint = nil

        local listWrap = vgui.Create("DPanel", contentWrap)
        listWrap:Dock(FILL)
        listWrap.Paint = nil

        local listTop = vgui.Create("DPanel", listWrap)
        listTop:Dock(TOP)
        listTop:SetTall(34)
        listTop:DockMargin(6, 6, 6, 6)
        listTop.Paint = function(self, w, h)
            local P = GetPalette()
            surface.SetDrawColor(P.panel)
            surface.DrawRect(0, 0, w, h)
        end
        local plusBtn = StyledButton(listTop, "+ New")
        plusBtn:Dock(RIGHT)
        plusBtn:SetWide(90)
        plusBtn:DockMargin(6,4,6,4)
        plusBtn.DoClick = function() OpenCreateTicket() end

        local listScroller = vgui.Create("DHorizontalScroller", listWrap)
        listScroller:Dock(FILL)
        listScroller:DockMargin(6, 0, 6, 6)
        listScroller:SetOverlap(-8)

        local columns = {}
        local function CreateColumn()
            local colW = math.max(360, math.floor((listWrap:GetWide()-24) * 0.33))
            local col = vgui.Create("DPanel")
            col:SetWide(colW)
            col.Paint = nil
            function col:Think()
                local h = listWrap:GetTall() - 8
                if h < 200 then h = 200 end
                if self:GetTall() ~= h then self:SetTall(h) end
            end
            local colLayout = vgui.Create("DIconLayout", col)
            colLayout:Dock(FILL)
            colLayout:SetSpaceY(8)
            colLayout:SetSpaceX(0)
            col._layout = colLayout
            col._count = 0
            listScroller:AddPanel(col)
            return col
        end
        local function GetActiveColumn()
            local last = columns[#columns]
            if not IsValid(last) or (last._count or 0) >= 5 then
                last = CreateColumn()
                table.insert(columns, last)
            end
            return last
        end

        local chatWrap = vgui.Create("DPanel", contentWrap)
        chatWrap:Dock(FILL)
        chatWrap:SetVisible(false)
        chatWrap.Paint = nil
        local actionRow = vgui.Create("DPanel", chatWrap)
        actionRow:Dock(TOP)
        actionRow:SetTall(42)
        actionRow:DockMargin(0,0,0,6)
        actionRow:SetVisible(false)
        actionRow.Paint = function(self, pw, ph)
            local P = GetPalette()
            DrawModernPanel(P, (P.radius or 6), 0, 0, pw, ph, P.panel, P.outline, 1)
        end
        local chatScroll = vgui.Create("DScrollPanel", chatWrap)
        chatScroll:Dock(FILL)

        local statsWrap = vgui.Create("DPanel", chatWrap)
        statsWrap:Dock(RIGHT)
        local statsPanelW = 270
        statsWrap:SetWide(statsPanelW)
        statsWrap:DockMargin(10, 0, 0, 0)
        statsWrap.Paint = function(self, pw, ph)
            local P = GetPalette()
            DrawModernPanel(P, (P.radius or 6), 0, 0, pw, ph, Color(34, 34, 36, 246), Color(60, 60, 64), 1)
        end
        local function RefreshStatsLayout()
            if not IsValid(chatWrap) or not IsValid(statsWrap) or not IsValid(chatScroll) then return end
            local dynamicW = math.Clamp(math.floor(chatWrap:GetWide() * 0.3), 220, 270)
            statsPanelW = dynamicW
            statsWrap:SetWide(dynamicW)
            chatScroll:DockMargin(8, 8, dynamicW + 18, 8)
            statsWrap:MoveToFront()
        end
        chatWrap.OnSizeChanged = function()
            RefreshStatsLayout()
        end
        timer.Simple(0, function()
            if IsValid(chatWrap) then
                RefreshStatsLayout()
            end
        end)

        local statsBody = vgui.Create("DPanel", statsWrap)
        statsBody:Dock(FILL)
        statsBody:DockMargin(12, 12, 12, 12)
        statsBody.Paint = nil

        local statsTitle = vgui.Create("DLabel", statsBody)
        statsTitle:Dock(TOP)
        statsTitle:SetTall(28)
        statsTitle:SetFont("InvMed")
        statsTitle:SetTextColor(GetPalette().text)
        statsTitle:SetText("TICKET INFO")

        local function CreateStatRow(parent, labelText)
            local row = vgui.Create("DPanel", parent)
            row:Dock(TOP)
            row:SetTall(58)
            row:DockMargin(0, 0, 0, 10)
            row.Paint = function(self, pw, ph)
                local P = GetPalette()
                DrawModernPanel(P, (P.radius or 6), 0, 0, pw, ph, Color(40, 40, 42, 235), Color(66, 66, 70), 1)
            end

            local lbl = vgui.Create("DLabel", row)
            lbl:Dock(TOP)
            lbl:DockMargin(10, 7, 10, 0)
            lbl:SetTall(18)
            lbl:SetFont("InvMed")
            lbl:SetTextColor(GetPalette().textMuted or Color(185, 188, 194))
            lbl:SetText(string.upper(labelText or ""))

            local val = vgui.Create("DLabel", row)
            val:Dock(BOTTOM)
            val:DockMargin(10, 0, 10, 8)
            val:SetTall(18)
            val:SetFont("InvSmall")
            val:SetTextColor(GetPalette().text)
            val:SetText("-")
            return val
        end

        local statCreated = CreateStatRow(statsBody, "Created")
        local statUpdated = CreateStatRow(statsBody, "Last Updated")
        local statStatus = CreateStatRow(statsBody, "Status")

        local agentCard = vgui.Create("DPanel", statsBody)
        agentCard:Dock(TOP)
        agentCard:SetTall(92)
        agentCard:DockMargin(0, 0, 0, 10)
        agentCard.Paint = function(self, pw, ph)
            local P = GetPalette()
            DrawModernPanel(P, (P.radius or 6), 0, 0, pw, ph, Color(40, 40, 42, 235), Color(66, 66, 70), 1)
        end

        local agentTitle = vgui.Create("DLabel", agentCard)
        agentTitle:Dock(TOP)
        agentTitle:DockMargin(10, 7, 10, 0)
        agentTitle:SetTall(18)
        agentTitle:SetFont("InvMed")
        agentTitle:SetTextColor(GetPalette().textMuted or Color(185, 188, 194))
        agentTitle:SetText("AGENT")

        local agentBody = vgui.Create("DPanel", agentCard)
        agentBody:Dock(FILL)
        agentBody:DockMargin(10, 4, 10, 10)
        agentBody.Paint = nil

        local agentAvatarWrap = vgui.Create("DPanel", agentBody)
        agentAvatarWrap:Dock(LEFT)
        agentAvatarWrap:SetWide(56)
        agentAvatarWrap:DockMargin(0, 0, 8, 0)

        local agentAvatar = vgui.Create("AvatarImage", agentAvatarWrap)
        agentAvatar:SetPaintedManually(true)

        local avatarPad = 3
        agentAvatarWrap.OnSizeChanged = function(self, pw, ph)
            agentAvatar:SetPos(avatarPad, avatarPad)
            agentAvatar:SetSize(math.max(0, pw - (avatarPad * 2)), math.max(0, ph - (avatarPad * 2)))
        end
        agentAvatarWrap.Paint = function(self, pw, ph)
            local P = GetPalette()
            DrawModernPanel(P, (P.radius or 6), 0, 0, pw, ph, Color(50, 50, 52, 235), Color(74, 74, 78), 1)

            render.ClearStencil()
            render.SetStencilEnable(true)
            render.SetStencilWriteMask(1)
            render.SetStencilTestMask(1)
            render.SetStencilReferenceValue(1)
            render.SetStencilCompareFunction(STENCIL_ALWAYS)
            render.SetStencilPassOperation(STENCIL_REPLACE)
            render.SetStencilFailOperation(STENCIL_KEEP)
            render.SetStencilZFailOperation(STENCIL_KEEP)

            draw.RoundedBox(math.max(2, (P.radius or 6) - 1), avatarPad, avatarPad, pw - (avatarPad * 2), ph - (avatarPad * 2), color_white)

            render.SetStencilCompareFunction(STENCIL_EQUAL)
            render.SetStencilPassOperation(STENCIL_KEEP)
            agentAvatar:PaintManual()
            render.SetStencilEnable(false)
        end

        local agentRight = vgui.Create("DPanel", agentBody)
        agentRight:Dock(FILL)
        agentRight:DockMargin(0, 0, 0, 0)
        agentRight.Paint = nil

        local agentName = vgui.Create("DLabel", agentRight)
        agentName:Dock(FILL)
        agentName:SetFont("InvMed")
        agentName:SetTextColor(GetPalette().text)
        agentName:SetContentAlignment(4)
        agentName:SetText("Unassigned")

        local participantsCard = vgui.Create("DPanel", statsBody)
        participantsCard:Dock(FILL)
        participantsCard:DockMargin(0, 10, 0, 0)
        participantsCard.Paint = function(self, pw, ph)
            local P = GetPalette()
            DrawModernPanel(P, (P.radius or 6), 0, 0, pw, ph, Color(40, 40, 42, 235), Color(66, 66, 70), 1)
        end

        local participantsBody = vgui.Create("DPanel", participantsCard)
        participantsBody:Dock(FILL)
        participantsBody:DockMargin(10, 8, 10, 10)
        participantsBody.Paint = nil

        local participantsHdr = vgui.Create("DPanel", participantsBody)
        participantsHdr:Dock(TOP)
        participantsHdr:SetTall(34)
        participantsHdr:DockMargin(0, 0, 0, 8)
        participantsHdr.Paint = nil

        local participantsTitle = vgui.Create("DLabel", participantsHdr)
        participantsTitle:SetFont("InvMed")
        participantsTitle:SetTextColor(GetPalette().text)
        participantsTitle:SetText("PARTICIPANTS")

        local participantsAddBtn = StyledButton(participantsHdr, "+")
        participantsAddBtn:SetSize(28, 28)
        participantsAddBtn.Paint = function(self, pw, ph)
            local P = GetPalette()
            local bg = P.btn
            if self:GetDisabled() then
                bg = Color(bg.r, bg.g, bg.b, 120)
            elseif self.Depressed or self:IsDown() or self.Selected then
                bg = P.primary
            elseif self.Hovered then
                bg = P.btnHover
            end
            DrawModernPanel(P, P.radius or 6, 0, 0, pw, ph, bg, P.outline, 1)
            draw.SimpleText("+", "InvMed", math.floor(pw * 0.5), math.floor(ph * 0.5), P.btnText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        participantsHdr.PerformLayout = function(self, pw, ph)
            participantsAddBtn:SetPos(math.max(0, pw - 28), math.floor((ph - 28) * 0.5))
            participantsTitle:SetPos(0, 0)
            participantsTitle:SetSize(math.max(0, pw - 36), ph)
        end

        local participantsList = vgui.Create("DScrollPanel", participantsBody)
        participantsList:Dock(FILL)
        participantsList:DockMargin(0, 0, 0, 0)
        local pbar = participantsList:GetVBar()
        pbar.Paint = function(s, pw, ph)
            local P = GetPalette()
            surface.SetDrawColor(P.scrollTrack) surface.DrawRect(0,0,pw,ph)
        end
        pbar.btnUp.Paint = function(s, pw, ph)
            local P = GetPalette()
            surface.SetDrawColor(P.btn) surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.outline) surface.DrawOutlinedRect(0,0,pw,ph,1)
        end
        pbar.btnDown.Paint = pbar.btnUp.Paint
        pbar.btnGrip.Paint = function(s, pw, ph)
            local P = GetPalette()
            local clr = s.Hovered and P.scrollGripHover or P.scrollGrip
            surface.SetDrawColor(clr) surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.outline) surface.DrawOutlinedRect(0,0,pw,ph,1)
        end

        local cvbar = chatScroll:GetVBar()
        cvbar.Paint = function(s, pw, ph)
            local P = GetPalette()
            surface.SetDrawColor(P.scrollTrack) surface.DrawRect(0,0,pw,ph)
        end
        cvbar.btnUp.Paint = function(s, pw, ph)
            local P = GetPalette()
            surface.SetDrawColor(P.btn) surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.outline) surface.DrawOutlinedRect(0,0,pw,ph,1)
        end
        cvbar.btnDown.Paint = cvbar.btnUp.Paint
        cvbar.btnGrip.Paint = function(s, pw, ph)
            local P = GetPalette()
            local clr = s.Hovered and P.scrollGripHover or P.scrollGrip
            surface.SetDrawColor(clr) surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.outline) surface.DrawOutlinedRect(0,0,pw,ph,1)
        end
        local inputRow = vgui.Create("DPanel", chatWrap)
        inputRow:Dock(BOTTOM)
        inputRow:SetTall(28)
        inputRow:SetVisible(false)
        inputRow.Paint = function(self, pw, ph)
            local P = GetPalette()
            DrawModernPanel(P, (P.radius or 6), 0, 0, pw, ph, P.panel, P.outline, 1)
        end
        local entry = vgui.Create("DTextEntry", inputRow)
        entry:Dock(FILL)
        entry:SetFont("InvSmall")
        entry:SetPlaceholderText("Select a ticket to reply...")
        entry:SetTextColor(Color(230,230,230))
        entry:SetDrawLanguageID(false)
        entry.Paint = function(self, pw, ph)
            local P = GetPalette()
            DrawModernPanel(P, (P.radius or 6), 0, 0, pw, ph, P.inputBg, P.inputBorder, 1)
            self:DrawTextEntryText(P.inputText, P.selection, P.inputText)

            local MAXLEN = 75
            local txt = tostring(self:GetValue() or "")
            local counter = string.format("%d/%d", math.min(#txt, MAXLEN), MAXLEN)
            surface.SetFont("InvSmall")
            local tw, th = surface.GetTextSize(counter)
            surface.SetTextColor(200,200,200,180)
            surface.SetTextPos(pw - tw - 6, ph - th - 2)
            surface.DrawText(counter)
        end

        do
            local MAXLEN = 75
            entry._maxLen = MAXLEN
            entry:SetUpdateOnType(true)
            function entry:AllowInput(ch)
                local v = self:GetValue() or ""
                if self.GetSelectedText and self:GetSelectedText() ~= "" then return false end
                if #v >= (self._maxLen or MAXLEN) then return true end
                return false
            end
            function entry:OnTextChanged()
                if self._squelch then return end
                local v = self:GetValue() or ""
                local maxl = self._maxLen or MAXLEN
                if #v > maxl then
                    local caret = self:GetCaretPos()
                    self._squelch = true
                    self:SetText(string.sub(v, 1, maxl))
                    self:SetCaretPos(math.min(caret, maxl))
                    self._squelch = false
                end
            end
        end

        local state = {
            currentId = nil,
            ticketsCache = {},
            emptyLabel = nil,
            listScroller = listScroller,
            listWrap = listWrap,
            columns = columns,
            actionRow = actionRow,
            chatWrap = chatWrap,
            chatScroll = chatScroll,
            inputRow = inputRow,
            entry = entry,
            notifWrap = notifWrap,
            notifItems = {},
            statsWrap = statsWrap,
            statCreated = statCreated,
            statUpdated = statUpdated,
            statStatus = statStatus,
            participantsList = participantsList,
            participantsAddBtn = participantsAddBtn,
            agentAvatar = agentAvatar,
            agentName = agentName,
        }
        state.plusBtn = plusBtn

        local function FormatAgo(ts)
            ts = tonumber(ts or 0) or 0
            if ts <= 0 then return "-" end
            local delta = math.max(0, os.time() - ts)
            if delta < 60 then
                return string.format("%d seconds ago", delta)
            elseif delta < 3600 then
                return string.format("%d minutes ago", math.floor(delta / 60))
            elseif delta < 86400 then
                return string.format("%d hours ago", math.floor(delta / 3600))
            end
            return string.format("%d days ago", math.floor(delta / 86400))
        end

        local function GetLastUpdateTS(t)
            if not istable(t) then return os.time() end
            local last = tonumber(t.updated or 0) or 0
            last = math.max(last, tonumber(t.created or 0) or 0)
            last = math.max(last, tonumber(t.claimed or 0) or 0)
            last = math.max(last, tonumber(t.closed or 0) or 0)
            for _, m in ipairs(t.messages or {}) do
                last = math.max(last, tonumber(m.time or 0) or 0)
            end
            if last <= 0 then last = os.time() end
            return last
        end

        local function ResolveNameFromSID(ticket, sid64)
            sid64 = tostring(sid64 or "")
            if sid64 == "" then return "Unknown" end
            local ply = player.GetBySteamID64(sid64)
            if IsValid(ply) then return tostring(ply:Nick() or sid64) end
            if tostring(ticket.reporter or "") == sid64 then
                return tostring(ticket.reporterName or sid64)
            end
            if tostring(ticket.claimedBy or "") == sid64 then
                return tostring(ticket.claimedByName or sid64)
            end
            for _, m in ipairs(ticket.messages or {}) do
                if tostring(m.sid or "") == sid64 and tostring(m.name or "") ~= "" then
                    return tostring(m.name)
                end
            end
            return sid64
        end

        local function AddParticipantRow(ticket, label, sid64, canRemove)
            local row = vgui.Create("DPanel", state.participantsList)
            row:Dock(TOP)
            row:SetTall(28)
            row:DockMargin(0, 0, 0, 4)
            row.Paint = function(self, pw, ph)
                local P = GetPalette()
                DrawModernPanel(P, (P.radius or 6), 0, 0, pw, ph, Color(52, 52, 54, 225), Color(76, 76, 80), 1)
            end

            local txt = vgui.Create("DLabel", row)
            txt:Dock(FILL)
            txt:DockMargin(8, 0, 8, 0)
            txt:SetFont("InvSmall")
            txt:SetTextColor(GetPalette().text)
            txt:SetText(label .. ": " .. ResolveNameFromSID(ticket, sid64))

            if canRemove then
                local removeBtn = vgui.Create("DButton", row)
                removeBtn:Dock(RIGHT)
                removeBtn:SetWide(26)
                removeBtn:SetText("")
                removeBtn:DockMargin(0, 2, 2, 2)
                removeBtn.Paint = function(self, pw, ph)
                    local P = GetPalette()
                    local bg = self:IsHovered() and Color(172, 68, 68) or Color(140, 58, 58)
                    DrawModernPanel(P, (P.radius or 6), 0, 0, pw, ph, bg, Color(192, 92, 92), 1)
                    draw.SimpleText("×", "InvSmall", pw * 0.5, ph * 0.5, Color(245, 245, 245), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                removeBtn.DoClick = function()
                    net.Start("Monarch_Tickets_Action")
                        net.WriteUInt(ticket.id, 16)
                        net.WriteString("remove_participant")
                        net.WriteString(tostring(sid64 or ""))
                    net.SendToServer()
                    timer.Simple(0, function()
                        if not IsValid(frame) then return end
                        net.Start("Monarch_Tickets_RequestList")
                        net.SendToServer()
                    end)
                end
            end
        end

        function state:RefreshTicketStats(ticket)
            if not istable(ticket) then return end

            self._statsCreatedTS = tonumber(ticket.created or GetCreatedTS(ticket)) or os.time()
            self._statsUpdatedTS = tonumber(GetLastUpdateTS(ticket)) or os.time()
            self._statsTicketId = ticket.id

            self.statCreated:SetText(FormatAgo(self._statsCreatedTS))
            self.statUpdated:SetText(FormatAgo(self._statsUpdatedTS))
            self.statStatus:SetText(string.upper(tostring(ticket.status or "open")))

            if tostring(ticket.claimedBy or "") ~= "" then
                self.agentName:SetText(ResolveNameFromSID(ticket, ticket.claimedBy))
                if self.agentAvatar.SetSteamID then
                    self.agentAvatar:SetSteamID(tostring(ticket.claimedBy), 64)
                end
            else
                self.agentName:SetText("Unassigned")
                if self.agentAvatar.SetSteamID then
                    self.agentAvatar:SetSteamID("0", 64)
                end
            end

            self.participantsList:Clear()
            AddParticipantRow(ticket, "Reporter", ticket.reporter, false)
            if tostring(ticket.claimedBy or "") ~= "" then
                AddParticipantRow(ticket, "Agent", ticket.claimedBy, false)
            end
            for _, sid in ipairs(ticket.participants or {}) do
                AddParticipantRow(ticket, "Participant", sid, true)
            end
        end

        statsWrap._lastStatTick = 0
        statsWrap.Think = function(self)
            local tick = os.time()
            if self._lastStatTick ~= tick then
                self._lastStatTick = tick
                if state._statsCreatedTS then
                    state.statCreated:SetText(FormatAgo(state._statsCreatedTS))
                end
                if state._statsUpdatedTS then
                    state.statUpdated:SetText(FormatAgo(state._statsUpdatedTS))
                end
            end
        end

        local function GetTicketById(id)
            if not id then return nil end
            for _, t in ipairs(state.ticketsCache or {}) do if t.id == id then return t end end
            return nil
        end

        state.participantsAddBtn.DoClick = function()
            if not state.currentId then return end
            local tk = GetTicketById(state.currentId)
            if not tk then return end

            local existing = {}
            existing[tostring(tk.reporter or "")] = true
            existing[tostring(tk.claimedBy or "")] = true
            for _, sid in ipairs(tk.participants or {}) do
                existing[tostring(sid or "")] = true
            end

            local menu = DermaMenu()
            local options = 0
            for _, ply in ipairs(player.GetAll()) do
                if IsValid(ply) then
                    local sid = tostring(ply:SteamID64() or "")
                    if sid ~= "" and not existing[sid] then
                        options = options + 1
                        local label = string.format("%s (%s)", tostring(ply:Nick() or sid), sid)
                        menu:AddOption(label, function()
                            net.Start("Monarch_Tickets_Action")
                                net.WriteUInt(tk.id, 16)
                                net.WriteString("add_participant")
                                net.WriteString(sid)
                            net.SendToServer()
                            timer.Simple(0, function()
                                if not IsValid(frame) then return end
                                net.Start("Monarch_Tickets_RequestList")
                                net.SendToServer()
                            end)
                        end)
                    end
                end
            end
            if options == 0 then
                local opt = menu:AddOption("No available players")
                if IsValid(opt) then opt:SetEnabled(false) end
            end
            menu:Open()
        end
        local function SendActionCurrent(act)
            if not state.currentId then return end
            net.Start("Monarch_Tickets_Action") net.WriteUInt(state.currentId, 16) net.WriteString(act) net.SendToServer()
        end
        local function RemoveTicketRowById(id)
            if not state.columns then return end
            local targetRow, targetCol
            for _, col in ipairs(state.columns) do
                if IsValid(col) and IsValid(col._layout) then
                    for _, child in ipairs(col._layout:GetChildren() or {}) do
                        if IsValid(child) and child.ticketId == id then targetRow = child targetCol = col break end
                    end
                end
                if targetRow then break end
            end
            if not IsValid(targetRow) then return end
            if state.currentId == id then
                state.currentId = nil
                state.forceChatOpenId = nil
                state.chatScroll:Clear()
                state.inputRow:SetVisible(false)
                state.actionRow:SetVisible(false)
            end
            targetRow:SetMouseInputEnabled(false)
            targetRow:SetKeyboardInputEnabled(false)
            local function afterRemove()
                if IsValid(targetCol) then targetCol._count = math.max(0, (targetCol._count or 1) - 1) end
                local anyLeft = false
                for _, c in ipairs(state.columns or {}) do
                    if IsValid(c) and IsValid(c._layout) then
                        for _, ch in ipairs(c._layout:GetChildren() or {}) do if IsValid(ch) and ch ~= targetRow then anyLeft = true break end end
                    end
                    if anyLeft then break end
                end
                if not anyLeft then
                    if IsValid(state.emptyLabel) then state.emptyLabel:Remove() end
                    state.emptyLabel = vgui.Create("DLabel", state.listWrap)
                    state.emptyLabel:Dock(FILL)
                    state.emptyLabel:SetText("No available tickets")
                    state.emptyLabel:SetFont("InvMed")
                    state.emptyLabel:SetTextColor(Color(220,220,220))
                    state.emptyLabel:SetContentAlignment(5)
                end
            end
            if targetRow.AlphaTo then targetRow:AlphaTo(0, 0.15, 0, function() if IsValid(targetRow) then targetRow:Remove() end afterRemove() end) else if IsValid(targetRow) then targetRow:Remove() end afterRemove() end
        end
        local function FormatAge(sec)
            if sec < 0 then sec = 0 end
            if sec < 60 then return string.format("%ds", sec) end
            local m = math.floor(sec / 60) local s = sec % 60
            if m < 60 then return string.format("%dm %ds", m, s) end
            local h = math.floor(m / 60) m = m % 60
            if h < 24 then return string.format("%dh %dm", h, m) end
            local d = math.floor(h / 24) h = h % 24
            return string.format("%dd %dh", d, h)
        end
        local function GetCreatedTS(t)
            if t.created then return tonumber(t.created) or os.time() end
            if t.messages and #t.messages > 0 then
                local earliest
                for _, m in ipairs(t.messages) do local mt = tonumber(m.time) if mt and (not earliest or mt < earliest) then earliest = mt end end
                if earliest then return earliest end
            end
            return os.time()
        end
        local function GetStatusMeta(status)
            local key = string.lower(status or "open")
            if key == "claimed" then
                return "CLAIMED", Color(86, 164, 118), Color(40, 78, 58)
            elseif key == "closed" then
                return "CLOSED", Color(132, 140, 150), Color(56, 60, 66)
            end
            return "OPEN", Color(214, 170, 86), Color(88, 68, 34)
        end
        local function GetTicketSummary(t)
            local text = t.description or t.text or t.message or ""
            if text == "" and istable(t.messages) and t.messages[1] and t.messages[1].text then
                text = tostring(t.messages[1].text)
            end
            text = string.Trim(tostring(text or ""))
            if #text > 155 then
                text = string.sub(text, 1, 152) .. "..."
            end
            return text
        end
        local function PopulateChat(t)
            state.chatScroll:Clear()
            state:RefreshTicketStats(t)
            if not t or not t.messages then return end
            for _, m in ipairs(t.messages) do
                local reporterSID = tostring(t.reporter or t.reporterId or "")
                local handlerSID = tostring(t.claimedBy or t.claimedById or "")
                local msgSID = tostring(m.sid or "")
                local msgOrigin = string.lower(tostring(m.origin or m.source or ""))
                local isReportMsg
                if msgOrigin == "report" then
                    isReportMsg = true
                elseif msgOrigin == "admin" then
                    isReportMsg = false
                else
                    local msgRole = string.lower(tostring(m.role or ""))
                    if msgRole == "player" then
                        isReportMsg = true
                    elseif msgRole == "staff" then
                        isReportMsg = false
                    elseif msgSID == "" then
                        isReportMsg = true
                    else
                        isReportMsg = (msgSID == reporterSID)
                    end
                end
                local isCreator = (msgSID ~= "" and msgSID == reporterSID)
                local isHandler = (msgSID ~= "" and handlerSID ~= "" and msgSID == handlerSID)
                local holder = vgui.Create("DPanel", state.chatScroll)
                holder:Dock(TOP)
                holder:DockMargin(0,0,0,6)
                holder:SetTall(48)
                holder.Paint = nil
                local row = vgui.Create("DPanel", holder)
                row:Dock(FILL)
                row:DockMargin(8, 0, 8, 0)
                row.Paint = function(self, pw, ph)
                    local P = GetPalette()
                    local bg = isReportMsg and Color(48, 132, 72) or Color(54, 98, 176)
                    local border = isReportMsg and Color(62, 156, 92) or Color(74, 124, 206)
                    local radius = (P.radius or 6) + 2
                    DrawModernPanel(P, radius, 0, 0, pw, ph, bg, border, 1)

                    local who = m.name or (isHandler and "Handler" or (isCreator and "Creator" or "Player"))
                    local when = os.date("%I:%M %p", tonumber(m.time or os.time()))
                    draw.SimpleText(who .. " - " .. when, "InvSmall", 8, 9, Color(244,246,250), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                local text = vgui.Create("DLabel", row)
                text:Dock(FILL)
                text:DockMargin(8, 22, 8, 8)
                text:SetFont("InvSmall")
                text:SetTextColor(Color(248,250,252))
                text:SetWrap(true)
                text:SetAutoStretchVertical(true)
                text:SetText(tostring(m.text or ""))
            end
        end
        local function PopulateList(payload)
            for _, col in ipairs(columns) do if IsValid(col) then col:Remove() end end
            table.Empty(columns)
            if IsValid(state.emptyLabel) then state.emptyLabel:Remove() state.emptyLabel=nil end
            state.ticketsCache = payload or {}
            local count = 0
            for _, t in ipairs(state.ticketsCache) do
                local status = string.lower(t.status or "")
                local isClosed = (status == "closed") or (t.closed == true)
                if not isClosed then
                    count = count + 1
                    local col = GetActiveColumn()
                    local row = col._layout:Add("DPanel")
                    row:SetTall(154)
                    row:SetWide(col:GetWide() - 8)
                    row.ticketId = t.id
                    col._count = (col._count or 0) + 1
                    row.Think = nil
                    row.Paint = nil
                    local card = vgui.Create("DPanel", row)
                    card:Dock(FILL)
                    card:DockMargin(8,0,8,0)
                    card.Paint = function(self, pw, ph)
                        local P = GetPalette()
                        local _, accent, accentSoft = GetStatusMeta(t.status)
                        local fill = Color(43, 46, 51, 236)
                        local border = (state.currentId == t.id) and accent or P.outline
                        DrawModernPanel(P, (P.radius or 6) + 2, 0, 0, pw, ph, fill, border, 2)
                        draw.RoundedBoxEx((P.radius or 6) + 1, 0, 0, pw, 4, accentSoft, true, true, false, false)
                    end
                    local createdTS = GetCreatedTS(t)
                    local function composeAge()
                        return FormatAge(os.time() - createdTS) .. " ago"
                    end
                    local btnStrip = vgui.Create("DPanel", card)
                    btnStrip:Dock(RIGHT)
                    btnStrip:SetWide(108)
                    btnStrip:DockMargin(0,12,12,12)
                    btnStrip.Paint = nil
                    local content = vgui.Create("DPanel", card)
                    content:Dock(FILL)
                    content:DockMargin(14,12,10,12)
                    content.Paint = nil

                    local statusText, accentColor, accentSoft = GetStatusMeta(t.status)

                    local header = vgui.Create("DPanel", content)
                    header:Dock(TOP)
                    header:SetTall(62)
                    header.Paint = nil
                    header:SetMouseInputEnabled(false)

                    local topRow = vgui.Create("DPanel", header)
                    topRow:Dock(TOP)
                    topRow:SetTall(24)
                    topRow.Paint = nil
                    topRow:SetMouseInputEnabled(false)

                    local agePill = vgui.Create("DPanel", topRow)
                    agePill:Dock(RIGHT)
                    agePill:SetWide(86)
                    agePill:DockMargin(8, 0, 0, 0)
                    agePill.Paint = function(self, pw, ph)
                        local P = GetPalette()
                        DrawModernPanel(P, P.radius or 6, 0, 2, pw, ph - 4, Color(49, 53, 59), Color(74, 80, 90), 1)
                        draw.SimpleText(composeAge(), "InvSmall", pw * 0.5, ph * 0.5, P.textMuted or Color(180, 184, 192), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                    agePill:SetMouseInputEnabled(false)

                    local titleLabel = vgui.Create("DLabel", topRow)
                    titleLabel:Dock(LEFT)
                    titleLabel:SetWide(140)
                    titleLabel:SetFont("InvMed")
                    titleLabel:SetTextColor(GetPalette().text)
                    titleLabel:SetText("Ticket #" .. tostring(t.id or "?"))
                    titleLabel:SetMouseInputEnabled(false)

                    local metaRow = vgui.Create("DPanel", header)
                    metaRow:Dock(TOP)
                    metaRow:DockMargin(0, 6, 0, 0)
                    metaRow:SetTall(22)
                    metaRow.Paint = nil
                    metaRow:SetMouseInputEnabled(false)

                    local statusPill = vgui.Create("DPanel", metaRow)
                    statusPill:Dock(LEFT)
                    statusPill:SetWide(86)
                    statusPill:DockMargin(0, 0, 10, 0)
                    statusPill.Paint = function(self, pw, ph)
                        local P = GetPalette()
                        DrawModernPanel(P, P.radius or 6, 0, 1, pw, ph - 2, accentSoft, accentColor, 1)
                        draw.SimpleText(statusText, "InvSmall", pw * 0.5, ph * 0.5, accentColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                    statusPill:SetMouseInputEnabled(false)

                    local reporterLabel = vgui.Create("DLabel", metaRow)
                    reporterLabel:Dock(FILL)
                    reporterLabel:SetFont("InvSmall")
                    reporterLabel:SetTextColor(GetPalette().textMuted or Color(180, 184, 192))
                    reporterLabel:SetText(tostring(t.reporterName or t.reporter or "Unknown Player"))
                    reporterLabel:SetMouseInputEnabled(false)

                    row._titleLabel = titleLabel
                    row._agePill = agePill
                    row._statusPill = statusPill
                    row._statusText = statusText
                    row._accentColor = accentColor
                    row._accentSoft = accentSoft
                    row._selectedCard = card
                    local function SelectThisTicket()
                        state.currentId = t.id
                        if isfunction(SetBreadcrumb) then
                            SetBreadcrumb({ "Admin Hub", "Tickets", "#" .. tostring(t.id or "?") })
                        end
                        for _, c in ipairs(state.columns or {}) do
                            if IsValid(c) and IsValid(c._layout) then
                                for _, r in ipairs(c._layout:GetChildren() or {}) do
                                    if IsValid(r) then r._isSelected = false end
                                end
                            end
                        end
                        row._isSelected = true
                    end
                    card:SetCursor("hand")
                    card.OnMousePressed = function(_, code)
                        if code == MOUSE_LEFT then
                            SelectThisTicket()
                        end
                    end
                    btnStrip:SetCursor("hand")
                    btnStrip.OnMousePressed = function(_, code)
                        if code == MOUSE_LEFT then
                            SelectThisTicket()
                        end
                    end
                    local clickOverlay = vgui.Create("DButton", content)
                    clickOverlay:Dock(FILL) clickOverlay:SetText("") clickOverlay:SetCursor("hand") clickOverlay.Paint=nil
                    clickOverlay.DoClick = function() SelectThisTicket() end
                    row._lastAgeTick = 0
                    row.Think = function(self)
                        local tick = os.time()
                        if self._lastAgeTick ~= tick then
                            self._lastAgeTick = tick
                            if IsValid(self._agePill) then
                                self._agePill:InvalidateLayout(true)
                            end
                        end
                    end
                    local function ActionButton(parent, text, bg, border, w, h)
                        local b = vgui.Create("DButton", parent)
                        b:SetText("") b:SetSize(w or 64, h or 26) b.ButtonText = text or ""
                        b.Paint = function(s, pw, ph)
                            local P = GetPalette()
                            local base = bg or P.btn
                            local hov = s:IsHovered()
                            local col = hov and Color(math.min(base.r + 10,255), math.min(base.g + 10,255), math.min(base.b + 10,255)) or base
                            DrawModernPanel(P, P.radius or 6, 0, 0, pw, ph, col, border or P.outline, 1)
                            surface.SetFont("InvSmall")
                            local tw, th = surface.GetTextSize(s.ButtonText)
                            surface.SetTextColor(255,255,255) surface.SetTextPos(pw/2 - tw/2, ph/2 - th/2) surface.DrawText(s.ButtonText)
                        end
                        return b
                    end
                    local btnClose = ActionButton(btnStrip, "Close", Color(122, 64, 68), Color(170, 94, 102))
                    btnClose:SetSize(96, 30)
                    btnClose.DoClick = function()
                        net.Start("Monarch_Tickets_Action") net.WriteUInt(t.id, 16) net.WriteString("close") net.SendToServer()
                        timer.Simple(0, function() if not IsValid(frame) then return end net.Start("Monarch_Tickets_RequestList") net.SendToServer() end)
                        if state.currentId == t.id then
                            state.currentId = nil
                            state.chatScroll:Clear()
                            state.inputRow:SetVisible(false)
                            state.actionRow:SetVisible(false)
                            state.chatWrap:SetVisible(false)
                            listWrap:SetVisible(true)
                        end
                        row:SetMouseInputEnabled(false) row:SetKeyboardInputEnabled(false)
                        local function afterRemove()
                            if IsValid(col) then col._count = math.max(0, (col._count or 1) - 1) end
                            local anyLeft = false
                            for _, c in ipairs(state.columns or {}) do if IsValid(c) and IsValid(c._layout) then for _, ch in ipairs(c._layout:GetChildren() or {}) do if IsValid(ch) and ch ~= row then anyLeft = true break end end end if anyLeft then break end end
                            if not anyLeft then if IsValid(state.emptyLabel) then state.emptyLabel:Remove() end state.emptyLabel = vgui.Create("DLabel", state.listWrap) state.emptyLabel:Dock(FILL) state.emptyLabel:SetText("No available tickets") state.emptyLabel:SetFont("InvMed") state.emptyLabel:SetTextColor(Color(220,220,220)) state.emptyLabel:SetContentAlignment(5) end
                        end
                        if row.AlphaTo then row:AlphaTo(0, 0.15, 0, function() if IsValid(row) then row:Remove() end afterRemove() end) else if IsValid(row) then row:Remove() end afterRemove() end
                    end
                    local btnClaim = ActionButton(btnStrip, "Claim", Color(56, 110, 82), Color(90, 160, 120))
                    btnClaim:SetSize(96, 30)
                    btnClaim.DoClick = function()
                        net.Start("Monarch_Tickets_Action") net.WriteUInt(t.id, 16) net.WriteString("claim") net.SendToServer()
                        state.currentId = t.id
                        state.forceChatOpenId = t.id
                        for _, c in ipairs(state.columns or {}) do if IsValid(c) and IsValid(c._layout) then for _, r in ipairs(c._layout:GetChildren() or {}) do if IsValid(r) then r._isSelected = false end end end end
                        if IsValid(row) then row._isSelected = true end
                        listWrap:SetVisible(false)
                        state.chatWrap:SetVisible(true)
                        state.chatScroll:SetVisible(true)
                        state.inputRow:SetVisible(true)
                        state.actionRow:SetVisible(true)
                        state.entry:SetPlaceholderText(string.format("Reply to #%d...", t.id))
                        PopulateChat(t)
                        if IsValid(state.plusBtn) then state.plusBtn:SetVisible(false) end
                    end
                    btnStrip.PerformLayout = function(self, pw, ph)
                        local btnW, btnH = 96, 30
                        local gap = 8
                        local startY = 72
                        local maxStart = math.max(0, ph - ((btnH * 2) + gap))
                        if startY > maxStart then
                            startY = maxStart
                        end
                        btnClose:SetPos(math.floor((pw - btnW) * 0.5), startY)
                        btnClaim:SetPos(math.floor((pw - btnW) * 0.5), startY + btnH + gap)
                    end
                    local function getOriginalMessage()
                        if t.messages and #t.messages > 0 then
                            local first = t.messages[1]
                            if first and first.text and first.text ~= "" then return first.text end
                            local earliest, emsg
                            for _, m in ipairs(t.messages) do if m and m.text and m.text ~= "" then if not earliest or (m.time or 0) < earliest then earliest = m.time or 0 emsg = m.text end end end
                            return emsg or ""
                        end
                        return t.text or t.message or ""
                    end
                    local previewWrap = vgui.Create("DPanel", content)
                    previewWrap:Dock(FILL)
                    previewWrap:DockMargin(0, 8, 8, 0)
                    previewWrap.Paint = function(self, pw, ph)
                        local P = GetPalette()
                        DrawModernPanel(P, P.radius or 6, 0, 0, pw, ph, Color(36, 39, 44, 220), Color(58, 62, 70), 1)
                    end
                    previewWrap:SetMouseInputEnabled(false)

                    local preview = vgui.Create("DLabel", previewWrap)
                    preview:Dock(FILL)
                    preview:DockMargin(10, 8, 10, 8)
                    preview:SetFont("InvSmall")
                    preview:SetTextColor(GetPalette().textMuted or GetPalette().text)
                    preview:SetWrap(true)
                    preview:SetAutoStretchVertical(true)
                    preview:SetText(GetTicketSummary(t))
                    preview:SetMouseInputEnabled(false)

                    clickOverlay:MoveToFront()
                end
            end
            if IsValid(state.listScroller) and state.listScroller.InvalidateLayout then state.listScroller:InvalidateLayout(true) end
            if count == 0 then
                state.emptyLabel = vgui.Create("DLabel", state.listWrap)
                state.emptyLabel:Dock(FILL)
                state.emptyLabel:SetText("No available tickets")
                state.emptyLabel:SetFont("InvMed")
                state.emptyLabel:SetTextColor(Color(220,220,220))
                state.emptyLabel:SetContentAlignment(5)
                state.inputRow:SetVisible(false)
            end
        end
        state.entry.OnEnter = function(self)
            if not state.currentId then return end
            local MAXLEN = 75
            local text = string.Trim(self:GetText() or "") if text == "" then return end
            if #text > MAXLEN then text = string.sub(text, 1, MAXLEN) end
            net.Start("Monarch_Tickets_Message") net.WriteUInt(state.currentId, 16) net.WriteString(text) net.WriteString("admin") net.SendToServer()
            self:SetText("")
        end
        do
            local pad = 6
            local btnClose = StyledButton(actionRow, "CLOSE")
            btnClose:Dock(RIGHT) btnClose:DockMargin(pad,pad,pad,pad) btnClose:SetWide(104)
            btnClose.Paint = function(self, pw, ph)
                local P = GetPalette()
                local bg = self:IsHovered() and Color(146, 72, 76) or Color(122, 64, 68)
                DrawModernPanel(P, P.radius or 6, 0, 0, pw, ph, bg, Color(170, 94, 102), 1)
                draw.SimpleText(self.ButtonText or "", "InvSmall", math.floor(pw * 0.5), math.floor(ph * 0.5), Color(250, 250, 252), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            btnClose.DoClick = function()
                if not state.currentId then return end
                SendActionCurrent("close")
                RemoveTicketRowById(state.currentId)
                if isfunction(SetBreadcrumb) then
                    SetBreadcrumb({ "Admin Hub", "Tickets" })
                end
                timer.Simple(0, function() if not IsValid(frame) then return end net.Start("Monarch_Tickets_RequestList") net.SendToServer() end)
            end
            local btnCreator = StyledButton(actionRow, "Item Creator")
            btnCreator:Dock(LEFT) btnCreator:DockMargin(pad,pad,0,pad) btnCreator:SetWide(120)
            btnCreator.DoClick = function() if RunConsoleCommand then RunConsoleCommand("monarch_itemcreator") end end
            local btnCopy = StyledButton(actionRow, "Copy SID64")
            actionRow.btnCopySID = btnCopy
            btnCopy:Dock(LEFT) btnCopy:DockMargin(pad,pad,0,pad) btnCopy:SetWide(120)
            btnCopy.DoClick = function()
                if not state.currentId then return end
                local tk = GetTicketById(state.currentId)
                local sid = tk and (tk.reporter or tk.reporterId)
                if sid and sid ~= "" then if SetClipboardText then SetClipboardText(tostring(sid)) end surface.PlaySound("menu/ui_click.mp3") end
            end
            local btnGoto = StyledButton(actionRow, "Goto")
            btnGoto:Dock(LEFT) btnGoto:DockMargin(pad,pad,0,pad) btnGoto:SetWide(80)
            btnGoto.DoClick = function() if not state.currentId then return end SendActionCurrent("goto") end
            local btnBring = StyledButton(actionRow, "Bring")
            btnBring:Dock(LEFT) btnBring:DockMargin(pad,pad,0,pad) btnBring:SetWide(80)
            btnBring.DoClick = function() if not state.currentId then return end SendActionCurrent("bring") end
        end
        frame._views = frame._views or {}
        frame._views.tickets = {
            state = state,
            PopulateList = PopulateList,
            PopulateChat = PopulateChat,
            RemoveTicketRowById = RemoveTicketRowById,
            AddNotification = function(kind, tk) state:AddNotification(kind, tk) end,
            UpdateMiddleForTicket = function(tk)
                if not tk then return end
                local claimed = (tk.status and string.lower(tk.status) == "claimed") or (tk.claimedBy ~= nil)
                if state.forceChatOpenId and state.forceChatOpenId == tk.id then
                    if isfunction(SetBreadcrumb) then SetBreadcrumb({ "Admin Hub", "Tickets", "#" .. tostring(tk.id or "?") }) end
                    listWrap:SetVisible(false) state.chatWrap:SetVisible(true) state.chatScroll:SetVisible(true) state.inputRow:SetVisible(true) state.actionRow:SetVisible(true) if IsValid(state.plusBtn) then state.plusBtn:SetVisible(false) end
                elseif claimed then
                    if isfunction(SetBreadcrumb) then SetBreadcrumb({ "Admin Hub", "Tickets", "#" .. tostring(tk.id or "?") }) end
                    listWrap:SetVisible(false) state.chatWrap:SetVisible(true) state.chatScroll:SetVisible(true) state.inputRow:SetVisible(true) state.actionRow:SetVisible(true) if IsValid(state.plusBtn) then state.plusBtn:SetVisible(false) end
                else
                    if isfunction(SetBreadcrumb) then SetBreadcrumb({ "Admin Hub", "Tickets" }) end
                    state.chatWrap:SetVisible(false) listWrap:SetVisible(true) if IsValid(state.plusBtn) then state.plusBtn:SetVisible(true) end
                end
            end
        }

        local notifPad = 6
        local function LayoutNotifications()
            local y = (state.notifWrap:GetTall() or 0) - notifPad
            for i = #state.notifItems, 1, -1 do
                local item = state.notifItems[i]
                if not IsValid(item) then table.remove(state.notifItems, i) else
                    item:SetWide(math.max(0, (state.notifWrap:GetWide() or 0) - 12))
                    local h = item:GetTall()
                    y = y - h
                    local targetY = y
                    y = y - notifPad
                    item._targetY = targetY
                end
            end
        end
        notifWrap.OnSizeChanged = function()
            LayoutNotifications()
        end
        function state:AddNotification(kind, t)
            if not IsValid(self.notifWrap) then return end
            local col = Color(120,120,255)
            local label = "Updated"
            if kind == "created" then
                col = Color(214,170,86)
                label = "Created"
            elseif kind == "claimed" then
                col = Color(40,160,80)
                label = "Claimed"
            elseif kind == "closed" then
                col = Color(160,60,60)
                label = "Closed"
            end

            local function ResolveReporterPlayer(data)
                if not istable(data) then return nil end
                if IsValid(data.reporter) and data.reporter:IsPlayer() then return data.reporter end

                local sid64 = tostring(data.reporterId or data.reporter or "")
                if sid64 ~= "" then
                    for _, ply in ipairs(player.GetAll()) do
                        if IsValid(ply) and ply:SteamID64() == sid64 then
                            return ply
                        end
                    end
                end

                local reporterName = tostring(data.reporterName or data.reporter or "")
                if reporterName ~= "" then
                    for _, ply in ipairs(player.GetAll()) do
                        if IsValid(ply) and string.lower(ply:Nick() or "") == string.lower(reporterName) then
                            return ply
                        end
                    end
                end

                return nil
            end

            local panel = vgui.Create("DPanel", self.notifWrap)
            panel:SetSize(self.notifWrap:GetWide()-12, 70)
            panel:SetPos(6, self.notifWrap:GetTall()+70)
            panel.spawn = CurTime()
            panel.alpha = 0
            panel._targetY = self.notifWrap:GetTall()-panel:GetTall()-6

            local avatarWrap = vgui.Create("DPanel", panel)
            avatarWrap:SetSize(44, 44)
            avatarWrap:SetPos(10, 13)
            avatarWrap.Paint = function(s, aw, ah)
                local P = GetPalette()
                local a = math.Clamp(panel.alpha or 255, 0, 255)
                DrawModernPanel(P, (P.radius or 6), 0, 0, aw, ah, Color(54, 58, 64, a), Color(96, 102, 112, a), 1)
            end

            local avatar = vgui.Create("AvatarImage", avatarWrap)
            avatar:SetSize(40, 40)
            avatar:SetPos(2, 2)

            local avatarPly = ResolveReporterPlayer(t)
            if IsValid(avatarPly) then
                avatar:SetPlayer(avatarPly, 64)
            end

            local avatarFallback = vgui.Create("DLabel", avatarWrap)
            avatarFallback:Dock(FILL)
            avatarFallback:SetFont("InvSmall")
            avatarFallback:SetTextColor(Color(220, 224, 232))
            avatarFallback:SetContentAlignment(5)
            avatarFallback:SetText(IsValid(avatarPly) and "" or "?")

            panel.Paint = function(s, pw, ph)
                local a = s.alpha or 255
                local P = GetPalette()
                DrawModernPanel(P, (P.radius or 6), 0, 0, pw, ph, Color(P.panel.r, P.panel.g, P.panel.b, 220 * (a / 255)), Color(col.r, col.g, col.b, 220 * (a / 255)), 2)
                local titleText = string.format("%s Ticket #%s", label, tostring(t.id or "?"))
                local detailText = tostring(t.reporterName or t.reporter or "Unknown Player")
                surface.SetTextColor(P.text.r, P.text.g, P.text.b, a)
                draw.SimpleText(titleText, "InvSmall", 64, 18, Color(P.text.r, P.text.g, P.text.b, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(detailText, "InvSmall", 64, 40, Color((P.textMuted and P.textMuted.r) or 190, (P.textMuted and P.textMuted.g) or 192, (P.textMuted and P.textMuted.b) or 195, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            panel.Think = function(s)
                local dt = FrameTime() * 10
                s.alpha = Lerp(dt, s.alpha, 255)
                if IsValid(avatarWrap) then avatarWrap:SetAlpha(s.alpha) end
                if IsValid(avatar) then avatar:SetAlpha(s.alpha) end
                if IsValid(avatarFallback) then avatarFallback:SetAlpha(s.alpha) end
                local x, y = 6, select(2, s:GetPos())
                local targetY = s._targetY or y
                y = Lerp(dt, y, targetY)
                s:SetPos(x, y)
            end
            table.insert(self.notifItems, panel)
            LayoutNotifications()
        end
        timer.Simple(0, function()
            if not IsValid(notifWrap) or not Monarch_Tickets_Global or not Monarch_Tickets_Global.notifications then return end
            for _, n in ipairs(Monarch_Tickets_Global.notifications) do
                state:AddNotification(n.kind or "updated", { id = n.id, reporterName = n.reporter })
            end
        end)

        net.Start("Monarch_Tickets_RequestList") net.SendToServer()
        state.inputRow:SetVisible(false)
        state.actionRow:SetVisible(false)
    end

    return BuildTicketsView
end

