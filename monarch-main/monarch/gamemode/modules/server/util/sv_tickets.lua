if not SERVER then return end

util.AddNetworkString("Monarch_Tickets_Create")
util.AddNetworkString("Monarch_Tickets_RequestList")
util.AddNetworkString("Monarch_Tickets_List")
util.AddNetworkString("Monarch_Tickets_Action")
util.AddNetworkString("Monarch_Tickets_RequestOpen")
util.AddNetworkString("Monarch_Tickets_OpenUI")
util.AddNetworkString("Monarch_Tickets_Message")

Monarch = Monarch or {}
Monarch.Tickets = Monarch.Tickets or {}
Monarch.Tickets.Queue = Monarch.Tickets.Queue or {}
Monarch.Tickets.NextID = Monarch.Tickets.NextID or 1

Monarch.Tickets.OpenTimes = Monarch.Tickets.OpenTimes or {}

local function IsAdmin(ply)
    if Monarch and Monarch.IsAdminRank then return Monarch.IsAdminRank(ply) end
    return IsValid(ply) and ply:IsAdmin()
end

net.Receive("Monarch_Tickets_Create", function(_, ply)
    if not IsValid(ply) then return end
    local desc = net.ReadString() or ""
    if desc == "" then return end

    local id = Monarch.Tickets.NextID
    Monarch.Tickets.NextID = id + 1

    local ticket = {
        id = id,
        reporter = ply:SteamID64(),
        reporterName = ply:Nick(),
        description = desc,
        status = "open",
        created = os.time(),
        claimed = nil,
        claimedBy = nil,
        claimedByName = nil,
        closed = nil,
        messages = {},
    }

    table.insert(Monarch.Tickets.Queue, ticket)

    for _, admin in player.Iterator() do
        if IsValid(admin) and IsAdmin(admin) then
            net.Start("Monarch_Tickets_List")
                net.WriteTable(Monarch.Tickets.Queue)
            net.Send(admin)
        end
    end

    if IsValid(ply) then
        local playerTickets = {}
        for _, t in ipairs(Monarch.Tickets.Queue) do
            if t.reporter == ply:SteamID64() then
                table.insert(playerTickets, t)
            end
        end
        net.Start("Monarch_Tickets_List")
            net.WriteTable(playerTickets)
        net.Send(ply)
    end
end)

net.Receive("Monarch_Tickets_RequestList", function(_, ply)
    if not IsValid(ply) then return end

    if IsAdmin(ply) then
        net.Start("Monarch_Tickets_List")
            net.WriteTable(Monarch.Tickets.Queue)
        net.Send(ply)
    else
        local playerTickets = {}
        local sid = ply:SteamID64()
        for _, t in ipairs(Monarch.Tickets.Queue) do
            if t.reporter == sid then
                table.insert(playerTickets, t)
            end
        end
        net.Start("Monarch_Tickets_List")
            net.WriteTable(playerTickets)
        net.Send(ply)
    end
end)

