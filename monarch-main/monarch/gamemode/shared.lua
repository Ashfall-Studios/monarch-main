Monarch = Monarch or {}
lib = lib or {}
Config = Config or {}

GM.Name = "monarch"
DeriveGamemode("sandbox")

CreateClientConVar("monarch_thirdperson", "0", true, false)
CreateClientConVar("monarch_shouldshowlegs", "0", true, false)
CreateClientConVar("monarch_thirdperson_left", "0", true, false)

if (SERVER) then
	concommand.Remove("gm_save")
	concommand.Remove("gmod_admin_cleanup")
	RunConsoleCommand("sv_defaultdeployspeed", 1)
end

function Monarch.LoadFile(fileName)
	if (!fileName) then
		error("[Monarch Bootstrapper] File to include has no name!")
	end

	local function hasLuaData(path)
		local size = file.Size(path, "LUA")
		size = tonumber(size)
		return size and size > 0
	end

	local function normalizePath(path)
		path = tostring(path or "")
		path = path:gsub("\\", "/")
		path = path:gsub("^/+", "")
		return path
	end

	local function addCandidate(candidates, seen, path)
		path = normalizePath(path)
		if path == "" or seen[path] then
			return
		end

		seen[path] = true
		table.insert(candidates, path)
	end

	local function resolveLuaPath(path)
		local cleaned = normalizePath(path)
		local stripped = cleaned
		stripped = stripped:gsub("^monarch/gamemode/", "")
		stripped = stripped:gsub("^gamemode/", "")

		local candidates = {}
		local seen = {}
		addCandidate(candidates, seen, cleaned)
		addCandidate(candidates, seen, stripped)
		addCandidate(candidates, seen, "gamemode/" .. stripped)
		addCandidate(candidates, seen, "monarch/gamemode/" .. stripped)

		for _, candidate in ipairs(candidates) do
			if hasLuaData(candidate) then
				return candidate
			end
		end

		return nil
	end

	local resolvedFileName = resolveLuaPath(fileName)
	if not resolvedFileName then
		ErrorNoHalt(string.format("[Monarch Bootstrapper] Skipping unresolved include path: %s\n", tostring(fileName)))
		return
	end

	local includeResult

	if resolvedFileName:find("sv_") then
		if (SERVER) then
			includeResult = include(resolvedFileName)
		end
	elseif resolvedFileName:find("sh_") then
		if (SERVER) then
			AddCSLuaFile(resolvedFileName)
		end
		includeResult = include(resolvedFileName)
	elseif resolvedFileName:find("cl_") then
		if (SERVER) then
			AddCSLuaFile(resolvedFileName)
		else
			includeResult = include(resolvedFileName)
		end
	elseif resolvedFileName:find("rq_") then
		if (SERVER) then
			AddCSLuaFile(resolvedFileName)
		end

		local requestName = string.GetFileFromFilename(resolvedFileName):gsub("%.lua$", "")
		includeResult = include(resolvedFileName)
		_G[requestName] = includeResult
	else
		MsgC(Color(255,0,0), "[Monarch WARNING]", Color(83,143,239), " Defaulting to SHARED file (this occurs if there is no tag cl_, sh_, sv_, in front of the file name)! \n", Color(255,0,0), "File name: ", Color(83,143,239), resolvedFileName.."\n")
		if (SERVER) then
			AddCSLuaFile(resolvedFileName)
		end
		includeResult = include(resolvedFileName)
	end

	return includeResult
end

function Monarch.includeDir(directory, hookMode, variable, uid)
	local files, folders = file.Find(directory.."/*", "LUA")

	for k, v in ipairs(files) do
    	if hookMode then
    		Monarch.Schema.LoadHooks(directory.."/"..v, variable, uid)
    	else
    		Monarch.LoadFile(directory.."/"..v)
    	end
	end

	for k, v in ipairs(folders) do
		if v == "entities" or v == "weapons" then
			continue
		end
		local subdir = directory.."/"..v
		Monarch.includeDir(subdir, hookMode, variable, uid)
	end
