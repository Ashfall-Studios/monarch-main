Monarch = Monarch or {}
Monarch.Doors = Monarch.Doors or {}

if SERVER then
    util.AddNetworkString("Monarch.Doors.TryBuy")
    util.AddNetworkString("Monarch.Doors.TrySell")
    util.AddNetworkString("Monarch.Doors.ToggleLock")
    util.AddNetworkString("Monarch.Doors.SetName")
    util.AddNetworkString("Monarch.Doors.OpenNamingUI")
    util.AddNetworkString("Monarch.Doors.SetGroup")
    util.AddNetworkString("Monarch.Doors.OpenGroupUI")
    util.AddNetworkString("Monarch.Doors.SetPrice")
    util.AddNetworkString("Monarch.Doors.OpenPriceUI")

    file.CreateDir("monarch/doors")
end

Monarch.Doors.NW = Monarch.Doors.NW or {
    OWNER = "MonarchDoorOwner",
    OWNERS = "MonarchDoorOwners",
    PURCHASER = "MonarchDoorPurchaser",
    FORSALE = "MonarchDoorForSale",
    PRICE = "MonarchDoorPrice",
    GROUP = "MonarchDoorGroup",
    LOCKED = "MonarchDoorLocked"
}

local NW = Monarch.Doors.NW
Monarch.Doors.Data = Monarch.Doors.Data or {}

local function isDoor(ent)
    return Monarch.Doors.IsDoor(ent)
end

local function normalizeSteamID64(id)
    if id == nil then return nil end
    id = tostring(id)
    id = string.Trim(id)
    if id == "" then return nil end
    return id
end

local function getDoorOwnerSet(door)
    if not isDoor(door) then return {} end

    local set = {}
    local raw = door:GetNWString(NW.OWNERS, "")
    if raw ~= "" then
        local ok, parsed = pcall(util.JSONToTable, raw)
        if ok and istable(parsed) then
            for _, sid64 in ipairs(parsed) do
                sid64 = normalizeSteamID64(sid64)
                if sid64 then
                    set[sid64] = true
                end
            end
        end
    end

    local primary = door:GetNWEntity(NW.OWNER)
    if IsValid(primary) then
        local sid64 = normalizeSteamID64(primary:SteamID64())
        if sid64 then
            set[sid64] = true
        end
    end

    return set
end

