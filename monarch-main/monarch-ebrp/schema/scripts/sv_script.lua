function Monarch.CharSystem.ShowPIC(ply, target)
    if not IsValid(target) or not IsValid(ply) then return end
    local c = ply.MonarchActiveChar or ply.MonarchCharData
    if not c then return end
    local occupation = team.GetName and team.GetName(c.team or 1) or "Citizen"

	local loyaltyTier = 0
	local partyTier = 0
	local charKey = ply.GetCharID and ply:GetCharID()
	if Monarch.Loyalty then
		local loyaltyData
		if Monarch.Loyalty.GetPlayerData then
			loyaltyData = Monarch.Loyalty.GetPlayerData(ply)
		end
		if not loyaltyData and charKey and Monarch.Loyalty.Data then
			loyaltyData = Monarch.Loyalty.Data[tostring(charKey)]
		end

		if loyaltyData then
			loyaltyTier = loyaltyData.loyalty_points or loyaltyData.loyalty_tier or 0
			partyTier = loyaltyData.party_tier or 0
		end
	end

    net.Start("Monarch_ShowPIC")
        net.WriteString(c.name or "Unknown")
        net.WriteString(occupation)
        net.WriteString(ply:SteamID())
        net.WriteUInt(c.id or 0, 32)
        net.WriteInt(ply:Health(), 16)
        net.WriteString(c.height or "")
        net.WriteString(c.weight or "")
        net.WriteString(c.haircolor or "")
        net.WriteString(c.eyecolor or "")
        net.WriteInt(c.age or 0, 16)
        net.WriteInt(loyaltyTier, 16)
        net.WriteInt(partyTier, 16)
    net.Send(target)
end

