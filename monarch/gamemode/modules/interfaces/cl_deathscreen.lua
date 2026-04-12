
local w, h = ScrW(), ScrH()
local blurDrawPanel = {
	[1] = function(x, y, w, h)

		render.UpdateScreenEffectTexture()

		render.SetScissorRect(x, y, x+w, y+h, true)
		DrawBokehDOF(6, 0, 0)
		render.SetScissorRect(0, 0, 0, 0, false)
	end
}

local function BlurRect(x, y, w, h)
	blurDrawPanel[1](x,y,w,h)
end

local function FormatCountdown(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60

    local minLabel = mins == 1 and "minute" or "minutes"
    local secLabel = secs == 1 and "second" or "seconds"
    return string.format("%d %s and %d %s", mins, minLabel, secs, secLabel)
end

surface.CreateFont("Monarch_DeathScreenLarge", {
    font = "Din Pro Bold",
    size = 80,
    weight = 800,
    antialias = true,
})

surface.CreateFont("Monarch_DeathScreenLargeBlur", {
    font = "Din Pro Bold",
    size = 80,
    weight = 1000,
    antialias = true,
    blursize = 5
})

surface.CreateFont("Monarch_DeathScreenMed", {
    font = "Din Pro Regular",
    size = 24,
    italic = true,
    weight = 100,
    antialias = true,
})

surface.CreateFont("Monarch_DeathScreenSmall", {
    font = "Din Pro Regular",
    size = 22,
    weight = 100,
    antialias = true,
})

local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    self:SetDeleteOnClose(false)
    self:SetAlpha(0)
    self:AlphaTo(255, 0.5, 0)

    timer.Create("DeathScreenClose", Config.DeathTimer, 1, function()
        self.CanRespawn = true
        self.respawnLabel:SetText("Press any key to respawn...")
        RunConsoleCommand("monarch_reloadmainmenu")
    end)

    local seconds = math.ceil(timer.TimeLeft("DeathScreenClose") or 0)

    self.background = vgui.Create("DPanel", self)
    self.background:Dock(FILL)
    self.background.Paint = function(s, w, h)
        surface.SetDrawColor(20, 20, 20, 20)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(255, 255, 255, 100)
    end

    self.titleLabelShadow = vgui.Create("DLabel", self.background)
    self.titleLabelShadow:SetFont("Monarch_DeathScreenLarge")
    self.titleLabelShadow:SetText("NEAR DEATH")
    self.titleLabelShadow:SetTextColor(Color(0, 0, 0, 250))
    self.titleLabelShadow:SizeToContents()
    self.titleLabelShadow:Center()
    self.titleLabelShadow:SetY(ScrH() / 2 - 100 + 2)
    self.titleLabelShadow:SetX((ScrW() - self.titleLabelShadow:GetWide()) / 2 + 2)

    self.titleLabel = vgui.Create("DLabel", self.background)
    self.titleLabel:SetFont("Monarch_DeathScreenLarge")
    self.titleLabel:SetText("NEAR DEATH")
    self.titleLabel:SetTextColor(Color(255, 60, 60, 255))
    self.titleLabel:SizeToContents()
    self.titleLabel:Center()
    self.titleLabel:SetY(ScrH() / 2 - 100)
    self.titleLabel:SetX((ScrW() - self.titleLabel:GetWide()) / 2)

    self.respawnLabel = vgui.Create("DLabel", self.background)
    self.respawnLabel:SetFont("Monarch_DeathScreenMed")
    self.respawnLabel:SetText("You will respawn in " .. FormatCountdown(seconds) .. "...")
    self.respawnLabel:SizeToContents()
    self.respawnLabel:Center()
    self.respawnLabel:SetY(ScrH() / 2 + 50)
    self.respawnLabel:SetX((ScrW() - self.respawnLabel:GetWide()) / 2)

    self.warningLabel = vgui.Create("DLabel", self.background)
    self.warningLabel:SetFont("Monarch_DeathScreenSmall")
    self.warningLabel:SetText("WARNING: If you disconnect now, you may be subject to penalties.")
    self.warningLabel:SizeToContents()
    self.warningLabel:Center()
    self.warningLabel:SetY(ScrH() / 2 + 90)
    self.warningLabel:SetX((ScrW() - self.warningLabel:GetWide()) / 2)
end

PANEL.Paint = function(s, w, h)

    BlurRect(0, 0, w, h)

    surface.SetDrawColor(0, 0, 0, 150)
    surface.DrawRect(0, 0, w, h)
end

function PANEL:Think()
    if LocalPlayer():Health() > 0 then
        self:Close()
        return
    end

    local seconds = math.ceil(timer.TimeLeft("DeathScreenClose") or 0)
    if not self.CanRespawn then
        self.respawnLabel:SetText("You will respawn in " .. FormatCountdown(seconds) .. "...")
    end
end

vgui.Register("MonarchDeathScreen", PANEL, "DFrame")

local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    self:SetDeleteOnClose(false)
    self:SetAlpha(0)
    self:AlphaTo(255, 0.5, 0)

    self.background = vgui.Create("DPanel", self)
    self.background:Dock(FILL)
    self.background.Paint = function(s, w, h)
        surface.SetDrawColor(20, 20, 20, 20)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(255, 255, 255, 100)
    end

    self.titleLabelShadow = vgui.Create("DLabel", self.background)
    self.titleLabelShadow:SetFont("Monarch_DeathScreenLarge")
    self.titleLabelShadow:SetText("SLEEPING...")
    self.titleLabelShadow:SetTextColor(Color(0, 0, 0, 250))
    self.titleLabelShadow:SizeToContents()
    self.titleLabelShadow:Center()
    self.titleLabelShadow:SetY(ScrH() / 2 - 100 + 2)
    self.titleLabelShadow:SetX((ScrW() - self.titleLabelShadow:GetWide()) / 2 + 2)

    self.titleLabel = vgui.Create("DLabel", self.background)
    self.titleLabel:SetFont("Monarch_DeathScreenLarge")
    self.titleLabel:SetText("SLEEPING...")
    self.titleLabel:SizeToContents()
    self.titleLabel:Center()
    self.titleLabel:SetY(ScrH() / 2 - 100)
    self.titleLabel:SetX((ScrW() - self.titleLabel:GetWide()) / 2)

    self.warningLabel = vgui.Create("DLabel", self.background)
    self.warningLabel:SetFont("Monarch_DeathScreenMed")
    self.warningLabel:SetText("Press the interact key to wake up...")
    self.warningLabel:SizeToContents()
    self.warningLabel:Center()
    self.warningLabel:SetY(ScrH() / 2 + 90)
    self.warningLabel:SetX((ScrW() - self.warningLabel:GetWide()) / 2)
end

PANEL.Paint = function(s, w, h)

    BlurRect(0, 0, w, h)

    surface.SetDrawColor(0, 0, 0, 255)
    surface.DrawRect(0, 0, w, h)
end

function PANEL:Think()
    if not LocalPlayer().IsSleeping then
        self:Close()
        return
    end
end

vgui.Register("MonarchSleepScreen", PANEL, "DFrame")

local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    self:SetDeleteOnClose(false)
    self:SetAlpha(0)
    self:AlphaTo(255, 0.5, 0)
    self:MakePopup()
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)

    timer.Create("UnconsciousScreenClose", Config.ExhaustionCollapseTime or 10, 1, function()
        self.CanRespawn = true
    end)

    local seconds = math.ceil(timer.TimeLeft("UnconsciousScreenClose") or 0)

    self.background = vgui.Create("DPanel", self)
    self.background:Dock(FILL)
    self.background.Paint = function(s, w, h)
        surface.SetDrawColor(20, 20, 20, 20)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(255, 255, 255, 100)
    end

    self.titleLabelShadow = vgui.Create("DLabel", self.background)
    self.titleLabelShadow:SetFont("Monarch_DeathScreenLarge")
    self.titleLabelShadow:SetText("UNCONSCIOUS")
    self.titleLabelShadow:SetTextColor(Color(0, 0, 0, 250))
    self.titleLabelShadow:SizeToContents()
    self.titleLabelShadow:Center()
    self.titleLabelShadow:SetY(ScrH() / 2 - 100 + 2)
    self.titleLabelShadow:SetX((ScrW() - self.titleLabelShadow:GetWide()) / 2 + 2)

    self.titleLabel = vgui.Create("DLabel", self.background)
    self.titleLabel:SetFont("Monarch_DeathScreenLarge")
    self.titleLabel:SetText("UNCONSCIOUS")
    self.titleLabel:SizeToContents()
    self.titleLabel:Center()
    self.titleLabel:SetY(ScrH() / 2 - 100)
    self.titleLabel:SetX((ScrW() - self.titleLabel:GetWide()) / 2)

    self.respawnLabel = vgui.Create("DLabel", self.background)
    self.respawnLabel:SetFont("Monarch_DeathScreenMed")
    self.respawnLabel:SetText("You will wake up in " .. seconds .. " seconds...")
    self.respawnLabel:SizeToContents()
    self.respawnLabel:Center()
    self.respawnLabel:SetY(ScrH() / 2 + 50)
    self.respawnLabel:SetX((ScrW() - self.respawnLabel:GetWide()) / 2)

    self.warningLabel = vgui.Create("DLabel", self.background)
    self.warningLabel:SetFont("Monarch_DeathScreenSmall")
    self.warningLabel:SetText("WARNING: If you disconnect now, you may be subject to penalties.")
    self.warningLabel:SizeToContents()
    self.warningLabel:Center()
    self.warningLabel:SetY(ScrH() / 2 + 90)
    self.warningLabel:SetX((ScrW() - self.warningLabel:GetWide()) / 2)
end

PANEL.Paint = function(s, w, h)

    BlurRect(0, 0, w, h)

    surface.SetDrawColor(0, 0, 0, 150)
    surface.DrawRect(0, 0, w, h)
end

function PANEL:Think()
    if not LocalPlayer():GetNWBool("IsUnconscious", false) then
        self:Close()
        return
    end

    local seconds = math.ceil(timer.TimeLeft("UnconsciousScreenClose") or 0)
    if not self.CanRespawn then
        self.respawnLabel:SetText("You will wake up in " .. seconds .. " seconds...")
    end
end

vgui.Register("MonarchUnconsciousScreen", PANEL, "DFrame")
