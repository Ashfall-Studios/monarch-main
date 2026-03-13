

Monarch.RegisterItem({

    Name = "Model 1911",
    Description = "A popular pistol. This weapon is chambered in .45 ACP and can be used for a variety of purposes.",
    UniqueID = "wep_1911",
    Model = "models/weapons/tfa_codww2/1911/w_1911_l.mdl",
    Weight = 2,
    CanStack = false,
    WeaponClass = "tfa_codww2_1911",
    Illegal = true,
    EquipGroup = "secondary_weapon",
    UseName = "Equip",
    EquipName = "Equip M1911",
    UnEquipName = "Unequip M1911",
    UseTime = 1.4,
    Workbar = "Equipping Model 1911...",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        local wepClass = def.WeaponClass
        if not wepClass then return false end

        if not ply:HasWeapon(wepClass) then
            ply:Give(wepClass)
            timer.Simple(0, function()
                if IsValid(ply) and ply:HasWeapon(wepClass) then
                    ply:SelectWeapon(wepClass)
                end
            end)
            return { equipped = true }
        else
            local active = ply:GetActiveWeapon()
            if IsValid(active) and active:GetClass() == wepClass then
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            else
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            end
        end
    end
})

Monarch.RegisterItem({

    Name = "M1A1 Thompson SMG",
    Description = "A popular SMG among soldiers and citizens alike. This weapon is chambered in .45 ACP and can be used for a variety of purposes.",
    UniqueID = "wep_m1a1",
    Model = "models/cw2/weapons/w_tac_thompson.mdl",
    Weight = 2,
    CanSell = true,
    CanStack = false,
    WeaponClass = "tfa_codww2_thompson",
    Illegal = true,
    EquipGroup = "primary_weapon",
    UseName = "Equip",
    EquipName = "Equip M1A1",
    UnEquipName = "Unequip M1A1",
    UseTime = 1.5,
    Workbar = "Equipping M1A1 Thompson...",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        local wepClass = def.WeaponClass
        if not wepClass then return false end

        if not ply:HasWeapon(wepClass) then
            ply:Give(wepClass)
            timer.Simple(0, function()
                if IsValid(ply) and ply:HasWeapon(wepClass) then
                    ply:SelectWeapon(wepClass)
                end
            end)
            return { equipped = true }
        else
            local active = ply:GetActiveWeapon()
            if IsValid(active) and active:GetClass() == wepClass then
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            else
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            end
        end
    end
})

Monarch.RegisterItem({

    Name = "SPAS-12",
    Description = "A powerful shotgun. This weapon is chambered in 12 Gauge and can be used for hunting birds, small animals, or other utility purposes.",
    UniqueID = "wep_spas12",
    Model = "models/weapons/w_iiopnshotgun.mdl",
    Weight = 2,
    CanSell = true,
    CanStack = false,
    WeaponClass = "tfa_projecthl2_spas12",
    EquipGroup = "primary_weapon",
    Illegal = true,
    UseName = "Equip",
    EquipName = "Equip SPAS-12",
    UnEquipName = "Unequip SPAS-12",
    UseTime = 1.6,
    Workbar = "Equipping SPAS-12...",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        local wepClass = def.WeaponClass
        if not wepClass then return false end

        if not ply:HasWeapon(wepClass) then
            ply:Give(wepClass)
            timer.Simple(0, function()
                if IsValid(ply) and ply:HasWeapon(wepClass) then
                    ply:SelectWeapon(wepClass)
                end
            end)
            return { equipped = true }
        else
            local active = ply:GetActiveWeapon()
            if IsValid(active) and active:GetClass() == wepClass then
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            else
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            end
        end
    end
})

Monarch.RegisterItem({

    Name = "M1 Garand",
    Description = "A powerful rifle. Used by the US military during World War 2, this weapon is chambered in .30-06 Springfield and can be used for a variety of purposes.",
    UniqueID = "wep_m1garand",
    Model = "models/weapons/w_garand.mdl",
    Weight = 2,
    CanStack = false,
    WeaponClass = "tfa_codww2_m1garand",
    Illegal = true,
    EquipGroup = "primary_weapon",
    UseName = "Equip",
    EquipName = "Equip M1 Garand",
    UnEquipName = "Unequip M1 Garand",
    UseTime = 1.7,
    Workbar = "Equipping M1 Garand...",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        local wepClass = def.WeaponClass
        if not wepClass then return false end

        if not ply:HasWeapon(wepClass) then
            ply:Give(wepClass)
            timer.Simple(0, function()
                if IsValid(ply) and ply:HasWeapon(wepClass) then
                    ply:SelectWeapon(wepClass)
                end
            end)
            return { equipped = true }
        else
            local active = ply:GetActiveWeapon()
            if IsValid(active) and active:GetClass() == wepClass then
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            else
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            end
        end
    end
})

Monarch.RegisterItem({

    Name = "Crowbar",
    Description = "A useful melee utility.",
    UniqueID = "wep_melee_crowbar",
    Model = "models/weapons/w_crowbar.mdl",
    Weight = 2,
    Illegal = true,
    CanStack = false,
    WeaponClass = "tfa_projecthl2_crowbar",
    EquipGroup = "utility",
    UseName = "Equip",
    EquipName = "Equip Crowbar",
    UnEquipName = "Unequip Crowbar",
    UseTime = 1.2,
    Workbar = "Equipping Crowbar...",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        local wepClass = def.WeaponClass
        if not wepClass then return false end

        if not ply:HasWeapon(wepClass) then
            ply:Give(wepClass)
            timer.Simple(0, function()
                if IsValid(ply) and ply:HasWeapon(wepClass) then
                    ply:SelectWeapon(wepClass)
                end
            end)
            return { equipped = true }
        else
            local active = ply:GetActiveWeapon()
            if IsValid(active) and active:GetClass() == wepClass then
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            else
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            end
        end
    end
})

