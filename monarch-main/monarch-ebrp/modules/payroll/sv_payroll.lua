

Monarch.Payroll = Monarch.Payroll or {}

Monarch.Payroll.PendingChecks = Monarch.Payroll.PendingChecks or {}

util.AddNetworkString("Monarch.SendPayroll")
util.AddNetworkString("Monarch.RequestPayroll")
util.AddNetworkString("Monarch.SendPayrollClient")
util.AddNetworkString("Monarch_LoyaltyGain")
util.AddNetworkString("Monarch_AdminAddLoyalty")

function Monarch.Payroll.SendPayroll(ply, amt)
    if not IsValid(ply) then 
        return 
    end
    if amt <= 0 then 
        return 
    end

    local charID = ply.GetCharID and ply:GetCharID() or (ply.MonarchActiveChar and ply.MonarchActiveChar.id)
    if not charID then
        return
    end

    local success = false
    success = ply:GiveInventoryItem("util_payroll_check", 1)

    return success
end

net.Receive("Monarch.RequestPayroll", function(len, ply)
    local amt = Monarch.Payroll.CalculatePayroll(ply)

    net.Start("Monarch.SendPayrollClient")
    net.Send(ply)

    Monarch.Payroll.SendPayroll(ply, amt)
end)

function Monarch.Payroll.DistributeAutomaticPayroll()
    local players = player.GetAll()
    local totalPaid = 0
    local recipientCount = 0

    for _, ply in ipairs(players) do
        if IsValid(ply) and ply:Alive() then
            local amt = Monarch.Payroll.CalculatePayroll(ply)

            if amt > 0 then

                Monarch.Payroll.SendPayroll(ply, amt)

                net.Start("Monarch.SendPayrollClient")
                net.Send(ply)

                totalPaid = totalPaid + amt
                recipientCount = recipientCount + 1
            end
        end
    end

end

function Monarch.Payroll.Initialize()    
    if not Monarch.Payroll.Config or not Monarch.Payroll.Config.PayInterval then
        print("[Payroll] Error: Config not loaded yet")
        return
    end

    local interval = Monarch.Payroll.Config.PayInterval
    timer.Create("Monarch.Payroll.AutomaticDistribution", interval, 0, function()
        Monarch.Payroll.DistributeAutomaticPayroll()
    end)
end

hook.Add("InitPostEntity", "Monarch.Payroll.Init", function()
    timer.Simple(2, function()
        if Monarch.Payroll.Config then
            Monarch.Payroll.Initialize()
        else
            print("[Payroll] WARNING: Config still not loaded")
        end
    end)
end)

net.Receive("Monarch_AdminAddLoyalty", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then
        if ply.Notify then ply:Notify("You don't have permission to use this command.") end
        return
    end

    local steamid = net.ReadString()
    local amount = net.ReadInt(32)

    if not amount or amount <= 0 then
        if ply.Notify then ply:Notify("Amount must be a positive number.") end
        return
    end

    local targetPly = nil
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and (p:SteamID64() == steamid or p:SteamID() == steamid) then
            targetPly = p
            break
        end
    end

    if not targetPly then
        if ply.Notify then ply:Notify("Player with SteamID " .. steamid .. " not found.") end
        return
    end

    if not Monarch or not Monarch.Loyalty then
        if ply.Notify then ply:Notify("Loyalty system not loaded.") end
        return
    end

    local data = Monarch.Loyalty.GetPlayerData(targetPly)
    if not data then
        if ply.Notify then ply:Notify("Could not retrieve player loyalty data.") end
        return
    end

    local currentPoints = tonumber(data.loyalty_points) or 0
    local newPoints = math.min(currentPoints + amount, 100)
    local actualGain = newPoints - currentPoints

    Monarch.Loyalty.SetLoyaltyTier(targetPly, newPoints)

    net.Start("Monarch_LoyaltyGain")
    net.WriteInt(actualGain, 8)
    net.Send(targetPly)

    if ply.Notify then ply:Notify("Added " .. actualGain .. " loyalty to " .. targetPly:GetName() .. " (now " .. newPoints .. "/100).") end
    if targetPly.Notify then targetPly:Notify("An admin added " .. actualGain .. " loyalty to your account!") end
end)