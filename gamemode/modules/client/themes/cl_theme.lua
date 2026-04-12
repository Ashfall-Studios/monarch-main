Monarch = Monarch or {}
Monarch.Theme = Monarch.Theme or {}

local cookie = cookie
local surface = surface

local palettes = {
    dark = {
        name = "dark",
        bg = Color(20, 20, 20),
        bgAlt = Color(28, 28, 28),
        panel = Color(25, 25, 25),
        outline = Color(50, 50, 50),
        text = Color(220, 220, 220),
        textMuted = Color(180, 180, 180),
        titlebar = Color(35, 35, 35),
        divider = Color(60, 60, 60, 160),
        btn = Color(45, 45, 45),
        btnHover = Color(65, 65, 65),
        btnText = Color(230, 230, 230),
        inputBg = Color(30, 30, 30),
        inputBorder = Color(80, 80, 80),
        inputText = Color(210, 210, 210),
    primary = Color(85, 85, 85),
    primaryHover = Color(120, 120, 120),
    selection = Color(140, 140, 140, 55),
        scrollTrack = Color(35, 35, 35),
        scrollGrip = Color(80, 80, 80),
        scrollGripHover = Color(100, 100, 100),
        radius = 6,
        spacing = { xs=4, sm=8, md=12, lg=16, xl=24 }
    },
    figma = {
        name = "dark",
        bg = Color(20, 20, 20),
        bgAlt = Color(28, 28, 28),
        panel = Color(25, 25, 25),
        outline = Color(50, 50, 50),
        text = Color(220, 220, 220),
        textMuted = Color(180, 180, 180),
        titlebar = Color(35, 35, 35),
        divider = Color(60, 60, 60, 160),
        btn = Color(45, 45, 45),
        btnHover = Color(65, 65, 65),
        btnText = Color(230, 230, 230),
        inputBg = Color(30, 30, 30),
        inputBorder = Color(80, 80, 80),
        inputText = Color(210, 210, 210),
    primary = Color(85, 85, 85),
    primaryHover = Color(120, 120, 120),
    selection = Color(140, 140, 140, 55),
        scrollTrack = Color(35, 35, 35),
        scrollGrip = Color(80, 80, 80),
        scrollGripHover = Color(100, 100, 100),
        radius = 6,
        spacing = { xs=4, sm=8, md=12, lg=16, xl=24 }
    },
    light = {
        name = "dark",
        bg = Color(20, 20, 20),
        bgAlt = Color(28, 28, 28),
        panel = Color(25, 25, 25),
        outline = Color(50, 50, 50),
        text = Color(220, 220, 220),
        textMuted = Color(180, 180, 180),
        titlebar = Color(35, 35, 35),
        divider = Color(60, 60, 60, 160),
        btn = Color(45, 45, 45),
        btnHover = Color(65, 65, 65),
        btnText = Color(230, 230, 230),
        inputBg = Color(30, 30, 30),
        inputBorder = Color(80, 80, 80),
        inputText = Color(210, 210, 210),
    primary = Color(85, 85, 85),
    primaryHover = Color(120, 120, 120),
    selection = Color(140, 140, 140, 55),
        scrollTrack = Color(35, 35, 35),
        scrollGrip = Color(80, 80, 80),
        scrollGripHover = Color(100, 100, 100),
        radius = 6,
        spacing = { xs=4, sm=8, md=12, lg=16, xl=24 }
    }
}

local function getDefaultTheme()
    local saved = cookie and cookie.GetString("monarch_theme", "dark") or "dark"
    if palettes[saved] then return saved end
    return "dark"
end

Monarch.Theme.current = Monarch.Theme.current or getDefaultTheme()

function Monarch.Theme.Get()
    return palettes[Monarch.Theme.current]
end

function Monarch.Theme.Set(name)
    if not palettes[name] then return end
    if Monarch.Theme.current == name then return end
    Monarch.Theme.current = name
    if cookie then cookie.Set("monarch_theme", name) end
    hook.Run("MonarchThemeChanged", name)