Monarch.RegisterItem({

    Name = "AK-107",
    Description = "A powerful assault rifle. This weapon is chambered in 7.62x39mm and was built for durability and reliability in harsh conditions.",
    UniqueID = "wep_ak107",
    Model = "models/weapons/w_bocw_ak47.mdl",
    Weight = 2,
    CanStack = false,
    WeaponClass = "tfa_ins2_ak103",
    Illegal = true,
    EquipGroup = "primary",
    UseName = "Equip",
    EquipName = "Equip AK-107",
    UnEquipName = "Unequip AK-107",
    UseTime = 1.6,
    Workbar = "Equipping AK-107...",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        local wepClass = def.WeaponClass
        if not wepClass then return false end

        if not ply:HasWeapon(wepClass) then
            ply:Give(wepClass)
            timer.Simple(0, function()
                if IsValid(ply) and ply:HasWeapon(wepClass) then
                    ply:SelectWeapon(wepClass)
                end
            end)
            return { equipped = true }
        else
            local active = ply:GetActiveWeapon()
            if IsValid(active) and active:GetClass() == wepClass then
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            else
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            end
        end
    end
})

Monarch.RegisterItem({

    Name = "SVT-40",
    Description = "A powerful battle rifle. This weapon was built for durability and reliability in harsh conditions during World War 2.",
    UniqueID = "wep_svt40",
    Model = "models/weapons/tfa_codww2/svt40/w_svt40_stock.mdl",
    Weight = 2,
    CanStack = false,
    WeaponClass = "tfa_codww2_svt40",
    Illegal = true,
    EquipGroup = "primary",
    UseName = "Equip",
    EquipName = "Equip SVT-40",
    UnEquipName = "Unequip SVT-40",
    UseTime = 1.6,
    Workbar = "Equipping SVT-40...",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        local wepClass = def.WeaponClass
        if not wepClass then return false end

        if not ply:HasWeapon(wepClass) then
            ply:Give(wepClass)
            timer.Simple(0, function()
                if IsValid(ply) and ply:HasWeapon(wepClass) then
                    ply:SelectWeapon(wepClass)
                end
            end)
            return { equipped = true }
        else
            local active = ply:GetActiveWeapon()
            if IsValid(active) and active:GetClass() == wepClass then
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            else
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            end
        end
    end
})

Monarch.RegisterItem({

    Name = "Makarov PM",
    Description = "A simple pistol used by the Russian military during World War 2.",
    UniqueID = "wep_pm",
    Model = "models/weapons/tfa_ins2/c_pm.mdl",
    Weight = 2,
    CanStack = false,
    WeaponClass = "tfa_ins2_pm",
    Illegal = true,
    EquipGroup = "secondary",
    UseName = "Equip",
    EquipName = "Equip Makarov",
    UnEquipName = "Unequip Makarov",
    UseTime = 1.3,
    Workbar = "Equipping Makarov...",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        local wepClass = def.WeaponClass
        if not wepClass then return false end

        if not ply:HasWeapon(wepClass) then
            ply:Give(wepClass)
            timer.Simple(0, function()
                if IsValid(ply) and ply:HasWeapon(wepClass) then
                    ply:SelectWeapon(wepClass)
                end
            end)
            return { equipped = true }
        else
            local active = ply:GetActiveWeapon()
            if IsValid(active) and active:GetClass() == wepClass then
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            else
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            end
        end
    end
})

Monarch.RegisterItem({

    Name = "Revolver",
    Description = "A simple revolver. This weapon is chambered in .357 Magnum and is a great choice for a sidearm. Especially in situations where reliability is key.",
    UniqueID = "wep_rev",
    Model = "models/weapons/w_ins2_revolver_mr96.mdl",
    Weight = 2,
    CanStack = false,
    WeaponClass = "tfa_ins2_mr96",
    Illegal = true,
    EquipGroup = "secondary",
    UseName = "Equip",
    EquipName = "Equip Revolver",
    UnEquipName = "Unequip Revolver",
    UseTime = 1.4,
    Workbar = "Equipping Revolver...",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        local wepClass = def.WeaponClass
        if not wepClass then return false end

        if not ply:HasWeapon(wepClass) then
            ply:Give(wepClass)
            timer.Simple(0, function()
                if IsValid(ply) and ply:HasWeapon(wepClass) then
                    ply:SelectWeapon(wepClass)
                end
            end)
            return { equipped = true }
        else
            local active = ply:GetActiveWeapon()
            if IsValid(active) and active:GetClass() == wepClass then
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            else
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            end
        end
    end
})

Monarch.RegisterItem({

    Name = "PPSH-41",
    Description = "A simple rapid fire SMG used by the Russian military during World War 2.",
    UniqueID = "wep_ppsh",
    Model = "models/weapons/tfa_codww2/ppsh41/w_ppsh41_stock.mdl",
    Weight = 2,
    CanStack = false,
    WeaponClass = "tfa_codww2_ppsh41",
    Illegal = true,
    EquipGroup = "primary",
    UseName = "Equip",
    EquipName = "Equip PPSH-41",
    UnEquipName = "Unequip PPSH-41",
    UseTime = 1.5,
    Workbar = "Equipping PPSH-41...",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        local wepClass = def.WeaponClass
        if not wepClass then return false end

        if not ply:HasWeapon(wepClass) then
            ply:Give(wepClass)
            timer.Simple(0, function()
                if IsValid(ply) and ply:HasWeapon(wepClass) then
                    ply:SelectWeapon(wepClass)
                end
            end)
            return { equipped = true }
        else
            local active = ply:GetActiveWeapon()
            if IsValid(active) and active:GetClass() == wepClass then
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            else
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            end
        end
    end
})

