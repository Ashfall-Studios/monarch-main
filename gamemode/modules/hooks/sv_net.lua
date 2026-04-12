

Monarch = Monarch or {}
Monarch.CharSystem = Monarch.CharSystem or {
    PlayClicked = false,
    PendingChars = nil,
    PendingForceCreate = false
}

-- Helper function to sanitize item definitions for networking
-- Removes functions and properly handles the Actions table
local function Monarch_SanitizeItemDef(itemDef)
	local safe = {}
	for key, value in pairs(itemDef) do
		if type(value) == "function" then
			-- Skip functions
		elseif key == "Actions" and istable(value) then
			-- Handle Actions table specially - only include action names
			safe.Actions = {}
			for actionID, actionData in pairs(value) do
				if istable(actionData) and actionData.name then
					safe.Actions[actionID] = {
						name = actionData.name
					}
				end
			end
		else
			safe[key] = value
		end
	end
	
	-- Mark if item has a use function
	if type(itemDef.OnUse) == "function" then
		safe.Usable = true
	end
	
	return safe
end

local function Monarch_BuildSanitizedItemDefsPayload()
    local defs = {}
    local items = Monarch and Monarch.Inventory and Monarch.Inventory.Items or {}
    for k, v in pairs(items) do
        if istable(v) then
            defs[k] = Monarch_SanitizeItemDef(v)
        end
    end

    return {
        Items = defs,
        Ref = (Monarch and Monarch.Inventory and Monarch.Inventory.ItemsRef) or {}
    }
end

local function Monarch_SendItemDefsCompressed(target)
    local payload = Monarch_BuildSanitizedItemDefsPayload()
    local json = util.TableToJSON(payload, false) or "{}"
    local compressed = util.Compress(json)

    if compressed and #compressed > 0 then
        net.Start("Monarch_Inventory_ItemDefs_Compressed")
            net.WriteUInt(#compressed, 32)
            net.WriteData(compressed, #compressed)
        if IsValid(target) then
            net.Send(target)
        else
            net.Broadcast()
        end
        return
    end

    net.Start("Monarch_Inventory_ItemDefs")
        net.WriteTable(payload)
    if IsValid(target) then
        net.Send(target)
    else
        net.Broadcast()
    end
end

util.AddNetworkString("Monarch.Notify")
util.AddNetworkString("CreateMainMenu")
util.AddNetworkString("MonarchSprintState")
util.AddNetworkString("Monarch_CharacterCreate")
util.AddNetworkString("SUBMIT_PLAYER_TO_DB")
util.AddNetworkString("Monarch_GOTO")
util.AddNetworkString("monarchRagdollLink")
util.AddNetworkString("SendBroadcast")
util.AddNetworkString("BroadcastChatMessage")
util.AddNetworkString("MonarchSetHP")
util.AddNetworkString("MonarchSetArmor")
util.AddNetworkString("MonarchAddMoney")
util.AddNetworkString("MonarchSetHunger")
util.AddNetworkString("MonarchSetHydration")
util.AddNetworkString("MonarchSetExhaustion")
util.AddNetworkString("MonarchSetStamina")
util.AddNetworkString("MonarchGiveAmmo")
util.AddNetworkString("MonarchSetName")
util.AddNetworkString("MonarchSelectTeam")
util.AddNetworkString("Monarch_SleepingState")
util.AddNetworkString("Monarch_UpdateSleepingState")
util.AddNetworkString("Monarch_DeathHandle")

util.AddNetworkString("Monarch_Interact_Pulse")
util.AddNetworkString("Monarch_Interact_PulseResult")
util.AddNetworkString("Monarch_GiveMoney_Request")
util.AddNetworkString("Monarch_GiveMoney_Result")

util.AddNetworkString("Monarch_InitDeathScreen")
util.AddNetworkString("Monarch_SendDSToClient")
util.AddNetworkString("Monarch_OpenDeathScreen")

util.AddNetworkString("Monarch_Inventory_Request")
util.AddNetworkString("Monarch_Inventory_Update")
util.AddNetworkString("Monarch_Inventory_Move")
util.AddNetworkString("Monarch_Inventory_Equip")
util.AddNetworkString("Monarch_Inventory_Unequip")
util.AddNetworkString("MonarchInvDoEquip")
util.AddNetworkString("MonarchInvDoDrop")
util.AddNetworkString("MonarchInvDoUse")
util.AddNetworkString("MonarchInvUpdateEquip")
util.AddNetworkString("MonarchMultiDrop")

util.AddNetworkString("Monarch_Inventory_MoveItem")
util.AddNetworkString("Monarch_Inventory_UseItem")
util.AddNetworkString("Monarch_Inventory_UnequipToSlot")
util.AddNetworkString("Monarch_Inventory_Dismantle")
util.AddNetworkString("Monarch_Inventory_SplitStack")
util.AddNetworkString("Monarch_Admin_ShowItemCreator")
util.AddNetworkString("Monarch_Admin_GiveItem")
util.AddNetworkString("Monarch_Inventory_ItemDefs")
util.AddNetworkString("Monarch_Inventory_ItemDefs_Compressed")
util.AddNetworkString("Monarch_Inventory_DropItem")

util.AddNetworkString("Monarch_Tickets_OpenUI")
util.AddNetworkString("Monarch_Tickets_RequestOpen")
util.AddNetworkString("Monarch_Tickets_List")
util.AddNetworkString("Monarch_Tickets_Create")
util.AddNetworkString("Monarch_Tickets_Message")
util.AddNetworkString("Monarch_Tickets_RequestList")
util.AddNetworkString("Monarch_Tickets_Action")

util.AddNetworkString("Monarch_Loot_Open")
util.AddNetworkString("Monarch_Loot_Update")
util.AddNetworkString("Monarch_Loot_RequestOpen")
util.AddNetworkString("Monarch_Loot_BeginOpen")
util.AddNetworkString("Monarch_Loot_SetRefillTime")

util.AddNetworkString("Monarch_Loot_Put")
util.AddNetworkString("Monarch_Loot_PutResult")
util.AddNetworkString("Monarch_Loot_TakeToSlot")
util.AddNetworkString("Monarch_Loot_Take")
util.AddNetworkString("Monarch_Loot_TakeAll")

util.AddNetworkString("Monarch_Tools_Ban")
util.AddNetworkString("Monarch_Tools_Warn")
util.AddNetworkString("Monarch_Tools_GetWarns")
util.AddNetworkString("Monarch_Tools_WarnsData")
util.AddNetworkString("Monarch_Tools_AddNote")
util.AddNetworkString("Monarch_Tools_GetNotes")
util.AddNetworkString("Monarch_Tools_NotesData")
util.AddNetworkString("Monarch_Tools_GetLogs")
util.AddNetworkString("Monarch_Tools_LogsData")
util.AddNetworkString("Monarch_Tools_Kick")

util.AddNetworkString("Monarch_Tools_GiveTools")

util.AddNetworkString("Monarch_Admin_GetAllChars")
util.AddNetworkString("Monarch_Admin_AllChars")
util.AddNetworkString("Monarch_Admin_UpdateChar")
util.AddNetworkString("Monarch_Admin_UpdateCharResult")

util.AddNetworkString("Monarch_MSM_GetData")
util.AddNetworkString("Monarch_MSM_Data")
util.AddNetworkString("Monarch_MSM_SetStaff")
util.AddNetworkString("Monarch_MSM_RemoveStaff")
util.AddNetworkString("Monarch_MSM_SaveRanks")
util.AddNetworkString("Monarch_MSM_Result")
util.AddNetworkString("Monarch_MSM_GetMetricsFor")
util.AddNetworkString("Monarch_MSM_MetricsFor")

hook.Add("PlayerSay", "Monarch_SetSkillXP_Chat", function(ply, text)
    if not IsValid(ply) or not isstring(text) then return end
    local lower = string.Trim(string.lower(text or ""))
    if not (string.StartWith(lower, "!setskillxp") or string.StartWith(lower, "/setskillxp")) then return end

    if not (ply.IsAdmin and ply:IsAdmin()) and not (ply.IsSuperAdmin and ply:IsSuperAdmin()) then
        if ply.Notify then ply:Notify("You must be admin to use this.") end
        return ""
    end

    local parts = string.Explode(" ", lower)

    local skillId = parts[2]
    local xpStr = parts[3]
    if not skillId or not xpStr then
        if ply.Notify then ply:Notify("Usage: !setskillxp <skillId> <xp>") end
        return ""
    end
    local xp = tonumber(xpStr)
    if not xp then
        if ply.Notify then ply:Notify("XP must be a number.") end
        return ""
    end

    if Monarch and Monarch.Skills and Monarch.Skills.SetXP then
        Monarch.Skills.SetXP(ply, skillId, xp)
        local def = Monarch.GetSkill and Monarch.GetSkill(skillId)
        local name = def and def.Name or skillId
        if ply.Notify then ply:Notify("Set " .. name .. " XP to " .. tostring(xp) .. ".") end
    else
        if ply.Notify then ply:Notify("Skills system not available.") end
    end
    return ""
end)

net.Receive("Monarch_Inventory_UnequipToSlot", function(_, ply)
    if not IsValid(ply) or not ply.beenInvSetup then return end
    local src = net.ReadUInt(8) or 0
    local dst = net.ReadUInt(8) or 0
    local maxSlots = MONARCH_INV_MAX_SLOTS or 20
    if src < 1 or src > maxSlots or dst < 1 or dst > maxSlots then return end

    local charID = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchID or ply.MonarchLastCharID
    if not charID then return end

    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}
    local charStore = Monarch.Inventory.Data[charID]
    if not charStore or not charStore[1] then return end
    local inv = charStore[1]

    local srcItem = inv[src]
    if not istable(srcItem) then return end

    if not srcItem.equipped then return end

    if ply.SetInventoryItemEquipped then
        pcall(function()
            ply:SetInventoryItemEquipped(src, false)
        end)
    else
        srcItem.equipped = false
    end

    local dstItem = inv[dst]
    inv[dst] = srcItem
    inv[src] = dstItem

    if ply.SyncInventory then ply:SyncInventory() end
    do
        local saveCharID = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchID or ply.MonarchLastCharID or charID
        if saveCharID and Monarch and Monarch.Inventory and Monarch.Inventory.SaveForOwner then
            Monarch.Inventory.SaveForOwner(ply, saveCharID, inv)
        end
        if Monarch and Monarch.SaveInventoryPData then Monarch.SaveInventoryPData(ply, inv) end
    end
end)

if SERVER then

    util.AddNetworkString("Monarch_CharListRequest")
    util.AddNetworkString("Monarch_CharList") 
    util.AddNetworkString("Monarch_CharSelect")
    util.AddNetworkString("Monarch_CharDelete")
    util.AddNetworkString("Monarch_CharActivated")
    util.AddNetworkString("Monarch_CharForceCreate")
end

util.AddNetworkString("Monarch_Unconscious")
util.AddNetworkString("Monarch_WakeUp")

MONARCH_INV_MAX_SLOTS = 30 

Monarch.NormalizeEquipGroup = Monarch.NormalizeEquipGroup or function(eq)
    if not eq then return nil end
    eq = string.lower(tostring(eq))
    if eq == "primary_weapon" or eq == "primary" then return "primary" end
    if eq == "secondary_weapon" or eq == "secondary" then return "secondary" end
    if eq == "utility" then return "utility" end
    if eq == "tool" then return "tool" end
    if eq == "head" then return "head" end
    if eq == "face" or eq == "mask" then return "face" end
    if eq == "torso" or eq == "chest" or eq == "body" then return "torso" end
    if eq == "legs" or eq == "pants" then return "legs" end
    if eq == "shoes" or eq == "feet" or eq == "boots" then return "shoes" end

    return eq
end

Monarch.Loot = Monarch.Loot or { Defs = {}, Ref = {} }

Monarch.Tickets = Monarch.Tickets or {} 

local function Monarch_IsStaff(ply)
    if not IsValid(ply) then return false end
    local g = string.lower(ply:GetUserGroup() or "")
    if g == "admin" or g == "superadmin" or g == "operator" or g == "moderator" or g == "owner" then return true end

    Monarch.Staff = Monarch.Staff or { ranks = nil, users = nil }
    local function StaffEnsureDefaults()
        Monarch.Staff.ranks = Monarch.Staff.ranks or {
            { key = "superadmin", label = "Super Admin", perms = { tickets=true, tools=true, chars=true, msm=true } },
            { key = "admin", label = "Admin", perms = { tickets=true, tools=true, chars=true, msm=false } },
            { key = "moderator", label = "Moderator", perms = { tickets=true, tools=false, chars=false, msm=false } }
        }
        Monarch.Staff.users = Monarch.Staff.users or {}
    end
    local function StaffConfigPath() return "monarch/staff/config.json" end
    local function StaffLoad()
        file.CreateDir("monarch"); file.CreateDir("monarch/staff")
        if file.Exists(StaffConfigPath(), "DATA") then
            local t = util.JSONToTable(file.Read(StaffConfigPath(), "DATA") or "{}") or {}
            Monarch.Staff.ranks = t.ranks or nil
            Monarch.Staff.users = t.users or nil
        end
        StaffEnsureDefaults()
    end
    if not Monarch.Staff.ranks then StaffLoad() end
    local sid = ply:SteamID64()
    if sid and Monarch.Staff and Monarch.Staff.users and Monarch.Staff.users[sid] then return true end
    return false
end

hook.Add("PlayerInitialSpawn", "Monarch_MSM_ApplyUserGroup", function(ply)
    timer.Simple(1, function()
        if not IsValid(ply) then return end
        local sid = ply:SteamID64()
        local rec = Monarch.Staff and Monarch.Staff.users and Monarch.Staff.users[sid]
        if rec and rec.usergroup and rec.usergroup ~= "" and ply.SetUserGroup then
            ply:SetUserGroup(rec.usergroup)
        end
    end)
end)

hook.Add("PlayerSay", "Monarch_Tickets_PlayerSay", function(ply, text)
    if not IsValid(ply) or not isstring(text) or text == "" then return end
    if string.sub(text, 1, 1) ~= "@" then return end

    local body = string.Trim(string.sub(text, 2))
    if body == "" then
        ply:ChatPrint("Ticket not created. Type @ followed by your issue.")
        return "" 
    end

    Monarch.Tickets = Monarch.Tickets or {}
    Monarch.Tickets.Queue = Monarch.Tickets.Queue or {}
    Monarch.Tickets.NextID = Monarch.Tickets.NextID or 1

    local id = Monarch.Tickets.NextID
    Monarch.Tickets.NextID = id + 1

    local ticket = {
        id = id,
        reporter = ply:SteamID64(),
        reporterName = ply:Nick(),
        description = body,
        status = "open",
        created = os.time(),
        claimed = nil,
        claimedBy = nil,
        claimedByName = nil,
        closed = nil,
    }

    table.insert(Monarch.Tickets.Queue, ticket)

    local function IsAdmin(p)
        if Monarch and Monarch.IsAdminRank then return Monarch.IsAdminRank(p) end
        return IsValid(p) and p:IsAdmin()
    end

    for _, admin in player.Iterator() do
        if IsValid(admin) and IsAdmin(admin) then
            admin:ChatPrint(string.format("[Ticket #%d] %s: %s", id, ply:Nick(), body))
            net.Start("Monarch_Tickets_List")
                net.WriteTable(Monarch.Tickets.Queue)
            net.Send(admin)
        end
    end

    ply:ChatPrint("Your ticket (#"..id..") was created. Staff will respond soon.")

    return ""
end)

Monarch.AdminLogs = Monarch.AdminLogs or {}
Monarch.AdminLogsMax = Monarch.AdminLogsMax or 200

local function Monarch_Log(action, data)
    local entry = {
        time = os.time(),
        action = action,
        adminSID = IsValid(data.admin) and data.admin:SteamID64() or data.adminSID,
        adminName = (IsValid(data.admin) and data.admin:Nick()) or data.adminName or "",
        targetSID = IsValid(data.target) and data.target:SteamID64() or data.targetSID,
        targetName = (IsValid(data.target) and data.target:Nick()) or data.targetName or "",
        reason = data.reason or "",
        duration = data.duration or 0,
    }
    table.insert(Monarch.AdminLogs, entry)
    local extra = #Monarch.AdminLogs - (Monarch.AdminLogsMax or 200)
    if extra > 0 then
        for i = 1, extra do table.remove(Monarch.AdminLogs, 1) end
    end
end

local function EnsureModDirs()
    file.CreateDir("monarch")
    file.CreateDir("monarch/moderation")
    file.CreateDir("monarch/moderation/warns")
    file.CreateDir("monarch/moderation/notes")
end

net.Receive("Monarch_Tools_Ban", function(_, ply)
    if not Monarch_IsStaff(ply) then return end
    local target = net.ReadEntity()
    local minutes = math.max(0, math.floor(tonumber(net.ReadUInt(16)) or 0))
    local reason = string.sub(net.ReadString() or "", 1, 200)
    if not IsValid(target) or not target:IsPlayer() then return end

    target:Ban(minutes, true)
    timer.Simple(0, function()
        if IsValid(target) then
            if minutes == 0 then
                target:Kick(string.format("Permanently banned: %s", reason ~= "" and reason or "No reason provided"))
            else
                target:Kick(string.format("Banned (%dm): %s", minutes, reason ~= "" and reason or "No reason provided"))
            end
        end
    end)
    Monarch_Log("ban", { admin = ply, target = target, reason = reason, duration = minutes })
end)

net.Receive("Monarch_Tools_Kick", function(_, ply)
    if not Monarch_IsStaff(ply) then return end
    local target = net.ReadEntity()
    local reason = string.sub(net.ReadString() or "", 1, 200)
    if not IsValid(target) or not target:IsPlayer() then return end
    timer.Simple(0, function()
        if IsValid(target) then target:Kick(reason ~= "" and reason or "Kicked by an administrator") end
    end)
    Monarch_Log("kick", { admin = ply, target = target, reason = reason })
end)

net.Receive("Monarch_Tools_Warn", function(_, ply)
    if not Monarch_IsStaff(ply) then return end
    local target = net.ReadEntity()
    local reason = string.sub(net.ReadString() or "", 1, 300)
    if not IsValid(target) or not target:IsPlayer() then return end
    EnsureModDirs()
    local sid = target:SteamID64()
    local path = "monarch/moderation/warns/" .. sid .. ".json"
    local arr = {}
    if file.Exists(path, "DATA") then
        arr = util.JSONToTable(file.Read(path, "DATA") or "[]") or {}
    end
    table.insert(arr, { time = os.time(), admin = ply:SteamID64(), adminName = ply:Nick(), reason = reason })
    file.Write(path, util.TableToJSON(arr, false))
    Monarch_Log("warn", { admin = ply, target = target, reason = reason })
end)

net.Receive("Monarch_Tools_GetWarns", function(_, ply)
    if not Monarch_IsStaff(ply) then return end
    EnsureModDirs()
    local sid = net.ReadString() or ""
    if sid == "" then return end
    local path = "monarch/moderation/warns/" .. sid .. ".json"
    local arr = {}
    if file.Exists(path, "DATA") then
        arr = util.JSONToTable(file.Read(path, "DATA") or "[]") or {}
    end
    net.Start("Monarch_Tools_WarnsData")
        net.WriteString(sid)
        net.WriteTable(arr)
    net.Send(ply)
end)

net.Receive("Monarch_Tools_AddNote", function(_, ply)
    if not Monarch_IsStaff(ply) then return end
    EnsureModDirs()
    local sid = net.ReadString() or ""
    local text = string.sub(net.ReadString() or "", 1, 500)
    if sid == "" or text == "" then return end
    local path = "monarch/moderation/notes/" .. sid .. ".json"
    local arr = {}
    if file.Exists(path, "DATA") then
        arr = util.JSONToTable(file.Read(path, "DATA") or "[]") or {}
    end
    table.insert(arr, { time = os.time(), admin = ply:SteamID64(), adminName = ply:Nick(), text = text })
    file.Write(path, util.TableToJSON(arr, false))
    Monarch_Log("note", { admin = ply, targetSID = sid, reason = text })
end)

net.Receive("Monarch_Tools_GetNotes", function(_, ply)
    if not Monarch_IsStaff(ply) then return end
    EnsureModDirs()
    local sid = net.ReadString() or ""
    if sid == "" then return end
    local path = "monarch/moderation/notes/" .. sid .. ".json"
    local arr = {}
    if file.Exists(path, "DATA") then
        arr = util.JSONToTable(file.Read(path, "DATA") or "[]") or {}
    end
    net.Start("Monarch_Tools_NotesData")
        net.WriteString(sid)
        net.WriteTable(arr)
    net.Send(ply)
end)

net.Receive("Monarch_Tools_GetLogs", function(_, ply)
    if not Monarch_IsStaff(ply) then return end
    local limit = math.min( math.max(10, net.ReadUInt(12) or 100), 500 )
    local out = {}
    local start = math.max(1, #Monarch.AdminLogs - limit + 1)
    for i = start, #Monarch.AdminLogs do table.insert(out, Monarch.AdminLogs[i]) end
    net.Start("Monarch_Tools_LogsData")
        net.WriteTable(out)
    net.Send(ply)
end)

function Monarch.RegisterLoot(def)
    if not def or not def.UniqueID then return end
    Monarch.Loot.Defs[def.UniqueID] = def
    Monarch.Loot.Ref[def.UniqueID] = def.UniqueID
end
local STORAGE_SLOT_START = 31
local STORAGE_SLOT_END = 200
local STORAGE_LOOT_ID = "storage_character"

Monarch.Storage = Monarch.Storage or {}

local function Monarch_IsLootEntity(ent)
    if not IsValid(ent) then return false end
    local cls = ent:GetClass()
    return (cls == "monarch_loot" or cls == "monarch_storage")
end

local function Monarch_IsStorageEntity(ent)
    if not IsValid(ent) then return false end
    if ent:GetClass() == "monarch_storage" then return true end
    local defID = ent.GetLootDefID and ent:GetLootDefID()
    return (defID == STORAGE_LOOT_ID)
end

Monarch.Storage.IsLootEntity = Monarch_IsLootEntity
Monarch.Storage.IsStorageEntity = Monarch_IsStorageEntity

local function Monarch_GetStorageList(ply)
    if not IsValid(ply) then return {} end
    local steamid = ply:SteamID64()
    if not steamid then return {} end
    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}
    local inv = Monarch.Inventory.Data[steamid] or {}
    local out = {}
    for slot, item in pairs(inv) do
        if istable(item) and tonumber(item.storagetype or 1) == 2 then
            table.insert(out, { slot = tonumber(slot) or 0, item = item })
        end
    end
    table.sort(out, function(a, b) return (a.slot or 0) < (b.slot or 0) end)
    return out
end

Monarch.Storage.GetList = Monarch_GetStorageList

local function Monarch_BuildStorageContents(ply)
    local list = Monarch_GetStorageList(ply)
    local contents = {}
    for _, entry in ipairs(list) do
        local it = entry.item
        table.insert(contents, {
            id = it.id or it.class,
            amount = it.amount or 1,
            restricted = it.restricted or false,
            constrained = it.constrained or false,
            slot = entry.slot
        })
    end
    return contents
end

Monarch.Storage.BuildContents = Monarch_BuildStorageContents

local function Monarch_FindNextStorageSlot(inv)
    for i = STORAGE_SLOT_START, STORAGE_SLOT_END do
        if not inv[i] then return i end
    end
end

Monarch.Storage.FindNextSlot = Monarch_FindNextStorageSlot

if not (Monarch.Loot and Monarch.Loot.Defs and Monarch.Loot.Defs[STORAGE_LOOT_ID]) then
    Monarch.RegisterLoot({
        UniqueID = STORAGE_LOOT_ID,
        UseName = "Personal Storage",
        Model = "models/props_junk/wood_crate001a.mdl",
        OpenTime = 1.0,
        OpenSound = "foley/containers/wood_wardrobe_open.mp3",
        CloseSound = "foley/containers/wood_wardrobe_close.mp3",
        CanStore = true,
        CapacityX = 5,
        CapacityY = 6,
        LootTable = {}
    })
elseif Monarch.Loot and Monarch.Loot.Defs and Monarch.Loot.Defs[STORAGE_LOOT_ID] then
    Monarch.Loot.Defs[STORAGE_LOOT_ID].UseName = "Personal Storage"
end

local function Monarch_SaveLootPersist()
    if not Monarch._lootPersist then return end
    local MAP = game.GetMap()
    local out = {}
    for _, data in pairs(Monarch._lootPersist) do
        table.insert(out, data)
    end
    file.CreateDir("monarch")
    file.Write("monarch/loot_" .. MAP .. ".json", util.TableToJSON(out, false))
end

local function Monarch_LoadLootPersist()
    Monarch._lootPersist = {}
    local MAP = game.GetMap()
    local path = "monarch/loot_" .. MAP .. ".json"
    if not file.Exists(path, "DATA") then return end
    local txt = file.Read(path, "DATA") or "[]"
    local arr = util.JSONToTable(txt) or {}
    for _, rec in ipairs(arr) do
        Monarch._lootPersist[rec.uid] = rec
        local ent = ents.Create("monarch_loot")
        if IsValid(ent) then
            ent:SetPos(Vector(rec.pos.x, rec.pos.y, rec.pos.z))
            ent:SetAngles(Angle(rec.ang.p, rec.ang.y, rec.ang.r))
            ent:Spawn()
            if rec.model and rec.model ~= "" and ent.SetCustomModel then
                ent:SetCustomModel(rec.model)
            end
            ent:SetLootDef(rec.defid)
            ent:SetPersistentID(rec.uid)
            ent:SetContents(rec.contents or {})
        end
    end
end

local meta = FindMetaTable("Player")

function Monarch.SaveInventoryPData(ply, inv)
    if not IsValid(ply) then return end
    local charid = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchLastCharID
    if not charid then return end

    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}

    local maxSlots = MONARCH_INV_MAX_SLOTS or 20
    local flat = {}

    for slot, item in pairs(inv or {}) do
        if istable(item) then
            local cls = tostring(item.class or item.id or "")
            local s = tonumber(slot)
            if cls ~= "" and s and s > 0 and s <= maxSlots then
                s = math.floor(s)
                table.insert(flat, {
                    slot = s,
                    id = cls,
                    class = cls,
                    amount = math.max(1, math.floor(tonumber(item.amount or 1) or 1)),
                    equipped = item.equipped or false,
                    restricted = item.restricted or false,
                    constrained = item.constrained or false,
                    storagetype = tonumber(item.storagetype or 1) or 1,
                    clip = math.floor(tonumber(item.clip or 0) or 0),
                    durability = math.Clamp(math.floor(tonumber(item.durability or 100) or 100), 0, 100),
                })
            end
        end
    end

    local json = util.TableToJSON(flat) or "[]"
    ply:SetPData("MonarchInventory_" .. tostring(charid), json)
