

local PLAYER = FindMetaTable("Player")

Monarch = Monarch or {}
Monarch.Status = Monarch.Status or {}
Monarch.Status.BleedTick = 6.0         
Monarch.Status.BleedDamage = 2          
Monarch.Status.DiseaseTick = 3.0       
Monarch.Status.DiseaseDamage = 1       
Monarch.Status.StarveTick = 1.0        
Monarch.Status.StarveDamage = 1        
Monarch.Status.StarveMinHP = 3         
Monarch.Status.BleedMinHP = 5         
Monarch.Status.HungerThreshold = 5     

function PLAYER:IsBleeding()
	return self:GetNWBool("Monarch_Bleeding", false)
end

function PLAYER:SetBleeding(state)
	self:SetNWBool("Monarch_Bleeding", state and true or false)
	if state then
		self._monarchNextBleed = 0
	end
end

function PLAYER:HasDisease()
	return self:GetNWBool("Monarch_Diseased", false)
end

function PLAYER:SetDisease(state)
	self:SetNWBool("Monarch_Diseased", state and true or false)
	if state then
		self._monarchNextDisease = 0
	end
end

hook.Add("EntityTakeDamage", "Monarch_Bleeding", function(ent, dmg)
	if not IsValid(ent) or not ent:IsPlayer() then return end
	if ent:IsBleeding() then return end
	local dmgType = dmg:GetDamageType()
	if bit.band(dmgType, DMG_BULLET) ~= 0 or bit.band(dmgType, DMG_SLASH) ~= 0 or bit.band(dmgType, DMG_CLUB) ~= 0 then
		if math.random() < 0.05 then
			ent:SetBleeding(true)
		end
	end
end)

Monarch = Monarch or {}
Monarch.Vendors = Monarch.Vendors or {}
Monarch.RankVendors = Monarch.RankVendors or {}

Monarch.Vendors["material_store"] = {
	name = "Hardware Supply",
	desc = "Purchase crafting materials and components",
	model = "models/Humans/Group01/male_02.mdl",
	items = {
		{
			class = "mat_screws",
			name = "Screws",
			desc = "A small container of screws",
			model = "models/mosi/fallout4/props/junk/components/screws.mdl",
			price = 25,
			sellPrice = 12, 
			stock = 100
		},
		{
			class = "mat_springs",
			name = "Springs",
			desc = "A small container of springs",
			model = "models/mosi/fallout4/props/junk/components/springs.mdl",
			price = 30,
			stock = 80
		},
		{
			class = "mat_adhesive",
			name = "Adhesive",
			desc = "A small bottle of adhesive",
			model = "models/mosi/fallout4/props/junk/components/adhesive.mdl",
			price = 35,
			stock = 60
		},
		{
			class = "mat_duct_tape",
			name = "Duct Tape",
			desc = "A roll of duct tape",
			model = "models/mosi/fallout4/props/junk/ducttape.mdl",
			price = 40,
			stock = 50
		},
		{
			class = "mat_glass",
			name = "Glass",
			desc = "A small shard of glass",
			model = "models/mosi/fallout4/props/junk/components/glass.mdl",
			price = 20,
			stock = 75
		},
		{
			class = "mat_lead",
			name = "Lead",
			desc = "A small ingot of lead",
			model = "models/mosi/fallout4/props/junk/components/lead.mdl",
			price = 45,
			stock = 40
		},
		{
			class = "mat_cloth",
			name = "Cloth",
			desc = "A small roll of cloth",
			model = "models/mosi/fallout4/props/junk/components/cloth.mdl",
			price = 15,
			stock = 120
		},
		{
			class = "mat_wood",
			name = "Wood",
			desc = "A small pile of wood",
			model = "models/mosi/fallout4/props/junk/components/wood.mdl",
			price = 10,
			stock = 150
		},
		{
			class = "mat_leather",
			name = "Leather",
			desc = "A small roll of leather",
			model = "models/mosi/fallout4/props/junk/components/leather.mdl",
			price = 50,
			stock = 35
		}
	}
}

