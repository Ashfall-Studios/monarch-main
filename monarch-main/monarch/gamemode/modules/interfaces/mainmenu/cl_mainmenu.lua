local PANEL = {}

Monarch = Monarch or {}

if not Monarch.UI or not Monarch.UI.Scale then
    Monarch.LoadFile("modules/client/themes/cl_scale.lua")
end

Monarch.UI = Monarch.UI or {}

local Scale = Monarch.UI.Scale or function(v) return v end
local ScaleFont = Monarch.UI.ScaleFont or function(v) return v end

local function LerpColor(a,b,c)
    return Color(Lerp(a,b.r,c.r),Lerp(a,b.g,c.g),Lerp(a,b.b,c.b),Lerp(a,b.a,c.a))
end

MAIN_MUSIC = "mainmenu_unedited.mp3"

local menuFontCache = {}
local function GetMenuFont(prefix, size, weight)
    size = math.max(8, math.Round(size or 16))
    weight = weight or 600
    local key = prefix .. "_" .. size .. "_" .. weight
    if not menuFontCache[key] then
        local name = "MonarchMenuDynamic_" .. key
        surface.CreateFont(name, {
            font = "Roboto",
            size = size,
            weight = weight,
            antialias = true
        })
        menuFontCache[key] = name
    end

    return menuFontCache[key]
end

local blurDrawPanel = {
    [1] = function(x, y, w, h)

        render.UpdateScreenEffectTexture()

        render.SetScissorRect(x, y, x+w, y+h, true)
        DrawBokehDOF(6, 0, 0)
        render.SetScissorRect(0, 0, 0, 0, false)
    end
}

function BlurRect(x, y, w, h)
    surface.SetDrawColor(20, 20, 20, 25)
    surface.DrawRect(x or 0, y or 0, w or ScrW(), h or ScrH())
    blurDrawPanel[1](x,y,w,h)
end

