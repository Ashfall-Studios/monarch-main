return function(PANEL)
    if not CLIENT then return end

    local Scale = (Monarch and Monarch.UI and Monarch.UI.Scale) or function(v) return v end
    local INVENTORY_PANEL_OPEN_FADE_TIME = 0.36
    local INVENTORY_CONTENT_OPEN_DELAY = 0.22
    local INVENTORY_SIDE_CLOSE_TIME = 0.36
    local INVENTORY_SIDE_LERP_SPEED = 7
    local INVENTORY_SIDE_OPEN_TIME = 0.18

    local function UI_FadeClose(panel, duration, onClosed)
        if not IsValid(panel) then return end

        panel:AlphaTo(0, tonumber(duration) or 0.15, 0, function()
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

    local function GetDisplayName(ply)
        if not IsValid(ply) then return "" end
        return (ply.GetRPName and ply:GetRPName()) or ply:Nick()
    end

    local function ResolveTeamVisuals(ply)
        if not IsValid(ply) then
            return "Unknown", Color(200, 200, 200)
        end

        local teamID = ply:Team()
        local teamName = team.GetName(teamID) or "Unknown"
        local teamColor = team.GetColor(teamID) or Color(200, 200, 200)

        return teamName, teamColor
    end

    local function CreateLabel(parent, font, color, text)
        local lbl = vgui.Create("DLabel", parent)
        lbl:SetFont(font)
        lbl:SetTextColor(color)
        lbl:SetText(text or "")
        lbl:SizeToContents()
        return lbl
    end

    local function SetupModelPreview(self)
        local ply = LocalPlayer()
        local modelPreview = vgui.Create("DModelPanel", self)
        modelPreview:SetZPos(-100)
        modelPreview:MoveToBack()
        modelPreview:SetSize(Scale(600), ScrH())
        modelPreview:SetPos(Scale(10), 0)
        modelPreview:SetFOV(20)
        modelPreview:SetLookAt(Vector(0, 0, 55))
        modelPreview:SetModel(IsValid(ply) and ply:GetModel() or "models/props_junk/cardboard_box004a.mdl")
        modelPreview:SetAlpha(255)
        self.modelPreview = modelPreview
        self._modelBaseX = Scale(10)
        self._modelBaseY = 0
        self._modelStartX = -(modelPreview:GetWide() + Scale(60))

        function modelPreview:LayoutEntity(ent)
            if not IsValid(ent) or not IsValid(LocalPlayer()) then return end

            ent:SetAngles(Angle(-1, 52, 0))
            ent:SetPos(Vector(0, 0, -1.30))
            self:RunAnimation()

            local lp = LocalPlayer()
            ent:SetSkin(lp:GetSkin())

            for _, bodygroup in pairs(lp:GetBodyGroups()) do
                if bodygroup and bodygroup.id then
                    local bgValue = lp:GetBodygroup(bodygroup.id)
                    ent:SetBodygroup(bodygroup.id, bgValue)
                end
            end

            hook.Run("SetupInventoryModel", self, ent)
            self.setup = true
        end

        return modelPreview
    end

    local function SetupInfoLabels(self)
        local lp = LocalPlayer()
        local name = GetDisplayName(lp)
        local teamName, teamColor = ResolveTeamVisuals(lp)

        self.infoNameShadow = CreateLabel(self, "InvLarge", Color(0, 0, 0, 0), name)
        self.infoName = CreateLabel(self, "InvLarge", Color(200, 200, 200, 0), name)
        self.infoTeam = CreateLabel(self, "InvMed", Color(teamColor.r, teamColor.g, teamColor.b, 0), teamName)

        local nx = (self._modelBaseX or Scale(10)) + Scale(16)
        local ny = Scale(12)
        self._infoBaseX = nx
        self._infoBaseY = ny
        self._infoStartX = -Scale(300)

        local textX = nx
        local teamNameOffset = -Scale(5)
        self.infoNameShadow:SetPos(textX + 2, ny + 2)
        self.infoName:SetPos(textX, ny)
        self.infoTeam:SetPos(textX, ny + self.infoName:GetTall() + teamNameOffset)
    end

    local function CreateStatusBar(parent, label, color, order)
        local barHeight = Scale(8)
        local spacing = Scale(45)
        local topOffset = (order - 1) * spacing

        local lbl = CreateLabel(parent, "InvMed", Color(255, 255, 255), label)
        lbl:SetPos(0, topOffset)

        local bar = vgui.Create("DPanel", parent)
        bar:SetPos(Scale(-0), topOffset + lbl:GetTall() + Scale(2))
        bar:SetSize(ScrW() * 0.2, barHeight)
        bar.Paint = function(s, w, h)
            local value = s.Value or 100
            s.DisplayValue = Lerp(FrameTime() * 14, s.DisplayValue or value, value)
            local fillW = math.Clamp((s.DisplayValue or value) * 4, 0, w)
            local radius = h / 2

            surface.SetDrawColor(0, 0, 0, 180)
            draw.RoundedBox(radius, 0, 0, w, h, Color(0, 0, 0, 180))

            surface.SetDrawColor(color)
            if fillW > 0 then
                draw.RoundedBox(radius, 0, 0, fillW, h, color)
            end
        end

        bar.Value = 100
        bar.DisplayValue = 100
        return bar
    end

    local function UpdateStatBarValue(bar, value)
        if IsValid(bar) then
            bar.Value = value
        end
    end

function PANEL:Init()

    self.selectedItem = nil
    self._lootCanStore = true 

    timer.Simple(0.1, function()
        if IsValid(self) then

            net.Start("Monarch_Inventory_Request")
            net.SendToServer()

            timer.Simple(2, function()
                if IsValid(self) then
                    local steamID = LocalPlayer():SteamID64()
                    if not steamID or table.Count(Monarch.Inventory.Data[steamID] or {}) == 0 then

                    end
                end
            end)
        end
    end)

    for _, panel in pairs(vgui.GetWorldPanel():GetChildren()) do
        if panel ~= self and panel.ClassName == "MonarchInventory" and IsValid(panel) then
            panel:Remove()
            break
        end
    end

    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:CenterHorizontal()
    self:MakePopup()
    self:SetAlpha(0)
    self:AlphaTo(255, INVENTORY_PANEL_OPEN_FADE_TIME, 0)
    self._inventoryContentOpenDelay = INVENTORY_CONTENT_OPEN_DELAY
    self._inventorySideOpenDuration = INVENTORY_SIDE_OPEN_TIME
    self:MoveToFront()
    self:AddCloseButton()

    Monarch = Monarch or {}
    Monarch.InventoryPanel = self

    self.ShowItemInfo = false

    self.keyMonitor = false

    local w, h = self:GetSize()

    self._modelBaseX = Scale(10)
    self._modelBaseY = 0
    self._modelWidth = Scale(600)
    SetupInfoLabels(self)

    local statsYOffset = Scale(225)
    local statsXOffset = Scale(350)
    self.statusPanel = vgui.Create("DPanel", self)
    self.statusPanel:SetSize(ScrW() / 3, ScrH())
    self.statusPanel:SetPos((self._modelBaseX + self._modelWidth) - statsXOffset, ScrH() / 2 + statsYOffset + Scale(20))
    self.statusPanel.Paint = function() end
    self.statusPanel:SetAlpha(0)
    self._statsBaseX = (self._modelBaseX + self._modelWidth) - statsXOffset
    self._statsBaseY = ScrH() / 2 + statsYOffset
    self._statsStartX = -(self.statusPanel:GetWide() + Scale(80))

    self._animModel = 1
    self._animInfo = 0
    self._animStats = 0
    self._animEquip = 0
    self._contentIntroStarted = false
    self._targetInfo = 0
    self._targetStats = 0

    timer.Simple(tonumber(self._inventoryContentOpenDelay) or 0, function()
        if not IsValid(self) then return end
        if not IsValid(self.modelPreview) then
            SetupModelPreview(self)
        end
        self._contentIntroStarted = true
        self._targetInfo = 1
        self._targetStats = 1
    end)

    self.healthBar = CreateStatusBar(self.statusPanel, "Health", Color(255, 179, 186, 100), 1)
    self.hydrationBar   = CreateStatusBar(self.statusPanel, "Hydration",   Color(186, 225, 255, 100), 2)
    self.hungerBar      = CreateStatusBar(self.statusPanel, "Hunger",      Color(255, 223, 186, 100), 3)
    self.exhaustionBar  = CreateStatusBar(self.statusPanel, "Exhaustion",  Color(201, 186, 255, 100), 4)

    self.healthBar.Value = LocalPlayer():Health() or 100

    self.hydrationBar.Value  = LocalPlayer():GetNWInt("Hydration", 100)
    self.hungerBar.Value     = LocalPlayer():GetNWInt("Hunger", 100)
    self.exhaustionBar.Value = LocalPlayer():GetNWInt("Exhaustion", 100)

    self.notificationQueue = {}
    self.notificationPanel = vgui.Create("DPanel", self)
    self.notificationPanel:SetSize(Scale(500), Scale(300))
    self.notificationPanel:SetPos((self:GetWide() - Scale(500)) / 2, Scale(40))
    self.notificationPanel:SetZPos(500)
    self.notificationPanel:SetMouseInputEnabled(false)
    self.notificationPanel:SetKeyboardInputEnabled(false)
    self.notificationPanel.Paint = function() end

    self:SetupVerticalTabs(w, h)

    self:AddCloseButton()

    net.Start("Monarch_Inventory_Request")
    net.SendToServer()
end

function PANEL:ShowNotification(message, color, duration)
    duration = duration or 4

    if not IsValid(self.notificationPanel) then return end

    if not self.notificationQueue then
        self.notificationQueue = {}
    end

    local function RepositionNotifications(queue, panel, moveTime)
        if not (IsValid(panel) and queue) then return end
        local x = (panel:GetWide() - Scale(450)) / 2
        for i, n in ipairs(queue) do
            if IsValid(n) then
                n:MoveTo(x, (i - 1) * Scale(45), moveTime or 0.2)
            end
        end
    end

    local notif = vgui.Create("DPanel", self.notificationPanel)
    notif:SetSize(Scale(450), Scale(40))
    notif:SetPos((self.notificationPanel:GetWide() - Scale(450)) / 2, 0)
    notif:SetAlpha(0)
    notif:AlphaTo(255, 0.15, 0)

    notif.Paint = function(s, w, h)

        surface.SetDrawColor(80, 80, 85, 180)
        draw.RoundedBox(4, 0, 0, w, h, Color(80, 80, 85, 180))

        surface.SetDrawColor(60, 60, 65, 200)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local textLabel = vgui.Create("DLabel", notif)
    textLabel:SetFont("InvSmall")
    textLabel:SetTextColor(Color(220, 220, 220))
    textLabel:SetText(message)
    textLabel:SetPos(Scale(12), Scale(8))
    textLabel:SetSize(Scale(450) - Scale(24), Scale(40) - Scale(16))
    textLabel:SetWrap(true)
    textLabel:SetContentAlignment(4)

    table.insert(self.notificationQueue, notif)

    RepositionNotifications(self.notificationQueue, self.notificationPanel, 0.15)

    local queue = self.notificationQueue  
    local panel = self.notificationPanel  
    timer.Simple(duration, function()
        UI_FadeClose(notif)

        if queue then
            for i, v in ipairs(queue) do
                if v == notif then
                    table.remove(queue, i)
                    break
                end
            end
        end

        RepositionNotifications(queue, panel, 0.2)
    end)

    return notif
end

function PANEL:Think()
    local ft = FrameTime()
    local targetInfo = self._targetInfo or 1
    local targetStats = self._targetStats or 1

    local currentInfo = self._animInfo or 0
    local infoDuration = targetInfo > currentInfo and (self._inventorySideOpenDuration or INVENTORY_SIDE_OPEN_TIME) or INVENTORY_SIDE_CLOSE_TIME
    if infoDuration <= 0 then
        self._animInfo = targetInfo
    else
        self._animInfo = math.Approach(currentInfo, targetInfo, ft / infoDuration)
    end

    local currentStats = self._animStats or 0
    local statsDuration = targetStats > currentStats and (self._inventorySideOpenDuration or INVENTORY_SIDE_OPEN_TIME) or INVENTORY_SIDE_CLOSE_TIME
    if statsDuration <= 0 then
        self._animStats = targetStats
    else
        self._animStats = math.Approach(currentStats, targetStats, ft / statsDuration)
    end

    local currentEquip = self._animEquip or 0
    local equipDuration = targetInfo > currentEquip and (self._inventorySideOpenDuration or INVENTORY_SIDE_OPEN_TIME) or INVENTORY_SIDE_CLOSE_TIME
    if equipDuration <= 0 then
        self._animEquip = targetInfo
    else
        self._animEquip = math.Approach(currentEquip, targetInfo, ft / equipDuration)
    end

    if IsValid(self.modelPreview) then
        self.modelPreview:SetPos(self._modelBaseX or Scale(10), self._modelBaseY or 0)
        self.modelPreview:SetAlpha(self._contentIntroStarted and 255 or 0)
    end

    if IsValid(self.infoName) and IsValid(self.infoNameShadow) and IsValid(self.infoTeam) then
        local infoAlpha = math.floor(255 * (self._animInfo or 0))
        local shadowAlpha = math.floor(250 * (self._animInfo or 0))
        self.infoName:SetTextColor(Color(200, 200, 200, infoAlpha))
        self.infoNameShadow:SetTextColor(Color(0, 0, 0, shadowAlpha))

        local lp = LocalPlayer()
        if IsValid(lp) and (self._nextInfoPoll or 0) < CurTime() then
            self._nextInfoPoll = CurTime() + 0.25
            local displayName = GetDisplayName(lp)
            if self.infoName:GetText() ~= displayName then
                self.infoName:SetText(displayName)
                self.infoName:SizeToContents()
                self.infoNameShadow:SetText(displayName)
                self.infoNameShadow:SizeToContents()
            end

            local teamName, teamColor = ResolveTeamVisuals(lp)
            self.infoTeam:SetText(teamName)
            self.infoTeam:SizeToContents()
            self.infoTeam._teamColor = teamColor
        end

        local teamColor = self.infoTeam._teamColor or Color(200, 200, 200)
        self.infoTeam:SetTextColor(Color(teamColor.r, teamColor.g, teamColor.b, infoAlpha))

        local nx = Lerp(self._animInfo, self._infoStartX or -Scale(200), self._infoBaseX or self.infoName:GetX())
        local ny = self._infoBaseY or self.infoName:GetY()
        local yOffset = Lerp(self._animInfo, Scale(12), 0)
        local textX = nx

        local teamNameOffset = -Scale(5)

        self.infoNameShadow:SetPos(textX + 2, ny + 2 + yOffset)
        self.infoName:SetPos(textX, ny + yOffset)
        self.infoTeam:SetPos(textX, ny + self.infoName:GetTall() + teamNameOffset + yOffset)
    end

    if IsValid(self.statusPanel) then
        local statsAlpha = math.floor(255 * (self._animStats or 0))
        self.statusPanel:SetAlpha(statsAlpha)
        local statsX = Lerp(self._animStats, self._statsStartX or -Scale(200), self._statsBaseX or self.statusPanel:GetX())
        local statsY = Lerp(self._animStats, (self._statsBaseY or 0) + Scale(20), self._statsBaseY or 0)
        self.statusPanel:SetPos(statsX, statsY)
    end

    if IsValid(self.equipPanel) then
        local equipX = Lerp(self._animEquip or 0, self._equipStartX or -Scale(200), self._equipBaseX or 0)
        self.equipPanel:SetPos(equipX, 0)
    end

    if (self._nextStatPoll or 0) < CurTime() then
        self._nextStatPoll = CurTime() + 0.2
        local lp = LocalPlayer()
        if IsValid(lp) then
            UpdateStatBarValue(self.healthBar, lp:Health() or (self.healthBar and self.healthBar.Value) or 100)
            UpdateStatBarValue(self.hydrationBar, lp:GetNWInt("Hydration", (self.hydrationBar and self.hydrationBar.Value) or 100))
            UpdateStatBarValue(self.hungerBar, lp:GetNWInt("Hunger", (self.hungerBar and self.hungerBar.Value) or 100))
            UpdateStatBarValue(self.exhaustionBar, lp:GetNWInt("Exhaustion", (self.exhaustionBar and self.exhaustionBar.Value) or 100))
        end
    end
end

function PANEL:AddCloseButton()
    if IsValid(self.closeBtn) then self.closeBtn:Remove() end
    local closeBtn = vgui.Create("DButton", self)
    closeBtn:SetText("CLOSE ✕")
    closeBtn:SetFont("InvSmall")
    closeBtn:SetTextColor(Color(235,235,235))
    closeBtn:SetSize(0, 30)
    closeBtn:SizeToContentsX()
    closeBtn._hoverT = 0
    closeBtn.Paint = function(s, w, h)
        local hovered = s:IsHovered()
        local col = hovered and Color(90,90,90, 200) or Color(40,40,40, 3)
        surface.SetDrawColor(col)
        surface.DrawRect(0, 0, w, h)

    end
    closeBtn.DoClick = function(s)
        if not self._closing then
            self:AnimateClose()
        end
    end
    closeBtn.Think = function(s)
        local pw, ph = self:GetSize()
        s:SetPos(pw - s:GetWide() - 12, 10)
    end
    self.closeBtn = closeBtn

    self.OnKeyCodePressed = function(p, key)
        if key == KEY_ESCAPE then
            if not self._closing then
                self:AnimateClose()
            end
        end

        local bind = tonumber(Monarch.GetSetting and Monarch.GetSetting("bind_inventory") or KEY_G) or KEY_G
        if key == bind then
            if not self._closing then
                self:AnimateClose()
            end
        end
    end
end

function PANEL:AnimateClose()
    if self._closing then return end
    self._closing = true

    if IsValid(self.modelPreview) then
        self.modelPreview:Remove()
        self.modelPreview = nil
    end

    local dur = INVENTORY_SIDE_CLOSE_TIME
    local left = self.leftPanel
    local right = self.rightPanel

    self._targetInfo = 0
    self._targetStats = 0

    if IsValid(left) then
        left:MoveTo(-600, 0, dur, 0)
        left:AlphaTo(0, dur, 0)
    end
    if IsValid(right) then
        local w = self:GetWide()
        right:MoveTo(w, 0, dur, 0)
        right:AlphaTo(0, dur, 0)
    end

    self:AlphaTo(0, dur, 0, function()
        if IsValid(self) then
            self:Remove()
        end
        if Monarch and Monarch.InventoryPanel == self then
            Monarch.InventoryPanel = nil
        end
    end)
end

bggrunge = Material("mrp/menu_stuff/bg_grunge.png")

PANEL.Paint = function(self, w, h)	
    BlurRect(self.x, self.y, w, h)

    surface.SetMaterial(bggrunge)
    surface.SetDrawColor(255, 255, 255, 75)
    surface.DrawTexturedRect(0, 0, w, h)
end

function PANEL:SetupVerticalTabs(w, h)
    if IsValid(self.tabPanel) then self.tabPanel:Remove() end
    if IsValid(self.contentPanel) then self.contentPanel:Remove() end

    local tabWidth = Scale(120)
    local tabX = w - tabWidth - Scale(10)
    local contentWidth = tabX - Scale(10) - Scale(10)
    local contentX = w - contentWidth - tabWidth - Scale(-180)

    self.tabPanel = vgui.Create("DPanel", self)
    self.tabPanel:SetPos(tabX, Scale(40))
    self.tabPanel:SetSize(tabWidth, h - Scale(42))
    self.tabPanel:SetZPos(100)
    self.tabPanel:SetAlpha(0)
    self.tabPanel.Paint = function() end

    self.contentPanel = vgui.Create("DPanel", self)
    self.contentPanel:SetPos(contentX, Scale(40))
    self.contentPanel:SetSize(contentWidth, h - Scale(42))
    self.contentPanel:SetAlpha(0)
    self.contentPanel.Paint = function() end

    local tabIcons = {
        {name = "", icon = "icons/inventory/backpack_icon.png", panelFunc = function() return self:CreateInventoryPanel(self.contentPanel) end},
        {name = "", icon = "mrp/icons/skills.png", panelFunc = function() return self:CreateSkillsPanel(self.contentPanel) end},
        {name = "", icon = "mrp/icons/settings.png", panelFunc = function() return self:CreateSettingsPanel(self.contentPanel) end},
        {name = "", icon = "mrp/icons/unknown-user-symbol.png", panelFunc = function() return self:CreateCommunityPanel(self.contentPanel) end},
        {name = "", icon = "icons/player_factions/legacy/crew_crown.png", panelFunc = function() return self:CreateFactionsPanel(self.contentPanel) end},
    }

    self.tabs = {}
    self.tabLabels = {}
    self.tabContents = {}

    local selectSound = "ui/hls_ui_select.wav" 
    local hvrSound = "ui/hls_ui_scroll_click.wav"
    local bgimgopt = Material("icons/inventory/cmb_poly.png", "smooth")
    local buttonSize = Scale(90)
    local buttonX = (self.tabPanel:GetWide() - buttonSize) / 2
    local y = 80

    local function AttachTabAnimation(pnl)
        if not IsValid(pnl) then return end
        pnl._baseX, pnl._baseY = pnl:GetPos()
        pnl._tabAlpha = 0
        pnl._targetAlpha = 0
        pnl._tabOffset = Scale(20)
        pnl._targetOffset = Scale(20)
        pnl:SetAlpha(0)
        local oldThink = pnl.Think
        pnl.Think = function(s)
            if oldThink then oldThink(s) end
            local alphaTarget = s._targetAlpha or 0
            local offsetTarget = s._targetOffset or Scale(20)
            s._tabAlpha = Lerp(FrameTime() * 18, s._tabAlpha or 0, alphaTarget)
            s._tabOffset = Lerp(FrameTime() * 18, s._tabOffset or offsetTarget, offsetTarget)
            local bx, by = s._baseX or 0, s._baseY or 0
            s:SetPos(bx + (s._tabOffset or 0), by)
            s:SetAlpha(math.Clamp(s._tabAlpha or 0, 0, 255))
            if (s._tabAlpha or 0) <= 1 and (s._targetAlpha or 0) <= 0 then
                s:SetVisible(false)
            else
                s:SetVisible(true)
            end
        end
    end

    local function CreateTabButton(i, tab, yPos)
        local btn = vgui.Create("DImageButton", self.tabPanel)
        btn:SetSize(buttonSize, buttonSize)
        btn:SetPos(buttonX, yPos)
        btn.imgMat = Material(tab.icon, "smooth")
        btn.HoverAlpha = 0
        btn._wasHovered = false

        btn.Think = function(s)
            local hovered = s:IsHovered()
            local target = (hovered or self.activeTab == i) and 80 or 0
            s.HoverAlpha = Lerp(FrameTime() * 10, s.HoverAlpha, target)

            if hovered and not s._wasHovered then
                surface.PlaySound(hvrSound)
            end
            s._wasHovered = hovered
        end

        btn.Paint = function(s, w, h)
            local outlinePad = 4 
            local imagePad = 10
            local squareW, squareH = w - outlinePad * 2, h - outlinePad * 2
            local squareX, squareY = outlinePad, outlinePad
            local isActive = self.activeTab == i
            local isHovered = s:IsHovered()

            surface.SetDrawColor(Color(100, 100, 100, 150))
            surface.DrawOutlinedRect(squareX, squareY, squareW, squareH, 1)

            local imgSize = math.min(squareW, squareH) - imagePad * 2
            local imgX = (w - imgSize) / 2
            local imgY = (h - imgSize) / 2

            surface.SetDrawColor(isHovered and Color(255,255,255) or isActive and Color(255,255,255) or Color(200,200,200))
            surface.SetMaterial(bgimgopt)
            surface.DrawTexturedRect(squareX, squareY, squareW, squareH)

            surface.SetDrawColor(Color(0, 0, 0, 100))
            surface.SetMaterial(s.imgMat)
            surface.DrawTexturedRect(imgX + 2, imgY + 2, imgSize, imgSize)

            surface.SetDrawColor(isHovered and Color(255,255,255) or isActive and Color(255,255,255) or Color(200,200,200))
            surface.SetMaterial(s.imgMat)
            surface.DrawTexturedRect(imgX, imgY, imgSize, imgSize)
        end

        btn.DoClick = function()
            self:ShowTab(i)
            surface.PlaySound(selectSound)
        end

        return btn
    end

    local function CreateTabLabel(tab, yPos)
        local lbl = CreateLabel(self.tabPanel, "InvSmall", Color(220,220,220), tab.name)
        local labelX = (self.tabPanel:GetWide() - lbl:GetWide()) / 2
        local labelY = yPos + 8 + 85
        lbl:SetPos(labelX, labelY)
        return lbl, labelY
    end

    for i, tab in ipairs(tabIcons) do
        self.tabs[i] = CreateTabButton(i, tab, y)

        local lbl, labelY = CreateTabLabel(tab, y)
        self.tabLabels[i] = lbl
        y = labelY + lbl:GetTall() - 25

        self.tabContents[i] = tab.panelFunc()
        self.tabContents[i]:SetVisible(false)
        AttachTabAnimation(self.tabContents[i])
    end

    local introDelay = tonumber(self._inventoryContentOpenDelay) or 0
    self.tabPanel:AlphaTo(255, 0.18, introDelay)
    self.contentPanel:AlphaTo(255, 0.18, introDelay)
    timer.Simple(introDelay, function()
        if not IsValid(self) then return end
        self:ShowTab(1)
    end)
end

function PANEL:ShowTab(idx)
    self.activeTab = idx
    for i, pnl in pairs(self.tabContents) do
        if IsValid(pnl) then
            local isActive = (i == idx)
            pnl._targetAlpha = isActive and 255 or 0
            pnl._targetOffset = isActive and 0 or Scale(20)
            pnl:SetVisible(true)
            pnl:SetMouseInputEnabled(isActive)
            pnl:SetKeyboardInputEnabled(isActive)
        end
    end

    if idx == 1 then
        net.Start("Monarch_Inventory_Request")
        net.SendToServer()
    else

        if self.ClearItemSelection then
            self:ClearItemSelection()
        end
    end

    if idx == 5 then 
        if Monarch.Factions and Monarch.Factions.RequestPlayerFaction then
            Monarch.Factions.RequestPlayerFaction()
        end

    else

        if IsValid(self.inventoryMemberScroll) then self.inventoryMemberScroll:SetVisible(false) end
        if IsValid(self.inventoryRoleScroll) then self.inventoryRoleScroll:SetVisible(false) end
    end
end

function PANEL:UpdatePlayerInfoUI()
    local lp = LocalPlayer()
    if not IsValid(lp) then
        return
    end

    if IsValid(self.infoName) then
        local name = lp.GetRPName and lp:GetRPName() or lp:Nick()
        self.infoName:SetText(name)
        self.infoName:SizeToContents()

        if IsValid(self.infoNameShadow) then
            self.infoNameShadow:SetText(name)
            self.infoNameShadow:SizeToContents()
        end
    end

    if IsValid(self.infoTeam) then
        self.infoTeam:SetText(team.GetName(lp:Team()))
        self.infoTeam:SizeToContents()
    end

    if IsValid(self.healthBar) then
        self.healthBar.Value = lp:Health() or self.healthBar.Value or 100
    end
    if IsValid(self.hydrationBar) and lp.GetHydration then
        self.hydrationBar.Value = lp:GetHydration() or self.hydrationBar.Value
    end
    if IsValid(self.hungerBar) and lp.GetHunger then
        self.hungerBar.Value = lp:GetHunger() or self.hungerBar.Value
    end
    if IsValid(self.exhaustionBar) and lp.GetExhaustion then
        self.exhaustionBar.Value = lp:GetExhaustion() or self.exhaustionBar.Value
    end
end

end

