Monarch = Monarch or {}

local function Monarch_RegisterCPChatDecorator()
    if type(Monarch.RegisterICChatDecorator) ~= "function" then return false end
    Monarch.RegisterICChatDecorator("cp_brackets", function(sender, message)
        if sender:IsCP() then
            return "<:: ", " ::>"
        end
    end)
    return true
end

if not Monarch_RegisterCPChatDecorator() then
    hook.Add("Initialize", "Monarch_RegisterCPChatDecorator_Init", function()
        if Monarch_RegisterCPChatDecorator() then
            hook.Remove("Initialize", "Monarch_RegisterCPChatDecorator_Init")
        end
    end)
end

local function GetStaminaMax() return Config.DefaultStamina or 100 end
local function GetStaminaDrainRate() return Config.DefaultStaminaDrainRate or 3.33 end
local function GetStaminaRegenRate() return Config.DefaultStaminaRegenRate or 1.5 end
local function GetWalkSpeed() return Config.DefaultWalkSpeed or 60 end
local function GetRunSpeed() return Config.DefaultJogSpeed or 200 end
local function GetSpeedWalkSpeed() return Config.DefaultSpeedWalkSpeed or 140 end

local STAMINA_REENABLE = 5
local STAMINA_JUMP_COST = 6
local STAMINA_LERP_SPEED = 100

function MonarchApplySpeeds(ply)
    if not IsValid(ply) then return end
    ply:SetWalkSpeed(GetWalkSpeed())
    ply:SetRunSpeed(GetRunSpeed())
end

hook.Add("Spawn", "OtherSpeedStuff", function(ply)
    MonarchApplySpeeds(ply)
end)

do
    local pmeta = FindMetaTable("Player")
    if pmeta and not pmeta.SetRPName then
        function pmeta:SetRPName(name, _)
            name = tostring(name or "")
            if name == "" then return end
            self:SetNWString("rpname", name)
            if self.MonarchActiveChar then
                self.MonarchActiveChar.name = name
                self.MonarchActiveChar.rpname = name
            end
        end
    end
end

hook.Add("Think", "MonarchStaminaSystem", function()
    for _, ply in player.Iterator() do
        if not (IsValid(ply) and ply:Alive()) then continue end
        local now = CurTime()
        local STAMINA_MAX = GetStaminaMax()
        local stamina = ply:GetNWFloat("Stamina", STAMINA_MAX)
        local last = ply.LastStaminaUpdate or now
        local dt = now - last
        if dt > 1 then dt = 0.1 end

        local isTryingToSprint = ply:KeyDown(IN_SPEED) and ply:GetVelocity():Length2D() > 50

        if isTryingToSprint and stamina > 0 then
            stamina = math.max(0, stamina - GetStaminaDrainRate() * dt)
        else
            stamina = math.min(STAMINA_MAX, stamina + GetStaminaRegenRate() * dt)
        end

        if stamina <= 0 then
            if ply:GetRunSpeed() ~= GetWalkSpeed() then
                ply:SetRunSpeed(GetWalkSpeed())
            end
        else
            local desired = ply.IsFastWalking and GetSpeedWalkSpeed() or GetRunSpeed()
            if ply:GetRunSpeed() ~= desired then
                ply:SetRunSpeed(desired)
            end
        end

        ply:SetNWFloat("Stamina", stamina)

        local disp = ply:GetNWFloat("StaminaDisplay", stamina)
        if stamina < disp then

            disp = math.Approach(disp, stamina, STAMINA_LERP_SPEED * dt)
        else

            disp = stamina
        end
        ply:SetNWFloat("StaminaDisplay", disp)

        ply.LastStaminaUpdate = now
    end
end)

util.AddNetworkString("Monarch_FastWalk_Toggle")
util.AddNetworkString("CreateMainMenu")
util.AddNetworkString("Monarch_CPR_Begin")
util.AddNetworkString("Monarch_CPR_Cancel")
net.Receive("Monarch_FastWalk_Toggle", function(_, ply)
    if not (IsValid(ply) and ply:Alive()) then return end
    ply.IsFastWalking = not ply.IsFastWalking
    local desired = ply.IsFastWalking and GetSpeedWalkSpeed() or GetRunSpeed()
    ply:SetRunSpeed(desired)
end)

hook.Add("PlayerInitialSpawn", "Monarch_InitSpeeds", function(ply)
    ply.IsSprinting = false
    ply:SetNWFloat("Stamina", GetStaminaMax())
    MonarchApplySpeeds(ply)

	net.Start("CreateMainMenu")
	net.Send(ply)
end)

function GM:PlayerSetHandsModel( pl, ent )

	local info
	
	local teamData = Monarch and Monarch.Team and Monarch.Team[pl:Team()]
	if teamData and teamData.handsModel then
		info = {
			model = teamData.handsModel,
			skin = 0,
			body = "0000000"
		}
	else
		info = player_manager.RunClass( pl, "GetHandsModel" )
		if ( !info ) then
			local playermodel = player_manager.TranslateToPlayerModelName( pl:GetModel() )
			info = player_manager.TranslatePlayerHands( playermodel )
		end
	end

	if ( info ) then
		ent:SetModel( info.model )
		ent:SetSkin( info.matchBodySkin and pl:GetSkin() or info.skin )
		ent:SetBodyGroups( info.body )
        return true
	end
end

local RespawnTimers = {}

