Monarch = Monarch or {}
Monarch.CharSystem = Monarch.CharSystem or {}

local CHAR_TABLE = "monarch_characters"

util.AddNetworkString("Monarch_CharCreate")
util.AddNetworkString("Monarch_CharListRequest")
util.AddNetworkString("Monarch_CharList")
util.AddNetworkString("Monarch_CharActivated")
util.AddNetworkString("Monarch_CharForceCreate")
util.AddNetworkString("Monarch_ShowPIC")
util.AddNetworkString("Monarch_CharSelect")
util.AddNetworkString("Monarch_RPUpdate")

hook.Add("DatabaseConnected", "Monarch_CharTableInit", function()
    local desired = {
        height = "VARCHAR(8) NOT NULL DEFAULT ''",
        weight = "VARCHAR(8) NOT NULL DEFAULT ''",
        haircolor = "VARCHAR(32) NOT NULL DEFAULT ''",
        eyecolor = "VARCHAR(32) NOT NULL DEFAULT ''",
        age = "TINYINT NOT NULL DEFAULT 0"
    }
    mysql:RawQuery("SHOW COLUMNS FROM monarch_players", function(res)
        local existing = {}
        if istable(res) then
            for _, row in ipairs(res) do
                local f = row.Field or row.field
                if isstring(f) then existing[string.lower(f)] = true end
            end
        end
        for col, def in pairs(desired) do
            if not existing[col] then
                local q = "ALTER TABLE monarch_players ADD COLUMN "..col.." "..def
                mysql:RawQuery(q, function() end)
            end
        end
    end)
end)

local function SanitizeRP(name, model, skin, female, height, weight, hair, eye, age)
    name = string.Trim(name or "")
    if #name < 3 or #name > 48 then return nil, "Invalid name length" end

    model = string.Trim(model or "")
    if model == "" then return nil, "Invalid model" end

    skin = tonumber(skin) or 0
    skin = math.Clamp(skin, 0, 255)

    female = female and true or false

    height = string.Trim(height or "")
    if #height > 8 then height = string.sub(height, 1, 8) end

    weight = string.Trim(weight or "")
    if #weight > 8 then weight = string.sub(weight, 1, 8) end
    if weight ~= "" then
        local wNum = tonumber(weight)
        if wNum then
            wNum = math.Clamp(math.floor(wNum), 60, 400)
            weight = tostring(wNum)
        end
    end

    hair = string.Trim(hair or "")
    if #hair > 32 then hair = string.sub(hair, 1, 32) end
    eye = string.Trim(eye or "")
    if #eye > 32 then eye = string.sub(eye, 1, 32) end

    age = tonumber(age) or 0
    age = math.Clamp(age, 0, 120)

    return {
        name = name,
        model = model,
        skin = skin,
        female = female,
        height = height,
        weight = weight,
        haircolor = hair,
        eyecolor = eye,
        age = age
    }
end