end

local function Monarch_UnequipAllOnLoad(ply, inv)
    if not IsValid(ply) or not istable(inv) then return inv end
    for _, item in pairs(inv) do
        if istable(item) then
            local class = item.class or item.id
            if item.equipped then

                local def = (Monarch.Inventory and Monarch.Inventory.Items and Monarch.Inventory.Items[class]) or nil
                if (not def) and Monarch.Inventory and Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[class] then
                    local key = Monarch.Inventory.ItemsRef[class]
                    def = Monarch.Inventory.Items and Monarch.Inventory.Items[key]
                end
                if def and def.WeaponClass then
                    local wep = ply:GetWeapon(def.WeaponClass)
                    if IsValid(wep) then
                        ply:StripWeapon(def.WeaponClass)
                    end
                end
                item.equipped = false
            end
        end
    end
    return inv
end

local function Monarch_RestoreFromUnconscious(ply, finalPos)
    if not IsValid(ply) then return end

    if finalPos then
        ply:SetPos(finalPos)
    end

    local ragdoll = ply:GetNWEntity("UnconsciousRagdoll")
    if IsValid(ragdoll) and ragdoll.MonarchKnockoutOwner == ply then
        ragdoll:Remove()
    end

    ply:SetNWEntity("UnconsciousRagdoll", NULL)
    ply:SetNWBool("IsUnconscious", false)

    ply:SpectateEntity(NULL)
    ply:Spectate(OBS_MODE_NONE)
    ply:UnSpectate()
    ply:SetMoveType(MOVETYPE_WALK)
    ply:Freeze(false)
    ply:SetSolid(SOLID_BBOX)
    ply:SetRenderMode(RENDERMODE_NORMAL)
    ply:SetColor(Color(255, 255, 255, 255))
    ply:SetNoDraw(false)
    ply:SetNotSolid(false)
    ply:GodDisable()
    ply:DrawViewModel(true)
    ply:DrawWorldModel(true)
    ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    if ply.CollisionRulesChanged then
        ply:CollisionRulesChanged()
    end
end

hook.Add("PlayerSpawn", "Monarch_UnconsciousSpawnSafety", function(ply)
    if not IsValid(ply) then return end

    timer.Simple(0, function()
        if not IsValid(ply) then return end
        if ply:GetNWBool("IsUnconscious", false) then return end
        Monarch_RestoreFromUnconscious(ply)
    end)
end)

function Monarch.KnockOutPlayer(ply, knockOutTime)
    if not IsValid(ply) or not ply:Alive() then return end
    if ply:GetNWBool("IsUnconscious", false) then return end

    ply:GodDisable()

    local savedWeapons = {}
    for _, wep in ipairs(ply:GetWeapons()) do
        table.insert(savedWeapons, wep:GetClass())
    end
    local savedModel = ply:GetModel()
    local savedSkin = ply:GetSkin()
    local savedBodygroups = {}
    for i = 0, ply:GetNumBodyGroups() - 1 do
        savedBodygroups[i] = ply:GetBodygroup(i)
    end

    ply:ConCommand("say /me suddenly collapses to the ground from exhaustion.")

    local ragdoll = ents.Create("prop_ragdoll")
    if not IsValid(ragdoll) then return end

    ragdoll:SetModel(ply:GetModel())
    ragdoll:SetSkin(ply:GetSkin())
    ragdoll:SetPos(ply:GetPos())
    ragdoll:SetAngles(ply:GetAngles())
    ragdoll:Spawn()
    ragdoll:SetVelocity(ply:GetVelocity())
    ragdoll.MonarchKnockoutOwner = ply

    for i = 0, ply:GetNumBodyGroups() - 1 do
        ragdoll:SetBodygroup(i, ply:GetBodygroup(i))
    end

    ply:StripWeapons()
    ply:Freeze(true)
    ply:DrawViewModel(false)
    ply:DrawWorldModel(false)
    ply:SetNoDraw(true)
    ply:SetNotSolid(true)
    ply:SetSolid(SOLID_NONE)
    ply:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    ply:SetMoveType(MOVETYPE_WALK)
    ply:SetNWEntity("UnconsciousRagdoll", ragdoll)
    ply:SetNWBool("IsUnconscious", true)

    timer.Simple(0.1, function()
        if IsValid(ragdoll) and IsValid(ply) then
            net.Start("monarchRagdollLink")
            net.WriteEntity(ragdoll)
            net.Send(ply)
        end
    end)

    local collapseTime = tonumber(knockOutTime) or Config.ExhaustionCollapseTime or Config.UnconsciousTimer or 10
    collapseTime = math.max(0.1, collapseTime)
    timer.Simple(collapseTime, function()
        if not IsValid(ply) then return end
        if not ply:GetNWBool("IsUnconscious", false) then return end

        local finalPos = IsValid(ragdoll) and ragdoll:GetPos() or ply:GetPos()

        if IsValid(ragdoll) then
            ragdoll:Remove()
        end

        Monarch_RestoreFromUnconscious(ply, finalPos)
        ply:SetVelocity(-ply:GetVelocity())

        ply:SetModel(savedModel)
        ply:SetSkin(savedSkin)
        for i, bg in pairs(savedBodygroups) do
            ply:SetBodygroup(i, bg)
        end

        for _, wepClass in ipairs(savedWeapons) do
            ply:Give(wepClass)
        end

        ply:SetNWEntity("UnconsciousRagdoll", NULL)
        ply:SetNWBool("IsUnconscious", false)
        ply:SetNWInt("Exhaustion", 0)

        timer.Simple(0, function()
            if not IsValid(ply) then return end
            if ply:GetNWBool("IsUnconscious", false) then return end
            Monarch_RestoreFromUnconscious(ply)
        end)

        timer.Simple(0.1, function()
            if not IsValid(ply) then return end
            if ply:GetNWBool("IsUnconscious", false) then return end
            Monarch_RestoreFromUnconscious(ply)
        end)

        net.Start("Monarch_WakeUp")
        net.Send(ply)
    end)

    net.Start("Monarch_Unconscious")
    net.Send(ply)
end

hook.Add("EntityTakeDamage", "Monarch_UnconsciousRagdollDamage", function(ent, dmginfo)
    if not IsValid(ent) or ent:GetClass() ~= "prop_ragdoll" then return end

    local owner = ent.MonarchKnockoutOwner
    if not IsValid(owner) or not owner:IsPlayer() then return end
    if not owner:GetNWBool("IsUnconscious", false) then return end

    local inflictor = dmginfo:GetInflictor()
    local isWeaponInflictor = IsValid(inflictor) and (inflictor:IsWeapon() or inflictor:GetClass() == "player")
    local damageType = dmginfo:GetDamageType() or 0
    local isWeaponLikeType = dmginfo:IsBulletDamage()
        or bit.band(damageType, DMG_BUCKSHOT) ~= 0
        or bit.band(damageType, DMG_SLASH) ~= 0
        or bit.band(damageType, DMG_CLUB) ~= 0
        or bit.band(damageType, DMG_BLAST) ~= 0

    if not isWeaponInflictor and not isWeaponLikeType then return end

    local damage = math.max(0, dmginfo:GetDamage() or 0)
    if damage <= 0 then return end

    local newHealth = owner:Health() - damage
    owner:SetHealth(newHealth)

    if newHealth <= 0 then
        owner:SetNWBool("IsUnconscious", false)
        owner:SetNWEntity("UnconsciousRagdoll", NULL)

        Monarch_RestoreFromUnconscious(owner)

        if IsValid(ent) then
            ent:Remove()
        end

        owner:Kill()
    end
end)

util.AddNetworkString("Monarch_TriggerCollapse")

net.Receive("Monarch_TriggerCollapse", function(len, ply)
    if not IsValid(ply) then return end
    Monarch.KnockOutPlayer(ply)
end)

concommand.Add("monarch_knockout", function(ply, cmd, args)
    if not IsValid(ply) then return end

    if #args == 0 then
        Monarch.KnockOutPlayer(ply)
        return
    end

    if not ply:IsAdmin() then
        ply:ChatPrint("You must be an admin to target other players.")
        return
    end

    local target = Monarch.FindPlayer(args[1])
    if not target or #target == 0 then
        ply:ChatPrint("Player not found.")
        return
    end

    target = target[1]
    if not IsValid(target) then
        ply:ChatPrint("Invalid target.")
        return
    end

    Monarch.KnockOutPlayer(target)
end)

net.Receive("Monarch_InitDeathScreen", function(len, ply)
    net.Start("Monarch_SendDSToClient")
    net.Send(ply)
end)
util.AddNetworkString("Monarch_DrinkFinish")
util.AddNetworkString("Monarch_DrinkStart")

net.Receive("Monarch_DrinkFinish", function(len, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end

    ent:EmitSound("needs/valve/fill_sink2.wav")
    ply:EmitSound("needs/thrist_drink_0"..math.random(1,5)..".wav")

    ent.Drinker = ply
    if IsValid(ent.Drinker) then
        ent:Drink(ply)
    end
end)

net.Receive("Monarch_Inventory_DropItem", function(_, ply)
    if not IsValid(ply) then return end
    local slot = net.ReadUInt(8)
    local requestedAmount = net.ReadUInt(8)
    if not slot or slot < 1 or slot > 100 then return end

    local steamid64 = ply:SteamID64()
    if not steamid64 then return end
    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}
    local inv = Monarch.Inventory.Data[steamid64]
    if not inv then return end

    local item = inv[slot]
    if not item then
        ply:Notify("No item in that slot.")
        return
    end

    local itemClass = item.class or item.id
    if not itemClass then return end

    local def = Monarch.Inventory.Items and Monarch.Inventory.Items[itemClass]
    if (not def) and Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[itemClass] then
        def = Monarch.Inventory.Items and Monarch.Inventory.Items[Monarch.Inventory.ItemsRef[itemClass]]
    end
    if not def then
        return
    end

    if item.Locked then
        return ply:Notify("This item is not able to be dropped.")
    end

    if item.equipped then

        if def.WeaponClass then
            local wep = ply:GetWeapon(def.WeaponClass)
            if IsValid(wep) then

                if wep.Clip1 then
                    local clip1 = wep:Clip1()
                    if isnumber(clip1) then
                        item.clip = clip1
                    end
                end
                ply:StripWeapon(def.WeaponClass)
            end
        end

        if type(def.OnRemove) == "function" then
            pcall(def.OnRemove, def, ply, item, slot)
        end

        hook.Run("MonarchItemRemoved", ply, item, def, slot)
        item.equipped = false
    end

    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * 45,
        filter = ply
    })

    local currentAmount = math.max(1, math.floor(tonumber(item.amount) or 1))
    local dropCount = math.Clamp(math.max(1, math.floor(tonumber(requestedAmount) or 1)), 1, currentAmount)
    local newAmount = currentAmount - dropCount
    if newAmount > 0 then
        item.amount = newAmount
    else
        inv[slot] = nil
    end
    Monarch.SaveInventory(ply, inv)

    local ent = ents.Create("monarch_item")
    if not IsValid(ent) then
        ply:Notify("Failed to drop item.")
        return
    end
    ent:SetPos((tr.HitPos or ply:GetPos()) + Vector(0,0,10))

    ent:SetModel((def and def.Model) or "models/props_junk/cardboard_box004a.mdl")
    if def and def.Material then ent:SetMaterial(def.Material) end
    ent:SetItemClass(itemClass)
    if ent.SetStackAmount then
        ent:SetStackAmount(dropCount)
    else
        ent.StackAmount = dropCount
        ent:SetNWInt("StackAmount", dropCount)
    end
    ent:Spawn()
    ent:Activate()
    ent.ItemOwner = ply
    ent.IsRestrictedItem = item.restricted or (def and def.Restricted) or false
    if def.WeaponClass and item.clip then
        ent.ItemClip = item.clip
    end
    ent:SetCollisionGroup(COLLISION_GROUP_WORLD)

    net.Start("Monarch_Inventory_Update")
        net.WriteTable(inv)
    net.Send(ply)

    if Monarch_Log then
        Monarch_Log("drop_item", { admin = ply, reason = string.format("slot=%d class=%s x%d", slot or -1, itemClass or "?", dropCount or 1) })
    end
end)

net.Receive("Monarch_SendDSToClient", function(len, ply)
    net.Start("Monarch_OpenDeathScreen")
    net.Send(ply)
end)

net.Receive("Monarch_CharListRequest", function(len, ply)
    if not IsValid(ply) then return end

    local query = mysql:Select("monarch_players")
    query:Where("steamid", ply:SteamID())
    query:Callback(function(result)
        local chars = result or {}

        net.Start("Monarch_CharList")
        net.WriteUInt(#chars, 3)

        for i, char in ipairs(chars) do
            net.WriteUInt(char.id, 32)
            net.WriteString(char.rpname or "Unknown")
            net.WriteString(char.model or "models/player/alyx.mdl")
            net.WriteUInt(char.skin or 0, 8)
            net.WriteInt(char.xp or 0, 32)
            net.WriteInt(char.money or 0, 32)
            net.WriteInt(char.bankmoney or 0, 32)
        end

        net.Send(ply)

        if #chars == 0 then
            net.Start("Monarch_CharForceCreate")
            net.Send(ply)
        end
    end)
    query:Execute()
end)

net.Receive("Monarch_Inventory_Request", function(_, ply)
    if not IsValid(ply) then return end

    local charID = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchID or ply.MonarchLastCharID
    if not charID then return end 

    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}
    local inv = Monarch.Inventory.Data[ply:SteamID64()] or {}

    net.Start("Monarch_Inventory_Update")
        net.WriteTable(inv)
    net.Send(ply)

    if not ply._MonarchItemDefsSent then
        Monarch_SendItemDefsCompressed(ply)
        ply._MonarchItemDefsSent = true
    end
end)