local function Monarch_IsRagdollFinisherDamage(dmginfo)
    if not dmginfo then return false end

    local inflictor = dmginfo:GetInflictor()
    local isWeaponInflictor = IsValid(inflictor) and (inflictor:IsWeapon() or inflictor:GetClass() == "player")
    local damageType = dmginfo:GetDamageType() or 0

    local isWeaponLikeType = dmginfo:IsBulletDamage()
        or bit.band(damageType, DMG_BUCKSHOT) ~= 0
        or bit.band(damageType, DMG_SLASH) ~= 0
        or bit.band(damageType, DMG_CLUB) ~= 0
        or bit.band(damageType, DMG_BLAST) ~= 0

    if not isWeaponInflictor and not isWeaponLikeType then
        return false
    end

    local damage = math.max(0, dmginfo:GetDamage() or 0)
    return damage > 0
end

function GM:DoPlayerDeath(ply, attacker, dmginfo) 
	local vel = ply:GetVelocity()

	local ragCount = #ents.FindByClass("prop_ragdoll")

	local ragdoll = ents.Create("prop_ragdoll")
	ragdoll:SetModel(ply:GetModel())
	ragdoll:SetPos(ply:GetPos())
	ragdoll:SetSkin(ply:GetSkin())
	ragdoll.DeadPlayer = ply
	ragdoll.Killer = attacker
	ragdoll.DmgInfo = dmginfo

	if ply.LastFall and ply.LastFall > CurTime() - 0.5 then
		ragdoll.FallDeath = true
        ragdoll.MonarchDeceased = true
	end

	if IsValid(attacker) and attacker:IsPlayer() then
		local wep = attacker:GetActiveWeapon()

		if IsValid(wep) then
			ragdoll.DmgWep = wep:GetClass()
		end	
	end

	ragdoll.CanConstrain = false
	ragdoll.NoCarry = true

	for v,k in pairs(ply:GetBodyGroups()) do
		ragdoll:SetBodygroup(k.id, ply:GetBodygroup(k.id))
	end

	hook.Run("PlayerRagdollPreSpawn", ragdoll, ply, attacker)

	if ply.MonarchID and Monarch.Inventory and Monarch.Inventory.Data then
		local inv = Monarch.Inventory.Data[ply.MonarchID]
		if inv and inv[1] then
			local itemsToDrop = {}
			for slotID, item in pairs(inv[1]) do
				if istable(item) then
					local itemClass = item.class or item.id
					local itemKey = Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[itemClass]
					local itemData = itemKey and Monarch.Inventory.Items and Monarch.Inventory.Items[itemKey]

					local isLocked = itemData and itemData.Locked or item.Locked or item.locked
					local isRestricted = itemData and itemData.Restricted or item.restricted or false
					local shouldDrop = itemData and (itemData.DeathDrop ~= false) and not isLocked and not isRestricted

					if shouldDrop and not item.equipped then
						table.insert(itemsToDrop, {slotID = slotID, item = item})
					end
				end
			end

			if Monarch.Inventory.SaveForOwner then
				local charID = ply.MonarchID or (ply.MonarchActiveChar and ply.MonarchActiveChar.id)
				if charID then
					timer.Simple(0.1, function()
						if IsValid(ply) then
							Monarch.Inventory.SaveForOwner(ply, charID)
						end
					end)
				end
			end
		end
	end

	ragdoll:Spawn()
	ragdoll:SetCollisionGroup(COLLISION_GROUP_WORLD)

    ply.DeathRagdoll = ragdoll

	local velocity = ply:GetVelocity()

	for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
		local physObj = ragdoll:GetPhysicsObjectNum(i)

		if IsValid(physObj) then
			physObj:SetVelocity(velocity)

			local index = ragdoll:TranslatePhysBoneToBone(i)

			if index then
				local pos, ang = ply:GetBonePosition(index)

				physObj:SetPos(pos)
				physObj:SetAngles(ang)
			end
		end
	end

	timer.Simple(Config.RagdollDespawnTime, function()
		if ragdoll and IsValid(ragdoll) then
			ragdoll:Fire("FadeAndRemove", 7)

			timer.Simple(10, function()
				if IsValid(ragdoll) then
					ragdoll:Remove() 
				end
			end)
		end
	end)

	timer.Simple(0.1, function()
		if IsValid(ragdoll) and IsValid(ply) then
			net.Start("monarchRagdollLink")
		 net.WriteEntity(ragdoll)
			net.Send(ply)
		end
	end)

    net.Start("Monarch_OpenDeathScreen")
	net.Send(ply)

	return true
end

hook.Add("EntityTakeDamage", "Monarch_NearDeathFinishOff", function(ent, dmginfo)
    if not IsValid(ent) or ent:GetClass() ~= "prop_ragdoll" then return end
    if ent.MonarchDeceased then return end

    local deadPlayer = ent.DeadPlayer
    if not (IsValid(deadPlayer) and deadPlayer:IsPlayer() and not deadPlayer:Alive()) then return end

    if not Monarch_IsRagdollFinisherDamage(dmginfo) then return end

    ent.MonarchDeceased = true
    ent.MonarchCPRInProgress = nil
end)

local RespawnTimers = {}

hook.Add("DoPlayerDeath", "SetRespawnTimer", function(ply, attacker, dmginfo)
    ply.respawnWait = CurTime() + Config.DeathTimer

    ply._monarchDeathCharID = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchLastCharID
    net.Start("Monarch_DeathHandle")
    net.Send(ply)
end)

function GM:PlayerDeathThink(ply)
	if not ply.respawnWait then
		ply:Spawn()
		return true
	end

	if ply.respawnWait < CurTime() then
		ply:Spawn()
	end

	return true
end