timer.Simple(0, function()
    if not Monarch or not Monarch.RegisterCraftingBench then return end

    Monarch.RegisterCraftingBench({
        id = "weapons_bench",
        Name = "Weaponsmithing",
        Model = "models/props_c17/workbench01.mdl",
        Skill = "weaponsmithing",
        RequiredLevel = 1,
        Illegal = false
    })

	Monarch.RegisterCraftingBench({
		id = "tailoring_bench",
		Name = "Tailoring",
		Model = "models/props_c17/workbench01.mdl",
		Skill = "crafting",
		RequiredLevel = 1,
		Illegal = false
	})

	Monarch.RegisterCraftingBench({
		id = "gunsmith_bench",
		Name = "Heavy Weapons",
		Model = "models/props_wasteland/controlroom_desk001b.mdl",
		Skill = "weaponsmithing",
		RequiredLevel = 3,
		Illegal = true,
		Sound = "foley/skills/skill_crafting.wav"
	})

	local function R(level, bench, output, time, mats)
		Monarch.RegisterRecipe({ level = level, Bench = bench, Output = output, Time = time, Mats = mats })
	end

	R(2, "tailoring_bench", "cos_blacksuit", 30, { mat_cloth = 8, mat_adhesive = 2 })
	R(1, "tailoring_bench", "cos_boots", 18, { mat_leather = 4, mat_cloth = 2, mat_adhesive = 1 })
	R(1, "tailoring_bench", "cos_bpants", 18, { mat_cloth = 5, mat_adhesive = 1 })
	R(2, "tailoring_bench", "cos_gasmask", 28, { mat_glass = 2, mat_adhesive = 2, mat_cloth = 2, mat_duct_tape = 2 })
	R(2, "tailoring_bench", "cos_heavypants", 24, { mat_cloth = 6, mat_leather = 2, mat_duct_tape = 1 })
	R(2, "tailoring_bench", "cos_m3helm", 26, { mat_lead = 6, mat_cloth = 1, mat_adhesive = 2 })
	R(1, "tailoring_bench", "cos_milhat", 14, { mat_cloth = 3, mat_leather = 1, mat_adhesive = 1 })
	R(1, "tailoring_bench", "cos_refugeeCoat", 22, { mat_cloth = 6, mat_leather = 2, mat_adhesive = 1 })
	R(2, "tailoring_bench", "cos_vest", 26, { mat_cloth = 6, mat_leather = 3, mat_adhesive = 2 })
	R(2, "tailoring_bench", "cos_winterjacket", 28, { mat_cloth = 8, mat_leather = 2, mat_adhesive = 2 })

	R(1, "general_bench", "med_bandage", 8, { mat_cloth = 2, mat_adhesive = 1 })
	R(2, "general_bench", "med_medkit", 20, { mat_cloth = 4, mat_adhesive = 2, mat_glass = 1, mat_duct_tape = 1 })
	R(1, "general_bench", "util_sleepingbag", 22, { mat_cloth = 6, mat_leather = 2, mat_adhesive = 2 })

	R(4, "gunsmith_bench", "wep_spas12", 45, { mat_lead = 12, mat_springs = 3, mat_screws = 4, mat_adhesive = 2, mat_wood = 1 })
	R(4, "gunsmith_bench", "wep_svt40", 50, { mat_lead = 12, mat_wood = 3, mat_springs = 3, mat_screws = 4, mat_adhesive = 2 })
	R(4, "gunsmith_bench", "wep_ppsh", 42, { mat_lead = 10, mat_wood = 2, mat_springs = 3, mat_screws = 4, mat_adhesive = 2 })
	R(4, "gunsmith_bench", "wep_ak107", 55, { mat_lead = 12, mat_wood = 2, mat_springs = 3, mat_screws = 4, mat_adhesive = 2 })
	R(3, "gunsmith_bench", "wep_throw_grenade", 18, { mat_lead = 4, mat_adhesive = 2, mat_screws = 2, mat_duct_tape = 2 })

    R(3, "weapons_bench", "wep_1911", 25, { mat_lead = 8, mat_springs = 2, mat_screws = 4})
    R(4, "weapons_bench", "wep_m1a1", 40, { mat_lead = 12, mat_springs = 4, mat_screws = 6, mat_wood = 4 })
    R(4, "weapons_bench", "wep_spas12", 45, { mat_lead = 14, mat_springs = 4, mat_screws = 6})
    R(5, "weapons_bench", "wep_m1garand", 55, { mat_lead = 16, mat_springs = 4, mat_screws = 8, mat_wood = 6 })

    R(2, "general_bench", "wep_melee_crowbar", 10, { mat_lead = 6, mat_screws = 2 })

    R(1, "tailoring_bench", "cos_formalshoes", 15, { mat_cloth = 6 })
    R(1, "tailoring_bench", "cos_fedora", 12, { mat_cloth = 5 })
    R(2, "tailoring_bench", "cos_blacksuit", 30, { mat_cloth = 12})

    Monarch.RegisterCraftingBench({
        id = "general_workbench",
        Name = "General Workbench",
        Model = "models/props_c17/FurnitureBoiler001a.mdl",
        Skill = "crafting",
        CraftingSound = "foley/skills/skill_crafting.wav",
        Illegal = false,
        CanUse = function(ply, ent)
            return true
        end
    })

    Monarch.RegisterRecipe({
        level = 1,
        Bench = "general_workbench",
        Output = "food_bread",
        Time = 3,
        Mats = {
            ["gen_flour"] = { take = 1 },
            ["food_watercan"] = { take = 1 }
        }
    })

    Monarch.RegisterRecipe({
        level = 1,
        Bench = "general_workbench",
        Output = "mat_screws",
        Time = 3,
        Mats = {
            ["mat_lead"] = { take = 1 }
        }
    })

    Monarch.RegisterRecipe({
        level = 1,
        Bench = "general_workbench",
        Output = "mat_lead",
        Time = 1,
        Mats = {
            ["mat_screws"] = { take = 1 }
        }
    })

    Monarch.RegisterRecipe({
        level = 2,
        Bench = "general_workbench",
        Output = "food_emptywaterbottle",
        Time = 5,
        Mats = {
            ["mat_glass"] = { take = 2 }
        }
    })

    Monarch.RegisterRecipe({
        level = 4,
        Bench = "general_workbench",
        Output = "mat_duct_tape",
        Time = 4,
        Mats = {
            ["mat_adhesive"] = { take = 2 },
            ["mat_cloth"] = { take = 1}
        }
    })
end)

