return function(ctx)
    local frame = ctx.frame
    local right = ctx.right
    local StyledButton = ctx.StyledButton
    local PanelControlButton = ctx.PanelControlButton
    local GetPalette = ctx.GetPalette
    local ClearRight = ctx.ClearRight
    local OpenCreateTicket = ctx.OpenCreateTicket
    local BuildTicketsView, BuildToolsView, BuildCustomToolsView, BuildPlayersView, BuildCharsView, BuildStaffView

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

    return BuildCharsView
end

