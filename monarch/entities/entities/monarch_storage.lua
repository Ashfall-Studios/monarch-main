AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Storage"
ENT.Category = "Monarch"
ENT.Author = "Monarch"
ENT.Spawnable = true
ENT.HUDDisplayText = "Open personal storage." 

ENT.ContextLabel = "View Personal Storage"
ENT.ShouldShowContext = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "LootDefID")
    self:NetworkVar("String", 1, "LootName")
    self:NetworkVar("String", 2, "CustomOpenSound")
    self:NetworkVar("String", 3, "PersistUID")
    self:NetworkVar("Int", 0, "CapacityX")
    self:NetworkVar("Int", 1, "CapacityY")
    self:NetworkVar("Bool", 0, "Storeable")
end

if SERVER then
    local STORAGE_DEF_ID = "storage_character"
    local STORAGE_DB_TABLE = "monarch_storage_items"

    util.AddNetworkString("Monarch_Loot_BeginOpen")
    util.AddNetworkString("Monarch_Loot_Open")
    util.AddNetworkString("Monarch_Loot_Update")

    Monarch = Monarch or {}
    Monarch.Storage = Monarch.Storage or {}
    Monarch.Storage._SaveToken = Monarch.Storage._SaveToken or {}
    Monarch.Storage._GlobalContents = Monarch.Storage._GlobalContents or {}

    local function getMapName()
        return game.GetMap() or "unknown"
    end

    local function ensureStorageTable()
        if not (mysql and mysql.RawQuery) then return end
        local sql = [[
            CREATE TABLE IF NOT EXISTS `monarch_storage_items` (
                `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
                `map` VARCHAR(96) NOT NULL,
                `crate_uid` VARCHAR(128) NOT NULL,
                `ownerid` VARCHAR(64) NOT NULL DEFAULT '0',
                `slot` INT UNSIGNED NOT NULL,
                `uniqueid` VARCHAR(128) NOT NULL,
                `amount` INT UNSIGNED NOT NULL DEFAULT 1,
                `restricted` TINYINT(1) NOT NULL DEFAULT 0,
                `constrained` TINYINT(1) NOT NULL DEFAULT 0,
                `clip` INT NOT NULL DEFAULT 0,
                PRIMARY KEY (`id`),
                UNIQUE KEY `uniq_map_crate_owner_slot` (`map`, `crate_uid`, `ownerid`, `slot`),
                INDEX `idx_map_crate_owner` (`map`, `crate_uid`, `ownerid`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
        mysql:RawQuery(sql, function() end)

        mysql:RawQuery("ALTER TABLE `monarch_storage_items` ADD COLUMN IF NOT EXISTS `ownerid` VARCHAR(64) NOT NULL DEFAULT '0' AFTER `crate_uid`;", function() end)

        mysql:RawQuery("SHOW INDEX FROM `monarch_storage_items`;", function(rows)
            local hasOldUnique = false
            local hasOwnerUnique = false
            local hasOwnerIdx = false

            if istable(rows) then
                for _, r in ipairs(rows) do
                    local keyName = tostring((r and (r.Key_name or r.key_name)) or "")
                    if keyName == "uniq_map_crate_slot" then
                        hasOldUnique = true
                    elseif keyName == "uniq_map_crate_owner_slot" then
                        hasOwnerUnique = true
                    elseif keyName == "idx_map_crate_owner" then
                        hasOwnerIdx = true
                    end
                end
            end

            if hasOldUnique then
                mysql:RawQuery("ALTER TABLE `monarch_storage_items` DROP INDEX `uniq_map_crate_slot`;", function() end)
            end
            if not hasOwnerUnique then
                mysql:RawQuery("ALTER TABLE `monarch_storage_items` ADD UNIQUE KEY `uniq_map_crate_owner_slot` (`map`, `crate_uid`, `ownerid`, `slot`);", function() end)
            end
            if not hasOwnerIdx then
                mysql:RawQuery("ALTER TABLE `monarch_storage_items` ADD INDEX `idx_map_crate_owner` (`map`, `crate_uid`, `ownerid`);", function() end)
            end
        end)
    end

    hook.Add("DatabaseConnected", "Monarch_Storage_TableInit", ensureStorageTable)

    local function ensureStorageUID(ent)
        if not IsValid(ent) then return "" end
        local uid = ent.GetPersistentID and ent:GetPersistentID() or ""
        if uid ~= "" then return uid end

        local p = ent:GetPos()
        uid = string.format("storage_%s_%d_%d_%d", getMapName(), math.floor(p.x), math.floor(p.y), math.floor(p.z))
        if ent.SetPersistentID then
            ent:SetPersistentID(uid)
        end
        return uid
    end

    local function sanitizeContents(contents)
        local out = {}
        if not istable(contents) then return out end

        for _, item in pairs(contents) do
            if istable(item) then
                local class = tostring(item.class or item.id or "")
                if class ~= "" then
                    table.insert(out, {
                        id = class,
                        class = class,
                        amount = math.max(1, math.floor(tonumber(item.amount or 1) or 1)),
                        restricted = (item.restricted == true) or ((tonumber(item.restricted or 0) or 0) ~= 0),
                        constrained = (item.constrained == true) or ((tonumber(item.constrained or 0) or 0) ~= 0),
                        clip = math.floor(tonumber(item.clip or 0) or 0)
                    })
                end
            end
        end

        return out
    end

    local function getOwnerKey(plyOrOwner)
        if IsValid(plyOrOwner) and plyOrOwner:IsPlayer() then
            local cid = (plyOrOwner.MonarchActiveChar and plyOrOwner.MonarchActiveChar.id) or plyOrOwner.MonarchID or plyOrOwner.MonarchLastCharID
            if cid then return tostring(cid) end
            if plyOrOwner.SteamID64 then return "steam_" .. tostring(plyOrOwner:SteamID64() or "0") end
            return "0"
        end

        local t = type(plyOrOwner)
        if t == "string" then
            if plyOrOwner == "" then return "0" end
            return plyOrOwner
        end
        if t == "number" then
            return tostring(math.floor(plyOrOwner))
        end
        return "0"
    end

    Monarch.Storage.GetOwnerKey = getOwnerKey

    local function setGlobalContents(ownerKey, contents)
        Monarch.Storage._GlobalContents = Monarch.Storage._GlobalContents or {}
        Monarch.Storage._GlobalContents[ownerKey] = sanitizeContents(contents)
        return Monarch.Storage._GlobalContents[ownerKey]
    end

    local function getGlobalContents(ownerKey)
        Monarch.Storage._GlobalContents = Monarch.Storage._GlobalContents or {}
        return Monarch.Storage._GlobalContents[ownerKey]
    end

    function Monarch.Storage.LoadCrateContents(ent, plyOrOwner, onDone)
        if isfunction(plyOrOwner) and onDone == nil then
            onDone = plyOrOwner
            plyOrOwner = nil
        end

        if not IsValid(ent) then
            if onDone then onDone(nil, {}) end
            return
        end

        ensureStorageTable()
        local legacyUID = ensureStorageUID(ent)
        if not (mysql and mysql.Select) then
            local fallback = ent.GetContents and ent:GetContents(plyOrOwner) or {}
            if onDone then onDone(ent, fallback) end
            return
        end

        local ownerKey = getOwnerKey(plyOrOwner)
        ent._CharContents = ent._CharContents or {}

        local ownerCandidates = { ownerKey }
        if IsValid(plyOrOwner) and plyOrOwner:IsPlayer() and plyOrOwner.SteamID64 then
            local sk = "steam_" .. tostring(plyOrOwner:SteamID64() or "0")
            if sk ~= ownerKey then
                table.insert(ownerCandidates, sk)
            end
        end
        if ownerKey ~= "0" then
            table.insert(ownerCandidates, "0")
        end

        local legacyMap = getMapName()
        local function parseRows(rows)
            local loaded = {}
            if istable(rows) then
                for _, row in ipairs(rows) do
                    local class = tostring(row.uniqueid or "")
                    if class ~= "" then
                        table.insert(loaded, {
                            id = class,
                            class = class,
                            amount = math.max(1, math.floor(tonumber(row.amount or 1) or 1)),
                            restricted = (tonumber(row.restricted or 0) or 0) ~= 0,
                            constrained = (tonumber(row.constrained or 0) or 0) ~= 0,
                            clip = math.floor(tonumber(row.clip or 0) or 0)
                        })
                    end
                end
            end
            return loaded
        end

        local function queryOwnerAt(index)
            if not IsValid(ent) then return end
            local key = ownerCandidates[index]
            if not key then
                local shared = getGlobalContents(ownerKey)
                if not istable(shared) then
                    shared = setGlobalContents(ownerKey, ent._CharContents[ownerKey] or {})
                end
                ent._CharContents[ownerKey] = shared
                if onDone then onDone(ent, shared) end
                return
            end

            local function queryScope(mapKey, uidKey, done)
                local q = mysql:Select(STORAGE_DB_TABLE)
                q:Select("slot")
                q:Select("uniqueid")
                q:Select("amount")
                q:Select("restricted")
                q:Select("constrained")
                q:Select("clip")
                q:Where("map", mapKey)
                q:Where("crate_uid", uidKey)
                q:Where("ownerid", key)
                q:OrderByAsc("slot")
                q:Callback(function(rows)
                    if not IsValid(ent) then return end
                    done(parseRows(rows))
                end)
                q:Execute()
            end

            local function queryGlobal(done)
                local q = mysql:Select(STORAGE_DB_TABLE)
                q:Select("slot")
                q:Select("uniqueid")
                q:Select("amount")
                q:Select("restricted")
                q:Select("constrained")
                q:Select("clip")
                q:Where("ownerid", key)
                q:OrderByAsc("slot")
                q:Callback(function(rows)
                    if not IsValid(ent) then return end
                    done(parseRows(rows))
                end)
                q:Execute()
            end

            queryGlobal(function(globalRows)
                if #globalRows > 0 then
                    local shared = setGlobalContents(ownerKey, globalRows)
                    ent._CharContents[ownerKey] = shared
                    if key ~= ownerKey and Monarch and Monarch.Storage and Monarch.Storage.SaveCrateContents then
                        Monarch.Storage.SaveCrateContents(ent, ownerKey)
                    end
                    if onDone then onDone(ent, shared) end
                    return
                end

                queryScope(legacyMap, legacyUID, function(legacyRows)
                    if #legacyRows > 0 then
                        local shared = setGlobalContents(ownerKey, legacyRows)
                        ent._CharContents[ownerKey] = shared
                        if Monarch and Monarch.Storage and Monarch.Storage.SaveCrateContents then
                            Monarch.Storage.SaveCrateContents(ent, ownerKey)
                        end
                        if onDone then onDone(ent, shared) end
                        return
                    end

                    queryOwnerAt(index + 1)
                end)
            end)
        end

        queryOwnerAt(1)
    end

    function Monarch.Storage.SaveCrateContents(ent, plyOrOwner)
        if not IsValid(ent) then return end
        ensureStorageTable()
        if not (mysql and mysql.Delete) then return end

        ensureStorageUID(ent)
        local uid = ensureStorageUID(ent)

        local ownerKey = getOwnerKey(plyOrOwner)
        ent._CharContents = ent._CharContents or {}
        local ownerContents = getGlobalContents(ownerKey)
        if not istable(ownerContents) then
            ownerContents = ent._CharContents[ownerKey]
        end
        if not istable(ownerContents) then
            ownerContents = ent.GetContents and ent:GetContents(ownerKey) or {}
        end

        local contents = sanitizeContents(ownerContents)

        local nextToken = (tonumber(Monarch.Storage._SaveToken[ownerKey]) or 0) + 1
        Monarch.Storage._SaveToken[ownerKey] = nextToken

        local function saveIsCurrent()
            return IsValid(ent) and Monarch and Monarch.Storage and Monarch.Storage._SaveToken and Monarch.Storage._SaveToken[ownerKey] == nextToken
        end

        local function sqlQ(v)
            return SQLStr(tostring(v or ""))
        end

        local map = getMapName()
        local del = mysql:Delete(STORAGE_DB_TABLE)
        del:Where("ownerid", ownerKey)
        del:Callback(function()
            if not saveIsCurrent() then return end

            for slot, item in ipairs(contents) do
                local cls = tostring(item.class or item.id or "")
                if cls ~= "" then
                    local amount = math.max(1, math.floor(tonumber(item.amount or 1) or 1))
                    local restricted = item.restricted and 1 or 0
                    local constrained = item.constrained and 1 or 0
                    local clip = math.floor(tonumber(item.clip or 0) or 0)

                    if mysql.RawQuery then
                        local query = string.format(
                            "INSERT INTO `%s` (`map`, `crate_uid`, `ownerid`, `slot`, `uniqueid`, `amount`, `restricted`, `constrained`, `clip`) VALUES (%s, %s, %s, %d, %s, %d, %d, %d, %d) ON DUPLICATE KEY UPDATE `uniqueid` = VALUES(`uniqueid`), `amount` = VALUES(`amount`), `restricted` = VALUES(`restricted`), `constrained` = VALUES(`constrained`), `clip` = VALUES(`clip`);",
                            STORAGE_DB_TABLE,
                            sqlQ(map),
                            sqlQ(uid),
                            sqlQ(ownerKey),
                            tonumber(slot) or 0,
                            sqlQ(cls),
                            amount,
                            restricted,
                            constrained,
                            clip
                        )
                        mysql:RawQuery(query, function() end)
                    elseif mysql.Insert then
                        local ins = mysql:Insert(STORAGE_DB_TABLE)
                        ins:Insert("map", map)
                        ins:Insert("crate_uid", uid)
                        ins:Insert("ownerid", ownerKey)
                        ins:Insert("slot", slot)
                        ins:Insert("uniqueid", cls)
                        ins:Insert("amount", amount)
                        ins:Insert("restricted", restricted)
                        ins:Insert("constrained", constrained)
                        ins:Insert("clip", clip)
                        ins:Execute()
                    end
                end
            end
        end)
        del:Execute()
    end

    function ENT:Initialize()
        local def = self:GetLootDef()
        local mdl = (def and def.Model) or "models/props_junk/wood_crate003a.mdl"
        self:SetModel(mdl)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end

        if self.GetLootDefID and (self:GetLootDefID() or "") == "" then
            self:SetLootDefID(STORAGE_DEF_ID)
        end
        if self.GetStoreable and self:GetStoreable() == false then
            self:SetStoreable(true)
        end
        if self.GetCapacityX and self:GetCapacityX() == 0 then
            self:SetCapacityX(tonumber(Config and Config.StorageGridCols) or 5)
        end
        if self.GetCapacityY and self:GetCapacityY() == 0 then
            self:SetCapacityY(tonumber(Config and Config.StorageGridRows) or 6)
        end

        self._CharContents = self._CharContents or {}

        ensureStorageUID(self)
    end

    function ENT:GetLootDef()
        local id = self:GetLootDefID()
        return (Monarch and Monarch.Loot and Monarch.Loot.Defs) and Monarch.Loot.Defs[id] or nil
    end

    function ENT:SetLootDef(defid)
        if defid and defid ~= "" then
            self:SetLootDefID(defid)
        end
    end

    function ENT:SetPersistentID(uid)
        local val = tostring(uid or "")
        if self.SetPersistUID then
            self:SetPersistUID(val)
        else
            self:SetNWString("MonarchStoragePersistUID", val)
        end
    end

    function ENT:GetPersistentID()
        if self.GetPersistUID then
            return self:GetPersistUID()
        end
        return self:GetNWString("MonarchStoragePersistUID", "")
    end

    function ENT:GetContents(context)
        self._CharContents = self._CharContents or {}
        local ownerKey = getOwnerKey(context)
        if ownerKey == "0" and self._LastOwnerKey then
            ownerKey = self._LastOwnerKey
        end
        self._LastOwnerKey = ownerKey

        local shared = getGlobalContents(ownerKey)
        if istable(shared) then
            self._CharContents[ownerKey] = shared
            return shared
        end

        if istable(self._CharContents[ownerKey]) then
            local promoted = setGlobalContents(ownerKey, self._CharContents[ownerKey])
            self._CharContents[ownerKey] = promoted
            return promoted
        end

        local empty = setGlobalContents(ownerKey, {})
        self._CharContents[ownerKey] = empty
        return empty
    end

    function ENT:SetContents(tbl, context, skipSave)
        if isbool(context) and skipSave == nil then
            skipSave = context
            context = nil
        end

        self._CharContents = self._CharContents or {}
        local ownerKey = getOwnerKey(context)
        if ownerKey == "0" and self._LastOwnerKey then
            ownerKey = self._LastOwnerKey
        end
        self._LastOwnerKey = ownerKey

        local shared = setGlobalContents(ownerKey, tbl)
        self._CharContents[ownerKey] = shared
        if not skipSave and Monarch and Monarch.Storage and Monarch.Storage.SaveCrateContents then
            Monarch.Storage.SaveCrateContents(self, ownerKey)
        end
    end

    function ENT:SaveContents(context)
        if Monarch and Monarch.Storage and Monarch.Storage.SaveCrateContents then
            Monarch.Storage.SaveCrateContents(self, context)
        end
    end

    function ENT:LoadContentsFor(context, onDone)
        if Monarch and Monarch.Storage and Monarch.Storage.LoadCrateContents then
            Monarch.Storage.LoadCrateContents(self, context, onDone)
            return
        end
        if onDone then onDone(self, self:GetContents(context)) end
    end

    function ENT:GetContentsFor(context)
        local ownerKey = getOwnerKey(context)
        self._CharContents = self._CharContents or {}
        if not getGlobalContents(ownerKey) and Monarch and Monarch.Storage and Monarch.Storage.LoadCrateContents then
            Monarch.Storage.LoadCrateContents(self, ownerKey)
        end
        return self:GetContents(ownerKey)
    end

    function ENT:Use(activator)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        local def = self:GetLootDef()

        if def and def.CanLoot ~= nil then
            local canOpen, denyReason = true, nil

            if isfunction(def.CanLoot) then
                local ok, result, reason = pcall(def.CanLoot, activator, self, def)
                if ok then
                    canOpen = result ~= false
                    denyReason = reason
                else
                    canOpen = false
                    denyReason = "You cannot open this container right now."
                end
            else
                local reqLevel = tonumber(def.CanLoot) or 0
                local skillId = tostring(def.CanLootSkill or "scrapping")
                if reqLevel > 0 then
                    local curLevel = (Monarch and Monarch.Skills and Monarch.Skills.GetLevel and Monarch.Skills.GetLevel(activator, skillId)) or 0
                    if curLevel < reqLevel then
                        canOpen = false
                        local skillDef = Monarch and Monarch.GetSkill and Monarch.GetSkill(skillId)
                        local skillName = (skillDef and skillDef.Name) or skillId
                        local levelName = (Monarch and Monarch.Skills and Monarch.Skills.GetLevelName and Monarch.Skills.GetLevelName(reqLevel)) or tostring(reqLevel)
                        denyReason = string.format("This requires you to be %s in %s.", string.lower(tostring(levelName)), tostring(skillName))
                    end
                end
            end

            if not canOpen then
                if activator.Notify then
                    activator:Notify(denyReason or "You cannot open this container yet.")
                end
                return
            end
        end

        local openTime = (def and (def.OpenTime or def.OpenTIme)) or 0

        local soundToPlay = self:GetCustomOpenSound()
        if not soundToPlay or soundToPlay == "" then
            soundToPlay = (def and def.OpenSound) or "foley/containers/wood_wardrobe_open.mp3"
        end
        if soundToPlay and soundToPlay ~= "" then
            self:EmitSound(soundToPlay, 65, 100, 1, CHAN_AUTO)
        end

        if openTime > 0 then
            net.Start("Monarch_Loot_BeginOpen")
                net.WriteEntity(self)
                net.WriteFloat(openTime)
                net.WriteString(def and (def.UseName or "Personal Storage") or "Personal Storage")
            net.Send(activator)
        end

        timer.Simple(openTime, function()
            if not IsValid(self) or not IsValid(activator) or not activator:IsPlayer() then return end
            if self:GetPos():DistToSqr(activator:GetPos()) > (130 * 130) then return end

            local function sendOpen(contents)
                local capX = tonumber(Config and Config.StorageGridCols) or (self.GetCapacityX and self:GetCapacityX()) or 5
                local capY = tonumber(Config and Config.StorageGridRows) or (self.GetCapacityY and self:GetCapacityY()) or 6

                net.Start("Monarch_Loot_Open")
                    net.WriteEntity(self)
                    net.WriteTable(contents or {})
                    net.WriteString(def and (def.UseName or "Personal Storage") or "Personal Storage")
                    net.WriteUInt(math.max(0, math.min(capX * capY, 4095)), 12)
                    net.WriteBool(true)
                    net.WriteUInt(math.max(0, math.min(capX, 255)), 8)
                    net.WriteUInt(math.max(0, math.min(capY, 255)), 8)
                net.Send(activator)
            end

            if self.LoadContentsFor then
                self:LoadContentsFor(activator, function(entLoaded, loaded)
                    if not IsValid(entLoaded) or not IsValid(activator) then return end
                    if entLoaded:GetPos():DistToSqr(activator:GetPos()) > (130 * 130) then return end
                    sendOpen(loaded)
                end)
            else
                local contents
                if self.GetContentsFor then
                    contents = self:GetContentsFor(activator)
                else
                    contents = self:GetContents(activator)
                end
                sendOpen(contents)
            end
        end)
    end

    function ENT:OnRemove()
        return
    end
end