end

Monarch.includeDir("monarch/gamemode/libs")
Monarch.includeDir("monarch/gamemode/sync")
Monarch.includeDir("monarch/gamemode/plugins")

Monarch.includeDir("monarch/gamemode/modules")

Monarch.includeDir("monarch/gamemode/modules/config")
Monarch.includeDir("monarch/gamemode/modules/client")
Monarch.includeDir("monarch/gamemode/modules/shared")
Monarch.includeDir("monarch/gamemode/modules/server")
Monarch.includeDir("monarch/gamemode/modules/hooks")
Monarch.includeDir("monarch/gamemode/modules/interfaces")

Monarch.Schema = Monarch.Schema or {}
if Monarch.Schema.Load and not Monarch.SchemaLoaded then
	Monarch.Schema.Load()
	Monarch.SchemaLoaded = true
end

do
	local function _MonarchPrecacheModelSafe(modelPath, seen)
		if not (util and util.PrecacheModel) then return end
		if not isstring(modelPath) then return end
		modelPath = string.Trim(modelPath)
		if modelPath == "" then return end
		if seen and seen[modelPath] then return end
		if seen then seen[modelPath] = true end
		util.PrecacheModel(modelPath)
	end

	local function _MonarchPrecacheModelCollection(value, seen)
		if isstring(value) then
			_MonarchPrecacheModelSafe(value, seen)
			return
		end

		if not istable(value) then return end
		for _, v in pairs(value) do
			if isstring(v) then
				_MonarchPrecacheModelSafe(v, seen)
			elseif istable(v) then
				_MonarchPrecacheModelCollection(v, seen)
			end
		end
	end

	function Monarch.PrecacheConfiguredModels()
		local seen = {}
		_MonarchPrecacheModelSafe(Config and Config.DefaultModel, seen)
		_MonarchPrecacheModelCollection(Config and Config.DefaultModels, seen)
		_MonarchPrecacheModelCollection(Config and Config.CharacterModels, seen)
		_MonarchPrecacheModelCollection(Config and Config.FemaleCharacterModels, seen)

		if istable(Monarch.Team) then
			for _, teamData in pairs(Monarch.Team) do
				if istable(teamData) then
					_MonarchPrecacheModelCollection(teamData.model, seen)
					_MonarchPrecacheModelCollection(teamData.Model, seen)
					_MonarchPrecacheModelCollection(teamData.models, seen)
					_MonarchPrecacheModelCollection(teamData.Models, seen)
				end
			end
		end
	end

	function Monarch.PrecacheInventoryItemModels()
		local seen = {}
		local items = Monarch and Monarch.Inventory and Monarch.Inventory.Items
		if not istable(items) then return end

		for _, def in pairs(items) do
			if istable(def) then
				_MonarchPrecacheModelSafe(def.Model or def.model, seen)
			end
		end
	end

	timer.Simple(0, function()
		if not Monarch then return end
		Monarch.PrecacheConfiguredModels()
		Monarch.PrecacheInventoryItemModels()
	end)
end

if SERVER and not Monarch._CharSysLoaded then 
	if file.Exists("monarch/gamemode/modules/server/sv_char.lua", "LUA") then
		include("monarch/gamemode/modules/server/sv_char.lua")
		Monarch._CharSysLoaded = true
		MsgC(Color(83,143,239), "[Monarch] Forced include (INVESTIGATE!).\n")
	end
end