net.Receive("MonarchSelectTeam", function(_, ply)
    if not IsValid(ply) then return end
    local teamID = net.ReadUInt(8)
    local target = net.ReadPlayer()
    if not IsValid(target) then target = ply end

    if not teamID or teamID < 1 then return end
    target:Monarch_SetTeam(teamID)

    if mysql and mysql.Update and target.MonarchActiveChar and target.MonarchActiveChar.id then
        local query = mysql:Update("monarch_characters")
        query:Update("team", teamID)
        query:Where("id", target.MonarchActiveChar.id)
        query:Callback(function()
            if IsValid(target) and target.MonarchActiveChar then
                target.MonarchActiveChar.team = teamID
            end
            if IsValid(ply) and ply ~= target and ply.Notify then
                ply:Notify("Set " .. target:Nick() .. "'s team to " .. (team.GetName(teamID) or teamID))
            end
            if IsValid(target) and target.Notify then
                target:Notify("Your team has been set to " .. (team.GetName(teamID) or teamID))
            end
        end)
        query:Execute()
    end
end)

net.Receive("MonarchSetName", function(len, ply)
	local name = net.ReadString()

	ply:SetName(name)
	ply:SetPData("RPName", name)
end)

net.Receive("MonarchGiveAmmo", function(len, ply)
    local amt = net.ReadUInt(32)
    local targ = net.ReadEntity()  
    local type = net.ReadString()

    if not IsValid(targ) or not targ:IsPlayer() then
        ply:Notify("Invalid target player.")
        return
    end

    if not amt or amt <= 0 then
        ply:Notify("Invalid ammo amount.")
        return
    end

    if not type or type == "" then
        ply:Notify("Invalid ammo type.")
        return
    end

    targ:GiveAmmo(amt, type, true)
end)

net.Receive("MonarchSetArmor", function(len, ply)
	local amt = net.ReadUInt(32)
	local targ = net.ReadPlayer()

	targ:SetArmor(amt)
end)

net.Receive("MonarchSetHP", function(len, ply)
	local amt = net.ReadUInt(32)
	local targ = net.ReadPlayer()

	targ:SetHealth(amt)
end)

net.Receive("MonarchAddMoney", function(len, ply)
	if not IsValid(ply) or not ply:IsAdmin() then return end

	local amt = net.ReadInt(32)
	local targ = net.ReadPlayer()

	if not IsValid(targ) then return end

	if targ.AddMoney then
		targ:AddMoney(amt)
		if targ.Notify then
			targ:Notify("You received $" .. amt .. " from an administrator.")
		end
	end
end)

function BroadcastChatMessage(prefixColor, prefix, userData, userColor, chatColor, message, fontName)
	net.Start("BroadcastChatMessage")
		net.WriteColor(prefixColor)
		net.WriteString(prefix)
	 	net.WriteColor(userColor)
		net.WriteString(userData)
		net.WriteString(message)
		net.WriteColor(chatColor)
		net.WriteString(fontName or "")
	net.Broadcast()
end

net.Receive("SendBroadcast", function(len, ply)
	local prefixColor = net.ReadColor()
	local prefix = net.ReadString()
	local msg = net.ReadString()
	local chatColor = net.ReadColor()
	local playerInfo = net.ReadString()
	local teamCol = net.ReadColor()
	BroadcastChatMessage(prefixColor, prefix, playerInfo, teamCol, chatColor, msg)
end)

net.Receive("Monarch_GOTO", function(len, ply)
	local pos = net.ReadVector()

	ply:SetPos(pos)
end)

