
Monarch = Monarch or {}
Monarch.Loyalty = Monarch.Loyalty or {}
Monarch.Loyalty._charScoped = true

Monarch.Loyalty.Tiers = {
    [1] = { name = "Criminal", color = Color(200, 0, 0), tax = 0.50, benefits = "" },
    [2] = { name = "Unreliable", color = Color(255, 100, 0), tax = 0.40, benefits = "" },
    [3] = { name = "Neutral", color = Color(200, 200, 0), tax = 0.30, benefits = "" },
    [4] = { name = "Trustworthy", color = Color(100, 200, 0), tax = 0.20, benefits = "" },
    [5] = { name = "Exemplary", color = Color(0, 200, 0), tax = 0.10, benefits = "" },
}

Monarch.Loyalty.PartyTiers = {
    [0] = { name = "No Level", color = Color(128, 128, 128), perks = "" },
    [1] = { name = "Level 1", color = Color(50, 150, 50), perks = "" },
    [2] = { name = "Level 2", color = Color(100, 255, 100), perks = "" },
    [3] = { name = "Level 3", color = Color(100, 255, 100), perks = "" },
    [4] = { name = "Level 4", color = Color(100, 255, 100), perks = "" },
}

function Monarch.Loyalty.GetTierName(tier)
    tier = math.Clamp(tier or 1, 1, 5)
    return Monarch.Loyalty.Tiers[tier].name
end

function Monarch.Loyalty.GetTierColor(tier)
    tier = math.Clamp(tier or 1, 1, 5)
    return Monarch.Loyalty.Tiers[tier].color
end

function Monarch.Loyalty.GetPartyTierName(tier)
    tier = math.Clamp(tier or 0, 0, 4)
    return Monarch.Loyalty.PartyTiers[tier].name
end

function Monarch.Loyalty.GetPartyTierColor(tier)
    tier = math.Clamp(tier or 0, 0, 4)
    return Monarch.Loyalty.PartyTiers[tier].color
end
