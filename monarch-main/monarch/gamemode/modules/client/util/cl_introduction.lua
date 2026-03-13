Monarch = Monarch or {}
Monarch.Introductions = Monarch.Introductions or {}

local knownPlayers = {}

local CM = {
    panel = nil,
    target = nil,
    options = {},
    fade = 0,
    closing = false,
    hovered = 0,
    iconSizes = {},
    textSizes = {},
    scroll = 0,
    scrollTarget = 0,
    focused = 0,
}
hook.Remove("GUIMousePressed", "Monarch_ContextMenuClicks")
hook.Remove("Think", "Monarch_ContextMenuInput")
hook.Remove("HUDPaint", "Monarch_DrawContextMenu")
hook.Remove("HUDPaint", "Monarch_DrawEHoldProgress")
hook.Remove("PlayerButtonDown", "Monarch_ContextMenuClicks")

surface.CreateFont("Monarch_ContextMenu_Title", { font = "Arial", size = 20, weight = 500, antialias = true })
local createdFonts = {}
local function ScaledFont(size)
    local key = "Monarch_CM_" .. math.floor(size)
    if not createdFonts[key] then
        surface.CreateFont(key, { font = "Arial", size = math.Clamp(math.floor(size), 8, 72), weight = size > 20 and 600 or 400, antialias = true })
        createdFonts[key] = true
    end
    return key
end

local optionIcon = Material((Config and Config.InteractionMenuOptionsMat) or "icons/dropdown/option_icon.png", "mips smooth")

local CONTEXT_ENTITY_CLASS_ALLOWLIST = {
    ["ammobox"] = true,
    ["hl2rp_bed"] = true,
    ["hl2rp_couch"] = true,
    ["hl2rp_mattress"] = true,
    ["item"] = true,
    ["monarch_atm"] = true,
    ["monarch_bodygroup_closet"] = true,
    ["monarch_computer"] = true,
    ["monarch_craftingbench"] = true,
    ["monarch_loot"] = true,
    ["monarch_ocman"] = true,
    ["monarch_rankvendor"] = true,
    ["monarch_storage"] = true,
    ["monarch_vehiclevendor"] = true,
    ["monarch_vendor"] = true,
    ["radio"] = true,
    ["ration_terminal"] = true,
    ["rp_bed"] = true,
    ["rp_monarch_container"] = true,
    ["rp_monarch_disassemblytable"] = true,
    ["rp_monarch_extractiontable"] = true,
    ["rp_monarch_factory"] = true,
    ["rp_monarch_fuelcontainer"] = true,
    ["rp_monarch_materials"] = true,
    ["rp_monarch_oilcontainer"] = true,
    ["rp_monarch_packagingbench"] = true,
    ["rp_monarch_partscontainer"] = true,
    ["rp_monarch_product"] = true,
    ["rp_monarch_shipmentcontainer"] = true,
    ["rp_sink"] = true
}

local CONTEXT_ENTITY_CLASS_PREFIXES = {
    "monarch_",
    "rp_monarch_",
    "hl2rp_"
}

local CONTEXT_ENTITY_CLASS_BLOCKLIST = {
    ["monarch_craftingbench"] = true
}

local function IsContextEntityClass(className)
    if not isstring(className) or className == "" then return false end
    if CONTEXT_ENTITY_CLASS_BLOCKLIST[className] then return false end
    if CONTEXT_ENTITY_CLASS_ALLOWLIST[className] then return true end

    for _, prefix in ipairs(CONTEXT_ENTITY_CLASS_PREFIXES) do
        if string.StartWith(className, prefix) then
            return true
        end
    end

    return false
end

local function ShouldShowEntityContext(ent, activator)
    if not IsValid(ent) or not IsContextEntityClass(ent:GetClass()) then
        return false
    end

    local rule = ent.ShouldShowContext
    if isbool(rule) then
        return rule
    end

    if isfunction(rule) then
        local ok, result = pcall(rule, ent, activator)
        return ok and result == true
    end

    return false
end

local function GetContextAnchorPos(ent, activator)
    if not IsValid(ent) then return nil end

    local anchorPos = ent:GetPos()
    if not IsValid(activator) or not ent.GetFenceA or not ent.GetFenceB then
        return anchorPos
    end

    local fenceA = ent:GetFenceA()
    local fenceB = ent:GetFenceB()
    local activatorPos = activator:GetPos()
    local bestDist = math.huge

    if IsValid(fenceA) then
        local dist = activatorPos:DistToSqr(fenceA:GetPos())
        if dist < bestDist then
            bestDist = dist
            anchorPos = fenceA:GetPos()
        end
    end

    if IsValid(fenceB) then
        local dist = activatorPos:DistToSqr(fenceB:GetPos())
        if dist < bestDist then
            anchorPos = fenceB:GetPos()
        end
    end

    return anchorPos