function Monarch.TryPerformCPR(ply, ragdoll)
    if not (IsValid(ply) and ply:IsPlayer() and ply:Alive()) then return false end
    if not (IsValid(ragdoll) and ragdoll:GetClass() == "prop_ragdoll") then return false end

    if ragdoll.MonarchDeceased or ragdoll.FallDeath then
        if ply.Notify then
            ply:Notify("This person is deceased.")
        end
        return false
    end

    local maxAttempts = math.max(1, math.floor(tonumber(Config.CPRMaxAttemptsPerLife) or 2))
    local attemptsUsed = tonumber(ply._monarchCPRAttemptsUsed) or 0
    if attemptsUsed >= maxAttempts then
        if ply.Notify then
            ply:Notify("This person is no longer savable.")
        end
        return false
    end

    if (ply._nextCPRAttempt or 0) > CurTime() then return false end

    local target = ragdoll.DeadPlayer
    if not (IsValid(target) and target:IsPlayer() and not target:Alive()) then
        if ply.Notify then ply:Notify("This body cannot be revived.") end
        return false
    end

    local useDist = tonumber(Config.CPRUseDistance) or 130
    if ply:GetPos():DistToSqr(ragdoll:GetPos()) > (useDist * useDist) then return false end

    if ragdoll.MonarchCPRInProgress then
        if ply.Notify then ply:Notify("Someone is already performing CPR.") end
        return false
    end

    ragdoll.MonarchCPRInProgress = true
    ply._monarchCPRAttemptsUsed = attemptsUsed + 1
    ply._nextCPRAttempt = CurTime() + (tonumber(Config.CPRAttemptCooldown) or 1.5)

    local cprTime = math.max(1, tonumber(Config.CPRTime) or 6)
    local startTime = CurTime()
    local timerSuffix = tostring(ply:EntIndex()) .. "_" .. tostring(ragdoll:EntIndex())
    local finishTimerName = "Monarch_CPR_Finish_" .. timerSuffix
    local monitorTimerName = "Monarch_CPR_Monitor_" .. timerSuffix

    local function SendCPRCancel()
        if IsValid(ply) then
            net.Start("Monarch_CPR_Cancel")
            net.Send(ply)
        end
    end

    local function CancelCPRAttempt(notifyMessage)
        if IsValid(ragdoll) then
            ragdoll.MonarchCPRInProgress = nil
        end

        timer.Remove(finishTimerName)
        timer.Remove(monitorTimerName)

        SendCPRCancel()

        if notifyMessage and IsValid(ply) and ply.Notify then
            ply:Notify(notifyMessage)
        end
    end

    net.Start("Monarch_CPR_Begin")
        net.WriteFloat(cprTime)
        net.WriteString("Performing CPR...")
    net.Send(ply)

    timer.Create(monitorTimerName, 0.1, 0, function()
        if CurTime() - startTime >= cprTime then
            timer.Remove(monitorTimerName)
            return
        end

        if not IsValid(ragdoll) then
            CancelCPRAttempt(nil)
            return
        end

        if ragdoll.MonarchDeceased or ragdoll.FallDeath then
            CancelCPRAttempt("CPR failed. This person is deceased.")
            return
        end

        if not (IsValid(ply) and ply:Alive()) then
            CancelCPRAttempt(nil)
            return
        end

        local liveTarget = ragdoll.DeadPlayer
        if not (IsValid(liveTarget) and liveTarget:IsPlayer() and not liveTarget:Alive()) then
            CancelCPRAttempt(nil)
            return
        end

        if ply:GetPos():DistToSqr(ragdoll:GetPos()) > (useDist * useDist) then
            CancelCPRAttempt("CPR failed.")
            return
        end
    end)

    timer.Create(finishTimerName, cprTime, 1, function()
        timer.Remove(monitorTimerName)

        if not IsValid(ragdoll) then
            SendCPRCancel()
            return
        end

        if ragdoll.MonarchDeceased or ragdoll.FallDeath then
            SendCPRCancel()
            if ply.Notify then ply:Notify("CPR failed. This person is deceased.") end
            return
        end

        ragdoll.MonarchCPRInProgress = nil

        if not (IsValid(ply) and ply:Alive()) then
            SendCPRCancel()
            return
        end

        local reviveTarget = ragdoll.DeadPlayer
        if not (IsValid(reviveTarget) and reviveTarget:IsPlayer() and not reviveTarget:Alive()) then
            SendCPRCancel()
            return
        end

        if ply:GetPos():DistToSqr(ragdoll:GetPos()) > (useDist * useDist) then
            SendCPRCancel()
            if ply.Notify then ply:Notify("CPR failed. You moved too far away.") end
            return
        end

        local successChance = math.Clamp(tonumber(Config.CPRSuccessChance) or 0.35, 0, 1)
        if math.Rand(0, 1) > successChance then
            SendCPRCancel()
            if ply.Notify then ply:Notify("CPR failed.") end
            if reviveTarget.Notify then reviveTarget:Notify("Someone attempted CPR, but it failed.") end
            return
        end

        SendCPRCancel()

        local revivePos = ragdoll:GetPos() + Vector(0, 0, 8)
        local reviveAng = ragdoll:GetAngles()

        reviveTarget.respawnWait = nil
        reviveTarget:Spawn()

        timer.Simple(0, function()
            if not IsValid(reviveTarget) then return end
            reviveTarget:SetPos(revivePos)
            reviveTarget:SetEyeAngles(Angle(0, reviveAng.y, 0))
            reviveTarget:SetHealth(math.min(10, reviveTarget:GetMaxHealth()))
        end)

        if IsValid(ragdoll) then ragdoll:Remove() end

        if ply.Notify then ply:Notify("CPR successful. They are barely alive.") end
        if reviveTarget.Notify then reviveTarget:Notify("You were revived by CPR with 10 HP.") end
    end)

    return true
end