local function SendCharList(ply)
    if not IsValid(ply) then return end
    local steamid = ply:SteamID()
    local q = mysql:Select("monarch_players")
    q:Select("id")
    q:Select("rpname")
    q:Select("model")
    q:Select("skin")
    q:Select("xp")
    q:Select("money")
    q:Select("bankmoney")
    q:Select("team")
    q:Select("bodygroups")
    q:WhereEqual("steamid", steamid)
    q:Callback(function(res)
        if not IsValid(ply) then return end
        local count = (res and #res) or 0
        net.Start("Monarch_CharList")
            net.WriteUInt(count, 3)
            if res then
                for _, row in ipairs(res) do
                    net.WriteUInt(tonumber(row.id) or 0, 32)
                    net.WriteString(row.rpname or "")
                    net.WriteString(row.model or "")
                    net.WriteUInt(tonumber(row.skin) or 0, 8)
                    net.WriteInt(tonumber(row.xp) or 0, 32)
                    net.WriteInt(tonumber(row.money) or 0, 32)
                    net.WriteInt(tonumber(row.bankmoney) or 0, 32)
                    net.WriteUInt(tonumber(row.team) or 1, 8)
                    net.WriteString(row.bodygroups or "")
                end
            end
        net.Send(ply)
    end)
    q:Execute()
end

net.Receive("Monarch_CharListRequest", function(_, ply)
    SendCharList(ply)
end)

net.Receive("Monarch_RPUpdate", function(_, ply)
    if not IsValid(ply) then return end
    local h = net.ReadString()
    local w = net.ReadString()
    local hair = net.ReadString()
    local eye = net.ReadString()
    local age = net.ReadUInt(8)
    local c = ply.MonarchActiveChar
    if not c or not c.id then return end

    local canUpdatePhysical = hook.Run("Monarch_CanUpdateCharacterPhysical", ply, c, h, w, hair, eye, age)
    if canUpdatePhysical == false then return end

    local needs = (not c.height or c.height == "") or (not c.weight or c.weight == "") or (not c.haircolor or c.haircolor == "") or (not c.eyecolor or c.eyecolor == "") or (tonumber(c.age) or 0) == 0
    if not needs then return end
    c.height = h; c.weight = w; c.haircolor = hair; c.eyecolor = eye; c.age = age
    ply:SetNWString("CharHeight", h)
    ply:SetNWString("CharWeight", w)
    ply:SetNWString("CharHairColor", hair)
    ply:SetNWString("CharEyeColor", eye)
    ply:SetNWInt("CharAge", age)
    local upd = mysql:Update("monarch_players")
    upd:Update("height", h)
    upd:Update("weight", w)
    upd:Update("haircolor", hair)
    upd:Update("eyecolor", eye)
    upd:Update("age", age)
    upd:WhereEqual("id", c.id)
    upd:Callback(function()
        if not IsValid(ply) then return end
        hook.Run("Monarch_CharacterPhysicalUpdated", ply, c, {
            height = h,
            weight = w,
            haircolor = hair,
            eyecolor = eye,
            age = age
        })
    end)
    upd:Execute()
end)

concommand.Add("monarch_update_charinfo", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then ply:ChatPrint("[Monarch] Admin only.") return end
    local c = ply.MonarchActiveChar
    if not c or not c.id then ply:ChatPrint("[Monarch] No active character to update.") return end

    local height = args[1] or c.height or ""
    local weight = args[2] or c.weight or ""
    local hair = args[3] or c.haircolor or ""
    local eye = args[4] or c.eyecolor or ""
    local age = tonumber(args[5]) or c.age or 0

    local up = mysql:Update("monarch_players")
    up:Update("height", height)
    up:Update("weight", weight)
    up:Update("haircolor", hair)
    up:Update("eyecolor", eye)
    up:Update("age", age)
    up:WhereEqual("id", c.id)
    up:Callback(function()
        if not IsValid(ply) then return end
        c.height = height
        c.weight = weight
        c.haircolor = hair
        c.eyecolor = eye
        c.age = age
        ply:ChatPrint("[Monarch] RP fields updated.")
    end)
    up:Execute()
end, nil, "monarch_update_rp <height> <weight> <hair> <eye> <age> (admin)")

local function Monarch_FinalizeCharActivation(ply, charData)
    if not (IsValid(ply) and charData) then return end

	local shouldSpawn = hook.Run("Monarch_ShouldSpawnCharacter", ply, charData)
    ply:Freeze(false)
	if shouldSpawn ~= false then
        ply:Spawn()
	end

	hook.Run("Monarch_PreCharacterActivated", ply, charData)

    timer.Simple(0, function()
        if not (IsValid(ply) and charData) then return end
        hook.Run("Monarch_PostCharacterSpawn", ply, charData)
        hook.Run("OnCharacterActivated", ply, charData)
        hook.Run("Monarch_CharLoaded", ply, charData)
        hook.Run("Monarch_PostCharacterActivated", ply, charData)
        net.Start("Monarch_CharActivated")
        net.Send(ply)
    end)
end

net.Receive("Monarch_CharSelect", function(_, ply)
    if not IsValid(ply) then 
        return 
    end
    local charID = net.ReadUInt(32)
    local charName = net.ReadString()
    local steamid = ply:SteamID64() or ply:SteamID()

    local canSelectCharacter = hook.Run("Monarch_CanSelectCharacter", ply, charID, charName)
    if canSelectCharacter == false then
        return
    end

    if ply.MonarchActiveChar and ply.MonarchActiveChar.id then
        if Monarch and Monarch.Inventory and Monarch.Inventory.SaveForOwner then
            Monarch.Inventory.SaveForOwner(ply, ply.MonarchActiveChar.id)
        end
    end

    local q = mysql:Select("monarch_players")
    q:Select("id")
    q:Select("rpname")
    q:Select("model")
    q:Select("skin")
    q:Select("team")
    q:Select("bodygroups")
    q:Select("height")
    q:Select("weight")
    q:Select("haircolor")
    q:Select("eyecolor")
    q:Select("age")
    q:WhereEqual("steamid", ply:SteamID())
    q:WhereEqual("id", charID)
    q:Limit(1)
    q:Callback(function(res)
        if not IsValid(ply) then return end
        if not res or not res[1] then
            MsgC(Color(255,100,100), "[Monarch] Character ID ", charID, " not found for ", ply:Nick(), "\n")
            return
        end
        local row = res[1]
        ply.MonarchActiveChar = {
            id = tonumber(row.id) or charID,
            steamid = ply:SteamID(),
            name = row.rpname or charName,
            model = row.model or "models/player/Group01/male_01.mdl",
            skin = tonumber(row.skin) or 0,
            team = tonumber(row.team) or 1,
            bodygroups = row.bodygroups or "{}",
            height = row.height or "",
            weight = row.weight or "",
            haircolor = row.haircolor or "",
            eyecolor = row.eyecolor or "",
            age = tonumber(row.age) or 0
        }
        ply.MonarchCharData = ply.MonarchActiveChar
        ply.MonarchLastCharID = ply.MonarchActiveChar.id
        ply.MonarchID = ply.MonarchActiveChar.id
        ply:SetNWString("MonarchCharID", tostring(ply.MonarchActiveChar.id))

        hook.Run("Monarch_CharacterDataSelected", ply, ply.MonarchActiveChar, row)

        if Monarch.GetWhitelistLevels and Monarch_SetWhitelistNWBulk then
            local wl = Monarch.GetWhitelistLevels(ply) or {}
            Monarch_SetWhitelistNWBulk(ply, wl)
        end

        ply:SetModel(ply.MonarchActiveChar.model)
        ply:SetSkin(ply.MonarchActiveChar.skin)

        if ply.MonarchActiveChar.bodygroups and ply.MonarchActiveChar.bodygroups ~= "" and ply.MonarchActiveChar.bodygroups ~= "{}" then
            local success, bodygroups = pcall(util.JSONToTable, ply.MonarchActiveChar.bodygroups)
            if success and bodygroups and type(bodygroups) == "table" then
                for bgID, bgValue in pairs(bodygroups) do
                    local id = tonumber(bgID)
                    local value = tonumber(bgValue)
                    if id and value then
                        ply:SetBodygroup(id, value)
                    end
                end
            end
        end

        ply:SetTeam(ply.MonarchActiveChar.team)

        if ply.Monarch_SetTeam then
            ply:Monarch_SetTeam(ply.MonarchActiveChar.team)
        end

        if ply.SetRPName then
            ply:SetRPName(ply.MonarchActiveChar.name or "Unknown", false)
        else
            ply:SetNWString("rpname", ply.MonarchActiveChar.name or "Unknown")
        end

        if Monarch and Monarch.Inventory and Monarch.Inventory.LoadForOwner then
            Monarch.Inventory.LoadForOwner(ply, ply.MonarchActiveChar.id, function()
                if not IsValid(ply) then return end
                Monarch_FinalizeCharActivation(ply, ply.MonarchActiveChar)
            end)
        else
            Monarch_FinalizeCharActivation(ply, ply.MonarchActiveChar)
        end
    end)
    q:Execute()
end)