net.Receive("SUBMIT_PLAYER_TO_DB", function(len, ply)
	if (ply.NextCreate or 0) > CurTime() then return end
	ply.NextCreate = CurTime() + 10

	local charName = net.ReadString() or ply:Nick()
	local charModel = net.ReadString() or Config.DefaultModel
	local charSkin = net.ReadUInt(8) or 0

	local plyID = ply:SteamID()
	local plyGroup = ply:GetUserGroup() or "user"
	local timestamp = math.floor(os.time())

	local canUseName = true

	local query = mysql:Select("monarch_players")
	query:Where("steamid", plyID)
	query:Callback(function(result)
		if (type(result) == "table" and #result > 0) then return end 

		local insertQuery = mysql:Insert("monarch_players")
		insertQuery:Insert("rpname", charName)
		insertQuery:Insert("steamid", plyID)
		insertQuery:Insert("group", "user")
		insertQuery:Insert("xp", 0)
		insertQuery:Insert("money", Config.StartingMoney)
		insertQuery:Insert("bankmoney", Config.StartingMoney)
		insertQuery:Insert("model", charModel)
		insertQuery:Insert("skin", charSkin)
		insertQuery:Insert("firstjoin", timestamp)
		insertQuery:Insert("data", "[]")
		insertQuery:Insert("skills", "[]")
		insertQuery:Callback(function(result, status, lastID)
			if IsValid(ply) then
                ply.MonarchCharJustCreatedID = tostring(lastID or "")
				local setupData = {
					id = lastID,
					rpname = charName,
					steamid = plyID,
					group = "user",
					xp = 0,
					money = Config.StartingMoney,
					bankmoney = Config.StartingMoney,
					model = charModel,
					data = "[]",
					skills = "[]",
					skin = charSkin,
					firstjoin = timestamp
				}

				ply:Freeze(false)

                if not ply.MonarchActiveChar then
                    setupData.name = setupData.rpname  
                    Monarch.CharSystem.ActivateCharacter(ply, setupData)
                end
			end
		end)
		insertQuery:Execute()
	end)
	query:Execute()
end)

net.Receive("Monarch_CharCreate", function(len, ply)
    if (ply.NextCreate or 0) > CurTime() then return end
    ply.NextCreate = CurTime() + 10

    local charName = net.ReadString()
    local charModel = net.ReadString()
    local charSkin = net.ReadUInt(8)
    local isFemale = net.ReadBool()

    local height = net.ReadString()
    local weight = net.ReadString()
    local hair = net.ReadString()
    local eye = net.ReadString()
    local age = net.ReadUInt(8)

    local plyID = ply:SteamID()
    local plyGroup = ply:GetUserGroup()
    local timestamp = math.floor(os.time())

    local canUseName, filteredName = true, charName

    if canUseName then
        charName = filteredName
    else
        ply:ChatAddText(Color(255, 100, 100), "Invalid name: " .. (filteredName or "unknown error"))
        return
    end

    local query = mysql:Select("monarch_players")
    query:Where("steamid", plyID)
    query:Callback(function(result)
        if not IsValid(ply) then return end

        if result and #result >= Config.MaxChars then
            ply:ChatAddText(Color(255, 100, 100), "You already have the maximum number of characters!")
            return
        end

        local insertQuery = mysql:Insert("monarch_players")
        insertQuery:Insert("steamid", plyID)
        insertQuery:Insert("rpname", charName)
        insertQuery:Insert("xp", 0)
        insertQuery:Insert("money", Config.StartingMoney)
        insertQuery:Insert("bankmoney", Config.StartingMoney)
        insertQuery:Insert("model", charModel)
        insertQuery:Insert("skin", charSkin)
        insertQuery:Insert("team", Config.DefaultTeam or 1) 
        insertQuery:Insert("bodygroups", "{}") 
        insertQuery:Insert("firstjoin", os.time())
        insertQuery:Insert("data", "[]")
        insertQuery:Insert("skills", "[]")
        insertQuery:Insert("group", "user")

        insertQuery:Insert("height", height)
        insertQuery:Insert("weight", weight)
        insertQuery:Insert("haircolor", hair)
        insertQuery:Insert("eyecolor", eye)
        insertQuery:Insert("age", age)

        insertQuery:Callback(function(result, status, lastID)
            if not IsValid(ply) then return end

            ply.MonarchCharJustCreatedID = tostring(lastID or "")

            Monarch.CharSystem.SendCharacterList(ply, function(listCount)
                if listCount == 1 then

                    local selectQuery = mysql:Select("monarch_players")
                    selectQuery:Select("id")
                    selectQuery:Select("rpname")
                    selectQuery:Select("model")
                    selectQuery:Select("skin")
                    selectQuery:Select("team")
                    selectQuery:Select("bodygroups")
                    selectQuery:Select("height")
                    selectQuery:Select("weight")
                    selectQuery:Select("haircolor")
                    selectQuery:Select("eyecolor")
                    selectQuery:Select("age")
                    selectQuery:Select("xp")
                    selectQuery:Select("money")
                    selectQuery:Select("bankmoney")
                    selectQuery:Where("id", lastID)
                    selectQuery:Where("steamid", ply:SteamID())
                    selectQuery:Limit(1)

                    selectQuery:Callback(function(rows)
                        if not IsValid(ply) then return end
                        local row = rows and rows[1]
                        if row then
                            row.name = row.rpname
                            row.bodygroups = row.bodygroups or "{}"
                            Monarch.CharSystem.ActivateCharacter(ply, row)
                        end
                    end)
                    selectQuery:Execute()
                end
            end)
        end)
        insertQuery:Execute()
    end)
    query:Execute()
end)

util.AddNetworkString("Monarch_CharSelect")
util.AddNetworkString("Monarch_CharActivated")

function Monarch.CharSystem.ActivateCharacter(ply, charRow)
   Monarch.SetupPlayerFromChar(ply, charData)
    ply:SetGravity(Config.Gravity)
    ply:SetMaxHealth(100)
    ply:SetHealth(100)

    MonarchApplySpeeds(ply)

    ply:SetNWFloat("Stamina", STAMINA_MAX)
    ply.LastStaminaUpdate = CurTime()
    ply.IsSprinting = false
    ply.IsFastWalking = false

    monarch.Sync.Data[ply:EntIndex()] = {}

    for v,k in pairs(monarch.Sync.Data) do
        local ent = Entity(v)
        if IsValid(ent) then
            ent:Sync(ply)
        end
    end

    if !ply:GetPData("PreviouslyJoined") then
        local query = mysql:Select("monarch_players")
        query:Select("id")
        query:Select("rpname")
        query:Select("group")
        query:Select("rpgroup")
        query:Select("rpgrouprank")
        query:Select("xp")
        query:Select("money")
        query:Select("bankmoney")
        query:Select("model")
        query:Select("skin")
        query:Select("data")
        query:Select("skills")
        query:Select("ammo")
        query:Select("firstjoin")
        query:Where("steamid", ply:SteamID())
        query:Callback(function(result)
            if IsValid(ply) and type(result) == "table" and #result > 0 then 
                isNew = false
                Monarch.SetupPlayer(ply, result[1])
            end
        end)
        query:Execute()
	end

	ply:SetViewEntity(ply)
    ply:SetGravity(Config.Gravity)
    ply:SetupHands()

    if IsValid(ply) then
        local nm = nil
        if ply.MonarchActiveChar and ply.MonarchActiveChar.name and ply.MonarchActiveChar.name ~= "" then
            nm = ply.MonarchActiveChar.name
        else
            nm = ply:GetNWString("rpname", "")
        end
        if not nm or nm == "" then
            nm = ply:GetPData("rpname", "")
        end
        if not nm or nm == "" then
            nm = ply:Nick() 
        end
        ply:SetNWString("rpname", nm)
        ply:SetPData("rpname", nm)
    end
	ply:SetTeam(Config.DefaultTeam or TEAM_CITIZEN)

    if ply.MonarchActiveChar and ply.MonarchActiveChar.model and ply.MonarchActiveChar.model ~= "" then
        ply:SetModel(ply.MonarchActiveChar.model)
        ply:SetSkin(tonumber(ply.MonarchActiveChar.skin) or 0)
    end

    ply:SetupHands()
    MonarchApplySpeeds(ply)

    ply:SetNWFloat("Stamina", STAMINA_MAX)
    ply.IsSprinting = false
    ply.IsFastWalking = false
    ply.LastStaminaUpdate = CurTime()

    for _,wep in pairs(Config.DeafultWeps) do
        ply:Give(wep)
    end

    local MAP_NAME = game.GetMap()
    local posData = ply:GetPData("LastPos_" .. MAP_NAME)
    if posData then
        local tbl = util.JSONToTable(posData)
        if tbl and tbl.x and tbl.y and tbl.z then
            ply:SetPos(Vector(tbl.x, tbl.y, tbl.z))
            if tbl.pitch and tbl.yaw and tbl.roll then
                ply:SetEyeAngles(Angle(tbl.pitch, tbl.yaw, tbl.roll))
            end
        end
    end
end

for i,row in ipairs(result or {}) do
    net.WriteUInt(math.Clamp(row.id or row.charid or 0, 0, 0xFFFFFFFF), 32)
    net.WriteString(row.rpname or row.name or "")
    net.WriteString(row.model or "models/player/alyx.mdl")
    net.WriteUInt(tonumber(row.skin) or 0, 8)
    net.WriteInt(tonumber(row.xp) or 0, 32)
    net.WriteInt(tonumber(row.money) or 0, 32)
    net.WriteInt(tonumber(row.bankmoney) or 0, 32)
end

net.Receive("Monarch_CharSelect", function(len, ply)
    local charID = net.ReadUInt(32)
    local charName = net.ReadString()

    local query = mysql:Select("monarch_players")
    query:Select("id")
    query:Select("rpname")
    query:Select("steamid")
    query:Select("group")
    query:Select("xp")
    query:Select("money")
    query:Select("bankmoney")
    query:Select("model")
    query:Select("skin")
    query:Select("team")
    query:Select("bodygroups")
    query:Select("data")
    query:Select("skills")
    query:Select("firstjoin")
    query:Select("height")
    query:Select("weight")
    query:Select("haircolor")
    query:Select("eyecolor")
    query:Select("age")
    query:Where("id", charID)
    query:Where("steamid", ply:SteamID())
    query:Callback(function(result)
        if result and #result > 0 then
            local char = result[1]
            ply.MonarchActiveChar = {
                id = tonumber(char.id) or 0,
                steamid = char.steamid or ply:SteamID(),
                name = char.rpname or "Unknown",
                model = char.model or "",
                skin = tonumber(char.skin) or 0,
                team = tonumber(char.team) or 1,
                height = char.height or "",
                weight = char.weight or "",
                haircolor = char.haircolor or "",
                eyecolor = char.eyecolor or "",
                age = tonumber(char.age) or 0
            }
            do
                local steamid = ply:SteamID64()
                if steamid and ply.MonarchLastCharID then
                    Monarch.SaveInventoryPData(ply)
                end
            end
            Monarch.Inventory = Monarch.Inventory or {}
            Monarch.Inventory.Data = Monarch.Inventory.Data or {}
            Monarch.Inventory.Data[ply:SteamID64()] = {}
            net.Start("Monarch_Inventory_Update")
                net.WriteTable({})
            net.Send(ply)

            ply:Monarch_SetTeam(tonumber(char.team) or Config.DefaultTeam)
            ply:SetModel(char.model)
            ply:SetSkin(tonumber(char.skin) or 0)

            if char.bodygroups and char.bodygroups != "" then
                local bodygroups = util.JSONToTable(char.bodygroups)
                if bodygroups then
                    if Monarch and Monarch.FilterAllowedBodygroups then
                        bodygroups = Monarch.FilterAllowedBodygroups(char.model, bodygroups)
                    end
                    for bgID, bgValue in pairs(bodygroups) do
                        ply:SetBodygroup(tonumber(bgID), tonumber(bgValue))
                    end
                end
            end

            ply:SetNWString("rpname", char.rpname)
            ply:SetNWString("temp_rpname", "")
            ply:SetNWString("original_rpname", "")
            ply:SetNWString("CharHeight", char.height or "")
            ply:SetNWString("CharWeight", char.weight or "")
            ply:SetNWString("CharHairColor", char.haircolor or "")
            ply:SetNWString("CharEyeColor", char.eyecolor or "")
            ply:SetNWInt("CharAge", tonumber(char.age) or 0)
            ply:SetNWString("MonarchCharID", tostring(tonumber(char.id) or 0))

            local needPatch = (not char.height or char.height == "") and ply._MonarchPendingRP
            if needPatch then
                local pend = ply._MonarchPendingRP
                local upd = mysql:Update("monarch_players")
                upd:Update("height", pend.height or "")
                upd:Update("weight", pend.weight or "")
                upd:Update("haircolor", pend.haircolor or "")
                upd:Update("eyecolor", pend.eyecolor or "")
                upd:Update("age", pend.age or 0)
                upd:Where("id", char.id)
                upd:Callback(function()
                    ply.MonarchActiveChar.height = pend.height or ""
                    ply.MonarchActiveChar.weight = pend.weight or ""
                    ply.MonarchActiveChar.haircolor = pend.haircolor or ""
                    ply.MonarchActiveChar.eyecolor = pend.eyecolor or ""
                    ply.MonarchActiveChar.age = pend.age or 0
                    ply:SetNWString("CharHeight", pend.height or "")
                    ply:SetNWString("CharWeight", pend.weight or "")
                    ply:SetNWString("CharHairColor", pend.haircolor or "")
                    ply:SetNWString("CharEyeColor", pend.eyecolor or "")
                    ply:SetNWInt("CharAge", pend.age or 0)
                    ply._MonarchPendingRP = nil
                end)
                upd:Execute()
            end

            ply.MonarchLastCharID = tonumber(char.id)

            local charID = tonumber(char.id)
            Monarch.LoadInventoryForChar(ply, charID, function(loadedPly)
                if not IsValid(loadedPly) then return end

                local actualCharID = loadedPly.MonarchID or (loadedPly.MonarchActiveChar and loadedPly.MonarchActiveChar.id) or loadedPly.MonarchLastCharID
                if not actualCharID then return end
            end)

            timer.Simple(0, function()
                if not IsValid(ply) then return end
                hook.Run("OnCharacterActivated", ply, ply.MonarchActiveChar)
                hook.Run("Monarch_CharLoaded", ply, ply.MonarchActiveChar)
            end)

            net.Start("Monarch_CharActivated")
            net.Send(ply)
        end
    end)
    query:Execute()
end)

util.AddNetworkString("Monarch_CharListRequest")
util.AddNetworkString("Monarch_CharList")
util.AddNetworkString("Monarch_CharCreate")
util.AddNetworkString("Monarch_CharDelete")
util.AddNetworkString("Monarch_CharSelect")
util.AddNetworkString("Monarch_CharForceCreate")
util.AddNetworkString("Monarch_CharActivated")
util.AddNetworkString("Monarch_SetModel")

util.AddNetworkString("Monarch_SetRPName")
util.AddNetworkString("MonarchSelectTeam")
util.AddNetworkString("Monarch_ShowPIC")

net.Receive("Monarch_SetRPName", function(_, admin)
    if not IsValid(admin) or not admin:IsAdmin() then return end
    local target = net.ReadEntity()
    local newName = string.Trim(net.ReadString() or "")
    if not IsValid(target) or newName == "" then return end
    if #newName > 64 then return end

    if target.SetTempRPName then
        target:SetTempRPName(newName)
    else
        target:SetNWString("temp_rpname", newName)
    end

    if IsValid(admin) and admin.Notify then
        admin:Notify("Temporarily set " .. target:Nick() .. "'s name to '"..newName.."'.")
    end
    if IsValid(target) and target.Notify then
        target:Notify("Your temporary name is now '"..newName.."'.")
    end
end)

hook.Add("PostPlayerDeath", "Monarch_RestoreTempName_OnDeath", function(ply)
    if not IsValid(ply) then return end
    if ply.RestoreRPName then ply:RestoreRPName() end
end)

net.Receive("Monarch_SetModel", function(_, ply)
    local targ = net.ReadEntity()
    local mdl = net.ReadString()
    if not IsValid(targ) or not mdl or mdl == "" then return end

    targ:SetModel(Model(mdl))

    if mysql and mysql.Update and targ.MonarchActiveChar and targ.MonarchActiveChar.id then
        local query = mysql:Update("monarch_characters")
        query:Update("model", mdl)

        if IsValid(targ) and targ:GetSkin() then
            query:Update("skin", targ:GetSkin())
            targ.MonarchActiveChar.skin = targ:GetSkin()
        end

        if targ.GetBodygroupCount then
            local groups = {}
            for i = 0, targ:GetNumBodyGroups() - 1 do
                groups[i] = targ:GetBodygroup(i)
            end
            local bgStr = util.TableToJSON(groups)
            if bgStr then
                query:Update("bodygroups", bgStr)
                targ.MonarchActiveChar.bodygroups = bgStr
            end
        end
        query:Where("id", targ.MonarchActiveChar.id)
        query:Callback(function()
            if IsValid(targ) and targ.MonarchActiveChar then
                targ.MonarchActiveChar.model = mdl
            end
            if IsValid(ply) and ply ~= targ and ply.Notify then
                ply:Notify("Set " .. targ:Nick() .. "'s model to " .. mdl)
            end
            if IsValid(targ) and targ.Notify then
                targ:Notify("Your model has been changed")
            end
        end)
        query:Execute()
    end
end)
if SERVER then

util.AddNetworkString("Monarch_CharDelete")
util.AddNetworkString("Monarch_CharList")

net.Receive("Monarch_CharDelete", function(len, ply)
    local charID = net.ReadUInt(32)
    if not IsValid(ply) or not charID or charID == 0 then return end

    if not Monarch_IsStaff(ply) then return end

    local delInv = mysql:Delete("monarch_inventory")
    delInv:Where("charid", charID)
    delInv:Callback(function()

        local query = mysql:Delete("monarch_players")
        query:Where("id", charID)
        query:Callback(function()
            if Monarch_Log then Monarch_Log("char_delete", { admin = ply, reason = string.format("id=%d", charID) }) end

            Monarch.CharSystem.SendCharacterList(ply)
        end)
        query:Execute()
    end)
    delInv:Execute()
end)

function Monarch.CharSystem.SendCharacterList(ply, callback)
    local query = mysql:Select("monarch_players")
    query:Where("steamid", ply:SteamID())
    query:OrderByAsc("id")

    query:Callback(function(result)
        if not IsValid(ply) then return end

        local chars = result or {}
        local count = math.min(#chars, 7) 

        net.Start("Monarch_CharList")
        net.WriteUInt(count, 3)

        for i = 1, count do
            local c = chars[i]
            net.WriteUInt(c.id, 32)
            net.WriteString(c.rpname or "")
            net.WriteString(c.model or "")
            net.WriteUInt(c.skin or 0, 8)
            net.WriteInt(c.xp or 0, 32)
            net.WriteInt(c.money or 0, 32)
            net.WriteInt(c.bankmoney or 0, 32)
            net.WriteUInt(c.team or 1, 8) 
            net.WriteString(c.bodygroups or "{}") 
        end

        net.Send(ply)

        if callback then
            callback(count)
        end
    end)

    query:Execute()
end

net.Receive("Monarch_CharListRequest", function(_, ply)
    Monarch.CharSystem.SendCharacterList(ply)
end)

end

net.Receive("MonarchInvDoDrop", function(len, ply)
    local itemid = net.ReadUInt(16)

    if not ply.beenInvSetup then 

        ply:Notify("Inventory not setup.")
        return 
    end

    if ply.NextItemDrop and ply.NextItemDrop > CurTime() then 

        ply:Notify("Please wait before dropping another item.")
        return 
    end

    local steamid = ply:SteamID64()

    if not Monarch or not Monarch.Inventory or not Monarch.Inventory.Data then

        ply:Notify("Inventory system not available.")
        return
    end

    if not Monarch.Inventory.Data[steamid] then

        ply:Notify("No inventory data found.")
        return
    end

    local inventoryData = Monarch.Inventory.Data[steamid]
    if not inventoryData then ply:Notify("Invalid inventory structure."); return end

    local item = inventoryData[itemid]
    if not item then

        ply:Notify("Item not found in inventory slot " .. itemid)
        return
    end

    local itemClass = item.class or item.id
    if not itemClass then

        ply:Notify("Invalid item data.")
        return
    end

    local itemKey = Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[itemClass]
    local itemDef = itemKey and Monarch.Inventory.Items and Monarch.Inventory.Items[itemKey]

    if not itemDef then

        ply:Notify("Unknown item type.")
        return
    end

    if item.equipped then

        ply:Notify("You cannot drop an equipped item. Unequip it first.")
        return
    end

    if (item.restricted or itemDef.Restricted or itemDef.restricted) and not itemDef.DropIfRestricted then

        ply:Notify("You cannot drop this item.")
        return
    end

    ply.DroppedItemsC = ply.DroppedItemsC or 0
    local limit = 30
    if ply.DroppedItemsC >= limit then

        ply:Notify("You can only have up to " .. limit .. " dropped items at once.")
        return
    end

    local trace = {}
    trace.start = ply:EyePos()
    trace.endpos = trace.start + ply:GetAimVector() * 45
    trace.filter = ply
    local tr = util.TraceLine(trace)

    inventoryData[itemid] = nil
    Monarch.SaveInventory(ply, inventoryData)

    local ent = ents.Create("monarch_item")
    if not IsValid(ent) then
        ply:Notify("Failed to create dropped item.")
        return
    end

    ent:SetPos(tr.HitPos + Vector(0, 0, 10))
    ent:SetModel(itemDef.Model or "models/props_junk/cardboard_box004a.mdl")
    ent:SetItemClass(itemClass)
    ent:Spawn()
    ent:Activate()

    ent.ItemOwner = ply
    ent.IsRestrictedItem = item.restricted or false

    if itemDef.WeaponClass and item.clip then
        ent.ItemClip = item.clip
    end

    ply.DroppedItemsC = ply.DroppedItemsC + 1
    ply.DroppedItemsCA = (ply.DroppedItemsCA or 0) + 1
    ply.DroppedItems = ply.DroppedItems or {}
    ply.NextItemDrop = CurTime() + 2
    ent.DropIndex = ply.DroppedItemsCA
    ply.DroppedItems[ply.DroppedItemsCA] = ent

    ent:SetCollisionGroup(COLLISION_GROUP_WORLD)

    ply:Notify("You dropped " .. itemDef.Name)

    net.Start("Monarch_Inventory_Update")
    net.WriteTable(Monarch.Inventory.Data[steamid] or {})
    net.Send(ply)
    if Monarch_Log then
        local cls = item and (item.class or item.id) or "?"
        Monarch_Log("drop_item", { admin = ply, reason = string.format("id=%s", tostring(cls)) })
    end
end)

net.Receive("MonarchMultiDrop", function(len, ply)
    local itemClass = net.ReadString()
    local amount = net.ReadUInt(6)

    amount = 1

    if not ply.beenInvSetup then 

        return 
    end

    if ply.NextItemDrop and ply.NextItemDrop > CurTime() then 

        return 
    end

    amount = math.min(amount or 1, 50) 
    local dropped = 0
    local steamid = ply:SteamID64()

    if not Monarch.Inventory.Data[steamid] then
        ply:Notify("No inventory data found.")
        return
    end

    local inventoryData = Monarch.Inventory.Data[steamid]
    if not inventoryData then ply:Notify("Invalid inventory structure."); return end

    for k, v in pairs(inventoryData) do
        if (v.class == itemClass or v.id == itemClass) and not v.equipped then
            local itemKey = Monarch.Inventory.ItemsRef[v.class or v.id]
            local itemDef = itemKey and Monarch.Inventory.Items[itemKey]

            if itemDef and (not v.restricted or itemDef.DropIfRestricted) then

                local trace = {}
                trace.start = ply:EyePos()
                trace.endpos = trace.start + ply:GetAimVector() * 45
                trace.filter = ply
                local tr = util.TraceLine(trace)

                inventoryData[k] = nil
                Monarch.SaveInventory(ply, inventoryData)

                local ent = ents.Create("monarch_item")
                if IsValid(ent) then
                    ent:SetPos(tr.HitPos + Vector(0, 0, 10))
                    ent:SetModel((itemDef and itemDef.Model) or "models/props_junk/cardboard_box004a.mdl")
                    if itemDef and itemDef.Material then ent:SetMaterial(itemDef.Material) end
                    ent:SetItemClass(v.class or v.id)
                    ent:Spawn()
                    ent:Activate()

                    ent.ItemOwner = ply
                    ent.IsRestrictedItem = v.restricted or false

                    if itemDef.WeaponClass and v.clip then
                        ent.ItemClip = v.clip
                    end

                    ply.DroppedItemsC = (ply.DroppedItemsC or 0) + 1
                    ply.DroppedItemsCA = (ply.DroppedItemsCA or 0) + 1
                    ply.DroppedItems = ply.DroppedItems or {}
                    ent.DropIndex = ply.DroppedItemsCA
                    ply.DroppedItems[ply.DroppedItemsCA] = ent

                    ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
                    dropped = dropped + 1
                end
            end

            if dropped >= amount then
                break
            end
        end
    end

    if dropped > 0 then
        local itemKey = Monarch.Inventory.ItemsRef[itemClass]
        local itemData = itemKey and Monarch.Inventory.Items[itemKey]
        local itemName = itemData and itemData.Name or itemClass
        ply:Notify("You dropped " .. dropped .. "x " .. itemName)
        ply.NextItemDrop = CurTime() + 2

        net.Start("Monarch_Inventory_Update")
        net.WriteTable(Monarch.Inventory.Data[steamid] or {})
        net.Send(ply)
        if Monarch_Log then
            Monarch_Log("drop_item_multi", { admin = ply, reason = string.format("class=%s x%d", itemClass or "?", dropped) })
        end
    else
        ply:Notify("No items to drop.")
    end
end)

hook.Add("Initialize", "MonarchAddTestItems", function()
    timer.Simple(0, function()
        if not Monarch or not Monarch.Inventory then return end
        Monarch_SendItemDefsCompressed(nil)

    end)
end)

hook.Add("PlayerInitialSpawn", "Monarch_SendItemDefs", function(ply)
    if not IsValid(ply) then return end
    if not Monarch or not Monarch.Inventory then return end
    Monarch_SendItemDefsCompressed(ply)
    ply._MonarchItemDefsSent = true

end)

local function Monarch_IsValidItemClass(cls)
    if not cls then return false end
    local Items = Monarch.Inventory and Monarch.Inventory.Items
    local Ref = Monarch.Inventory and Monarch.Inventory.ItemsRef
    if Items and Items[cls] then return true end 
    if Ref and Ref[cls] then
        local key = Ref[cls]
        if Items and Items[key] then return true end
    end
    return false
end

local function Monarch_SanitizeInventory(inv, maxSlots)
    if type(inv) ~= "table" then return {} end
    maxSlots = maxSlots or (MONARCH_INV_MAX_SLOTS or 25)
    local cleaned = {}
    for k, v in pairs(inv) do
        local idx = tonumber(k)
        if idx and idx >= 1 and idx <= maxSlots and type(v) == "table" then
            local cls = v.class or v.id
            if Monarch_IsValidItemClass(cls) then

                cleaned[idx] = {
                    id = cls,
                    class = cls,
                    equipped = v.equipped == true,
                    amount = tonumber(v.amount) or 1,
                    restricted = v.restricted == true,
                    constrained = v.constrained == true,
                    durability = math.Clamp(math.floor(tonumber(v.durability or 100) or 100), 0, 100)
                }
            end
        end
    end
    return cleaned
end

function meta:GiveInventoryItem(itemClass, amount, metadata)
    amount = amount or 1
    metadata = metadata or {}
    local steamid = self:SteamID64()

    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}
    Monarch.Inventory.Data[steamid] = Monarch.Inventory.Data[steamid] or {}

    local inv = Monarch.Inventory.Data[steamid]

    local maxSlots = MONARCH_INV_MAX_SLOTS or 25
    inv = Monarch_SanitizeInventory(inv, maxSlots)
    Monarch.Inventory.Data[steamid] = inv

    local def
    if Monarch.Inventory and Monarch.Inventory.Items then
        def = Monarch.Inventory.Items[itemClass]
        if (not def) and Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[itemClass] then
            local key = Monarch.Inventory.ItemsRef[itemClass]
            def = Monarch.Inventory.Items[key]
        end
    end

    if not def then
        if invDebug and invDebug:GetBool() then
            print(string.format("[INV] WARNING: Item definition not found for '%s'", tostring(itemClass)))
        end

        return 0
    end

    local preGive = hook.Run("Monarch_CanGiveInventoryItem", self, itemClass, amount, metadata, def)
    if preGive == false then
        return 0
    end
    if isnumber(preGive) then
        amount = math.max(0, math.floor(preGive))
        if amount <= 0 then
            return 0
        end
    end

    local hasDurability = def and def.Durability == true
    local canStack = def and (def.CanStack == true or def.Stackable == true)

    if hasDurability then
        canStack = false
    end
    local maxStack = 0 
    if def then
        maxStack = tonumber(def.MaxStack or def.StackSize or 0) or 0
    end

    if canStack and maxStack == 0 then
        maxStack = 5
    end

    if invDebug and invDebug:GetBool() then
        print(string.format("[INV] GiveInventoryItem: class=%s, amount=%d, canStack=%s, maxStack=%d", 
            tostring(itemClass), amount, tostring(canStack), maxStack))
    end

    amount = math.max(1, math.floor(tonumber(amount) or 1))
    local requestedAmount = amount
    local remaining = amount
    local addedAny = false

    local gridMaxSlots = MONARCH_INV_GRID_SLOTS or 20

    local gridInv = {}
    for i = 1, gridMaxSlots do
        if inv[i] and inv[i].equipped ~= true then
            gridInv[i] = inv[i]
        end
    end

    -- Constrained items should not stack - treat them as individual items
    local isConstrainedItem = metadata.constrained or false
    local itemStartingDurability = math.Clamp(math.floor(tonumber(def and (def.StartingDurability or def.DurabilityStart or def.DefaultDurability) or 100) or 100), 0, 100)
    local initialDurability = math.Clamp(math.floor(tonumber(metadata.durability or metadata.DurabilityValue or itemStartingDurability) or itemStartingDurability), 0, 100)

    if canStack and not isConstrainedItem then
        for i = 1, maxSlots do
            local it = gridInv[i]
            if it then
                -- Don't stack onto constrained items
                local existingIsConstrained = it.constrained or false
                if not existingIsConstrained then
                    local cls = it.class or it.id
                    if cls == itemClass then
                        local curr = tonumber(it.amount) or 1
                        if maxStack > 0 then
                            local space = math.max(0, maxStack - curr)
                            if space > 0 then
                                local add = math.min(space, remaining)
                                it.amount = curr + add
                                inv[i].amount = it.amount  
                                remaining = remaining - add
                                addedAny = addedAny or (add > 0)
                                if remaining <= 0 then break end
                            end
                        else

                            it.amount = curr + remaining
                            inv[i].amount = it.amount  
                            remaining = 0
                            addedAny = true
                            break
                        end
                    end
                end
            end
        end
    end

    while remaining > 0 do
        local nextSlot
        for i = 1, gridMaxSlots do
            if inv[i] == nil then
                nextSlot = i
                break
            end
        end
        if not nextSlot then

            if not addedAny then
                self:Notify("Inventory is full.")
                hook.Run("Monarch_InventoryGiveBlocked", self, itemClass, requestedAmount, metadata, "full")
                return false
            else
                self:Notify("Inventory is full.")
                break
            end
        end

        local slotAmount
        -- Constrained items always take 1 slot each, never stack
        if isConstrainedItem then
            slotAmount = 1
        elseif canStack then

            if maxStack > 0 then
                slotAmount = math.min(remaining, maxStack)
            else

                slotAmount = remaining
            end
        else

            slotAmount = 1
        end

        inv[nextSlot] = {
            id = itemClass,
            class = itemClass,
            equipped = false,
            amount = slotAmount,
            restricted = false,
            constrained = metadata.constrained or false,
            durability = hasDurability and initialDurability or nil
        }
        remaining = remaining - slotAmount
        addedAny = true
    end

    do
        local charID = self.MonarchID or (self.MonarchActiveChar and self.MonarchActiveChar.id) or self.MonarchLastCharID
        if charID and Monarch and Monarch.Inventory and Monarch.Inventory.SaveForOwner then

            Monarch.Inventory.Data = Monarch.Inventory.Data or {}
            Monarch.Inventory.Data[charID] = Monarch.Inventory.Data[charID] or {}
            Monarch.Inventory.Data[charID][1] = {}
            for i = 1, (MONARCH_INV_MAX_SLOTS or 20) do
                local it = inv[i]
                if it then
                    Monarch.Inventory.Data[charID][1][i] = table.Copy(it)
                end
            end
            Monarch.Inventory.SaveForOwner(self, charID, Monarch.Inventory.Data[charID][1])
        end
    end
    self:SyncInventory()

    local actuallyAdded = amount - remaining

    if invDebug and invDebug:GetBool() then
        print(string.format("[INV] GiveInventoryItem result: added=%d, remaining=%d, full=%s", 
            actuallyAdded, remaining, tostring(remaining > 0)))
    end

    hook.Run("Monarch_InventoryItemGiven", self, itemClass, actuallyAdded, requestedAmount, metadata, def, remaining)

    return actuallyAdded
end

local function Monarch_GetItemDurability(item, def)
    if not istable(item) or not istable(def) or def.Durability ~= true then
        return nil
    end

    local value = item.durability
    if value == nil then
        value = 100
        item.durability = value
    end

    value = math.Clamp(math.floor(tonumber(value) or 100), 0, 100)
    item.durability = value
    return value
end

local function Monarch_ResolveDurabilityLoss(def, ply, slot, item, context)
    if not def or type(def.ShouldLoseDurability) ~= "function" then
        return 0
    end

    local ok, result = pcall(def.ShouldLoseDurability, def, ply, slot, item, context)
    if not ok then
        ok, result = pcall(def.ShouldLoseDurability, ply, slot, item, def, context)
    end
    if not ok then
        return 0
    end

    if result == true then
        return 1
    end

    if isnumber(result) then
        return math.max(0, math.floor(result))
    end

    if istable(result) then
        if result.lose == false then return 0 end
        if isnumber(result.amount) then
            return math.max(0, math.floor(result.amount))
        end
        if result.lose == true then
            return 1
        end
    end

    return 0
end

local function Monarch_ApplyDurabilityLoss(ply, inv, slot, item, def, context)
    local durability = Monarch_GetItemDurability(item, def)
    if durability == nil then return false end

    local loss = Monarch_ResolveDurabilityLoss(def, ply, slot, item, context)
    if loss <= 0 then return false end

    local newDurability = math.Clamp(durability - loss, 0, 100)
    if type(def.SetDurability) == "function" then
        local ok = pcall(def.SetDurability, def, item, newDurability, ply, slot, context)
        if not ok then
            pcall(def.SetDurability, item, newDurability)
        end
    else
        item.durability = newDurability
    end

    if newDurability > 0 then
        return true
    end

    if type(def.OnDurabilityDrained) == "function" then
        local ok = pcall(def.OnDurabilityDrained, def, ply, slot, item, context)
        if not ok then
            pcall(def.OnDurabilityDrained, ply, slot, item, def, context)
        end
    end

    if item.equipped then
        if def.WeaponClass then
            local wep = ply:GetWeapon(def.WeaponClass)
            if IsValid(wep) then
                if wep.Clip1 then
                    local clip = wep:Clip1()
                    if isnumber(clip) then item.clip = clip end
                end
                ply:StripWeapon(def.WeaponClass)
            end
        end
        Monarch_CallItemHook(def, "OnRemove", ply, slot, item)
    end

    inv[slot] = nil
    return true
end

function meta:SyncInventory()
    local steamid = self:SteamID64()
    if not steamid then return end
    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}
    local inv = Monarch.Inventory.Data[steamid] or {}

    net.Start("Monarch_Inventory_Update")
        net.WriteTable(inv)
    net.Send(self)

end

concommand.Add("monarch_giveitem", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    local target = ply
    local itemClass = args[1]
    local amount = tonumber(args[2]) or 1

    if args[3] then
        local targetName = args[1]
        itemClass = args[2]
        amount = tonumber(args[3]) or 1

        for _, p in player.Iterator() do
            if string.find(string.lower(p:Nick()), string.lower(targetName)) then
                target = p
                break
            end
        end
    end

    if not itemClass then
        ply:ChatPrint("Usage: monarch_giveitem <player> <itemclass> <amount>")
        return
    end

    if not Monarch.Inventory.ItemsRef[itemClass] then
        ply:ChatPrint("Item '" .. itemClass .. "' does not exist!")

        return
    end

    for i = 1, amount do
        target:GiveInventoryItem(itemClass)
    end

    ply:ChatPrint("Gave " .. amount .. "x " .. itemClass .. " to " .. target:Nick())
end)