function Monarch.SetupPlayer(ply, dbData)

	ply:SetSyncVar(SYNC_RPNAME, dbData.rpname, true)
	ply:SetSyncVar(SYNC_XP, dbData.xp, true)

	ply:SetLocalSyncVar(SYNC_MONEY, dbData.money)
	ply:SetLocalSyncVar(SYNC_BANKMONEY, dbData.bankmoney)

	if ply.SetMoney then
		ply:SetMoney(tonumber(dbData.money) or 0)
	end
	if ply.SetSecondaryMoney then
		ply:SetSecondaryMoney(tonumber(dbData.bankmoney) or 0)
	end

	local data = util.JSONToTable(dbData.data)

	ply.firstJoin = dbData.firstjoin

	ply.defaultModel = dbData.model
	ply.defaultSkin = dbData.skin
	ply.defaultRPName = dbData.rpname

	ply:SetFOV(90, 0)
	ply:AllowFlashlight(true)

	ply:Monarch_SetTeam(TEAM_CITIZEN) 
	ply:EmitSound("ui/hls_loading_enter.mp3", 75, 100, 1, CHAN_AUTO)

	ply.beenSetup = true
end

function Monarch.SetupPlayerFromChar(ply, charData)

    if not IsValid(ply) or not charData then return end

    ply.MonarchActiveChar = charData

    if charData.model and charData.model != "" then
        ply:SetModel(charData.model)
    end

    if charData.skin and tonumber(charData.skin) then
        ply:SetSkin(tonumber(charData.skin))
    end

    ply:SetSyncVar(SYNC_RPNAME, charData.rpname, true)
    ply:SetSyncVar(SYNC_XP, charData.xp, true)
    ply:SetLocalSyncVar(SYNC_MONEY, charData.money)

    if ply.SetMoney then
        ply:SetMoney(tonumber(charData.money) or 0)
    end
    if ply.SetSecondaryMoney then
        ply:SetSecondaryMoney(tonumber(charData.bankmoney) or 0)
    end

    ply:SetNWString("rpname", charData.rpname or charData.name or "Unknown")

    ply:SetNWString("original_rpname", charData.rpname or charData.name or "Unknown")

    if charData.team and tonumber(charData.team) then
        if ply.Monarch_SetTeam then
            ply:Monarch_SetTeam(tonumber(charData.team))
        else
            ply:SetTeam(tonumber(charData.team))
        end
    end

    if charData.bodygroups and charData.bodygroups != "" and charData.bodygroups != "{}" then
        local success, bodygroups = pcall(util.JSONToTable, charData.bodygroups)
        if success and bodygroups and type(bodygroups) == "table" then
            TranslatePhysBoneToBone(physNum)
            for bgID, bgValue in pairs(bodygroups) do
                local id = tonumber(bgID)
                local value = tonumber(bgValue)
                if id and value and id >= 0 and value >= 0 then
                    ply:SetBodygroup(id, value)
                end
            end
        else
            print("[Monarch] Failed to parse bodygroups for " .. ply:Nick() .. ":", charData.bodygroups)
        end
    end

    ply.CharacterBodygroups = charData.bodygroups

    ply:SetNWString("MonarchCharName", charData.name or charData.rpname or "")

    ply:SetFOV(90, 0)
    ply:AllowFlashlight(true)
    ply.beenSetup = true
end

Monarch = Monarch or {}

