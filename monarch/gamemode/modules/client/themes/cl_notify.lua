surface.CreateFont("CombineNotifyMain", {
    font = "Din Pro Medium",
    size = 23,
    extended = true
})

surface.CreateFont("CombineNotifySmall", {
    font = "Din Pro Medium",
    size = 17,
    extended = true
})

local ScreenPosY        = 28
local ScreenPosXMargin  = 28

local BG_COLOR          = Color(5, 5, 5, 0)
local BG_COLOR_ALT      = Color(15, 15, 15, 0)
local FOREGROUND_COLOR  = Color(230, 230, 0,0)
local ACCENT_DEFAULT    = Color(210, 210, 210,0)
local ACCENT_ERROR      = Color(170, 170, 170,0)
local ACCENT_HINT       = Color(190, 190, 190,0)
local ACCENT_UNDO       = Color(160, 160, 160,0)
local ACCENT_CLEANUP    = Color(140, 140, 140,0)
local ACCENT_LOADING    = Color(200, 200, 200,0)

local TypeAccent = {
    [NOTIFY_GENERIC]  = ACCENT_DEFAULT,
    [NOTIFY_ERROR]    = ACCENT_ERROR,
    [NOTIFY_HINT]     = ACCENT_HINT,
    [NOTIFY_UNDO]     = ACCENT_UNDO,
    [NOTIFY_CLEANUP]  = ACCENT_CLEANUP
}

local Notifications = {}

local function PlayNotifySound()
    if Config and Config.NotifySound then
        surface.PlaySound(Config.NotifySound)
    end
end

local function LerpColor(t, a, b)
    return Color(
        Lerp(t, a.r, b.r),
        Lerp(t, a.g, b.g),
        Lerp(t, a.b, b.b),
        Lerp(t, a.a, b.a)
    )
end

local function DrawGlitchAccent(x, y, h, accentCol, a)
    local baseA = math.floor(accentCol.a * a)
    surface.SetDrawColor(255, 255, 255, baseA * 0.55)
    surface.DrawRect(x, y, 4, h)

    local pulse = 0.35 + math.sin(CurTime()*5.5) * 0.25
    surface.SetDrawColor(255, 255, 255, baseA * pulse * 0.45)
    surface.DrawRect(x+4, y, 2, h)

    local scanY = y + (h * ((CurTime()*0.6)%1))
    surface.SetDrawColor(255,255,255, baseA * 0.75)
    surface.DrawRect(x, scanY, 6, 2)
end

local function DrawProgressBar(x, y, w, h, frac, accentCol, a)
    frac = math.Clamp(frac or 0, 0, 1)
    local barH = 3
    local by = y + h - barH
    surface.SetDrawColor(40, 40, 40, math.floor(160 * a))
    surface.DrawRect(x, by, w, barH)
    surface.SetDrawColor(230, 230, 230, math.floor(230 * a))
    surface.DrawRect(x, by, w * frac, barH)
end

local function GetWrappedTextDimensions(text, maxWidth, font)
    surface.SetFont(font)
    local explodedLines = string.Explode("\n", text)
    local lines = {}

    for _, explodedLine in ipairs(explodedLines) do
        local words = string.Explode(" ", explodedLine)
        local currentLine = ""

        for _, word in ipairs(words) do
            local testLine = currentLine == "" and word or currentLine .. " " .. word
            local tw = surface.GetTextSize(testLine)

            if tw > maxWidth and currentLine ~= "" then
                table.insert(lines, currentLine)
                currentLine = word
            else
                currentLine = testLine
            end
        end

        if currentLine ~= "" or explodedLine == "" then
            table.insert(lines, currentLine)
        end
    end

    local _, th = surface.GetTextSize("A")
    return lines, th * #lines
end

local function DrawNotification(n)
    local a = n.alpha
    local x, y, w, h = math.floor(n.x), math.floor(n.y), n.w, n.h
    local accent = n.accent

    surface.SetFont("CombineNotifyMain")
    local _, th = surface.GetTextSize("A")
    local tx = x + 10 + 10
    local ty = y + 10

    surface.SetTextColor(color_white)
    for i, line in ipairs(n.lines or {n.text}) do
        surface.SetTextPos(tx, ty + (i - 1) * (th + 2))
        surface.DrawText(line)
    end

    if n.progress then
        DrawProgressBar(x, y, w, h, n.progress, n.accent, a)
    end
end

local function AddNotification(tbl)
    table.insert(Notifications, tbl)
    PlayNotifySound()
end

function notification.AddLegacy(text, type, time)
    local maxWidth = 350
    local lines, textHeight = GetWrappedTextDimensions(text, maxWidth - 40, "CombineNotifyMain")
    local w = math.max(220, maxWidth)
    local h = math.max(54, textHeight + 20)

    AddNotification({
        text     = text,
        lines    = lines,
        type     = type,
        accent   = TypeAccent[type] or ACCENT_DEFAULT,
        lifeSpan = time,
        time     = CurTime() + time,
        progress = nil,
        removing = false,
        x        = ScrW() + w,
        y        = ScreenPosY,
        w        = w,
        h        = h,
        alpha    = 0
    })
end

function notification.AddProgress(id, text, frac)
    for _, n in ipairs(Notifications) do
        if n.id == id then
            local maxWidth = 350
            local lines, textHeight = GetWrappedTextDimensions(text, maxWidth - 40, "CombineNotifyMain")
            n.text = text
            n.lines = lines
            n.progress = math.Clamp(frac or 0, 0, 1)
            n.h = math.max(60, textHeight + 30)
            n.time = math.huge
            return
        end
    end
    local maxWidth = 350
    local lines, textHeight = GetWrappedTextDimensions(text, maxWidth - 40, "CombineNotifyMain")
    local w = math.max(240, maxWidth)
    local h = math.max(60, textHeight + 30)

    AddNotification({
        id       = id,
        text     = text,
        lines    = lines,
        type     = NOTIFY_GENERIC,
        accent   = ACCENT_LOADING,
        lifeSpan = math.huge,
        time     = math.huge,
        progress = math.Clamp(frac or 0, 0, 1),
        removing = false,
        x        = ScrW() + w,
        y        = ScreenPosY,
        w        = w,
        h        = h,
        alpha    = 0
    })
end

function notification.Kill(id)
    for _, n in ipairs(Notifications) do
        if n.id == id then
            n.removing = true
            n.time = CurTime()
        end
    end
end

function Notify(text, time)
    notification.AddLegacy(text, NOTIFY_GENERIC, time or 4)
end

hook.Add("HUDPaint", "Combine_DrawNotifications", function()
    local now = CurTime()
    for _, n in ipairs(Notifications) do
        if not n.removing and n.time ~= math.huge and n.time <= now then
            n.removing = true
        end
    end

    local idx = 0
    for _, n in ipairs(Notifications) do
        if not n.removing then
            idx = idx + 1
            local targetY = ScreenPosY + (idx - 1) * (n.h + 6)
            n.y = Lerp(FrameTime() * 12, n.y, targetY)
        end
        local targetX = n.removing and (ScrW() + n.w) or (ScrW() - n.w - ScreenPosXMargin - (n.w * 0.15))
        n.x = Lerp(FrameTime() * 10, n.x, targetX)

        local targetAlpha = n.removing and 0 or 1
        n.alpha = Lerp(FrameTime() * 10, n.alpha, targetAlpha)

        DrawNotification(n)
    end

    for i = #Notifications, 1, -1 do
        local n = Notifications[i]
        if n.removing and math.abs(n.x - (ScrW() + n.w)) < 2 then
            table.remove(Notifications, i)
        end
    end
end)