end

local function LerpColor(t, a, b)
    return Color(
        Lerp(t, a.r, b.r),
        Lerp(t, a.g, b.g),
        Lerp(t, a.b, b.b),
        Lerp(t, a.a or 255, b.a or 255)
    )
end

Monarch.Theme.LerpColor = LerpColor

do
    local SKIN = {}
    SKIN.PrintName = "Monarch Dynamic Skin"
    SKIN.Author = "Monarch"
    SKIN.DermaVersion = 1

    function SKIN:PaintFrame(panel, w, h)
        local P = Monarch.Theme.Get()
        surface.SetDrawColor(P.panel)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(P.outline)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        surface.SetDrawColor(P.titlebar)
        surface.DrawRect(0, 0, w, panel.topBarH or 28)
        surface.SetDrawColor(P.divider)
        surface.DrawLine(0, panel.topBarH or 28, w, panel.topBarH or 28)
    end

    function SKIN:PaintPanel(panel, w, h)
        if not panel.m_bBackground then return end
        local P = Monarch.Theme.Get()
        local bg = panel._bgOverride or P.panel
        if isstring(bg) then bg = P[bg] or P.panel end
        surface.SetDrawColor(bg)
        surface.DrawRect(0, 0, w, h)
        if panel._border then
            surface.SetDrawColor(P.outline)
            surface.DrawOutlinedRect(0, 0, w, h)
        end
    end

    function SKIN:PaintButton(panel, w, h)
        local P = Monarch.Theme.Get()
        local bg = P.btn
        if panel:GetDisabled() then
            bg = Color(bg.r, bg.g, bg.b, 120)
        elseif panel.Depressed or panel:IsSelected() or panel:GetToggle() then
            bg = P.primary
        elseif panel.Hovered then
            bg = P.btnHover
        end
        surface.SetDrawColor(bg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(P.outline)
        surface.DrawOutlinedRect(0, 0, w, h)
    end

    function SKIN:SchemeButton(panel)
        local P = Monarch.Theme.Get()
        panel:SetTextColor(P.btnText)
    end

    function SKIN:PaintTextEntry(panel, w, h)
        local P = Monarch.Theme.Get()
        surface.SetDrawColor(P.inputBg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(P.inputBorder)
        surface.DrawOutlinedRect(0, 0, w, h)
        panel:DrawTextEntryText(P.inputText, P.selection, P.inputText)
    end

    function SKIN:PaintVScrollBar(panel, w, h)
        local P = Monarch.Theme.Get()
        surface.SetDrawColor(P.scrollTrack)
        surface.DrawRect(0, 0, w, h)
    end

    function SKIN:PaintScrollBarGrip(panel, w, h)
        local P = Monarch.Theme.Get()
        local clr = panel.Hovered and P.scrollGripHover or P.scrollGrip
        surface.SetDrawColor(clr)
        surface.DrawRect(0, 0, w, h)
    end

    function SKIN:PaintPropertySheet(panel, w, h)
        local P = Monarch.Theme.Get()
        surface.SetDrawColor(P.panel)
        surface.DrawRect(0, 0, w, h)
    end

    function SKIN:PaintTab(panel, w, h)
        local P = Monarch.Theme.Get()
        local bg = panel:IsActive() and P.primary or P.bgAlt
        surface.SetDrawColor(bg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(P.outline)
        surface.DrawOutlinedRect(0, 0, w, h)
    end

    function SKIN:SchemeTab(panel)
        local P = Monarch.Theme.Get()
        panel:SetTextColor(panel:IsActive() and P.btnText or P.text)
    end

    derma.DefineSkin("MonarchSkin", "Dynamic Monarch theme skin", SKIN)
end

function Monarch.Theme.AttachSkin(panel)
    if not IsValid(panel) then return end
    panel:SetSkin("MonarchSkin")
end

return Monarch.Theme