function PANEL:Init()
    parent = self
    if IsValid(g_SpawnMenu) and g_SpawnMenu:IsVisible() then
        g_SpawnMenu:Close()
    end

    if file.Exists("sound/" .. MAIN_MUSIC, "GAME") then
        LocalPlayer():EmitSound(MAIN_MUSIC)
    end

    if IsValid(Monarch.MainMenu) then
        Monarch.MainMenu:Remove()
    end
    Monarch.MainMenu = self

    if Monarch.MenuScenes and Monarch.MenuScenes.Initialize then
        Monarch.MenuScenes:Initialize()
    end

    if Monarch then
        Monarch.hudEnabled = false
    end

    self:SetPos(0,0)
    self:SetSize(ScrW(), ScrH())
    self:MakePopup()
    self:SetPopupStayAtBack(true)

    self:SetKeyboardInputEnabled(true)
    self:SetMouseInputEnabled(true)

    hook.Add("OnSpawnMenuOpen", "BlockSpawnMenuInMainMenu", function()
        if IsValid(Monarch.MainMenu) then
            return false
        end
    end)

    hook.Add("OnContextMenuOpen", "BlockContextMenuInMainMenu", function()
        if IsValid(Monarch.MainMenu) then
            return false
        end
    end)

    self.mouseX = ScrW() / 2
    self.mouseY = ScrH() / 2
    self.smoothMouseX = ScrW() / 2
    self.smoothMouseY = ScrH() / 2
    self.backgroundOffset = 0
    self.backgroundAngle = 0

    self.titleY = ScrH()/2 - Scale(200)  
    self.titleTargetY = ScrH()/2 - Scale(200)
    self.titleAnimSpeed = 8

    local panel = self

    self._bgPath = nil
    self._bgMat = nil

    self.base = vgui.Create("DPanel", self)
    self.base:SetPos(0, 0)
    self.base:SetSize(ScrW(), ScrH())
    function self.base:Paint(w, h)
    end

    local buttonStartY = ScrH()/2 - Scale(35)
    local buttonWidth = Scale(250)   
    local buttonHeight = Scale(45)   
    local buttonX = ScrW()/2 - buttonWidth/2

    local hasActiveChar = Monarch.HasActiveCharacter
    local baseColor = Color(125, 125, 125, 255)
    local bgColor = Color(30, 30, 30, 255)
    local hoverColor = Color(200, 200, 200, 255)

    local button = vgui.Create("DButton", self.base)
    button:SetPos(buttonX, buttonStartY)
    button:SetSize(buttonWidth, buttonHeight)
    button:SetText("")
    button.hoverLerp = 0
    button.hasActiveChar = hasActiveChar

    function button:Paint(w, h)

        if not self.hasActiveChar then return end

        local col = LerpColor(self.hoverLerp, baseColor, hoverColor)

        surface.SetDrawColor(bgColor)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(0, 0, w, h, 2)

        local btnText = self.hasActiveChar and "Play Game"
        local baseFontSize = self.hasActiveChar and 32 or 36 
        local grow = (w / buttonWidth) / 1.5
        local fontSize = math.Round(baseFontSize * grow)
        local fontName = GetMenuFont("Button", fontSize, 800)

        surface.SetFont(fontName)
        local tw, th = surface.GetTextSize(btnText)
        local tx = w/2 - tw/2
        local ty = h/2 - th/2

        surface.SetTextColor(col)
        surface.SetTextPos(tx, ty)
        surface.DrawText(btnText)

        return false
    end

    function button:OnCursorEntered()
        if not self.hasActiveChar then return end
    end

    function button:DoClick()
        if not self.hasActiveChar then return end
        surface.PlaySound("menu/ui_click.mp3")

        if self.hasActiveChar then

            self:GetParent():GetParent():Remove()
        else

            self:GetParent():GetParent():ShowCharacterSelect()
        end
    end

    function button:Think()
        local targetLerp = self:IsHovered() and 1 or 0
        self.hoverLerp = Lerp(FrameTime() * 8, self.hoverLerp, targetLerp)

        local grow = Lerp(self.hoverLerp, 1, 1.15)
        local drawW = buttonWidth * grow
        local drawH = buttonHeight * grow
        local drawX = ScrW()/2 - drawW/2
        local drawY = buttonStartY + buttonHeight/2 - drawH/2

        self:SetPos(drawX, drawY)
        self:SetSize(drawW, drawH)
    end

    if IsValid(LocalPlayer()) then
        local switchButton = vgui.Create("DButton", self.base)
        switchButton:SetPos(buttonX, buttonStartY + 60) 
        switchButton:SetSize(buttonWidth, buttonHeight)
        switchButton:SetText("")
        switchButton.hoverLerp = 0

        function switchButton:Paint(w, h)
            local col = LerpColor(self.hoverLerp, baseColor, hoverColor)

            surface.SetDrawColor(bgColor)
            surface.DrawRect(0, 0, w, h)

            surface.SetDrawColor(col)
            surface.DrawOutlinedRect(0, 0, w, h, 2)

            local btnText = "Select your Story..."
            local baseFontSize = 28 
            local grow = (w / buttonWidth) / 1.5
            local fontSize = math.Round(baseFontSize * grow)
            local fontName = GetMenuFont("Switch", fontSize, 600)

            surface.SetFont(fontName)
            local tw, th = surface.GetTextSize(btnText)
            local tx = w/2 - tw/2
            local ty = h/2 - th/2

            surface.SetTextColor(col)
            surface.SetTextPos(tx, ty)
            surface.DrawText(btnText)

            return false
        end

        function switchButton:DoClick()
            surface.PlaySound("menu/ui_click.mp3")
            self:GetParent():GetParent():ShowCharacterSelect()
        end

        function switchButton:Think()
            local targetLerp = self:IsHovered() and 1 or 0
            self.hoverLerp = Lerp(FrameTime() * 8, self.hoverLerp, targetLerp)

            local grow = Lerp(self.hoverLerp, 1, 1.1) 
            local drawW = buttonWidth * grow
            local drawH = buttonHeight * grow
            local drawX = ScrW()/2 - drawW/2
            local drawY = (buttonStartY + 60) + buttonHeight/2 - drawH/2

            self:SetPos(drawX, drawY)
            self:SetSize(drawW, drawH)
        end
    end

    timer.Simple(0, function()
        if not IsValid(self) then return end
        if Monarch.MainMenu and Monarch.MainMenu.popup then return end

        hook.Run("DisplayMenuMessages", self)
        hook.Run("OnMenuFirstLoad", self)

        if REFUND_MSG then
            Derma_Message(REFUND_MSG, "Monarch", "Claim Refund")
        end

        if steamworks and steamworks.IsSubscribed then
            if not steamworks.IsSubscribed("3035353556") then
                Derma_Query("You are not subscribed to the content!\nIf you do not subscribe you will experience missing textures and errors.\nAfter subscribing, rejoin the server.",
                    "Monarch",
                    "Subscribe",
                    function()
                        gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3032449280")
                    end,
                    "No thanks")
            end
        end
    end)
