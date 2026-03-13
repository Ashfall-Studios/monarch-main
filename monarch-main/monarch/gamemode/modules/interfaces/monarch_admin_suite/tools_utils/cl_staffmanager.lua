return function(ctx)
    local frame = ctx.frame
    local right = ctx.right
    local StyledButton = ctx.StyledButton
    local PanelControlButton = ctx.PanelControlButton
    local GetPalette = ctx.GetPalette
    local ClearRight = ctx.ClearRight
    local OpenCreateTicket = ctx.OpenCreateTicket
    local BuildTicketsView, BuildToolsView, BuildCustomToolsView, BuildPlayersView, BuildCharsView, BuildStaffView

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

    return BuildStaffView
end

