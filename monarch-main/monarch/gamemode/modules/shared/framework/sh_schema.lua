Monarch.Schema = Monarch.Schema or {}

function Monarch.Schema.ReloadCurrentRealm()
    Monarch.Schema._loadedRealms = Monarch.Schema._loadedRealms or {}
    local realmKey = SERVER and "server" or "client"
    Monarch.Schema._loadedRealms[realmKey] = nil
    Monarch.SchemaLoaded = false
    Monarch.Schema.Load()
end

function Monarch.Schema.Load()
    Monarch.Schema._loadedRealms = Monarch.Schema._loadedRealms or {}
    local realmKey = SERVER and "server" or "client"
    if Monarch.Schema._loadedRealms[realmKey] then
        return
    end

    local gm = gmod and gmod.GetGamemode and gmod.GetGamemode() or GAMEMODE
    local folder = engine.ActiveGamemode() or (gm and gm.FolderName) or "monarch"
    SCHEMA_NAME = folder
    Config = Config or {}

    local mapName = string.lower(game.GetMap())
    local mapPath = SCHEMA_NAME.."/schema/config/maps/"..mapName..".lua"
    if file.Exists(mapPath, "LUA") then
        print("[Monarch] Loading map config: "..mapPath)
        Monarch.LoadFile(mapPath)
    else

        local altPath = SCHEMA_NAME.."/schema/config/maps/"..mapName..".lua"
        if file.Exists(altPath, "LUA") then
            print("[Monarch] Loading fallback map config: "..altPath)
            Monarch.LoadFile(altPath)
        else
            print("[Monarch] Map config not found: "..mapPath)
        end
    end

    local function includeDirNoMCfg(dir)
        local files, folders = file.Find(dir.."/*", "LUA")
        for _, f in ipairs(files) do
            Monarch.LoadFile(dir.."/"..f)
        end
        for _, sub in ipairs(folders) do
            if sub == "maps" then continue end
            includeDirNoMCfg(dir.."/"..sub)
        end
    end

    includeDirNoMCfg(SCHEMA_NAME.."/schema/config")
    Monarch.includeDir(SCHEMA_NAME.."/schema/scripts")
    Monarch.includeDir(SCHEMA_NAME.."/schema/scripts/hooks")
    Monarch.includeDir(SCHEMA_NAME.."/schema/scripts/vgui")
    Monarch.includeDir(SCHEMA_NAME.."/modules")

    local modRoot = SCHEMA_NAME.."/modules"
    local _, modFolders = file.Find(modRoot.."/*", "LUA")
    for _, modName in ipairs(modFolders) do
        Monarch.LoadEntites(modRoot.."/"..modName)
    end
    Monarch.includeDir(SCHEMA_NAME.."/schema/teams")

    Config = Config or {}
    if Config.SchemaName then
        GM.Name = Config.SchemaName
    end

    Monarch.Schema._loadedRealms[realmKey] = true
end

if not Monarch.Schema._refreshHookRegistered then
    Monarch.Schema._refreshHookRegistered = true
    hook.Add("OnReloaded", "Monarch.Schema.ReloadOnRefresh", function()
        if not Monarch or not Monarch.Schema or not Monarch.Schema.Load then return end
        Monarch.Schema.ReloadCurrentRealm()
    end)
end

function Monarch.LoadEntites(path)
    local files, folders

    local function IncludeFiles(path2, clientOnly)
        if (SERVER and file.Exists(path2.."init.lua", "LUA") or CLIENT) then
            if (clientOnly and CLIENT) or SERVER then
                include(path2.."init.lua")
            end

            if (file.Exists(path2.."cl_init.lua", "LUA")) then
                if SERVER then
                    AddCSLuaFile(path2.."cl_init.lua")
                else
                    include(path2.."cl_init.lua")
                end
            end

            return true
        elseif (file.Exists(path2.."shared.lua", "LUA")) then
            AddCSLuaFile(path2.."shared.lua")
            include(path2.."shared.lua")

            return true
        end

        return false
    end

    local function HandleEntityInclusion(folder, variable, register, default, clientOnly)
        files, folders = file.Find(path.."/"..folder.."/*", "LUA")
        default = default or {}

        for k, v in ipairs(folders) do
            local path2 = path.."/"..folder.."/"..v.."/"

            _G[variable] = table.Copy(default)
                _G[variable].ClassName = v

                if (IncludeFiles(path2, clientOnly) and !client) then
                    if (clientOnly) then
                        if (CLIENT) then
                            register(_G[variable], v)
                        end
                    else
                        register(_G[variable], v)
                    end
                end
            _G[variable] = nil
        end

        for k, v in ipairs(files) do
            local niceName = string.StripExtension(v)

            _G[variable] = table.Copy(default)
                _G[variable].ClassName = niceName
                AddCSLuaFile(path.."/"..folder.."/"..v)
                include(path.."/"..folder.."/"..v)

                if (clientOnly) then
                    if (CLIENT) then
                        register(_G[variable], niceName)
                    end
                else
                    register(_G[variable], niceName)
                end
            _G[variable] = nil
        end
    end

    HandleEntityInclusion("entities", "ENT", scripted_ents.Register, {
        Type = "anim",
        Base = "base_gmodentity",
        Spawnable = true
    })

    HandleEntityInclusion("weapons", "SWEP", weapons.Register, {
        Primary = {},
        Secondary = {},
        Base = "weapon_base"
    })

    HandleEntityInclusion("effects", "EFFECT", effects and effects.Register, nil, true)
end
