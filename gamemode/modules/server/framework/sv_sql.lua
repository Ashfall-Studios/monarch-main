Config = Config or {}

Config.DBInfo = {
	ip = "localhost",
	username = "root",
	password = "",
	database = "Monarch",
	port = 3306
} -- placed here for security

Q = [[
CREATE TABLE IF NOT EXISTS monarch_player (
    ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name VARCHAR(255) NOT NULL UNIQUE,
    XP INTEGER,
    Money INTEGER
);
]]

local success = sql.Query(Q)

hook.Add("PlayerInitialSpawn", "CheckFirstJoin", function(ply)
    if not ply:GetPData("PreviouslyJoined") then
        local id = ply:SteamID64()
        local playerName = sql.SQLStr(tostring(ply:Nick())) or sql.SQLStr("ERR.")
        local money = Config.DefaultMoney
        local xp = 0

        local query1 = "INSERT INTO monarch_player (ID, Name, XP, Money) VALUES (" .. id .. ", " .. playerName .. ", " .. money .. ", " .. xp .. ");"

        local success1 = sql.Query(query1)

        if sql.LastError() then ply:RemovePData("PreviouslyJoined") end

        if success1 == false then
            local err = sql.LastError() or "Unknown error"
            ply:RemovePData("PreviouslyJoined")
            MsgC(Color(255, 0, 0), "[Monarch ERROR HANDLER] ", Color(83, 100, 255), "ERROR SAVING NEW PLAYER DATA FOR " .. ply:Nick() .. " ERR. CODE - " .. err .. "\n")
        else
            ply.MonarchActiveChar = { id = id }
            ply.MonarchLastCharID = id
            ply:SetNWString("MonarchCharID", tostring(id))
        end
    end

    if not ply.MonarchActiveChar or not ply.MonarchActiveChar.id then
    end
end)

