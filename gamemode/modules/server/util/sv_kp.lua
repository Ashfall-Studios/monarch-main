Monarch = Monarch or {}
Monarch.Introductions = Monarch.Introductions or {}

util.AddNetworkString("Monarch_IntroducePlayer")
util.AddNetworkString("Monarch_RequestContextMenu")
util.AddNetworkString("Monarch_SendContextMenu")
util.AddNetworkString("Monarch_UpdateIntroductions")
util.AddNetworkString("Monarch_AdminForceIntroduce")
util.AddNetworkString("Monarch_SearchInventory")
util.AddNetworkString("Monarch_SearchInventoryResponse")
util.AddNetworkString("Monarch_SearchInventory_Admin")
util.AddNetworkString("Monarch_SearchInventoryResponse_Admin")
util.AddNetworkString("Monarch_ConfiscateItem")
util.AddNetworkString("Monarch_ConfiscateItem_Admin")
util.AddNetworkString("Monarch_FactionInvite_Prompt")
util.AddNetworkString("Monarch_FactionInvite_Response")
util.AddNetworkString("Monarch_FactionInvite_Result")

local pendingFactionInvites = pendingFactionInvites or {}

-- Classes covered by the context replacement even if they do not follow common prefixes.
local CONTEXT_ENTITY_CLASS_ALLOWLIST = {
    ["ammobox"] = true,
    ["hl2rp_bed"] = true,
    ["hl2rp_couch"] = true,
    ["hl2rp_mattress"] = true,
    ["item"] = true,
    ["monarch_atm"] = true,
    ["monarch_bodygroup_closet"] = true,
    ["monarch_computer"] = true,
    ["monarch_craftingbench"] = true,
    ["monarch_loot"] = true,
    ["monarch_ocman"] = true,
    ["monarch_rankvendor"] = true,
    ["monarch_storage"] = true,
    ["monarch_vehiclevendor"] = true,
    ["monarch_vendor"] = true,
    ["radio"] = true,
    ["ration_terminal"] = true,
    ["rp_bed"] = true,
    ["rp_monarch_container"] = true,
    ["rp_monarch_disassemblytable"] = true,
    ["rp_monarch_extractiontable"] = true,
    ["rp_monarch_factory"] = true,
    ["rp_monarch_fuelcontainer"] = true,
    ["rp_monarch_materials"] = true,
    ["rp_monarch_oilcontainer"] = true,
    ["rp_monarch_packagingbench"] = true,
    ["rp_monarch_partscontainer"] = true,
    ["rp_monarch_product"] = true,
    ["rp_monarch_shipmentcontainer"] = true,
    ["rp_sink"] = true
}

-- Prefixes used by framework/schema scripted entities that should route Use through context.
local CONTEXT_ENTITY_CLASS_PREFIXES = {
    "monarch_",
    "rp_monarch_",
    "hl2rp_"
}

local CONTEXT_ENTITY_CLASS_BLOCKLIST = {
    ["monarch_craftingbench"] = true
}

local function KP_Notify(ply, msg)
    if not IsValid(ply) then return end
    if ply.Notify then
        ply:Notify(msg)
    else
        ply:ChatPrint(msg)
    end
end

