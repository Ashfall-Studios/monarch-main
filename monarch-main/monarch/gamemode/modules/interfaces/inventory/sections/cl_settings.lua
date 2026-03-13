return function(PANEL)
    if not CLIENT then return end

    local Scale = (Monarch and Monarch.UI and Monarch.UI.Scale) or function(v) return v end

function PANEL:CreateSettingsPanel(parent)
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

    local titleShadow = vgui.Create("DLabel", col)
    titleShadow:SetFont("Inventory_Title")
    titleShadow:SetColor(Color(0, 0, 0, 250))
    titleShadow:SetText("SETTINGS/CONTROLS")
    titleShadow:SizeToContents()

    local title = vgui.Create("DLabel", col)
    title:SetFont("Inventory_Title")
    title:SetColor(Color(185, 185, 185))
    title:SetText("SETTINGS/CONTROLS")
    title:SizeToContents()

    local iconSize = Scale(55)
    local iconSpacing = Scale(10)

    local iconShadow = vgui.Create("DImage", col)
    iconShadow:SetImage("mrp/icons/settings.png")
    iconShadow:SetSize(iconSize, iconSize)
    iconShadow:SetImageColor(Color(0, 0, 0, 150))

    local icon = vgui.Create("DImage", col)
    icon:SetImage("mrp/icons/settings.png")
    icon:SetSize(iconSize, iconSize)
    icon:SetImageColor(Color(185, 185, 185))

    local totalWidth = iconSize + iconSpacing + title:GetWide()
    local centerX = (col:GetWide() - totalWidth) * 0.5
    iconShadow:SetPos(centerX + 2, Scale(20) + 2)
    titleShadow:SetPos(centerX + iconSize + iconSpacing + 2, Scale(20) + 2)
    icon:SetPos(centerX, Scale(20) + (title:GetTall() - iconSize) * 0.5)
    title:SetPos(centerX + iconSize + iconSpacing, Scale(20))

    local container = vgui.Create("DScrollPanel", col)
    container:SetPos(10, Scale(80))
    container:SetSize(col:GetWide() - 20, h - Scale(90))

    local vbar = container:GetVBar()
    vbar:SetWide(8)
    function vbar:Paint(pw, ph)
        local P = GetP()
        surface.SetDrawColor(ColorAlpha(P.inputBg, 160))
        surface.DrawRect(0, 0, pw, ph)
    end
    function vbar.btnUp:Paint() end
    function vbar.btnDown:Paint() end
    function vbar.btnGrip:Paint(pw, ph)
        local P = GetP()
        surface.SetDrawColor(P.btn)
        surface.DrawRect(0, 0, pw, ph)
    end

    local function addSpacer(sz)
        local s = vgui.Create("DPanel", container)
        s:SetTall(sz)
        s:Dock(TOP)
        s.Paint = function() end
    end

    local function styleButton(btn)
        btn:SetFont("InvSmall")
        btn:SetTextColor(GetP().btnText)
        btn.Paint = function(s, pw, ph)
            local P = GetP()
            local bg = s:IsHovered() and P.btnHover or P.btn
            surface.SetDrawColor(bg) surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.inputBorder) surface.DrawOutlinedRect(0,0,pw,ph,1)
        end
    end

    local function styleCheckbox(chk)
        chk:SetText("")
        chk:SizeToContents()

        local box = chk.Button or chk.Checkbox or chk
        if IsValid(box) then box:SetSize(24,24) end
        function box:Paint(pw, ph)
            local P = GetP()
            surface.SetDrawColor(P.inputBg) surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.inputBorder) surface.DrawOutlinedRect(0,0,pw,ph,1)
            if self:GetChecked() then

                local function drawSegment(ax, ay, bx, by, thickness, col)
                    ax, ay, bx, by = math.floor(ax+0.5), math.floor(ay+0.5), math.floor(bx+0.5), math.floor(by+0.5)
                    local dx, dy = bx-ax, by-ay
                    local len = math.sqrt(dx*dx + dy*dy)
                    if len <= 0 then return end
                    dx, dy = dx/len, dy/len
                    local px, py = -dy * thickness/2, dx * thickness/2
                    local poly = {
                        {x = ax + px, y = ay + py},
                        {x = bx + px, y = by + py},
                        {x = bx - px, y = by - py},
                        {x = ax - px, y = ay - py},
                    }
                    draw.NoTexture()
                    surface.SetDrawColor(col)
                    surface.DrawPoly(poly)
                end
                local t = math.max(2, math.floor(math.min(pw, ph) * 0.15))
                local ax, ay = pw * 0.20, ph * 0.58
                local bx, by = pw * 0.46, ph * 0.82
                local cx, cy = pw * 0.80, ph * 0.22
                local col = Color(240,240,240)
                drawSegment(ax, ay, bx, by, t, col)
                drawSegment(bx, by, cx, cy, t, col)
            end
        end
    end

    local function styleSlider(slider)
        slider:SetText("")
        if IsValid(slider.Label) then slider.Label:SetText("") end
        local track = slider.Slider
        local wang = slider.TextArea
        function track:Paint(pw, ph)
            local P = GetP()
            surface.SetDrawColor(Color(70,70,72))
            surface.DrawRect(0, math.floor(ph/2-1), pw, 2)
        end
        if IsValid(track.Knob) then track.Knob:SetSize(12,12) end
        function track.Knob:Paint(pw, ph)
            local P = GetP()
            local k = 10
            local x = math.floor((pw - k) * 0.5)
            local y = math.floor((ph - k) * 0.5)
            surface.SetDrawColor(Color(210,210,210))
            surface.DrawRect(x, y, k, k)
            surface.SetDrawColor(Color(120,120,120))
            surface.DrawOutlinedRect(x, y, k, k, 1)
        end
        if IsValid(wang) then
            function wang:Paint(pw, ph)
                local P = GetP()
                surface.SetDrawColor(P.inputBg) surface.DrawRect(0,0,pw,ph)
                surface.SetDrawColor(P.inputBorder) surface.DrawOutlinedRect(0,0,pw,ph,1)
                self:DrawTextEntryText(P.inputText, Color(180,180,180), P.inputText)
            end
        end
    end

    local function styleEntry(entry)
        function entry:Paint(pw, ph)
            local P = GetP()
            surface.SetDrawColor(P.inputBg) surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.inputBorder) surface.DrawOutlinedRect(0,0,pw,ph,1)
            self:DrawTextEntryText(P.inputText, Color(200,200,200), P.inputText)
        end
    end

    local function styleCombo(combo)
        function combo:Paint(pw, ph)
            local P = GetP()
            surface.SetDrawColor(Color(16,16,18)) surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(P.inputBorder) surface.DrawOutlinedRect(0,0,pw,ph,1)
        end

    local te = (combo.GetTextArea and combo:GetTextArea()) or combo.TextEntry
        if IsValid(te) then
            te:SetTextColor(GetP().inputText)
            te:SetDrawLanguageID(false)
            function te:Paint(pw, ph)
                local P = GetP()

                self:DrawTextEntryText(P.inputText, Color(200,200,200), P.inputText)
            end
        end

        function combo:OnMenuOpened(menu)
            if not IsValid(menu) then return end
            menu.Paint = function(s, pw, ph)
                local P = GetP()
                surface.SetDrawColor(Color(16,16,18)) surface.DrawRect(0,0,pw,ph)
                surface.SetDrawColor(P.inputBorder) surface.DrawOutlinedRect(0,0,pw,ph,1)
            end
        end
    end

    local S = Monarch and Monarch.Settings
    if not (S and istable(S)) then
        local warn = vgui.Create("DLabel", container)
        warn:SetText("No settings available.")
        warn:SetFont("InvSmall")
        warn:SetTextColor(Color(220,120,120))
        warn:Dock(TOP)
        warn:SetTall(24)
        return base
    end

    local categories = {}
    for k, def in pairs(S) do
        if istable(def) then
            local cat = def.category or "General"
            categories[cat] = categories[cat] or {}
            table.insert(categories[cat], k)
        end
    end

    local catNames = {}
    for cat,_ in pairs(categories) do table.insert(catNames, cat) end
    table.sort(catNames, function(a,b) return tostring(a) < tostring(b) end)

    local ctlW = 240

    local function addCategoryHeader(cat)
        local header = vgui.Create("DPanel", container)
        header:Dock(TOP)
        header:DockMargin(0, 10, 0, 8)
        header:SetTall(32)
        header.Paint = function(s, pw, ph)
            local P = GetP()
            surface.SetDrawColor(P.text)
            draw.SimpleText(cat, "InvMed", 0, 0, P.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            surface.SetDrawColor(P.divider)
            surface.DrawRect(0, ph-2, pw, 2)
        end
        return header
    end

    local function placeRight(ctrl, tall, width)
        tall = tall or 24
        local wctrl = width or ctlW
        ctrl:SetSize(wctrl, tall)
        local rightPad = ((IsValid(vbar) and vbar:GetWide()) or 8) + 10
        ctrl:SetPos(container:GetWide() - wctrl - rightPad, 8)
    end

    for _, cat in ipairs(catNames) do
        addCategoryHeader(cat)
        local keys = categories[cat]
        table.sort(keys, function(a,b)
            local da, db = S[a], S[b]
            local na = (da and da.name) or a
            local nb = (db and db.name) or b
            if na == nb then return a < b end
            return tostring(na) < tostring(nb)
        end)

        for _, key in ipairs(keys) do
            local def = S[key] or {}
            local row = vgui.Create("DPanel", container)
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, 10)
            row:SetTall(64)
            row.Paint = function() end

            local nameLbl = vgui.Create("DLabel", row)
            nameLbl:SetPos(0, 0)
            nameLbl:SetFont("InvSmall")
            nameLbl:SetTextColor(Color(230,230,230))
            nameLbl:SetText((def.name or key))
            nameLbl:SizeToContents()

            local descLbl = vgui.Create("DLabel", row)
            descLbl:SetPos(0, 20)
            descLbl:SetFont("InvSmall")
            descLbl:SetTextColor(Color(170,170,170))
            descLbl:SetText(def.desc or "")
            descLbl:SetWide(math.max(0, (container:GetWide() - ctlW - 20)))
            descLbl:SetWrap(true)
            if descLbl.SetAutoStretchVertical then descLbl:SetAutoStretchVertical(true) end

            local controlType = string.lower(tostring(def.type or "tickbox"))
            local curVal = Monarch.GetSetting and Monarch.GetSetting(key) or def.default

            if controlType == "tickbox" then

                local wrap = vgui.Create("DPanel", row)
                wrap.Paint = function() end
                placeRight(wrap, 28, 48)

                local toggle = vgui.Create("DButton", wrap)
                toggle:SetSize(48, 24)
                toggle:SetPos(0, 0)
                toggle:SetText("")
                toggle:SetCursor("hand")
                toggle.Checked = tobool(curVal)
                toggle.HoverAlpha = 0
                toggle.CircleX = tobool(curVal) and 24 or 0

                function toggle:SetChecked(v)
                    self.Checked = tobool(v)
                end
                function toggle:GetChecked()
                    return tobool(self.Checked)
                end

                function toggle:DoClick()
                    self.Checked = not self.Checked

                    if Monarch.SetSetting then
                        Monarch.SetSetting(key, self.Checked and 1 or 0)
                    end
                end

                function toggle:OnCursorEntered()
                    self.HoverAlpha = 0
                end

                function toggle:OnCursorExited()
                    self.HoverAlpha = 0
                end

                toggle.Paint = function(s, pw, ph)
                    local P = GetP()
                    local radius = math.floor(ph * 0.5)

                    local targetX = s.Checked and (pw - radius * 2) or 0

                    if not s.CircleX then s.CircleX = targetX end
                    s.CircleX = Lerp(FrameTime() * 8, s.CircleX, targetX)

                    local trackBg = s.Checked and Color(70, 150, 100, 200) or Color(200, 100, 100, 100)
                    draw.RoundedBox(radius, 0, 0, pw, ph, trackBg)

                    local circleBg = Color(200, 200, 200)
                    draw.RoundedBox(radius, s.CircleX, 0, radius * 2, ph, circleBg)
                end

                toggle._nextSync = 0
                function toggle:Think()
                    if CurTime() < (self._nextSync or 0) then return end
                    self._nextSync = CurTime() + 0.3
                    local v = Monarch.GetSetting and Monarch.GetSetting(key)
                    if v ~= nil then
                        local b = tobool(v)
                        if b ~= self.Checked then
                            self.Checked = b
                        end
                    end
                end

                function wrap:GetChecked()
                    return toggle:GetChecked()
                end
                function wrap:SetChecked(v)
                    toggle:SetChecked(v)
                end
            elseif controlType == "slider" then
                local slider = vgui.Create("DNumSlider", row)
                slider:SetMinMax(tonumber(def.minValue) or 0, tonumber(def.maxValue) or 100)
                slider:SetDecimals(2)
                slider:SetValue(tonumber(curVal) or tonumber(def.default) or 0)
                placeRight(slider, 28)
                styleSlider(slider)
                function slider:OnValueChanged(val)
                    if Monarch.SetSetting then Monarch.SetSetting(key, tonumber(val) or 0) end
                end
            elseif controlType == "plainint" then
                local entry = vgui.Create("DTextEntry", row)
                entry:SetNumeric(true)
                entry:SetText(tostring(curVal or def.default or 0))
                placeRight(entry, 24)
                styleEntry(entry)
                function entry:OnEnter(val)
                    if Monarch.SetSetting then Monarch.SetSetting(key, tonumber(val) or 0) end
                end
                function entry:OnLoseFocus()
                    if Monarch.SetSetting then Monarch.SetSetting(key, tonumber(entry:GetText()) or 0) end
                end
            elseif controlType == "keybind" then

                local wrap = vgui.Create("DPanel", row)
                wrap.Paint = function() end
                placeRight(wrap, 24, 200)

                local function KeyNameFor(k)
                    if input and input.GetKeyName then
                        local n = input.GetKeyName(tonumber(k) or 0)
                        if isstring(n) and n ~= "" then return string.upper(n) end
                    end
                    local m = {
                        [KEY_NONE] = "UNBOUND",
                        [KEY_SPACE] = "SPACE",
                        [KEY_TAB] = "TAB",
                        [KEY_ESCAPE] = "ESC",
                        [KEY_ENTER] = "ENTER",
                        [KEY_BACKSPACE] = "BACKSPACE",
                        [KEY_LSHIFT] = "L-SHIFT",
                        [KEY_RSHIFT] = "R-SHIFT",
                        [KEY_LCONTROL] = "L-CTRL",
                        [KEY_RCONTROL] = "R-CTRL",
                        [KEY_LALT] = "L-ALT",
                        [KEY_RALT] = "R-ALT",
                        [KEY_F1] = "F1",[KEY_F2] = "F2",[KEY_F3] = "F3",[KEY_F4] = "F4",
                        [KEY_F5] = "F5",[KEY_F6] = "F6",[KEY_F7] = "F7",[KEY_F8] = "F8",
                        [KEY_F9] = "F9",[KEY_F10] = "F10",[KEY_F11] = "F11",[KEY_F12] = "F12",
                    }
                    return m[tonumber(k) or 0] or ("#" .. tostring(k))
                end

                local bindBtn = vgui.Create("DButton", wrap)
                bindBtn:SetText(KeyNameFor(curVal))
                bindBtn:Dock(LEFT)
                bindBtn:DockMargin(0,0,8,0)
                bindBtn:SetWide(130)
                styleButton(bindBtn)

                local clearBtn = vgui.Create("DButton", wrap)
                clearBtn:SetText("Clear")
                clearBtn:Dock(LEFT)
                clearBtn:SetWide(60)
                styleButton(clearBtn)

                function clearBtn:DoClick()
                    if Monarch.SetSetting then Monarch.SetSetting(key, KEY_NONE or 0) end
                    if IsValid(bindBtn) then bindBtn:SetText("UNBOUND") end
                    surface.PlaySound("mrp/ui/click.wav")
                end

                function bindBtn:DoClick()
                    local overlay = vgui.Create("DFrame")
                    overlay:SetSize(320, 120)
                    overlay:Center()
                    overlay:SetTitle("Press a key to bind")
                    overlay:MakePopup()
                    overlay:SetDraggable(true)
                    overlay:ShowCloseButton(true)
                    function overlay:Paint(pw, ph)
                        local P = GetP()
                        surface.SetDrawColor(P.inputBg) surface.DrawRect(0,0,pw,ph)
                        surface.SetDrawColor(P.inputBorder) surface.DrawOutlinedRect(0,0,pw,ph,1)
                        draw.SimpleText("Waiting for key...", "InvSmall", pw/2, ph/2, P.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                    function overlay:OnKeyCodePressed(kc)
                        if Monarch.SetSetting then Monarch.SetSetting(key, tonumber(kc) or 0) end
                        if IsValid(bindBtn) then bindBtn:SetText(KeyNameFor(kc)) end
                        self:Close()
                        surface.PlaySound("mrp/ui/click.wav")
                    end
                end
            elseif controlType == "dropdown" then
                local combo = vgui.Create("DComboBox", row)
                combo:SetSortItems(false)
                local cur = curVal or def.default
                if istable(def.options) then
                    for _, opt in ipairs(def.options) do
                        combo:AddChoice(tostring(opt), opt)
                    end
                end
                timer.Simple(0, function()
                    if not IsValid(combo) then return end
                    local choices = combo.Choices or {}
                    for id, text in ipairs(choices) do
                        local data = combo:GetOptionData(id)
                        if data == cur or text == cur then
                            combo:ChooseOptionID(id)
                            break
                        end
                    end
                end)
                placeRight(combo, 24)
                styleCombo(combo)
                function combo:OnSelect(_, _, data)
                    if Monarch.SetSetting then Monarch.SetSetting(key, data) end
                end
            else
                local entry = vgui.Create("DTextEntry", row)
                entry:SetText(tostring(curVal or def.default or ""))
                placeRight(entry, 24)
                styleEntry(entry)
                function entry:OnEnter(val)
                    if Monarch.SetSetting then Monarch.SetSetting(key, tostring(val or "")) end
                end
                function entry:OnLoseFocus()
                    if Monarch.SetSetting then Monarch.SetSetting(key, tostring(entry:GetText() or "")) end
                end
            end
        end
    end

    addSpacer(6)
    local reset = vgui.Create("DButton", container)
    reset:Dock(TOP)
    reset:SetTall(26)
    reset:SetText("Reset to Defaults")
    styleButton(reset)
    reset.DoClick = function()
        local S = Monarch and Monarch.Settings
        if not (S and istable(S)) then return end
        for k, meta in pairs(S) do
            if istable(meta) then
                if Monarch.SetSetting then Monarch.SetSetting(k, meta.default) end
            end
        end
        surface.PlaySound("mrp/ui/click.wav")

        if IsValid(base) and IsValid(parent) then
            base:Remove()
            self:CreateSettingsPanel(parent):SetVisible(true)
        end
    end

    return base
end

end