function GM:PlayerInitialSpawn(ply)
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

    ply:SetModel(Config.DefaultModel)
    print("Starting data load")

    if ply:GetPData("PreviouslyJoined") then
        print("Data not loading, "..ply:Nick().." has previously joined and has stored data.")
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
            elseif IsValid(ply) then
                ply:Freeze(true)
            end
        end)
        query:Execute()
    else
        local timestamp = math.floor(os.time())

        local query = mysql:Select("monarch_players")
        query:Where("steamid", plyID)
        query:Callback(function(result)
            if (type(result) == "table" and #result > 0) then return end 

            local insertQuery = mysql:Insert("monarch_players")
            insertQuery:Insert("rpname", ply:Nick())
            insertQuery:Insert("steamid", ply:SteamID())
            insertQuery:Insert("group", "user")
            insertQuery:Insert("xp", 0)
            insertQuery:Insert("money", Config.StartingMoney)
            insertQuery:Insert("bankmoney", Config.StartingMoney)
            insertQuery:Insert("model", Config.DefaultModel)
            insertQuery:Insert("skin", 0)
            insertQuery:Insert("firstjoin", timestamp)
            insertQuery:Insert("data", "[]")
            insertQuery:Insert("skills", "[]")
            insertQuery:Insert("ammo", "[]")
            insertQuery:Callback(function(result, status, lastID)
                if IsValid(ply) then
                    local setupData = {
                        id = ply:SteamID64(),
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
                end
            end)
            insertQuery:Execute()
        end)
        ply:SetPData("PreviouslyJoined", true) 
        query:Execute()
    end

    ply:SetNWInt("Money",  tonumber(ply:GetPData("Money")))
    ply:SetNWInt("xp", tonumber(ply:GetPData("xp")))

    ply:SetRPName(ply:Name())
end 

function GM:PlayerSilentDeath(ply)
	ply.IsKillSilent = true
	ply.TempWeapons = {}

	for v,k in pairs(ply:GetWeapons()) do
		ply.TempWeapons[v] = {wep = k:GetClass(), clip = k:Clip1()}
	end

	ply.TempAmmo = ply:GetAmmo()

	local wep = ply:GetActiveWeapon()

	if wep and IsValid(wep) then
		ply.TempSelected = wep:GetClass()
		ply.TempSelectedRaised = ply:IsWeaponRaised()
	end
end

hook.Add( "PlayerSwitchFlashlight", "BlockFlashLight", function( ply, enabled )
	if ply:HasWeapon("flashlight") then return true end
end )

function GM:PlayerSpawn(ply)
	ply:SetViewEntity(ply)
    ply:SetGravity(Config.Gravity)
    ply:SetupHands()

    if not ply._rankVendorInProgress then
        local c = ply.MonarchActiveChar
        if c then
            local rp = c.name or c.rpname
            if rp and rp ~= "" then
                if ply.SetRPName then
                    ply:SetRPName(rp, false)
                else
                    ply:SetNWString("rpname", rp)
                end
            end
        end
    end

    if ply.MonarchActiveChar and ply.MonarchActiveChar.model and ply.MonarchActiveChar.model ~= "" then
        ply:SetModel(ply.MonarchActiveChar.model)
        ply:SetSkin(tonumber(ply.MonarchActiveChar.skin) or 0)
    elseif ply.defaultModel and ply.defaultModel ~= "" then
        ply:SetModel(ply.defaultModel)
    else
        ply:SetModel(Config.DefaultModel or "models/player/gman_high.mdl")
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

    timer.Simple(0, function()
        if not IsValid(ply) or not ply.MonarchActiveChar then return end
        local c = ply.MonarchActiveChar

        if c.model and c.model ~= "" then
            ply:SetModel(c.model)
            print("Set Model: "..c.model)
            ply:SetSkin(tonumber(c.skin) or 0)
        end

        if c.bodygroups and c.bodygroups ~= "" and c.bodygroups ~= "{}" then
            local success, bodygroups = pcall(util.JSONToTable, c.bodygroups)
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
    end)

end

if SERVER then
	Monarch.BAS = Monarch.BAS or {}

	function Monarch.BAS.Cloak(ply)
		ply:SetNoDraw(true)
		ply.isCloaked = true

		for v,k in ipairs(ply:GetWeapons()) do
			k:SetNoDraw(true)
		end

		for v,k in ipairs(ents.FindByClass("physgun_beam")) do
			if k:GetParent() == ply then
				k:SetNoDraw(true)
			end
		end

		hook.Add("Think", "basCloak", cloakThink)
	end

	function Monarch.BAS.Uncloak(ply)
		ply:SetNoDraw(false)
		ply.isCloaked = nil

		for v,k in pairs(ply:GetWeapons()) do
			k:SetNoDraw(false)
		end

		for v,k in pairs(ents.FindByClass("physgun_beam")) do
			if k:GetParent() == ply then
				k:SetNoDraw(false)
			end
		end

		ply.cloakWeapon = nil

		local shouldRemoveThink = true

		for v,k in player.Iterator() do
			if k.isCloaked then
				shouldRemoveThink = false
				break
			end
		end

		if shouldRemoveThink then
			hook.Remove("Think", "basCloak")
		end
	end

	local nextCloakThink = 0

	function cloakThink()
		if nextCloakThink > CurTime() then return end 

		for v,k in player.Iterator() do
			if k.isCloaked then
				local activeWeapon = k:GetActiveWeapon()

				if activeWeapon:IsValid() and activeWeapon != k.cloakWeapon then
					k.cloakWeapon = activeWeapon
					activeWeapon:SetNoDraw(true)

					if activeWeapon:GetClass() == "weapon_physgun" then
						for x,y in ipairs(ents.FindByClass("physgun_beam")) do
							if y:GetParent() == k then
								y:SetNoDraw(true)
							end
						end
					end
				end
			end
		end

		nextCloakThink = CurTime() + 0.1
	end
end

hook.Add("PlayerNoClip", "basNoClip", function(ply, state)
	if ply:IsAdmin() then
		if SERVER then
			if state then
				Monarch.BAS.Cloak(ply)

				ply:GodEnable()
				ply:SetCollisionGroup(COLLISION_GROUP_WEAPON)

				if ply:FlashlightIsOn() then
					ply:Flashlight(false)
				end

				ply:AllowFlashlight(false)
			else
				Monarch.BAS.Uncloak(ply)
				ply:GodDisable()
				ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
				ply:AllowFlashlight(true)
			end
		end

		return true
	end

	return false
end)

hook.Add("PlayerSpawn", "ResetStuff", function(ply)
    ply:SetMoveType(MOVETYPE_WALK)
    ply:GodDisable()
    ply._monarchCPRAttemptsUsed = 0

end)

util.AddNetworkString("MonarchSprintState")

util.AddNetworkString("Monarch_CharCreate")
util.AddNetworkString("Monarch_CharList")
util.AddNetworkString("Monarch_CharSelect")

net.Receive("MonarchSprintState", function(len, ply)
    local isSprinting = net.ReadBool()
    ply.IsSprinting = isSprinting
end)

hook.Add("KeyPress", "Monarch_StaminaJumpDrain", function(ply, key)
    if key ~= IN_JUMP then return end
    if not (IsValid(ply) and ply:Alive()) then return end
    if not ply:OnGround() then return end
    local stamina = ply:GetNWFloat("Stamina", STAMINA_MAX)
    if stamina <= 0 then return end
    stamina = math.max(0, stamina - STAMINA_JUMP_COST)
    ply:SetNWFloat("Stamina", stamina)
    ply.LastStaminaUpdate = CurTime()
    if stamina <= 0 then
        ply:SetRunSpeed(GetWalkSpeed())
    end
end)

hook.Add("SetupMove", "Monarch_BlockJumpOnNoStamina", function(ply, mv, cmd)
    if not (IsValid(ply) and ply:Alive()) then return end
    if ply:GetNWFloat("Stamina", STAMINA_MAX) > 0 then return end
    local buttons = mv:GetButtons()
    if bit.band(buttons, IN_JUMP) ~= 0 then
        mv:SetButtons(bit.band(buttons, bit.bnot(IN_JUMP)))
    end
end)

hook.Add("PlayerSpawn", "MonarchApplyBodygroups", function(ply)
    if not ply.MonarchActiveChar then return end

    timer.Simple(0.1, function()
        if IsValid(ply) and ply.CharacterBodygroups then
            local bodygroups = util.JSONToTable(ply.CharacterBodygroups)
            if bodygroups and type(bodygroups) == "table" then
                for bgID, bgValue in pairs(bodygroups) do
                    local id = tonumber(bgID)
                    local value = tonumber(bgValue)
                    if id and value then
                        ply:SetBodygroup(id, value)
                    end
                end
            end
        end
    end)
end)

Monarch.CharSystem = Monarch.CharSystem or {}

local function Monarch_ResetAllBodygroups(ply)
    if not IsValid(ply) then return end
    if not ply.GetBodyGroups then return end

    local bodygroups = ply:GetBodyGroups()
    if not istable(bodygroups) then return end

    for i = 1, #bodygroups do
        local bodygroup = bodygroups[i]
        if bodygroup and bodygroup.id then
            ply:SetBodygroup(bodygroup.id, 0)
        end
    end
end

hook.Add("PlayerSpawn", "Monarch_ResetBodygroupsPreEquip", function(ply)
    Monarch_ResetAllBodygroups(ply)
end)

local function Monarch_RunCharacterActivatedHooks(ply, charData)
    hook.Run("OnCharacterActivated", ply, charData)
    hook.Run("Monarch_CharLoaded", ply, charData)
end

function Monarch.SendCharacterList(ply)
    local query = mysql:Select("monarch_players")  
    query:Select("*")
    query:Where("steamid", ply:SteamID())
    query:Callback(function(result)
        if result then
            net.Start("Monarch_CharList")
            net.WriteUInt(#result, 3)

            for i, char in ipairs(result) do
                net.WriteUInt(char.id, 32)
                net.WriteString(char.rpname)  
                net.WriteString(char.model)
                net.WriteUInt(char.skin or 0, 8)
                net.WriteInt(char.xp or 0, 32)
                net.WriteInt(char.money or 0, 32)
                net.WriteInt(char.bankmoney or 0, 32)
                net.WriteUInt(char.team or 1, 8)
                net.WriteString(char.bodygroups or "")
            end

            net.Send(ply)
        end
    end)
    query:Execute()
end

function Monarch.CharSystem.ActivateCharacter(ply, charData)
    if not IsValid(ply) or not charData then return end

    ply.MonarchLastCharID = charData.id

    if Monarch.GetWhitelistLevels and Monarch_SetWhitelistNWBulk then
        local wl = Monarch.GetWhitelistLevels(ply) or {}
        Monarch_SetWhitelistNWBulk(ply, wl)
    end

    Monarch.SetupPlayerFromChar(ply, charData)

    Monarch_ResetAllBodygroups(ply)

    ply:Freeze(false)
    ply:Spawn()

    if Monarch.Skills then
        if Monarch.Skills.SyncRegistryToClient then Monarch.Skills.SyncRegistryToClient(ply) end
        if Monarch.Skills.SyncToClient then Monarch.Skills.SyncToClient(ply) end
    end

    Monarch_RunCharacterActivatedHooks(ply, charData)

    net.Start("Monarch_CharActivated")
    net.Send(ply)
end

net.Receive("Monarch_CharCreate", function(len, ply)

    if (ply.NextCreate or 0) > CurTime() then 
        return 
    end
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

    if not mysql then
        ply:ChatAddText(Color(255, 100, 100), "Database unavailable!")
        return
    end

    local plyID = ply:SteamID()

    if string.len(charName) < 3 or string.len(charName) > 48 then
        ply:ChatAddText(Color(255, 100, 100), "Name must be between 3-48 characters!")
        return
    end

    local checkQuery = mysql:Select("monarch_players")
    checkQuery:Where("steamid", plyID)
    checkQuery:Callback(function(result)
        if not IsValid(ply) then return end

        if result and #result >= 3 then
            ply:ChatAddText(Color(255, 100, 100), "Maximum characters reached!")
            return
        end

        local insertQuery = mysql:Insert("monarch_players")
        insertQuery:Insert("steamid", plyID)
        insertQuery:Insert("rpname", charName)
        insertQuery:Insert("xp", 0)
        insertQuery:Insert("money", Config.StartingMoney or 500)
        insertQuery:Insert("bankmoney", Config.StartingMoney or 500)
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

        insertQuery:Callback(function(insertResult, status, lastID)
            if not IsValid(ply) then return end

            if not status then
                ply:ChatAddText(Color(255, 100, 100), "Database error during character creation!")
                return
            end

            if not lastID or lastID <= 0 then
                ply:ChatAddText(Color(255, 100, 100), "Character creation failed - invalid ID!")
                return
            end

            ply.MonarchCharJustCreatedID = tostring(lastID)

            timer.Simple(0.1, function()
                if IsValid(ply) then
                    local verifyQuery = mysql:Select("monarch_players")
                    verifyQuery:Where("id", lastID)
                    verifyQuery:Callback(function(verifyResult)
                        if verifyResult and #verifyResult > 0 then
                            local savedChar = verifyResult[1]
                        end
                    end)
                    verifyQuery:Execute()
                end
            end)

            ply:ChatAddText(Color(100, 255, 100), "Character '" .. charName .. "' created!")

            timer.Simple(0.5, function()
                if IsValid(ply) then
                    Monarch.CharSystem.SendCharacterList(ply)
                end
            end)
        end)

        insertQuery:Execute()
    end)
    checkQuery:Execute()

end)

function ResetNeeds(ply)
    ply:SetHunger(100)
    ply:SetHydration(100)
    ply:SetExhaustion(100)
end

net.Receive("Monarch_CharSelect", function(len, ply)
    local charID = net.ReadUInt(32)

    ply.ShouldNeedsLower = true

    ResetNeeds(ply)

    local query = mysql:Select("monarch_players")
    query:Select("id")
    query:Select("rpname")
    query:Select("model")
    query:Select("skin")
    query:Select("team")
    query:Select("bodygroups")
    query:Select("height")
    query:Select("weight")
    query:Select("haircolor")
    query:Select("eyecolor")
    query:Select("age")
    query:Where("id", charID)
    query:Where("steamid", ply:SteamID()) 
    query:Limit(1)

    query:Callback(function(result)
        if not IsValid(ply) then return end
        if not result or #result == 0 then
            ply:ChatAddText(Color(255, 100, 100), "Character not found!")
            return
        end

        local charData = result[1]
        charData.name = charData.rpname 

        Monarch.CharSystem.ActivateCharacter(ply, charData)
    end)

    query:Execute()
end)

Monarch = Monarch or {}
Monarch.Inventory = Monarch.Inventory or {}
Monarch.Inventory.Data = Monarch.Inventory.Data or {}

function Monarch.CharSystem.LoadCharacterByID(ply, charID)
    if not IsValid(ply) or not charID then return end

    local query = mysql:Select("monarch_players")
    query:Where("id", charID)
    query:Where("steamid", ply:SteamID()) 
    query:Limit(1)
    query:Callback(function(result)
        if not IsValid(ply) then return end
        if not result or #result == 0 then
            ply:ChatAddText(Color(255, 100, 100), "Failed to load character (not found)!")
            return
        end

        local charData = result[1]
        charData.name = charData.rpname 

        Monarch.SetupPlayerFromChar(ply, charData)
        ply.MonarchLastCharID = charID 
    end)
    query:Execute()
end

hook.Add("PlayerSpawn", "Monarch_AutoLoadLastCharacter", function(ply)

    if ply.MonarchLastCharID and ply.MonarchActiveChar then
        timer.Simple(0, function()
            if not IsValid(ply) then return end
            local char = ply.MonarchActiveChar

            if char.team and tonumber(char.team) then
                ply:Monarch_SetTeam(tonumber(char.team))
            end

            if char.model and char.model ~= "" then
                ply:SetModel(char.model)
            end
            if char.skin then
                ply:SetSkin(tonumber(char.skin) or 0)
            end

            if char.bodygroups and char.bodygroups ~= "" and char.bodygroups ~= "{}" then
                local success, bodygroups = pcall(util.JSONToTable, char.bodygroups)
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

            if char.name or char.rpname then
                if ply.SetRPName then
                    ply:SetRPName(char.name or char.rpname, false)
                else
                    ply:SetNWString("rpname", char.name or char.rpname)
                end
            end

            ply:SetNWString("CharHeight", char.height or "")
            ply:SetNWString("CharWeight", char.weight or "")
            ply:SetNWString("CharHairColor", char.haircolor or "")
            ply:SetNWString("CharEyeColor", char.eyecolor or "")
            ply:SetNWInt("CharAge", tonumber(char.age) or 0)
        end)
    end
end)

hook.Add("PlayerSpawn", "Monarch_PostSpawnReapplyChar", function(ply)
    timer.Simple(3, function()
        if not IsValid(ply) then return end
        local c = ply.MonarchActiveChar
        if not c then return end

        if c.team and tonumber(c.team) then
            if ply.Monarch_SetTeam then
                ply:Monarch_SetTeam(tonumber(c.team))
            else
                ply:SetTeam(tonumber(c.team))
            end
        end

        if c.model and c.model ~= "" then
            ply:SetModel(c.model)
        end
        if c.skin then
            ply:SetSkin(tonumber(c.skin) or 0)
        end

        if c.bodygroups and c.bodygroups ~= "" and c.bodygroups ~= "{}" then
            local success, bodygroups = pcall(util.JSONToTable, c.bodygroups)
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

        if c.name or c.rpname then
            if ply.SetRPName then
                ply:SetRPName(c.name or c.rpname, false)
            else
                ply:SetNWString("rpname", c.name or c.rpname)
            end
        end

        ply:SetNWString("CharHeight", c.height or "")
        ply:SetNWString("CharWeight", c.weight or "")
        ply:SetNWString("CharHairColor", c.haircolor or "")
        ply:SetNWString("CharEyeColor", c.eyecolor or "")
        ply:SetNWInt("CharAge", tonumber(c.age) or 0)
    end)
end)

hook.Add("PlayerDeath", "Monarch_DeathScreen", function(ply)
    net.Start("Monarch_InitDeathScreen")
    net.Send(ply)
end)

function Monarch.SaveInventoryPData(ply, inv)
    if not IsValid(ply) then return end
    local charid = (ply.MonarchActiveChar and ply.MonarchActiveChar.id) or ply.MonarchLastCharID
    if not charid then return end

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
                    storagetype = tonumber(item.storagetype or 1) or 1,
                    clip = math.floor(tonumber(item.clip or 0) or 0),
                })
            end
        end
    end

    local json = util.TableToJSON(flat) or "[]"
    ply:SetPData("MonarchInventory_" .. tostring(charid), json)
end

function Monarch.LoadInventoryFromPData(ply, charid)
    if not IsValid(ply) or not charid then return end

    local json = ply:GetPData("MonarchInventory_" .. tostring(charid), "[]")
    local raw = util.JSONToTable(json) or {}
    local inv = {}
    local maxSlots = MONARCH_INV_MAX_SLOTS or 20

    local function addItem(slot, item)
        local cls = tostring(item.class or item.id or "")
        if not slot or slot < 1 or slot > maxSlots or cls == "" then return end
        slot = math.floor(slot)
        inv[slot] = {
            id = cls,
            class = cls,
            amount = math.max(1, math.floor(tonumber(item.amount or 1) or 1)),
            equipped = item.equipped or false,
            restricted = item.restricted or false,
            storagetype = tonumber(item.storagetype or 1) or 1,
            clip = math.floor(tonumber(item.clip or 0) or 0),
        }
    end

    if istable(raw) and raw.__charid and raw.items then
        raw = raw.items
    end

    if istable(raw) then
        if #raw > 0 then
            for _, item in ipairs(raw) do
                addItem(tonumber(item.slot or 0), item)
            end
        else
            for slot, item in pairs(raw) do
                addItem(tonumber(item.slot or slot), item)
            end
        end
    end

    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}

    local sid = ply:SteamID64()
    Monarch.Inventory.Data[sid] = inv

    Monarch.Inventory.Data[charid] = Monarch.Inventory.Data[charid] or {}
    Monarch.Inventory.Data[charid][1] = {}
    for i = 1, maxSlots do
        local item = inv[i]
        if item then
            Monarch.Inventory.Data[charid][1][i] = table.Copy(item)
        end
    end

    ply.beenInvSetup = true
    ply._invLoaded = true

    net.Start("Monarch_Inventory_Update")
        net.WriteTable(inv)
    net.Send(ply)