Monarch.Vendors["weapon_vp_armory"] = {
	name = "VP Armory",
	desc = "Weapons, Ammunition, and other tools for a police officers day to day duties.",
	model = "models/Humans/Group01/male_04.mdl",
	team = TEAM_COP,

	CanBuy = function(ply, vend, item)
		return true
	end,
	items = {
		{
			class = "med_pills",
			name = "Pills",
			desc = "Standard pain medication. Restores a small amount of health.",
			model = "models/synapse/misc_props/synapse_medicine_bottles_2.mdl",
			price = 0,
			stock = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "wep_pm",
			name = "Makarov PM",
			desc = "A standard issue sidearm for VP officers.",
			model = "models/weapons/tfa_ins2/c_pm.mdl",
			price = 0,
			stock = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "wep_svt40",
			name = "SVT-40",
			desc = "A semi-automatic rifle used by Soviet forces during World War II.",
			model = "models/weapons/tfa_codww2/svt40/w_svt40_stock.mdl",
			price = 200,
			stock = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "wep_ppsh",
			name = "PPSH-41",
			desc = "A Soviet submachine gun used during World War II.",
			model = "models/weapons/tfa_codww2/ppsh41/w_ppsh41_stock.mdl",
			price = 200,
			stock = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "food_ration",
			name = "VP Ration",
			desc = "A standard military ration pack.",
			model = "models/hls/alyxports/cardboard_box_3.mdl",
			price = 50,
			stock = 20,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		}
	}
}

Monarch.Vendors["weapon_stasi_armory"] = {
	name = "Military Armory",
	desc = "Weapons, Ammunition, and other tools for a soldiers day to day duties.",
	model = "models/Humans/Group01/male_04.mdl",

	CanBuy = function(ply, vend, item)
		return true
	end,
	items = {
		{
			class = "med_pills",
			name = "Pills",
			desc = "Standard pain medication. Restores a small amount of health.",
			model = "models/synapse/misc_props/synapse_medicine_bottles_2.mdl",
			price = 0,
			stock = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "wep_pm",
			name = "Makarov PM",
			desc = "A standard issue sidearm for VP officers.",
			model = "models/weapons/tfa_ins2/c_pm.mdl",
			price = 0,
			stock = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "wep_svt40",
			name = "SVT-40",
			desc = "A semi-automatic rifle used by Soviet forces during World War II.",
			model = "models/weapons/tfa_codww2/svt40/w_svt40_stock.mdl",
			price = 200,
			stock = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "wep_ppsh",
			name = "PPSH-41",
			desc = "A Soviet submachine gun used during World War II.",
			model = "models/weapons/tfa_codww2/ppsh41/w_ppsh41_stock.mdl",
			price = 200,
			stock = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "food_ration",
			name = "Soviet Military Grade Ration",
			desc = "A standard military ration pack.",
			model = "models/hls/alyxports/cardboard_box_3.mdl",
			price = 50,
			stock = 20,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		}
	}
}

Monarch.Vendors["weapon_stasi2_armory"] = {
	name = "Stasi Armory",
	desc = "Weapons, Ammunition, and other tools for a police officer's day to day duties.",
	model = "models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_01.mdl",

	CanBuy = function(ply, vend, item)
		return true
	end,
	items = {
		{
			class = "med_pills",
			name = "Pills",
			desc = "Standard pain medication. Restores a small amount of health.",
			model = "models/synapse/misc_props/synapse_medicine_bottles_2.mdl",
			price = 0,
			stock = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "wep_pm",
			name = "Makarov PM",
			desc = "A standard issue sidearm for VP officers.",
			model = "models/weapons/tfa_ins2/c_pm.mdl",
			price = 0,
			stock = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "wep_svt40",
			name = "SVT-40",
			desc = "A semi-automatic rifle used by Soviet forces during World War II.",
			model = "models/weapons/tfa_codww2/svt40/w_svt40_stock.mdl",
			price = 200,
			stock = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return ply:GetWhitelist(TEAM_STASI) >= 2 end
		},
		{
			class = "wep_ppsh",
			name = "PPSH-41",
			desc = "A Soviet submachine gun used during World War II.",
			model = "models/weapons/tfa_codww2/ppsh41/w_ppsh41_stock.mdl",
			price = 250,
			stock = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return ply:GetWhitelist(TEAM_STASI) >= 2 end
		},
		{
			class = "wep_rev",
			name = "Revolver",
			desc = "A high powered revolver.",
			model = "models/weapons/w_ins2_revolver_mr96.mdl",
			price = 100,
			stock = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return ply:GetWhitelist(TEAM_STASI) >= 5 end
		},
		{
			class = "food_ration",
			name = "Loyalist Grade Ration",
			desc = "A standard loyalist ration pack.",
			model = "models/hls/alyxports/cardboard_box_3.mdl",
			price = 50,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "util_rustyclock",
			name = "Rusty Clock",
			desc = "An old clock. You can use it to tell the time.",
			model = "models/props_c17/clock01.mdl",
			price = 10,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "cos_stasiuniform_undercover",
			name = "Town Uniform",
			desc = "A standard soviet uniform.",
			model = "models/willardnetworks/update_items/cajacket1_item.mdl",
			price = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "cos_stasiuniform_enservice",
			name = "Enlisted S.U",
			desc = "A standard enlisted uniform worn by enlisted members of the Stasi.",
			model = "models/willardnetworks/update_items/cajacket1_item.mdl",
			price = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return ply:GetWhitelist(TEAM_STASI) >= 1 end
		},
		{
			class = "cos_stasiuniform_coservice",
			name = "Officer's S.U",
			desc = "A standard Officer uniform worn by Commissioned members of the Stasi.",
			model = "models/willardnetworks/update_items/cajacket1_item.mdl",
			price = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return ply:GetWhitelist(TEAM_STASI) >= 6 end
		},
		{
			class = "cos_stasiuniform_cosocial",
			name = "Officer's S.O.U",
			desc = "A standard Social uniform worn by Commissioned members of the Stasi.",
			model = "models/willardnetworks/update_items/cajacket1_item.mdl",
			price = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return ply:GetWhitelist(TEAM_STASI) >= 6 end
		},
		{
			class = "cos_stasiuniform_genservice",
			name = "General's S.U",
			desc = "A standard Service uniform worn by Generals of the Stasi.",
			model = "models/willardnetworks/update_items/cajacket1_item.mdl",
			price = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return ply:GetWhitelist(TEAM_STASI) == 10 end
		},
		{
			class = "cos_stasiuniform_gensocial",
			name = "General's S.O.U",
			desc = "A standard Social uniform worn by Generals of the Stasi.",
			model = "models/willardnetworks/update_items/cajacket1_item.mdl",
			price = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return ply:GetWhitelist(TEAM_STASI) == 10 end
		},
	}
}

