local PANEL = {}

function PANEL:Init()
    self.Colour = Color(83, 143, 239, 255)
    self.Name = "Connecting..."
    self.Ping = 0
    self:SetCursor("hand")
    self:SetTooltip("Right click to copy SteamID.")

    self.avatar = vgui.Create("AvatarImage", self)
    self.avatar:SetSize(34, 34)
    self.avatar:SetPos(6, 10)
end

function PANEL:SetPlayer(player)
    if Config and Config.GamemodeColor then
        self.Colour = Color(Config.GamemodeColor.r, Config.GamemodeColor.g, Config.GamemodeColor.b, 255)
    end

    self.Name = player:GetPData("RPName") or player:GetNWString("RPName") or player:Nick()
    self.Player = player
    self.Badges = {}

    if IsValid(self.avatar) then
        self.avatar:SetPlayer(player, 64)
    end
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

local function DrawGlowingText(text, font, x, y, color, glowIntensity, alignX, alignY)
    glowIntensity = glowIntensity or 1
    alignX = alignX or TEXT_ALIGN_LEFT
    alignY = alignY or TEXT_ALIGN_TOP

    local glowAlpha = math.Clamp(95 * glowIntensity, 0, 255)
    local glowColor = Color(color.r, color.g, color.b, glowAlpha)
    local glowFont = font .. "Glow"

    draw.SimpleText(text, glowFont, x, y, glowColor, alignX, alignY)
    draw.SimpleText(text, font, x, y, color, alignX, alignY)
end

surface.CreateFont("MonarchScoreboardRowName", {
    font = "DIN Pro Medium",
    size = 21,
    weight = 500,
    antialias = true,
    extended = true,
})

surface.CreateFont("MonarchScoreboardRowNameGlow", {
    font = "DIN Pro Medium",
    size = 21,
    weight = 500,
    blursize = 6,
    antialias = true,
    extended = true,
})

surface.CreateFont("MonarchScoreboardRowRank", {
    font = "DIN Pro Medium",
    size = 21,
    weight = 500,
    antialias = true,
    extended = true,
})

surface.CreateFont("MonarchScoreboardRowRankGlow", {
    font = "DIN Pro Medium",
    size = 21,
    weight = 500,
    blursize = 6,
    antialias = true,
    extended = true,
})

surface.CreateFont("MonarchScoreboardRowPing", {
    font = "DIN Pro Medium",
    size = 21,
    weight = 500,
    antialias = true,
    extended = true,
})

surface.CreateFont("MonarchScoreboardRowPingGlow", {
    font = "DIN Pro Medium",
    size = 21,
    weight = 500,
    blursize = 6,
    antialias = true,
    extended = true,
})

function PANEL:Paint(w,h)
    if not IsValid(self.Player) then return end

    if self:IsHovered() then
        surface.SetDrawColor(255, 255, 255, 8)
        surface.DrawRect(0, 0, w, h)
    end

    local usergroup = self.Player:GetUserGroup()
    local capitalizedUsergroup = CapitalizeFirst(usergroup)
    local nameColor = GetUsergroupColor(usergroup)
    local name = self.Player:Nick()

    draw.SimpleText(name, "MonarchScoreboardRowName", 46, 15, Color(nameColor.r, nameColor.g, nameColor.b, 245), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    DrawGlowingText(capitalizedUsergroup, "MonarchScoreboardRowRank", w * 0.41, 15, Color(nameColor.r, nameColor.g, nameColor.b, 245), 1.05, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(tostring(self.Player:Ping()), "MonarchScoreboardRowPing", w - 6, 15, Color(178, 178, 178), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
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