end

hook.Add("OnCharacterActivated", "Monarch_LoadInventoryOnActivate", function(ply, charData)
    if not IsValid(ply) or not charData then return end

    local steamid = ply:SteamID64()
    local charid = charData.id

    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}
    Monarch.Inventory.Data[steamid] = Monarch.Inventory.Data[steamid] or {}

    if Monarch.Inventory and Monarch.Inventory.LoadForOwner then
        Monarch.Inventory.LoadForOwner(ply, charid)

        timer.Simple(0.5, function()
            if not IsValid(ply) then return end
            local inv = Monarch.Inventory.Data and Monarch.Inventory.Data[steamid]
            if not inv or table.Count(inv) == 0 then
                Monarch.LoadInventoryFromPData(ply, charid)
            end
        end)
    else
        Monarch.LoadInventoryFromPData(ply, charid)
    end
end)

hook.Add("PlayerDisconnected", "Monarch_SaveInventoryOnDisconnect", function(ply)
    if not IsValid(ply) or not ply.MonarchActiveChar then return end
    local steamid = ply:SteamID64()
    local charid = ply.MonarchActiveChar.id
    local inv = Monarch.Inventory.Data and Monarch.Inventory.Data[steamid]
    if not inv or not charid then return end
    if Monarch.Inventory and Monarch.Inventory.SaveForOwner then
        Monarch.Inventory.SaveForOwner(ply, charid, inv)
    end
    Monarch.SaveInventoryPData(ply, inv)
end)

