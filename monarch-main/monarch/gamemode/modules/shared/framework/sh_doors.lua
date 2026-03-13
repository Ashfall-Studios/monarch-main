Monarch = Monarch or {}
Monarch.Doors = Monarch.Doors or {}
Monarch.Doors.Groups = Monarch.Doors.Groups or {}

Monarch.Doors.Config = {
    LockTime = 1
}

local NW_OWNER   = "monarch_door_owner"
local NW_OWNERS  = "monarch_door_owners"
local NW_PURCHASER = "monarch_door_purchaser"
local NW_GROUP   = "monarch_door_group"
local NW_FORSALE = "monarch_door_forsale"
local NW_PRICE   = "monarch_door_price"
local NW_LOCKED  = "monarch_door_locked"

Monarch.Doors.NW = {
    OWNER = NW_OWNER,
    OWNERS = NW_OWNERS,
    PURCHASER = NW_PURCHASER,
    GROUP = NW_GROUP,
    FORSALE = NW_FORSALE,
    PRICE = NW_PRICE,
    LOCKED = NW_LOCKED
}

local DOOR_CLASSES = {
    ["func_door"] = true,
    ["func_door_rotating"] = true,
    ["prop_door_rotating"] = true,
}

function Monarch.Doors.IsDoor(ent)
    if not IsValid(ent) then return false end
    local class = ent:GetClass()
    return DOOR_CLASSES[class] == true
end

function Monarch.Doors.RegisterGroup(name, checker)
    if not isstring(name) or name == "" then return false end
    if checker ~= nil and not isfunction(checker) then return false end
    Monarch.Doors.Groups[name] = checker or function() return false end
    return true
end

function Monarch.Doors.GetGroupChecker(name)
    return Monarch.Doors.Groups[name]
end

local function normalizeSteamID64(id)
    if id == nil then return nil end
    id = tostring(id)
    id = string.Trim(id)
    if id == "" then return nil end
    return id
end

function Monarch.Doors.GetOwnerSteamIDs(door)
    if not Monarch.Doors.IsDoor(door) then return {} end

    local ids = {}
    local seen = {}

    local raw = door:GetNWString(NW_OWNERS, "")
    if raw ~= "" then
        local ok, parsed = pcall(util.JSONToTable, raw)
        if ok and istable(parsed) then
            for _, id in ipairs(parsed) do
                id = normalizeSteamID64(id)
                if id and not seen[id] then
                    seen[id] = true
                    ids[#ids + 1] = id
                end
            end
        end
    end

    local primary = door:GetNWEntity(NW_OWNER)
    if IsValid(primary) then
        local sid64 = normalizeSteamID64(primary:SteamID64())
        if sid64 and not seen[sid64] then
            seen[sid64] = true
            ids[#ids + 1] = sid64
        end
    end

    return ids
end

function Monarch.Doors.IsOwner(ply, door)
    if not (IsValid(ply) and Monarch.Doors.IsDoor(door)) then return false end

    local owner = door:GetNWEntity(NW_OWNER)
    if IsValid(owner) and owner == ply then
        return true
    end

    local sid64 = normalizeSteamID64(ply:SteamID64())
    if not sid64 then return false end

    for _, id in ipairs(Monarch.Doors.GetOwnerSteamIDs(door)) do
        if id == sid64 then
            return true
        end
    end

    return false
end

function Monarch.Doors.CanPlayerAccessDoor(ply, door)
    if not IsValid(ply) or not Monarch.Doors.IsDoor(door) then return false end
    if Monarch.Doors.IsOwner(ply, door) then return true end
    local g = door:GetNWString(NW_GROUP, "")
    if g ~= "" then
        local checker = Monarch.Doors.Groups[g]
        if checker and checker(ply) then return true end
    end
    return false
end

function Monarch.Doors.GetOwner(door)
    if not Monarch.Doors.IsDoor(door) then return nil end
    local o = door:GetNWEntity(NW_OWNER)
    return IsValid(o) and o or nil
end

function Monarch.Doors.GetOwners(door)
    local owners = {}
    if not Monarch.Doors.IsDoor(door) then return owners end

    for _, sid64 in ipairs(Monarch.Doors.GetOwnerSteamIDs(door)) do
        for _, ply in player.Iterator() do
            if IsValid(ply) and tostring(ply:SteamID64() or "") == sid64 then
                owners[#owners + 1] = ply
                break
            end
        end
    end

    return owners
end

function Monarch.Doors.GetPurchaserSteamID64(door)
    if not Monarch.Doors.IsDoor(door) then return nil end
    local sid64 = normalizeSteamID64(door:GetNWString(NW_PURCHASER, ""))
    return sid64
end

function Monarch.Doors.IsPurchaser(ply, door)
    if not (IsValid(ply) and Monarch.Doors.IsDoor(door)) then return false end
    local sid64 = normalizeSteamID64(ply:SteamID64())
    if not sid64 then return false end
    return sid64 == Monarch.Doors.GetPurchaserSteamID64(door)
end

function Monarch.Doors.GetGroup(door)
    if not Monarch.Doors.IsDoor(door) then return nil end
    local g = door:GetNWString(NW_GROUP, "")
    return g ~= "" and g or nil
end

function Monarch.Doors.IsForSale(door)
    if not Monarch.Doors.IsDoor(door) then return false end
    return door:GetNWBool(NW_FORSALE, false)
end

function Monarch.Doors.GetPrice(door)
    if not Monarch.Doors.IsDoor(door) then return 0 end
    return door:GetNWInt(NW_PRICE, 0)
end

function Monarch.Doors.IsLocked(door)
    if not Monarch.Doors.IsDoor(door) then return false end
    return door:GetNWBool(NW_LOCKED, false)
end

function Monarch.Doors.CanAfford(ply, cost)
    cost = tonumber(cost) or 0
    if cost <= 0 then return true end
    if not IsValid(ply) then return false end
    if ply.GetMoney then
        local bal = tonumber(ply:GetMoney()) or 0
        return bal >= cost
    end
    return true
end

function Monarch.Doors.SetDoorForSale(door, forSale, price) end

function Monarch.Doors.SetDoorGroup(door, groupName) end

function Monarch.Doors.SetDoorOwner(door, ply) end

function Monarch.Doors.AddDoorOwner(door, ply) end

function Monarch.Doors.RemoveDoorOwner(door, ply) end

function Monarch.Doors.AddCoOwner(door, ply) end

function Monarch.Doors.RemoveCoOwner(door, ply) end

function Monarch.Doors.SetDoorLocked(door, locked) end

function Monarch.Doors.SetPlayerDoors(ply, doors)
end

function Monarch.Doors.ResetPlayerDoors(ply)
end