Monarch.Vendors["weapon_gov_armory"] = {
	name = "Government Armory",
	desc = "General equipment to provide a level of personal security to government officials.",
	model = "models/strabe/ddr2/stasi7482/stasi/suit/suits/stasi_suit_04.mdl",

	CanBuy = function(ply, vend, item)
		return true
	end,
	items = {
		{
			class = "med_pills",
			name = "Pills",
			desc = "Standard pain medication. Restores a small amount of health.",
			model = "models/synapse/misc_props/synapse_medicine_bottles_2.mdl",
			price = 0,
			stock = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "wep_pm",
			name = "Makarov PM",
			desc = "A standard issue sidearm for self-defense.",
			model = "models/weapons/tfa_ins2/c_pm.mdl",
			price = 0,
			stock = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "wep_rev",
			name = "Revolver",
			desc = "A high powered revolver.",
			model = "models/weapons/w_ins2_revolver_mr96.mdl",
			price = 0,
			stock = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return ply:GetWhitelist(TEAM_GOV) >= 5 end
		},
		{
			class = "food_ration",
			name = "Loyalist Grade Ration",
			desc = "A standard loyalist ration pack.",
			model = "models/hls/alyxports/cardboard_box_3.mdl",
			price = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "util_rustyclock",
			name = "Rusty Clock",
			desc = "An old clock. You can use it to tell the time.",
			model = "models/props_c17/clock01.mdl",
			price = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		},
		{
			class = "util_flight",
			name = "Flashlight",
			desc = "A standard issue flashlight.",
			model = "models/props_c17/TrapPropeller_Lever.mdl",
			price = 0,
			CustomCheck = function(ply, vend, item) return true end,
			CanBuy = function(ply, vend, item) return true end
		}
	}
}

Monarch.RegisterSkill({ id = "crafting", Name = "Craftsmanship", Color = Color(255, 75, 75), Icon = "icons/skills/crafting-icon128.png" })
Monarch.RegisterSkill({ id = "culinary", Name = "Culinary Arts", Color = Color(255, 165, 0), Icon = "icons/skills/cooking-icon128.png" })
Monarch.RegisterSkill({ id = "weaponsmithing", Name = "Weaponsmithing", Color = Color(200, 200, 200), Icon = "icons/skills/crafting-icon128.png" })
Monarch.RegisterSkill({ id = "scrapping", Name = "Scavenging", Color = Color(150, 75, 0), Icon = "icons/skills/scavenging-icon128.png" })
Monarch.RegisterSkill({ id = "farming", Name = "Agriculture", Color = Color(75, 250, 75), Icon = "icons/skills/farming-icon128.png" })

Monarch = Monarch or {}
Monarch.Loyalty = Monarch.Loyalty or {}

