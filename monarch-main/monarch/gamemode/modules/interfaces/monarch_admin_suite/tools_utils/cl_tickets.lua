return function(ctx)
    local frame = ctx.frame
    local right = ctx.right
    local StyledButton = ctx.StyledButton
    local PanelControlButton = ctx.PanelControlButton
    local GetPalette = ctx.GetPalette
    local ClearRight = ctx.ClearRight
    local OpenCreateTicket = ctx.OpenCreateTicket
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
                local isCreator = (msgSID ~= "" and msgSID == reporterSID)
                local isHandler = (msgSID ~= "" and handlerSID ~= "" and msgSID == handlerSID)
                local holder = vgui.Create("DPanel", state.chatScroll)
                holder:Dock(TOP)
                holder:DockMargin(0,0,0,6)
                holder:SetTall(48)
                holder.Paint = nil
                local row = vgui.Create("DPanel", holder)
                row:Dock(FILL)
                row:DockMargin(isHandler and 80 or 8, 0, isHandler and 8 or 80, 0)
                row.Paint = function(self, pw, ph)
                    local P = GetPalette()
                    local creatorBg = Color(40,120,60)
                    local creatorBorder = Color(60,160,80)
                    local handlerBg = Color(60,100,180)
                    local handlerBorder = Color(80,130,210)
                    local neutralBg = P.inputBg
                    local neutralBorder = P.outline
                    local bg, border
                    if isHandler then bg, border = handlerBg, handlerBorder
                    elseif isCreator then bg, border = creatorBg, creatorBorder
                    else bg, border = neutralBg, neutralBorder end
                    local radius = (P.radius or 6) + 2
                    draw.RoundedBox(radius, 0, 0, pw, ph, bg)
                    surface.SetDrawColor(border)
                    surface.DrawOutlinedRect(0, 0, pw, ph, 1)
                    local who = m.name or (isHandler and "Handler" or (isCreator and "Creator" or "Player"))
                    local when = os.date("%I:%M %p", tonumber(m.time or os.time()))
                    draw.SimpleText(who.." Â· "..when, "InvSmall", 8, 6, (isHandler or isCreator) and Color(245,245,245) or Color(190,192,195))
                end
                local text = vgui.Create("DLabel", row)
                text:Dock(FILL)
                text:DockMargin(8, 20, 8, 8)
                text:SetFont("InvSmall")
                text:SetTextColor((isHandler or isCreator) and Color(250,250,250) or GetPalette().inputText)
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
            net.Start("Monarch_Tickets_Message") net.WriteUInt(state.currentId, 16) net.WriteString(text) net.SendToServer()
            self:SetText("")
        end
        do
            local pad = 6
            local btnClose = PanelControlButton(actionRow, "X")
            btnClose:Dock(RIGHT) btnClose:DockMargin(pad,pad,pad,pad) btnClose:SetWide(40)
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

        local function LayoutNotifications()
            local pad = 8
            local y = (state.notifWrap:GetTall() or 0) - pad
            for i = #state.notifItems, 1, -1 do
                local item = state.notifItems[i]
                if not IsValid(item) then table.remove(state.notifItems, i) else
                    local h = item:GetTall()
                    y = y - h
                    local targetY = y
                    y = y - pad
                    item._targetY = targetY
                end
            end
        end
        function state:AddNotification(kind, t)
            if not IsValid(self.notifWrap) then return end
            local col = Color(120,120,255) local label = "Updated"
            if kind == "claimed" then col = Color(40,160,80) label = "Claimed" end
            if kind == "closed" then col = Color(160,60,60) label = "Closed" end
            local panel = vgui.Create("DPanel", self.notifWrap)
            panel:SetSize(self.notifWrap:GetWide()-12, 60)
            panel:SetPos(6, self.notifWrap:GetTall()+60)
            panel.spawn = CurTime() panel.alpha = 0 panel._targetY = self.notifWrap:GetTall()-panel:GetTall()-6
            panel.Paint = function(s, pw, ph)
                local a = s.alpha or 255
                local P = GetPalette()
                surface.SetDrawColor(P.panel.r, P.panel.g, P.panel.b, 220 * (a/255)) surface.DrawRect(0,0,pw,ph)
                surface.SetDrawColor(col.r, col.g, col.b, 220 * (a/255)) surface.DrawOutlinedRect(0,0,pw,ph,2)
                surface.SetFont("InvSmall")
                local text = string.format("%s â€¢ #%s %s", label, tostring(t.id or "?"), tostring(t.reporterName or t.reporter or ""))
                local tw, th = surface.GetTextSize(text)
                surface.SetTextColor(P.text.r, P.text.g, P.text.b, a)
                surface.SetTextPos(10, ph/2 - th/2)
                surface.DrawText(text)
            end
            panel.Think = function(s)
                local dt = FrameTime() * 10
                s.alpha = Lerp(dt, s.alpha, 255)
                local x, y = s:GetPos()
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

