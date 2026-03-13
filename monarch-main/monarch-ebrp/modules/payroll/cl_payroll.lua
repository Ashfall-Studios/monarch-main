
Monarch.Payroll = Monarch.Payroll or {}

net.Receive("Monarch.SendPayrollClient", function(len)
    LocalPlayer():Notify("Because of your work in the City you have received your pay. You can cash your check in at the bank.", NOTIFY_GENERIC, 5)
end)

if not Monarch.UI or not Monarch.UI.Scale then
    include("monarch/gamemode/modules/client/cl_scale.lua")
end

local Scale = Monarch.UI.Scale or function(x) return x end

    surface.CreateFont("Monarch_LoyaltyNotification", {
        font = "Din Pro Regular",
        size = 24,
        weight = 300,
        antialias = true,
    })

local loyaltyMat = Material("mrp/hud/inv_bg.png")

if loyaltyMat:IsError() then
    loyaltyMat = Material("vgui/white")
end

local LoyaltyNotification = {
    active = false,
    start = 0,
    duration = 5.0,
    amount = 0,
}

hook.Add("Monarch_SettingChanged", "PayrollImmersiveToggle", function(settingName, newValue)
    if settingName == "immerse_mode" then
        immerse_mode = newValue
    end
end)

net.Receive("Monarch_LoyaltyGain", function()
    LoyaltyNotification.amount = net.ReadInt(8) or 0
    LoyaltyNotification.start = CurTime()
    LoyaltyNotification.active = true
end)

hook.Add("HUDPaint", "Monarch_DrawLoyaltyNotification", function()
    if not LoyaltyNotification.active then return end

    local t = CurTime() - (LoyaltyNotification.start or 0)
    local total = LoyaltyNotification.duration or 5
    if t >= total then 
        LoyaltyNotification.active = false 
        return 
    end

    local fadeInDuration = 0.2
    local fadeOutDuration = 0.2
    local alpha = 255
    local slideProgress = 1

    if t < fadeInDuration then
        local u = t / fadeInDuration
        alpha = math.floor(255 * (u * u * (3 - 2 * u)))
        slideProgress = u
    elseif t > (total - fadeOutDuration) then
        local u = (total - t) / fadeOutDuration
        alpha = math.floor(255 * (u * u * (3 - 2 * u)))
        slideProgress = u
    else
        alpha = 255
        slideProgress = 1
    end

    local scrW, scrH = ScrW(), ScrH()
    local notifW, notifH = Scale(100), Scale(40)
    local marginRight = Scale(20)

    local targetX = scrW - notifW - marginRight
    local startX = scrW

    local x = Lerp(slideProgress, startX, targetX)
    local y = (scrH * 0.25) - (notifH * 0.5)

    surface.SetMaterial(loyaltyMat)
    surface.SetDrawColor(0, 0, 0, math.Clamp(alpha * 0.9, 0, 150))
    surface.DrawTexturedRect(x, y, notifW, notifH)

    local cornerSize = Scale(12)
    local cornerThickness = 2
    surface.SetDrawColor(250, 250, 250, math.Clamp(alpha, 0, 150))

    surface.DrawRect(x, y, cornerSize, cornerThickness)
    surface.DrawRect(x, y, cornerThickness, cornerSize)

    surface.DrawRect(x + notifW - cornerSize, y, cornerSize, cornerThickness)
    surface.DrawRect(x + notifW - cornerThickness, y, cornerThickness, cornerSize)

    surface.DrawRect(x, y + notifH - cornerThickness, cornerSize, cornerThickness)
    surface.DrawRect(x, y + notifH - cornerSize, cornerThickness, cornerSize)

    surface.DrawRect(x + notifW - cornerSize, y + notifH - cornerThickness, cornerSize, cornerThickness)
    surface.DrawRect(x + notifW - cornerThickness, y + notifH - cornerSize, cornerThickness, cornerSize)

    local text = "+ " .. tostring(LoyaltyNotification.amount) .. " EXP"
    draw.SimpleText(text, "Monarch_LoyaltyNotification", x + notifW/2, y + notifH/2, 
        Color(250, 250, 250, math.Clamp(alpha, 0, 255)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)