Monarch.Loyalty.Tiers = {
    [1] = { name = "Suspect", color = Color(200, 0, 0), tax = 0.50, benefits = "None" },
    [2] = { name = "Unreliable", color = Color(255, 100, 0), tax = 0.40, benefits = "Basic rations" },
    [3] = { name = "Neutral", color = Color(200, 200, 0), tax = 0.30, benefits = "Standard rations" },
    [4] = { name = "Trustworthy", color = Color(100, 200, 0), tax = 0.20, benefits = "Housing priority" },
    [5] = { name = "Exemplary", color = Color(0, 200, 0), tax = 0.10, benefits = "All benefits" },
}

Monarch.Loyalty.PartyTiers = {
    [0] = { name = "Non-Member", color = Color(128, 128, 128), perks = "None" },
    [1] = { name = "Candidate", color = Color(150, 150, 200), perks = "Party meetings" },
    [2] = { name = "Member", color = Color(100, 100, 255), perks = "Party benefits" },
    [3] = { name = "Officer", color = Color(50, 50, 200), perks = "Leadership role" },
    [4] = { name = "Committee Member", color = Color(200, 50, 50), perks = "Full authority" },
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

Monarch.VehicleVendors = Monarch.VehicleVendors or {}

Monarch.VehicleVendors["motor_depot"] = {
	name = "Motor Depot",
	desc = "Purchase and spawn personal and government vehicles",
	model = "models/Humans/Group01/male_02.mdl",
	vehicles = {
		{
			class = "ses_gaz24",
			name = "GAZ-24 Volga",
			desc = "Classic sedan, reliable and spacious",
			model = "models/ses/gaz_24.mdl",
			price = 1500,
			CustomCheck = function(ply, vend, veh) return true end
		},
		{
			class = "ses_gaz2410",
			name = "GAZ-2410 Volga",
			desc = "Upgraded Volga model with improved performance",
			model = "models/ses/gaz_2410.mdl",
			price = 1600,
			CustomCheck = function(ply, vend, veh) return true end
		},
		{
			class = "ses_vaz2105",
			name = "VAZ-2105 Lada",
			desc = "Compact and economical car",
			model = "models/ses/vaz_2105.mdl",
			price = 1250,
			CustomCheck = function(ply, vend, veh) return true end
		},
		{
			class = "ses_vaz2108_cabrio",
			name = "VAZ-2108 Cabrio",
			desc = "Open-top convertible",
			model = "models/ses/vaz_2108_cabrio.mdl",
			price = 2500,
			CustomCheck = function(ply, vend, veh) return true end
		},
		{
			class = "ses_uaz452",
			name = "UAZ-452 Van",
			desc = "Versatile utility van for cargo and passengers",
			model = "models/ses/uaz_452.mdl",
			price = 2000,
			CustomCheck = function(ply, vend, veh) return true end
		},
		{
			class = "ses_vaz2109u",
			name = "VAZ-2109 Samara",
			desc = "Modern hatchback with good fuel economy",
			model = "models/ses/vaz_2109u.mdl",
			price = 1800,
			CustomCheck = function(ply, vend, veh) return true end
		},
		{
			class = "ses_vaz2109_police",
			name = "VAZ-2109 Police",
			desc = "Police patrol vehicle - Stasi or VP Corporal+",
			model = "models/ses/vaz_2109_police.mdl",
			price = 0,
			CustomCheck = function(ply, vend, veh)
				if ply:Team() == TEAM_STASI then return true end
				if ply:Team() == TEAM_COP and ply:GetWhitelist(TEAM_COP) >= 1 then return true end
				return false
			end
		},
		{
			class = "ses_gaz24_kgb",
			name = "GAZ-24 KGB",
			desc = "State Security service vehicle - Stasi",
			model = "models/ses/gaz_24_kgb.mdl",
			price = 0,
			CustomCheck = function(ply, vend, veh)
				return ply:Team() == TEAM_STASI
			end
		},
		{
			class = "ses_uaz469",
			name = "UAZ-469 Military",
			desc = "Military transport vehicle - Military",
			model = "models/ses/uaz_469.mdl",
			price = 0,
			CustomCheck = function(ply, vend, veh)
				return ply:Team() == TEAM_MIL
			end
		},
		{
			class = "lvs_zil431510",
			name = "ZIL-431510 Truck",
			desc = "Heavy cargo truck - Foreman+",
			model = "models/diggercars/zil_431510/zil_431510.mdl",
			price = 0,
			CustomCheck = function(ply, vend, veh)
				return ply:Team() == TEAM_CITIZEN and ply:GetWhitelist(1) >= 1
			end
		}
	}
}
