
Monarch.Payroll = Monarch.Payroll or {}

Monarch.Payroll.Config = {
    PayInterval = 900,
    LoyaltyGainChance = 0.25,
    LoyaltyGainAmount = math.random(1,5),

    TeamPay = {},

    LoyaltyMultipliers = {
        [1] = 0.5, 
        [2] = 0.75,
        [3] = 1.0,
        [4] = 1.25,
        [5] = 1.5,
    },
}

hook.Add("InitPostEntity", "Monarch_Payroll_InitTeamPay", function()
    Monarch.Payroll.Config.TeamPay = {}
    if TEAM_CITIZEN then Monarch.Payroll.Config.TeamPay[TEAM_CITIZEN] = 50 end
    if TEAM_WORKFORCE then Monarch.Payroll.Config.TeamPay[TEAM_WORKFORCE] = 100 end
    if TEAM_COP then Monarch.Payroll.Config.TeamPay[TEAM_COP] = 150 end
    if TEAM_MIL then Monarch.Payroll.Config.TeamPay[TEAM_MIL] = 200 end
    if TEAM_STASI then Monarch.Payroll.Config.TeamPay[TEAM_STASI] = 250 end
    if TEAM_GOV then Monarch.Payroll.Config.TeamPay[TEAM_GOV] = 300 end
end)

if SERVER then
    Monarch.RegisterItem({
        Name = "Check",
        Description = "A check that can be cashed in at the bank.",
        UniqueID = "util_payroll_check",
        CanSell = true,
        Model = "models/props_lab/clipboard.mdl",
        Stats = [[<color=112, 145, 156>+ Money</color>]],
        Weight = 0,
        UseTime = 0.2,
        CanStack = true,
    })
end

function Monarch.Payroll.GetLoyaltyTier(ply)
    if not IsValid(ply) then return 3 end

    if Monarch and Monarch.Loyalty and Monarch.Loyalty.GetPlayerData then
        local data = Monarch.Loyalty.GetPlayerData(ply)
        if data and data.loyalty_points then
            local points = tonumber(data.loyalty_points) or 0

            if points >= 80 then return 5 
            elseif points >= 60 then return 4 
            elseif points >= 40 then return 3 
            elseif points >= 20 then return 2 
            else return 1 end 
        end
    end

    return 3 
end

function Monarch.Payroll.GetTaxRate(ply)
    if not IsValid(ply) then return 0.30 end

    if SERVER and Monarch and Monarch.Loyalty and Monarch.Loyalty.GetPlayerData then
        local data = Monarch.Loyalty.GetPlayerData(ply)
        if data and data.tax_rate then
            local customTax = tonumber(data.tax_rate)
            if customTax then
                return customTax
            end
        end
    end

    local loyaltyTier = Monarch.Payroll.GetLoyaltyTier(ply)
    local tierInfo = Monarch.Loyalty and Monarch.Loyalty.Tiers and Monarch.Loyalty.Tiers[loyaltyTier]

    if tierInfo and tierInfo.tax then
        return tierInfo.tax
    end

    return 0.30 
end

function Monarch.Payroll.CalculatePayroll(ply)
    if not IsValid(ply) then return 0 end

    local team = ply:Team()
    local basePay = Monarch.Payroll.Config.TeamPay[team] or 100

    local loyaltyTier = Monarch.Payroll.GetLoyaltyTier(ply)
    local loyaltyMult = Monarch.Payroll.Config.LoyaltyMultipliers[loyaltyTier] or 1.0

    local grossPay = basePay * loyaltyMult

    local taxRate = Monarch.Payroll.GetTaxRate(ply)
    local netPay = grossPay * (1 - taxRate)

    return math.floor(netPay)
end