Monarch.RegisterLoot({
    UniqueID = "storage_lockbox",
    UseName = "Opening Lockbox...",
    Model = "models/props_junk/wood_crate001a.mdl",
    OpenTime = 1.2,
    OpenSound = "foley/containers/wood_wardrobe_open.mp3",
    CloseSound = "foley/containers/wood_wardrobe_close.mp3",
    CanStore = true,
    CapacityX = 5,
    CapacityY = 6,
    LootTable = {
    }
})

Monarch.RegisterLoot({
    UniqueID = "Common",
    UseName = "Opening...",
    OpenTime = 1.2,
    LootTable = {
        mat_wood = { rolls = 2, rarity = 1 },
        food_bread = { rolls = 1, rarity = 4 },
        food_water = { rolls = 1, rarity = 4 },
        mat_coins = { rolls = 1, rarity = 3 },
        mat_screws = { rolls = 1, rarity = 2 },
        mat_cloth = { rolls = 1, rarity = 2 },
    }
})

Monarch.RankVendors["vp_recruiter"] = {
	name = "VP Recruiter",
	desc = "Join the Police force or advance your rank",
	model = "models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_04.mdl",
	team = TEAM_COP,
	CanBuy = function(ply, vend, r)
		return true
	end,
	ranks = {
		{
			id = "vp_offduty",
			name = "Off Duty",
			desc = "Quittin time already?",
			team = TEAM_COP,
			group = "VP",
			grouprank = "Off Duty",
			respawn = true,
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetBodyGroups("00000000000000")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName(baseName)
			end
		},
		{
			id = "vp_recruit",
			name = "VP Recruit",
			desc = "Join as a Recruit",
			team = TEAM_COP,
			group = "VP",
			grouprank = "Off Duty",
			respawn = false,
			model = "models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Private "..baseName)
			end
		},
		{
			id = "vp_corporal",
			name = "VP Corporal",
			desc = "Join as a Corporal",
			team = TEAM_COP,
			group = "VP",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 1,
			model = "models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Corporal "..baseName)
			end
		},
		{
			id = "vp_sergeant",
			name = "VP Sergeant",
			desc = "Join as a Sergeant",
			team = TEAM_COP,
			group = "VP",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 2,
			model = "models/strabe/ddr2/dvp6780/polizei/service/sergeant/dvp_sergeant_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Sergeant "..baseName)
			end
		},
		{
			id = "vp_ssgt",
			name = "VP Staff Sergeant",
			desc = "Join as a Staff Sergeant",
			team = TEAM_COP,
			group = "VP",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 3,
			model = "models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Staff Sergeant "..baseName)
			end
		},
		{
			id = "vp_fstsgt",
			name = "VP Senior Sergeant",
			desc = "Join as a Senior Sergeant",
			team = TEAM_COP,
			group = "VP",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 4,
			model = "models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Senior Sergeant "..baseName)
			end
		},
		{
			id = "vp_csm",
			name = "VP Command Sergeant Major",
			desc = "Join as a Command Sergeant Major",
			team = TEAM_COP,
			group = "VP",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 5,
			model = "models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/dvp6780/polizei/service/constable/dvp_constable_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Command Sergeant Major "..baseName)
			end
		},

		{
			id = "vp_lt",
			name = "VP Lieutenant",
			desc = "Join as a Lieutenant",
			team = TEAM_COP,
			group = "VP",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 6,
			model = "models/strabe/ddr2/dvp6780/polizei/service/officer/dvp_officer_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/dvp6780/polizei/service/officer/dvp_officer_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Lieutenant "..baseName)
			end
		},
		{
			id = "vp_cpt",
			name = "VP Captain",
			desc = "Join as a Captain",
			team = TEAM_COP,
			group = "VP",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 7,
			model = "models/strabe/ddr2/dvp6780/polizei/service/officer/dvp_officer_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/dvp6780/polizei/service/officer/dvp_officer_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Captain "..baseName)
			end
		},
		{
			id = "vp_maj",
			name = "VP Major",
			desc = "Join as a Major",
			team = TEAM_COP,
			group = "VP",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 8,
			model = "models/strabe/ddr2/dvp6780/polizei/service/officer/dvp_officer_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/dvp6780/polizei/service/officer/dvp_officer_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Major "..baseName)
			end
		},
		{
			id = "vp_lcol",
			name = "VP Lieutenant Colonel",
			desc = "Join as a Lieutenant Colonel",
			team = TEAM_COP,
			group = "VP",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 8,
			model = "models/strabe/ddr2/dvp6780/polizei/service/officer/dvp_officer_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/dvp6780/polizei/service/officer/dvp_officer_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Lieutenant Colonel "..baseName)
			end
		},
		{
			id = "vp_col",
			name = "VP Colonel",
			desc = "Join as a Colonel",
			team = TEAM_COP,
			group = "VP",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 9,
			model = "models/strabe/ddr2/dvp6780/polizei/service/officer/dvp_officer_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/dvp6780/polizei/service/officer/dvp_officer_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Colonel "..baseName)
			end
		},
		{
			id = "vp_general",
			name = "VP General",
			desc = "Join as a General",
			team = TEAM_COP,
			group = "VP",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 10,
			model = "models/strabe/ddr2/dvp6780/polizei/service/general/dvp_general_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/dvp6780/polizei/service/general/dvp_general_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("General "..baseName)
			end
		},
	}
}