concommand.Add("monarch_addmoney", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end

    if not args[1] or not args[2] then
        ply:ChatPrint("Usage: monarch_addmoney <player> <amount>")
        return
    end

    local targetName = args[1]
    local amount = tonumber(args[2])

    if not amount then
        ply:ChatPrint("Invalid amount specified.")
        return
    end

    local target = nil
    for _, p in player.Iterator() do
        if string.find(string.lower(p:Nick()), string.lower(targetName)) then
            target = p
            break
        end
    end

    if not IsValid(target) then
        ply:ChatPrint("Player not found.")
        return
    end

    if target.AddMoney then
        target:AddMoney(amount)
        ply:ChatPrint("Added $" .. amount .. " to " .. target:Nick() .. "'s wallet.")
        if target.Notify then
            target:Notify("You received $" .. amount .. " from an administrator.")
        end
    else
        ply:ChatPrint("Failed to add money (AddMoney function not available).")
    end
end)

util.AddNetworkString("Monarch_Inventory_MoveItem")

net.Receive("Monarch_Inventory_MoveItem", function(_, ply)
    local source = net.ReadUInt(8)
    local target = net.ReadUInt(8)
    if not IsValid(ply) then return end
    local steamid = ply:SteamID64()
    if not steamid then return end

    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}
    local inv = Monarch.Inventory.Data[steamid]
    if not inv then return end
    if source == target then return end
    if not inv[source] and not inv[target] then return end

    local function resolveDef(class)
        if not class then return nil end
        local defs = Monarch.Inventory and Monarch.Inventory.Items or nil
        local ref = Monarch.Inventory and Monarch.Inventory.ItemsRef or nil
        if not defs then return nil end
        if ref and ref[class] then
            return defs[ref[class]]
        end
        return defs[class]
    end

    local function callRemove(def, slotId, itemData)
        if not def or type(def.OnRemove) ~= "function" then return end
        local ok = pcall(def.OnRemove, ply, slotId, itemData, def)
        if not ok then
            pcall(def.OnRemove, def, ply, itemData, slotId)
        end
    end

    local function unequipIfNeeded(slotId, itemData)
        if not istable(itemData) or itemData.equipped ~= true then return end
        local class = itemData.class or itemData.id
        local def = resolveDef(class)
        if def and def.WeaponClass then
            local wep = ply:GetWeapon(def.WeaponClass)
            if IsValid(wep) and wep.Clip1 then
                local c = wep:Clip1()
                if isnumber(c) then itemData.clip = c end
            end
            if IsValid(wep) then
                ply:StripWeapon(def.WeaponClass)
            end
        end
        callRemove(def, slotId, itemData)
        itemData.equipped = false
    end

    unequipIfNeeded(source, inv[source])
    unequipIfNeeded(target, inv[target])

    inv[source], inv[target] = inv[target], inv[source]
    Monarch.SaveInventory(ply, inv)
    net.Start("Monarch_Inventory_Update")
        net.WriteTable(inv)
    net.Send(ply)
end)

function Monarch.SaveInventory(ply, inv)

    if not IsValid(ply) then return end
    local charid = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchID or ply.MonarchLastCharID
    local sid = ply:SteamID64()
    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}

    if sid then Monarch.Inventory.Data[sid] = inv end
    if charid and Monarch and Monarch.Inventory and Monarch.Inventory.SaveForOwner then
        Monarch.Inventory.SaveForOwner(ply, charid, inv)
    end
end

function Monarch.LoadInventoryForChar(ply, charid, onLoaded)

    if not IsValid(ply) or not charid then return end
    if Monarch and Monarch.Inventory and Monarch.Inventory.LoadForOwner then
        Monarch.Inventory.LoadForOwner(ply, charid, onLoaded)
    end
end

local function Monarch_GetInventory(ply)
    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}
    local sid = ply:SteamID64()
    Monarch.Inventory.Data[sid] = Monarch.Inventory.Data[sid] or {}
    return Monarch.Inventory.Data[sid]
end

local function Monarch_SyncInventoryOnly(ply, inv)
    if not IsValid(ply) then return end
    if not inv then inv = Monarch_GetInventory(ply) end
    net.Start("Monarch_Inventory_Update")
        net.WriteTable(inv)
    net.Send(ply)
end

local pendingSaves = {}
local function Monarch_QueueSave(ply)
    if not IsValid(ply) then return end
    local sid = ply:SteamID64()
    if pendingSaves[sid] then return end 
    pendingSaves[sid] = true
    timer.Simple(1, function() 
        if not IsValid(ply) then pendingSaves[sid] = nil return end
        local inv = Monarch_GetInventory(ply)
        local charID = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchID or ply.MonarchLastCharID
        if charID and Monarch and Monarch.Inventory and Monarch.Inventory.SaveForOwner then
            Monarch.Inventory.SaveForOwner(ply, charID, inv)
        end
        if Monarch.SaveInventoryPData then Monarch.SaveInventoryPData(ply, inv) end
        pendingSaves[sid] = nil
    end)
end

local function Monarch_SaveAndSyncInventory(ply, inv, doSave)
    Monarch_SyncInventoryOnly(ply, inv)
    if doSave ~= false then
        Monarch_QueueSave(ply)
    end
end

hook.Add("PlayerInitialSpawn", "Monarch_LoadInventoryFallback", function(ply)

end)

hook.Add("PlayerDisconnected", "Monarch_SaveInventoryPData", function(ply)
    local inv = Monarch.Inventory.Data[ply:SteamID64()]
    if inv then
        local charID = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchID or ply.MonarchLastCharID
        if charID and Monarch and Monarch.Inventory and Monarch.Inventory.SaveForOwner then
            Monarch.Inventory.SaveForOwner(ply, charID, inv)
        end
        Monarch.SaveInventoryPData(ply, inv)
    end
end)

if SERVER then
    timer.Create("Monarch_Inventory_AutosaveFast", 1, 0, function()
        for _, ply in player.Iterator() do
            if IsValid(ply) then
                local charID = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchID or ply.MonarchLastCharID

                if not ply._invLoaded then continue end

                if charID then
                    local inv = Monarch_GetInventory(ply)
                    if Monarch and Monarch.Inventory and Monarch.Inventory.SaveForOwner then
                        Monarch.Inventory.SaveForOwner(ply, charID, inv)
                    end
                    if Monarch.SaveInventoryPData then Monarch.SaveInventoryPData(ply, inv) end
                end
            end
        end
    end)
end

net.Receive("Monarch_Loot_RequestOpen", function(_, ply)
    local ent = net.ReadEntity()
    if not Monarch_IsLootEntity(ent) then return end
    if ent:GetPos():DistToSqr(ply:GetPos()) > (130*130) then return end
    local def = ent.GetLootDef and ent:GetLootDef()

    if def and def.CanLoot ~= nil then
        local canOpen, denyReason = true, nil

        if isfunction(def.CanLoot) then
            local ok, result, reason = pcall(def.CanLoot, ply, ent, def)
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
                local curLevel = (Monarch and Monarch.Skills and Monarch.Skills.GetLevel and Monarch.Skills.GetLevel(ply, skillId)) or 0
                if curLevel < reqLevel then
                    canOpen = false
                    local skillDef = Monarch and Monarch.GetSkill and Monarch.GetSkill(skillId)
                    local skillName = (skillDef and skillDef.Name) or skillId
                    local levelName = (Monarch and Monarch.Skills and Monarch.Skills.GetLevelName and Monarch.Skills.GetLevelName(reqLevel)) or tostring(reqLevel)
                    denyReason = string.format("This requires %s level %s.", string.lower(tostring(skillName)), tostring(levelName))
                end
            end
        end

        if not canOpen then
            if ply.Notify then
                ply:Notify(denyReason or "You cannot open this container yet.")
            end
            return
        end
    end

    local defID = ent.GetLootDefID and ent:GetLootDefID()
    local openTime = (def and (def.OpenTime or def.OpenTIme)) or 0
    timer.Simple(openTime, function()
        if not IsValid(ply) or not IsValid(ent) then return end
        if ent:GetPos():DistToSqr(ply:GetPos()) > (130*130) then return end
        local isStorage = Monarch_IsStorageEntity(ent)

        local function sendOpen(contents)
            net.Start("Monarch_Loot_Open")
                net.WriteEntity(ent)
                net.WriteTable(contents or {})
                net.WriteString(def and (def.UseName or "Open Loot") or "Open Loot")

                local capX = (def and tonumber(def.CapacityX)) or (ent.GetCapacityX and ent:GetCapacityX()) or 5
                local capY = (def and tonumber(def.CapacityY)) or (ent.GetCapacityY and ent:GetCapacityY()) or 5
                if isStorage then
                    capX = tonumber(Config and Config.StorageGridCols) or capX or 5
                    capY = tonumber(Config and Config.StorageGridRows) or capY or 6
                end

                local canStore = (def and def.CanStore == true) or (ent.GetStoreable and ent:GetStoreable()) or false
                if isStorage then canStore = true end
                net.WriteUInt(math.max(0, math.min(capX * capY, 4095)), 12)
                net.WriteBool(canStore)
                net.WriteUInt(math.max(0, math.min(capX, 255)), 8)
                net.WriteUInt(math.max(0, math.min(capY, 255)), 8)
            net.Send(ply)
        end

        if isStorage and ent:GetClass() == "monarch_storage" and ent.LoadContentsFor then
            ent:LoadContentsFor(ply, function(entLoaded, loaded)
                if not IsValid(entLoaded) or not IsValid(ply) then return end
                if entLoaded:GetPos():DistToSqr(ply:GetPos()) > (130*130) then return end
                sendOpen(loaded)
            end)
            return
        end

        local contents = (ent.GetContents and ent:GetContents()) or {}
        if isStorage and (not ent.GetContents or ent:GetClass() ~= "monarch_storage") then
            contents = Monarch_BuildStorageContents(ply)
        end
        sendOpen(contents)
    end)
end)

local function Monarch_NormalizeGiveResult(result, requestedAmount)
    if result == true then return requestedAmount end
    if result == false or result == nil then return 0 end
    return math.max(0, math.floor(tonumber(result) or 0))
end

local function Monarch_GetCrateContentsFor(ent, ply)
    if not IsValid(ent) then return {} end
    if ent.GetContentsFor then
        local c = ent:GetContentsFor(ply)
        return istable(c) and c or {}
    end
    if ent.GetContents then
        local c = ent:GetContents(ply)
        return istable(c) and c or {}
    end
    return {}
end

local function Monarch_UpdateLoot(ent)
    if not IsValid(ent) then return end
    if Monarch_IsStorageEntity and Monarch_IsStorageEntity(ent) then return end
    if not ent.GetContents then return end
    if ent.GetPersistentID then
        local uid = ent:GetPersistentID()
        if uid and Monarch._lootPersist and Monarch._lootPersist[uid] then
            local rec = Monarch._lootPersist[uid]
            rec.contents = ent:GetContents() or {}
            Monarch_SaveLootPersist()
        end
    end
end

net.Receive("Monarch_Loot_Take", function(_, ply)
    local ent = net.ReadEntity()
    local idx = net.ReadUInt(8)
    if not Monarch_IsLootEntity(ent) then return end
    if ent:GetPos():DistToSqr(ply:GetPos()) > (130*130) then return end
    local defID = ent.GetLootDefID and ent:GetLootDefID()
    local isStorage = Monarch_IsStorageEntity(ent)
    local contents = (not isStorage and ent.GetContents and ent:GetContents()) or {}
    local item = contents[idx]

    if isStorage then
        if ent.GetContents and ent:GetClass() == "monarch_storage" then
            local crateContents = Monarch_GetCrateContentsFor(ent, ply)
            local crateItem = crateContents[idx]
            if not crateItem then return end

            local requested = math.max(1, math.floor(tonumber(crateItem.amount or 1) or 1))
            local added = 0
            if ply.GiveInventoryItem then
                added = Monarch_NormalizeGiveResult(ply:GiveInventoryItem(crateItem.id or crateItem.class, requested), requested)
            end
            if added <= 0 then return end

            local remaining = requested - added
            if remaining > 0 then
                crateItem.amount = remaining
                crateContents[idx] = crateItem
            else
                table.remove(crateContents, idx)
            end

            if ent.SetContents then
                ent:SetContents(crateContents, ply)
            end
            if ent.SaveContents then
                ent:SaveContents(ply)
            end

            local steamid = ply:SteamID64()
            local inv = Monarch.Inventory.Data and Monarch.Inventory.Data[steamid] or {}
            Monarch.SaveInventory(ply, inv)
            net.Start("Monarch_Inventory_Update")
                net.WriteTable(inv)
            net.Send(ply)

            net.Start("Monarch_Loot_Update")
                net.WriteEntity(ent)
                net.WriteTable(Monarch_GetCrateContentsFor(ent, ply))
            net.Send(ply)
            return
        end

        local list = Monarch_GetStorageList(ply)
        local entry = list[idx]
        if not entry or not entry.item then return end
        local stored = entry.item
        local amount = tonumber(stored.amount) or 1
        local added = 0
        if ply.GiveInventoryItem then
            added = ply:GiveInventoryItem(stored.id or stored.class, amount) or 0
        end
        if added <= 0 then return end

        local steamid = ply:SteamID64()
        local inv = Monarch.Inventory.Data and Monarch.Inventory.Data[steamid] or {}
        local remaining = amount - added
        if remaining > 0 then
            stored.amount = remaining
            inv[entry.slot] = stored
        else
            inv[entry.slot] = nil
        end

        Monarch.SaveInventory(ply, inv)
        net.Start("Monarch_Inventory_Update")
            net.WriteTable(inv)
        net.Send(ply)

        net.Start("Monarch_Loot_Update")
            net.WriteEntity(ent)
            net.WriteTable(Monarch_BuildStorageContents(ply))
        net.Send(ply)
        if Monarch_Log then
            Monarch_Log("loot_take", { admin = ply, reason = string.format("from=%s idx=%d id=%s storage=%s", tostring(ent), idx or -1, tostring(stored.id or "?"), tostring(isStorage)) })
        end
        return
    end

    if not item then return end
    local success = false
    if ply.GiveInventoryItem then
        success = ply:GiveInventoryItem(item.id, item.amount or 1)
    end

    if success then
        table.remove(contents, idx)
        ent:SetContents(contents)
        Monarch_UpdateLoot(ent)
        hook.Run("Monarch_LootItemTaken", ply, ent, item.id, item.amount or 1, false)
        net.Start("Monarch_Loot_Update")
            net.WriteEntity(ent)
            net.WriteTable(contents)
        net.Send(ply)
        if Monarch_Log then
            Monarch_Log("loot_take", { admin = ply, reason = string.format("from=%s idx=%d id=%s storage=%s", tostring(ent), idx or -1, tostring(item.id or "?"), tostring(isStorage)) })
        end
    end
end)

net.Receive("Monarch_Loot_TakeAll", function(_, ply)
    local ent = net.ReadEntity()
    if not Monarch_IsLootEntity(ent) then return end
    if ent:GetPos():DistToSqr(ply:GetPos()) > (130*130) then return end
    local defID = ent.GetLootDefID and ent:GetLootDefID()
    local isStorage = Monarch_IsStorageEntity(ent)
    local contents = (not isStorage and ent.GetContents and ent:GetContents()) or {}

    if isStorage then
        if ent.GetContents and ent:GetClass() == "monarch_storage" then
            local crateContents = Monarch_GetCrateContentsFor(ent, ply)
            if #crateContents == 0 then return end

            local i = 1
            while i <= #crateContents do
                local crateItem = crateContents[i]
                local requested = math.max(1, math.floor(tonumber(crateItem.amount or 1) or 1))
                local added = 0
                if ply.GiveInventoryItem then
                    added = Monarch_NormalizeGiveResult(ply:GiveInventoryItem(crateItem.id or crateItem.class, requested), requested)
                end

                if added > 0 then
                    local remaining = requested - added
                    if remaining > 0 then
                        crateItem.amount = remaining
                        crateContents[i] = crateItem
                        i = i + 1
                    else
                        table.remove(crateContents, i)
                    end
                else
                    i = i + 1
                end
            end

            if ent.SetContents then
                ent:SetContents(crateContents, ply)
            end
            if ent.SaveContents then
                ent:SaveContents(ply)
            end

            local steamid = ply:SteamID64()
            local inv = Monarch.Inventory.Data and Monarch.Inventory.Data[steamid] or {}
            Monarch.SaveInventory(ply, inv)
            net.Start("Monarch_Inventory_Update")
                net.WriteTable(inv)
            net.Send(ply)

            net.Start("Monarch_Loot_Update")
                net.WriteEntity(ent)
                net.WriteTable(Monarch_GetCrateContentsFor(ent, ply))
            net.Send(ply)
            return
        end

        local list = Monarch_GetStorageList(ply)
        if #list == 0 then return end
        local steamid = ply:SteamID64()
        local inv = Monarch.Inventory.Data and Monarch.Inventory.Data[steamid] or {}
        for _, entry in ipairs(list) do
            local stored = entry.item
            local amount = tonumber(stored.amount) or 1
            local added = 0
            if ply.GiveInventoryItem then
                added = ply:GiveInventoryItem(stored.id or stored.class, amount) or 0
            end
            if added > 0 then
                local remaining = amount - added
                if remaining > 0 then
                    stored.amount = remaining
                    inv[entry.slot] = stored
                else
                    inv[entry.slot] = nil
                end
            end
        end

        Monarch.SaveInventory(ply, inv)
        net.Start("Monarch_Inventory_Update")
            net.WriteTable(inv)
        net.Send(ply)

        net.Start("Monarch_Loot_Update")
            net.WriteEntity(ent)
            net.WriteTable(Monarch_BuildStorageContents(ply))
        net.Send(ply)
        if Monarch_Log then
            Monarch_Log("loot_take_all", { admin = ply, reason = string.format("from=%s storage=%s", tostring(ent), tostring(isStorage)) })
        end
        return
    end

    local i = 1
    while i <= #contents do
        local item = contents[i]
        if ply.GiveInventoryItem and ply:GiveInventoryItem(item.id, item.amount or 1) then
            hook.Run("Monarch_LootItemTaken", ply, ent, item.id, item.amount or 1, false)
            table.remove(contents, i)
        else
            i = i + 1
        end
    end
    ent:SetContents(contents)
    Monarch_UpdateLoot(ent)
    net.Start("Monarch_Loot_Update")
        net.WriteEntity(ent)
        net.WriteTable(contents)
    net.Send(ply)
    if Monarch_Log then
        Monarch_Log("loot_take_all", { admin = ply, reason = string.format("from=%s storage=%s", tostring(ent), tostring(isStorage)) })
    end
end)

hook.Add("PlayerDeath", "Monarch_DropInventoryOnDeath", function(ply, inflictor, attacker)
    if not IsValid(ply) then return end
    local steamid = ply:SteamID64()
    if not steamid then return end
    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}
    local inv = Monarch.Inventory.Data[steamid] or {}

    inv = Monarch_SanitizeInventory(inv, MONARCH_INV_MAX_SLOTS)

    local contents = {}
    local lockedItems = {}
    for i = 1, MONARCH_INV_MAX_SLOTS or 20 do
        local it = inv[i]
        if it and (it.id or it.class) then
            local itemID = it.id or it.class
            local itemDef = Monarch.Inventory.Items and Monarch.Inventory.Items[itemID]

            local isLocked = itemDef and itemDef.Locked
            local isRestricted = (itemDef and (itemDef.Restricted or itemDef.restricted)) or it.restricted or false
            local isConstrained = it.constrained or false

            -- Locked and restricted items stay in inventory, constrained items drop
            if isLocked or isRestricted then
                table.insert(lockedItems, { slot = i, item = table.Copy(it) })
            else
                table.insert(contents, { id = itemID, amount = it.amount or 1 })
            end
        end
    end

    if #contents == 0 then return end

    Monarch.Inventory.Data[steamid] = {}
    for _, lockedItem in ipairs(lockedItems) do
        Monarch.Inventory.Data[steamid][lockedItem.slot] = table.Copy(lockedItem.item)
    end
    Monarch.SaveInventory(ply, Monarch.Inventory.Data[steamid])
    if ply.SyncInventory then ply:SyncInventory() end

    local chunkSize = MONARCH_INV_MAX_SLOTS or 20
    local pos = ply:GetPos() + Vector(0,0,8)
    local ang = Angle(0, ply:EyeAngles().y, 0)
    local spawned = 0
    local idx = 1
    while idx <= #contents do
        local ent = ents.Create("monarch_loot")
        if not IsValid(ent) then break end
        ent:SetPos(pos + Vector(math.random(-12,12), math.random(-12,12), 4))
        ent:SetAngles(ang)
        ent:Spawn()

        local slice = {}
        for i = idx, math.min(idx + chunkSize - 1, #contents) do
            table.insert(slice, contents[i])
        end
        ent:SetContents(slice)

        if ent.SetCustomModel then
            ent:SetCustomModel("models/props_junk/wood_crate001a.mdl")
        end

        timer.Simple(600, function()
            if IsValid(ent) then ent:Remove() end
        end)
        spawned = spawned + 1
        idx = idx + chunkSize
    end

    if IsValid(attacker) and attacker:IsPlayer() then
        if Monarch_Log then Monarch_Log("kill", { admin = attacker, target = ply, reason = tostring(IsValid(inflictor) and inflictor:GetClass() or "") }) end
    end
end)

