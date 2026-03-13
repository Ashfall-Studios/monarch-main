return function(PANEL)
    if not CLIENT then return end

    local Scale = (Monarch and Monarch.UI and Monarch.UI.Scale) or function(v) return v end

function PANEL:CreateCommunityPanel(parent)
    local base = vgui.Create("DPanel", self)
    base:SetSize(Scale(600), Scale(680))
    base:SetPos(Scale(1200), Scale(40))
    base.Paint = function(s, pw, ph)
    end

    local w, h = base:GetSize()
    local col = vgui.Create("DPanel", base)
    col:SetSize(w, h)
    col:SetPos(0, 0)
    col.Paint = function() end

    local titleShadow = vgui.Create("DLabel", col)
    titleShadow:SetFont("Inventory_Title")
    titleShadow:SetColor(Color(0, 0, 0, 250))
    titleShadow:SetText("COMMUNITY")
    titleShadow:SizeToContents()

    local title = vgui.Create("DLabel", col)
    title:SetFont("Inventory_Title")
    title:SetColor(Color(185, 185, 185))
    title:SetText("COMMUNITY")
    title:SizeToContents()

    local iconSize = Scale(55)
    local iconSpacing = Scale(10)

    local iconShadow = vgui.Create("DImage", col)
    iconShadow:SetImage("mrp/icons/unknown-user-symbol.png")
    iconShadow:SetSize(iconSize, iconSize)
    iconShadow:SetImageColor(Color(0, 0, 0, 150))

    local icon = vgui.Create("DImage", col)
    icon:SetImage("mrp/icons/unknown-user-symbol.png")
    icon:SetSize(iconSize, iconSize)
    icon:SetImageColor(Color(185, 185, 185))

    local totalWidth = iconSize + iconSpacing + title:GetWide()
    local centerX = (col:GetWide() - totalWidth) * 0.5
    iconShadow:SetPos(centerX + 2, Scale(20) + 2)
    titleShadow:SetPos(centerX + iconSize + iconSpacing + 2, Scale(20) + 2)
    icon:SetPos(centerX, Scale(20) + (title:GetTall() - iconSize) * 0.5)
    title:SetPos(centerX + iconSize + iconSpacing, Scale(20))

    local list = vgui.Create("DPanel", col)
    list:SetPos(10, Scale(80))
    list:SetSize(col:GetWide() - 20, col:GetTall() - Scale(90))
    list.Paint = function(s, w2, h2)
    end

    local forumsURL  = (Config and Config.Forums)   or "https://google.com"
    local discordURL = (Config and Config.Discord)  or "https://discord.com/"
    local donateURL  = (Config and Config.Donations) or "https://www.paypal.com/donate"

    local function addLinkButton(parentPanel, label, url)
        local btn = vgui.Create("DButton", parentPanel)
        btn:Dock(TOP)
        btn:DockMargin(0, 0, 0, 8)
        btn:SetTall(Scale(40))
        btn:SetText(label)
        btn:SetFont("InvMed")
        btn:SetTextColor(Color(240,240,240))
        btn.Paint = function(s, w3, h3)
            local bg = s:IsHovered() and Color(56,56,60) or Color(40,40,44)
            surface.SetDrawColor(bg)
            surface.DrawRect(0,0,w3,h3)
            surface.SetDrawColor(Color(130,130,135))
            surface.DrawOutlinedRect(0,0,w3,h3,1)
        end
        btn.DoClick = function()
            gui.OpenURL(url)
        end
        return btn
    end

    addLinkButton(list, "Forums",   forumsURL)
    addLinkButton(list, "Discord",  discordURL)
    addLinkButton(list, "Donations", donateURL)

    return base
end

end