Monarch.RegisterItem({

    Name = "Mk2 Frag Grenade",
    Description = "A standard issue fragmentation grenade.",
    UniqueID = "wep_throw_grenade",
    Model = "models/weapons/w_eq_fraggrenade_thrown.mdl",
    Weight = 2,
    CanStack = false,
    ShouldRemoveOnEquip = true,
    WeaponClass = "tfa_codww2_usa_frag",
    EquipGroup = "tool",
    Illegal = true,
    UseName = "Equip",
    EquipName = "Equip Mk2 Frag Grenade",
    UnEquipName = "Unequip Mk2 Frag Grenade",
    UseTime = 1.2,
    Workbar = "Equipping Mk2 Frag Grenade...",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        local wepClass = def.WeaponClass
        if not wepClass then return false end

        if not ply:HasWeapon(wepClass) then
            ply:Give(wepClass)
            timer.Simple(0, function()
                if IsValid(ply) and ply:HasWeapon(wepClass) then
                    ply:SelectWeapon(wepClass)
                end
            end)
            return { equipped = true, remove = true }
        else
            local active = ply:GetActiveWeapon()
            if IsValid(active) and active:GetClass() == wepClass then
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            else
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            end
        end
    end
})

Monarch.RegisterItem({

    Name = "Lead Pipe",
    Description = "A long piece of metal pipe. Not very durable however it can be used as a weapon in the most dire of circumstances.",
    UniqueID = "wep_melee_pipe",
    Model = "models/props_canal/mattpipe.mdl",
    Weight = 2,
    CanStack = false,
    ShouldRemoveOnEquip = true,
    WeaponClass = "tfa_melee_pipe",
    EquipGroup = "utility",
    Illegal = true,
    UseName = "Equip",
    EquipName = "Equip lead pipe",
    UnEquipName = "Unequip lead pipe",
    UseTime = 1.2,
    Workbar = "Equipping lead pipe...",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        local wepClass = def.WeaponClass
        if not wepClass then return false end

        if not ply:HasWeapon(wepClass) then
            ply:Give(wepClass)
            timer.Simple(0, function()
                if IsValid(ply) and ply:HasWeapon(wepClass) then
                    ply:SelectWeapon(wepClass)
                end
            end)
            return { equipped = true, remove = true }
        else
            local active = ply:GetActiveWeapon()
            if IsValid(active) and active:GetClass() == wepClass then
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            else
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            end
        end
    end
})

Monarch.RegisterItem({

    Name = "Ration",
    Description = "A barebones meal. Given to citizens for sustenance.",
    UniqueID = "food_ration",
    Model = "models/hls/alyxports/cardboard_box_3.mdl",
    Weight = 2,
    CanSell = true,
    CanStack = false,
    Stats = "<color=156, 145, 112>1 Bread</color>\n<color=112, 145, 156>1 Water Can</color>",
    UseTime = 2,
    Workbar = "Opening Rations",
    UseName = "Open Ration Package",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:GiveInventoryItem("food_bread", 1)
        ply:GiveInventoryItem("food_watercan", 1)
        ply:EmitSound("willardnetworks/inventory/inv_bandage.wav")

        return { remove = true }
    end
})

Monarch.RegisterItem({

    Name = "Bandage",
    Description = "A basic bandage for treating wounds.",
    UniqueID = "med_bandage",
    Model = "models/willardnetworks/skills/stitched_cloth.mdl",
    Weight = 1,
    CanSell = true,
    CanStack = true,
    Stats = "<color=255, 126, 112>+ Stops Bleeding</color>",
    UseName = "Apply Bandage",
    UseTime = 1.2,
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:EmitSound("willardnetworks/inventory/inv_bandage.wav")
        ply:SetBleeding(false)

        return { remove = true }
    end
})

Monarch.RegisterItem({

    Name = "Medkit",
    Description = "A medical kit for treating wounds.",
    UniqueID = "med_medkit",
    Illegal = true,
    Model = "models/willardnetworks/skills/surgicalkit.mdl",
    Weight = 1,
    CanSell = true,
    Illegal = true,
    CanStack = true,
    Stats = "<color=255, 126, 112>+ Health</color>\n<color=255, 126, 112>+ Stops Bleeding</color>",
    UseName = "Use Medkit",
    UseTime = 3,
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:EmitSound("willardnetworks/inventory/inv_bandage.wav")
        ply:SetBleeding(false)
        local amount = math.random(25, 70)
        ply:SetHealth(math.min(ply:Health() + amount, ply:GetMaxHealth()))

        return { remove = true }
    end
})

Monarch.RegisterItem({

    Name = "Pills",
    Description = "A small vial containing helpful pills.",
    UniqueID = "med_pills",
    CanSell = true,
    Model = "models/synapse/misc_props/synapse_medicine_bottles_2.mdl",
    Illegal = true,
    Stats = "<color=255, 126, 112>+ Health</color>",
    Weight = 1,
    CanStack = false,
    UseName = "Use Pills",
    UseTime = 1,
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:EmitSound("needs/bottle/take_pills.wav")
        local amount = math.random(10, 15)
        ply:SetHealth(math.min(ply:Health() + amount, ply:GetMaxHealth()))

        return { remove = true }
    end
})

Monarch.RegisterItem({

    Name = "Bread",
    Description = "A stale loaf of bread. Not very appetizing, but it'll do in a pinch.",
    UniqueID = "food_bread",
    CanSell = true,
    Model = "models/willardnetworks/food/wn_food_loaf.mdl",
    Weight = 2,
    UseTime = 0.5,
    CanStack = true,
        Stats = "<color=156, 145, 112>+ Hunger</color>\n<color=147, 181, 178>+ Exhaustion</color>\n",
    UseName = "Consume",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetHunger(math.Clamp(ply:GetHunger() + 10, 0, 100))
        ply:SetExhaustion(math.Clamp(ply:GetExhaustion() + 5, 0, 100))
        ply:EmitSound("needs/hunger_eat_0"..math.random(1,5)..".wav")

        return { remove = true }
    end
})