local function setDoorOwners(door, ownerSet)
    if not isDoor(door) then return false end
    ownerSet = ownerSet or {}

    local ids = {}
    for sid64, has in pairs(ownerSet) do
        sid64 = normalizeSteamID64(sid64)
        if sid64 and has then
            ids[#ids + 1] = sid64
        end
    end

    table.sort(ids)
    door:SetNWString(NW.OWNERS, util.TableToJSON(ids) or "[]")

    local primary = nil
    for _, sid64 in ipairs(ids) do
        for _, ply in player.Iterator() do
            if IsValid(ply) and tostring(ply:SteamID64() or "") == sid64 then
                primary = ply
                break
            end
        end
        if IsValid(primary) then break end
    end

    if IsValid(primary) then
        door:SetNWEntity(NW.OWNER, primary)
        door.OwningPlayer = primary
    else
        door:SetNWEntity(NW.OWNER, NULL)
        door.OwningPlayer = nil
    end

    return true
end

local function doorHasAnyOwner(door)
    local owners = getDoorOwnerSet(door)
    for _, has in pairs(owners) do
        if has then return true end
    end
    return false
end

local function getDoorPurchaserSID64(door)
    if not isDoor(door) then return nil end
    local sid64 = normalizeSteamID64(door:GetNWString(NW.PURCHASER, ""))
    return sid64
end

local function setDoorPurchaserSID64(door, sid64)
    if not isDoor(door) then return false end
    sid64 = normalizeSteamID64(sid64)
    door:SetNWString(NW.PURCHASER, sid64 or "")
    return true
end

local function TryCharge(ply, amount)
    amount = math.max(tonumber(amount) or 0, 0)
    if amount <= 0 then return true end
    if ply.AddMoney then return ply:AddMoney(-amount) and true or true end
    if ply.TakeMoney then
        local ok = ply:TakeMoney(amount)
        return ok ~= false
    end
    if ply.SetNWInt and ply.GetNWInt then
        local cur = tonumber(ply:GetNWInt("Money", 0)) or 0
        if cur >= amount then
            local newAmount = cur - amount
            ply:SetNWInt("Money", newAmount)
            if ply.SetLocalSyncVar and _G.SYNC_MONEY then
                ply:SetLocalSyncVar(SYNC_MONEY, newAmount)
            end
            ply.Money = (ply.Money or cur) - amount
            return true
        else
            return false
        end
    end
    return true
end

local function TryRefund(ply, amount)
    amount = math.max(tonumber(amount) or 0, 0)
    if amount <= 0 then return end
    if ply.AddMoney then ply:AddMoney(amount) return end
    if ply.GiveMoney then ply:GiveMoney(amount) return end
    if ply.SetNWInt and ply.GetNWInt then
        local cur = tonumber(ply:GetNWInt("Money", 0)) or 0
        local newAmount = cur + amount
        ply:SetNWInt("Money", newAmount)
        if ply.SetLocalSyncVar and _G.SYNC_MONEY then
            ply:SetLocalSyncVar(SYNC_MONEY, newAmount)
        end
        ply.Money = (ply.Money or cur) + amount
        return
    end
end

function Monarch.Doors.SetDoorForSale(door, forSale, price)
    if not isDoor(door) then return false end
    door:SetNWBool(NW.FORSALE, forSale and true or false)
    if price ~= nil then
        door:SetNWInt(NW.PRICE, math.max(tonumber(price) or 0, 0))
    end
    return true
end

function Monarch.Doors.SetDoorGroup(door, groupName)
    if not isDoor(door) then return false end
    local name = isstring(groupName) and groupName or ""
    door:SetNWString(NW.GROUP, name)
    return true
end

function Monarch.Doors.SetDoorOwner(door, ply)
    if not isDoor(door) then return false end
    if IsValid(ply) and ply:IsPlayer() then
        local sid64 = normalizeSteamID64(ply:SteamID64())
        if not sid64 then return false end
        local ok = setDoorOwners(door, { [sid64] = true })
        if ok then
            setDoorPurchaserSID64(door, sid64)
        end
        return ok
    else
        local ok = setDoorOwners(door, {})
        if ok then
            setDoorPurchaserSID64(door, nil)
        end
        return ok
    end
end

function Monarch.Doors.AddDoorOwner(door, ply)
    if not isDoor(door) then return false end
    if not (IsValid(ply) and ply:IsPlayer()) then return false end

    local sid64 = normalizeSteamID64(ply:SteamID64())
    if not sid64 then return false end

    local owners = getDoorOwnerSet(door)
    owners[sid64] = true
    return setDoorOwners(door, owners)
end

function Monarch.Doors.RemoveDoorOwner(door, ply)
    if not isDoor(door) then return false end
    if not (IsValid(ply) and ply:IsPlayer()) then return false end

    local sid64 = normalizeSteamID64(ply:SteamID64())
    if not sid64 then return false end

    local owners = getDoorOwnerSet(door)
    owners[sid64] = nil
    return setDoorOwners(door, owners)
end

function Monarch.Doors.AddCoOwner(door, targetPly)
    if not isDoor(door) then return false, "Invalid door." end
    if not (IsValid(targetPly) and targetPly:IsPlayer()) then return false, "Invalid target." end
    if not doorHasAnyOwner(door) then return false, "Door has no purchaser owner." end

    local ok = Monarch.Doors.AddDoorOwner(door, targetPly)
    if not ok then
        return false, "Failed to add co-owner."
    end

    return true
end

function Monarch.Doors.RemoveCoOwner(door, targetPly)
    if not isDoor(door) then return false, "Invalid door." end
    if not (IsValid(targetPly) and targetPly:IsPlayer()) then return false, "Invalid target." end

    local purchaserSid64 = getDoorPurchaserSID64(door)
    local targetSid64 = normalizeSteamID64(targetPly:SteamID64())
    if purchaserSid64 and targetSid64 and purchaserSid64 == targetSid64 then
        return false, "Cannot remove purchaser via RemoveCoOwner."
    end

    local ok = Monarch.Doors.RemoveDoorOwner(door, targetPly)
    if not ok then
        return false, "Failed to remove co-owner."
    end

    return true
end

local function setLocked(door, locked)
    locked = locked and true or false
    door:SetNWBool(NW.LOCKED, locked)
    if locked then
        door:Fire("Lock")
        door:EmitSound("doors/latchlocked2.wav", 75, 100, 0.7)
    else
        door:Fire("Unlock")
        door:EmitSound("doors/latchunlocked1.wav", 75, 100, 0.7)
    end
end

function Monarch.Doors.SetDoorLocked(door, locked)
    if not isDoor(door) then return false end
    setLocked(door, locked)
    return true
end

function Monarch.Doors.SetPlayerDoors(ply, doors)
    if not IsValid(ply) then return false end
    for _, ent in ipairs(ents.GetAll()) do
        if isDoor(ent) and Monarch.Doors.IsOwner and Monarch.Doors.IsOwner(ply, ent) then
            Monarch.Doors.RemoveDoorOwner(ent, ply)
        end
    end
    if istable(doors) then
        for _, ent in ipairs(doors) do
            if isDoor(ent) then
                Monarch.Doors.AddDoorOwner(ent, ply)
                ent:SetNWBool(NW.FORSALE, false)
            end
        end
    end
    return true
end

function Monarch.Doors.ResetPlayerDoors(ply)
    if not IsValid(ply) then return false end
    for _, ent in ipairs(ents.GetAll()) do
        if isDoor(ent) and Monarch.Doors.IsOwner and Monarch.Doors.IsOwner(ply, ent) then
            Monarch.Doors.RemoveDoorOwner(ent, ply)
        end
    end
    return true
end

hook.Add("PlayerUse", "Monarch.Doors.BlockLockedUse", function(ply, ent)
    if not isDoor(ent) then return end

    local hasAccess = Monarch.Doors.CanPlayerAccessDoor(ply, ent)
    
    if ent:GetClass() == "func_door" and hasAccess then
        ent:Fire("Open", "", 0)
    end

    if not ent:GetNWBool(NW.LOCKED, false) then return end
    
    if hasAccess then return end
    
    if IsValid(ply) then ply:Notify("This door is locked.") end
    return false
end)

net.Receive("Monarch.Doors.TryBuy", function(_, ply)
    local ent = net.ReadEntity()
    if not isDoor(ent) then 
        ply:Notify("Invalid door.")
        return 
    end

    if doorHasAnyOwner(ent) then
        ply:Notify("This door is already owned.")
        return
    end

    local group = ent:GetNWString(NW.GROUP, "")
    if group ~= "" then
        ply:Notify("This door is assigned to a group and cannot be purchased.")
        return
    end

    local forSale = ent:GetNWBool(NW.FORSALE, true)
    if not forSale then
        ply:Notify("This door is not for sale.")
        return
    end

    local doorName = ent:GetNWString("DoorName", "")
    if doorName == "" or doorName == "Door" then
        ply:Notify("This door is not purchaseable.")
        return
    end

    local price = math.max(ent:GetNWInt(NW.PRICE, 0), 0)
    if not Monarch.Doors.CanAfford(ply, price) then
        ply:Notify("You can't afford this door.")
        return
    end
    if not TryCharge(ply, price) then
        ply:Notify("Payment failed.")
        return
    end

    local ok = Monarch.Doors.SetDoorOwner(ent, ply)
    if not ok then
        ply:Notify("Failed to assign ownership.")
        TryRefund(ply, price)
        return
    end

    ent:SetNWBool(NW.FORSALE, false)
    setDoorPurchaserSID64(ent, ply:SteamID64())
    ply:Notify("You bought the door" .. (price > 0 and (" for $"..price) or "") .. ".")
end)

net.Receive("Monarch.Doors.TrySell", function(_, ply)
    local ent = net.ReadEntity()
    if not isDoor(ent) then return end
    if not (Monarch.Doors.IsOwner and Monarch.Doors.IsOwner(ply, ent)) then
        ply:Notify("You don't own this door.")
        return
    end

    if not (Monarch.Doors.IsPurchaser and Monarch.Doors.IsPurchaser(ply, ent)) then
        ply:Notify("Only the purchaser can sell this door.")
        return
    end
    
    local doorGroup = ent:GetNWString(NW.GROUP, "")
    if doorGroup == "Standard" or doorGroup == "Priority" then
        ply:Notify("You cannot sell this door.")
        return
    end
    
    local price = math.max(ent:GetNWInt(NW.PRICE, 0), 0)
    TryRefund(ply, math.floor(price * 0.8))

    Monarch.Doors.SetDoorOwner(ent, nil)
    ent:SetNWBool(NW.FORSALE, true)
    setDoorPurchaserSID64(ent, nil)
    ply:Notify("You sold the door.")
end)

net.Receive("Monarch.Doors.ToggleLock", function(_, ply)
    local ent = net.ReadEntity()
    local wantsLocked = net.ReadBool()

    if not isDoor(ent) then return end

    local activeWeapon = ply:GetActiveWeapon()
    if not IsValid(activeWeapon) or activeWeapon:GetClass() ~= "monarch_keys" then
        ply:Notify("You must be holding the keys to lock/unlock doors.")
        return
    end

    ply.DoorLockCooldown = ply.DoorLockCooldown or 0
    if CurTime() < ply.DoorLockCooldown then
        return
    end

    if not Monarch.Doors.CanPlayerAccessDoor(ply, ent) then
        ply:Notify("You can't lock/unlock this door.")
        return
    end

    ply.DoorLockCooldown = CurTime() + (Monarch.Doors.Config.LockTime or 1)

    timer.Simple(Monarch.Doors.Config.LockTime or 1, function()
        if not IsValid(ent) or not IsValid(ply) then return end
        setLocked(ent, wantsLocked)
    end)
end)

local function getEyeDoor(ply, maxDist)
    maxDist = maxDist or 150
    local tr = ply:GetEyeTrace()
    if not tr or not tr.Hit or not IsValid(tr.Entity) then return nil end
    if tr.HitPos:DistToSqr(ply:GetShootPos()) > (maxDist*maxDist) then return nil end
    local ent = tr.Entity
    if not isDoor(ent) then return nil end
    return ent
end

concommand.Add("monarch_setdoorgroup", function(ply, _, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    local ent = getEyeDoor(ply)
    if not ent then ply:Notify("Look at a door.") return end
    local group = args[1] or ""
    Monarch.Doors.SetDoorGroup(ent, group)
    ply:Notify(group ~= "" and ("Door group set to '"..group.."'.") or "Door group cleared.")
end)

concommand.Add("monarch_setdoorsale", function(ply, _, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    local ent = getEyeDoor(ply)
    if not ent then ply:Notify("Look at a door.") return end
    local flag = tonumber(args[1] or 0) == 1
    local price = tonumber(args[2] or 0) or 0
    Monarch.Doors.SetDoorForSale(ent, flag, price)
    ply:Notify(flag and ("Door set For Sale for $"..math.max(price,0)) or "Door not for sale")
end)

local fileName = "monarch/doors/"..game.GetMap()

function Monarch.Doors.Save()
    local doors = {}
    for v, k in pairs(ents.GetAll()) do
        if isDoor(k) and k:MapCreationID() >= 0 then
            local name = k:GetNWString("DoorName", "")
            local group = k:GetNWString(NW.GROUP, "")
            local buyable = k:GetNWBool(NW.FORSALE, true)
            local price = math.max(k:GetNWInt(NW.PRICE, 0), 0)

            if name ~= "" or group ~= "" or buyable == false or price > 0 then
                doors[k:MapCreationID()] = {
                    name = name ~= "" and name or nil,
                    group = group ~= "" and group or nil,
                    pos = k:GetPos(),
                    buyable = buyable,
                    price = price > 0 and price or nil
                }
            end
        end
    end

    print("[Monarch] Saving doors to "..fileName..".dat | Doors saved: "..table.Count(doors))
    file.Write(fileName..".dat", util.TableToJSON(doors))
end

function Monarch.Doors.Load()
    Monarch.Doors.Data = {}

    if file.Exists(fileName..".dat", "DATA") then
        local mapDoorData = util.JSONToTable(file.Read(fileName..".dat", "DATA"))
        local posBuffer = {}
        local posFinds = {}

        for doorID, doorData in pairs(mapDoorData) do
            if doorData.pos then
                posBuffer[doorData.pos.x.."|"..doorData.pos.y.."|"..doorData.pos.z] = doorID
            end
        end

        for v, k in pairs(ents.GetAll()) do
            if isDoor(k) then
                local p = k:GetPos()
                local found = posBuffer[p.x.."|"..p.y.."|"..p.z]

                if found then
                    local doorData = mapDoorData[found]
                    local doorIndex = k:EntIndex()
                    posFinds[doorIndex] = true

                    if doorData.name then k:SetNWString("DoorName", doorData.name) end
                    if doorData.group then k:SetNWString(NW.GROUP, doorData.group) end
                    if doorData.buyable ~= nil then k:SetNWBool(NW.FORSALE, doorData.buyable) end
                    if doorData.price ~= nil then k:SetNWInt(NW.PRICE, math.max(tonumber(doorData.price) or 0, 0)) end
                end
            end
        end

        for doorID, doorData in pairs(mapDoorData) do
            local doorEnt = ents.GetMapCreatedEntity(doorID)

            if IsValid(doorEnt) and isDoor(doorEnt) then
                local doorIndex = doorEnt:EntIndex()

                if not posFinds[doorIndex] then
                    if doorData.name then doorEnt:SetNWString("DoorName", doorData.name) end
                    if doorData.group then doorEnt:SetNWString(NW.GROUP, doorData.group) end
                    if doorData.buyable ~= nil then doorEnt:SetNWBool(NW.FORSALE, doorData.buyable) end
                    if doorData.price ~= nil then doorEnt:SetNWInt(NW.PRICE, math.max(tonumber(doorData.price) or 0, 0)) end

                    print("[Monarch] Warning! Added door by Hammer ID because it could not be found via pos. (NOTE: These change after recompiling the map!) Door index: "..doorIndex)
                end
            end
        end

        posBuffer = nil
        posFinds = nil

        print("[Monarch] Loaded "..table.Count(mapDoorData).." doors from data file")
    end

    hook.Run("MonarchDoorsLoaded")
end

net.Receive("Monarch.Doors.SetName", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local ent = net.ReadEntity()
    local name = net.ReadString()

    if not IsValid(ent) or not isDoor(ent) then
        ply:Notify("Invalid door entity.")
        return
    end

    name = string.Trim(name or "")
    if name == "" then name = "Door" end

    ent:SetNWString("DoorName", name)
    ply:Notify("Door name set to: " .. name)

    timer.Simple(0.5, function()
        Monarch.Doors.Save()
    end)
end)

net.Receive("Monarch.Doors.SetGroup", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local ent = net.ReadEntity()
    local group = net.ReadString()

    if not IsValid(ent) or not isDoor(ent) then
        ply:Notify("Invalid door entity.")
        return
    end

    group = string.Trim(group or "")

    if group == "" then
        ent:SetNWString(NW.GROUP, "")
        ply:Notify("Door group cleared.")
    else
        Monarch.Doors.SetDoorGroup(ent, group)
        ply:Notify("Door group set to: " .. group)
    end

    timer.Simple(0.5, function()
        Monarch.Doors.Save()
    end)
end)

net.Receive("Monarch.Doors.SetPrice", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local ent = net.ReadEntity()
    local price = net.ReadInt(32)

    if not IsValid(ent) or not isDoor(ent) then
        ply:Notify("Invalid door entity.")
        return
    end

    price = math.max(tonumber(price) or 0, 0)

    Monarch.Doors.SetDoorForSale(ent, true, price)
    ply:Notify("Door price set to: $" .. price)

    timer.Simple(0.5, function()
        Monarch.Doors.Save()
    end)
end)

concommand.Add("monarch_savedoors", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    Monarch.Doors.Save()
    if IsValid(ply) then
        ply:Notify("Doors saved!")
    else
        print("[Monarch] Doors saved!")
    end
end)

hook.Add("InitPostEntity", "Monarch.Doors.Load", function()
    timer.Simple(1, function()
        Monarch.Doors.Load()
    end)
end)