local function KP_GetCharID(ply)
    if not IsValid(ply) then return nil end
    local cid = ply.MonarchID or (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or (ply.GetCharID and ply:GetCharID())
    if cid == nil then return nil end
    cid = tostring(cid)
    if cid == "" then return nil end
    return cid
end

local function KP_CanInviteToFaction(ply, target)
    if not (IsValid(ply) and IsValid(target) and ply:IsPlayer() and target:IsPlayer()) then return false end
    if ply == target then return false end

    if not (Monarch and Monarch.Factions and Monarch.Factions.GetPlayerFaction and Monarch.Factions.HasPermission) then
        return false
    end

    local inviterFaction = Monarch.Factions.GetPlayerFaction(ply)
    if not inviterFaction then return false end

    local inviterCharID = KP_GetCharID(ply)
    if not inviterCharID then return false end

    local founderKey = tostring(inviterFaction.founderCharID or inviterFaction.founderSteamID or "")
    local isFounder = founderKey ~= "" and (
        founderKey == inviterCharID or
        founderKey == tostring(ply:SteamID64() or "") or
        founderKey == tostring(ply:SteamID() or "")
    )

    if not isFounder and not Monarch.Factions.HasPermission(ply, "invite") then
        return false
    end

    local targetFaction = Monarch.Factions.GetPlayerFaction(target)
    if targetFaction then return false end

    return true
end

local function KP_FindPlayerBySID64(sid64)
    if not sid64 or sid64 == "" then return nil end
    for _, candidate in player.Iterator() do
        if IsValid(candidate) and candidate:SteamID64() == sid64 then
            return candidate
        end
    end
    return nil
end

local function KP_SendFactionInviteResult(ply, message, isError, refreshFaction)
    if not IsValid(ply) then return end

    net.Start("Monarch_FactionInvite_Result")
    net.WriteString(tostring(message or ""))
    net.WriteBool(isError == true)
    net.WriteBool(refreshFaction == true)
    net.Send(ply)
end

local function KP_ClearFactionInviteForTarget(targetSID64)
    if not targetSID64 or targetSID64 == "" then return end
    pendingFactionInvites[targetSID64] = nil
end

local function KP_IsContextReplacedClass(className)
    if not isstring(className) or className == "" then
        return false
    end

    if CONTEXT_ENTITY_CLASS_BLOCKLIST[className] then
        return false
    end

    if CONTEXT_ENTITY_CLASS_ALLOWLIST[className] then
        return true
    end

    for _, prefix in ipairs(CONTEXT_ENTITY_CLASS_PREFIXES) do
        if string.StartWith(className, prefix) then
            return true
        end
    end

    return false
end

local function KP_IsContextReplacedEntity(target)
    if not IsValid(target) or target:IsPlayer() then
        return false
    end

    return KP_IsContextReplacedClass(target:GetClass())
end

local function KP_ShouldShowEntityContext(target, activator)
    if not IsValid(target) or not KP_IsContextReplacedEntity(target) then
        return false
    end

    local rule = target.ShouldShowContext
    if isbool(rule) then
        return rule
    end

    if isfunction(rule) then
        local ok, result = pcall(rule, target, activator)
        return ok and result == true
    end

    return false
end

local function KP_GenerateDefaultContextLabel(className, printName)
    if isstring(printName) and string.Trim(printName) ~= "" and printName ~= "Entity" then
        return "Use " .. printName
    end

    local readableClass = className or ""
    readableClass = string.gsub(readableClass, "^rp_monarch_", "")
    readableClass = string.gsub(readableClass, "^monarch_", "")
    readableClass = string.gsub(readableClass, "^hl2rp_", "")
    readableClass = string.gsub(readableClass, "^rp_", "")

    local readable = string.Trim(string.gsub(readableClass, "[_%-]", " "))
    if readable == "" then
        return "Use"
    end

    readable = string.lower(readable)
    readable = string.gsub(readable, "(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. rest
    end)

    local lowerClass = string.lower(className or "")
    if string.find(lowerClass, "bed", 1, true) or string.find(lowerClass, "couch", 1, true) or string.find(lowerClass, "mattress", 1, true) then
        return "Sleep"
    end
    if string.find(lowerClass, "loot", 1, true) then
        return "Search " .. readable
    end
    if string.find(lowerClass, "atm", 1, true)
        or string.find(lowerClass, "terminal", 1, true)
        or string.find(lowerClass, "storage", 1, true)
        or string.find(lowerClass, "container", 1, true)
        or string.find(lowerClass, "vendor", 1, true)
        or string.find(lowerClass, "computer", 1, true)
        or string.find(lowerClass, "closet", 1, true)
    then
        return "Open " .. readable
    end

    return "Use " .. readable
end

local function KP_GetEntityUseLabel(target)
    if not IsValid(target) then return "Use" end

    local custom = target.ContextLabel or target.MonarchContextUseLabel
    if isstring(custom) and string.Trim(custom) ~= "" then
        return custom
    end

    local className = target:GetClass()
    local stored = scripted_ents.GetStored(className)
    if stored and istable(stored.t) then
        local storedLabel = stored.t.ContextLabel or stored.t.MonarchContextUseLabel
        if isstring(storedLabel) and string.Trim(storedLabel) ~= "" then
            return storedLabel
        end
    end

    return KP_GenerateDefaultContextLabel(className, target.PrintName)
end

local function KP_GetContextAnchorPos(target, activator)
    if not IsValid(target) then return nil end

    local anchorPos = target:GetPos()
    if not IsValid(activator) or not target.GetFenceA or not target.GetFenceB then
        return anchorPos
    end

    local fenceA = target:GetFenceA()
    local fenceB = target:GetFenceB()
    local activatorPos = activator:GetPos()
    local bestDist = math.huge

    if IsValid(fenceA) then
        local dist = activatorPos:DistToSqr(fenceA:GetPos())
        if dist < bestDist then
            bestDist = dist
            anchorPos = fenceA:GetPos()
        end
    end

    if IsValid(fenceB) then
        local dist = activatorPos:DistToSqr(fenceB:GetPos())
        if dist < bestDist then
            anchorPos = fenceB:GetPos()
        end
    end

    return anchorPos
end

local function KP_ResolveStoredUseFunction(className, visited)
    if not isstring(className) or className == "" then return nil end

    visited = visited or {}
    if visited[className] then return nil end
    visited[className] = true

    local stored = scripted_ents.GetStored(className)
    if not stored or not istable(stored.t) then return nil end

    local entTable = stored.t
    if isfunction(entTable.Use) then
        return entTable.Use
    end

    local baseClass = entTable.Base
    if not isstring(baseClass) or baseClass == "" then
        return nil
    end

    return KP_ResolveStoredUseFunction(baseClass, visited)
end

local function KP_SendContextMenuToPlayer(ply, target)
    if not IsValid(ply) or not IsValid(target) or target == ply then return end
    local anchorPos = KP_GetContextAnchorPos(target, ply)
    if not anchorPos or ply:GetPos():DistToSqr(anchorPos) > (150 * 150) then return end

    local options = {}

    if target:GetClass() == "prop_ragdoll" then
        local isDeceased = target.MonarchDeceased or target.FallDeath

        if isDeceased then
            table.insert(options, {
                text = "Body Status: Deceased",
                action = "none",
                target = target
            })
        else
            table.insert(options, {
                text = "Perform CPR",
                action = "corpse_cpr",
                target = target
            })
        end

        table.insert(options, {
            text = "None",
            action = "none",
            target = target
        })

        net.Start("Monarch_SendContextMenu")
        net.WriteEntity(target)
        net.WriteUInt(#options, 8)

        for _, option in ipairs(options) do
            net.WriteString(option.text)
            net.WriteString(option.action)
        end

        net.Send(ply)
        return
    end

    if target:IsPlayer() then
        table.insert(options, {
            text = "Introduce yourself",
            action = "introduce_self",
            target = target
        })

        table.insert(options, {
            text = "Take Pulse",
            action = "take_pulse",
            target = target
        })

        table.insert(options, {
            text = "Give Cash",
            action = "give_cash",
            target = target
        })

        if KP_CanInviteToFaction(ply, target) then
            table.insert(options, {
                text = "Invite to Faction",
                action = "faction_invite",
                target = target
            })
        end

        if target:GetNWBool("MonarchCuffed") then
            table.insert(options, {
                text = "Search Inventory",
                action = "search_inventory",
                target = target
            })
        end

        hook.Run("MonarchBuildPlayerContextOptions", ply, target, options)
    else
        if not KP_ShouldShowEntityContext(target, ply) then return end

        if not isfunction(target.MonarchOriginalUse) then return end

        table.insert(options, {
            text = KP_GetEntityUseLabel(target),
            action = "entity_use",
            target = target
        })

        -- Allow schema/framework modules to append additional entity-specific options.
        hook.Run("MonarchBuildEntityContextOptions", ply, target, options)
    end

    table.insert(options, {
        text = "None",
        action = "none",
        target = target
    })

    net.Start("Monarch_SendContextMenu")
    net.WriteEntity(target)
    net.WriteUInt(#options, 8)

    for _, option in ipairs(options) do
        net.WriteString(option.text)
        net.WriteString(option.action)
    end

    net.Send(ply)
end

local function KP_PatchEntityClassUse(className)
    if not KP_IsContextReplacedClass(className) then return end

    local stored = scripted_ents.GetStored(className)
    if not stored or not istable(stored.t) then return end

    local entTable = stored.t
    if entTable.MonarchContextUsePatched then return end

    local originalUse = entTable.Use
    if not isfunction(originalUse) then
        originalUse = KP_ResolveStoredUseFunction(className)
    end
    if not isfunction(originalUse) then return end

    -- Every patched entity gets a default ContextLabel unless the entity defines its own.
    if not isstring(entTable.ContextLabel) or string.Trim(entTable.ContextLabel) == "" then
        entTable.ContextLabel = KP_GenerateDefaultContextLabel(className, entTable.PrintName)
    end

    entTable.MonarchOriginalUse = originalUse
    entTable.Use = function(self, activator, caller, useType, value)
        if self.MonarchExecutingContextUse then
            return self.MonarchOriginalUse(self, activator, caller, useType, value)
        end

        if not IsValid(activator) or not activator:IsPlayer() then
            return self.MonarchOriginalUse(self, activator, caller, useType, value)
        end

        if not KP_ShouldShowEntityContext(self, activator) then
            return self.MonarchOriginalUse(self, activator, caller, useType, value)
        end

        -- Player interaction is handled by client hold-E request; block direct Use execution.
        return
    end

    entTable.MonarchContextUsePatched = true
end

local function KP_PatchAllEntityUseHandlers()
    for className in pairs(CONTEXT_ENTITY_CLASS_ALLOWLIST) do
        KP_PatchEntityClassUse(className)
    end

    local registered = scripted_ents.GetList() or {}
    for className in pairs(registered) do
        KP_PatchEntityClassUse(className)
    end
end

hook.Add("InitPostEntity", "Monarch_PatchEntityUseForContextMenu", function()
    KP_PatchAllEntityUseHandlers()
end)

hook.Add("OnEntityCreated", "Monarch_PatchContextUseForLateEntities", function(ent)
    if not IsValid(ent) then return end

    timer.Simple(0, function()
        if not IsValid(ent) then return end
        KP_PatchEntityClassUse(ent:GetClass())
    end)
end)

net.Receive("Monarch_AdminForceIntroduce", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    local target = net.ReadEntity()
    local name = net.ReadString()

    if not IsValid(target) or target == ply then return end
    name = string.Trim(name or "")
    if name == "" then return end

    net.Start("Monarch_UpdateIntroductions")
        net.WriteEntity(target)
        net.WriteString(name)
    net.Send(ply)
end)

local playerIntroductions = {}

Monarch.Introductions.DefaultTeamKnowledge = Monarch.Introductions.DefaultTeamKnowledge or {}

local function TeamRuleMatchesTargetTeam(teamRules, targetTeam)
    if teamRules == true then
        return true
    end

    if not istable(teamRules) then
        return false
    end

    if teamRules[targetTeam] ~= nil then
        return teamRules[targetTeam] and true or false
    end

    for _, teamId in ipairs(teamRules) do
        if teamId == targetTeam then
            return true
        end
    end

    return false
end

function Monarch.Introductions.SetDefaultTeamKnowledge(rules)
    Monarch.Introductions.DefaultTeamKnowledge = istable(rules) and rules or {}
end

function Monarch.Introductions.GetDefaultTeamKnowledge()
    return Monarch.Introductions.DefaultTeamKnowledge or {}
end

local function InitializePlayerIntroductions(ply)
    if not playerIntroductions[ply] then
        playerIntroductions[ply] = {}
    end

    for _, otherPly in player.Iterator() do
        if otherPly ~= ply then
            if not playerIntroductions[ply][otherPly] then
                playerIntroductions[ply][otherPly] = false
            end
            if not playerIntroductions[otherPly] then
                playerIntroductions[otherPly] = {}
            end
            if not playerIntroductions[otherPly][ply] then
                playerIntroductions[otherPly][ply] = false
            end
        end
    end
end

local function SyncKnownName(observer, target, knownName)
    if not IsValid(observer) or not IsValid(target) then return false end

    InitializePlayerIntroductions(observer)

    local introducedName = knownName or target:GetRPName() or target:Nick()
    if not introducedName or introducedName == "" then
        introducedName = target:Nick()
    end

    if playerIntroductions[observer][target] == introducedName then
        return false
    end

    playerIntroductions[observer][target] = introducedName

    net.Start("Monarch_UpdateIntroductions")
        net.WriteEntity(target)
        net.WriteString(introducedName)
    net.Send(observer)

    return true
end

local function ShouldKnowTargetByDefault(observer, target)
    if not IsValid(observer) or not IsValid(target) then return false end
    if observer == target then return false end

    local observerTeam = observer:Team()
    local targetTeam = target:Team()
    if not observerTeam or not targetTeam then return false end

    local rules = Monarch.Introductions.DefaultTeamKnowledge or {}
    local teamRules = rules[observerTeam]
    if teamRules == nil then
        return false
    end

    return TeamRuleMatchesTargetTeam(teamRules, targetTeam)
end

local function ApplyDefaultKnowledgeForObserver(observer, specificTarget)
    if not IsValid(observer) then return end

    if IsValid(specificTarget) then
        if specificTarget ~= observer and ShouldKnowTargetByDefault(observer, specificTarget) then
            SyncKnownName(observer, specificTarget)
        end
        return
    end

    for _, target in player.Iterator() do
        if target ~= observer and ShouldKnowTargetByDefault(observer, target) then
            SyncKnownName(observer, target)
        end
    end
end

function Monarch.Introductions.ApplyDefaultTeamKnowledge(observer, specificTarget)
    ApplyDefaultKnowledgeForObserver(observer, specificTarget)
end

function Monarch.Introductions.GetKnownName(observer, target)
    if not IsValid(observer) or not IsValid(target) then return "Unknown" end
    if observer == target then return target:GetRPName() or target:Nick() end

    if not playerIntroductions[observer] or not playerIntroductions[observer][target] then
        return "Unknown"
    end

    local knownName = playerIntroductions[observer][target]
    return knownName or "Unknown"
end

function Monarch.Introductions.IntroducePlayer(introducer, target, observer, customName)
    if not IsValid(introducer) or not IsValid(target) or not IsValid(observer) then return false end

    if introducer == target then return false end

    local introducedName = customName or target:GetRPName() or target:Nick()
    SyncKnownName(observer, target, introducedName)

    if observer == introducer then
        target:ChatPrint(introducer:Nick() .. " introduces themselves as '" .. introducedName .. "'")
        introducer:ChatPrint("You introduce yourself to " .. target:Nick() .. " as '" .. introducedName .. "'")
    else
        observer:ChatPrint(introducer:Nick() .. " introduces " .. target:Nick() .. " as '" .. introducedName .. "'")
        target:ChatPrint(introducer:Nick() .. " introduces you to " .. observer:Nick() .. " as '" .. introducedName .. "'")
        introducer:ChatPrint("You introduce " .. target:Nick() .. " to " .. observer:Nick() .. " as '" .. introducedName .. "'")
    end

    return true
end

local function AdminIntroduceCommand(admin, cmd, args)
    if not admin:IsAdmin() then
        admin:ChatPrint("You don't have permission to use this command.")
        return
    end

    if #args < 3 then
        admin:ChatPrint("Usage: !introduce <target> <observer> <name>")
        return
    end

    local targetName = args[1]
    local observerName = args[2]
    local introducedName = table.concat(args, " ", 3)

    local target = nil
    local observer = nil

    for _, ply in player.Iterator() do
        if string.find(string.lower(ply:Nick()), string.lower(targetName)) then
            target = ply
            break
        end
    end

    for _, ply in player.Iterator() do
        if string.find(string.lower(ply:Nick()), string.lower(observerName)) then
            observer = ply
            break
        end
    end

    if not target then
        admin:ChatPrint("Could not find target player: " .. targetName)
        return
    end

    if not observer then
        admin:ChatPrint("Could not find observer player: " .. observerName)
        return
    end

    if Monarch.Introductions.IntroducePlayer(admin, target, observer, introducedName) then
        admin:ChatPrint("Successfully introduced " .. target:Nick() .. " to " .. observer:Nick() .. " as '" .. introducedName .. "'")
    else
        admin:ChatPrint("Failed to introduce players.")
    end
end

if Monarch and Monarch.ChatCommands and Monarch.ChatCommands.Add then
    Monarch.ChatCommands.Add("introduce", AdminIntroduceCommand, {
        description = "Introduce one player to another",
        usage = "!introduce <target> <observer> <name>",
        adminOnly = true
    })
end

net.Receive("Monarch_IntroducePlayer", function(len, ply)
    local target = net.ReadEntity()
    local introducedName = net.ReadString()

    if not IsValid(target) or target == ply then return end

    local witnesses = {}
    local maxDistance = 300

    for _, witness in player.Iterator() do
        if witness ~= ply and witness:GetPos():Distance(ply:GetPos()) <= maxDistance then
            table.insert(witnesses, witness)
        end
    end

    for _, witness in ipairs(witnesses) do
        Monarch.Introductions.IntroducePlayer(ply, ply, witness, introducedName)
    end
end)
util.AddNetworkString("Monarch_SelectContextOption")

net.Receive("Monarch_SelectContextOption", function(len, ply)
    local target = net.ReadEntity()
    local action = net.ReadString()

    if not IsValid(target) or target == ply then return end

    local anchorPos = KP_GetContextAnchorPos(target, ply)
    if not anchorPos or ply:GetPos():DistToSqr(anchorPos) > (150 * 150) then return end

    if action == "entity_use" then
        if not KP_ShouldShowEntityContext(target, ply) then return end

        if isfunction(target.Use) then
            target.MonarchExecutingContextUse = true
            target:Use(ply, ply, USE_ON, 1)
            target.MonarchExecutingContextUse = nil
        end
        return
    end

    if action == "corpse_cpr" then
        if target:GetClass() ~= "prop_ragdoll" then return end
        if target.MonarchDeceased or target.FallDeath then return end
        if Monarch and Monarch.TryPerformCPR then
            Monarch.TryPerformCPR(ply, target)
        end
        return
    end

    if hook.Run("MonarchHandleContextOption", ply, target, action) == true then
        return
    end

    if not target:IsPlayer() then return end

    if action == "introduce_self" then
        ply:ConCommand("monarch_introduce " .. target:EntIndex() .. " " .. (ply:GetRPName() or ply:Nick()))
    elseif action == "take_pulse" then
        return
    elseif action == "give_cash" then
        return
    elseif action == "faction_invite" then
        if not KP_CanInviteToFaction(ply, target) then
            KP_Notify(ply, "You cannot invite this player to your faction.")
            return
        end

        local faction = Monarch.Factions.GetPlayerFaction(ply)
        if not faction then
            KP_Notify(ply, "Failed to invite player to faction.")
            return
        end

        local inviterSID64 = tostring(ply:SteamID64() or "")
        local targetSID64 = tostring(target:SteamID64() or "")
        if inviterSID64 == "" or targetSID64 == "" then
            KP_Notify(ply, "Failed to invite player to faction.")
            return
        end

        local now = CurTime()
        local existing = pendingFactionInvites[targetSID64]
        if existing and existing.expiresAt and existing.expiresAt > now then
            KP_Notify(ply, "That player already has a pending faction invite.")
            return
        end

        local inviteID = tostring(math.floor(now * 1000)) .. "_" .. tostring(math.random(1000, 9999))
        pendingFactionInvites[targetSID64] = {
            id = inviteID,
            inviterSID64 = inviterSID64,
            factionID = faction.id,
            factionName = tostring(faction.name or "Unknown"),
            expiresAt = now + 30
        }

        net.Start("Monarch_FactionInvite_Prompt")
        net.WriteString(inviteID)
        net.WriteEntity(ply)
        net.WriteString(tostring(faction.name or "Unknown"))
        net.WriteUInt(30, 8)
        net.Send(target)

        KP_Notify(ply, "Faction invite sent to " .. (target.GetRPName and target:GetRPName() or target:Nick()) .. ".")
    else
        return
    end
end)

net.Receive("Monarch_FactionInvite_Response", function(_, ply)
    if not IsValid(ply) then return end

    local inviteID = tostring(net.ReadString() or "")
    local accepted = net.ReadBool()

    local targetSID64 = tostring(ply:SteamID64() or "")
    local pending = pendingFactionInvites[targetSID64]
    if not pending then
        KP_SendFactionInviteResult(ply, "This invite is no longer valid.", true, false)
        return
    end

    if pending.id ~= inviteID then
        KP_SendFactionInviteResult(ply, "This invite is no longer valid.", true, false)
        return
    end

    if not pending.expiresAt or pending.expiresAt < CurTime() then
        KP_ClearFactionInviteForTarget(targetSID64)
        KP_SendFactionInviteResult(ply, "This faction invite has expired.", true, false)
        return
    end

    local inviter = KP_FindPlayerBySID64(pending.inviterSID64)
    if not IsValid(inviter) then
        KP_ClearFactionInviteForTarget(targetSID64)
        KP_SendFactionInviteResult(ply, "The inviter is no longer online.", true, false)
        return
    end

    if not accepted then
        KP_ClearFactionInviteForTarget(targetSID64)
        KP_SendFactionInviteResult(ply, "Faction invite declined.", false, false)
        KP_SendFactionInviteResult(inviter, (ply.GetRPName and ply:GetRPName() or ply:Nick()) .. " declined your faction invite.", false, false)
        return
    end

    if not KP_CanInviteToFaction(inviter, ply) then
        KP_ClearFactionInviteForTarget(targetSID64)
        KP_SendFactionInviteResult(ply, "This invite is no longer valid.", true, false)
        KP_SendFactionInviteResult(inviter, "Faction invite failed: requirements are no longer met.", true, false)
        return
    end

    local faction = Monarch.Factions.GetPlayerFaction(inviter)
    local targetCharID = KP_GetCharID(ply)
    if not faction or not targetCharID then
        KP_ClearFactionInviteForTarget(targetSID64)
        KP_SendFactionInviteResult(ply, "Failed to join faction.", true, false)
        KP_SendFactionInviteResult(inviter, "Failed to add player to faction.", true, false)
        return
    end

    local ok, err = Monarch.Factions.AddMember(faction.id, targetCharID, "Member")
    KP_ClearFactionInviteForTarget(targetSID64)

    if not ok then
        KP_SendFactionInviteResult(ply, err or "Failed to join faction.", true, false)
        KP_SendFactionInviteResult(inviter, err or "Failed to add player to faction.", true, false)
        return
    end

    KP_SendFactionInviteResult(ply, "You joined faction '" .. tostring(faction.name or "Unknown") .. "'.", false, true)
    KP_SendFactionInviteResult(inviter, "" .. (ply.GetRPName and ply:GetRPName() or ply:Nick()) .. " joined your faction.", false, true)

    if Monarch and Monarch.Factions and Monarch.Factions.SyncPlayer then
        Monarch.Factions.SyncPlayer(ply)
        Monarch.Factions.SyncPlayer(inviter)
    end

    hook.Run("OnFactionMemberInvited", inviter, ply, faction)
end)

net.Receive("Monarch_RequestContextMenu", function(len, ply)
    local target = net.ReadEntity()

    if not IsValid(target) or target == ply then return end
    KP_SendContextMenuToPlayer(ply, target)
end)

net.Receive("Monarch_SearchInventory", function(len, ply)
    local target = net.ReadEntity()

    if not IsValid(target) or target == ply then return end
    if not target:GetNWBool("MonarchCuffed") then return end

    -- Verify the player is close enough
    if ply:GetPos():Distance(target:GetPos()) > 150 then return end

    -- Get the target's inventory items from Monarch.Inventory.Data using MonarchID (character ID)
    local charID = target.MonarchID or target.MonarchActiveChar and target.MonarchActiveChar.id
    if not charID then return end
    
    local invData = (Monarch and Monarch.Inventory and Monarch.Inventory.Data and Monarch.Inventory.Data[charID] and Monarch.Inventory.Data[charID][1]) or {}
    
    local items = {}
    for slot, item in pairs(invData) do
        if istable(item) and item.class then
            table.insert(items, item)
        end
    end

    -- Send inventory data to the requesting player
    net.Start("Monarch_SearchInventoryResponse")
    net.WriteEntity(target)
    net.WriteUInt(#items, 16)
    
    for _, item in ipairs(items) do
        if item then
            local itemClass = item.class or "unknown"
            net.WriteString(itemClass)
            net.WriteUInt(item.amount or 1, 16)
            
            -- Get the item name from the item definition
            local itemName = "Unknown Item"
            if Monarch and Monarch.Inventory and Monarch.Inventory.Items then
                local itemDef = Monarch.Inventory.Items[itemClass]
                if itemDef and itemDef.Name then
                    itemName = itemDef.Name
                end
            end
            net.WriteString(itemName)
            
            -- Get the item definition to check if it's illegal
            local isIllegal = false
            if Monarch and Monarch.Inventory and Monarch.Inventory.Items then
                local itemDef = Monarch.Inventory.Items[itemClass]
                if itemDef and itemDef.Illegal then
                    isIllegal = true
                end
            end
            net.WriteBool(isIllegal)
        end
    end

    net.Send(ply)
end)

net.Receive("Monarch_SearchInventory_Admin", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    local target = net.ReadEntity()

    if not IsValid(target) then return end

    -- Get the target's inventory items from Monarch.Inventory.Data using MonarchID (character ID)
    local charID = target.MonarchID or target.MonarchActiveChar and target.MonarchActiveChar.id
    if not charID then return end
    
    local invData = (Monarch and Monarch.Inventory and Monarch.Inventory.Data and Monarch.Inventory.Data[charID] and Monarch.Inventory.Data[charID][1]) or {}
    
    local items = {}
    for slot, item in pairs(invData) do
        if istable(item) and item.class then
            table.insert(items, item)
        end
    end

    -- Send inventory data to the requesting admin
    net.Start("Monarch_SearchInventoryResponse_Admin")
    net.WriteEntity(target)
    net.WriteUInt(#items, 16)
    
    for _, item in ipairs(items) do
        if item then
            local itemClass = item.class or "unknown"
            net.WriteString(itemClass)
            net.WriteUInt(item.amount or 1, 16)
            
            -- Get the item name from the item definition
            local itemName = "Unknown Item"
            if Monarch and Monarch.Inventory and Monarch.Inventory.Items then
                local itemDef = Monarch.Inventory.Items[itemClass]
                if itemDef and itemDef.Name then
                    itemName = itemDef.Name
                end
            end
            net.WriteString(itemName)
            
            -- Get the item definition to check if it's illegal
            local isIllegal = false
            if Monarch and Monarch.Inventory and Monarch.Inventory.Items then
                local itemDef = Monarch.Inventory.Items[itemClass]
                if itemDef and itemDef.Illegal then
                    isIllegal = true
                end
            end
            net.WriteBool(isIllegal)
        end
    end

    net.Send(ply)
end)

local function Monarch_RemoveInventoryItemByClass(target, itemClass)
    if not IsValid(target) or not itemClass then return false end

    local charID = target.MonarchID
    local steamid = target:SteamID64()
    if not charID or not steamid then return false end

    local storetype = 1
    if not Monarch.Inventory.Data[charID] or not Monarch.Inventory.Data[charID][storetype] then
        return false
    end

    local invChar = Monarch.Inventory.Data[charID][storetype]
    local invSteam = Monarch.Inventory.Data[steamid] or {}
    local foundSlot = nil

    for slot, item in pairs(invChar) do
        if istable(item) and item.class == itemClass then
            foundSlot = slot
            invChar[slot] = nil
            break
        end
    end

    if not foundSlot then
        return false
    end

    if invSteam[foundSlot] and istable(invSteam[foundSlot]) and invSteam[foundSlot].class == itemClass then
        invSteam[foundSlot] = nil
    else
        for slot, item in pairs(invSteam) do
            if istable(item) and item.class == itemClass then
                invSteam[slot] = nil
                break
            end
        end
    end

    target.InventoryRegister = target.InventoryRegister or {}
    target.InventoryRegister[itemClass] = math.max((target.InventoryRegister[itemClass] or 1) - 1, 0)
    if target.InventoryRegister[itemClass] == 0 then
        target.InventoryRegister[itemClass] = nil
    end

    if Monarch.Inventory.DBRemoveItem then
        Monarch.Inventory.DBRemoveItem(charID, itemClass, storetype, 1)
    end

    if Monarch.Inventory.SaveForOwner then
        Monarch.Inventory.SaveForOwner(target, charID, invChar)
    end

    net.Start("Monarch_Inventory_Update")
        net.WriteTable(invSteam)
    net.Send(target)

    return true
end

net.Receive("Monarch_ConfiscateItem", function(len, ply)
    local target = net.ReadEntity()
    local itemClass = net.ReadString()

    if not IsValid(target) or target == ply then return end
    if not target:GetNWBool("MonarchCuffed") then return end
    if ply:GetPos():Distance(target:GetPos()) > 150 then return end

    Monarch_RemoveInventoryItemByClass(target, itemClass)
end)

net.Receive("Monarch_ConfiscateItem_Admin", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local target = net.ReadEntity()
    local itemClass = net.ReadString()

    if not IsValid(target) then return end

    Monarch_RemoveInventoryItemByClass(target, itemClass)
end)

hook.Add("PlayerInitialSpawn", "Monarch_InitIntroductions", function(ply)
    InitializePlayerIntroductions(ply)

    timer.Simple(0.5, function()
        if not IsValid(ply) then return end

        ApplyDefaultKnowledgeForObserver(ply)
        for _, observer in player.Iterator() do
            if observer ~= ply then
                ApplyDefaultKnowledgeForObserver(observer, ply)
            end
        end
    end)
end)

hook.Add("OnPlayerChangedTeam", "Monarch_DefaultTeamKnowledge_ChangedTeam", function(ply)
    if not IsValid(ply) then return end

    timer.Simple(0, function()
        if not IsValid(ply) then return end

        ApplyDefaultKnowledgeForObserver(ply)
        for _, observer in player.Iterator() do
            if observer ~= ply then
                ApplyDefaultKnowledgeForObserver(observer, ply)
            end
        end
    end)
end)

hook.Add("PlayerDisconnected", "Monarch_CleanupIntroductions", function(ply)
    for observer, targets in pairs(playerIntroductions) do
        if targets[ply] then
            targets[ply] = nil
        end
    end

    playerIntroductions[ply] = nil
end)
