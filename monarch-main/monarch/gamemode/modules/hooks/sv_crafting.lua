if SERVER then
    util.AddNetworkString("Monarch_Crafting_RequestOpen")
    util.AddNetworkString("Monarch_Crafting_Open")
    util.AddNetworkString("Monarch_Crafting_RecipesChunk")
    util.AddNetworkString("Monarch_Crafting_AddToQueue")
    util.AddNetworkString("Monarch_Crafting_RemoveFromQueue")
    util.AddNetworkString("Monarch_Crafting_Update")
    util.AddNetworkString("Monarch_Crafting_CancelAll")
    util.AddNetworkString("Monarch_Crafting_Canceled")
    util.AddNetworkString("Monarch_Crafting_RequestCraft")
    util.AddNetworkString("Monarch_Crafting_CancelItem")
    util.AddNetworkString("Monarch_Crafting_ClaimRewards")
end

Monarch = Monarch or {}
Monarch.Crafting = Monarch.Crafting or {}
Monarch.CraftingQueues = Monarch.CraftingQueues or {} 
Monarch.CraftingLastEnt = Monarch.CraftingLastEnt or {} 
Monarch.CraftingPropBenchData = Monarch.CraftingPropBenchData or {}
Monarch.CraftingRuntimeBenchData = Monarch.CraftingRuntimeBenchData or {}
Monarch.CraftingUseCooldown = Monarch.CraftingUseCooldown or {}

local CRAFTING_PROP_FILE = "monarch/crafting_props_" .. game.GetMap() .. ".json"

local function getPropBenchKey(ent)
    if not IsValid(ent) then return nil end
    local mapId = tonumber(ent:MapCreationID() or -1) or -1
    if mapId > 0 then
        return "map:" .. tostring(mapId)
    end
    return "runtime:" .. tostring(ent:EntIndex())
end

local function getEntitySignature(ent)
    if not IsValid(ent) then return nil end
    local pos = ent:GetPos()
    local ang = ent:GetAngles()
    return string.format(
        "%s|%s|%.2f,%.2f,%.2f|%.1f,%.1f,%.1f",
        tostring(ent:GetClass() or ""),
        tostring(ent:GetModel() or ""),
        tonumber(pos.x) or 0,
        tonumber(pos.y) or 0,
        tonumber(pos.z) or 0,
        tonumber(ang.p) or 0,
        tonumber(ang.y) or 0,
        tonumber(ang.r) or 0
    )
end

local function getPersistentBenchKey(ent)
    if not IsValid(ent) then return nil end
    local mapId = tonumber(ent:MapCreationID() or -1) or -1
    if mapId > 0 then
        return "map:" .. tostring(mapId)
    end
    local sig = getEntitySignature(ent)
    if not sig or sig == "" then return nil end
    return "sig:" .. sig
end

local function isMapBenchKey(key)
    return isstring(key) and string.sub(key, 1, 4) == "map:"
end

local function isSigBenchKey(key)
    return isstring(key) and string.sub(key, 1, 4) == "sig:"
end

local function keyToMapId(key)
    if not isMapBenchKey(key) then return nil end
    return tonumber(string.sub(key, 5))
end

