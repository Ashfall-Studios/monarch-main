local PANEL = {}
local Populate = {}

local blurDrawPanel = {
    [1] = function(x, y, w, h)

        render.UpdateScreenEffectTexture()

        render.SetScissorRect(x, y, x + w, y + h, true)
        if DrawBokehDOF then
            DrawBokehDOF(6, 0, 0)
        end
        render.SetScissorRect(0, 0, 0, 0, false)
    end
}

local function BlurRect(x, y, w, h)
    blurDrawPanel[1](x, y, w, h)
end

function Populate:Init()

    local panelWidth = ScrW() * 0.4  
    local panelHeight = ScrH() * 0.85
    local leftMargin = 20
    local topMargin = ScrH() * 0.1

    self:SetSize(panelWidth, panelHeight)
    self:SetPos(-panelWidth, topMargin) 
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetDraggable(false)
    self:MakePopup()
    self:MoveToFront()

    self.targetX = leftMargin
    self.targetAlpha = 255
    self.currentAlpha = 0
    self.animSpeed = 8
    self.isExiting = false 

    self.Paint = function(self, panelW, panelH)  

        local gradientMaterial = Material("vgui/gradient-l")
        if gradientMaterial and not gradientMaterial:IsError() then
            surface.SetMaterial(gradientMaterial)
            surface.SetDrawColor(0, 0, 0, 200 * (self.currentAlpha / 255))
            surface.DrawTexturedRect(0, 0, panelW, panelH)
        else
            surface.SetDrawColor(0, 0, 0, 200 * (self.currentAlpha / 255))
            surface.DrawRect(0, 0, panelW, panelH)
        end

        surface.SetDrawColor(60, 60, 60, 255 * (self.currentAlpha / 255))
        surface.DrawOutlinedRect(0, 0, panelW, panelH, 2)
    end

    self.Think = function(self)

        local currentX = self:GetPos()
        local newX = Lerp(FrameTime() * self.animSpeed, currentX, self.targetX)
        self:SetPos(newX, topMargin)

        self.currentAlpha = Lerp(FrameTime() * self.animSpeed, self.currentAlpha, self.targetAlpha)
        self:SetAlpha(self.currentAlpha)

        if self.isExiting then
            local screenLeft = -self:GetWide() * 0.5 
            if currentX <= screenLeft then

                self:SetMouseInputEnabled(false)
                self:SetKeyboardInputEnabled(false)
                gui.EnableScreenClicker(false)
            end
        end
    end

    self.scrollPanel = vgui.Create("DScrollPanel", self)
    self.scrollPanel:Dock(FILL)
    self.scrollPanel:DockMargin(10, 10, 10, 10)

    local sbar = self.scrollPanel:GetVBar()
    function sbar:Paint(barW, barH) 
        surface.SetDrawColor(40, 40, 40, 150)
        surface.DrawRect(0, 0, barW, barH)
    end
    function sbar.btnUp:Paint(btnW, btnH) 
        surface.SetDrawColor(60, 60, 60, 255)
        surface.DrawRect(0, 0, btnW, btnH)
    end
    function sbar.btnDown:Paint(btnW, btnH) 
        surface.SetDrawColor(60, 60, 60, 255)
        surface.DrawRect(0, 0, btnW, btnH)
    end
    function sbar.btnGrip:Paint(gripW, gripH) 
        surface.SetDrawColor(80, 80, 80, 255)
        surface.DrawRect(0, 0, gripW, gripH)
    end

    local playerList = player.GetAll()

    table.sort(playerList, function(a, b)
        local aGroup = string.lower(a:GetUserGroup() or "user")
        local bGroup = string.lower(b:GetUserGroup() or "user")

        local aRank = 1
        local bRank = 1
        if Monarch and Monarch.Ranks and Monarch.Ranks.GetOrder then
            aRank = Monarch.Ranks.GetOrder(aGroup)
            bRank = Monarch.Ranks.GetOrder(bGroup)
        else

            local staffRankOrder = {
                ["owner"] = 100,
                ["operator"] = 90,
                ["director"] = 85,
                ["superadmin"] = 80,
                ["senior admin"] = 70,
                ["senioradmin"] = 70,
                ["admin"] = 60,
                ["jr. admin"] = 50,
                ["jradmin"] = 50,
                ["junior admin"] = 50,
                ["moderator"] = 40,
                ["trialmod"] = 30,
                ["trial mod"] = 30,
                ["trial moderator"] = 30,
                ["vip"] = 20,
                ["donator"] = 15,
                ["supporter"] = 10,
                ["user"] = 1,
            }
            aRank = staffRankOrder[aGroup] or 1
            bRank = staffRankOrder[bGroup] or 1
        end

        if aRank ~= bRank then
            return aRank > bRank
        end

        if a:Team() ~= b:Team() then
            return a:Team() > b:Team()
        end

        return string.lower(a:Nick()) < string.lower(b:Nick())
    end)

    for v,k in pairs(playerList) do
        local playerCard = self.scrollPanel:Add("Monarch_ScoreboardCard")
        playerCard:SetPlayer(k)
        playerCard:SetHeight(60)
        playerCard:Dock(TOP)
        playerCard:DockMargin(0, 0, 0, 5)
    end
end

function Populate:StartExitAnimation()
    self.targetX = -self:GetWide()
    self.targetAlpha = 0
    self.isExiting = true
end

vgui.Register("Monarch_Scoreboard.Populate",  Populate, "DFrame")