net.Receive("Monarch_Tickets_Action", function(_, actor)
    if not IsValid(actor) then return end
    local id = net.ReadUInt(16)
    local action = net.ReadString() or ""

    local ticket = nil
    for _, t in ipairs(Monarch.Tickets.Queue) do
        if t.id == id then ticket = t break end
    end

    if not ticket then return end

    if action == "claim" then
        if not IsAdmin(actor) then return end
        ticket.claimed = os.time()
        ticket.claimedBy = actor:SteamID64()
        ticket.claimedByName = actor:Nick()
        ticket.status = "claimed"
        Monarch.Tickets.OpenTimes[id] = { sid = actor:SteamID64(), start = os.time() }
        print("[Monarch Tickets] Ticket #"..id.." claimed by "..actor:Nick().." ("..actor:SteamID64()..")")

    elseif action == "close" then
        local isStaff = IsAdmin(actor)
        local isReporter = tostring(actor:SteamID64()) == tostring(ticket.reporter)
        if not (isStaff or isReporter) then return end

        ticket.closed = os.time()
        ticket.status = "closed"

        if isStaff then
            if not ticket.claimedBy then
                ticket.claimed = ticket.closed
                ticket.claimedBy = actor:SteamID64()
                ticket.claimedByName = actor:Nick()
                Monarch.Tickets.OpenTimes[id] = { sid = actor:SteamID64(), start = ticket.created or ticket.closed }
            end

            if ticket.claimedBy and Monarch.Tickets.OpenTimes[id] then
                local open = Monarch.Tickets.OpenTimes[id]
                local duration = math.max(0, ticket.closed - open.start)

                Monarch.StaffStats = Monarch.StaffStats or {}
                local sid = open.sid
                local rec = Monarch.StaffStats[sid] or { name = ticket.claimedByName or sid, group = "user", tickets = 0, total_time = 0, strikes = {}, strike_points = 0 }
                rec.tickets = (tonumber(rec.tickets) or 0) + 1
                rec.total_time = (tonumber(rec.total_time) or 0) + duration
                rec.last_active = os.time()
                Monarch.StaffStats[sid] = rec

                if Monarch.SaveStaffStats then 
                    Monarch.SaveStaffStats() 
                    print("[Monarch Tickets] Logged ticket #"..id.." for "..rec.name.." (duration: "..duration.."s, total tickets: "..rec.tickets..")")
                end

                Monarch.Tickets.OpenTimes[id] = nil
            end
        end

        for i, t in ipairs(Monarch.Tickets.Queue) do
            if t.id == id then
                table.remove(Monarch.Tickets.Queue, i)
                break
            end
        end
    end

    for _, p in player.Iterator() do
        if IsValid(p) and IsAdmin(p) then
            net.Start("Monarch_Tickets_List")
                net.WriteTable(Monarch.Tickets.Queue)
            net.Send(p)
        end
    end

    if ticket and ticket.reporter then
        local reporter = player.GetBySteamID64(ticket.reporter)
        if IsValid(reporter) then
            local playerTickets = {}
            for _, t in ipairs(Monarch.Tickets.Queue) do
                if t.reporter == ticket.reporter then
                    table.insert(playerTickets, t)
                end
            end
            net.Start("Monarch_Tickets_List")
                net.WriteTable(playerTickets)
            net.Send(reporter)
        end
    end
end)

net.Receive("Monarch_Tickets_Message", function(_, sender)
    if not IsValid(sender) then return end
    local id = net.ReadUInt(16)
    local text = net.ReadString() or ""
    if text == "" then return end

    local ticket
    for _, t in ipairs(Monarch.Tickets.Queue) do if t.id == id then ticket = t break end end
    if not ticket then return end

    local isStaff = IsAdmin(sender)
    local isReporter = tostring(sender:SteamID64()) == tostring(ticket.reporter)
    if not (isStaff or isReporter) then return end

    ticket.messages = ticket.messages or {}
    local msg = {
        sid = sender:SteamID64(),
        name = sender:Nick(),
        role = isStaff and "staff" or "player",
        text = string.sub(text, 1, 500), 
        time = os.time()
    }
    table.insert(ticket.messages, msg)

    local sent = {}
    local function SendMsg(toPly)
        if not IsValid(toPly) then return end
        if sent[toPly] then return end
        sent[toPly] = true
        net.Start("Monarch_Tickets_Message")
            net.WriteUInt(id, 16)
            net.WriteTable(msg)
        net.Send(toPly)
    end

    for _, p in player.Iterator() do
        if IsValid(p) and IsAdmin(p) then
            SendMsg(p)
        end
    end
    local rep = player.GetBySteamID64(ticket.reporter)
    if IsValid(rep) then
        SendMsg(rep)
    end
end)

net.Receive("Monarch_Tickets_RequestOpen", function(_, ply)
    if not IsValid(ply) then return end
    net.Start("Monarch_Tickets_OpenUI")
    net.Send(ply)
end)

hook.Add("PlayerSay", "Monarch_Tickets_ChatCommand", function(ply, text)
    if not IsValid(ply) or not isstring(text) then return end
    local lower = string.lower(text)
    if lower == "!ticket" or lower == "/ticket" then
        net.Start("Monarch_Tickets_OpenUI")
        net.Send(ply)
        return ""
    end
end)
