Monarch = Monarch or {}
Monarch.Crafting = Monarch.Crafting or {
    Benches = {},
    Recipes = {},
    RecipesByBench = {} 
}

local Crafting = Monarch.Crafting

local function sanitize(def)
    local out = {}
    for k, v in pairs(def or {}) do
        if type(v) ~= "function" then
            out[k] = v
        end
    end
    return out
end

function Monarch.RegisterCraftingBench(def)
    if type(def) ~= "table" then return end
    local id = def.id or def.ID or def.UniqueID
    if type(id) ~= "string" or id == "" then
        MsgC(Color(255,0,0), "[Monarch Crafting] Bench registration missing id\n")
        return
    end
    def.Illegal = def.Illegal == true
    if def.Skill == nil or def.Skill == "" then def.Skill = "crafting" end
    if (def.Name == "Test Workbench" or id == "Test Workbench") and (def.Sound == nil or def.Sound == "") then
        def.Sound = "foley/skills/skill_crafting.wav"
    elseif (string.lower(def.Name or id) == "general workbench") and (def.Sound == nil or def.Sound == "") then
        def.Sound = "foley/skills/skill_crafting.wav"
    end

    Monarch.Crafting = Monarch.Crafting or {}
    Monarch.Crafting.Benches = Monarch.Crafting.Benches or {}
    Monarch.Crafting.Benches[id] = def
end

function Monarch.GetCraftingBench(id)
    return Monarch.Crafting and Monarch.Crafting.Benches and Monarch.Crafting.Benches[id]
end

function Monarch.GetCraftingBenches(safe)
    if not Monarch.Crafting or not Monarch.Crafting.Benches then return {} end
    if not safe then return Monarch.Crafting.Benches end
    local t = {}
    for id, def in pairs(Monarch.Crafting.Benches) do t[id] = sanitize(def) end
    return t
end

