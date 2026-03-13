
if not CLIENT then return end

Monarch = Monarch or {}
Monarch.Loyalty = Monarch.Loyalty or {}
Monarch.Loyalty.ClientData = Monarch.Loyalty.ClientData or {}
Monarch.Loyalty._charScoped = true

function Monarch.Loyalty.RequestData()
    net.Start("Monarch_Loyalty_RequestData")
    net.SendToServer()
end

function Monarch.Loyalty.UpdateLoyaltyPoints(charKey, points)
    net.Start("Monarch_Loyalty_UpdateTier")
    net.WriteString(tostring(charKey or ""))
    net.WriteUInt(math.Clamp(points or 0, 0, 65535), 16)
    net.SendToServer()
end

function Monarch.Loyalty.UpdatePartyTier(charKey, tier)
    net.Start("Monarch_Loyalty_UpdateParty")
    net.WriteString(tostring(charKey or ""))
    net.WriteUInt(tier, 4)
    net.SendToServer()
end

function Monarch.Loyalty.UpdateTaxRate(charKey, rate)
    net.Start("Monarch_Loyalty_UpdateTax")
    net.WriteString(tostring(charKey or ""))
    net.WriteFloat(rate)
    net.SendToServer()
end

function Monarch.Loyalty.UpdateNote(charKey, note)
    net.Start("Monarch_Loyalty_UpdateNote")
    net.WriteString(tostring(charKey or ""))
    net.WriteString(note)
    net.SendToServer()
end

function Monarch.Loyalty.GetClientData()
    return Monarch.Loyalty.ClientData
end

net.Receive("Monarch_Loyalty_Sync", function()
    Monarch.Loyalty.ClientData = {}

    local count = net.ReadUInt(16)
    for i = 1, count do
        local charKey = net.ReadString()
        local steamid = net.ReadString()
        local name = net.ReadString()
        local char_name = net.ReadString()
        local loyalty_points = net.ReadUInt(16)
        local party_tier = net.ReadUInt(4)
        local tax_rate = net.ReadFloat()
        local note = net.ReadString()

        Monarch.Loyalty.ClientData[charKey] = {
            char_id = charKey,
            steamid = steamid,
            name = name,
            char_name = char_name,
            loyalty_points = loyalty_points,
            party_tier = party_tier,
            tax_rate = tax_rate,
            note = note,
        }
    end
end)

hook.Add("InitPostEntity", "Monarch_Loyalty_ClientInit", function()
    timer.Simple(2, function()
        Monarch.Loyalty.RequestData()
    end)
end)