Monarch.VoiceModes = Monarch.VoiceModes or {}

local playerVoiceModes = {}

function Monarch.VoiceModes.SetPlayerMode(ply, modeId)
    if not IsValid(ply) then return end

    local mode = Monarch.VoiceModes.GetMode(modeId)
    if not mode then
        ErrorNoHalt("[Monarch VoiceModes] Attempted to set invalid mode: " .. tostring(modeId) .. "\n")
        return
    end

    playerVoiceModes[ply:SteamID()] = modeId

    net.Start("Monarch_VoiceMode_Notify")
        net.WriteString(modeId)
        net.WriteString(mode.name)
        net.WriteColor(mode.color)
    net.Send(ply)
end

function Monarch.VoiceModes.GetPlayerMode(ply)
    if not IsValid(ply) then return Monarch.VoiceModes.DefaultMode end

    local modeId = playerVoiceModes[ply:SteamID()]
    if not modeId then
        return Monarch.VoiceModes.DefaultMode
    end

    return modeId
end

net.Receive("Monarch_VoiceMode_Set", function(len, ply)
    if not IsValid(ply) then return end

    local newModeId = net.ReadString()

    if not Monarch.VoiceModes.GetMode(newModeId) then
        return
    end

    Monarch.VoiceModes.SetPlayerMode(ply, newModeId)
end)