if SERVER then
	Monarch.YML = {}
	local dbFile = "monarch/config.yml"

	Monarch.DB = Config.DBInfo or {
		ip = "localhost",
		username = "root",
		password = "",
		database = "Monarch",
		port = 3306
	}

	local dbConfLoaded = false

	if file.Exists(dbFile, "DATA") then
		local worked, err = pcall(function() Monarch.Yaml.Read("data/"..dbFile) end) 

		if worked then
			local dbConf = Monarch.Yaml.Read("data/"..dbFile)

			if dbConf and type(dbConf) == "table" then
				if dbConf.db and type(dbConf.db) == "table" then
					table.Merge(Monarch.DB, dbConf.db)
					print("[Monarch] [config.yml] Loaded release database config file!")
					dbConfLoaded = true
				end
			end

				if dbConf.schemadb and dbConf.schemadb[engine.ActiveGamemode()] then
					Monarch.DB.database = dbConf.schemadb[engine.ActiveGamemode()]
				end

				Monarch.YML = dbConf
		else
			print("[Monarch] [config.yml] Error: "..err)
		end
	end

	Monarch.YML = Monarch.YML or {}
	Monarch.YML.apis = Monarch.YML.apis or {}

	if not dbConfLoaded then
		print("[Monarch] [config.yml] No database configuration found. Assuming development database configuration. If this is a live server please setup this file!")
	end
end

if SERVER then
	mysql:Connect(Monarch.DB.ip, Monarch.DB.username, Monarch.DB.password, Monarch.DB.database, Monarch.DB.port)
end

function GM:ScalePlayerDamage(ply, group, dat)
	local preHandled = hook.Run("Monarch_PreScalePlayerDamage", ply, group, dat)
	if preHandled == true then
		return
	end

	if (group == HITGROUP_HEAD) then
		dat:ScaleDamage(dat:IsBulletDamage() and 1.3 or 1.1)
	end

	if (group == HITGROUP_LEFTARM or group == HITGROUP_RIGHTARM or group == HITGROUP_LEFTLEG or group == HITGROUP_RIGHTLEG) then
		dat:ScaleDamage(0.85)
	end

	hook.Run("Monarch_PostScalePlayerDamage", ply, group, dat)
end

function GM:CanPlayerSuicide(ply)
	local canSuicide = hook.Run("Monarch_CanPlayerSuicide", ply)
	if canSuicide == true then
		return true
	end

	hook.Run("Monarch_PlayerSuicideBlocked", ply)
	ply:Notify("You can't commit suicide.")

	return false
end

function GM:PlayerStepSoundTime( ply, iType, bWalking ) 
	if not IsValid(ply) then return end

	local fStepTime = 350
	local vel = ply:GetVelocity():Length2D()

	if ( iType == STEPSOUNDTIME_NORMAL || iType == STEPSOUNDTIME_WATER_FOOT ) then

		if ( vel <= 80 ) then
			fStepTime = 500
		elseif ( vel <= 150 ) then
 			fStepTime = 420 
		elseif ( vel <= 250 ) then
			fStepTime = 350
		else
			fStepTime = 250
		end

	elseif ( iType == STEPSOUNDTIME_ON_LADDER ) then

		fStepTime = 450

	elseif ( iType == STEPSOUNDTIME_WATER_KNEE ) then

		fStepTime = 600

	end

	if ( ply:Crouching() ) then
		fStepTime = fStepTime + 50
	end

	return fStepTime

end

