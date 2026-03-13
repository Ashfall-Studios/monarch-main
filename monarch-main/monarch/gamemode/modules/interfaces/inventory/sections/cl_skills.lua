return function(PANEL)
    if not CLIENT then return end

    local Scale = (Monarch and Monarch.UI and Monarch.UI.Scale) or function(v) return v end

function PANEL:CreateSkillsPanel(parent)
    local base = vgui.Create("DPanel", self)
    base:SetSize(Scale(600), Scale(680))
    base:SetPos(Scale(1200), Scale(40))
    base.Paint = function(s, pw, ph)
    end

    local w, h = base:GetSize()
    local col = vgui.Create("DPanel", base)
    col:SetSize(w, h)
    col:SetPos(0, 0)
    col.Paint = function() end

    local function GetP()
        if Monarch and Monarch.Theme and Monarch.Theme.Get then
            return Monarch.Theme.Get()
        end
        return {
            panel = Color(25, 25, 25),
            outline = Color(50, 50, 50),
            titlebar = Color(35, 35, 35),
            divider = Color(60, 60, 60, 160),
            text = Color(220, 220, 220),
            btn = Color(45, 45, 45),
            btnHover = Color(65, 65, 65),
            btnText = Color(230, 230, 230),
            primary = Color(200, 200, 200),
            primaryHover = Color(220, 220, 220),
            inputBg = Color(30, 30, 30),
            inputBorder = Color(80, 80, 80),
            inputText = Color(210, 210, 210),
            radius = 6,
        }
    end

    local function DrawRoundedMaterial(radius, x, y, w, h, mat, color, drawX, drawY, drawW, drawH)
        if not mat or mat:IsError() then return end
        if w <= 0 or h <= 0 then return end

        render.ClearStencil()
        render.SetStencilEnable(true)
        render.SetStencilWriteMask(0xFF)
        render.SetStencilTestMask(0xFF)
        render.SetStencilReferenceValue(1)
        render.SetStencilCompareFunction(STENCIL_ALWAYS)
        render.SetStencilPassOperation(STENCIL_REPLACE)
        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilZFailOperation(STENCIL_KEEP)

        render.OverrideColorWriteEnable(true, false)
        draw.RoundedBox(radius, x, y, w, h, Color(0, 0, 0, 255))
        render.OverrideColorWriteEnable(false)

        render.SetStencilCompareFunction(STENCIL_EQUAL)
        render.SetStencilPassOperation(STENCIL_KEEP)

        surface.SetMaterial(mat)
        surface.SetDrawColor(color)
        surface.DrawTexturedRect(drawX or x, drawY or y, drawW or w, drawH or h)

        render.SetStencilEnable(false)
        render.SetStencilCompareFunction(STENCIL_ALWAYS)
        render.SetStencilPassOperation(STENCIL_KEEP)
    end

    local iconSize = Scale(55)
    local iconSpacing = Scale(10)

    local iconShadow = vgui.Create("DImage", col)
    iconShadow:SetImage("mrp/icons/skills.png")
    iconShadow:SetSize(iconSize, iconSize)
    iconShadow:SetImageColor(Color(0, 0, 0, 150))

    local icon = vgui.Create("DImage", col)
    icon:SetImage("mrp/icons/skills.png")
    icon:SetSize(iconSize, iconSize)
    icon:SetImageColor(Color(185, 185, 185))

    local titleShadow = vgui.Create("DLabel", col)
    titleShadow:SetFont("Inventory_Title")
    titleShadow:SetColor(Color(0, 0, 0, 250))
    titleShadow:SetText("PROGRESSION")
    titleShadow:SizeToContents()
    local totalWidth = iconSize + iconSpacing + titleShadow:GetWide()
    local centerX = (col:GetWide() - totalWidth) * 0.5
    iconShadow:SetPos(centerX + 2, Scale(20) + 2)
    titleShadow:SetPos(centerX + iconSize + iconSpacing + 2, Scale(20) + 2)

    local title = vgui.Create("DLabel", col)
    title:SetFont("Inventory_Title")
    title:SetColor(Color(185, 185, 185))
    title:SetText("PROGRESSION")
    title:SizeToContents()
    icon:SetPos(centerX, Scale(20) + (title:GetTall() - iconSize) * 0.5)
    title:SetPos(centerX + iconSize + iconSpacing, Scale(20))

    local showingFaction = false
    local lastSkillRenderTime = 0
    local lastFactionRenderTime = 0
    local isRendering = false

    local switchBtn = vgui.Create("DButton", col)
    switchBtn:SetText("Switch to Faction Progression")
    switchBtn:SetFont("InvSmall")
    switchBtn:SetTextColor(Color(220, 220, 220))
    switchBtn:SetSize(Scale(580), Scale(26))
    switchBtn:SetPos((col:GetWide() - switchBtn:GetWide()) * 0.5, Scale(110))
    switchBtn.Paint = function(s, w, h)
        local P = GetP()
        local bg = s:IsHovered() and P.btnHover or P.btn
        surface.SetDrawColor(bg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(P.inputBorder)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    if net then
        net.Start("Monarch_RequestWhitelistSync")
        net.SendToServer()
    end

    local list = vgui.Create("DScrollPanel", col)
    list:SetPos(10, Scale(147))
    list:SetSize(col:GetWide() - 20, col:GetTall() - Scale(157))
    local listCanvas = list:GetCanvas()
    function listCanvas:Paint() end
    local vbar = list:GetVBar()
    if IsValid(vbar) then
        vbar.Paint = function(s,w,h) surface.SetDrawColor(25,25,25,255) surface.DrawRect(0,0,w,h) end
        vbar.btnUp.Paint = function(s,w,h) surface.SetDrawColor(45,45,45) surface.DrawRect(0,0,w,h) end
        vbar.btnDown.Paint = vbar.btnUp.Paint
        vbar.btnGrip.Paint = function(s,w,h) surface.SetDrawColor(70,70,70) surface.DrawRect(0,0,w,h) end
    end

    local function renderSkills()
        if isRendering then return end
        isRendering = true

        listCanvas:Clear()
        local ply = LocalPlayer()
        local skills = (Monarch and Monarch.Skills and Monarch.Skills.Registry) or {}
        local ordered = {}
        for id, def in pairs(skills) do
            ordered[#ordered+1] = {id=id, def=def}
        end
        table.sort(ordered, function(a, b)
            local an = (a.def and a.def.Name) or a.id or ""
            local bn = (b.def and b.def.Name) or b.id or ""
            return string.lower(an) < string.lower(bn)
        end)

        local bg = Material("mrp/menu_stuff/bg_grunge.png")

        if #ordered == 0 then
            local empty = vgui.Create("DLabel", listCanvas)
            empty:Dock(TOP)
            empty:SetFont("InvSmall")
            empty:SetTextColor(Color(200,200,200))
            empty:SetText("No skills registered.")
            empty:DockMargin(4,4,4,4)
            empty:SizeToContents()
            isRendering = false
            return
        end
        for _, sk in ipairs(ordered) do
            local id, def = sk.id, sk.def

            local row = vgui.Create("DPanel", listCanvas)
            row:Dock(TOP)
            row:SetTall(Scale(90))
            row:DockMargin(0,0,0,6)
            row.gradientMat = Material("vgui/gradient-l")
            row.gradientMatS = Material("mrp/spherical_gradient.png")

            local iconPath = (def.Icon) or "icons/skills/scavenging-icon128.png"
            local iconMat = Material(iconPath, "mips")
            local skillColor = (def.Color) or Color(100, 100, 100, 255)
            local bgMat = Material("mrp/square_rounded.png")

            row.Paint = function(s,w,h)
                local isHovered = s:IsHovered()
                local bgColor = isHovered and Color(52,52,52,200) or Color(42,42,42,200)
                local outlineColor =  Color(20, 20, 20, 220)
                local inset = 2
                local innerX = inset
                local innerY = inset
                local innerW = w - (inset * 2)
                local innerH = h - (inset * 2)
                local cardRadius = 6
                local innerRadius = 5

                draw.RoundedBox(cardRadius, 0, 0, w, h, outlineColor)
                draw.RoundedBox(innerRadius, innerX, innerY, innerW, innerH, bgColor)

                DrawRoundedMaterial(innerRadius, innerX, innerY, innerW, innerH, s.gradientMatS, Color(55, 55, 55, 200), innerX, innerY, innerW * 2, innerH * 1.5)

                if s.gradientMat and not s.gradientMat:IsError() then
                    local gradAlpha = isHovered and 40 or 25
                    local edgeGradW = innerW * 0.2
                    DrawRoundedMaterial(innerRadius, innerX, innerY, innerW, innerH, s.gradientMat, Color(skillColor.r, skillColor.g, skillColor.b, gradAlpha), innerX, innerY, edgeGradW, innerH)
                end

                local iconSize = 64
                local iconX = 14
                local iconY = (h - iconSize) * 0.5
                if iconMat and not iconMat:IsError() then
                    surface.SetMaterial(iconMat)
                    surface.SetDrawColor(240, 240, 240, 255)
                    surface.DrawTexturedRect(iconX, iconY, iconSize, iconSize)
                end

                local barH = 5
                local barX = innerX
                local barW = innerW
                local barY = innerY + innerH - barH
                local barRadius = 3
                draw.RoundedBoxEx(barRadius, barX, barY, barW, barH, Color(80, 80, 80, 255), true, true, true, true)

                local progress = math.Clamp(s._frac or 0, 0, 1)
                if progress > 0 then
                    local fillW = barW * progress
                    local roundRight = fillW >= (barRadius * 2)
                    draw.RoundedBoxEx(barRadius, barX, barY, fillW, barH, Color(skillColor.r, skillColor.g, skillColor.b, 255), true, roundRight, true, roundRight)
                end
            end

            local lvl, cur, req, frac = 0,0,0,0
            if Monarch and Monarch.Skills and Monarch.Skills.GetProgress then
                lvl, cur, req, frac = Monarch.Skills.GetProgress(ply, id)
            end
            row._frac = frac

            local name = vgui.Create("DLabel", row)
            name:SetFont("SkillsTitle")
            name:SetTextColor(Color(245,245,245))
            name:SetPos(90, 12)
            name:SetText(string.upper(def.Name or id))
            name:SizeToContents()

            local levelLbl = vgui.Create("DLabel", row)
            levelLbl:SetFont("SkillsLabel")
            levelLbl:SetTextColor(Color(180,180,180))
            levelLbl:SetPos(90, 38)
            local getName = Monarch and Monarch.Skills and Monarch.Skills.GetLevelName
            local lvlName = getName and getName(lvl) or ("Level " .. tostring(lvl))
            levelLbl:SetText(lvlName)
            levelLbl:SizeToContents()

            local expLbl = vgui.Create("DLabel", row)
            expLbl:SetFont("InvSmall")
            expLbl:SetTextColor(Color(160,160,160))
            expLbl:SetText("Experience")
            expLbl:SizeToContents()
            expLbl:SetPos(row:GetWide() - expLbl:GetWide() - 16, (row:GetTall() - expLbl:GetTall()) * 0.5 + Scale(26))

            function row:PerformLayout()
                if IsValid(expLbl) then
                    expLbl:SetPos(row:GetWide() - expLbl:GetWide() - 16, (row:GetTall() - expLbl:GetTall()) * 0.5 + Scale(26))
                end
            end

            local function refresh()
                if not (Monarch and Monarch.Skills and Monarch.Skills.GetProgress) then
                    return
                end
                local rlvl, _, _, rfrac = Monarch.Skills.GetProgress(ply, id)
                row._frac = rfrac
                if IsValid(levelLbl) then
                    local getName = Monarch and Monarch.Skills and Monarch.Skills.GetLevelName
                    local lvlName = getName and getName(rlvl) or ("Level " .. tostring(rlvl))
                    levelLbl:SetText(lvlName)
                    levelLbl:SizeToContents()
                end
                if IsValid(row) then row:InvalidateLayout(true) end
            end

            row.Think = function()
                if (row._nextRefresh or 0) < CurTime() then
                    row._nextRefresh = CurTime() + 0.5
                    refresh()
                end
            end

            hook.Add("Monarch_SkillsUpdated", row, refresh)
        end
        isRendering = false
    end

    local function renderFactions()
        if isRendering then return end
        isRendering = true

        listCanvas:Clear()
        local ply = LocalPlayer()

        local vendors = Monarch and Monarch.RankVendors or {}
        local teams = Monarch and Monarch.Team or {}

        local ladder = Monarch and Monarch.RankLadders or {}
        if not (ladder and next(ladder)) then
            ladder = {}
            for _, vend in pairs(vendors or {}) do
                for _, r in ipairs(vend.ranks or {}) do
                    if r.team and r.whitelistLevel then
                        local tid = tonumber(r.team)
                        if tid then
                            ladder[tid] = ladder[tid] or {}
                            table.insert(ladder[tid], { lvl = tonumber(r.whitelistLevel) or 0, name = r.grouprank or r.name or r.id })
                        end
                    end
                end
            end
            for tid, arr in pairs(ladder) do
                table.SortByMember(arr, "lvl", true)
            end
        end

        local entries = {}
        local maxTeamID = #team.GetAllTeams()

        for tid = 1, maxTeamID do
            local data = teams[tid]
            if data and istable(data) then
                local level = ply:GetNWInt("MonarchWhitelist_" .. tid, 0)
                local teamLadder = ladder[tid] or {}
                local hasProgressionFlag = (data.HasProgression == true) or (data.hasProgression == true)
                local hasProgressionData = (#teamLadder > 0) or (level > 0)

                if hasProgressionFlag or hasProgressionData then
                    entries[#entries+1] = {
                        id = tid,
                        name = data.name or ("Team " .. tid),
                        color = data.color or Color(180,180,180),
                        mat = data.material,
                        level = level,
                        ladder = teamLadder,
                    }
                end
            end
        end

        table.sort(entries, function(a,b) return tostring(a.name) < tostring(b.name) end)

        if #entries == 0 then
            local empty = vgui.Create("DLabel", listCanvas)
            empty:Dock(TOP)
            empty:SetFont("InvSmall")
            empty:SetTextColor(Color(200,200,200))
            empty:SetText("No faction progression found.")
            empty:DockMargin(4,4,4,4)
            empty:SizeToContents()
            isRendering = false
            return
        end

        for _, ent in ipairs(entries) do
            local row = vgui.Create("DPanel", listCanvas)
            row:Dock(TOP)
            row:SetTall(Scale(90))
            row:DockMargin(0,0,0,6)
            row.gradientMat = Material("vgui/gradient-l")
            row.gradientMatS = Material("mrp/spherical_gradient.png")

            local bestLvl = -1
            for _, r in ipairs(ent.ladder) do
                if r.lvl and r.lvl > bestLvl then
                    bestLvl = r.lvl
                end
            end

            row.Paint = function(s,w,h)
                local isHovered = s:IsHovered()
                local bgColor = isHovered and Color(52,52,52,200) or Color(42,42,42,200)
                local outlineColor = Color(20, 20, 20, 220)
                local inset = 2
                local innerX = inset
                local innerY = inset
                local innerW = w - (inset * 2)
                local innerH = h - (inset * 2)
                local cardRadius = 6
                local innerRadius = 5

                draw.RoundedBox(cardRadius, 0, 0, w, h, outlineColor)
                draw.RoundedBox(innerRadius, innerX, innerY, innerW, innerH, bgColor)

                DrawRoundedMaterial(innerRadius, innerX, innerY, innerW, innerH, s.gradientMat, Color(30, 30, 30, 150), innerX, innerY, innerW, innerH)
                DrawRoundedMaterial(innerRadius, innerX, innerY, innerW, innerH, s.gradientMatS, Color(55, 55, 55, 200), Scale(-100) + innerX, innerY, innerW * 2, innerH * 1.5)

                if s.gradientMat and not s.gradientMat:IsError() then
                    local gradAlpha = isHovered and 40 or 25
                    local edgeGradW = innerW * 0.2
                    DrawRoundedMaterial(innerRadius, innerX, innerY, innerW, innerH, s.gradientMat, Color(ent.color.r, ent.color.g, ent.color.b, gradAlpha), innerX, innerY, edgeGradW, innerH)
                end

                if ent.mat and not ent.mat:IsError() then
                    surface.SetMaterial(ent.mat)
                    surface.SetDrawColor(255,255,255,200)
                    surface.DrawTexturedRect(14, (h-64)*0.5, 64, 64)
                end

                local barH = 5
                local barX = innerX
                local barW = innerW
                local barY = innerY + innerH - barH
                local barRadius = 3
                draw.RoundedBoxEx(barRadius, barX, barY, barW, barH, Color(80, 80, 80, 255), true, true, true, true)
                local frac = math.Clamp(ent.level / math.max(bestLvl, 1), 0, 1)
                if frac > 0 then
                    local fillW = barW * frac
                    local roundRight = fillW >= (barRadius * 2)
                    draw.RoundedBoxEx(barRadius, barX, barY, fillW, barH, Color(ent.color.r, ent.color.g, ent.color.b, 255), true, roundRight, true, roundRight)
                end
            end

            local nameLbl = vgui.Create("DLabel", row)
            nameLbl:SetFont("SkillsTitle")
            nameLbl:SetTextColor(Color(245,245,245))
            nameLbl:SetPos(90, 12)
            nameLbl:SetText(string.upper(ent.name))
            nameLbl:SizeToContents()

            local lvlLbl = vgui.Create("DLabel", row)
            lvlLbl:SetFont("SkillsLabel")
            lvlLbl:SetTextColor(Color(180,180,180))
            lvlLbl:SetPos(90, 38)
            lvlLbl:SetText("Level " .. tostring(ent.level or 0))
            lvlLbl:SizeToContents()
        end

        isRendering = false
    end

    switchBtn.DoClick = function()
        showingFaction = not showingFaction
        switchBtn:SetText(showingFaction and "Switch to Skill Progression" or "Switch to Faction Progression")
        if showingFaction then
            renderFactions()
        else
            renderSkills()
        end
    end

    renderSkills()

    hook.Add("Monarch_SkillsUpdated", base, function()
        if not IsValid(base) then
            hook.Remove("Monarch_SkillsUpdated", base)
            return
        end
        if showingFaction then
            renderFactions()
        else
            renderSkills()
        end
    end)

    return base
end

end

