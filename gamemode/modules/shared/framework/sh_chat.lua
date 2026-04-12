Monarch = Monarch or {}
Monarch.ChatCommands = Monarch.ChatCommands or {}
Config = Config or {}

Monarch.ChatDecorators = Monarch.ChatDecorators or {}
Monarch.ChatTypes = Monarch.ChatTypes or {}

function Monarch.RegisterICChatDecorator(id, fn)
    if not id or id == "" or not isfunction(fn) then return end
    Monarch.ChatDecorators[id] = fn
end

function Monarch.BuildICChatDecorations(ply, message)
    local prefix = ""
    local suffix = ""

    for _, fn in pairs(Monarch.ChatDecorators) do
        local ok, p, s = pcall(fn, ply, message)
        if ok then
            if istable(p) then
                local t = p
                p = t.prefix
                s = t.suffix
            end
            if isstring(p) and p ~= "" then prefix = prefix .. p end
            if isstring(s) and s ~= "" then suffix = suffix .. s end
        end
    end

    if prefix == "" and suffix == "" then return nil end
    return prefix, suffix
end

local function NormalizeChatTypeColor(inputColor)
    if not IsColor(inputColor) then
        return Color(255, 255, 255)
    end

    return Color(inputColor.r or 255, inputColor.g or 255, inputColor.b or 255, inputColor.a or 255)
end

function Monarch.RegisterChatType(uniqueID, fontType, textColor, canSeeFn)
    uniqueID = string.lower(string.Trim(tostring(uniqueID or "")))
    if uniqueID == "" then return false, "invalid-id" end

    if istable(fontType) then
        local data = fontType
        fontType = data.FontType or data.fontType or data.Font or data.font or ""
        textColor = data.TextColor or data.textColor or color_white
        canSeeFn = data.CanSee or data.canSee
    end

    if canSeeFn ~= nil and not isfunction(canSeeFn) then
        return false, "invalid-canseefn"
    end

    Monarch.ChatTypes[uniqueID] = {
        UniqueID = uniqueID,
        FontType = tostring(fontType or ""),
        TextColor = NormalizeChatTypeColor(textColor or color_white),
        CanSee = canSeeFn or function(_, _, _, _)
            return true
        end
    }

    return true, Monarch.ChatTypes[uniqueID]
end

function Monarch.GetChatType(uniqueID)
    uniqueID = string.lower(string.Trim(tostring(uniqueID or "")))
    if uniqueID == "" then return nil end
    return Monarch.ChatTypes[uniqueID]
end

function Monarch.SendChatMessage(chatType, message)
    local resolvedType = Monarch.GetChatType(chatType)
    if not resolvedType then
        return false, "unknown-chat-type"
    end

    local text = tostring(message or "")

    if SERVER then
        local recipients = player.GetAll()
        return Monarch.SendChatType(chatType, nil, color_white, "", color_white, "", text, recipients)
    end

    if resolvedType.FontType and resolvedType.FontType ~= "" and Monarch.ChatAddTextWithFont then
        Monarch.ChatAddTextWithFont(resolvedType.FontType, resolvedType.TextColor or color_white, text)
    else
        chat.AddText(resolvedType.TextColor or color_white, text)
    end

    return true
end