Monarch.RankVendors["mil_recruiter"] = {
	name = "NVA Recruiter",
	desc = "Join the NVA or advance your rank",
	model = "models/hts/comradebear/pm0v3/player/rkka/infantry/en/m43_s1_04.mdl",
	team = TEAM_MIL,
	CanBuy = function(ply, vend, r)
		return true
	end,
	ranks = {
		{
			id = "nva_offduty",
			name = "Off Duty",
			desc = "Quittin time already?",
			team = TEAM_MIL,
			group = "Military",
			grouprank = "Off Duty",
			respawn = true,
			model = "models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetBodyGroups("00000000000000")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName(baseName)
			end
		},
		{
			id = "nva_recruit",
			name = "NVA Recruit",
			desc = "Join as a Recruit",
			team = TEAM_MIL,
			group = "Military",
			grouprank = "Off Duty",
			respawn = false,
			model = "models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/nva7380/lask/shirt/enlisted/lask_enlisted_service_shirt_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Private "..baseName)
			end
		},
		{
			id = "nva_corporal",
			name = "NVA Corporal",
			desc = "Join as a Corporal",
			team = TEAM_MIL,
			group = "Military",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 1,
			model = "models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Corporal "..baseName)
			end
		},
		{
			id = "nva_sergeant",
			name = "NVA Sergeant",
			desc = "Join as a Sergeant",
			team = TEAM_MIL,
			group = "Military",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 2,
			model = "models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Sergeant "..baseName)
			end
		},
		{
			id = "nva_ssgt",
			name = "NVA Staff Sergeant",
			desc = "Join as a Staff Sergeant",
			team = TEAM_MIL,
			group = "Military",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 3,
			model = "models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Staff Sergeant "..baseName)
			end
		},
		{
			id = "nva_fstsgt",
			name = "NVA Senior Sergeant",
			desc = "Join as a Senior Sergeant",
			team = TEAM_MIL,
			group = "Military",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 4,
			model = "models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Senior Sergeant "..baseName)
			end
		},
		{
			id = "nva_csm",
			name = "NVA Command Sergeant Major",
			desc = "Join as a Command Sergeant Major",
			team = TEAM_MIL,
			group = "Military",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 5,
			model = "models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/nva7380/lask/service/enlisted/lask_enlisted_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Command Sergeant Major "..baseName)
			end
		},

		{
			id = "nva_lt",
			name = "NVA Lieutenant",
			desc = "Join as a Lieutenant",
			team = TEAM_MIL,
			group = "Military",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 6,
			model = "models/strabe/ddr2/nva7380/lask/service/officer/lask_officer_service_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/nva7380/lask/service/officer/lask_officer_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Lieutenant "..baseName)
			end
		},
		{
			id = "nva_cpt",
			name = "NVA Captain",
			desc = "Join as a Captain",
			team = TEAM_MIL,
			group = "Military",
			grouprank = "Off Duty",
			respawn = false,
			model = "models/strabe/ddr2/nva7380/lask/service/officer/lask_officer_service_04.mdl",
			whitelistLevel = 7,
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/nva7380/lask/service/officer/lask_officer_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Captain "..baseName)
			end
		},
		{
			id = "nva_maj",
			name = "NVA Major",
			desc = "Join as a Major",
			team = TEAM_MIL,
			group = "Military",
			grouprank = "Off Duty",
			respawn = false,
			model = "models/strabe/ddr2/nva7380/lask/service/officer/lask_officer_service_04.mdl",
			whitelistLevel = 8,
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/nva7380/lask/service/officer/lask_officer_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Major "..baseName)
			end
		},
		{
			id = "nva_lcol",
			name = "NVA Lieutenant Colonel",
			desc = "Join as a Lieutenant Colonel",
			team = TEAM_MIL,
			group = "Military",
			grouprank = "Off Duty",
			respawn = false,
			model = "models/strabe/ddr2/nva7380/lask/service/officer/lask_officer_service_04.mdl",
			whitelistLevel = 8,
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/nva7380/lask/service/officer/lask_officer_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Lieutenant Colonel "..baseName)
			end
		},
		{
			id = "nva_col",
			name = "NVA Colonel",
			desc = "Join as a Colonel",
			team = TEAM_MIL,
			group = "Military",
			model = "models/strabe/ddr2/nva7380/lask/service/officer/lask_officer_service_04.mdl",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 9,
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/nva7380/lask/service/officer/lask_officer_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Colonel "..baseName)
			end
		},
		{
			id = "nva_general",
			name = "NVA General",
			desc = "Join as a General",
			team = TEAM_MIL,
			group = "Military",
			grouprank = "Off Duty",
			respawn = false,
			model = "models/strabe/ddr2/nva7380/lask/service/general/lask_general_service_04.mdl",
			whitelistLevel = 10,
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/nva7380/lask/service/general/lask_general_service_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("General "..baseName)
			end
		},
	}
}

