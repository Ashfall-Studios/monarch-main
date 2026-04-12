if CLIENT then

    Monarch = Monarch or {}
    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Items = Monarch.Inventory.Items or {}
    Monarch.Inventory.ItemsRef = Monarch.Inventory.ItemsRef or {}

    if not Monarch.UI or not Monarch.UI.Scale then
        Monarch.LoadFile("modules/client/themes/cl_scale.lua")
    end
end

Monarch.UI = Monarch.UI or {}

local Scale = Monarch.UI.Scale or function(v) return v end
local ScaleFont = Monarch.UI.ScaleFont or function(v) return v end

if CLIENT then

    MONARCH_INV_SLOT_SIZE = Scale(100)
    MONARCH_INV_SLOT_SPACING = Scale(3)
    local INVENTORY_FADE_IN_TIME = 2
    local INVENTORY_FADE_OUT_TIME = 0.5
    local DERMA_QUERY_FADE_IN_TIME = 0.2
    local DERMA_QUERY_FADE_OUT_TIME = 0.15
    MAT_INV_BORDER = MAT_INV_BORDER or Material("icons/inventory/cmb_poly.png", "smooth")
    COL_INV_BORDER = Color(70, 70, 70, 255)
    COL_INV_BORDER_ILLEGAL = Color(90, 28, 28, 220)
    COL_INV_BORDER_RESTRICTED = Color(255, 200, 100, 25)
    COL_INV_BORDER_CONSTRAINED = Color(255, 200, 100, 25) -- Yellow border like restricted
    MAT_INV_BORDER_STR = "icons/inventory/cmb_poly.png"

    local MAT_HOVER_GRAD = Material("vgui/gradient-l")
    local INV_HOVER_SOUND = "ui/hls_ui_scroll_click.wav"

    local function DrawRoundedRect(x, y, w, h, radius, color)
        draw.RoundedBox(radius, x, y, w, h, color)
    end

    local function UI_PaintFullscreenBackdrop(s, pw, ph)
        Derma_DrawBackgroundBlur(s)
        surface.SetDrawColor(0, 0, 0, 100)
        surface.DrawRect(0, 0, pw, ph)
    end

    local function UI_CreateFullscreenOverlay()
        local frame = vgui.Create("DFrame")
        frame:SetSize(ScrW(), ScrH())
        frame:Center()
        frame:SetTitle("")
        frame:ShowCloseButton(false)
        frame:SetDraggable(false)
        frame:SetBackgroundBlur(true)
        frame:SetDrawOnTop(true)
        frame:MakePopup()
        frame:SetDeleteOnClose(true)
        frame:SetAlpha(0)
        frame:AlphaTo(255, DERMA_QUERY_FADE_IN_TIME, 0)
        frame.Paint = UI_PaintFullscreenBackdrop
        return frame
    end

    local function UI_FadeClose(panel, duration, onClosed)
        if not IsValid(panel) then return end

        panel:AlphaTo(0, tonumber(duration) or DERMA_QUERY_FADE_OUT_TIME, 0, function()
            if IsValid(panel) then
                if panel.Close then
                    panel:Close()
                else
                    panel:Remove()
                end
            end

            if onClosed then
                onClosed(panel)
            end
        end)
    end

    local function UI_PaintBasicDialogButton(button, width, height)
        local bgColor = button:IsHovered() and Color(20, 20, 20, 200) or Color(0, 0, 0, 100)
        draw.RoundedBox(0, 0, 0, width, height, bgColor)
    end

    local function UI_DrawFilledCircle(x, y, radius, seg, col)
        draw.NoTexture()
        surface.SetDrawColor(col)

        local poly = {{x = x, y = y}}
        for i = 0, seg do
            local ang = math.rad((i / seg) * 360)
            poly[#poly + 1] = {x = x + math.cos(ang) * radius, y = y + math.sin(ang) * radius}
        end

        surface.DrawPoly(poly)
    end

    local function UI_DrawCircleSector(x, y, radius, startAng, endAng, seg, col)
        draw.NoTexture()
        surface.SetDrawColor(col)

        local poly = {{x = x, y = y}}
        for i = 0, seg do
            local t = i / seg
            local ang = math.rad(startAng + (endAng - startAng) * t)
            poly[#poly + 1] = {x = x + math.cos(ang) * radius, y = y + math.sin(ang) * radius}
        end

        surface.DrawPoly(poly)
    end

    surface.CreateFont("MonarchInventory_Tiny", {
        font = "Arial",
        size = ScaleFont(12),
        weight = 500,
        antialias = true,
    })

    surface.CreateFont("MonarchInventory_Sub", {
        font = "Arial",
        size = ScaleFont(14),
        weight = 500,
        antialias = true,
    })

    surface.CreateFont("MonarchInventory_Text", {
        font = "Arial",
        size = ScaleFont(14),
        weight = 500,
        antialias = true,
    })

    surface.CreateFont("MonarchInventory_BigGlow", {
        font = "Arial Black",
        size = ScaleFont(32),
        weight = 900,
        blursize = 8,
        antialias = true,
        additive = true,
    })
    surface.CreateFont("MonarchInventory_Big", {
        font = "Arial Black",
        size = ScaleFont(75),
        weight = 900,
        antialias = true,
    })

    surface.CreateFont("DinPro", {
        font = "Din Pro Regular",
        size = 20,
        weight = 400,
        antialias = true,
    })

    surface.CreateFont("DinProLarge", {
        font = "Din Pro Regular",
        size = 24,
        weight = 400,
        antialias = true,
    })

    local draggedItem = nil
    local dragPanel = nil
    local dragStartPos = nil
    local isDragging = false

    Monarch.GetItemModelFOV = Monarch.GetItemModelFOV or function(def, defaultFov)
        local f = def and (def.ModelFOV or def.FOV)
        f = tonumber(f)
        if not f then return defaultFov or 35 end
        if f < 5 then f = 5 elseif f > 120 then f = 120 end
        return f
    end
    local function Monarch_FindInventoryPanel()
        for _, child in ipairs(vgui.GetWorldPanel():GetChildren()) do
            if child.ClassName == "MonarchInventory" and child.SetupItems then return child end
        end
    end

    local function INV_GetPalette()
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
            primary = Color(85, 85, 85),
            primaryHover = Color(120, 120, 120),
            inputBg = Color(30, 30, 30),
            inputBorder = Color(80, 80, 80),
            inputText = Color(210, 210, 210),
            radius = 6,
        }
    end

    Monarch.UI = Monarch.UI or {}
    function Monarch.UI.OpenAmountDialog(opts)

        opts = opts or {}

        local f = UI_CreateFullscreenOverlay()

        local container = vgui.Create("DPanel", f)
        container:SetSize(600, 250)
        container:Center()
        container.Paint = function() end

        local title = vgui.Create("DLabel", container)
        title:SetText(opts.title or "Amount")
        title:SetFont("DinProLarge")
        title:SetTextColor(color_white)
        title:SetContentAlignment(5)
        title:Dock(TOP)
        title:DockMargin(0, 20, 0, 20)
        title:SetTall(32)

        local lbl = vgui.Create("DLabel", container)
        lbl:SetText(opts.subtitle or "Enter amount")
        lbl:SetFont("DinPro")
        lbl:SetTextColor(color_white)
        lbl:SetContentAlignment(5)
        lbl:Dock(TOP)
        lbl:DockMargin(0, 0, 0, 20)
        lbl:SetTall(24)

        local entry = vgui.Create("DTextEntry", container)
        entry:SetText(tostring(math.floor(tonumber(opts.default) or 1)))
        entry:SetFont("DinPro")
        entry:SetTextColor(color_white)
        entry:SetPaintBackground(true)
        entry.Paint = function(s, pw, ph)
            draw.RoundedBox(0, 0, 0, pw, ph, Color(40, 40, 40))
            s:DrawTextEntryText(s:GetTextColor(), s:GetHighlightColor(), s:GetCursorColor())
        end
        entry:Dock(TOP)
        entry:DockMargin(80, 0, 80, 25)
        entry:SetTall(40)
        if entry.SetNumeric then entry:SetNumeric(true) end

        local btnPanel = vgui.Create("DPanel", container)
        btnPanel:SetTall(40)
        btnPanel:Dock(BOTTOM)
        btnPanel:DockMargin(0, 0, 0, 15)
        btnPanel.Paint = function() end

        local ok = vgui.Create("DButton", btnPanel)
        ok:SetText("OK")
        ok:SetFont("DinPro")
        ok:SetWide(150)
        ok:SetTextColor(color_white)
        ok:Dock(LEFT)
        ok:DockMargin(150, 0, 0, 0)
        ok.Paint = UI_PaintBasicDialogButton
        ok.DoClick = function()
            local v = tonumber(entry:GetText() or "")
            local min = math.max(1, math.floor(tonumber(opts.min) or 1))
            local max = math.max(min, math.floor(tonumber(opts.max) or min))
            if not v then return end
            v = math.floor(v)
            if v < min or v > max then return end
            if opts.onSubmit then opts.onSubmit(v) end
            UI_FadeClose(f)
        end

        local cancel = vgui.Create("DButton", btnPanel)
        cancel:SetText("Cancel")
        cancel:SetFont("DinPro")
        cancel:SetWide(150)
        cancel:SetTextColor(color_white)
        cancel:Dock(LEFT)
        cancel:DockMargin(0, 0, 0, 0)
        cancel.Paint = UI_PaintBasicDialogButton
        cancel.DoClick = function()
            UI_FadeClose(f)
        end

        entry.OnEnter = function() ok:DoClick() end

        entry:RequestFocus()
        entry:SelectAllText(true)
        return f
    end


    Monarch.NormalizeEquipGroup = Monarch.NormalizeEquipGroup or function(eq)
        if not eq then return nil end
        eq = string.lower(tostring(eq))
        if eq == "primary_weapon" or eq == "primary" then return "primary" end
        if eq == "secondary_weapon" or eq == "secondary" then return "secondary" end
        if eq == "utility" then return "utility" end
        if eq == "tool" then return "tool" end
        if eq == "head" then return "head" end
        if eq == "face" then return "face" end
        if eq == "torso" or eq == "chest" or eq == "body" then return "torso" end
        if eq == "legs" or eq == "pants" then return "legs" end
        if eq == "shoes" or eq == "feet" or eq == "boots" then return "shoes" end
        return eq
    end

    function Monarch_ShowUseBar(parentPanel, duration, labelText, onDone, allowMovement)
        duration = math.max(0.05, tonumber(duration) or 0)
        if duration <= 0 then
            if onDone then onDone() end
            return
        end

        local function IsInventoryOpenForUseBar()
            local panel = Monarch_FindInventoryPanel()
            return IsValid(panel) and panel:IsVisible() and not panel._closing, panel
        end

        local useInventoryOverlay, invPanel = IsInventoryOpenForUseBar()

        if IsValid(Monarch._activeUseOverlay) then
            Monarch._activeUseOverlay:Remove()
            Monarch._activeUseOverlay = nil
        end

        if useInventoryOverlay and invPanel.ClearItemSelection then
            invPanel:ClearItemSelection()
        end

        local targetParent = IsValid(parentPanel) and parentPanel or vgui.GetWorldPanel()
        if useInventoryOverlay then
            targetParent = vgui.GetWorldPanel()
        end

        local shouldCaptureInput = (not allowMovement) and (not useInventoryOverlay)

        local overlay = vgui.Create("DPanel")
            overlay:SetParent(targetParent)
            overlay:Dock(FILL)
            overlay:SetZPos(40000)
            if overlay.SetDrawOnTop then overlay:SetDrawOnTop(true) end
            overlay:SetMouseInputEnabled(shouldCaptureInput)
            overlay:SetKeyboardInputEnabled(shouldCaptureInput)
            overlay:MoveToFront()
        if shouldCaptureInput then
            overlay:MakePopup()
            if overlay.SetFocusTopLevel then overlay:SetFocusTopLevel(true) end
        end

        local endTime = CurTime() + duration

        local function FormatCountdown(totalSeconds)
            local t = math.max(0, tonumber(totalSeconds) or 0)
            local minutes = math.floor(t / 60)
            local seconds = math.floor(t % 60)
            local centiseconds = math.floor((t - math.floor(t)) * 100)
            return string.format("%02d:%02d:%02d", minutes, seconds, centiseconds)
        end

        overlay.Paint = function(s, w, h)

            local inventoryOpenNow = IsInventoryOpenForUseBar()

            local cx = w * 0.5
            local cy = inventoryOpenNow and (h * 0.42) or (h - math.max(170, h * 0.20))
            local R = inventoryOpenNow and math.max(98, math.min(w, h) * 0.085) or math.max(48, math.min(w, h) * 0.025)
            local remain = math.max(0, endTime - CurTime())
            local frac = 1 - (remain / duration)
            local useBg = Color(20,20,20, 120)
            local useFill = Color(135, 185, 186, 200)
            local labelFont = "InvSmall"
            local timerFont = "InvSmall"
            local labelYOffset = 76
            local timerYOffset = -6

            UI_DrawFilledCircle(cx, cy, R, 96, useBg)

            local startAng = -90
            local endAng = startAng + 360 * math.Clamp(frac, 0, 1)
            local seg = math.max(12, math.floor(96 * math.Clamp(frac, 0.05, 1)))
            UI_DrawCircleSector(cx, cy, R, startAng, endAng, seg, useFill)

            if not inventoryOpenNow then
                local timerText = FormatCountdown(remain)
                draw.SimpleTextOutlined(labelText or "Using item...", labelFont, cx, cy + labelYOffset, Color(240,240,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, Color(0,0,0,180))
                draw.SimpleTextOutlined(timerText, timerFont, cx, cy + timerYOffset, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0,0,0,180))
            end
        end

        local finished = false
        overlay.Think = function()
            if finished then return end
            if IsValid(overlay) then overlay:MoveToFront() end
            if CurTime() >= endTime then
                finished = true
                if IsValid(overlay) then overlay:Remove() end
                Monarch._activeUseOverlay = nil
                if onDone then onDone() end
            end
        end

        Monarch._activeUseOverlay = overlay
        return overlay
    end
    local function Monarch_RefreshInventoryUI(reason)
        local panel = Monarch_FindInventoryPanel()
        if not panel then return end
        local lp = LocalPlayer()
        if IsValid(lp) then
            if IsValid(panel.healthBar) then panel.healthBar.Value = lp:Health() or panel.healthBar.Value or 100 end
            if IsValid(panel.hydrationBar) and lp.GetHydration then panel.hydrationBar.Value = lp:GetHydration() or panel.hydrationBar.Value end
            if IsValid(panel.hungerBar) and lp.GetHunger then panel.hungerBar.Value = lp:GetHunger() or panel.hungerBar.Value end
            if IsValid(panel.exhaustionBar) and lp.GetExhaustion then panel.exhaustionBar.Value = lp:GetExhaustion() or panel.exhaustionBar.Value end
        end
        if panel.SetupItems then panel:SetupItems() end

        if panel.lastSelectedSlot then
            local slot = panel.inventorySlots and panel.inventorySlots[panel.lastSelectedSlot]
            if IsValid(slot) and IsValid(slot.ItemPanel) and panel.ShowItemInfo then
                panel:ShowItemInfo(slot.ItemPanel)
            elseif panel.ClearItemSelection then
                panel:ClearItemSelection()
            end
        end
    end

    net.Receive("Monarch_Inventory_Update", function()
        local inventoryData = net.ReadTable() or {}
        local steamID = LocalPlayer():SteamID64()
        if not steamID then return end
        Monarch.Inventory = Monarch.Inventory or {}
        Monarch.Inventory.Data = Monarch.Inventory.Data or {}
        Monarch.Inventory.Data[steamID] = inventoryData

        local pending = Monarch._pendingSelect
        if pending then
            local it = inventoryData[pending.slot]
            local same = false
            if it then
                local curClass = it.class or it.id
                same = (curClass == pending.class)
            end
            local panel = Monarch_FindInventoryPanel()
            if IsValid(panel) then

                if pending.action == "use" then
                    panel.lastSelectedSlot = nil
                    if panel.ClearItemSelection then panel:ClearItemSelection() end
                elseif pending.action == "drop" or pending.action == "dismantle" then

                    panel.lastSelectedSlot = nil
                    if panel.ClearItemSelection then panel:ClearItemSelection() end
                elseif same then
                    panel.lastSelectedSlot = pending.slot
                else
                    panel.lastSelectedSlot = nil
                    if panel.ClearItemSelection then panel:ClearItemSelection() end
                end
            end
            Monarch._pendingSelect = nil
        end

        Monarch_RefreshInventoryUI("inventory-update")

        local invPanel2 = Monarch_FindInventoryPanel()
        if IsValid(invPanel2) and invPanel2.RefreshEquipSlots then
            invPanel2:RefreshEquipSlots()
        end
    end)

    if not Monarch.Inventory._ItemDefsReceiverAdded then
        net.Receive("Monarch_Inventory_ItemDefs", function()
            local payload = net.ReadTable() or {}
            if not istable(payload) then return end
            local defs = payload.Items or payload 
            local refMap = payload.Ref or {}
            Monarch.Inventory.Items = Monarch.Inventory.Items or {}
            Monarch.Inventory.ItemsRef = Monarch.Inventory.ItemsRef or {}
            local added, updated = 0, 0
            for uniqueID, def in pairs(defs) do
                if istable(def) then

                    local modelPath = def.Model or def.model
                    if util and util.PrecacheModel and isstring(modelPath) and modelPath ~= "" then
                        util.PrecacheModel(modelPath)
                    end

                    if Monarch.Inventory.Items[uniqueID] then
                        local wasPlaceholder = (Monarch.Inventory.Items[uniqueID].Model and not Monarch.Inventory.Items[uniqueID].Usable and not Monarch.Inventory.Items[uniqueID].WeaponClass)
                        if wasPlaceholder then
                            Monarch.Inventory.Items[uniqueID] = table.Copy(def)
                            updated = updated + 1
                        else
                            for k,v in pairs(def) do
                                Monarch.Inventory.Items[uniqueID][k] = v
                            end
                            updated = updated + 1
                        end
                    else
                        Monarch.Inventory.Items[uniqueID] = table.Copy(def)
                        added = added + 1
                    end
                end
            end

            if istable(refMap) and next(refMap) then
                Monarch.Inventory.ItemsRef = refMap
            else

                for uniqueID,_ in pairs(defs) do
                    Monarch.Inventory.ItemsRef[uniqueID] = uniqueID
                end
            end

            Monarch_RefreshInventoryUI("defs-update")
        end)

        net.Receive("Monarch_Inventory_ItemDefs_Compressed", function()
            local bytes = net.ReadUInt(32)
            local raw = (bytes and bytes > 0) and net.ReadData(bytes) or nil
            local json = raw and util.Decompress(raw) or nil
            local payload = util.JSONToTable(json or "{}") or {}
            if not istable(payload) then return end

            local defs = payload.Items or payload
            local refMap = payload.Ref or {}
            Monarch.Inventory.Items = Monarch.Inventory.Items or {}
            Monarch.Inventory.ItemsRef = Monarch.Inventory.ItemsRef or {}

            for uniqueID, def in pairs(defs) do
                if istable(def) then
                    local modelPath = def.Model or def.model
                    if util and util.PrecacheModel and isstring(modelPath) and modelPath ~= "" then
                        util.PrecacheModel(modelPath)
                    end

                    if Monarch.Inventory.Items[uniqueID] then
                        for k, v in pairs(def) do
                            Monarch.Inventory.Items[uniqueID][k] = v
                        end
                    else
                        Monarch.Inventory.Items[uniqueID] = table.Copy(def)
                    end
                end
            end

            if istable(refMap) and next(refMap) then
                Monarch.Inventory.ItemsRef = refMap
            else
                for uniqueID, _ in pairs(defs) do
                    Monarch.Inventory.ItemsRef[uniqueID] = uniqueID
                end
            end

            Monarch_RefreshInventoryUI("defs-update")
        end)
        Monarch.Inventory._ItemDefsReceiverAdded = true
    end

    if not Monarch.Inventory._RankLadderReceiverAdded then
        net.Receive("Monarch_RankLadder", function()
            local tbl = net.ReadTable() or {}
            if istable(tbl) then
                Monarch.RankLadders = tbl
            end
        end)
        Monarch.Inventory._RankLadderReceiverAdded = true
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

    local function ApplySpawnIconPosition(iconPanel, itemDef, isClicked)
        if not IsValid(iconPanel) then return end
        local ent = iconPanel:GetEntity()
        if not IsValid(ent) then return end

        local tab = isfunction(PositionSpawnIcon) and PositionSpawnIcon(ent, ent:GetPos()) or nil

        local camPos = istable(tab) and tab.origin or nil
        if not isvector(camPos) then
            local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
            local center = (mins + maxs) * 0.5
            local radius = math.max((maxs - mins):Length(), 16)
            camPos = center + Vector(radius * 1.1, radius * 1.1, radius * 0.65)
        end

        camPos = camPos + ResolveSpawnIconOffset(itemDef, isClicked)
        if isfunction(iconPanel.SetCamPos) then
            iconPanel:SetCamPos(camPos)
        end

        if isfunction(iconPanel.SetFOV) then
            local baseFOV = (istable(tab) and tab.fov) and tonumber(tab.fov) or 36
            iconPanel:SetFOV(ResolveSpawnIconFOV(itemDef, isClicked, baseFOV))
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

        if isfunction(iconPanel.SetLookAng) then
            iconPanel:SetLookAng(finalLookAng)
        elseif isfunction(iconPanel.SetLookAt) then
            local lookDist = math.max(camPos:Distance(ent:OBBCenter()), 16)
            iconPanel:SetLookAt(camPos + finalLookAng:Forward() * lookDist)
        end
    end

    function Monarch_CreateDragPanel(itemPanel)
        if IsValid(dragPanel) then
            dragPanel:Remove()
        end

        local cardW, cardH = itemPanel:GetWide(), itemPanel:GetTall()
        dragPanel = vgui.Create("DPanel")
        dragPanel:SetSize(cardW, cardH)
        dragPanel:SetMouseInputEnabled(false)
        dragPanel:SetKeyboardInputEnabled(false)
        dragPanel:MakePopup()
        dragPanel:SetZPos(9999)
        dragPanel:SetAlpha(200)

        dragPanel.Paint = function(self, w, h)

        end

        local modelPath = "models/props_junk/cardboard_box004a.mdl"
        if itemPanel.ItemDef and (itemPanel.ItemDef.Model or itemPanel.ItemDef.model) then
            modelPath = itemPanel.ItemDef.Model or itemPanel.ItemDef.model
        end

        local dragModel = vgui.Create("DModelPanel", dragPanel)
        dragModel:Dock(FILL)
        dragModel:SetMouseInputEnabled(false)
        dragModel:SetKeyboardInputEnabled(false)
        dragModel.LayoutEntity = function() end
        dragModel:SetModel(modelPath)

        timer.Simple(0, function()
            if not IsValid(dragModel) then return end
            ApplySpawnIconPosition(dragModel, itemPanel.ItemDef, false)
        end)

        local x, y = gui.MousePos()
        dragPanel:SetPos(x - 40, y - 40)
    end

    function Monarch_CleanupDrag()
        if IsValid(dragPanel) then
            dragPanel:Remove()
            dragPanel = nil
        end
        draggedItem = nil
        dragStartPos = nil
        isDragging = false
    end

    function Monarch_GetDragState()
        return isDragging, draggedItem, dragStartPos
    end

    function Monarch_SetDragState(dragging, item, startPos)
        isDragging = dragging
        draggedItem = item
        dragStartPos = startPos
    end

    hook.Add("Think", "Monarch_UpdateDragPanel", function()
        if isDragging and IsValid(dragPanel) then
            local x, y = gui.MousePos()
            local dw, dh = dragPanel:GetSize()
            dragPanel:SetPos(x - math.floor(dw * 0.5), y - math.floor(dh * 0.5))
        end
    end)

    function Monarch_CreateDragPanelForLoot(mdlPath, label, w, h, fov)
        if IsValid(dragPanel) then dragPanel:Remove() end

        w = tonumber(w) or 80
        h = tonumber(h) or 80
        fov = tonumber(fov) or 35

        dragPanel = vgui.Create("DPanel")
        dragPanel:SetSize(w, h)
        dragPanel:SetMouseInputEnabled(false)
        dragPanel:SetKeyboardInputEnabled(false)
        dragPanel:MakePopup()
        dragPanel:SetZPos(9999)
        dragPanel:SetAlpha(200)
        dragPanel.Paint = function(self, pw, ph)

        end

        local mdl = vgui.Create("SpawnIcon", dragPanel)
        mdl:Dock(FILL)
        mdl:SetMouseInputEnabled(false)
        mdl:SetKeyboardInputEnabled(false)
        mdl:SetModel(mdlPath or "models/props_junk/PopCan01a.mdl")

        local x, y = gui.MousePos()
        dragPanel:SetPos(x - math.floor(w * 0.5), y - math.floor(h * 0.5))
    end

local PANEL = {}

INVENTORY_SLOT_COUNT = tonumber(INVENTORY_SLOT_COUNT) or 20
INVENTORY_SLOTS_PER_ROW = tonumber(INVENTORY_SLOTS_PER_ROW) or 5
local INVENTORY_REFRESH_SUPPRESS_REASONS = {
    ["use-click"] = true,
    ["dismantle-click"] = true,
    ["drop-click"] = true,
    ["refresh-ui-local"] = true,
}

local function ResolveInventoryItemDef(itemClass)
    if not itemClass or not Monarch or not Monarch.Inventory then
        return nil
    end

    local items = Monarch.Inventory.Items
    local refs = Monarch.Inventory.ItemsRef
    if not items then
        return nil
    end

    if refs and refs[itemClass] then
        local mappedClass = refs[itemClass]
        if mappedClass and items[mappedClass] then
            return items[mappedClass]
        end

        local mappedNum = tonumber(mappedClass)
        if mappedNum and items[mappedNum] then
            return items[mappedNum]
        end

        local mappedStr = tostring(mappedClass or "")
        if mappedStr ~= "" and items[mappedStr] then
            return items[mappedStr]
        end
    end

    if items[itemClass] then
        return items[itemClass]
    end

    local classNum = tonumber(itemClass)
    if classNum and items[classNum] then
        return items[classNum]
    end

    local classStr = tostring(itemClass)
    if classStr ~= "" and items[classStr] then
        return items[classStr]
    end

    return nil
end

function PANEL:ResolveItemDefinition(itemClass)
    return ResolveInventoryItemDef(itemClass)
end

function PANEL:IsEquipRefreshSuppressed(reason)
    return INVENTORY_REFRESH_SUPPRESS_REASONS[reason] == true
end

function PANEL:RestoreItemSelection(selectedSlot)
    local slotToRestore = selectedSlot or self.lastSelectedSlot
    if not slotToRestore then
        return
    end

    local slot = self.inventorySlots and self.inventorySlots[slotToRestore]
    if IsValid(slot) and IsValid(slot.ItemPanel) then
        self:ShowItemInfo(slot.ItemPanel)
        return
    end

    if self.ClearItemSelection then
        self:ClearItemSelection()
    end
end

function PANEL:OnRemove()

    Monarch_CleanupDrag()
    if self._miniForLoot then

        if gui and gui.EnableScreenClicker then gui.EnableScreenClicker(false) end
    end
end

do
    local registerUseful = Monarch.LoadFile("modules/interfaces/inventory/cl_util.lua")
    if isfunction(registerUseful) then
        registerUseful()
    end

    local registerMainUI = Monarch.LoadFile("modules/interfaces/inventory/cl_main.lua")
    if isfunction(registerMainUI) then
        registerMainUI(PANEL)
    end

    local registerInventoryTab = Monarch.LoadFile("modules/interfaces/inventory/tabs/cl_inv_tab.lua")
    if isfunction(registerInventoryTab) then
        registerInventoryTab(PANEL)
    end

    local registerSkillsTab = Monarch.LoadFile("modules/interfaces/inventory/tabs/cl_skills_tab.lua")
    if isfunction(registerSkillsTab) then
        registerSkillsTab(PANEL)
    end

    local registerSettingsTab = Monarch.LoadFile("modules/interfaces/inventory/tabs/cl_settings_tab.lua")
    if isfunction(registerSettingsTab) then
        registerSettingsTab(PANEL)
    end

    local registerCommunityTab = Monarch.LoadFile("modules/interfaces/inventory/tabs/cl_community_tab.lua")
    if isfunction(registerCommunityTab) then
        registerCommunityTab(PANEL)
    end

    local registerFactionsTab = Monarch.LoadFile("modules/interfaces/inventory/tabs/cl_factions_tab.lua")
    if isfunction(registerFactionsTab) then
        registerFactionsTab(PANEL)
    end
end

vgui.Register("MonarchInventory", PANEL, "EditablePanel")


local function Monarch_OpenLootUI(ent, contents, title, capacityArg, canStore, capXArg, capYArg, readOnly)
    local capacity = tonumber(capacityArg) or 0
    local capX = tonumber(capXArg) or 0
    local capY = tonumber(capYArg) or 0
    if capX > 0 and capY > 0 then
        capacity = capX * capY
    end
    if capacity <= 0 then
        capacity = 20 
        if capX <= 0 then capX = 5 end
        if capY <= 0 then capY = 4 end
    end
    local canStoreHere = canStore == true
    local invPanel
    if Monarch_FindInventoryPanel then
        invPanel = Monarch_FindInventoryPanel()
    end
    if not IsValid(invPanel) then
        local createdMini = true

        local world = vgui.GetWorldPanel()
        if IsValid(world) then
            for _, child in ipairs(world:GetChildren()) do
                if child.ClassName == "MonarchInventory" and child.SetupItems then invPanel = child break end
            end
        end
        if not IsValid(invPanel) then
            invPanel = vgui.Create("MonarchInventory")

            invPanel.keyMonitor = false
            invPanel._miniForLoot = true

            if not invPanel._origPaint then invPanel._origPaint = invPanel.Paint end
            invPanel.disableBackground = false 
            invPanel.Paint = function(self, w, h)
                if not self.disableBackground and self._origPaint then
                    self:_origPaint(w, h)
                end
            end

            invPanel:SetMouseInputEnabled(true)
            invPanel:SetKeyboardInputEnabled(true)
            if IsValid(invPanel.contentPanel) then
                invPanel.contentPanel:SetMouseInputEnabled(true)
                invPanel.contentPanel:SetKeyboardInputEnabled(true)
            end
            if gui and gui.EnableScreenClicker then gui.EnableScreenClicker(true) end

            if IsValid(invPanel.statusPanel) then invPanel.statusPanel:SetVisible(false) end
            if IsValid(invPanel.tabPanel) then invPanel.tabPanel:SetVisible(false) end

            if invPanel.ShowTab then invPanel:ShowTab(1) end
        end
    end
    if IsValid(invPanel._lootPanel) then invPanel._lootPanel:Remove() end

    if IsValid(invPanel.infoCard) then invPanel.infoCard:SetVisible(false) end
    invPanel._suppressInfoCard = true

    local parent = invPanel.contentPanel or invPanel
    local lootPanel = vgui.Create("DPanel", parent)
    lootPanel:SetKeyboardInputEnabled(true)
    lootPanel:SetMouseInputEnabled(true)
    local slotSize = MONARCH_INV_SLOT_SIZE
    local spacing = MONARCH_INV_SLOT_SPACING
    local cols = (capX > 0 and capX) or 5
    local headerH = 0 
    local sidePadding = 10
    local panelW = cols * slotSize + (cols - 1) * spacing + sidePadding * 2
    local panelTop = Scale(10)
    lootPanel:SetPos(Scale(520), panelTop)
    local maxPanelH = 540
    if IsValid(parent) then
        maxPanelH = math.max(280, parent:GetTall() - panelTop - Scale(10))
    end
    lootPanel:SetSize(panelW, maxPanelH)
    lootPanel.Paint = function() end 

    local btnClose = vgui.Create("DButton", lootPanel)
    btnClose:SetVisible(false) 
    local function CloseLoot()
        if IsValid(invPanel) and invPanel._lootClosing then return end
        if IsValid(invPanel) then invPanel._lootClosing = true end
        if IsValid(invPanel) and invPanel.HideItemHoverTooltip then
            invPanel:HideItemHoverTooltip()
        end

        local closeDur = INVENTORY_FADE_OUT_TIME

        local function DisableLootCursorState()
            if IsValid(invPanel) then
                invPanel:SetMouseInputEnabled(false)
                invPanel:SetKeyboardInputEnabled(false)
                if IsValid(invPanel.contentPanel) then
                    invPanel.contentPanel:SetMouseInputEnabled(false)
                    invPanel.contentPanel:SetKeyboardInputEnabled(false)
                end
            end
            if gui and gui.EnableScreenClicker then
                gui.EnableScreenClicker(false)
            end
        end

        local function FinishLootCleanup()
            if IsValid(invPanel) and IsValid(invPanel._lootPanel) then
                invPanel._lootPanel:Remove()
            end

            if IsValid(invPanel) then
                invPanel._suppressInfoCard = nil
                invPanel._lootGrid = nil
                invPanel._lootEnt = nil
                invPanel._lootCapacity = nil
                invPanel._lootContentsRef = nil
                invPanel._lootReadOnly = nil
                invPanel._lootClosing = nil
                if IsValid(invPanel._lootWarningLabel) then invPanel._lootWarningLabel:Remove() invPanel._lootWarningLabel = nil end
            end
        end

        if IsValid(invPanel) and IsValid(invPanel._lootEnt) then
            local ent = invPanel._lootEnt
            if ent.GetLootDef then
                local def = ent:GetLootDef()
            end
        end

        if IsValid(invPanel) and IsValid(invPanel._lootCloseBtn) then
            invPanel._lootCloseBtn:SetVisible(false)
        end

        if IsValid(invPanel) and IsValid(invPanel._lootPanel) then
            local lp = invPanel._lootPanel
            local sx, sy = lp:GetPos()
            lp:MoveTo(sx + Scale(30), sy, closeDur, 0)
            lp:AlphaTo(0, closeDur, 0, function()
                if IsValid(invPanel) and not invPanel._miniForLoot then
                    FinishLootCleanup()
                end
            end)
        end

        if IsValid(invPanel) and invPanel._miniForLoot then
            FinishLootCleanup()
            DisableLootCursorState()

            if invPanel.AnimateClose then
                invPanel:AnimateClose()
            else
                invPanel:AlphaTo(0, closeDur, 0, function()
                    if IsValid(invPanel) then invPanel:Remove() end
                end)
            end

            if gui and gui.EnableScreenClicker then
                timer.Simple(closeDur, function()
                    gui.EnableScreenClicker(false)
                end)
            end
        end
    end
    btnClose.DoClick = CloseLoot

    lootPanel.OnKeyCodePressed = function(s, key)
        if key == KEY_ESCAPE then
            CloseLoot()
        end
    end

    if IsValid(invPanel) and invPanel._miniForLoot then
        if IsValid(btnClose) then btnClose:SetVisible(false) end
        if not IsValid(invPanel._lootCloseBtn) then
            local closeBtn = vgui.Create("DButton", invPanel)
            closeBtn:SetSize(24, 30)
            closeBtn:SetText("CLOSE ✕")
            closeBtn:SetFont("InvSmall")
            closeBtn:SetTextColor(Color(255,255,255))
            closeBtn:SizeToContentsX()
            closeBtn.Paint = function(s, w, h)
                local hovered = s:IsHovered()
                local col = hovered and Color(90,90,90, 200) or Color(40,40,40, 3)
                surface.SetDrawColor(col)
                surface.DrawRect(0, 0, w, h)
            end
            closeBtn.DoClick = CloseLoot

            closeBtn.Think = function(s)
                if not IsValid(invPanel) then return end
                local pw, ph = invPanel:GetSize()
                s:SetPos(pw - s:GetWide() - 12, 10)
            end
            invPanel._lootCloseBtn = closeBtn
        else
            invPanel._lootCloseBtn:SetVisible(true)
            invPanel._lootCloseBtn.DoClick = CloseLoot
        end

        invPanel.OnKeyCodePressed = function(p, key)
            if key == KEY_ESCAPE then
                CloseLoot()
            end
        end
    end

    local lootTitleShadow = vgui.Create("DLabel", lootPanel)
    local lootTitle = vgui.Create("DLabel", lootPanel)
    local uiTitle = (IsValid(ent) and ent.GetLootName and ent:GetLootName() ~= "" and ent:GetLootName()) or (title ~= "" and title or "Loot")
    lootTitleShadow:SetText(string.upper(uiTitle))
    lootTitleShadow:SetFont("Inventory_Title")
    lootTitleShadow:SetColor(Color(0, 0, 0, 250))
    lootTitleShadow:SizeToContents()
    lootTitle:SetText(string.upper(uiTitle))
    lootTitle:SetFont("Inventory_Title")
    lootTitle:SetColor(Color(185, 185, 185))
    lootTitle:SizeToContents()

    local lootWarnH = 68
    local lootDividerGap = Scale(6)
    local lootWarnTopGap = Scale(8)
    local lootBottomPadding = Scale(8)

    local gridTop
    do
        local invTopLocal
        if IsValid(invPanel) and IsValid(invPanel.invGrid) then
            local sx, sy = invPanel.invGrid:LocalToScreen(0, 0)
            local px, py = lootPanel:GetParent():ScreenToLocal(sx, sy)
            invTopLocal = py - lootPanel:GetY()
        end
        local defaultTop = Scale(80)
        gridTop = invTopLocal and math.max(defaultTop, invTopLocal) or defaultTop
    end
    local gridScroll = vgui.Create("DScrollPanel", lootPanel)
    gridScroll:SetSize(lootPanel:GetWide() - sidePadding * 2, lootPanel:GetTall() - gridTop - lootWarnH - 16)
    gridScroll:SetPos(sidePadding, gridTop)
    local vbar = gridScroll:GetVBar()
    if IsValid(vbar) then
        vbar:SetWide(6)
        function vbar:Paint(w, h)
            surface.SetDrawColor(0, 0, 0, 120)
            surface.DrawRect(0, 0, w, h)
        end
        function vbar.btnUp:Paint(w, h) end
        function vbar.btnDown:Paint(w, h) end
        function vbar.btnGrip:Paint(w, h)
            local col = self:IsHovered() and Color(140, 140, 140, 200) or Color(100, 100, 100, 160)
            surface.SetDrawColor(col)
            surface.DrawRect(0, 2, w, h - 4)
        end
    end
    local grid = gridScroll:GetCanvas()
    function grid:Paint() end
    invPanel._lootGrid = grid
    invPanel._lootEnt = ent
    invPanel._lootCapacity = capacity
    invPanel._lootContentsRef = contents
    invPanel._lootCanStore = canStoreHere
    invPanel._lootReadOnly = readOnly == true

    lootTitle:SizeToContents()
    local lootIconSize = Scale(55)
    local titleMargin = Scale(-8)
    local iconSpacing = Scale(4)

    local totalWidth = lootIconSize + iconSpacing + lootTitle:GetWide()
    local lx = sidePadding + (gridScroll:GetWide() - totalWidth) * 0.5 + lootIconSize + iconSpacing
    local ly = gridTop - lootTitle:GetTall() - titleMargin

    if IsValid(invPanel) and invPanel._invTitleBaseline then
        ly = invPanel._invTitleBaseline
    end
    local titleX = math.floor(lx)
    local titleY = math.floor(ly) + Scale(8)
    lootTitle:SetPos(titleX, titleY)
    lootTitleShadow:SetPos(titleX + 2, titleY + 2)

    local lootIcon = vgui.Create("DImage", lootPanel)
    lootIcon:SetImage("mrp/radar/blip_box.png")
    lootIcon:SetSize(lootIconSize, lootIconSize)
    lootIcon:SetImageColor(Color(185, 185, 185))
    lootIcon:SetPos(lootTitle:GetX() - lootIconSize - iconSpacing, lootTitle:GetY() + (lootTitle:GetTall() - lootIconSize) * 0.5 - Scale(0))

    local lootDividerH = math.max(1, Scale(2))
    local gradLeft = Material("vgui/gradient-l")
    local lootDivider = vgui.Create("DPanel", lootPanel)
    lootDivider:SetSize(lootPanel:GetWide() - sidePadding * 2, lootDividerH)
    lootDivider.Paint = function(_, pw, ph)
        if gradLeft then
            surface.SetMaterial(gradLeft)
            surface.SetDrawColor(100,100,100, 155)
            surface.DrawTexturedRect(0, 0, pw, ph)
        end
    end
    lootDivider:SetZPos(999)

    local lootWarn = vgui.Create("DPanel", lootPanel)
    lootWarn:SetVisible(true)
    lootWarn:SetSize(lootPanel:GetWide() - sidePadding * 2, lootWarnH)

    local currentLootRows = 0
    local function UpdateLootLayout(rows)
        currentLootRows = tonumber(rows) or currentLootRows or 0

        local availableGridH = lootPanel:GetTall() - gridTop - lootDividerGap - lootDividerH - lootWarnTopGap - lootWarnH - lootBottomPadding
        availableGridH = math.max(slotSize, availableGridH)

        local contentH = 0
        if currentLootRows > 0 then
            contentH = currentLootRows * slotSize + (currentLootRows - 1) * spacing
        end
        local targetGridH = math.Clamp(contentH, slotSize, availableGridH)

        gridScroll:SetPos(sidePadding, gridTop)
        gridScroll:SetSize(lootPanel:GetWide() - sidePadding * 2, targetGridH)

        local dividerY = gridTop + targetGridH + lootDividerGap
        lootDivider:SetPos(sidePadding, dividerY)
        lootDivider:SetSize(lootPanel:GetWide() - sidePadding * 2, lootDividerH)

        local warnY = dividerY + lootDividerH + lootWarnTopGap
        lootWarn:SetPos(sidePadding, warnY)
        lootWarn:SetSize(lootPanel:GetWide() - sidePadding * 2, lootWarnH)
    end

    local gradMat2 = Material("vgui/gradient-l")
    local iconMat2 = Material("mrp/icons/backpack.png", "smooth")
    lootWarn.Paint = function(s, pw, ph)
        surface.SetDrawColor(28, 28, 28, 105)
        if gradMat2 then
            surface.SetMaterial(gradMat2)
            surface.SetDrawColor(100, 28, 28, 105)
            surface.DrawTexturedRect(0, 0, pw, ph)
        end
        local pad = 12
        local iconSize = ph - pad * 2
        if iconMat2 then
            surface.SetMaterial(iconMat2)
            surface.SetDrawColor(255, 80, 80)
            surface.DrawTexturedRect(pad, pad, iconSize, iconSize)
            surface.SetMaterial(iconMat2)
            surface.SetDrawColor(0, 0, 0,160)
            surface.DrawTexturedRect(pad+2, pad+2, iconSize, iconSize)
        end
        local msg = "You cannot place items in this container."
        surface.SetFont("InvMed")
        local tw, th = surface.GetTextSize(msg)
        local tx = pad * 2 + iconSize
        local ty = math.floor((ph - th) * 0.5)
        draw.SimpleText(msg, "InvMed", tx+1, ty+1, Color(0,0,0,160), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(msg, "InvMed", tx, ty, Color(255, 80, 80), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(255, 140, 140, 200)
    end
    lootWarn.Think = function(s)

        if not IsValid(invPanel) or not IsValid(lootPanel) then return end
        local ent = invPanel._lootEnt
        local shouldShow = false
        if IsValid(ent) and ent.GetStoreable then

            local storeable = ent:GetStoreable()
            shouldShow = (storeable == false)
        else

            shouldShow = (invPanel._lootReadOnly ~= true) and (invPanel._lootCanStore == false)
        end
        s:SetVisible(shouldShow)
        if not shouldShow then return end
        s:SetZPos(1000)
        s:MoveToFront()
    end

    lootPanel.Think = function(s)
        if not IsValid(gridScroll) then return end
        if s._lastW ~= s:GetWide() or s._lastH ~= s:GetTall() then
            s._lastW, s._lastH = s:GetWide(), s:GetTall()
            UpdateLootLayout(currentLootRows)
        end
    end

    local function ResolveDef(class)
        local ref = Monarch and Monarch.Inventory and Monarch.Inventory.ItemsRef or {}
        local defs = Monarch and Monarch.Inventory and Monarch.Inventory.Items or {}
        local key = ref[class] or class
        return defs[key]
    end

    local function IsLootSlotDragHovered(slotPanel)
        local isDragging, draggedItem = Monarch_GetDragState()
        if not (isDragging and IsValid(draggedItem) and IsValid(slotPanel)) then
            return false
        end

        local mouseX, mouseY = gui.MousePos()
        local slotX, slotY = slotPanel:LocalToScreen(0, 0)
        local slotW, slotH = slotPanel:GetSize()
        local tolerance = 10

        return mouseX >= (slotX - tolerance) and mouseX <= (slotX + slotW + tolerance)
            and mouseY >= (slotY - tolerance) and mouseY <= (slotY + slotH + tolerance)
    end

    local function MakeCard(i, itm)
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        local slot = vgui.Create("DPanel", grid)
        slot:SetSize(slotSize, slotSize)
        slot:SetPos(col * (slotSize + spacing), row * (slotSize + spacing))
        slot.LootSlotID = i
        slot:SetCursor("hand")
        slot.HasItem = true
        slot.ItemData = itm
        slot.ClickAlpha = 0
        slot._isClicked = false
        slot.HoverAlpha = 0
        slot._wasHovered = false

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

        slot.Paint = function(s, w, h)
            local baseR, baseG, baseB = 28, 28, 28
            local hoverR, hoverG, hoverB = 45, 45, 45
            local alpha = 230

            local isDropTarget = IsLootSlotDragHovered(s)
            if isDropTarget then
                baseR, baseG, baseB = 220, 220, 220
                alpha = 40
            end

            local hoverFactor = math.Clamp((s.HoverAlpha or 0) / 100, 0, 1)
            local r = Lerp(hoverFactor, baseR, hoverR)
            local g = Lerp(hoverFactor, baseG, hoverG)
            local b = Lerp(hoverFactor, baseB, hoverB)

            local bgColor = Color(r, g, b, alpha)
            DrawRoundedRect(0, 0, w, h, 3, bgColor)

            if s.ClickAlpha and s.ClickAlpha > 1 then
                local clickColor = Color(100, 100, 100, math.floor(s.ClickAlpha))
                DrawRoundedRect(0, 0, w, h, 3, clickColor)
            end

            local bcol = COL_INV_BORDER
            local d = s._LootItemDef
            local itemRestricted = itm and itm.restricted or false
            if d and d.Illegal then
                bcol = COL_INV_BORDER_ILLEGAL
            elseif itemRestricted or (d and (d.Restricted or d.restricted)) then
                bcol = COL_INV_BORDER_RESTRICTED
            end

            if MAT_INV_BORDER then
                surface.SetMaterial(MAT_INV_BORDER)
                surface.SetDrawColor(bcol)
                surface.DrawTexturedRect(0, 0, w, h)
            end
        end

        local def = ResolveDef(itm.id or "")
        slot._LootItemDef = def
        local mdlPath = (def and (def.Model or def.model)) or "models/props_junk/cardboard_box004a.mdl"
        local name = (def and (def.Name or def.name)) or (itm.id or "Item")

        local item = vgui.Create("DPanel", slot)
        item:SetSize(slot:GetWide() - 4, slot:GetTall() - 4)
        item:SetPos(2, 2)
        item:SetMouseInputEnabled(true)
        item:SetCursor("hand")
        item.ItemDef = def
        item.ItemData = itm
        item.ItemClass = itm.id
        item.InvPanel = invPanel
        item.HoverAlpha = 0
        item.HoverScale = 1
        item.ClickScale = 1
        item._wasHovered = false

        local amt = tonumber(itm.amount) or 1
        item.Paint = function(itemSelf, w, h)
            local scale = math.Clamp((itemSelf.HoverScale or 1) * (itemSelf.ClickScale or 1), 0.85, 1.15)
            local sw, sh = math.floor(w * scale), math.floor(h * scale)
            local sx, sy = math.floor((w - sw) * 0.5), math.floor((h - sh) * 0.5)

            if amt > 1 then
                local txt = tostring(amt)
                surface.SetFont("InvStackSmall")
                local x, y = sx + 6, sy + 4
                draw.SimpleTextOutlined(txt, "InvStackSmall", x, y, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1, Color(0,0,0,180))
            end
        end

        local model = vgui.Create("SpawnIcon", item)
        local baseModelW = item:GetWide() - 10
        local baseModelH = item:GetTall() - 25
        model:SetSize(baseModelW, baseModelH)
        model:SetPos(5, 5)
        model:SetMouseInputEnabled(false)
        model:SetKeyboardInputEnabled(false)
        model:SetModel(mdlPath)

        local click = vgui.Create("DButton", item)
        click:SetText("")
        click:Dock(FILL)
        click:SetAlpha(0)
        click.Paint = function() end
        click.DoClick = function()
            if invPanel and invPanel._lootReadOnly then return end
            if IsValid(invPanel) then invPanel._suppressInfoCard = true end
            net.Start("Monarch_Loot_Take")
                net.WriteEntity(ent)
                net.WriteUInt(i, 8)
            net.SendToServer()
        end

        click.dragStartTime = 0
        click.dragStartPos = nil
        click.isDragActive = false
        click.OnMousePressed = function(p, key)
            if key == MOUSE_LEFT then
                slot._isClicked = true
                p.dragStartTime = CurTime()
                p.dragStartPos = {gui.MousePos()}
            end
        end
        click.OnMouseReleased = function(p, key)
            if key ~= MOUSE_LEFT then return end
            slot._isClicked = false
            if p.isDragActive then

            else

                p:DoClick()
            end
            p.dragStartTime = 0
            p.dragStartPos = nil
            p.isDragActive = false
        end
        click.Think = function(p)
            local hovered = item:IsHovered() or p:IsHovered()
            slot.HoverAlpha = hovered and 100 or 0
            slot.ClickAlpha = slot._isClicked and 80 or 0

            if IsValid(invPanel) and invPanel.ShowItemHoverTooltip then
                local isDragging = Monarch_GetDragState()
                if hovered and not isDragging and not p.isDragActive then
                    invPanel:ShowItemHoverTooltip(item)
                else
                    invPanel:HideItemHoverTooltip(item)
                end
            end

            if hovered and not slot._wasHovered then
                surface.PlaySound(INV_HOVER_SOUND)
                slot._wasHovered = true
            elseif not hovered then
                slot._wasHovered = false
            end

            item.HoverAlpha = hovered and 100 or 0
            item.HoverScale = hovered and 1.08 or 1.0
            item.ClickScale = (input.IsMouseDown(MOUSE_LEFT) and hovered) and 0.85 or 1.0

            local combinedScale = math.Clamp((item.HoverScale or 1) * (item.ClickScale or 1), 0.85, 1.15)
            local sw, sh = math.floor(baseModelW * combinedScale), math.floor(baseModelH * combinedScale)
            local mx = math.floor((item:GetWide() - sw) * 0.5)
            local my = math.floor((item:GetTall() - sh) * 0.5)
            if IsValid(model) then
                model:SetSize(sw, sh)
                model:SetPos(mx, my)
            end

            if p.dragStartTime > 0 and input.IsMouseDown(MOUSE_LEFT) and p.dragStartPos then
                if invPanel and invPanel._lootReadOnly then
                    p.dragStartTime = 0
                    p.dragStartPos = nil
                    return
                end
                if not p.isDragActive and CurTime() - p.dragStartTime > 0.15 then
                    local cur = {gui.MousePos()}
                    local dist = math.sqrt((cur[1]-p.dragStartPos[1])^2 + (cur[2]-p.dragStartPos[2])^2)
                    if dist > 10 then
                        p.isDragActive = true
                        Monarch_SetDragState(true, p, p.dragStartPos)
                        local fov = Monarch.GetItemModelFOV(def, 35)
                        Monarch_CreateDragPanelForLoot(mdlPath, name .. (itm.amount and (" x"..itm.amount) or ""), slot:GetWide(), slot:GetTall(), fov)
                    end
                end
            end

            if p.isDragActive and not input.IsMouseDown(MOUSE_LEFT) then

                if invPanel and invPanel._lootReadOnly then
                    Monarch_CleanupDrag()
                    Monarch_SetDragState(false, nil, nil)
                    p.isDragActive = false
                    p.dragStartTime = 0
                    p.dragStartPos = nil
                    return
                end

                local mouseX, mouseY = gui.MousePos()
                local foundSlot = nil
                for _, slotP in ipairs(invPanel.inventorySlots or {}) do
                    if IsValid(slotP) then
                        local sx, sy = slotP:LocalToScreen(0,0)
                        local sw, sh = slotP:GetSize()
                        if mouseX >= sx and mouseX <= sx + sw and mouseY >= sy and mouseY <= sy + sh then
                            foundSlot = slotP
                            break
                        end
                    end
                end
                if foundSlot and foundSlot.SlotID then
                    net.Start("Monarch_Loot_TakeToSlot")
                        net.WriteEntity(ent)
                        net.WriteUInt(i, 8)
                        net.WriteUInt(foundSlot.SlotID, 8)
                    net.SendToServer()
                    surface.PlaySound("willardnetworks/inventory/inv_move1.wav")
                end
                Monarch_CleanupDrag()
                Monarch_SetDragState(false, nil, nil)
                p.isDragActive = false
                p.dragStartTime = 0
                p.dragStartPos = nil
            end
        end
    end

    local function Rebuild()
        grid:Clear()
        local total = #contents
        local maxTiles = math.max(total, capacity)
        local rows = math.ceil(maxTiles / cols)
        for i = 1, maxTiles do
            local itm = contents[i]
            if itm then
                MakeCard(i, itm)
            else
                local row = math.floor((i - 1) / cols)
                local col = (i - 1) % cols
                local slot = vgui.Create("DPanel", grid)
                slot:SetSize(slotSize, slotSize)
                slot:SetPos(col * (slotSize + spacing), row * (slotSize + spacing))
                slot.LootSlotID = i
                slot:SetCursor("hand")
                slot.HasItem = false
                slot.ClickAlpha = 0
                slot._isClicked = false
                slot.HoverAlpha = 0
                slot._wasHovered = false

                slot.OnMousePressed = function(slotSelf, mouseCode)
                    if mouseCode == MOUSE_LEFT then
                        slotSelf._isClicked = true
                        slotSelf.ClickStartTime = CurTime()
                    end
                end

                slot.OnMouseReleased = function(slotSelf, mouseCode)
                    if mouseCode ~= MOUSE_LEFT then return end
                    slotSelf._isClicked = false

                    if not slotSelf:IsHovered() then return end
                    if not IsValid(invPanel) then return end

                    invPanel.lastSelectedSlot = nil
                    if invPanel.ClearItemSelection then
                        invPanel:ClearItemSelection()
                    end
                end

                slot.Think = function(s)
                    local hovered = s:IsHovered()
                    s.HoverAlpha = hovered and 100 or 0

                    if s._isClicked then
                        s.ClickAlpha = 80
                    else
                        s.ClickAlpha = 0
                    end

                    if hovered and not s._wasHovered then
                        surface.PlaySound(INV_HOVER_SOUND)
                        s._wasHovered = true
                    elseif not hovered then
                        s._wasHovered = false
                    end
                end

                slot.Paint = function(s, w, h)
                    local isDropTarget = IsLootSlotDragHovered(s)
                    local hoverFactor = math.Clamp((s.HoverAlpha or 0) / 100, 0, 1)
                    local r = Lerp(hoverFactor, 28, 45)
                    local g = Lerp(hoverFactor, 28, 45)
                    local b = Lerp(hoverFactor, 28, 45)
                    local a = 230
                    if isDropTarget then
                        r, g, b, a = 220, 220, 220, 40
                    end
                    DrawRoundedRect(0, 0, w, h, 3, Color(r, g, b, a))

                    if s.ClickAlpha and s.ClickAlpha > 1 then
                        DrawRoundedRect(0, 0, w, h, 3, Color(100, 100, 100, math.floor(s.ClickAlpha)))
                    end

                    if MAT_INV_BORDER then
                        surface.SetMaterial(MAT_INV_BORDER)
                        surface.SetDrawColor(COL_INV_BORDER)
                        surface.DrawTexturedRect(0, 0, w, h)
                    end
                end
            end
        end
        local h = 0
        if rows > 0 then
            h = rows * slotSize + (rows - 1) * spacing
        end
        grid:SetSize(gridScroll:GetWide(), h)
        UpdateLootLayout(rows)
        if IsValid(invPanel) and IsValid(invPanel._lootWarningLabel) then invPanel._lootWarningLabel:InvalidateLayout(true) end
    end

    invPanel._lootPanel = lootPanel
    invPanel:MoveToFront()
    Rebuild()

    net.Receive("Monarch_Loot_Update", function()
        local updEnt = net.ReadEntity()
        local tbl = net.ReadTable() or {}
        if IsValid(invPanel) and IsValid(invPanel._lootPanel) and IsValid(updEnt) and updEnt == ent then
            contents = tbl
            Rebuild()
        end
    end)
end

net.Receive("Monarch_Loot_Open", function()
    local ent = net.ReadEntity()
    local contents = net.ReadTable() or {}
    local title = net.ReadString() or "Loot"
    local cap = 0
    local ok, err = pcall(function()
        cap = net.ReadUInt(12) or 0
    end)
    if not ok then cap = 0 end
    local canStore = true
    local ok2 = pcall(function()
        canStore = net.ReadBool()
    end)
    if not ok2 then canStore = true end
    local capX, capY = 0, 0
    local ok3 = pcall(function()
        capX = net.ReadUInt(8) or 0
        capY = net.ReadUInt(8) or 0
    end)
    Monarch_OpenLootUI(ent, contents, title, cap, canStore, capX, capY)
end)

net.Receive("Monarch_Loot_PutResult", function()
    local success = net.ReadBool()
    if success then
        surface.PlaySound("willardnetworks/inventory/inv_move1.wav")
    else
        surface.PlaySound("ui/hls_ui_denied.wav")
    end
end)

net.Receive("Monarch_Loot_BeginOpen", function()
    local ent = net.ReadEntity()
    local dur = net.ReadFloat() or 0
    local label = net.ReadString() or "Opening..."
    if dur <= 0 or not IsValid(ent) then return end

    local invPanel = Monarch_FindInventoryPanel and Monarch_FindInventoryPanel() or nil
    if IsValid(invPanel) and invPanel.HideInfoCard then invPanel:HideInfoCard() end
    Monarch_ShowUseBar(vgui.GetWorldPanel() or nil, dur, label, function()

    end)
end)


end