
if SERVER then return end

Monarch = Monarch or {}
Monarch.CharSystem = Monarch.CharSystem or {
    PlayClicked = false,
    PendingChars = nil,
    PendingForceCreate = false
}

if not Monarch.UI or not Monarch.UI.Scale then
    Monarch.LoadFile("modules/client/themes/cl_scale.lua")
end

Monarch.UI = Monarch.UI or {}

local Scale = Monarch.UI.Scale or function(v) return v end
local ScaleFont = Monarch.UI.ScaleFont or function(v) return v end

local MAX_CHARS = (Config and Config.MaxChars) or 3
local AllowedModels = (Config and Config.CharacterModels)
if not istable(AllowedModels) or #AllowedModels == 0 then
    AllowedModels = {
        "models/player/group01/male_02.mdl",
        "models/player/group01/male_04.mdl",
        "models/player/group01/female_02.mdl",
        "models/player/alyx.mdl"
    }
end

surface.CreateFont("MChar_Title",  {font="Purista", size=ScaleFont(48)})
surface.CreateFont("MChar_Sub",    {font="Purista", size=ScaleFont(26), weight=600})
surface.CreateFont("MChar_Text",   {font="Purista", size=ScaleFont(20)})
surface.CreateFont("MChar_Button", {font="Purista", size=ScaleFont(22), weight=600})

local function LerpColor(t, from, to)
    return Color(
        Lerp(t, from.r, to.r),
        Lerp(t, from.g, to.g),
        Lerp(t, from.b, to.b),
        Lerp(t, from.a or 255, to.a or 255)
    )
end

local function NiceMoney(n) return string.Comma(math.floor(tonumber(n) or 0)) end

local PANEL = {}

function PANEL:ShowMainMenu()
    if IsValid(self.CharacterSelect) then
        self.CharacterSelect:SetVisible(false)
    end
    if IsValid(self.base) then
        self.base:SetVisible(true)
    end
end

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:SetKeyboardInputEnabled(true)
    self:SetMouseInputEnabled(true)

    if Monarch then
        Monarch.hudEnabled = false
    end

    Monarch.CharSelect = self

    self.ForcedCreate = false
    self.ActiveCreate = false
    self.ModelIndex = 1
    self.Chars = {}
    self.SelectedChar = nil

    self.CharList = vgui.Create("DPanel", self)
    self.CharList:SetSize(Scale(400), ScrH() - Scale(200))
    self.CharList:SetPos(Scale(50), Scale(150))
    function self.CharList:Paint() end

    self.CharInfo = vgui.Create("DPanel", self)
    self.CharInfo:SetSize(ScrW() - Scale(500), ScrH() - Scale(200))
    self.CharInfo:SetPos(Scale(470), Scale(150))
    function self.CharInfo:Paint() end

    self.BackBtn = self:CreateStyledButton("Back", Scale(150), Scale(45))
    self.BackBtn:SetPos(Scale(50), Scale(50))
    function self.BackBtn:DoClick()
        surface.PlaySound("menu/ui_click.mp3")

        if IsValid(Monarch.NameEntry) then
            Monarch.NameEntry:Remove()
            Monarch.NameEntry = nil
        end

        if IsValid(Monarch.MainMenu) then

            if IsValid(Monarch.MainMenu.CharacterSelect) then
                Monarch.MainMenu.CharacterSelect:SetVisible(false)
            end

            if IsValid(Monarch.MainMenu.base) then
                Monarch.MainMenu.base:SetVisible(true)
            end

            Monarch.MainMenu.titleTargetY = ScrH()/2 - 200
        end
    end

    timer.Simple(0, function()
        if IsValid(self) then self:ShowPlaceholder() end
    end)
end

function PANEL:CreateStyledButton(text, w, h)
    local btn = vgui.Create("DButton", self)
    btn:SetSize(w, h)
    btn:SetText("")
    btn.hoverLerp = 0
    btn.ButtonText = text

    function btn:Paint(w, h)
        local baseColor = Color(125, 125, 125, 255)
        local bgColor = Color(30, 30, 30, 255)
        local hoverColor = Color(200, 200, 200, 255)
        local col = LerpColor(self.hoverLerp, baseColor, hoverColor)

        surface.SetDrawColor(bgColor)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        surface.SetFont("MChar_Button")
        local tw, th = surface.GetTextSize(self.ButtonText)
        local tx = w/2 - tw/2
        local ty = h/2 - th/2

        surface.SetTextColor(col)
        surface.SetTextPos(tx, ty)
        surface.DrawText(self.ButtonText)
    end

    function btn:Think()
        local targetLerp = self:IsHovered() and 1 or 0
        self.hoverLerp = Lerp(FrameTime() * 8, self.hoverLerp, targetLerp)
    end

    return btn
end

function PANEL:Paint(w, h)
end

function PANEL:ShowPlaceholder()

    if IsValid(Monarch.NameEntry) then
        Monarch.NameEntry:Remove()
        Monarch.NameEntry = nil
    end

    self.CharInfo:Clear()
    local lbl = vgui.Create("DLabel", self.CharInfo)
    lbl:SetFont("MChar_Text")
    lbl:SetTextColor(Color(200, 200, 200))
    lbl:SetText("")
    lbl:SizeToContents()
    lbl:Center()
end