Monarch.RankVendors["stasi_recruiter"] = {
	name = "Stasi Recruiter",
	desc = "Join the Stasi or advance your rank",
	model = "models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_04.mdl",
	team = TEAM_STASI,
	CanBuy = function(ply, vend, r)
		return true
	end,
	ranks = {
		{
			id = "stasi_offduty",
			name = "Off Duty",
			desc = "Quittin time already?",
			team = TEAM_STASI,
			group = "Stasi",
			grouprank = "Off Duty",
			respawn = true,
			model = "models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetBodyGroups("00000000000000")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName(baseName)
			end
		},
		{
			id = "stasi_recruit",
			name = "Stasi Recruit",
			desc = "Join as a Recruit",
			team = TEAM_STASI,
			group = "Stasi",
			grouprank = "Off Duty",
			respawn = false,
			model = "models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Private "..baseName)
			end
		},
		{
			id = "stasi_corporal",
			name = "Stasi Corporal",
			desc = "Join as a Corporal",
			team = TEAM_STASI,
			group = "Stasi",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 1,
			model = "models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Corporal "..baseName)
			end
		},
		{
			id = "stasi_sergeant",
			name = "Stasi Sergeant",
			desc = "Join as a Sergeant",
			team = TEAM_STASI,
			group = "Stasi",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 2,
			model = "models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Sergeant "..baseName)
			end
		},
		{
			id = "stasi_ssgt",
			name = "Stasi Staff Sergeant",
			desc = "Join as a Staff Sergeant",
			team = TEAM_STASI,
			group = "Stasi",
			grouprank = "Off Duty",
			respawn = false,
			model = "models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_04.mdl",
			whitelistLevel = 3,
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Staff Sergeant "..baseName)
			end
		},
		{
			id = "stasi_fstsgt",
			name = "Stasi Senior Sergeant",
			desc = "Join as a Senior Sergeant",
			team = TEAM_STASI,
			group = "Stasi",
			model = "models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_04.mdl",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 4,
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Senior Sergeant "..baseName)
			end
		},
		{
			id = "stasi_csm",
			name = "Stasi Command Sergeant Major",
			desc = "Join as a Command Sergeant Major",
			team = TEAM_STASI,
			group = "Stasi",
			model = "models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_04.mdl",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 5,
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/stasi7482/stasi/wrfd/enlisted/stasi_enlisted_wrfd_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Command Sergeant Major "..baseName)
			end
		},

		{
			id = "stasi_lt",
			name = "Stasi Lieutenant",
			desc = "Join as a Lieutenant",
			team = TEAM_STASI,
			group = "Stasi",
			model = "models/strabe/ddr2/stasi7482/stasi/wrfd/officer/stasi_officer_wrfd_04.mdl",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 6,
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/stasi7482/stasi/wrfd/officer/stasi_officer_wrfd_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Lieutenant "..baseName)
			end
		},
		{
			id = "stasi_cpt",
			name = "Stasi Captain",
			desc = "Join as a Captain",
			team = TEAM_STASI,
			group = "Stasi",
			grouprank = "Off Duty",
			respawn = false,
			model = "models/strabe/ddr2/stasi7482/stasi/wrfd/officer/stasi_officer_wrfd_04.mdl",
			whitelistLevel = 7,
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/stasi7482/stasi/wrfd/officer/stasi_officer_wrfd_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Captain "..baseName)
			end
		},
		{
			id = "stasi_maj",
			name = "Stasi Major",
			desc = "Join as a Major",
			team = TEAM_STASI,
			group = "Stasi",
			grouprank = "Off Duty",
			model = "models/strabe/ddr2/stasi7482/stasi/wrfd/officer/stasi_officer_wrfd_04.mdl",
			respawn = false,
			whitelistLevel = 8,
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/stasi7482/stasi/wrfd/officer/stasi_officer_wrfd_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Major "..baseName)
			end
		},
		{
			id = "stasi_lcol",
			name = "Stasi Lieutenant Colonel",
			desc = "Join as a Lieutenant Colonel",
			team = TEAM_STASI,
			group = "Stasi",
			grouprank = "Off Duty",
			respawn = false,
			model = "models/strabe/ddr2/stasi7482/stasi/wrfd/officer/stasi_officer_wrfd_04.mdl",
			whitelistLevel = 8,
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/stasi7482/stasi/wrfd/officer/stasi_officer_wrfd_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Lieutenant Colonel "..baseName)
			end
		},
		{
			id = "stasi_col",
			name = "Stasi Colonel",
			desc = "Join as a Colonel",
			team = TEAM_STASI,
			group = "Stasi",
			model = "models/strabe/ddr2/stasi7482/stasi/wrfd/officer/stasi_officer_wrfd_04.mdl",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 9,
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/stasi7482/stasi/wrfd/officer/stasi_officer_wrfd_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Colonel "..baseName)
			end
		},
		{
			id = "stasi_general",
			name = "Stasi General",
			desc = "Join as a General",
			team = TEAM_STASI,
			group = "Stasi",
			model = "models/strabe/ddr2/stasi7482/stasi/dbdress/general/stasi_general_dbdress_04.mdl",
			grouprank = "Off Duty",
			respawn = false,
			whitelistLevel = 10,
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				ply:SetModel("models/strabe/ddr2/stasi7482/stasi/dbdress/general/stasi_general_dbdress_04.mdl")
				local baseName = ply:GetBaseRPName()
				ply:SetRPName("General "..baseName)
			end
		},
	}
}