local function encodeBenchSet(set)
    local out = {}
    for id, allowed in pairs(set or {}) do
        if allowed == true and type(id) == "string" and id ~= "" then
            out[#out + 1] = id
        end
    end
    table.sort(out)
    return out
end

local function decodeBenchSet(raw)
    local out = {}
    if istable(raw) then
        local isArray = raw[1] ~= nil
        if isArray then
            for _, id in ipairs(raw) do
                if type(id) == "string" and id ~= "" then
                    out[id] = true
                end
            end
        else
            for id, allowed in pairs(raw) do
                if allowed and type(id) == "string" and id ~= "" then
                    out[id] = true
                end
            end
        end
    end
    return out
end

local function setRuntimeBenchTag(ent, benchSet)
    if not IsValid(ent) then return end
    local has = benchSet and next(benchSet) ~= nil
    ent:SetNWBool("MonarchCraftingBenchProp", has and true or false)
    if has then
        ent:SetNWString("MonarchCraftingBenchList", table.concat(encodeBenchSet(benchSet), ", "))
    else
        ent:SetNWString("MonarchCraftingBenchList", "")
    end
end

local function savePropBenchData()
    local out = {}
    for key, rec in pairs(Monarch.CraftingPropBenchData or {}) do
        if istable(rec) then
            local benches = encodeBenchSet(rec.benches)
            if #benches > 0 then
                local row = {
                    key = tostring(key),
                    benches = benches,
                    class = tostring(rec.class or ""),
                    model = tostring(rec.model or "")
                }
                local mapId = keyToMapId(key)
                if mapId then
                    row.mapId = mapId
                end
                out[#out + 1] = row
            end
        end
    end
    file.CreateDir("monarch")
    file.Write(CRAFTING_PROP_FILE, util.TableToJSON(out, false) or "[]")
end

local function loadPropBenchData()
    Monarch.CraftingPropBenchData = {}
    if not file.Exists(CRAFTING_PROP_FILE, "DATA") then return end

    local txt = file.Read(CRAFTING_PROP_FILE, "DATA") or "[]"
    local arr = util.JSONToTable(txt) or {}
    for _, rec in ipairs(arr) do
        local benches = decodeBenchSet(rec.benches)
        local key = nil

        if isstring(rec.key) and rec.key ~= "" then
            key = rec.key
        else
            local mapId = tonumber(rec.mapId)
            if mapId then
                key = "map:" .. tostring(mapId)
            end
        end

        if key and next(benches) ~= nil then
            Monarch.CraftingPropBenchData[key] = {
                benches = benches,
                class = tostring(rec.class or ""),
                model = tostring(rec.model or "")
            }
        end
    end

    for key, rec in pairs(Monarch.CraftingPropBenchData) do
        local mapId = keyToMapId(key)
        if mapId then
            local ent = ents.GetMapCreatedEntity(mapId)
            if IsValid(ent) then
                setRuntimeBenchTag(ent, rec.benches)
            end
        elseif isSigBenchKey(key) then
            local sig = string.sub(key, 5)
            if sig and sig ~= "" then
                for _, ent in ipairs(ents.GetAll()) do
                    if IsValid(ent) and getEntitySignature(ent) == sig then
                        setRuntimeBenchTag(ent, rec.benches)
                    end
                end
            end
        end
    end
end

function Monarch.GetCraftingPropBenchRecord(ent)
    local key = getPropBenchKey(ent)
    local persistentKey = getPersistentBenchKey(ent)
    if not key and not persistentKey then return nil end

    local runtimeRec = key and Monarch.CraftingRuntimeBenchData and Monarch.CraftingRuntimeBenchData[key]
    if runtimeRec then
        return runtimeRec, key, false
    end

    local persistentRec = persistentKey and Monarch.CraftingPropBenchData and Monarch.CraftingPropBenchData[persistentKey]
    if persistentRec then
        return persistentRec, persistentKey, true
    end

    if isMapBenchKey(key) then
        return nil, key, nil
    end

    if persistentKey then
        return nil, persistentKey, nil
    end

    if key then
        return nil, key, nil
    end

    return nil
end

function Monarch.GetCraftingBenchesForEntity(ent)
    if not IsValid(ent) then return nil end
    if ent:GetClass() == "monarch_craftingbench" then return nil end
    local rec = Monarch.GetCraftingPropBenchRecord(ent)
    if not rec or not istable(rec.benches) or next(rec.benches) == nil then return nil end
    return rec.benches
end

function Monarch.IsCraftingBenchEntity(ent)
    if not IsValid(ent) then return false end
    if ent:GetClass() == "monarch_craftingbench" then return true end
    local benches = Monarch.GetCraftingBenchesForEntity(ent)
    return benches ~= nil and next(benches) ~= nil
end

function Monarch.SetCraftingPropBenches(ent, benchSet, options)
    if not IsValid(ent) then return false, "Invalid entity." end
    local key = getPropBenchKey(ent)
    local persistentKey = getPersistentBenchKey(ent)
    if not key and not persistentKey then return false, "Failed to identify entity key." end

    options = istable(options) and options or {}
    local wantsPersist = options.persist
    local canPersist = persistentKey ~= nil
    local shouldPersist = canPersist
    if wantsPersist ~= nil then
        shouldPersist = (wantsPersist == true) and canPersist
    end

    local cleaned = decodeBenchSet(benchSet)
    if next(cleaned) == nil then
        local touchedPersist = false
        if persistentKey and Monarch.CraftingPropBenchData[persistentKey] ~= nil then
            Monarch.CraftingPropBenchData[persistentKey] = nil
            touchedPersist = true
        end
        if key then
            Monarch.CraftingRuntimeBenchData[key] = nil
        end
        setRuntimeBenchTag(ent, nil)
        if touchedPersist then
            savePropBenchData()
            return true, "Removed crafting bench tag from prop (de-persisted)."
        end
        return true, "Removed crafting bench tag from prop."
    end

    local rec = {
        benches = cleaned,
        class = ent:GetClass() or "",
        model = ent:GetModel() or ""
    }

    if shouldPersist then
        Monarch.CraftingPropBenchData[persistentKey] = rec
        if key then
            Monarch.CraftingRuntimeBenchData[key] = nil
        end
    else
        if key then
            Monarch.CraftingRuntimeBenchData[key] = rec
        end
        if persistentKey then
            Monarch.CraftingPropBenchData[persistentKey] = nil
        end
    end

    setRuntimeBenchTag(ent, cleaned)

    if shouldPersist then
        savePropBenchData()
        return true, "Crafting bench tag applied and saved."
    end

    if canPersist then
        savePropBenchData()
        return true, "Crafting bench tag applied (runtime only; de-persisted)."
    end

    return true, "Crafting bench tag applied (temporary; non-map prop)."
end

function Monarch.GetCraftingPropBenchSaveData()
    return Monarch.CraftingPropBenchData or {}
end

if SERVER then
    hook.Add("InitPostEntity", "Monarch_Crafting_LoadPropBenchData", function()
        loadPropBenchData()
    end)

    hook.Add("EntityRemoved", "Monarch_Crafting_CleanupRuntimeBenchTag", function(ent)
        if not IsValid(ent) then return end
        local key = getPropBenchKey(ent)
        if not key or isMapBenchKey(key) then return end
        Monarch.CraftingRuntimeBenchData[key] = nil
    end)
end

local function isBenchAllowedOnEntity(ent, benchId)
    local benches = Monarch.GetCraftingBenchesForEntity(ent)
    if not benches then return true end
    return benches[benchId] == true
end

local function getRecipeOutputs(recipe)
    if not istable(recipe) then return {} end

    if istable(recipe.Outputs) and #recipe.Outputs > 0 then
        local out = {}
        for _, def in ipairs(recipe.Outputs) do
            if istable(def) and isstring(def.id) and def.id ~= "" then
                out[#out + 1] = { id = def.id, amount = math.max(1, math.floor(tonumber(def.amount) or 1)) }
            end
        end
        if #out > 0 then return out end
    end

    if isstring(recipe.Output) and recipe.Output ~= "" then
        return { { id = recipe.Output, amount = 1 } }
    end

    return {}
end

local function getRecipePrimaryOutput(recipe)
    local outputs = getRecipeOutputs(recipe)
    return outputs[1] and outputs[1].id or nil
end

local function getRecipeQueueLabel(recipe)
    local outputs = getRecipeOutputs(recipe)
    if #outputs == 0 then return "Unknown" end
    if #outputs == 1 and outputs[1].amount == 1 then return outputs[1].id end

    local first = outputs[1]
    local extra = #outputs - 1
    local firstLabel = ((first.amount or 1) > 1) and (tostring(first.amount) .. "x " .. tostring(first.id)) or tostring(first.id)
    if extra > 0 then
        return firstLabel .. " +" .. tostring(extra) .. " more"
    end
    return firstLabel
end

local function buildSnapshotFor(ply, ent)
    local benchFilter = Monarch.GetCraftingBenchesForEntity(ent)
    local benches = {}
    for id, def in pairs(Monarch.Crafting.Benches or {}) do
        if benchFilter and not benchFilter[id] then
            continue
        end
        local allowed = Monarch.CraftingCanUseBench(ply, id, ent)
        local lvl = 0
        if Monarch.Skills and def.Skill then
            lvl = (Monarch.Skills.GetLevel and Monarch.Skills.GetLevel(ply, def.Skill)) or 0
        end
        benches[#benches+1] = {
            id = id,
            Name = def.Name or id,
            Model = def.Model or "",
            Skill = def.Skill,
            PlayerLevel = lvl,
            Allowed = allowed and true or false,
            RequiredLevel = tonumber(def.RequiredLevel) or 0,
            RequiredXP = tonumber(def.RequiredXP) or 0
        }
    end

    local recipes = {}
    local all = Monarch.Crafting.Recipes or {}
    for idx, r in ipairs(all) do
        if benchFilter and not benchFilter[r.Bench] then
            continue
        end
        if Monarch.Crafting.Benches[r.Bench] then
            local benchDef = Monarch.Crafting.Benches[r.Bench]
            local benchAllowed = Monarch.CraftingCanUseBench(ply, r.Bench, ent)
            local plyLvl = 0
            if Monarch.Skills and benchDef.Skill and Monarch.Skills.GetLevel then
                plyLvl = Monarch.Skills.GetLevel(ply, benchDef.Skill) or 0
            end
            local needLvl = tonumber(r.level) or 1
            local canCraft = (not benchDef.Skill) or (plyLvl >= needLvl)
            local primaryOutput = getRecipePrimaryOutput(r)
            local outputs = getRecipeOutputs(r)
            local itemMeta = {}
            if Monarch.Inventory and Monarch.Inventory.ItemsRef and Monarch.Inventory.Items then
                local key = primaryOutput and Monarch.Inventory.ItemsRef[primaryOutput]
                local def = key and Monarch.Inventory.Items[key]
                if def then
                    itemMeta.Name = def.Name or primaryOutput or "Unknown"
                    itemMeta.Description = def.Description or ""
                    itemMeta.Model = def.Model or ""
                    itemMeta.Illegal = def.Illegal or false
                else
                    itemMeta.Name = primaryOutput or "Unknown"
                    itemMeta.Description = ""
                    itemMeta.Model = ""
                    itemMeta.Illegal = false
                end
            end
            if #outputs > 1 then
                itemMeta.Name = (itemMeta.Name or (primaryOutput or "Unknown")) .. " +" .. tostring(#outputs - 1) .. " more"
            end

            local mats = {}
            local matsNice = {}
            for itemId, need in pairs(r.Mats or {}) do
                local take = (istable(need) and tonumber(need.take)) or tonumber(need) or 1
                mats[itemId] = take

                local nice = tostring(itemId)
                if Monarch.Inventory and Monarch.Inventory.ItemsRef and Monarch.Inventory.Items then
                    local k = Monarch.Inventory.ItemsRef[itemId]
                    local d = k and Monarch.Inventory.Items[k]
                    if d and d.Name and d.Name ~= "" then nice = d.Name end
                end
                matsNice[itemId] = nice
            end
            recipes[#recipes+1] = {
                idx = idx,
                Bench = r.Bench,
                Output = primaryOutput or r.Output,
                Outputs = outputs,
                Time = r.Time or 0,
                level = r.level or 1,
                item = itemMeta,
                Mats = mats,
                MatsNice = matsNice,
                CanCraft = canCraft,
                BenchAllowed = benchAllowed,
                NeedLevel = needLvl
            }
        end
    end

    local sid = IsValid(ply) and ply:SteamID64() or nil
    local q = (sid and Monarch.CraftingQueues[sid]) or { current = nil, pending = {}, completed = {} }
    local queueSnap = {
        current = q.current and {
            idx = q.current.idx,
            Bench = q.current.Bench,
            Output = q.current.Output,
            startTime = q.current.startTime,
            endTime = q.current.endTime,
        } or nil,
        pending = {},
        completed = {}
    }
    for i, e in ipairs(q.pending or {}) do
        local rr = Monarch.Crafting.Recipes[e.idx]
        queueSnap.pending[i] = { idx = e.idx, Bench = e.Bench, Output = e.Output, Time = rr and rr.Time or 0 }
    end
    for i, e in ipairs(q.completed or {}) do
        local rr = Monarch.Crafting.Recipes[e.idx]
        queueSnap.completed[i] = { idx = e.idx, Bench = e.Bench, Output = e.Output, Time = rr and rr.Time or 0 }
    end

    return { benches = benches, recipes = recipes, queue = queueSnap }
end

local function sendOpen(ply, ent)
    local snap = buildSnapshotFor(ply, ent)

    net.Start("Monarch_Crafting_Open")
        net.WriteEntity(ent)
        net.WriteTable({ benches = snap.benches, queue = snap.queue })
    net.Send(ply)

    local chunkSize = 60
    local total = #snap.recipes
    local idx = 1
    while idx <= total do
        local last = math.min(idx + chunkSize - 1, total)
        local chunk = {}
        for i = idx, last do chunk[#chunk+1] = snap.recipes[i] end
        net.Start("Monarch_Crafting_RecipesChunk")
            net.WriteUInt(idx, 16) 
            net.WriteBool(last == total) 
            net.WriteTable(chunk)
        net.Send(ply)
        idx = last + 1
    end
end

function Monarch.CraftingOpen(ply, ent)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(ent) then return end
    if not Monarch.IsCraftingBenchEntity(ent) then return end
    if ent:GetPos():DistToSqr(ply:GetPos()) > (130 * 130) then return end
    Monarch.CraftingLastEnt[ply:SteamID64()] = ent
    sendOpen(ply, ent)
end

local function sendUpdate(ply)
    local sid = IsValid(ply) and ply:SteamID64() or nil
    if not sid then return end
    local q = Monarch.CraftingQueues[sid] or { current = nil, pending = {}, completed = {} }
    local payload = {
        current = q.current and {
            idx = q.current.idx,
            Bench = q.current.Bench,
            Output = q.current.Output,
            startTime = q.current.startTime,
            endTime = q.current.endTime,
        } or nil,
        pending = {},
        completed = {}
    }
    for i, e in ipairs(q.pending or {}) do
        local rr = Monarch.Crafting.Recipes[e.idx]
        payload.pending[i] = { idx = e.idx, Bench = e.Bench, Output = e.Output, Time = rr and rr.Time or 0 }
    end
    for i, e in ipairs(q.completed or {}) do
        local rr = Monarch.Crafting.Recipes[e.idx]
        payload.completed[i] = { idx = e.idx, Bench = e.Bench, Output = e.Output, Time = rr and rr.Time or 0 }
    end
    net.Start("Monarch_Crafting_Update")
        net.WriteTable(payload)
    net.Send(ply)
end

local function startNextInQueue(ply)
    local sid = ply:SteamID64()
    local q = Monarch.CraftingQueues[sid]
    if not q then return end
    if q.current then return end
    if not q.pending or #q.pending == 0 then return end

    local nextEntry = table.remove(q.pending, 1)
    local r = Monarch.Crafting.Recipes[nextEntry.idx]
    if not r then return end

    q.current = {
        idx = nextEntry.idx,
        Bench = nextEntry.Bench,
        Output = nextEntry.Output,
        BenchEnt = nextEntry.BenchEnt,
        startTime = CurTime(),
        endTime = CurTime() + (tonumber(r.Time) or 0)
    }

    local benchDef = Monarch.Crafting and Monarch.Crafting.Benches and Monarch.Crafting.Benches[nextEntry.Bench]
    local snd = benchDef and benchDef.Sound
    if snd and snd ~= "" then
        local ent = IsValid(nextEntry.BenchEnt) and nextEntry.BenchEnt or (Monarch.CraftingLastEnt and Monarch.CraftingLastEnt[sid])
        if IsValid(ent) then
            ent:EmitSound(snd, 70, 100, 1, CHAN_AUTO)
        else
            if IsValid(ply) then ply:EmitSound(snd, 70, 100, 1, CHAN_AUTO) end
        end
    end
    sendUpdate(ply)
end

local function giveOutput(ply, r)
    if not IsValid(ply) or not r then return end
    local primaryOutput = getRecipePrimaryOutput(r)
    local ok = false
    if primaryOutput and ply.GiveInventoryItem then
        ok = ply:GiveInventoryItem(primaryOutput, 1) == true
    end
    if not ok then

        local ent = ents.Create("monarch_item")
        if IsValid(ent) then
            local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 45, filter = ply })
            ent:SetPos((tr.HitPos or ply:GetPos()) + Vector(0,0,10))
            if primaryOutput then
                ent:SetItemClass(primaryOutput)
            end

            if Monarch.Inventory and Monarch.Inventory.ItemsRef and Monarch.Inventory.Items then
                local key = primaryOutput and Monarch.Inventory.ItemsRef[primaryOutput]
                local def = key and Monarch.Inventory.Items[key]
                if def and def.Model then ent:SetModel(def.Model) end
            end
            ent:Spawn()
            ent:Activate()
        end
    end
end

local function tickQueues()
    for _, ply in player.Iterator() do
        if IsValid(ply) then
            local sid = ply:SteamID64()
            local q = Monarch.CraftingQueues[sid]
            if q then
                if q.current then
                    if CurTime() >= (q.current.endTime or 0) then
                        local r = Monarch.Crafting.Recipes[q.current.idx]

                        if not q.completed then q.completed = {} end
                        table.insert(q.completed, {
                            idx = q.current.idx,
                            Bench = q.current.Bench,
                            Output = q.current.Output,
                            BenchEnt = q.current.BenchEnt
                        })

                        if not ply.craftingRewards then
                            ply.craftingRewards = { items = {}, xp = {} }
                        end

                        if r then
                            local outputs = getRecipeOutputs(r)
                            for _, outputDef in ipairs(outputs) do
                                local outputId = outputDef.id
                                local outputAmount = math.max(1, math.floor(tonumber(outputDef.amount) or 1))
                                if outputId and outputId ~= "" then
                                    ply.craftingRewards.items[outputId] = (ply.craftingRewards.items[outputId] or 0) + outputAmount
                                end
                            end
                        end

                        local benchDef = r and Monarch.Crafting.Benches and r.Bench and Monarch.Crafting.Benches[r.Bench]
                        if benchDef and benchDef.Skill and Monarch.Skills and Monarch.Skills.AddXP then
                            local skillId = benchDef.Skill
                            local time = tonumber(r.Time) or 0

                            if time <= 0 then time = 1 end
                            local rate = (Monarch.Skills.GetRate and Monarch.Skills.GetRate(skillId)) or (Monarch.Skills.XPPerSecondCraft or 1)
                            local explicit = r.XP and tonumber(r.XP)
                            local base = (explicit and explicit > 0) and explicit or math.floor(time * math.max(rate, 0.01))
                            if base <= 0 then base = 1 end 
                            ply.craftingRewards.xp[skillId] = (ply.craftingRewards.xp[skillId] or 0) + base
                        end

                        q.current = nil
                        startNextInQueue(ply)
                        sendUpdate(ply)
                    end
                else

                    if q.pending and #q.pending > 0 then
                        startNextInQueue(ply)

                        if q.current then
                            sendUpdate(ply)
                        end
                    end
                end
            end
        end
    end
end

if SERVER then
    timer.Create("Monarch_Crafting_Tick", 0.5, 0, tickQueues)
end

net.Receive("Monarch_Crafting_RequestOpen", function(_, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) or not Monarch.IsCraftingBenchEntity(ent) then return end
    if ent:GetPos():DistToSqr(ply:GetPos()) > (130*130) then return end
    Monarch.CraftingLastEnt[ply:SteamID64()] = ent
    sendOpen(ply, ent)
end)

net.Receive("Monarch_Crafting_AddToQueue", function(_, ply)
    local recipeIdx = net.ReadUInt(16)
    local amount = net.ReadUInt(8)
    amount = math.max(1, math.min(amount or 1, 50))

    local r = Monarch.Crafting.Recipes and Monarch.Crafting.Recipes[recipeIdx]
    if not r then return end
    local ent = Monarch.CraftingLastEnt[ply:SteamID64()]
    if not isBenchAllowedOnEntity(ent, r.Bench) then return end
    if not Monarch.CraftingCanUseBench(ply, r.Bench, ent) then return end

    local benchDef = Monarch.Crafting.Benches and Monarch.Crafting.Benches[r.Bench]
    if benchDef and benchDef.Skill and Monarch.Skills and Monarch.Skills.GetLevel then
        local plyLvl = Monarch.Skills.GetLevel(ply, benchDef.Skill)
        local needLvl = tonumber(r.level) or 1
        if plyLvl < needLvl then
            if ply.Notify then ply:Notify("Requires "..(benchDef.Skill or "skill").." level "..needLvl.." (you are level "..plyLvl..")") end
            sendUpdate(ply)
            return
        end
    end

    local sid = ply:SteamID64()
    Monarch.CraftingQueues[sid] = Monarch.CraftingQueues[sid] or { current = nil, pending = {} }
    local q = Monarch.CraftingQueues[sid]

    local added = 0
    for i=1, amount do
        if not Monarch.CraftingHasMaterials(ply, r.Mats) then
            break
        end
        if not Monarch.CraftingConsumeMaterials(ply, r.Mats) then
            break
        end
    table.insert(q.pending, { idx = recipeIdx, Bench = r.Bench, Output = getRecipeQueueLabel(r), BenchEnt = ent })
        added = added + 1
    end
    if added == 0 then
        if ply.Notify then ply:Notify("You don't have the required materials.") end
        sendUpdate(ply)
        return
    end
    if not q.current then
        startNextInQueue(ply)
    end
    sendUpdate(ply)
end)

net.Receive("Monarch_Crafting_RemoveFromQueue", function(_, ply)
    local recipeIdx = net.ReadUInt(16)
    local count = net.ReadUInt(8)
    count = math.max(1, math.min(count or 1, 50))

    local r = Monarch.Crafting.Recipes and Monarch.Crafting.Recipes[recipeIdx]
    if not r then return end

    local sid = ply:SteamID64()
    local q = Monarch.CraftingQueues[sid]
    if not q then return end

    local removed = 0
    for i = #q.pending, 1, -1 do
        if q.pending[i].idx == recipeIdx then
            table.remove(q.pending, i)
            removed = removed + 1

            for itemId, need in pairs(r.Mats or {}) do
                local take = (istable(need) and tonumber(need.take)) or tonumber(need) or 1
                for t=1, take do
                    if not (ply.GiveInventoryItem and ply:GiveInventoryItem(itemId, 1)) then
                        local ent = ents.Create("monarch_item")
                        if IsValid(ent) then
                            local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 45, filter = ply })
                            ent:SetPos((tr.HitPos or ply:GetPos()) + Vector(0,0,10))
                            ent:SetItemClass(itemId)
                            ent:Spawn()
                            ent:Activate()
                        end
                    end
                end
            end

            if removed >= count then break end
        end
    end

    sendUpdate(ply)
end)

net.Receive("Monarch_Crafting_CancelAll", function(_, ply)
    local sid = ply:SteamID64()
    local q = Monarch.CraftingQueues[sid]
    if not q then return end

    local function refund(recipeIdx)
        local r = Monarch.Crafting.Recipes and Monarch.Crafting.Recipes[recipeIdx]
        if not r then return end
        for itemId, need in pairs(r.Mats or {}) do
            local take = (istable(need) and tonumber(need.take)) or tonumber(need) or 1
            for t=1, take do
                if not (ply.GiveInventoryItem and ply:GiveInventoryItem(itemId, 1)) then
                    local ent = ents.Create("monarch_item")
                    if IsValid(ent) then
                        local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 45, filter = ply })
                        ent:SetPos((tr.HitPos or ply:GetPos()) + Vector(0,0,10))
                        ent:SetItemClass(itemId)
                        ent:Spawn(); ent:Activate()
                    end
                end
            end
        end
    end

    if q.current then
        refund(q.current.idx)
    end

    for _, e in ipairs(q.pending or {}) do
        refund(e.idx)
    end

    Monarch.CraftingQueues[sid] = { current = nil, pending = {} }

    net.Start("Monarch_Crafting_Canceled")
        net.WriteUInt(0, 8) 
    net.Send(ply)
