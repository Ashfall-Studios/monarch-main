local function OpenPlayerTicketUI()
    if IsValid(Monarch_Player_Ticket_Frame) then Monarch_Player_Ticket_Frame:Remove() end

    local scrW, scrH = ScrW(), ScrH()
    local w = math.floor(scrW * 0.7)
    local h = math.floor(scrH * 0.7)

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

    local frame = vgui.Create("DFrame")
    frame:SetSize(w, h)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame:SetDeleteOnClose(true)
    frame.topBarH = 42
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
        draw.SimpleText("My Tickets", "InvMed", 12, math.floor((s.topBarH - 24) * 0.5), P.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    frame.closeBtn = vgui.Create("DButton", frame)
    frame.closeBtn:SetSize(24, 20)
    frame.closeBtn:SetPos(frame:GetWide() - 28, math.floor((frame.topBarH - 20) * 0.5))
    frame.closeBtn:SetText("X")
    frame.closeBtn:SetFont("InvSmall")
    frame.closeBtn:SetTextColor(color_white)
    frame.closeBtn.Paint = function(s, pw, ph)
        local P = GetPalette()
        local bg = s:IsHovered() and Color(160,60,60) or Color(120,50,50)
        surface.SetDrawColor(bg)
        surface.DrawRect(0, 0, pw, ph)
        surface.SetDrawColor(P.outline)
        surface.DrawOutlinedRect(0, 0, pw, ph, 1)
    end
    frame.closeBtn.DoClick = function() frame:Remove() end

    Monarch_Player_Ticket_Frame = frame

    local function StyledButton(parent, text)
        local btn = vgui.Create("DButton", parent)
        btn:SetText("")
        btn.ButtonText = text or ""
        btn.Selected = false
        btn.Font = "InvMed"
        function btn:Paint(pw, ph)
            local P = GetPalette()
            local bg = P.btn
            if self:GetDisabled() then
                bg = Color(bg.r, bg.g, bg.b, 120)
            elseif self.Depressed or self:IsDown() or self.Selected then
                bg = P.primary
            elseif self.Hovered then
                bg = P.btnHover
            end
            draw.RoundedBox(P.radius or 6, 0, 0, pw, ph, bg)
            surface.SetDrawColor(P.outline)
            surface.DrawOutlinedRect(0, 0, pw, ph, 1)
            surface.SetFont(self.Font)
            local label = self.ButtonText or ""
            local tw, th = surface.GetTextSize(label)
            surface.SetTextColor(P.btnText)
            surface.SetTextPos(math.floor(pw * 0.5 - tw * 0.5), math.floor(ph * 0.5 - th * 0.5))
            surface.DrawText(label)
        end
        return btn
    end

    local container = vgui.Create("DPanel", frame)
    container:Dock(FILL)
    container:DockMargin(0, frame.topBarH, 0, 0)
    container.Paint = nil

    local left = vgui.Create("DPanel", container)
    left:Dock(LEFT)
    left:SetWide(180)
    left.Paint = function(self, lw, lh)
        local P = GetPalette()
        surface.SetDrawColor(P.titlebar)
        surface.DrawRect(0, 0, lw, lh)
        surface.SetDrawColor(P.divider)
        surface.DrawLine(lw - 1, 0, lw - 1, lh)
    end

    local right = vgui.Create("DPanel", container)
    right:Dock(FILL)
    right.Paint = function(self, rw, rh)
        local P = GetPalette()
        surface.SetDrawColor(P.panel)
        surface.DrawRect(0, 0, rw, rh)
    end

    local activeTab = nil
    local tabs = {}

    local function ClearRight()
        for _, child in ipairs(right:GetChildren()) do
            if IsValid(child) then child:Remove() end
        end
    end

    local function CreateTab(name, buildFunc)
        local P = GetPalette()
        local tab = vgui.Create("DButton", left)
        tab:Dock(TOP)
        tab:SetTall(40)
        tab:DockMargin(8, 8, 8, 0)
        tab:SetText("")
        tab.isActive = false
        tab.ButtonText = name
        tab.Paint = function(self, tw, th)
            local P = GetPalette()
            local bg = self.isActive and P.primary or (self:IsHovered() and P.btnHover or P.btn)
            draw.RoundedBox(P.radius or 6, 0, 0, tw, th, bg)
            surface.SetDrawColor(P.outline)
            surface.DrawOutlinedRect(0, 0, tw, th, 1)
            draw.SimpleText(self.ButtonText, "InvMed", tw/2, th/2, P.btnText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        tab.DoClick = function()
            if activeTab then activeTab.isActive = false end
            tab.isActive = true
            activeTab = tab
            ClearRight()
            buildFunc()
        end
        table.insert(tabs, tab)
        return tab
    end

    CreateTab("My Tickets", function()
        local P = GetPalette()
        local scroll = vgui.Create("DScrollPanel", right)
        scroll:Dock(FILL)
        scroll:DockMargin(10, 10, 10, 10)

        local list = vgui.Create("DListLayout", scroll)
        list:Dock(TOP)

        frame._myTicketsList = list
        frame._myTicketsScroll = scroll

        local function FormatAge(seconds)
            if seconds < 60 then return math.floor(seconds).."s"
            elseif seconds < 3600 then return math.floor(seconds/60).."m"
            elseif seconds < 86400 then return math.floor(seconds/3600).."h"
            else return math.floor(seconds/86400).."d" end
        end

        local function ShowTicketDetail(t)
            ClearRight()

            local detailPanel = vgui.Create("DPanel", right)
            detailPanel:Dock(FILL)
            detailPanel:DockMargin(15, 15, 15, 15)
            detailPanel.Paint = nil

            frame._chatActiveTicketId = t.id
            frame._chatScroll = nil
            frame._chatInput = nil

            local backBtn = StyledButton(detailPanel, "â† Back to Tickets")
            backBtn:Dock(TOP)
            backBtn:SetTall(36)
            backBtn:DockMargin(0, 0, 0, 15)
            backBtn.DoClick = function()
                if tabs[1] then tabs[1]:DoClick() end
                frame._chatActiveTicketId = nil
            end

            local headerPanel = vgui.Create("DPanel", detailPanel)
            headerPanel:Dock(TOP)
            headerPanel:SetTall(80)
            headerPanel.Paint = function(self, pw, ph)
                local P = GetPalette()
                surface.SetDrawColor(P.titlebar)
                surface.DrawRect(0, 0, pw, ph)
                surface.SetDrawColor(P.outline)
                surface.DrawOutlinedRect(0, 0, pw, ph, 1)
            end

            local headerContent = vgui.Create("DPanel", headerPanel)
            headerContent:Dock(FILL)
            headerContent:DockMargin(15, 15, 15, 15)
            headerContent.Paint = nil

            local titleLabel = vgui.Create("DLabel", headerContent)
            titleLabel:Dock(TOP)
            titleLabel:SetText("Ticket #"..(t.id or "?"))
            titleLabel:SetFont("InvMed")
            titleLabel:SetTextColor(P.text)

            local infoRow = vgui.Create("DPanel", headerContent)
            infoRow:Dock(TOP)
            infoRow:DockMargin(0, 8, 0, 0)
            infoRow:SetTall(20)
            infoRow.Paint = nil

            local statusLabel = vgui.Create("DLabel", infoRow)
            statusLabel:Dock(LEFT)
            statusLabel:SetWide(120)
            statusLabel:SetText("Status: "..string.upper(t.status or "OPEN"))
            statusLabel:SetFont("InvSmall")

            local statusColor = Color(220, 80, 80)
            if string.lower(t.status or "") == "claimed" then
                statusColor = Color(100, 200, 100)
            elseif string.lower(t.status or "") == "closed" then
                statusColor = Color(150, 150, 150)
            end
            statusLabel:SetTextColor(statusColor)

            if t.claimedByName then
                local staffLabel = vgui.Create("DLabel", infoRow)
                staffLabel:Dock(LEFT)
                staffLabel:SetWide(200)
                staffLabel:SetText("Handled by: "..t.claimedByName)
                staffLabel:SetFont("InvSmall")
                staffLabel:SetTextColor(Color(100, 200, 100))
            end

            if IsValid(frame) then
                frame._chatContext = {
                    reporterSID64 = tostring(t.reporter or t.reporterId or ""),
                    handlerSID64 = tostring(t.claimedBy or t.claimedById or "")
                }
            end

            local descLabel = vgui.Create("DLabel", detailPanel)
            descLabel:Dock(TOP)
            descLabel:DockMargin(0, 0, 0, 5)
            descLabel:SetText("Your Issue:")
            descLabel:SetFont("InvMed")
            descLabel:SetTextColor(P.text)

            local descBox = vgui.Create("DPanel", detailPanel)
            descBox:Dock(TOP)
            descBox:SetTall(80)
            descBox:DockMargin(0, 0, 0, 15)
            descBox.Paint = function(self, pw, ph)
                surface.SetDrawColor(P.inputBg)
                surface.DrawRect(0, 0, pw, ph)
                surface.SetDrawColor(P.inputBorder)
                surface.DrawOutlinedRect(0, 0, pw, ph, 1)
            end

            local descText = vgui.Create("DLabel", descBox)
            descText:Dock(FILL)
            descText:DockMargin(10, 10, 10, 10)
            descText:SetText(t.description or "")
            descText:SetFont("InvSmall")
            descText:SetTextColor(P.inputText)
            descText:SetWrap(true)
            descText:SetAutoStretchVertical(true)

            local chatLabel = vgui.Create("DLabel", detailPanel)
            chatLabel:Dock(TOP)
            chatLabel:DockMargin(0, 0, 0, 5)
            chatLabel:SetText("Conversation")
            chatLabel:SetFont("InvMed")
            chatLabel:SetTextColor(P.text)

            local chatWrap = vgui.Create("DPanel", detailPanel)
            chatWrap:Dock(FILL)
            chatWrap:DockMargin(0, 0, 0, 10)
            chatWrap.Paint = function(self, pw, ph)
                local P = GetPalette()
                surface.SetDrawColor(P.titlebar)
                surface.DrawRect(0, 0, pw, ph)
                surface.SetDrawColor(P.outline)
                surface.DrawOutlinedRect(0, 0, pw, ph, 1)
            end

            local chatScroll = vgui.Create("DScrollPanel", chatWrap)
            chatScroll:Dock(FILL)
            chatScroll:DockMargin(8, 8, 8, 8)
            frame._chatScroll = chatScroll

            local function AddBubble(msg)
                if not IsValid(chatScroll) then return end
                local reporterSID = tostring(t.reporter or t.reporterId or "")
                local handlerSID = tostring(t.claimedBy or t.claimedById or "")
                local msgSID = tostring(msg.sid or "")
                local isCreator = (msgSID ~= "" and msgSID == reporterSID)
                local isHandler = (msgSID ~= "" and handlerSID ~= "" and msgSID == handlerSID)
                local holder = vgui.Create("DPanel", chatScroll)
                holder:Dock(TOP)
                holder:DockMargin(0, 0, 0, 6)
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

                    surface.SetDrawColor(bg)
                    surface.DrawRect(0, 0, pw, ph)
                    surface.SetDrawColor(border)
                    surface.DrawOutlinedRect(0, 0, pw, ph, 1)

                    local who = msg.name or (isHandler and "Handler" or (isCreator and "Creator" or "Player"))
                    local when = os.date("%I:%M %p", tonumber(msg.time or os.time()))
                    local nameClr = (isHandler or isCreator) and Color(245,245,245) or Color(190,192,195)
                    draw.SimpleText(who.." Â· "..when, "InvSmall", 8, 6, nameClr, TEXT_ALIGN_LEFT)
                end

                local text = vgui.Create("DLabel", row)
                text:Dock(FILL)
                text:DockMargin(8, 20, 8, 8)
                text:SetFont("InvSmall")
                local P2 = GetPalette()
                text:SetTextColor((isHandler or isCreator) and Color(250,250,250) or P2.inputText)
                text:SetWrap(true)
                text:SetAutoStretchVertical(true)
                do
                    local raw = tostring(msg.text or "")
                    if #raw > 75 then
                        raw = string.sub(raw, 1, 75) .. "..."
                    end
                    text:SetText(raw)
                end

                chatScroll:InvalidateLayout(true)
                chatScroll:PerformLayout()
                timer.Simple(0, function()
                    if IsValid(chatScroll) then chatScroll:GetVBar():SetScroll(chatScroll:GetVBar():GetScroll() + 9999) end
                end)
            end

            if istable(t.messages) then
                for _, m in ipairs(t.messages) do AddBubble(m) end
            end

            if string.lower(t.status or "") ~= "closed" then
                local actionRow = vgui.Create("DPanel", detailPanel)
                actionRow:Dock(BOTTOM)
                actionRow:SetTall(72)
                actionRow:DockMargin(0, 10, 0, 0)
                actionRow.Paint = nil

                local input = vgui.Create("DTextEntry", actionRow)
                input:Dock(FILL)
                input:DockMargin(0, 0, 10, 0)
                input:SetTall(36)
                input:SetFont("InvSmall")
                input:SetPlaceholderText("Type a message to staff...")
                input.Paint = function(self, bw, bh)
                    local P = GetPalette()
                    surface.SetDrawColor(P.inputBg)
                    surface.DrawRect(0, 0, bw, bh)
                    surface.SetDrawColor(P.inputBorder)
                    surface.DrawOutlinedRect(0, 0, bw, bh, 1)
                    self:DrawTextEntryText(P.inputText, P.primary, P.inputText)

                    local MAXLEN = 75
                    local txt = tostring(self:GetValue() or "")
                    local counter = string.format("%d/%d", math.min(#txt, MAXLEN), MAXLEN)
                    surface.SetFont("InvSmall")
                    local tw, th = surface.GetTextSize(counter)
                    surface.SetTextColor(200,200,200,180)
                    surface.SetTextPos(bw - tw - 6, bh - th - 4)
                    surface.DrawText(counter)
                end

                do
                    local MAXLEN = 75
                    input._maxLen = MAXLEN
                    input:SetUpdateOnType(true)
                    function input:AllowInput(ch)
                        local v = self:GetValue() or ""
                        if self.GetSelectedText and self:GetSelectedText() ~= "" then return false end
                        if #v >= (self._maxLen or MAXLEN) then return true end
                        return false
                    end
                    function input:OnTextChanged()
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
                frame._chatInput = input

                local sendBtn = StyledButton(actionRow, "Send")
                sendBtn:SetSize(100, 36)
                sendBtn:Dock(RIGHT)
                sendBtn.DoClick = function()
                    local MAXLEN = 75
                    local text = input:GetValue() or ""
                    if text == "" then return end
                    if #text > MAXLEN then text = string.sub(text, 1, MAXLEN) end
                    net.Start("Monarch_Tickets_Message")
                        net.WriteUInt(t.id, 16)
                        net.WriteString(text)
                    net.SendToServer()
                    input:SetText("")
                end

                local closeBtn = StyledButton(actionRow, "Close Ticket")
                closeBtn:SetSize(150, 36)
                closeBtn:Dock(RIGHT)
                closeBtn.Paint = function(self, pw, ph)
                    local P = GetPalette()
                    local bg = self:IsHovered() and Color(180, 80, 80) or Color(160, 60, 60)
                    draw.RoundedBox(P.radius or 6, 0, 0, pw, ph, bg)
                    surface.SetDrawColor(P.outline)
                    surface.DrawOutlinedRect(0, 0, pw, ph, 1)
                    surface.SetFont(self.Font)
                    local label = self.ButtonText or ""
                    local tw, th = surface.GetTextSize(label)
                    surface.SetTextColor(color_white)
                    surface.SetTextPos(math.floor(pw * 0.5 - tw * 0.5), math.floor(ph * 0.5 - th * 0.5))
                    surface.DrawText(label)
                end
                closeBtn.DoClick = function()
                    Derma_Query("Are you sure you want to close this ticket?", "Close Ticket",
                        "Yes, Close", function()
                            net.Start("Monarch_Tickets_Action")
                                net.WriteUInt(t.id, 16)
                                net.WriteString("close")
                            net.SendToServer()
                            chat.AddText(Color(100, 200, 100), "[Tickets] ", Color(200, 200, 200), "Ticket #"..t.id.." has been closed.")
                            surface.PlaySound("buttons/button14.wav")
                            if tabs[1] then tabs[1]:DoClick() end
                            frame._chatActiveTicketId = nil
                        end,
                        "Cancel", function() end
                    )
                end

                local helpText = vgui.Create("DLabel", actionRow)
                helpText:Dock(FILL)
                helpText:DockMargin(15, 0, 0, 0)
                helpText:SetText("Note: Staff may continue to help you even after you close the ticket.")
                helpText:SetFont("InvSmall")
                helpText:SetTextColor(Color(P.text.r * 0.6, P.text.g * 0.6, P.text.b * 0.6))
                helpText:SetWrap(true)
            end

            if string.lower(t.status or "") == "closed" then
                local closedMsg = vgui.Create("DLabel", detailPanel)
                closedMsg:Dock(TOP)
                closedMsg:DockMargin(0, 0, 0, 15)
                closedMsg:SetText("This ticket has been closed.")
                closedMsg:SetFont("InvMed")
                closedMsg:SetTextColor(Color(150, 150, 150))
                closedMsg:SetContentAlignment(5)
            end
        end

        local function CreateTicketCard(t)
            local card = vgui.Create("DButton", list)
            card:Dock(TOP)
            card:DockMargin(0, 0, 0, 10)
            card:SetTall(120)
            card:SetText("")
            card.Paint = function(self, pw, ph)
                local P = GetPalette()
                local bg = self:IsHovered() and P.btnHover or P.titlebar
                surface.SetDrawColor(bg)
                surface.DrawRect(0, 0, pw, ph)

                local statusColor = P.primary
                if string.lower(t.status or "") == "claimed" then
                    statusColor = Color(100, 180, 100)
                elseif string.lower(t.status or "") == "closed" then
                    statusColor = Color(120, 120, 120)
                end
                surface.SetDrawColor(statusColor)
                surface.DrawRect(0, 0, 4, ph)

                surface.SetDrawColor(P.outline)
                surface.DrawOutlinedRect(0, 0, pw, ph, 2)
            end
            card.DoClick = function()
                ShowTicketDetail(t)
            end

            local content = vgui.Create("DPanel", card)
            content:Dock(FILL)
            content:DockMargin(12, 10, 10, 10)
            content.Paint = nil
            content:SetMouseInputEnabled(false)

            local header = vgui.Create("DPanel", content)
            header:Dock(TOP)
            header:SetTall(24)
            header.Paint = nil

            local idLabel = vgui.Create("DLabel", header)
            idLabel:Dock(LEFT)
            idLabel:SetWide(80)
            idLabel:SetText("Ticket #"..(t.id or "?"))
            idLabel:SetFont("InvMed")
            idLabel:SetTextColor(P.text)

            local statusLabel = vgui.Create("DLabel", header)
            statusLabel:Dock(LEFT)
            statusLabel:SetWide(100)
            statusLabel:SetText(string.upper(t.status or "OPEN"))
            statusLabel:SetFont("InvSmall")

            local statusColor = Color(220, 80, 80)
            if string.lower(t.status or "") == "claimed" then
                statusColor = Color(100, 200, 100)
            elseif string.lower(t.status or "") == "closed" then
                statusColor = Color(150, 150, 150)
            end
            statusLabel:SetTextColor(statusColor)

            local ageLabel = vgui.Create("DLabel", header)
            ageLabel:Dock(RIGHT)
            ageLabel:SetWide(60)
            local age = t.created and FormatAge(os.time() - t.created) or "?"
            ageLabel:SetText(age.." ago")
            ageLabel:SetFont("InvSmall")
            ageLabel:SetTextColor(Color(P.text.r * 0.7, P.text.g * 0.7, P.text.b * 0.7))
            ageLabel:SetContentAlignment(6)

            local desc = vgui.Create("DLabel", content)
            desc:Dock(TOP)
            desc:DockMargin(0, 8, 0, 0)
            desc:SetTall(40)
            local descText = t.description or ""
            if #descText > 100 then descText = string.sub(descText, 1, 100).."..." end
            desc:SetText(descText)
            desc:SetFont("InvSmall")
            desc:SetTextColor(P.inputText)
            desc:SetWrap(true)

            if t.claimedByName then
                local staffInfo = vgui.Create("DLabel", content)
                staffInfo:Dock(TOP)
                staffInfo:DockMargin(0, 8, 0, 0)
                staffInfo:SetText("Handled by: "..t.claimedByName)
                staffInfo:SetFont("InvSmall")
                staffInfo:SetTextColor(Color(100, 200, 100))
            end

            return card
        end

        local function PopulateMyTickets(payload)
            list:Clear()
            local mySID = LocalPlayer():SteamID64()
            local myTickets = {}

            for _, t in ipairs(payload or {}) do
                if t.reporter == mySID then
                    table.insert(myTickets, t)
                end
            end

            if #myTickets == 0 then
                local noTickets = vgui.Create("DPanel", list)
                noTickets:Dock(TOP)
                noTickets:SetTall(100)
                noTickets.Paint = function(self, nw, nh)
                    local P = GetPalette()
                    draw.SimpleText("You have no active tickets.", "InvMed", nw/2, nh/2 - 12, P.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText("Use the 'Create Ticket' tab to submit a new ticket.", "InvSmall", nw/2, nh/2 + 12, Color(P.text.r * 0.7, P.text.g * 0.7, P.text.b * 0.7), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            else

                table.sort(myTickets, function(a, b) return (a.created or 0) > (b.created or 0) end)
                for _, t in ipairs(myTickets) do
                    CreateTicketCard(t)
                end
            end
        end

        frame._populateMyTickets = PopulateMyTickets

        frame._gotoMyTickets = function()
            if tabs[1] then tabs[1]:DoClick() end
        end

        net.Start("Monarch_Tickets_RequestList")
        net.SendToServer()
    end)

    CreateTab("Create Ticket", function()
        local P = GetPalette()
        local content = vgui.Create("DPanel", right)
        content:Dock(FILL)
        content:DockMargin(20, 20, 20, 20)
        content.Paint = nil

        local title = vgui.Create("DLabel", content)
        title:Dock(TOP)
        title:DockMargin(0, 0, 0, 9)
        title:SetText("Create New Ticket")
        title:SetFont("InvMed")
        title:SetTextColor(P.text)
        title:SetContentAlignment(5)

        local infoLabel = vgui.Create("DLabel", content)
        infoLabel:Dock(TOP)
        infoLabel:DockMargin(0, 0, 0, 20)
        infoLabel:SetText("Describe your issue below. Staff will be notified and will respond to you.")
        infoLabel:SetFont("InvSmall")
        infoLabel:SetTextColor(Color(P.text.r * 0.8, P.text.g * 0.8, P.text.b * 0.8))
        infoLabel:SetWrap(true)
        infoLabel:SetAutoStretchVertical(true)

        local descLabel = vgui.Create("DLabel", content)
        descLabel:Dock(TOP)
        descLabel:DockMargin(0, 0, 0, 8)
        descLabel:SetText("Issue Description:")
        descLabel:SetFont("InvMed")
        descLabel:SetTextColor(P.text)

        local descBox = vgui.Create("DTextEntry", content)
        descBox:Dock(TOP)
        descBox:DockMargin(0, 0, 0, 20)
        descBox:SetTall(150)
        descBox:SetMultiline(true)
        descBox:SetFont("InvSmall")
        descBox:SetPlaceholderText("Describe what you need help with...")
        descBox.Paint = function(self, bw, bh)
            local P = GetPalette()
            surface.SetDrawColor(P.inputBg)
            surface.DrawRect(0, 0, bw, bh)
            surface.SetDrawColor(P.inputBorder)
            surface.DrawOutlinedRect(0, 0, bw, bh, 1)
            self:DrawTextEntryText(P.inputText, P.primary, P.inputText)
        end

        local helpText = vgui.Create("DLabel", content)
        helpText:Dock(TOP)
        helpText:DockMargin(0, 0, 0, 20)
        helpText:SetText("Tip: You can also type @ followed by your message in chat to create a ticket.")
        helpText:SetFont("InvSmall")
        helpText:SetTextColor(Color(P.text.r * 0.6, P.text.g * 0.6, P.text.b * 0.6))
        helpText:SetWrap(true)
        helpText:SetAutoStretchVertical(true)

        local btnRow = vgui.Create("DPanel", content)
        btnRow:Dock(TOP)
        btnRow:SetTall(36)
        btnRow.Paint = nil

        local submitBtn = StyledButton(btnRow, "Submit Ticket")
        submitBtn:SetSize(140, 36)
        submitBtn:Dock(LEFT)
        submitBtn:DockMargin(0, 0, 10, 0)
        submitBtn.DoClick = function()
            local desc = descBox:GetValue()
            if desc == "" or #desc < 3 then
                chat.AddText(Color(255, 100, 100), "[Tickets] ", Color(200, 200, 200), "Please enter a description (at least 3 characters).")
                surface.PlaySound("buttons/button10.wav")
                return
            end

            net.Start("Monarch_Tickets_Create")
                net.WriteString(desc)
            net.SendToServer()

            chat.AddText(Color(100, 200, 100), "[Tickets] ", Color(200, 200, 200), "Your ticket has been submitted! Staff will respond soon.")
            surface.PlaySound("buttons/button14.wav")
            descBox:SetText("")

            if tabs[1] then tabs[1]:DoClick() end
        end
    end)

    if tabs[1] then tabs[1]:DoClick() end
end

Monarch_Tickets_OpenPlayerUI = OpenPlayerTicketUI

