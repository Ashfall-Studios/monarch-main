Monarch = Monarch or {}
Monarch.UI = Monarch.UI or {}

local REF_W, REF_H = 1920, 1080
local cachedW, cachedH = 0, 0
local cachedScale, cachedScaleX, cachedScaleY = 1, 1, 1

local function recalc()
	cachedW, cachedH = ScrW(), ScrH()
	cachedScaleX = cachedW / REF_W
	cachedScaleY = cachedH / REF_H
	cachedScale = math.min(cachedScaleX, cachedScaleY)
end

function Monarch.UI.GetScale()
	if cachedW ~= ScrW() or cachedH ~= ScrH() then
		recalc()
	end
	return cachedScale, cachedScaleX, cachedScaleY
end

function Monarch.UI.Scale(v)
	local s = select(1, Monarch.UI.GetScale())
	return math.floor((v or 0) * s + 0.5)
end

function Monarch.UI.ScaleX(v)
	local _, sx = Monarch.UI.GetScale()
	return math.floor((v or 0) * sx + 0.5)
end

function Monarch.UI.ScaleY(v)
	local _, _, sy = Monarch.UI.GetScale()
	return math.floor((v or 0) * sy + 0.5)
end

function Monarch.UI.ScaleFont(sz)
	return Monarch.UI.Scale(sz)
end

function Monarch.UI.ScreenCenter()
	return ScrW() * 0.5, ScrH() * 0.5
end

function Monarch.UI.BlinkAlpha(baseAlpha)
	local ba = baseAlpha or 255
	return ba * (0.5 + 0.5 * math.sin(CurTime() * 10))
end

function Monarch.MakeWorkbar(time, text, callback, freeze) -- this isnt clean at all and i hate it, dont use it
    local workbar = vgui.Create("DPanel")
    workbar:SetSize(300, 60)
    workbar:Center()
    workbar:MakePopup()
    workbar:SetKeyboardInputEnabled(false)

    local startTime = CurTime()
    local endTime = startTime + time

    if freeze then
        LocalPlayer():Freeze(true)
    end

    workbar.Paint = function(self, w, h)
        surface.SetDrawColor(40, 40, 40, 240)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(120, 120, 120, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        local progress = math.Clamp((CurTime() - startTime) / time, 0, 1)
        surface.SetDrawColor(60, 120, 60, 200)
        surface.DrawRect(5, h - 15, (w - 10) * progress, 10)

        surface.SetDrawColor(100, 200, 100, 255)
        surface.DrawOutlinedRect(5, h - 15, w - 10, 10, 1)

        surface.SetFont("MonarchInventory_Text")
        local textW, textH = surface.GetTextSize(text)
        surface.SetTextColor(255, 255, 255)
        surface.SetTextPos((w - textW) / 2, (h - textH) / 2 + 14)
        surface.DrawText(text)
    end

    workbar.Think = function(self)
        if CurTime() >= endTime then
            if freeze then
                LocalPlayer():Freeze(false)
            end

            if callback then
                callback()
            end

            self:Remove()
        end

        if input.IsKeyDown(KEY_SPACE) then
            if freeze then
                LocalPlayer():Freeze(false)
            end
            self:Remove()
        end
    end
end

function Scale(v) return Monarch.UI.Scale(v) end
function ScaleX(v) return Monarch.UI.ScaleX(v) end
function ScaleY(v) return Monarch.UI.ScaleY(v) end
function ScaleFont(sz) return Monarch.UI.ScaleFont(sz) end

hook.Add("OnScreenSizeChanged", "Monarch.UI.RecalcScale", recalc)
recalc()
