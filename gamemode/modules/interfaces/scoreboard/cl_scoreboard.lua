local PANEL = {}

local STAFF_RANK_ORDER = {
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

local BANNER_MATERIAL = Material("materials/mrp/ui/sb_bg.png")

local function NormalizeUrl(url)
    local parsed = string.Trim(tostring(url or ""))
    if parsed == "" then
        parsed = "google.com"
    end

    if not string.match(parsed, "^https?://") then
        parsed = "https://" .. parsed
    end

    return parsed
end

local function OpenConfiguredUrl(configKey)
    local configured = (Config and Config[configKey]) or "google.com"
    gui.OpenURL(NormalizeUrl(configured))
end

surface.CreateFont("MonarchScoreboardTitleDIN", {
    font = "DIN Pro Medium",
    size = 22,
    weight = 600,
    antialias = true,
    extended = true,
})

surface.CreateFont("MonarchScoreboardCountSmall", {
    font = "DIN Pro Medium",
    size = 20,
    weight = 500,
    antialias = true,
    extended = true,
})

surface.CreateFont("MonarchScoreboardNav", {
    font = "DIN Pro Medium",
    size = 20,
    weight = 500,
    antialias = true,
    extended = true,
})

surface.CreateFont("MonarchScoreboardSmall", {
    font = "DIN Pro Medium",
    size = 17,
    weight = 500,
    antialias = true,
    extended = true,
})

local function GetAccentColor(alpha)
    alpha = alpha or 255
    if Config and Config.GamemodeColor then
        return Color(Config.GamemodeColor.r, Config.GamemodeColor.g, Config.GamemodeColor.b, alpha)
    end

    return Color(83, 143, 239, alpha)
end

local function GetRankOrder(usergroup)
    local normalized = string.lower(usergroup or "user")
    if Monarch and Monarch.Ranks and Monarch.Ranks.GetOrder then
        return Monarch.Ranks.GetOrder(normalized) or 1
    end

    return STAFF_RANK_ORDER[normalized] or 1
end

local function SortPlayers(list)
    table.sort(list, function(a, b)
        local aRank = GetRankOrder(a:GetUserGroup())
        local bRank = GetRankOrder(b:GetUserGroup())

        if aRank ~= bRank then
            return aRank > bRank
        end

        if a:Team() ~= b:Team() then
            return a:Team() > b:Team()
        end

        return string.lower(a:Nick()) < string.lower(b:Nick())
    end)
end

function PANEL:Init()
    local panelWidth = ScrW() * 0.45
    local panelHeight = ScrH()
    local panelY = 0

    self:SetSize(panelWidth, panelHeight)
    self:SetPos(-panelWidth, panelY)
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetDraggable(false)
    self:SetSizable(false)
    self:SetMouseInputEnabled(true)

    self.targetX = -30
    self.targetY = panelY
    self.currentAlpha = 0
    self.targetAlpha = 255
    self.animSpeed = 10
    self.closing = false
    self.nextRefresh = 0
    self.playerCards = {}
    self.playerOrder = {}

    self.rulesButton = vgui.Create("DButton", self)
    self.rulesButton:SetText("")
    self.rulesButton.DoClick = function()
        OpenConfiguredUrl("ruleslink")
    end
    self.rulesButton.Paint = function(btn, w, h)
        local alphaMul = self.currentAlpha / 255
        local col = btn:IsHovered() and Color(230, 230, 230, 255 * alphaMul) or Color(175, 175, 175, 215 * alphaMul)
        draw.SimpleText("Game Rules", "MonarchScoreboardSmall", 0, 0, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    self.discordButton = vgui.Create("DButton", self)
    self.discordButton:SetText("")
    self.discordButton.DoClick = function()
        OpenConfiguredUrl("discordlink")
    end
    self.discordButton.Paint = function(btn, w, h)
        local alphaMul = self.currentAlpha / 255
        local col = btn:IsHovered() and Color(230, 230, 230, 255 * alphaMul) or Color(175, 175, 175, 215 * alphaMul)
        draw.SimpleText("Discord", "MonarchScoreboardSmall", 0, 0, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    self.subscribeButton = vgui.Create("DButton", self)
    self.subscribeButton:SetText("")
    self.subscribeButton.DoClick = function()
        OpenConfiguredUrl("donatelink")
    end
    self.subscribeButton.Paint = function(btn, w, h)
        local alphaMul = self.currentAlpha / 255
        local col = btn:IsHovered() and Color(230, 230, 230, 255 * alphaMul) or Color(175, 175, 175, 215 * alphaMul)
        draw.SimpleText("Subscribe", "MonarchScoreboardSmall", 0, 0, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    self.scrollPanel = vgui.Create("DScrollPanel", self)
    self.scrollPanel:Dock(FILL)
    self.scrollPanel:DockMargin(10, 34, 200, 6)

    local sbar = self.scrollPanel:GetVBar()
    function sbar:Paint(barW, barH)
        surface.SetDrawColor(10, 10, 10, 160)
        surface.DrawRect(0, 0, barW, barH)
    end

    function sbar.btnUp:Paint(btnW, btnH)
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawRect(0, 0, btnW, btnH)
    end

    function sbar.btnDown:Paint(btnW, btnH)
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawRect(0, 0, btnW, btnH)
    end

    function sbar.btnGrip:Paint(gripW, gripH)
        surface.SetDrawColor(110, 110, 110, 210)
        surface.DrawRect(0, 0, gripW, gripH)
    end

    self:RebuildPlayerCards(true)
end

function PANEL:PerformLayout(panelW, panelH)
    local navY = 7
    local textH = draw.GetFontHeight("MonarchScoreboardSmall")

    self.rulesButton:SetPos(panelW * 0.34, navY)
    self.rulesButton:SetSize(110, textH + 2)

    self.discordButton:SetPos(panelW * 0.47, navY)
    self.discordButton:SetSize(90, textH + 2)

    self.subscribeButton:SetPos(panelW * 0.57, navY)
    self.subscribeButton:SetSize(95, textH + 2)
end

function PANEL:RebuildPlayerCards(force)
    local players = player.GetAll()
    SortPlayers(players)

    local signatureParts = {}
    for i = 1, #players do
        local ply = players[i]
        signatureParts[#signatureParts + 1] = tostring(ply:EntIndex()) .. ":" .. tostring(ply:Team()) .. ":" .. string.lower(ply:GetUserGroup() or "user")
    end

    local signature = table.concat(signatureParts, "|")
    if not force and signature == self.lastSignature then
        return
    end

    self.lastSignature = signature

    local seen = {}
    for i = 1, #players do
        local ply = players[i]
        seen[ply] = true

        local card = self.playerCards[ply]
        if not IsValid(card) then
            card = self.scrollPanel:Add("Monarch_ScoreboardCard")
            card:SetHeight(54)
            card:Dock(TOP)
            card:DockMargin(0, 0, 50, 1)
            self.playerCards[ply] = card
        end

        card:SetPlayer(ply)
        card:SetZPos(i)
    end

    for ply, card in pairs(self.playerCards) do
        if (not seen[ply]) or (not IsValid(ply)) then
            if IsValid(card) then
                card:Remove()
            end
            self.playerCards[ply] = nil
        end
    end
end

function PANEL:Think()
    local x, y = self:GetPos()
    local newX = Lerp(FrameTime() * self.animSpeed, x, self.targetX)
    self:SetPos(newX, self.targetY)

    self.currentAlpha = Lerp(FrameTime() * self.animSpeed, self.currentAlpha, self.targetAlpha)
    self:SetAlpha(self.currentAlpha)

    if self.closing and self.currentAlpha <= 2 then
        self:Remove()
        return
    end

    if CurTime() >= self.nextRefresh then
        self.nextRefresh = CurTime() + 1
        self:RebuildPlayerCards(false)
    end
end

function PANEL:StartClose()
    self.closing = true
    self.targetX = -self:GetWide() - 24
    self.targetAlpha = 0
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)
end

function PANEL:OnRemove()
    Monarch = Monarch or {}
    Monarch.ScoreboardOpen = false
    gui.EnableScreenClicker(false)
end

function PANEL:Paint(panelW, panelH)
    local alphaMul = self.currentAlpha / 100

    if BANNER_MATERIAL and not BANNER_MATERIAL:IsError() then
        surface.SetMaterial(BANNER_MATERIAL)
        surface.SetDrawColor(180,180,180, 100 * alphaMul)
        surface.DrawTexturedRect(0, 0, panelW, panelH)
    end

    local online = #player.GetAll()
    local maxPlayers = game.MaxPlayers()

    local navY = 7
    draw.SimpleText("MONARCH", "MonarchScoreboardTitleDIN", 8, 4, Color(232, 232, 232, 255 * alphaMul), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Players: " .. online .. "/" .. maxPlayers, "MonarchScoreboardSmall", panelW * 0.18, navY, Color(210, 210, 210, 230 * alphaMul), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

vgui.Register("Monarch_Scoreboard", PANEL, "DFrame")

local function EnsureScoreboard()
    if IsValid(Score) then
        return Score
    end

    Score = vgui.Create("Monarch_Scoreboard")
    return Score
end

function GM:ScoreboardShow()
    local board = EnsureScoreboard()
    if not IsValid(board) then
        return
    end

    board.closing = false
    board.targetX = 0
    board.targetAlpha = 255
    board:SetVisible(true)
    board:SetMouseInputEnabled(true)
    board:SetKeyboardInputEnabled(false)
    board:RebuildPlayerCards(true)
    board:MakePopup()
    board:SetKeyboardInputEnabled(false)
    gui.EnableScreenClicker(true)

    Monarch = Monarch or {}
    Monarch.ScoreboardOpen = true

    return true
end

function GM:ScoreboardHide()
    gui.EnableScreenClicker(false)

    if IsValid(Score) then
        Score:StartClose()
    end

    Monarch = Monarch or {}
    Monarch.ScoreboardOpen = false

    return true
end
