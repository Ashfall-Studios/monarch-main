local PANEL = {}

function PANEL:Init()
    Monarch.hudEnabled = false
    Monarch.card = self

    self:SetPos(0,0)
    self:SetSize(ScrW(), ScrH())
    self:MakePopup()
    self:SetPopupStayAtBack(true)

    local panel = self
    self.isDataReady = false
    self.loaderStartTime = CurTime()

    self.core = vgui.Create("DPanel", self)
    self.core:SetPos(0, 0)
    self.core:SetSize(ScrW(), ScrH())

    local bgMat = Material("monarch_bg1.png")
    local splashCol = Color(200, 200, 200, 190)

    function self.core:Paint(w, h)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(bgMat)
        surface.DrawTexturedRect(0, 0, w, h)

        local x = w * 0.5
        local y = h * 0.4

        local origW, origH = 324, 46
        local logoScale = 1.1
        local logoW = origW * logoScale
        local logoH = origH * logoScale
        surface.SetFont("MainmenuLarge")
        local titleText = ""

        local font = "MainmenuLarge"
        surface.SetFont(font)
        local tw, th = surface.GetTextSize(titleText)
        local tx = ScrW()/2 - tw/2
        local ty = h/2 - 300

        if not panel.isDataReady then
            local loaderY = y + logoH + 60
            local dotSize = 12
            local spacing = 50
            local t = (CurTime() - panel.loaderStartTime) * 0.8
            local cycle = t % 3

            local triangleHeight = spacing * math.sqrt(3) / 2
            local dots = {
                {x = x - spacing * 0.5, y = loaderY + triangleHeight * 0.33},
                {x = x + spacing * 0.5, y = loaderY + triangleHeight * 0.33},
                {x = x, y = loaderY - triangleHeight * 0.66}
            }

            for i = 1, 3 do
                local phaseOffset = (i - 1)
                local phase = (cycle + phaseOffset) % 3
                local targetIdx = (math.floor(phase) % 3) + 1
                local nextIdx = (targetIdx % 3) + 1
                local lerpAmount = phase - math.floor(phase)

                local fromPos = dots[targetIdx]
                local toPos = dots[nextIdx]
                local finalX = Lerp(lerpAmount, fromPos.x, toPos.x)
                local finalY = Lerp(lerpAmount, fromPos.y, toPos.y)

                local pulseAlpha = 200 + 55 * math.sin(t * 3 + i * 0.5)
                surface.SetDrawColor(255, 255, 255, pulseAlpha)
                draw.NoTexture()
                local segments = 16
                local step = (math.pi * 2) / segments
                for seg = 0, segments - 1 do
                    local angle1 = seg * step
                    local angle2 = (seg + 1) * step
                    local x1 = finalX + math.cos(angle1) * dotSize
                    local y1 = finalY + math.sin(angle1) * dotSize
                    local x2 = finalX + math.cos(angle2) * dotSize
                    local y2 = finalY + math.sin(angle2) * dotSize
                    surface.DrawPoly({
                        {x = finalX, y = finalY},
                        {x = x1, y = y1},
                        {x = x2, y = y2}
                    })
                end
            end

            draw.DrawText("Loading data...","DispLgr",x,loaderY + 80,Color(255,255,255,180),TEXT_ALIGN_CENTER)
        end
    end

    function self.core:OnMousePressed()
        if panel.isDataReady then
            panel:OnKeyCodeReleased()
        end
    end

    Monarch.splash = self
    if Monarch.MenuScenes and Monarch.MenuScenes.Initialize then
        Monarch.MenuScenes:Initialize()
    end
    
end

function PANEL:Think()
    if Monarch.MenuScenes and Monarch.MenuScenes.Update then
        Monarch.MenuScenes:Update(FrameTime())
    end

    if not self.isDataReady then
        local lp = LocalPlayer()
        local elapsed = CurTime() - self.loaderStartTime

        if (IsValid(lp) and lp.MonarchActiveChar and lp.beenInvSetup) or elapsed > 20 then
            self.isDataReady = true

            timer.Simple(0.1, function()
                if IsValid(self) and not self.used then
                    self:OnKeyCodeReleased()
                end
            end)

        end
    end
end

function PANEL:OnKeyCodeReleased()
    if self.used or not self.isDataReady then return end

    self.used = true
    Monarch_IsReady = true

    self.core:AlphaTo(0, 1.5, 0, function()
        if not IsValid(self) then
            return
        end
        vgui.Create("Monarch.MainMenu")
        self:Remove()
    end)

    hook.Run("PostReloadToolsMenu")
end

function PANEL:OnMousePressed()
    if self.isDataReady then
        self:OnKeyCodeReleased()
    end
end

function PANEL:Paint(w,h)
    Derma_DrawBackgroundBlur(self)
end

vgui.Register("MonarchSplash", PANEL, "DPanel")

concommand.Add("monarch_reloadmainmenu", function()
    vgui.Create("Monarch.MainMenu")    
end)

concommand.Add("monarch_reloadsplash", function()
    if IsValid(Monarch.splash) then
        Monarch.splash:Remove()
    end

    if IsValid(Monarch._mainMenu) then
        Monarch._mainMenu:Remove()
    end

    local lp = LocalPlayer()
    if IsValid(lp) then
        lp.beenInvSetup = false
        lp.MonarchActiveChar = nil
    end

    vgui.Create("MonarchSplash")
end)