hook.Add("PlayerHurt", "Monarch_LogDamage", function(victim, attacker, hpRemaining, dmgTaken)
    if IsValid(attacker) and attacker:IsPlayer() and IsValid(victim) and victim:IsPlayer() then
        if Monarch_Log then Monarch_Log("damage", { admin = attacker, target = victim, reason = string.format("%d dmg (hp left %d)", tonumber(dmgTaken) or 0, tonumber(hpRemaining) or 0) }) end
    end
end)

concommand.Add("monarch_spawnloot", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local defid = args[1]
    if not defid or not (Monarch.Loot and Monarch.Loot.Defs[defid]) then
        ply:ChatPrint("Usage: monarch_spawnloot <defid> [unique_id]")
        return
    end
    local uid = args[2] or (defid .. "_" .. string.Left(util.CRC(tostring(RealTime()) .. ply:SteamID()), 8))
    local tr = ply:GetEyeTrace()
    local ent = ents.Create("monarch_loot")
    if not IsValid(ent) then return end
    ent:SetPos(tr.HitPos + Vector(0,0,10))
    ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    ent:Spawn()
    ent:SetLootDef(defid)
    if ent.SetPersistentID then ent:SetPersistentID(uid) end
    Monarch._lootPersist = Monarch._lootPersist or {}
    local rec = {
        uid = uid,
        defid = defid,
        pos = {x=ent:GetPos().x,y=ent:GetPos().y,z=ent:GetPos().z},
        ang = {p=ent:GetAngles().p,y=ent:GetAngles().y,r=ent:GetAngles().r},
        contents = ent.GetContents and ent:GetContents() or {},
        model = ent:GetModel()
    }
    Monarch._lootPersist[uid] = rec
    Monarch_SaveLootPersist()
    ply:ChatPrint("Spawned loot '"..defid.."' with UID "..uid)
end)

concommand.Add("monarch_setlootmodel", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local mdl = args[1]
    if not mdl or mdl == "" then
        ply:ChatPrint("Usage: monarch_setlootmodel <model_path>")
        return
    end
    local tr = ply:GetEyeTrace()
    local ent = IsValid(tr.Entity) and tr.Entity or nil
    if not IsValid(ent) or ent:GetClass() ~= "monarch_loot" then
        ply:ChatPrint("Look at a monarch_loot entity to configure it.")
        return
    end
    if ent.SetCustomModel then ent:SetCustomModel(mdl) else ent:SetModel(mdl) end

    if ent.GetPersistentID then
        local uid = ent:GetPersistentID()
        if uid and uid ~= "" then
            Monarch._lootPersist = Monarch._lootPersist or {}
            local rec = Monarch._lootPersist[uid] or {}
            rec.uid = uid
            rec.defid = ent.GetLootDefID and ent:GetLootDefID() or rec.defid
            rec.pos = rec.pos or {x=ent:GetPos().x,y=ent:GetPos().y,z=ent:GetPos().z}
            rec.ang = rec.ang or {p=ent:GetAngles().p,y=ent:GetAngles().y,r=ent:GetAngles().r}
            rec.contents = ent.GetContents and ent:GetContents() or rec.contents or {}
            rec.model = ent:GetModel()
            Monarch._lootPersist[uid] = rec
            local MAP = game.GetMap()
            local out = {}
            for _, data in pairs(Monarch._lootPersist) do table.insert(out, data) end
            file.CreateDir("monarch")
            file.Write("monarch/loot_" .. MAP .. ".json", util.TableToJSON(out, false))
        end
    end
    ply:ChatPrint("Set loot model to '" .. mdl .. "'")
end)

concommand.Add("monarch_setloot", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local defid = args[1]
    if not defid or not (Monarch.Loot and Monarch.Loot.Defs[defid]) then
        ply:ChatPrint("Usage: monarch_setloot <defid> [unique_id]")
        return
    end

    local tr = ply:GetEyeTrace()
    local ent = IsValid(tr.Entity) and tr.Entity or nil
    if not IsValid(ent) or ent:GetClass() ~= "monarch_loot" then
        ply:ChatPrint("Look at a monarch_loot entity to configure it.")
        return
    end

    ent:SetLootDef(defid)

    local uid = args[2]
    if not uid or uid == "" then
        uid = ent.GetPersistentID and ent:GetPersistentID() or nil
    end
    if not uid or uid == "" then
        uid = defid .. "_" .. string.Left(util.CRC(tostring(RealTime()) .. ply:SteamID()), 8)
    end
    if ent.SetPersistentID then ent:SetPersistentID(uid) end

    Monarch._lootPersist = Monarch._lootPersist or {}
    local rec = Monarch._lootPersist[uid] or {}
    rec.uid = uid
    rec.defid = defid
    rec.pos = { x = ent:GetPos().x, y = ent:GetPos().y, z = ent:GetPos().z }
    rec.ang = { p = ent:GetAngles().p, y = ent:GetAngles().y, r = ent:GetAngles().r }
    rec.contents = ent.GetContents and ent:GetContents() or {}
    Monarch._lootPersist[uid] = rec

    local MAP = game.GetMap()
    local out = {}
    for _, data in pairs(Monarch._lootPersist) do table.insert(out, data) end
    file.CreateDir("monarch")
    file.Write("monarch/loot_" .. MAP .. ".json", util.TableToJSON(out, false))

    ply:ChatPrint("Configured loot to '" .. defid .. "' with UID " .. uid)
    net.Start("Monarch_Loot_Update")
        net.WriteEntity(ent)
        net.WriteTable(rec.contents or {})
    net.Broadcast()
end)

local function Monarch_GetLootCapacity(ent)
    if not IsValid(ent) or ent:GetClass() ~= "monarch_loot" then return 0 end
    local def = ent.GetLootDef and ent:GetLootDef()
    if not def then return 0 end

    local capExplicit = tonumber(def.Capacity)
    if capExplicit and capExplicit > 0 then
        return capExplicit
    end

    local capX = tonumber(def.CapacityX) or 5
    local capY = tonumber(def.CapacityY) or 5
    return math.max(0, capX) * math.max(0, capY)
end

local function Monarch_CountLootItems(contents)
    local count = 0
    for _, v in pairs(contents or {}) do
        if istable(v) and (v.id or v.class) then
            count = count + 1
        end
    end
    return count
end

net.Receive("Monarch_Loot_Put", function(_, ply)
    local ent = net.ReadEntity()
    local sourceSlot = net.ReadUInt(8)
    local targetLootSlot = 0
    pcall(function()
        targetLootSlot = net.ReadUInt(12) or 0
    end)
    if not IsValid(ply) or not Monarch_IsLootEntity(ent) then return end
    if ent:GetPos():DistToSqr(ply:GetPos()) > (130*130) then return end
    local defID = ent.GetLootDefID and ent:GetLootDefID()
    local isStorage = Monarch_IsStorageEntity(ent)

    local canStore = (ent.GetStoreable and ent:GetStoreable())
    if canStore == nil then

        local def = ent.GetLootDef and ent:GetLootDef() or nil
        canStore = (def and def.CanStore == true) or false
    end
    if not canStore then

        net.Start("Monarch_Loot_PutResult")
            net.WriteBool(false)  
            net.WriteString("You can't put items into this container.")
        net.Send(ply)
        return
    end
    local steamid = ply:SteamID64()
    if not steamid then return end

    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}
    local inv = Monarch.Inventory.Data[steamid] or {}
    local item = inv[sourceSlot]
    if not item or not item.id then return end

    local itemClass = item.class or item.id
    local def = (Monarch.Inventory.Items and Monarch.Inventory.Items[itemClass]) or nil
    if (not def) and Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[itemClass] then
        local key = Monarch.Inventory.ItemsRef[itemClass]
        def = Monarch.Inventory.Items and Monarch.Inventory.Items[key]
    end

    if isStorage then
        local isRestricted = item.restricted or (def and (def.Restricted or def.restricted))
        local isConstrained = item.constrained or false
        if isRestricted or isConstrained then
            net.Start("Monarch_Loot_PutResult")
                net.WriteBool(false)
                net.WriteString("You cannot store this item.")
            net.Send(ply)
            return
        end
    end

    if item.equipped then
        if def and def.WeaponClass then
            local wep = ply:GetWeapon(def.WeaponClass)
            if IsValid(wep) then
                if wep.Clip1 then
                    local clip1 = wep:Clip1()
                    if isnumber(clip1) then
                        item.clip = clip1
                    end
                end
                ply:StripWeapon(def.WeaponClass)
            end
        end

        Monarch_CallItemHook(def, "OnRemove", ply, sourceSlot, item)
        item.equipped = false
    end

    if isStorage then
        if ent.GetContents and ent:GetClass() == "monarch_storage" then
            local crateContents = Monarch_GetCrateContentsFor(ent, ply)
            local capX = tonumber(Config and Config.StorageGridCols) or (ent.GetCapacityX and ent:GetCapacityX()) or 5
            local capY = tonumber(Config and Config.StorageGridRows) or (ent.GetCapacityY and ent:GetCapacityY()) or 6
            local capacity = math.max(1, math.floor((tonumber(capX) or 5) * (tonumber(capY) or 6)))
            if Monarch_CountLootItems(crateContents) >= capacity then
                ply:ChatPrint("That storage is full.")
                return
            end

            inv[sourceSlot] = nil
            item.storagetype = 2
            item.equipped = false
            item.class = item.class or item.id

            local putData = {
                id = item.id or item.class,
                class = item.class or item.id,
                amount = math.max(1, math.floor(tonumber(item.amount or 1) or 1)),
                restricted = item.restricted == true,
                constrained = item.constrained == true,
                clip = math.floor(tonumber(item.clip or 0) or 0),
            }

            local usedTarget = false
            if targetLootSlot > 0 and targetLootSlot <= capacity then
                if crateContents[targetLootSlot] == nil or crateContents[targetLootSlot] == false then
                    for idx = 1, targetLootSlot - 1 do
                        if crateContents[idx] == nil then
                            crateContents[idx] = false
                        end
                    end
                    crateContents[targetLootSlot] = putData
                    usedTarget = true
                else
                    net.Start("Monarch_Loot_PutResult")
                        net.WriteBool(false)
                        net.WriteString("That loot slot is occupied.")
                    net.Send(ply)
                    return
                end
            end

            if not usedTarget then
                table.insert(crateContents, putData)
            end

            if ent.SetContents then
                ent:SetContents(crateContents, ply)
            end
            if ent.SaveContents then
                ent:SaveContents(ply)
            end

            Monarch.SaveInventory(ply, inv)

            net.Start("Monarch_Inventory_Update")
                net.WriteTable(inv)
            net.Send(ply)

            net.Start("Monarch_Loot_Update")
                net.WriteEntity(ent)
                net.WriteTable(Monarch_GetCrateContentsFor(ent, ply))
            net.Send(ply)

            net.Start("Monarch_Loot_PutResult")
                net.WriteBool(true)
            net.Send(ply)
            return
        end

        local storageSlot = Monarch_FindNextStorageSlot(inv)
        if not storageSlot then
            ply:ChatPrint("That storage is full.")
            return
        end

        inv[sourceSlot] = nil
        item.storagetype = 2
        item.equipped = false
        inv[storageSlot] = item

        Monarch.SaveInventory(ply, inv)

        net.Start("Monarch_Inventory_Update")
            net.WriteTable(inv)
        net.Send(ply)

        net.Start("Monarch_Loot_Update")
            net.WriteEntity(ent)
            net.WriteTable(Monarch_BuildStorageContents(ply))
        net.Send(ply)

        net.Start("Monarch_Loot_PutResult")
            net.WriteBool(true)
        net.Send(ply)
        return
    end

    local contents = ent:GetContents() or {}
    local capacity = Monarch_GetLootCapacity(ent)
    if capacity <= 0 then capacity = 0 end
    if Monarch_CountLootItems(contents) >= capacity then
        ply:ChatPrint("That container is full.")
        return
    end

    inv[sourceSlot] = nil

    local putData = { id = item.id, amount = item.amount or 1 }
    local usedTarget = false
    if targetLootSlot > 0 and targetLootSlot <= capacity then
        if contents[targetLootSlot] == nil or contents[targetLootSlot] == false then
            for idx = 1, targetLootSlot - 1 do
                if contents[idx] == nil then
                    contents[idx] = false
                end
            end
            contents[targetLootSlot] = putData
            usedTarget = true
        else
            net.Start("Monarch_Loot_PutResult")
                net.WriteBool(false)
                net.WriteString("That loot slot is occupied.")
            net.Send(ply)
            return
        end
    end

    if not usedTarget then
        table.insert(contents, putData)
    end

    ent:SetContents(contents)
    Monarch_UpdateLoot(ent)
    Monarch.SaveInventory(ply, inv)

    net.Start("Monarch_Inventory_Update")
        net.WriteTable(inv)
    net.Send(ply)

    net.Start("Monarch_Loot_Update")
        net.WriteEntity(ent)
        net.WriteTable(contents)
    net.Send(ply)

    net.Start("Monarch_Loot_PutResult")
        net.WriteBool(true)
    net.Send(ply)
end)

net.Receive("Monarch_Loot_TakeToSlot", function(_, ply)
    local ent = net.ReadEntity()
    local idx = net.ReadUInt(8)
    local targetSlot = net.ReadUInt(8)
    if not IsValid(ply) or not Monarch_IsLootEntity(ent) then return end
    if ent:GetPos():DistToSqr(ply:GetPos()) > (130*130) then return end
    local defID = ent.GetLootDefID and ent:GetLootDefID()
    local isStorage = Monarch_IsStorageEntity(ent)
    local steamid = ply:SteamID64()
    if not steamid then return end

    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}
    local inv = Monarch.Inventory.Data[steamid] or {}
    inv[targetSlot] = inv[targetSlot] 
    if inv[targetSlot] ~= nil then
        ply:ChatPrint("That slot is occupied.")
        return
    end

    if isStorage then
        if ent.GetContents and ent:GetClass() == "monarch_storage" then
            local crateContents = Monarch_GetCrateContentsFor(ent, ply)
            local crateItem = crateContents[idx]
            if not crateItem then return end

            inv[targetSlot] = {
                id = crateItem.id or crateItem.class,
                class = crateItem.id or crateItem.class,
                amount = math.max(1, math.floor(tonumber(crateItem.amount or 1) or 1)),
                equipped = false,
                restricted = crateItem.restricted or false,
                constrained = crateItem.constrained or false,
                clip = math.floor(tonumber(crateItem.clip or 0) or 0)
            }
            table.remove(crateContents, idx)

            if ent.SetContents then
                ent:SetContents(crateContents, ply)
            end
            if ent.SaveContents then
                ent:SaveContents(ply)
            end

            Monarch.SaveInventory(ply, inv)

            net.Start("Monarch_Inventory_Update")
                net.WriteTable(inv)
            net.Send(ply)

            net.Start("Monarch_Loot_Update")
                net.WriteEntity(ent)
                net.WriteTable(Monarch_GetCrateContentsFor(ent, ply))
            net.Send(ply)
            return
        end

        local list = Monarch_GetStorageList(ply)
        local entry = list[idx]
        if not entry or not entry.item then return end
        local stored = entry.item
        inv[targetSlot] = {
            id = stored.id or stored.class,
            class = stored.id or stored.class,
            amount = stored.amount or 1,
            equipped = false,
            restricted = stored.restricted or false,
            constrained = stored.constrained or false
        }
        inv[entry.slot] = nil
        Monarch.SaveInventory(ply, inv)

        net.Start("Monarch_Inventory_Update")
            net.WriteTable(inv)
        net.Send(ply)

        net.Start("Monarch_Loot_Update")
            net.WriteEntity(ent)
            net.WriteTable(Monarch_BuildStorageContents(ply))
        net.Send(ply)
        return
    end

    local contents = ent:GetContents() or {}
    local item = contents[idx]
    if not item then return end

    inv[targetSlot] = { id = item.id, class = item.id, amount = item.amount or 1, equipped = false, restricted = item.restricted or false, constrained = item.constrained or false }
    table.remove(contents, idx)
    ent:SetContents(contents)

    Monarch_UpdateLoot(ent)
    hook.Run("Monarch_LootItemTaken", ply, ent, item.id, item.amount or 1, false)
    Monarch.SaveInventory(ply, inv)

    net.Start("Monarch_Inventory_Update")
        net.WriteTable(inv)
    net.Send(ply)

    net.Start("Monarch_Loot_Update")
        net.WriteEntity(ent)
        net.WriteTable(contents)
    net.Send(ply)
end)

net.Receive("Monarch_Inventory_Dismantle", function(_, ply)
    if not IsValid(ply) then return end
    local slot = net.ReadUInt(8)
    if not slot or slot < 1 or slot > 100 then return end

    local steamid64 = ply:SteamID64()
    if not steamid64 then return end
    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}
    local inv = Monarch.Inventory.Data[steamid64]
    if not inv then return end

    local item = inv[slot]
    if not item then return end
    local itemClass = item.class or item.id
    if not itemClass then return end

    local def = Monarch.Inventory.Items and Monarch.Inventory.Items[itemClass]
    if (not def) and Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[itemClass] then
        def = Monarch.Inventory.Items and Monarch.Inventory.Items[Monarch.Inventory.ItemsRef[itemClass]]
    end
    if not def then return end

    local yields = def.Dismantle or def.dismantle
    if not yields then return end

    print("[Monarch] Dismantling item: " .. itemClass .. " from slot " .. slot)

    local currentAmount = tonumber(item.amount or 1) or 1
    local removingAll = (currentAmount <= 1)

    if removingAll then

        if item.equipped then
            if def.WeaponClass then
                local wep = ply:GetWeapon(def.WeaponClass)
                if IsValid(wep) then
                    if wep.Clip1 then
                        local clip1 = wep:Clip1()
                        if isnumber(clip1) then item.clip = clip1 end
                    end
                    ply:StripWeapon(def.WeaponClass)
                end
            end
            Monarch_CallItemHook(def, "OnRemove", ply, slot, item)
            item.equipped = false
        end

        inv[slot] = nil
    else

        item.amount = currentAmount - 1
        inv[slot] = item
    end

    local grants = {}
    if istable(yields) then
        local isArray = (#yields > 0)
        if isArray then
            for _, v in ipairs(yields) do
                if isstring(v) then
                    table.insert(grants, { id = v, amount = 1 })
                elseif istable(v) then
                    local id = v.id or v.class
                    local amt = tonumber(v.amount or 1) or 1
                    if id then table.insert(grants, { id = id, amount = math.max(1, math.floor(amt)) }) end
                end
            end
        else
            for k, v in pairs(yields) do
                if isstring(k) and isnumber(v) then
                    table.insert(grants, { id = k, amount = math.max(1, math.floor(v)) })
                end
            end
        end
    end

    if ply.GiveInventoryItem then
        for _, g in ipairs(grants) do
            print("[Monarch] Granting: " .. g.id .. " x" .. g.amount)
            ply:GiveInventoryItem(g.id, g.amount or 1)
        end
    end

    inv = Monarch_GetInventory(ply)

    Monarch.SaveInventory(ply, inv)

    net.Start("Monarch_Inventory_Update")
        net.WriteTable(inv)
    net.Send(ply)
end)

