return function(PANEL)
    if not CLIENT then return end

    local Scale = (Monarch and Monarch.UI and Monarch.UI.Scale) or function(v) return v end
    local INV_HOVER_SOUND = "ui/hls_ui_scroll_click.wav"
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

    local function ConfigureInventoryModelPanel(panel)
        if not IsValid(panel) then return end
        panel.LayoutEntity = function() end
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

function PANEL:BuildEquipSlots()
    self.equipSlots = self.equipSlots or {}

    local EQUIP_ICONS = {
        head  = Material("icons/icon_headgear.png", "smooth"),
        face  = Material("icons/icon_head.png", "smooth"),
        torso = Material("icons/icon_torso.png", "smooth"),
        hands = Material("icons/icon_hands.png", "smooth"),
        legs  = Material("icons/icon_leggings.png", "smooth"),
        shoes = Material("icons/icon_feet.png", "smooth"),
        primary = Material("mrp/icons/rifle.png", "smooth"),
        secondary = Material("mrp/icons/pistol.png", "smooth"),
        utility = Material("mrp/icons/knife.png", "smooth"),
        tool = Material("mrp/icons/shield.png", "smooth"),
    }

    local function IsFreeEquipCandidate(def)
        if not istable(def) then return false end
        if Monarch and Monarch.NormalizeEquipGroup and Monarch.NormalizeEquipGroup(def.EquipGroup) then
            return false
        end

        -- Extra free slots are for explicit equip-type items only, not generic usable items.
        if def.EquipName or def.UnEquipName then return true end
        if isstring(def.UseName) and string.lower(def.UseName) == "equip" then return true end
        if def.WeaponClass then return true end

        return false
    end

    function self:CreateEquipItemCard(slotPanel, itemData, def, sourceSlotId)
        if not (IsValid(slotPanel) and istable(itemData)) then return end
        if IsValid(slotPanel.ItemPanel) then slotPanel.ItemPanel:Remove() slotPanel.ItemPanel = nil end
        local item = vgui.Create("DPanel", slotPanel)
        item:SetSize(slotPanel:GetWide() - 4, slotPanel:GetTall() - 4)
        item:SetPos(2, 2)
        item:SetMouseInputEnabled(true)
        item:SetCursor("hand")

        item.ItemData = itemData
        item.ItemDef = def
        item.ItemClass = itemData.class or itemData.id
        if sourceSlotId then item.SourceSlot = { SlotID = sourceSlotId, IsEquipped = true } end
        item.InvPanel = self
        item._wasHovered = false
        item.ClickAlpha = 0
        item._isClicked = false
        item._lastSpawnIconClicked = false
        item.ClickScale = 1.0

        slotPanel.HasItem = true
        slotPanel.ItemData = itemData
        slotPanel.ItemPanel = item
        slotPanel.ClickAlpha = 0

        item.Paint = function(s, w, h)
        end

        item.PaintOver = function(s, w, h)
            local durabilityPct = GetItemDurabilityPercent(s.ItemData, s.ItemDef)
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

        local mdl = vgui.Create("DModelPanel", item)
        ConfigureInventoryModelPanel(mdl)
        local modelPad = math.max(3, math.floor(math.min(item:GetWide(), item:GetTall()) * 0.08))
        local baseModelSize = math.max(8, math.min(item:GetWide(), item:GetTall()) - (modelPad * 2))
        local baseModelW = baseModelSize
        local baseModelH = baseModelSize
        mdl:SetSize(baseModelW, baseModelH)
        mdl:SetPos(
            math.floor((item:GetWide() - baseModelW) * 0.5),
            math.floor((item:GetTall() - baseModelH) * 0.5)
        )
        mdl:SetMouseInputEnabled(false)
        local modelPath = (def and (def.Model or def.model)) or "models/props_junk/cardboard_box004a.mdl"
        mdl:SetModel(modelPath)
        mdl:SetKeyboardInputEnabled(false)
        ApplySpawnIconPosition(mdl, def, false)

        item.dragStartTime = 0
        item.dragStartPos = nil
        item.isDragActive = false

        item.OnMousePressed = function(panel, mc)
            if mc == MOUSE_LEFT then
                if self and self.ShowItemInfo then self:ShowItemInfo(panel) end
                panel._isClicked = true
                panel.ClickStartTime = CurTime()
                panel.dragStartTime = CurTime()
                panel.dragStartPos = {gui.MousePos()}
            elseif mc == MOUSE_RIGHT then
                if self and self.OpenItemContextMenuForItem then
                    self:OpenItemContextMenuForItem(panel)
                end
            end
        end

        item.OnMouseReleased = function(panel, mc)
            if mc ~= MOUSE_LEFT then return end
            panel._isClicked = false
            if panel.isDragActive then

            else

                panel.dragStartTime = 0
                panel.dragStartPos = nil
            end
        end

        item.Think = function(panel)

            local hovered = panel:IsHovered()

            if IsValid(panel.InvPanel) and panel.InvPanel.ShowItemHoverTooltip then
                local isDragging = Monarch_GetDragState()
                if hovered and not isDragging and not panel.isDragActive then
                    panel.InvPanel:ShowItemHoverTooltip(panel)
                else
                    panel.InvPanel:HideItemHoverTooltip(panel)
                end
            end

            if hovered and not panel._wasHovered then
                surface.PlaySound(INV_HOVER_SOUND)
                panel._wasHovered = true
            elseif not hovered then
                panel._wasHovered = false
            end

            if panel._isClicked then
                panel.ClickAlpha = 80
                local isClicked = input.IsMouseDown(MOUSE_LEFT) and hovered
                local targetClickScale = isClicked and 0.85 or 1.0
                panel.ClickScale = targetClickScale
            else
                panel.ClickAlpha = 0
                panel.ClickScale = 1.0
            end

            local iconPressed = panel._isClicked and input.IsMouseDown(MOUSE_LEFT) and hovered
            if panel._lastSpawnIconClicked ~= iconPressed then
                panel._lastSpawnIconClicked = iconPressed
                ApplySpawnIconPosition(mdl, panel.ItemDef, iconPressed)
            end

            if IsValid(panel.SourceSlot) then
                panel.SourceSlot.ClickAlpha = panel.ClickAlpha or 0
            end

            local combinedScale = panel.ClickScale
            local sw, sh = math.floor(baseModelW * combinedScale), math.floor(baseModelH * combinedScale)
            local mx, my = math.floor((item:GetWide() - sw) * 0.5), math.floor((item:GetTall() - sh) * 0.5)
            if IsValid(mdl) then
                mdl:SetSize(sw, sh)
                mdl:SetPos(mx, my)
            end

            if panel.dragStartTime > 0 and input.IsMouseDown(MOUSE_LEFT) and panel.dragStartPos then
                local isDragging = select(1, Monarch_GetDragState())
                if not isDragging and not panel.isDragActive then
                    local cur = {gui.MousePos()}
                    local dist = math.sqrt((cur[1]-panel.dragStartPos[1])^2 + (cur[2]-panel.dragStartPos[2])^2)
                    if dist > 10 then
                        panel.isDragActive = true
                        Monarch_SetDragState(true, panel, panel.dragStartPos)
                        Monarch_CreateDragPanel(panel)
                        panel:SetAlpha(0)
                    end
                end
            end

            local isDragging = select(1, Monarch_GetDragState())
            if not isDragging and not input.IsMouseDown(MOUSE_LEFT) and panel:GetAlpha() < 255 then
                panel:SetAlpha(255)
            end

            if panel.isDragActive and not input.IsMouseDown(MOUSE_LEFT) then
                local mouseX, mouseY = gui.MousePos()
                local invP = panel.InvPanel
                local foundSlot = nil
                if IsValid(invP) then
                    for _, slot in ipairs(invP.inventorySlots or {}) do
                        if IsValid(slot) then
                            local sx, sy = slot:LocalToScreen(0,0)
                            local sw, sh = slot:GetSize()
                            if mouseX >= sx and mouseX <= sx + sw and mouseY >= sy and mouseY <= sy + sh then
                                foundSlot = slot
                                break
                            end
                        end
                    end
                end
                if foundSlot and foundSlot.SlotID and panel.SourceSlot and panel.SourceSlot.SlotID then
                    local sourceSlotID = tonumber(panel.SourceSlot.SlotID)
                    if sourceSlotID then
                        if foundSlot.HasItem then
                            panel:SetAlpha(255)
                            Monarch_CleanupDrag()
                            Monarch_SetDragState(false, nil, nil)
                            panel.isDragActive = false
                            panel.dragStartTime = 0
                            panel.dragStartPos = nil
                            return
                        end

                        surface.PlaySound("mrp/ui/click.wav")
                        net.Start("Monarch_Inventory_MoveItem")
                            net.WriteUInt(sourceSlotID, 8)
                            net.WriteUInt(foundSlot.SlotID, 8)
                        net.SendToServer()

                        timer.Simple(0, function()
                            if not IsValid(invP) then return end
                            net.Start("Monarch_Inventory_Request")
                            net.SendToServer()
                        end)
                    end
                end
                panel:SetAlpha(255)
                Monarch_CleanupDrag()
                Monarch_SetDragState(false, nil, nil)
                panel.isDragActive = false
                panel.dragStartTime = 0
                panel.dragStartPos = nil
            end
        end

        return item
    end

    local function makeSlot(parent, key, labelText, x, y, opts)
        opts = opts or {}
        local slotSize = self._equipSlotSize or MONARCH_INV_SLOT_SIZE
        local slot = vgui.Create("DPanel", parent)
        slot:SetSize(slotSize, slotSize)
        slot:SetPos(x, y)
        slot.EquipKey = key
        slot.IsFreeEquip = opts.isFreeEquip == true
        slot.HasItem = false
        slot.ItemData = nil
        slot.ItemPanel = nil
        slot.InvPanel = self
        slot.HoverAlpha = 0
        slot.ClickAlpha = 0
        slot._wasHovered = false
        slot.AppearAlpha = 0
        slot.AppearScale = 0.95

        slot.Think = function(s)

            local hovered = s:IsHovered()
            if not hovered and s.HasItem and IsValid(s.ItemPanel) then
                hovered = s.ItemPanel:IsHovered()
            end
            s.HoverAlpha = hovered and 100 or 0

            if hovered and not s._wasHovered then
                surface.PlaySound(INV_HOVER_SOUND)
                s._wasHovered = true
            elseif not hovered then
                s._wasHovered = false
            end
        end

        slot.Paint = function(s, w, h)
            local isDragging, dragged = Monarch_GetDragState()
            local baseR, baseG, baseB = 28, 28, 28
            local hoverR, hoverG, hoverB = 45, 45, 45
            local baseAlpha = s.IsFreeEquip and 252 or 246
            local hoverAlpha = 255

            local appearFactor = math.Clamp((s.AppearAlpha or 0) / 255, 0, 1)
            local scale = s.AppearScale or 1
            local dw = math.max(1, w * scale)
            local dh = math.max(1, h * scale)
            local dx = (w - dw) * 0.5
            local dy = (h - dh) * 0.5

            local isDropTarget = false
            if isDragging and IsValid(dragged) then
                local mouseX, mouseY = gui.MousePos()
                local slotX, slotY = s:LocalToScreen(0, 0)
                local tolerance = 15
                if mouseX >= (slotX - tolerance) and mouseX <= (slotX + w + tolerance)
                and mouseY >= (slotY - tolerance) and mouseY <= (slotY + h + tolerance) then
                    isDropTarget = true
                    baseR, baseG, baseB = 220, 220, 220
                    hoverR, hoverG, hoverB = 240, 240, 240
                    baseAlpha = 40
                    hoverAlpha = 60
                end
            end

            local hoverFactor = math.Clamp((s.HoverAlpha or 0) / 100, 0, 1)
            local r = Lerp(hoverFactor, baseR, hoverR)
            local g = Lerp(hoverFactor, baseG, hoverG)
            local b = Lerp(hoverFactor, baseB, hoverB)
            local a = Lerp(hoverFactor, baseAlpha, hoverAlpha) * appearFactor

            local clickFactor = math.Clamp((s.ClickAlpha or 0) / 100, 0, 1)
            r = Lerp(clickFactor, r, 60)
            g = Lerp(clickFactor, g, 60)
            b = Lerp(clickFactor, b, 60)

            local bgColor = Color(r, g, b, a)
            DrawRoundedRect(dx, dy, dw, dh, 3, bgColor)

            if not s.HasItem then
                local icon = EQUIP_ICONS[key]
                if icon then
                    surface.SetMaterial(icon)
                    surface.SetDrawColor(10, 10, 10, 160 * appearFactor)
                    local pad = 24
                    local iw, ih = dw - pad * 2, dh - pad * 2
                    surface.DrawTexturedRect(dx + pad, dy + pad, iw, ih)
                else
                    local numText
                    if key == "primary" then numText = "1" end
                    if key == "secondary" then numText = "2" end
                    if key == "utility" then numText = "3" end
                    if key == "tool" then numText = "4" end
                    if numText then
                        draw.DrawText(numText, "MonarchInventory_Big", w/2, h/6, Color(255,255,255,10 * appearFactor), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, Color(0,0,0,150))
                    end
                end

                local borderCol = COL_INV_BORDER
                draw.NoTexture()
                surface.SetDrawColor(ColorAlpha(borderCol, (borderCol.a or 255) * appearFactor))
                surface.SetMaterial(MAT_INV_BORDER)
                surface.DrawTexturedRect(dx, dy, dw, dh)
            end

            if labelText and labelText ~= "" then
                surface.SetFont("InvSmall")
                local tw, th = surface.GetTextSize(labelText)
                surface.SetTextColor(220,220,220,220 * appearFactor)
                surface.SetTextPos(w/2 - tw/2, h + 4)
                surface.DrawText(labelText)
            end
        end

        slot.PaintOver = function(s, w, h)
            if s.HasItem and IsValid(s.ItemPanel) then

                local appearFactor = math.Clamp((s.AppearAlpha or 0) / 255, 0, 1)
                local scale = s.AppearScale or 1
                local dw = math.max(1, w * scale)
                local dh = math.max(1, h * scale)
                local dx = (w - dw) * 0.5
                local dy = (h - dh) * 0.5

                local borderCol = COL_INV_BORDER
                if s.ItemData then
                    local itemClass = s.ItemData.class or s.ItemData.id
                    local def = nil
                    if itemClass then
                        if Monarch and Monarch.Inventory and Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[itemClass] then
                            def = Monarch.Inventory.Items and Monarch.Inventory.Items[Monarch.Inventory.ItemsRef[itemClass]]
                        else
                            def = Monarch.Inventory.Items and Monarch.Inventory.Items[itemClass]
                        end
                    end
                    if def and (def.Illegal or def.Restricted) then
                        borderCol = COL_INV_BORDER_ILLEGAL
                    end
                end
                draw.NoTexture()
                surface.SetDrawColor(ColorAlpha(borderCol, (borderCol.a or 255) * appearFactor))
                surface.SetMaterial(MAT_INV_BORDER)
                surface.DrawTexturedRect(dx, dy, dw, dh)
            end
        end

        function slot:Think()

            local hovered = self:IsHovered()
            if not hovered and self.HasItem and IsValid(self.ItemPanel) then
                hovered = self.ItemPanel:IsHovered()
            end
            self.HoverAlpha = hovered and 100 or 0
            self.AppearAlpha = Lerp(FrameTime() * 8, self.AppearAlpha, 255)
            local hoverScale = hovered and 1.03 or 1.0
            self.AppearScale = hoverScale

            if hovered and not self._wasHovered then
                surface.PlaySound(INV_HOVER_SOUND)
                self._wasHovered = true
            elseif not hovered then
                self._wasHovered = false
            end

            local isDragging, dragged = Monarch_GetDragState()
            if not self.HasItem or not IsValid(self.ItemPanel) then return end

        end

        slot.OnMousePressed = function(s, mc)
            if mc ~= MOUSE_LEFT then return end
            if s.HasItem and IsValid(s.ItemPanel) then
                local card = s.ItemPanel
                card.dragStartTime = CurTime()
                card.dragStartPos = {gui.MousePos()}
                card.isDragActive = true
                Monarch_SetDragState(true, card, card.dragStartPos)
                Monarch_CreateDragPanel(card)
            end
        end

        self:InvalidateLayout(true)
        return slot
    end

    local s = math.max(Scale(56), MONARCH_INV_SLOT_SIZE - Scale(10))
    self._equipSlotSize = s
    local rowGap = math.max(4, math.floor(MONARCH_INV_SLOT_SPACING * 0.35))
    local spacingY = s + rowGap + 2
    local leftMargin = 16
    local betweenColumns = 36
    local bottomMargin = 24
    local utilityCount = 7
    local utilityGap = 8
    local utilityRowWidth = (s * utilityCount) + (utilityGap * (utilityCount - 1))
    local utilityReserve = s + 26

    local equipList = {
        { key = "head",  label = "Head" },
        { key = "face",  label = "Face" },
        { key = "torso", label = "Torso" },
        { key = "hands", label = "Hands" },
        { key = "legs",  label = "Legs" },
        { key = "shoes", label = "Shoes" },
    }
    local weapList = {
        { key = "primary",   label = "Primary" },
        { key = "secondary", label = "Secondary" },
        { key = "utility",   label = "Utility" },
        { key = "tool",      label = "Tool" },
    }
    local maxRows = math.max(#equipList, #weapList)

    self.equipPanel = vgui.Create("DPanel", self)
    local twoColWidth = leftMargin + s + betweenColumns + s + leftMargin
    local panelW = math.max(twoColWidth, (leftMargin * 2) + utilityRowWidth)
    self.equipPanel:SetSize(panelW, self:GetTall())
    self.equipPanel:SetPos(-panelW - Scale(40), 0)
    self.equipPanel.Paint = function() end
    self._equipBaseX = 0
    self._equipStartX = -panelW - Scale(40)

    local baseY = self:GetTall() - bottomMargin - utilityReserve - s - spacingY * (maxRows - 1)
    if baseY < 80 then baseY = 80 end

    local baseX = leftMargin
    for i, info in ipairs(equipList) do
        local y = baseY + spacingY * ((maxRows - #equipList) + (i - 1))
        self.equipSlots[info.key] = makeSlot(self.equipPanel, info.key, info.label, baseX, y)
    end

    local baseX2 = baseX + s + betweenColumns
    for i, info in ipairs(weapList) do
        local y = baseY + spacingY * ((maxRows - #weapList) + (i - 1))
        self.equipSlots[info.key] = makeSlot(self.equipPanel, info.key, info.label, baseX2, y)
    end

    local utilityBaseX = math.floor((panelW - utilityRowWidth) * 0.5)
    local utilityY = self:GetTall() - bottomMargin - s
    for i = 1, utilityCount do
        local key = "free" .. i
        local x = utilityBaseX + (i - 1) * (s + utilityGap)
        self.equipSlots[key] = makeSlot(self.equipPanel, key, "", x, utilityY, { isFreeEquip = true })
    end

    if not self._equipHooked then
        self._equipHooked = true
        local oldCreate = self.CreateGridItemCard
        self.CreateGridItemCard = function(invSelf, slotIndex, itemData)
            oldCreate(invSelf, slotIndex, itemData)
            local slot = invSelf.inventorySlots[slotIndex]
            if not IsValid(slot) or not IsValid(slot.ItemPanel) then return end
            local item = slot.ItemPanel
            local oldPerformDrop = item.PerformDrop
            item.PerformDrop = function(it, target)

                if IsValid(target) and target.EquipKey then
                    local def = it.ItemDef
                    local eg = def and Monarch.NormalizeEquipGroup(def.EquipGroup)

                    if target.IsFreeEquip then
                        if eg or not IsFreeEquipCandidate(def) then
                            it:SetAlpha(255)
                            Monarch_CleanupDrag()
                            return
                        end
                        local sourceKey = it.SourceSlot and it.SourceSlot.SlotID
                        invSelf:CreateEquipItemCard(target, it.ItemData, def, sourceKey)
                        surface.PlaySound("willardnetworks/inventory/inv_move1.wav")
                        it:SetAlpha(255)
                        Monarch_CleanupDrag()
                        return
                    end

                    if eg and eg == target.EquipKey then

                        local sourceKey = it.SourceSlot and it.SourceSlot.SlotID
                        if sourceKey then
                            local useTime = tonumber(def and (def.UseTime or def.UseWorkBarTime)) or 0
                            local useName = (def and (def.Workbar or def.UseWorkBarName)) or "Equipping..."
                            local delayed = false
                            if useTime > 0 and Monarch_ShowUseBar then
                                delayed = true
                                Monarch_ShowUseBar(vgui.GetWorldPanel() or nil, useTime, useName .. "", function()
                                    net.Start("Monarch_Inventory_UseItem")
                                        net.WriteUInt(sourceKey, 8)
                                    net.SendToServer()
                                    net.Start("Monarch_Inventory_Request")
                                    net.SendToServer()
                                end)
                            else
                                net.Start("Monarch_Inventory_UseItem")
                                    net.WriteUInt(sourceKey, 8)
                                net.SendToServer()
                                net.Start("Monarch_Inventory_Request")
                                net.SendToServer()
                            end

                            if not delayed and target.HasItem and target.ItemData then

                                local backItem = table.Copy(target.ItemData)
                                backItem.class = backItem.class or backItem.id or (target.ItemPanel and target.ItemPanel.ItemClass)
                                local backDef = target.ItemPanel and target.ItemPanel.ItemDef or nil
                                if IsValid(it.SourceSlot) then
                                    if IsValid(it.SourceSlot.ItemPanel) then it.SourceSlot.ItemPanel:Remove() end
                                    local gridItem = table.Copy(backItem)
                                    gridItem.ItemDef = backDef
                                    invSelf:CreateGridItemCard(it.SourceSlot.SlotID, gridItem)
                                end
                            end

                            if not delayed then
                                invSelf:CreateEquipItemCard(target, it.ItemData, def, sourceKey)
                            end
                            surface.PlaySound("willardnetworks/inventory/inv_move1.wav")
                        end

                        it:SetAlpha(255)
                        Monarch_CleanupDrag()
                        return
                    end
                end

                if oldPerformDrop then return oldPerformDrop(it, target) end
            end
        end
    end

    function self:RefreshEquipSlots()
        if not self.equipSlots then return end

        local steamID = LocalPlayer():SteamID64()
        local inv = Monarch.Inventory.Data and Monarch.Inventory.Data[steamID]
        if not inv then return end

        local desired = {}
        for idx = 21, 30 do
            local it = inv[idx]
            if istable(it) then
                local def = nil
                local cls = it.class or it.id
                if cls then
                    if Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[cls] then
                        def = Monarch.Inventory.Items and Monarch.Inventory.Items[Monarch.Inventory.ItemsRef[cls]]
                    else
                        def = Monarch.Inventory.Items and Monarch.Inventory.Items[cls]
                    end
                end
                local eg = def and Monarch.NormalizeEquipGroup(def.EquipGroup)
                if eg then desired[eg] = { data = it, def = def, idx = idx } end
            end
        end

        for egKey, slotPanel in pairs(self.equipSlots) do
            if not slotPanel.IsFreeEquip then
                local want = desired[egKey]
                if want then
                    local curClass = slotPanel.ItemData and (slotPanel.ItemData.class or slotPanel.ItemData.id)
                    local wantClass = want.data.class or want.data.id
                    if not (slotPanel.HasItem and curClass == wantClass and IsValid(slotPanel.ItemPanel)) then
                        if IsValid(slotPanel.ItemPanel) then slotPanel.ItemPanel:Remove() end
                        local card = self:CreateEquipItemCard(slotPanel, want.data, want.def, want.idx)
                        if IsValid(card) then
                            local oldPD = card.PerformDrop
                            card.PerformDrop = function(itm, target)
                                if IsValid(target) and target.SlotID then
                                    Monarch_CleanupDrag()
                                    return
                                end
                                if oldPD then return oldPD(itm, target) end
                            end
                        end
                    else

                        slotPanel.ItemData = want.data
                        if IsValid(slotPanel.ItemPanel) then
                            slotPanel.ItemPanel.ItemData = want.data
                        end
                    end
                else
                    if slotPanel.HasItem then
                        if IsValid(slotPanel.ItemPanel) then slotPanel.ItemPanel:Remove() end
                        slotPanel.ItemPanel = nil
                        slotPanel.ItemData = nil
                        slotPanel.HasItem = false
                    end
                end
            end
        end
    end

    timer.Simple(0, function()
        if IsValid(self) then self:RefreshEquipSlots() end
    end)
end

    end