function PANEL:Populate(chars)

    if IsValid(Monarch.NameEntry) then
        Monarch.NameEntry:Remove()
        Monarch.NameEntry = nil
    end

    self.Chars = chars or {}
    self.CharList:Clear()

    local scrollPanel = vgui.Create("DScrollPanel", self.CharList)
    scrollPanel:Dock(FILL)
    function scrollPanel:Paint() end

    local sbar = scrollPanel:GetVBar()
    function sbar:Paint(w, h)
        surface.SetDrawColor(40, 40, 40, 255)
        surface.DrawRect(0, 0, w, h)
    end
    function sbar.btnUp:Paint(w, h)
        surface.SetDrawColor(60, 60, 60, 255)
        surface.DrawRect(0, 0, w, h)
    end
    function sbar.btnDown:Paint(w, h)
        surface.SetDrawColor(60, 60, 60, 255)
        surface.DrawRect(0, 0, w, h)
    end
    function sbar.btnGrip:Paint(w, h)
        surface.SetDrawColor(100, 100, 100, 255)
        surface.DrawRect(0, 0, w, h)
    end

    for slot = 1, MAX_CHARS do
        local char = self.Chars[slot] 
        local isEmptySlot = not char

        local card = vgui.Create("DButton", scrollPanel)
        card:SetSize(Scale(380), Scale(80))
        card:Dock(TOP)
        card:DockMargin(0, 0, 0, Scale(10))
        card:SetText("")
        card.CharData = char
        card.SlotNumber = slot
        card.IsEmpty = isEmptySlot
        card.RootPanel = self
        card.hoverLerp = 0

        function card:Paint(w, h)
            local selected = self.CharData == self.RootPanel.SelectedChar
            local baseColor, bgColor, hoverColor

            if self.IsEmpty then

                baseColor = Color(80, 80, 80, 255)
                bgColor = Color(20, 20, 20, 255)
                hoverColor = Color(120, 120, 120, 255)
            else

                baseColor = selected and Color(200, 200, 200, 255) or Color(125, 125, 125, 255)
                bgColor = Color(30, 30, 30, 255)
                hoverColor = Color(200, 200, 200, 255)
            end

            local col = LerpColor(self.hoverLerp, baseColor, hoverColor)

            surface.SetDrawColor(bgColor)
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(col)
            surface.DrawOutlinedRect(0, 0, w, h, 2)

            if self.IsEmpty then

                surface.SetFont("MChar_Sub")
                surface.SetTextColor(Color(120, 120, 120))
                surface.SetTextPos(Scale(15), Scale(15))
                surface.DrawText("Empty Character")
            else

                surface.SetFont("MChar_Sub")
                surface.SetTextColor(col)
                surface.SetTextPos(Scale(15), Scale(15))
                surface.DrawText(self.CharData.name)
            end
        end

        function card:Think()
            local targetLerp = self:IsHovered() and 1 or 0
            self.hoverLerp = Lerp(FrameTime() * 8, self.hoverLerp, targetLerp)
        end

        function card:DoClick()
            surface.PlaySound("menu/ui_click.mp3")

            if self.IsEmpty then

                if IsValid(self.RootPanel) and self.RootPanel.ShowCreateForm then
                    self.RootPanel:ShowCreateForm()
                end
            else

                if IsValid(self.RootPanel) and self.RootPanel.ShowCharacterInfo then
                    self.RootPanel:ShowCharacterInfo(self.CharData)
                end
            end
        end

        if not isEmptySlot and not self.ForcedCreate then
            local del = vgui.Create("DButton", card)
            del:SetSize(Scale(80), Scale(30))
            del:SetPos(Scale(290), Scale(25))
            del:SetText("")
            del.ButtonText = "Delete"
            del.RootPanel = self
            del.hoverLerp = 0

            function del:Paint(w, h)
                local baseColor = Color(200, 70, 70, 255)
                local bgColor = Color(30, 30, 30, 255)
                local hoverColor = Color(255, 100, 100, 255)
                local col = LerpColor(self.hoverLerp, baseColor, hoverColor)

                surface.SetDrawColor(bgColor)
                surface.DrawRect(0, 0, w, h)

                surface.SetDrawColor(col)
                surface.DrawOutlinedRect(0, 0, w, h, 2)

                surface.SetFont("MChar_Text")
                local tw, th = surface.GetTextSize(self.ButtonText)
                surface.SetTextColor(col)
                surface.SetTextPos(w/2 - tw/2, h/2 - th/2)
                surface.DrawText(self.ButtonText)
            end

            function del:Think()
                local targetLerp = self:IsHovered() and 1 or 0
                self.hoverLerp = Lerp(FrameTime() * 8, self.hoverLerp, targetLerp)
            end

            function del:DoClick()
                surface.PlaySound("menu/ui_click.mp3")
                Derma_Query("Delete " .. char.name .. " permanently?", "Confirm",
                    "Delete", function()
                        net.Start("Monarch_CharDelete")
                        net.WriteUInt(char.id, 32)
                        net.SendToServer()
                        timer.Simple(0.5, function()
                            net.Start("Monarch_CharListRequest")
                            net.SendToServer()
                        end)
                    end,
                    "Cancel")
                return true 
            end
        end
    end

    if #self.Chars == 0 then
        timer.Simple(0, function()
            if IsValid(self) then
                self:ShowCreateForm()
            end
        end)
    end
end