Monarch.RankVendors["workforce_terminal"] = {
	name = "Workforce Terminal",
	desc = "Join the workforce.",
	model = "models/willardnetworks_custom/citizens/male07.mdl",
	team = TEAM_CITIZEN,
	CanBuy = function(ply, vend, r)
		return true
	end,
	ranks = {
		{
			id = "wrk_offduty",
			name = "Off Duty",
			desc = "Quittin time already?",
			team = TEAM_CITIZEN,
			group = "Workforce",
			grouprank = "Off Duty",
			respawn = true,
			model = "models/willardnetworks_custom/citizens/male07.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				local baseName = ply:GetBaseRPName()

				ply:SetBodygroup(0, 0)
				ply:SetBodygroup(1, 0)
				ply:SetBodygroup(2, 0)
				ply:SetBodygroup(4,0)
			end
		},
		{
			id = "wrk_worker",
			name = "Laborer",
			desc = "You are the backbone of the workforce.",
			team = TEAM_CITIZEN,
			group = "Workforce",
			grouprank = "Laborer",
			respawn = false,
			model = "models/willardnetworks_custom/citizens/male07.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")

				ply:SetBodygroup(1, 9)
				ply:SetBodygroup(2, 18)
				ply:SetBodygroup(3, 4)
				ply:SetBodygroup(5,1)
			end
		},
		{
			id = "wrk_sup",
			name = "Foreman",
			desc = "You are a foreman for the workforce.",
			team = TEAM_CITIZEN,
			group = "Workforce",
			grouprank = "Foreman",
			whitelistLevel = 1,
			respawn = false,
			model = "models/willardnetworks_custom/citizens/male07.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")

				ply:SetBodygroup(1, 9)
				ply:SetBodygroup(2, 21)
				ply:SetBodygroup(3, 4)
				ply:SetBodygroup(5,1)

				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Foreman "..baseName)
			end
		},
		{
			id = "wrk_mgr",
			name = "Shift Leader",
			desc = "You are a shift leader for the workforce.",
			team = TEAM_CITIZEN,
			group = "Workforce",
			grouprank = "Shift Leader",
			whitelistLevel = 2,
			respawn = false,
			model = "models/willardnetworks_custom/citizens/male07.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")

				ply:SetBodygroup(1, 9)
				ply:SetBodygroup(2, 21)
				ply:SetBodygroup(3, 4)
				ply:SetBodygroup(5,1)

				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Shift Leader "..baseName)
			end
		},
		{
			id = "wrk_mntr",
			name = "Plant Manager",
			desc = "You are a Plant Manager for the workforce.",
			team = TEAM_CITIZEN,
			group = "Workforce",
			grouprank = "Plant Manager",
			whitelistLevel = 3,
			respawn = false,
			model = "models/willardnetworks_custom/citizens/male07.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")

				ply:SetBodygroup(1, 0)
				ply:SetBodygroup(2, 44)
				ply:SetBodygroup(3, 9)
				ply:SetBodygroup(4,5)

				local baseName = ply:GetBaseRPName()
				ply:SetRPName("Manager "..baseName)
			end
		},
	}
}