end

function PANEL:ShowCharacterSelect()

    self.titleTargetY = 50

    if IsValid(self.base) then
        self.base:SetVisible(false)
    end

    if not IsValid(self.CharacterSelect) then
        self.CharacterSelect = vgui.Create("MonarchCharacterSelect", self)

        Monarch.MainMenu = self
    end

    self.CharacterSelect:SetVisible(true)

    net.Start("Monarch_CharListRequest")
    net.SendToServer()
end

function PANEL:ShowMainMenu()
    if IsValid(self.CharacterSelect) then
        self.CharacterSelect:SetVisible(false)
    end
    if IsValid(self.base) then
        self.base:SetVisible(true)
    end

    self.titleTargetY = ScrH()/2 - 200
end

function PANEL:OnKeyCodePressed(keyCode)
    if keyCode == KEY_Q or keyCode == KEY_C then
        return true
    end

    if keyCode == KEY_ESCAPE then
        self:Remove()
        return true
    end

    return false
end

local fullRemove = PANEL.Remove 
function PANEL:Remove()
    self:SetVisible(false)
    hook.Remove("OnSpawnMenuOpen", "BlockSpawnMenuInMainMenu")
    hook.Remove("OnContextMenuOpen", "BlockContextMenuInMainMenu")

    if MAIN_MUSIC then
        LocalPlayer():StopSound(MAIN_MUSIC)
    end

    if Monarch then
        Monarch.hudEnabled = true
    end
end

function PANEL:Think()
    local frameTime = FrameTime()
    local curTime = CurTime()
    local mx, my = input.GetCursorPos()

    self.mouseX = mx
    self.mouseY = my

    local lerpSpeed = frameTime * 3
    self.smoothMouseX = Lerp(lerpSpeed, self.smoothMouseX, mx)
    self.smoothMouseY = Lerp(lerpSpeed, self.smoothMouseY, my)

    local centerX, centerY = ScrW() / 2, ScrH() / 2
    local offsetX = (self.smoothMouseX - centerX) / centerX
    local offsetY = (self.smoothMouseY - centerY) / centerY

    self.backgroundOffsetX = offsetX * 20
    self.backgroundOffsetY = offsetY * 20

    self.backgroundAngle = math.sin(curTime * 0.5) * 0.5 + (offsetX * 2)

    self.titleY = Lerp(frameTime * self.titleAnimSpeed, self.titleY, self.titleTargetY)

    if Monarch.MenuScenes and Monarch.MenuScenes.Update then
        Monarch.MenuScenes:Update(frameTime)
    end
end