if SERVER then
	local matSounds = {
		[MAT_CONCRETE] = {"player/footsteps/concrete1.wav", "player/footsteps/concrete2.wav", "player/footsteps/concrete3.wav", "player/footsteps/concrete4.wav"},
		[MAT_METAL]    = {"player/footsteps/metal1.wav", "player/footsteps/metal2.wav", "player/footsteps/metal3.wav", "player/footsteps/metal4.wav"},
		[MAT_DIRT]     = {"player/footsteps/dirt1.wav", "player/footsteps/dirt2.wav", "player/footsteps/dirt3.wav", "player/footsteps/dirt4.wav"},
		[MAT_WOOD]     = {"player/footsteps/wood1.wav", "player/footsteps/wood2.wav", "player/footsteps/wood3.wav", "player/footsteps/wood4.wav"},
		[MAT_GRASS]    = {"player/footsteps/grass1.wav", "player/footsteps/grass2.wav", "player/footsteps/grass3.wav", "player/footsteps/grass4.wav"},
		[MAT_SAND]     = {"player/footsteps/sand1.wav", "player/footsteps/sand2.wav", "player/footsteps/sand3.wav", "player/footsteps/sand4.wav"},
		[MAT_GLASS]    = {"player/footsteps/glass1.wav", "player/footsteps/glass2.wav", "player/footsteps/glass3.wav", "player/footsteps/glass4.wav"},
		[MAT_TILE]     = {"player/footsteps/tile1.wav", "player/footsteps/tile2.wav", "player/footsteps/tile3.wav", "player/footsteps/tile4.wav"},
		[MAT_FLESH]    = {"player/footsteps/mud1.wav", "player/footsteps/mud2.wav", "player/footsteps/mud3.wav", "player/footsteps/mud4.wav"},
		[MAT_COMPUTER] = {"player/footsteps/metal1.wav", "player/footsteps/metal2.wav", "player/footsteps/metal3.wav", "player/footsteps/metal4.wav"},
		[MAT_SNOW]     = {"player/footsteps/sand1.wav", "player/footsteps/sand2.wav", "player/footsteps/sand3.wav", "player/footsteps/sand4.wav"},
	}

	for _, bank in pairs(matSounds) do
		for _, snd in ipairs(bank) do
			util.PrecacheSound(snd)
		end
	end

	local defaultSounds = matSounds[MAT_CONCRETE]

	local function pickSound(matType)
		local bank = matSounds[matType] or defaultSounds
		return bank[math.random(1, #bank)]
	end

	hook.Add("Think", "Monarch_ForceFootsteps", function()
		for _, ply in player.Iterator() do
			if not (IsValid(ply) and ply:Alive() and ply:OnGround()) then
				ply._LastFootstepVel = nil
				continue
			end

			local vel = ply:GetVelocity():Length2D()

			if vel < 5 then
				ply._LastFootstepVel = nil
				continue
			end

			local stepInterval = 0.35
			if vel <= 65 then
				stepInterval = 0.5
			else
				return
			end

			local now = CurTime()
			ply._NextStepTime = ply._NextStepTime or now

			if now >= ply._NextStepTime then
				local pos = ply:GetPos()
				local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
				local start = Vector(pos.x, pos.y, pos.z + mins.z + 1)
				local tr = util.TraceHull({
					start = start,
					endpos = start - Vector(0, 0, 72),
					mins = Vector(-4, -4, 0),
					maxs = Vector(4, 4, 4),
					filter = ply,
					mask = MASK_PLAYERSOLID_BRUSHONLY
				})

				local matType = tr.MatType or MAT_CONCRETE
				local footstepSound = pickSound(matType)
				local pitch = math.random(95, 105)
				local volume = 1

				local shouldEmit = hook.Run("Monarch_CanEmitForcedFootstep", ply, matType, vel, stepInterval, tr)
				if shouldEmit == false then
					ply._NextStepTime = now + stepInterval
					continue
				end

				local override = hook.Run("Monarch_GetForcedFootstepSound", ply, matType, footstepSound, pitch, volume, tr)
				if istable(override) then
					footstepSound = override.sound or footstepSound
					pitch = tonumber(override.pitch) or pitch
					volume = tonumber(override.volume) or volume
				end

				ply:EmitSound(footstepSound, 43, pitch, volume, CHAN_BODY)
				sound.Play(footstepSound, pos + Vector(0, 0, 40), 43, pitch, volume)
				hook.Run("Monarch_ForcedFootstepPlayed", ply, matType, footstepSound, pitch, volume, tr)
				ply._NextStepTime = now + stepInterval
			end
		end
	end)
end