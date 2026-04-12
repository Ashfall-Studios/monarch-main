    net.Receive("Monarch_Tickets_List", function()
        local payload = net.ReadTable() or {}

        local playerFrame = (IsValid(Monarch_Player_Ticket_Frame) and Monarch_Player_Ticket_Frame) or nil
        if playerFrame and playerFrame._populateMyTickets then
            playerFrame._populateMyTickets(payload)

            if playerFrame._chatActiveTicketId then
                local found = false
                for _, t in ipairs(payload) do if t.id == playerFrame._chatActiveTicketId then found = true break end end
                if not found then

                    if playerFrame._gotoMyTickets then playerFrame._gotoMyTickets() end
                    playerFrame._chatActiveTicketId = nil
                end
            end
        end

        local frameRef = (IsValid(Monarch_Tickets_Frame) and Monarch_Tickets_Frame) or nil
        local v = frameRef and frameRef._views and frameRef._views.tickets

        if v and v.PopulateList then
            v.PopulateList(payload)
            local st = v.state
            if st and st.currentId then
                local foundOpen = false
                for _, t in ipairs(payload) do
                    local status = string.lower(t.status or "")
                    local isClosed = (status == "closed") or (t.closed == true)
                    if (not isClosed) and t.id == st.currentId then
                        if v.PopulateChat then v.PopulateChat(t) end
                        foundOpen = true
                        if v.UpdateMiddleForTicket then v.UpdateMiddleForTicket(t) end
                        if st.forceChatOpenId and st.forceChatOpenId == t.id then st.forceChatOpenId = nil end
                        break
                    end
                end
                if not foundOpen and st then
                    if st.forceChatOpenId then
                        if IsValid(st.listWrap) then st.listWrap:SetVisible(false) end
                        if IsValid(st.chatWrap) then st.chatWrap:SetVisible(true) end
                        if IsValid(st.inputRow) then st.inputRow:SetVisible(true) end
                        if IsValid(st.actionRow) then st.actionRow:SetVisible(true) end
                        if IsValid(st.plusBtn) then st.plusBtn:SetVisible(false) end
                    else
                        st.currentId = nil
                        if IsValid(st.chatScroll) then st.chatScroll:Clear() end
                        if IsValid(st.inputRow) then st.inputRow:SetVisible(false) end
                        if IsValid(st.actionRow) then st.actionRow:SetVisible(false) end
                        if IsValid(st.chatWrap) then st.chatWrap:SetVisible(false) end
                        if IsValid(st.listWrap) then st.listWrap:SetVisible(true) end
                        if IsValid(st.plusBtn) then st.plusBtn:SetVisible(true) end
                    end
                end

                if st and st.columns then
                    for _, c in ipairs(st.columns or {}) do
                        if IsValid(c) and IsValid(c._layout) then
                            for _, r in ipairs(c._layout:GetChildren() or {}) do
                                if IsValid(r) and IsValid(r._labelBtn) and r._labelBtn.ButtonText then
                                    r._labelBtn.Selected = (st.currentId ~= nil) and string.find(r._labelBtn.ButtonText, "#" .. tostring(st.currentId) .. "  ") ~= nil
                                end
                            end
                        end
                    end
                end
            end
        end

        Monarch_Tickets_Global.prevMap = Monarch_Tickets_Global.prevMap or {}
        if not Monarch_Tickets_Global.hadInitial then
            for _, t in ipairs(payload) do
                local msgCount = (t.messages and #t.messages) or 0
                Monarch_Tickets_Global.prevMap[t.id] = { status = t.status, claimedBy = t.claimedBy, messages = msgCount }
            end
            Monarch_Tickets_Global.hadInitial = true
            return
        end
        local byId = {}
        for _, t in ipairs(payload) do byId[t.id] = t end
        for id, t in pairs(byId) do
            local prev = Monarch_Tickets_Global.prevMap[id]
            local msgCount = (t.messages and #t.messages) or 0
            if prev then
                local oldStatus = string.lower(prev.status or "")
                local newStatus = string.lower(t.status or "")
                if oldStatus ~= newStatus then
                    if newStatus == "claimed" and Monarch_Tickets_AddGlobalAndUI then Monarch_Tickets_AddGlobalAndUI("claimed", t) end
                    if newStatus == "closed" and Monarch_Tickets_AddGlobalAndUI then Monarch_Tickets_AddGlobalAndUI("closed", t) end
                end
                if msgCount > (prev.messages or 0) and Monarch_Tickets_AddGlobalAndUI then Monarch_Tickets_AddGlobalAndUI("updated", t) end
            else

                if Monarch_Tickets_IsStaff and Monarch_Tickets_IsStaff() and Monarch_Tickets_CreateTicketNotification then
                    Monarch_Tickets_CreateTicketNotification(t)
                end
            end
            Monarch_Tickets_Global.prevMap[id] = { status = t.status, claimedBy = t.claimedBy, messages = msgCount }
        end

    end)

net.Receive("Monarch_Staff_StatsData", function()
    local data = net.ReadTable() or {}
    local frameRef = (IsValid(Monarch_Tickets_Frame) and Monarch_Tickets_Frame) or nil
    if not frameRef then return end
    local container = frameRef._staffContainer
    if not (IsValid(container) and container._staffLists) then return end

    local refs = container._staffLists
    local currentList = refs.current
    local currentCat = refs.currentCat
    local makeRow, isAdminGroup = refs.makeRow, refs.isAdminGroup
    local strikesScroll = refs.strikesScroll

    if not IsValid(currentList) then return end

    currentList:Clear()
    if IsValid(currentCat) and currentCat.Clear then currentCat:Clear() end
    if IsValid(strikesScroll) and strikesScroll.Clear then strikesScroll:Clear() end

    local arr = {}
    for sid, rec in pairs(data) do
        if isAdminGroup(rec.group) then
            rec._sid = sid
            table.insert(arr, rec)
        end
    end

    if table.SortByMember then
        table.SortByMember(arr, "name", true)
    else
        table.sort(arr, function(a,b)
            local an = tostring(a.name or "")
            local bn = tostring(b.name or "")
            return an:lower() < bn:lower()
        end)
    end

    local nCurrent = 0
    local seen = {}
    for _, rec in ipairs(arr) do
        local sid = tostring(rec._sid or "")
        if sid ~= "" and not seen[sid] then
            seen[sid] = true
            if IsValid(currentList) then
                makeRow(currentList, rec._sid, rec)
                nCurrent = nCurrent + 1
            end
        end
    end
    if IsValid(currentCat) then currentCat:SetLabel("Staff Members ("..nCurrent..")") end

    if IsValid(strikesScroll) then

        for _, rec in ipairs(arr) do
            local sid = tostring(rec._sid or "")
            if sid ~= "" and seen[sid] then
                local cat = refs.makeStrikeRow(strikesScroll, rec._sid, rec)
                if IsValid(cat) then strikesScroll:AddItem(cat) end
            end
        end
    end
end)

net.Receive("Monarch_Tickets_OpenUI", function()
    if Monarch_Tickets_IsStaff and Monarch_Tickets_IsStaff() then
        if Monarch_Tickets_OpenAdminUI then Monarch_Tickets_OpenAdminUI() end
    else
        if Monarch_Tickets_OpenPlayerUI then Monarch_Tickets_OpenPlayerUI() end
    end
end)

net.Receive("Monarch_Tickets_Message", function()
    local id = net.ReadUInt(16)
    local msg = net.ReadTable() or {}

    local pf = (IsValid(Monarch_Player_Ticket_Frame) and Monarch_Player_Ticket_Frame) or nil
    if pf and pf._chatActiveTicketId and pf._chatActiveTicketId == id and IsValid(pf._chatScroll) then
        local function GetPalette()
            if Monarch and Monarch.Theme and Monarch.Theme.Get then return Monarch.Theme.Get() end
            return {
                panel = Color(28,28,30), outline = Color(55,57,63), titlebar = Color(30,30,32), divider = Color(80,82,88,160),
                text = Color(230,232,236), btn = Color(60,64,72), btnHover = Color(72,76,84), btnText = Color(240,242,245),
                primary = Color(88,88,88), primaryHover = Color(130,130,130), inputBg = Color(38,39,44), inputBorder = Color(70,73,79), inputText = Color(230,232,236), radius = 6,
            }
        end
        local P = GetPalette()
        local ctx = pf._chatContext or { reporterSID64 = "", handlerSID64 = "" }
        local msgSID = tostring(msg.sid or "")
        local isCreator = (msgSID ~= "" and ctx.reporterSID64 ~= "" and msgSID == ctx.reporterSID64)
        local isHandler = (msgSID ~= "" and ctx.handlerSID64 ~= "" and msgSID == ctx.handlerSID64)
        local holder = vgui.Create("DPanel", pf._chatScroll)
        holder:Dock(TOP)
        holder:DockMargin(0, 0, 0, 6)
        holder:SetTall(48)
        holder.Paint = nil

        local row = vgui.Create("DPanel", holder)
        row:Dock(FILL)
        row:DockMargin(isHandler and 80 or 8, 0, isHandler and 8 or 80, 0)
        row.Paint = function(self, pw, ph)
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
            local who = msg.name or (isHandler and "Handler" or (isCreator and "Creator" or "Player"))
            local when = os.date("%I:%M %p", tonumber(msg.time or os.time()))
            draw.SimpleText(who.." Â· "..when, "InvSmall", 8, 6, (isHandler or isCreator) and Color(245,245,245) or Color(190,192,195))
        end
        local text = vgui.Create("DLabel", row)
        text:Dock(FILL)
        text:DockMargin(8, 20, 8, 8)
        text:SetFont("InvSmall")
        text:SetTextColor((isHandler or isCreator) and Color(250,250,250) or P.inputText)
        text:SetWrap(true)
        text:SetAutoStretchVertical(true)
        do
            local raw = tostring(msg.text or "")
            if #raw > 75 then
                raw = string.sub(raw, 1, 75) .. "..."
            end
            text:SetText(raw)
        end
        pf._chatScroll:InvalidateLayout(true)
        pf._chatScroll:PerformLayout()
        timer.Simple(0, function()
            if IsValid(pf) and IsValid(pf._chatScroll) and IsValid(pf._chatScroll:GetVBar()) then
                pf._chatScroll:GetVBar():SetScroll(pf._chatScroll:GetVBar():GetScroll() + 9999)
            end
        end)
    end

    local af = (IsValid(Monarch_Tickets_Frame) and Monarch_Tickets_Frame) or nil
    local v = af and af._views and af._views.tickets
    if v and v.state and v.state.currentId == id and IsValid(v.state.chatScroll) then
        local tk
        for _, it in ipairs(v.state.ticketsCache or {}) do if it.id == id then tk = it break end end
        local reporterSID = tk and tostring(tk.reporter or tk.reporterId or "") or ""
        local handlerSID = tk and tostring(tk.claimedBy or tk.claimedById or "") or ""
        local msgSID = tostring(msg.sid or "")
        local isCreator = (msgSID ~= "" and msgSID == reporterSID)
        local isHandler = (msgSID ~= "" and handlerSID ~= "" and msgSID == handlerSID)
        local holder = vgui.Create("DPanel", v.state.chatScroll)
        holder:Dock(TOP)
        holder:DockMargin(0,0,0,6)
        holder:SetTall(48)
        holder.Paint = nil
        local row = vgui.Create("DPanel", holder)
        row:Dock(FILL)
        row:DockMargin(isHandler and 80 or 8, 0, isHandler and 8 or 80, 0)
        row.Paint = function(self, pw, ph)
            local P = (Monarch_Tickets_GetPalette and Monarch_Tickets_GetPalette()) or {
                panel = Color(28,28,30), outline = Color(55,57,63), titlebar = Color(30,30,32), divider = Color(80,82,88,160),
                text = Color(230,232,236), btn = Color(60,64,72), btnHover = Color(72,76,84), btnText = Color(240,242,245),
                primary = Color(88,88,88), primaryHover = Color(130,130,130), inputBg = Color(38,39,44), inputBorder = Color(70,73,79), inputText = Color(230,232,236), radius = 6,
            }
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

            surface.SetDrawColor(bg)
            surface.DrawRect(0, 0, pw, ph)
            surface.SetDrawColor(border)
            surface.DrawOutlinedRect(0, 0, pw, ph, 1)
            local who = msg.name or (isHandler and "Handler" or (isCreator and "Creator" or "Player"))
            local when = os.date("%I:%M %p", tonumber(msg.time or os.time()))
            draw.SimpleText(who.." Â· "..when, "InvSmall", 8, 6, (isHandler or isCreator) and Color(245,245,245) or Color(190,192,195))
        end
        local text = vgui.Create("DLabel", row)
        text:Dock(FILL)
        text:DockMargin(8, 20, 8, 8)
        text:SetFont("InvSmall")
        text:SetTextColor((isHandler or isCreator) and Color(250,250,250) or GetPalette().inputText)
        text:SetWrap(true)
        text:SetAutoStretchVertical(true)
        text:SetText(tostring(msg.text or ""))
        v.state.chatScroll:InvalidateLayout(true)
        timer.Simple(0, function()
            if IsValid(v.state.chatScroll) and IsValid(v.state.chatScroll:GetVBar()) then
                local bar = v.state.chatScroll:GetVBar()
                bar:SetScroll(bar:GetScroll() + 9999)
            end
        end)
    end
end)

concommand.Add("monarch_tickets", function()
    if Monarch_Tickets_IsStaff and Monarch_Tickets_IsStaff() then
        if Monarch_Tickets_OpenAdminUI then Monarch_Tickets_OpenAdminUI() end
    else
        if Monarch_Tickets_OpenPlayerUI then Monarch_Tickets_OpenPlayerUI() end
    end
end)

concommand.Add("monarch_ticket", function()
    if Monarch_Tickets_OpenPlayerUI then Monarch_Tickets_OpenPlayerUI() end
end)

concommand.Add("monarch_ticket_test", function()
    if Monarch_Tickets_IsStaff and Monarch_Tickets_IsStaff() then
        if Monarch_Tickets_OpenPlayerUI then Monarch_Tickets_OpenPlayerUI() end
    else
        chat.AddText(Color(255, 100, 100), "[Tickets] ", color_white, "Staff only.")
    end
end)