function GM:DatabaseConnected()
    local sqlQuery = mysql:Create("monarch_players")
        sqlQuery:Create("id", "int unsigned NOT NULL AUTO_INCREMENT")
        sqlQuery:Create("rpname", "varchar(70) NOT NULL") 
        sqlQuery:Create("steamid", "varchar(25) NOT NULL") 
        sqlQuery:Create("team", "int(11) unsigned NOT NULL DEFAULT 1")
        sqlQuery:Create("bodygroups", "varchar(255) NOT NULL DEFAULT '{}'")
        sqlQuery:Create("group", "varchar(70) NOT NULL DEFAULT 'user'")
        sqlQuery:Create("rpgroup", "int(11) unsigned NOT NULL DEFAULT 0") 
        sqlQuery:Create("rpgrouprank", "varchar(255) NOT NULL DEFAULT ''")
        sqlQuery:Create("xp", "int(11) unsigned DEFAULT NULL")
        sqlQuery:Create("money", "int(11) unsigned DEFAULT NULL")
        sqlQuery:Create("bankmoney", "int(11) unsigned DEFAULT NULL")
        sqlQuery:Create("skills", "longtext")
        sqlQuery:Create("ammo", "text")
        sqlQuery:Create("model", "varchar(160) NOT NULL")
        sqlQuery:Create("skin", "tinyint")
        sqlQuery:Create("cosmetic", "longtext")
        sqlQuery:Create("data", "longtext")
        sqlQuery:Create("firstjoin", "int(11) unsigned NOT NULL")
        sqlQuery:Create("height", "varchar(8) NOT NULL DEFAULT ''")
        sqlQuery:Create("weight", "varchar(8) NOT NULL DEFAULT ''")
        sqlQuery:Create("haircolor", "varchar(32) NOT NULL DEFAULT ''")
        sqlQuery:Create("eyecolor", "varchar(32) NOT NULL DEFAULT ''")
        sqlQuery:Create("age", "tinyint NOT NULL DEFAULT 0")
        sqlQuery:PrimaryKey("id")
    sqlQuery:Execute()

    local sqlQuery = mysql:Create("monarch_inventory")
        sqlQuery:Create("id", "int unsigned NOT NULL AUTO_INCREMENT")
        sqlQuery:Create("uniqueid", "varchar(25) NOT NULL")
        sqlQuery:Create("ownerid", "int(11) unsigned DEFAULT NULL")
        sqlQuery:Create("storagetype", "tinyint NOT NULL DEFAULT 1") 
        sqlQuery:PrimaryKey("id")
    sqlQuery:Execute()

    local function ensureColumn(tbl, colDef)
        local name = colDef.name
        mysql:RawQuery("SHOW COLUMNS FROM `"..tbl.."` LIKE '"..name.."'", function(result)
            if not (type(result) == "table" and #result > 0) then
                local alter = "ALTER TABLE `"..tbl.."` ADD COLUMN `"..name.."` "..colDef.type
                mysql:RawQuery(alter, function() end)
            end
        end)
    end
    ensureColumn("monarch_inventory", { name = "ownerid", type = "int(11) unsigned DEFAULT NULL" })
    ensureColumn("monarch_inventory", { name = "storagetype", type = "tinyint NOT NULL DEFAULT 1" })
    ensureColumn("monarch_players", { name = "team", type = "int(11) unsigned NOT NULL DEFAULT 1" })
    ensureColumn("monarch_players", { name = "bodygroups", type = "varchar(255) NOT NULL DEFAULT '{}'" })
    ensureColumn("monarch_players", { name = "group", type = "varchar(70) NOT NULL DEFAULT 'user'" })
    ensureColumn("monarch_players", { name = "rpgroup", type = "int(11) unsigned NOT NULL DEFAULT 0" })
    ensureColumn("monarch_players", { name = "rpgrouprank", type = "varchar(255) NOT NULL DEFAULT ''" })
    ensureColumn("monarch_players", { name = "height", type = "varchar(8) NOT NULL DEFAULT ''" })
    ensureColumn("monarch_players", { name = "weight", type = "varchar(8) NOT NULL DEFAULT ''" })
    ensureColumn("monarch_players", { name = "haircolor", type = "varchar(32) NOT NULL DEFAULT ''" })
    ensureColumn("monarch_players", { name = "eyecolor", type = "varchar(32) NOT NULL DEFAULT ''" })
    ensureColumn("monarch_players", { name = "age", type = "tinyint NOT NULL DEFAULT 0" })

    local sqlQuery = mysql:Create("player_whitelists")
        sqlQuery:Create("id", "int unsigned NOT NULL AUTO_INCREMENT")
        sqlQuery:Create("steamid", "varchar(25) NOT NULL")
        sqlQuery:Create("team", "varchar(90) NOT NULL")
        sqlQuery:Create("level", "int(11) unsigned NOT NULL")
        sqlQuery:PrimaryKey("id")
    sqlQuery:Execute()

    local sqlQuery = mysql:Create("monarch_rpgroups")
        sqlQuery:Create("id", "int unsigned NOT NULL AUTO_INCREMENT")
        sqlQuery:Create("ownerid", "int(11) unsigned DEFAULT NULL")
        sqlQuery:Create("name", "varchar(255) NOT NULL")
        sqlQuery:Create("type", "int(11) unsigned NOT NULL")
        sqlQuery:Create("maxsize", "int(11) unsigned NOT NULL")
        sqlQuery:Create("maxstorage", "int(11) unsigned NOT NULL")
        sqlQuery:Create("ranks", "longtext")
        sqlQuery:Create("data", "longtext")
        sqlQuery:PrimaryKey("id")
    sqlQuery:Execute()

    local sqlQuery = mysql:Create("monarch_data")
        sqlQuery:Create("id", "int unsigned NOT NULL AUTO_INCREMENT")
        sqlQuery:Create("name", "varchar(255) NOT NULL")
        sqlQuery:Create("data", "longtext")
        sqlQuery:PrimaryKey("id")
    sqlQuery:Execute()

    local sqlQuery = mysql:Create("monarch_characters")
        sqlQuery:Create("id", "int unsigned NOT NULL AUTO_INCREMENT")
        sqlQuery:Create("steamid", "varchar(32) NOT NULL")  
        sqlQuery:Create("name", "varchar(64) NOT NULL")     
        sqlQuery:Create("model", "varchar(160) NOT NULL")       
        sqlQuery:Create("skin", "tinyint unsigned NOT NULL")
        sqlQuery:Create("team", "int(11) unsigned NOT NULL DEFAULT 1") 
        sqlQuery:Create("bodygroups", "varchar(255)")  
        sqlQuery:Create("money", "int(11) unsigned NOT NULL DEFAULT 0")
        sqlQuery:Create("bankmoney", "int(11) unsigned NOT NULL DEFAULT 0")
        sqlQuery:Create("xp", "int(11) unsigned NOT NULL DEFAULT 0")
        sqlQuery:Create("data", "longtext")
        sqlQuery:Create("skills", "longtext") 
        sqlQuery:Create("created_at", "int(11) unsigned NOT NULL") 
        sqlQuery:Create("last_played", "int(11) unsigned NOT NULL")
        sqlQuery:PrimaryKey("id")
    sqlQuery:Execute()

    local sqlQuery = mysql:Create("monarch_persistence")
        sqlQuery:Create("id", "int unsigned NOT NULL AUTO_INCREMENT")
        sqlQuery:Create("map", "varchar(64) NOT NULL")
        sqlQuery:Create("type", "varchar(32) NOT NULL")
        sqlQuery:Create("data", "longtext")
        sqlQuery:Create("updated_at", "int(11) unsigned NOT NULL DEFAULT 0")
        sqlQuery:PrimaryKey("id")
    sqlQuery:Execute()
end

timer.Create("Monarch.DATABASE_Think", 1, 0, function()
    mysql:Think()
end)
