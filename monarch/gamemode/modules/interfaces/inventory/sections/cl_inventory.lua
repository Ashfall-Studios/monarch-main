return function(PANEL)
    if not CLIENT then return end

    local Scale = (Monarch and Monarch.UI and Monarch.UI.Scale) or function(v) return v end
    local INV_HOVER_SOUND = "ui/hls_ui_scroll_click.wav"
    local function DrawRoundedRect(x, y, w, h, radius, color)
        draw.RoundedBox(radius, x, y, w, h, color)
    end

function PANEL:CreateInventoryPanel(parent)
    parentInv = self
    local w, h = parent:GetSize()
    local panel = vgui.Create("DPanel", parent)
    panel:SetSize(w, h)
    panel:SetPos(0, 0)
    panel.Paint = function() end

    local leftPanel = vgui.Create("DPanel", panel)
    leftPanel:SetSize(280, h)
    leftPanel:SetPos(0, 0)
    leftPanel.Paint = function() end
    self.inventoryGrid = vgui.Create("DIconLayout", panel)
    self.inventoryGrid:SetSize(w - 300, h)
    self.inventoryGrid:SetPos(300, 0)
    self.inventoryGrid:SetSpaceX(2)
    self.inventoryGrid:SetSpaceY(2)

    local leftPanel = vgui.Create("DPanel", panel)
    leftPanel:SetSize(600, h)
    leftPanel:SetPos(-600, 0)
    leftPanel.Paint = function() end
    self.leftPanel = leftPanel

    local tabsWidth = Scale(130)
    local rightPanelWidth = Scale(590) 
    local rightPanel = vgui.Create("DPanel", panel)
    rightPanel:SetSize(rightPanelWidth, h)
    rightPanel:SetPos(w, 0)
    rightPanel.Paint = function() end

    self.rightPanel = rightPanel

    leftPanel:SetAlpha(0)
    rightPanel:SetAlpha(0)
    local dur = 0.18
    local introDelay = tonumber(self._inventoryContentOpenDelay) or 0
    local finalLeftX = 0
    local finalRightX = w - tabsWidth - rightPanelWidth - Scale(10)
    leftPanel:MoveTo(finalLeftX, 0, dur, introDelay)
    leftPanel:AlphaTo(255, dur, introDelay)
    rightPanel:MoveTo(finalRightX, 0, dur, introDelay)
    rightPanel:AlphaTo(255, dur, introDelay)

    local invGrid = vgui.Create("DPanel", rightPanel)
    invGrid:SetPos(Scale(10), Scale(80))

    local rows = 4
    local gridHeight = Scale(10) + rows * MONARCH_INV_SLOT_SIZE + (rows - 1) * MONARCH_INV_SLOT_SPACING + Scale(10)
    invGrid:SetSize(rightPanel:GetWide() - Scale(20), gridHeight)
    invGrid.Paint = function() end 

    local invTitleShadow = vgui.Create("DLabel", rightPanel)
    invTitleShadow:SetText("INVENTORY")
    invTitleShadow:SetFont("Inventory_Title")
    invTitleShadow:SetColor(Color(0, 0, 0, 250))
    invTitleShadow:SizeToContents()

    local invTitle = vgui.Create("DLabel", rightPanel)
    invTitle:SetText("INVENTORY")
    invTitle:SetFont("Inventory_Title")
    invTitle:SetColor(Color(185, 185, 185))
    invTitle:SizeToContents()

    local titleMargin = Scale(20)
    local invIconSize = Scale(55)
    local iconSpacing = Scale(4)

    local totalWidth = invIconSize + iconSpacing + invTitle:GetWide()
    local ix = invGrid:GetX() + (invGrid:GetWide() - totalWidth) * 0.5 + invIconSize + iconSpacing
    local iy = invGrid:GetY() - invTitle:GetTall() - titleMargin
    invTitle:SetPos(math.floor(ix), math.floor(iy))
    invTitleShadow:SetPos(math.floor(ix) + 2, math.floor(iy) + 2)
    self._invTitleBaseline = math.floor(iy)

    local invIconShadow = vgui.Create("DImage", rightPanel)
    invIconShadow:SetImage("icons/inventory/backpack_icon.png")
    invIconShadow:SetSize(invIconSize, invIconSize)
    invIconShadow:SetPos(invTitle:GetX() - invIconSize - iconSpacing + 2, invTitle:GetY() + (invTitle:GetTall() - invIconSize) * 0.5 + 2)
    invIconShadow:SetImageColor(Color(0, 0, 0, 150))

    local invIcon = vgui.Create("DImage", rightPanel)
    invIcon:SetImage("icons/inventory/backpack_icon.png")
    invIcon:SetSize(invIconSize, invIconSize)
    invIcon:SetPos(invTitle:GetX() - invIconSize - iconSpacing, invTitle:GetY() + (invTitle:GetTall() - invIconSize) * 0.5)
    invIcon:SetImageColor(Color(185, 185, 185))

    self.invGrid = invGrid

    if not self.inventorySlots or table.Count(self.inventorySlots) == 0 then
        self.inventorySlots = {}
        local slotSize = MONARCH_INV_SLOT_SIZE
        local spacing = MONARCH_INV_SLOT_SPACING
        local slotsPerRow = INVENTORY_SLOTS_PER_ROW
        local startX = Scale(6)
        local startY = Scale(6)

        for i = 1, INVENTORY_SLOT_COUNT do
            local row = math.floor((i - 1) / slotsPerRow)
            local col = (i - 1) % slotsPerRow

            local slot = vgui.Create("DPanel", invGrid)
            slot:SetSize(slotSize, slotSize)
            slot:SetPos(startX + col * (slotSize + spacing), startY + row * (slotSize + spacing))
            slot:SetCursor("hand")
            slot.SlotID = i
            slot.HasItem = false
            slot.ItemData = nil
            slot.ItemPanel = nil
            slot.ParentInventory = self
            slot.HoverAlpha = 0
            slot._wasHovered = false
            slot.ClickAlpha = 0
            slot._isClicked = false

            slot.OnMousePressed = function(slotSelf, mouseCode)
                if mouseCode == MOUSE_LEFT then
                    slotSelf._isClicked = true
                    slotSelf.ClickStartTime = CurTime()
                end
            end

            slot.OnMouseReleased = function(slotSelf, mouseCode)
                if mouseCode == MOUSE_LEFT then
                    slotSelf._isClicked = false
                end
            end

            slot.Think = function(slotSelf)

                local emptyHovered = slotSelf:IsHovered() and not slotSelf.HasItem
                local itemHovered = slotSelf.HasItem and IsValid(slotSelf.ItemPanel) and slotSelf.ItemPanel:IsHovered()
                local hovered = emptyHovered or itemHovered
                slotSelf.HoverAlpha = hovered and 100 or 0

                if hovered and not slotSelf._wasHovered then
                    surface.PlaySound(INV_HOVER_SOUND)
                    slotSelf._wasHovered = true
                elseif not hovered then
                    slotSelf._wasHovered = false
                end

                if slotSelf._isClicked then
                    slotSelf.ClickAlpha = 80
                else
                    slotSelf.ClickAlpha = 0
                end
            end

            slot.Paint = function(slotSelf, slotW, slotH)
                local isDragging, draggedItem = Monarch_GetDragState()
                local baseR, baseG, baseB = 28, 28, 28
                local hoverR, hoverG, hoverB = 45, 45, 45
                local alpha = 248

                local isDropTarget = false
                if isDragging and IsValid(draggedItem) then
                    local mouseX, mouseY = gui.MousePos()
                    local slotX, slotY = slotSelf:LocalToScreen(0, 0)
                    local actualW, actualH = slotSelf:GetSize()
                    local tolerance = 15
                    if mouseX >= (slotX - tolerance) and mouseX <= (slotX + actualW + tolerance) and
                       mouseY >= (slotY - tolerance) and mouseY <= (slotY + actualH + tolerance) then
                        isDropTarget = true
                        baseR, baseG, baseB = 220, 220, 220
                        alpha = 40
                    end
                end

                local hoverFactor = math.Clamp((slotSelf.HoverAlpha or 0) / 100, 0, 1)
                local r = Lerp(hoverFactor, baseR, hoverR)
                local g = Lerp(hoverFactor, baseG, hoverG)
                local b = Lerp(hoverFactor, baseB, hoverB)

                local bgColor = Color(r, g, b, alpha)
                DrawRoundedRect(0, 0, slotW, slotH, 3, bgColor)

                if slotSelf.ClickAlpha and slotSelf.ClickAlpha > 1 then
                    local clickColor = Color(100, 100, 100, math.floor(slotSelf.ClickAlpha))
                    DrawRoundedRect(0, 0, slotW, slotH, 3, clickColor)
                end

                local borderCol = COL_INV_BORDER
                if slotSelf.HasItem and slotSelf.ItemData then
                    local itemData = slotSelf.ItemData
                    local itemRestricted = itemData.restricted or false
                    local itemClass = itemData.class or itemData.id
                    local def = itemData.ItemDef or self:ResolveItemDefinition(itemClass)

                    local isConstrained = itemData and itemData.constrained or false
                    
                    if def and def.Illegal then
                        borderCol = COL_INV_BORDER_ILLEGAL
                    elseif itemRestricted or (def and (def.Restricted or def.restricted)) then
                        borderCol = COL_INV_BORDER_RESTRICTED
                    elseif isConstrained then
                        borderCol = COL_INV_BORDER_CONSTRAINED
                    end
                end
                draw.NoTexture()

                surface.SetDrawColor(borderCol)
                surface.SetMaterial(MAT_INV_BORDER)
                surface.DrawTexturedRect(0, 0, slotW, slotH)

            end

            self.inventorySlots[i] = slot
        end

        if Monarch and Monarch.Inventory and Monarch.Inventory.Data then

            self:SetupItems()
        else

        end
    end

    if not self._equipSlotsBuilt then
        self:BuildEquipSlots()
        self._equipSlotsBuilt = true
    end

    return panel
end

end

