TLib = TLib or {}
local meta = FindMetaTable("Player")
Config = Config or {}

function Monarch.GetDefaultSpawnVector()
    local arr = Config.DefaultSpawnVectors
    if istable(arr) and #arr > 0 then
        return arr[math.random(1, #arr)]
    end
    return Config.DefaultSpawnVector
end

function meta:Notify(msg, length)
    msg = tostring(msg or "")
    kind = 0 
    length = tonumber(length) or (Config and Config.NotificationLength) or 3
    if CLIENT then
        if notification and notification.AddLegacy then
            notification.AddLegacy(msg, kind, length)
        else
            chat.AddText(Color(200,200,200), msg)
        end
    else 
        if not IsValid(self) or not self:IsPlayer() then return end
        if util and util.AddNetworkString then 
            net.Start("Monarch.Notify")
                net.WriteString(msg)
                net.WriteUInt(kind, 3)
                net.WriteFloat(length)
            net.Send(self)
        end
    end
end

function meta:GetTeamName()
    local tn = team and team.GetName and team.GetName(ply:Team()) or nil
    return isstring(tn) and string.lower(tn) or ""
end

function meta:SetRPName(str, saveToDb)

    if not str or str == "" then return end

    saveToDb = saveToDb == true  

    if CLIENT then
        net.Start("Monarch_SetRPName")
            net.WriteEntity(self)
            net.WriteString(str)
        net.SendToServer()
        return
    end

    if SERVER then
        if saveToDb and self.MonarchActiveChar and mysql then

            self.MonarchActiveChar.rpname = str
            local q = mysql:Update("monarch_players")
            q:Update("rpname", str)
            q:Where("id", self.MonarchActiveChar.id)
            q:Callback(function()

                self:SetNWString("rpname", str)
                self:SetNWString("original_rpname", str)
            end)
            q:Execute()
        else

            if self.SetTempRPName then 
                self:SetTempRPName(str) 
            else
                self:SetNWString("temp_rpname", str)
            end
        end
    end
end

function meta:RequestTempRPName(newName)
    if not newName or newName == "" then return false end
    if CLIENT then
        net.Start("Monarch_SetRPName")
            net.WriteEntity(self)
            net.WriteString(newName)
        net.SendToServer()
        return true
    else
        return self.SetTempRPName and self:SetTempRPName(newName)
    end
end

function meta:IsSlowWalking()
    return self:GetVelocity():Length2D() < 61 
end

function meta:SetWhitelist(teamID, level)
    if not isnumber(teamID) then return false end
    level = tonumber(level) or 1
    self:SetPData("MonarchWhitelist_"..tostring(teamID), level)
    self:SetNWInt("MonarchWhitelist_"..tostring(teamID), level)
    return true
end

function meta:GetWhitelist(teamID)
    if not isnumber(teamID) then return 0 end
    local nw = tonumber(self:GetNWInt("MonarchWhitelist_"..tostring(teamID), -1))
    if nw and nw >= 0 then 
        return nw 
    end
    local pd = tonumber(self:GetPData("MonarchWhitelist_"..tostring(teamID)) or 0) or 0
    return pd
end

function meta:HasWhitelist(teamID, requiredLevel)
    requiredLevel = tonumber(requiredLevel) or 1
    return (self:GetWhitelist(teamID) >= requiredLevel)
end

function meta:RemoveWhitelist(teamID)
    if not isnumber(teamID) then return false end
    self:SetPData("MonarchWhitelist_"..tostring(teamID), 0)
    self:SetNWInt("MonarchWhitelist_"..tostring(teamID), 0)
    return true
end

function meta:ClearAllWhitelists()
    for _, team in ipairs(RPExtraTeams or {}) do
        if team.team then
            self:RemoveWhitelist(team.team)
        end
    end
    return true
end

function meta:GetAllWhitelists()
    local whitelists = {}
    for _, team in ipairs(RPExtraTeams or {}) do
        if team.team then
            local level = self:GetWhitelist(team.team)
            if level > 0 then
                whitelists[team.team] = {
                    level = level,
                    name = team.name,
                    teamData = team
                }
            end
        end
    end
    return whitelists
end

if CLIENT then
    net.Receive("Monarch.Notify", function()
        local msg = net.ReadString() or ""
        local kind = net.ReadUInt(3) or 0
        local length = net.ReadFloat() or 3
        if notification and notification.AddLegacy then
            notification.AddLegacy(msg, kind, length)
        else
            chat.AddText(Color(200,200,200), msg)
        end
    end)
end

function meta:GetMoney()
    return self:GetSyncVar(SYNC_MONEY, 0)
end

function meta:GetXP()
    return self:GetSyncVar(SYNC_XP, 0)
end

function meta:AddMoney(amount, reason)
    if not isnumber(amount) or amount <= 0 then return false end
    if SERVER then
        local current = self:GetMoney() or 0
        self:SetSyncVar(SYNC_MONEY, current + amount)
        if reason and self.Notify then
            self:Notify(string.format("You received $%d (%s)", amount, reason))
        end
        return true
    end
    return false
end

function meta:TakeMoney(amount, reason)
    if not isnumber(amount) or amount <= 0 then return false end
    if SERVER then
        local current = self:GetMoney() or 0
        if current < amount then return false end
        self:SetSyncVar(SYNC_MONEY, current - amount)
        if reason and self.Notify then
            self:Notify(string.format("You lost $%d (%s)", amount, reason))
        end
        return true
    end
    return false
end

function meta:SetMoney(amount)
    if not isnumber(amount) or amount < 0 then return false end
    if SERVER then
        self:SetSyncVar(SYNC_MONEY, amount)
        return true
    end
    return false
end

function meta:CanAfford(amount)
    return self:GetMoney() >= (tonumber(amount) or 0)
end

function meta:AddXP(amount, reason)
    if not isnumber(amount) or amount <= 0 then return false end
    if SERVER then
        local current = self:GetXP() or 0
        self:SetSyncVar(SYNC_XP, current + amount)
        if reason and self.Notify then
            self:Notify(string.format("You gained %d XP (%s)", amount, reason))
        end
        return true
    end
    return false
end

function meta:TakeXP(amount, reason)
    if not isnumber(amount) or amount <= 0 then return false end
    if SERVER then
        local current = self:GetXP() or 0
        if current < amount then return false end
        self:SetSyncVar(SYNC_XP, current - amount)
        if reason and self.Notify then
            self:Notify(string.format("You lost %d XP (%s)", amount, reason))
        end
        return true
    end
    return false
end

function meta:SetXP(amount)
    if not isnumber(amount) or amount < 0 then return false end
    if SERVER then
        self:SetSyncVar(SYNC_XP, amount)
        return true
    end
    return false
end

local KEY_BLACKLIST = IN_ATTACK + IN_ATTACK2
local isValid = IsValid
local mathAbs = math.abs

function GM:PlayerSwitchWeapon(ply, oldWep, newWep)
	if SERVER then
		if newWep.QuickDraw and newWep.QuickDraw == true then
			ply:SetWeaponRaised(true)
		else
			ply:SetWeaponRaised(false)
		end
	end
end

function meta:GetRPName()
    if not IsValid(self) then return "Unknown" end
    local ply = self

    local tmp = ply:GetNWString("temp_rpname", "")
    if tmp ~= "" then return tmp end

    local name = ply:GetNWString("MonarchCharName", "")
    if name == "" then name = ply:GetNWString("monarch_char_name", "") end
    if (not name or name == "") and ply.MonarchActiveChar and ply.MonarchActiveChar.name then
        name = ply.MonarchActiveChar.name
    end
    if (not name or name == "") then
        local rp = ply:GetNWString("rpname", "")
        if rp ~= "" then name = rp end
    end
    if (not name or name == "") then
        local pdata = ply:GetPData("rpname", "")
        if pdata ~= "" then name = pdata end
    end
    if not name or name == "" then name = ply:Nick() end
    return name
end

function meta:GetBaseRPName()
    if not IsValid(self) then return "Unknown" end
    local ply = self

    local name = ply:GetNWString("MonarchCharName", "")
    if name == "" then name = ply:GetNWString("monarch_char_name", "") end
    if (not name or name == "") and ply.MonarchActiveChar and ply.MonarchActiveChar.name then
        name = ply.MonarchActiveChar.name
    end
    if (not name or name == "") then
        local rp = ply:GetNWString("rpname", "")
        if rp ~= "" then name = rp end
    end
    if (not name or name == "") then
        local pdata = ply:GetPData("rpname", "")

function meta:GetCharID()
    if self.MonarchActiveChar and self.MonarchActiveChar.id then
        return self.MonarchActiveChar.id
    end
    return nil
end

function meta:GetCharData()
    return self.MonarchActiveChar or {}
end

function meta:GetCurrentRank()
    if not IsValid(self) then return nil, 0, 0 end

    local teamID = self:Team()
    local currentLevel = self:GetNWInt("MonarchWhitelist_" .. teamID, 0)
    local bestRankName = nil
    local bestRankLevel = -1

    local ladders = Monarch and Monarch.RankLadders
    local teamLadder = istable(ladders) and ladders[teamID] or nil

    if istable(teamLadder) then
        for _, entry in ipairs(teamLadder) do
            local entryLevel = tonumber(entry.lvl or entry.level or entry.whitelistLevel) or 0
            if currentLevel >= entryLevel and entryLevel >= bestRankLevel then
                bestRankLevel = entryLevel
                bestRankName = entry.name or entry.grouprank or entry.id
            end
        end
    end

    if not bestRankName and Monarch and Monarch.RankVendors then
        for _, vendor in pairs(Monarch.RankVendors) do
            for _, rankDef in ipairs(vendor.ranks or {}) do
                local rankTeamID = tonumber(rankDef.team)
                local requiredLevel = tonumber(rankDef.whitelistLevel)

                if rankTeamID == teamID and requiredLevel and currentLevel >= requiredLevel and requiredLevel >= bestRankLevel then
                    bestRankLevel = requiredLevel
                    bestRankName = rankDef.grouprank or rankDef.name or rankDef.id
                end
            end
        end
    end

    return bestRankName, currentLevel, teamID
end

function meta:HasActiveChar()
    return self.MonarchActiveChar ~= nil and self.MonarchActiveChar.id ~= nil
end

function meta:CharacterIsNew()
    if not IsValid(self) then return false end

    if self.MonarchActiveChar and self.MonarchActiveChar.isNew ~= nil then
        return self.MonarchActiveChar.isNew == true
    end

    return self:GetNWBool("MonarchCharIsNew", false)
end

if SERVER then
    hook.Add("OnCharacterActivated", "Monarch_CharacterIsNewFlag", function(ply, charData)
        if not IsValid(ply) then return end

        local activeCharID = tostring((charData and charData.id) or (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or "")
        local createdCharID = tostring(ply.MonarchCharJustCreatedID or "")
        local isNew = (activeCharID ~= "" and createdCharID ~= "" and activeCharID == createdCharID)

        ply:SetNWBool("MonarchCharIsNew", isNew)

        if ply.MonarchActiveChar then
            ply.MonarchActiveChar.isNew = isNew
        end

        if isNew then
            ply.MonarchCharJustCreatedID = nil
        end
    end)

    hook.Add("PlayerInitialSpawn", "Monarch_CharacterIsNewReset", function(ply)
        if not IsValid(ply) then return end
        ply:SetNWBool("MonarchCharIsNew", false)
    end)
end

function meta:GetCharModel()
    if self.MonarchActiveChar and self.MonarchActiveChar.model then
        return self.MonarchActiveChar.model
    end
    return self:GetModel()
end

function meta:GetCharSkin()
    if self.MonarchActiveChar and self.MonarchActiveChar.skin then
        return self.MonarchActiveChar.skin
    end
    return 0
end

function meta:IsFemaleChar()
    if self.MonarchActiveChar then
        return self.MonarchActiveChar.female == true or self.MonarchActiveChar.female == 1
    end
    return false
end

function meta:GetHeight()
    if self.MonarchActiveChar and self.MonarchActiveChar.height then
        return self.MonarchActiveChar.height
    end
    return ""
end

function meta:GetWeight()
    if self.MonarchActiveChar and self.MonarchActiveChar.weight then
        return self.MonarchActiveChar.weight
    end
    return ""
end

function meta:GetHairColor()
    if self.MonarchActiveChar and self.MonarchActiveChar.haircolor then
        return self.MonarchActiveChar.haircolor
    end
    return ""
end

function meta:GetEyeColor()
    if self.MonarchActiveChar and self.MonarchActiveChar.eyecolor then
        return self.MonarchActiveChar.eyecolor
    end
    return ""
end

function meta:GetAge()
    if self.MonarchActiveChar and self.MonarchActiveChar.age then
        return self.MonarchActiveChar.age
    end
    return 0
end

function meta:GetPhysicalDescription()
    return {
        height = self:GetHeight(),
        weight = self:GetWeight(),
        hair = self:GetHairColor(),
        eyes = self:GetEyeColor(),
        age = self:GetAge()
    }
end     if pdata ~= "" then name = pdata end
    end
    if not name or name == "" then name = ply:Nick() end
    return name
end

function meta:SetTempRPName(tempName, prefix, suffix)
    if not tempName or tempName == "" then return false end

    if (self:GetNWString("original_rpname", "") or "") == "" then
        local original = nil
        if self.MonarchActiveChar then
            original = self.MonarchActiveChar.rpname or self.MonarchActiveChar.name
        end
        if not original or original == "" then
            original = self:GetNWString("rpname", "")
        end
        if not original or original == "" then
            original = self:GetPData("rpname", "")
        end
        if not original or original == "" then
            original = self:Nick()
        end
        self:SetNWString("original_rpname", original or "")
    end

    local fullTempName = tempName
    if prefix and prefix ~= "" then
        fullTempName = prefix .. " " .. fullTempName
    end
    if suffix and suffix ~= "" then
        fullTempName = fullTempName .. " " .. suffix
    end

    self:SetNWString("temp_rpname", fullTempName)
    return true
end

function meta:RestoreRPName()
    local originalName = self:GetNWString("original_rpname", "")

    if originalName and originalName ~= "" then
        self:SetNWString("rpname", originalName)
        self:SetNWString("temp_rpname", "")
        self:SetNWString("original_rpname", "")

        if SERVER then
            self:Notify("Your name has been restored to: " .. originalName)
        end

        return true
    else
        if SERVER then
            self:Notify("No original name found to restore!")
        end
        return false
    end
end

function meta:GetCharName()

    if SERVER and self.MonarchActiveChar and self.MonarchActiveChar.rpname then
        return self.MonarchActiveChar.rpname
    end

    local originalName = self:GetNWString("original_rpname", "")
    if originalName and originalName ~= "" then
        return originalName
    end

    return self:GetNWString("rpname", self:GetPData("rpname", self:Nick()))
end

function meta:HasTempRPName()
    local tempName = self:GetNWString("temp_rpname", "")
    return tempName and tempName ~= ""
end

concommand.Add( "monarch_set_name", function( ply, cmd, args )
    local name = args[1]
    if not name or name == "" then return end
    if ply.RequestTempRPName then
        ply:RequestTempRPName(name)
    else
        ply:SetRPName(name)
    end
end )

concommand.Add( "monarch_set_temp_name", function( ply, cmd, args )
    if not ply:IsAdmin() then 
        ply:Notify("You don't have permission to use this command!")
        return 
    end

    local targetName = args[1]
    local tempName = args[2]
    local prefix = args[3] or ""
    local suffix = args[4] or ""

    if not targetName or not tempName then
        ply:Notify("Usage: monarch_set_temp_name <player> <temp_name> [prefix] [suffix]")
        return
    end

    local target = nil
    for _, v in player.Iterator() do
        if string.find(string.lower(v:Nick()), string.lower(targetName)) then
            target = v
            break
        end
    end

    if not target then
        ply:Notify("Player not found!")
        return
    end

    target:SetTempRPName(tempName, prefix, suffix)
    ply:Notify("Set temporary name for " .. target:Nick())
end )

concommand.Add( "monarch_restore_name", function( ply, cmd, args )
    if not ply:IsAdmin() then 
        ply:Notify("You don't have permission to use this command!")
        return 
    end

    local targetName = args[1]

    if not targetName then
        ply:Notify("Usage: monarch_restore_name <player>")
        return
    end

    local target = nil
    for _, v in player.Iterator() do
        if string.find(string.lower(v:Nick()), string.lower(targetName)) then
            target = v
            break
        end
    end

    if not target then
        ply:Notify("Player not found!")
        return
    end

    if target:RestoreRPName() then
        ply:Notify("Restored original name for " .. target:Nick())
    else
        ply:Notify("No temporary name to restore for " .. target:Nick())
    end
end )

function player:GetSecondaryMoney()
    local nw = tonumber(self:GetNWInt("bankMoney", -1))
    if nw ~= nil and nw >= 0 then return nw end
    local pd = tonumber(self:GetPData("bankMoney") or 0) or 0
    if pd and pd > 0 then return pd end
    return tonumber(self.BankMoney) or 0
end

function player:GetMoney()
    local nw = tonumber(self:GetNWInt("Money", -1))
    if nw ~= nil and nw >= 0 then return nw end
    local pd = tonumber(self:GetPData("Money") or 0) or 0
    if pd and pd > 0 then return pd end
    return tonumber(self.Money) or 0
end

function meta:GetXP()
    return self:GetPData("XP")
end

function IsNewPlayer(ply)
    if ply:GetPData("PreviouslyJoined") == true then 
        return true
    end
end

function SetNewPlayer(ply)
    ply:SetPData("PreviouslyJoined", true)
end 

if SERVER then
    hook.Add("PhysgunPickup", "basPhysGunPickup", function(ply, ent)
        if (ply:IsAdmin() and ent:IsPlayer()) then
            ent:SetMoveType(MOVETYPE_NONE)
            return true
        end
    end)

    hook.Add("PhysgunDrop", "basPhysGunDrop", function(ply, ent)
        if ent:IsPlayer() then
            ent:SetMoveType(MOVETYPE_WALK)
            ply:GodDisable()
        end
    end)

    util.AddNetworkString("Monarch_DebugCharName")
end

local SAFE_FALL_SPEED   = Config.FallDamageSafeSpeed or 300
local FATAL_FALL_SPEED  = Config.FallDamageFatalSpeed or 1100
local FALL_DMG_SCALE    = Config.FallDamageScale or 1

function GM:GetFallDamage(ply, speed)
    if speed <= SAFE_FALL_SPEED then return 0 end

    local t = math.Clamp((speed - SAFE_FALL_SPEED) / (FATAL_FALL_SPEED - SAFE_FALL_SPEED), 0, 1)

    local curved = t ^ 1.35

    local dmg = curved * ply:GetMaxHealth() * 1.25 * FALL_DMG_SCALE

    ply.LastFall = CurTime()

    return dmg
end

hook.Add("OnPlayerHitGround", "Monarch_FallImpactFeedback", function(ply, inWater, onFloater, speed)
    if inWater or speed < SAFE_FALL_SPEED then return end
    if speed > SAFE_FALL_SPEED + 150 then
        ply:EmitSound("player/pl_fallpain"..math.random(1,3)..".wav", 70, 100)
    end
    local severity = math.Clamp((speed - SAFE_FALL_SPEED) / (FATAL_FALL_SPEED - SAFE_FALL_SPEED), 0, 1)
    if severity > 0 then
        ply:ViewPunch(Angle(severity * -10, 0, 0))
    end
end)

net.Receive("Monarch_DebugCharName", function(len, ply)
    if not IsValid(ply) then return end
    local active = ply.MonarchActiveChar
    local nm = active and active.name or "(nil)"
    print(string.format("[Monarch][DebugCharName] %s -> id=%s name='%s'",
        ply:Nick(),
        active and tostring(active.id) or "nil",
        nm
    ))
end)

pmeta = FindMetaTable("Player")

hook.Add("PlayerInitialSpawn", "InitPlayerStats", function(ply)
    ply:SetNWInt("Hydration", 100)
    ply:SetNWInt("Hunger", 100)
    ply:SetNWInt("Exhaustion", 100)
end)

hook.Add("PlayerSpawn", "PlayerStats", function(ply)
    ply:SetNWInt("Hydration", 100)
    ply:SetNWInt("Hunger", 100)
    ply:SetNWInt("Exhaustion", 100)
end)


function pmeta:GetHunger()
    return self:GetNWInt("Hunger", 100)
end
function pmeta:GetExhaustion()
    return self:GetNWInt("Exhaustion", 100)
end

function pmeta:GetHydration()
    return self:GetNWInt("Hydration", 100)
end

function pmeta:SetHunger(value)
    self:SetNWInt("Hunger", value)
end
function pmeta:SetExhaustion(value)
    self:SetNWInt("Exhaustion", value)
end

function pmeta:SetHydration(value)
    self:SetNWInt("Hydration", value)
end

Config.DisallowedBodygroupsByModel = Config.DisallowedBodygroupsByModel or {}

Monarch = Monarch or {}

function Monarch.IsBodygroupDisallowed(modelPath, groupId)
    if not modelPath or groupId == nil then return false end
    local t = Config.DisallowedBodygroupsByModel[modelPath]
    if t and t[tonumber(groupId)] then return true end
    return false
end

function Monarch.FilterAllowedBodygroups(modelPath, bodygroups)
    local out = {}
    if type(bodygroups) ~= "table" then return out end
    local dis = Config.DisallowedBodygroupsByModel[modelPath]
    for id, val in pairs(bodygroups) do
        local nid = tonumber(id)
        local nval = tonumber(val) or 0
        if nid and not (dis and dis[nid]) then
            out[nid] = nval
        end
    end
    return out
end

if SERVER then
    util.AddNetworkString("Monarch_PlayerChatAddText")
    local function isColor(v) return istable(v) and v.r and v.g and v.b end
    function meta:ChatAddText(...)
        if not IsValid(self) then return end
        local args = {...}
        net.Start("Monarch_PlayerChatAddText")
        net.WriteUInt(#args, 8)
        for _, v in ipairs(args) do
            if isColor(v) then
                net.WriteUInt(1, 2)
                net.WriteUInt(v.r, 8)
                net.WriteUInt(v.g, 8)
                net.WriteUInt(v.b, 8)
                net.WriteUInt(v.a or 255, 8)
            else
                net.WriteUInt(2, 2)
                net.WriteString(tostring(v))
            end
        end
        net.Send(self)
    end
else
    net.Receive("Monarch_PlayerChatAddText", function()
        local count = net.ReadUInt(8)
        local parts = {}
        for i = 1, count do
            local t = net.ReadUInt(2)
            if t == 1 then
                local r = net.ReadUInt(8)
                local g = net.ReadUInt(8)
                local b = net.ReadUInt(8)
                local a = net.ReadUInt(8)
                parts[#parts+1] = Color(r,g,b,a)
            else
                parts[#parts+1] = net.ReadString()
            end
        end
        if chat and chat.AddText then
            chat.AddText(unpack(parts))
        end
    end)
end

Monarch = Monarch or {}
Monarch.Time = Monarch.Time or {}

local Time = Monarch.Time
Time.ServerStartTime = nil 
Time.ClientSyncOffset = 0  

function GetServerGameTime()
    if SERVER then
        if not Time.ServerStartTime then
            Time.ServerStartTime = CurTime()
        end
        return CurTime() - Time.ServerStartTime
    else
        return CurTime() - Time.ClientSyncOffset
    end
end

if SERVER then
    util.AddNetworkString("Monarch_TimeSync")

    function Time.InitServerTime()
        if not Time.ServerStartTime then
            Time.ServerStartTime = CurTime()
        end
    end

    function Time.SyncToClient(ply)
        if not IsValid(ply) then return end
        local serverGameTime = GetServerGameTime()
        net.Start("Monarch_TimeSync")
            net.WriteFloat(serverGameTime)
        net.Send(ply)
    end

    hook.Add("InitPostEntity", "Monarch_TimeInit", function()
        Time.InitServerTime()
    end)

    hook.Add("PlayerInitialSpawn", "Monarch_TimeSyncPlayer", function(ply)
        timer.Simple(0.1, function()
            if IsValid(ply) then
                Time.SyncToClient(ply)
            end
        end)
    end)
else

    net.Receive("Monarch_TimeSync", function()
        local serverGameTime = net.ReadFloat()
        local clientCurTime = CurTime()
        Time.ClientSyncOffset = clientCurTime - serverGameTime
    end)
end

Monarch = Monarch or {}
Monarch.Time = Monarch.Time or {}

Monarch.Time.CYCLE_DURATION = 3600 / 1.5
Monarch.Time.ServerTimeOffset = 0 

function Monarch.Time.Get()
    local posInCycle = (CurTime() + (Monarch.Time.ServerTimeOffset or 0)) % Monarch.Time.CYCLE_DURATION
    local totalMinutes = (posInCycle / Monarch.Time.CYCLE_DURATION) * 24 * 60
    local hour = math.floor(totalMinutes / 60)
    local minute = math.floor(totalMinutes % 60)

    local ampm = hour >= 12 and "PM" or "AM"
    local hour12 = hour % 12
    if hour12 == 0 then hour12 = 12 end

    return string.format("%02d:%02d %s", hour12, minute, ampm)
end

if net then
    net.Receive("Curfew_SyncTime", function()
        local serverHour = net.ReadUInt(8)
        local cycleTime = Monarch.Time.CYCLE_DURATION
        local expectedPosInCycle = (serverHour / 24) * cycleTime
        local actualPosInCycle = CurTime() % cycleTime
        Monarch.Time.ServerTimeOffset = expectedPosInCycle - actualPosInCycle
    end)
end

if surface and surface.CreateFont then
    surface.CreateFont("ClockTime", {
        font = "Purista",
        size = 30,
        weight = 400,
        antialias = true,
        shadow = true,
        blursize = 0
    })
end
Monarch.VoiceModes = Monarch.VoiceModes or {}

Monarch.VoiceModes.Modes = Monarch.VoiceModes.Modes or {}
Monarch.VoiceModes.ModeOrder = Monarch.VoiceModes.ModeOrder or {}

Monarch.VoiceModes.DefaultMode = "speaking"

function Monarch.VoiceModes.Register(modeData)
    if not modeData then
        ErrorNoHalt("[Monarch VoiceModes] Cannot register mode: modeData is nil\n")
        return false
    end

    if not modeData.id or modeData.id == "" then
        ErrorNoHalt("[Monarch VoiceModes] Cannot register mode: id is required\n")
        return false
    end

    if not modeData.name or modeData.name == "" then
        ErrorNoHalt("[Monarch VoiceModes] Cannot register mode: name is required\n")
        return false
    end

    if not modeData.distance or type(modeData.distance) ~= "number" then
        ErrorNoHalt("[Monarch VoiceModes] Cannot register mode: valid distance is required\n")
        return false
    end

    modeData.color = modeData.color or Color(255, 255, 255)
    modeData.description = modeData.description or ""

    Monarch.VoiceModes.Modes[modeData.id] = modeData

    if not table.HasValue(Monarch.VoiceModes.ModeOrder, modeData.id) then
        table.insert(Monarch.VoiceModes.ModeOrder, modeData.id)
    end

    return true
end

function Monarch.VoiceModes.GetMode(id)
    return Monarch.VoiceModes.Modes[id]
end

function Monarch.VoiceModes.GetAllModes()
    return Monarch.VoiceModes.Modes
end

function Monarch.VoiceModes.GetModeOrder()
    return Monarch.VoiceModes.ModeOrder
end

function Monarch.VoiceModes.GetNextMode(currentMode)
    local order = Monarch.VoiceModes.ModeOrder

    if #order == 0 then
        return Monarch.VoiceModes.DefaultMode
    end

    local currentIndex = 1
    for i, modeId in ipairs(order) do
        if modeId == currentMode then
            currentIndex = i
            break
        end
    end

    local nextIndex = (currentIndex % #order) + 1
    return order[nextIndex]
end

Monarch.VoiceModes.Register({
    id = "whispering",
    name = "Whispering",
    distance = 150,
    color = Color(200, 200, 200),
    description = "Very quiet, only nearby players can hear you"
})

Monarch.VoiceModes.Register({
    id = "speaking",
    name = "Speaking",
    distance = 600,
    color = Color(200, 200, 200),
    description = "Normal talking distance"
})

Monarch.VoiceModes.Register({
    id = "shouting",
    name = "Shouting",
    distance = 1200,
    color = Color(255, 150, 150),
    description = "Very loud, can be heard from far away"
})

if SERVER then
    util.AddNetworkString("Monarch_VoiceMode_Set")
    util.AddNetworkString("Monarch_VoiceMode_Notify")
end

function meta:GetVoiceMode()
    if CLIENT then
        return Monarch.VoiceModes.CurrentMode or Monarch.VoiceModes.DefaultMode
    else
        if Monarch.VoiceModes.GetPlayerMode then
            return Monarch.VoiceModes.GetPlayerMode(self)
        end
        return Monarch.VoiceModes.DefaultMode
    end
end

function meta:SetVoiceMode(modeId)
    if not Monarch.VoiceModes.GetMode(modeId) then 
        return false 
    end

    if SERVER and Monarch.VoiceModes.SetPlayerMode then
        Monarch.VoiceModes.SetPlayerMode(self, modeId)
        return true
    elseif CLIENT then
        net.Start("Monarch_VoiceMode_Set")
            net.WriteString(modeId)
        net.SendToServer()
        return true
    end

    return false
end

function meta:GetVoiceModeData()
    local modeId = self:GetVoiceMode()
    return Monarch.VoiceModes.GetMode(modeId)
end

function meta:GetVoiceDistance()
    local mode = self:GetVoiceModeData()
    return mode and mode.distance or 600
end

function meta:CycleVoiceMode()
    local current = self:GetVoiceMode()
    local next = Monarch.VoiceModes.GetNextMode(current)
    return self:SetVoiceMode(next)
end

Monarch.Utils = Monarch.Utils or {}

function Monarch.Utils.IsEmpty(str)
    return not str or str == ""
end

function Monarch.Utils.Clamp(value, min, max)
    return math.Clamp(tonumber(value) or 0, tonumber(min) or 0, tonumber(max) or 100)
end

function Monarch.Utils.FormatMoney(amount)
    amount = tonumber(amount) or 0
    local formatted = tostring(math.floor(amount))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return "$" .. formatted
end

function Monarch.Utils.GetDistance(a, b)
    local posA = isvector(a) and a or (IsValid(a) and a:GetPos() or Vector(0,0,0))
    local posB = isvector(b) and b or (IsValid(b) and b:GetPos() or Vector(0,0,0))
    return posA:Distance(posB)
end

function Monarch.Utils.IsWithinDistance(ply1, ply2, distance)
    if not IsValid(ply1) or not IsValid(ply2) then return false end
    return Monarch.Utils.GetDistance(ply1, ply2) <= (tonumber(distance) or 0)
end

function Monarch.Utils.GetPlayersInRadius(source, distance, filter)
    local pos = isvector(source) and source or (IsValid(source) and source:GetPos() or Vector(0,0,0))
    local players = {}
    distance = tonumber(distance) or 0

    for _, ply in player.Iterator() do
        if IsValid(ply) and ply:GetPos():Distance(pos) <= distance then
            if not filter or filter(ply) then
                table.insert(players, ply)
            end
        end
    end

    return players
end

function Monarch.Utils.Sanitize(str, allowSpaces)
    str = tostring(str or "")
    if allowSpaces then
        return string.gsub(str, "[^%w%s]", "")
    else
        return string.gsub(str, "[^%w]", "")
    end
end

function Monarch.Utils.TableCopy(original)
    if type(original) ~= "table" then return original end
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = Monarch.Utils.TableCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

Monarch.Anim = Monarch.Anim or {}

function meta:PlayGesture(gesture, restart)
    if not IsValid(self) or not isnumber(gesture) then return false end
    restart = restart ~= false 

    if CLIENT then
        self:AnimRestartGesture(GESTURE_SLOT_CUSTOM, gesture, restart)
    else
        local seq = self:LookupSequence(self:SelectWeightedSequence(gesture))
        self:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, seq, 0, restart)
    end
    return true
end

function meta:StopGesture()
    if not IsValid(self) then return false end

    if CLIENT then
        self:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
    else
        self:RemoveGesture(GESTURE_SLOT_CUSTOM)
    end
    return true
end

function meta:PlaySequence(sequenceName)
    if not IsValid(self) or not isstring(sequenceName) then return false end

    local sequence = self:LookupSequence(sequenceName)
    if sequence and sequence > 0 then
        self:SetSequence(sequence)
        self:SetCycle(0)
        return true
    end
    return false
end

function meta:SetAnimationRate(rate)
    if not IsValid(self) or not isnumber(rate) then return false end
    self:SetPlaybackRate(rate)
    return true
end

function meta:RestartAnimation()
    if not IsValid(self) then return false end
    self:SetCycle(0)
    return true
end

function meta:SetScale(scale, duration)
    if not IsValid(self) or not isnumber(scale) then return false end
    scale = math.Clamp(scale, 0.1, 10) 
    duration = tonumber(duration) or 0

    if SERVER then
        self:SetModelScale(scale, duration)

        local mins = Vector(-16, -16, 0) * scale
        local maxs = Vector(16, 16, 72) * scale
        self:SetHull(mins, maxs)
        self:SetHullDuck(mins, maxs * 0.5)
    end

    return true
end

function meta:GetScale()
    if not IsValid(self) then return 1 end
    return self:GetModelScale()
end

function meta:ResetScale(duration)
    return self:SetScale(1.0, duration)
end

function meta:ScaleBone(boneID, scale)
    if not IsValid(self) or not isnumber(boneID) then return false end
    if not isvector(scale) then scale = Vector(1, 1, 1) end

    self:ManipulateBoneScale(boneID, scale)
    return true
end

function meta:ResetBoneScales()
    if not IsValid(self) then return false end

    for i = 0, self:GetBoneCount() - 1 do
        self:ManipulateBoneScale(i, Vector(1, 1, 1))
    end
    return true
end

Monarch.Time = Monarch.Time or {}
Monarch.Time.CYCLE_DURATION = Monarch.Time.CYCLE_DURATION or (3600 / 1.5) 
Monarch.Time.ServerTimeOffset = Monarch.Time.ServerTimeOffset or 0

function Monarch.Time.GetFormatted(use24Hour)
    local posInCycle = (CurTime() + (Monarch.Time.ServerTimeOffset or 0)) % Monarch.Time.CYCLE_DURATION
    local totalMinutes = (posInCycle / Monarch.Time.CYCLE_DURATION) * 24 * 60
    local hour = math.floor(totalMinutes / 60)
    local minute = math.floor(totalMinutes % 60)

    if use24Hour then
        return string.format("%02d:%02d", hour, minute)
    else
        local ampm = hour >= 12 and "PM" or "AM"
        local hour12 = hour % 12
        if hour12 == 0 then hour12 = 12 end
        return string.format("%02d:%02d %s", hour12, minute, ampm)
    end
end

function Monarch.Time.GetHour()
    local posInCycle = (CurTime() + (Monarch.Time.ServerTimeOffset or 0)) % Monarch.Time.CYCLE_DURATION
    local totalMinutes = (posInCycle / Monarch.Time.CYCLE_DURATION) * 24 * 60
    return math.floor(totalMinutes / 60)
end

function Monarch.Time.GetMinute()
    local posInCycle = (CurTime() + (Monarch.Time.ServerTimeOffset or 0)) % Monarch.Time.CYCLE_DURATION
    local totalMinutes = (posInCycle / Monarch.Time.CYCLE_DURATION) * 24 * 60
    return math.floor(totalMinutes % 60)
end

function Monarch.Time.GetTime()
    return {
        hour = Monarch.Time.GetHour(),
        minute = Monarch.Time.GetMinute()
    }
end

function Monarch.Time.IsDaytime()
    local hour = Monarch.Time.GetHour()
    return hour >= 6 and hour < 18
end

function Monarch.Time.IsNighttime()
    return not Monarch.Time.IsDaytime()
end

function Monarch.Time.SetCycleDuration(seconds)
    if CLIENT then return false end
    if not isnumber(seconds) or seconds <= 0 then return false end
    Monarch.Time.CYCLE_DURATION = seconds
    return true
end

function Monarch.Time.SetTime(hour, minute)
    if CLIENT then return false end
    if not isnumber(hour) then return false end
    hour = math.Clamp(hour, 0, 23)
    minute = math.Clamp(tonumber(minute) or 0, 0, 59)

    local totalMinutes = hour * 60 + minute
    local desiredPosInCycle = (totalMinutes / (24 * 60)) * Monarch.Time.CYCLE_DURATION

    local currentPosInCycle = CurTime() % Monarch.Time.CYCLE_DURATION
    Monarch.Time.ServerTimeOffset = desiredPosInCycle - currentPosInCycle

    if util and util.AddNetworkString then
        if util.NetworkStringExists then
            if not util.NetworkStringExists("Monarch_SetTime") then
                util.AddNetworkString("Monarch_SetTime")
            end
        else
            util.AddNetworkString("Monarch_SetTime")
        end
    end

    net.Start("Monarch_SetTime")
        net.WriteFloat(Monarch.Time.ServerTimeOffset)
    net.Broadcast()

    return true
end

if SERVER then
    concommand.Add("monarch_settime", function(ply, _, args)
        if IsValid(ply) and not ply:IsAdmin() then return end

        local hour = tonumber(args[1])
        local minute = tonumber(args[2]) or 0

        if hour == nil then
            if IsValid(ply) and ply.Notify then
                ply:Notify("Usage: monarch_settime <hour> [minute]")
            else
                print("Usage: monarch_settime <hour> [minute]")
            end
            return
        end

        hour = math.floor(hour)
        minute = math.floor(minute)

        if hour < 0 or hour > 23 or minute < 0 or minute > 59 then
            if IsValid(ply) and ply.Notify then
                ply:Notify("Time must be within 00:00 to 23:59.")
            else
                print("Time must be within 00:00 to 23:59.")
            end
            return
        end

        Monarch.Time.SetTime(hour, minute)

        local msg = string.format("Set server time to %02d:%02d", hour, minute)
        if IsValid(ply) and ply.Notify then
            ply:Notify(msg)
        else
            print(msg)
        end
    end)
end

function Monarch.Time.GetPeriod()
    local hour = Monarch.Time.GetHour()

    if hour >= 5 and hour < 12 then
        return "Morning"
    elseif hour >= 12 and hour < 17 then
        return "Afternoon"
    elseif hour >= 17 and hour < 21 then
        return "Evening"
    else
        return "Night"
    end
end

function Monarch.Time.RealToGameTime(realSeconds)
    if not isnumber(realSeconds) then return 0 end
    local ratio = (24 * 3600) / Monarch.Time.CYCLE_DURATION
    return realSeconds * ratio
end

function Monarch.Time.GameToRealTime(gameSeconds)
    if not isnumber(gameSeconds) then return 0 end
    local ratio = Monarch.Time.CYCLE_DURATION / (24 * 3600)
    return gameSeconds * ratio
end

if not Monarch.Time.Get then
    function Monarch.Time.Get()
        return Monarch.Time.GetFormatted(false)
    end
end

if CLIENT then
    net.Receive("Monarch_SetTime", function()
        Monarch.Time.ServerTimeOffset = net.ReadFloat()
    end)
end

Monarch.AdminTools = Monarch.AdminTools or {}

function Monarch.AddAdminTool(id, label, onUse, opts)
    opts = opts or {}
    if not id or id == "" then return end

    Monarch.AdminTools[id] = {
        id = id,
        label = label or id,
        onUse = onUse,
        color = opts.color,
        order = opts.order or 0,
    }
end

function Monarch.GetAdminTools()
    local list = {}
    for _, tool in pairs(Monarch.AdminTools) do
        list[#list + 1] = tool
    end
    table.sort(list, function(a, b)
        return (a.order or 0) < (b.order or 0)
    end)
    return list
end