if SERVER then
    function Monarch.GetChatTypeRecipients(uniqueID, speaker, message, context)
        local chatType = Monarch.GetChatType(uniqueID)
        if not chatType then
            return IsValid(speaker) and {speaker} or {}
        end

        local recipients = {}
        for _, listener in player.Iterator() do
            if not IsValid(listener) then continue end

            local ok, canSee = pcall(chatType.CanSee, listener, speaker, message, context or {})
            if ok and canSee then
                recipients[#recipients + 1] = listener
            end
        end

        if #recipients == 0 and IsValid(speaker) then
            recipients[1] = speaker
        end

        return recipients
    end

    function Monarch.SendChatType(uniqueID, speaker, prefixColor, prefix, userColor, userData, message, recipients)
        local chatType = Monarch.GetChatType(uniqueID)
        if not chatType then return false, "unknown-chat-type" end

        net.Start("BroadcastChatMessage")
            net.WriteColor(prefixColor or color_white)
            net.WriteString(prefix or "")
            net.WriteColor(userColor or color_white)
            net.WriteString(userData or "")
            net.WriteString(tostring(message or ""))
            net.WriteColor(chatType.TextColor or color_white)
            net.WriteString(chatType.FontType or "")
        net.Send(recipients or {})

        return true
    end
end

local convars = {
    showDead = {"chatrankprefix_showdead", "1", FCVAR_REPLICATED, "Show the *DEAD* text?"},
    showRank = {"chatrankprefix_showrank", "1", FCVAR_REPLICATED, "Show teams?"},
    useTeamColor = {"chatrankprefix_userankcolor", "1", FCVAR_REPLICATED, "Use team colors for the player name?"},
    enabled = {"chatrankprefix_enabled", "1", FCVAR_REPLICATED, "Enable chat rank prefixes?"}
}

Config.LOOCCooldown = Config.LOOCCooldown or 15
local MAX_ME_ACTION_LENGTH = 80
local MAX_SPEECH_PREVIEW_LENGTH = 30

local function TruncateMEAction(text)
    text = string.Trim(tostring(text or ""))
    if #text <= MAX_ME_ACTION_LENGTH then return text end
    return string.sub(text, 1, MAX_ME_ACTION_LENGTH) .. "..."
end

local function TruncateSpeechPreview(text)
    text = string.Trim(tostring(text or ""))
    if #text <= MAX_SPEECH_PREVIEW_LENGTH then return text end
    return string.sub(text, 1, MAX_SPEECH_PREVIEW_LENGTH) .. "..."
end

if CLIENT then
    surface.CreateFont("Monarch_LOOCChatFont", {
        font = "Din Pro Medium",
        size = 16,
        weight = 500,
        shadow = true,
        antialias = true
    })

    surface.CreateFont("Monarch_ME3D2D", {
        font = "Din Pro Bold",
        size = 45,
        weight = 800,
        antialias = true,
        extended = true
    })

    surface.CreateFont("Monarch_Speech3D2D", {
        font = "Din Pro Medium",
        size = 56,
        weight = 700,
        antialias = true,
        extended = true
    })
end

if SERVER then
    AddCSLuaFile()

    for _, convar in pairs(convars) do
        CreateConVar(unpack(convar))
    end

    util.AddNetworkString("Monarch_BRING")
    util.AddNetworkString("Monarch_GOTO")
    util.AddNetworkString("Monarch_Respawn")
    util.AddNetworkString("Monarch_AdminForceIntroduce")
    util.AddNetworkString("BroadcastChatMessage")
    util.AddNetworkString("Monarch_LOOC")
    util.AddNetworkString("Monarch_Yell")
    util.AddNetworkString("Monarch_Whisper")
    util.AddNetworkString("Monarch_ME_Display")
    util.AddNetworkString("Monarch_ME_Send")
    util.AddNetworkString("Monarch_SpeechStatus_Send")
    util.AddNetworkString("Monarch_SpeechStatus")
    util.AddNetworkString("MonarchInventorySync")
    util.AddNetworkString("MonarchInventorySyncServer")
    util.AddNetworkString("MonarchInventorySyncClient")
    util.AddNetworkString("Monarch_SetCharWhitelist")
    util.AddNetworkString("Monarch_SetTime")

    Monarch.RegisterChatType(
        "looc",
        "Monarch-Small",
        Color(255, 255, 255),
        function(listener, speaker, _, context)
            if not IsValid(listener) or not IsValid(speaker) then return false end
            local radius = tonumber(context and context.radius) or (Config and Config.LOOCRadius) or 400
            return listener:GetPos():DistToSqr(speaker:GetPos()) <= (radius * radius)
        end
    )

    Monarch.RegisterChatType(
        "yell",
        "Monarch-Large",
        Color(255, 220, 0, 255),
        function(listener, speaker)
            if not IsValid(listener) or not IsValid(speaker) then return false end
            local radius = 800
            return listener:GetPos():DistToSqr(speaker:GetPos()) <= (radius * radius)
        end
    )

    Monarch.RegisterChatType(
        "whisper",
        "Monarch-Small",
        Color(255, 220, 0, 255),
        function(listener, speaker)
            if not IsValid(listener) or not IsValid(speaker) then return false end
            local radius = 150
            return listener:GetPos():DistToSqr(speaker:GetPos()) <= (radius * radius)
        end
    )

    Monarch.RegisterChatType(
        "me",
        "Monarch-Normal",
        Color(255, 150, 150),
        function(listener, speaker)
            if not IsValid(listener) or not IsValid(speaker) then return false end
            local radius = 400
            return listener:GetPos():DistToSqr(speaker:GetPos()) <= (radius * radius)
        end
    )

    hook.Add("PlayerSay", "Monarch_ICChatDecorate", function(ply, text)
        if not isstring(text) then return end
        local firstChar = text:sub(1, 1)
        if firstChar == "!" or firstChar == "/" then return end

        if Monarch and Monarch.Voice and Monarch.Voice.ProcessChatMessage then
            local outMessage = select(1, Monarch.Voice.ProcessChatMessage(ply, text, "say"))
            if isstring(outMessage) and outMessage ~= "" then
                text = outMessage
            end
        end

        local prefix, suffix = Monarch.BuildICChatDecorations(ply, text)
        if prefix or suffix then
            return (prefix or "") .. text .. (suffix or "")
        end

        return text
    end)

    local function BroadcastSpeechState(ply, isTyping, text)
        if not IsValid(ply) then return end

        local RADIUS = 400
        local rsq = RADIUS * RADIUS
        local origin = ply:GetPos()
        local recips = {}
        for _, v in player.Iterator() do
            if IsValid(v) and v:GetPos():DistToSqr(origin) <= rsq then
                table.insert(recips, v)
            end
        end
        if #recips == 0 then recips = {ply} end

        net.Start("Monarch_SpeechStatus")
            net.WriteEntity(ply)
            net.WriteBool(isTyping)
            net.WriteString(text or "")
        net.Send(recips)
    end

    net.Receive("Monarch_SpeechStatus_Send", function(_, ply)
        if not IsValid(ply) then return end

        local isTyping = net.ReadBool()
        local rawText = string.Trim(net.ReadString() or "")
        local firstChar = rawText:sub(1, 1)

        if rawText == "" or firstChar == "!" or firstChar == "/" then
            BroadcastSpeechState(ply, false, "")
            return
        end

        BroadcastSpeechState(ply, isTyping and true or false, "")
    end)

    hook.Add("PlayerSay", "Monarch_SpeechPreview", function(ply, text)
        if not IsValid(ply) or not isstring(text) then return end
        text = string.Trim(text)
        if text == "" then return end

        local firstChar = text:sub(1, 1)
        if firstChar == "!" or firstChar == "/" then
            return
        end

        BroadcastSpeechState(ply, false, TruncateSpeechPreview(text))
    end)
    net.Receive("Monarch_BRING", function(_, admin)
        if not IsValid(admin) or not admin:IsAdmin() then return end
        local target = net.ReadEntity()
        if not IsValid(target) or not target:IsPlayer() or target == admin then return end

        local basePos = admin:GetPos()
        local forward = admin:GetForward()
        local tryPositions = {
            basePos + forward * 60,
            basePos - forward * 60,
            basePos + admin:GetRight() * 60,
            basePos - admin:GetRight() * 60,
            basePos + Vector(0,0,60)
        }

        local dest = tryPositions[1]
        for _, pos in ipairs(tryPositions) do
            local tr = util.TraceHull({
                start = pos,
                endpos = pos,
                mins = Vector(-16,-16,0),
                maxs = Vector(16,16,72),
                filter = {admin, target}
            })
            if not tr.Hit then
                dest = pos
                break
            end
        end

        if target:InVehicle() then
            local veh = target:GetVehicle()
            if IsValid(veh) then veh:Remove() end
        end

        target:SetPos(dest)
        target:SetLocalVelocity(Vector(0,0,0))
    end)

    net.Receive("Monarch_GOTO", function(_, admin)
        if not IsValid(admin) or not admin:IsAdmin() then return end
        local dest = net.ReadVector()
        if not dest or dest == vector_origin then return end
        if not admin:Alive() then admin:Spawn() end
        admin:SetPos(dest)
        if admin.Notify then admin:Notify("Teleported.") end
    end)

    net.Receive("Monarch_AdminForceIntroduce", function(_, admin)
        if not IsValid(admin) or not admin:IsAdmin() then return end
        local target = net.ReadEntity()
        local name = string.Trim(net.ReadString() or "")
        if not IsValid(target) or target == admin or name == "" then return end
        net.Start("Monarch_UpdateIntroductions")
            net.WriteEntity(target)
            net.WriteString(name)
        net.Send(admin)
    end)

    net.Receive("Monarch_Respawn", function(_, admin)
        if not IsValid(admin) or not admin:IsAdmin() then return end
        local target = net.ReadEntity()
        if not IsValid(target) or not target:IsPlayer() then return end

        if target:Alive() then
            if admin.Notify then admin:Notify(target:Nick() .. " is already alive.") end
            return
        end

        target.respawnWait = nil
        local deathCharID = target._monarchDeathCharID or target.MonarchLastCharID
        if deathCharID then
            target.MonarchLastCharID = deathCharID
        end

        target:Spawn()

        if deathCharID and Monarch and Monarch.CharSystem and Monarch.CharSystem.LoadCharacterByID then
            timer.Simple(0, function()
                if IsValid(target) then
                    Monarch.CharSystem.LoadCharacterByID(target, deathCharID)
                end
            end)
        end

        if admin.Notify then admin:Notify("Respawned " .. target:Nick() .. ".") end
        if target.Notify then target:Notify("An administrator respawned you.") end
    end)

    net.Receive("Monarch_LOOC", function(_, ply)
        if not IsValid(ply) then return end
        local msg = string.Trim(net.ReadString() or "")
        if msg == "" then return end

        local now = CurTime()
        local cd = tonumber(Config.LOOCCooldown) or 15
        ply._monarchNextLOOC = ply._monarchNextLOOC or 0
        if now < ply._monarchNextLOOC then
            local wait = math.ceil(ply._monarchNextLOOC - now)
            if ply.Notify then ply:Notify("LOOC is on cooldown. Wait "..wait.."s.") end
            return
        end
        ply._monarchNextLOOC = now + cd

        local RADIUS = (Config and Config.LOOCRadius) or 400
        local recips = Monarch.GetChatTypeRecipients("looc", ply, msg, {radius = RADIUS})

        local prefixColor = Color(255,100,100)
        local userColor = Color(255,255,255)
        local prefix =  "(LOOC) "
        local userData = (ply:Nick()) .. ": "

        Monarch.SendChatType("looc", ply, prefixColor, prefix, userColor, userData, msg, recips)
    end)

    net.Receive("Monarch_Yell", function(_, ply)
        if not IsValid(ply) then return end
        local msg = string.Trim(net.ReadString() or "")
        if msg == "" then return end

        local recips = Monarch.GetChatTypeRecipients("yell", ply, msg)

        if Monarch and Monarch.Voice and Monarch.Voice.ProcessChatMessage then
            local outMessage = select(1, Monarch.Voice.ProcessChatMessage(ply, msg, "yell", recips))
            if isstring(outMessage) and outMessage ~= "" then
                msg = outMessage
            end
        end

        local lastChar = string.sub(msg, -1)
        if not string.find(lastChar, "[.!?]") then
            msg = msg .. "!"
        end

        msg = "yells \"" .. msg .. "\""

        local prefixColor = Color(255,100,100)
        local userColor = Color(170,170,200)
        local prefix =  ""
        local userData = (ply:GetRPName()) .. " "

        Monarch.SendChatType("yell", ply, prefixColor, prefix, userColor, userData, msg, recips)
    end)

    net.Receive("Monarch_Whisper", function(_, ply)
        if not IsValid(ply) then return end
        local msg = string.Trim(net.ReadString() or "")
        if msg == "" then return end

        local recips = Monarch.GetChatTypeRecipients("whisper", ply, msg)

        if Monarch and Monarch.Voice and Monarch.Voice.ProcessChatMessage then
            local outMessage = select(1, Monarch.Voice.ProcessChatMessage(ply, msg, "whisper", recips))
            if isstring(outMessage) and outMessage ~= "" then
                msg = outMessage
            end
        end

        local lastChar = string.sub(msg, -1)
        if not string.find(lastChar, "[.!?]") then
            msg = msg .. "."
        end

        msg = "whispers \"" .. msg .. "\""

        local prefixColor = Color(255,100,100)
        local userColor = Color(170,170,200)
        local prefix =  ""
        local userData = (ply:GetRPName()) .. " "

        Monarch.SendChatType("whisper", ply, prefixColor, prefix, userColor, userData, msg, recips)
    end)

    net.Receive("Monarch_ME_Send", function(_, ply)
        if not IsValid(ply) then return end
        local action = string.Trim(net.ReadString() or "")
        if action == "" then return end

        local recips = Monarch.GetChatTypeRecipients("me", ply, action)

        local prefixColor = Color(255, 150, 150)
        local userColor = Color(255, 150, 150)
        local prefix = "*** "
        local displayName = (ply.GetRPName and ply:GetRPName()) or ply:Nick()
        local userData = displayName .. " "

        Monarch.SendChatType("me", ply, prefixColor, prefix, userColor, userData, action, recips)

        net.Start("Monarch_ME_Display")
            net.WriteEntity(ply)
            net.WriteString(action)
        net.Send(recips)
    end)

    net.Receive("Monarch_SetCharWhitelist", function(_, admin)
        if not IsValid(admin) or not admin:IsAdmin() then return end
        local target = net.ReadEntity()
        local teamID = net.ReadUInt(16)
        local level = net.ReadUInt(16)
        if not IsValid(target) or not target:IsPlayer() then return end
        if teamID <= 0 then if admin.Notify then admin:Notify("Invalid team ID") end return end
        if level < 0 then level = 0 end

        if Monarch_SetWhitelistNW then
            Monarch_SetWhitelistNW(target, teamID, level)
            if admin.Notify then admin:Notify("Set whitelist level "..level.." for team "..teamID.." on "..(target.GetRPName and target:GetRPName() or target:Nick())) end
            if target.Notify then target:Notify("Your whitelist for team "..teamID.." is now level "..level) end
        else
            if admin.Notify then admin:Notify("ERROR: Whitelist system not initialized!") end
        end
    end)
end

local lastLOOCTime = 0

local registeredCommands = {}

local function CanUseLOOC()
    local currentTime = CurTime()
    return currentTime - lastLOOCTime >= Config.LOOCCooldown
end

local function GetLOOCTimeRemaining()
    local currentTime = CurTime()
    local timeRemaining = Config.LOOCCooldown - (currentTime - lastLOOCTime)
    return math.max(0, timeRemaining)
end

local function IsPlayerNearby(ply1, ply2)
    if not IsValid(ply1) or not IsValid(ply2) then return false end
    local dist = ply1:GetPos():Distance(ply2:GetPos())
    return dist <= chatRadius
end

local clr = {
    RPColorG = Color(255,255,255),
    RPColorY = Color(200, 180, 70),
    RPColorW = Color(200, 180, 255),
    white = Color(255, 255, 255),
    gray = Color(170,170,170),
    bezevii = Color(255,150,150),
    yellow = Color(255,170,0),
    red = Color(255, 50, 100),
    blue = Color(255,255,255),
    green = Color(50, 255, 100)
}

local function ParseArguments(text, expectedTypes)
    local args = {}
    local argString = string.Trim(text)

    if argString == "" then
        return args
    end

    local inQuotes = false
    local currentArg = ""
    local i = 1

    while i <= #argString do
        local char = argString:sub(i, i)

        if char == '"' then
            inQuotes = not inQuotes
        elseif char == ' ' and not inQuotes then
            if currentArg ~= "" then
                table.insert(args, currentArg)
                currentArg = ""
            end
        else
            currentArg = currentArg .. char
        end

        i = i + 1
    end

    if currentArg ~= "" then
        table.insert(args, currentArg)
    end

    if expectedTypes then
        for i, argType in ipairs(expectedTypes) do
            if args[i] then
                if argType == "number" then
                    args[i] = tonumber(args[i])
                elseif argType == "boolean" then
                    args[i] = string.lower(args[i]) == "true" or args[i] == "1"
                elseif argType == "player" then
                    local found = Monarch.FindPlayer(args[i])
                    args[i] = found and found[1] or nil
                end
            end
        end
    end

    return args
end

function Monarch.RegisterChatCommand(command, config)
    local cmd = {
        name = command,
        aliases = config.aliases or {},
        adminOnly = config.adminOnly or false,
        hideMessage = config.hideMessage ~= false,
        description = config.description or "No description",
        usage = config.usage or command,
        minArgs = config.minArgs or 0,
        maxArgs = config.maxArgs or math.huge,
        argTypes = config.argTypes or {},
        cooldown = config.cooldown or 0,
        callback = config.callback,
        lastUsed = {},
        outputFont = config.outputFont 
    }
    registeredCommands[command] = cmd
    for _, alias in ipairs(cmd.aliases) do
        registeredCommands[alias] = cmd
    end
    Monarch.ChatCommands.registeredCommands = registeredCommands
    hook.Run("MonarchChatCommandRegistered", cmd)
end

local function ValidateCommand(ply, cmd, args)
    if cmd.adminOnly and not ply:IsAdmin() then
        ply:Notify("You don't have permission to use this command!")
        return false
    end

    if #args < cmd.minArgs then
        ply:Notify("Usage: " .. cmd.usage)
        return false
    end

    if #args > cmd.maxArgs then
        ply:Notify("Too many arguments! Usage: " .. cmd.usage)
        return false
    end

    if cmd.cooldown > 0 then
        local lastUsed = cmd.lastUsed[ply:SteamID()] or 0
        local timePassed = CurTime() - lastUsed

        if timePassed < cmd.cooldown then
            local remaining = math.ceil(cmd.cooldown - timePassed)
            ply:Notify("Command on cooldown! Wait " .. remaining .. " more second(s).")
            return false
        end

        cmd.lastUsed[ply:SteamID()] = CurTime()
    end

    return true
end

hook.Add("OnPlayerChat", "Monarch_ChatCommands", function(ply, strText, bTeam, bDead)
    if ply ~= LocalPlayer() then return end

    local text = string.Trim(strText)
    local firstChar = text:sub(1, 1)

    if firstChar ~= "!" and firstChar ~= "/" then
        return
    end

    local spacePos = text:find(" ")
    local command, argText

    if spacePos then
        command = text:sub(1, spacePos - 1)
        argText = text:sub(spacePos + 1)
    else
        command = text
        argText = ""
    end

    command = string.lower(command)

    local cmd = registeredCommands[command]
    if not cmd then
        return print("Chat command not found:", command)
    end

    local args = ParseArguments(argText, cmd.argTypes)

    if not ValidateCommand(ply, cmd, args) then
        return cmd.hideMessage
    end

    local success, err = pcall(cmd.callback, ply, args)
    if not success then
        ply:Notify("Command error: " .. tostring(err))
        print("Chat command error:", err)
    end

    return cmd.hideMessage
end)

function Monarch.AddChatCommand(listener, takeArgs, adminRestricted, shouldHideMessage, callback)
    Monarch.RegisterChatCommand(listener, {
        adminOnly = adminRestricted,
        hideMessage = shouldHideMessage,
        callback = function(ply, args)
            if takeArgs then
                callback(ply, table.concat(args, " "))
            else
                callback(ply, "")
            end
        end
    })
end

function Monarch.isEmpty(vector, ignore)
    ignore = ignore or {}

    local point = util.PointContents(vector)
    local a = point ~= CONTENTS_SOLID
        and point ~= CONTENTS_MOVEABLE
        and point ~= CONTENTS_LADDER
        and point ~= CONTENTS_PLAYERCLIP
        and point ~= CONTENTS_MONSTERCLIP
    if not a then return false end

    local b = true

    for _, v in ipairs(ents.FindInSphere(vector, 35)) do
        if (v:IsNPC() or v:IsPlayer() or v:GetClass() == "prop_physics" or v.NotEmptyPos) and not table.HasValue(ignore, v) then
            b = false
            break
        end
    end

    return a and b
end

function Monarch.findEmptyPos(pos, ignore, distance, step, area)
    if Monarch.isEmpty(pos, ignore) and Monarch.isEmpty(pos + area, ignore) then
        return pos
    end

    for j = step, distance, step do
        for i = -1, 1, 2 do
            local k = j * i

            if Monarch.isEmpty(pos + Vector(k, 0, 0), ignore) and Monarch.isEmpty(pos + Vector(k, 0, 0) + area, ignore) then
                return pos + Vector(k, 0, 0)
            end

            if Monarch.isEmpty(pos + Vector(0, k, 0), ignore) and Monarch.isEmpty(pos + Vector(0, k, 0) + area, ignore) then
                return pos + Vector(0, k, 0)
            end

            if Monarch.isEmpty(pos + Vector(0, 0, k), ignore) and Monarch.isEmpty(pos + Vector(0, 0, k) + area, ignore) then
                return pos + Vector(0, 0, k)
            end
        end
    end

    return pos
end

function Monarch.FindPlayer(info)
    if not info then return nil end
    local pls = player.GetAll()
    local found = {}

    if string.lower(info) == "*" or string.lower(info) == "<all>" then return pls end

    local InfoPlayers = {}
    for A in string.gmatch(info .. ";", "([a-zA-Z0-9:_.]*)[;(,%s)%c]") do
        if A ~= "" then
            table.insert(InfoPlayers, A)
        end
    end

    for _, PlayerInfo in ipairs(InfoPlayers) do
        if tonumber(PlayerInfo) then
            if IsValid(Player(PlayerInfo)) and not found[Player(PlayerInfo)] then
                found[Player(PlayerInfo)] = true
            end
            continue
        end

        for _, v in ipairs(pls) do
            if (PlayerInfo == v:SteamID() or v:SteamID() == "UNKNOWN") and not found[v] then
                found[v] = true
            end

            if string.find(string.lower(v:Nick()), string.lower(tostring(PlayerInfo)), 1, true) ~= nil and not found[v] then
                found[v] = true
            end

            if v.SteamName and string.find(string.lower(v:SteamName()), string.lower(tostring(PlayerInfo)), 1, true) ~= nil and not found[v] then
                found[v] = true
            end
        end
    end

    local players = {}
    local empty = true
    for k in pairs(found or {}) do
        empty = false
        table.insert(players, k)
    end
    return not empty and players or nil
end

if CLIENT then
    local meDisplayByPlayer = meDisplayByPlayer or {}
    local ME_DISPLAY_DURATION = 10
    local ME_DISPLAY_MAX_DIST_SQR = 750 * 750
    local speechDisplayByPlayer = speechDisplayByPlayer or {}
    local SPEECH_PREVIEW_DURATION = 4
    local SPEECH_MAX_DIST_SQR = 750 * 750

    net.Receive("Monarch_SpeechStatus", function()
        local target = net.ReadEntity()
        local isTyping = net.ReadBool()
        local message = string.Trim(net.ReadString() or "")
        if not IsValid(target) then return end

        if isTyping then
            speechDisplayByPlayer[target] = {
                text = "Speaking...",
                isTyping = true,
                expiresAt = 0
            }
            return
        end

        if message ~= "" then
            speechDisplayByPlayer[target] = {
                text = TruncateSpeechPreview(message),
                isTyping = false,
                expiresAt = CurTime() + SPEECH_PREVIEW_DURATION
            }
        else
            local existing = speechDisplayByPlayer[target]
            if not (existing and not existing.isTyping and existing.expiresAt and existing.expiresAt > CurTime()) then
                speechDisplayByPlayer[target] = nil
            end
        end
    end)

    do
        local lastTypingState = false
        local lastTypingText = ""
        local nextTypingUpdate = 0

        local function SendTypingState(isTyping, text, force)
            text = tostring(text or "")
            if not force and CurTime() < nextTypingUpdate and isTyping == lastTypingState and text == lastTypingText then
                return
            end

            lastTypingState = isTyping
            lastTypingText = text
            nextTypingUpdate = CurTime() + 0.1

            net.Start("Monarch_SpeechStatus_Send")
                net.WriteBool(isTyping)
                net.WriteString(text)
            net.SendToServer()
        end

        hook.Add("StartChat", "Monarch_Speech_StartChat", function()
            SendTypingState(true, "", true)
        end)

        hook.Add("FinishChat", "Monarch_Speech_FinishChat", function()
            SendTypingState(false, "", true)
        end)

        hook.Add("ChatTextChanged", "Monarch_Speech_TextChanged", function(text)
            local trimmed = string.Trim(text or "")
            if trimmed == "" then
                SendTypingState(false, "", false)
                return
            end

            SendTypingState(true, trimmed, false)
        end)
    end

    net.Receive("Monarch_ME_Display", function()
        local target = net.ReadEntity()
        local action = TruncateMEAction(net.ReadString() or "")
        if not IsValid(target) or action == "" then return end

        meDisplayByPlayer[target] = {
            action = action,
            expiresAt = CurTime() + ME_DISPLAY_DURATION
        }
    end)

    hook.Add("PostPlayerDraw", "Monarch_ME_3D2D", function(ply)
        local localPlayer = LocalPlayer()
        if not IsValid(localPlayer) then return end
        if not IsValid(ply) or not ply:Alive() then return end

        local displayData = meDisplayByPlayer[ply]
        if not displayData then return end

        if CurTime() >= displayData.expiresAt then
            meDisplayByPlayer[ply] = nil
            return
        end

        if localPlayer:GetPos():DistToSqr(ply:GetPos()) > ME_DISPLAY_MAX_DIST_SQR then
            return
        end

        local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
        local chestLocal = Vector((mins.x + maxs.x) * 0.5, (mins.y + maxs.y) * 0.5, mins.z + (maxs.z - mins.z) * 0.55)
        local halfWidth = math.max((maxs.x - mins.x) * 0.5, (maxs.y - mins.y) * 0.5)

        local drawPos = ply:LocalToWorld(chestLocal) + ply:GetForward() * math.max(halfWidth - 6, 0)
        local drawAng = Angle(0, ply:EyeAngles().y - 90, 90)

        local alpha = math.Clamp((displayData.expiresAt - CurTime()) * 255, 0, 255)

        cam.Start3D2D(drawPos, drawAng, 0.05)
            draw.SimpleTextOutlined(
                "***" .. displayData.action,
                "Monarch_ME3D2D",
                0,
                0,
                Color(253, 253, 150, alpha),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                Color(20, 20, 20, alpha)
            )
        cam.End3D2D()
    end)

    hook.Add("PostPlayerDraw", "Monarch_Speech_3D2D", function(ply)
        local localPlayer = LocalPlayer()
        if not IsValid(localPlayer) then return end
        if not IsValid(ply) or not ply:Alive() then return end

        local speechData = speechDisplayByPlayer[ply]
        if not speechData then return end

        if not speechData.isTyping and speechData.expiresAt > 0 and CurTime() >= speechData.expiresAt then
            speechDisplayByPlayer[ply] = nil
            return
        end

        if localPlayer:GetPos():DistToSqr(ply:GetPos()) > SPEECH_MAX_DIST_SQR then
            return
        end

        local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
        local drawPos = ply:GetPos() + Vector(2,0, maxs.z + 1)

        local drawAng = Angle(0, ply:EyeAngles().y - 90, 90)

        local alpha = speechData.isTyping and 210 or math.Clamp((speechData.expiresAt - CurTime()) * 255, 0, 255)
        local textColor = speechData.isTyping and Color(210, 210, 210, alpha) or Color(255, 255, 255, alpha)

        cam.Start3D2D(drawPos, drawAng, 0.04)
            draw.SimpleTextOutlined(
                speechData.text,
                "Monarch_Speech3D2D",
                0,
                0,
                textColor,
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_CENTER,
                2,
                Color(10, 10, 10, alpha)
            )
        cam.End3D2D()
    end)

    net.Receive("BroadcastChatMessage", function(len, ply)
        local prefixColor = net.ReadColor()
        local prefix = net.ReadString()
        local userColor = net.ReadColor()
        local userData = net.ReadString()
        local msg = net.ReadString()
        local chatColor = net.ReadColor()
        local fontName = net.ReadString()

        if fontName and fontName ~= "" then
            Monarch.ChatAddTextWithFont(fontName, prefixColor, prefix, userColor, userData, chatColor, msg)
        else
            chat.AddText(prefixColor, prefix, userColor, userData, chatColor, msg)
        end
    end)

    Monarch.RegisterChatCommand("/looc", {
        aliases = {"//"},
        hideMessage = true,
        description = "Local OOC chat",
        usage = "/looc <message>",
        minArgs = 1,
        cooldown = Config.LOOCCooldown,
        callback = function(ply, args)
            local message = table.concat(args, " ")
            if not CanUseLOOC() then
                local remaining = math.ceil(GetLOOCTimeRemaining())
                if ply.Notify then ply:Notify("LOOC on cooldown: "..remaining.."s") end
                return
            end
            net.Start("Monarch_LOOC")
                net.WriteString(message)
            net.SendToServer()
            lastLOOCTime = CurTime()
        end
    })

    Monarch.RegisterChatCommand("/yell", {
        aliases = {"!yell", "/y", "!y"},
        hideMessage = true,
        description = "Yell so people far away can hear you",
        usage = "/yell <message>",
        minArgs = 1,
        callback = function(ply, args)
            local message = table.concat(args, " ")
            net.Start("Monarch_Yell")
                net.WriteString(message)
            net.SendToServer()
        end
    })

    Monarch.RegisterChatCommand("/whisper", {
        aliases = {"!whisper", "/w", "!w"},
        hideMessage = true,
        description = "Whisper quietly so only nearby people hear you",
        usage = "/whisper <message>",
        minArgs = 1,
        callback = function(ply, args)
            local message = table.concat(args, " ")
            net.Start("Monarch_Whisper")
                net.WriteString(message)
            net.SendToServer()
        end
    })

    Monarch.RegisterChatCommand("/introduce", {
        aliases = {"!introduce"},
        adminOnly = true,
        description = "Force learn a player's name (introduce them to you)",
        usage = "/introduce <player> [name override]",
        minArgs = 1,
        callback = function(ply, args)
            local targetIdent = args[1]
            local targets = Monarch.FindPlayer(targetIdent)
            local target = targets and targets[1]
            if not IsValid(target) then
                ply:Notify("Player not found.")
                return
            end
            if target == ply then
                ply:Notify("Cannot use on yourself.")
                return
            end

            local learnedName
            if #args > 1 then
                learnedName = table.concat(args, " ", 2)
            else
                learnedName = (target.GetRPName and target:GetRPName())
            end
            if not learnedName or learnedName == "" then
                ply:Notify("Invalid name.")
                return
            end

            net.Start("Monarch_AdminForceIntroduce")
                net.WriteEntity(target)
                net.WriteString(learnedName)
            net.SendToServer()

            ply:Notify("You have learned "..target:Nick().."'s name as '"..learnedName.."'.")
        end
    })

    Monarch.RegisterChatCommand("/report", {
        aliases = {"!report"},
        adminOnly = true,
        description = "Make a ticket for staff to help you.",
        usage = "/report",
        minArgs = 0,
        callback = function(ply, args)
            concommand.Run(ply, "monarch_ticket")
        end
    })

    Monarch.RegisterChatCommand("!bring", {
        adminOnly = true,
        description = "Teleport a player to your position",
        usage = "!bring <player>",
        minArgs = 1,
        argTypes = {"player"},
        callback = function(ply, args)
            local target = args[1]
            if not IsValid(target) then
                ply:Notify("Player not found!")
                return
            end
            if target == ply then
                ply:Notify("Cannot bring yourself.")
                return
            end
            net.Start("Monarch_BRING")
                net.WriteEntity(target)
            net.SendToServer()
            ply:Notify("Bringing "..target:Nick().."...")
        end
    })

    Monarch.RegisterChatCommand("!respawn", {
        adminOnly = true,
        description = "Respawn a dead player",
        usage = "!respawn <player>",
        minArgs = 1,
        argTypes = {"player"},
        callback = function(ply, args)
            local target = args[1]
            if not IsValid(target) then
                ply:Notify("Player not found!")
                return
            end
            if target:Alive() then
                ply:Notify(target:Nick() .. " is already alive.")
                return
            end
            net.Start("Monarch_Respawn")
                net.WriteEntity(target)
            net.SendToServer()
        end
    })

    Monarch.RegisterChatCommand("!setname", {
        adminOnly = true,
        aliases = {"/charsetname", "!charsetname", "/setname"},
        description = "Set a player's character name (NOT PERMANENT)",
        usage = "!setname <player> <new name...>",
        minArgs = 2,
        argTypes = {"player"},
        callback = function(ply, args)
            local target = args[1]
            if not IsValid(target) then
                ply:Notify("Player not found!")
                return
            end
            if #args < 2 then
                ply:Notify("Usage: !setname <player> <new name...>")
                return
            end
            local newName = string.Trim(table.concat(args, " ", 2))
            if newName == "" then
                ply:Notify("Invalid name.")
                return
            end
            if #newName > 64 then
                ply:Notify("Name too long (64 char max).")
                return
            end
            ply:Notify("Renaming "..(target.GetRPName and target:GetRPName() or target:Nick()).." to '"..newName.."'.")
            net.Start("Monarch_SetRPName")
                net.WriteEntity(target)
                net.WriteString(newName)
            net.SendToServer()
        end
    })

    Monarch.RegisterChatCommand("!setmodel", {
        adminOnly = true,
        aliases = {"/charsetmodel", "/setmodel"},
        description = "Set a player's character model (NOT PERMANENT)",
        usage = "!setmodel <player> <model_path>",
        minArgs = 2,
        argTypes = {"player", "model"},
        callback = function(ply, args)
            local target = args[1]
            local model = args[2]
            if not IsValid(target) then
                ply:Notify("No Player Found!")
            end

            net.Start("Monarch_SetModel")
                net.WriteEntity(target)
                net.WriteString(model)
            net.SendToServer()

            LocalPlayer():Notify("You have set "..target:GetRPName().."'s model to "..model)
        end
    })

    Monarch.RegisterChatCommand("!goto", {
        adminOnly = true,
        description = "Teleport to a player",
        usage = "!goto <player>",
        minArgs = 1,
        argTypes = {"player"},
        callback = function(ply, args)
            local target = args[1]
            if not IsValid(target) then
                ply:Notify("Player not found!")
                return
            end

            if not ply:Alive() then ply:Spawn() end

            local targetPos = target:GetPos()
            local newPos = Vector(targetPos.x + 25, targetPos.y, targetPos.z)

            net.Start("Monarch_GOTO")
                net.WriteVector(newPos)
            net.SendToServer()
        end
    })

    Monarch.RegisterChatCommand("!setteam", {
        adminOnly = true,
        aliases = {"/charsetteam", "/setteam", "!charsetteam"},
        description = "Set a player's team",
        usage = "!setteam <player> <team_id>",
        minArgs = 2,
        argTypes = {"player", "number"},
        callback = function(ply, args)
            local target, teamID = args[1], args[2]

            if not IsValid(target) then
                ply:Notify("Player not found!")
                return
            end

            if not teamID or teamID < 1 then
                ply:Notify("Invalid team ID!")
                return
            end

            if teamID > #Monarch.Team then
                ply:Notify("This team does not exist!")
                return
            end

            ply:Notify("You have set "..target:Nick().." to team "..Monarch.Team[teamID].name)

            net.Start("MonarchSelectTeam")
                net.WriteUInt(teamID, 8)
                net.WriteEntity(target)
            net.SendToServer()
        end
    })

    Monarch.RegisterChatCommand("!settime", {
        adminOnly = true,
        aliases = {"/settime"},
        description = "Set the server game time (0-23)",
        usage = "!settime <hour>",
        minArgs = 1,
        maxArgs = 1,
        argTypes = {"number"},
        callback = function(ply, args)
            local hour = args[1]

            if not hour then
                ply:Notify("Invalid hour!")
                return
            end

            hour = math.floor(hour)

            if hour < 0 or hour > 23 then
                ply:Notify("Hour must be between 0 and 23!")
                return
            end

            net.Start("Monarch_SetTime")
                net.WriteUInt(hour, 8)
            net.SendToServer()

            ply:Notify("Set server time to " .. hour .. ":00")
        end
    })

    Monarch.RegisterChatCommand("/setcharwhitelist", {
        aliases = {"!setcharwhitelist"},
        adminOnly = true,
        description = "Set a player's whitelist level for a team",
        usage = "/setcharwhitelist <player> <teamID> <level>",
        minArgs = 3,
        argTypes = {"player", "number", "number"},
        callback = function(ply, args)
            local target, teamID, level = args[1], args[2], args[3]
            if not IsValid(target) then ply:Notify("Player not found!") return end
            if not teamID or teamID <= 0 then ply:Notify("Invalid team ID!") return end
            if not level or level < 0 then level = 0 end
            net.Start("Monarch_SetCharWhitelist")
                net.WriteEntity(target)
                net.WriteUInt(teamID, 16)
                net.WriteUInt(level, 16)
            net.SendToServer()
            ply:Notify("Setting whitelist level "..level.." for team "..teamID.." on "..(target.GetRPName and target:GetRPName() or target:Nick()).."...")
        end
    })

    Monarch.RegisterChatCommand("/addloyalty", {
        aliases = {"!addloyalty"},
        adminOnly = true,
        description = "Add loyalty points to a player",
        usage = "/addloyalty <steamid64> <amount>",
        minArgs = 2,
        maxArgs = 2,
        argTypes = {"string", "number"},
        callback = function(ply, args)
            local steamid = tostring(args[1])
            local amount = tonumber(args[2]) or 0

            if not steamid or steamid == "" then
                ply:Notify("Invalid SteamID64!")
                return
            end

            if amount <= 0 then
                ply:Notify("Amount must be a positive number!")
                return
            end

            net.Start("Monarch_AdminAddLoyalty")
                net.WriteString(steamid)
                net.WriteInt(amount, 32)
            net.SendToServer()
        end
    })

    Monarch.RegisterChatCommand("!menu", {
        adminOnly = true,
        aliases = {"/menu", "!mas", "/mas"},
        hideMessage = true,
        description = "Opens the Monarch Admin System",
        usage = "!menu",
        minArgs = 0,
        callback = function(ply)
            if net and net.Start then
                net.Start("Monarch_Tickets_RequestOpen")
                net.SendToServer()
            else
                if chat and chat.AddText then
                    chat.AddText(Color(220,80,80), "[MAS] ", color_white, "Networking unavailable.")
                end
            end
        end
    })

    Monarch.RegisterChatCommand("!sethp", {
        adminOnly = true,
        description = "Set a player's health",
        usage = "!sethp <player> <amount>",
        minArgs = 2,
        argTypes = {"player", "number"},
        callback = function(ply, args)
            local target, hpAmount = args[1], args[2]

            if not IsValid(target) then
                ply:Notify("Player not found!")
                return
            end

            if not hpAmount or hpAmount < 0 then
                ply:Notify("Invalid health amount!")
                return
            end

            ply:Notify("You have set "..target:Nick().."'s HP to "..hpAmount)

            net.Start("MonarchSetHP")
                net.WriteUInt(hpAmount, 32)
                net.WritePlayer(target)
            net.SendToServer()
        end
    })

    Monarch.RegisterChatCommand("!setarmor", {
        adminOnly = true,
        description = "Set a player's armor",
        usage = "!setarmor <player> <amount>",
        minArgs = 2,
        argTypes = {"player", "number"},
        callback = function(ply, args)
            local target, armorAmount = args[1], args[2]

            if not IsValid(target) then
                ply:Notify("Player not found!")
                return
            end

            if not armorAmount or armorAmount < 0 then
                ply:Notify("Invalid armor amount!")
                return
            end

            ply:Notify("You have set "..target:Nick().."'s Armor to "..armorAmount)

            net.Start("MonarchSetArmor")
                net.WriteUInt(armorAmount, 32)
                net.WritePlayer(target)
            net.SendToServer()
        end
    })

    Monarch.RegisterChatCommand("!addmoney", {
        adminOnly = true,
        aliases = {"/addmoney", "!givemoney"},
        description = "Add money to a player's wallet",
        usage = "!addmoney <player> <amount>",
        minArgs = 2,
        argTypes = {"player", "number"},
        callback = function(ply, args)
            local target, amount = args[1], args[2]

            if not IsValid(target) then
                ply:Notify("Player not found!")
                return
            end

            if not amount then
                ply:Notify("Invalid amount!")
                return
            end

            ply:Notify("You added $"..amount.." to "..target:Nick().."'s wallet")

            net.Start("MonarchAddMoney")
                net.WriteInt(amount, 32)
                net.WritePlayer(target)
            net.SendToServer()
        end
    })

    net.Receive("Monarch_Interact_PulseResult", function()
        local target = net.ReadEntity()
        local pulse = net.ReadUInt(12)
        local dead = net.ReadBool()
        if not IsValid(target) then return end
        local tname = target.GetRPName and target:GetRPName() or target:Nick()
        if dead or pulse < 50 then
            LocalPlayer():Notify(tname.." has no detectable pulse.")
        else
            LocalPlayer():Notify(tname.."'s pulse is "..tostring(pulse).." BPM.")
        end
    end)

    net.Receive("Monarch_GiveMoney_Result", function()
        local ok = net.ReadBool()
        local msg = net.ReadString()
        if ok then
            LocalPlayer():Notify(msg)
        else
            LocalPlayer():Notify(msg)
        end
    end)

    Monarch.RegisterChatCommand("/me", {
        adminOnly = false,
        description = "Perform an action as yourself",
        usage = "/me <action>",
        minArgs = 1,
        callback = function(ply, args)
            local action = table.concat(args, " ")
            net.Start("Monarch_ME_Send")
                net.WriteString(action)
            net.SendToServer()
        end
    })

    Monarch.RegisterChatCommand("/giveammo", {
        adminOnly = true,
        description = "Give ammo to a player",
        usage = "/giveammo <player> <amount>",
        minArgs = 2,
        argTypes = {"player", "number"},
        callback = function(ply, args)
            local target, ammoAmt = args[1], args[2]

            if not IsValid(target) then
                ply:Notify("Player not found!")
                return
            end

            if not ammoAmt or ammoAmt <= 0 then
                ply:Notify("Invalid ammo amount!")
                return
            end

            local weapon = ply:GetActiveWeapon()
            if not IsValid(weapon) then
                ply:Notify("You are not holding a valid weapon!")
                return
            end

            local ammoTypeID = weapon:GetPrimaryAmmoType()
            local ammoType = game.GetAmmoName(ammoTypeID)
            if not ammoType then
                ply:Notify("Invalid ammo type!")
                return
            end

            ply:Notify("You have given " .. ammoAmt .. " " .. ammoType .. " ammo to " .. target:Nick())

            net.Start("MonarchGiveAmmo")
                net.WriteUInt(ammoAmt, 32)
                net.WriteEntity(target)
                net.WriteString(ammoType)
            net.SendToServer()
        end
    })

    Monarch.RegisterChatCommand("/givemoney", {
        aliases = {"!givemoney"},
        adminOnly = false,
        description = "Give money to a player",
        usage = "/givemoney <player> <amount>",
        minArgs = 2,
        argTypes = {"player", "number"},
        callback = function(ply, args)
            local target, amount = args[1], args[2]
            if not IsValid(target) then
                ply:Notify("Player not found!")
                return
            end
            amount = tonumber(amount) or 0
            if amount <= 0 then
                ply:Notify("Invalid amount!")
                return
            end
            local ok, err = pcall(net.Start, "Monarch.GiveMoney")
            if not ok then
                ply:Notify("Money system not ready: "..tostring(err))
                return
            end

                net.WriteEntity(target)
                net.WriteUInt(math.floor(amount), 32)
            net.SendToServer()
        end
    })

    Monarch.RegisterChatCommand("!setmoney", {
        adminOnly = true,
        description = "Set a player's money",
        usage = "!setmoney <player> <amount>",
        minArgs = 2,
        argTypes = {"player", "number"},
        callback = function(ply, args)
            local target, amount = args[1], args[2]
            if not IsValid(target) then
                ply:Notify("Player not found!")
                return
            end
            amount = tonumber(amount) or 0
            if amount < 0 then amount = 0 end
            local ok, err = pcall(net.Start, "Monarch.SetMoney")
            if not ok then
                ply:Notify("Money system not ready: "..tostring(err))
                return
            end

                net.WriteEntity(target)
                net.WriteUInt(math.floor(amount), 32)
            net.SendToServer()
        end
    })

    Monarch.RegisterChatCommand("!sethunger", {
        adminOnly = true,
        description = "Set a player's hunger (0-100)",
        usage = "!sethunger <player> <amount>",
        minArgs = 2,
        argTypes = {"player", "number"},
        callback = function(ply, args)
            local target, amt = args[1], tonumber(args[2])
            if not IsValid(target) then ply:Notify("Player not found!") return end
            if not amt then ply:Notify("Invalid amount!") return end
            net.Start("MonarchSetHunger")
                net.WriteUInt(math.Clamp(math.floor(amt), 0, 100), 16)
                net.WritePlayer(target)
            net.SendToServer()
            ply:Notify("Set "..target:Nick().." hunger to "..math.Clamp(math.floor(amt), 0, 100))
        end
    })

    Monarch.RegisterChatCommand("!sethydration", {
        adminOnly = true,
        description = "Set a player's hydration (0-100)",
        usage = "!sethydration <player> <amount>",
        minArgs = 2,
        argTypes = {"player", "number"},
        callback = function(ply, args)
            local target, amt = args[1], tonumber(args[2])
            if not IsValid(target) then ply:Notify("Player not found!") return end
            if not amt then ply:Notify("Invalid amount!") return end
            net.Start("MonarchSetHydration")
                net.WriteUInt(math.Clamp(math.floor(amt), 0, 100), 16)
                net.WritePlayer(target)
            net.SendToServer()
            ply:Notify("Set "..target:Nick().." hydration to "..math.Clamp(math.floor(amt), 0, 100))
        end
    })

    Monarch.RegisterChatCommand("!setexhaustion", {
        adminOnly = true,
        description = "Set a player's exhaustion (0-100)",
        usage = "!setexhaustion <player> <amount>",
        minArgs = 2,
        argTypes = {"player", "number"},
        callback = function(ply, args)
            local target, amt = args[1], tonumber(args[2])
            if not IsValid(target) then ply:Notify("Player not found!") return end
            if not amt then ply:Notify("Invalid amount!") return end
            net.Start("MonarchSetExhaustion")
                net.WriteUInt(math.Clamp(math.floor(amt), 0, 100), 16)
                net.WritePlayer(target)
            net.SendToServer()
            ply:Notify("Set "..target:Nick().." exhaustion to "..math.Clamp(math.floor(amt), 0, 100))
        end
    })

    Monarch.RegisterChatCommand("!setstamina", {
        adminOnly = true,
        description = "Set a player's stamina (0-100)",
        usage = "!setstamina <player> <amount>",
        minArgs = 2,
        argTypes = {"player", "number"},
        callback = function(ply, args)
            local target, amt = args[1], tonumber(args[2])
            if not IsValid(target) then ply:Notify("Player not found!") return end
            if not amt then ply:Notify("Invalid amount!") return end
            net.Start("MonarchSetStamina")
                net.WriteUInt(math.Clamp(math.floor(amt), 0, 100), 16)
                net.WritePlayer(target)
            net.SendToServer()
            ply:Notify("Set "..target:Nick().." stamina to "..math.Clamp(math.floor(amt), 0, 100))
        end
    })

    Monarch.RegisterChatCommand("/name", {
        description = "Set your RP name",
        usage = "/name <new_name>",
        minArgs = 1,
        callback = function(ply, args)
            local name = table.concat(args, " ")

            if string.len(name) < 2 then
                ply:Notify("Name must be at least 2 characters long!")
                return
            end

            if string.len(name) > 50 then
                ply:Notify("Name is too long! Maximum 50 characters.")
                return
            end

            ply:Notify("You have set your name to " .. name)

            net.Start("MonarchSetName")
                net.WriteString(name)
            net.SendToServer()
        end
    })

    surface.CreateFont("Monarch_CommandHeader", {
        font = "Arial",
        size = 18,
        weight = 600,
        antialias = true
    })

    function Monarch.CommandChatPrint(cmd, ...)
        if cmd and cmd.outputFont then
            hook.Run("MonarchCommandChatPrint", cmd.outputFont, {...})
        else
            chat.AddText(...)
        end
    end

    hook.Add("MonarchCommandChatPrint", "Monarch_DefaultFontPrinter", function(fontName, segments)

        chat.AddText(unpack(segments))
    end)

    Monarch.RegisterChatCommand("/help", {
        aliases = {"!help", "/commands", "!commands"},
        description = "Show available commands",
        usage = "/help [command]",
        maxArgs = 1,
        outputFont = "Monarch_CommandHeader", 
        callback = function(ply, args)
            local cmdObj
            if args[1] then
                cmdObj = registeredCommands[string.lower(args[1])]
                if cmdObj then
                    Monarch.CommandChatPrint(cmdObj,
                        Color(100,255,100),"Command: ", Color(255,255,255),cmdObj.name,"\n",
                        Color(100,255,100),"Description: ", Color(255,255,255),cmdObj.description,"\n",
                        Color(100,255,100),"Usage: ", Color(255,255,255),cmdObj.usage,
                        (#cmdObj.aliases>0 and "\n" or ""),
                        (#cmdObj.aliases>0 and Color(100,255,100) or Color(0,0,0,0)),
                        (#cmdObj.aliases>0 and "Aliases: " or ""),
                        (#cmdObj.aliases>0 and Color(255,255,255) or Color(0,0,0,0)),
                        (#cmdObj.aliases>0 and table.concat(cmdObj.aliases,", ") or "")
                    )
                else
                    Monarch.CommandChatPrint(nil, Color(255,100,100),"Command not found!")
                end
            else
                Monarch.CommandChatPrint(cmdObj, Color(100,255,100),"Available commands:")
                local shown = {}
                for _, c in pairs(registeredCommands) do
                    if c.name == _ and not shown[c] and (not c.adminOnly or ply:IsAdmin()) then
                        Monarch.CommandChatPrint(c, Color(255,255,255),"  "..c.usage.." - "..c.description)
                        shown[c] = true
                    end
                end
                Monarch.CommandChatPrint(cmdObj, Color(200,200,200),"Use /help <command> for detailed info")
            end
        end
    })
end

    Monarch.RegisterChatCommand("!giveitem", {
        adminOnly = true,
        description = "Give an item to a player",
        usage = "!giveitem <player> <item_class> [amount]",
        minArgs = 2,
        argTypes = {"player", "string", "number"},
        callback = function(ply, args)
            if not ply:IsSuperAdmin() then
                ply:Notify("You need to be a Super Admin to use this command.")
                return
            end

            local target, itemClass = args[1], args[2]
            local amount = args[3] or 1

            if not IsValid(target) then
                ply:Notify("Player not found!")
                return
            end

            local itemKey = Monarch.Inventory.ItemsRef[itemClass]
            if not itemKey or not Monarch.Inventory.Items[itemKey] then
                ply:Notify("Item not found: " .. itemClass)
                return
            end

            if amount <= 0 or amount > 100 then
                ply:Notify("Invalid amount! Must be between 1 and 100.")
                return
            end

            local steamid = target:SteamID64()
            if not Monarch.Inventory.Data[steamid] then
                Monarch.Inventory.Data[steamid] = {[1] = {}}
            end
            if not Monarch.Inventory.Data[steamid][1] then
                Monarch.Inventory.Data[steamid][1] = {}
            end

            for i = 1, amount do
                local nextSlot = 1
                while Monarch.Inventory.Data[steamid][1][nextSlot] do
                    nextSlot = nextSlot + 1
                end

                Monarch.Inventory.Data[steamid][1][nextSlot] = {
                    id = itemClass,
                    class = itemClass,
                    equipped = false
                }
            end

            net.Start("MonarchInventorySyncClient")
            net.WriteTable(Monarch.Inventory.Data[steamid] or {})
            net.SendToServer()

            local itemData = Monarch.Inventory.Items[itemKey]
            ply:Notify("Gave " .. amount .. "x " .. itemClass .. " to " .. target:Nick())
            target:Notify("You received " .. amount .. "x " .. itemData.Name .. " from " .. ply:Nick())
        end
    })

if SERVER then
    net.Receive("MonarchInventorySyncServer", function(len,ply)
        local inventoryData = net.ReadTable()
        net.Start("MonarchInventorySync")
        net.WriteTable(inventoryData)
        net.Send(ply)
    end)
end