Monarch_Tickets_Global = Monarch_Tickets_Global or {}
Monarch_Tickets_Global.notifications = Monarch_Tickets_Global.notifications or {}
Monarch_Tickets_Global.maxNotifs = Monarch_Tickets_Global.maxNotifs or 100

local function Tickets_AddGlobalAndUI(kind, t)

    local entry = {
        kind = kind,
        id = t and t.id,
        reporter = t and (t.reporterName or t.reporter or ""),
        status = t and t.status,
        time = CurTime()
    }
    table.insert(Monarch_Tickets_Global.notifications, entry)

    local extra = #Monarch_Tickets_Global.notifications - (Monarch_Tickets_Global.maxNotifs or 100)
    if extra > 0 then
        for i = 1, extra do table.remove(Monarch_Tickets_Global.notifications, 1) end
    end

    if IsValid(Monarch_Tickets_Frame) then
        local v = Monarch_Tickets_Frame._views and Monarch_Tickets_Frame._views.tickets
        if v and v.AddNotification then v.AddNotification(kind, t or { id = entry.id, reporterName = entry.reporter }) end
    end
end

local function IsStaff()
    local g = string.lower(LocalPlayer():GetUserGroup() or "")
    return g == "admin" or g == "superadmin" or g == "operator" or g == "moderator" or g == "owner" or g == "director"
end

Monarch_Tickets_Notifications = Monarch_Tickets_Notifications or {}

local function CreateTicketNotification(ticketData)
    local notif = vgui.Create("DPanel")
    notif:SetSize(350, 80)
    notif:SetPos(20, 20)
    notif.alpha = 0
    notif.targetAlpha = 255
    notif.lifeTime = CurTime() + 5
    notif.created = CurTime()

    notif.Paint = function(self, w, h)

        if CurTime() < self.lifeTime - 0.5 then
            self.alpha = Lerp(FrameTime() * 8, self.alpha, self.targetAlpha)
        else
            self.targetAlpha = 0
            self.alpha = Lerp(FrameTime() * 12, self.alpha, 0)
        end

        surface.SetDrawColor(30, 30, 32, self.alpha)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(200, 60, 60, self.alpha)
        surface.DrawRect(0, 0, 4, h)

        surface.SetDrawColor(70, 70, 72, self.alpha * 0.8)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        draw.SimpleText("New Ticket", "DermaDefaultBold", 15, 8, Color(220, 80, 80, self.alpha), TEXT_ALIGN_LEFT)

        local reporter = ticketData.reporterName or "Unknown"
        local id = ticketData.id or "?"
        draw.SimpleText("Ticket #"..id.." from "..reporter, "DermaDefault", 15, 28, Color(200, 200, 200, self.alpha), TEXT_ALIGN_LEFT)

        local desc = ticketData.description or ""
        if #desc > 45 then desc = string.sub(desc, 1, 45).."..." end
        draw.SimpleText(desc, "DermaDefault", 15, 48, Color(160, 160, 160, self.alpha), TEXT_ALIGN_LEFT)
    end

    notif.Think = function(self)
        if CurTime() > self.lifeTime then
            self:Remove()
            table.RemoveByValue(Monarch_Tickets_Notifications, self)
        end

        local yOffset = 20
        for i, n in ipairs(Monarch_Tickets_Notifications) do
            if IsValid(n) then
                n:SetPos(20, yOffset)
                yOffset = yOffset + n:GetTall() + 10
            end
        end
    end

    table.insert(Monarch_Tickets_Notifications, notif)
    surface.PlaySound("buttons/button14.wav")

    return notif
end

local function GetPalette()
    if Monarch and Monarch.Theme and Monarch.Theme.Get then
        return Monarch.Theme.Get()
    end
    return {
        panel = Color(28,28,30),
        outline = Color(55,57,63),
        titlebar = Color(30,30,32),
        divider = Color(80,82,88,160),
        text = Color(230,232,236),
        btn = Color(60,64,72),
        btnHover = Color(72,76,84),
        btnText = Color(240,242,245),
        primary = Color(88,88,88),
        primaryHover = Color(130,130,130),
        inputBg = Color(38,39,44),
        inputBorder = Color(70,73,79),
        inputText = Color(230,232,236),
        radius = 6,
    }
end

Monarch_Tickets_AddGlobalAndUI = Tickets_AddGlobalAndUI
Monarch_Tickets_IsStaff = IsStaff
Monarch_Tickets_CreateTicketNotification = CreateTicketNotification
Monarch_Tickets_GetPalette = GetPalette

