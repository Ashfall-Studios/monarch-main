return function(PANEL)
    if not CLIENT then return end

    local Scale = (Monarch and Monarch.UI and Monarch.UI.Scale) or function(v) return v end
    local INV_HOVER_SOUND = (isstring(_G.INV_HOVER_SOUND) and _G.INV_HOVER_SOUND ~= "") and _G.INV_HOVER_SOUND or "ui/buttonrollover.wav"

    local UI_CreateFullscreenOverlay = isfunction(_G.UI_CreateFullscreenOverlay) and _G.UI_CreateFullscreenOverlay or function()
        local overlay = vgui.Create("EditablePanel")
        overlay:SetSize(ScrW(), ScrH())
        overlay:SetPos(0, 0)
        overlay:SetMouseInputEnabled(true)
        overlay:SetKeyboardInputEnabled(true)
        overlay:MakePopup()
        overlay:SetAlpha(0)
        overlay:AlphaTo(255, 0.12, 0)
        overlay.Paint = function(_, w, h)
            surface.SetDrawColor(0, 0, 0, 200)
            surface.DrawRect(0, 0, w, h)
        end
        return overlay
    end

    local UI_FadeClose = isfunction(_G.UI_FadeClose) and _G.UI_FadeClose or function(panel)
        if not IsValid(panel) then return end
        panel:AlphaTo(0, 0.1, 0, function()
            if IsValid(panel) then
                panel:Remove()
            end
        end)
    end