Monarch.RegisterItem({

    Name = "Water Can",
    Description = "A can of rather disgusting water. I would not drink this too often.",
    UniqueID = "food_watercan",
    CanSell = true,
    Model = "models/willardnetworks/food/wn_food_can.mdl",
    Stats = [[<color=112, 145, 156>+ Hydration</color>]],
    Weight = 0,
    UseTime = 0.2,
    CanStack = true,
    UseName = "Consume",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetHydration(math.Clamp(ply:GetHydration() + 7, 0, 100))
        ply:EmitSound("needs/thrist_drink_0"..math.random(1,5)..".wav")
        ply:GiveInventoryItem("food_emptywatercan", 1)

        return { remove = true }
    end
})

Monarch.RegisterItem({
    Name = "P.I.C Card",
    Description = "A card for Identification purposes. It would be wise to keep this on you at all times.",
    UniqueID = "util_idcard",
    CanSell = false,
    restricted = true,
    illegal = false,
    Model = "models/willardnetworks/gearsofindustry/wn_data_card.mdl",
    Weight = 0,
    Stats = "<color=200, 200, 100>Restricted</color>",
    Locked = true,
    UseName = "View/Show ID",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        local char = ply.MonarchActiveChar or {}
        local name = (ply.GetRPName and ply:GetRPName()) or char.name or ply:Nick()
        local steamid = ply:SteamID() or "Unknown"
        local charid = tonumber(char.id or 0) or 0
        local occupation = (ply.GetTeamName and ply:GetTeamName()) or (char.team and Monarch.Team[char.team] and Monarch.Team[char.team].name) or team.GetName(ply:Team()) or "Unknown"
        local health = ply:Health() or 0

        local height = (char.height or ply:GetNWString("CharHeight", "Unknown"))
        local weight = (char.weight or ply:GetNWString("CharWeight", "Unknown"))
        local hair   = (char.haircolor or ply:GetNWString("CharHairColor", "Unknown"))
        local eye    = (char.eyecolor or ply:GetNWString("CharEyeColor", "Unknown"))
        local age    = (char.age or ply:GetNWInt("CharAge", 0))

        local loyaltyTier = 50
        local partyTier = 0
        if Monarch.Loyalty and Monarch.Loyalty.GetPlayerData then
            local loyaltyData = Monarch.Loyalty.GetPlayerData(ply) or {}
            loyaltyTier = loyaltyData.loyalty_points or 50
            partyTier = loyaltyData.party_tier or 0
        end

        local tr = ply:GetEyeTrace()
        if tr and IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity ~= ply and ply:GetPos():DistToSqr(tr.Entity:GetPos()) <= (200*200) then
            targPly = tr.Entity

            ply:Notify("You present your ID to "..(targPly:GetRPName() or targPly:Nick())..". \n\n Name: "..(ply:GetRPName() or ply:Nick())..".\n ID#: "..charid.."\n".."Occupation: "..occupation.."\n".. 
            "Height: "..height.."\n".."Weight: "..weight.."\n".."Hair Color: "..hair.."\n".."Eye Color: "..eye.."\n".."Age: "..age.."\n".."Loyalty Tier: "..loyaltyTier.."\n".."Party Membership: "..partyTier.."\n", 9) 

            targPly:Notify(ply:GetRPName() .. " presents their ID. \n\n Name: "..(ply:GetRPName() or ply:Nick())..".\n ID#: "..charid.."\n".."Occupation: "..occupation.."\n".. 
            "Height: "..height.."\n".."Weight: "..weight.."\n".."Hair Color: "..hair.."\n".."Eye Color: "..eye.."\n".."Age: "..age.."\n".."Loyalty Tier: "..loyaltyTier.."\n".."Party Membership: "..partyTier.."\n", 9) 
        else
            ply:Notify("You view your ID.\n\n Name: "..(ply:GetRPName() or ply:Nick())..".\n ID#: "..charid.."\n".."Occupation: "..occupation.."\n".. 
            "Height: "..height.."\n".."Weight: "..weight.."\n".."Hair Color: "..hair.."\n".."Eye Color: "..eye.."\n".."Age: "..age.."\n".."Loyalty Tier: "..loyaltyTier.."\n".."Party Membership: "..partyTier.."\n", 9) 
        end

        return false 
    end
})

Monarch.RegisterItem({

    Name = "Dirty Water Bottle",
    Description = "A bottle of dirty water. It is not particularly safe for drinking.",
    UniqueID = "food_dirtywater",
    CanSell = true,
    Model = "models/hls/alyxports/beer_bottle_1.mdl",
    Stats = "<color=112, 145, 156>+ Hydration</color>\n<color=255, 126, 112>- Possible Health Loss</color>",
    Weight = 0,
    UseTime = 0.2,
    CanStack = true,
    UseName = "Drink",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetHydration(math.Clamp(ply:GetHydration() + 5, 0, 100))
        ply:EmitSound("needs/thrist_drink_0"..math.random(1,5)..".wav")
        local chance = math.random(1, 100)

        ply:GiveInventoryItem("food_emptywaterbottle", 1)

        if chance <= 10 then
            ply:SetHealth(math.min(ply:Health() - math.random(1,8), ply:GetMaxHealth()))
            ply:EmitSound("impulse_redux/misc/tc_breathing.wav")
            ply:EmitSound("player/pl_pain6.wav")
        end

        return { remove = true }
    end
})

Monarch.RegisterItem({

    Name = "Empty Bottle",
    Description = "An empty bottle. You can refill this at a water source.",
    UniqueID = "food_emptywaterbottle",
    Model = "models/hls/alyxports/beer_bottle_empty.mdl",
    Weight = 0,
    Dismantle = {"mat_glass"},
    DismantleTime = 2,
    DismantleSound = "foley/inventory/inv_move6.mp3",
    Stats = [[Fillable near a sink]],
    Dismantle = {"mat_glass"},
    DismantleTime = 2,
    UseTime = 0.2,
    CanStack = true,
    UseName = "Fill",
    CanUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        local tr = ply:GetEyeTrace()
        if not tr or not IsValid(tr.Entity) then return false end
        local ent = tr.Entity
        if ent:GetClass() ~= "rp_sink" then return false end
        if ent:GetPos():DistToSqr(ply:GetPos()) > (130*130) then return false else return true end
    end,
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:GiveInventoryItem("food_dirtywater", 1)
        return { remove = true }
    end
})