end)

net.Receive("Monarch_Crafting_RequestCraft", function(_, ply)
    local recipeData = net.ReadTable() or {}
    local idx = recipeData.idx

    if not idx then return end

    local recipeList = Monarch.Crafting.Recipes or {}
    local recipe = recipeList[idx]

    if not recipe then return end

    local ent = Monarch.CraftingLastEnt[ply:SteamID64()] or NULL
    if not isBenchAllowedOnEntity(ent, recipe.Bench) then return end
    if not Monarch.CraftingCanUseBench(ply, recipe.Bench, ent) then return end

    local benchDef = Monarch.Crafting.Benches and Monarch.Crafting.Benches[recipe.Bench]
    if benchDef and benchDef.Skill and Monarch.Skills and Monarch.Skills.GetLevel then
        local plyLvl = Monarch.Skills.GetLevel(ply, benchDef.Skill)
        local needLvl = tonumber(recipe.level) or 1
        if plyLvl < needLvl then
            if ply.Notify then ply:Notify("Requires "..(benchDef.Skill or "skill").." level "..needLvl.." (you are level "..plyLvl..")") end
            sendUpdate(ply)
            return
        end
    end

    local sid = ply:SteamID64()
    Monarch.CraftingQueues[sid] = Monarch.CraftingQueues[sid] or { current = nil, pending = {} }
    local q = Monarch.CraftingQueues[sid]

    if not Monarch.CraftingHasMaterials(ply, recipe.Mats) then
        if ply.Notify then ply:Notify("You don't have the required materials.") end
        sendUpdate(ply)
        return
    end

    if not Monarch.CraftingConsumeMaterials(ply, recipe.Mats) then
        if ply.Notify then ply:Notify("Failed to consume materials.") end
        sendUpdate(ply)
        return
    end

    table.insert(q.pending, { idx = idx, Bench = recipe.Bench, Output = getRecipeQueueLabel(recipe), BenchEnt = ent })

    if not q.current then
        startNextInQueue(ply)
    end

    sendUpdate(ply)
end)

