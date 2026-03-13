include("shared.lua")

local function fmtMoney(n)
    if Monarch and Monarch.FormatMoney then return Monarch.FormatMoney(n) end
    n = tonumber(n) or 0
    return "$"..tostring(n)
end

local function openATM(ent, wallet, bank)
    if IsValid(ent._atmFrame) then ent._atmFrame:Remove() end

    local f = vgui.Create("DFrame")
    ent._atmFrame = f
    f:SetSize(360, 280)
    f:Center()
    f:SetTitle("")
    f:ShowCloseButton(false)
    f:MakePopup()
    f:SetAlpha(0)
    f:AlphaTo(255, 0.15, 0)
    f.topBarH = 28
    f.Paint = function(s, w, h)
        surface.SetDrawColor(20, 20, 20, 240)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(50, 50, 50, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    if Monarch and Monarch.Theme and Monarch.Theme.AttachSkin then Monarch.Theme.AttachSkin(f) end

    local closeBtn = vgui.Create("DButton", f)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPos(f:GetWide() - 55 - closeBtn:GetWide(), math.floor((f.topBarH - 20) * 0.5))
    closeBtn:SetText("CLOSE ✕")
    closeBtn:SetFont("InvSmall")
    closeBtn:SetTextColor(color_white)
    closeBtn:SizeToContentsX()
    closeBtn.Paint = function(s, w, h)
        local bg = s:IsHovered() and Color(120, 50, 50) or Color(90, 40, 40)
        surface.SetDrawColor(bg)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(140, 60, 60)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    closeBtn.DoClick = function()
        if not IsValid(f) then return end
        f:AlphaTo(0, 0.15, 0, function()
            if IsValid(f) then f:Remove() end
        end)
    end

    local lblW = vgui.Create("DLabel", f)
    lblW:SetText("Wallet: " .. fmtMoney(wallet))
    lblW:SetFont("InvMed")
    lblW:SetTextColor(color_white)
    lblW:Dock(TOP)
    lblW:DockMargin(12, 12, 12, 4)
    lblW:SizeToContents()

    local lblB = vgui.Create("DLabel", f)
    lblB:SetText("Bank:   " .. fmtMoney(bank))
    lblB:SetFont("InvMed")
    lblB:SetTextColor(color_white)
    lblB:Dock(TOP)
    lblB:DockMargin(12, 0, 12, 16)
    lblB:SizeToContents()

    local amtEntry = vgui.Create("DTextEntry", f)
    amtEntry:SetPlaceholderText("Amount")
    amtEntry:SetFont("InvSmall")
    amtEntry:SetTextColor(color_white)
    amtEntry:Dock(TOP)
    amtEntry:DockMargin(12, 0, 12, 12)
    amtEntry:SetTall(32)
    amtEntry.Paint = function(s, w, h)
        surface.SetDrawColor(35, 35, 35, 255)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(90, 90, 90, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        s:DrawTextEntryText(s:GetTextColor(), s:GetHighlightColor(), s:GetCursorColor())
    end

    local row = vgui.Create("DPanel", f)
    row:Dock(TOP)
    row:SetTall(44)
    row:DockMargin(12, 0, 12, 12)
    row.Paint = nil

    local btnDep = vgui.Create("DButton", row)
    btnDep:SetText("DEPOSIT")
    btnDep:SetFont("InvMed")
    btnDep:Dock(LEFT)
    btnDep:SetWide(158)
    btnDep:DockMargin(0, 0, 8, 0)
    btnDep.Paint = function(s, w, h)
        s:SetCursor("hand")
        local hover = s:IsHovered()
        local bg = hover and Color(60, 60, 60, 255) or Color(35, 35, 35, 255)
        draw.RoundedBox(4, 0, 0, w, h, bg)
        surface.SetDrawColor(90, 90, 90, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        surface.SetDrawColor(60, 60, 60, 180)
        surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)
        draw.SimpleText(s:GetText(), s:GetFont(), w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return true
    end

    local btnWit = vgui.Create("DButton", row)
    btnWit:SetText("WITHDRAW")
    btnWit:SetFont("InvMed")
    btnWit:Dock(FILL)
    btnWit.Paint = function(s, w, h)
        s:SetCursor("hand")
        local hover = s:IsHovered()
        local bg = hover and Color(60, 60, 60, 255) or Color(35, 35, 35, 255)
        draw.RoundedBox(4, 0, 0, w, h, bg)
        surface.SetDrawColor(90, 90, 90, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        surface.SetDrawColor(60, 60, 60, 180)
        surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)
        draw.SimpleText(s:GetText(), s:GetFont(), w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return true
    end

    local btnCash = vgui.Create("DButton", f)
    btnCash:SetText("CASH CHECK")
    btnCash:SetFont("InvMed")
    btnCash:Dock(TOP)
    btnCash:DockMargin(12, 12, 12, 0)
    btnCash:SetTall(32)
    btnCash.Paint = function(s, w, h)
        s:SetCursor("hand")
        local hover = s:IsHovered()
        local bg = hover and Color(50, 80, 50, 255) or Color(35, 60, 35, 255)
        draw.RoundedBox(4, 0, 0, w, h, bg)
        surface.SetDrawColor(80, 120, 80, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        surface.SetDrawColor(60, 90, 60, 180)
        surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)
        draw.SimpleText(s:GetText(), s:GetFont(), w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return true
    end

    local function getAmt()
        local t = amtEntry:GetText() or ""
        local n = tonumber(t) or 0
        n = math.floor(math.max(0, n))
        return n
    end

    btnDep.DoClick = function()
        local amt = getAmt()
        if amt <= 0 then return end
        net.Start("Monarch_ATM_Deposit")
            net.WriteUInt(amt, 32)
        net.SendToServer()
    end

    btnWit.DoClick = function()
        local amt = getAmt()
        if amt <= 0 then return end
        net.Start("Monarch_ATM_Withdraw")
            net.WriteUInt(amt, 32)
        net.SendToServer()
    end

    btnCash.DoClick = function()
        net.Start("Monarch_ATM_CashCheck")
        net.SendToServer()
    end

    function f:UpdateBalances(w, b)
        lblW:SetText("Wallet: " .. fmtMoney(w))
        lblB:SetText("Bank:   " .. fmtMoney(b))

    end

    f.OnRemove = function()
        ent._atmFrame = nil
    end
end

net.Receive("Monarch_ATM_Open", function()
    local ent = net.ReadEntity()
    local wallet = net.ReadInt(32)
    local bank = net.ReadInt(32)
    if not IsValid(ent) then return end
    openATM(ent, wallet, bank)
end)

net.Receive("Monarch_ATM_Update", function()
    local w = net.ReadInt(32)
    local b = net.ReadInt(32)

    for _, ent in ipairs(ents.FindByClass("monarch_atm")) do
        if IsValid(ent._atmFrame) then
            ent._atmFrame:UpdateBalances(w, b)
            break
        end
    end
end)