function PANEL:ShowCharacterInfo(c)

    if IsValid(Monarch.NameEntry) then
        Monarch.NameEntry:Remove()
        Monarch.NameEntry = nil
    end

    self.SelectedChar = c
    self.CharInfo:Clear()

    self.ActiveCreate = false

    local rightWidth = self.CharInfo:GetWide()
    local rightHeight = self.CharInfo:GetTall()
    local modelSize = math.min(ScrW() * 0.8, ScrH() * 0.8) 

    local mdl = vgui.Create("DModelPanel", self.CharInfo)
    mdl:SetSize(modelSize, modelSize * 1.27 + 110) 
    mdl:SetPos(rightWidth/2 - modelSize/2, 100) 

    local modelPath = c.model
    if not modelPath or modelPath == "" then
        modelPath = "models/player/alyx.mdl"
    end

    mdl:SetModel(modelPath)

    mdl:SetFOV(28)
    mdl:SetCamPos(Vector(80, 0, 50))
    mdl:SetLookAt(Vector(0, 0, 45))

    function mdl:LayoutEntity(ent)
        if not IsValid(ent) then return end

        ent:SetPos(Vector(0, 0, 0))
        ent:SetAngles(Angle(0, -15, 0)) 

        if c.skin and tonumber(c.skin) then
            ent:SetSkin(tonumber(c.skin))
        end

        if c.bodygroups and c.bodygroups != "" and c.bodygroups != "{}" then
            local bodygroups = util.JSONToTable(c.bodygroups)
            if bodygroups and type(bodygroups) == "table" then
                for bgID, bgValue in pairs(bodygroups) do
                    local id = tonumber(bgID)
                    local value = tonumber(bgValue)
                    if id and value then
                        ent:SetBodygroup(id, value)
                    end
                end
            end
        end

        local seq = ent:LookupSequence("idle_all_01")
        if seq > 0 then
            ent:SetSequence(seq)
        end

        ent:SetNoDraw(false)
        ent:SetRenderMode(RENDERMODE_NORMAL)

        return
    end

    timer.Simple(0, function()
        if IsValid(mdl) then
            local ent = mdl:GetEntity()
            if IsValid(ent) then
                ent:SetModel(modelPath)
                ent:SetPos(Vector(0, 0, 0))
                ent:SetAngles(Angle(0, 25, 0))

                if c.skin and tonumber(c.skin) then
                    ent:SetSkin(tonumber(c.skin))
                end

                local seq = ent:LookupSequence("idle_all_01")
                if seq > 0 then
                    ent:SetSequence(seq)
                    ent:SetCycle(0)
                end

                ent:SetNoDraw(false)
            end
        end
    end)

    local loadBtn = self:CreateStyledButton(Config.LoadButtonText or "Load Character", Scale(250), Scale(60))
    loadBtn:SetParent(self.CharInfo)
    loadBtn:SetPos(rightWidth/2 - Scale(125), rightHeight - Scale(100))
    function loadBtn:DoClick()
        surface.PlaySound("cinematic/deep_boom.mp3")
        surface.PlaySound("woosh2.mp3")
        net.Start("Monarch_CharSelect")
        net.WriteUInt(c.id, 32)
        net.WriteString(c.name)
        net.SendToServer()

        Monarch.HasActiveCharacter = true

        LocalPlayer():SetNWString("rpname", c.name)

        self.ButtonText = "Loading..."
        self:SetDisabled(true)

        Monarch.hudEnabled = true

        if IsValid(Monarch.MainMenu) then
            Monarch.MainMenu:Remove()
        end
    end
end