hook.Add("PlayerUse", "Monarch_Crafting_UseTaggedProps", function(ply, ent)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(ent) then return end
    if not Monarch.IsCraftingBenchEntity(ent) then return end

    local sid = ply:SteamID64()
    local nextUse = Monarch.CraftingUseCooldown[sid] or 0
    if CurTime() < nextUse then return false end

    Monarch.CraftingUseCooldown[sid] = CurTime() + 0.35
    Monarch.CraftingOpen(ply, ent)
    return false
end)

net.Receive("Monarch_Crafting_CancelItem", function(_, ply)
    local itemIdx = net.ReadUInt(16)
    local sid = ply:SteamID64()
    local q = Monarch.CraftingQueues[sid]

    if not q or not q.pending or not q.pending[itemIdx] then return end

    local item = q.pending[itemIdx]
    local recipeList = Monarch.Crafting.Recipes or {}
    local recipe = recipeList[item.idx]

    if recipe and istable(recipe.Mats) then
        for itemId, amount in pairs(recipe.Mats) do
            if Monarch.Inventory and Monarch.Inventory.AddItem then
                Monarch.Inventory.AddItem(ply, itemId, tonumber(amount or 1))
            end
        end
    end

    table.remove(q.pending, itemIdx)

    net.Start("Monarch_Crafting_Update")
    net.WriteTable(q)
    net.Send(ply)
end)