function PANEL:Paint(w, h)
    local bg = Config.MainMenuBackground
    if bg then
        if self._bgPath ~= bg or not self._bgMat then
            self._bgPath = bg
            self._bgMat = Material(bg)
        end
        if self._bgMat then
            surface.SetMaterial(self._bgMat)
        end
        surface.SetDrawColor(255,255,255)
        surface.DrawTexturedRect(0,0,w,h)
    elseif bg == nil then
        surface.SetDrawColor(255,255,255,245)
        surface.SetMaterial(Material("mrp/menu_stuff/bg_grunge.png"))
        surface.DrawTexturedRect(0, 0, w, h)
    else

        surface.SetDrawColor(255,255,255,245)
        surface.SetMaterial(Material("mrp/menu_stuff/bg_grunge.png"))
        surface.DrawTexturedRect(0, 0, w, h)
    end

    self:DrawFloatingParticles(w, h)
    BlurRect(0, 0, w, h)

    local title = Config.SchemaName or "M O N A R C H"
    local font = "MainmenuLarge"
    surface.SetFont(font)
    local tw, th = surface.GetTextSize(title)
    local tx = ScrW()/2 - tw/2
    local ty = self.titleY  

    for ox = -2, 2 do
        for oy = -2, 2 do
            if ox ~= 0 or oy ~= 0 then
                surface.SetTextColor(0, 0, 0, 200)
                surface.SetTextPos(tx + ox, ty + oy)
                surface.DrawText(title)
            end
        end
    end
    surface.SetTextColor(255, 255, 255, 255)
    surface.SetTextPos(tx, ty)
    surface.DrawText(title)
end

function PANEL:DrawFloatingParticles(w, h)
    if not self.particles then
        self.particles = {}
        for i = 1, 20 do
            table.insert(self.particles, {
                x = math.random(0, w),
                y = math.random(0, h),
                baseX = math.random(0, w),
                baseY = math.random(0, h),
                size = math.random(1, 3.5),
                alpha = math.random(30, 50),
                speed = math.random(0.5, 1),
                glowSize = math.random(5, 8)
            })
        end
    end

    local now = CurTime()
    local halfW, halfH = ScrW() / 2, ScrH() / 2
    local mouseInfluenceBaseX = ((self.smoothMouseX or halfW) - halfW) * 0.01
    local mouseInfluenceBaseY = ((self.smoothMouseY or halfH) - halfH) * 0.01

    for i = 1, #self.particles do
        local particle = self.particles[i]
        local mouseInfluenceX = mouseInfluenceBaseX * particle.speed
        local mouseInfluenceY = mouseInfluenceBaseY * particle.speed

        particle.x = particle.baseX + math.sin(now * particle.speed + i) * 50 + mouseInfluenceX
        particle.y = particle.baseY + math.cos(now * particle.speed * 0.7 + i) * 30 + mouseInfluenceY

        if particle.x < -10 then particle.baseX = w + 10 end
        if particle.x > w + 10 then particle.baseX = -10 end
        if particle.y < -10 then particle.baseY = h + 10 end
        if particle.y > h + 10 then particle.baseY = -10 end

        local pulseScale = 1 + math.sin(now * 2 + i) * 0.3
        local currentGlowSize = particle.glowSize * pulseScale

        surface.SetDrawColor(255, 255, 255, particle.alpha * 0.1)
        surface.DrawRect(
            particle.x - currentGlowSize/2, 
            particle.y - currentGlowSize/2, 
            currentGlowSize, 
            currentGlowSize
        )

        local midGlowSize = currentGlowSize * 0.6
        surface.SetDrawColor(255, 165, 0, particle.alpha * 0.3)
        surface.DrawRect(
            particle.x - midGlowSize/2, 
            particle.y - midGlowSize/2, 
            midGlowSize, 
            midGlowSize
        )

        local innerGlowSize = currentGlowSize * 0.3
        surface.SetDrawColor(100, 54, 0, particle.alpha * 0.6)
        surface.DrawRect(
            particle.x - innerGlowSize/2, 
            particle.y - innerGlowSize/2, 
            innerGlowSize, 
            innerGlowSize
        )
        surface.SetDrawColor(255, 255, 255, particle.alpha)
        surface.DrawRect(particle.x, particle.y, particle.size, particle.size)
    end

    if Monarch.MenuScenes and Monarch.MenuScenes.DrawFadeOverlay then
        Monarch.MenuScenes:DrawFadeOverlay()
    end
end

vgui.Register("Monarch.MainMenu", PANEL, "DPanel")