local shirts = {
    "cos_darkshirt",
    "cos_flannelshirt",
    "cos_scoat",
    "cos_tanshirt"
}

Monarch.RegisterItem({
    Name = "Empty Suitcase",
    Description = "An empty suitcase. You brought this with you from the train. You could probably destroy this and obtain some materials",
    UniqueID = "util_empty_suitcase",
    Model = "models/props_c17/SuitCase_Passenger_Physics.mdl",
    Weight = 0,
    UseTime = 0.2,
    CanStack = true,
    Dismantle = {"mat_wood", "mat_screws", "mat_metal", "mat_leather", "mat_leather", "mat_leather"},
})

Monarch.RegisterItem({
    Name = "Suitcase",
    Description = "A suitcase. You brought this with you from the train. Perhaps you brought some stuff you can make use of?",
    UniqueID = "util_suitcase",
    Model = "models/props_c17/SuitCase_Passenger_Physics.mdl",
    Weight = 0,
    Stats = [[Contains a few useful starter items.]],
    UseTime = 0.2,
    WeaponClass = "weapon_suitcase",
    CanStack = true,
    Dismantle = {"util_payroll_check", "food_ration", "util_idcard", "cos_bpants", "cos_boots", shirts[math.random(1,#shirts)], "util_empty_suitcase"},
    UseName = "Carry Suitcase",
    UseTime = 2,
    Workbar = "Carrying suitcase...",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        local wepClass = def.WeaponClass
        if not wepClass then return false end

        if not ply:HasWeapon(wepClass) then
            ply:Give(wepClass)
            timer.Simple(0, function()
                if IsValid(ply) and ply:HasWeapon(wepClass) then
                    ply:SelectWeapon(wepClass)
                end
            end)
            return { equipped = true, remove = true }
        else
            local active = ply:GetActiveWeapon()
            if IsValid(active) and active:GetClass() == wepClass then
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            else
                ply:StripWeapon(wepClass)
                return { unequipped = true }
            end
        end
    end
})

Monarch.RegisterItem({
    Name = "Dark Shirt",
    Description = "A simple dark shirt. This doesn't offer much protection but it does offer some style for your outwear.",
    UniqueID = "cos_darkshirt",
    Model = "models/willardnetworks/clothingitems/torso_alyxcoat4.mdl",
    Weight = 2,
    CanStack = false,
    EquipGroup = "torso",
    Illegal = false,
    EquipName = "Wear shirt",
    UseTime = 1.2,
    Workbar = "Equipping Shirt...",
    UnEquipName = "Remove shirt",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(2, 15)
        return { equipped = true, unequipped = false }
    end,

    OnRemove = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(2, 0)
        return { unequipped = true }
    end
})

Monarch.RegisterItem({
    Name = "Flannel Shirt",
    Description = "A simple flannel shirt. This will offer some protection against the elements and offers some style for your outwear.",
    UniqueID = "cos_flannelshirt",
    Model = "models/willardnetworks/clothingitems/torso_alyxcoat6.mdl",
    Weight = 2,
    CanStack = false,
    EquipGroup = "torso",
    Illegal = false,
    EquipName = "Wear shirt",
    UseTime = 1.2,
    Workbar = "Equipping Shirt...",
    UnEquipName = "Remove shirt",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(2, 20)
        return { equipped = true, unequipped = false }
    end,

    OnRemove = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(2, 0)
        return { unequipped = true }
    end
})

Monarch.RegisterItem({
    Name = "Coat",
    Description = "A simple coat made from blue, white, and yellow Polyester. This will offer some protection against the elements and offers some style for your outwear.",
    UniqueID = "cos_scoat",
    Model = "models/willardnetworks/clothingitems/torso_alyxcoat9.mdl",
    Weight = 2,
    CanStack = false,
    EquipGroup = "torso",
    Illegal = false,
    EquipName = "Wear coat",
    UseTime = 1.2,
    Workbar = "Equipping Coat...",
    UnEquipName = "Remove coat",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(2, 26)
        return { equipped = true, unequipped = false }
    end,

    OnRemove = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(2, 0)
        return { unequipped = true }
    end
})

Monarch.RegisterItem({
    Name = "Tan Shirt",
    Description = "A tan shirt. This doesn't offer much protection, however it offers some style to your wardrobe.",
    UniqueID = "cos_tanshirt",
    Model = "models/willardnetworks/clothingitems/torso_citizen2.mdl",
    Weight = 2,
    CanStack = false,
    EquipGroup = "torso",
    Illegal = false,
    EquipName = "Wear shirt",
    UseTime = 1.2,
    Workbar = "Equipping Tan Shirt...",
    UnEquipName = "Remove shirt",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(2, 2)
        return { equipped = true, unequipped = false }
    end,

    OnRemove = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(2, 0)
        return { unequipped = true }
    end
})

Monarch.RegisterItem({

    Name = "Empty Can",
    Description = "An Empty Can. You can refill this at a water source.",
    UniqueID = "food_emptywatercan",
    Model = "models/willardnetworks/food/wn_food_can.mdl",
    Weight = 0,
    Stats = [[Fillable near a sink.]],
    Dismantle = {"mat_lead"},
    DismantleTime = 2,
    UseTime = 0.2,
    CanStack = true,
    UseName = "Fill",
    CanUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        local tr = ply:GetEyeTrace()
        if not tr or not IsValid(tr.Entity) then return false end
        local ent = tr.Entity
        if ent:GetClass() ~= "rp_sink" then return false end
        if ent:GetPos():DistToSqr(ply:GetPos()) > (130*130) then return false else return true end
    end,
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:GiveInventoryItem("food_watercan", 1)
        return { remove = true }
    end
})

Monarch.RegisterItem({

    Name = "Screws",
    Description = "A small container of screws.",
    UniqueID = "mat_screws",
    Model = "models/mosi/fallout4/props/junk/components/screws.mdl",
    Weight = 0.1,
    UseTime = 0.2,
    CanStack = true,
})

Monarch.RegisterItem({

    Name = "Flour",
    Description = "A small bag of flour.",
    UniqueID = "gen_flour",
    Model = "models/hls/hawke/bag_flour_1.mdl",
    Weight = 0.1,
    UseTime = 0.2,
    CanStack = true,
})

Monarch.RegisterItem({

    Name = "Lead",
    Description = "A small ingot of lead.",
    UniqueID = "mat_lead",
    Illegal = true,
    Model = "models/mosi/fallout4/props/junk/components/lead.mdl",
    Weight = 0.1,
    UseTime = 0.2,
    CanStack = true,
})

Monarch.RegisterItem({

    Name = "Glass",
    Description = "A small shard of glass.",
    UniqueID = "mat_glass",
    Illegal = true,
    Model = "models/mosi/fallout4/props/junk/components/glass.mdl",
    Weight = 0.1,
    UseTime = 0.2,
    CanStack = true,
})

Monarch.RegisterItem({

    Name = "Springs",
    Description = "A small container of springs.",
    UniqueID = "mat_springs",
    Model = "models/mosi/fallout4/props/junk/components/springs.mdl",
    Weight = 0.1,
    UseTime = 0.2,
    CanStack = true,
})

Monarch.RegisterItem({

    Name = "Adhesive",
    Description = "A small bottle of adhesive.",
    UniqueID = "mat_adhesive",
    Model = "models/mosi/fallout4/props/junk/components/adhesive.mdl",
    Weight = 0.1,
    UseTime = 0.2,
    CanStack = true,
})

Monarch.RegisterItem({

    Name = "Cloth",
    Description = "A small roll of cloth.",
    UniqueID = "mat_cloth",
    Model = "models/mosi/fallout4/props/junk/components/cloth.mdl",
    Weight = 0.1,
    UseTime = 0.2,
    CanStack = true,
})

Monarch.RegisterItem({

    Name = "Wood",
    Description = "A small pile of wood.",
    UniqueID = "mat_wood",
    Model = "models/mosi/fallout4/props/junk/components/wood.mdl",
    Weight = 0.1,
    UseTime = 0.2,
    CanStack = true,
})

Monarch.RegisterItem({

    Name = "Duct Tape",
    Description = "A roll of duct tape.",
    UniqueID = "mat_duct_tape",
    Model = "models/mosi/fallout4/props/junk/ducttape.mdl",
    Weight = 0.1,
    UseTime = 0.2,
    CanStack = true,
})

Monarch.RegisterItem({

    Name = "Leather",
    Description = "A small roll of leather.",
    UniqueID = "mat_leather",
    Model = "models/mosi/fallout4/props/junk/components/leather.mdl",
    Weight = 0.1,
    UseTime = 0.2,
    CanStack = true,
})

Monarch.RegisterItem({

    Name = "Coins",
    Description = "A small pile of coins.",
    UniqueID = "mat_coins",
    Model = "models/currency/credits/goldcoins.mdl",
    Dismantle = { "mat_lead" },
    Weight = 0.1,
    UseTime = 0.2,
    CanStack = true,
})

Monarch.RegisterItem({

    Name = "Sleeping Bag",
    Description = "A portable sleeping bag. This is useful for survival in the wild but it is not very comfortable.",
    UniqueID = "util_sleepingbag",
    Model = "models/props_equipment/sleeping_bag2.mdl",
    Weight = 2,
    CanStack = false,
    Illegal = false,
    UseTime = 8,
    Workbar = "Placing Sleeping Bag...",
    UseName = "Place Sleeping Bag",
    EquipName = "Place Sleeping Bag",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end

        local tr = ply:GetEyeTrace()
        if tr.Hit and tr.HitPos:Distance(ply:GetPos()) <= 100 then
            local ang = ply:EyeAngles()
            ang.p = 0
            ang.r = 0
            ang.y = (ang.y + 180) % 360

            local ent = ents.Create("rp_sleepingbag")
            if IsValid(ent) then
                ent:SetPos(tr.HitPos + tr.HitNormal * 18)
                ent:SetAngles(ang)
                ent:Spawn()
                ent:Activate()

                return { remove = true }
            end
        end

        return false
    end
})

Monarch.RegisterItem({

    Name = "Refugee Coat",
    Description = "A warm coat suitable for a refugee.",
    UniqueID = "cos_refugeeCoat",
    Model = "models/willardnetworks/clothingitems/torso_refugee_coat.mdl",
    Weight = 2,
    CanStack = false,
    EquipGroup = "chest",
    Illegal = false,
    EquipName = "Wear coat",
    UseTime = 1.2,
    Workbar = "Equipping Refugee Coat...",
    UnEquipName = "Remove Coat",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(2, 14)
        return { equipped = true, unequipped = false }
    end,

    OnRemove = function(ply, slot, itemData, def)
        if not IsValid(ply) then return end
        ply:SetBodygroup(2, 0)
        return { unequipped = true }
    end
})

Monarch.RegisterItem({

    Name = "Military Cap",
    Description = "A warm cap used by a former military. This can be used to keep your head warm and dry.",
    UniqueID = "cos_milhat",
    Model = "models/willardnetworks/clothingitems/head_confederatehat.mdl",
    Weight = 2,
    Illegal = true,
    CanStack = false,
    EquipGroup = "head",
    Illegal = false,
    EquipName = "Wear cap",
    UseTime = 1.2,
    Workbar = "Equipping Military Cap...",
    UnEquipName = "Remove cap",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(1, 6)
        return { equipped = true, unequipped = false }
    end,

    OnRemove = function(ply, slot, itemData, def)
        if not IsValid(ply) then return end
        ply:SetBodygroup(1, 0)
        return { unequipped = true }
    end
})

Monarch.RegisterItem({

    Name = "Brown Boots",
    Description = "A pair of sturdy boots used by a former military. These can be used to keep your feet warm and dry.",
    UniqueID = "cos_boots",
    Model = "models/willardnetworks/clothingitems/shoes_military.mdl",
    Weight = 2,
    Illegal = true,
    CanStack = false,
    EquipGroup = "feet",
    Illegal = false,
    EquipName = "Wear boots",
    UseTime = 1.2,
    Workbar = "Equipping Brown Boots...",
    UnEquipName = "Remove boots",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(4, 3)
        return { equipped = true, unequipped = false }
    end,

    OnRemove = function(ply, slot, itemData, def)
        if not IsValid(ply) then return end
        ply:SetBodygroup(4, 0)
        return { unequipped = true }
    end
})

Monarch.RegisterItem({

    Name = "Heavy Duty Vest",
    Description = "A sturdy vest used by the rebels. This can be used to keep your torso warm.",
    UniqueID = "cos_vest",
    Model = "models/willardnetworks/clothingitems/torso_rebel_torso_1.mdl",
    Weight = 2,
    Illegal = true,
    CanStack = false,
    EquipGroup = "torso",
    EquipName = "Wear vest",
    UseTime = 1.3,
    Workbar = "Equipping Heavy Duty Vest...",
    UnEquipName = "Remove vest",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(2, 8)
        return { equipped = true, unequipped = false }
    end,

    OnRemove = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(2, 0)
        return { unequipped = true }
    end
})

Monarch.RegisterItem({

    Name = "Heavy Duty Pants",
    Description = "A sturdy pair of pants used by the rebels. This can be used to keep your legs warm.",
    UniqueID = "cos_heavypants",
    Model = "models/willardnetworks/clothingitems/legs_rebel1.mdl",
    Weight = 2,
    CanStack = false,
    EquipGroup = "legs",
    Illegal = true,
    EquipName = "Wear pants",
    UseTime = 1.2,
    Workbar = "Equipping Heavy Duty Pants...",
    UnEquipName = "Remove pants",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(3, 7)
        return { equipped = true, unequipped = false }
    end,

    OnRemove = function(ply, slot, itemData, def)
        if not IsValid(ply) then return end
        ply:SetBodygroup(3, 0)
        return { unequipped = true }
    end
})

Monarch.RegisterItem({

    Name = "Heavy Duty Gas Mask",
    Description = "A old gas mask. This can be used to protect your face from harmful substances.",
    UniqueID = "cos_gasmask",
    Model = "models/willardnetworks/clothingitems/head_gasmask.mdl",
    Weight = 2,
    CanSell = true,
    CanStack = false,
    EquipGroup = "face",
    Illegal = true,
    Stats = [[+ No Gas damage]],
    EquipName = "Wear gas mask",
    UseTime = 1.4,
    Workbar = "Equipping Gas Mask...",
    UnEquipName = "Remove gas mask",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(9, 2)
        ply.HasGasMask = true
        if ply.SetNWBool then ply:SetNWBool("MonarchHasGasMask", true) end
        return { equipped = true, unequipped = false }
    end,

    OnRemove = function(ply, slot, itemData, def)
        if not IsValid(ply) then return end
        ply:SetBodygroup(9, 0)
        ply.HasGasMask = false
        if ply.SetNWBool then ply:SetNWBool("MonarchHasGasMask", false) end
        return { unequipped = true }
    end
})

Monarch.RegisterItem({

    Name = "Military Helmet",
    Description = "An heavy duty helmet designed for protection.",
    UniqueID = "cos_m3helm",
    Model = "models/willardnetworks/clothingitems/head_helmet.mdl",
    Weight = 2,
    CanSell = true,
    CanStack = false,
    EquipGroup = "head",
    Illegal = true,
    EquipName = "Wear helmet",
    UseTime = 1.3,
    Workbar = "Equipping Military Helmet...",
    UnEquipName = "Remove helmet",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(1, 4)
        return { equipped = true, unequipped = false }
    end,

    OnRemove = function(ply, slot, itemData, def)
        if not IsValid(ply) then return end
        ply:SetBodygroup(1, 0)
        return { unequipped = true }
    end
})

Monarch.RegisterItem({

    Name = "Black Pants",
    Description = "A black pair of pants. This can be used to keep your legs warm.",
    UniqueID = "cos_bpants",
    Model = "models/willardnetworks/clothingitems/legs_citizen4.mdl",
    Weight = 2,
    CanStack = false,
    EquipGroup = "legs",
    Illegal = false,
    EquipName = "Wear pants",
    UseTime = 1.2,
    Workbar = "Equipping Black Pants...",
    UnEquipName = "Remove pants",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(3, 9)
        return { equipped = true, unequipped = false }
    end,

    OnRemove = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(3, 0)
        return { unequipped = true }
    end
})

Monarch.RegisterItem({

    Name = "Winter Jacket",
    Description = "A warm winter jacket. This can be used to keep you warm.",
    UniqueID = "cos_winterjacket",
    Model = "models/willardnetworks/update_items/cajacket2_item.mdl",
    Weight = 2,
    CanStack = false,
    EquipGroup = "torso",
    Illegal = false,
    EquipName = "Wear jacket",
    UseTime = 1.3,
    Workbar = "Equipping Winter Jacket...",
    UnEquipName = "Remove jacket",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(2, 44)
        return { equipped = true, unequipped = false }
    end,

    OnRemove = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(2, 0)
        return { unequipped = true }
    end
})

Monarch.RegisterItem({

    Name = "Formal Shoes",
    Description = "A pair of formal shoes. This can be used to complete your outfit.",
    UniqueID = "cos_formalshoes",
    Model = "models/willardnetworks/clothingitems/shoes_formal.mdl",
    Weight = 2,
    CanStack = false,
    EquipGroup = "shoes",
    Illegal = false,
    EquipName = "Wear shoes",
    UseTime = 1.2,
    Workbar = "Equipping Formal Shoes...",
    UnEquipName = "Remove shoes",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(4, 5)
        return { equipped = true, unequipped = false }
    end,

    OnRemove = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(4, 0)
        return { unequipped = true }
    end
})

Monarch.RegisterItem({

    Name = "Fedora",
    Description = "A stylish fedora hat.",
    UniqueID = "cos_fedora",
    Model = "models/willardnetworks/update_items/fedora_item.mdl",
    Weight = 2,
    CanStack = false,
    EquipGroup = "head",
    Illegal = false,
    EquipName = "Wear fedora",
    UseTime = 1.2,
    Workbar = "Equipping Fedora...",
    UnEquipName = "Remove fedora",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(1, 10)
        return { equipped = true, unequipped = false }
    end,

    OnRemove = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(1, 0)
        return { unequipped = true }
    end
})

Monarch.RegisterItem({

    Name = "Black Suit",
    Description = "A stylish black suit.",
    UniqueID = "cos_blacksuit",
    Model = "models/willardnetworks/clothingitems/torso_ca_8.mdl",
    Weight = 2,
    CanStack = false,
    EquipGroup = "torso",
    Illegal = false,
    EquipName = "Wear suit",
    UseTime = 1.3,
    Workbar = "Equipping Black Suit...",
    UnEquipName = "Remove suit",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(2, 22)
        return { equipped = true, unequipped = false }
    end,

    OnRemove = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetBodygroup(2, 0)
        return { unequipped = true }
    end
})

Monarch.RegisterItem({
    Name = "Rusty Clock",
    Description = "An old, rusty clock that still works. It allows you to tell the time.",
    UniqueID = "util_rustyclock",
    Model = "models/props_c17/clock01.mdl",
    Weight = 2,
    CanSell = true,
    CanStack = false,
    Illegal = false,
    Stats = [[Shows the time.]],
    UseName = "Inspect",
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:Notify("The clock ticks quietly. You can see the time while reading the dials on the clock.")
        return false
    end
})

Monarch.RegisterItem({
    Name = "Stasi Enlisted Service Uniform",
    Description = "A standard service uniform worn by enlisted members of the Stasi.",
    UniqueID = "cos_stasiuniform_enservice",
    Model = "models/willardnetworks/update_items/cajacket1_item.mdl",
    Weight = 2,
    CanSell = false,
    CanStack = false,
    Illegal = true,
    UseName = "Equip",
    EquipGroup = "torso",
    UseTime = 3,
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetModel("models/strabe/ddr2/stasi7482/stasi/staffservice/enlisted/stasi_enlisted_staff_service_04.mdl")
        return false
    end
})

Monarch.RegisterItem({
    Name = "Stasi Officer's Service Uniform",
    Description = "A standard service uniform worn by Commissioned members of the Stasi.",
    UniqueID = "cos_stasiuniform_coservice",
    Model = "models/willardnetworks/update_items/cajacket1_item.mdl",
    Weight = 2,
    CanSell = false,
    CanStack = false,
    Illegal = true,
    UseName = "Equip",
    EquipGroup = "torso",
    UseTime = 3,
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetModel("models/strabe/ddr2/stasi7482/stasi/staffservice/officer/stasi_officer_staff_service_04.mdl")
        return false
    end
})

Monarch.RegisterItem({
    Name = "Stasi Officer's Social Uniform",
    Description = "A standard Social uniform worn by Commissioned members of the Stasi.",
    UniqueID = "cos_stasiuniform_cosocial",
    Model = "models/willardnetworks/update_items/cajacket1_item.mdl",
    Weight = 2,
    CanSell = false,
    CanStack = false,
    Illegal = true,
    UseName = "Equip",
    EquipGroup = "torso",
    UseTime = 3,
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetModel("models/strabe/ddr2/stasi7482/stasi/social/officer/stasi_officer_social_04.mdl")
        return false
    end
})

Monarch.RegisterItem({
    Name = "Stasi General's Social Uniform",
    Description = "A standard Social uniform worn by Generals of the Stasi.",
    UniqueID = "cos_stasiuniform_gensocial",
    Model = "models/willardnetworks/update_items/cajacket1_item.mdl",
    Weight = 2,
    CanSell = false,
    CanStack = false,
    Illegal = true,
    UseName = "Equip",
    EquipGroup = "torso",
    UseTime = 3,
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetModel("models/strabe/ddr2/stasi7482/stasi/social/general/stasi_general_social_04.mdl")
        return false
    end
})

Monarch.RegisterItem({
    Name = "Stasi General's Service Uniform",
    Description = "A standard Service uniform worn by Generals of the Stasi.",
    UniqueID = "cos_stasiuniform_genservice",
    Model = "models/willardnetworks/update_items/cajacket1_item.mdl",
    Weight = 2,
    CanSell = false,
    CanStack = false,
    Illegal = true,
    UseName = "Equip",
    EquipGroup = "torso",
    UseTime = 3,
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetModel("models/strabe/ddr2/stasi7482/stasi/staffservice/general/stasi_general_staff_service_04.mdl")
        return false
    end
})

Monarch.RegisterItem({
    Name = "Stasi Uniform",
    Description = "A standard uniform worn by members of the Stasi. You may wear this uniform around town whilst off duty.",
    UniqueID = "cos_stasiuniform_undercover",
    Model = "models/willardnetworks/update_items/cajacket1_item.mdl",
    Weight = 2,
    CanSell = false,
    CanStack = false,
    Illegal = true,
    UseName = "Equip",
    EquipGroup = "torso",
    UseTime = 2,
    OnUse = function(ply, slot, itemData, def)
        if not IsValid(ply) then return false end
        ply:SetModel("models/strabe/ddr2/stasi7482/stasi/suit/suits/stasi_suit_04.mdl")
        return false
    end
})

Monarch.RegisterItem({
    Name = "Flashlight",
    Description = "A weak flashlight.",
    UniqueID = "util_flight",
    Model = "models/yukon/cod/props/military/cod_flashlight.mdl",
    Weight = 2,
    CanSell = false,
    CanStack = false,
    Illegal = false,
})

