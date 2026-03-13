return function(PANEL)
    if not CLIENT then return end

    local Scale = (Monarch and Monarch.UI and Monarch.UI.Scale) or function(v) return v end
    local INV_HOVER_SOUND = "ui/hls_ui_scroll_click.wav"
    local GRADIENT_L = Material("vgui/gradient-l")
    local function DrawRoundedRect(x, y, w, h, radius, color)
        draw.RoundedBox(radius, x, y, w, h, color)
    end

    local function GetItemDurabilityPercent(itemData, itemDef)
        if not (itemDef and itemDef.Durability == true) then return nil end
        if not istable(itemData) then return 100 end
        local pct = math.floor(tonumber(itemData.durability or 100) or 100)
        return math.Clamp(pct, 0, 100)
    end

    local function GetDurabilityColor(pct)
        if not isnumber(pct) then return Color(100, 220, 100, 220) end
        if pct < 20 then
            return Color(220, 70, 70, 220)
        end
        if pct > 50 then
            return Color(95, 220, 95, 220)
        end
        return Color(230, 160, 60, 220)
    end

    local function ResolveSpawnIconOffset(itemDef, isClicked)
        if not istable(itemDef) then return vector_origin end

        local baseOffset = itemDef.PositionSpawnIcon
            or itemDef.PositionSpawnIconIdle
            or itemDef.SpawnIconOffset
            or itemDef.spawnIconOffset
            or vector_origin

        if not isClicked then
            return isvector(baseOffset) and baseOffset or vector_origin
        end

        local clickedOffset = itemDef.PositionSpawnIconClicked
            or itemDef.SpawnIconOffsetClicked
            or itemDef.spawnIconOffsetClicked

        if isvector(clickedOffset) then
            return clickedOffset
        end

        return isvector(baseOffset) and baseOffset or vector_origin
    end

    local function ResolveSpawnIconAngleOffset(itemDef, isClicked)
        if not istable(itemDef) then return angle_zero end

        local baseOffset = itemDef.AngleSpawnIcon
            or itemDef.AngleSpawnIconIdle
            or itemDef.SpawnIconAngleOffset
            or itemDef.spawnIconAngleOffset
            or angle_zero

        if not isClicked then
            return isangle(baseOffset) and baseOffset or angle_zero
        end

        local clickedOffset = itemDef.AngleSpawnIconClicked
            or itemDef.SpawnIconAngleOffsetClicked
            or itemDef.spawnIconAngleOffsetClicked

        if isangle(clickedOffset) then
            return clickedOffset
        end

        return isangle(baseOffset) and baseOffset or angle_zero
    end

    local function ResolveSpawnIconFOV(itemDef, isClicked, fallbackFOV)
        fallbackFOV = tonumber(fallbackFOV) or 36
        if not istable(itemDef) then return fallbackFOV end

        local baseFOV = tonumber(itemDef.FOVSpawnIcon
            or itemDef.FOVSpawnIconIdle
            or itemDef.SpawnIconFOV
            or itemDef.spawnIconFOV)

        if not isClicked then
            return baseFOV or fallbackFOV
        end

        local clickedFOV = tonumber(itemDef.FOVSpawnIconClicked
            or itemDef.SpawnIconFOVClicked
            or itemDef.spawnIconFOVClicked)

        return clickedFOV or baseFOV or fallbackFOV
    end

    local function ResolveSpawnIconModelPanel(iconPanel)
        if not IsValid(iconPanel) then return nil end

        if isfunction(iconPanel.GetEntity) and isfunction(iconPanel.SetCamPos) and isfunction(iconPanel.SetFOV)
            and (isfunction(iconPanel.SetLookAng) or isfunction(iconPanel.SetLookAt)) then
            return iconPanel
        end

        if IsValid(iconPanel.Icon) and isfunction(iconPanel.Icon.GetEntity) and isfunction(iconPanel.Icon.SetCamPos) then
            return iconPanel.Icon
        end

        if isfunction(iconPanel.GetChildren) then
            for _, child in ipairs(iconPanel:GetChildren()) do
                if IsValid(child) and isfunction(child.GetEntity) and isfunction(child.SetCamPos) and isfunction(child.SetFOV)
                    and (isfunction(child.SetLookAng) or isfunction(child.SetLookAt)) then
                    return child
                end
            end
        end

        return nil
    end

    local function ApplySpawnIconPosition(iconPanel, itemDef, isClicked, deferred)
        if not IsValid(iconPanel) then return end

        local modelPanel = ResolveSpawnIconModelPanel(iconPanel)
        if not IsValid(modelPanel) then
            if not deferred then
                timer.Simple(0, function()
                    if IsValid(iconPanel) then
                        ApplySpawnIconPosition(iconPanel, itemDef, isClicked, true)
                    end
                end)
            end
            return
        end

        local ent = modelPanel:GetEntity()
        if not IsValid(ent) then
            if not deferred then
                timer.Simple(0, function()
                    if IsValid(iconPanel) then
                        ApplySpawnIconPosition(iconPanel, itemDef, isClicked, true)
                    end
                end)
            end
            return
        end

        local tab = isfunction(PositionSpawnIcon) and PositionSpawnIcon(ent, ent:GetPos()) or nil

        local camPos = istable(tab) and tab.origin or nil
        if not isvector(camPos) then
            local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
            local center = (mins + maxs) * 0.5
            local radius = math.max((maxs - mins):Length(), 16)
            camPos = center + Vector(radius * 1.1, radius * 1.1, radius * 0.65)
        end
        camPos = camPos + ResolveSpawnIconOffset(itemDef, isClicked)
        modelPanel:SetCamPos(camPos)

        if isfunction(modelPanel.SetFOV) then
            local baseFOV = (istable(tab) and tab.fov) and tonumber(tab.fov) or 36
            modelPanel:SetFOV(ResolveSpawnIconFOV(itemDef, isClicked, baseFOV))
        end

        local baseLookAng = istable(tab) and isangle(tab.angles) and tab.angles or nil
        if not baseLookAng then
            baseLookAng = (ent:OBBCenter() - camPos):Angle()
        end

        local angleOffset = ResolveSpawnIconAngleOffset(itemDef, isClicked)
        local finalLookAng = Angle(
            baseLookAng.p + angleOffset.p,
            baseLookAng.y + angleOffset.y,
            baseLookAng.r + angleOffset.r
        )

        if isfunction(modelPanel.SetLookAng) then
            modelPanel:SetLookAng(finalLookAng)
        elseif isfunction(modelPanel.SetLookAt) then
            local lookDist = math.max(camPos:Distance(ent:OBBCenter()), 16)
            modelPanel:SetLookAt(camPos + finalLookAng:Forward() * lookDist)
        end
    end

    local function ConfigureInventoryModelPanel(panel)
        if not IsValid(panel) then return end
        panel.LayoutEntity = function() end
    end

    local function ResolveSchemaStats(itemPanel, itemDef, defaultStats)
        local schemaStats = Monarch and Monarch.SchemaInventoryStats
        if not (istable(schemaStats) and isfunction(schemaStats.ResolveStats)) then
            return defaultStats
        end

        local ok, handled, value = pcall(schemaStats.ResolveStats, itemPanel, itemDef, defaultStats)
        if not ok then
            return defaultStats
        end
        if handled then
            return value
        end
        return defaultStats
    end

    local function WrapTooltipText(text, font, maxWidth, maxLines)
        text = tostring(text or "")
        if text == "" then return {} end

        surface.SetFont(font)
        local lines = {}
        local current = ""
        local wasTruncated = false

        for word in string.gmatch(text, "%S+") do
            local candidate = (current == "") and word or (current .. " " .. word)
            local candidateW = select(1, surface.GetTextSize(candidate))

            if candidateW <= maxWidth then
                current = candidate
            else
                if current ~= "" then
                    lines[#lines + 1] = current
                end
                current = word

                if maxLines and #lines >= maxLines then
                    wasTruncated = true
                    break
                end
            end
        end

        if current ~= "" and (not maxLines or #lines < maxLines) then
            lines[#lines + 1] = current
        end

        if maxLines and #lines > maxLines then
            while #lines > maxLines do
                table.remove(lines)
            end
        end

        if maxLines and #lines == maxLines and wasTruncated then
            local last = lines[#lines] or ""
            local ellipsis = "..."
            while last ~= "" do
                local test = last .. ellipsis
                local w = select(1, surface.GetTextSize(test))
                if w <= maxWidth then break end
                last = string.sub(last, 1, math.max(0, #last - 1))
            end
            lines[#lines] = string.Trim(last) .. ellipsis
        end

        return lines
    end

    local function TruncateTooltipText(text, font, maxWidth)
        text = tostring(text or "")
        if text == "" then return "" end

        surface.SetFont(font)
        local textW = select(1, surface.GetTextSize(text))
        if textW <= maxWidth then return text end

        local ellipsis = "..."
        local out = text
        while out ~= "" do
            local test = out .. ellipsis
            local w = select(1, surface.GetTextSize(test))
            if w <= maxWidth then
                return string.Trim(out) .. ellipsis
            end
            out = string.sub(out, 1, math.max(0, #out - 1))
        end

        return ellipsis
    end

    function PANEL:EnsureItemHoverTooltip()
        if IsValid(self.itemHoverTooltip) then return self.itemHoverTooltip end

        local tooltip = vgui.Create("DPanel", vgui.GetWorldPanel())
        tooltip:SetVisible(false)
        tooltip:SetMouseInputEnabled(false)
        tooltip:SetKeyboardInputEnabled(false)
        tooltip:SetDrawOnTop(true)
        tooltip.Padding = Scale(8)
        tooltip.MinWidth = math.floor(Scale(180))
        tooltip.MaxWidth = math.floor(Scale(360))
        tooltip.BodyText = ""
        tooltip.FooterText = ""
        tooltip.TitleText = ""
        tooltip.DisplayTitleText = ""
        tooltip.BodyLines = {}

        tooltip.SetTooltipData = function(tp, data)
            data = data or {}
            tp.TitleText = tostring(data.title or "")
            tp.BodyText = tostring(data.body or "")
            tp.FooterText = tostring(data.footer or "")
            tp.DisplayTitleText = tp.TitleText

            local pad = tp.Padding
            surface.SetFont("InvTitle")
            local titleW, titleH = surface.GetTextSize(tp.TitleText ~= "" and tp.TitleText or "M")
            surface.SetFont("InvSmall")
            local footerW, footerH = surface.GetTextSize(tp.FooterText ~= "" and tp.FooterText or "M")
            surface.SetFont("InvMed")
            local bodyRawW, bodyLineH = surface.GetTextSize(tp.BodyText ~= "" and tp.BodyText or "M")

            local widthFromLabels = math.max(titleW, footerW) + (pad * 2) + Scale(10)
            local panelW = math.Clamp(math.max(widthFromLabels, tp.MinWidth), tp.MinWidth, tp.MaxWidth)
            local drawW = panelW - (pad * 2)

            if bodyRawW > drawW then
                panelW = math.Clamp(math.max(panelW, math.min(bodyRawW + (pad * 2) + Scale(10), tp.MaxWidth)), tp.MinWidth, tp.MaxWidth)
                drawW = panelW - (pad * 2)
            end

            tp.BodyLines = WrapTooltipText(tp.BodyText, "InvMed", drawW, 4)

            local maxBodyLineW = 0
            surface.SetFont("InvMed")
            for _, line in ipairs(tp.BodyLines or {}) do
                local lw = surface.GetTextSize(line)
                if lw > maxBodyLineW then
                    maxBodyLineW = lw
                end
            end

            local finalContentW = math.max(titleW, footerW, maxBodyLineW)
            local finalPanelW = math.Clamp(finalContentW + (pad * 2) + Scale(10), tp.MinWidth, tp.MaxWidth)
            local finalDrawW = finalPanelW - (pad * 2)

            if math.abs(finalDrawW - drawW) > 1 then
                tp.BodyLines = WrapTooltipText(tp.BodyText, "InvMed", finalDrawW, 4)
            end

            tp.DisplayTitleText = TruncateTooltipText(tp.TitleText, "InvTitle", finalDrawW)

            local bodyH = math.max(1, #tp.BodyLines) * bodyLineH
            local totalH = pad + titleH + Scale(4) + bodyH + Scale(8) + footerH + pad
            tp:SetSize(finalPanelW, totalH)
        end

        tooltip.Think = function(tp)
            if not IsValid(tp.Anchor) then
                tp:SetVisible(false)
                return
            end

            local mx, my = gui.MousePos()
            local offset = Scale(14)
            local x = mx + offset
            local y = my + offset
            local sw, sh = ScrW(), ScrH()

            if x + tp:GetWide() > sw - 6 then
                x = mx - tp:GetWide() - offset
            end
            if y + tp:GetTall() > sh - 6 then
                y = my - tp:GetTall() - offset
            end

            tp:SetPos(math.max(6, x), math.max(6, y))
        end

        local grad_ra = Material("mrp/spherical_gradient.png")

        tooltip.Paint = function(tp, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(54, 54, 54, 110))

            surface.SetDrawColor(100,100,100,90)
            surface.SetMaterial(grad_ra)
            local gradW = w * 1.5
            local gradH = h * 4
            local gradX = (w - gradW) * 0.5
            local gradY = (h - gradH) * 0.5
            surface.DrawTexturedRect(gradX, gradY, gradW, gradH)

--[[            surface.SetDrawColor(255, 255, 255, 18)
            surface.DrawOutlinedRect(0, 0, w, h, 1)]]

            

            local x = tp.Padding
            local y = tp.Padding

            draw.SimpleText(tp.DisplayTitleText or tp.TitleText, "InvTitle", x, y, Color(240, 240, 240), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            surface.SetFont("InvTitle")
            local _, titleH = surface.GetTextSize("M")
            y = y + titleH + Scale(4)

            local lineY = y
            for _, line in ipairs(tp.BodyLines or {}) do
                draw.SimpleText(line, "InvMed", x, lineY, Color(205, 205, 205), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                surface.SetFont("InvMed")
                local _, lh = surface.GetTextSize("M")
                lineY = lineY + lh
            end

            y = lineY + Scale(6)

            local dividerY = y
            local dividerH = math.max(3, Scale(3))
            local dividerW = math.max(1, w - (tp.Padding * 2))
            local dividerX = tp.Padding
            surface.SetDrawColor(145, 145, 145, 90)
            surface.SetMaterial(GRADIENT_L)
            surface.DrawTexturedRect(0, dividerY, w, dividerH)

            y = dividerY + Scale(4)
            draw.SimpleText(tp.FooterText, "InvSmall", x, y, Color(215, 215, 215), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        self.itemHoverTooltip = tooltip
        return tooltip
    end

    function PANEL:BuildItemHoverTooltipData(itemPanel)
        local def = IsValid(itemPanel) and itemPanel.ItemDef or nil
        if not def then return nil end
        local itemData = IsValid(itemPanel) and itemPanel.ItemData or nil

        local title = def.Name or def.name or itemPanel.ItemClass or "Item"
        local durabilityPct = GetItemDurabilityPercent(itemData, def)
        if durabilityPct ~= nil then
            title = string.format("%s (%d%%)", tostring(title), durabilityPct)
        end
        local body = def.TooltipDescription
            or def.TooltipDesc
            or def.HoverDescription
            or def.HoverDesc
            or def.Description
            or def.description
            or def.Desc
            or "No description available."

        local footer = def.TooltipFooter
            or def.HoverFooter
            or def.Passive
            or def.PassiveLabel
            or def.DropType
            or def.DropLabel

        local isLocked = false
        if def.Locked == true or def.locked == true then
            isLocked = true
        elseif istable(itemData) then
            if itemData.locked == true or itemData.Locked == true then
                isLocked = true
            elseif isstring(itemData.status) and string.lower(itemData.status) == "constrained" then
                isLocked = true
            end
        end

        if footer == nil and def.DeathDrop and not isLocked then
            footer = isstring(def.DeathDrop) and def.DeathDrop or "Death Drop"
        end

        if footer == nil and isLocked then
            footer = "Constrained"
        end

        if footer == nil then
            if def.Illegal then
                footer = "Contraband"
            elseif def.Restricted or def.restricted or def.Locked then
                footer = "Restricted"
            else
                footer = "General Item"
            end
        end

        return {
            title = tostring(title),
            body = tostring(body),
            footer = tostring(footer)
        }
    end

    function PANEL:ShowItemHoverTooltip(itemPanel)
        if not IsValid(itemPanel) then return end
        local tooltip = self:EnsureItemHoverTooltip()
        if not IsValid(tooltip) then return end

        local data = self:BuildItemHoverTooltipData(itemPanel)
        if not data then
            tooltip:SetVisible(false)
            tooltip.Anchor = nil
            return
        end

        tooltip.Anchor = itemPanel
        tooltip:SetTooltipData(data)
        tooltip:SetVisible(true)
        tooltip:MoveToFront()
    end

    function PANEL:HideItemHoverTooltip(itemPanel)
        if not IsValid(self.itemHoverTooltip) then return end
        if IsValid(itemPanel) and self.itemHoverTooltip.Anchor ~= itemPanel then return end
        self.itemHoverTooltip.Anchor = nil
        self.itemHoverTooltip:SetVisible(false)
    end

function PANEL:SetupItems(suppressEquipRefresh)
    local isDragging = Monarch_GetDragState()
    if isDragging then
        return
    end

    if not Monarch or not Monarch.Inventory then

        return
    end

    if self.itemsPanels then
        for _, pnl in pairs(self.itemsPanels) do
            if IsValid(pnl) then pnl:Remove() end
        end
    end

    self.items = {}
    self.itemsPanels = {}
    local totalWeight = 0

    if not self.inventorySlots then

        return
    end

    for i = 1, INVENTORY_SLOT_COUNT do
        local slot = self.inventorySlots[i]
        if slot then
            slot.HasItem = false
            slot.ItemData = nil
            if IsValid(slot.ItemPanel) then
                slot.ItemPanel:Remove()
                slot.ItemPanel = nil
            end
        end
    end

    local steamID = LocalPlayer():SteamID64()
    local realInv = (Monarch.Inventory.Data and Monarch.Inventory.Data[steamID]) or {}
    local count = table.Count(realInv)
    if count == 0 then

        return
    end

    for invSlot = 1, INVENTORY_SLOT_COUNT do
        local itemData = realInv[invSlot]
        if istable(itemData) then
            local item = table.Copy(itemData)
            item.realKey = invSlot
            item.InvID = invSlot
            local itemClass = item.class or item.id
            if itemClass then

                local def = self:ResolveItemDefinition(itemClass)
                if def then
                    item.ItemDef = def
                    totalWeight = totalWeight + (def.Weight or 0)

                    self:CreateGridItemCard(invSlot, item)
                else

                end
            else

            end
        end
    end

    self.invWeight = totalWeight

    if not suppressEquipRefresh then
        timer.Simple(0, function()
            if IsValid(self) and self.RefreshEquipSlots then self:RefreshEquipSlots() end
        end)
    end
end

function PANEL:RefreshUI(reason)
    self:UpdatePlayerInfoUI()

    local prevSelectedSlot = self.lastSelectedSlot
    self:SetupItems(self:IsEquipRefreshSuppressed(reason))
    self:RestoreItemSelection(prevSelectedSlot)
end

function PANEL:CreateGridItemCard(slotIndex, itemData)
    local slot = self.inventorySlots[slotIndex]
    if not slot then return end

    local itemClass = (itemData and (itemData.class or itemData.id or itemData.ItemClass)) or nil
    local itemDef = itemData.ItemDef

    local itemName = itemDef and (itemDef.Name or itemDef.name) or itemClass or "Unknown Item"
    local itemDesc = itemDef and (itemDef.Description or itemDef.description or itemDef.Desc or "There is no Description for this.") or "There is no Description for this."
    local itemID = itemDef and (itemDef.UniqueID or itemDef.uniqueID or 0) or 0
    local itemModel = itemDef and (itemDef.Model or itemDef.model) or "models/props_junk/cardboard_box004a.mdl"

    if IsValid(slot.ItemPanel) then
        slot.ItemPanel:Remove()
    end

    if not IsValid(self.infoCard) then
        self.infoCard = vgui.Create("DPanel", self.contentPanel)
        self._baseInfoCardTall = Scale(680)
        self._baseInfoCardY = Scale(-200)
        self.infoCard:SetSize(Scale(600), self._baseInfoCardTall)
        self.infoCard:SetPos(Scale(350), self._baseInfoCardY)
        self.infoCard:SetVisible(false)
        self.infoCard.Paint = function(s, w, h)

            if IsValid(self.infoDescLabel) then
                local descY = self.infoDescLabel:GetY()
                local descW = self.infoDescLabel:GetWide()
                local text = self.infoDescLabel:GetText()

                if text and text ~= "" then

                    surface.SetFont(self.infoDescLabel:GetFont() or "InvMed")
                    local _, lineH = surface.GetTextSize("M")
                    local totalW = select(1, surface.GetTextSize(text))

                    local wrapWidth = descW - Scale(20)
                    local numLines = math.max(1, math.ceil(totalW / wrapWidth))
                    local textHeight = lineH * numLines

                    local lineY = descY + textHeight + Scale(12)
                    surface.SetDrawColor(200,200,200,75)
                    surface.DrawRect(Scale(10), lineY, w - Scale(20), Scale(1))
                end
            end
        end

        self.infoItemPreview = vgui.Create("DPanel", self.infoCard)
        self.infoItemPreview:SetSize(Scale(100), Scale(100))
        self.infoItemPreview:SetPos(Scale(25), Scale(10))
        self.infoItemPreview:SetMouseInputEnabled(true)
        self.infoItemPreview:SetCursor("hand")
        self.infoItemPreview.HoverAlpha = 0
        self.infoItemPreview._wasHovered = false
        self.infoItemPreview.ClickAlpha = 0
        self.infoItemPreview._isClicked = false
        self.infoItemPreview.ClickScale = 1.0
        self.infoItemPreview.dragStartTime = 0
        self.infoItemPreview.dragStartPos = nil

        self.infoItemPreview.OnMousePressed = function(previewSelf, keyCode)
            if keyCode == MOUSE_LEFT then
                previewSelf._isClicked = true
                previewSelf.ClickStartTime = CurTime()
                previewSelf.dragStartTime = CurTime()
                previewSelf.dragStartPos = {gui.MousePos()}
            end
        end

        self.infoItemPreview.OnMouseReleased = function(previewSelf, keyCode)
            if keyCode == MOUSE_LEFT then
                previewSelf._isClicked = false
            end
        end

        self.infoItemPreview.Think = function(previewSelf)
            local hovered = previewSelf:IsHovered()
            local target = hovered and 80 or 0
            previewSelf.HoverAlpha = Lerp(FrameTime() * 15, previewSelf.HoverAlpha, target)

            if hovered and not previewSelf._wasHovered then
                surface.PlaySound(INV_HOVER_SOUND)
                previewSelf._wasHovered = true
            elseif not hovered then
                previewSelf._wasHovered = false
            end

            if previewSelf._isClicked then
                previewSelf.ClickAlpha = Lerp(FrameTime() * 25, previewSelf.ClickAlpha, 80)
            else
                previewSelf.ClickAlpha = Lerp(FrameTime() * 20, previewSelf.ClickAlpha, 0)
            end

            if IsValid(self.infoItemModel) and previewSelf._itemDef then
                local iconPressed = previewSelf._isClicked and input.IsMouseDown(MOUSE_LEFT)
                if previewSelf._lastSpawnIconClicked ~= iconPressed then
                    previewSelf._lastSpawnIconClicked = iconPressed
                    ApplySpawnIconPosition(self.infoItemModel, previewSelf._itemDef, iconPressed)
                end
            end

            if previewSelf.dragStartTime > 0 and input.IsMouseDown(MOUSE_LEFT) and previewSelf.dragStartPos then
                local isDragging = Monarch_GetDragState()
                if not isDragging then
                    local currentPos = {gui.MousePos()}
                    local distance = math.sqrt((currentPos[1] - previewSelf.dragStartPos[1])^2 + (currentPos[2] - previewSelf.dragStartPos[2])^2)
                    if distance > 10 then

                        if IsValid(self.selectedItem) then
                            local item = self.selectedItem
                            item.isDragActive = true
                            Monarch_SetDragState(true, item, previewSelf.dragStartPos)
                            Monarch_CreateDragPanel(item)
                            item:SetAlpha(0)
                        end
                        previewSelf.dragStartTime = 0
                        previewSelf.dragStartPos = nil
                    end
                end
            end
        end

        self.infoItemPreview.Paint = function(previewSelf, pw, ph)
            DrawRoundedRect(0, 0, pw, ph, 3, Color(40, 40, 40, 200))

            if previewSelf.HoverAlpha > 0 then
                DrawRoundedRect(0, 0, pw, ph, 3, Color(50, 50, 50, previewSelf.HoverAlpha))
            end

            if previewSelf.ClickAlpha and previewSelf.ClickAlpha > 1 then
                local clickColor = Color(100, 100, 100, math.floor(previewSelf.ClickAlpha))
                DrawRoundedRect(0, 0, pw, ph, 3, clickColor)
            end

            local outlineColor = previewSelf.OutlineColor or Color(100, 100, 100, 255)

            if previewSelf.IsIllegal then
                surface.SetDrawColor(COL_INV_BORDER_ILLEGAL)
            elseif previewSelf.isRestricted then
                surface.SetDrawColor(COL_INV_BORDER_RESTRICTED)
            elseif previewSelf.isConstrained then
                surface.SetDrawColor(COL_INV_BORDER_CONSTRAINED)
            else
                surface.SetDrawColor(COL_INV_BORDER)
            end
            surface.SetMaterial(Material("icons/inventory/cmb_poly.png", "smooth"))
            surface.DrawTexturedRect(0, 0, pw, ph)

            local stackAmount = tonumber(previewSelf.StackAmount) or 1
            if stackAmount > 1 then
                local stackText = tostring(stackAmount)
                draw.SimpleTextOutlined(stackText, "InvStackSmall", Scale(6), Scale(4), Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0, 0, 0, 180))
            end
        end

        self.infoItemModel = vgui.Create("DModelPanel", self.infoItemPreview)
        ConfigureInventoryModelPanel(self.infoItemModel)
        self.infoItemModel:Dock(FILL)
        self.infoItemModel:DockMargin(5, 5, 5, 5)
        self.infoItemModel:SetMouseInputEnabled(false)
        self.infoItemModel:SetKeyboardInputEnabled(false)
        self.infoNameLabelShadow = vgui.Create("DLabel", self.infoCard)
        self.infoNameLabelShadow:SetFont("InvLargeShadow")
        self.infoNameLabelShadow:SetText("")
        self.infoNameLabelShadow:SetTextColor(Color(0,0,0,250))
        self.infoNameLabelShadow:SetPos(Scale(13), Scale(13))

        self.infoNameLabel = vgui.Create("DLabel", self.infoCard)
        self.infoNameLabel:SetFont("InvLarge")
        self.infoNameLabel:SetText("")
        self.infoNameLabel:SetTextColor(Color(200,200,200))
        self.infoNameLabel:SetPos(Scale(10), Scale(8))

        self.infoDescLabel = vgui.Create("DLabel", self.infoCard)
        self.infoDescLabel:SetFont("InvMedLight")
        self.infoDescLabel:SetTextColor(Color(200,200,200))
        self.infoDescLabel:SetPos(Scale(10), Scale(72))
        self.infoDescLabel:SetSize(self.infoCard:GetWide() - Scale(130), self.infoCard:GetTall() - Scale(60))
        self.infoDescLabel:SetWrap(true)
        self.infoDescLabel:SetContentAlignment(7)

    self.footerPanel = vgui.Create("DPanel", self.infoCard)
        self.footerPanel:SetSize(self.infoCard:GetWide() - 20, 160)
        self.footerPanel:SetPos(10, self.infoCard:GetTall() - self.footerPanel:GetTall() - 10)
        self.footerPanel.Paint = function() end

    self.statsPanel = vgui.Create("DPanel", self.footerPanel)
    self.statsPanel:SetWide(math.floor(self.footerPanel:GetWide() * 0.5) - 4)
    self.statsPanel:Dock(LEFT)
    self.statsPanel:DockMargin(0,0,8,0)
    self.statsPanel:SetPaintBackground(false)

    self.statsLabel = vgui.Create("DLabel", self.statsPanel)
    self.statsLabel:SetFont("InvTitle")
    self.statsLabel:SetTextColor(Color(200,200,200))
    self.statsLabel:SetText("STATS")
    self.statsLabel:Dock(TOP)
    self.statsLabel:DockMargin(0,0,0,6)
    self.statsLabel:SizeToContents()

    self.statsText = vgui.Create("RichText", self.statsPanel)
    self.statsText:Dock(TOP)
    self.statsText:DockMargin(0,0,0,0)
    self.statsText:SetVerticalScrollbarEnabled(false)

    self.statsText:SetMouseInputEnabled(false)
    self.statsText:SetKeyboardInputEnabled(false)
    self.statsText:SetCursor("arrow")

        self.actionsPanel = vgui.Create("DPanel", self.footerPanel)
        self.actionsPanel:Dock(FILL)
        self.actionsPanel:SetPaintBackground(false)

        self.actionsLabel = vgui.Create("DLabel", self.actionsPanel)
        self.actionsLabel:SetFont("InvTitle")
        self.actionsLabel:SetTextColor(Color(200,200,200))
        self.actionsLabel:SetText(string.upper("Actions"))
        self.actionsLabel:Dock(TOP)
        self.actionsLabel:DockMargin(0,0,0,6)
        self.actionsLabel:SizeToContents()

        self.actionsButtonsList = vgui.Create("DPanel", self.actionsPanel)
        self.actionsButtonsList:Dock(FILL)
        self.actionsButtonsList.Paint = function() end

        -- Table to store dynamic action buttons
        self.actionButtons = {}

        -- Original Use button (kept for compatibility)
        self.useButton = vgui.Create("DButton", self.actionsButtonsList)
        self.useButton:SetTall(28)
        self.useButton:Dock(TOP)
        self.useButton:DockMargin(0,0,0,0)
        self.useButton:SetText("Use Item")
        self.useButton:SetFont("InvMedLight")
        self.useButton:SetTextColor(Color(255,255,255))
        self.useButton.Paint = function(s, w, h)
            local bgColor = s:IsHovered() and Color(25,25,25,200) or Color(20,20,20,125)
            surface.SetDrawColor(bgColor)
            surface.DrawRect(0,0,w,h)
        end
        self.useButton.DoClick = function(btn)
            if btn:GetDisabled() then return end
            surface.PlaySound("mrp/ui/click.wav")
            local sel = self.selectedItem
            if not (IsValid(sel) and sel.SourceSlot and sel.SourceSlot.SlotID) then return end
            local slotID = sel.SourceSlot.SlotID
            local classCapture = sel.ItemClass
            local def = sel.ItemDef or {}

            local useTime = tonumber(def.UseTime or def.UseWorkBarTime) or 0
            local useName = def.Workbar or def.UseWorkBarName or "Using..."
            local freeze = def.UseWorkBarFreeze == true
            local useSound = def.UseWorkBarSound

            if sel.SourceSlot and sel.SourceSlot.IsEquipped then
                useTime = 0
            end

            local function setPendingAndSend()
                Monarch._pendingSelect = { slot = slotID, class = classCapture, action = "use" }
                if useSound and useSound ~= "" then surface.PlaySound(useSound) end
                net.Start("Monarch_Inventory_UseItem")
                    net.WriteUInt(slotID, 8)
                net.SendToServer()

            end

            local function stillValid()
                local steamID = LocalPlayer():SteamID64()
                local inv = Monarch and Monarch.Inventory and Monarch.Inventory.Data and Monarch.Inventory.Data[steamID]
                if not inv then return false end
                local it = inv[slotID]
                if not it then return false end
                local curClass = it.class or it.id
                return (not classCapture) or (curClass == classCapture)
            end

            if self.ClearItemSelection then
                self:ClearItemSelection()
            end

            if useTime > 0 and Monarch_ShowUseBar then

                Monarch_ShowUseBar(vgui.GetWorldPanel() or nil, useTime, (useName or "Using...") .. "", function()

                    if stillValid() then
                        setPendingAndSend()
                    else
                        if self.RefreshUI then self:RefreshUI("use-cancelled") end
                    end
                end)
            else
                setPendingAndSend()
            end
        end
        self.useButton.OnCursorEntered = nil

        self.Dismantle = vgui.Create("DButton", self.actionsButtonsList)
        self.Dismantle:SetTall(28)
        self.Dismantle:Dock(TOP)
        self.Dismantle:DockMargin(0,0,0,0)
        self.Dismantle:SetText("Break Down")
        self.Dismantle:SetFont("InvMedLight")
        self.Dismantle:SetTextColor(Color(255,255,255))
        self.Dismantle.Paint = function(s, w, h)
            local bgColor = s:IsHovered() and Color(25,25,25,200) or Color(20,20,20,125)
            surface.SetDrawColor(bgColor)
            surface.DrawRect(0,0,w,h)
        end
        self.Dismantle.DoClick = function()
            local sel = self.selectedItem
            if not (IsValid(sel) and sel.SourceSlot and sel.SourceSlot.SlotID) then return end
            surface.PlaySound("mrp/ui/click.wav")
            local dismantleTime = sel.ItemDef and (sel.ItemDef.DismantleTime or sel.ItemDef.dismantletime)

            local slotIdCapture = sel.SourceSlot and sel.SourceSlot.SlotID
            local classCapture = sel.ItemClass
            local dismantleSound = sel.ItemDef and (sel.ItemDef.DismantleSound or sel.ItemDef.dismantlesound)
            local function sendDismantleIfStillValid()
                local steamID = LocalPlayer():SteamID64()
                local inv = Monarch.Inventory.Data and Monarch.Inventory.Data[steamID]
                if not inv or not slotIdCapture then return end
                local curItem = inv[slotIdCapture]
                if not curItem then return end
                local curClass = curItem.class or curItem.id
                if classCapture and curClass ~= classCapture then
                    return
                end

                if dismantleSound and dismantleSound ~= "" then 
                    surface.PlaySound(dismantleSound) 
                end
                Monarch._pendingSelect = { slot = slotIdCapture, class = classCapture, action = "dismantle" }
                net.Start("Monarch_Inventory_Dismantle")
                    net.WriteUInt(slotIdCapture, 8)
                net.SendToServer()

                net.Start("Monarch_Inventory_Request")
                net.SendToServer()
            end

            if dismantleTime and tonumber(dismantleTime) and dismantleTime > 0 then
                Monarch_ShowUseBar(self, dismantleTime, (sel.ItemDef.DismantleBar or "Dismantling") .. "...", sendDismantleIfStillValid)
            else
                sendDismantleIfStillValid()
            end

            if self.ClearItemSelection then self:ClearItemSelection() end
            if self.RefreshUI then self:RefreshUI("dismantle-click") end
        end
        self.Dismantle.OnCursorEntered = nil

        self.Dismantle:SetVisible(false)

        self.SplitStack = vgui.Create("DButton", self.actionsButtonsList)
        self.SplitStack:SetTall(28)
        self.SplitStack:Dock(TOP)
        self.SplitStack:DockMargin(0,0,0,0)
        self.SplitStack:SetText("Split Stack")
        self.SplitStack:SetFont("InvMedLight")
        self.SplitStack:SetTextColor(Color(255,255,255))
        self.SplitStack.Paint = function(s, w, h)
            local bgColor = s:IsHovered() and Color(25,25,25,200) or Color(20,20,20,125)
            surface.SetDrawColor(bgColor)
            surface.DrawRect(0,0,w,h)
        end
        self.SplitStack:SetDisabled(true)
        self.SplitStack.DoClick = function(btn)
            if btn:GetDisabled() then return end
            if not IsValid(self.selectedItem) or not self.selectedItem.ItemData then return end
            local data = self.selectedItem.ItemData
            local total = tonumber(data.amount or 1) or 1
            if total < 2 then return end
            local slotId = self.selectedItem.SourceSlot and self.selectedItem.SourceSlot.SlotID
            if not slotId then return end
            local default = math.Clamp(math.floor(total/2), 1, total-1)
            local openDialog = (Monarch and Monarch.UI and Monarch.UI.OpenAmountDialog)
                or function(opt)
                    Thrawn_Derma_StringRequest(opt.title or "Amount", opt.subtitle or "Enter amount", tostring(opt.default or 1), function(text)
                        local v = tonumber(text)
                        if not v then return end
                        if opt.onSubmit then opt.onSubmit(v) end
                    end)
                end
            openDialog({
                title = "Split Stack",
                subtitle = "Enter amount (Max: "..tostring(total-1).."):",
                min = 1,
                max = total - 1,
                default = default,
                onSubmit = function(amt)
                    amt = math.floor(tonumber(amt) or 0)
                    if amt < 1 or amt >= total then return end
                    net.Start("Monarch_Inventory_SplitStack")
                        net.WriteUInt(slotId, 8)
                        net.WriteUInt(amt, 16)
                        net.WriteBool(false) 
                    net.SendToServer()
                end
            })
        end

        local function DropSelectedStackAmount(requestedAmount, promptForAmount)
            if not IsValid(self.selectedItem) or not self.selectedItem.ItemData then return end
            local sel = self.selectedItem
            if not (sel.SourceSlot and sel.SourceSlot.SlotID) then return end

            local data = sel.SourceSlot.ItemData
            local total = tonumber(data.amount or 1) or 1
            if total < 1 then return end

            local isRestricted = data.restricted or false
            local isConstrained = data.constrained or false
            local def = data.ItemDef
            if not isRestricted and def then
                isRestricted = (def.Restricted or def.restricted) and true or false
            end
            if isRestricted or isConstrained then
                self:ShowNotification("You cannot drop this item.", Color(255, 100, 100), 2)
                return
            end

            local slotID = sel.SourceSlot.SlotID

            if promptForAmount then
                if total <= 1 then
                    DropSelectedStackAmount(1, false)
                    return
                end

                local openDialog = (Monarch and Monarch.UI and Monarch.UI.OpenAmountDialog)
                    or function(opt)
                        Thrawn_Derma_StringRequest(opt.title or "Amount", opt.subtitle or "Enter amount", tostring(opt.default or 1), function(text)
                            local v = tonumber(text)
                            if not v then return end
                            if opt.onSubmit then opt.onSubmit(v) end
                        end)
                    end

                openDialog({
                    title = "Drop Amount",
                    subtitle = "Enter amount to drop (Max: " .. tostring(total) .. "):",
                    min = 1,
                    max = total,
                    default = math.Clamp(math.floor(total / 2), 1, total),
                    onSubmit = function(amt)
                        DropSelectedStackAmount(amt, false)
                    end
                })
                return
            end

            local amount = math.floor(tonumber(requestedAmount) or 1)
            amount = math.Clamp(amount, 1, total)
            surface.PlaySound("mrp/ui/click.wav")

            if not IsValid(self) then return end
            net.Start("Monarch_Inventory_DropItem")
                net.WriteUInt(slotID, 8)
                net.WriteUInt(amount, 8)
            net.SendToServer()
        end

        self.DropStackMain = vgui.Create("DButton", self.actionsButtonsList)
        self.DropStackMain:SetTall(28)
        self.DropStackMain:Dock(TOP)
        self.DropStackMain:DockMargin(0, 0, 0, 0)
        self.DropStackMain:SetText("Drop")
        self.DropStackMain:SetFont("InvMedLight")
        self.DropStackMain:SetTextColor(Color(255,255,255))
        self.DropStackMain.Paint = function(s, w, h)
            local bgColor = s:IsHovered() and Color(25,25,25,200) or Color(20,20,20,125)
            surface.SetDrawColor(bgColor)
            surface.DrawRect(0,0,w,h)
        end
        self.DropStackMain.DoClick = function(btn)
            if btn:GetDisabled() then return end
            DropSelectedStackAmount(nil, true)
        end

        local function SetupDropSubButton(btn, text, onClick)
            btn:SetTall(22)
            btn:Dock(TOP)
            btn:DockMargin(0, 0, 0, 0)
            btn:SetText(text)
            btn:SetFont("InvStackSmall")
            btn:SetTextColor(Color(220,220,220))
            btn.Paint = function(s, w, h)
                local bgColor = s:IsHovered() and Color(24,24,24,195) or Color(18,18,18,120)
                surface.SetDrawColor(bgColor)
                surface.DrawRect(0,0,w,h)
            end
            btn.DoClick = function(s)
                if s:GetDisabled() then return end
                if onClick then onClick() end
            end
        end

        self.DropStackOne = vgui.Create("DButton", self.actionsButtonsList)
        SetupDropSubButton(self.DropStackOne, "Drop 1", function()
            DropSelectedStackAmount(1, false)
        end)

        self.DropStackHalf = vgui.Create("DButton", self.actionsButtonsList)
        SetupDropSubButton(self.DropStackHalf, "Drop 1/2", function()
            if not IsValid(self.selectedItem) or not self.selectedItem.ItemData then return end
            local total = tonumber(self.selectedItem.ItemData.amount or 1) or 1
            local half = math.Clamp(math.floor(total / 2), 1, total)
            DropSelectedStackAmount(half, false)
        end)

        self.DropStackX = vgui.Create("DButton", self.actionsButtonsList)
        SetupDropSubButton(self.DropStackX, "Drop X", function()
            DropSelectedStackAmount(nil, true)
        end)

        self.DropStackMain:SetVisible(false)
        self.DropStackOne:SetVisible(false)
        self.DropStackHalf:SetVisible(false)
        self.DropStackX:SetVisible(false)
        self.DropStackMain:SetDisabled(true)
        self.DropStackOne:SetDisabled(true)
        self.DropStackHalf:SetDisabled(true)
        self.DropStackX:SetDisabled(true)

        function self:LayoutActions()
            if not (IsValid(self.actionsPanel) and IsValid(self.footerPanel) and IsValid(self.infoCard)) then return end

            local function visibleTall(pnl)
                if not IsValid(pnl) or not pnl:IsVisible() then return 0 end
                return pnl:GetTall()
            end

            local actionsRowsTall = 0
            actionsRowsTall = actionsRowsTall + visibleTall(self.useButton)
            actionsRowsTall = actionsRowsTall + visibleTall(self.Dismantle)
            actionsRowsTall = actionsRowsTall + visibleTall(self.SplitStack)
            actionsRowsTall = actionsRowsTall + visibleTall(self.DropStackMain)
            actionsRowsTall = actionsRowsTall + visibleTall(self.DropStackOne)
            actionsRowsTall = actionsRowsTall + visibleTall(self.DropStackHalf)
            actionsRowsTall = actionsRowsTall + visibleTall(self.DropStackX)
            for _, btn in pairs(self.actionButtons or {}) do
                actionsRowsTall = actionsRowsTall + visibleTall(btn)
            end

            local actionsHeaderTall = visibleTall(self.actionsLabel)
            local actionsNeeded = actionsHeaderTall + Scale(6) + actionsRowsTall + Scale(6)

            local statsNeeded = 0
            if IsValid(self.statsLabel) then
                statsNeeded = statsNeeded + self.statsLabel:GetTall() + Scale(6)
            end
            if IsValid(self.statsText) then
                statsNeeded = statsNeeded + self.statsText:GetTall()
            end
            statsNeeded = statsNeeded + Scale(6)

            local minFooter = Scale(140)
            local maxFooter = math.max(minFooter, self.infoCard:GetTall() - Scale(220))
            local targetFooterTall = math.Clamp(math.max(actionsNeeded, statsNeeded, minFooter), minFooter, maxFooter)

            local baseInfoTall = self._baseInfoCardTall or self.infoCard:GetTall()
            local baseInfoY = self._baseInfoCardY or self.infoCard:GetY()
            local extraFooterTall = math.max(0, targetFooterTall - minFooter)
            local targetInfoTall = baseInfoTall + extraFooterTall
            self.infoCard:SetTall(targetInfoTall)
            self.infoCard:SetY(baseInfoY)

            self.footerPanel:SetTall(targetFooterTall)
            self.footerPanel:SetPos(10, self.infoCard:GetTall() - targetFooterTall - 10)

            if IsValid(self.infoNameLabel) and IsValid(self.infoNameLabelShadow) and IsValid(self.infoDescLabel) then
                local footerY = self.footerPanel:GetY()
                local nameHeight = self.infoNameLabel:GetTall()
                local padding = Scale(12)

                local nameY = footerY - Scale(180)
                self.infoNameLabel:SetPos(Scale(10), nameY)
                self.infoNameLabelShadow:SetPos(Scale(11), nameY + 2)

                local maxNameWidth = self.infoCard:GetWide() - Scale(130)
                self.infoNameLabel:SetWide(maxNameWidth)
                self.infoNameLabelShadow:SetWide(maxNameWidth)

                local descY = nameY + nameHeight + Scale(4)
                local descHeight = footerY - descY - padding
                self.infoDescLabel:SetPos(Scale(10), descY)
                self.infoDescLabel:SetSize(self.infoCard:GetWide() - Scale(130), descHeight)

                if IsValid(self.infoItemPreview) then
                    local previewW = self.infoItemPreview:GetWide()
                    local previewH = self.infoItemPreview:GetTall()
                    local titleCenterY = nameY + (nameHeight / 2)
                    local previewY = titleCenterY - (previewH / 2)
                    local previewX = self.infoCard:GetWide() - previewW - Scale(10)
                    self.infoItemPreview:SetPos(previewX, previewY)
                end
            end

            self.actionsPanel:InvalidateLayout(true)
            if IsValid(self.actionsButtonsList) then
                self.actionsButtonsList:InvalidateLayout(true)
            end
        end
    end

    function self:ShowItemInfo(itemPanel)
        if self._suppressInfoCard then return end
        if not (IsValid(itemPanel) and itemPanel.ItemDef) then return end
        Monarch = Monarch or {}
        Monarch._ActiveInvCorePanel = self
        self.selectedItem = itemPanel

        if itemPanel.SourceSlot and itemPanel.SourceSlot.SlotID then
            self.lastSelectedSlot = itemPanel.SourceSlot.SlotID
        end
        local itemDef = itemPanel.ItemDef
        local name = (itemDef.Name or itemDef.name or itemPanel.ItemClass or "Item")
        local durabilityPct = GetItemDurabilityPercent(itemPanel.ItemData, itemDef)
        if durabilityPct ~= nil then
            name = string.format("%s (%d%%)", tostring(name), durabilityPct)
        end
        local desc = (itemDef.Description or itemDef.description or itemDef.Desc or "No description available.")

        local displayName = name
        if string.len(name) > 14 then
            displayName = string.sub(name, 1, 14) .. "..."
        end

        self.infoNameLabel:SetText(string.upper(displayName))
        self.infoNameLabel:SizeToContents()
        self.infoNameLabelShadow:SetText(string.upper(displayName))
        self.infoNameLabelShadow:SizeToContents()
        self.infoDescLabel:SetText(desc)

        if IsValid(self.infoItemModel) and IsValid(self.infoItemPreview) then
            local modelPath = itemDef.Model or itemDef.model or "models/props_junk/cardboard_box004a.mdl"
            self.infoItemModel:SetModel(modelPath)
            self.infoItemPreview._itemDef = itemDef
            self.infoItemPreview._lastSpawnIconClicked = false
            self.infoItemPreview.StackAmount = 1
            if itemPanel.ItemData and itemPanel.ItemData.amount then
                self.infoItemPreview.StackAmount = tonumber(itemPanel.ItemData.amount) or 1
            end
            ApplySpawnIconPosition(self.infoItemModel, itemDef, false)

            local outlineColor = Color(100, 100, 100, 255)
            local isIllegal = itemDef and itemDef.Illegal
            local isRestricted = itemDef and (itemDef.Restricted or itemDef.restricted or itemDef.Locked)
            local isConstrained = selectedItem and selectedItem.constrained
            if isIllegal then
                outlineColor = Color(200, 90, 90, 255)
            elseif isRestricted then
                outlineColor = Color(250, 200, 100, 255)
            elseif isConstrained then
                outlineColor = Color(250, 200, 100, 255)
            end
            self.infoItemPreview.OutlineColor = outlineColor
            self.infoItemPreview.IsIllegal = isIllegal
            self.infoItemPreview.isRestricted = isRestricted
            self.infoItemPreview.isConstrained = isConstrained
        end

        local footerY = self.footerPanel:GetY()
        local nameHeight = self.infoNameLabel:GetTall()
        local padding = Scale(12)

        local nameY = footerY - Scale(180) 
        self.infoNameLabel:SetPos(Scale(10), nameY)
        self.infoNameLabelShadow:SetPos(Scale(11), nameY + 2)

        local maxNameWidth = self.infoCard:GetWide() - Scale(130)
        self.infoNameLabel:SetWide(maxNameWidth)
        self.infoNameLabelShadow:SetWide(maxNameWidth)

        local descY = nameY + nameHeight + Scale(4)
        local descHeight = footerY - descY - padding
        self.infoDescLabel:SetPos(Scale(10), descY)
        self.infoDescLabel:SetSize(self.infoCard:GetWide() - Scale(130), descHeight)

        if IsValid(self.infoItemPreview) then
            local previewW = self.infoItemPreview:GetWide()
            local previewH = self.infoItemPreview:GetTall()

            local titleCenterY = nameY + (nameHeight / 2)
            local previewY = titleCenterY - (previewH / 2)
            local previewX = self.infoCard:GetWide() - previewW - Scale(10)
            self.infoItemPreview:SetPos(previewX, previewY)
        end

        if IsValid(self.useButton) then
            local useName = itemDef.UseName or itemDef.usename or "Use Item"
            local hasEquip = (itemDef.EquipGroup ~= nil) or (itemDef.WeaponClass ~= nil)
            if hasEquip and itemPanel.ItemData then
                local equipped = itemPanel.ItemData.equipped and true or false
                if equipped then
                    useName = itemDef.UnEquipName or "Unequip"
                else
                    useName = itemDef.EquipName or "Equip"
                end
            end
            self.useButton:SetText(useName)

            local hasUseAction = (itemDef.Usable == true) or (itemDef.UseName ~= nil) or itemDef.WeaponClass ~= nil or (type(itemDef.OnUse) == "function")

            local allowedByCanUse = true
            if type(itemDef.CanUse) == "function" then
                local ok, res = pcall(itemDef.CanUse, itemDef, LocalPlayer(), itemPanel.ItemData)
                if ok then
                    allowedByCanUse = res and true or false
                else
                    allowedByCanUse = false
                end
            end
            local canUse = hasUseAction and allowedByCanUse
            self.useButton:SetDisabled(not canUse)
            self.useButton:SetAlpha(canUse and 255 or 120)
        end

        if IsValid(self.SplitStack) then
            local amt = 1
            if itemPanel.ItemData and itemPanel.ItemData.amount then
                amt = tonumber(itemPanel.ItemData.amount) or 1
            end
            local showSplit = amt > 1
            self.SplitStack:SetVisible(showSplit)
            self.SplitStack:SetDisabled(not showSplit)

            local showDropActions = amt > 1
            if IsValid(self.DropStackMain) then
                self.DropStackMain:SetVisible(true)
                self.DropStackMain:SetDisabled(false)
            end
            if IsValid(self.DropStackOne) then
                self.DropStackOne:SetVisible(showDropActions)
                self.DropStackOne:SetDisabled(not showDropActions)
            end
            if IsValid(self.DropStackHalf) then
                self.DropStackHalf:SetVisible(showDropActions)
                self.DropStackHalf:SetDisabled(not showDropActions)
            end
            if IsValid(self.DropStackX) then
                self.DropStackX:SetVisible(showDropActions)
                self.DropStackX:SetDisabled(not showDropActions)
            end
        end

        local hasDismantle = (itemDef.Dismantle ~= nil) or (itemDef.dismantle ~= nil)
        if IsValid(self.Dismantle) then
            self.Dismantle:SetVisible(hasDismantle)
        end
        if IsValid(self.statsText) then
            local stats = itemDef.Stats or itemDef.stats or "None"
            stats = ResolveSchemaStats(itemPanel, itemDef, stats)

            if type(stats) == "function" then
                local ok, result = pcall(stats, LocalPlayer(), itemPanel.ItemData)
                stats = ok and result or "Error"
            end

            local canStack = itemDef.CanStack == true or itemDef.Stackable == true
            local isIllegal = itemDef and itemDef.Illegal

            if isIllegal then
                if stats == "None" then
                    stats = "<color=100,50,50>Contraband</color>"
                else
                    stats = stats .. "\n<color=100,50,50>Contraband</color>"
                end
            end

            if canStack then
                local maxStack = tonumber(itemDef.MaxStack or itemDef.StackSize or 5) or 5
                local stackInfo = "Stack Size: " .. maxStack

                if stats == "None" then
                    stats = stackInfo
                else

                    stats = stats .. "\n" .. stackInfo
                end
            end

            self.statsText:SetText("")

            local lines = string.Explode("\n", tostring(stats))
            for _, line in ipairs(lines) do
                if line and line ~= "" then

                    local r, g, b, text = string.match(line, "<color=%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*>(.+)</color>")
                    if r and g and b and text then
                        self.statsText:InsertColorChange(tonumber(r), tonumber(g), tonumber(b), 255)
                        self.statsText:AppendText(text)
                    else

                        self.statsText:InsertColorChange(220, 220, 220, 255)
                        self.statsText:AppendText(line)
                    end
                    self.statsText:AppendText("\n")
                end
            end

            function self.statsText:PerformLayout()
                self:SetFontInternal("InvMed")
                self:SetFGColor(Color(220, 220, 220))
            end

            surface.SetFont("InvMed")
            local _, lineHeight = surface.GetTextSize("M")
            local numLines = math.max(#lines, 1)
            local totalHeight = math.max(lineHeight * (numLines + 2), Scale(60))
            self.statsText:SetTall(totalHeight)
        end
        if self.RebuildActionButtons then self:RebuildActionButtons(itemPanel) end
        if self.LayoutActions then self:LayoutActions() end
        self.infoCard:SetVisible(true)
        self.infoCard:MoveToFront()
    end

    -- Rebuild action buttons based on selected item
    function self:RebuildActionButtons(itemPanel)
        if not IsValid(itemPanel) or not itemPanel.ItemDef then return end
        
        local itemDef = itemPanel.ItemDef
        local itemData = itemPanel.ItemData
        local slotID = itemPanel.SourceSlot and itemPanel.SourceSlot.SlotID
        
        -- Clear existing action buttons
        for _, btn in pairs(self.actionButtons or {}) do
            if IsValid(btn) then
                btn:Remove()
            end
        end
        self.actionButtons = {}
        
        -- Hide default use button if we have custom actions
        local hasActions = itemDef.Actions and istable(itemDef.Actions) and table.Count(itemDef.Actions) > 0
        
        if hasActions then
            self.useButton:SetVisible(false)
            
            -- Create buttons for each action
            for actionID, actionData in pairs(itemDef.Actions) do
                if not actionData.name then continue end
                
                local btnParent = IsValid(self.actionsButtonsList) and self.actionsButtonsList or self.actionsPanel
                local btn = vgui.Create("DButton", btnParent)
                btn:SetTall(28)
                btn:Dock(TOP)
                btn:DockMargin(0, 0, 0, 0)
                btn:SetText(actionData.name)
                btn:SetFont("InvMedLight")
                btn:SetTextColor(Color(255,255,255))
                btn.Paint = function(s, w, h)
                    local bgColor = s:IsHovered() and Color(25,25,25,200) or Color(20,20,20,125)
                    surface.SetDrawColor(bgColor)
                    surface.DrawRect(0,0,w,h)
                end
                
                -- Check if action can run
                local canRun = true
                if type(actionData.CanRun) == "function" then
                    local ok, result = pcall(actionData.CanRun, itemData, LocalPlayer())
                    if ok then
                        canRun = result and true or false
                    else
                        canRun = false
                    end
                end
                
                btn:SetDisabled(not canRun)
                btn:SetAlpha(canRun and 255 or 120)
                
                -- Button click handler
                btn.DoClick = function(b)
                    if b:GetDisabled() then return end
                    surface.PlaySound("mrp/ui/click.wav")
                    
                    if not slotID then return end
                    
                    -- Send action to server
                    net.Start("Monarch_Inventory_ExecuteAction")
                        net.WriteUInt(slotID, 8)
                        net.WriteString(actionID)
                    net.SendToServer()
                end
                
                table.insert(self.actionButtons, btn)
            end
        else
            -- Show default use button
            self.useButton:SetVisible(true)
        end
    end

    function self:ClearItemSelection()
        self.selectedItem = nil
        self.lastSelectedSlot = nil
        if self.CloseItemContextMenu then
            self:CloseItemContextMenu()
        end
        if IsValid(self.infoCard) then
            self.infoCard:SetVisible(false)
        end
        if self.HideItemHoverTooltip then
            self:HideItemHoverTooltip()
        end
        if IsValid(self.SplitStack) then
            self.SplitStack:SetVisible(false)
            self.SplitStack:SetDisabled(true)
        end
        if IsValid(self.DropStackMain) then
            self.DropStackMain:SetVisible(false)
            self.DropStackMain:SetDisabled(true)
        end
        if IsValid(self.DropStackOne) then
            self.DropStackOne:SetVisible(false)
            self.DropStackOne:SetDisabled(true)
        end
        if IsValid(self.DropStackHalf) then
            self.DropStackHalf:SetVisible(false)
            self.DropStackHalf:SetDisabled(true)
        end
        if IsValid(self.DropStackX) then
            self.DropStackX:SetVisible(false)
            self.DropStackX:SetDisabled(true)
        end
        if IsValid(self.ListForSale) then
            self.ListForSale:SetVisible(false)
        end
        if IsValid(self.useButton) then
            self.useButton:SetDisabled(true)
            self.useButton:SetAlpha(120)
            self.useButton:SetVisible(true)
        end
        
        -- Clear action buttons
        for _, btn in pairs(self.actionButtons or {}) do
            if IsValid(btn) then
                btn:Remove()
            end
        end
        self.actionButtons = {}
    end

    function self:HideInfoCard()
        if self.CloseItemContextMenu then
            self:CloseItemContextMenu()
        end
        if IsValid(self.infoCard) then
            self.infoCard:SetVisible(false)
        end
        if self.HideItemHoverTooltip then
            self:HideItemHoverTooltip()
        end
    end

    function self:CloseItemContextMenu()
        if IsValid(self.itemContextMenu) then
            self.itemContextMenu:Remove()
        end
        self.itemContextMenu = nil
    end

    function self:OnRemove()
        if self.CloseItemContextMenu then
            self:CloseItemContextMenu()
        end
    end

    local item = vgui.Create("DPanel", slot)
    item:SetSize(slot:GetWide() - 4, slot:GetTall() - 4)
    item:SetPos(2, 2)
    item:SetMouseInputEnabled(true)
    item:SetCursor("hand")

    item.ItemData = itemData
    item.InvID = itemData.realKey or itemData.InvID
    item.InvPanel = self
    item.ItemClass = itemClass
    item.ItemDef = itemDef
    item.SourceSlot = slot
    item.dragStartTime = 0
    item.dragStartPos = nil
    item.isDragActive = false

    slot.HasItem = true
    slot.ItemData = itemData
    slot.ItemPanel = item
    slot.InvID = item.InvID

    item.HoverAlpha = 0
    item.HoverScale = 1
    item._wasHovered = false
    item.Paint = function(itemSelf, w, h)
    end

    item.PaintOver = function(itemSelf, w, h)
        local scale = math.Clamp(itemSelf.HoverScale or 1, 0.9, 1.15)
        local sw, sh = math.floor(w * scale), math.floor(h * scale)
        local sx, sy = math.floor((w - sw) * 0.5), math.floor((h - sh) * 0.5)

        local amt = tonumber((itemSelf.ItemData and itemSelf.ItemData.amount) or 1) or 1
        if amt > 1 then
            local txt = tostring(amt)
            draw.SimpleTextOutlined(txt, "InvStackSmall", sx + 6, sy + 4, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0,0,0,180))
        end

        local durabilityPct = GetItemDurabilityPercent(itemSelf.ItemData, itemSelf.ItemDef)
        if durabilityPct ~= nil then
            local barW = math.max(3, Scale(4))
            local barX = 2
            local barY = 2
            local barH = math.max(8, h - 4)
            local fillH = math.floor(barH * (durabilityPct / 100))
            local fillY = barY + (barH - fillH)

            surface.SetDrawColor(20, 20, 20, 180)
            surface.DrawRect(barX, barY, barW, barH)

            if fillH > 0 then
                local dCol = GetDurabilityColor(durabilityPct)
                surface.SetDrawColor(dCol)
                surface.DrawRect(barX, fillY, barW, fillH)
            end
        end
    end

    local function DropItemFromContext(itemPanel, requestedAmount, promptForAmount)
        if not IsValid(itemPanel) or not IsValid(itemPanel.InvPanel) then return end
        if not (itemPanel.SourceSlot and itemPanel.SourceSlot.SlotID) then return end

        local itemData = itemPanel.SourceSlot.ItemData
        local totalAmount = tonumber(itemData and itemData.amount or 1) or 1
        local isRestricted = false
        local isConstrained = false

        if itemData then
            isRestricted = itemData.restricted or false
            isConstrained = itemData.constrained or false
            local def = itemData.ItemDef
            if not isRestricted and def then
                isRestricted = (def.Restricted or def.restricted) and true or false
            end
        end

        if isRestricted or isConstrained then
            itemPanel.InvPanel:ShowNotification("You cannot drop this item.", Color(255, 100, 100), 2)
            return
        end

        if promptForAmount then
            local openDialog = (Monarch and Monarch.UI and Monarch.UI.OpenAmountDialog)
                or function(opt)
                    Thrawn_Derma_StringRequest(opt.title or "Amount", opt.subtitle or "Enter amount", tostring(opt.default or 1), function(text)
                        local v = tonumber(text)
                        if not v then return end
                        if opt.onSubmit then opt.onSubmit(v) end
                    end)
                end

            openDialog({
                title = "Drop Amount",
                subtitle = "Enter amount to drop (Max: " .. tostring(totalAmount) .. "):",
                min = 1,
                max = totalAmount,
                default = math.Clamp(math.floor(totalAmount / 2), 1, totalAmount),
                onSubmit = function(amt)
                    DropItemFromContext(itemPanel, amt, false)
                end
            })
            return
        end

        local amount = math.floor(tonumber(requestedAmount) or 1)
        amount = math.Clamp(amount, 1, totalAmount)

        surface.PlaySound("mrp/ui/click.wav")
        local slotID = itemPanel.SourceSlot.SlotID
        if not IsValid(itemPanel) or not itemPanel.SourceSlot or not slotID then return end
        net.Start("Monarch_Inventory_DropItem")
            net.WriteUInt(slotID, 8)
            net.WriteUInt(amount, 8)
        net.SendToServer()
    end

    local function UseItemFromContext(itemPanel)
        if not IsValid(itemPanel) or not (itemPanel.SourceSlot and itemPanel.SourceSlot.SlotID) then return end

        local def = itemPanel.ItemDef or {}
        local slotID = itemPanel.SourceSlot.SlotID
        local classCapture = itemPanel.ItemClass

        local hasUseAction = (def.Usable == true) or (def.UseName ~= nil) or def.WeaponClass ~= nil or (type(def.OnUse) == "function")
        if not hasUseAction then return end

        if type(def.CanUse) == "function" then
            local ok, res = pcall(def.CanUse, def, LocalPlayer(), itemPanel.ItemData)
            if (not ok) or (not res) then return end
        end

        local useTime = tonumber(def.UseTime or def.UseWorkBarTime) or 0
        local useName = def.Workbar or def.UseWorkBarName or "Using..."
        local useSound = def.UseWorkBarSound
        if itemPanel.SourceSlot and itemPanel.SourceSlot.IsEquipped then
            useTime = 0
        end

        local function stillValid()
            local steamID = LocalPlayer():SteamID64()
            local inv = Monarch and Monarch.Inventory and Monarch.Inventory.Data and Monarch.Inventory.Data[steamID]
            if not inv then return false end
            local it = inv[slotID]
            if not it then return false end
            local curClass = it.class or it.id
            return (not classCapture) or (curClass == classCapture)
        end

        local function setPendingAndSend()
            Monarch._pendingSelect = { slot = slotID, class = classCapture, action = "use" }
            if useSound and useSound ~= "" then surface.PlaySound(useSound) end
            net.Start("Monarch_Inventory_UseItem")
                net.WriteUInt(slotID, 8)
            net.SendToServer()
        end

        surface.PlaySound("mrp/ui/click.wav")
        if useTime > 0 and Monarch_ShowUseBar then
            Monarch_ShowUseBar(vgui.GetWorldPanel() or nil, useTime, (useName or "Using...") .. "", function()
                if stillValid() then
                    setPendingAndSend()
                end
            end)
        else
            setPendingAndSend()
        end
    end

    local function StyleContextOption(opt)
        if not IsValid(opt) then return end
        local optionTall = math.max(Scale(48), 48)
        opt:SetTextInset(Scale(10), 0)
        opt:SetTall(optionTall)
        opt._monarchContextTall = optionTall
        opt._monarchContextStyled = true

        -- DMenuOption can reapply its own height during layout; force ours.
        opt.PerformLayout = function(btn)
            if btn:GetTall() ~= btn._monarchContextTall then
                btn:SetTall(btn._monarchContextTall)
            end
        end
        
        opt:SetFont("InvMed")
        opt:SetTextColor(Color(230, 230, 230))
        opt.Paint = function(btn, w, h)
            local enabled = true
            if isfunction(btn.GetDisabled) then
                enabled = not btn:GetDisabled()
            elseif isfunction(btn.IsEnabled) then
                enabled = btn:IsEnabled()
            end
            local bg = btn:IsHovered() and Color(58, 58, 58, 230) or Color(44, 44, 44, 220)
            if not enabled then
                bg = Color(36, 36, 36, 215)
            end
            surface.SetDrawColor(bg)
            surface.DrawRect(0, 0, w, h)
            if btn:IsHovered() then
                surface.SetDrawColor(140, 140, 140, 22)
                surface.DrawRect(0, 0, w, h)
            end
        end
    end

    local function StyleContextSubOption(opt)
        if not IsValid(opt) then return end
        local optionTall = math.max(Scale(28), 28)
        opt:SetTextInset(Scale(24), 0)
        opt:SetTall(optionTall)
        opt._monarchContextTall = optionTall
        opt._monarchContextStyled = true
        opt.PerformLayout = function(btn)
            if btn:GetTall() ~= btn._monarchContextTall then
                btn:SetTall(btn._monarchContextTall)
            end
        end

        opt:SetFont("InvStackSmall")
        opt:SetTextColor(Color(210, 210, 210))
        opt.Paint = function(btn, w, h)
            local enabled = true
            if isfunction(btn.GetDisabled) then
                enabled = not btn:GetDisabled()
            elseif isfunction(btn.IsEnabled) then
                enabled = btn:IsEnabled()
            end

            local bg = btn:IsHovered() and Color(54, 54, 54, 220) or Color(40, 40, 40, 205)
            if not enabled then
                bg = Color(34, 34, 34, 200)
            end
            surface.SetDrawColor(bg)
            surface.DrawRect(0, 0, w, h)
        end
    end

    local function OpenItemContextMenu(itemPanel)
        if not IsValid(itemPanel) then return end
        if not IsValid(parentInv) then return end

        if parentInv.CloseItemContextMenu then
            parentInv:CloseItemContextMenu()
        end

        local menu = DermaMenu()
        if not IsValid(menu) then return end
        parentInv.itemContextMenu = menu

        menu:SetMinimumWidth(math.max(Scale(270), 270))
        menu.Paint = function(_, w, h)
            surface.SetDrawColor(44, 44, 44, 230)
            surface.DrawRect(0, 0, w, h)
        end

        local def = itemPanel.ItemDef or {}
        local hasEquip = (def.EquipGroup ~= nil) or (def.WeaponClass ~= nil)
        local hasUseAction = (def.Usable == true) or (def.UseName ~= nil) or def.WeaponClass ~= nil or (type(def.OnUse) == "function")
        local canUse = true
        if type(def.CanUse) == "function" then
            local ok, res = pcall(def.CanUse, def, LocalPlayer(), itemPanel.ItemData)
            canUse = ok and (res and true or false) or false
        end

        if hasEquip then
            local isEquipped = itemPanel.ItemData and itemPanel.ItemData.equipped and true or false
            local equipLabel = isEquipped and ("UNEQUIP") or ("EQUIP")
            equipLabel = string.upper(tostring(equipLabel or "EQUIP"))
            local equipOpt = menu:AddOption(equipLabel, function()
                UseItemFromContext(itemPanel)
            end)
            StyleContextOption(equipOpt)

            if IsValid(equipOpt) and not canUse then
                equipOpt:SetEnabled(false)
                equipOpt:SetTextColor(Color(140, 140, 140))
            end
        elseif hasUseAction then
            local useLabel = def.UseName or def.usename or "USE"
            local useOpt = menu:AddOption(tostring(useLabel), function()
                UseItemFromContext(itemPanel)
            end)
            StyleContextOption(useOpt)

            if IsValid(useOpt) and not canUse then
                useOpt:SetEnabled(false)
                useOpt:SetTextColor(Color(140, 140, 140))
            end
        end

        local totalAmount = tonumber(itemPanel.ItemData and itemPanel.ItemData.amount or 1) or 1
        local isStacked = totalAmount > 1

        local dropOpt = menu:AddOption(string.upper("DROP"), function()
            if isStacked then
                DropItemFromContext(itemPanel, nil, true)
            else
                DropItemFromContext(itemPanel, 1, false)
            end
        end)
        StyleContextOption(dropOpt)

        if isStacked then
            local dropOneOpt = menu:AddOption("DROP 1", function()
                DropItemFromContext(itemPanel, 1, false)
            end)
            StyleContextSubOption(dropOneOpt)

            local dropHalfOpt = menu:AddOption("DROP 1/2", function()
                local half = math.Clamp(math.floor(totalAmount / 2), 1, totalAmount)
                DropItemFromContext(itemPanel, half, false)
            end)
            StyleContextSubOption(dropHalfOpt)

            local dropXOpt = menu:AddOption("DROP X", function()
                DropItemFromContext(itemPanel, nil, true)
            end)
            StyleContextSubOption(dropXOpt)
        end

        menu:Open()

        timer.Simple(0, function()
            if not IsValid(menu) then return end
            local canvas = menu.GetCanvas and menu:GetCanvas() or nil
            if not IsValid(canvas) then return end
            for _, child in ipairs(canvas:GetChildren() or {}) do
                if IsValid(child) and child._monarchContextStyled and child._monarchContextTall then
                    child:SetTall(child._monarchContextTall)
                end
            end
            menu:InvalidateLayout(true)
        end)
    end

    function self:OpenItemContextMenuForItem(itemPanel)
        OpenItemContextMenu(itemPanel)
    end

    item.OnMousePressed = function(itemPanel, keyCode)
        if not IsValid(parentInv) then return end
        if keyCode == MOUSE_LEFT then
            parentInv:ShowItemInfo(itemPanel)
            itemPanel.dragStartTime = CurTime()
            itemPanel.dragStartPos = {gui.MousePos()}
        elseif keyCode == MOUSE_RIGHT then
            OpenItemContextMenu(itemPanel)
        end
    end

    item.OnMouseReleased = function(self, keyCode)
        if keyCode == MOUSE_LEFT then
            self.dragStartTime = 0
            self.dragStartPos = nil
        end
    end

    local model = vgui.Create("DModelPanel", item)
    ConfigureInventoryModelPanel(model)
    local baseModelW = item:GetWide() - 10
    local baseModelH = item:GetTall() - 25
    model:SetSize(baseModelW, baseModelH)
    model:SetPos(5, 5)
    model:SetMouseInputEnabled(false)
    model:SetModel(itemModel)
    model:SetKeyboardInputEnabled(false)
    ApplySpawnIconPosition(model, itemDef, false)

    item.Think = function(self)

        local hovered = self:IsHovered()
        self.HoverAlpha = hovered and 100 or 0

        if IsValid(self.InvPanel) and self.InvPanel.ShowItemHoverTooltip then
            local isDragging = Monarch_GetDragState()
            if hovered and not isDragging and not self.isDragActive then
                self.InvPanel:ShowItemHoverTooltip(self)
            else
                self.InvPanel:HideItemHoverTooltip(self)
            end
        end

        local isClicked = input.IsMouseDown(MOUSE_LEFT) and hovered
        local targetClickScale = isClicked and 0.85 or 1.0  
        self.ClickScale = self.ClickScale or 1.0
        self.ClickScale = targetClickScale

        local targetScale = hovered and 1.08 or 1.0
        self.HoverScale = targetScale

        local combinedScale = self.HoverScale * self.ClickScale

        local w, h = self:GetSize()
        local sw, sh = math.floor(baseModelW * combinedScale), math.floor(baseModelH * combinedScale)
        local mx = math.floor((w - sw) * 0.5)
        local my = math.floor((h - sh) * 0.5)
        if IsValid(model) then
            model:SetSize(sw, sh)
            model:SetPos(mx, my)

            local iconPressed = isClicked and input.IsMouseDown(MOUSE_LEFT)
            if self._lastSpawnIconClicked ~= iconPressed then
                self._lastSpawnIconClicked = iconPressed
                ApplySpawnIconPosition(model, itemDef, iconPressed)
            end
        end
        if hovered and not self._wasHovered then
            surface.PlaySound(INV_HOVER_SOUND)
            self._wasHovered = true
        elseif not hovered then
            self._wasHovered = false
        end

        if self.dragStartTime > 0 and input.IsMouseDown(MOUSE_LEFT) and self.dragStartPos then
            local isDragging, draggedItem = Monarch_GetDragState()
            if not isDragging and not self.isDragActive and CurTime() - self.dragStartTime > 0.15 then
                local currentPos = {gui.MousePos()}
                local distance = math.sqrt((currentPos[1] - self.dragStartPos[1])^2 + (currentPos[2] - self.dragStartPos[2])^2)
                if distance > 10 then
                    self.isDragActive = true
                    Monarch_SetDragState(true, self, self.dragStartPos)
                    Monarch_CreateDragPanel(self)
                    self:SetAlpha(0) 
                end
            end
        end

        local isDragging, draggedItem = Monarch_GetDragState()
        if not isDragging and not input.IsMouseDown(MOUSE_LEFT) and self:GetAlpha() < 255 then
            self:SetAlpha(255)
        end

        if self.isDragActive and not input.IsMouseDown(MOUSE_LEFT) then

            local mouseX, mouseY = gui.MousePos()
            local foundSlot = nil
            for _, slot in ipairs(self.InvPanel.inventorySlots or {}) do
                if IsValid(slot) then
                    local slotX, slotY = slot:LocalToScreen(0, 0)
                    local slotW, slotH = slot:GetSize()
                    if mouseX >= slotX and mouseX <= slotX + slotW and mouseY >= slotY and mouseY <= slotY + slotH then
                        foundSlot = slot
                        break
                    end
                end
            end

            if not foundSlot then
                local eq = self.InvPanel.equipSlots or {}
                for _, slot in pairs(eq) do
                    if IsValid(slot) then
                        local sX, sY = slot:LocalToScreen(0, 0)
                        local sW, sH = slot:GetSize()
                        if mouseX >= sX and mouseX <= sX + sW and mouseY >= sY and mouseY <= sY + sH then
                            foundSlot = slot
                            break
                        end
                    end
                end
            end

            if foundSlot then
                if self.PerformDrop then
                    self:PerformDrop(foundSlot)
                end
            else

                local invP = self.InvPanel
                local lootP = IsValid(invP) and invP._lootPanel
                if IsValid(lootP) then
                    local lpX, lpY = lootP:LocalToScreen(0, 0)
                    local lpW, lpH = lootP:GetSize()
                    if mouseX >= lpX and mouseX <= lpX + lpW and mouseY >= lpY and mouseY <= lpY + lpH then
                        local sourceKey = self.SourceSlot.SlotID
                        if sourceKey then
                            if invP._lootReadOnly == true or invP._lootCanStore == false then

                                self:SetAlpha(255)
                            else

                                if IsValid(invP._lootEnt) then
                                    local sourceKey = self.SourceSlot.SlotID
                                    local targetLootSlot = 0
                                    local lootGrid = invP._lootGrid
                                    if IsValid(lootGrid) then
                                        for _, child in ipairs(lootGrid:GetChildren()) do
                                            if IsValid(child) and child.LootSlotID then
                                                local sx, sy = child:LocalToScreen(0, 0)
                                                local sw, sh = child:GetSize()
                                                if mouseX >= sx and mouseX <= sx + sw and mouseY >= sy and mouseY <= sy + sh then
                                                    targetLootSlot = math.max(0, math.floor(tonumber(child.LootSlotID) or 0))
                                                    break
                                                end
                                            end
                                        end
                                    end

                                    net.Start("Monarch_Loot_Put")
                                        net.WriteEntity(invP._lootEnt)
                                        net.WriteUInt(sourceKey, 8)
                                        net.WriteUInt(targetLootSlot, 12)
                                    net.SendToServer()

                                end
                            end
                        end
                    else

                        if self.SourceSlot and self.SourceSlot.SlotID then
                            local itemData = self.SourceSlot.ItemData
                            local isRestricted = false
                            local isConstrained = false

                            if itemData then
                                isRestricted = itemData.restricted or false
                                isConstrained = itemData.constrained or false
                                local def = itemData.ItemDef
                                if not isRestricted and def then
                                    isRestricted = (def.Restricted or def.restricted) and true or false
                                end
                            end

                            if isRestricted or isConstrained then
                                self.InvPanel:ShowNotification("You cannot drop this item.", Color(255, 100, 100), 2)
                                self:SetAlpha(255)
                            else
                                net.Start("Monarch_Inventory_DropItem")
                                    net.WriteUInt(self.SourceSlot.SlotID, 8)
                                net.SendToServer()
                                self:SetAlpha(255)
                            end
                        end
                    end
                else

                    if self.SourceSlot and self.SourceSlot.SlotID then
                        local itemData = self.SourceSlot.ItemData
                        local isRestricted = false
                        local isConstrained = false

                        if itemData then
                            isRestricted = itemData.restricted or false
                            isConstrained = itemData.constrained or false
                            local def = itemData.ItemDef
                            if not isRestricted and def then
                                isRestricted = (def.Restricted or def.restricted) and true or false
                            end
                        end

                        if isRestricted or isConstrained then
                            self.InvPanel:ShowNotification("You cannot drop this item.", Color(255, 100, 100), 2)
                            self:SetAlpha(255)
                        else
                            net.Start("Monarch_Inventory_DropItem")
                                net.WriteUInt(self.SourceSlot.SlotID, 8)
                            net.SendToServer()
                            self:SetAlpha(255)
                        end
                    end
                end
            end

            Monarch_CleanupDrag()
            self.isDragActive = false
            self.dragStartTime = 0
            self.dragStartPos = nil
        end
    end

    function item:PerformDrop(targetSlot)
        local inv = Monarch.Inventory.Data[LocalPlayer():SteamID64()]
        if not inv then return end
        if not IsValid(targetSlot) then return end
        if not IsValid(self.SourceSlot) then return end

        local sourceKey = self.SourceSlot.SlotID
        local targetKey = targetSlot.SlotID
        if not sourceKey or not targetKey then return end

        if sourceKey == targetKey then

            self:SetAlpha(255)
            return
        end

        inv[sourceKey], inv[targetKey] = inv[targetKey], inv[sourceKey]

        surface.PlaySound("willardnetworks/inventory/inv_move1.wav")

        timer.Simple(0, function()
            if IsValid(self.InvPanel) then
                self.InvPanel:SetupItems(true)

                local targetSlot = self.InvPanel.inventorySlots and self.InvPanel.inventorySlots[targetKey]
                if IsValid(targetSlot) and IsValid(targetSlot.ItemPanel) then
                    self.InvPanel:ShowItemInfo(targetSlot.ItemPanel)
                end
            end
        end)

            net.Start("Monarch_Inventory_MoveItem")
                net.WriteUInt(sourceKey, 8)
                net.WriteUInt(targetKey, 8)
            net.SendToServer()
        end

        if itemClass then
            self.items[itemClass] = item
        end
        if item.InvID then
            self.itemsPanels[item.InvID] = item
        end

        return item
    end

end