function PANEL:ShowCreateForm()
    if not IsValid(self.CharInfo) then
        timer.Simple(0.1, function()
            if IsValid(self) then
                self:ShowCreateForm()
            end
        end)
        return
    end

    self.ActiveCreate = true
    self.CharInfo:Clear()

    self.CharInfo:SetMouseInputEnabled(true)
    self.CharInfo:SetKeyboardInputEnabled(true)

    local title = vgui.Create("DLabel", self.CharInfo)
    title:SetFont("MChar_Sub")
    title:SetText("Create Character")
    title:SetTextColor(Color(255, 255, 255))
    title:SizeToContents()
    title:SetPos(Scale(20), Scale(20))

    local name = vgui.Create("DTextEntry")
    Monarch.NameEntry = name
    name:SetSize(Scale(350), Scale(40))
    name:SetFont("MChar_Sub")
    name:SetPlaceholderText("Full Name (3-48 chars)")
    name:SetTextColor(Color(255, 255, 255))
    name:SetCursorColor(Color(255, 255, 255))
    name:SetHighlightColor(Color(100, 100, 255, 100))
    name:SetEditable(true)
    name:SetEnabled(true)
    name:SetMouseInputEnabled(true)
    name:SetKeyboardInputEnabled(true)

    name:MakePopup()

    local charInfoX, charInfoY = self.CharInfo:LocalToScreen(0, 0)
    name:SetPos(charInfoX + Scale(20), charInfoY + Scale(70))

    function name:Paint(w, h)
        surface.SetDrawColor(40, 40, 40, 255)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(125, 125, 125, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        self:DrawTextEntryText(Color(255, 255, 255), Color(100, 100, 255, 100), Color(255, 255, 255))
    end

    function name:OnMousePressed(code)
        if code == MOUSE_LEFT then
            self:RequestFocus()

            return true
        end
    end

    function name:Think()
        if IsValid(self:GetParent().CharInfo) then
            local charInfoX, charInfoY = self:GetParent().CharInfo:LocalToScreen(0, 0)
            self:SetPos(charInfoX + 20, charInfoY + 70)
        end
    end

    function name:OnTextChanged()
        local name = self:GetValue()

        if IsValid(name) then
            name:SetText(name)
        end

        self.Parent.CharacterName = name

        if string.len(name) < 3 then
            self:SetTextColor(Color(255, 100, 100))
        else
            self:SetTextColor(Color(255, 255, 255))
        end
    end

    name:SetParent(self)

    timer.Simple(0.1, function()
        if IsValid(name) then
            name:RequestFocus()
            name:SetCaretPos(0)
        end
    end)

    self.NameEntry = name

    local scrollContainer = vgui.Create("DScrollPanel", self.CharInfo)
    scrollContainer:SetSize(Scale(420), self.CharInfo:GetTall() - Scale(130))
    scrollContainer:SetPos(Scale(10), Scale(120))
    scrollContainer:SetMouseInputEnabled(true)
    scrollContainer:SetKeyboardInputEnabled(true)

    local sbar = scrollContainer:GetVBar()
    function sbar:Paint(w, h)
        surface.SetDrawColor(20, 20, 20, 200)
        surface.DrawRect(0, 0, w, h)
    end
    function sbar.btnUp:Paint(w, h)
        surface.SetDrawColor(40, 40, 40, 255)
        surface.DrawRect(0, 0, w, h)
    end
    function sbar.btnDown:Paint(w, h)
        surface.SetDrawColor(40, 40, 40, 255)
        surface.DrawRect(0, 0, w, h)
    end
    function sbar.btnGrip:Paint(w, h)
        surface.SetDrawColor(80, 80, 80, 255)
        surface.DrawRect(0, 0, w, h)
    end

    local form = vgui.Create("DPanel", scrollContainer)
    form:SetSize(Scale(400), Scale(850)) 
    form:SetPos(0, 0)
    form:SetMouseInputEnabled(true)
    form:SetKeyboardInputEnabled(true)
    function form:Paint() end

    local femaleCheck = vgui.Create("DCheckBoxLabel", form)
    femaleCheck:SetPos(0, Scale(10))
    femaleCheck:SetText("Female Character")
    femaleCheck:SetFont("MChar_Text")
    femaleCheck:SetTextColor(Color(200, 200, 200))
    femaleCheck:SetChecked(false)

    local modelPreview = vgui.Create("DModelPanel", self.CharInfo)
    local availW, availH = self.CharInfo:GetWide(), self.CharInfo:GetTall()

    local modelSize = math.min(availW * 0.95, availH * 0.95)
    modelPreview:SetSize(modelSize, modelSize)
    modelPreview:SetPos(availW - modelSize - 4, (availH - modelSize) * 0.5)
    modelPreview:SetMouseInputEnabled(false) 
    modelPreview:SetFOV(30)

    local FRAME_FOV_BASE = 26      
    local FRAME_FOV_MIN  = 22
    local FRAME_FOV_MAX  = 34
    local FRAME_VERT_MARGIN = 0.06 
    local FRAME_DIST_SCALE = 1.02  
    local FRAME_SIDE_FACTOR = 0.20 

    local function FrameModel(pnl, pass)
        if not IsValid(pnl) then return end
        local ent = pnl:GetEntity()
        if not IsValid(ent) then return end

        local mn, mx = ent:OBBMins(), ent:OBBMaxs()
        local center = (mn + mx) * 0.5
        local size   = mx - mn
        local width  = math.max(size.x, size.y)
        local height = size.z

        local paddedHeight = height * (1 + FRAME_VERT_MARGIN * 2)

        local aspectTall = paddedHeight / math.max(width, 1)
        local desiredFOV = math.Clamp(FRAME_FOV_BASE + (aspectTall - 1) * -6, FRAME_FOV_MIN, FRAME_FOV_MAX)
        pnl:SetFOV(desiredFOV)

        local fovRad = math.rad(desiredFOV)
        local dist   = (paddedHeight * 0.5) / math.tan(fovRad * 0.5)
        dist = dist * FRAME_DIST_SCALE

        local camX = dist
        local camY = dist * FRAME_SIDE_FACTOR
        local camZ = paddedHeight * 0.52

        pnl:SetCamPos(Vector(camX, camY, camZ))
        pnl:SetLookAt(Vector(center.x, center.y, center.z + height * 0.015))

        if pass == 0 then
            timer.Simple(0.05, function() FrameModel(pnl, 1) end)
        end
    end

    function modelPreview:LayoutEntity(ent)
        if not IsValid(ent) then return end
        ent:SetPos(Vector(0, 0, 0))
        ent:SetAngles(Angle(0, 25, 0))
        ent:SetNoDraw(false)
        ent:SetRenderMode(RENDERMODE_NORMAL)
    end

    local MaleModels = AllowedModels
    local FemaleModels = Config.FemaleCharacterModels

    self.ModelIndex = self.ModelIndex or 1
    local selectedModel = MaleModels[self.ModelIndex] or MaleModels[1]
    local currentModels = MaleModels
    local selectedIcon
    modelPreview:SetModel(selectedModel)
    FrameModel(modelPreview, 0)

    local modelScroll = vgui.Create("DScrollPanel", form)
    modelScroll:SetPos(0, Scale(40))
    modelScroll:SetSize(Scale(380), Scale(220))
    function modelScroll:Paint(w, h)
        surface.SetDrawColor(30, 30, 30, 255)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(125, 125, 125, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end

    local sbar = modelScroll:GetVBar()
    function sbar:Paint(w, h)
        surface.SetDrawColor(40, 40, 40, 255)
        surface.DrawRect(0, 0, w, h)
    end
    function sbar.btnUp:Paint(w, h)
        surface.SetDrawColor(60, 60, 60, 255)
        surface.DrawRect(0, 0, w, h)
    end
    function sbar.btnDown:Paint(w, h)
        surface.SetDrawColor(60, 60, 60, 255)
        surface.DrawRect(0, 0, w, h)
    end
    function sbar.btnGrip:Paint(w, h)
        surface.SetDrawColor(100, 100, 100, 255)
        surface.DrawRect(0, 0, w, h)
    end

    local grid = vgui.Create("DIconLayout", modelScroll)
    grid:Dock(FILL)
    grid:SetSpaceX(Scale(12))
    grid:SetSpaceY(Scale(12))
    grid:DockMargin(Scale(10), Scale(10), Scale(10), Scale(10))

    local function PopulateModelIcons(models)
        grid:Clear()
        for i, mdl in ipairs(models) do
            local icon = vgui.Create("SpawnIcon", grid)
            icon:SetModel(mdl)
            icon:SetSize(Scale(64), Scale(64))
            icon:SetTooltip(mdl)
            icon:SetMouseInputEnabled(true)
            icon.Selected = false

            function icon:Paint(w, h)
                surface.SetDrawColor(40, 40, 40, 255)
                surface.DrawRect(0, 0, w, h)

                if self.Selected then
                    surface.SetDrawColor(200, 200, 200, 255)
                    surface.DrawOutlinedRect(0, 0, w, h, Scale(3))
                elseif self:IsHovered() then
                    surface.SetDrawColor(125, 125, 125, 255)
                    surface.DrawOutlinedRect(0, 0, w, h, Scale(2))
                else
                    surface.SetDrawColor(80, 80, 80, 255)
                    surface.DrawOutlinedRect(0, 0, w, h, 1)
                end
            end

            function icon:DoClick()
                surface.PlaySound("menu/ui_click.mp3")
                selectedModel = mdl
                self:GetParent():GetParent():GetParent():GetParent().ModelIndex = i
                if IsValid(selectedIcon) then
                    selectedIcon.Selected = false
                end
                selectedIcon = icon
                icon.Selected = true
                if IsValid(modelPreview) then
                    modelPreview:SetModel(selectedModel)
                    FrameModel(modelPreview, 0)
                end
            end

            if i == (self.ModelIndex or 1) then
                selectedIcon = icon
                icon.Selected = true
            end
        end
    end

    PopulateModelIcons(MaleModels)

    function femaleCheck:OnChange(val)
        if val then
            currentModels = FemaleModels
        else
            currentModels = MaleModels
        end
        self:GetParent():GetParent().ModelIndex = 1
        selectedModel = currentModels[1]
        PopulateModelIcons(currentModels)
        if IsValid(modelPreview) then
            modelPreview:SetModel(selectedModel)
            FrameModel(modelPreview, 0)
        end
    end

    local skinSlider = vgui.Create("DPanel", form)
    skinSlider:SetPos(0, Scale(270))
    skinSlider:SetSize(Scale(350), Scale(42))
    skinSlider.value = 0
    skinSlider.min = 0
    skinSlider.max = 10
    skinSlider.hoverLerp = 0
    skinSlider.dragging = false

    function skinSlider:GetValue() return self.value end
    function skinSlider:SetValue(val)
        self.value = math.Clamp(math.floor(val), self.min, self.max)
        local ent = modelPreview:GetEntity()
        if IsValid(ent) then
            ent:SetSkin(self.value)
        end
    end

    function skinSlider:Paint(w, h)
        surface.SetDrawColor(30, 30, 30, 255)
        surface.DrawRect(0, 0, w, h)

        local col = LerpColor(self.hoverLerp, Color(90,90,90), Color(180,180,180))
        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(0, 0, w, h, Scale(2))

        local frac = self.value / math.max(1, self.max - self.min)
        local barW = (w - Scale(8)) * frac
        surface.SetDrawColor(70, 70, 70, 255)
        surface.DrawRect(Scale(4), Scale(4), w - Scale(8), h - Scale(8))
        surface.SetDrawColor(125, 125, 125, 255)
        surface.DrawRect(Scale(4), Scale(4), barW, h - Scale(8))

        draw.SimpleText("Skin: " .. self.value, "MChar_Text", w/2, h/2 - 10, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    end

    function skinSlider:Think()
        local targetLerp = self:IsHovered() and 1 or 0
        self.hoverLerp = Lerp(FrameTime() * 8, self.hoverLerp, targetLerp)
    end

    function skinSlider:OnMousePressed()
        self.dragging = true
        self:MouseCapture(true)
        local x = self:CursorPos()
        local frac = math.Clamp(x / self:GetWide(), 0, 1)
        self:SetValue(self.min + frac * (self.max - self.min))
    end

    function skinSlider:OnMouseReleased()
        self.dragging = false
        self:MouseCapture(false)
    end

    function skinSlider:Think()
        if self.dragging then
            local x = self:CursorPos()
            local frac = math.Clamp(x / self:GetWide(), 0, 1)
            self:SetValue(self.min + frac * (self.max - self.min))
        end
        local targetLerp = self:IsHovered() and 1 or 0
        self.hoverLerp = Lerp(FrameTime() * 8, self.hoverLerp, targetLerp)
    end

    local attrY = Scale(325)
    local function LabeledEntry(parent, y, labelText, placeholder, numeric)
        local lbl = vgui.Create("DLabel", parent)
        lbl:SetPos(0, y)
        lbl:SetFont("MChar_Text")
        lbl:SetTextColor(Color(200,200,200))
        lbl:SetText(labelText)
        lbl:SizeToContents()
        local e = vgui.Create("DTextEntry", parent)
        e:SetPos(0, y + Scale(22))
        e:SetSize(Scale(350), Scale(32))
        e:SetFont("MChar_Text")
        e:SetPlaceholderText(placeholder)
        e:SetUpdateOnType(true)
        e:SetTextColor(Color(255,255,255))
        e:SetCursorColor(Color(255,255,255))
        e:SetHighlightColor(Color(100,100,255,80))
        function e:Paint(w,h)
            surface.SetDrawColor(30,30,30,255)
            surface.DrawRect(0,0,w,h)
            local col = self:IsHovered() and Color(180,180,180) or Color(90,90,90)
            surface.SetDrawColor(col)
            surface.DrawOutlinedRect(0,0,w,h,Scale(2))
            self:DrawTextEntryText(Color(255,255,255), Color(120,120,255,100), Color(255,255,255))
            if self:GetValue() == "" then
                draw.SimpleText(placeholder, "MChar_Text", Scale(6), h/2 - Scale(10), Color(140,140,140))
            end
        end
        if numeric then
            function e:OnTextChanged()
                local val = self:GetValue()
                if val ~= "" then
                    local filtered = val:gsub("[^0-9]", "")
                    if filtered ~= val then
                        local caret = self:GetCaretPos()
                        self:SetText(filtered)
                        self:SetCaretPos(math.max(caret-1,0))
                    end
                end
                if Validate then Validate() end
            end
        else
            function e:OnTextChanged()
                if Validate then Validate() end
            end
        end
        return e
    end

    local heightLabel = vgui.Create("DLabel", form)
    heightLabel:SetPos(0, attrY)
    heightLabel:SetFont("MChar_Text")
    heightLabel:SetTextColor(Color(200,200,200))
    heightLabel:SetText("Height")
    heightLabel:SizeToContents()

    local heightSlider = vgui.Create("DPanel", form)
    heightSlider:SetPos(0, attrY + Scale(22))
    heightSlider:SetSize(Scale(350), Scale(36))
    heightSlider.value = 66
    heightSlider.min = 48
    heightSlider.max = 84
    heightSlider.hoverLerp = 0
    heightSlider.dragging = false

    function heightSlider:GetValue() return self.value end
    function heightSlider:SetValue(val)
        self.value = math.Clamp(math.floor(val), self.min, self.max)
        if Validate then Validate() end
    end

    function heightSlider:Paint(w,h)
        surface.SetDrawColor(30,30,30,255)
        surface.DrawRect(0,0,w,h)

        local col = LerpColor(self.hoverLerp, Color(90,90,90), Color(180,180,180))
        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(0,0,w,h,Scale(2))

        local frac = (self.value - self.min) / math.max(1, self.max - self.min)
        local barW = (w - Scale(8)) * frac
        surface.SetDrawColor(70, 70, 70, 255)
        surface.DrawRect(Scale(4), Scale(4), w - Scale(8), h - Scale(8))
        surface.SetDrawColor(125, 125, 125, 255)
        surface.DrawRect(Scale(4), Scale(4), barW, h - Scale(8))

        local ft = math.floor(self.value/12)
        local inch = self.value % 12
        draw.SimpleText(string.format("%d'%d\"", ft, inch), "MChar_Text", w/2, h/2 - Scale(10), Color(255, 255, 255), TEXT_ALIGN_CENTER)
    end

    function heightSlider:OnMousePressed()
        self.dragging = true
        self:MouseCapture(true)
        local x = self:CursorPos()
        local frac = math.Clamp(x / self:GetWide(), 0, 1)
        self:SetValue(self.min + frac * (self.max - self.min))
    end

    function heightSlider:OnMouseReleased()
        self.dragging = false
        self:MouseCapture(false)
    end

    function heightSlider:Think()
        if self.dragging then
            local x = self:CursorPos()
            local frac = math.Clamp(x / self:GetWide(), 0, 1)
            self:SetValue(self.min + frac * (self.max - self.min))
        end
        local targetLerp = self:IsHovered() and 1 or 0
        self.hoverLerp = Lerp(FrameTime() * 8, self.hoverLerp, targetLerp)
    end

    local weightLabel = vgui.Create("DLabel", form)
    weightLabel:SetPos(0, attrY + Scale(70))
    weightLabel:SetFont("MChar_Text")
    weightLabel:SetTextColor(Color(200,200,200))
    weightLabel:SetText("Weight (lbs)")
    weightLabel:SizeToContents()

    local weightSlider = vgui.Create("DPanel", form)
    weightSlider:SetPos(0, attrY + Scale(92))
    weightSlider:SetSize(Scale(350), Scale(36))
    weightSlider.value = 150
    weightSlider.min = 50
    weightSlider.max = 400
    weightSlider.hoverLerp = 0
    weightSlider.dragging = false

    function weightSlider:GetValue() return self.value end
    function weightSlider:SetValue(val)
        self.value = math.Clamp(math.floor(val), self.min, self.max)
        if Validate then Validate() end
    end

    function weightSlider:Paint(w,h)
        surface.SetDrawColor(30,30,30,255)
        surface.DrawRect(0,0,w,h)

        local col = LerpColor(self.hoverLerp, Color(90,90,90), Color(180,180,180))
        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(0,0,w,h,Scale(2))

        local frac = (self.value - self.min) / math.max(1, self.max - self.min)
        local barW = (w - Scale(8)) * frac
        surface.SetDrawColor(70, 70, 70, 255)
        surface.DrawRect(Scale(4), Scale(4), w - Scale(8), h - Scale(8))
        surface.SetDrawColor(125, 125, 125, 255)
        surface.DrawRect(Scale(4), Scale(4), barW, h - Scale(8))

        draw.SimpleText(""..self.value.." lbs", "MChar_Text", w/2, h/2 - Scale(10), Color(255, 255, 255), TEXT_ALIGN_CENTER)
    end

    function weightSlider:OnMousePressed()
        self.dragging = true
        self:MouseCapture(true)
        local x = self:CursorPos()
        local frac = math.Clamp(x / self:GetWide(), 0, 1)
        self:SetValue(self.min + frac * (self.max - self.min))
    end

    function weightSlider:OnMouseReleased()
        self.dragging = false
        self:MouseCapture(false)
    end

    function weightSlider:Think()
        if self.dragging then
            local x = self:CursorPos()
            local frac = math.Clamp(x / self:GetWide(), 0, 1)
            self:SetValue(self.min + frac * (self.max - self.min))
        end
        local targetLerp = self:IsHovered() and 1 or 0
        self.hoverLerp = Lerp(FrameTime() * 8, self.hoverLerp, targetLerp)
    end

    local heightEntry, weightEntry = nil, nil 

    local hairLabel = vgui.Create("DLabel", form)
    hairLabel:SetPos(0, attrY + Scale(140))
    hairLabel:SetFont("MChar_Text")
    hairLabel:SetTextColor(Color(200,200,200))
    hairLabel:SetText("Hair Color")
    hairLabel:SizeToContents()

    local hairCombo = vgui.Create("DComboBox", form)
    hairCombo:SetPos(0, attrY + Scale(162))
    hairCombo:SetSize(Scale(350), Scale(32))
    hairCombo:SetFont("MChar_Text")
    hairCombo:SetTextColor(Color(255,255,255))
    hairCombo:SetValue("Select Hair Color")
    local hairOptions = {"Black","Brown","Blonde","Dark Blonde","Auburn","Red","Ginger","Gray","White","Dyed"}
    for _, opt in ipairs(hairOptions) do hairCombo:AddChoice(opt) end
    function hairCombo:Paint(w,h)
        surface.SetDrawColor(30,30,30,255)
        surface.DrawRect(0,0,w,h)
        local col = self:IsHovered() and Color(180,180,180) or Color(90,90,90)
        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(0,0,w,h,Scale(2))
        self:DrawTextEntryText(Color(255,255,255), Color(120,120,255,100), Color(255,255,255))
    end
    function hairCombo:OnSelect() if Validate then Validate() end end

    local eyeLabel = vgui.Create("DLabel", form)
    eyeLabel:SetPos(0, attrY + Scale(210))
    eyeLabel:SetFont("MChar_Text")
    eyeLabel:SetTextColor(Color(200,200,200))
    eyeLabel:SetText("Eye Color")
    eyeLabel:SizeToContents()

    local eyeCombo = vgui.Create("DComboBox", form)
    eyeCombo:SetPos(0, attrY + Scale(232))
    eyeCombo:SetSize(Scale(350), Scale(32))
    eyeCombo:SetFont("MChar_Text")
    eyeCombo:SetTextColor(Color(255,255,255))
    eyeCombo:SetValue("Select Eye Color")
    local eyeOptions = {"Brown","Blue","Green","Hazel","Gray","Amber"}
    for _, opt in ipairs(eyeOptions) do eyeCombo:AddChoice(opt) end
    function eyeCombo:Paint(w,h)
        surface.SetDrawColor(30,30,30,255)
        surface.DrawRect(0,0,w,h)
        local col = self:IsHovered() and Color(180,180,180) or Color(90,90,90)
        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(0,0,w,h,Scale(2))
        self:DrawTextEntryText(Color(255,255,255), Color(120,120,255,100), Color(255,255,255))
    end
    function eyeCombo:OnSelect() if Validate then Validate() end end

    local ageLabel = vgui.Create("DLabel", form)
    ageLabel:SetPos(0, attrY + Scale(280))
    ageLabel:SetFont("MChar_Text")
    ageLabel:SetTextColor(Color(200,200,200))
    ageLabel:SetText("Age")
    ageLabel:SizeToContents()

    local ageSlider = vgui.Create("DPanel", form)
    ageSlider:SetPos(0, attrY + Scale(302))
    ageSlider:SetSize(Scale(350), Scale(36))
    ageSlider.value = 25
    ageSlider.min = 10
    ageSlider.max = 100
    ageSlider.hoverLerp = 0
    ageSlider.dragging = false

    function ageSlider:GetValue() return self.value end
    function ageSlider:SetValue(val)
        self.value = math.Clamp(math.floor(val), self.min, self.max)
        if Validate then Validate() end
    end

    function ageSlider:Paint(w,h)
        surface.SetDrawColor(30,30,30,255)
        surface.DrawRect(0,0,w,h)

        local col = LerpColor(self.hoverLerp, Color(90,90,90), Color(180,180,180))
        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(0,0,w,h,2)

        local frac = (self.value - self.min) / math.max(1, self.max - self.min)
        local barW = (w - Scale(8)) * frac
        surface.SetDrawColor(70, 70, 70, 255)
        surface.DrawRect(Scale(4), Scale(4), w - Scale(8), h - Scale(8))
        surface.SetDrawColor(125, 125, 125, 255)
        surface.DrawRect(Scale(4), Scale(4), barW, h - Scale(8))

        draw.SimpleText(""..self.value.." yrs", "MChar_Text", w/2, h/2 - Scale(10), Color(255, 255, 255), TEXT_ALIGN_CENTER)
    end

    function ageSlider:OnMousePressed()
        self.dragging = true
        self:MouseCapture(true)
        local x = self:CursorPos()
        local frac = math.Clamp(x / self:GetWide(), 0, 1)
        self:SetValue(self.min + frac * (self.max - self.min))
    end

    function ageSlider:OnMouseReleased()
        self.dragging = false
        self:MouseCapture(false)
    end

    function ageSlider:Think()
        if self.dragging then
            local x = self:CursorPos()
            local frac = math.Clamp(x / self:GetWide(), 0, 1)
            self:SetValue(self.min + frac * (self.max - self.min))
        end
        local targetLerp = self:IsHovered() and 1 or 0
        self.hoverLerp = Lerp(FrameTime() * 8, self.hoverLerp, targetLerp)
    end

    local createBtn = self:CreateStyledButton("Create Character", Scale(250), Scale(50))
    createBtn:SetParent(form)
    createBtn:SetPos(0, attrY + Scale(350))
    createBtn:SetDisabled(true)

    local function Validate()
        local n = string.Trim(name:GetValue() or "")
        local heightInches = math.floor(heightSlider:GetValue() or 0)
        local weightVal = tostring(math.floor(weightSlider:GetValue() or 0))
        local hairVal = string.Trim(hairCombo:GetValue() or "")
        if hairVal == "Select Hair Color" then hairVal = "" end
        local eyeVal = string.Trim(eyeCombo:GetValue() or "")
        if eyeVal == "Select Eye Color" then eyeVal = "" end
        local ageNum = math.floor(ageSlider:GetValue() or 0)

        local nameOK = #n >= 3 and #n <= 48
        local heightOK = heightInches >= 48 and heightInches <= 84
        local weightNum = tonumber(weightVal)
        local weightOK = weightNum and weightNum >= 50 and weightNum <= 400
        local hairOK = #hairVal >= 3 and #hairVal <= 24
        local eyeOK = #eyeVal >= 3 and #eyeVal <= 24
        local ageOK = ageNum >= 10 and ageNum <= 100

        local isValid = nameOK and heightOK and weightOK and hairOK and eyeOK and ageOK
        if IsValid(createBtn) then
            createBtn:SetDisabled(not isValid)
        end
        return isValid
    end

    function name:OnValueChange()
        Validate()
    end

    function name:OnTextChanged()
        Validate()
    end

    timer.Simple(0, function()
        if IsValid(name) then
            Validate()
        end
    end)

    function createBtn:DoClick()

        if not Validate() then
            local n = string.Trim(name:GetValue() or "")
            if #n < 3 or #n > 48 then
                chat.AddText(Color(255, 100, 100), "Name must be 3-48 characters")
            end
            chat.AddText(Color(255,100,100), "Ensure all RP fields are valid")
            return
        end

        surface.PlaySound("menu/char_load.mp3")

        local nameValue = string.Trim(name:GetValue() or "")
        local modelToUse = selectedModel or currentModels[1] or AllowedModels[1]
        local skinValue = math.Clamp(skinSlider:GetValue(), 0, 255)
        local isFemale = femaleCheck:GetChecked() or false

        local heightInches = math.floor(heightSlider:GetValue() or 0)
        local heightVal = ""
        if heightInches >= 48 and heightInches <= 84 then
            local ft = math.floor(heightInches/12)
            local inch = heightInches % 12
            heightVal = string.format("%d'%d\"", ft, inch)
        end
        local weightVal = tostring(math.floor(weightSlider:GetValue() or 0))
        local hairVal = string.Trim(hairCombo:GetValue() or "")
        if hairVal == "Select Hair Color" then hairVal = "" end
        local eyeVal = string.Trim(eyeCombo:GetValue() or "")
        if eyeVal == "Select Eye Color" then eyeVal = "" end
        local ageVal = math.floor(ageSlider:GetValue() or 0)

        Monarch.LastSentRP = {height = heightVal, weight = weightVal, hair = hairVal, eye = eyeVal, age = ageVal}

        net.Start("Monarch_CharCreate")
            net.WriteString(nameValue)
            net.WriteString(modelToUse)
            net.WriteUInt(skinValue, 8)
            net.WriteBool(isFemale)

            net.WriteString(heightVal)
            net.WriteString(weightVal)
            net.WriteString(hairVal)
            net.WriteString(eyeVal)
            net.WriteUInt(math.Clamp(ageVal,0,255), 8)
        net.SendToServer()

        LocalPlayer():Notify("Character \"" .. nameValue .. "\" created (RP attributes included)")

        self.ButtonText = "Creating..."
        self:SetDisabled(true)
    end
end

function PANEL:ForceCreateMode()
    self.ForcedCreate = true
    if #self.Chars == 0 then self:ShowCreateForm() end
end

function PANEL:Remove()
    if IsValid(Monarch.NameEntry) then
        Monarch.NameEntry:Remove()
        Monarch.NameEntry = nil
    end
    BaseClass.Remove(self)
end

vgui.Register("MonarchCharacterSelect", PANEL, "EditablePanel")

function Monarch.CharSystem.OpenSelector()
    if Monarch.HasActiveCharacter then return end
    if not vgui.GetControlTable("MonarchCharacterSelect") then return end

    if not IsValid(Monarch.CharSelect) then
        Monarch.CharSelect = vgui.Create("MonarchCharacterSelect")

        net.Start("Monarch_CharListRequest")
        net.SendToServer()

        Monarch.CharSelect:ShowPlaceholder()
    end

    if Monarch.CharSystem.PendingChars then
        Monarch.CharSelect:Populate(Monarch.CharSystem.PendingChars)
        if Monarch.CharSystem.PendingForceCreate then
            Monarch.CharSelect:ForceCreateMode()
        end
    end
end

net.Receive("Monarch_CharList", function()
    local count = net.ReadUInt(3)
    local chars = {}
    for i=1,count do
        chars[i] = {
            id = net.ReadUInt(32),
            name = net.ReadString(),
            model = net.ReadString(),
            skin = net.ReadUInt(8),
            xp = net.ReadInt(32),
            money = net.ReadInt(32),
            bankmoney = net.ReadInt(32),
            team = net.ReadUInt(8), 
            bodygroups = net.ReadString() 
        }

    end

    if IsValid(Monarch.MainMenu) and IsValid(Monarch.MainMenu.CharacterSelect) then
        Monarch.MainMenu.CharacterSelect:Populate(chars)
        if Monarch.CharSystem.PendingForceCreate then
            Monarch.MainMenu.CharacterSelect:ForceCreateMode()
        end
    end

    Monarch.CharSystem.PendingChars = chars
end)

net.Receive("Monarch_CharActivated", function()

    if IsValid(Monarch.NameEntry) then
        Monarch.NameEntry:Remove()
        Monarch.NameEntry = nil
    end

    if IsValid(Monarch.MainMenu) then
        Monarch.MainMenu:Remove()
    end

    if Monarch.Inventory and Monarch.Inventory.Data then
        local localSteamID = LocalPlayer():SteamID64()
        if localSteamID then
            Monarch.Inventory.Data[localSteamID] = nil
        end
    end

    if Monarch and Monarch.LastSentRP then
        local rp = Monarch.LastSentRP
        net.Start("Monarch_RPUpdate")
            net.WriteString(rp.height or "")
            net.WriteString(rp.weight or "")
            net.WriteString(rp.hair or "")
            net.WriteString(rp.eye or "")
            net.WriteUInt(rp.age or 0, 8)
        net.SendToServer()
    end

    net.Start("Monarch_Inventory_Request")
    net.SendToServer()
end)

net.Receive("Monarch_CharForceCreate", function()
    Monarch.CharSystem.PendingForceCreate = true
    if IsValid(Monarch.MainMenu) and IsValid(Monarch.MainMenu.CharacterSelect) then
        Monarch.MainMenu.CharacterSelect:ShowCreateForm()
    end
end)

function Monarch.CharSystem.CleanupNameEntry()
    if IsValid(Monarch.NameEntry) then
        Monarch.NameEntry:Remove()
        Monarch.NameEntry = nil
    end
end

