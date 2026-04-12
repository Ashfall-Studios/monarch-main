if SERVER then
    Monarch = Monarch or {}

    local cv_autoload = CreateConVar("monarch_persist_autoload", "1", FCVAR_ARCHIVE, "Auto-load persisted entities on map start")
    local cv_autosave_runtime = CreateConVar("monarch_persist_autosave_runtime", "0", FCVAR_ARCHIVE, "Autosave persistence files when marking/unmarking or changing keyvalues")

    local function mapName()
        return game.GetMap() or "default"
    end

    local function ensureDir()
        file.CreateDir("monarch")
        file.CreateDir("monarch/maps")
        file.CreateDir("monarch/maps/" .. mapName())
    end

    local function lootPath()
        return string.format("monarch/maps/%s/loot.json", mapName())
    end

    local function vendorsPath()
        return string.format("monarch/maps/%s/vendors.json", mapName())
    end

    local function propsPath()
        return string.format("monarch/maps/%s/props.json", mapName())
    end

    local function legacyLootPath()
        return string.format("monarch/loot_%s.json", mapName())
    end

    local function legacyPropsPath()
        return string.format("monarch/props_%s.json", mapName())
    end

    local function requireSuperAdmin(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return false end
        if not ply:IsSuperAdmin() then
            if ply.Notify then ply:Notify("Superadmin only.") end
            return false
        end
        return true
    end

    Monarch._persistMarkedProps = Monarch._persistMarkedProps or {}

    local function captureBodygroups(ent)
        local out = {}
        local n = ent:GetNumBodyGroups() or 0
        for i = 0, n - 1 do
            out[i] = ent:GetBodygroup(i)
        end
        return out
    end

    local function captureEntity(ent)
        if not IsValid(ent) then return nil end
        local rec = {
            uid = ent._persistUID or nil,
            class = ent:GetClass() or "",
            pos = { x = ent:GetPos().x, y = ent:GetPos().y, z = ent:GetPos().z },
            ang = { p = ent:GetAngles().p, y = ent:GetAngles().y, r = ent:GetAngles().r },
            model = ent:GetModel() or "",
            skin = ent:GetSkin() or 0,
            color = { r = ent:GetColor().r, g = ent:GetColor().g, b = ent:GetColor().b, a = ent:GetColor().a },
            material = ent:GetMaterial() or "",
            bodygroups = captureBodygroups(ent),
            collisiongroup = ent:GetCollisionGroup() or COLLISION_GROUP_NONE,
            frozen = false
        }
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then rec.frozen = phys:IsMotionEnabled() == false end

        if ent:GetClass() == "rp_monarch_recepticle" and ent.GetRecepticleName then
            local name = ent:GetRecepticleName()
            if name and name ~= "" then
                rec.recepticleName = name
            end
        end

        return rec
    end

    local function collectMarkedProps()
        local out = {}
        for _, rec in ipairs(Monarch._persistMarkedProps) do
            local cls = tostring(rec.class or "")
            if cls ~= "monarch_vendor" and cls ~= "monarch_rankvendor" then
                table.insert(out, table.Copy(rec))
            end
        end
        return out
    end
    local function collectLoot()
        local out = {}
        local lootEnts = {}
        for _, ent in ipairs(ents.FindByClass("monarch_loot")) do
            table.insert(lootEnts, ent)
        end
        for _, ent in ipairs(ents.FindByClass("monarch_storage")) do
            table.insert(lootEnts, ent)
        end
        for _, ent in ipairs(lootEnts) do
            if not IsValid(ent) then continue end
            local defid = (ent.GetLootDefID and ent:GetLootDefID()) or ""
            if defid == "" then continue end
            local uid = (ent.GetPersistentID and ent:GetPersistentID()) or ""
            if uid == "" then
                uid = ("loot_" .. os.time() .. "_" .. ent:EntIndex())
                if ent.SetPersistentID then ent:SetPersistentID(uid) end
            end
            local pos = ent:GetPos()
            local ang = ent:GetAngles()
            local rec = {
                uid = uid,
                class = ent:GetClass(),
                pos = { x = pos.x, y = pos.y, z = pos.z },
                ang = { p = ang.p, y = ang.y, r = ang.r },
                model = ent:GetModel() or "",
                name = (ent.GetLootName and ent:GetLootName()) or "",
                defid = defid,
                contents = (ent.GetContents and ent:GetContents()) or {},
                capX = (ent.GetCapacityX and ent:GetCapacityX()) or 0,
                capY = (ent.GetCapacityY and ent:GetCapacityY()) or 0,
                storeable = (function()
                    if ent.GetStoreable then
                        local s = ent:GetStoreable()
                        if s == nil then return true end
                        return s
                    end
                    return true
                end)(),
                openSound = (ent.GetCustomOpenSound and ent:GetCustomOpenSound()) or "",
            }
            table.insert(out, rec)
        end
        return out
    end

    local function toVector(pos)
        if isvector and isvector(pos) then return pos end
        if istable(pos) then return Vector(tonumber(pos.x) or 0, tonumber(pos.y) or 0, tonumber(pos.z) or 0) end
        return vector_origin
    end

    local function toAngle(ang)
        if isangle and isangle(ang) then return ang end
        if istable(ang) then return Angle(tonumber(ang.p) or 0, tonumber(ang.y) or 0, tonumber(ang.r) or 0) end
        return angle_zero
    end

    local function spawnLoot(records)
        records = records or {}

        local existingUIDs = {}
        for _, ent in ipairs(ents.FindByClass("monarch_loot")) do
            if IsValid(ent) and ent.GetPersistentID then
                local uid = tostring(ent:GetPersistentID() or "")
                if uid ~= "" then existingUIDs[uid] = true end
            end
        end
        for _, ent in ipairs(ents.FindByClass("monarch_storage")) do
            if IsValid(ent) and ent.GetPersistentID then
                local uid = tostring(ent:GetPersistentID() or "")
                if uid ~= "" then existingUIDs[uid] = true end
            end
        end

        for _, data in ipairs(records) do
            local entClass = (data.class and data.class ~= "") and data.class or "monarch_loot"
            local uid = tostring(data.uid or "")
            if uid ~= "" and existingUIDs[uid] then
                continue
            end

            local ent = ents.Create(entClass)
            if not IsValid(ent) then continue end
            ent:SetPos(toVector(data.pos))
            ent:SetAngles(toAngle(data.ang))
            ent:Spawn()
            ent:Activate()
            if data.model and ent.SetCustomModel then ent:SetCustomModel(data.model) end
            if data.defid and ent.SetLootDef then ent:SetLootDef(data.defid) end
            if data.uid and ent.SetPersistentID then ent:SetPersistentID(data.uid) end
            if data.name and ent.SetLootName then ent:SetLootName(data.name) end
            if data.capX and ent.SetCapacityX then ent:SetCapacityX(tonumber(data.capX) or 0) end
            if data.capY and ent.SetCapacityY then ent:SetCapacityY(tonumber(data.capY) or 0) end
            if data.storeable ~= nil and ent.SetStoreable then ent:SetStoreable(data.storeable) end
            if data.openSound and ent.SetCustomOpenSound then ent:SetCustomOpenSound(data.openSound) end
            if istable(data.contents) and ent.SetContents then ent:SetContents(data.contents) end

            if data.uid and tostring(data.uid) ~= "" then
                existingUIDs[tostring(data.uid)] = true
            end

            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(false)
                phys:Sleep()
            end
        end
    end

    local function applyBodygroups(ent, groups)
        if not istable(groups) then return end
        for i, v in pairs(groups) do
            local idx = tonumber(i) or i
            local val = tonumber(v) or 0
            if idx and val then
                pcall(function() ent:SetBodygroup(idx, val) end)
            end
        end
    end

    local function tableToColor(c)
        if not istable(c) then return nil end
        return Color(tonumber(c.r) or 255, tonumber(c.g) or 255, tonumber(c.b) or 255, tonumber(c.a) or 255)
    end

    local function spawnProps(records)
        records = records or {}
        print("[Monarch] spawnProps called with " .. #records .. " records")

        local removedCount = 0
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:GetNWBool("MonarchPersistMarked", false) then
                ent:Remove()
                removedCount = removedCount + 1
            end
        end
        if removedCount > 0 then
            print("[Monarch] Removed " .. removedCount .. " existing persisted props before spawning")
        end

        for _, data in ipairs(records) do
            local class = tostring(data.class or "")
            if class == "" then class = "prop_physics" end
            if class == "monarch_vendor" or class == "monarch_rankvendor" then
                print("[Monarch] Skipping vendor class in props: " .. class)
                continue
            end
            local ent = ents.Create(class)
            if not IsValid(ent) then 
                print("[Monarch] Failed to create entity of class: " .. class)
                continue 
            end
            if data.model and data.model ~= "" then
                pcall(function() ent:SetModel(data.model) end)
            end
            ent:SetPos(toVector(data.pos))
            ent:SetAngles(toAngle(data.ang))
            ent:Spawn()
            ent:Activate()
            if data.skin then pcall(function() ent:SetSkin(tonumber(data.skin) or 0) end) end
            if data.material and data.material ~= "" then pcall(function() ent:SetMaterial(data.material) end) end
            if data.color then
                local col = tableToColor(data.color)
                if col then pcall(function() ent:SetColor(col) end) end
            end
            if data.bodygroups then applyBodygroups(ent, data.bodygroups) end
            if data.collisiongroup then pcall(function() ent:SetCollisionGroup(tonumber(data.collisiongroup) or ent:GetCollisionGroup()) end) end

            if class == "rp_monarch_recepticle" and data.recepticleName and ent.SetRecepticleName then
                pcall(function() ent:SetRecepticleName(data.recepticleName) end)
            end

            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then phys:EnableMotion(false) phys:Sleep() end

            if data.uid then ent._persistUID = data.uid end
            ent:SetNWBool("MonarchPersistMarked", true)
        end
        print("[Monarch] Finished spawning props")
    end

    local function writeJSON(path, tbl)
        ensureDir()
        file.Write(path, util.TableToJSON(tbl or {}, false))
    end

    local function readJSON(path, legacy)
        local function loadPath(p)
            if not file.Exists(p, "DATA") then return nil end
            local raw = file.Read(p, "DATA") or "[]"
            print("[Monarch] readJSON: Read " .. #raw .. " bytes from " .. p)
            local ok, data = pcall(util.JSONToTable, raw)
            if ok and istable(data) then
                if data.list and istable(data.list) then
                    print("[Monarch] readJSON: Unwrapped 'list' field with " .. #data.list .. " records")
                    data = data.list
                end
                print("[Monarch] readJSON: Successfully parsed JSON with " .. #data .. " records")
                return data
            end
            print("[Monarch] readJSON: Failed to parse JSON from " .. p)
            return {}
        end
        local data = loadPath(path)
        if data ~= nil then return data end
        if legacy then
            data = loadPath(legacy)
            if data ~= nil then
                writeJSON(path, data)
                return data
            end
        end
        print("[Monarch] readJSON: File does not exist: " .. path)
        return {}
    end

    local function canUseDatabase()
        if not (mysql and mysql.Select and mysql.Insert and mysql.Delete) then return false end
        if mysql.IsConnected and mysql:IsConnected() == false then return false end
        return true
    end

    local function persistSaveDb(which, data, cb)
        if not canUseDatabase() then
            if cb then cb(false) end
            return false
        end
        local map = mapName()
        local payload = util.TableToJSON(data or {}, false) or "[]"
        local del = mysql:Delete("monarch_persistence")
        del:Where("map", map)
        del:Where("type", which)
        del:Callback(function()
            local ins = mysql:Insert("monarch_persistence")
            ins:Insert("map", map)
            ins:Insert("type", which)
            ins:Insert("data", payload)
            ins:Insert("updated_at", tostring(os.time()))
            if cb then ins:Callback(function() cb(true) end) end
            ins:Execute()
        end)
        del:Execute()
        return true
    end

    local function persistLoadDb(which, cb, fallbackFn)
        if not canUseDatabase() then
            if cb then cb(fallbackFn and fallbackFn() or {}, false) end
            return false
        end
        local q = mysql:Select("monarch_persistence")
        q:Where("map", mapName())
        q:Where("type", which)
        q:Limit(1)
        q:Callback(function(res)
            local data
            local fromDb = false
            if type(res) == "table" and res[1] and res[1].data then
                local ok, parsed = pcall(util.JSONToTable, res[1].data)
                if ok and istable(parsed) then
                    data = parsed
                    fromDb = true
                end
            end
            if not istable(data) then
                data = fallbackFn and fallbackFn() or {}
            end
            if cb then cb(data, fromDb) end
        end)
        q:Execute()
        return true
    end

    Monarch._persistPending = Monarch._persistPending or {}

    local function persistSave(which, data, filePath)
        local usedDb = persistSaveDb(which, data)
        if filePath then
            writeJSON(filePath, data)
        end
        return usedDb
    end

    local function persistLoad(which, filePath, legacyPath, cb)
        local fallbackFn = function() return readJSON(filePath, legacyPath) end
        if not persistLoadDb(which, function(data, fromDb)
            if (not fromDb) and istable(data) and next(data) then
                if canUseDatabase() then
                    persistSaveDb(which, data)
                else
                    Monarch._persistPending[which] = { data = data }
                end
            end
            if cb then cb(data, fromDb) end
        end, fallbackFn) then
            local data = fallbackFn()
            if istable(data) and next(data) then
                Monarch._persistPending[which] = { data = data }
            end
            if cb then cb(data, false) end
        end
    end

    hook.Add("DatabaseConnected", "Monarch_Persist_DbMigrate", function()
        if not canUseDatabase() then return end
        if Monarch._persistPending then
            for which, payload in pairs(Monarch._persistPending) do
                if payload and istable(payload.data) then
                    persistSaveDb(which, payload.data)
                end
            end
            Monarch._persistPending = {}
        end
    end)

    concommand.Add("monarch_setlootmodel", function(ply, _, args)
        if not requireSuperAdmin(ply) then return end
        local model = tostring(args[1] or "")
        if model == "" then if ply.Notify then ply:Notify("Usage: monarch_setlootmodel <model>") end return end
        local tr = ply:GetEyeTrace()
        local ent = IsValid(tr.Entity) and tr.Entity or nil
        if not IsValid(ent) or ent:GetClass() ~= "monarch_loot" then if ply.Notify then ply:Notify("Look at a monarch_loot.") end return end
        if ent.SetCustomModel then ent:SetCustomModel(model) end
        if ply.Notify then ply:Notify("Loot model set.") end
    end)

    concommand.Add("monarch_setloot", function(ply, _, args)
        if not requireSuperAdmin(ply) then return end
        local defid = tostring(args[1] or "")
        local uid = tostring(args[2] or "")
        if defid == "" then if ply.Notify then ply:Notify("Usage: monarch_setloot <defid> [uid]") end return end
        local tr = ply:GetEyeTrace()
        local ent = IsValid(tr.Entity) and tr.Entity or nil
        if not IsValid(ent) or ent:GetClass() ~= "monarch_loot" then if ply.Notify then ply:Notify("Look at a monarch_loot.") end return end
        if ent.SetLootDef then ent:SetLootDef(defid) end
        if uid ~= "" and ent.SetPersistentID then ent:SetPersistentID(uid) end
        if ply.Notify then ply:Notify("Loot definition applied.") end
    end)

    concommand.Add("monarch_setkv", function(ply, _, args)
        if not requireSuperAdmin(ply) then return end
        local key = tostring(args[1] or "")
        if key == "" then if ply.Notify then ply:Notify("Usage: monarch_setkv <key> <value>") end return end
        table.remove(args, 1)
        local value = table.concat(args, " ")
        local tr = ply:GetEyeTrace()
        local ent = IsValid(tr.Entity) and tr.Entity or nil
        if not IsValid(ent) then if ply.Notify then ply:Notify("No entity targeted.") end return end

        local class = ent:GetClass()
        if class == "monarch_vendor" then
            key = string.lower(key)
            if key == "vendorid" or key == "vendor_id" or key == "id" then
                if ent.SetVendorID then ent:SetVendorID(value) end
            elseif key == "name" then
                if ent.SetVendorName then ent:SetVendorName(value) end
            elseif key == "desc" or key == "description" then
                if ent.SetVendorDesc then ent:SetVendorDesc(value) end
            elseif key == "model" then
                if value ~= "" then ent:SetModel(value) end
            else
                if ply.Notify then ply:Notify("Unknown vendor key: " .. key) end
                return
            end
            if ply.Notify then ply:Notify("Vendor keyvalue applied.") end

            return
        elseif class == "monarch_loot" then
            key = string.lower(key)
            if key == "defid" or key == "def" or key == "lootdef" then
                if ent.SetLootDef then ent:SetLootDef(value) end
            elseif key == "uid" then
                if ent.SetPersistentID then ent:SetPersistentID(value) end
            elseif key == "model" then
                if ent.SetCustomModel then ent:SetCustomModel(value) end
            else
                if ply.Notify then ply:Notify("Unknown loot key: " .. key) end
                return
            end
            if ply.Notify then ply:Notify("Loot keyvalue applied.") end
            if cv_autosave_runtime:GetBool() then persistSave("loot", collectLoot(), lootPath()) end
            return
        end

        if ply.Notify then ply:Notify("This entity type has no keyvalues.") end
    end)

    concommand.Add("monarch_persist_mark", function(ply, _, args)
        if not requireSuperAdmin(ply) then return end
        local tr = ply:GetEyeTrace()
        local ent = IsValid(tr.Entity) and tr.Entity or nil
        if not IsValid(ent) then if ply.Notify then ply:Notify("No entity targeted.") end return end
        if ent:IsPlayer() then if ply.Notify then ply:Notify("Cannot mark players.") end return end

        local existingUID = ent._persistUID
        if existingUID then

            local removed = false
            for i = #Monarch._persistMarkedProps, 1, -1 do
                if Monarch._persistMarkedProps[i].uid == existingUID then
                    table.remove(Monarch._persistMarkedProps, i)
                    removed = true
                    break
                end
            end

            ent._persistUID = nil
            ent:SetNWBool("MonarchPersistMarked", false)

            writeJSON(propsPath(), collectMarkedProps())

            if ply.Notify then 
                ply:Notify("Unmarked entity (" .. (ent:GetClass() or "") .. ")")
            end
            return
        end

        local rec = captureEntity(ent)
        if not rec then return end
        rec.uid = string.format("prop_%d_%d", os.time(), ent:EntIndex())
        table.insert(Monarch._persistMarkedProps, rec)
        ent._persistUID = rec.uid
        ent:SetNWBool("MonarchPersistMarked", true)
        if cv_autosave_runtime:GetBool() then
            persistSave("props", collectMarkedProps(), propsPath())
        end
        if ply.Notify then ply:Notify("Marked entity for persistence (" .. (rec.class or "") .. ")") end
    end, nil, "Toggle marking for the entity you're looking at")

    concommand.Add("monarch_persist_unmark", function(ply, _, args)
        if not requireSuperAdmin(ply) then return end
        local uid = tostring(args[1] or "")
        local removed = false
        local removedUID = nil
        if uid ~= "" then
            for i = #Monarch._persistMarkedProps, 1, -1 do
                if Monarch._persistMarkedProps[i].uid == uid then 
                    removedUID = uid
                    table.remove(Monarch._persistMarkedProps, i) 
                    removed = true 
                    break 
                end
            end
        else
            local tr = ply:GetEyeTrace()
            local targetEnt = IsValid(tr.Entity) and tr.Entity or nil

            if IsValid(targetEnt) and targetEnt._persistUID then
                removedUID = targetEnt._persistUID
                for i = #Monarch._persistMarkedProps, 1, -1 do
                    if Monarch._persistMarkedProps[i].uid == removedUID then
                        table.remove(Monarch._persistMarkedProps, i)
                        removed = true
                        break
                    end
                end
            end

            if not removed then
                local hitpos = tr.HitPos or ply:GetShootPos()
                local bestIdx, bestDist
                for i, rec in ipairs(Monarch._persistMarkedProps) do
                    local d = rec.pos and toVector(rec.pos):DistToSqr(hitpos) or math.huge
                    if not bestDist or d < bestDist then bestDist = d bestIdx = i end
                end
                if bestIdx then 
                    removedUID = Monarch._persistMarkedProps[bestIdx].uid
                    table.remove(Monarch._persistMarkedProps, bestIdx) 
                    removed = true 
                end
            end
        end

        if removed and removedUID then
            for _, ent in ipairs(ents.GetAll()) do
                if IsValid(ent) and ent._persistUID == removedUID then
                    ent._persistUID = nil
                    ent:SetNWBool("MonarchPersistMarked", false)
                    break
                end
            end
        end

        if removed then
            persistSave("props", collectMarkedProps(), propsPath())
            if ply.Notify then ply:Notify("Unmarked entity (UID: " .. removedUID .. ") and saved.") end
        else
            if ply.Notify then ply:Notify("No mark found.") end
        end
    end, nil, "Unmark a persisted entity by UID or nearest to crosshair")

    concommand.Add("monarch_persist_list", function(ply)
        if not requireSuperAdmin(ply) then return end
        local count = #Monarch._persistMarkedProps
        ply:PrintMessage(HUD_PRINTCONSOLE, string.format("[Monarch] %d marked entities:", count))
        for i, rec in ipairs(Monarch._persistMarkedProps) do
            ply:PrintMessage(HUD_PRINTCONSOLE, string.format(" #%d uid=%s class=%s model=%s", i, tostring(rec.uid or ""), tostring(rec.class or ""), tostring(rec.model or "")))
        end
    end, nil, "List marked entities in console")

    concommand.Add("monarch_persist_mark_clear", function(ply)
        if not requireSuperAdmin(ply) then return end
        Monarch._persistMarkedProps = {}
        if ply.Notify then ply:Notify("Cleared in-memory marks.") end
    end, nil, "Clear in-memory entity marks (does not delete file)")

    local function doSave(ply, which)
        ensureDir()
        which = string.lower(which or "all")
        print("[Monarch] doSave called with which=" .. which)
        if which == "loot" then
            local loot = collectLoot()
            persistSave("loot", loot, lootPath())
            if #loot == 0 then
                print("[Monarch] Save note: no loot found; wrote empty loot persistence")
                if ply.Notify then ply:Notify("No loot to save; wrote empty loot persistence.") end
            else
                if ply.Notify then ply:Notify("Saved loot entities for " .. mapName()) end
            end
        elseif which == "vendors" or which == "vendor" then
            if Monarch.ItemVendor_SaveAll then Monarch.ItemVendor_SaveAll() end
            if Monarch.RankVendor_SaveAll then Monarch.RankVendor_SaveAll() end
            if ply.Notify then ply:Notify("Saved vendors (item + rank) via native systems.") end
        elseif which == "props" or which == "entities" then
            local props = collectMarkedProps()
            print("[Monarch] Saving " .. #props .. " marked props")
            persistSave("props", props, (#props > 0) and propsPath() or nil)
            if #props == 0 then
                print("[Monarch] Save note: no marked props; DB updated, file preserved")
                if ply.Notify then ply:Notify("No marked props to save; DB updated, file kept.") end
            else
                if ply.Notify then ply:Notify("Saved marked props for " .. mapName()) end
            end
        else
            local loot = collectLoot()
            local props = collectMarkedProps()
            print("[Monarch] Saving " .. #props .. " marked props")
            persistSave("loot", loot, lootPath())
            if #loot == 0 then print("[Monarch] Wrote empty loot file: none found") end
            if Monarch.ItemVendor_SaveAll then Monarch.ItemVendor_SaveAll() else print("[Monarch] Skip item vendors: saver missing") end
            if Monarch.RankVendor_SaveAll then Monarch.RankVendor_SaveAll() else print("[Monarch] Skip rank vendors: saver missing") end
            persistSave("props", props, (#props > 0) and propsPath() or nil)
            if #props == 0 then print("[Monarch] Skip writing props file: none found") end
            if ply.Notify then ply:Notify("Saved persistence (loot/vendors/props)") end
        end
    end

    local function doLoad(ply, which)
        which = string.lower(which or "all")
        if which == "loot" then
            persistLoad("loot", lootPath(), legacyLootPath(), function(data, fromDb)
                spawnLoot(data)
                if ply and ply.Notify then
                    ply:Notify("Loaded loot entities" .. (fromDb and " (db)" or "") .. ".")
                end
            end)
        elseif which == "vendors" or which == "vendor" then
            if Monarch.ItemVendor_LoadAll then Monarch.ItemVendor_LoadAll() else print("[Monarch] ItemVendor_LoadAll missing; skipped") end
            if Monarch.RankVendor_LoadAll then Monarch.RankVendor_LoadAll() else print("[Monarch] RankVendor_LoadAll missing; skipped") end
            if ply and ply.Notify then ply:Notify("Loaded vendors (item + rank).") end
        elseif which == "props" or which == "entities" then
            persistLoad("props", propsPath(), legacyPropsPath(), function(recs, fromDb)
                spawnProps(recs)
                Monarch._persistMarkedProps = recs
                if ply and ply.Notify then
                    ply:Notify("Loaded marked props" .. (fromDb and " (db)" or "") .. ".")
                end
            end)
        else
            persistLoad("loot", lootPath(), legacyLootPath(), function(data)
                spawnLoot(data)
            end)
            if Monarch.ItemVendor_LoadAll then Monarch.ItemVendor_LoadAll() else print("[Monarch] ItemVendor_LoadAll missing; skipped") end
            if Monarch.RankVendor_LoadAll then Monarch.RankVendor_LoadAll() else print("[Monarch] RankVendor_LoadAll missing; skipped") end
            persistLoad("props", propsPath(), legacyPropsPath(), function(recs)
                spawnProps(recs)
                Monarch._persistMarkedProps = recs
                if ply and ply.Notify then ply:Notify("Loaded loot, vendors and props.") end
            end)
        end
    end

    local function doClear(ply, which)
        which = string.lower(which or "all")
        if which == "loot" then
            if canUseDatabase() then
                local del = mysql:Delete("monarch_persistence")
                del:Where("map", mapName())
                del:Where("type", "loot")
                del:Execute()
            end
            if file.Exists(lootPath(), "DATA") then file.Delete(lootPath()) end
            if ply.Notify then ply:Notify("Cleared loot save.") end
        elseif which == "vendors" or which == "vendor" then

            if file.Exists("monarch/itemvendors_" .. mapName() .. ".json", "DATA") then file.Delete("monarch/itemvendors_" .. mapName() .. ".json") end
            if file.Exists(vendorsPath(), "DATA") then file.Delete(vendorsPath()) end
            if ply.Notify then ply:Notify("Cleared vendor saves (item + rank).") end
        elseif which == "props" or which == "entities" then
            if canUseDatabase() then
                local del = mysql:Delete("monarch_persistence")
                del:Where("map", mapName())
                del:Where("type", "props")
                del:Execute()
            end
            if file.Exists(propsPath(), "DATA") then file.Delete(propsPath()) end
            if ply.Notify then ply:Notify("Cleared props save.") end
        else
            if canUseDatabase() then
                local del = mysql:Delete("monarch_persistence")
                del:Where("map", mapName())
                del:Where("type", "loot")
                del:Execute()
                local del2 = mysql:Delete("monarch_persistence")
                del2:Where("map", mapName())
                del2:Where("type", "props")
                del2:Execute()
            end
            if file.Exists(lootPath(), "DATA") then file.Delete(lootPath()) end
            if file.Exists("monarch/itemvendors_" .. mapName() .. ".json", "DATA") then file.Delete("monarch/itemvendors_" .. mapName() .. ".json") end
            if file.Exists(vendorsPath(), "DATA") then file.Delete(vendorsPath()) end
            if file.Exists(propsPath(), "DATA") then file.Delete(propsPath()) end
            if ply.Notify then ply:Notify("Cleared loot, vendor, and prop saves.") end
        end
    end

    concommand.Add("monarch_persist_save", function(ply, _, args)
        if not requireSuperAdmin(ply) then return end
        doSave(ply, tostring(args[1] or "all"))
    end, nil, "Save monarch persistent entities (loot, vendors). Usage: monarch_persist_save [loot|vendors|all]")

    concommand.Add("monarch_persist_load", function(ply, _, args)
        if not requireSuperAdmin(ply) then return end
        doLoad(ply, tostring(args[1] or "all"))
    end, nil, "Load monarch persistent entities (loot, vendors). Usage: monarch_persist_load [loot|vendors|all]")

    concommand.Add("monarch_persist_clear", function(ply, _, args)
        if not requireSuperAdmin(ply) then return end
        doClear(ply, tostring(args[1] or "all"))
    end, nil, "Clear monarch persistent save files. Usage: monarch_persist_clear [loot|vendors|all]")

    concommand.Add("monarch_persist_normalize", function(ply, _, args)
        if not requireSuperAdmin(ply) then return end
        local which = string.lower(tostring(args[1] or "vendors"))
        local path
        if which == "loot" then
            path = lootPath()
        elseif which == "vendors" or which == "vendor" then
            path = vendorsPath()
        elseif which == "props" or which == "entities" then
            path = propsPath()
        else
            if ply and ply.Notify then ply:Notify("Usage: monarch_persist_normalize [loot|vendors|props]") end
            return
        end

        if not file.Exists(path, "DATA") then
            if ply and ply.Notify then ply:Notify("File does not exist: " .. path) end
            return
        end

        local data = readJSON(path)
        local seen = {}
        local deduped = {}
        for _, rec in ipairs(data) do
            local key
            if rec.uid then
                key = rec.uid
            elseif rec.vendorID and rec.pos then
                key = rec.vendorID .. "@" .. math.floor(rec.pos.x or 0) .. "," .. math.floor(rec.pos.y or 0) .. "," .. math.floor(rec.pos.z or 0)
            else
                key = util.TableToJSON(rec)
            end

            if not seen[key] then
                seen[key] = true
                table.insert(deduped, rec)
            end
        end

        ensureDir()
        file.Write(path, util.TableToJSON(deduped, true))

        local msg = string.format("[Monarch] Normalized %s: %d → %d records (removed %d duplicates)", 
            which, #data, #deduped, #data - #deduped)
        print(msg)
        if ply and ply.Notify then ply:Notify(msg) end
    end, nil, "Normalize and deduplicate a persistence file. Usage: monarch_persist_normalize [loot|vendors|props]")

    hook.Add("InitPostEntity", "Monarch_Persist_Autoload", function()
        if Monarch._persistAutoloadRan then
            print("[Monarch] Autoload already ran; skipping duplicate init load.")
            return
        end
        if cv_autoload:GetBool() then
            Monarch._persistAutoloadRan = true
            timer.Simple(0.5, function()
                print("[Monarch] Running autoload (loot, vendors, props)...")
                doLoad(nil, "all")
                print("[Monarch] Autoload complete.")
            end)
        else
            print("[Monarch] Autoload disabled (monarch_persist_autoload = 0)")
        end
    end)

    hook.Add("PostCleanupMap", "Monarch_Persist_ReloadAfterCleanup", function()
        if not cv_autoload:GetBool() then return end
        Monarch._persistAutoloadRan = true
        timer.Simple(0.5, function()
            print("[Monarch] PostCleanupMap: reloading persisted entities (loot, vendors, props)...")
            doLoad(nil, "all")
            print("[Monarch] PostCleanupMap reload complete.")
        end)
    end)
end