Monarch.RankVendors["gvt_terminal"] = {
	name = "Government Official",
	desc = "Join the Government.",
	model = "models/strabe/ddr2/stasi7482/stasi/suit/suits/stasi_suit_04.mdl",
	team = TEAM_GOV,
	CanBuy = function(ply, vend, r)
		return true
	end,
	ranks = {
		{
			id = "wrk_offduty",
			name = "Off Duty",
			desc = "Quittin time already?",
			team = TEAM_GOV,
			group = "Administration",
			grouprank = "Off Duty",
			respawn = true,
			model = "models/player/Suits/male_07_open_tie.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				local baseName = ply:GetBaseRPName()
			end
		},
		{
			id = "gvt_clerk",
			name = "Clerk",
			desc = "A simple logistical clerk.",
			team = TEAM_GOV,
			group = "Administration",
			grouprank = "Clerk",
			model = "models/strabe/ddr2/stasi7482/stasi/suit/suits/stasi_suit_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				local baseName = ply:GetBaseRPName()
			end
		},
		{
			id = "gvt_secretary",
			name = "Secretary",
			desc = "A secretary for the government.",
			team = TEAM_GOV,
			group = "Administration",
			grouprank = "Secretary",
			whitelistLevel = 1,
			model = "models/strabe/ddr2/stasi7482/stasi/suit/suits/stasi_suit_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				local baseName = ply:GetBaseRPName()

				ply:SetRPName("Secretary "..baseName)
			end
		},
		{
			id = "gvt_divisioncohead",
			name = "Division Co-Head",
			desc = "A co-head for a government division.",
			team = TEAM_GOV,
			group = "Administration",
			grouprank = "Co-Head",
			whitelistLevel = 2,
			model = "models/strabe/ddr2/stasi7482/stasi/suit/suits/stasi_suit_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				local baseName = ply:GetBaseRPName()

				ply:SetRPName("Co-Head "..baseName)
			end
		},
		{
			id = "gvt_divisionhead",
			name = "Division Head",
			desc = "A head for a government division.",
			team = TEAM_GOV,
			group = "Administration",
			grouprank = "Head",
			whitelistLevel = 3,
			model = "models/strabe/ddr2/stasi7482/stasi/suit/suits/stasi_suit_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				local baseName = ply:GetBaseRPName()

				ply:SetRPName("Head "..baseName)
			end
		},
		{
			id = "gvt_coordinator",
			name = "Coordinator",
			desc = "A coordinator between the divisions of government.",
			team = TEAM_GOV,
			group = "Coordinator",
			grouprank = "Coordinator",
			whitelistLevel = 4,
			model = "models/strabe/ddr2/stasi7482/stasi/suit/suits/stasi_suit_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				local baseName = ply:GetBaseRPName()

				ply:SetRPName("Coordinator "..baseName)
			end
		},
		{
			id = "gvt_deputygovernor",
			name = "Deputy Governor",
			desc = "A deputy governor of the DDR.",
			team = TEAM_GOV,
			group = "Deputy Governor",
			grouprank = "Deputy Governor",
			whitelistLevel = 5,
			model = "models/strabe/ddr2/stasi7482/stasi/suit/suits/stasi_suit_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				local baseName = ply:GetBaseRPName()

				ply:SetRPName("Deputy Governor "..baseName)
			end
		},
		{
			id = "gvt_governor",
			name = "Governor",
			desc = "A governor of the DDR.",
			team = TEAM_GOV,
			group = "Governor",
			grouprank = "Governor",
			whitelistLevel = 6,
			model = "models/strabe/ddr2/stasi7482/stasi/suit/suits/stasi_suit_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				local baseName = ply:GetBaseRPName()

				ply:SetRPName("Governor "..baseName)
			end
		},
		{
			id = "gvt_premier",
			name = "Premier",
			desc = "The head of the Soviet Union. You have full power over all sections of the government.",
			team = TEAM_GOV,
			group = "Premier",
			grouprank = "Premier",
			whitelistLevel = 7,
			model = "models/strabe/ddr2/stasi7482/stasi/social/general/stasi_general_social_04.mdl",
			CustomCheck = function(ply, vend, r) return true end,
			onBecome = function(ply)
				if not IsValid(ply) then return end
				ply:Give("monarch_hands")
				ply:Give("monarch_keys")
				local baseName = ply:GetBaseRPName()

				ply:SetRPName("Premier "..baseName)
			end
		},
	}
}

hook.Add( "PlayerSwitchFlashlight", "Monarch.Flight", function( ply, enabled )
	return ply:HasInventoryItem("util_flight")
end )
