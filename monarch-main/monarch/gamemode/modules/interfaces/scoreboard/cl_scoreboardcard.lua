local PANEL = {}

function PANEL:Init()
    self.Colour = Color(60,255,105,150)
    self.Name = "Connecting..."
    self.Ping = 0
    self:SetCursor("hand")
    self:SetTooltip("Right click to copy SteamID.")
end

function PANEL:SetPlayer(player)
    self.Colour = Config.GamemodeColor
    self.Name = player:GetPData("RPName") or player:GetNWString("RPName") or player:Nick()
    self.Player = player
    self.Badges =  {}
end

local function CapitalizeFirst(str)
    if not str or str == "" then return str end
    return string.upper(string.sub(str, 1, 1)) .. string.lower(string.sub(str, 2))
end

local function GetUsergroupColor(usergroup)

    if Monarch and Monarch.Ranks and Monarch.Ranks.GetColor then
        return Monarch.Ranks.GetColor(usergroup)
    end

    local colors = {
        ["owner"] = Color(255, 0, 0, 255),
        ["operator"] = Color(255, 10, 10, 255),
        ["superadmin"] = Color(255, 50, 50, 255),
        ["senior admin"] = Color(255, 165, 0, 255),
        ["senioradmin"] = Color(255, 165, 0, 255),
        ["admin"] = Color(0, 255, 200, 255),
        ["junior admin"] = Color(100, 150, 255, 255),
        ["trial admin"] = Color(150, 255, 150, 255),
        ["moderator"] = Color(150, 255, 150, 255),
        ["Donator"] = Color(255, 255, 100, 255),
        ["user"] = Color(255, 255, 255, 255),
        ["player"] = Color(255, 255, 255, 255),
    }

    local lowerGroup = string.lower(usergroup or "user")
    return colors[lowerGroup] or Color(255, 255, 255, 255) 
end

local function DrawGlowingText(text, font, x, y, color, glowIntensity)
end

local gradient = Material("vgui/gradient-l")
local gradientr = Material("vgui/gradient-r")
local outlineCol = Color(190,190,190,240)
local darkCol = Color(0,0,0,200)

function PANEL:Paint(w,h)
    if not IsValid(self.Player) then return end

    surface.SetDrawColor(outlineCol)
    surface.DrawOutlinedRect(0,0,w, h)

    surface.SetDrawColor(Color(0,0,0,200))
    surface.SetMaterial(gradient)
    surface.DrawRect(1,1,w-1,h-2)

    local Avatar = vgui.Create( "AvatarImage", self )
    Avatar:SetSize( 40, 40 )
    Avatar:SetPos( w/45, 9.8 )
    Avatar:SetPlayer( self.Player, 64 ) 

    local usergroup = self.Player:GetUserGroup()
    local capitalizedUsergroup = CapitalizeFirst(usergroup)
    local nameColor = GetUsergroupColor(usergroup)

    surface.SetFont("ThickUI-Element23")
    surface.SetTextColor(color_white)
    surface.SetTextPos(w/1.12,10)
    surface.DrawText("Ping: "..self.Player:Ping())

    surface.SetFont("ThickUI-Element23")
    local playerName = self.Player:Nick()

    surface.SetTextColor(nameColor)
    surface.SetTextPos(w/11.5, 5)
    surface.DrawText(playerName)

    surface.SetFont("ThickUI-Element23Shadow")
    local playerName = self.Player:Nick()

    surface.SetTextColor(Color(nameColor.r, nameColor.g, nameColor.b, 70))
    surface.SetTextPos(w/11.5, 5)
    surface.DrawText(playerName)

    surface.SetFont("ThickUI-Element13")
    surface.SetTextColor(Color(200, 200, 200, 255))
    surface.SetTextPos(w/11.5, 25)
    surface.DrawText(capitalizedUsergroup)
end

function PANEL:OnMousePressed(key)
    if not IsValid(self.Player) then
        return false
    end

    if key == MOUSE_RIGHT then
        Notify("You have copied "..self.Player:Nick().."'s Steam ID.", 5)
        SetClipboardText(self.Player:SteamID())
    end
end

vgui.Register("Monarch_ScoreboardCard", PANEL, "DPanel")