net.Receive("Monarch_Crafting_ClaimRewards", function(_, ply)
    local sid = ply:SteamID64()
    local q = Monarch.CraftingQueues[sid] or { current = nil, pending = {}, completed = {} }
    local rewardsGiven = false

    if ply.craftingRewards then
        if ply.craftingRewards.items then
            for itemId, amount in pairs(ply.craftingRewards.items) do
                if ply.GiveInventoryItem then
                    ply:GiveInventoryItem(itemId, amount)
                else

                    for _ = 1, amount do
                        local ent = ents.Create("monarch_item")
                        if IsValid(ent) then
                            local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 45, filter = ply })
                            ent:SetPos((tr.HitPos or ply:GetPos()) + Vector(0,0,10))
                            ent:SetItemClass(itemId)

                            if Monarch.Inventory and Monarch.Inventory.ItemsRef and Monarch.Inventory.Items then
                                local key = Monarch.Inventory.ItemsRef[itemId]
                                local def = key and Monarch.Inventory.Items[key]
                                if def and def.Model then ent:SetModel(def.Model) end
                            end
                            ent:Spawn()
                            ent:Activate()
                        end
                    end
                end
            end
        end

        if ply.craftingRewards.xp then
            for skillName, xpAmount in pairs(ply.craftingRewards.xp) do
                if Monarch.Skills and Monarch.Skills.AddXP then
                    Monarch.Skills.AddXP(ply, skillName, xpAmount)
                end
            end
        end

        ply.craftingRewards = nil
        rewardsGiven = true
    end

    if rewardsGiven then

        q.completed = {}

        net.Start("Monarch_Crafting_Update")
        net.WriteTable(q)
        net.Send(ply)
    end
end)

