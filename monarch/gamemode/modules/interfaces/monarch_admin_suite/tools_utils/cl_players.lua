return function(ctx)
    local frame = ctx.frame
    local right = ctx.right
    local StyledButton = ctx.StyledButton
    local PanelControlButton = ctx.PanelControlButton
    local GetPalette = ctx.GetPalette
    local ClearRight = ctx.ClearRight
    local OpenCreateTicket = ctx.OpenCreateTicket
    local BuildTicketsView, BuildToolsView, BuildCustomToolsView, BuildPlayersView, BuildCharsView, BuildStaffView

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

    return BuildPlayersView
end

