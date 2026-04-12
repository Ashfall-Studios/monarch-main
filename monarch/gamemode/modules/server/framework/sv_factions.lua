if SERVER then
    Monarch = Monarch or {}
    Monarch.Factions = Monarch.Factions or {}

    hook.Add("DatabaseConnected", "Monarch_FactionsTableInit", function()
        local facTable = mysql:Create("monarch_factions")
        facTable:Create("id", "int unsigned NOT NULL AUTO_INCREMENT")
        facTable:Create("name", "varchar(64) NOT NULL")
        facTable:Create("founderSteamID", "varchar(25) NOT NULL")
        facTable:Create("color_r", "tinyint unsigned NOT NULL DEFAULT 100")
        facTable:Create("color_g", "tinyint unsigned NOT NULL DEFAULT 100")
        facTable:Create("color_b", "tinyint unsigned NOT NULL DEFAULT 100")
        facTable:Create("logoIndex", "tinyint unsigned NOT NULL DEFAULT 1")
        facTable:Create("createdAt", "int(11) unsigned NOT NULL")
        facTable:PrimaryKey("id")
        facTable:Execute()

        local memTable = mysql:Create("monarch_faction_members")
        memTable:Create("id", "int unsigned NOT NULL AUTO_INCREMENT")
        memTable:Create("factionID", "int unsigned NOT NULL")
        memTable:Create("steamID", "varchar(25) NOT NULL")
        memTable:Create("role", "varchar(64) NOT NULL DEFAULT 'Member'")
        memTable:Create("joinedAt", "int(11) unsigned NOT NULL")
        memTable:PrimaryKey("id")
        memTable:Execute()

        local rolesTable = mysql:Create("monarch_faction_roles")
        rolesTable:Create("id", "int unsigned NOT NULL AUTO_INCREMENT")
        rolesTable:Create("factionID", "int unsigned NOT NULL")
        rolesTable:Create("roleID", "varchar(64) NOT NULL")
        rolesTable:Create("name", "varchar(32) NOT NULL")
        rolesTable:Create("color_r", "tinyint unsigned NOT NULL DEFAULT 100")
        rolesTable:Create("color_g", "tinyint unsigned NOT NULL DEFAULT 100")
        rolesTable:Create("color_b", "tinyint unsigned NOT NULL DEFAULT 100")
        rolesTable:Create("precedence", "int unsigned NOT NULL DEFAULT 0")
        rolesTable:Create("permissions", "longtext")
        rolesTable:PrimaryKey("id")
        rolesTable:Execute()
    end)

    util.AddNetworkString("Monarch_Role_Create")
    util.AddNetworkString("Monarch_Role_Update")
    util.AddNetworkString("Monarch_Role_Delete")
    util.AddNetworkString("Monarch_Role_Created")
    util.AddNetworkString("Monarch_Role_Updated")
    util.AddNetworkString("Monarch_Role_Deleted")
    util.AddNetworkString("Monarch_Faction_Updated")
    util.AddNetworkString("Monarch_Faction_Announcement")
    util.AddNetworkString("Monarch_Faction_ShowAnnouncement")
    util.AddNetworkString("Monarch_Faction_PermissionsList")
    util.AddNetworkString("Monarch_Faction_Create")
    util.AddNetworkString("Monarch_Faction_CreateResponse")
    util.AddNetworkString("Monarch_Faction_Edit")
    util.AddNetworkString("Monarch_Faction_EditResponse")
    util.AddNetworkString("Monarch_Faction_RequestList")
    util.AddNetworkString("Monarch_Faction_List")
    util.AddNetworkString("Monarch_Faction_Join")
    util.AddNetworkString("Monarch_Faction_JoinResponse")
    util.AddNetworkString("Monarch_Faction_Leave")
    util.AddNetworkString("Monarch_Faction_LeaveResponse")
    util.AddNetworkString("Monarch_Faction_RequestPlayerFaction")
    util.AddNetworkString("Monarch_Faction_PlayerData")
    util.AddNetworkString("Monarch_Faction_SetMemberRole")
    util.AddNetworkString("Monarch_Faction_SetMemberRoleResponse")

    local function getCharID(ply)
        if not IsValid(ply) then return nil end

        local cid = ply.MonarchID or 
                   (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or
                   (ply.GetCharID and ply:GetCharID())

        if cid and cid ~= "" then
            return tostring(cid)
        end

        return nil
    end

    local function getIdentityKeys(ply)
        if not IsValid(ply) then return nil, nil, nil end

        local charID = getCharID(ply)
        local steamID64 = tostring(ply:SteamID64() or "")
        local steamID = tostring(ply:SteamID() or "")

        if charID ~= nil then
            charID = tostring(charID)
        end

        if steamID64 == "" then steamID64 = nil end
        if steamID == "" then steamID = nil end

        return charID, steamID64, steamID
    end

    local function isFounderForPlayer(faction, ply, providedCharID)
        if not istable(faction) then return false end

        local founderKey = tostring(faction.founderCharID or faction.founderSteamID or "")
        if founderKey == "" then return false end

        local charID = providedCharID and tostring(providedCharID) or nil
        local sid64
        local sid

        if IsValid(ply) then
            local resolvedCharID, resolvedSid64, resolvedSid = getIdentityKeys(ply)
            charID = charID or resolvedCharID
            sid64 = resolvedSid64
            sid = resolvedSid
        end

        return (charID and founderKey == charID)
            or (sid64 and founderKey == sid64)
            or (sid and founderKey == sid)
    end

    local function findPlayerByMemberKey(memberKey)
        if not memberKey then return nil end
        memberKey = tostring(memberKey)
        for _, ply in player.Iterator() do
            local cid = getCharID(ply)
            if cid and cid == memberKey then
                return ply
            end

            local sid64 = ply:SteamID64()
            local sid = ply:SteamID()
            if memberKey == sid64 or memberKey == sid then
                return ply
            end
        end
        return nil
    end

    local factionsByID = {}
    local factionsByFounderID = {}
    local syncFactionToPlayer

    local function loadAllFactions()
        factionsByID = {}
        factionsByFounderID = {}

        local q = mysql:Select("monarch_factions")
        q:Callback(function(factions)
            if not istable(factions) then return end

            for _, fac in ipairs(factions) do
                local factionID = tonumber(fac.id)
                local founderCharID = tostring(fac.founderCharID or fac.founderSteamID or "")

                local faction = {
                    id = factionID,
                    name = fac.name,
                    founderCharID = founderCharID,
                    founderSteamID = fac.founderSteamID or founderCharID, 
                    color = {
                        r = tonumber(fac.color_r) or 100,
                        g = tonumber(fac.color_g) or 100,
                        b = tonumber(fac.color_b) or 100
                    },
                    logoIndex = tonumber(fac.logoIndex) or 1,
                    createdAt = tonumber(fac.createdAt) or 0,
                    members = {},
                    roles = {}
                }

                factionsByID[factionID] = faction
                if founderCharID ~= "" then
                    factionsByFounderID[founderCharID] = factionID
                end

                local mq = mysql:Select("monarch_faction_members")
                mq:Where("factionID", factionID)
                mq:Callback(function(members)
                    if istable(members) then
                        for _, mem in ipairs(members) do
                            local memberKey = tostring(mem.charID or mem.steamID or "")
                            if memberKey ~= "" then
                                faction.members[memberKey] = {
                                    joinedAt = tonumber(mem.joinedAt) or 0,
                                    role = mem.role or "Member",
                                    char_id = memberKey,
                                    steamid = mem.steamID
                                }
                            end
                        end
                    end
                end)
                mq:Execute()

                local rq = mysql:Select("monarch_faction_roles")
                rq:Where("factionID", factionID)
                rq:Callback(function(roles)
                    if istable(roles) then
                        for _, role in ipairs(roles) do
                            local perms = {}
                            if role.permissions and role.permissions ~= "" then
                                local ok, data = pcall(util.JSONToTable, role.permissions)
                                if ok and istable(data) then perms = data end
                            end

                            faction.roles[role.roleID] = {
                                id = role.roleID,
                                name = role.name,
                                color = {
                                    r = tonumber(role.color_r) or 100,
                                    g = tonumber(role.color_g) or 100,
                                    b = tonumber(role.color_b) or 100
                                },
                                precedence = tonumber(role.precedence) or 0,
                                permissions = perms
                            }
                        end
                    end
                end)
                rq:Execute()
            end
        end)
        q:Execute()
    end

    local function saveFaction(faction)
        if not istable(faction) or not faction.id then return false end

        local u = mysql:Update("monarch_factions")
        u:Update("name", faction.name)
        u:Update("founderSteamID", faction.founderCharID or "")
        u:Update("color_r", faction.color.r)
        u:Update("color_g", faction.color.g)
        u:Update("color_b", faction.color.b)
        u:Update("logoIndex", faction.logoIndex)
        u:Where("id", faction.id)
        u:Execute()

        local del = mysql:Delete("monarch_faction_members")
        del:Where("factionID", faction.id)
        del:Execute()

        for memberCharID, memberData in pairs(faction.members or {}) do
            local ins = mysql:Insert("monarch_faction_members")
            ins:Insert("factionID", faction.id)
            ins:Insert("steamID", memberCharID)
            ins:Insert("role", memberData.role or "Member")
            ins:Insert("joinedAt", math.floor(memberData.joinedAt or 0))
            ins:Execute()
        end

        local delr = mysql:Delete("monarch_faction_roles")
        delr:Where("factionID", faction.id)
        delr:Execute()

        for roleID, roleData in pairs(faction.roles or {}) do
            local ins = mysql:Insert("monarch_faction_roles")
            ins:Insert("factionID", faction.id)
            ins:Insert("roleID", roleID)
            ins:Insert("name", roleData.name)
            ins:Insert("color_r", roleData.color.r)
            ins:Insert("color_g", roleData.color.g)
            ins:Insert("color_b", roleData.color.b)
            ins:Insert("precedence", roleData.precedence)
            ins:Insert("permissions", util.TableToJSON(roleData.permissions or {}))
            ins:Execute()
        end

        return true
    end

    local registeredPermissions = {}

    function Monarch.Factions.RegisterPermission(key, label, description)
        if not (isstring(key) and isstring(label)) then
            error("RegisterPermission: key and label must be strings")
        end

        registeredPermissions[key] = {
            key = key,
            label = label,
            description = description or "No description provided"
        }
    end

    function Monarch.Factions.GetPermission(key)
        return registeredPermissions[key]
    end

    function Monarch.Factions.GetAllPermissions()
        return table.Copy(registeredPermissions)
    end

    function Monarch.Factions.IsPermissionRegistered(key)
        return registeredPermissions[key] ~= nil
    end

    local function initializeDefaultPermissions()
        Monarch.Factions.RegisterPermission("invite", "Invite Members", "Allow members to invite new players to the faction")
        Monarch.Factions.RegisterPermission("editInfo", "Edit Faction Info", "Allow members to edit faction name, color, and logo")
        Monarch.Factions.RegisterPermission("kick", "Kick Members", "Allow members to kick other players from the faction")
        Monarch.Factions.RegisterPermission("lockInvites", "Lock Invites", "Allow members to lock/unlock faction invitations")
        Monarch.Factions.RegisterPermission("manageRoles", "Manage Roles", "Allow members to create, edit, and delete faction roles")
        Monarch.Factions.RegisterPermission("makeAnnouncements", "Make Announcements", "Allow members to post announcements to the faction")
        Monarch.Factions.RegisterPermission("editMemberRoles", "Edit Member Roles", "Allow members to change other members' roles")
    end

    local function makeFounderRoleName(founderRole)
        local name = string.Trim(tostring(founderRole or "Founder"))
        if name == "" then name = "Founder" end
        return string.sub(name, 1, 32)
    end

    function Monarch.Factions.Create(founderCharID, name, founderRole, color, logoIndex, onCreated)
        if not (isstring(founderCharID) and founderCharID ~= "" and isstring(name) and name ~= "") then
            return nil, "Invalid parameters"
        end

        local founderRoleName = makeFounderRoleName(founderRole)
        founderCharID = tostring(founderCharID)

        local ins = mysql:Insert("monarch_factions")
        ins:Insert("name", string.sub(name, 1, 64))
        ins:Insert("founderSteamID", founderCharID)
        ins:Insert("color_r", math.Clamp(tonumber(color.r) or 100, 0, 255))
        ins:Insert("color_g", math.Clamp(tonumber(color.g) or 100, 0, 255))
        ins:Insert("color_b", math.Clamp(tonumber(color.b) or 100, 0, 255))
        ins:Insert("logoIndex", math.Clamp(tonumber(logoIndex) or 1, 1, 17))
        ins:Insert("createdAt", math.floor(os.time()))
        ins:Callback(function(_, status, lastID)
            if status and lastID then
                local createdAt = os.time()
                local faction = {
                    id = lastID,
                    name = string.sub(name, 1, 64),
                    founderCharID = founderCharID,
                    founderSteamID = founderCharID, 
                    color = {
                        r = math.Clamp(tonumber(color.r) or 100, 0, 255),
                        g = math.Clamp(tonumber(color.g) or 100, 0, 255),
                        b = math.Clamp(tonumber(color.b) or 100, 0, 255)
                    },
                    logoIndex = math.Clamp(tonumber(logoIndex) or 1, 1, 17),
                    members = {
                        [founderCharID] = { joinedAt = os.time(), role = founderRoleName, char_id = founderCharID }
                    },
                    roles = {
                        founder = {
                            id = "founder",
                            name = founderRoleName,
                            color = {
                                r = math.Clamp(tonumber(color.r) or 100, 0, 255),
                                g = math.Clamp(tonumber(color.g) or 100, 0, 255),
                                b = math.Clamp(tonumber(color.b) or 100, 0, 255)
                            },
                            precedence = 10000,
                            permissions = {}
                        }
                    },
                    createdAt = createdAt
                }

                factionsByID[lastID] = faction
                factionsByFounderID[founderCharID] = lastID

                local memIns = mysql:Insert("monarch_faction_members")
                memIns:Insert("factionID", lastID)
                memIns:Insert("steamID", founderCharID)
                memIns:Insert("role", founderRoleName)
                memIns:Insert("joinedAt", math.floor(os.time()))
                memIns:Execute()

                local roleIns = mysql:Insert("monarch_faction_roles")
                roleIns:Insert("factionID", lastID)
                roleIns:Insert("roleID", "founder")
                roleIns:Insert("name", founderRoleName)
                roleIns:Insert("color_r", faction.color.r)
                roleIns:Insert("color_g", faction.color.g)
                roleIns:Insert("color_b", faction.color.b)
                roleIns:Insert("precedence", 10000)
                roleIns:Insert("permissions", util.TableToJSON({}))
                roleIns:Execute()

                if isfunction(onCreated) then
                    onCreated(faction)
                end
            else
                if isfunction(onCreated) then
                    onCreated(nil)
                end
            end
        end)
        ins:Execute()

        local tempFaction = {
            id = 0,
            name = string.sub(name, 1, 64),
            founderCharID = founderCharID,
            founderSteamID = founderCharID,
            color = {
                r = math.Clamp(tonumber(color.r) or 100, 0, 255),
                g = math.Clamp(tonumber(color.g) or 100, 0, 255),
                b = math.Clamp(tonumber(color.b) or 100, 0, 255)
            },
            logoIndex = math.Clamp(tonumber(logoIndex) or 1, 1, 17),
            members = {
                [founderCharID] = { joinedAt = os.time(), role = founderRoleName, char_id = founderCharID }
            },
            roles = {
                founder = {
                    id = "founder",
                    name = founderRoleName,
                    color = {
                        r = math.Clamp(tonumber(color.r) or 100, 0, 255),
                        g = math.Clamp(tonumber(color.g) or 100, 0, 255),
                        b = math.Clamp(tonumber(color.b) or 100, 0, 255)
                    },
                    precedence = 10000,
                    permissions = {}
                }
            },
            createdAt = os.time()
        }

        return tempFaction
    end

    function Monarch.Factions.GetByID(factionID)
        return factionsByID[tonumber(factionID) or 0]
    end

    function Monarch.Factions.GetByFounder(founderCharID)
        local factionID = factionsByFounderID[tostring(founderCharID or "")]
        if factionID then
            return factionsByID[factionID]
        end
        return nil
    end

    local function migrateMembershipToCharID(ply, faction)
        if not (IsValid(ply) and faction) then return end
        local cid = getCharID(ply)
        if not cid or cid == "" then return end

        local sid64 = tostring(ply:SteamID64() or "")
        local sid = tostring(ply:SteamID() or "")
        local sourceKey = nil

        if sid64 ~= "" and faction.members and faction.members[sid64] then
            sourceKey = sid64
        elseif sid ~= "" and faction.members and faction.members[sid] then
            sourceKey = sid
        end

        if sourceKey and not faction.members[cid] then
            faction.members[cid] = table.Copy(faction.members[sourceKey])
            faction.members[cid].char_id = cid
            faction.members[cid].steamid = sid64 ~= "" and sid64 or sid
            faction.members[sourceKey] = nil

            if faction.founderCharID == sourceKey then
                factionsByFounderID[sourceKey] = nil
                faction.founderCharID = cid
                factionsByFounderID[cid] = faction.id
            end

            saveFaction(faction)
        end
    end

    function Monarch.Factions.GetPlayerFaction(idOrPlayer)
        local charID
        local ply

        if IsEntity(idOrPlayer) then
            ply = idOrPlayer
            charID = getCharID(ply)
        else
            charID = idOrPlayer
        end

        charID = tostring(charID or "")
        if charID ~= "" then
            for _, faction in pairs(factionsByID) do
                if faction.members and faction.members[charID] then
                    return faction
                end
            end
        end

        if ply then
            local steamID64 = tostring(ply:SteamID64() or "")
            local steamID = tostring(ply:SteamID() or "")
            for _, faction in pairs(factionsByID) do
                if faction.members and (
                    (steamID64 ~= "" and faction.members[steamID64]) or
                    (steamID ~= "" and faction.members[steamID])
                ) then
                    migrateMembershipToCharID(ply, faction)
                    return faction
                end
            end
        end

        return nil
    end

    function Monarch.Factions.Edit(factionID, field, value)
        local faction = factionsByID[tonumber(factionID) or 0]
        if not faction then return false, "Faction not found" end

        if field == "name" and isstring(value) then
            faction.name = string.sub(value, 1, 64)
        elseif field == "color" and istable(value) then
            faction.color = {
                r = math.Clamp(tonumber(value.r) or 100, 0, 255),
                g = math.Clamp(tonumber(value.g) or 100, 0, 255),
                b = math.Clamp(tonumber(value.b) or 100, 0, 255)
            }
        elseif field == "logoIndex" and isnumber(value) then
            faction.logoIndex = math.Clamp(value, 1, 17)
        else
            return false, "Invalid field or value"
        end

        saveFaction(faction)
        return true
    end

    function Monarch.Factions.AddMember(factionID, memberCharID, role)
        local faction = factionsByID[tonumber(factionID) or 0]
        if not faction then return false, "Faction not found" end

        memberCharID = tostring(memberCharID or "")
        if memberCharID == "" then return false, "Invalid character" end

        if faction.members[memberCharID] then
            return false, "Member already in faction"
        end

        faction.members[memberCharID] = {
            joinedAt = os.time(),
            role = role or "Member",
            char_id = memberCharID
        }

        saveFaction(faction)
        return true
    end

    function Monarch.Factions.RemoveMember(factionID, memberCharID)
        local faction = factionsByID[tonumber(factionID) or 0]
        if not faction then return false, "Faction not found" end

        memberCharID = tostring(memberCharID or "")
        if memberCharID == "" then return false, "Invalid character" end

        if not faction.members[memberCharID] then
            return false, "Member not in faction"
        end

        if memberCharID == faction.founderCharID then
            return false, "Cannot remove faction founder"
        end

        faction.members[memberCharID] = nil
        saveFaction(faction)
        return true
    end

    function Monarch.Factions.Disband(factionID)
        local faction = factionsByID[tonumber(factionID) or 0]
        if not faction then return false, "Faction not found" end

        if faction.founderCharID then
            factionsByFounderID[faction.founderCharID] = nil
        end
        factionsByID[factionID] = nil

        local del = mysql:Delete("monarch_factions")
        del:Where("id", factionID)
        del:Execute()

        local delm = mysql:Delete("monarch_faction_members")
        delm:Where("factionID", factionID)
        delm:Execute()

        local delr = mysql:Delete("monarch_faction_roles")
        delr:Where("factionID", factionID)
        delr:Execute()

        return true
    end

    function Monarch.Factions.GetAll()
        local result = {}
        for factionID, faction in pairs(factionsByID) do
            result[factionID] = faction
        end
        return result
    end

    function Monarch.Factions.GetPublicList()
        local result = {}
        for factionID, faction in pairs(factionsByID) do
            result[factionID] = {
                id = faction.id,
                name = faction.name,
                founderCharID = faction.founderCharID,
                founderSteamID = faction.founderSteamID or faction.founderCharID,
                color = faction.color,
                logoIndex = faction.logoIndex,
                memberCount = table.Count(faction.members or {}),
                createdAt = faction.createdAt
            }
        end
        return result
    end

    net.Receive("Monarch_Faction_Create", function(_, ply)
        if not IsValid(ply) then return end

        local name = net.ReadString()
        local founderRole = net.ReadString()
        local r, g, b = net.ReadUInt(8), net.ReadUInt(8), net.ReadUInt(8)
        local logoIndex = net.ReadUInt(8)

        local charID = getCharID(ply)
        if not charID then
            net.Start("Monarch_Faction_CreateResponse")
            net.WriteBool(false)
            net.WriteString("You must have an active character to create a faction")
            net.Send(ply)
            return
        end
        local color = { r = r, g = g, b = b }

        local faction, err = Monarch.Factions.Create(charID, name, founderRole, color, logoIndex, function(createdFaction)
            if not IsValid(ply) then return end
            net.Start("Monarch_Faction_CreateResponse")
            net.WriteBool(createdFaction ~= nil)
            if createdFaction then
                net.WriteTable(createdFaction)
            else
                net.WriteString("Faction create failed")
            end
            net.Send(ply)
        end)

        if not faction then
            net.Start("Monarch_Faction_CreateResponse")
            net.WriteBool(false)
            net.WriteString(err or "Unknown error")
            net.Send(ply)
        end
    end)

    net.Receive("Monarch_Faction_Edit", function(_, ply)
        if not IsValid(ply) then return end

        local factionID = net.ReadUInt(16)
        local field = net.ReadString()

        local faction = Monarch.Factions.GetByID(factionID)
        if not faction then return end

        local charID = getCharID(ply)
        if not charID then return end
        if not isFounderForPlayer(faction, ply, charID) and not Monarch.Factions.HasPermission(ply, "editInfo") then return end

        local value
        if field == "name" then
            value = net.ReadString()
        elseif field == "color" then
            value = { r = net.ReadUInt(8), g = net.ReadUInt(8), b = net.ReadUInt(8) }
        elseif field == "logoIndex" then
            value = net.ReadUInt(8)
        end

        local ok, err = Monarch.Factions.Edit(factionID, field, value)

        net.Start("Monarch_Faction_EditResponse")
        net.WriteBool(ok)
        if not ok then
            net.WriteString(err or "Unknown error")
        end
        net.Send(ply)
    end)

    net.Receive("Monarch_Faction_RequestList", function(_, ply)
        if not IsValid(ply) then return end

        local publicList = Monarch.Factions.GetPublicList()

        net.Start("Monarch_Faction_List")
        net.WriteTable(publicList)
        net.Send(ply)
    end)

    net.Receive("Monarch_Faction_Join", function(_, ply)
        if not IsValid(ply) then return end

        local factionID = net.ReadUInt(16)
        local charID = getCharID(ply)
        if not charID then return end

        local faction = Monarch.Factions.GetByID(factionID)
        if not faction then return end

        if Monarch.Factions.GetPlayerFaction(charID) then
            net.Start("Monarch_Faction_JoinResponse")
            net.WriteBool(false)
            net.WriteString("Already in a faction")
            net.Send(ply)
            return
        end

        local ok, err = Monarch.Factions.AddMember(factionID, charID, "Member")

        net.Start("Monarch_Faction_JoinResponse")
        net.WriteBool(ok)
        if not ok then
            net.WriteString(err or "Unknown error")
        end
        net.Send(ply)
    end)

    net.Receive("Monarch_Faction_Leave", function(_, ply)
        if not IsValid(ply) then return end

        local charID = getCharID(ply)
        if not charID then return end

        local faction = Monarch.Factions.GetPlayerFaction(charID)

        if not faction then
            net.Start("Monarch_Faction_LeaveResponse")
            net.WriteBool(false)
            net.WriteString("Not in a faction")
            net.Send(ply)
            return
        end

        local ok, err

        if isFounderForPlayer(faction, ply, charID) then
            ok, err = Monarch.Factions.Disband(faction.id)
        else
            ok, err = Monarch.Factions.RemoveMember(faction.id, charID)
        end

        net.Start("Monarch_Faction_LeaveResponse")
        net.WriteBool(ok)
        if not ok then
            net.WriteString(err or "Unknown error")
        end
        net.Send(ply)
    end)

    net.Receive("Monarch_Faction_RequestPlayerFaction", function(_, ply)
        if not IsValid(ply) then return end
        syncFactionToPlayer(ply)
    end)

    net.Receive("Monarch_Role_Create", function(_, ply)
        if not IsValid(ply) then return end

        local charID = getCharID(ply)
        if not charID then return end

        local faction = Monarch.Factions.GetPlayerFaction(charID)
        if not faction then
            return
        end

        if not isFounderForPlayer(faction, ply, charID) and not Monarch.Factions.HasPermission(ply, "manageRoles") then
            return
        end

        local name = net.ReadString()
        local r = net.ReadUInt(8)
        local g = net.ReadUInt(8)
        local b = net.ReadUInt(8)
        local precedence = net.ReadUInt(16)
        local permissions = net.ReadTable() or {}

        local role = Monarch.Factions.CreateRole(faction.id, name, { r = r, g = g, b = b }, precedence, permissions)

        if role then
            net.Start("Monarch_Role_Created")
            net.WriteBool(true)
            net.WriteTable(role)
            net.Send(ply)

            net.Start("Monarch_Faction_Updated")
            net.WriteTable(faction)
            net.Broadcast()
        end
    end)

    net.Receive("Monarch_Role_Update", function(_, ply)
        if not IsValid(ply) then return end

        local charID = getCharID(ply)
        if not charID then return end

        local faction = Monarch.Factions.GetPlayerFaction(charID)
        if not faction then
            return
        end

        if not isFounderForPlayer(faction, ply, charID) and not Monarch.Factions.HasPermission(ply, "manageRoles") then
            return
        end

        local roleID = net.ReadString()
        local name = net.ReadString()
        local r = net.ReadUInt(8)
        local g = net.ReadUInt(8)
        local b = net.ReadUInt(8)
        local precedence = net.ReadUInt(16)
        local permissions = net.ReadTable() or {}

        local success = Monarch.Factions.UpdateRole(faction.id, roleID, name, { r = r, g = g, b = b }, precedence, permissions)

        if success then
            net.Start("Monarch_Role_Updated")
            net.WriteBool(true)
            net.Send(ply)

            net.Start("Monarch_Faction_Updated")
            net.WriteTable(faction)
            net.Broadcast()
        end
    end)

    net.Receive("Monarch_Role_Delete", function(_, ply)
        if not IsValid(ply) then return end

        local charID = getCharID(ply)
        if not charID then return end

        local faction = Monarch.Factions.GetPlayerFaction(charID)
        if not faction then
            return
        end

        if not isFounderForPlayer(faction, ply, charID) and not Monarch.Factions.HasPermission(ply, "manageRoles") then
            return
        end

        local roleID = net.ReadString()
        local success = Monarch.Factions.DeleteRole(faction.id, roleID)

        if success then
            net.Start("Monarch_Role_Deleted")
            net.WriteBool(true)
            net.Send(ply)

            net.Start("Monarch_Faction_Updated")
            net.WriteTable(faction)
            net.Broadcast()
        end
    end)

    net.Receive("Monarch_Faction_SetMemberRole", function(_, ply)
        if not IsValid(ply) then return end

        local actorCharID = getCharID(ply)
        if not actorCharID then return end

        local faction = Monarch.Factions.GetPlayerFaction(actorCharID)
        if not faction then return end

        if not isFounderForPlayer(faction, ply, actorCharID) and not Monarch.Factions.HasPermission(ply, "editMemberRoles") then
            net.Start("Monarch_Faction_SetMemberRoleResponse")
            net.WriteBool(false)
            net.WriteString("You do not have permission to edit member roles.")
            net.Send(ply)
            return
        end

        local memberKey = tostring(net.ReadString() or "")
        local requestedRole = string.Trim(tostring(net.ReadString() or ""))

        if memberKey == "" then
            net.Start("Monarch_Faction_SetMemberRoleResponse")
            net.WriteBool(false)
            net.WriteString("Invalid member selection.")
            net.Send(ply)
            return
        end

        local function resolveFactionMemberKey(targetFaction, key)
            key = tostring(key or "")
            if key == "" then return nil end

            if targetFaction.members and targetFaction.members[key] then
                return key
            end

            for existingKey, memberData in pairs(targetFaction.members or {}) do
                local memberSID = tostring(memberData and memberData.steamid or "")
                if memberSID ~= "" and memberSID == key then
                    return tostring(existingKey)
                end
            end

            local foundPlayer = findPlayerByMemberKey(key)
            if IsValid(foundPlayer) then
                local cid, sid64, sid = getIdentityKeys(foundPlayer)
                if cid and targetFaction.members[cid] then return cid end
                if sid64 and targetFaction.members[sid64] then return sid64 end
                if sid and targetFaction.members[sid] then return sid end
            end

            return nil
        end

        local resolvedMemberKey = resolveFactionMemberKey(faction, memberKey)
        if not resolvedMemberKey then
            net.Start("Monarch_Faction_SetMemberRoleResponse")
            net.WriteBool(false)
            net.WriteString("Member not found in faction.")
            net.Send(ply)
            return
        end

        local founderKey = tostring(faction.founderCharID or faction.founderSteamID or "")
        local targetMemberData = faction.members and faction.members[resolvedMemberKey] or nil
        local targetMemberSID = tostring(targetMemberData and targetMemberData.steamid or "")
        if founderKey ~= "" and (resolvedMemberKey == founderKey or targetMemberSID == founderKey) then
            net.Start("Monarch_Faction_SetMemberRoleResponse")
            net.WriteBool(false)
            net.WriteString("You cannot change the founder's role.")
            net.Send(ply)
            return
        end

        local function resolveRoleName(targetFaction, rawRole)
            local requested = string.Trim(tostring(rawRole or ""))
            if requested == "" then
                return "Member"
            end

            if string.lower(requested) == "member" then
                return "Member"
            end

            local lowered = string.lower(requested)
            for roleID, roleData in pairs(targetFaction.roles or {}) do
                local roleName = tostring(roleData and roleData.name or "")
                if roleName ~= "" and (
                    roleID == requested
                    or string.lower(tostring(roleID)) == lowered
                    or string.lower(roleName) == lowered
                ) then
                    return roleName
                end
            end

            return nil
        end

        local resolvedRole = resolveRoleName(faction, requestedRole)
        if not resolvedRole then
            net.Start("Monarch_Faction_SetMemberRoleResponse")
            net.WriteBool(false)
            net.WriteString("Selected role does not exist.")
            net.Send(ply)
            return
        end

        local ok, err = Monarch.Factions.SetMemberRole(faction.id, resolvedMemberKey, resolvedRole)
        net.Start("Monarch_Faction_SetMemberRoleResponse")
        net.WriteBool(ok)
        net.WriteString(ok and "Member role updated." or (err or "Failed to update role."))
        net.Send(ply)

        if ok then
            net.Start("Monarch_Faction_Updated")
            net.WriteTable(faction)
            net.Broadcast()
        end
    end)

    net.Receive("Monarch_Faction_Announcement", function(_, ply)
        if not IsValid(ply) then return end

        local charID = getCharID(ply)
        if not charID then return end

        local faction = Monarch.Factions.GetPlayerFaction(charID)
        if not faction then
            return
        end

        if not isFounderForPlayer(faction, ply, charID) and not Monarch.Factions.HasPermission(ply, "makeAnnouncements") then
            return
        end

        local message = net.ReadString()
        if not message or message == "" or string.len(message) < 3 then
            return
        end

        if string.len(message) > 500 then
            message = string.sub(message, 1, 500)
        end

        local timestamp = os.date("%d/%m/%Y - %H:%M:%S")

        local function sendAnnouncement(player)
            if not IsValid(player) then return end
            net.Start("Monarch_Faction_ShowAnnouncement")
            net.WriteString(faction.name)
            net.WriteUInt(faction.logoIndex or 1, 8)
            net.WriteUInt(faction.color.r or 100, 8)
            net.WriteUInt(faction.color.g or 100, 8)
            net.WriteUInt(faction.color.b or 100, 8)
            net.WriteString(ply.GetRPName and ply:GetRPName() or ply:Nick())
            net.WriteString(message)
            net.WriteString(timestamp)
            net.Send(player)
        end

        for memberCharID, _ in pairs(faction.members or {}) do
            local member = findPlayerByMemberKey(memberCharID)
            sendAnnouncement(member)
        end
    end)

    function Monarch.Factions.SetMemberRole(factionID, memberCharID, role)
        local faction = factionsByID[tonumber(factionID) or 0]
        if not faction then return false, "Faction not found" end

        if not faction.members[memberCharID] then
            return false, "Member not in faction"
        end

        faction.members[memberCharID].role = role or "Member"

        saveFaction(faction)
        return true
    end

    function Monarch.Factions.CreateRole(factionID, name, color, precedence, permissions)
        local faction = factionsByID[tonumber(factionID) or 0]
        if not faction then return nil, "Faction not found" end

        faction.roles = faction.roles or {}

        local roleID = "role_" .. tostring(math.abs(tonumber(os.time() .. math.random(1000, 9999))))

        local role = {
            id = roleID,
            name = string.sub(tostring(name), 1, 32),
            color = {
                r = math.Clamp(tonumber(color.r) or 100, 0, 255),
                g = math.Clamp(tonumber(color.g) or 100, 0, 255),
                b = math.Clamp(tonumber(color.b) or 100, 0, 255)
            },
            precedence = math.max(0, tonumber(precedence) or 0),
            permissions = permissions or {}
        }

        faction.roles[roleID] = role
        saveFaction(faction)

        return role
    end

    function Monarch.Factions.UpdateRole(factionID, roleID, name, color, precedence, permissions)
        local faction = factionsByID[tonumber(factionID) or 0]
        if not faction then return false, "Faction not found" end

        if not faction.roles or not faction.roles[roleID] then
            return false, "Role not found"
        end

        local role = faction.roles[roleID]
        local oldRoleName = role.name
        if name then role.name = string.sub(tostring(name), 1, 32) end
        if color then
            role.color = {
                r = math.Clamp(tonumber(color.r) or role.color.r, 0, 255),
                g = math.Clamp(tonumber(color.g) or role.color.g, 0, 255),
                b = math.Clamp(tonumber(color.b) or role.color.b, 0, 255)
            }
        end
        if precedence then
            role.precedence = math.max(0, tonumber(precedence) or 0)
        end
        if permissions then
            role.permissions = permissions
        end

        if oldRoleName and role.name and oldRoleName ~= role.name then
            for _, member in pairs(faction.members or {}) do
                if member.role == oldRoleName then
                    member.role = role.name
                end
            end
        end

        saveFaction(faction)
        return true
    end

    function Monarch.Factions.DeleteRole(factionID, roleID)
        local faction = factionsByID[tonumber(factionID) or 0]
        if not faction then return false, "Faction not found" end

        if not faction.roles or not faction.roles[roleID] then
            return false, "Role not found"
        end

        local roleName = faction.roles[roleID].name
        for _, member in pairs(faction.members or {}) do
            if member.role == roleName then
                member.role = "Member"
            end
        end

        faction.roles[roleID] = nil
        saveFaction(faction)
        return true
    end

    function Monarch.Factions.GetRoles(factionID)
        local faction = factionsByID[tonumber(factionID) or 0]
        if not faction then return {} end

        return faction.roles or {}
    end

    function Monarch.Factions.HasPermission(idOrPlayer, permissionKey)
        local faction = Monarch.Factions.GetPlayerFaction(idOrPlayer)
        if not faction then return false end

        local charID = idOrPlayer
        if IsEntity(idOrPlayer) then
            charID = getCharID(idOrPlayer)
        end

        charID = tostring(charID or "")

        if IsEntity(idOrPlayer) and isFounderForPlayer(faction, idOrPlayer, charID) then return true end
        if not IsEntity(idOrPlayer) and tostring(faction.founderCharID or faction.founderSteamID or "") == charID then return true end

        local member = faction.members[charID]
        if not member and IsEntity(idOrPlayer) then
            local _, sid64, sid = getIdentityKeys(idOrPlayer)
            if sid64 and faction.members[sid64] then
                member = faction.members[sid64]
            elseif sid and faction.members[sid] then
                member = faction.members[sid]
            end
        end
        if not member or not member.role then return false end

        local roleData = nil
        if faction.roles then
            roleData = faction.roles[member.role]
        end

        if not roleData then
            for roleID, role in pairs(faction.roles or {}) do
                if role.name == member.role or roleID == member.role then
                    roleData = role
                    break
                end
            end
        end

        if not roleData then return false end
        return roleData.permissions and roleData.permissions[permissionKey] or false
    end

    syncFactionToPlayer = function(ply)
        if not IsValid(ply) then return end

        local faction = Monarch.Factions.GetPlayerFaction(ply)
        net.Start("Monarch_Faction_PlayerData")
        if faction then
            net.WriteBool(true)
            net.WriteTable(faction)
        else
            net.WriteBool(false)
        end
        net.Send(ply)

        net.Start("Monarch_Faction_PermissionsList")
        net.WriteTable(registeredPermissions)
        net.Send(ply)
    end

    Monarch.Factions.SyncPlayer = syncFactionToPlayer

    hook.Add("Initialize", "Monarch_LoadFactions", function()
        loadAllFactions()
        initializeDefaultPermissions()
    end)

    hook.Add("PlayerInitialSpawn", "Monarch_LoadPlayerFaction", function(ply)
        if not IsValid(ply) then return end
        timer.Simple(0.5, function()
            if not IsValid(ply) then return end
            syncFactionToPlayer(ply)
        end)
    end)

    hook.Add("OnCharacterActivated", "Monarch_Factions_SyncOnCharActivate", function(ply)
        if not IsValid(ply) then return end
        timer.Simple(0, function()
            if not IsValid(ply) then return end
            syncFactionToPlayer(ply)
        end)
    end)
end