hook.Add("PlayerSpawn", "Monarch_VoiceMode_Initialize", function(ply)
    if not IsValid(ply) then return end

    if not playerVoiceModes[ply:SteamID()] then
        Monarch.VoiceModes.SetPlayerMode(ply, Monarch.VoiceModes.DefaultMode)
    else

        local currentMode = playerVoiceModes[ply:SteamID()]
        local mode = Monarch.VoiceModes.GetMode(currentMode)
        if mode then
            net.Start("Monarch_VoiceMode_Notify")
                net.WriteString(currentMode)
                net.WriteString(mode.name)
                net.WriteColor(mode.color)
            net.Send(ply)
        end
    end
end)

hook.Add("PlayerDisconnected", "Monarch_VoiceMode_Cleanup", function(ply)
    if IsValid(ply) then
        playerVoiceModes[ply:SteamID()] = nil
    end
end)

hook.Add("PlayerCanHearPlayersVoice", "Monarch_VoiceMode_Distance", function(listener, talker)
    if not IsValid(listener) or not IsValid(talker) then return false end

    if listener == talker then return true end

    local talkerMode = Monarch.VoiceModes.GetPlayerMode(talker)
    local mode = Monarch.VoiceModes.GetMode(talkerMode)

    if not mode then

        mode = Monarch.VoiceModes.GetMode(Monarch.VoiceModes.DefaultMode)
    end

    if not mode then

        return true, true 
    end

    local distance = listener:GetPos():Distance(talker:GetPos())

    if distance <= mode.distance then
        return true, true 
    else
        return false 
    end
end)

hook.Add("PlayerDeath", "Monarch_ResetNeedsOnDeath", function(ply)
    ResetNeeds(ply)
end)