function PANEL:CreateFactionsPanel(parent)

    local base = vgui.Create("DPanel", parent)
    base:SetSize(Scale(600), Scale(1600))
    base:SetPos(Scale(1000), Scale(40))
    base.Paint = function(s, pw, ph)
    end

    local w, h = base:GetSize()

    local titleShadow = vgui.Create("DLabel", base)
    titleShadow:SetFont("Inventory_Title")
    titleShadow:SetColor(Color(0, 0, 0, 250))
    titleShadow:SetText("FACTIONS")
    titleShadow:SizeToContents()

    local title = vgui.Create("DLabel", base)
    title:SetFont("Inventory_Title")
    title:SetColor(Color(185, 185, 185))
    title:SetText("FACTIONS")
    title:SizeToContents()

    local iconSize = Scale(55)
    local iconSpacing = Scale(10)

    local iconShadow = vgui.Create("DImage", base)
    iconShadow:SetImage("icons/player_factions/legacy/crew_crown.png")
    iconShadow:SetSize(iconSize, iconSize)
    iconShadow:SetImageColor(Color(0, 0, 0, 150))

    local icon = vgui.Create("DImage", base)
    icon:SetImage("icons/player_factions/legacy/crew_crown.png")
    icon:SetSize(iconSize, iconSize)
    icon:SetImageColor(Color(185, 185, 185))

    local totalWidth = iconSize + iconSpacing + title:GetWide()
    local centerX = (w - totalWidth) * 0.5
    iconShadow:SetPos(centerX + 2, Scale(20) + 2)
    titleShadow:SetPos(centerX + iconSize + iconSpacing + 2, Scale(20) + 2)
    icon:SetPos(centerX, Scale(20) + (title:GetTall() - iconSize) * 0.5)
    title:SetPos(centerX + iconSize + iconSpacing, Scale(20))

    local scroll = vgui.Create("DScrollPanel", base)
    scroll:SetPos(10, Scale(90))
    scroll:SetSize(w - 20, h - Scale(100))
    local vbar = scroll:GetVBar()
    if IsValid(vbar) then
        vbar:SetWide(6)
        function vbar:Paint(sw, sh)
            surface.SetDrawColor(0, 0, 0, 120)
            surface.DrawRect(0, 0, sw, sh)
        end
        function vbar.btnUp:Paint() end
        function vbar.btnDown:Paint() end
        function vbar.btnGrip:Paint(sw, sh)
            local col = self:IsHovered() and Color(140, 140, 140, 200) or Color(100, 100, 100, 160)
            surface.SetDrawColor(col)
            surface.DrawRect(0, 2, sw, sh - 4)
        end
    end

    local list = scroll:GetCanvas()
    function list:Paint() end

    local factionNameLabel = vgui.Create("DLabel", list)
    factionNameLabel:SetFont("InvMed")
    factionNameLabel:SetColor(Color(200, 200, 200))
    factionNameLabel:SetText("Faction Name:")
    factionNameLabel:SizeToContents()
    factionNameLabel:SetPos(0, Scale(100))

    local factionName = vgui.Create("DTextEntry", list)
    factionName:SetFont("InvSmall")
    factionName:SetTextColor(Color(200, 200, 200))
    factionName:SetPos(0, Scale(128))
    factionName:SetSize(Scale(580), Scale(28))
    factionName:SetText("")
    factionName.Paint = function(s, sw, sh)
        surface.SetDrawColor(Color(5, 5, 5, 250))
        surface.DrawRect(0, 0, sw, sh)
        surface.SetDrawColor(Color(80, 80, 80))
        surface.DrawOutlinedRect(0, 0, sw, sh, 1)
        s:DrawTextEntryText(Color(200, 200, 200), Color(25, 255, 25), Color(200, 200, 200))
    end

    local founderLabel = vgui.Create("DLabel", list)
    founderLabel:SetFont("InvMed")
    founderLabel:SetColor(Color(200, 200, 200))
    founderLabel:SetText("Founder Role Name:")
    founderLabel:SizeToContents()
    founderLabel:SetPos(0, Scale(170))

    local founderRole = vgui.Create("DTextEntry", list)
    founderRole:SetFont("InvSmall")
    founderRole:SetTextColor(Color(200, 200, 200))
    founderRole:SetPos(0, Scale(198))
    founderRole:SetSize(Scale(580), Scale(28))
    founderRole:SetText("")
    founderRole.Paint = function(s, sw, sh)
        surface.SetDrawColor(Color(5, 5, 5, 250))
        surface.DrawRect(0, 0, sw, sh)
        surface.SetDrawColor(Color(80, 80, 80))
        surface.DrawOutlinedRect(0, 0, sw, sh, 1)
        s:DrawTextEntryText(Color(200, 200, 200), Color(25, 255, 25), Color(200, 200, 200))
    end

    local colorLabel = vgui.Create("DLabel", list)
    colorLabel:SetFont("InvMed")
    colorLabel:SetColor(Color(200, 200, 200))
    colorLabel:SetText("Faction Color:")
    colorLabel:SizeToContents()
    colorLabel:SetPos(0, Scale(240))

    local selectedColor = Color(100, 100, 100)

    local colorPicker = vgui.Create("DPanel", list)
    colorPicker:SetPos(0, Scale(268))
    colorPicker:SetSize(Scale(580), Scale(180))
    colorPicker.Paint = function() end

    local colorCube = vgui.Create("DColorCube", colorPicker)
    colorCube:SetPos(Scale(20), 0)
    colorCube:SetSize(128, 128)
    colorCube:SetColor(selectedColor)

    local rgbPicker = vgui.Create("DRGBPicker", colorPicker)
    rgbPicker:SetPos(Scale(160), 0)
    rgbPicker:SetSize(20, 128)

    colorCube.OnUserChanged = function(_, col)
        if not col then return end
        selectedColor = Color(col.r or 0, col.g or 0, col.b or 0)
        if IsValid(rgbPicker) then rgbPicker:SetRGB(selectedColor.r, selectedColor.g, selectedColor.b) end
    end

    rgbPicker.OnChange = function(_, col)
        if not col then return end
        selectedColor = Color(col.r or 0, col.g or 0, col.b or 0)
        if IsValid(colorCube) then colorCube:SetColor(selectedColor) end
    end

    local logoLabel = vgui.Create("DLabel", list)
    logoLabel:SetFont("InvMed")
    logoLabel:SetColor(Color(200, 200, 200))
    logoLabel:SetText("Faction Logo:")
    logoLabel:SizeToContents()
    logoLabel:SetPos(0, Scale(420))

    local logoGridScroll = vgui.Create("DScrollPanel", list)
    logoGridScroll:SetPos(0, Scale(448))
    logoGridScroll:SetSize(Scale(580), Scale(180))

    local vbar = logoGridScroll:GetVBar()
    if IsValid(vbar) then
        vbar:SetWide(6)
        function vbar:Paint(sw, sh)
            surface.SetDrawColor(0, 0, 0, 120)
            surface.DrawRect(0, 0, sw, sh)
        end
        function vbar.btnUp:Paint() end
        function vbar.btnDown:Paint() end
        function vbar.btnGrip:Paint(sw, sh)
            local col = self:IsHovered() and Color(140, 140, 140, 200) or Color(100, 100, 100, 160)
            surface.SetDrawColor(col)
            surface.DrawRect(0, 2, sw, sh - 4)
        end
    end

    local logoGrid = logoGridScroll:GetCanvas()
    logoGrid.Paint = function() end

    local logos = Config and Config.FactionIcons or {}
    local selectedLogo = 1

    local cols = 5
    local logoSize = 75
    local spacing = 0
    local logoButtons = {}
    for i, logo in ipairs(logos) do
        local row = math.floor((i - 1) / cols)
        local col = (i - 1) % cols
        local btn = vgui.Create("DButton", logoGrid)
        btn:SetSize(logoSize, logoSize)
        btn:SetPos(col * (logoSize + spacing) + 10, row * (logoSize + spacing) + 1)
        btn:SetText("")
        btn._logoIndex = i
        btn._isSelected = (i == 1)
        btn.Paint = function(s, sw, sh)
            surface.SetDrawColor(Color(0, 0, 0, 2))
            surface.DrawRect(0, 0, sw, sh)
            surface.SetMaterial(Material("mrp/gradient_corner_2k.png", "smooth"))
            surface.SetDrawColor(Color(100, 100, 100, 200))
            surface.DrawTexturedRect(0, 0, sw, sh)

            local selColor = s._isSelected and Color(255, 255, 255) or Color(185, 185, 185)

            surface.SetMaterial(Material(logo, "smooth"))
            surface.SetDrawColor(selColor)
            surface.DrawTexturedRect(5, 5, sw - 10, sh - 10)
        end
        btn.DoClick = function()

            for _, prevBtn in ipairs(logoButtons) do
                prevBtn._isSelected = false
            end

            btn._isSelected = true
            selectedLogo = i
        end
        logoButtons[i] = btn
    end

    local previewCard = vgui.Create("DPanel", list)
    previewCard:SetPos(0, 0)
    previewCard:SetSize(Scale(560), Scale(65))
    previewCard:SetVisible(true)
    previewCard.Paint = function(s, w, h)

        surface.SetDrawColor(Color(35, 35, 35, 250))
        surface.DrawRect(0, 0, w, h)
        surface.SetMaterial(Material("mrp/gradient_corner_2k.png", "smooth"))
        surface.SetDrawColor(selectedColor.r, selectedColor.g, selectedColor.b, 30)
        surface.DrawTexturedRect(0, 0, w, h)

        surface.SetDrawColor(Color(100, 100, 100))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local previewTitle = vgui.Create("DLabel", previewCard)
    previewTitle:SetFont("InvMed")
    previewTitle:SetTextColor(Color(220, 220, 220))
    previewTitle:SetPos(Scale(90), Scale(10))
    previewTitle:SetSize(Scale(470), Scale(25))
    previewTitle:SetWrap(true)
    previewTitle:SetText("Your New Faction")

    local previewSubtitle = vgui.Create("DLabel", previewCard)
    previewSubtitle:SetFont("InvSmall")
    previewSubtitle:SetTextColor(Color(160, 160, 160))
    previewSubtitle:SetPos(Scale(90), Scale(38))
    previewSubtitle:SetSize(Scale(470), Scale(20))
    previewSubtitle:SetText("Create your faction")

    local previewLogo = vgui.Create("DImage", previewCard)
    previewLogo:SetSize(Scale(38), Scale(38))
    previewLogo:SetPos(Scale(16), Scale(16))

    local infoLabel = vgui.Create("DLabel", list)
    infoLabel:SetFont("InvMed")
    infoLabel:SetColor(Color(200, 200, 200))
    infoLabel:SetText("INFORMATION")
    infoLabel:SizeToContents()
    infoLabel:SetPos(0, Scale(550))
    infoLabel:SetVisible(false)

    local infoText = vgui.Create("DLabel", list)
    infoText:SetFont("InvSmall")
    infoText:SetColor(Color(160, 160, 160))
    infoText:SetText("There is currently [NUM] member(s) in [FACTION NAME]..\nYou are a [YOUR ROLE] within this faction.")
    infoText:SetWrap(true)
    infoText:SetSize(Scale(560), Scale(80))
    infoText:SetPos(10, Scale(580))
    infoText:SetVisible(false)

    local memberScroll = vgui.Create("DScrollPanel", self)
    memberScroll:SetPos(Scale(550), Scale(100))
    memberScroll:SetSize(Scale(580), Scale(450))
    memberScroll:SetVisible(false)
    self.inventoryMemberScroll = memberScroll  

    do
        local vbar = memberScroll:GetVBar()
        if IsValid(vbar) then
            vbar:SetWide(6)
            function vbar:Paint(sw, sh)
                surface.SetDrawColor(0, 0, 0, 120)
                surface.DrawRect(0, 0, sw, sh)
            end
            function vbar.btnUp:Paint() end
            function vbar.btnDown:Paint() end
            function vbar.btnGrip:Paint(sw, sh)
                local col = self:IsHovered() and Color(140, 140, 140, 200) or Color(100, 100, 100, 160)
                surface.SetDrawColor(col)
                surface.DrawRect(0, 2, sw, sh - 4)
            end
        end
    end
    local memberList = memberScroll:GetCanvas()
    function memberList:Paint() end

    local roleScroll = vgui.Create("DScrollPanel", self)
    roleScroll:SetPos(Scale(550), Scale(100))
    roleScroll:SetSize(Scale(580), Scale(450))
    roleScroll:SetVisible(false)
    self.inventoryRoleScroll = roleScroll  

    do
        local vbar = roleScroll:GetVBar()
        if IsValid(vbar) then
            vbar:SetWide(6)
            function vbar:Paint(sw, sh)
                surface.SetDrawColor(0, 0, 0, 120)
                surface.DrawRect(0, 0, sw, sh)
            end
            function vbar.btnUp:Paint() end
            function vbar.btnDown:Paint() end
            function vbar.btnGrip:Paint(sw, sh)
                local col = self:IsHovered() and Color(140, 140, 140, 200) or Color(100, 100, 100, 160)
                surface.SetDrawColor(col)
                surface.DrawRect(0, 2, sw, sh - 4)
            end
        end
    end
    local roleList = roleScroll:GetCanvas()
    function roleList:Paint() end

    local actionsLabel = vgui.Create("DLabel", base)
    actionsLabel:SetFont("InvMed")
    actionsLabel:SetColor(Color(200, 200, 200))
    actionsLabel:SetText("ACTIONS")
    actionsLabel:SizeToContents()
    actionsLabel:SetPos(Scale(10), Scale(360))

    local function addActionButton(parentPanel, label, y, doClickFunc)
        local btn = vgui.Create("DButton", parentPanel)
        btn:SetPos(Scale(10), y)
        btn:SetSize(Scale(560), Scale(38))
        btn:SetText(label)
        btn:SetFont("InvSmall")
        btn:SetTextColor(Color(230, 230, 230))
        btn._wasHovered = false
        btn.Paint = function(s, sw, sh)
            local isDanger = string.find(string.lower(label), "leave") or string.find(string.lower(label), "disband")
            local isHovered = s:IsHovered()
            local baseCol = isDanger and Color(95, 45,45, 120) or Color(55, 55, 55, 200)
            local gradCol = isDanger and Color(110, 55, 55, 125) or Color(125, 125, 125, 25)

            surface.SetDrawColor(baseCol)
            surface.DrawRect(0, 0, sw, sh)

            surface.SetMaterial(Material("mrp/gradient_corner_2k.png", "smooth"))
            surface.SetDrawColor(gradCol)
            surface.DrawTexturedRect(0, 0, sw, sh)

            if isHovered and not s._wasHovered then
                surface.PlaySound(INV_HOVER_SOUND)
                s._wasHovered = true
            elseif not isHovered then
                s._wasHovered = false
            end

            if isHovered then
                surface.SetDrawColor(isDanger and Color(150, 80, 80, 40) or Color(100, 150, 200, 30))
                surface.DrawRect(0, 0, sw, sh)
            end

            surface.SetDrawColor(isHovered and Color(70, 70, 70, 120) or Color(45, 45, 45, 60))
            surface.DrawOutlinedRect(0, 0, sw, sh, 2)
        end
        btn.DoClick = doClickFunc or function() end
        return btn
    end

    local createBtn = vgui.Create("DButton", list)
    createBtn:SetPos(10, Scale(685))
    createBtn:SetSize(Scale(560), Scale(32))
    createBtn:SetText("Create Faction")
    createBtn:SetFont("InvSmall")
    createBtn:SetTextColor(Color(255, 255, 255))

    createBtn.Paint = function(s, sw, sh)
        surface.SetDrawColor(Color(55, 55, 55, 250))
        surface.DrawRect(0, 0, sw, sh)
        surface.SetMaterial(Material("mrp/gradient_corner_2k.png", "smooth"))
        surface.SetDrawColor(Color(65, 65, 65, 230))
        surface.DrawTexturedRect(0, 0, sw, sh)

        surface.SetDrawColor(45,45,45,50)
        surface.DrawOutlinedRect(0, 0, sw, sh, 2)
    end
    createBtn.DoClick = function()
        local name = factionName:GetValue() or ""
        local role = founderRole:GetValue() or ""
        name = string.Trim(name)
        role = string.Trim(role)

        if name == "" or role == "" then
            self:ShowNotification("Please fill in all fields", Color(255, 100, 100), 3)
            return
        end

        if Monarch.Factions and Monarch.Factions.Create then
            Monarch.Factions.Create(name, role, selectedColor.r, selectedColor.g, selectedColor.b, selectedLogo)
        else
            self:ShowNotification("Faction system not available", Color(255, 100, 100), 3)
        end
    end
    createBtn:SetVisible(false)

    local function GetLocalFactionIdentityKeys()
        local lp = LocalPlayer()
        if not IsValid(lp) then return nil, nil, nil end

        local charID = tostring(lp:GetNWString("MonarchCharID", "") or "")
        if charID == "" then
            charID = tostring(lp.MonarchID or (lp.MonarchActiveChar and lp.MonarchActiveChar.id) or "")
        end
        if charID == "" then charID = nil end

        local sid64 = tostring(lp:SteamID64() or "")
        local sid = tostring(lp:SteamID() or "")
        if sid64 == "" then sid64 = nil end
        if sid == "" then sid = nil end

        return charID, sid64, sid
    end

    local function IsLocalFactionFounder(faction)
        if not istable(faction) then return false end
        local founderKey = tostring(faction.founderCharID or faction.founderSteamID or "")
        if founderKey == "" then return false end

        local charID, sid64, sid = GetLocalFactionIdentityKeys()
        return (charID and founderKey == charID)
            or (sid64 and founderKey == sid64)
            or (sid and founderKey == sid)
    end

    local function GetFounderMemberData(faction)
        if not istable(faction) or not istable(faction.members) then return nil end

        local founderKey = tostring(faction.founderCharID or faction.founderSteamID or "")
        if founderKey ~= "" and faction.members[founderKey] then
            return faction.members[founderKey]
        end

        local charID, sid64, sid = GetLocalFactionIdentityKeys()
        if charID and faction.members[charID] then return faction.members[charID] end
        if sid64 and faction.members[sid64] then return faction.members[sid64] end
        if sid and faction.members[sid] then return faction.members[sid] end

        return nil
    end

    local function HasLocalFactionPermission(faction, permissionKey)
        if not istable(faction) then return false end
        if IsLocalFactionFounder(faction) then return true end

        local charID, sid64, sid = GetLocalFactionIdentityKeys()
        local members = faction.members or {}
        local member = (charID and members[charID]) or (sid64 and members[sid64]) or (sid and members[sid])
        if not member then return false end

        local roleName = tostring(member.role or "")
        if roleName == "" then return false end

        local roleData = nil
        if faction.roles and faction.roles[roleName] then
            roleData = faction.roles[roleName]
        end

        if not roleData then
            for roleID, role in pairs(faction.roles or {}) do
                if tostring(roleID) == roleName or tostring(role.name or "") == roleName then
                    roleData = role
                    break
                end
            end
        end

        return roleData and roleData.permissions and roleData.permissions[permissionKey] or false
    end

    local function CanLocalEditMemberRoles(faction)
        return HasLocalFactionPermission(faction, "editMemberRoles")
    end

    local function OpenMemberRolePicker(memberInfo)
        if not istable(memberInfo) then return end
        if not (Monarch.Factions and Monarch.Factions.PlayerFaction) then return end

        local faction = Monarch.Factions.PlayerFaction
        if not CanLocalEditMemberRoles(faction) then
            self:ShowNotification("You do not have permission to edit member roles", Color(200, 100, 100), 3)
            return
        end

        local memberKey = tostring(memberInfo.charID or "")
        if memberKey == "" then
            self:ShowNotification("Unable to identify this faction member", Color(200, 100, 100), 3)
            return
        end

        local founderKey = tostring(faction.founderCharID or faction.founderSteamID or "")
        local memberSteamID = tostring(memberInfo.steamID or "")
        if founderKey ~= "" and (memberKey == founderKey or memberSteamID == founderKey) then
            self:ShowNotification("Founder role cannot be changed", Color(200, 100, 100), 3)
            return
        end

        local currentRole = tostring(memberInfo.role or "Member")
        local menu = DermaMenu()

        local seen = {}
        local function addRoleOption(roleName)
            roleName = tostring(roleName or "")
            if roleName == "" then return end
            local dedupeKey = string.lower(roleName)
            if seen[dedupeKey] then return end
            seen[dedupeKey] = true

            local option = menu:AddOption(roleName, function()
                if Monarch.Factions and Monarch.Factions.SetMemberRole then
                    Monarch.Factions.SetMemberRole(memberKey, roleName)
                else
                    net.Start("Monarch_Faction_SetMemberRole")
                    net.WriteString(memberKey)
                    net.WriteString(roleName)
                    net.SendToServer()
                end
            end)

            if roleName == currentRole and option and option.SetIcon then
                option:SetIcon("icon16/tick.png")
            end
        end

        addRoleOption("Member")

        for _, roleData in pairs(faction.roles or {}) do
            local roleName = tostring(roleData and roleData.name or "")
            if roleName ~= "" and string.lower(roleName) ~= "founder" then
                addRoleOption(roleName)
            end
        end

        menu:Open()
    end

    local editNameBtn = addActionButton(base, "Edit Name", Scale(805), function()
        if not (Monarch.Factions and Monarch.Factions.PlayerFaction) then return end

        local faction = Monarch.Factions.PlayerFaction
        if not IsLocalFactionFounder(faction) then
            self:ShowNotification("Only faction owner can edit name", Color(255, 100, 100), 3)
            return
        end

        local f = UI_CreateFullscreenOverlay()

        local container = vgui.Create("DPanel", f)
        container:SetSize(600, 250)
        container:Center()
        container.Paint = function() end

        local title = vgui.Create("DLabel", container)
        title:SetText("Edit Faction Name")
        title:SetFont("DinProLarge")
        title:SetTextColor(color_white)
        title:SetContentAlignment(5)
        title:Dock(TOP)
        title:DockMargin(0, 20, 0, 20)
        title:SetTall(32)

        local lbl = vgui.Create("DLabel", container)
        lbl:SetText("Enter new faction name (1-64 characters)")
        lbl:SetFont("DinPro")
        lbl:SetTextColor(color_white)
        lbl:SetContentAlignment(5)
        lbl:Dock(TOP)
        lbl:DockMargin(0, 0, 0, 20)
        lbl:SetTall(24)

        local entry = vgui.Create("DTextEntry", container)
        entry:SetText(faction.name or "")
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

        local btnPanel = vgui.Create("DPanel", container)
        btnPanel:SetTall(40)
        btnPanel:Dock(BOTTOM)
        btnPanel:DockMargin(0, 0, 0, 15)
        btnPanel.Paint = function() end

        local ok = vgui.Create("DButton", btnPanel)
        ok:SetText("Save")
        ok:SetFont("DinPro")
        ok:SetWide(150)
        ok:SetTextColor(color_white)
        ok:Dock(LEFT)
        ok:DockMargin(150, 0, 0, 0)
        ok.Paint = UI_PaintBasicDialogButton
        ok.DoClick = function()
            local newName = entry:GetText() or ""
            if newName == "" then
                self:ShowNotification("Faction name cannot be empty", Color(255, 100, 100), 3)
                return
            end
            if string.len(newName) > 64 then
                self:ShowNotification("Faction name too long (max 64 characters)", Color(255, 100, 100), 3)
                return
            end
            Monarch.Factions.Edit(faction.id, "name", newName)
            UI_FadeClose(f)
        end

        local cancel = vgui.Create("DButton", btnPanel)
        cancel:SetText("Cancel")
        cancel:SetFont("DinPro")
        cancel:SetWide(150)
        cancel:SetTextColor(color_white)
        cancel:Dock(LEFT)
        cancel.Paint = UI_PaintBasicDialogButton
        cancel.DoClick = function()
            UI_FadeClose(f)
        end

        entry:RequestFocus()
        entry:SelectAllText()
    end)
    editNameBtn:SetVisible(false)

    local editColorBtn = addActionButton(base, "Edit Color", Scale(885), function()
        if not (Monarch.Factions and Monarch.Factions.PlayerFaction) then return end
        local faction = Monarch.Factions.PlayerFaction

        local colorFrame = UI_CreateFullscreenOverlay()

        local container = vgui.Create("DPanel", colorFrame)
        container:SetSize(600, 450)
        container:Center()
        container.Paint = function() end

        local title = vgui.Create("DLabel", container)
        title:SetText("Edit Faction Color")
        title:SetFont("DinProLarge")
        title:SetTextColor(color_white)
        title:SetContentAlignment(5)
        title:Dock(TOP)
        title:DockMargin(0, 20, 0, 20)
        title:SetTall(32)

        local lbl = vgui.Create("DLabel", container)
        lbl:SetText("Choose a new color for your faction.")
        lbl:SetFont("DinPro")
        lbl:SetTextColor(color_white)
        lbl:SetContentAlignment(5)
        lbl:Dock(TOP)
        lbl:DockMargin(0, 0, 0, 20)
        lbl:SetTall(24)

        local colorPanel = vgui.Create("DPanel", container)
        colorPanel:SetTall(230)
        colorPanel:Dock(TOP)
        colorPanel:DockMargin(0, 0, 0, 20)
        colorPanel.Paint = function() end

        local colorLabel = vgui.Create("DLabel", colorPanel)
        colorLabel:SetText("Color")
        colorLabel:SetFont("DinPro")
        colorLabel:SetTextColor(Color(200, 200, 200))
        colorLabel:Dock(TOP)
        colorLabel:DockMargin(80, 5, 0, 10)
        colorLabel:SetTall(20)

        local pickerContainer = vgui.Create("DPanel", colorPanel)
        pickerContainer:SetTall(128)
        pickerContainer:Dock(TOP)
        pickerContainer:DockMargin(80, 0, 80, 0)
        pickerContainer.Paint = function() end

        local newColor = Color(faction.color.r, faction.color.g, faction.color.b)

        local colorCube = vgui.Create("DColorCube", pickerContainer)
        colorCube:SetPos(20, 0)
        colorCube:SetSize(128, 128)
        colorCube:SetColor(newColor)

        local rgbPicker = vgui.Create("DRGBPicker", pickerContainer)
        rgbPicker:SetPos(160, 0)
        rgbPicker:SetSize(20, 128)

        colorCube.OnUserChanged = function(_, col)
            if not col then return end
            newColor = Color(col.r or 0, col.g or 0, col.b or 0)
            if IsValid(rgbPicker) then rgbPicker:SetRGB(newColor.r, newColor.g, newColor.b) end
        end

        rgbPicker.OnChange = function(_, col)
            if not col then return end
            newColor = Color(col.r or 0, col.g or 0, col.b or 0)
            if IsValid(colorCube) then colorCube:SetColor(newColor) end
        end

        local btnPanel = vgui.Create("DPanel", container)
        btnPanel:SetTall(40)
        btnPanel:Dock(BOTTOM)
        btnPanel:DockMargin(0, 0, 0, 15)
        btnPanel.Paint = function() end

        local saveBtn = vgui.Create("DButton", btnPanel)
        saveBtn:SetText("Save Color")
        saveBtn:SetFont("DinPro")
        saveBtn:SetWide(150)
        saveBtn:SetTextColor(color_white)
        saveBtn:Dock(LEFT)
        saveBtn:DockMargin(150, 0, 0, 0)
        saveBtn.Paint = UI_PaintBasicDialogButton
        saveBtn.DoClick = function()
            Monarch.Factions.Edit(faction.id, "color", {r = newColor.r, g = newColor.g, b = newColor.b})
            UI_FadeClose(colorFrame)
        end

        local cancelBtn = vgui.Create("DButton", btnPanel)
        cancelBtn:SetText("Cancel")
        cancelBtn:SetFont("DinPro")
        cancelBtn:SetWide(150)
        cancelBtn:SetTextColor(color_white)
        cancelBtn:Dock(LEFT)
        cancelBtn.Paint = UI_PaintBasicDialogButton
        cancelBtn.DoClick = function()
            UI_FadeClose(colorFrame)
        end
    end)
    editColorBtn:SetVisible(false)

    local editLogoBtn = addActionButton(base, "Edit Logo", Scale(925), function()
        if not (Monarch.Factions and Monarch.Factions.PlayerFaction) then return end
        local faction = Monarch.Factions.PlayerFaction

        local logoFrame = UI_CreateFullscreenOverlay()

        local container = vgui.Create("DPanel", logoFrame)
        container:SetSize(600, 500)
        container:Center()
        container.Paint = function() end

        local title = vgui.Create("DLabel", container)
        title:SetText("Edit Faction Logo")
        title:SetFont("DinProLarge")
        title:SetTextColor(color_white)
        title:SetContentAlignment(5)
        title:Dock(TOP)
        title:DockMargin(0, 20, 0, 20)
        title:SetTall(32)

        local lbl = vgui.Create("DLabel", container)
        lbl:SetText("Choose a new logo for your faction.")
        lbl:SetFont("DinPro")
        lbl:SetTextColor(color_white)
        lbl:SetContentAlignment(5)
        lbl:Dock(TOP)
        lbl:DockMargin(0, 0, 0, 20)
        lbl:SetTall(24)

        local logoPanel = vgui.Create("DPanel", container)
        logoPanel:SetTall(280)
        logoPanel:Dock(TOP)
        logoPanel:DockMargin(0, 0, 0, 20)
        logoPanel.Paint = function() end

        local logoLabel = vgui.Create("DLabel", logoPanel)
        logoLabel:SetText("Select Logo")
        logoLabel:SetFont("DinPro")
        logoLabel:SetTextColor(Color(200, 200, 200))
        logoLabel:Dock(TOP)
        logoLabel:DockMargin(80, 5, 0, 10)
        logoLabel:SetTall(20)

        local logoGridScroll = vgui.Create("DScrollPanel", logoPanel)
        logoGridScroll:Dock(TOP)
        logoGridScroll:DockMargin(80, 0, 80, 0)
        logoGridScroll:SetTall(240)

        local vbar = logoGridScroll:GetVBar()
        if IsValid(vbar) then
            vbar:SetWide(6)
            function vbar:Paint(sw, sh)
                surface.SetDrawColor(0, 0, 0, 120)
                surface.DrawRect(0, 0, sw, sh)
            end
            function vbar.btnUp:Paint() end
            function vbar.btnDown:Paint() end
            function vbar.btnGrip:Paint(sw, sh)
                local col = self:IsHovered() and Color(140, 140, 140, 200) or Color(100, 100, 100, 160)
                surface.SetDrawColor(col)
                surface.DrawRect(0, 2, sw, sh - 4)
            end
        end

        local logoGrid = logoGridScroll:GetCanvas()
        logoGrid.Paint = function() end

        local logos = Config and Config.FactionIcons or {}
        local newLogoIndex = faction.logoIndex or 1

        local cols = 5
        local logoSize = 75
        local spacing = 0
        local logoButtons = {}

        for i, logo in ipairs(logos) do
            local row = math.floor((i - 1) / cols)
            local col = (i - 1) % cols
            local btn = vgui.Create("DButton", logoGrid)
            btn:SetSize(logoSize, logoSize)
            btn:SetPos(col * (logoSize + spacing) + 10, row * (logoSize + spacing) + 1)
            btn:SetText("")
            btn._logoIndex = i
            btn._isSelected = (i == newLogoIndex)
            btn.Paint = function(s, sw, sh)
                surface.SetDrawColor(Color(0, 0, 0, 2))
                surface.DrawRect(0, 0, sw, sh)
                surface.SetMaterial(Material("mrp/gradient_corner_2k.png", "smooth"))
                surface.SetDrawColor(Color(100, 100, 100, 200))
                surface.DrawTexturedRect(0, 0, sw, sh)

                local selColor = s._isSelected and Color(255, 255, 255) or Color(185, 185, 185)

                surface.SetMaterial(Material(logo, "smooth"))
                surface.SetDrawColor(selColor)
                surface.DrawTexturedRect(5, 5, sw - 10, sh - 10)
            end
            btn.DoClick = function()
                for _, prevBtn in ipairs(logoButtons) do
                    prevBtn._isSelected = false
                end
                btn._isSelected = true
                newLogoIndex = i
            end
            logoButtons[i] = btn
        end

        local btnPanel = vgui.Create("DPanel", container)
        btnPanel:SetTall(40)
        btnPanel:Dock(BOTTOM)
        btnPanel:DockMargin(0, 0, 0, 15)
        btnPanel.Paint = function() end

        local saveBtn = vgui.Create("DButton", btnPanel)
        saveBtn:SetText("Save Logo")
        saveBtn:SetFont("DinPro")
        saveBtn:SetWide(150)
        saveBtn:SetTextColor(color_white)
        saveBtn:Dock(LEFT)
        saveBtn:DockMargin(150, 0, 0, 0)
        saveBtn.Paint = UI_PaintBasicDialogButton
        saveBtn.DoClick = function()
            Monarch.Factions.Edit(faction.id, "logoIndex", newLogoIndex)
            UI_FadeClose(logoFrame)
        end

        local cancelBtn = vgui.Create("DButton", btnPanel)
        cancelBtn:SetText("Cancel")
        cancelBtn:SetFont("DinPro")
        cancelBtn:SetWide(150)
        cancelBtn:SetTextColor(color_white)
        cancelBtn:Dock(LEFT)
        cancelBtn.Paint = UI_PaintBasicDialogButton
        cancelBtn.DoClick = function()
            UI_FadeClose(logoFrame)
        end
    end)
    editLogoBtn:SetVisible(false)

    local announcementBtn = addActionButton(base, "Make Announcement", Scale(805), function()
        if not (Monarch.Factions and Monarch.Factions.PlayerFaction) then return end
        local faction = Monarch.Factions.PlayerFaction

        local f = UI_CreateFullscreenOverlay()

        local container = vgui.Create("DPanel", f)
        container:SetSize(600, 350)
        container:Center()
        container.Paint = function() end

        local title = vgui.Create("DLabel", container)
        title:SetText("Make Announcement")
        title:SetFont("DinProLarge")
        title:SetTextColor(color_white)
        title:SetContentAlignment(5)
        title:Dock(TOP)
        title:DockMargin(0, 20, 0, 20)
        title:SetTall(32)

        local lbl = vgui.Create("DLabel", container)
        lbl:SetText("Send an announcement to all faction members.")
        lbl:SetFont("DinPro")
        lbl:SetTextColor(color_white)
        lbl:SetContentAlignment(5)
        lbl:Dock(TOP)
        lbl:DockMargin(0, 0, 0, 20)
        lbl:SetTall(24)

        local msgPanel = vgui.Create("DPanel", container)
        msgPanel:SetTall(150)
        msgPanel:Dock(TOP)
        msgPanel:DockMargin(0, 0, 0, 20)
        msgPanel.Paint = function() end

        local msgLabel = vgui.Create("DLabel", msgPanel)
        msgLabel:SetText("Announcement Message")
        msgLabel:SetFont("DinPro")
        msgLabel:SetTextColor(Color(200, 200, 200))
        msgLabel:SetContentAlignment(5)
        msgLabel:Dock(TOP)
        msgLabel:DockMargin(0, 5, 0, 5)
        msgLabel:SetTall(20)

        local msgInput = vgui.Create("DTextEntry", msgPanel)
        msgInput:SetFont("DinPro")
        msgInput:SetTextColor(color_white)
        msgInput:SetMultiline(true)
        msgInput:SetPaintBackground(true)
        msgInput.Paint = function(s, pw, ph)
            draw.RoundedBox(0, 0, 0, pw, ph, Color(40, 40, 40))
            s:DrawTextEntryText(s:GetTextColor(), s:GetHighlightColor(), s:GetCursorColor())
        end
        msgInput:Dock(TOP)
        msgInput:DockMargin(80, 0, 80, 0)
        msgInput:SetTall(110)
        msgInput:RequestFocus()

        local btnPanel = vgui.Create("DPanel", container)
        btnPanel:SetTall(44)
        btnPanel:Dock(BOTTOM)
        btnPanel:DockMargin(0, 0, 0, 0)
        btnPanel.Paint = function() end

        local sendBtn = vgui.Create("DButton", btnPanel)
        sendBtn:SetText("Send Announcement")
        sendBtn:SetFont("DinPro")
        sendBtn:SetWide(180)
        sendBtn:SetTextColor(color_white)
        sendBtn:Dock(FILL)
        sendBtn:DockMargin(160, 0, 160, 0)
        sendBtn.Paint = UI_PaintBasicDialogButton
        sendBtn.DoClick = function()
            local message = msgInput:GetValue()
            if message == "" or string.len(message) < 3 then
                self:ShowNotification("Announcement must be at least 3 characters", Color(200, 100, 100), 3)
                return
            end

            net.Start("Monarch_Faction_Announcement")
            net.WriteString(message)
            net.SendToServer()

            UI_FadeClose(f)
        end
    end)
    announcementBtn:SetVisible(false)

    local roleBtn = addActionButton(base, "Edit Roles", Scale(965), function()
        if not (Monarch.Factions and Monarch.Factions.PlayerFaction) then return end

        local faction = Monarch.Factions.PlayerFaction
        if not IsLocalFactionFounder(faction) then
            self:ShowNotification("Only faction founder can manage roles", Color(200, 100, 100), 3)
            return
        end

        if not IsValid(self.inventoryRoleScroll) or not IsValid(self.inventoryMemberScroll) then return end

        self.inventoryRoleScroll:SetVisible(true)
        self.inventoryMemberScroll:SetVisible(false)

        local function populateRoleList()
            if not IsValid(self.inventoryRoleScroll) then return end

            if not (Monarch.Factions and Monarch.Factions.PlayerFaction) then return end
            local faction = Monarch.Factions.PlayerFaction

            local roleList = self.inventoryRoleScroll:GetCanvas()
            roleList:Clear()
            local roles = faction.roles or {}

            local titleLabel = vgui.Create("DLabel", roleList)
            titleLabel:SetFont("InvMed")
            titleLabel:SetColor(Color(200, 200, 200))
            titleLabel:SetText("FACTION ROLES")
            titleLabel:Dock(TOP)
            titleLabel:DockMargin(10, 8, 0, 4)
            titleLabel:SetTall(Scale(16))

            local descLabel = vgui.Create("DLabel", roleList)
            descLabel:SetFont("InvSmall")
            descLabel:SetColor(Color(130, 130, 130))
            descLabel:SetText("Manage custom roles for your faction members.")
            descLabel:Dock(TOP)
            descLabel:DockMargin(10, 0, 0, 12)
            descLabel:SetTall(Scale(14))

            if table.Count(roles) == 0 then

                local founderPanel = vgui.Create("DPanel", roleList)
                founderPanel:Dock(TOP)
                founderPanel:DockMargin(0, 0, 0, 6)
                founderPanel:SetTall(Scale(70))

                founderPanel.Paint = function(s, w, h)

                    draw.RoundedBox(0, 0, 0, w, h, Color(42, 42, 45, 255))
                    surface.SetDrawColor(35, 35, 35, 255)
                    surface.DrawRect(0, 0, w, h)

                    local gradientMat = Material("vgui/gradient-l")
                    if gradientMat and not gradientMat:IsError() then
                        surface.SetMaterial(gradientMat)
                        surface.SetDrawColor(faction.color.r, faction.color.g, faction.color.b, 25)
                        local gradW = w * 0.35
                        surface.DrawTexturedRect(0, 0, gradW, h)
                    end

                    surface.SetDrawColor(100, 100, 100, 200)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end

                local colorBox = vgui.Create("DPanel", founderPanel)
                colorBox:SetPos(Scale(10), Scale(12))
                colorBox:SetSize(Scale(20), Scale(20))
                colorBox.Paint = function(s, w, h)
                    draw.RoundedBox(2, 0, 0, w, h, Color(faction.color.r, faction.color.g, faction.color.b, 255))
                end

                local nameLabel = vgui.Create("DLabel", founderPanel)
                nameLabel:SetPos(Scale(38), Scale(8))
                nameLabel:SetSize(Scale(300), Scale(20))
                nameLabel:SetFont("InvMed")
                nameLabel:SetTextColor(Color(245, 245, 245))
                nameLabel:SetText("Founder")
                nameLabel:SetContentAlignment(4)

                local precLabel = vgui.Create("DLabel", founderPanel)
                precLabel:SetPos(Scale(38), Scale(30))
                precLabel:SetSize(Scale(300), Scale(16))
                precLabel:SetFont("InvSmall")
                precLabel:SetTextColor(Color(160, 160, 160))
                precLabel:SetText("Precedence: 999 (Default)")
                precLabel:SetContentAlignment(4)
            else

                local founderPanel = vgui.Create("DPanel", roleList)
                founderPanel:Dock(TOP)
                founderPanel:DockMargin(0, 0, 0, 6)
                founderPanel:SetTall(Scale(70))

                founderPanel.Paint = function(s, w, h)

                    draw.RoundedBox(0, 0, 0, w, h, Color(42, 42, 45, 255))
                    surface.SetDrawColor(35, 35, 35, 255)
                    surface.DrawRect(0, 0, w, h)

                    local gradientMat = Material("vgui/gradient-l")
                    if gradientMat and not gradientMat:IsError() then
                        surface.SetMaterial(gradientMat)
                        surface.SetDrawColor(faction.color.r, faction.color.g, faction.color.b, 25)
                        local gradW = w * 0.35
                        surface.DrawTexturedRect(0, 0, gradW, h)
                    end

                    surface.SetDrawColor(100, 100, 100, 200)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end

                local colorBox = vgui.Create("DPanel", founderPanel)
                colorBox:SetPos(Scale(10), Scale(12))
                colorBox:SetSize(Scale(20), Scale(20))
                colorBox.Paint = function(s, w, h)
                    draw.RoundedBox(2, 0, 0, w, h, Color(faction.color.r, faction.color.g, faction.color.b, 255))
                end

                local nameLabel = vgui.Create("DLabel", founderPanel)
                nameLabel:SetPos(Scale(38), Scale(8))
                nameLabel:SetSize(Scale(300), Scale(20))
                nameLabel:SetFont("InvMed")
                nameLabel:SetTextColor(Color(245, 245, 245))
                nameLabel:SetText("Founder")
                nameLabel:SetContentAlignment(4)

                local precLabel = vgui.Create("DLabel", founderPanel)
                precLabel:SetPos(Scale(38), Scale(30))
                precLabel:SetSize(Scale(300), Scale(16))
                precLabel:SetFont("InvSmall")
                precLabel:SetTextColor(Color(160, 160, 160))
                precLabel:SetText("Precedence: 999 (Default)")
                precLabel:SetContentAlignment(4)

                for roleID, role in pairs(roles) do
                    local rolePanel = vgui.Create("DPanel", roleList)
                    rolePanel:Dock(TOP)
                    rolePanel:DockMargin(0, 0, 0, 6)
                    rolePanel:SetTall(Scale(70))

                    rolePanel.Paint = function(s, w, h)

                        draw.RoundedBox(0, 0, 0, w, h, Color(42, 42, 45, 255))
                        surface.SetDrawColor(35, 35, 35, 255)
                        surface.DrawRect(0, 0, w, h)

                        local gradientMat = Material("vgui/gradient-l")
                        if gradientMat and not gradientMat:IsError() then
                            surface.SetMaterial(gradientMat)
                            surface.SetDrawColor(role.color.r, role.color.g, role.color.b, 25)
                            local gradW = w * 0.35
                            surface.DrawTexturedRect(0, 0, gradW, h)
                        end

                        surface.SetDrawColor(100, 100, 100, 200)
                        surface.DrawOutlinedRect(0, 0, w, h, 1)
                    end

                    local colorBox = vgui.Create("DPanel", rolePanel)
                    colorBox:SetPos(Scale(10), Scale(12))
                    colorBox:SetSize(Scale(20), Scale(20))
                    colorBox.Paint = function(s, w, h)
                        draw.RoundedBox(2, 0, 0, w, h, Color(role.color.r, role.color.g, role.color.b, 255))
                    end

                    local nameLabel = vgui.Create("DLabel", rolePanel)
                    nameLabel:SetPos(Scale(38), Scale(8))
                    nameLabel:SetSize(Scale(300), Scale(20))
                    nameLabel:SetFont("InvMed")
                    nameLabel:SetTextColor(Color(245, 245, 245))
                    nameLabel:SetText(role.name)
                    nameLabel:SetContentAlignment(4)

                    local precLabel = vgui.Create("DLabel", rolePanel)
                    precLabel:SetPos(Scale(38), Scale(30))
                    precLabel:SetSize(Scale(300), Scale(16))
                    precLabel:SetFont("InvSmall")
                    precLabel:SetTextColor(Color(160, 160, 160))
                    precLabel:SetText("Precedence: " .. role.precedence)
                    precLabel:SetContentAlignment(4)

                    local editBtn = vgui.Create("DButton", rolePanel)
                    editBtn:SetPos(Scale(420), Scale(20))
                    editBtn:SetSize(Scale(140), Scale(32))
                    editBtn:SetText("Edit")
                    editBtn:SetFont("InvSmall")
                    editBtn:SetTextColor(Color(230, 230, 230))
                    editBtn._wasHovered = false
                    editBtn.Paint = function(s, w, h)
                        local isHovered = s:IsHovered()
                        local baseCol = Color(55, 55, 55, 200)
                        local gradCol = Color(65,65,65, 25)

                        surface.SetDrawColor(baseCol)
                        surface.DrawRect(0, 0, w, h)

                        surface.SetMaterial(Material("mrp/gradient_corner_2k.png", "smooth"))
                        surface.SetDrawColor(gradCol)
                        surface.DrawTexturedRect(0, 0, w, h)

                        if isHovered then
                            surface.SetDrawColor(Color(100, 150, 200, 30))
                            surface.DrawRect(0, 0, w, h)
                        end

                        surface.SetDrawColor(isHovered and Color(70, 70, 70, 120) or Color(45, 45, 45, 60))
                        surface.DrawOutlinedRect(0, 0, w, h, 2)
                    end
                    editBtn.DoClick = function()

                        local editFrame = UI_CreateFullscreenOverlay()

                        local container = vgui.Create("DPanel", editFrame)
                        container:SetSize(600, 650)
                        container:Center()
                        container.Paint = function() end

                        local title = vgui.Create("DLabel", container)
                        title:SetText("Edit Role")
                        title:SetFont("DinProLarge")
                        title:SetTextColor(color_white)
                        title:SetContentAlignment(5)
                        title:Dock(TOP)
                        title:DockMargin(0, 20, 0, 20)
                        title:SetTall(32)

                        local lbl = vgui.Create("DLabel", container)
                        lbl:SetText("Modify role properties for " .. role.name .. ".")
                        lbl:SetFont("DinPro")
                        lbl:SetTextColor(color_white)
                        lbl:SetContentAlignment(5)
                        lbl:Dock(TOP)
                        lbl:DockMargin(0, 0, 0, 20)
                        lbl:SetTall(24)

                        local namePanel = vgui.Create("DPanel", container)
                        namePanel:SetTall(50)
                        namePanel:Dock(TOP)
                        namePanel:DockMargin(0, 0, 0, 15)
                        namePanel.Paint = function() end

                        local nameLabel = vgui.Create("DLabel", namePanel)
                        nameLabel:SetText("Role Name")
                        nameLabel:SetFont("DinPro")
                        nameLabel:SetTextColor(Color(200, 200, 200))
                        nameLabel:Dock(TOP)
                        nameLabel:DockMargin(80, 5, 0, 5)
                        nameLabel:SetTall(20)

                        local nameInput = vgui.Create("DTextEntry", namePanel)
                        nameInput:SetFont("DinPro")
                        nameInput:SetTextColor(color_white)
                        nameInput:SetText(role.name)
                        nameInput:SetPaintBackground(true)
                        nameInput.Paint = function(s, pw, ph)
                            draw.RoundedBox(0, 0, 0, pw, ph, Color(40, 40, 40))
                            s:DrawTextEntryText(s:GetTextColor(), s:GetHighlightColor(), s:GetCursorColor())
                        end
                        nameInput:Dock(TOP)
                        nameInput:DockMargin(80, 0, 80, 0)
                        nameInput:SetTall(24)

                        local precPanel = vgui.Create("DPanel", container)
                        precPanel:SetTall(50)
                        precPanel:Dock(TOP)
                        precPanel:DockMargin(0, 0, 0, 15)
                        precPanel.Paint = function() end

                        local precLabel = vgui.Create("DLabel", precPanel)
                        precLabel:SetText("Precedence")
                        precLabel:SetFont("DinPro")
                        precLabel:SetTextColor(Color(200, 200, 200))
                        precLabel:Dock(TOP)
                        precLabel:DockMargin(80, 5, 0, 5)
                        precLabel:SetTall(20)

                        local precInput = vgui.Create("DNumberWang", precPanel)
                        precInput:SetFont("DinPro")
                        precInput:SetTextColor(color_white)
                        precInput:SetValue(role.precedence)
                        precInput:SetMin(0)
                        precInput:SetMax(9999)
                        precInput.Paint = function(s, pw, ph)
                            draw.RoundedBox(0, 0, 0, pw, ph, Color(40, 40, 40))
                            s:DrawTextEntryText(s:GetTextColor(), s:GetHighlightColor(), s:GetCursorColor())
                        end
                        precInput:Dock(TOP)
                        precInput:DockMargin(80, 0, 80, 0)
                        precInput:SetTall(24)

                        local colorPanel = vgui.Create("DPanel", container)
                        colorPanel:SetTall(150)
                        colorPanel:Dock(TOP)
                        colorPanel:DockMargin(0, 0, 0, 20)
                        colorPanel.Paint = function() end

                        local colorLabel = vgui.Create("DLabel", colorPanel)
                        colorLabel:SetText("Color")
                        colorLabel:SetFont("DinPro")
                        colorLabel:SetTextColor(Color(200, 200, 200))
                        colorLabel:Dock(TOP)
                        colorLabel:DockMargin(80, 5, 0, 10)
                        colorLabel:SetTall(20)

                        local colorMixer = vgui.Create("DColorMixer", colorPanel)
                        colorMixer:SetColor(Color(role.color.r, role.color.g, role.color.b))
                        colorMixer:SetPalette(false)
                        colorMixer:SetAlphaBar(false)
                        colorMixer:Dock(TOP)
                        colorMixer:DockMargin(80, 0, 80, 0)
                        colorMixer:SetTall(100)

                        local permPanel = vgui.Create("DPanel", container)
                        permPanel:SetTall(140)
                        permPanel:Dock(TOP)
                        permPanel:DockMargin(0, 0, 0, 15)
                        permPanel.Paint = function() end

                        local permLabel = vgui.Create("DLabel", permPanel)
                        permLabel:SetText("Permissions")
                        permLabel:SetFont("DinPro")
                        permLabel:SetTextColor(Color(200, 200, 200))
                        permLabel:Dock(TOP)
                        permLabel:DockMargin(80, 5, 0, 10)
                        permLabel:SetTall(20)

                        local permChecks = {}
                        local permissions = {
                            {key = "invite", label = "Invite Members"},
                            {key = "editInfo", label = "Edit Faction Info"},
                            {key = "kick", label = "Kick Members"},
                            {key = "lockInvites", label = "Lock Invites"},
                            {key = "manageRoles", label = "Manage Roles"},
                            {key = "makeAnnouncements", label = "Make Announcements"},
                        }

                        local permGrid = vgui.Create("DPanel", permPanel)
                        permGrid:Dock(TOP)
                        permGrid:DockMargin(80, 0, 80, 0)
                        permGrid:SetTall(100)
                        permGrid.Paint = function() end

                        local col1 = vgui.Create("DPanel", permGrid)
                        col1:Dock(LEFT)
                        col1:SetWide(150)
                        col1.Paint = function() end

                        local col2 = vgui.Create("DPanel", permGrid)
                        col2:Dock(LEFT)
                        col2:SetWide(150)
                        col2.Paint = function() end

                        for i, perm in ipairs(permissions) do
                            local col = (i % 2 == 1) and col1 or col2
                            local chk = vgui.Create("DCheckBoxLabel", col)
                            chk:SetText(perm.label)
                            chk:SetFont("DinPro")
                            chk:SetTextColor(Color(200, 200, 200))
                            chk:Dock(TOP)
                            chk:DockMargin(0, 2, 0, 2)
                            chk:SetTall(24)
                            chk:SetChecked(role.permissions and role.permissions[perm.key] or false)
                            permChecks[perm.key] = chk
                        end

                        local btnPanel = vgui.Create("DPanel", container)
                        btnPanel:SetTall(40)
                        btnPanel:Dock(BOTTOM)
                        btnPanel:DockMargin(0, 0, 0, 15)
                        btnPanel.Paint = function() end

                        local saveBtn = vgui.Create("DButton", btnPanel)
                        saveBtn:SetText("Save Changes")
                        saveBtn:SetFont("DinPro")
                        saveBtn:SetWide(120)
                        saveBtn:SetTextColor(color_white)
                        saveBtn:Dock(LEFT)
                        saveBtn:DockMargin(100, 0, 10, 0)
                        saveBtn.Paint = UI_PaintBasicDialogButton
                        saveBtn.DoClick = function()
                            local newName = nameInput:GetValue()
                            if newName == "" then
                                self:ShowNotification("Role name cannot be empty", Color(200, 100, 100), 2)
                                return
                            end

                            local newColor = colorMixer:GetColor()
                            local newPrec = precInput:GetValue()

                            local perms = {}
                            for key, chk in pairs(permChecks) do
                                perms[key] = chk:GetChecked()
                            end

                            net.Start("Monarch_Role_Update")
                            net.WriteString(roleID)
                            net.WriteString(newName)
                            net.WriteUInt(newColor.r, 8)
                            net.WriteUInt(newColor.g, 8)
                            net.WriteUInt(newColor.b, 8)
                            net.WriteUInt(newPrec, 16)
                            net.WriteTable(perms)
                            net.SendToServer()

                            timer.Simple(0.1, function()
                                if Monarch.Factions and Monarch.Factions.RequestPlayerFaction then
                                    Monarch.Factions.RequestPlayerFaction()
                                end
                            end)

                            UI_FadeClose(editFrame)
                        end

                        local deleteBtn = vgui.Create("DButton", btnPanel)
                        deleteBtn:SetText("Delete Role")
                        deleteBtn:SetFont("DinPro")
                        deleteBtn:SetWide(120)
                        deleteBtn:SetTextColor(color_white)
                        deleteBtn:Dock(LEFT)
                        deleteBtn:DockMargin(0, 0, 10, 0)
                        deleteBtn.Paint = function(s, pw, ph)
                            local bgColor = s:IsHovered() and Color(120, 20, 20, 200) or Color(80, 0, 0, 100)
                            draw.RoundedBox(0, 0, 0, pw, ph, bgColor)
                        end
                        deleteBtn.DoClick = function()
                            net.Start("Monarch_Role_Delete")
                            net.WriteString(roleID)
                            net.SendToServer()

                            timer.Simple(0.1, function()
                                if Monarch.Factions and Monarch.Factions.RequestPlayerFaction then
                                    Monarch.Factions.RequestPlayerFaction()
                                end
                            end)

                            UI_FadeClose(editFrame)
                        end

                        local cancelBtn = vgui.Create("DButton", btnPanel)
                        cancelBtn:SetText("Cancel")
                        cancelBtn:SetFont("DinPro")
                        cancelBtn:SetWide(120)
                        cancelBtn:SetTextColor(color_white)
                        cancelBtn:Dock(LEFT)
                        cancelBtn.Paint = UI_PaintBasicDialogButton
                        cancelBtn.DoClick = function()
                            UI_FadeClose(editFrame)
                        end
                    end
                end
            end

            local createRolePanel = vgui.Create("DPanel", roleList)
            createRolePanel:Dock(TOP)
            createRolePanel:DockMargin(0, 12, 0, 0)
            createRolePanel:SetTall(Scale(40))
            createRolePanel.Paint = function() end

            local createRoleBtn = vgui.Create("DButton", createRolePanel)
            createRoleBtn:SetPos(Scale(10), 0)
            createRoleBtn:SetSize(Scale(560), Scale(38))
            createRoleBtn:SetText("+ Create New Role")
            createRoleBtn:SetFont("InvSmall")
            createRoleBtn:SetTextColor(Color(230, 230, 230))
            createRoleBtn._wasHovered = false
            createRoleBtn.Paint = function(s, w, h)
                local isHovered = s:IsHovered()
                local baseCol = Color(55, 55, 55, 200)
                local gradCol = Color(65,65,65, 25)

                surface.SetDrawColor(baseCol)
                surface.DrawRect(0, 0, w, h)

                surface.SetMaterial(Material("mrp/gradient_corner_2k.png", "smooth"))
                surface.SetDrawColor(gradCol)
                surface.DrawTexturedRect(0, 0, w, h)

                if isHovered then
                    surface.SetDrawColor(Color(100, 150, 200, 30))
                    surface.DrawRect(0, 0, w, h)
                end

                surface.SetDrawColor(isHovered and Color(70, 70, 70, 120) or Color(45, 45, 45, 60))
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            end
            createRoleBtn.DoClick = function()

                local createFrame = UI_CreateFullscreenOverlay()

                local container = vgui.Create("DPanel", createFrame)
                container:SetSize(600, 600)
                container:Center()
                container.Paint = function() end

                local title = vgui.Create("DLabel", container)
                title:SetText("Create New Role")
                title:SetFont("DinProLarge")
                title:SetTextColor(color_white)
                title:SetContentAlignment(5)
                title:Dock(TOP)
                title:DockMargin(0, 20, 0, 20)
                title:SetTall(32)

                local lbl = vgui.Create("DLabel", container)
                lbl:SetText("Configure a new role for your faction members.")
                lbl:SetFont("DinPro")
                lbl:SetTextColor(color_white)
                lbl:SetContentAlignment(5)
                lbl:Dock(TOP)
                lbl:DockMargin(0, 0, 0, 20)
                lbl:SetTall(24)

                local namePanel = vgui.Create("DPanel", container)
                namePanel:SetTall(50)
                namePanel:Dock(TOP)
                namePanel:DockMargin(0, 0, 0, 15)
                namePanel.Paint = function() end

                local nameLabel = vgui.Create("DLabel", namePanel)
                nameLabel:SetText("Role Name")
                nameLabel:SetFont("DinPro")
                nameLabel:SetTextColor(Color(200, 200, 200))
                nameLabel:Dock(TOP)
                nameLabel:DockMargin(80, 5, 0, 5)
                nameLabel:SetTall(20)

                local nameInput = vgui.Create("DTextEntry", namePanel)
                nameInput:SetFont("DinPro")
                nameInput:SetTextColor(color_white)
                nameInput:SetPaintBackground(true)
                nameInput.Paint = function(s, pw, ph)
                    draw.RoundedBox(0, 0, 0, pw, ph, Color(40, 40, 40))
                    s:DrawTextEntryText(s:GetTextColor(), s:GetHighlightColor(), s:GetCursorColor())
                end
                nameInput:Dock(TOP)
                nameInput:DockMargin(80, 0, 80, 0)
                nameInput:SetTall(24)
                nameInput:RequestFocus()

                local precPanel = vgui.Create("DPanel", container)
                precPanel:SetTall(50)
                precPanel:Dock(TOP)
                precPanel:DockMargin(0, 0, 0, 15)
                precPanel.Paint = function() end

                local precLabel = vgui.Create("DLabel", precPanel)
                precLabel:SetText("Precedence")
                precLabel:SetFont("DinPro")
                precLabel:SetTextColor(Color(200, 200, 200))
                precLabel:Dock(TOP)
                precLabel:DockMargin(80, 5, 0, 5)
                precLabel:SetTall(20)

                local precInput = vgui.Create("DNumberWang", precPanel)
                precInput:SetFont("DinPro")
                precInput:SetTextColor(color_white)
                precInput:SetValue(0)
                precInput:SetMin(0)
                precInput:SetMax(9999)
                precInput.Paint = function(s, pw, ph)
                    draw.RoundedBox(0, 0, 0, pw, ph, Color(40, 40, 40))
                    s:DrawTextEntryText(s:GetTextColor(), s:GetHighlightColor(), s:GetCursorColor())
                end
                precInput:Dock(TOP)
                precInput:DockMargin(80, 0, 80, 0)
                precInput:SetTall(24)

                local colorPanel = vgui.Create("DPanel", container)
                colorPanel:SetTall(150)
                colorPanel:Dock(TOP)
                colorPanel:DockMargin(0, 0, 0, 20)
                colorPanel.Paint = function() end

                local colorLabel = vgui.Create("DLabel", colorPanel)
                colorLabel:SetText("Color")
                colorLabel:SetFont("DinPro")
                colorLabel:SetTextColor(Color(200, 200, 200))
                colorLabel:Dock(TOP)
                colorLabel:DockMargin(80, 5, 0, 10)
                colorLabel:SetTall(20)

                local colorMixer = vgui.Create("DColorMixer", colorPanel)
                colorMixer:SetColor(Color(100, 150, 200))
                colorMixer:SetPalette(false)
                colorMixer:SetAlphaBar(false)
                colorMixer:Dock(TOP)
                colorMixer:DockMargin(80, 0, 80, 0)
                colorMixer:SetTall(100)

                local permPanel = vgui.Create("DPanel", container)
                permPanel:SetTall(140)
                permPanel:Dock(TOP)
                permPanel:DockMargin(0, 0, 0, 15)
                permPanel.Paint = function() end

                local permLabel = vgui.Create("DLabel", permPanel)
                permLabel:SetText("Permissions")
                permLabel:SetFont("DinPro")
                permLabel:SetTextColor(Color(200, 200, 200))
                permLabel:Dock(TOP)
                permLabel:DockMargin(80, 5, 0, 10)
                permLabel:SetTall(20)

                local permChecks = {}
                local permissions = {
                    {key = "invite", label = "Invite Members"},
                    {key = "editInfo", label = "Edit Faction Info"},
                    {key = "kick", label = "Kick Members"},
                    {key = "manageRoles", label = "Manage Roles"},
                    {key = "makeAnnouncements", label = "Make Announcements"},
                }

                local permGrid = vgui.Create("DPanel", permPanel)
                permGrid:Dock(TOP)
                permGrid:DockMargin(80, 0, 80, 0)
                permGrid:SetTall(100)
                permGrid.Paint = function() end

                local col1 = vgui.Create("DPanel", permGrid)
                col1:Dock(LEFT)
                col1:SetWide(150)
                col1.Paint = function() end

                local col2 = vgui.Create("DPanel", permGrid)
                col2:Dock(LEFT)
                col2:SetWide(150)
                col2.Paint = function() end

                local col3 = vgui.Create("DPanel", permGrid)
                col3:Dock(FILL)
                col3.Paint = function() end

                for i, perm in ipairs(permissions) do
                    local col = (i % 2 == 1) and col1 or col2
                    local chk = vgui.Create("DCheckBoxLabel", col)
                    chk:SetText(perm.label)
                    chk:SetFont("DinPro")
                    chk:SetTextColor(Color(200, 200, 200))
                    chk:Dock(TOP)
                    chk:DockMargin(0, 2, 0, 2)
                    chk:SetTall(24)
                    chk:SetChecked(false)
                    permChecks[perm.key] = chk
                end

                local btnPanel = vgui.Create("DPanel", container)
                btnPanel:SetTall(40)
                btnPanel:Dock(BOTTOM)
                btnPanel:DockMargin(0, 0, 0, 15)
                btnPanel.Paint = function() end

                local okBtn = vgui.Create("DButton", btnPanel)
                okBtn:SetText("Create")
                okBtn:SetFont("DinPro")
                okBtn:SetWide(150)
                okBtn:SetTextColor(color_white)
                okBtn:Dock(LEFT)
                okBtn:DockMargin(150, 0, 0, 0)
                okBtn.Paint = UI_PaintBasicDialogButton
                okBtn.DoClick = function()
                    local name = nameInput:GetValue()
                    if name == "" then
                        self:ShowNotification("Role name cannot be empty", Color(200, 100, 100), 2)
                        return
                    end

                    local color = colorMixer:GetColor()
                    local prec = precInput:GetValue()

                    local perms = {}
                    for key, chk in pairs(permChecks) do
                        perms[key] = chk:GetChecked()
                    end

                    net.Start("Monarch_Role_Create")
                    net.WriteString(name)
                    net.WriteUInt(color.r, 8)
                    net.WriteUInt(color.g, 8)
                    net.WriteUInt(color.b, 8)
                    net.WriteUInt(prec, 16)
                    net.WriteTable(perms)
                    net.SendToServer()

                    timer.Simple(0.1, function()
                        if Monarch.Factions and Monarch.Factions.RequestPlayerFaction then
                            Monarch.Factions.RequestPlayerFaction()
                        end
                    end)

                    UI_FadeClose(createFrame)
                end

                local cancelBtn = vgui.Create("DButton", btnPanel)
                cancelBtn:SetText("Cancel")
                cancelBtn:SetFont("DinPro")
                cancelBtn:SetWide(150)
                cancelBtn:SetTextColor(color_white)
                cancelBtn:Dock(LEFT)
                cancelBtn.Paint = UI_PaintBasicDialogButton
                cancelBtn.DoClick = function()
                    UI_FadeClose(createFrame)
                end
            end
        end

        Monarch.Factions.OnRoleListUpdate = populateRoleList

        populateRoleList()
    end)
    roleBtn:SetVisible(false)

    local viewMembersBtn = addActionButton(base, "View Members", Scale(1005), function()
        if not (Monarch.Factions and Monarch.Factions.PlayerFaction) then return end
        if IsValid(self.inventoryMemberScroll) then

            self.inventoryMemberScroll:SetVisible(true)
            self.inventoryRoleScroll:SetVisible(false)
        end
    end)
    viewMembersBtn:SetVisible(false)

    local leaveBtn = addActionButton(base, "Leave Faction", Scale(1405), function()
        if not (Monarch.Factions and Monarch.Factions.Leave) then return end

        local faction = Monarch.Factions.PlayerFaction
        local isOwner = IsLocalFactionFounder(faction)

        local f = UI_CreateFullscreenOverlay()

        local container = vgui.Create("DPanel", f)
        container:SetSize(600, 250)
        container:Center()
        container.Paint = function() end

        local title = vgui.Create("DLabel", container)
        title:SetText(isOwner and "Disband Faction" or "Leave Faction")
        title:SetFont("DinProLarge")
        title:SetTextColor(color_white)
        title:SetContentAlignment(5)
        title:Dock(TOP)
        title:DockMargin(0, 20, 0, 20)
        title:SetTall(32)

        local msgLabel = vgui.Create("DLabel", container)
        msgLabel:SetFont("DinPro")
        msgLabel:SetTextColor(color_white)
        msgLabel:SetContentAlignment(5)  
        if isOwner then
            msgLabel:SetText("As the faction owner, leaving will\ndisband the faction and remove all members.\n\nAre you sure?")
        else
            msgLabel:SetText("Are you sure you want to leave\nthis faction?")
        end
        msgLabel:Dock(TOP)
        msgLabel:DockMargin(0, 0, 0, 25)
        msgLabel:SetTall(90)
        msgLabel:SetAutoStretchVertical(false)

        local btnPanel = vgui.Create("DPanel", container)
        btnPanel:SetTall(40)
        btnPanel:Dock(BOTTOM)
        btnPanel:DockMargin(0, 0, 0, 15)
        btnPanel.Paint = function() end

        local confirmBtn = vgui.Create("DButton", btnPanel)
        confirmBtn:SetText(isOwner and "Disband Faction" or "Leave")
        confirmBtn:SetFont("DinPro")
        confirmBtn:SetWide(150)
        confirmBtn:SetTextColor(color_white)
        confirmBtn:Dock(LEFT)
        confirmBtn:DockMargin(150, 0, 0, 0)
        confirmBtn.Paint = UI_PaintBasicDialogButton
        confirmBtn.DoClick = function()
            Monarch.Factions.Leave()
            UI_FadeClose(f)
        end

        local cancelBtn = vgui.Create("DButton", btnPanel)
        cancelBtn:SetText("Cancel")
        cancelBtn:SetFont("DinPro")
        cancelBtn:SetWide(150)
        cancelBtn:SetTextColor(color_white)
        cancelBtn:Dock(LEFT)
        cancelBtn:DockMargin(0, 0, 0, 0)
        cancelBtn.Paint = UI_PaintBasicDialogButton
        cancelBtn.DoClick = function()
            UI_FadeClose(f)
        end
    end)
    leaveBtn:SetVisible(false)

    local lastFactionID = nil
    function base:Think()
        local hasPlayerFaction = Monarch.Factions and Monarch.Factions.PlayerFaction and istable(Monarch.Factions.PlayerFaction)

        if not hasPlayerFaction then
            local logos = Config and Config.FactionIcons or {}
            local logoPath = logos[selectedLogo] or ""
            if IsValid(previewLogo) then
                previewLogo:SetImage(logoPath)
                previewLogo:SetImageColor(color_white)
            end
            if IsValid(previewTitle) then
                local fname = factionName:GetValue()
                previewTitle:SetText(fname ~= "" and fname or "Your New Faction")
            end
        end

        if hasPlayerFaction then
            local faction = Monarch.Factions.PlayerFaction

            if lastFactionID ~= faction.id then
                lastFactionID = faction.id

                factionName:SetValue(faction.name or "")
                local founderMember = GetFounderMemberData(faction)
                founderRole:SetValue(founderMember and founderMember.role or "")

                if faction.color then
                    selectedColor = Color(faction.color.r or 100, faction.color.g or 100, faction.color.b or 100)
                    if IsValid(colorCube) then colorCube:SetRGB(selectedColor.r, selectedColor.g, selectedColor.b) end
                    if IsValid(rgbPicker) then rgbPicker:SetRGB(selectedColor.r, selectedColor.g, selectedColor.b) end
                end

                if faction.logoIndex then
                    selectedLogo = faction.logoIndex
                    for i, btn in ipairs(logoButtons) do
                        btn._isSelected = (i == selectedLogo)
                    end
                end
            end

            local logos = Config and Config.FactionIcons or {}
            local logoPath = logos[selectedLogo] or ""
            if IsValid(previewLogo) then
                previewLogo:SetImage(logoPath)
                previewLogo:SetImageColor(color_white)
            end
            if IsValid(previewTitle) then
                previewTitle:SetText(faction.name or "Unknown")
            end
            if IsValid(previewSubtitle) then
                previewSubtitle:SetText("Manage your faction")
            end

            local members = faction.members or {}
            local memberCount = table.Count(members)
            local localCharID = LocalPlayer():GetNWString("MonarchCharID", "")
            if localCharID == "" then
                localCharID = LocalPlayer().MonarchID or (LocalPlayer().MonarchActiveChar and LocalPlayer().MonarchActiveChar.id)
            end
            local playerData = (localCharID and members[tostring(localCharID)]) or {}
            local playerRole = playerData.role or "Member"
            infoText:SetText("Faction: " .. (faction.name or "Unknown") .. "\nMembers: " .. memberCount .. "\nYour Role: " .. playerRole)

            local memberHash = ""
            for charID, memberData in pairs(faction.members or {}) do
                local isOnline = false
                local targetKey = tostring(charID)
                local memberSID = memberData and tostring(memberData.steamid or "")
                for _, ply in player.Iterator() do
                    local plyCharID = ply:GetNWString("MonarchCharID", "")
                    if plyCharID == "" and ply.MonarchActiveChar and ply.MonarchActiveChar.id then
                        plyCharID = tostring(ply.MonarchActiveChar.id)
                    end
                    local sid64 = ply:SteamID64()
                    local sid = ply:SteamID()
                    if (plyCharID ~= "" and plyCharID == targetKey)
                        or (memberSID ~= "" and (memberSID == sid64 or memberSID == sid or memberSID == targetKey)) then
                        isOnline = true
                        break
                    end
                end
                memberHash = memberHash .. charID .. (isOnline and "1" or "0") .. (memberData.role or "")
            end

            if base._lastMemberHash ~= memberHash then
                base._lastMemberHash = memberHash
                memberList:Clear()

            local onlineMembers = {}
            local offlineMembers = {}

            for charID, memberData in pairs(faction.members or {}) do
                local playerName = "Unknown"
                local isOnline = false
                local foundPlayer = nil
                for _, ply in player.Iterator() do
                    local plyCharID = ply:GetNWString("MonarchCharID", "")
                    if plyCharID == "" and ply.MonarchActiveChar and ply.MonarchActiveChar.id then
                        plyCharID = tostring(ply.MonarchActiveChar.id)
                    end
                    local sid64 = ply:SteamID64()
                    local sid = ply:SteamID()
                    if (plyCharID ~= "" and tostring(plyCharID) == tostring(charID))
                        or (memberData and memberData.steamid and (tostring(memberData.steamid) == sid64 or tostring(memberData.steamid) == sid)) then
                        playerName = (ply.MonarchActiveChar and ply.MonarchActiveChar.name) or ply:Nick()
                        isOnline = true
                        foundPlayer = ply
                        break
                    end
                end

                if isOnline then
                    table.insert(onlineMembers, {charID = charID, steamID = foundPlayer:SteamID64(), name = playerName, role = memberData.role or "Member"})
                else
                    table.insert(offlineMembers, {charID = charID, steamID = memberData.steamid, name = playerName, role = memberData.role or "Member"})
                end
            end

            local onlineLabel = vgui.Create("DLabel", memberList)
            onlineLabel:SetFont("InvMed")
            onlineLabel:SetColor(Color(200, 200, 200))
            onlineLabel:SetText("ONLINE")
            onlineLabel:Dock(TOP)
            onlineLabel:DockMargin(10, 8, 0, 4)
            onlineLabel:SetTall(Scale(16))

            local onlineDesc = vgui.Create("DLabel", memberList)
            onlineDesc:SetFont("InvSmall")
            onlineDesc:SetColor(Color(130, 130, 130))
            onlineDesc:SetText("A list of online faction members.")
            onlineDesc:Dock(TOP)
            onlineDesc:DockMargin(10, 0, 0, 8)
            onlineDesc:SetTall(Scale(14))

            if #onlineMembers > 0 then
                for _, memberInfo in ipairs(onlineMembers) do
                    local memberRow = vgui.Create("DPanel", memberList)
                    memberRow:Dock(TOP)
                    memberRow:DockMargin(0, 0, 0, 6)
                    memberRow:SetTall(Scale(50))

                    local memberSteamID = memberInfo.steamID
                    local gradientMat = Material("vgui/gradient-l")
                    local factionColor = selectedColor or Color(180, 180, 180, 255)

                    memberRow.Paint = function(s, w, h)

                        draw.RoundedBox(0, 0, 0, w, h, Color(42, 42, 45, 255))
                        surface.SetDrawColor(35, 35, 35, 255)
                        surface.DrawRect(0, 0, w, h)

                        if gradientMat and not gradientMat:IsError() then
                            surface.SetMaterial(gradientMat)
                            surface.SetDrawColor(factionColor.r, factionColor.g, factionColor.b, 25)
                            local gradW = w * 0.35
                            surface.DrawTexturedRect(0, 0, gradW, h)
                        end

                        surface.SetDrawColor(100,100,100,200)
                        surface.DrawOutlinedRect(0, 0, w, h, 1)
                    end

                    local avatarSize = Scale(36)
                    local avatarX = Scale(8)
                    local avatarY = (Scale(50) - avatarSize) * 0.5

                    local avatar = vgui.Create("AvatarImage", memberRow)
                    avatar:SetPos(avatarX, avatarY)
                    avatar:SetSize(avatarSize, avatarSize)
                    if memberSteamID and memberSteamID ~= "" then
                        avatar:SetSteamID(memberSteamID, 64)
                    end

                    local nameLabel = vgui.Create("DLabel", memberRow)
                    nameLabel:SetPos(Scale(52), Scale(6))
                    nameLabel:SetSize(Scale(300), Scale(20))
                    nameLabel:SetFont("InvMed")
                    nameLabel:SetTextColor(Color(245, 245, 245))
                    nameLabel:SetText(memberInfo.name)
                    nameLabel:SetContentAlignment(4)  

                    local roleLabel = vgui.Create("DLabel", memberRow)
                    roleLabel:SetFont("InvSmallItalic")
                    roleLabel:SetTextColor(Color(180, 180, 180))
                    roleLabel:SetText(memberInfo.role)
                    roleLabel:SetSize(Scale(260), Scale(20))
                    roleLabel:SetPos(Scale(52), Scale(26))
                    roleLabel:SetContentAlignment(4)  

                    if CanLocalEditMemberRoles(faction) then
                        local editRoleBtn = vgui.Create("DButton", memberRow)
                        editRoleBtn:Dock(RIGHT)
                        editRoleBtn:DockMargin(0, Scale(9), Scale(8), Scale(9))
                        editRoleBtn:SetWide(Scale(110))
                        editRoleBtn:SetText("Edit Role")
                        editRoleBtn:SetFont("InvSmall")
                        editRoleBtn:SetTextColor(Color(230, 230, 230))
                        editRoleBtn.Paint = function(s, w, h)
                            local hovered = s:IsHovered()
                            surface.SetDrawColor(hovered and Color(65, 65, 70, 220) or Color(50, 50, 54, 210))
                            surface.DrawRect(0, 0, w, h)
                            surface.SetDrawColor(hovered and Color(105, 105, 112, 220) or Color(80, 80, 88, 220))
                            surface.DrawOutlinedRect(0, 0, w, h, 1)
                        end
                        editRoleBtn.DoClick = function()
                            OpenMemberRolePicker(memberInfo)
                        end
                    end
                end
            end

            local offlineLabel = vgui.Create("DLabel", memberList)
            offlineLabel:SetFont("InvMed")
            offlineLabel:SetColor(Color(200, 200, 200))
            offlineLabel:SetText("OFFLINE")
            offlineLabel:Dock(TOP)
            offlineLabel:DockMargin(10, 12, 0, 4)
            offlineLabel:SetTall(Scale(16))

            if #offlineMembers == 0 then
                local offlineMsg = vgui.Create("DLabel", memberList)
                offlineMsg:SetFont("InvSmall")
                offlineMsg:SetColor(Color(120, 80, 80))
                offlineMsg:SetText("There are currently no offline faction members.")
                offlineMsg:Dock(TOP)
                offlineMsg:DockMargin(10, 4, 0, 8)
                offlineMsg:SetTall(Scale(14))
            else
                for _, memberInfo in ipairs(offlineMembers) do
                    local memberRow = vgui.Create("DPanel", memberList)
                    memberRow:Dock(TOP)
                    memberRow:DockMargin(0, 0, 0, 6)
                    memberRow:SetTall(Scale(50))

                    local memberSteamID = memberInfo.steamID
                    local bg = Material("mrp/menu_stuff/bg.png")
                    local gradientMat = Material("vgui/gradient-l")
                    local factionColor = selectedColor or Color(180, 180, 180, 255)

                    memberRow.Paint = function(s, w, h)

                        draw.RoundedBox(0, 0, 0, w, h, Color(35, 33, 33, 255))
                        surface.SetMaterial(bg)
                        surface.SetDrawColor(255, 255, 255, 200)
                        surface.DrawTexturedRect(0, 0, w, h)

                        if gradientMat and not gradientMat:IsError() then
                            surface.SetMaterial(gradientMat)
                            surface.SetDrawColor(factionColor.r * 0.7, factionColor.g * 0.7, factionColor.b * 0.7, 15)
                            local gradW = w * 0.35
                            surface.DrawTexturedRect(0, 0, gradW, h)
                        end
                    end

                    local avatarSize = Scale(36)
                    local avatarX = Scale(8)
                    local avatarY = (Scale(50) - avatarSize) * 0.5

                    local avatar = vgui.Create("AvatarImage", memberRow)
                    avatar:SetPos(avatarX, avatarY)
                    avatar:SetSize(avatarSize, avatarSize)
                    if memberSteamID and memberSteamID ~= "" then
                        avatar:SetSteamID(memberSteamID, 64)
                    end

                    local nameLabel = vgui.Create("DLabel", memberRow)
                    nameLabel:SetPos(Scale(52), Scale(6))
                    nameLabel:SetSize(Scale(300), Scale(20))
                    nameLabel:SetFont("InvMed")
                    nameLabel:SetTextColor(Color(200, 180, 180))
                    nameLabel:SetText(memberInfo.name)
                    nameLabel:SetContentAlignment(4)  

                    local roleLabel = vgui.Create("DLabel", memberRow)
                    roleLabel:SetFont("InvSmallItalic")
                    roleLabel:SetTextColor(Color(150, 120, 120))
                    roleLabel:SetText(memberInfo.role)
                    roleLabel:SetSize(Scale(260), Scale(20))
                    roleLabel:SetPos(Scale(52), Scale(26))
                    roleLabel:SetContentAlignment(4)  

                    if CanLocalEditMemberRoles(faction) then
                        local editRoleBtn = vgui.Create("DButton", memberRow)
                        editRoleBtn:Dock(RIGHT)
                        editRoleBtn:DockMargin(0, Scale(9), Scale(8), Scale(9))
                        editRoleBtn:SetWide(Scale(110))
                        editRoleBtn:SetText("Edit Role")
                        editRoleBtn:SetFont("InvSmall")
                        editRoleBtn:SetTextColor(Color(230, 230, 230))
                        editRoleBtn.Paint = function(s, w, h)
                            local hovered = s:IsHovered()
                            surface.SetDrawColor(hovered and Color(65, 65, 70, 220) or Color(50, 50, 54, 210))
                            surface.DrawRect(0, 0, w, h)
                            surface.SetDrawColor(hovered and Color(105, 105, 112, 220) or Color(80, 80, 88, 220))
                            surface.DrawOutlinedRect(0, 0, w, h, 1)
                        end
                        editRoleBtn.DoClick = function()
                            OpenMemberRolePicker(memberInfo)
                        end
                    end
                end
            end
            end  

            factionNameLabel:SetVisible(false)
            factionName:SetVisible(false)
            founderLabel:SetVisible(false)
            founderRole:SetVisible(false)
            colorLabel:SetVisible(false)
            colorPicker:SetVisible(false)
            if IsValid(colorCube) then colorCube:SetVisible(false) end
            if IsValid(rgbPicker) then rgbPicker:SetVisible(false) end
            if IsValid(colorPreview) then colorPreview:SetVisible(false) end
            logoLabel:SetVisible(false)
            logoGrid:SetVisible(false)
            createBtn:SetVisible(false)

            previewCard:SetVisible(true)
            previewCard:SetPos(0, Scale(20))
            infoLabel:SetVisible(false)
            infoText:SetVisible(false)

            memberScroll:SetPos(Scale(520), Scale(100))
            actionsLabel:SetVisible(true)
            actionsLabel:SetPos(Scale(10), Scale(360))

            local startY = Scale(390)
            local btnH = Scale(34)
            local gap = Scale(5)
            announcementBtn:SetVisible(true)
            announcementBtn:SetPos(Scale(10), startY)
            editNameBtn:SetVisible(true)
            editNameBtn:SetPos(Scale(10), startY + btnH + gap)
            editColorBtn:SetVisible(true)
            editColorBtn:SetPos(Scale(10), startY + (btnH + gap) * 2)
            editLogoBtn:SetVisible(true)
            editLogoBtn:SetPos(Scale(10), startY + (btnH + gap) * 3)
            roleBtn:SetVisible(true)
            roleBtn:SetPos(Scale(10), startY + (btnH + gap) * 4)
            viewMembersBtn:SetVisible(true)
            viewMembersBtn:SetPos(Scale(10), startY + (btnH + gap) * 5)

            leaveBtn:SetVisible(true)
            leaveBtn:SetPos(Scale(10), Scale(640))
        else

            factionNameLabel:SetVisible(true)
            factionName:SetVisible(true)
            founderLabel:SetVisible(true)
            founderRole:SetVisible(true)
            colorLabel:SetVisible(true)
            colorPicker:SetVisible(true)
            if IsValid(colorCube) then colorCube:SetVisible(true) end
            if IsValid(rgbPicker) then rgbPicker:SetVisible(true) end
            if IsValid(colorPreview) then colorPreview:SetVisible(true) end
            logoLabel:SetVisible(true)
            logoGrid:SetVisible(true)
            createBtn:SetVisible(true)

            infoLabel:SetVisible(false)
            infoText:SetVisible(false)
            memberScroll:SetVisible(false)
            if IsValid(roleScroll) then roleScroll:SetVisible(false) end
            actionsLabel:SetVisible(false)
            editNameBtn:SetVisible(false)
            editColorBtn:SetVisible(false)
            editLogoBtn:SetVisible(false)
            announcementBtn:SetVisible(false)
            memberScroll:SetVisible(false)
            roleBtn:SetVisible(false)
            viewMembersBtn:SetVisible(false)
            leaveBtn:SetVisible(false)
        end
    end

    return base
end

function PANEL:OnRemove()
end

end