function PANEL:Init()
    local panelWidth = ScrW() * 0.4
    local headerHeight = 80
    local leftMargin = 20
    local topMargin = 20

    self:SetSize(panelWidth, headerHeight)
    self:SetPos(-panelWidth, topMargin) 
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetDraggable(false)
    self:MakePopup()

    self.targetX = leftMargin
    self.targetAlpha = 255
    self.currentAlpha = 0
    self.animSpeed = 8
    self.isExiting = false 

    self.Paint = function(self, panelW, panelH)  
        local gradientMaterial = Material("vgui/gradient-d")
        if gradientMaterial and not gradientMaterial:IsError() then
            surface.SetMaterial(gradientMaterial)
            surface.SetDrawColor(0, 0, 0, 220 * (self.currentAlpha / 255))
            surface.DrawTexturedRect(0, 0, panelW, panelH)
        else
            surface.SetDrawColor(0, 0, 0, 220 * (self.currentAlpha / 255))
            surface.DrawRect(0, 0, panelW, panelH)
        end

        local gradientMaterialR = Material("vgui/gradient-r")
        if gradientMaterialR and not gradientMaterialR:IsError() then
            surface.SetMaterial(gradientMaterialR)
            surface.SetDrawColor(0, 0, 0, 100 * (self.currentAlpha / 255))
            surface.DrawTexturedRect(0, 0, panelW, panelH)
        end

        surface.SetFont("MainmenuMedium")
        local titleText = "M O N A R C H"
        local titleW, titleH = surface.GetTextSize(titleText)
        surface.SetTextColor(255, 255, 255, 255 * (self.currentAlpha / 255))
        surface.SetTextPos(15, panelH/2 - titleH/2)
        surface.DrawText(titleText)

        surface.SetFont("DermaDefault")
        local subtitleText = "Player List"
        local subtitleW, subtitleH = surface.GetTextSize(subtitleText)
        surface.SetTextColor(200, 200, 200, 200 * (self.currentAlpha / 255))
        surface.SetTextPos(15, panelH/2 + titleH/2 + 5)
        surface.DrawText(subtitleText)

        local playerCount = #player.GetAll()
        local maxPlayers = game.MaxPlayers()
        local playerCountText = playerCount .. "/" .. maxPlayers
        surface.SetFont("MainmenuMedium")
        local countW, countH = surface.GetTextSize(playerCountText)
        surface.SetTextColor(255,255,255, 255 * (self.currentAlpha / 255))
        surface.SetTextPos(panelW - countW - 15, panelH/2 - countH/2)
        surface.DrawText(playerCountText)

        surface.SetDrawColor(60, 60, 60, 255 * (self.currentAlpha / 255))
        surface.DrawOutlinedRect(0, 0, panelW, panelH, 2)

        surface.SetDrawColor(83, 143, 239, 255 * (self.currentAlpha / 255))
        surface.DrawRect(0, panelH-3, panelW, 3)
    end

    self.Think = function(self)

        local currentX = self:GetPos()
        local newX = Lerp(FrameTime() * self.animSpeed, currentX, self.targetX)
        self:SetPos(newX, topMargin)

        self.currentAlpha = Lerp(FrameTime() * self.animSpeed, self.currentAlpha, self.targetAlpha)
        self:SetAlpha(self.currentAlpha)

        if self.isExiting then
            local screenLeft = -self:GetWide() * 0.5 
            if currentX <= screenLeft then

                self:SetMouseInputEnabled(false)
                self:SetKeyboardInputEnabled(false)
                gui.EnableScreenClicker(false)
            end
        end
    end
end

function PANEL:StartExitAnimation()
    self.targetX = -self:GetWide()
    self.targetAlpha = 0
    self.isExiting = true
end

vgui.Register("Monarch_Scoreboard", PANEL, "DFrame")

function GM:ScoreboardShow()
    Score = vgui.Create("Monarch_Scoreboard")
    Score:Show()
    Score:MakePopup()
    Score:SetKeyboardInputEnabled(false)

    Scr = vgui.Create("Monarch_Scoreboard.Populate")
    Scr:Show()
    Scr:MakePopup()
    Scr:SetKeyboardInputEnabled(false)

    hook.Add("HUDPaint", "drawBlur", function()
        if IsValid(Score) and IsValid(Scr) then

            if Score.currentAlpha and Score.currentAlpha > 10 then
                local headerX, headerY = Score:GetPos()
                local headerW, headerH = Score:GetSize()
                BlurRect(headerX, headerY, headerW, headerH)
            end

            if Scr.currentAlpha and Scr.currentAlpha > 10 then
                local mainX, mainY = Scr:GetPos()
                local mainW, mainH = Scr:GetSize()
                BlurRect(mainX, mainY, mainW, mainH)
            end
        end
    end)
end

function GM:ScoreboardHide()

    gui.EnableScreenClicker(false)

    if IsValid(Scr) then
        Scr:SetMouseInputEnabled(false)
        Scr:SetKeyboardInputEnabled(false)
        Scr:StartExitAnimation()

        timer.Simple(0.5, function()
            if IsValid(Scr) then
                Scr:Close()
            end
        end)
    end

    if IsValid(Score) then
        Score:SetMouseInputEnabled(false)
        Score:SetKeyboardInputEnabled(false)
        Score:StartExitAnimation()

        timer.Simple(0.5, function()
            if IsValid(Score) then
                Score:Close()
            end
        end)
    end

    timer.Simple(0.6, function()
        hook.Remove("HUDPaint", "drawBlur")
    end)
end