concommand.Add("monarch_itemcreator", function(ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    net.Start("Monarch_Admin_ShowItemCreator")
    net.Send(ply)
end, nil, "Open the Monarch Item Creator (admins only)")

net.Receive("Monarch_Admin_GiveItem", function(_, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local targetSID64 = net.ReadString() or ""
    local itemClass = net.ReadString() or ""
    local amount = tonumber(net.ReadUInt(8) or 1) or 1
    amount = math.max(1, math.min(100, amount))

    if targetSID64 == "" or itemClass == "" then return end

    local target
    for _, p in player.Iterator() do
        if p:SteamID64() == targetSID64 then target = p break end
    end
    if not IsValid(target) then return end

    local ok = false
    if Monarch.Inventory and Monarch.Inventory.Items then
        if Monarch.Inventory.Items[itemClass] then ok = true end
    end
    if not ok and Monarch.Inventory and Monarch.Inventory.ItemsRef then
        if Monarch.Inventory.ItemsRef[itemClass] then ok = true end
    end
    if not ok then return end

    local itemName = Monarch.Inventory.Items[itemClass].Name or itemClass

    for i=1, amount do
        if target.GiveInventoryItem then target:GiveInventoryItem(itemClass, 1) end
        target:Notify("You received 1x " .. itemName .. " from an admin.")
        ply:Notify("Gave 1x " .. itemName .. " to " .. target:Nick() .. ".")
    end
end)

local function Monarch_ResolveItemDef(class)
    if not class then return nil end
    local defs = Monarch.Inventory and Monarch.Inventory.Items or nil
    local ref = Monarch.Inventory and Monarch.Inventory.ItemsRef or nil
    if not defs then return nil end
    if ref and ref[class] then
        return defs[ref[class]]
    end
    return defs[class]
end

function Monarch_CallItemHook(def, hookName, ply, slot, item)
    if not def or type(def[hookName]) ~= "function" then return end
    local fn = def[hookName]

    local ok = pcall(fn, ply, slot, item, def)
    if not ok then

        pcall(fn, def, ply, item, slot)
    end
end

local function Monarch_EmitWeaponUsed(ply, wep, context)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(wep) then return end

    local wepClass = wep:GetClass()
    if not wepClass or wepClass == "" then return end

    local now = CurTime()
    ply.MonarchWeaponUsedCooldown = ply.MonarchWeaponUsedCooldown or {}
    local last = tonumber(ply.MonarchWeaponUsedCooldown[wepClass] or 0) or 0
    if (now - last) < 0.06 then return end
    ply.MonarchWeaponUsedCooldown[wepClass] = now

    local inv = Monarch_GetInventory(ply)
    if not istable(inv) then return end

    for slot = 1, (MONARCH_INV_MAX_SLOTS or 30) do
        local item = inv[slot]
        if istable(item) and item.equipped then
            local class = item.class or item.id
            local def = Monarch_ResolveItemDef(class)
            if def and def.WeaponClass == wepClass and type(def.WeaponUsed) == "function" then
                local ok = pcall(def.WeaponUsed, def, ply, slot, item, wep, context or {})
                if not ok then
                    pcall(def.WeaponUsed, ply, slot, item, def, wep, context or {})
                end
                return
            end
        end
    end
end

hook.Add("EntityFireBullets", "Monarch.Inventory.WeaponUsed", function(entity, data)
    local ply, wep
    if IsValid(entity) and entity:IsPlayer() then
        ply = entity
        wep = ply:GetActiveWeapon()
    elseif IsValid(entity) and entity:IsWeapon() then
        local owner = entity:GetOwner()
        if IsValid(owner) and owner:IsPlayer() then
            ply = owner
            wep = entity
        end
    end

    if not IsValid(ply) or not IsValid(wep) then return end
    Monarch_EmitWeaponUsed(ply, wep, {
        source = "entity_fire_bullets",
        bulletData = data,
    })
end)

hook.Add("StartCommand", "Monarch.Inventory.WeaponUsedPrimary", function(ply, cmd)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not cmd:KeyDown(IN_ATTACK) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    if not wep:IsWeapon() then return end

    if wep.GetNextPrimaryFire and wep:GetNextPrimaryFire() > CurTime() then
        return
    end

    Monarch_EmitWeaponUsed(ply, wep, {
        source = "start_command_primary",
    })
end)

net.Receive("Monarch_Inventory_MoveItem", function(_, ply)
    if not IsValid(ply) then return end
    local src = net.ReadUInt(8)
    local dst = net.ReadUInt(8)
    if not src or not dst then return end

    local maxSlots = MONARCH_INV_MAX_SLOTS or 30
    if src < 1 or src > maxSlots or dst < 1 or dst > maxSlots then return end

    local inv = Monarch_GetInventory(ply)
    local a, b = inv[src], inv[dst]

    if istable(a) then
        local aClass = a.class or a.id
        if not Monarch_IsValidItemClass(aClass) then return end
    end

    if istable(b) then
        local bClass = b.class or b.id
        if not Monarch_IsValidItemClass(bClass) then return end
    end

    local function unequipIfNeeded(slotId, itemData)
        if not istable(itemData) or itemData.equipped ~= true then return end
        local class = itemData.class or itemData.id
        local def = Monarch_ResolveItemDef(class)
        if def and def.WeaponClass then
            local wep = ply:GetWeapon(def.WeaponClass)
            if IsValid(wep) and wep.Clip1 then
                local c = wep:Clip1()
                if isnumber(c) then itemData.clip = c end
            end
            if IsValid(wep) then
                ply:StripWeapon(def.WeaponClass)
            end
        end
        Monarch_CallItemHook(def, "OnRemove", ply, slotId, itemData)
        itemData.equipped = false
    end

    unequipIfNeeded(src, a)
    unequipIfNeeded(dst, b)

    inv[src], inv[dst] = b, a
    Monarch_SaveAndSyncInventory(ply, inv)
end)

net.Receive("Monarch_Inventory_UseItem", function(_, ply)
    if not IsValid(ply) then return end
    local slot = net.ReadUInt(8)
    if not slot or slot < 1 or slot > MONARCH_INV_MAX_SLOTS then return end

    local inv = Monarch_GetInventory(ply)
    local item = inv[slot]
    if not istable(item) then return end

    local class = item.class or item.id
    local def = Monarch_ResolveItemDef(class)

    local equipGroup = def and Monarch.NormalizeEquipGroup(def.EquipGroup)
    if equipGroup then

        if item.equipped or slot >= 21 then

            if def.WeaponClass then
                local wep = ply:GetWeapon(def.WeaponClass)
                if IsValid(wep) and wep.Clip1 then
                    local c = wep:Clip1()
                    if isnumber(c) then item.clip = c end
                end
                if IsValid(wep) then ply:StripWeapon(def.WeaponClass) end
            end

            Monarch_CallItemHook(def, "OnRemove", ply, slot, item)
            ply:SetInventoryItemEquipped(slot, false)
            return
        end

        ply:SetInventoryItemEquipped(slot, true)

        inv = Monarch_GetInventory(ply)
        local equipSlot
        for i = 21, MONARCH_INV_MAX_SLOTS do
            local it = inv[i]
            if istable(it) and it.equipped and (it.class or it.id) == class then
                equipSlot = i
                break
            end
        end

        if def.WeaponClass then
            local newWep = ply:Give(def.WeaponClass)
            if IsValid(newWep) and equipSlot then
                local equippedItem = inv[equipSlot]
                if equippedItem and equippedItem.clip and newWep.SetClip1 then
                    newWep:SetClip1(tonumber(equippedItem.clip) or 0)
                end
            end
            timer.Simple(0, function()
                if IsValid(ply) and def.WeaponClass and ply:HasWeapon(def.WeaponClass) then
                    ply:SelectWeapon(def.WeaponClass)
                end
            end)
        else

            local equippedItem = equipSlot and inv[equipSlot] or item
            Monarch_CallItemHook(def, "OnUse", ply, equipSlot or slot, equippedItem)
        end

        local equippedItem = equipSlot and inv[equipSlot] or item
        Monarch_ApplyDurabilityLoss(ply, inv, equipSlot or slot, equippedItem, def, {
            action = "equip_use",
            equipGroup = equipGroup,
        })

        Monarch_SaveAndSyncInventory(ply, inv, false)
		print(string.format("[MONARCH EQUIP] equipped class=%s into slot=%s", tostring(class), tostring(equipSlot)))
        return
    end

    local isWeapon = def.WeaponClass ~= nil
    local egCur = Monarch.NormalizeEquipGroup(def.EquipGroup)
    local needsSave = false

    if isWeapon then

        if item.equipped then
            local wep = ply:GetWeapon(def.WeaponClass)
            if IsValid(wep) and wep.Clip1 then
                local c = wep:Clip1()
                if isnumber(c) then item.clip = c end
            end
            if IsValid(wep) then ply:StripWeapon(def.WeaponClass) end

            Monarch_CallItemHook(def, "OnRemove", ply, slot, item)
            item.equipped = false
            Monarch_SaveAndSyncInventory(ply, inv, false)
            return
        end

        local otherIndex, otherItem, otherDef
        if egCur then
            for i = 1, MONARCH_INV_MAX_SLOTS do
                if i ~= slot then
                    local o = inv[i]
                    if istable(o) and o.equipped then
                        local od = Monarch_ResolveItemDef(o.class or o.id)
                        local egO = od and Monarch.NormalizeEquipGroup(od.EquipGroup)
                        if egO and egO == egCur then
                            otherIndex, otherItem, otherDef = i, o, od
                            break
                        end
                    end
                end
            end
        end

        if otherItem and otherDef and otherDef.WeaponClass then
            local oldWep = ply:GetWeapon(otherDef.WeaponClass)
            if IsValid(oldWep) and oldWep.Clip1 then
                local c = oldWep:Clip1()
                if isnumber(c) then otherItem.clip = c end
            end
            if IsValid(oldWep) then ply:StripWeapon(otherDef.WeaponClass) end

            Monarch_CallItemHook(otherDef, "OnRemove", ply, otherIndex, otherItem)
        end

        local newWep = ply:Give(def.WeaponClass)
        if IsValid(newWep) and item.clip and newWep.SetClip1 then
            newWep:SetClip1(tonumber(item.clip) or 0)
        end

        timer.Simple(0, function()
            if IsValid(ply) and def.WeaponClass and ply:HasWeapon(def.WeaponClass) then
                ply:SelectWeapon(def.WeaponClass)
            end
        end)

        if otherIndex then

            inv[slot], inv[otherIndex] = inv[otherIndex], inv[slot]

            if inv[otherIndex] then inv[otherIndex].equipped = true end
            if inv[slot] then

                local old = inv[slot]
                local oldDef = Monarch_ResolveItemDef(old.class or old.id)
                Monarch_CallItemHook(oldDef, "OnRemove", ply, slot, old)
                inv[slot].equipped = false
            end
        else

            item.equipped = true
        end

        if def.ShouldRemoveOnEquip then
            local idx = otherIndex or slot

            if otherIndex then

                inv[slot], inv[otherIndex] = inv[otherIndex], inv[slot]
                if inv[slot] then inv[slot].equipped = false end
            end
            inv[slot] = nil
            needsSave = true
        end

        local postWeaponItem = otherIndex and inv[otherIndex] or inv[slot]
        Monarch_ApplyDurabilityLoss(ply, inv, (otherIndex or slot), postWeaponItem, def, {
            action = "weapon_use",
            swapped = otherIndex ~= nil,
        })

        Monarch_SaveAndSyncInventory(ply, inv, needsSave)
        return
    end

    local egCur = Monarch.NormalizeEquipGroup(def.EquipGroup)
    if egCur and item.equipped then
        Monarch_CallItemHook(def, "OnRemove", ply, slot, item)
        item.equipped = false
        Monarch_SaveAndSyncInventory(ply, inv, false)
        return
    end

    local removeAll, removeCount = false, 0
    local equipSet, equipChanged = nil, false

    if type(def.CanUse) == "function" then

        local okGate1, allowed1 = pcall(def.CanUse, ply, slot, item, def)
        local finalAllowed, haveFinal = nil, false
        if okGate1 and (allowed1 ~= nil and allowed1 ~= false) then
            finalAllowed, haveFinal = allowed1, true
        else

            local okGate2, allowed2 = pcall(def.CanUse, def, ply, item, slot)
            if okGate2 then
                finalAllowed, haveFinal = allowed2, true
            end
        end
        if haveFinal and finalAllowed == false then
            return
        end
    end
    if type(def.OnUse) == "function" then

        local ok1, res1 = pcall(def.OnUse, ply, slot, item, def)
        local ok, res = ok1, res1
        if (not ok1) or (res1 == nil or res1 == false) then
            ok, res = pcall(def.OnUse, def, ply, item, slot)
        end
        if not ok then
        else
            if res == true then
                removeCount = math.max(removeCount, 1)
            elseif istable(res) then
                if res.removeAll == true then
                    removeAll = true
                elseif res.remove == true then
                    removeCount = math.max(removeCount, 1)
                elseif type(res.remove) == "number" then
                    removeCount = math.max(removeCount, math.floor(res.remove))
                end
                if res.equipped == true then item.equipped = true equipSet = true equipChanged = true end
                if res.unequipped == true then

                    Monarch_CallItemHook(def, "OnRemove", ply, slot, item)
                    item.equipped = false
                    equipSet = false
                    equipChanged = true
                end
            end
        end
    end

    inv = Monarch_GetInventory(ply)
    item = inv[slot]

    if istable(item) and egCur and not equipChanged then
        if item.equipped then

            Monarch_CallItemHook(def, "OnRemove", ply, slot, item)
            item.equipped = false
        else

            local otherIndex
            for i = 1, MONARCH_INV_MAX_SLOTS do
                if i ~= slot then
                    local o = inv[i]
                    if istable(o) and o.equipped then
                        local od = Monarch_ResolveItemDef(o.class or o.id)
                        local egO = od and Monarch.NormalizeEquipGroup(od.EquipGroup)
                        if egO and egO == egCur then
                            otherIndex = i
                            break
                        end
                    end
                end
            end
            if otherIndex then
                inv[slot], inv[otherIndex] = inv[otherIndex], inv[slot]
                if inv[otherIndex] then inv[otherIndex].equipped = true end
                if inv[slot] then

                    local old = inv[slot]
                    local oldDef = Monarch_ResolveItemDef(old.class or old.id)
                    Monarch_CallItemHook(oldDef, "OnRemove", ply, slot, old)
                    inv[slot].equipped = false
                end
            else
                item.equipped = true
            end
        end
    end

    if removeAll then
        inv[slot] = nil
    elseif removeCount > 0 then
        local amt = tonumber(item and item.amount or 1) or 1
        local newAmt = amt - removeCount
        if newAmt > 0 and item then
            item.amount = newAmt
        else

            if item and item.equipped then
                Monarch_CallItemHook(def, "OnRemove", ply, slot, item)
            end
            inv[slot] = nil
        end
    end

    local postItem = inv[slot]
    if istable(postItem) then
        local postClass = postItem.class or postItem.id
        local postDef = Monarch_ResolveItemDef(postClass)
        local durabilityChanged = Monarch_ApplyDurabilityLoss(ply, inv, slot, postItem, postDef, {
            action = "use",
            removeAll = removeAll,
            removeCount = removeCount,
        })
        if durabilityChanged then
            removeAll = true
        end
    end

    Monarch_SaveAndSyncInventory(ply, inv, removeAll or removeCount > 0)
end)

net.Receive("Monarch_Inventory_SplitStack", function(_, ply)
    if not IsValid(ply) then return end
    local src = net.ReadUInt(8)
    local amt = net.ReadUInt(16)
    local hasTarget = net.ReadBool()
    local dst = hasTarget and net.ReadUInt(8) or nil

    if not src or src < 1 or src > (MONARCH_INV_MAX_SLOTS or 20) then return end
    if hasTarget then
        if not dst or dst < 1 or dst > (MONARCH_INV_MAX_SLOTS or 20) then return end
    end

    local inv = Monarch_GetInventory(ply)
    local item = inv[src]
    if not istable(item) then return end
    local total = tonumber(item.amount or 1) or 1
    amt = math.floor(tonumber(amt) or 0)
    if amt < 1 or amt >= total then return end 

    if not hasTarget then
        for i = 1, (MONARCH_INV_MAX_SLOTS or 20) do
            if inv[i] == nil then
                dst = i
                break
            end
        end
        if not dst then
            ply:Notify("Your inventory is full, so you can't split the stack.")
            Monarch_SyncInventoryOnly(ply, inv)
            return
        end
    else

        if inv[dst] ~= nil then
            ply:ChatPrint("Target slot is occupied.")
            Monarch_SyncInventoryOnly(ply, inv)
            return
        end
    end

    local cls = item.class or item.id
    inv[dst] = {
        id = cls,
        class = cls,
        amount = amt,
        equipped = false,
        restricted = item.restricted == true,
        constrained = item.constrained == true,
        durability = item.durability ~= nil and math.Clamp(math.floor(tonumber(item.durability or 100) or 100), 0, 100) or nil
    }

    item.amount = total - amt

    Monarch_SaveAndSyncInventory(ply, inv, true)
end)

net.Receive("Monarch_Inventory_UnequipToSlot", function(_, ply)
    if not IsValid(ply) then return end
    local srcSlot = net.ReadUInt(8)  
    local dstSlot = net.ReadUInt(8)  

    if not srcSlot or srcSlot < 1 or srcSlot > MONARCH_INV_MAX_SLOTS then return end
    if not dstSlot or dstSlot < 1 or dstSlot > MONARCH_INV_MAX_SLOTS then return end
    if srcSlot == dstSlot then return end

    local inv = Monarch_GetInventory(ply)
    local item = inv[srcSlot]
    if not istable(item) or not item.equipped then return end

    local class = item.class or item.id
    local def = Monarch_ResolveItemDef(class)

    if def and def.WeaponClass then
        local wep = ply:GetWeapon(def.WeaponClass)
        if IsValid(wep) then

            if wep.Clip1 then
                local clip = wep:Clip1()
                if isnumber(clip) then item.clip = clip end
            end
            ply:StripWeapon(def.WeaponClass)
        end
    end

    Monarch_CallItemHook(def, "OnRemove", ply, srcSlot, item)

    item.equipped = false

    inv[srcSlot], inv[dstSlot] = inv[dstSlot], inv[srcSlot]

    Monarch_SaveAndSyncInventory(ply, inv, true)
end)

net.Receive("Monarch_Tools_GiveTools", function(_, ply)
    if not Monarch_IsStaff(ply) then return end
    if not IsValid(ply) then return end
    ply:Give("weapon_physgun")
    ply:Give("gmod_tool")
    timer.Simple(0, function()
        if IsValid(ply) then
            local wep = ply:GetWeapon("weapon_physgun") or ply:GetWeapon("gmod_tool")
            if IsValid(wep) then ply:SelectWeapon(wep:GetClass()) end
        end
    end)
    if Monarch_Log then Monarch_Log("give_tools", { admin = ply, reason = "physgun, toolgun" }) end
end)

net.Receive("Monarch_Admin_GetAllChars", function(_, ply)
    if not Monarch_IsStaff(ply) then return end
    local q = mysql:Select("monarch_players")
    q:OrderByAsc("id")
    q:Callback(function(rows)
        rows = rows or {}

        local out = {}
        for _, r in ipairs(rows) do
            table.insert(out, {
                id = r.id,
                steamid = r.steamid,
                name = r.rpname or r.name or "",
                model = r.model or "",
                skin = tonumber(r.skin) or 0,
                team = tonumber(r.team) or 1,
                xp = tonumber(r.xp) or 0,
                money = tonumber(r.money) or 0,
                bankmoney = tonumber(r.bankmoney) or 0,
            })
        end
        net.Start("Monarch_Admin_AllChars")
            net.WriteTable(out)
        net.Send(ply)
    end)
    q:Execute()
end)

net.Receive("Monarch_Admin_UpdateChar", function(_, ply)
    if not Monarch_IsStaff(ply) then return end
    local id = net.ReadUInt(32)
    local newName = string.sub(net.ReadString() or "", 1, 64)
    local newModel = string.sub(net.ReadString() or "", 1, 128)
    local newTeam = tonumber(net.ReadUInt(8)) or 1
    local newSkin = tonumber(net.ReadUInt(8)) or 0
    local newXP = tonumber(net.ReadInt(32)) or nil
    local newMoney = tonumber(net.ReadInt(32)) or nil

    if id == 0 then return end

    local u = mysql:Update("monarch_players")
    u:Where("id", id)
    if newName ~= "" then u:Update("rpname", newName) end
    if newModel ~= "" then u:Update("model", newModel) end
    u:Update("team", newTeam)
    u:Update("skin", newSkin)
    if newXP then u:Update("xp", newXP) end
    if newMoney then u:Update("money", newMoney) end
    u:Callback(function(res, status)
        local ok = status ~= false
        if ok and Monarch_Log then Monarch_Log("char_update", { admin = ply, reason = string.format("id=%d", id) }) end
        net.Start("Monarch_Admin_UpdateCharResult")
            net.WriteBool(ok)
            net.WriteUInt(id, 32)
        net.Send(ply)
    end)
    u:Execute()
end)

local function MSM_BuildMetrics()
    local metrics = {}
    for _, t in pairs(Monarch.Tickets.list or {}) do
        if IsValid(t.claimedBy) and t.claimedAt and t.createdAt then
            local adminSID = t.claimedBy:SteamID64()
            local m = metrics[adminSID] or { claimed = 0, totalClaimSec = 0, closed = 0 }
            m.claimed = m.claimed + 1
            m.totalClaimSec = m.totalClaimSec + math.max(0, (t.claimedAt - t.createdAt))
            if t.closedAt then m.closed = m.closed + 1 end
            metrics[adminSID] = m
        end
    end
    for sid, m in pairs(metrics) do
        if (m.claimed or 0) > 0 then m.avgClaimSec = math.floor((m.totalClaimSec or 0) / m.claimed) else m.avgClaimSec = 0 end

        m.score = (m.closed or 0) * 10 + math.max(0, 300 - (m.avgClaimSec or 0))
    end
    return metrics
end

do
    local pulseCooldowns = {}

    local function Monarch_CurrentMoney(p)
        if not IsValid(p) then return 0 end
        if p.GetMoney then
            local ok, res = pcall(p.GetMoney, p)
            if ok and res ~= nil then return tonumber(res) or 0 end
        end
        return tonumber(p:GetNWInt("Money") or 0) or 0
    end

    local function Monarch_UpdateMoney(p, newAmount)
        if not IsValid(p) then return 0 end
        newAmount = math.max(0, math.floor(tonumber(newAmount) or 0))
        local u = mysql:Update("monarch_players")
        u:Update("money", newAmount)
        u:Where("steamid", p:SteamID())
        u:Execute()
        if p.SetLocalSyncVar then p:SetLocalSyncVar(SYNC_MONEY, newAmount) end
        p:SetNWInt("Money", newAmount)
        p:SetPData("Money", newAmount)
        return newAmount
    end

    net.Receive("Monarch_Interact_Pulse", function(_, ply)
        if not IsValid(ply) then return end
        local target = net.ReadEntity()
        if not IsValid(target) or not target:IsPlayer() then return end

        local sid = ply:SteamID64() or ply:SteamID() or tostring(ply)
        local now = CurTime()
        if (pulseCooldowns[sid] or 0) > now then return end
        pulseCooldowns[sid] = now + 1.5

        if ply:GetPos():DistToSqr(target:GetPos()) > (100 * 100) then
            ply:Notify("You need to be closer to take their pulse.")
            return
        end

        local hp = target:Health() or 0
        local dead = (not target:Alive()) or hp <= 0
        local pulse
        if dead then
            pulse = math.random(0, 40)
        else
            local baseline = 80 + (hp * 0.75)
            pulse = math.floor(baseline + math.Rand(-5, 5))
        end

        net.Start("Monarch_Interact_PulseResult")
            net.WriteEntity(target)
            net.WriteUInt(pulse, 12)
            net.WriteBool(dead or pulse < 50)
        net.Send(ply)
    end)

    net.Receive("Monarch_GiveMoney_Request", function(_, ply)
        if not IsValid(ply) then return end
        local target = net.ReadEntity()
        local amount = tonumber(net.ReadInt(32)) or 0
        amount = math.floor(math.abs(amount))

        if not IsValid(target) or not target:IsPlayer() or target == ply then
            net.Start("Monarch_GiveMoney_Result")
                net.WriteBool(false)
                net.WriteString("Invalid target.")
            net.Send(ply)
            return
        end

        if amount <= 0 then
            net.Start("Monarch_GiveMoney_Result")
                net.WriteBool(false)
                net.WriteString("Enter a valid amount.")
            net.Send(ply)
            return
        end

        local MAX_TRANSFER = 1000000
        if amount > MAX_TRANSFER then
            net.Start("Monarch_GiveMoney_Result")
                net.WriteBool(false)
                net.WriteString("Amount too large.")
            net.Send(ply)
            return
        end

        if ply:GetPos():DistToSqr(target:GetPos()) > (150 * 150) then
            net.Start("Monarch_GiveMoney_Result")
                net.WriteBool(false)
                net.WriteString("You must be near them to give money.")
            net.Send(ply)
            return
        end
        if not ply:Alive() or not target:Alive() then
            net.Start("Monarch_GiveMoney_Result")
                net.WriteBool(false)
                net.WriteString("Both players must be alive.")
            net.Send(ply)
            return
        end

        local giverBal = Monarch_CurrentMoney(ply)
        if giverBal < amount then
            net.Start("Monarch_GiveMoney_Result")
                net.WriteBool(false)
                net.WriteString("You don't have enough money.")
            net.Send(ply)
            return
        end

        local receiverBal = Monarch_CurrentMoney(target)
        giverBal = giverBal - amount
        receiverBal = receiverBal + amount

        Monarch_UpdateMoney(ply, giverBal)
        Monarch_UpdateMoney(target, receiverBal)

        ply:Notify("You gave $"..string.Comma(amount).." to "..(target.GetRPName and target:GetRPName() or target:Nick())..".")
        target:Notify("You received $"..string.Comma(amount).." from "..(ply.GetRPName and ply:GetRPName() or ply:Nick())..".")

        net.Start("Monarch_GiveMoney_Result")
            net.WriteBool(true)
            net.WriteString("Transferred $"..string.Comma(amount).." to "..target:Nick()..".")
        net.Send(ply)
    end)
end

net.Receive("Monarch_MSM_GetData", function(_, ply)
    if not Monarch_IsStaff(ply) then return end
    local staffArr = {}

    local listed = {}
    if Monarch.Staff and Monarch.Staff.users then
        for sid, rec in pairs(Monarch.Staff.users) do
            listed[sid] = true
            local p = nil
            for _, pl in player.Iterator() do if pl:SteamID64() == sid then p = pl break end end
            table.insert(staffArr, {
                sid = sid,
                name = (IsValid(p) and p:Nick()) or rec.name or sid,
                usergroup = (IsValid(p) and p:GetUserGroup()) or rec.usergroup or "",
                rank = rec.rank or "",
            })
        end
    end

    for _, pl in player.Iterator() do
        local g = string.lower(pl:GetUserGroup() or "")
        if (g == "admin" or g == "superadmin") and not listed[pl:SteamID64()] then
            table.insert(staffArr, { sid = pl:SteamID64(), name = pl:Nick(), usergroup = g, rank = g })
        end
    end
    local online = {}
    for _, pl in player.Iterator() do
        table.insert(online, { sid = pl:SteamID64(), name = pl:Nick(), usergroup = pl:GetUserGroup() })
    end
    local payload = {
        staff = staffArr,
        ranks = (Monarch.Staff and Monarch.Staff.ranks) or {},
        online = online,
        metrics = MSM_BuildMetrics(),
    }
    net.Start("Monarch_MSM_Data")
        net.WriteTable(payload)
    net.Send(ply)
end)

net.Receive("Monarch_MSM_SetStaff", function(_, ply)
    if not Monarch_IsStaff(ply) then return end
    local sid = net.ReadString() or ""
    local rank = net.ReadString() or ""
    local setGroup = net.ReadString() or ""
    if sid == "" then return end
    Monarch.Staff = Monarch.Staff or { ranks = {}, users = {} }
    Monarch.Staff.users[sid] = Monarch.Staff.users[sid] or {}
    Monarch.Staff.users[sid].rank = rank
    if setGroup == "" and Monarch.Staff.ranks then
        for _, r in ipairs(Monarch.Staff.ranks) do if r.key == rank and r.usergroup then setGroup = r.usergroup break end end
    end
    if setGroup ~= "" then Monarch.Staff.users[sid].usergroup = setGroup end

    for _, pl in player.Iterator() do
        if pl:SteamID64() == sid then
            Monarch.Staff.users[sid].name = pl:Nick()
            if setGroup ~= "" and pl.SetUserGroup then pl:SetUserGroup(setGroup) end
            break
        end
    end

    file.CreateDir("monarch"); file.CreateDir("monarch/staff")
    file.Write("monarch/staff/config.json", util.TableToJSON(Monarch.Staff, false))
    net.Start("Monarch_MSM_Result") net.WriteBool(true) net.Send(ply)
end)

net.Receive("Monarch_MSM_RemoveStaff", function(_, ply)
    if not Monarch_IsStaff(ply) then return end
    local sid = net.ReadString() or ""
    if sid == "" then return end
    Monarch.Staff = Monarch.Staff or { ranks = {}, users = {} }
    Monarch.Staff.users[sid] = nil
    file.CreateDir("monarch"); file.CreateDir("monarch/staff")
    file.Write("monarch/staff/config.json", util.TableToJSON(Monarch.Staff, false))
    net.Start("Monarch_MSM_Result") net.WriteBool(true) net.Send(ply)
end)

net.Receive("Monarch_MSM_SaveRanks", function(_, ply)
    if not Monarch_IsStaff(ply) then return end
    local ranks = net.ReadTable() or {}
    Monarch.Staff = Monarch.Staff or { ranks = {}, users = {} }
    Monarch.Staff.ranks = ranks
    file.CreateDir("monarch"); file.CreateDir("monarch/staff")
    file.Write("monarch/staff/config.json", util.TableToJSON(Monarch.Staff, false))
    net.Start("Monarch_MSM_Result") net.WriteBool(true) net.Send(ply)
end)

net.Receive("Monarch_MSM_GetMetricsFor", function(_, ply)
    if not Monarch_IsStaff(ply) then return end
    local sid = net.ReadString() or ""
    if sid == "" then return end
    local entries = {}
    for _, t in pairs(Monarch.Tickets.list or {}) do
        if IsValid(t.claimedBy) and t.claimedBy:SteamID64() == sid then
            table.insert(entries, {
                id = t.id,
                createdAt = t.createdAt,
                claimedAt = t.claimedAt,
                closedAt = t.closedAt,
                reporter = t.reporterId or (IsValid(t.reporter) and t.reporter:SteamID64())
            })
        end
    end
    net.Start("Monarch_MSM_MetricsFor")
        net.WriteString(sid)
        net.WriteTable(entries)
    net.Send(ply)
end)

local function Monarch_IsAdmin(p)
    return IsValid(p) and (p:IsAdmin() or p:IsSuperAdmin())
end

net.Receive("MonarchSetHunger", function(_, ply)
    if not Monarch_IsAdmin(ply) then return end
    local amt = net.ReadUInt(16)
    local targ = net.ReadPlayer()
    if not IsValid(targ) then return end
    targ:SetHunger(math.Clamp(amt, 0, 100))
end)

net.Receive("MonarchSetHydration", function(_, ply)
    if not Monarch_IsAdmin(ply) then return end
    local amt = net.ReadUInt(16)
    local targ = net.ReadPlayer()
    if not IsValid(targ) then return end
    targ:SetHydration(math.Clamp(amt, 0, 100))
end)

net.Receive("MonarchSetExhaustion", function(_, ply)
    if not Monarch_IsAdmin(ply) then return end
    local amt = net.ReadUInt(16)
    local targ = net.ReadPlayer()
    if not IsValid(targ) then return end
    targ:SetExhaustion(math.Clamp(amt, 0, 100))
end)

net.Receive("MonarchSetStamina", function(_, ply)
    if not Monarch_IsAdmin(ply) then return end
    local amt = net.ReadUInt(16)
    local targ = net.ReadPlayer()
    if not IsValid(targ) then return end
    targ:SetNWFloat("Stamina", math.max(0, math.min(100, amt)))
end)

timer.Create("Monarch_Needs_NoClipFreeze", 1, 0, function()
    for _, p in player.Iterator() do
        if not IsValid(p) then goto cont end
        local inNoClip = (p:GetMoveType() == MOVETYPE_NOCLIP) or (p:GetObserverMode() ~= OBS_MODE_NONE)
        p._MonarchNeedsLast = p._MonarchNeedsLast or { hunger = p:GetNWInt("Hunger", 100), hydration = p:GetNWInt("Hydration", 100), exhaustion = p:GetNWInt("Exhaustion", 100), stamina = p:GetNWFloat("Stamina", 100) }
        if inNoClip then
            local hLast = p._MonarchNeedsLast.hunger or 100
            local hyLast = p._MonarchNeedsLast.hydration or 100
            local eLast = p._MonarchNeedsLast.exhaustion or 100
            local sLast = p._MonarchNeedsLast.stamina or 100
            local hNow = p:GetNWInt("Hunger", 100)
            local hyNow = p:GetNWInt("Hydration", 100)
            local eNow = p:GetNWInt("Exhaustion", 100)
            local sNow = p:GetNWFloat("Stamina", 100)
            p._MonarchNeedsLast.hunger = math.max(hLast, hNow)
            p._MonarchNeedsLast.hydration = math.max(hyLast, hyNow)
            p._MonarchNeedsLast.exhaustion = math.max(eLast, eNow)
            p._MonarchNeedsLast.stamina = math.max(sLast, sNow)

            if hNow < p._MonarchNeedsLast.hunger then p:SetNWInt("Hunger", p._MonarchNeedsLast.hunger) end
            if hyNow < p._MonarchNeedsLast.hydration then p:SetNWInt("Hydration", p._MonarchNeedsLast.hydration) end
            if eNow < p._MonarchNeedsLast.exhaustion then p:SetNWInt("Exhaustion", p._MonarchNeedsLast.exhaustion) end
            if sNow < p._MonarchNeedsLast.stamina then p:SetNWFloat("Stamina", p._MonarchNeedsLast.stamina) end
        else
            p._MonarchNeedsLast.hunger = p:GetNWInt("Hunger", 100)
            p._MonarchNeedsLast.hydration = p:GetNWInt("Hydration", 100)
            p._MonarchNeedsLast.exhaustion = p:GetNWInt("Exhaustion", 100)
            p._MonarchNeedsLast.stamina = p:GetNWFloat("Stamina", 100)
        end
        ::cont::
    end
end)

net.Receive("MonarchSelectTeam", function(_, admin)
    if not IsValid(admin) or not admin:IsAdmin() then return end
    local teamID = net.ReadUInt(8)
    local target = net.ReadEntity()
    if not IsValid(target) or not target:IsPlayer() then return end
    if not teamID or teamID < 1 or teamID > #Monarch.Team then return end

    if target.Monarch_SetTeam then
        target:Monarch_SetTeam(teamID)
    else
        target:SetTeam(teamID)

        local td = Monarch.Team[teamID]
        if td and td.Model then
            target:SetModel(td.Model)
        end
    end

    if target.MonarchActiveChar then
        target.MonarchActiveChar.team = teamID
        target.MonarchActiveChar.model = target:GetModel()
    end

    if mysql and mysql.Update and target.MonarchActiveChar and target.MonarchActiveChar.id then
        local query = mysql:Update("monarch_characters")
        query:Update("team", teamID)
        query:Update("model", target:GetModel())

        if target.GetBodygroupCount then
            local groups = {}
            for i = 0, target:GetNumBodyGroups() - 1 do
                groups[i] = target:GetBodygroup(i)
            end
            local bgStr = util.TableToJSON(groups)
            if bgStr then
                query:Update("bodygroups", bgStr)
                if target.MonarchActiveChar then
                    target.MonarchActiveChar.bodygroups = bgStr
                end
            end
        end
        query:Where("id", target.MonarchActiveChar.id)
        query:Callback(function()
            if IsValid(admin) and admin.Notify then
                admin:Notify("Persisted team/model for " .. target:Nick() .. ".")
            end
            if IsValid(target) and target.Notify then
                target:Notify("Your character's team has been changed and saved.")
            end
        end)
        query:Execute()
    else
        if IsValid(admin) and admin.Notify then
            admin:Notify("Set " .. target:Nick() .. "'s team to " .. (Monarch.Team[teamID] and Monarch.Team[teamID].name or teamID) .. " (no DB).")
        end
        if IsValid(target) and target.Notify then
            target:Notify("Your character's team has been changed (not persisted).")
        end
    end
end)

net.Receive("Monarch_Loot_SetRefillTime", function(_, ply)
    if not IsValid(ply) or (not (ply.IsAdmin and ply:IsAdmin()) and not (ply.IsSuperAdmin and ply:IsSuperAdmin())) then return end
    local ent = net.ReadEntity()
    local minutes = net.ReadUInt(6) or 5 
    if not IsValid(ent) or ent:GetClass() ~= "monarch_loot" then return end
    minutes = math.Clamp(minutes, 5, 30)
    local seconds = minutes * 60
    if ent.SetRefillTime then ent:SetRefillTime(seconds) end
    if ent.SetupRefill then ent:SetupRefill(ent:GetLootDef()) end
end)

-- Constrained Items: Remove items marked as constrained when player changes team or disconnects
function meta:RemoveConstrainedItems()
    local steamid = self:SteamID64()
    if not steamid then return end

    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}
    local inv = Monarch.Inventory.Data[steamid]
    if not inv then return end

    local removed = {}
    local maxSlots = MONARCH_INV_MAX_SLOTS or 20
    for i = 1, maxSlots do
        local item = inv[i]
        local isConstrained = item and ((item.constrained == true) or ((tonumber(item.constrained) or 0) ~= 0))
        if isConstrained then
            local itemClass = item.class or item.id
            local def = (Monarch.Inventory.Items and Monarch.Inventory.Items[itemClass]) or nil
            if (not def) and Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[itemClass] then
                local key = Monarch.Inventory.ItemsRef[itemClass]
                def = Monarch.Inventory.Items and Monarch.Inventory.Items[key]
            end

            if def and def.WeaponClass then
                local wepClass = tostring(def.WeaponClass)
                local wep = self:GetWeapon(wepClass)
                if IsValid(wep) then
                    if wep.Clip1 and item.clip == nil then
                        local clip1 = wep:Clip1()
                        if isnumber(clip1) then
                            item.clip = clip1
                        end
                    end
                    self:StripWeapon(wepClass)
                end
            end

            if item.equipped then
                Monarch_CallItemHook(def, "OnRemove", self, i, item)
                item.equipped = false
            end

            table.insert(removed, item.class or item.id)
            inv[i] = nil
        end
    end

    if #removed > 0 then
        self:SyncInventory()
    end

    -- Also save the updated inventory
    local charID = self.MonarchID or (self.MonarchActiveChar and self.MonarchActiveChar.id) or self.MonarchLastCharID
    if charID and Monarch and Monarch.Inventory and Monarch.Inventory.SaveForOwner then
        Monarch.Inventory.Data[charID] = Monarch.Inventory.Data[charID] or {}
        Monarch.Inventory.Data[charID][1] = {}
        for i = 1, (MONARCH_INV_MAX_SLOTS or 20) do
            local it = inv[i]
            if it then
                Monarch.Inventory.Data[charID][1][i] = table.Copy(it)
            end
        end
        Monarch.Inventory.SaveForOwner(self, charID, Monarch.Inventory.Data[charID][1])
    end
end

hook.Add("OnPlayerChangedTeam", "Monarch_RemoveConstrainedOnTeamChange", function(ply, oldTeam, newTeam)
    if IsValid(ply) then
        ply:RemoveConstrainedItems()
        ply:SetupHands()
    end
end)

hook.Add("PlayerDisconnected", "Monarch_ClearConstrainedOnDisconnect", function(ply)
    -- Constrained items are automatically removed when inventory is saved on disconnect
    -- This is handled by the SaveForOwner function
end)