function Monarch.RegisterRecipe(recipe)
    if type(recipe) ~= "table" then return end
    recipe.level = tonumber(recipe.level) or 1
    recipe.Time = tonumber(recipe.Time) or 0
    if type(recipe.Bench) ~= "string" or recipe.Bench == "" then
        MsgC(Color(255,0,0), "[Monarch Crafting] Recipe missing Bench id\n")
        return
    end
    local function normalizeOutputs(raw)
        local out = {}
        local totals = {}
        local explicitPrimary = nil

        local function addOutput(itemId, amount)
            if type(itemId) ~= "string" or itemId == "" then return end
            explicitPrimary = explicitPrimary or itemId
            local take = math.max(1, math.floor(tonumber(amount) or 1))
            totals[itemId] = (totals[itemId] or 0) + take
        end

        local function parseEntry(entry)
            if type(entry) == "string" then
                addOutput(entry, 1)
                return
            end
            if not istable(entry) then return end

            local itemId = entry.id or entry.class or entry.item or entry.Output
            local amount = entry.amount or entry.count or entry.take or 1
            addOutput(itemId, amount)
        end

        if type(raw) == "string" then
            addOutput(raw, 1)
        elseif istable(raw) then
            if raw[1] ~= nil then
                for _, entry in ipairs(raw) do
                    parseEntry(entry)
                end
            else
                for itemId, amount in pairs(raw) do
                    if type(itemId) == "string" then
                        local take = (istable(amount) and (amount.amount or amount.count or amount.take)) or amount
                        addOutput(itemId, take)
                    else
                        parseEntry(amount)
                    end
                end
            end
        end

        for itemId, amount in pairs(totals) do
            out[#out + 1] = { id = itemId, amount = amount }
        end
        table.sort(out, function(a, b)
            return tostring(a.id) < tostring(b.id)
        end)

        local primary = nil
        if explicitPrimary and totals[explicitPrimary] then
            primary = explicitPrimary
        else
            primary = out[1] and out[1].id or nil
        end
        return primary, out
    end

    local primaryOutput, normalizedOutputs = normalizeOutputs(recipe.Output)
    if not primaryOutput then
        MsgC(Color(255,0,0), "[Monarch Crafting] Recipe missing Output item id\n")
        return
    end

    recipe.Output = primaryOutput
    recipe.Outputs = normalizedOutputs
    if type(recipe.Mats) ~= "table" then
        MsgC(Color(255,0,0), "[Monarch Crafting] Recipe missing Mats table\n")
        return
    end

    Monarch.Crafting = Monarch.Crafting or {}
    Monarch.Crafting.Recipes = Monarch.Crafting.Recipes or {}
    Monarch.Crafting.RecipesByBench = Monarch.Crafting.RecipesByBench or {}

    Monarch.Crafting.Recipes[#Monarch.Crafting.Recipes + 1] = recipe
    Monarch.Crafting.RecipesByBench[recipe.Bench] = Monarch.Crafting.RecipesByBench[recipe.Bench] or {}
    table.insert(Monarch.Crafting.RecipesByBench[recipe.Bench], recipe)

    if Monarch.Inventory and Monarch.Inventory.ItemsRef then
        for _, outputDef in ipairs(recipe.Outputs or {}) do
            local outputId = outputDef and outputDef.id
            if outputId and not Monarch.Inventory.ItemsRef[outputId] then
                MsgC(Color(255,165,0), "[Monarch Crafting] Warning: Output item '"..outputId.."' not found in ItemsRef at registration time.\n")
            end
        end
        for itemId, need in pairs(recipe.Mats) do
            if type(itemId) == "string" and not Monarch.Inventory.ItemsRef[itemId] then
                MsgC(Color(255,165,0), "[Monarch Crafting] Warning: Material item '"..itemId.."' not found in ItemsRef at registration time.\n")
            end
            if type(need) == "table" then
                need.take = tonumber(need.take) or 1
            end
        end
    end
end

function Monarch.GetRecipesForBench(benchId)
    return Crafting.RecipesByBench[benchId] or {}
end

function Monarch.GetAllRecipes()
    return Crafting.Recipes
end

function Monarch.CraftingCanUseBench(ply, benchId, ent)
    local bench = Crafting.Benches[benchId]
    if not bench then return false end
    if Monarch.Skills and (bench.RequiredLevel or bench.RequiredXP) and bench.Skill then
        local ok = true
        if bench.RequiredLevel and bench.RequiredLevel > 0 and Monarch.Skills.GetLevel then
            local lvl = Monarch.Skills.GetLevel(ply, bench.Skill)
            if (lvl or 0) < bench.RequiredLevel then ok = false end
        end
        if ok and bench.RequiredXP and bench.RequiredXP > 0 and Monarch.Skills.GetXP then
            local xp = Monarch.Skills.GetXP(ply, bench.Skill)
            if (xp or 0) < bench.RequiredXP then ok = false end
        end
        if not ok then return false end
    end
    if type(bench.CanUse) == "function" then
        local ok, res = pcall(bench.CanUse, ply, ent)
        if ok then return res ~= false end
        return false
    end
    return true
end

if SERVER then
    function Monarch.CraftingGetItemCount(ply, itemId)
        if not IsValid(ply) or not itemId then return 0 end
        local sid = ply:SteamID64()
        local data = Monarch.Inventory and Monarch.Inventory.Data and Monarch.Inventory.Data[sid]
        if not data then return 0 end
        local count = 0
        for _, it in pairs(data) do
            if istable(it) then
                local cls = it.class or it.id
                if cls == itemId then
                    count = count + (tonumber(it.amount) or 1)
                end
            end
        end
        return count
    end

    function Monarch.CraftingHasMaterials(ply, mats)
        if not IsValid(ply) then return false end
        for itemId, need in pairs(mats or {}) do
            local take = (istable(need) and tonumber(need.take)) or tonumber(need) or 1
            if Monarch.CraftingGetItemCount(ply, itemId) < take then
                return false
            end
        end
        return true
    end

    function Monarch.CraftingConsumeMaterials(ply, mats)
        if not IsValid(ply) then return false end
        local sid = ply:SteamID64()
        Monarch.Inventory = Monarch.Inventory or {}
        Monarch.Inventory.Data = Monarch.Inventory.Data or {}
        local inv = Monarch.Inventory.Data[sid] or {}

        if not Monarch.CraftingHasMaterials(ply, mats) then return false end

        for itemId, need in pairs(mats or {}) do
            local toTake = (istable(need) and tonumber(need.take)) or tonumber(need) or 1
            if toTake > 0 then
                for slot = 1, (MONARCH_INV_MAX_SLOTS or 20) do
                    local it = inv[slot]
                    if it then
                        local cls = it.class or it.id
                        if cls == itemId then
                            local amt = tonumber(it.amount) or 1
                            local delta = math.min(amt, toTake)
                            amt = amt - delta
                            toTake = toTake - delta
                            if amt <= 0 then
                                inv[slot] = nil
                            else
                                it.amount = amt
                            end
                            if toTake <= 0 then break end
                        end
                    end
                end
            end
        end

        Monarch.Inventory.Data[sid] = inv
        if Monarch.SaveInventory then Monarch.SaveInventory(ply, inv) end
        if ply.SyncInventory then ply:SyncInventory() end
        return true
    end
end

function Monarch.GetCraftingSnapshot()
    local benches = {}
    for id, def in pairs(Crafting.Benches) do benches[id] = sanitize(def) end
    local recipes = {}
    for i, r in ipairs(Crafting.Recipes) do recipes[i] = sanitize(r) end
    return { benches = benches, recipes = recipes }
end