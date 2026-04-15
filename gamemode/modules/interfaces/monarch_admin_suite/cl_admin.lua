local function OpenTicketsUI()
    local isStaff = Monarch_Tickets_IsStaff
    if isfunction(isStaff) and not isStaff() then return end

    if IsValid(Monarch_Tickets_Frame) then Monarch_Tickets_Frame:Remove() end

    local scrW, scrH = ScrW(), ScrH()
    local w = math.floor(scrW * 0.8)
    local h = math.floor(scrH * 0.8)

    local function RoundedOutlinedBox(radius, x, y, w, h, fill, outline, borderW)
        borderW = borderW or 1
        draw.RoundedBox(radius, x, y, w, h, outline)
        draw.RoundedBox(math.max(0, radius - borderW), x + borderW, y + borderW, w - (borderW * 2), h - (borderW * 2), fill)
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(w, h)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame:SetDeleteOnClose(true)
    frame.topBarH = 30
    frame.crumbH = 24

    if Monarch and Monarch.Theme and Monarch.Theme.AttachSkin then
        Monarch.Theme.AttachSkin(frame)
    end

    local function GetPalette()
        if Monarch and Monarch.Theme and Monarch.Theme.Get then
            return Monarch.Theme.Get()
        end
        return {
            panel = Color(28,28,30),
            panelElevated = Color(34,36,40),
            outline = Color(55,57,63),
            titlebar = Color(30,30,32),
            divider = Color(80,82,88,160),
            text = Color(230,232,236),
            textMuted = Color(180,184,192),
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

    frame.breadcrumb = { "Admin Hub", "Tickets" }
    function frame:SetBreadcrumb(parts)
        if not istable(parts) or #parts == 0 then return end
        self.breadcrumb = parts
    end

    frame.Paint = function(s, pw, ph)
        local P = GetPalette()
        local radius = (P.radius or 6) + 2

        RoundedOutlinedBox(radius, 0, 0, pw, ph, P.panel, P.outline, 1)
        draw.RoundedBox(radius, 1, 1, pw - 2, ph - 2, P.panelElevated or P.panel)

        RoundedOutlinedBox(radius, 1, 1, pw - 2, s.topBarH + s.crumbH, P.titlebar, P.outline, 1)
        surface.SetDrawColor(P.divider)
        surface.DrawLine(0, s.topBarH, pw, s.topBarH)
        surface.DrawLine(0, s.topBarH + s.crumbH, pw, s.topBarH + s.crumbH)
        draw.SimpleText("Monarch Admin Hub", "InvMed", 12, math.floor((s.topBarH - 24) * 0.5), P.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local crumbText = table.concat(s.breadcrumb or { "Admin Hub" }, " / ")
        draw.SimpleText(crumbText, "InvSmall", 12, s.topBarH + 5, P.textMuted or P.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    frame.closeBtn = vgui.Create("DButton", frame)
    frame.closeBtn:SetSize(28, 24)
    frame.closeBtn:SetPos(frame:GetWide() - 32, math.floor((frame.topBarH - 24) * 0.5))
    frame.closeBtn:SetText("")
    frame.closeBtn:SetFont("Trebuchet24")
    frame.closeBtn:SetTextColor(color_white)
    frame.closeBtn.Paint = function(s, pw, ph)
        local clr = s:IsHovered() and Color(220, 96, 96) or Color(240, 242, 245)
        draw.SimpleText("×", s:GetFont() or "Trebuchet24", math.floor(pw * 0.5), math.floor(ph * 0.5), clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    frame.closeBtn.DoClick = function() frame:Remove() end
    Monarch_Tickets_Frame = frame

    local StyledButton
    local PanelControlButton

    function StyledButton(parent, text)
        local btn = vgui.Create("DButton", parent)
        btn:SetText("")
        btn.ButtonText = text or ""
        btn.Selected = false
        btn.Font = btn.Font or "InvMed"
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
            RoundedOutlinedBox(P.radius or 6, 0, 0, pw, ph, bg, P.outline, 1)

            surface.SetFont(self.Font or "InvMed")
            local label = self.ButtonText or ""
            local tw, th = surface.GetTextSize(label)
            surface.SetTextColor(P.btnText)
            surface.SetTextPos(math.floor(pw * 0.5 - tw * 0.5), math.floor(ph * 0.5 - th * 0.5))
            surface.DrawText(label)
        end
        return btn
    end

    function PanelControlButton(parent, text)
        local btn = vgui.Create("DButton", parent)
        btn:SetText("")
        local label = text or ""
        if label == "✕" or label == "✖" or label == "X" then
            label = "×"
        end
        btn.ButtonText = label
        btn.Font = "Trebuchet24"
        function btn:Paint(pw, ph)
            local P = GetPalette()
            local clr = self.Hovered and Color(220, 96, 96) or P.btnText
            draw.SimpleText(self.ButtonText, self.Font, math.floor(pw * 0.5), math.floor(ph * 0.5), clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        return btn
    end

    local function OpenCreateTicket()
        local dw, dh = 520, 320
        local dlg = vgui.Create("DFrame")
        dlg:SetSize(dw, dh)
        dlg:Center()
        dlg:SetTitle("")
        dlg:ShowCloseButton(false)
        dlg:SetDraggable(false)
        dlg:MakePopup()
        dlg.topBarH = 28
        dlg.Paint = function(s, pw, ph)
            local P = GetPalette()
            RoundedOutlinedBox(P.radius or 6, 0, 0, pw, ph, P.panelElevated or P.panel, P.outline, 1)
            draw.SimpleText("Create Ticket", "InvMed", 12, 6, P.text)
        end
        local closeBtn = PanelControlButton(dlg, "×"); closeBtn:SetSize(24,20)
        closeBtn:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2))
        closeBtn.DoClick = function() dlg:Close() end
        closeBtn.Think = function(s) s:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)) end

        local body = vgui.Create("DPanel", dlg)
        body:Dock(FILL)
        body:DockMargin(8,32,8,8)
        body.Paint = nil

        local title = vgui.Create("DLabel", body)
        title:Dock(TOP)
        title:SetTall(22)
        title:SetText("Describe your issue")
        title:SetFont("InvMed")
        title:SetTextColor(Color(230,230,230))

        local entry = vgui.Create("DTextEntry", body)
        entry:Dock(FILL)
        entry:SetMultiline(true)
        entry:SetFont("DermaDefault")
        entry:SetPlaceholderText("Describe the problem and any people involved (steam IDs are helpful)â€¦")

        local actions = vgui.Create("DPanel", body)
        actions:Dock(BOTTOM)
        actions:SetTall(36)
        actions.Paint = nil
        local ok = StyledButton(actions, "Submit")
        ok:Dock(RIGHT)
        ok:SetWide(100)
        ok:DockMargin(6,0,0,0)
        ok.DoClick = function()
            local text = string.Trim(entry:GetValue() or "")
            if text ~= "" then

                if net and net.Start then
                    net.Start("Monarch_Tickets_Create")
                    net.WriteString(string.sub(text, 1, 500))
                    net.SendToServer()
                end
            end
            dlg:Close()
        end
        local cancel = StyledButton(actions, "Cancel")
        cancel:Dock(RIGHT)
        cancel:SetWide(100)
        cancel.DoClick = function() dlg:Close() end
    end

    local body = vgui.Create("DPanel", frame)
    body:Dock(FILL)
    body:DockMargin(8, frame.topBarH + frame.crumbH + 6, 8, 8)
    body.Paint = nil

    local tabsLeft = vgui.Create("DPanel", body)
    tabsLeft:Dock(LEFT)
    tabsLeft:SetWide(170)
    tabsLeft.Paint = function(self, w, h)
        local P = GetPalette()
        RoundedOutlinedBox(P.radius or 6, 0, 0, w, h, P.panel, P.outline, 1)
    end
    local tabList = vgui.Create("DScrollPanel", tabsLeft)
    tabList:Dock(FILL)
    tabList:DockMargin(4,4,4,4)

    local right = vgui.Create("DPanel", body)
    right:Dock(FILL)
    right:DockMargin(8, 0, 0, 0)
    right.Paint = function(self, w, h)
        local P = GetPalette()
        RoundedOutlinedBox(P.radius or 6, 0, 0, w, h, P.panel, P.outline, 1)
    end

    local function ClearRight()
        for _, ch in ipairs(right:GetChildren() or {}) do
            if IsValid(ch) then ch:Remove() end
        end
    end

    local TABS = {
        { key = "tickets", label = "Tickets" },
        { key = "tools",   label = "Tools"   },
        { key = "custom_tools", label = "Custom Tools" },
        { key = "players", label = "Players" },
        { key = "chars",   label = "Characters" },
    }

    if LocalPlayer() and LocalPlayer().IsSuperAdmin and LocalPlayer():IsSuperAdmin() then
        table.insert(TABS, { key = "staff", label = "Staff Manager" })
    end

    local BuildTicketsView, BuildToolsView, BuildCustomToolsView, BuildPlayersView, BuildCharsView, BuildStaffView

    BuildTicketsView = function()
        ClearRight()
        local container = vgui.Create("DPanel", right)
        container:Dock(FILL)
        container.Paint = nil

        local notifDivider = vgui.Create("DPanel", container)
        notifDivider:Dock(RIGHT)
        notifDivider:SetWide(6)
        notifDivider.Paint = function(self, pw, ph)
            local P = GetPalette()
            surface.SetDrawColor(P.divider) surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.outline) surface.DrawOutlinedRect(0,0,pw,ph,1)
        end
        local notifWrap = vgui.Create("DPanel", container)
        notifWrap:Dock(RIGHT)
        notifWrap:SetWide(260)
        notifWrap.Paint = function(self, pw, ph)
            local P = GetPalette()
            surface.SetDrawColor(P.panel) surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.outline) surface.DrawOutlinedRect(0,0,pw,ph,1)
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
        listTop.Paint = function(self, w, h)
            local P = GetPalette()
            surface.SetDrawColor(P.panel) surface.DrawRect(0,0,w,h)
        end
        local plusBtn = StyledButton(listTop, "+ New")
        plusBtn:Dock(RIGHT)
        plusBtn:SetWide(90)
        plusBtn:DockMargin(6,4,6,4)
        plusBtn.DoClick = function() OpenCreateTicket() end

        local listScroller = vgui.Create("DHorizontalScroller", listWrap)
        listScroller:Dock(FILL)
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
            surface.SetDrawColor(P.panel) surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.outline) surface.DrawOutlinedRect(0,0,pw,ph,1)
        end
        local chatScroll = vgui.Create("DScrollPanel", chatWrap)
        chatScroll:Dock(FILL)
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
            surface.SetDrawColor(P.panel) surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.outline) surface.DrawOutlinedRect(0,0,pw,ph,1)
        end
        local entry = vgui.Create("DTextEntry", inputRow)
        entry:Dock(FILL)
        entry:SetFont("InvSmall")
        entry:SetPlaceholderText("Select a ticket to replyâ€¦")
        entry:SetTextColor(Color(230,230,230))
        entry:SetDrawLanguageID(false)
        entry.Paint = function(self, pw, ph)
            local P = GetPalette()
            surface.SetDrawColor(P.inputBg) surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.inputBorder) surface.DrawOutlinedRect(0,0,pw,ph,1)
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
        }
        state.plusBtn = plusBtn

        local function GetTicketById(id)
            if not id then return nil end
            for _, t in ipairs(state.ticketsCache or {}) do if t.id == id then return t end end
            return nil
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
        local function PopulateChat(t)
            state.chatScroll:Clear()
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
                    draw.RoundedBox(radius, 0, 0, pw, ph, bg)
                    surface.SetDrawColor(border)
                    surface.DrawOutlinedRect(0, 0, pw, ph, 1)
                    local who = m.name or (isHandler and "Handler" or (isCreator and "Creator" or "Player"))
                    local when = os.date("%I:%M %p", tonumber(m.time or os.time()))
                    draw.SimpleText(who .. " - " .. when, "InvSmall", 8, 6, Color(244,246,250))
                end
                local text = vgui.Create("DLabel", row)
                text:Dock(FILL)
                text:DockMargin(8, 20, 8, 8)
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
                    row:SetTall(110)
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
                        surface.SetDrawColor(Color(50,50,50,120)) surface.DrawRect(0,0,pw,ph)
                        local border = (state.currentId == t.id) and P.primary or P.outline
                        surface.SetDrawColor(border) surface.DrawOutlinedRect(0,0,pw,ph,2)
                    end
                    local baseTitle = string.format("#%d  %s  [%s]", t.id, t.reporterName or t.reporter or "", (t.status or "open"))
                    local createdTS = GetCreatedTS(t)
                    local function composeTitle()
                        local age = FormatAge(os.time() - createdTS)
                        return string.format("%s - %s", baseTitle, age)
                    end
                    local btnStrip = vgui.Create("DPanel", card)
                    btnStrip:Dock(RIGHT)
                    btnStrip:SetWide(120)
                    btnStrip:DockMargin(6,8,8,8)
                    btnStrip.Paint = nil
                    local content = vgui.Create("DPanel", card)
                    content:Dock(FILL)
                    content:DockMargin(10,10,0,10)
                    content.Paint = nil
                    local labelBtn = StyledButton(content, composeTitle())
                    labelBtn:Dock(TOP)
                    labelBtn:SetTall(30)
                    labelBtn.Font = "InvSmall"
                    row._labelBtn = labelBtn
                    labelBtn.Selected = (state.currentId == t.id)
                    local function SelectThisTicket()
                        state.currentId = t.id
                        for _, c in ipairs(state.columns or {}) do if IsValid(c) and IsValid(c._layout) then for _, r in ipairs(c._layout:GetChildren() or {}) do if IsValid(r) and IsValid(r._labelBtn) then r._labelBtn.Selected = false end end end end
                        labelBtn.Selected = true
                    end
                    labelBtn.DoClick = SelectThisTicket
                    local clickOverlay = vgui.Create("DButton", content)
                    clickOverlay:Dock(FILL) clickOverlay:SetText("") clickOverlay:SetCursor("hand") clickOverlay.Paint=nil
                    clickOverlay.DoClick = function() SelectThisTicket() end
                    row._lastAgeTick = 0
                    row.Think = function(self)
                        local tick = os.time()
                        if self._lastAgeTick ~= tick then self._lastAgeTick = tick labelBtn.ButtonText = composeTitle() end
                    end
                    local function ActionButton(parent, text, bg, border, w, h)
                        local b = vgui.Create("DButton", parent)
                        b:SetText("") b:SetSize(w or 64, h or 26) b.ButtonText = text or ""
                        b.Paint = function(s, pw, ph)
                            local P = GetPalette()
                            local base = bg or P.btn
                            local hov = s:IsHovered()
                            local col = hov and Color(math.min(base.r+12,255), math.min(base.g+12,255), math.min(base.b+12,255)) or base
                            draw.RoundedBox(P.radius or 6, 0, 0, pw, ph, col)
                            surface.SetDrawColor(border or P.outline) surface.DrawOutlinedRect(0,0,pw,ph,1)
                            surface.SetFont("DermaDefaultBold")
                            local tw, th = surface.GetTextSize(s.ButtonText)
                            surface.SetTextColor(255,255,255) surface.SetTextPos(pw/2 - tw/2, ph/2 - th/2) surface.DrawText(s.ButtonText)
                        end
                        return b
                    end
                    local btnClose = ActionButton(btnStrip, "Close", Color(120,40,40), Color(140,60,60))
                    btnClose:Dock(TOP) btnClose:DockMargin(0,0,0,6)
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
                    local btnClaim = ActionButton(btnStrip, "Claim", Color(40,120,60), Color(60,160,80))
                    btnClaim:Dock(TOP) btnClaim:DockMargin(0,0,0,0)
                    btnClaim.DoClick = function()
                        net.Start("Monarch_Tickets_Action") net.WriteUInt(t.id, 16) net.WriteString("claim") net.SendToServer()
                        state.currentId = t.id
                        state.forceChatOpenId = t.id
                        for _, c in ipairs(state.columns or {}) do if IsValid(c) and IsValid(c._layout) then for _, r in ipairs(c._layout:GetChildren() or {}) do if IsValid(r) and IsValid(r._labelBtn) then r._labelBtn.Selected = false end end end end
                        if IsValid(row) and IsValid(row._labelBtn) then row._labelBtn.Selected = true end
                        listWrap:SetVisible(false)
                        state.chatWrap:SetVisible(true)
                        state.chatScroll:SetVisible(true)
                        state.inputRow:SetVisible(true)
                        state.actionRow:SetVisible(true)
                        state.entry:SetPlaceholderText(string.format("Reply to #%dâ€¦", t.id))
                        PopulateChat(t)
                        if IsValid(state.plusBtn) then state.plusBtn:SetVisible(false) end
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
                    local preview = vgui.Create("DLabel", content)
                    preview:Dock(FILL) preview:DockMargin(4,6,8,4)
                    preview:SetFont("DermaDefault") preview:SetTextColor(GetPalette().text)
                    preview:SetWrap(true) preview:SetAutoStretchVertical(true)
                    local msg = getOriginalMessage() or "" if #msg > 240 then msg = string.sub(msg,1,237).."..." end
                    preview:SetText(msg)
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
                local bg = self:IsHovered() and Color(144, 66, 66) or Color(120, 40, 40)
                RoundedOutlinedBox(P.radius or 6, 0, 0, pw, ph, bg, Color(140, 60, 60), 1)
                draw.SimpleText(self.ButtonText or "", "InvSmall", math.floor(pw * 0.5), math.floor(ph * 0.5), Color(250, 250, 252), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            btnClose.DoClick = function()
                if not state.currentId then return end
                SendActionCurrent("close")
                RemoveTicketRowById(state.currentId)
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
                    listWrap:SetVisible(false) state.chatWrap:SetVisible(true) state.chatScroll:SetVisible(true) state.inputRow:SetVisible(true) state.actionRow:SetVisible(true) if IsValid(state.plusBtn) then state.plusBtn:SetVisible(false) end
                elseif claimed then
                    listWrap:SetVisible(false) state.chatWrap:SetVisible(true) state.chatScroll:SetVisible(true) state.inputRow:SetVisible(true) state.actionRow:SetVisible(true) if IsValid(state.plusBtn) then state.plusBtn:SetVisible(false) end
                else
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
                        if IsValid(ply) and ply:SteamID64() == sid64 then return ply end
                    end
                end
                local reporterName = tostring(data.reporterName or data.reporter or "")
                if reporterName ~= "" then
                    for _, ply in ipairs(player.GetAll()) do
                        if IsValid(ply) and string.lower(ply:Nick() or "") == string.lower(reporterName) then return ply end
                    end
                end
                return nil
            end

            local panel = vgui.Create("DPanel", self.notifWrap)
            panel:SetSize(self.notifWrap:GetWide()-12, 70)
            panel:SetPos(6, self.notifWrap:GetTall()+70)
            panel.spawn = CurTime() panel.alpha = 0 panel._targetY = self.notifWrap:GetTall()-panel:GetTall()-6

            local avatarWrap = vgui.Create("DPanel", panel)
            avatarWrap:SetSize(44, 44)
            avatarWrap:SetPos(10, 13)
            avatarWrap.Paint = function(s, aw, ah)
                local a = math.Clamp(panel.alpha or 255, 0, 255)
                draw.RoundedBox(8, 0, 0, aw, ah, Color(96, 102, 112, a))
                draw.RoundedBox(7, 1, 1, aw - 2, ah - 2, Color(54, 58, 64, a))
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
                draw.RoundedBox(8, 0, 0, pw, ph, Color(P.panel.r, P.panel.g, P.panel.b, 220 * (a/255)))
                surface.SetDrawColor(col.r, col.g, col.b, 220 * (a/255)) surface.DrawOutlinedRect(0,0,pw,ph,2)
                draw.SimpleText(string.format("%s Ticket #%s", label, tostring(t.id or "?")), "InvSmall", 64, 18, Color(P.text.r, P.text.g, P.text.b, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(tostring(t.reporterName or t.reporter or "Unknown Player"), "InvSmall", 64, 40, Color(190, 192, 195, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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


    local function SetActiveTab(key)
        local tabLabel = key
        for _, t in ipairs(TABS) do
            if t.key == key then
                tabLabel = t.label
                break
            end
        end
        if IsValid(frame) and frame.SetBreadcrumb then
            frame:SetBreadcrumb({ "Admin Hub", tabLabel })
        end

        for _, btn in ipairs(tabList:GetChildren() or {}) do
            if IsValid(btn) and btn._isTabBtn then btn.Selected = (btn._tabKey == key) end
        end
        if key == "tickets" then BuildTicketsView()
        elseif key == "tools" then BuildToolsView()
        elseif key == "custom_tools" then BuildCustomToolsView()
        elseif key == "players" then BuildPlayersView()
        elseif key == "chars" then BuildCharsView()
        elseif key == "staff" then BuildStaffView()
        end
    end
    if not tabList._tabsBuilt then
        for _, t in ipairs(TABS) do
            local btn = StyledButton(tabList, t.label)
            btn:SetTall(40)
            btn:Dock(TOP)
            btn:DockMargin(2,2,2,2)
            btn._isTabBtn = true
            btn._tabKey = t.key
            btn.DoClick = function() SetActiveTab(t.key) end
        end
        tabList._tabsBuilt = true
    end

    local function OpenCreateTicketDialog()
        if IsValid(frame._createDlg) then frame._createDlg:Remove() end
        local dw, dh = 520, 360
        local dlg = vgui.Create("DFrame")
        dlg:SetSize(dw, dh)
        dlg:Center()
    dlg:SetTitle("")
    dlg:ShowCloseButton(false)
    dlg:SetDraggable(false)
        dlg:MakePopup()
        dlg.Paint = function(s, pw, ph)
            surface.SetDrawColor(28,28,28,255)
            surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(90,90,90,255)
            surface.DrawOutlinedRect(0,0,pw,ph,1)
            draw.SimpleText("Create Ticket", "InvMed", 12, 8, color_white)
        end

        local body = vgui.Create("DPanel", dlg)
        body:Dock(FILL)
        body:DockMargin(8,32,8,8)
        body.Paint = nil

        local title = vgui.Create("DLabel", body)
        title:Dock(TOP)
        title:SetTall(26)
        title:SetText("Describe your issue")
        title:SetFont("InvMed")
        title:SetTextColor(Color(230,230,230))

        local desc = vgui.Create("DLabel", body)
        desc:Dock(TOP)
        desc:DockMargin(0,0,0,8)
        desc:SetText("Please provide a brief description of your issue. A staff member will respond in this panel. Do not include sensitive information.")
        desc:SetFont("DermaDefault")
        desc:SetTextColor(Color(200,200,200))
        desc:SetWrap(true)
        desc:SetAutoStretchVertical(true)

        local entry = vgui.Create("DTextEntry", body)
        entry:Dock(FILL)

        local columns = {}
        local function GetActiveColumn()
            local last = columns[#columns]
            if not IsValid(last) or (last._count or 0) >= 5 then
                last = CreateColumn()
                table.insert(columns, last)
            end
            return last
        end

        do
            Monarch_Tickets_BGMat = Monarch_Tickets_BGMat or Material("monosuite/ui/graph_paper.png", "smooth")
            local bg = vgui.Create("DPanel", container)
            bg:Dock(FILL)
            bg:MoveToBack()
            bg:SetZPos(-1000)
            bg.Paint = function(self, pw, ph)
                local mat = Monarch_Tickets_BGMat
                if mat and not mat:IsError() then
                    surface.SetMaterial(mat)
                    surface.SetDrawColor(230, 230, 230, 28) 
                    local tile = 128
                    surface.DrawTexturedRectUV(0, 0, pw, ph, 0, 0, pw / tile, ph / tile)
                else

                    surface.SetDrawColor(200, 200, 200, 18)
                    for x = 0, pw, 24 do surface.DrawLine(x, 0, x, ph) end
                    for y = 0, ph, 24 do surface.DrawLine(0, y, pw, y) end
                end
            end
        end

        local notifDivider = vgui.Create("DPanel", container)
        notifDivider:Dock(RIGHT)
        notifDivider:SetWide(6)
        notifDivider.Paint = function(self, pw, ph)
            local P = GetPalette()
            surface.SetDrawColor(P.divider)
            surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.outline)
            surface.DrawOutlinedRect(0,0,pw,ph,1)
        end
        local notifWrap = vgui.Create("DPanel", container)
        notifWrap:Dock(RIGHT)
        notifWrap:SetWide(260)
        notifWrap.Paint = function(self, pw, ph)
            local P = GetPalette()
            surface.SetDrawColor(P.panel)
            surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.outline)
            surface.DrawOutlinedRect(0,0,pw,ph,1)
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
            surface.SetDrawColor(P.panel)
            surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.outline)
            surface.DrawOutlinedRect(0,0,pw,ph,1)
        end

        local chatScroll = vgui.Create("DScrollPanel", chatWrap)
        chatScroll:Dock(FILL)
        local cvbar = chatScroll:GetVBar()
        cvbar.Paint = function(s, pw, ph)
            local P = GetPalette()
            surface.SetDrawColor(P.scrollTrack)
            surface.DrawRect(0,0,pw,ph)
        end
        cvbar.btnUp.Paint = function(s, pw, ph)
            local P = GetPalette()
            surface.SetDrawColor(P.btn)
            surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.outline)
            surface.DrawOutlinedRect(0,0,pw,ph,1)
        end
        cvbar.btnDown.Paint = cvbar.btnUp.Paint
        cvbar.btnGrip.Paint = function(s, pw, ph)
            local P = GetPalette()
            local clr = s.Hovered and P.scrollGripHover or P.scrollGrip
            surface.SetDrawColor(clr)
            surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.outline)
            surface.DrawOutlinedRect(0,0,pw,ph,1)
        end

        local inputRow = vgui.Create("DPanel", chatWrap)
        inputRow:Dock(BOTTOM)
        inputRow:SetTall(28)
        inputRow.Paint = function(self, pw, ph)
            local P = GetPalette()
            surface.SetDrawColor(P.panel)
            surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.outline)
            surface.DrawOutlinedRect(0,0,pw,ph,1)
        end
        local entry = vgui.Create("DTextEntry", inputRow)
        entry:Dock(FILL)
        entry:SetFont("InvSmall")
        entry:SetPlaceholderText("Select a ticket to reply...")
        entry:SetTextColor(Color(230,230,230))
        entry:SetDrawLanguageID(false)
        entry.Paint = function(self, pw, ph)
            local P = GetPalette()
            surface.SetDrawColor(P.inputBg)
            surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.inputBorder)
            surface.DrawOutlinedRect(0,0,pw,ph,1)
            self:DrawTextEntryText(P.inputText, P.selection, P.inputText)
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
            notifItems = {}
        }

        state.plusBtn = plusBtn

        local function LayoutNotifications()
            local pad = 8
            local y = (state.notifWrap:GetTall() or 0) - pad
            for i = #state.notifItems, 1, -1 do
                local item = state.notifItems[i]
                if not IsValid(item) then table.remove(state.notifItems, i) else
                    item:SetWide(math.max(0, (state.notifWrap:GetWide() or 0) - 12))
                    local h = item:GetTall()
                    y = y - h
                    local targetY = y
                    y = y - pad
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
            if kind == "created" then col = Color(214,170,86) label = "Created" end
            if kind == "claimed" then col = Color(40,160,80) label = "Claimed" end
            if kind == "closed" then col = Color(160,60,60) label = "Closed" end

            local function ResolveReporterPlayer(data)
                if not istable(data) then return nil end
                if IsValid(data.reporter) and data.reporter:IsPlayer() then return data.reporter end
                local sid64 = tostring(data.reporterId or data.reporter or "")
                if sid64 ~= "" then
                    for _, ply in ipairs(player.GetAll()) do
                        if IsValid(ply) and ply:SteamID64() == sid64 then return ply end
                    end
                end
                local reporterName = tostring(data.reporterName or data.reporter or "")
                if reporterName ~= "" then
                    for _, ply in ipairs(player.GetAll()) do
                        if IsValid(ply) and string.lower(ply:Nick() or "") == string.lower(reporterName) then return ply end
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
                local a = math.Clamp(panel.alpha or 255, 0, 255)
                draw.RoundedBox(8, 0, 0, aw, ah, Color(96, 102, 112, a))
                draw.RoundedBox(7, 1, 1, aw - 2, ah - 2, Color(54, 58, 64, a))
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
                draw.RoundedBox(8, 0, 0, pw, ph, Color(P.panel.r, P.panel.g, P.panel.b, 220 * (a/255)))
                surface.SetDrawColor(col.r, col.g, col.b, 220 * (a/255))
                surface.DrawOutlinedRect(0,0,pw,ph,2)
                draw.SimpleText(string.format("%s Ticket #%s", label, tostring(t.id or "?")), "InvSmall", 64, 18, Color(P.text.r, P.text.g, P.text.b, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(tostring(t.reporterName or t.reporter or "Unknown Player"), "InvSmall", 64, 40, Color(190, 192, 195, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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

        local function GetTicketById(id)
            if not id then return nil end
            for _, t in ipairs(state.ticketsCache or {}) do
                if t.id == id then return t end
            end
            return nil
        end
        local function SendActionCurrent(act)
            if not state.currentId then return end
            net.Start("Monarch_Tickets_Action")
                net.WriteUInt(state.currentId, 16)
                net.WriteString(act)
            net.SendToServer()
        end
        local function RemoveTicketRowById(id)
            if not state.columns then return end
            local targetRow = nil
            local targetCol = nil
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
                if IsValid(targetCol) then
                    targetCol._count = math.max(0, (targetCol._count or 1) - 1)
                end

                local anyLeft = false
                for _, col in ipairs(state.columns or {}) do
                    if IsValid(col) and IsValid(col._layout) then
                        for _, ch in ipairs(col._layout:GetChildren() or {}) do
                            if IsValid(ch) and ch ~= targetRow then anyLeft = true break end
                        end
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
            if targetRow.AlphaTo then
                targetRow:AlphaTo(0, 0.15, 0, function()
                    if IsValid(targetRow) then targetRow:Remove() end
                    afterRemove()
                end)
            else
                if IsValid(targetRow) then targetRow:Remove() end
                afterRemove()
            end
        end
        local function FormatAge(sec)
            if sec < 0 then sec = 0 end
            if sec < 60 then return string.format("%ds", sec) end
            local m = math.floor(sec / 60)
            local s = sec % 60
            if m < 60 then return string.format("%dm %ds", m, s) end
            local h = math.floor(m / 60)
            m = m % 60
            if h < 24 then return string.format("%dh %dm", h, m) end
            local d = math.floor(h / 24)
            h = h % 24
            return string.format("%dd %dh", d, h)
        end
        local function GetCreatedTS(t)
            if t.created then return tonumber(t.created) or os.time() end
            if t.messages and #t.messages > 0 then
                local earliest = nil
                for _, m in ipairs(t.messages) do
                    local mt = tonumber(m.time)
                    if mt and (not earliest or mt < earliest) then earliest = mt end
                end
                if earliest then return earliest end
            end
            return os.time()
        end
        local function PopulateChat(t)
            state.chatScroll:Clear()
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
                    draw.RoundedBox(radius, 0, 0, pw, ph, bg)
                    surface.SetDrawColor(border)
                    surface.DrawOutlinedRect(0, 0, pw, ph, 1)
                    local who = m.name or (isHandler and "Handler" or (isCreator and "Creator" or "Player"))
                    local when = os.date("%I:%M %p", tonumber(m.time or os.time()))
                    draw.SimpleText(who .. " - " .. when, "InvSmall", 8, 6, Color(244,246,250))
                end
                local text = vgui.Create("DLabel", row)
                text:Dock(FILL)
                text:DockMargin(8, 20, 8, 8)
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
            if IsValid(state.emptyLabel) then state.emptyLabel:Remove() state.emptyLabel = nil end
            state.ticketsCache = payload or {}
            local count = 0
            for _, t in ipairs(state.ticketsCache) do
                local status = string.lower(t.status or "")
                local isClosed = (status == "closed") or (t.closed == true)
                if not isClosed then
                    count = count + 1
                    local col = GetActiveColumn()
                    local row = col._layout:Add("DPanel")
                    row:SetTall(110)
                    row:SetWide(col:GetWide() - 8)
                    row.ticketId = t.id
                    col._count = (col._count or 0) + 1
                    row.Think = nil
                    row.Paint = nil
                    local card = vgui.Create("DPanel", row)
                    card:Dock(FILL)
                    card:DockMargin(8, 0, 8, 0)
                    card.Paint = function(self, pw, ph)
                        local P = GetPalette()
                        surface.SetDrawColor(P.panel)
                        surface.DrawRect(0,0,pw,ph)
                        local border = (state.currentId == t.id) and P.primary or P.outline
                        surface.SetDrawColor(border)
                        surface.DrawOutlinedRect(0,0,pw,ph,2)
                    end
                    local baseTitle = string.format("#%d  %s  [%s]", t.id, t.reporterName or t.reporter or "", (t.status or "open"))
                    local createdTS = GetCreatedTS(t)
                    local function composeTitle()
                        local age = FormatAge(os.time() - createdTS)
                        return string.format("%s - %s", baseTitle, age)
                    end

                    local btnStrip = vgui.Create("DPanel", card)
                    btnStrip:Dock(RIGHT)
                    btnStrip:SetWide(120)
                    btnStrip:DockMargin(6,8,8,8)
                    btnStrip.Paint = nil

                    local content = vgui.Create("DPanel", card)
                    content:Dock(FILL)
                    content:DockMargin(10,10,0,10)
                    content.Paint = nil

                    local labelBtn = StyledButton(content, composeTitle())
                    labelBtn:Dock(TOP)
                    labelBtn:SetTall(30)
                    labelBtn.Font = "InvSmall" 
                    row._labelBtn = labelBtn
                    labelBtn.Selected = (state.currentId == t.id)
                    local function SelectThisTicket()

                        state.currentId = t.id

                        for _, c in ipairs(state.columns or {}) do
                            if IsValid(c) and IsValid(c._layout) then
                                for _, r in ipairs(c._layout:GetChildren() or {}) do
                                    if IsValid(r) and IsValid(r._labelBtn) then r._labelBtn.Selected = false end
                                end
                            end
                        end
                        labelBtn.Selected = true
                    end
                    labelBtn.DoClick = SelectThisTicket

                    local clickOverlay = vgui.Create("DButton", content)
                    clickOverlay:Dock(FILL)
                    clickOverlay:SetText("")
                    clickOverlay:SetCursor("hand")
                    clickOverlay.Paint = nil
                    clickOverlay.DoClick = function()
                        SelectThisTicket()
                    end
                    row._lastAgeTick = 0
                    row.Think = function(self)
                        local tick = os.time()
                        if self._lastAgeTick ~= tick then
                            self._lastAgeTick = tick
                            labelBtn.ButtonText = composeTitle()
                        end
                    end

                    local function ActionButton(parent, text, bg, border, w, h)
                        local b = vgui.Create("DButton", parent)
                        b:SetText("")
                        b:SetSize(w or 64, h or 26)
                        b.ButtonText = text or ""
                        b.Paint = function(s, pw, ph)
                            local P = GetPalette()
                            local base = bg or P.btn
                            local hov = s:IsHovered()
                            local col = hov and Color(math.min(base.r+12,255), math.min(base.g+12,255), math.min(base.b+12,255)) or base
                            draw.RoundedBox(P.radius or 6, 0, 0, pw, ph, col)
                            surface.SetDrawColor(border or P.outline)
                            surface.DrawOutlinedRect(0,0,pw,ph,1)
                            surface.SetFont("DermaDefaultBold")
                            local tw, th = surface.GetTextSize(s.ButtonText)
                            surface.SetTextColor(255,255,255)
                            surface.SetTextPos(pw/2 - tw/2, ph/2 - th/2)
                            surface.DrawText(s.ButtonText)
                        end
                        return b
                    end

                    local btnClose = ActionButton(btnStrip, "Close", Color(120,40,40), Color(140,60,60))
                    btnClose:Dock(TOP)
                    btnClose:DockMargin(0,0,0,6)
                    btnClose.DoClick = function()
                        net.Start("Monarch_Tickets_Action")
                            net.WriteUInt(t.id, 16)
                            net.WriteString("close")
                        net.SendToServer()

                        timer.Simple(0, function()
                            if not IsValid(frame) then return end
                            net.Start("Monarch_Tickets_RequestList") net.SendToServer()
                        end)
                        if state.currentId == t.id then
                            state.currentId = nil
                            state.chatScroll:Clear()
                            state.inputRow:SetVisible(false)
                            state.actionRow:SetVisible(false)
                            state.chatWrap:SetVisible(false)
                            listWrap:SetVisible(true)
                        end

                        row:SetMouseInputEnabled(false)
                        row:SetKeyboardInputEnabled(false)
                        local function afterRemove()
                            if IsValid(col) then col._count = math.max(0, (col._count or 1) - 1) end
                            local anyLeft = false
                            for _, c in ipairs(state.columns or {}) do
                                if IsValid(c) and IsValid(c._layout) then
                                    for _, ch in ipairs(c._layout:GetChildren() or {}) do
                                        if IsValid(ch) and ch ~= row then anyLeft = true break end
                                    end
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
                        if row.AlphaTo then
                            row:AlphaTo(0, 0.15, 0, function()
                                if IsValid(row) then row:Remove() end
                                afterRemove()
                            end)
                        else
                            if IsValid(row) then row:Remove() end
                            afterRemove()
                        end
                    end

                    local btnClaim = ActionButton(btnStrip, "Claim", Color(40,120,60), Color(60,160,80))
                    btnClaim:Dock(TOP)
                    btnClaim:DockMargin(0,0,0,0)
                    btnClaim.DoClick = function()
                        net.Start("Monarch_Tickets_Action")
                            net.WriteUInt(t.id, 16)
                            net.WriteString("claim")
                        net.SendToServer()

                           state.currentId = t.id
                           state.forceChatOpenId = t.id

                           for _, c in ipairs(state.columns or {}) do
                               if IsValid(c) and IsValid(c._layout) then
                                   for _, r in ipairs(c._layout:GetChildren() or {}) do
                                       if IsValid(r) and IsValid(r._labelBtn) then r._labelBtn.Selected = false end
                                   end
                               end
                           end
                           if IsValid(row) and IsValid(row._labelBtn) then row._labelBtn.Selected = true end
                           listWrap:SetVisible(false)
                           state.chatWrap:SetVisible(true)
                           state.chatScroll:SetVisible(true)
                           state.inputRow:SetVisible(true)
                           state.actionRow:SetVisible(true)
                           state.entry:SetPlaceholderText(string.format("Reply to #%d...", t.id))
                           PopulateChat(t)
                           if IsValid(state.plusBtn) then state.plusBtn:SetVisible(false) end
                    end

                    local function getOriginalMessage()
                        if t.messages and #t.messages > 0 then

                            local first = t.messages[1]
                            if first and first.text and first.text ~= "" then return first.text end

                            local earliest, emsg
                            for _, m in ipairs(t.messages) do
                                if m and m.text and m.text ~= "" then
                                    if not earliest or (m.time or 0) < earliest then
                                        earliest = m.time or 0
                                        emsg = m.text
                                    end
                                end
                            end
                            return emsg or ""
                        end
                        return t.text or t.message or ""
                    end
                    local preview = vgui.Create("DLabel", content)
                    preview:Dock(FILL)
                    preview:DockMargin(4,6,8,4)
                    preview:SetFont("DermaDefault")
                    preview:SetTextColor(GetPalette().text)
                    preview:SetWrap(true)
                    preview:SetAutoStretchVertical(true)
                    local msg = getOriginalMessage() or ""
                    if #msg > 240 then msg = string.sub(msg,1,237).."..." end
                    preview:SetText(msg)
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
            local text = string.Trim(self:GetText() or "")
            if text == "" then return end
            local MAXLEN = 75
            if #text > MAXLEN then text = string.sub(text, 1, MAXLEN) end
            net.Start("Monarch_Tickets_Message")
                net.WriteUInt(state.currentId, 16)
                net.WriteString(text)
                net.WriteString("admin")
            net.SendToServer()
            self:SetText("")
        end

        do
            local pad = 6
            local btnClose = PanelControlButton(actionRow, "✕")
            btnClose:Dock(RIGHT)
            btnClose:DockMargin(pad,pad,pad,pad)
            btnClose:SetWide(40)
            btnClose.DoClick = function()
                if not state.currentId then return end
                SendActionCurrent("close")
                RemoveTicketRowById(state.currentId)

                timer.Simple(0, function()
                    if not IsValid(frame) then return end
                    net.Start("Monarch_Tickets_RequestList") net.SendToServer()
                end)
            end

            local btnCreator = StyledButton(actionRow, "Item Creator")
            btnCreator:Dock(LEFT)
            btnCreator:DockMargin(pad,pad,0,pad)
            btnCreator:SetWide(120)
            btnCreator.DoClick = function()
                if RunConsoleCommand then RunConsoleCommand("monarch_itemcreator") end
            end

            local btnCopy = StyledButton(actionRow, "Copy SID64")
            actionRow.btnCopySID = btnCopy
            btnCopy:Dock(LEFT)
            btnCopy:DockMargin(pad,pad,0,pad)
            btnCopy:SetWide(120)
            btnCopy.DoClick = function()
                if not state.currentId then return end
                local tk = GetTicketById(state.currentId)
                local sid = tk and (tk.reporter or tk.reporterId)
                if sid and sid ~= "" then
                    if SetClipboardText then SetClipboardText(tostring(sid)) end
                    surface.PlaySound("menu/ui_click.mp3")
                end
            end

            local btnGoto = StyledButton(actionRow, "Goto")
            btnGoto:Dock(LEFT)
            btnGoto:DockMargin(pad,pad,0,pad)
            btnGoto:SetWide(80)
            btnGoto.DoClick = function()
                if not state.currentId then return end
                SendActionCurrent("goto")
            end

            local btnBring = StyledButton(actionRow, "Bring")
            btnBring:Dock(LEFT)
            btnBring:DockMargin(pad,pad,0,pad)
            btnBring:SetWide(80)
            btnBring.DoClick = function()
                if not state.currentId then return end
                SendActionCurrent("bring")
            end
        end

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
                    listWrap:SetVisible(false)
                    state.chatWrap:SetVisible(true)
                    state.chatScroll:SetVisible(true)
                    state.inputRow:SetVisible(true)
                    state.actionRow:SetVisible(true)
                    if IsValid(state.plusBtn) then state.plusBtn:SetVisible(false) end
                elseif claimed then
                    listWrap:SetVisible(false)
                    state.chatWrap:SetVisible(true)
                    state.chatScroll:SetVisible(true)
                    state.inputRow:SetVisible(true)
                    state.actionRow:SetVisible(true)
                    if IsValid(state.plusBtn) then state.plusBtn:SetVisible(false) end
                else
                            state.chatWrap:SetVisible(false)
                            listWrap:SetVisible(true)
                            if IsValid(state.plusBtn) then state.plusBtn:SetVisible(true) end
                    if IsValid(state.plusBtn) then state.plusBtn:SetVisible(true) end
                end
            end
        }

        net.Start("Monarch_Tickets_RequestList") net.SendToServer()

        state.inputRow:SetVisible(false)
        state.actionRow:SetVisible(false)
    end

    BuildToolsView = function()
        ClearRight()
        local container = vgui.Create("DPanel", right)
        container:Dock(FILL)
        container.Paint = nil
        local layout = vgui.Create("DIconLayout", container)
        layout:Dock(FILL)
        layout:SetSpaceX(10)
        layout:SetSpaceY(10)
        layout:DockMargin(10,10,10,10)

        local btnCreator = StyledButton(layout, "Item Creator")
        btnCreator:SetSize(180, 42)
        btnCreator.DoClick = function()
            if RunConsoleCommand then RunConsoleCommand("monarch_itemcreator") end
        end

        local btnTools = StyledButton(layout, "Tools")
        btnTools:SetSize(180, 42)
        btnTools.DoClick = function()
            net.Start("Monarch_Tools_GiveTools")
            net.SendToServer()
        end

        if LocalPlayer() and LocalPlayer().IsSuperAdmin and LocalPlayer():IsSuperAdmin() then
            local btnZones = StyledButton(layout, "Zone Manager")
            btnZones:SetSize(180, 42)
            btnZones.DoClick = function()
                if Monarch and Monarch.OpenZoneManager then
                    Monarch.OpenZoneManager()
                else
                    chat.AddText(Color(255, 100, 100), "[Error] Zone Manager not available.")
                end
            end
        end

        local btnBan = StyledButton(layout, "Ban")
        btnBan:SetSize(180, 42)
        btnBan.DoClick = function()
            local dlg = vgui.Create("DFrame")
            dlg:SetSize(520, 360)
            dlg:Center(); dlg:SetTitle(""); dlg:ShowCloseButton(false); dlg:MakePopup()
            dlg.topBarH = 28
            dlg.Paint = function(s,w,h)
                surface.SetDrawColor(28,28,28,255); surface.DrawRect(0,0,w,h)
                surface.SetDrawColor(90,90,90,255); surface.DrawOutlinedRect(0,0,w,h,1)
                draw.SimpleText("Ban Player", "InvMed", 12, 8, color_white)
            end
            local closeBtn = PanelControlButton(dlg, "✕"); closeBtn:SetSize(24,20)
            closeBtn:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2))
            closeBtn.DoClick = function() dlg:Close() end
            closeBtn.Think = function(s) s:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)) end
            local body = vgui.Create("DPanel", dlg); body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint=nil
            local pRow = vgui.Create("DPanel", body); pRow:Dock(TOP); pRow:SetTall(28); pRow.Paint=nil
            local lblP = vgui.Create("DLabel", pRow); lblP:Dock(LEFT); lblP:SetWide(70); lblP:SetText("Target:"); lblP:SetFont("DermaDefaultBold")
            local cmb = vgui.Create("DComboBox", pRow); cmb:Dock(FILL)
            for _,p in player.Iterator() do cmb:AddChoice(p:Nick(), p) end
            local rRow = vgui.Create("DPanel", body); rRow:Dock(TOP); rRow:SetTall(28); rRow:DockMargin(0,6,0,0); rRow.Paint=nil
            local lblM = vgui.Create("DLabel", rRow); lblM:Dock(LEFT); lblM:SetWide(70); lblM:SetText("Minutes:"); lblM:SetFont("DermaDefaultBold")
            local minEntry = vgui.Create("DTextEntry", rRow); minEntry:Dock(FILL); minEntry:SetNumeric(true); minEntry:SetUpdateOnType(false); minEntry:SetText("60")
            local eRow = vgui.Create("DPanel", body); eRow:Dock(FILL); eRow:DockMargin(0,6,0,0); eRow.Paint=nil
            local lblR = vgui.Create("DLabel", eRow); lblR:Dock(TOP); lblR:SetText("Reason:"); lblR:SetFont("DermaDefaultBold")
            local entry = vgui.Create("DTextEntry", eRow); entry:Dock(FILL); entry:SetMultiline(true)

            local aRow = vgui.Create("DPanel", body); aRow:Dock(BOTTOM); aRow:SetTall(36); aRow.Paint=nil; aRow:DockMargin(0,8,0,0)
            local ok = StyledButton(aRow, "Ban"); ok:Dock(RIGHT); ok:SetWide(90); ok:DockMargin(8,0,0,0)
            ok.DoClick = function()
                local _, plyEnt = cmb:GetSelected()
                if IsValid(plyEnt) then
                    local mins = tonumber(minEntry:GetText()) or 0
                    net.Start("Monarch_Tools_Ban")
                        net.WriteEntity(plyEnt)
                        net.WriteUInt(math.max(0, math.floor(mins)) % 65536, 16)
                        net.WriteString(string.sub(entry:GetValue() or "",1,200))
                    net.SendToServer()
                    dlg:Close()
                end
            end
            local cancel = StyledButton(aRow, "Cancel"); cancel:Dock(RIGHT); cancel:SetWide(90); cancel.DoClick=function() dlg:Close() end
        end

        local btnWarn = StyledButton(layout, "Warn")
        btnWarn:SetSize(180, 42)
        btnWarn.DoClick = function()
            local dlg = vgui.Create("DFrame")
            dlg:SetSize(380, 220)
            dlg:Center(); dlg:SetTitle(""); dlg:ShowCloseButton(false); dlg:MakePopup()
            dlg.topBarH = 28
            dlg.Paint = function(s,w,h)
                surface.SetDrawColor(28,28,28,255); surface.DrawRect(0,0,w,h)
                surface.SetDrawColor(90,90,90,255); surface.DrawOutlinedRect(0,0,w,h,1)
                draw.SimpleText("Warn Player", "InvMed", 12, 8, color_white)
            end
            local closeBtn = PanelControlButton(dlg, "✕"); closeBtn:SetSize(24,20)
            closeBtn:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2))
            closeBtn.DoClick = function() dlg:Close() end
            closeBtn.Think = function(s) s:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)) end
            local body = vgui.Create("DPanel", dlg); body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint=nil
            local pRow = vgui.Create("DPanel", body); pRow:Dock(TOP); pRow:SetTall(28); pRow.Paint=nil
            local lblP = vgui.Create("DLabel", pRow); lblP:Dock(LEFT); lblP:SetWide(70); lblP:SetText("Target:"); lblP:SetFont("DermaDefaultBold")
            local cmb = vgui.Create("DComboBox", pRow); cmb:Dock(FILL)
            for _,p in player.Iterator() do cmb:AddChoice(p:Nick(), p) end
            local eRow = vgui.Create("DPanel", body); eRow:Dock(FILL); eRow:DockMargin(0,6,0,0); eRow.Paint=nil
            local lblR = vgui.Create("DLabel", eRow); lblR:Dock(TOP); lblR:SetText("Reason:"); lblR:SetFont("DermaDefaultBold")
            local entry = vgui.Create("DTextEntry", eRow); entry:Dock(FILL); entry:SetMultiline(true)

            local aRow = vgui.Create("DPanel", body); aRow:Dock(BOTTOM); aRow:SetTall(36); aRow.Paint=nil; aRow:DockMargin(0,8,0,0)
            local ok = StyledButton(aRow, "Warn"); ok:Dock(RIGHT); ok:SetWide(90); ok:DockMargin(8,0,0,0)
            ok.DoClick = function()
                local _, plyEnt = cmb:GetSelected()
                if IsValid(plyEnt) then
                    net.Start("Monarch_Tools_Warn")
                        net.WriteEntity(plyEnt)
                        net.WriteString(string.sub(entry:GetValue() or "",1,300))
                    net.SendToServer()
                    dlg:Close()
                end
            end
            local cancel = StyledButton(aRow, "Cancel"); cancel:Dock(RIGHT); cancel:SetWide(90); cancel.DoClick=function() dlg:Close() end
        end

        local btnKick = StyledButton(layout, "Kick")
        btnKick:SetSize(180, 42)
        btnKick.DoClick = function()
            local dlg = vgui.Create("DFrame")
            dlg:SetSize(380, 220)
            dlg:Center(); dlg:SetTitle(""); dlg:ShowCloseButton(false); dlg:MakePopup(); dlg.topBarH = 28
            dlg.Paint = function(s,w,h)
                surface.SetDrawColor(28,28,28,255); surface.DrawRect(0,0,w,h)
                surface.SetDrawColor(90,90,90,255); surface.DrawOutlinedRect(0,0,w,h,1)
                draw.SimpleText("Kick Player", "InvMed", 12, 8, color_white)
            end
            local closeBtn = PanelControlButton(dlg, "✕"); closeBtn:SetSize(24,20)
            closeBtn:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2))
            closeBtn.DoClick = function() dlg:Close() end
            closeBtn.Think = function(s) s:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)) end
            local body = vgui.Create("DPanel", dlg); body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint=nil
            local pRow = vgui.Create("DPanel", body); pRow:Dock(TOP); pRow:SetTall(28); pRow.Paint=nil
            local lblP = vgui.Create("DLabel", pRow); lblP:Dock(LEFT); lblP:SetWide(70); lblP:SetText("Target:"); lblP:SetFont("DermaDefaultBold")
            local cmb = vgui.Create("DComboBox", pRow); cmb:Dock(FILL)
            for _,p in player.Iterator() do cmb:AddChoice(p:Nick(), p) end
            local eRow = vgui.Create("DPanel", body); eRow:Dock(FILL); eRow:DockMargin(0,6,0,0); eRow.Paint=nil
            local lblR = vgui.Create("DLabel", eRow); lblR:Dock(TOP); lblR:SetText("Reason:"); lblR:SetFont("DermaDefaultBold")
            local entry = vgui.Create("DTextEntry", eRow); entry:Dock(FILL); entry:SetMultiline(true)
            local aRow = vgui.Create("DPanel", body); aRow:Dock(BOTTOM); aRow:SetTall(36); aRow.Paint=nil; aRow:DockMargin(0,8,0,0)
            local ok = StyledButton(aRow, "Kick"); ok:Dock(RIGHT); ok:SetWide(90); ok:DockMargin(8,0,0,0)
            ok.DoClick = function()
                local _, plyEnt = cmb:GetSelected()
                if IsValid(plyEnt) then
                    net.Start("Monarch_Tools_Kick")
                        net.WriteEntity(plyEnt)
                        net.WriteString(string.sub(entry:GetValue() or "",1,200))
                    net.SendToServer()
                    dlg:Close()
                end
            end
            local cancel = StyledButton(aRow, "Cancel"); cancel:Dock(RIGHT); cancel:SetWide(90); cancel.DoClick=function() dlg:Close() end
        end

        local btnNotes = StyledButton(layout, "Player Notes")
        btnNotes:SetSize(180, 42)
        btnNotes.DoClick = function()
            local dlg = vgui.Create("DFrame"); dlg:SetSize(520, 420); dlg:Center(); dlg:SetTitle(""); dlg:ShowCloseButton(false); dlg:MakePopup()
            dlg.topBarH = 28
            dlg.Paint=function(s,w,h) surface.SetDrawColor(28,28,28,255); surface.DrawRect(0,0,w,h); surface.SetDrawColor(90,90,90,255); surface.DrawOutlinedRect(0,0,w,h,1); draw.SimpleText("Player Notes","InvMed",12,8,color_white) end
            local closeBtn = PanelControlButton(dlg, "✕"); closeBtn:SetSize(24,20)
            closeBtn:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2))
            closeBtn.DoClick = function() dlg:Close() end
            closeBtn.Think = function(s) s:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)) end
            local body = vgui.Create("DPanel", dlg); body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint=nil
            local top = vgui.Create("DPanel", body); top:Dock(TOP); top:SetTall(28); top.Paint=nil
            local lbl = vgui.Create("DLabel", top); lbl:Dock(LEFT); lbl:SetWide(90); lbl:SetText("Target SID64:"); lbl:SetFont("DermaDefaultBold")
            local sidEntry = vgui.Create("DTextEntry", top); sidEntry:Dock(FILL)
            local refresh = StyledButton(top, "Load"); refresh:Dock(RIGHT); refresh:SetWide(80)

            local selRow = vgui.Create("DPanel", body); selRow:Dock(TOP); selRow:SetTall(28); selRow:DockMargin(0,6,0,0); selRow.Paint=nil
            local selLbl = vgui.Create("DLabel", selRow); selLbl:Dock(LEFT); selLbl:SetWide(90); selLbl:SetText("Select Player:"); selLbl:SetFont("DermaDefaultBold")
            local selCmb = vgui.Create("DComboBox", selRow); selCmb:Dock(FILL)
            for _,p in player.Iterator() do selCmb:AddChoice(p:Nick(), p) end
            local useBtn = StyledButton(selRow, "Use"); useBtn:Dock(RIGHT); useBtn:SetWide(70); useBtn:DockMargin(8,0,0,0)
            useBtn.DoClick = function()
                local _, plyEnt = selCmb:GetSelected()
                if IsValid(plyEnt) then sidEntry:SetText(plyEnt:SteamID64() or "") end
            end
            local list = vgui.Create("DScrollPanel", body); list:Dock(FILL); list:DockMargin(0,6,0,0)
            local addRow = vgui.Create("DPanel", body); addRow:Dock(BOTTOM); addRow:SetTall(80); addRow:DockMargin(0,8,0,0); addRow.Paint=nil
            local addEntry = vgui.Create("DTextEntry", addRow); addEntry:Dock(FILL); addEntry:SetMultiline(true)
            local addBtn = StyledButton(addRow, "Add Note"); addBtn:Dock(RIGHT); addBtn:SetWide(100); addBtn:DockMargin(8,0,0,0)
            local function renderNotes(sid, arr)
                list:Clear()
                for idx, rec in ipairs(arr or {}) do
                    local p = vgui.Create("DPanel", list); p:Dock(TOP); p:DockMargin(0,0,0,6); p:SetTall(40); p.Paint=function(s,w,h)
                        surface.SetDrawColor(36,36,40); surface.DrawRect(0,0,w,h)
                        surface.SetDrawColor(110,110,120); surface.DrawOutlinedRect(0,0,w,h,1)
                        draw.SimpleText(os.date("%Y-%m-%d %H:%M", rec.time or os.time()), "DermaDefaultBold", 8, 4, color_white)
                        draw.SimpleText((rec.adminName or rec.admin or "") .. ":", "DermaDefault", 8, 22, Color(220,220,220))
                        draw.SimpleText(rec.text or rec.reason or "", "DermaDefault", 120, 22, Color(235,235,235))
                    end

                    local del = vgui.Create("DButton", p)
                    del:SetText("×")
                    del:SetFont("DermaDefaultBold")
                    del:SetSize(24, 20)
                    del:SetPos(p:GetWide() - 28, 10)
                    del:SetTextColor(color_white)
                    del.Paint = function(s, pw, ph)
                        local bg = s:IsHovered() and Color(200,70,70) or Color(160,55,55)
                        surface.SetDrawColor(bg)
                        surface.DrawRect(0, 0, pw, ph)

                        local outline = s:IsHovered() and Color(235,120,120) or Color(215,100,100)
                        surface.SetDrawColor(outline)
                        surface.DrawOutlinedRect(0, 0, pw, ph, 1)
                    end
                    del.DoClick = function()
                        surface.PlaySound("buttons/button10.wav")
                        net.Start("Monarch_Tools_RemoveNote")
                            net.WriteString(sid)
                            net.WriteUInt(idx, 16)
                        net.SendToServer()
                        timer.Simple(0.05, function() refresh:DoClick() end)
                    end
                    del.Think = function(s)
                        if not IsValid(p) then return end
                        s:SetPos(p:GetWide() - 28, 10)
                    end
                end
            end
            refresh.DoClick = function()
                local sid = string.Trim(sidEntry:GetText() or "")
                if sid ~= "" then
                    net.Start("Monarch_Tools_GetNotes"); net.WriteString(sid); net.SendToServer()
                end
            end
            addBtn.DoClick = function()
                local sid = string.Trim(sidEntry:GetText() or "")
                local txt = string.Trim(addEntry:GetValue() or "")
                if sid ~= "" and txt ~= "" then
                    net.Start("Monarch_Tools_AddNote"); net.WriteString(sid); net.WriteString(txt); net.SendToServer()
                    timer.Simple(0.1, function() if IsValid(dlg) then refresh:DoClick() end end)
                    addEntry:SetText("")
                end
            end

            local hookID = "MonarchNotes_" .. tostring(dlg)
            net.Receive("Monarch_Tools_NotesData", function()
                if not IsValid(dlg) then return end
                local sid = net.ReadString()
                local arr = net.ReadTable() or {}
                renderNotes(sid, arr)
            end)
            dlg.OnRemove = function() net.Receivers["Monarch_Tools_NotesData"] = nil end
        end

        local btnWarns = StyledButton(layout, "View Warns")
        btnWarns:SetSize(180, 42)
        btnWarns.DoClick = function()
            local dlg = vgui.Create("DFrame"); dlg:SetSize(520, 420); dlg:Center(); dlg:SetTitle(""); dlg:ShowCloseButton(false); dlg:MakePopup()
            dlg.topBarH = 28
            dlg.Paint=function(s,w,h) surface.SetDrawColor(28,28,28,255); surface.DrawRect(0,0,w,h); surface.SetDrawColor(90,90,90,255); surface.DrawOutlinedRect(0,0,w,h,1); draw.SimpleText("Player Warns","InvMed",12,8,color_white) end
            local closeBtn = PanelControlButton(dlg, "✕"); closeBtn:SetSize(24,20)
            closeBtn:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2))
            closeBtn.DoClick = function() dlg:Close() end
            closeBtn.Think = function(s) s:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)) end
            local body = vgui.Create("DPanel", dlg); body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint=nil
            local top = vgui.Create("DPanel", body); top:Dock(TOP); top:SetTall(28); top.Paint=nil
            local lbl = vgui.Create("DLabel", top); lbl:Dock(LEFT); lbl:SetWide(90); lbl:SetText("Target SID64:"); lbl:SetFont("DermaDefaultBold")
            local sidEntry = vgui.Create("DTextEntry", top); sidEntry:Dock(FILL)
            local refresh = StyledButton(top, "Load"); refresh:Dock(RIGHT); refresh:SetWide(80)

            local selRow = vgui.Create("DPanel", body); selRow:Dock(TOP); selRow:SetTall(28); selRow:DockMargin(0,6,0,0); selRow.Paint=nil
            local selLbl = vgui.Create("DLabel", selRow); selLbl:Dock(LEFT); selLbl:SetWide(90); selLbl:SetText("Select Player:"); selLbl:SetFont("DermaDefaultBold")
            local selCmb = vgui.Create("DComboBox", selRow); selCmb:Dock(FILL)
            for _,p in player.Iterator() do selCmb:AddChoice(p:Nick(), p) end
            local useBtn = StyledButton(selRow, "Use"); useBtn:Dock(RIGHT); useBtn:SetWide(70); useBtn:DockMargin(8,0,0,0)
            useBtn.DoClick = function()
                local _, plyEnt = selCmb:GetSelected()
                if IsValid(plyEnt) then sidEntry:SetText(plyEnt:SteamID64() or "") end
            end
            local list = vgui.Create("DScrollPanel", body); list:Dock(FILL); list:DockMargin(0,6,0,0)
            local function renderWarns(sid, arr)
                list:Clear()
                if not arr or #arr == 0 then
                    local empty = vgui.Create("DLabel", list)
                    empty:SetText("No warnings found for this player.")
                    empty:SetFont("DermaDefault")
                    empty:SetTextColor(Color(180,180,180))
                    empty:Dock(TOP)
                    empty:SetTall(30)
                    empty:SetContentAlignment(5)
                    return
                end
                for idx, rec in ipairs(arr) do
                    local p = vgui.Create("DPanel", list); p:Dock(TOP); p:DockMargin(0,0,0,6); p:SetTall(40); p.Paint=function(s,w,h)
                        surface.SetDrawColor(40,36,36); surface.DrawRect(0,0,w,h)
                        surface.SetDrawColor(120,90,90); surface.DrawOutlinedRect(0,0,w,h,1)
                        draw.SimpleText(os.date("%Y-%m-%d %H:%M", rec.time or os.time()), "DermaDefaultBold", 8, 4, Color(255,200,200))
                        draw.SimpleText((rec.adminName or rec.admin or "") .. ":", "DermaDefault", 8, 22, Color(220,180,180))
                        draw.SimpleText(rec.reason or "", "DermaDefault", 120, 22, Color(255,220,220))
                    end

                    local del = vgui.Create("DButton", p)
                    del:SetText("×")
                    del:SetFont("DermaDefaultBold")
                    del:SetSize(24, 20)
                    del:SetPos(p:GetWide() - 28, 10)
                    del:SetTextColor(color_white)
                    del.Paint = function(s, pw, ph)
                        local bg = s:IsHovered() and Color(200,70,70) or Color(160,55,55)
                        surface.SetDrawColor(bg)
                        surface.DrawRect(0, 0, pw, ph)
                        local outline = s:IsHovered() and Color(235,120,120) or Color(215,100,100)
                        surface.SetDrawColor(outline)
                        surface.DrawOutlinedRect(0, 0, pw, ph, 1)
                    end
                    del.DoClick = function()
                        surface.PlaySound("buttons/button10.wav")
                        if rec.id then
                            net.Start("Monarch_Tools_RemoveWarnById")
                                net.WriteString(sid)
                                net.WriteString(tostring(rec.id))
                            net.SendToServer()
                        else
                            net.Start("Monarch_Tools_RemoveWarn")
                                net.WriteString(sid)
                                net.WriteUInt(idx, 16)
                            net.SendToServer()
                        end
                        timer.Simple(0.1, function() if IsValid(dlg) then refresh:DoClick() end end)
                    end
                    del.Think = function(s)
                        if not IsValid(p) then return end
                        s:SetPos(p:GetWide() - 28, 10)
                    end
                end
            end
            refresh.DoClick = function()
                local sid = string.Trim(sidEntry:GetText() or "")
                if sid ~= "" then
                    net.Start("Monarch_Tools_GetWarns"); net.WriteString(sid); net.SendToServer()
                end
            end

            local hookID = "MonarchWarns_" .. tostring(dlg)
            net.Receive("Monarch_Tools_WarnsData", function()
                if not IsValid(dlg) then return end
                local sid = net.ReadString()
                local arr = net.ReadTable() or {}
                renderWarns(sid, arr)
            end)
            dlg.OnRemove = function() net.Receivers["Monarch_Tools_WarnsData"] = nil end
        end

        local btnSearchInv = StyledButton(layout, "Search Inventory")
        btnSearchInv:SetSize(180, 42)
        btnSearchInv.DoClick = function()
            local dlg = vgui.Create("DFrame"); dlg:SetSize(420, 400); dlg:Center(); dlg:SetTitle(""); dlg:ShowCloseButton(false); dlg:MakePopup()
            dlg.topBarH = 32
            
            if Monarch and Monarch.Theme and Monarch.Theme.AttachSkin then
                Monarch.Theme.AttachSkin(dlg)
            end
            
            -- Title label
            local titleLabel = vgui.Create("DLabel", dlg)
            titleLabel:Dock(TOP)
            titleLabel:SetTall(32)
            titleLabel:DockMargin(8, 6, 8, 6)
            titleLabel:SetText("Search Inventory")
            titleLabel:SetTextColor(Color(200, 200, 200))
            titleLabel:SetFont("Monarch-LightUI35")

            -- Custom close button
            local closeBtn = vgui.Create("DButton", dlg)
            closeBtn:SetText("×")
            closeBtn:SetTextColor(color_white)
            closeBtn:SetSize(28, 22)
            closeBtn:SetPos(dlg:GetWide() - 28 - 6, 6)
            closeBtn.DoClick = function() if IsValid(dlg) then dlg:Remove() end end

            local body = vgui.Create("DPanel", dlg)
            body:Dock(FILL)
            body:DockMargin(8, 0, 8, 8)
            body.Paint = nil

            -- Player selection section
            local selectRow = vgui.Create("DPanel", body)
            selectRow:Dock(TOP)
            selectRow:SetTall(35)
            selectRow:DockMargin(0, 0, 0, 8)
            selectRow.Paint = nil

            local selectLabel = vgui.Create("DLabel", selectRow)
            selectLabel:Dock(LEFT)
            selectLabel:SetWide(80)
            selectLabel:SetText("Player:")
            selectLabel:SetFont("DermaDefaultBold")
            selectLabel:SetTextColor(Color(200, 200, 200))

            local playerCombo = vgui.Create("DComboBox", selectRow)
            playerCombo:Dock(FILL)
            playerCombo:SetValue("Select a player...")
            for _, p in player.Iterator() do
                playerCombo:AddChoice(p:Nick(), p)
            end

            -- Create list view
            local listPanel = vgui.Create("DListView", body)
            listPanel:Dock(FILL)
            listPanel:SetMultiSelect(false)
            listPanel:AddColumn("Item")
            listPanel:AddColumn("Qty")

            local storedContraband = {}
            local storedRegular = {}
            local currentTarget = nil

            -- Handle list item clicks to confiscate
            function listPanel:OnRowSelected(index, row)
                if not IsValid(currentTarget) then return end
                
                -- Get item name from the line
                local itemName = row:GetValue(1)
                
                -- Find the matching item
                for _, contraband in ipairs(storedContraband or {}) do
                    if contraband.name == itemName then
                        net.Start("Monarch_ConfiscateItem_Admin")
                        net.WriteEntity(currentTarget)
                        net.WriteString(contraband.class)
                        net.SendToServer()
                        
                        surface.PlaySound("buttons/button10.wav")
                        self:RemoveLine(index)
                        return
                    end
                end
                
                for _, regular in ipairs(storedRegular or {}) do
                    if regular.name == itemName then
                        net.Start("Monarch_ConfiscateItem_Admin")
                        net.WriteEntity(currentTarget)
                        net.WriteString(regular.class)
                        net.SendToServer()
                        
                        surface.PlaySound("buttons/button10.wav")
                        self:RemoveLine(index)
                        return
                    end
                end
            end

            -- Loading label
            local loadingLabel = vgui.Create("DLabel", body)
            loadingLabel:Dock(TOP)
            loadingLabel:SetText("")
            loadingLabel:SetTextColor(Color(150, 150, 150))
            loadingLabel:SetFont("Monarch-LightUI20")
            loadingLabel:DockMargin(0, 20, 0, 0)

            -- Search button
            local searchBtn = StyledButton(body, "Search Inventory")
            searchBtn:Dock(TOP)
            searchBtn:SetTall(32)
            searchBtn:DockMargin(0, 8, 0, 0)
            
            searchBtn.DoClick = function()
                local _, targetEnt = playerCombo:GetSelected()
                if not IsValid(targetEnt) then
                    loadingLabel:SetText("Please select a player!")
                    loadingLabel:SetTextColor(Color(220, 80, 80))
                    return
                end

                loadingLabel:SetText("Loading inventory...")
                loadingLabel:SetTextColor(Color(150, 150, 150))
                listPanel:Clear()
                currentTarget = targetEnt

                -- Request inventory from server
                net.Start("Monarch_SearchInventory_Admin")
                net.WriteEntity(targetEnt)
                net.SendToServer()
            end

            -- Handle inventory response
            local function OnInventoryResponse()
                if not IsValid(listPanel) or not IsValid(dlg) or not IsValid(loadingLabel) then return end

                local targetFromNet = net.ReadEntity()
                local itemCount = net.ReadUInt(16)

                -- Clear loading label
                loadingLabel:SetText("")

                if itemCount == 0 then
                    listPanel:AddLine("(Empty)", "")
                    return
                end

                -- Store items for sorting
                local contraband_items = {}
                local regular_items = {}

                -- Read all items
                for i = 1, itemCount do
                    local itemClass = net.ReadString()
                    local quantity = net.ReadUInt(16)
                    local itemName = net.ReadString()
                    local isIllegal = net.ReadBool()

                    local itemData = {
                        name = itemName,
                        quantity = quantity,
                        isIllegal = isIllegal,
                        class = itemClass
                    }

                    if isIllegal then
                        table.insert(contraband_items, itemData)
                    else
                        table.insert(regular_items, itemData)

                                    -- Store items for later reference
                                    storedContraband = contraband_items
                                    storedRegular = regular_items
                    end
                end

                -- Add contraband items first (in red)
                for _, item in ipairs(contraband_items) do
                    local line = listPanel:AddLine(item.name, tostring(item.quantity))
                    if IsValid(line) then
                        pcall(function() line:SetTextColor(1, Color(220, 80, 80)) end)
                    end
                end

                -- Add regular items
                for _, item in ipairs(regular_items) do
                    local line = listPanel:AddLine(item.name, tostring(item.quantity))
                    if IsValid(line) then
                        pcall(function() line:SetTextColor(1, Color(200, 200, 200)) end)
                    end
                end
            end

            -- Add listener for inventory response
            net.Receive("Monarch_SearchInventoryResponse_Admin", function()
                OnInventoryResponse()
            end)
        end

        local btnLogs = StyledButton(layout, "MLogs")
        btnLogs:SetSize(180, 42)
        btnLogs.DoClick = function()
            local dlg = vgui.Create("DFrame"); dlg:SetSize(700, 480); dlg:Center(); dlg:SetTitle(""); dlg:ShowCloseButton(false); dlg:MakePopup()
            dlg.topBarH = 28
            dlg.Paint=function(s,w,h) surface.SetDrawColor(28,28,28,255); surface.DrawRect(0,0,w,h); surface.SetDrawColor(90,90,90,255); surface.DrawOutlinedRect(0,0,w,h,1); draw.SimpleText("Admin Logs (MLogs)","InvMed",12,8,color_white) end
            local closeBtn = PanelControlButton(dlg, "✕"); closeBtn:SetSize(24,20)
            closeBtn:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2))
            closeBtn.DoClick = function() dlg:Close() end
            closeBtn.Think = function(s) s:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)) end
            local body = vgui.Create("DPanel", dlg); body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint=nil
            local top = vgui.Create("DPanel", body); top:Dock(TOP); top:SetTall(28); top.Paint=nil
            local lbl = vgui.Create("DLabel", top); lbl:Dock(LEFT); lbl:SetWide(80); lbl:SetText("Show last:"); lbl:SetFont("DermaDefaultBold")
            local cmb = vgui.Create("DComboBox", top); cmb:Dock(LEFT); cmb:SetWide(80); cmb:AddChoice("50", 50, true); cmb:AddChoice("100", 100); cmb:AddChoice("200", 200)
            local btn = StyledButton(top, "Refresh"); btn:Dock(LEFT); btn:SetWide(90); btn:DockMargin(8,0,0,0)
            local list = vgui.Create("DListView", body); list:Dock(FILL); list:DockMargin(0,6,0,0)
            list:AddColumn("Time"); list:AddColumn("Action"); list:AddColumn("Admin"); list:AddColumn("Target"); list:AddColumn("Duration"); list:AddColumn("Reason")
            local function renderLogs(arr)
                list:Clear()
                for _, rec in ipairs(arr or {}) do
                    list:AddLine(os.date("%Y-%m-%d %H:%M", rec.time or os.time()), rec.action or "", rec.adminName or rec.adminSID or "", rec.targetName or rec.targetSID or "", tostring(rec.duration or 0), rec.reason or "")
                end
            end
            btn.DoClick = function()
                local _, val = cmb:GetSelected()
                val = tonumber(val or 100) or 100
                net.Start("Monarch_Tools_GetLogs"); net.WriteUInt(val % 4096, 12); net.SendToServer()
            end

            btn:DoClick()
            net.Receive("Monarch_Tools_LogsData", function()
                local arr = net.ReadTable() or {}
                renderLogs(arr)
            end)
        end

        local btnFreeze = StyledButton(layout, "Freeze/Unfreeze")
        btnFreeze:SetSize(180, 42)
        btnFreeze.DoClick = function()
            local dlg = vgui.Create("DFrame"); dlg:SetSize(360, 160); dlg:Center(); dlg:SetTitle(""); dlg:ShowCloseButton(false); dlg:MakePopup(); dlg.topBarH = 28
            dlg.Paint=function(s,w,h) surface.SetDrawColor(28,28,28,255); surface.DrawRect(0,0,w,h); surface.SetDrawColor(90,90,90,255); surface.DrawOutlinedRect(0,0,w,h,1); draw.SimpleText("Freeze/Unfreeze","InvMed",12,8,color_white) end
            local closeBtn = PanelControlButton(dlg, "✕"); closeBtn:SetSize(24,20); closeBtn:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)); closeBtn.DoClick=function() dlg:Close() end; closeBtn.Think=function(s) s:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)) end
            local body = vgui.Create("DPanel", dlg); body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint=nil
            local row = vgui.Create("DPanel", body); row:Dock(TOP); row:SetTall(28); row.Paint=nil
            local lbl = vgui.Create("DLabel", row); lbl:Dock(LEFT); lbl:SetWide(70); lbl:SetText("Target:"); lbl:SetFont("DermaDefaultBold")
            local cmb = vgui.Create("DComboBox", row); cmb:Dock(FILL)
            for _,p in player.Iterator() do cmb:AddChoice(p:Nick(), p) end
            local aRow = vgui.Create("DPanel", body); aRow:Dock(BOTTOM); aRow:SetTall(36); aRow.Paint=nil; aRow:DockMargin(0,8,0,0)
            local un = StyledButton(aRow, "Unfreeze"); un:Dock(RIGHT); un:SetWide(100)
            un.DoClick = function() local _, t = cmb:GetSelected(); if IsValid(t) then net.Start("Monarch_Tools_Freeze"); net.WriteEntity(t); net.WriteBool(false); net.SendToServer(); dlg:Close() end end
            local fr = StyledButton(aRow, "Freeze"); fr:Dock(RIGHT); fr:SetWide(100); fr:DockMargin(8,0,0,0)
            fr.DoClick = function() local _, t = cmb:GetSelected(); if IsValid(t) then net.Start("Monarch_Tools_Freeze"); net.WriteEntity(t); net.WriteBool(true); net.SendToServer(); dlg:Close() end end
        end

        local btnCloak = StyledButton(layout, "Cloak (toggle)")
        btnCloak:SetSize(180, 42)
        btnCloak.DoClick = function()
            local dlg = vgui.Create("DFrame"); dlg:SetSize(360, 150); dlg:Center(); dlg:SetTitle(""); dlg:ShowCloseButton(false); dlg:MakePopup(); dlg.topBarH = 28
            dlg.Paint=function(s,w,h) surface.SetDrawColor(28,28,28,255); surface.DrawRect(0,0,w,h); surface.SetDrawColor(90,90,90,255); surface.DrawOutlinedRect(0,0,w,h,1); draw.SimpleText("Cloak Player","InvMed",12,8,color_white) end
            local closeBtn = PanelControlButton(dlg, "✕"); closeBtn:SetSize(24,20); closeBtn:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)); closeBtn.DoClick=function() dlg:Close() end; closeBtn.Think=function(s) s:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)) end
            local body = vgui.Create("DPanel", dlg); body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint=nil
            local row = vgui.Create("DPanel", body); row:Dock(TOP); row:SetTall(28); row.Paint=nil
            local lbl = vgui.Create("DLabel", row); lbl:Dock(LEFT); lbl:SetWide(70); lbl:SetText("Target:"); lbl:SetFont("DermaDefaultBold")
            local cmb = vgui.Create("DComboBox", row); cmb:Dock(FILL)
            for _,p in player.Iterator() do cmb:AddChoice(p:Nick(), p) end
            local aRow = vgui.Create("DPanel", body); aRow:Dock(BOTTOM); aRow:SetTall(36); aRow.Paint=nil; aRow:DockMargin(0,8,0,0)
            local ok = StyledButton(aRow, "Toggle"); ok:Dock(RIGHT); ok:SetWide(100)
            ok.DoClick = function() local _, t = cmb:GetSelected(); if IsValid(t) then net.Start("Monarch_Tools_CloakToggle"); net.WriteEntity(t); net.SendToServer(); dlg:Close() end end
        end

        local btnNoclip = StyledButton(layout, "Noclip (toggle)")
        btnNoclip:SetSize(180, 42)
        btnNoclip.DoClick = function()
            net.Start("Monarch_Tools_NoclipToggle"); net.SendToServer()
        end

        local btnBring = StyledButton(layout, "Bring")
        btnBring:SetSize(180, 42)
        btnBring.DoClick = function()
            local dlg = vgui.Create("DFrame"); dlg:SetSize(360, 150); dlg:Center(); dlg:SetTitle(""); dlg:ShowCloseButton(false); dlg:MakePopup(); dlg.topBarH = 28
            dlg.Paint=function(s,w,h) surface.SetDrawColor(28,28,28,255); surface.DrawRect(0,0,w,h); surface.SetDrawColor(90,90,90,255); surface.DrawOutlinedRect(0,0,w,h,1); draw.SimpleText("Bring Player","InvMed",12,8,color_white) end
            local closeBtn = PanelControlButton(dlg, "✕"); closeBtn:SetSize(24,20); closeBtn:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)); closeBtn.DoClick=function() dlg:Close() end; closeBtn.Think=function(s) s:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)) end
            local body = vgui.Create("DPanel", dlg); body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint=nil
            local row = vgui.Create("DPanel", body); row:Dock(TOP); row:SetTall(28); row.Paint=nil
            local lbl = vgui.Create("DLabel", row); lbl:Dock(LEFT); lbl:SetWide(70); lbl:SetText("Target:"); lbl:SetFont("DermaDefaultBold")
            local cmb = vgui.Create("DComboBox", row); cmb:Dock(FILL)
            for _,p in player.Iterator() do if p ~= LocalPlayer() then cmb:AddChoice(p:Nick(), p) end end
            local aRow = vgui.Create("DPanel", body); aRow:Dock(BOTTOM); aRow:SetTall(36); aRow.Paint=nil; aRow:DockMargin(0,8,0,0)
            local ok = StyledButton(aRow, "Bring"); ok:Dock(RIGHT); ok:SetWide(100)
            ok.DoClick = function() local _, t = cmb:GetSelected(); if IsValid(t) then net.Start("Monarch_Tools_Bring"); net.WriteEntity(t); net.SendToServer(); dlg:Close() end end
        end

        local btnGoto = StyledButton(layout, "Goto")
        btnGoto:SetSize(180, 42)
        btnGoto.DoClick = function()
            local dlg = vgui.Create("DFrame"); dlg:SetSize(360, 150); dlg:Center(); dlg:SetTitle(""); dlg:ShowCloseButton(false); dlg:MakePopup(); dlg.topBarH = 28
            dlg.Paint=function(s,w,h) surface.SetDrawColor(28,28,28,255); surface.DrawRect(0,0,w,h); surface.SetDrawColor(90,90,90,255); surface.DrawOutlinedRect(0,0,w,h,1); draw.SimpleText("Goto Player","InvMed",12,8,color_white) end
            local closeBtn = PanelControlButton(dlg, "✕"); closeBtn:SetSize(24,20); closeBtn:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)); closeBtn.DoClick=function() dlg:Close() end; closeBtn.Think=function(s) s:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)) end
            local body = vgui.Create("DPanel", dlg); body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint=nil
            local row = vgui.Create("DPanel", body); row:Dock(TOP); row:SetTall(28); row.Paint=nil
            local lbl = vgui.Create("DLabel", row); lbl:Dock(LEFT); lbl:SetWide(70); lbl:SetText("Target:"); lbl:SetFont("DermaDefaultBold")
            local cmb = vgui.Create("DComboBox", row); cmb:Dock(FILL)
            for _,p in player.Iterator() do if p ~= LocalPlayer() then cmb:AddChoice(p:Nick(), p) end end
            local aRow = vgui.Create("DPanel", body); aRow:Dock(BOTTOM); aRow:SetTall(36); aRow.Paint=nil; aRow:DockMargin(0,8,0,0)
            local ok = StyledButton(aRow, "Goto"); ok:Dock(RIGHT); ok:SetWide(100)
            ok.DoClick = function() local _, t = cmb:GetSelected(); if IsValid(t) then net.Start("Monarch_Tools_Goto"); net.WriteEntity(t); net.SendToServer(); dlg:Close() end end
        end

        local btnSpec = StyledButton(layout, "Spectate")
        btnSpec:SetSize(180, 42)
        btnSpec.DoClick = function()
            local dlg = vgui.Create("DFrame"); dlg:SetSize(380, 160); dlg:Center(); dlg:SetTitle(""); dlg:ShowCloseButton(false); dlg:MakePopup(); dlg.topBarH = 28
            dlg.Paint=function(s,w,h) surface.SetDrawColor(28,28,28,255); surface.DrawRect(0,0,w,h); surface.SetDrawColor(90,90,90,255); surface.DrawOutlinedRect(0,0,w,h,1); draw.SimpleText("Spectate","InvMed",12,8,color_white) end
            local closeBtn = PanelControlButton(dlg, "✕"); closeBtn:SetSize(24,20); closeBtn:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)); closeBtn.DoClick=function() dlg:Close() end; closeBtn.Think=function(s) s:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)) end
            local body = vgui.Create("DPanel", dlg); body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint=nil
            local row = vgui.Create("DPanel", body); row:Dock(TOP); row:SetTall(28); row.Paint=nil
            local lbl = vgui.Create("DLabel", row); lbl:Dock(LEFT); lbl:SetWide(70); lbl:SetText("Target:"); lbl:SetFont("DermaDefaultBold")
            local cmb = vgui.Create("DComboBox", row); cmb:Dock(FILL)
            for _,p in player.Iterator() do if p ~= LocalPlayer() then cmb:AddChoice(p:Nick(), p) end end
            local aRow = vgui.Create("DPanel", body); aRow:Dock(BOTTOM); aRow:SetTall(36); aRow.Paint=nil; aRow:DockMargin(0,8,0,0)
            local stop = StyledButton(aRow, "Stop"); stop:Dock(RIGHT); stop:SetWide(100)
            stop.DoClick = function() net.Start("Monarch_Tools_SpectateStop"); net.SendToServer(); dlg:Close() end
            local start = StyledButton(aRow, "Start"); start:Dock(RIGHT); start:SetWide(100); start:DockMargin(8,0,0,0)
            start.DoClick = function() local _, t = cmb:GetSelected(); if IsValid(t) then net.Start("Monarch_Tools_SpectateStart"); net.WriteEntity(t); net.SendToServer(); dlg:Close() end end
        end

        local btnCleanup = StyledButton(layout, "Cleanup Props")
        btnCleanup:SetSize(180, 42)
        btnCleanup.DoClick = function()
            local dlg = vgui.Create("DFrame"); dlg:SetSize(380, 150); dlg:Center(); dlg:SetTitle(""); dlg:ShowCloseButton(false); dlg:MakePopup(); dlg.topBarH = 28
            dlg.Paint=function(s,w,h) surface.SetDrawColor(28,28,28,255); surface.DrawRect(0,0,w,h); surface.SetDrawColor(90,90,90,255); surface.DrawOutlinedRect(0,0,w,h,1); draw.SimpleText("Cleanup Props","InvMed",12,8,color_white) end
            local closeBtn = PanelControlButton(dlg, "✕"); closeBtn:SetSize(24,20); closeBtn:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)); closeBtn.DoClick=function() dlg:Close() end; closeBtn.Think=function(s) s:SetPos(dlg:GetWide()-28, math.floor((dlg.topBarH-20)/2)) end
            local body = vgui.Create("DPanel", dlg); body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint=nil
            local row = vgui.Create("DPanel", body); row:Dock(TOP); row:SetTall(28); row.Paint=nil
            local lbl = vgui.Create("DLabel", row); lbl:Dock(LEFT); lbl:SetWide(90); lbl:SetText("Player:"); lbl:SetFont("DermaDefaultBold")
            local cmb = vgui.Create("DComboBox", row); cmb:Dock(FILL)
            for _,p in player.Iterator() do cmb:AddChoice(p:Nick(), p) end
            local aRow = vgui.Create("DPanel", body); aRow:Dock(BOTTOM); aRow:SetTall(36); aRow.Paint=nil; aRow:DockMargin(0,8,0,0)
            local ok = StyledButton(aRow, "Cleanup"); ok:Dock(RIGHT); ok:SetWide(100)
            ok.DoClick = function() local _, t = cmb:GetSelected(); if IsValid(t) then net.Start("Monarch_Tools_CleanupProps"); net.WriteEntity(t); net.SendToServer(); dlg:Close() end end
        end
    end

    BuildCustomToolsView = function()
        ClearRight()
        local container = vgui.Create("DPanel", right)
        container:Dock(FILL)
        container.Paint = nil

        local tools = (Monarch and Monarch.GetAdminTools and Monarch.GetAdminTools()) or {}
        if not istable(tools) or #tools == 0 then
            local empty = vgui.Create("DLabel", container)
            empty:Dock(FILL)
            empty:SetText("No custom tools registered")
            empty:SetFont("InvMed")
            empty:SetTextColor(Color(220,220,220))
            empty:SetContentAlignment(5)
            return
        end

        local layout = vgui.Create("DIconLayout", container)
        layout:Dock(FILL)
        layout:SetSpaceX(10)
        layout:SetSpaceY(10)
        layout:DockMargin(10,10,10,10)

        for _, tool in ipairs(tools) do
            if tool and isfunction(tool.onUse) then
                local btn = StyledButton(layout, tostring(tool.label or tool.id or "Tool"))
                btn:SetSize(180, 42)
                btn.DoClick = function()
                    tool.onUse()
                end
            end
        end
    end

    BuildPlayersView = function()
        ClearRight()
        local container = vgui.Create("DPanel", right)
        container:Dock(FILL)
        container.Paint = nil

        local top = vgui.Create("DPanel", container)
        top:Dock(TOP)
        top:SetTall(34)
        top.Paint = function(self,w,h)
            surface.SetDrawColor(30,30,30) surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(90,90,90) surface.DrawOutlinedRect(0,0,w,h,1)
        end
        local refreshPlayers = StyledButton(top, "Refresh Players")
        refreshPlayers:Dock(LEFT)
        refreshPlayers:SetWide(150)
        refreshPlayers:DockMargin(8,4,0,4)
        refreshPlayers.DoClick = function()
            surface.PlaySound("buttons/button14.wav")
            BuildPlayersView()
        end

        local listScroller = vgui.Create("DHorizontalScroller", container)
        listScroller:Dock(FILL)
        listScroller:DockMargin(0,6,0,0)
        listScroller:SetOverlap(-8)

        local function CreateColumn()
            local colW = 480
            local col = vgui.Create("DPanel")
            col:SetWide(colW)
            col.Paint = nil
            function col:Think()
                local h = container:GetTall() - 8
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

        local columns = {}
        local function GetActiveColumn()
            local last = columns[#columns]
            if not IsValid(last) or (last._count or 0) >= 5 then
                last = CreateColumn()
                table.insert(columns, last)
            end
            return last
        end

        local function UsergroupLabel(ug)
            ug = tostring(ug or "user")
            local key = string.lower(ug)

            if Monarch and Monarch.Ranks and Monarch.Ranks.Get then
                local rk = Monarch.Ranks.Get(key)
                if rk then
                    local txt = tostring(rk.name or string.upper(ug))
                    local col = rk.color or Color(210,210,210)
                    return txt, col
                end
            end

            local map = {
                superadmin = { txt = "SUPERADMIN", col = Color(255, 80, 80) },
                admin      = { txt = "ADMIN",      col = Color(80, 140, 255) },
                moderator  = { txt = "MODERATOR",  col = Color(120, 180, 255) },
                operator   = { txt = "OPERATOR",   col = Color(160, 220, 160) },
                owner      = { txt = "OWNER",      col = Color(255, 180, 60) },
                developer  = { txt = "DEVELOPER",  col = Color(255, 90, 140) },
                user       = { txt = "USER",       col = Color(210,210,210) },
            }
            local rec = map[key] or { txt = string.upper(ug), col = Color(210,210,210) }
            return rec.txt, rec.col
        end

        local _players = player.GetAll() or {}
        table.sort(_players, function(a,b)
            if not (IsValid(a) and IsValid(b)) then return IsValid(a) and true or false end
            local aStaff = (a.IsSuperAdmin and a:IsSuperAdmin()) or (a.IsAdmin and a:IsAdmin())
            local bStaff = (b.IsSuperAdmin and b:IsSuperAdmin()) or (b.IsAdmin and b:IsAdmin())
            if aStaff ~= bStaff then return aStaff and true or false end

            local aSA = a.IsSuperAdmin and a:IsSuperAdmin()
            local bSA = b.IsSuperAdmin and b:IsSuperAdmin()
            if aSA ~= bSA then return aSA and true or false end

            local function rankOrder(p)
                local ug = string.lower(p:GetUserGroup() or "user")
                local rk = (Monarch and Monarch.Ranks and Monarch.Ranks.Get and Monarch.Ranks.Get(ug)) or nil
                return (rk and tonumber(rk.order or 0)) or 0
            end
            local ao, bo = rankOrder(a), rankOrder(b)
            if ao ~= bo then return ao < bo end

            local an = string.lower(tostring(a:Nick() or ""))
            local bn = string.lower(tostring(b:Nick() or ""))
            return an < bn
        end)

        for _, ply in ipairs(_players) do
            if IsValid(ply) then
                local col = GetActiveColumn()
                local card = vgui.Create("DPanel")
                card:DockMargin(8,12,8,0)
                card:SetTall(110)
                card:SetWide(col:GetWide() - 12)
                card._hoverLerp = 0
                card.Paint = function(self, pw, ph)

                    self._hoverLerp = Lerp(FrameTime() * 10, self._hoverLerp or 0, self:IsHovered() and 1 or 0)

                    local bg = Color(28,28,30)
                    local bg2 = Color(24,24,26)
                    local border = Color(80,80,90,220)

                    surface.SetDrawColor(bg)
                    surface.DrawRect(0,0,pw,ph)

                    surface.SetDrawColor(20,20,24,180)
                    surface.DrawRect(0, ph-26, pw, 26)

                    surface.SetDrawColor(border)
                    surface.DrawOutlinedRect(0,0,pw,ph,1)

                    local acc = self._ugCol or Color(120,120,120)
                    surface.SetDrawColor(Color(acc.r, acc.g, acc.b, 200))
                    surface.DrawRect(0,0,pw,3)

                    if (self._hoverLerp or 0) > 0.01 then
                        local a = math.floor(self._hoverLerp * 30)
                        surface.SetDrawColor(255,255,255, a)
                        surface.DrawOutlinedRect(0,0,pw,ph,1)
                    end
                end

                local avBorder = vgui.Create("DPanel", card)
                avBorder:SetPos(10, 10)
                avBorder:SetSize(52, 52)
                avBorder.Paint = function(s,w,h)
                    surface.SetDrawColor(40,40,45)
                    surface.DrawRect(0,0,w,h)
                    surface.SetDrawColor(90,90,100)
                    surface.DrawOutlinedRect(0,0,w,h,1)
                end

                local av = vgui.Create("AvatarImage", card)
                av:SetSize(48,48)
                av:SetPos(12, 12)
                if av.SetPlayer then av:SetPlayer(ply, 64) end

                local name = vgui.Create("DLabel", card)
                name:SetPos(72, 12)
                name:SetFont("MonarchSB_Name")
                name:SetTextColor(Color(235,235,235))
                name:SetText(ply:Nick() or "Unknown")
                name:SizeToContents()

                local meta = vgui.Create("DLabel", card)
                meta:SetPos(72, 38)
                meta:SetFont("MonarchSB_Meta")
                meta:SetTextColor(Color(200,200,200))
                meta:SetText(string.format("%d ms  â€¢  %s", tonumber(ply:Ping()) or 0, tostring(ply:SteamID() or "")))
                meta:SizeToContents()

                local ugTxt, ugCol = UsergroupLabel(ply:GetUserGroup())
                card._ugCol = ugCol
                local badge = vgui.Create("DPanel", card)
                badge:SetTall(22)
                surface.SetFont("MonarchSB_Badge")
                local tw, th = surface.GetTextSize(ugTxt)
                badge:SetWide(math.max(80, (tw or 0) + 18))
                badge:SetPos(card:GetWide() - badge:GetWide() - 10, 6)
                function badge:Paint(w,h)
                    local c = ugCol
                    draw.RoundedBox(6, 0, 0, w, h, Color(c.r, c.g, c.b, 42))
                    surface.SetDrawColor(c.r, c.g, c.b, 220)
                    surface.DrawOutlinedRect(0,0,w,h,1)
                    draw.SimpleText(ugTxt, "MonarchSB_Badge", w/2, h/2, Color(235,235,235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                function badge:Think()
                    self:SetPos(card:GetWide() - self:GetWide() - 10, 6)
                end

                local aRow = vgui.Create("DPanel", card)
                aRow:Dock(BOTTOM)
                aRow:SetTall(30)
                aRow.Paint = function(self, pw, ph)
                    surface.SetDrawColor(22,22,24,255)
                    surface.DrawRect(0,0,pw,ph)
                    surface.SetDrawColor(65,65,72,200)
                    surface.DrawOutlinedRect(0,0,pw,ph,1)
                end
                local pad = 6
                local btnSID = StyledButton(aRow, "Copy SID64")
                btnSID:Dock(RIGHT)
                btnSID:DockMargin(pad,4,pad,4)
                btnSID:SetWide(110)
                btnSID.DoClick = function()
                    if SetClipboardText then SetClipboardText(tostring(ply:SteamID64())) end
                    surface.PlaySound("menu/ui_click.mp3")
                end
                local btnBring = StyledButton(aRow, "Bring")
                btnBring:Dock(RIGHT)
                btnBring:DockMargin(0,4,0,4)
                btnBring:SetWide(70)
                btnBring.DoClick = function()
                    net.Start("Monarch_Tickets_Action")
                        net.WriteUInt(0, 16)
                        net.WriteString("bring:"..tostring(ply:SteamID64()))
                    net.SendToServer()
                end
                local btnGoto = StyledButton(aRow, "Goto")
                btnGoto:Dock(RIGHT)
                btnGoto:DockMargin(pad,4,0,4)
                btnGoto:SetWide(70)
                btnGoto.DoClick = function()
                    net.Start("Monarch_Tickets_Action")
                        net.WriteUInt(0, 16)
                        net.WriteString("goto:"..tostring(ply:SteamID64()))
                    net.SendToServer()
                end

                local cmbRole = vgui.Create("DComboBox", aRow)
                cmbRole:Dock(RIGHT)
                cmbRole:DockMargin(pad,4,0,4)
                cmbRole:SetWide(180)
                cmbRole:SetValue("Set Role")
                cmbRole:SetEnabled(LocalPlayer() and LocalPlayer():IsSuperAdmin())
                function cmbRole:Paint(w,h)
                    surface.SetDrawColor(30,30,32)
                    surface.DrawRect(0,0,w,h)
                    surface.SetDrawColor(90,90,98)
                    surface.DrawOutlinedRect(0,0,w,h,1)
                end
                local function populateRoles()
                    cmbRole:Clear()
                    local ranks = (Monarch and Monarch.Ranks and Monarch.Ranks.GetAll and Monarch.Ranks.GetAll()) or {}
                    if ranks and #ranks > 0 then
                        for _, rk in ipairs(ranks) do
                            local id = string.lower(rk.id or "")
                            local label = rk.name or id
                            cmbRole:AddChoice(label, id)
                        end
                    else
                        cmbRole:AddChoice("USER", "user")
                        cmbRole:AddChoice("ADMIN", "admin")
                        cmbRole:AddChoice("SUPERADMIN", "superadmin")
                    end
                end
                local function setCurrentRoleValue()
                    cmbRole._suppress = true
                    local key = string.lower(ply:GetUserGroup() or "user")
                    local choices = cmbRole.Choices or {}
                    local chosen = false
                    for idx, _ in ipairs(choices) do
                        local data = cmbRole:GetOptionData(idx)
                        if tostring(data) == tostring(key) then
                            cmbRole:ChooseOptionID(idx)
                            chosen = true
                            break
                        end
                    end
                    if not chosen then
                        local uTxt = select(1, UsergroupLabel(ply:GetUserGroup())) or "Set Role"
                        cmbRole:SetValue(uTxt)
                    end
                    cmbRole._suppress = false
                end
                populateRoles()
                setCurrentRoleValue()
                function cmbRole:OnSelect(index, value, data)
                    if self._suppress then return end
                    if not (LocalPlayer() and LocalPlayer():IsSuperAdmin()) then
                        surface.PlaySound("buttons/button10.wav")
                        return
                    end
                    local id = self:GetOptionData(index) or data
                    if id and IsValid(ply) then
                        net.Start("Monarch_Staff_SetGroup")
                            net.WriteEntity(ply)
                            net.WriteString(tostring(id))
                        net.SendToServer()
                    end
                end

                local _hookId = "Monarch_PlayersRole_" .. tostring(ply:SteamID64() or ply:Nick() or math.random(1,999999))
                hook.Add("Monarch_RanksUpdated", _hookId, function()
                    if IsValid(cmbRole) then
                        populateRoles()
                        setCurrentRoleValue()
                    end
                end)

                function card:Think()
                    local uTxt, uCol = UsergroupLabel(ply:GetUserGroup())
                    self._ugCol = uCol
                    if IsValid(cmbRole) then

                        local key = string.lower(ply:GetUserGroup() or "user")
                        local choices = cmbRole.Choices or {}
                        local matched = false
                        cmbRole._suppress = true
                        for idx, _ in ipairs(choices) do
                            local data = cmbRole:GetOptionData(idx)
                            if tostring(data) == tostring(key) then
                                matched = true
                                if cmbRole:GetSelectedID() ~= idx then
                                    cmbRole:ChooseOptionID(idx)
                                end
                                break
                            end
                        end
                        if not matched then
                            local cur = cmbRole:GetValue()
                            if tostring(cur) ~= tostring(uTxt) then
                                cmbRole:SetValue(uTxt)
                            end
                        end
                        cmbRole._suppress = false
                    end
                    if IsValid(meta) then meta:SetText(string.format("%d ms  â€¢  %s", tonumber(ply:Ping()) or 0, tostring(ply:SteamID() or ""))) meta:SizeToContents() end
                end

                function card:OnRemove()
                    if _hookId then
                        hook.Remove("Monarch_RanksUpdated", _hookId)
                    end
                end

                col._layout:Add(card)
                col._count = (col._count or 0) + 1
            end
        end
    end

    BuildCharsView = function()
        ClearRight()
        local container = vgui.Create("DPanel", right)
        container:Dock(FILL)
        container.Paint = nil
        local top = vgui.Create("DPanel", container); top:Dock(TOP); top:SetTall(34); top.Paint=function(self,w,h)
            surface.SetDrawColor(30,30,30); surface.DrawRect(0,0,w,h); surface.SetDrawColor(90,90,90); surface.DrawOutlinedRect(0,0,w,h,1)
        end
        local refresh = StyledButton(top, "Refresh"); refresh:Dock(LEFT); refresh:SetWide(90); refresh:DockMargin(8,4,0,4)
        local saveAll = StyledButton(top, "Save All"); saveAll:Dock(LEFT); saveAll:SetWide(90); saveAll:DockMargin(8,4,0,4)
        local list = vgui.Create("DScrollPanel", container); list:Dock(FILL); list:DockMargin(0,6,0,0)
        local pending = {}
        local function render(chars)
            list:Clear(); pending = {}
            for _, c in ipairs(chars or {}) do
                local row = vgui.Create("DPanel", list); row:Dock(TOP); row:SetTall(90); row:DockMargin(0,0,0,8); row.Paint=function(self,w,h)
                    surface.SetDrawColor(30,30,32); surface.DrawRect(0,0,w,h); surface.SetDrawColor(110,110,120); surface.DrawOutlinedRect(0,0,w,h,1)
                end

                local idLbl = vgui.Create("DLabel", row); idLbl:SetPos(8,6); idLbl:SetFont("DermaDefaultBold"); idLbl:SetText("ID "..tostring(c.id).."  ("..tostring(c.steamid)..")"); idLbl:SizeToContents()

                local nameLbl = vgui.Create("DLabel", row); nameLbl:SetPos(8,28); nameLbl:SetText("Name:"); nameLbl:SizeToContents()
                local name = vgui.Create("DTextEntry", row); name:SetPos(60,24); name:SetSize(180,22); name:SetText(c.name or "")

                local mdlLbl = vgui.Create("DLabel", row); mdlLbl:SetPos(250,28); mdlLbl:SetText("Model:"); mdlLbl:SizeToContents()
                local mdl = vgui.Create("DTextEntry", row); mdl:SetPos(300,24); mdl:SetSize(200,22); mdl:SetText(c.model or "")

                local facLbl = vgui.Create("DLabel", row); facLbl:SetPos(8,56); facLbl:SetText("Team:"); facLbl:SizeToContents()
                local teamBox = vgui.Create("DNumberWang", row); teamBox:SetPos(60,52); teamBox:SetSize(60,22); teamBox:SetMin(1); teamBox:SetMax(255); teamBox:SetValue(tonumber(c.team) or 1)

                local skinLbl = vgui.Create("DLabel", row); skinLbl:SetPos(130,56); skinLbl:SetText("Skin:"); skinLbl:SizeToContents()
                local skinBox = vgui.Create("DNumberWang", row); skinBox:SetPos(170,52); skinBox:SetSize(60,22); skinBox:SetMin(0); skinBox:SetMax(255); skinBox:SetValue(tonumber(c.skin) or 0)

                local xpLbl = vgui.Create("DLabel", row); xpLbl:SetPos(240,56); xpLbl:SetText("XP:"); xpLbl:SizeToContents()
                local xpBox = vgui.Create("DNumberWang", row); xpBox:SetPos(270,52); xpBox:SetSize(80,22); xpBox:SetValue(tonumber(c.xp) or 0)
                local moneyLbl = vgui.Create("DLabel", row); moneyLbl:SetPos(360,56); moneyLbl:SetText("Money:"); moneyLbl:SizeToContents()
                local moneyBox = vgui.Create("DNumberWang", row); moneyBox:SetPos(420,52); moneyBox:SetSize(80,22); moneyBox:SetValue(tonumber(c.money) or 0)
                local save = StyledButton(row, "Save"); save:SetSize(80,24); save:SetPos(row:GetWide()-176, row:GetTall()-30); save:SetZPos(10)
                local del = StyledButton(row, "Delete"); del:SetSize(80,24); del:SetPos(row:GetWide()-88, row:GetTall()-30); del:SetZPos(10)
                function row:PerformLayout(w,h)
                    if IsValid(save) then save:SetPos(w-176, h-30) end
                    if IsValid(del) then del:SetPos(w-88, h-30) end
                end
                local function queue()
                    pending[c.id] = {
                        id = c.id,
                        name = name:GetText(),
                        model = mdl:GetText(),
                        team = math.max(1, math.min(255, math.floor(teamBox:GetValue() or 1))),
                        skin = math.max(0, math.min(255, math.floor(skinBox:GetValue() or 0))),
                        xp = math.floor(xpBox:GetValue() or 0),
                        money = math.floor(moneyBox:GetValue() or 0)
                    }
                end
                name.OnChange = queue; mdl.OnChange = queue; teamBox.OnValueChanged = queue; skinBox.OnValueChanged = queue; xpBox.OnValueChanged = queue; moneyBox.OnValueChanged = queue
                local function sendOne(data)
                    net.Start("Monarch_Admin_UpdateChar")
                        net.WriteUInt(data.id, 32)
                        net.WriteString(data.name or "")
                        net.WriteString(data.model or "")
                        net.WriteUInt(data.team or 1, 8)
                        net.WriteUInt(data.skin or 0, 8)
                        net.WriteInt(data.xp or 0, 32)
                        net.WriteInt(data.money or 0, 32)
                    net.SendToServer()
                end
                save.DoClick = function() queue(); if pending[c.id] then sendOne(pending[c.id]) end end
                del.DoClick = function()
                    Derma_Query("Delete character ID "..tostring(c.id).."? This cannot be undone.", "Confirm Delete",
                        "Delete", function()
                            net.Start("Monarch_CharDelete")
                                net.WriteUInt(c.id, 32)
                            net.SendToServer()

                            timer.Simple(0.15, function() if IsValid(refresh) then refresh:DoClick() end end)
                        end,
                        "Cancel")
                end
            end
        end
        refresh.DoClick = function() net.Start("Monarch_Admin_GetAllChars"); net.SendToServer() end
        saveAll.DoClick = function()
            for _, data in pairs(pending) do
                net.Start("Monarch_Admin_UpdateChar")
                    net.WriteUInt(data.id, 32)
                    net.WriteString(data.name or "")
                    net.WriteString(data.model or "")
                    net.WriteUInt(data.team or 1, 8)
                    net.WriteUInt(data.skin or 0, 8)
                    net.WriteInt(data.xp or 0, 32)
                    net.WriteInt(data.money or 0, 32)
                net.SendToServer()
            end
        end

        local dlgId = tostring(container)
        net.Receive("Monarch_Admin_AllChars", function()
            if not IsValid(container) then return end
            local rows = net.ReadTable() or {}
            render(rows)
        end)
        net.Receive("Monarch_Admin_UpdateCharResult", function()
            if not IsValid(container) then return end
            local ok = net.ReadBool(); local id = net.ReadUInt(32)

            surface.PlaySound(ok and "buttons/button14.wav" or "buttons/button10.wav")
        end)

        refresh:DoClick()
    end

    BuildStaffView = function()
        ClearRight()
        if not (LocalPlayer() and LocalPlayer().IsSuperAdmin and LocalPlayer():IsSuperAdmin()) then
            local warn = vgui.Create("DPanel", right)
            warn:Dock(FILL)
            warn.Paint = function(self,w,h)
                surface.SetDrawColor(30,30,32) surface.DrawRect(0,0,w,h)
                draw.SimpleText("Superadmin only", "InvTitle", w*0.5, h*0.5-10, Color(220,80,80), TEXT_ALIGN_CENTER)
            end
            return
        end
        local container = vgui.Create("DPanel", right)
        container:Dock(FILL)
        container.Paint = nil

        if IsValid(frame) then frame._staffContainer = container end

        local top = vgui.Create("DPanel", container)
        top:Dock(TOP)
        top:SetTall(40)
        top.Paint = function(self,w,h)
            surface.SetDrawColor(140,30,30,255); surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(200,60,60,255); surface.DrawOutlinedRect(0,0,w,h,1)
            draw.SimpleText("Staff Manager", "InvTitle", 12, -2, color_white)
        end

        local actions = vgui.Create("DPanel", container)
        actions:Dock(TOP)
        actions:SetTall(36)
        actions:DockMargin(8,8,8,0)
        actions.Paint = nil

        local reloadBtn = StyledButton(actions, "Reload from file")
        reloadBtn:Dock(LEFT)
        reloadBtn:SetWide(160)
        reloadBtn.DoClick = function()
            net.Start("Monarch_Staff_Reload") net.SendToServer()
        end

        local refreshRanksBtn = StyledButton(actions, "Refresh Ranks")
        refreshRanksBtn:Dock(LEFT)
        refreshRanksBtn:SetWide(140)
        refreshRanksBtn:DockMargin(8,0,0,0)
        refreshRanksBtn.DoClick = function()

            net.Start("Monarch_Ranks_RequestSync")
            net.SendToServer()
            surface.PlaySound("buttons/button14.wav")
        end

        local addBtn = StyledButton(actions, "Add Staff")
        addBtn:Dock(LEFT)
        addBtn:SetWide(120)
        addBtn:DockMargin(8,0,0,0)
        addBtn.DoClick = function()
            local dlg = vgui.Create("DFrame")
            dlg:SetSize(380, 210)
            dlg:Center(); dlg:MakePopup(); dlg:SetTitle("")
            dlg:ShowCloseButton(false); dlg:SetDraggable(false)
            dlg.Paint = function(s,w,h)
                surface.SetDrawColor(28,28,28,255) surface.DrawRect(0,0,w,h)
                surface.SetDrawColor(90,90,90,255) surface.DrawOutlinedRect(0,0,w,h,1)
                draw.SimpleText("Add Staff", "InvTitle", 12, 8, color_white)
            end
            local body = vgui.Create("DPanel", dlg)
            body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint = nil

            local plyDrop = vgui.Create("DComboBox", body)
            plyDrop:Dock(TOP); plyDrop:SetTall(26)
            plyDrop:DockMargin(0,0,0,6)
            plyDrop:SetValue("Select Online Player (optional)")
            plyDrop:SetTextColor(Color(230,230,230))
            plyDrop.Paint = function(s,w,h)
                surface.SetDrawColor(40,40,42) surface.DrawRect(0,0,w,h)
                surface.SetDrawColor(100,100,100,200) surface.DrawOutlinedRect(0,0,w,h,1)
            end
            local sid = vgui.Create("DTextEntry", body)
            sid:Dock(TOP); sid:SetTall(26); sid:SetPlaceholderText("SteamID64 or STEAM_... (auto-fills from dropdown)")
            sid:DockMargin(0,6,0,6)
            sid:SetTextColor(Color(230,230,230))
            sid.Paint = function(s,w,h)
                surface.SetDrawColor(40,40,42) surface.DrawRect(0,0,w,h)
                surface.SetDrawColor(100,100,100,200) surface.DrawOutlinedRect(0,0,w,h,1)
                s:DrawTextEntryText(s:GetTextColor(), s:GetHighlightColor(), s:GetCursorColor())
            end
            for _, p in ipairs(player.GetAll() or {}) do
                if IsValid(p) then
                    local label = string.format("%s (%s)", p:Nick(), p:SteamID64())
                    plyDrop:AddChoice(label, p)
                end
            end
            function plyDrop:OnSelect(_, _, data)
                if IsValid(data) and data.SteamID64 then
                    sid:SetText(tostring(data:SteamID64()))
                end
            end

            local cmb = vgui.Create("DComboBox", body)
            cmb:Dock(TOP); cmb:SetTall(26)
            cmb:SetTextColor(Color(230,230,230))
            cmb.Paint = function(s,w,h)
                surface.SetDrawColor(40,40,42) surface.DrawRect(0,0,w,h)
                surface.SetDrawColor(100,100,100,200) surface.DrawOutlinedRect(0,0,w,h,1)
            end

            local function AddRankChoices(c, defaultId)
                c:Clear()

                c:AddChoice("USER", "user", (defaultId or "operator") == "user")
                local ranks = (Monarch and Monarch.Ranks and Monarch.Ranks.GetAll and Monarch.Ranks.GetAll()) or {}
                for _, r in ipairs(ranks) do
                    local perm = string.lower(r.permission or "user")
                    if perm == "admin" or perm == "superadmin" then
                        local id = string.lower(r.id or "")
                        local label = string.upper(r.name or id)
                        c:AddChoice(label, id, (defaultId or "operator") == id)
                    end
                end
            end
            AddRankChoices(cmb, "operator")

            local bar = vgui.Create("DPanel", body)
            bar:Dock(BOTTOM); bar:SetTall(30); bar.Paint = nil
            local ok = StyledButton(bar, "Add")
            ok:Dock(RIGHT); ok:SetWide(90)
            ok.DoClick = function()
                local sidval = string.Trim(sid:GetText() or "")
                local nm = ""

                local selId = cmb.GetSelectedID and cmb:GetSelectedID() or nil
                local chosen = selId and (cmb.GetOptionData and cmb:GetOptionData(selId) or nil) or nil
                if not chosen or chosen == "" then

                    local selText = cmb.GetSelected and cmb:GetSelected() or ""
                    chosen = string.lower(tostring(selText or "operator"))
                end
                if sidval == "" then return end
                net.Start("Monarch_Staff_Add")
                    net.WriteString(sidval)
                    net.WriteString(nm)
                    net.WriteString(chosen or "operator")
                net.SendToServer()
                dlg:Close()
                timer.Simple(0.2, function() net.Start("Monarch_Staff_RequestStats") net.SendToServer() end)
            end
            local cancel = StyledButton(bar, "Cancel")
            cancel:Dock(RIGHT); cancel:SetWide(90); cancel:DockMargin(8,0,0,0)
            cancel.DoClick=function() dlg:Close() end
        end

    local ps = vgui.Create("DPropertySheet", container)
    ps:Dock(FILL)
    ps:DockMargin(8,8,8,8)
    ps:SetFadeTime(0)

    local membersPanel = vgui.Create("DPanel", ps)
    membersPanel:Dock(FILL)
    membersPanel.Paint = nil
    ps:AddSheet("Members", membersPanel, "icon16/group.png")

    local strikesPanel = vgui.Create("DPanel", ps)
    strikesPanel:Dock(FILL)
    strikesPanel.Paint = nil
    ps:AddSheet("Strikes", strikesPanel, "icon16/exclamation.png")

    local ranksPanel = vgui.Create("DPanel", ps)
    ranksPanel:Dock(FILL)
    ranksPanel.Paint = nil
    ps:AddSheet("Ranks", ranksPanel, "icon16/award_star_gold_1.png")

    local ranksScroll = vgui.Create("DScrollPanel", ranksPanel)
    ranksScroll:Dock(FILL)
    ranksScroll:DockMargin(0,0,0,0)

    local ranksTopBar = vgui.Create("DPanel", ranksPanel)
    ranksTopBar:Dock(TOP)
    ranksTopBar:SetTall(40)
    ranksTopBar:DockMargin(0,0,0,8)
    ranksTopBar.Paint = nil

    local addRankBtn = StyledButton(ranksTopBar, "Add New Rank")
    addRankBtn:Dock(LEFT)
    addRankBtn:SetWide(140)
    addRankBtn.DoClick = function()
        local dlg = vgui.Create("DFrame")
        dlg:SetSize(520, 530)
        dlg:Center(); dlg:MakePopup(); dlg:SetTitle("")
        dlg:ShowCloseButton(false); dlg:SetDraggable(false)
        dlg.Paint = function(s,w,h)
            surface.SetDrawColor(28,28,28,255) surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(90,90,90,255) surface.DrawOutlinedRect(0,0,w,h,1)
            draw.SimpleText("Add Rank", "InvTitle", 12, 8, color_white)
        end
        local body = vgui.Create("DPanel", dlg)
        body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint = nil

        local idLbl = vgui.Create("DLabel", body)
        idLbl:Dock(TOP); idLbl:SetText("Rank ID (lowercase, no spaces):"); idLbl:SetFont("InvSmall"); idLbl:SetTextColor(Color(220,220,220)); idLbl:SizeToContents()
        local idBox = vgui.Create("DTextEntry", body)
        idBox:Dock(TOP); idBox:SetTall(26); idBox:DockMargin(0,2,0,8)
        idBox:SetTextColor(Color(230,230,230))
        idBox.Paint = function(s,w,h)
            surface.SetDrawColor(40,40,42) surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(100,100,100,200) surface.DrawOutlinedRect(0,0,w,h,1)
            s:DrawTextEntryText(s:GetTextColor(), s:GetHighlightColor(), s:GetCursorColor())
        end

        local nameLbl = vgui.Create("DLabel", body)
        nameLbl:Dock(TOP); nameLbl:SetText("Display Name:"); nameLbl:SetFont("InvSmall"); nameLbl:SetTextColor(Color(220,220,220)); nameLbl:SizeToContents()
        local nameBox = vgui.Create("DTextEntry", body)
        nameBox:Dock(TOP); nameBox:SetTall(26); nameBox:DockMargin(0,2,0,8)
        nameBox:SetTextColor(Color(230,230,230))
        nameBox.Paint = function(s,w,h)
            surface.SetDrawColor(40,40,42) surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(100,100,100,200) surface.DrawOutlinedRect(0,0,w,h,1)
            s:DrawTextEntryText(s:GetTextColor(), s:GetHighlightColor(), s:GetCursorColor())
        end

        local colorLbl = vgui.Create("DLabel", body)
        colorLbl:Dock(TOP); colorLbl:SetText("Color:"); colorLbl:SetFont("InvSmall"); colorLbl:SetTextColor(Color(220,220,220)); colorLbl:SizeToContents()
        local colorMixer = vgui.Create("DColorMixer", body)
        colorMixer:Dock(TOP); colorMixer:SetTall(150); colorMixer:DockMargin(0,2,0,8)
        colorMixer:SetPalette(true)
        colorMixer:SetAlphaBar(false)
        colorMixer:SetWangs(true)
        colorMixer:SetColor(Color(255, 255, 255))

        local permLbl = vgui.Create("DLabel", body)
        permLbl:Dock(TOP); permLbl:SetText("Permission Level:"); permLbl:SetFont("InvSmall"); permLbl:SetTextColor(Color(220,220,220)); permLbl:SizeToContents()
        local permBox = vgui.Create("DComboBox", body)
        permBox:Dock(TOP); permBox:SetTall(26); permBox:DockMargin(0,2,0,8)
        permBox:SetTextColor(Color(230,230,230))
        permBox.Paint = function(s,w,h)
            surface.SetDrawColor(40,40,42) surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(100,100,100,200) surface.DrawOutlinedRect(0,0,w,h,1)
        end
        permBox:AddChoice("User", "user")
        permBox:AddChoice("Admin", "admin")
        permBox:AddChoice("Super Admin", "superadmin")
        permBox:SetValue("User")

        local orderLbl = vgui.Create("DLabel", body)
        orderLbl:Dock(TOP); orderLbl:SetText("Sort Order (higher = top of list):"); orderLbl:SetFont("InvSmall"); orderLbl:SetTextColor(Color(220,220,220)); orderLbl:SizeToContents()
        local orderBox = vgui.Create("DNumberWang", body)
        orderBox:Dock(TOP); orderBox:SetTall(26); orderBox:DockMargin(0,2,0,8)
        orderBox:SetMin(1); orderBox:SetMax(999); orderBox:SetValue(50)

        local bar = vgui.Create("DPanel", body)
        bar:Dock(BOTTOM); bar:SetTall(30); bar.Paint = nil
        local ok = StyledButton(bar, "Add")
        ok:Dock(RIGHT); ok:SetWide(90)
        ok.DoClick = function()
            local id = string.lower(string.Trim(idBox:GetText() or ""))
            local name = string.Trim(nameBox:GetText() or "")
            local col = colorMixer:GetColor()
            local perm = permBox:GetOptionData(permBox:GetSelectedID()) or "user"
            local order = math.floor(orderBox:GetValue() or 50)

            if id == "" or name == "" then
                surface.PlaySound("buttons/button10.wav")
                return
            end

            net.Start("Monarch_Ranks_Add")
                net.WriteTable({
                    id = id,
                    name = name,
                    color = col,
                    permission = perm,
                    order = order
                })
            net.SendToServer()
            dlg:Close()
            surface.PlaySound("buttons/button14.wav")
            timer.Simple(0.3, function()
                net.Start("Monarch_Ranks_RequestSync")
                net.SendToServer()
            end)
        end
        local cancel = StyledButton(bar, "Cancel")
        cancel:Dock(RIGHT); cancel:SetWide(90); cancel:DockMargin(8,0,0,0)
        cancel.DoClick=function() dlg:Close() end
    end

    local refreshRanksBtn = StyledButton(ranksTopBar, "Refresh")
    refreshRanksBtn:Dock(LEFT)
    refreshRanksBtn:SetWide(100)
    refreshRanksBtn:DockMargin(8,0,0,0)
    refreshRanksBtn.DoClick = function()
        net.Start("Monarch_Ranks_RequestSync")
        net.SendToServer()
    end

    local function PopulateRanks()
        ranksScroll:Clear()

        if not (Monarch and Monarch.Ranks and Monarch.Ranks.GetAll) then
            local warn = vgui.Create("DLabel", ranksScroll)
            warn:Dock(TOP)
            warn:SetText("Ranks system not loaded")
            warn:SetFont("InvMed")
            warn:SetTextColor(Color(255, 100, 100))
            warn:SizeToContents()
            return
        end

        local ranks = Monarch.Ranks.GetAll()
        table.sort(ranks, function(a, b)
            local ao = tonumber(a and a.order or 0) or 0
            local bo = tonumber(b and b.order or 0) or 0

            if ao ~= bo then return ao > bo end

            local an = string.lower(tostring(a and (a.name or a.id) or ""))
            local bn = string.lower(tostring(b and (b.name or b.id) or ""))
            return an < bn
        end)
        for _, rank in ipairs(ranks) do
            local row = vgui.Create("DPanel", ranksScroll)
            row:Dock(TOP)
            row:SetTall(70)
            row:DockMargin(0,0,0,6)
            row.Paint = function(s,w,h)
                surface.SetDrawColor(30,30,32) surface.DrawRect(0,0,w,h)
                surface.SetDrawColor(60,60,60,160) surface.DrawOutlinedRect(0,0,w,h,1)
            end

            local colorBox = vgui.Create("DPanel", row)
            colorBox:SetPos(10, 10)
            colorBox:SetSize(50, 50)
            colorBox.Paint = function(s,w,h)
                surface.SetDrawColor(rank.color or Color(255,255,255))
                surface.DrawRect(0,0,w,h)
                surface.SetDrawColor(80,80,80,200)
                surface.DrawOutlinedRect(0,0,w,h,1)
            end

            local info = vgui.Create("DPanel", row)
            info:SetPos(70, 10)
            info:SetSize(400, 50)
            info.Paint = nil

            local nameLbl = vgui.Create("DLabel", info)
            nameLbl:SetPos(0, 0)
            nameLbl:SetFont("MonarchSB_Name")
            nameLbl:SetTextColor(Color(235,235,235))
            nameLbl:SetText(rank.name or rank.id)
            nameLbl:SizeToContents()

            local detailLbl = vgui.Create("DLabel", info)
            detailLbl:SetPos(0, 24)
            detailLbl:SetFont("MonarchSB_Meta")
            detailLbl:SetTextColor(Color(220,220,220))
            detailLbl:SetText(string.format("ID: %s  â€¢  Permission: %s  â€¢  Order: %d", rank.id or "", rank.permission or "user", rank.order or 0))
            detailLbl:SizeToContents()

            local editBtn = StyledButton(row, "Edit")
            editBtn:SetPos(row:GetWide() - 180, 23)
            editBtn:SetSize(80, 24)
            editBtn.DoClick = function()

                local dlg = vgui.Create("DFrame")
                dlg:SetSize(520, 420)
                dlg:Center(); dlg:MakePopup(); dlg:SetTitle("")
                dlg:ShowCloseButton(false); dlg:SetDraggable(false)
                dlg.Paint = function(s,w,h)
                    surface.SetDrawColor(28,28,28,255) surface.DrawRect(0,0,w,h)
                    surface.SetDrawColor(90,90,90,255) surface.DrawOutlinedRect(0,0,w,h,1)
                    draw.SimpleText("Edit Rank", "InvTitle", 12, 8, color_white)
                end
                local body = vgui.Create("DPanel", dlg)
                body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint = nil

                local idLbl = vgui.Create("DLabel", body)
                idLbl:Dock(TOP); idLbl:SetText("Rank ID (read-only):"); idLbl:SetFont("InvSmall"); idLbl:SetTextColor(Color(220,220,220)); idLbl:SizeToContents()
                local idBox = vgui.Create("DTextEntry", body)
                idBox:Dock(TOP); idBox:SetTall(26); idBox:DockMargin(0,2,0,8)
                idBox:SetText(rank.id or "")
                idBox:SetEditable(false)
                idBox:SetTextColor(Color(180,180,180))
                idBox.Paint = function(s,w,h)
                    surface.SetDrawColor(30,30,32) surface.DrawRect(0,0,w,h)
                    surface.SetDrawColor(80,80,80,200) surface.DrawOutlinedRect(0,0,w,h,1)
                    s:DrawTextEntryText(s:GetTextColor(), s:GetHighlightColor(), s:GetCursorColor())
                end

                local nameLbl = vgui.Create("DLabel", body)
                nameLbl:Dock(TOP); nameLbl:SetText("Display Name:"); nameLbl:SetFont("InvSmall"); nameLbl:SetTextColor(Color(220,220,220)); nameLbl:SizeToContents()
                local nameBox = vgui.Create("DTextEntry", body)
                nameBox:Dock(TOP); nameBox:SetTall(26); nameBox:DockMargin(0,2,0,8)
                nameBox:SetText(rank.name or "")
                nameBox:SetTextColor(Color(230,230,230))
                nameBox.Paint = function(s,w,h)
                    surface.SetDrawColor(40,40,42) surface.DrawRect(0,0,w,h)
                    surface.SetDrawColor(100,100,100,200) surface.DrawOutlinedRect(0,0,w,h,1)
                    s:DrawTextEntryText(s:GetTextColor(), s:GetHighlightColor(), s:GetCursorColor())
                end

                local colorLbl = vgui.Create("DLabel", body)
                colorLbl:Dock(TOP); colorLbl:SetText("Color:"); colorLbl:SetFont("InvSmall"); colorLbl:SetTextColor(Color(220,220,220)); colorLbl:SizeToContents()
                local colorMixer = vgui.Create("DColorMixer", body)
                colorMixer:Dock(TOP); colorMixer:SetTall(160); colorMixer:DockMargin(0,2,0,8)
                colorMixer:SetPalette(true)
                colorMixer:SetAlphaBar(false)
                colorMixer:SetWangs(true)
                colorMixer:SetColor(rank.color or Color(255, 255, 255))

                local permLbl = vgui.Create("DLabel", body)
                permLbl:Dock(TOP); permLbl:SetText("Permission Level:"); permLbl:SetFont("InvSmall"); permLbl:SetTextColor(Color(220,220,220)); permLbl:SizeToContents()
                local permBox = vgui.Create("DComboBox", body)
                permBox:Dock(TOP); permBox:SetTall(26); permBox:DockMargin(0,2,0,8)
                permBox:SetTextColor(Color(230,230,230))
                permBox.Paint = function(s,w,h)
                    surface.SetDrawColor(40,40,42) surface.DrawRect(0,0,w,h)
                    surface.SetDrawColor(100,100,100,200) surface.DrawOutlinedRect(0,0,w,h,1)
                end
                permBox:AddChoice("User", "user", (rank.permission or "user") == "user")
                permBox:AddChoice("Admin", "admin", (rank.permission or "user") == "admin")
                permBox:AddChoice("Super Admin", "superadmin", (rank.permission or "user") == "superadmin")

                local orderLbl = vgui.Create("DLabel", body)
                orderLbl:Dock(TOP); orderLbl:SetText("Sort Order (higher = top of list):"); orderLbl:SetFont("InvSmall"); orderLbl:SetTextColor(Color(220,220,220)); orderLbl:SizeToContents()
                local orderBox = vgui.Create("DNumberWang", body)
                orderBox:Dock(TOP); orderBox:SetTall(26); orderBox:DockMargin(0,2,0,8)
                orderBox:SetMin(1); orderBox:SetMax(999); orderBox:SetValue(rank.order or 50)

                local bar = vgui.Create("DPanel", body)
                bar:Dock(BOTTOM); bar:SetTall(30); bar.Paint = nil
                local ok = StyledButton(bar, "Save")
                ok:Dock(RIGHT); ok:SetWide(90)
                ok.DoClick = function()
                    local name = string.Trim(nameBox:GetText() or "")
                    local col = colorMixer:GetColor()
                    local perm = permBox:GetOptionData(permBox:GetSelectedID()) or "user"
                    local order = math.floor(orderBox:GetValue() or 50)

                    if name == "" then
                        surface.PlaySound("buttons/button10.wav")
                        return
                    end

                    net.Start("Monarch_Ranks_Add")
                        net.WriteTable({
                            id = rank.id,
                            name = name,
                            color = col,
                            permission = perm,
                            order = order
                        })
                    net.SendToServer()
                    dlg:Close()
                    surface.PlaySound("buttons/button14.wav")
                    timer.Simple(0.3, function()
                        net.Start("Monarch_Ranks_RequestSync")
                        net.SendToServer()
                    end)
                end
                local cancel = StyledButton(bar, "Cancel")
                cancel:Dock(RIGHT); cancel:SetWide(90); cancel:DockMargin(8,0,0,0)
                cancel.DoClick=function() dlg:Close() end
            end

            local delBtn = StyledButton(row, "Delete")
            delBtn:SetPos(row:GetWide() - 90, 23)
            delBtn:SetSize(80, 24)
            delBtn.DoClick = function()
                Derma_Query("Delete rank '" .. (rank.name or rank.id) .. "'?", "Confirm Delete",
                    "Delete", function()
                        net.Start("Monarch_Ranks_Remove")
                            net.WriteString(rank.id or "")
                        net.SendToServer()
                        surface.PlaySound("buttons/button14.wav")
                        timer.Simple(0.3, function()
                            net.Start("Monarch_Ranks_RequestSync")
                            net.SendToServer()
                        end)
                    end,
                    "Cancel")
            end

            function row:PerformLayout(w,h)
                if IsValid(editBtn) then editBtn:SetPos(w - 180, 23) end
                if IsValid(delBtn) then delBtn:SetPos(w - 90, 23) end
            end
        end
    end

    hook.Add("Monarch_RanksUpdated", "Monarch_StaffManager_RefreshRanks", function()
        if IsValid(ranksScroll) then
            PopulateRanks()
        end
    end)

    timer.Simple(0.1, function()
        if IsValid(ranksScroll) then
            PopulateRanks()
        end
    end)

    local list = vgui.Create("DScrollPanel", membersPanel)
    list:Dock(FILL)
    list:DockMargin(0,0,0,0)

        local currentCat = vgui.Create("DPanel", list)
        currentCat:Dock(TOP)
        currentCat:DockMargin(0,0,0,15)
        currentCat:SetTall(32)
        currentCat._labelText = "Staff Members"
        function currentCat:SetLabel(txt) self._labelText = tostring(txt or "") end
        currentCat.Paint = function(s,w,h)
            surface.SetDrawColor(50,50,52,255)
            surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(70,70,72,200)
            surface.DrawOutlinedRect(0,0,w,h,1)
            draw.SimpleText(s._labelText or "", "MonarchSB_Name", 8, h/2, Color(235,235,235), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        local currentList = vgui.Create("DListLayout", list)
        currentList:Dock(TOP)
        currentList:DockMargin(0,0,0,0)

        local strikesScroll = vgui.Create("DScrollPanel", strikesPanel)
        strikesScroll:Dock(FILL)
        strikesScroll:DockMargin(0,0,0,0)
        local function makeStrikeRow(parent, sid, rec)

            local card = vgui.Create("DPanel", parent)
            card:Dock(TOP)
            card:DockMargin(0,0,0,8)
            card:SetTall(120)
            card.Paint = function(s,w,h)
                surface.SetDrawColor(30,30,32) surface.DrawRect(0,0,w,h)
                surface.SetDrawColor(60,60,60,160) surface.DrawOutlinedRect(0,0,w,h,1)
            end

            local header = vgui.Create("DPanel", card)
            header:Dock(TOP)
            header:SetTall(38)
            header.Paint = function(s,w,h)
                surface.SetDrawColor(40,40,42) surface.DrawRect(0,0,w,h)
                surface.SetDrawColor(100,100,110,200) surface.DrawOutlinedRect(0,0,w,h,1)
                draw.SimpleText(string.format("%s (%s)  â€¢  Points: %d", rec.name or sid, rec.group or "user", tonumber(rec.strike_points) or 0), "MonarchSB_Name", 8, h/2, Color(235,235,235), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local add = StyledButton(header, "Add Strike")
            add:Dock(RIGHT)
            add:SetWide(110)
            add:DockMargin(6,6,6,6)
            add.DoClick = function()

                local dlg = vgui.Create("DFrame")
                dlg:SetSize(420, 200)
                dlg:Center(); dlg:MakePopup(); dlg:SetTitle("")
                dlg:ShowCloseButton(false); dlg:SetDraggable(false)
                dlg.Paint = function(s,w,h)
                    surface.SetDrawColor(28,28,28,255) surface.DrawRect(0,0,w,h)
                    surface.SetDrawColor(90,90,90,255) surface.DrawOutlinedRect(0,0,w,h,1)
                    draw.SimpleText("Add Strike", "InvTitle", 12, 8, color_white)
                end
                local body = vgui.Create("DPanel", dlg)
                body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint = nil
                local reason = vgui.Create("DTextEntry", body)
                reason:Dock(TOP); reason:SetTall(24); reason:SetPlaceholderText("Reason (required)")
                local pts = vgui.Create("DNumberWang", body)
                pts:Dock(TOP); pts:SetTall(24); pts:SetMin(1); pts:SetMax(10); pts:SetValue(1)
                pts:DockMargin(0,6,0,0)
                local bar = vgui.Create("DPanel", body)
                bar:Dock(BOTTOM); bar:SetTall(30); bar.Paint = nil
                local ok = StyledButton(bar, "Add")
                ok:Dock(RIGHT); ok:SetWide(90)
                ok.DoClick = function()
                    local r = string.Trim(reason:GetText() or "")
                    local p = math.max(1, math.floor(pts:GetValue() or 1))
                    if r == "" then return end
                    net.Start("Monarch_Staff_AddStrike")
                        net.WriteString(sid)
                        net.WriteString(r)
                        net.WriteUInt(p, 8)
                    net.SendToServer()
                    dlg:Close()
                    timer.Simple(0.2, function() net.Start("Monarch_Staff_RequestStats") net.SendToServer() end)
                end
                local cancel = StyledButton(bar, "Cancel")
                cancel:Dock(RIGHT); cancel:SetWide(90); cancel:DockMargin(8,0,0,0)
                cancel.DoClick=function() dlg:Close() end
            end
            local pnl = vgui.Create("DListLayout", card)
            pnl:Dock(TOP)
            pnl:DockMargin(8,6,8,8)
            pnl:SizeToChildren(true, true)

            local strikes = rec.strikes or {}
            if #strikes == 0 then
                local none = vgui.Create("DLabel", pnl)
                none:SetText("No strikes")
                none:SetFont("InvSmall")
                none:SetTextColor(Color(220,220,220))
                pnl:Add(none)
            else
                for i, srec in ipairs(strikes) do
                    local row = vgui.Create("DPanel", pnl)
                    row:SetTall(36)
                    row:Dock(TOP)
                    row:DockMargin(0,0,0,6)
                    row.Paint = function(s,w,h)
                        surface.SetDrawColor(30,30,32) surface.DrawRect(0,0,w,h)
                        surface.SetDrawColor(60,60,60,160) surface.DrawOutlinedRect(0,0,w,h,1)
                    end
                    local lbl = vgui.Create("DLabel", row)
                    lbl:Dock(FILL)
                    lbl:SetContentAlignment(4)
                    lbl:DockMargin(8,0,0,0)
                    lbl:SetFont("InvSmall")
                    local when = os.date("%Y-%m-%d %H:%M", tonumber(srec.time or os.time()))
                    lbl:SetText(string.format("%s  â€¢  +%d  â€¢  %s  â€¢  by %s", when, tonumber(srec.points) or 0, tostring(srec.reason or ""), tostring(srec.adminName or srec.admin or "")))
                    lbl:SetTextColor(Color(235,235,235))
                    local rm = StyledButton(row, "Remove")
                    rm:Dock(RIGHT)
                    rm:SetWide(90)
                    rm:DockMargin(0,6,6,6)
                    rm.DoClick = function()
                        if srec.id then
                            net.Start("Monarch_Staff_RemoveStrikeById")
                                net.WriteString(sid)
                                net.WriteString(tostring(srec.id))
                            net.SendToServer()
                        else
                            net.Start("Monarch_Staff_RemoveStrike")
                                net.WriteString(sid)
                                net.WriteUInt(i, 16)
                            net.SendToServer()
                        end
                        timer.Simple(0.2, function() net.Start("Monarch_Staff_RequestStats") net.SendToServer() end)
                    end
                end
            end

            local function refreshHeight()
                if not IsValid(card) then return end
                local total = (IsValid(header) and header:GetTall() or 0) + (IsValid(pnl) and pnl:GetTall() or 0) + 12
                card:SetTall(total)
            end

            pnl:InvalidateLayout(true)
            refreshHeight()
            timer.Simple(0, refreshHeight)
            return card
        end

        local groups = {"user", "operator", "moderator", "admin", "superadmin"}
        local function isAdminGroup(g)
            local key = string.lower(g or "")
            if Monarch and Monarch.Ranks and Monarch.Ranks.GetPermission then
                local perm = string.lower(Monarch.Ranks.GetPermission(key) or "user")
                if perm == "admin" or perm == "superadmin" then return true end
            end
            return key == "admin" or key == "superadmin" or key == "moderator" or key == "operator" or key == "owner" or key == "developer"
        end

        local function fmtTime(seconds)
            seconds = math.floor(tonumber(seconds) or 0)
            local m = math.floor(seconds / 60)
            local s = seconds % 60
            return string.format("%dm %02ds", m, s)
        end

        local function makeRow(parent, sid, rec)
            local row = vgui.Create("DPanel", parent)
            row:SetTall(90)
            row:Dock(TOP)
            row:DockMargin(0,0,0,6)
            row.Paint = function(s,w,h)
                surface.SetDrawColor(30,30,32) surface.DrawRect(0,0,w,h)
                surface.SetDrawColor(60,60,60,160) surface.DrawOutlinedRect(0,0,w,h,1)
            end

            local av = vgui.Create("AvatarImage", row)
            av:SetSize(50,50)
            av:SetPos(10, 20)
            if rec.online then
                local ply = player.GetBySteamID64(sid)
                if IsValid(ply) then av:SetPlayer(ply,64) end
            else
                if av.SetSteamID then av:SetSteamID(sid, 64) end
            end

            local leftInfo = vgui.Create("DPanel", row)
            leftInfo:SetPos(70, 10)
            leftInfo:SetSize(300, 70)
            leftInfo.Paint = nil

            local name = vgui.Create("DLabel", leftInfo)
            name:SetPos(0, 0)
            name:SetFont("MonarchSB_Name")
            name:SetTextColor(Color(235,235,235))
            name:SetText(rec.name or sid)
            name:SizeToContents()

            local statsLbl = vgui.Create("DLabel", leftInfo)
            statsLbl:SetPos(0, 24)
            statsLbl:SetFont("MonarchSB_Meta")
            statsLbl:SetTextColor(Color(220,220,220))
            local avg = 0
            local tickets = tonumber(rec.tickets) or 0
            local total = tonumber(rec.total_time) or 0
            if tickets > 0 then avg = math.floor(total / tickets) end
            local strikes = tonumber(rec.strike_points or 0)
            statsLbl:SetText(string.format("Group: %s    Tickets: %d    Total Time: %s    Strikes: %d", tostring(rec.group or "user"), tickets, fmtTime(avg), strikes))
            statsLbl:SizeToContents()

            local rightBar = vgui.Create("DPanel", row)
            rightBar:Dock(RIGHT)
            rightBar:SetWide(580)
            rightBar:DockMargin(8,10,10,10)
            rightBar.Paint = nil

            local cmb = vgui.Create("DComboBox", rightBar)
            cmb:Dock(TOP)
            cmb:SetTall(28)
            cmb:DockMargin(0,0,0,6)
            cmb.Paint = function(s,w,h)
                surface.SetDrawColor(40,40,42) surface.DrawRect(0,0,w,h)
                surface.SetDrawColor(100,100,100,200) surface.DrawOutlinedRect(0,0,w,h,1)
            end
            cmb:SetTextColor(Color(230,230,230))

            local function AddRankChoicesToRow(c, selectedId)
                c:Clear()
                local ranks = (Monarch and Monarch.Ranks and Monarch.Ranks.GetAll and Monarch.Ranks.GetAll()) or {}
                for _, r in ipairs(ranks) do
                    local id = string.lower(r.id or "")
                    local name = r.name or id
                    c:AddChoice(string.upper(name), id, selectedId == id)
                end

                local hasUser = false
                for _, r in ipairs(ranks) do if string.lower(r.id or "") == "user" then hasUser = true break end end
                if not hasUser then c:AddChoice("USER", "user", selectedId == "user") end
            end
            AddRankChoicesToRow(cmb, string.lower(rec.group or "user"))
            cmb.OnSelect = function(_, _, _, data)
                if not (LocalPlayer() and LocalPlayer():IsSuperAdmin()) then return end
                if rec.online then
                    local ply = player.GetBySteamID64(sid)
                    if IsValid(ply) then
                        net.Start("Monarch_Staff_SetGroup") net.WriteEntity(ply) net.WriteString(tostring(data)) net.SendToServer()
                    end
                else
                    net.Start("Monarch_Staff_SetGroupSID") net.WriteString(sid) net.WriteString(tostring(data)) net.SendToServer()
                end
            end

            local buttons = vgui.Create("DPanel", rightBar)
            buttons:Dock(FILL)
            buttons.Paint = nil

            local strike = StyledButton(buttons, "Add Strike")
            strike:Dock(LEFT)
            strike:SetWide(135)
            strike:DockMargin(0,0,4,0)
            strike.DoClick = function()
                local dlg = vgui.Create("DFrame")
                dlg:SetSize(420, 200)
                dlg:Center(); dlg:MakePopup(); dlg:SetTitle("")
                dlg:ShowCloseButton(false); dlg:SetDraggable(false)
                dlg.Paint = function(s,w,h)
                    surface.SetDrawColor(28,28,28,255) surface.DrawRect(0,0,w,h)
                    surface.SetDrawColor(90,90,90,255) surface.DrawOutlinedRect(0,0,w,h,1)
                    draw.SimpleText("Add Strike", "InvTitle", 12, 8, color_white)
                end
                local body = vgui.Create("DPanel", dlg)
                body:Dock(FILL); body:DockMargin(8,32,8,8); body.Paint = nil
                local reason = vgui.Create("DTextEntry", body)
                reason:Dock(TOP); reason:SetTall(24); reason:SetPlaceholderText("Reason (required)")
                local pts = vgui.Create("DNumberWang", body)
                pts:Dock(TOP); pts:SetTall(24); pts:SetMin(1); pts:SetMax(10); pts:SetValue(1)
                pts:DockMargin(0,6,0,0)
                local bar = vgui.Create("DPanel", body)
                bar:Dock(BOTTOM); bar:SetTall(30); bar.Paint = nil
                local ok = StyledButton(bar, "Add")
                ok:Dock(RIGHT); ok:SetWide(90)
                ok.DoClick = function()
                    local r = string.Trim(reason:GetText() or "")
                    local p = math.max(1, math.floor(tonumber(pts:GetValue()) or 1))
                    if r == "" then return end
                    net.Start("Monarch_Staff_AddStrike")
                        net.WriteString(tostring(sid))
                        net.WriteString(r)
                        net.WriteUInt(p, 8)
                    net.SendToServer()
                    dlg:Close()
                    timer.Simple(0.2, function() net.Start("Monarch_Staff_RequestStats") net.SendToServer() end)
                end
                local cancel = StyledButton(bar, "Cancel")
                cancel:Dock(RIGHT); cancel:SetWide(90); cancel:DockMargin(8,0,0,0)
                cancel.DoClick=function() dlg:Close() end
            end

            local copy = StyledButton(buttons, "Copy SID64")
            copy:Dock(LEFT)
            copy:SetWide(135)
            copy:DockMargin(0,0,0,0)
            copy.DoClick = function() SetClipboardText(tostring(sid)) surface.PlaySound("menu/ui_click.mp3") end

            return row
        end

        container._staffLists = {
            current = currentList,
            currentCat = currentCat,
            makeRow = makeRow,
            isAdminGroup = isAdminGroup,
            strikesScroll = strikesScroll,
            makeStrikeRow = makeStrikeRow
        }

        net.Start("Monarch_Staff_RequestStats") net.SendToServer()
    end

    local tabContext = {
        frame = frame,
        right = right,
        StyledButton = StyledButton,
        PanelControlButton = PanelControlButton,
        GetPalette = GetPalette,
        RoundedOutlinedBox = RoundedOutlinedBox,
        SetBreadcrumb = function(parts)
            if IsValid(frame) and frame.SetBreadcrumb then
                frame:SetBreadcrumb(parts)
            end
        end,
        ClearRight = ClearRight,
        OpenCreateTicket = OpenCreateTicket,
    }

    local function loadTabBuilder(path)
        local registerTab = Monarch.LoadFile(path)
        if not isfunction(registerTab) then return nil end
        local builder = registerTab(tabContext)
        if isfunction(builder) then return builder end
        return nil
    end

    BuildTicketsView = loadTabBuilder("modules/interfaces/monarch_admin_suite/tools_utils/cl_tickets.lua") or BuildTicketsView
    BuildToolsView = loadTabBuilder("modules/interfaces/monarch_admin_suite/tools_utils/cl_tools.lua") or BuildToolsView
    BuildCustomToolsView = loadTabBuilder("modules/interfaces/monarch_admin_suite/tools_utils/cl_customtools.lua") or BuildCustomToolsView
    BuildPlayersView = loadTabBuilder("modules/interfaces/monarch_admin_suite/tools_utils/cl_players.lua") or BuildPlayersView
    BuildCharsView = loadTabBuilder("modules/interfaces/monarch_admin_suite/tools_utils/cl_chars.lua") or BuildCharsView
    BuildStaffView = loadTabBuilder("modules/interfaces/monarch_admin_suite/tools_utils/cl_staffmanager.lua") or BuildStaffView

    if tabList._tabsBuilt and not frame._initialAdminTabLoaded then
        frame._initialAdminTabLoaded = true
        SetActiveTab("tickets")
    end

end

Monarch_Tickets_OpenAdminUI = OpenTicketsUI

