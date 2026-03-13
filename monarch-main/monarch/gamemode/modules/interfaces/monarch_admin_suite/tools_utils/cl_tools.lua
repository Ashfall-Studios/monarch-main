return function(ctx)
    local frame = ctx.frame
    local right = ctx.right
    local StyledButton = ctx.StyledButton
    local PanelControlButton = ctx.PanelControlButton
    local GetPalette = ctx.GetPalette
    local ClearRight = ctx.ClearRight
    local OpenCreateTicket = ctx.OpenCreateTicket
    local BuildTicketsView, BuildToolsView, BuildCustomToolsView, BuildPlayersView, BuildCharsView, BuildStaffView

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
                    del:SetText("X")
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
                    del:SetText("X")
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
            closeBtn:SetText("X")
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

    return BuildToolsView
end