end

local function CanHoldUseTarget(lp, ent)
    if not (IsValid(lp) and IsValid(ent)) then return false end
    local anchorPos = GetContextAnchorPos(ent, lp)
    if not anchorPos or lp:GetPos():DistToSqr(anchorPos) > (100 * 100) then return false end

    if ent:IsPlayer() then
        return ent ~= lp
    end

    if ent:GetClass() == "prop_ragdoll" then
        return true
    end

    return ShouldShowEntityContext(ent, lp)
end

local isHoldingE, holdStart, holdThreshold = false, 0, 0.5

function Monarch.Introductions.GetDisplayName(ply)
    if not IsValid(ply) then return "Unrecognized" end
    if ply == LocalPlayer() then return ply.GetRPName and (ply:GetRPName() or ply:Nick()) or ply:Nick() end
    return knownPlayers[ply] or "Unrecognized"
end

net.Receive("Monarch_UpdateIntroductions", function()
    local target = net.ReadEntity()
    local knownName = net.ReadString()
    if IsValid(target) then
        knownPlayers[target] = knownName
    end
end)

local function OpenContextOverlay()
    if IsValid(CM.panel) then return end
    CM.fade = 0
    CM.closing = false
    CM.hovered = 0
    CM.iconSizes = {}
    CM.textSizes = {}
    CM.scroll = 1
    CM.scrollTarget = 1
    CM.focused = 1

    local pnl = vgui.Create("EditablePanel")
    CM.panel = pnl
    pnl:SetSize(ScrW(), ScrH())
    pnl:SetPos(0, 0)
    pnl:SetKeyboardInputEnabled(true)
    pnl:SetMouseInputEnabled(true)
    pnl:MakePopup()
    pnl:SetCursor("blank")
    if surface and surface.SetCursor then
        surface.SetCursor("blank")
    end
    isHoldingE = false

    function pnl:OnKeyCodePressed(code)
        if code == KEY_ESCAPE then
            CM.closing = true
        end
    end

    function pnl:OnMouseReleased(mc)
        if mc == MOUSE_RIGHT then
            CM.closing = true
            return
        end
        if mc ~= MOUSE_LEFT then return end
        local idx = CM.focused
        local opt = CM.options[idx]
        if not opt then return end

        local clickSound = (Config and Config.InteractionMenuClick) or "mrp/ui/click.wav"
        surface.PlaySound(clickSound)

        if opt.action == "introduce_self" then
            CM.closing = true
            local targetEnt = CM.target
            timer.Simple(0.05, function()
                if not IsValid(targetEnt) then return end
                local defaultName = LocalPlayer().GetRPName and (LocalPlayer():GetRPName() or LocalPlayer():Nick()) or LocalPlayer():Nick()
                net.Start("Monarch_IntroducePlayer")
                net.WriteEntity(targetEnt)
                net.WriteString(defaultName)
                net.SendToServer()
            end)
        elseif opt.action == "take_pulse" then
            if not IsValid(CM.target) then return end
            net.Start("Monarch_Interact_Pulse")
                net.WriteEntity(CM.target)
            net.SendToServer()
            CM.closing = true
        elseif opt.action == "give_cash" then
            if not IsValid(CM.target) then return end
            local targetEnt = CM.target

            local dlg = vgui.Create("DFrame")
            dlg:SetSize(360, 180)
            dlg:Center()
            dlg:SetTitle("")
            dlg:ShowCloseButton(false)
            dlg:MakePopup()
            dlg.topBarH = 32

            if Monarch and Monarch.Theme and Monarch.Theme.AttachSkin then
                Monarch.Theme.AttachSkin(dlg)
            end

            local closeBtn = vgui.Create("DButton", dlg)
            closeBtn:SetText("X")
            closeBtn:SetTextColor(color_white)
            closeBtn:SetSize(28, 22)
            closeBtn:SetPos(dlg:GetWide() - 28 - 6, 6)
            closeBtn.DoClick = function() if IsValid(dlg) then dlg:Remove() end end

            local body = vgui.Create("DPanel", dlg)
            body:Dock(FILL)
            body:DockMargin(8, 32, 8, 8)
            body.Paint = nil

            local desc = vgui.Create("DLabel", body)
            desc:Dock(TOP)
            desc:DockMargin(0, 6, 0, 6)
            desc:SetText("Enter the amount to give to " .. (Monarch.Introductions.GetDisplayName(targetEnt) or targetEnt:Nick()) .. ":")
            desc:SetTextColor(color_white)
            desc:SetWrap(true)

            local amountEntry = vgui.Create("DTextEntry", body)
            amountEntry:Dock(TOP)
            amountEntry:SetTall(26)
            amountEntry:SetNumeric(true)
            amountEntry:SetUpdateOnType(false)
            amountEntry:SetText("")

            local actions = vgui.Create("DPanel", body)
            actions:Dock(BOTTOM)
            actions:SetTall(36)
            actions.Paint = nil

            local cancel = vgui.Create("DButton", actions)
            cancel:Dock(RIGHT)
            cancel:SetWide(90)
            cancel:SetText("Cancel")
            cancel:SetTextColor(color_white)
            cancel:DockMargin(6, 0, 0, 0)
            cancel.DoClick = function()
                if IsValid(dlg) then dlg:Remove() end
            end

            local confirm = vgui.Create("DButton", actions)
            confirm:Dock(RIGHT)
            confirm:SetWide(120)
            confirm:SetTextColor(color_white)
            confirm:SetText("Give Money")

            local function doConfirm()
                if not IsValid(targetEnt) then if IsValid(dlg) then dlg:Remove() end return end
                local text = amountEntry:GetText() or ""
                local amount = tonumber(text)
                if not amount or amount <= 0 then
                    if LocalPlayer and LocalPlayer().Notify then LocalPlayer():Notify("Enter a valid amount.") end
                    return
                end
                amount = math.floor(amount)
                net.Start("Monarch_GiveMoney_Request")
                    net.WriteEntity(targetEnt)
                    net.WriteInt(amount, 32)
                net.SendToServer()
                if IsValid(dlg) then dlg:Remove() end
            end

            confirm.DoClick = doConfirm
            amountEntry.OnEnter = doConfirm

            amountEntry:RequestFocus()

            CM.closing = true
        elseif opt.action == "search_inventory" then
            if not IsValid(CM.target) then return end
            local targetEnt = CM.target

            -- Create inventory search dialog
            local dlg = vgui.Create("DFrame")
            dlg:SetSize(420, 400)
            dlg:Center()
            dlg:SetTitle("")
            dlg:ShowCloseButton(false)
            dlg:MakePopup()
            dlg.topBarH = 32

            if Monarch and Monarch.Theme and Monarch.Theme.AttachSkin then
                Monarch.Theme.AttachSkin(dlg)
            end

            -- Title label
            local titleLabel = vgui.Create("DLabel", dlg)
            titleLabel:Dock(TOP)
            titleLabel:SetTall(32)
            titleLabel:DockMargin(8, 6, 8, 6)
            titleLabel:SetText("Search Inventory - " .. (Monarch.Introductions.GetDisplayName(targetEnt) or targetEnt:Nick()))
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

            -- Create list view with custom styling
            local listPanel = vgui.Create("DListView", body)
            listPanel:Dock(FILL)
            listPanel:SetMultiSelect(false)
            
            -- Add columns
            listPanel:AddColumn("Item")
            listPanel:AddColumn("Qty")

            -- Handle list item clicks to confiscate
            function listPanel:OnRowSelected(index, row)
                if not IsValid(targetEnt) then return end
                
                -- Find which item was clicked
                local allItems = {}
                
                -- Build list of items in display order
                for i, line in ipairs(self:GetLines()) do
                    if i == index then
                        -- Get item name from the line
                        local itemName = line:GetValue(1)
                        
                        -- Find the matching item from our stored data
                        for _, contraband in ipairs(storedContraband or {}) do
                            if contraband.name == itemName then
                                net.Start("Monarch_ConfiscateItem")
                                net.WriteEntity(targetEnt)
                                net.WriteString(contraband.class)
                                net.SendToServer()
                                
                                surface.PlaySound("buttons/button10.wav")
                                self:RemoveLine(index)
                                return
                            end
                        end
                        
                        for _, regular in ipairs(storedRegular or {}) do
                            if regular.name == itemName then
                                -- Send confiscate request
                                net.Start("Monarch_ConfiscateItem")
                                net.WriteEntity(targetEnt)
                                net.WriteString(regular.class)
                                net.SendToServer()
                                
                                surface.PlaySound("buttons/button10.wav")
                                self:RemoveLine(index)
                                return
                            end
                        end
                        break
                    end
                end
            end

            local storedContraband = {}
            local storedRegular = {}

            -- Add loading text
            local loadingLabel = vgui.Create("DLabel", body)
            loadingLabel:Dock(TOP)
            loadingLabel:SetText("Loading inventory...")
            loadingLabel:SetTextColor(Color(150, 150, 150))
            loadingLabel:SetFont("Monarch-LightUI20")
            loadingLabel:DockMargin(0, 20, 0, 0)

            -- Request inventory from server
            net.Start("Monarch_SearchInventory")
            net.WriteEntity(targetEnt)
            net.SendToServer()

            -- Handle inventory response
            local function OnInventoryResponse()
                if not IsValid(listPanel) or not IsValid(dlg) or not IsValid(loadingLabel) then return end

                local targetFromNet = net.ReadEntity()
                if targetFromNet ~= targetEnt then return end

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
            net.Receive("Monarch_SearchInventoryResponse", function()
                OnInventoryResponse()
            end)

            CM.closing = true
        else
            net.Start("Monarch_SelectContextOption")
            net.WriteEntity(CM.target or NULL)
            net.WriteString(opt.action or "")
            net.SendToServer()
            CM.closing = true
        end
    end

    local function getLayoutMetrics(w, h)
        local buttonH = 40
        local stepY = 50

        local visibleTop = math.floor(h * 0.2)
        local visibleBottom = math.floor(h * 0.8)
        local visibleHeight = visibleBottom - visibleTop
        local centerY = math.floor((visibleTop + visibleBottom) * 0.5)

        return {
            buttonH = buttonH,
            stepY = stepY,
            visibleTop = visibleTop,
            visibleBottom = visibleBottom,
            visibleHeight = visibleHeight,
            centerY = centerY,
        }
    end

    local function getButtonBounds(i, w, h)
        local metrics = getLayoutMetrics(w, h)
        local virtualFocused = math.Clamp(CM.scroll or 1, 1, math.max(#CM.options, 1))
        local optionCenterY = metrics.centerY + ((i - virtualFocused) * metrics.stepY)
        local buttonW, buttonH = 300, 40
        local buttonX = w / 2 - buttonW / 2
        local buttonY = optionCenterY - (buttonH * 0.5)
        return buttonX, buttonY, buttonW, buttonH
    end

    function pnl:Think()
        local ft = FrameTime()
        CM.fade = math.Clamp(CM.fade + (CM.closing and -600 or 600) * ft, 0, 255)

        if CM.closing and CM.fade <= 0 then
            if IsValid(self) then self:Remove() end
            CM.closing = false
            CM.panel = nil
            CM.target = nil
            CM.options = {}
            return
        end

        local _, my = gui.MousePos()
        if not my or my <= 0 then
            _, my = self:CursorPos()
        end
        local w, h = self:GetWide(), self:GetTall()

        local metrics = getLayoutMetrics(w, h)
        local count = #CM.options
        if count > 0 then
            local mouseFrac = math.Clamp((my - metrics.visibleTop) / metrics.visibleHeight, 0, 1)
            CM.scrollTarget = 1 + (mouseFrac * (count - 1))
            CM.scroll = Lerp(FrameTime() * 14, CM.scroll, CM.scrollTarget)
        else
            CM.scrollTarget = 1
            CM.scroll = Lerp(FrameTime() * 14, CM.scroll, 1)
        end

        local focusLineY = metrics.centerY

        local oldFocus = CM.focused
        CM.focused = 0
        local closestDist = math.huge
        for i = 1, #CM.options do
            local _, y, _, bh = getButtonBounds(i, w, h)
            if y + bh >= metrics.visibleTop and y <= metrics.visibleBottom then
                local centerY = y + (bh * 0.5)
                local dist = math.abs(centerY - focusLineY)
                if dist < closestDist then
                    closestDist = dist
                    CM.focused = i
                end
            end
        end

        CM.hovered = CM.focused

        if oldFocus ~= CM.focused and CM.focused ~= 0 then
            local hoverSound = (Config and Config.InteractMenuSound) or "ui/hls_ui_scroll_click.wav"
            surface.PlaySound(hoverSound)
        end

        self:SetCursor("blank")
        if surface and surface.SetCursor then
            surface.SetCursor("blank")
        end

        if not IsValid(CM.target) then
            CM.closing = true
            return
        end
        local lp = LocalPlayer()
        local anchorPos = GetContextAnchorPos(CM.target, lp)
        if IsValid(lp) and (not anchorPos or lp:GetPos():DistToSqr(anchorPos) > (100 * 100)) then
            CM.closing = true
            return
        end
    end

    function pnl:Paint(w, h)
        if CM.fade <= 0 then return end

        local alpha = CM.fade
        local metrics = getLayoutMetrics(w, h)
        surface.SetFont("Monarch_ContextMenu_Title")
        surface.SetTextColor(255, 255, 255, alpha)
        local targetName = "Unknown"
        if IsValid(CM.target) then
            if CM.target:IsPlayer() and Monarch and Monarch.Introductions and Monarch.Introductions.GetDisplayName then
                targetName = Monarch.Introductions.GetDisplayName(CM.target)
            else
                targetName = CM.target.PrintName or CM.target:GetClass() or "Unknown"
            end
        end
        local title = "Interaction with " .. targetName
        local tw, th = surface.GetTextSize(title)
        local titleY = metrics.visibleTop - 40

        for i, opt in ipairs(CM.options) do
            local x, y, bw, bh = getButtonBounds(i, w, h)
            if y + bh < metrics.visibleTop or y > metrics.visibleBottom then
                continue
            end
            local isFocused = (i == CM.focused)

            local iconTarget = isFocused and 26 or 16
            local textTarget = isFocused and 26 or 16
            CM.iconSizes[i] = Lerp(FrameTime() * 8, CM.iconSizes[i] or iconTarget, iconTarget)
            CM.textSizes[i] = Lerp(FrameTime() * 8, CM.textSizes[i] or textTarget, textTarget)

            local iconSize = CM.iconSizes[i]
            local textSize = CM.textSizes[i]

            local iconX = x + 20
            local iconY = y + (bh - iconSize) / 2
            local c = isFocused and 255 or 105
            surface.SetDrawColor(c, c, c, alpha)
            
            -- Draw material icon with fallback to rectangle
            if optionIcon and not optionIcon:IsError() then
                surface.SetMaterial(optionIcon)
                surface.DrawTexturedRect(iconX, iconY, iconSize, iconSize)
            else
                surface.DrawRect(iconX, iconY, iconSize / 3, iconSize / 3)
            end

            local font = ScaledFont(textSize)
            surface.SetFont(font)
            local tr, tg, tb = (isFocused and 255 or 120), (isFocused and 255 or 120), (isFocused and 255 or 120)
            local textAlpha = isFocused and alpha or math.floor(alpha * 0.65)
            surface.SetTextColor(tr, tg, tb, textAlpha)
            surface.SetTextPos(iconX + 40, y + (bh - textSize) / 2)
            surface.DrawText(opt.text or ("Option " .. i))
        end
    end

    function pnl:OnRemove()
        CM.closing = false
        if surface and surface.SetCursor then
            surface.SetCursor("arrow")
        end
        if CM.panel == self then CM.panel = nil end
    end
end

net.Receive("Monarch_SendContextMenu", function()
    if IsValid(CM.panel) or CM.closing then return end

    local target = net.ReadEntity()
    local count = net.ReadUInt(8) or 0

    CM.target = target
    CM.options = {}
    for i = 1, count do
        local text = net.ReadString()
        local action = net.ReadString()
        CM.options[i] = { text = text, action = action }
    end

    OpenContextOverlay()
end)

hook.Add("Think", "Monarch_EHoldToOpenMenu", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    if IsValid(CM.panel) or CM.closing then
        isHoldingE = false
        return
    end

    local tr = lp:GetEyeTrace()
    local ent = tr.Entity
    if input.IsKeyDown(KEY_E) and CanHoldUseTarget(lp, ent) then
        if not isHoldingE then
            isHoldingE = true
            holdStart = CurTime()
        elseif CurTime() - holdStart >= holdThreshold then
            net.Start("Monarch_RequestContextMenu")
            net.WriteEntity(ent)
            net.SendToServer()
            isHoldingE = false
        end
    else
        isHoldingE = false
    end
end)

do
    local eBarVisual = 0

    local function DrawEHoldProgress()
        if IsValid(CM.panel) or CM.closing then
            eBarVisual = Lerp(FrameTime() * 12, eBarVisual, 0)
            if eBarVisual <= 0.01 then return end
        end

        if isHoldingE then
            local progress = math.Clamp((CurTime() - holdStart) / holdThreshold, 0, 1)
            eBarVisual = Lerp(FrameTime() * 12, eBarVisual, progress)
        else
            eBarVisual = Lerp(FrameTime() * 12, eBarVisual, 0)
        end

        if eBarVisual <= 0.01 then return end

        local scrW, scrH = ScrW(), ScrH()
        local centerX, centerY = scrW * 0.5, scrH * 0.5 + 32

        local barW, barH = 140, 6
        local x = math.floor(centerX - barW / 2)
        local y = math.floor(centerY)

        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawRect(x, y, math.floor(barW * eBarVisual), barH)
    end

    hook.Add("HUDPaint", "Monarch_DrawEHoldProgress", DrawEHoldProgress)
end
