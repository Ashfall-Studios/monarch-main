AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Loot Container"
ENT.Category = "Monarch"
ENT.Author = "Monarch"
ENT.Spawnable = false

ENT.ContextLabel = "Search Container"
ENT.ShouldShowContext = true

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "LootDefID")
    self:NetworkVar("String", 1, "PersistUID")
    self:NetworkVar("String", 2, "LootName")
    self:NetworkVar("String", 3, "CustomOpenSound")
    self:NetworkVar("Int", 0, "CapacityX")
    self:NetworkVar("Int", 1, "CapacityY")
    self:NetworkVar("Bool", 0, "Storeable")
        self:NetworkVar("Int", 2, "RefillTime") 
end

if SERVER then
    function ENT:FreezePhysicsInPlace()
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(false)
            phys:Sleep()
        end
    end

    function ENT:Initialize()
        self:SetModel(self._CustomModel or self._PendingModel or "models/props_junk/wood_crate001a.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:FreezePhysicsInPlace()
        self.Contents = self.Contents or {}
        self._RefillTimerID = nil

        if self:GetCapacityX() == 0 then self:SetCapacityX(5) end
        if self:GetCapacityY() == 0 then self:SetCapacityY(2) end
        if not self:GetStoreable() then self:SetStoreable(true) end
        if (self.GetRefillTime and self:GetRefillTime() or 0) <= 0 then self:SetRefillTime(300) end
    end

    function ENT:SetLootDef(defid)
        local def = Monarch and Monarch.Loot and Monarch.Loot.Defs and Monarch.Loot.Defs[defid]
        self:SetLootDefID(defid or "")
        if (not self._CustomModel) and def and def.Model then
            self._PendingModel = def.Model
            self:SetModel(def.Model)
        end

        if def then
            if def.CapacityX and tonumber(def.CapacityX) > 0 then
                self:SetCapacityX(tonumber(def.CapacityX))
            end
            if def.CapacityY and tonumber(def.CapacityY) > 0 then
                self:SetCapacityY(tonumber(def.CapacityY))
            end
            if def.CanStore ~= nil then
                self:SetStoreable(def.CanStore)
            end
            local rt = tonumber(def.RefillTime) or tonumber(def.RespawnTime)
            if rt and rt > 0 then self:SetRefillTime(rt) end
        end

        if def and def.LootTable then
            self.Contents = self:GenerateContents(def)
            self._generated = true
        end

        self:SetupRefill(def)
    end

    function ENT:GetLootDef()
        local id = self:GetLootDefID()
        return (Monarch and Monarch.Loot and Monarch.Loot.Defs) and Monarch.Loot.Defs[id] or nil
    end

    function ENT:GetContents()
        return self.Contents or {}
    end

    function ENT:SetContents(tbl)
        self.Contents = tbl or {}
    end

    function ENT:ComputeCapacity(def)
        def = def or self:GetLootDef()
        local cap = 0
        local capX = (self.GetCapacityX and self:GetCapacityX()) or 0
        local capY = (self.GetCapacityY and self:GetCapacityY()) or 0
        if capX > 0 and capY > 0 then
            cap = capX * capY
        end
        if cap <= 0 and def and def.LootTable then
            local lt = def.LootTable
            if istable(lt) then
                if lt.entries and lt.rolls then
                    cap = tonumber(lt.rolls) or 0
                else
                    for _, entry in pairs(lt) do
                        if istable(entry) then
                            cap = cap + (tonumber(entry.rolls) or 0)
                        end
                    end
                end
            end
        end

        if cap <= 0 then cap = 10 end
        return cap
    end

    function ENT:SetupRefill(def)
        def = def or self:GetLootDef()
        if self._RefillTimerID then
            timer.Remove(self._RefillTimerID)
            self._RefillTimerID = nil
        end
        if not def then return end

        local t = (self.GetRefillTime and tonumber(self:GetRefillTime())) or tonumber(def.RefillTime) or tonumber(def.RespawnTime) or 300
        if not t or t <= 0 then t = 300 end
        local id = "monarch_loot_refill_" .. self:EntIndex()
        self._RefillTimerID = id
        timer.Create(id, t, 0, function()
            if not IsValid(self) then
                timer.Remove(id)
                return
            end
            self:DoRefill()
        end)
    end

    function ENT:DoRefill()
        local def = self:GetLootDef()
        if not def or not def.LootTable then return end
        local capacity = self:ComputeCapacity(def)
        local contents = self:GetContents() or {}

        if #contents > 0 then return end

        local new = self:GenerateContents(def) or {}
        if (#new == 0) and istable(def.LootTable) then

            for class,_ in pairs(def.LootTable) do
                table.insert(new, { id = class, amount = 1 })
                break
            end
        end
        for _, itm in ipairs(new) do
            if #contents >= capacity then break end
            table.insert(contents, { id = itm.id, amount = itm.amount or 1 })
        end
        self:SetContents(contents)

        if util and net then
            net.Start("Monarch_Loot_Update")
                net.WriteEntity(self)
                net.WriteTable(contents)
            net.Broadcast()
        end

        self:UpdatePersist()
    end

    function ENT:UpdatePersist()
        if not self.GetPersistentID then return end
        local uid = self:GetPersistentID()
        if not uid or uid == "" then return end
        Monarch = Monarch or {}
        if Monarch._lootPersist and Monarch._lootPersist[uid] then
            Monarch._lootPersist[uid].contents = self:GetContents() or {}
            Monarch._lootPersist[uid].model = self:GetModel()
            Monarch._lootPersist[uid].name = (self.GetLootName and self:GetLootName()) or ""
            Monarch._lootPersist[uid].opensound = (self.GetCustomOpenSound and self:GetCustomOpenSound()) or ""

            local MAP = game.GetMap()
            local out = {}
            for _, data in pairs(Monarch._lootPersist) do table.insert(out, data) end
            file.CreateDir("monarch")
            file.Write("monarch/loot_" .. MAP .. ".json", util.TableToJSON(out, false))
        end
    end

    function ENT:SetCustomModel(modelPath)
        if not isstring(modelPath) or modelPath == "" then return end
        self._CustomModel = modelPath
        self:SetModel(modelPath)

        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:FreezePhysicsInPlace()
        self:UpdatePersist()
    end

    function ENT:SetPersistentID(uid)
        self:SetPersistUID(tostring(uid or ""))
    end

    function ENT:GetPersistentID()
        return self:GetPersistUID()
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
                    denyReason = "You cannot search this container right now."
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
                    activator:Notify(denyReason or "You cannot search this container yet.")
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
                net.WriteString(def and (def.UseName or "Opening...") or "Opening...")
            net.Send(activator)
        end
        timer.Simple(openTime, function()
            if not IsValid(self) or not IsValid(activator) or not activator:IsPlayer() then return end
            if self:GetPos():DistToSqr(activator:GetPos()) > (130*130) then return end

            local totalRolls = 0
            if def and def.LootTable then
                local lt = def.LootTable
                if istable(lt) then
                    if lt.entries and lt.rolls then

                        totalRolls = tonumber(lt.rolls) or 0
                    else

                        for _, entry in pairs(lt) do
                            totalRolls = totalRolls + (tonumber(entry.rolls) or 0)
                        end
                    end
                end
            end
            net.Start("Monarch_Loot_Open")
                net.WriteEntity(self)
                net.WriteTable(self:GetContents() or {})
                net.WriteString(def and (def.UseName or "Open Loot") or "Open Loot")

                local capX = (self.GetCapacityX and self:GetCapacityX()) or 5
                local capY = (self.GetCapacityY and self:GetCapacityY()) or 2
                local legacyCap = capX * capY
                net.WriteUInt(math.max(0, math.min(legacyCap, 4095)), 12)

                local canStore = (def and def.CanStore == true) or (self.GetStoreable and self:GetStoreable()) or false
                net.WriteBool(canStore)
                net.WriteUInt(math.max(0, math.min(capX, 255)), 8)
                net.WriteUInt(math.max(0, math.min(capY, 255)), 8)
            net.Send(activator)
        end)
    end

    function ENT:GenerateContents(def)
        local contents = {}
        local tbl = def.LootTable or {}
        local capacity = self:ComputeCapacity(def)

        for class, entry in pairs(tbl) do
            if #contents >= capacity then break end
            local rolls = math.max(1, tonumber(entry.rolls) or 1)
            local rarity = math.max(1, tonumber(entry.rarity) or 100)
            for i=1, rolls do
                if #contents >= capacity then break end
                if math.random(1, rarity) == 1 then
                    table.insert(contents, { id = class, amount = 1 })
                end
            end
        end

        if #contents == 0 then
            local fallback = nil
            for class, entry in pairs(tbl) do
                fallback = class
                break
            end
            if fallback then
                table.insert(contents, { id = fallback, amount = 1 })
            end
        end
        return contents
    end
else
    function ENT:Draw()
        self:DrawModel()
    end
end

function ENT:OnRemove()
    if self._RefillTimerID then
        timer.Remove(self._RefillTimerID)
        self._RefillTimerID = nil
    end
end
