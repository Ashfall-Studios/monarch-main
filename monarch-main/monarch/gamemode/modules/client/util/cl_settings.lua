Monarch.Settings = Monarch.Settings or {}
Monarch.AdvSettings = Monarch.AdvSettings or {}

function Monarch.DefineSetting(name, settingdata)
    Monarch.Settings[name] = settingdata
    Monarch.LoadSettings()
end

local toBool = tobool
local optX = {["tickbox"] = true} 

function Monarch.GetSetting(name)
    local settingData = Monarch.Settings[name]

    if not settingData then
        return false
    end

    if optX[settingData.type] then
        if settingData.value == nil then
            return settingData.default
        end

        return toBool(settingData.value)
    end

    return settingData.value or settingData.default
end

function Monarch.LoadSettings(silent)
    for v,k in pairs(Monarch.Settings) do
        if not istable(k) then continue end
        if not k.type then continue end
        if k.type == "tickbox" or k.type == "slider" or k.type == "plainint" or k.type == "keybind" then
            local def = k.default
            if k.type == "tickbox" then 
                def = tonumber(k.default) 
            end

            k.value = cookie.GetNumber("Monarch-setting-"..v, def) 
        elseif k.type == "dropdown" or k.type == "textbox" then
            k.value = cookie.GetString("Monarch-setting-"..v, k.default)
        end

        if not silent and k.onChanged then
            k.onChanged(k.value)
        end
    end
end

function Monarch.SetSetting(name, newValue)
    local settingData = Monarch.Settings[name]
    if settingData then
        local oldEffectiveValue = Monarch.GetSetting(name)
        if type(newValue) == "boolean" then 
            newValue = newValue and 1 or 0
        end

        cookie.Set("Monarch-setting-"..name, newValue)
        settingData.value = newValue

        if settingData.onChanged then
            settingData.onChanged(newValue)
        end

        Monarch.LoadSettings(true)

        local newEffectiveValue = Monarch.GetSetting(name)
        if oldEffectiveValue ~= newEffectiveValue then
            hook.Run("Monarch_SettingChanged", name, newEffectiveValue, oldEffectiveValue, newValue)
        end

        return
    end
    return print("[Monarch] Error, could not SetSetting. You've probably got the name wrong! Attempted name: "..name)
end

function Monarch.GetAdvSetting(name)
    return Monarch.AdvSettings[name]
end

function Monarch.LoadAdvSettings()
    if not file.Exists("Monarch/adv_settings.json", "DATA") then
        return "No adv_settings.json file found."
    end

    local f = file.Read("Monarch/adv_settings.json")

    if not f then
        return "Can't read adv_settings.json file."
    end

    local json = util.JSONToTable(f)

    if not json or not istable(json) then
        return "Corrupted music kit file. Check formatting."
    end

    Monarch.AdvSettings = json

    local s = Monarch.Settings and Monarch.Settings["music_soundtrack"]
    if s then
        local adv = Monarch.AdvSettings or {}
        local kits = adv.music_kits or adv.soundtracks or adv.music
        local opts = {"Default"}
        if istable(kits) then
            opts = {}
            for k,_ in pairs(kits) do table.insert(opts, tostring(k)) end
            table.sort(opts, function(a,b) return tostring(a):lower() < tostring(b):lower() end)
        end
        s.options = opts

        local cur = tostring(s.value or s.default or "Default")
        local found = false
        for _,o in ipairs(opts) do if o == cur then found = true break end end
        if not found then
            s.value = s.default or "Default"
            cookie.Set("Monarch-setting-music_soundtrack", s.value)
            if s.onChanged then s.onChanged(s.value) end
        end
    end
end

Monarch.LoadAdvSettings()

concommand.Add("Monarch_reloadadvsettings", function()
    print("[Monarch] Attempting to reload advanced settings...")

    local try = Monarch.LoadAdvSettings()

    if try then
        print("[Monarch] Error when loading advanced settings: "..try)
    else
        print("[Monarch] Successful reload.")
    end
end)

concommand.Add("Monarch_resetsettings", function()
    for v,k in pairs(Monarch.Settings) do
        Monarch.SetSetting(v, k.default)
    end
    print("[Monarch] Settings reset!")
end)

local function DefineSettings()

    if not ConVarExists("monarch_music_enabled") then
        CreateClientConVar("monarch_music_enabled", "1", true, false, "Enable ambient music")
    end
    if not ConVarExists("monarch_music_volume") then
        CreateClientConVar("monarch_music_volume", "0.5", true, false, "Ambient music volume (0.0 - 1.0)")
    end

    Monarch.DefineSetting("hud_vignette", {name="Vignette enabled", category="HUD", type="tickbox", default=true})
    Monarch.DefineSetting("hud_cursor", {name="Display Crosshair", category="HUD", type="tickbox", default=true, desc="Shows the center crosshair."})

    Monarch.DefineSetting("perf_mcore", {name="Multi-core rendering enabled", category="Performance", type="tickbox", default=false, onChanged = function(newValue)
        RunConsoleCommand("gmod_mcore_test", tostring(tonumber(newValue)))

        if newValue == 1 then
            RunConsoleCommand("mat_queue_mode", "-1")
            RunConsoleCommand("cl_threaded_bone_setup", "1")
        else
            RunConsoleCommand("cl_threaded_bone_setup", "0")
        end
    end})
    Monarch.DefineSetting("perf_dynlight", {name="Dynamic light rendering enabled", category="Performance", type="tickbox", default=true, onChanged = function(newValue)
        local v = 0
        if newValue == 1 then
            v = 1
        end

        RunConsoleCommand("r_shadows", v)
        RunConsoleCommand("r_dynamic", v)
    end})

    local function getSoundtrackOptions()
        local adv = Monarch.AdvSettings or {}
        local kits = adv.music_kits or adv.soundtracks or adv.music
        local opts = {"Default"}
        if istable(kits) then
            opts = {}
            for k,_ in pairs(kits) do table.insert(opts, tostring(k)) end
            table.sort(opts, function(a,b) return tostring(a):lower() < tostring(b):lower() end)
        end
        return opts
    end

    Monarch.DefineSetting("ambient_music_enabled", {name="Ambient Music", category="Audio", type="tickbox", default=true, onChanged=function(v)
        RunConsoleCommand("monarch_music_enabled", tostring(tonumber(v)))
    end})

    Monarch.DefineSetting("ambient_music_volume", {name="Ambient Music Volume", category="Audio", type="slider", default=50, minValue=0, maxValue=100, onChanged=function(v)
        local normalizedVolume = (tonumber(v) or 50) / 100
        RunConsoleCommand("monarch_music_volume", tostring(normalizedVolume))
    end})

    Monarch.DefineSetting("viewbob_enable", {name="Ambient Viewbob", category="View", type="tickbox", default=true, onChanged = function(newValue)
        RunConsoleCommand("monarch_viewbob_enable", tostring(tonumber(newValue)))
    end})

    Monarch.DefineSetting("viewbob_intensity", {name="Viewbob Intensity", category="View", type="slider", default=0.5, minValue=0, maxValue=2, onChanged = function(newValue)
        RunConsoleCommand("monarch_viewbob_intensity", tostring(newValue))
    end})

    Monarch.DefineSetting("viewbob_speed", {name="Viewbob Speed", category="View", type="slider", default=1.0, minValue=0.1, maxValue=4, onChanged = function(newValue)
        RunConsoleCommand("monarch_viewbob_speed", tostring(newValue))
    end})

    Monarch.DefineSetting("disable_hunger_sounds", {name="Disable Hunger Warning Sounds", category="Audio", type="tickbox", default=false})
    Monarch.DefineSetting("disable_eng_sounds", {name="Disable Exhaustion Warning Sounds", category="Audio", type="tickbox", default=false})
    Monarch.DefineSetting("immerse_mode", {name="Immersive Mode", category="HUD", type="tickbox", desc="Minimalize the HUD to immerse yourself in the gameplay."})
    Monarch.DefineSetting("bind_inventory", {name="Open Inventory", category="Keybinds", type="keybind", default=KEY_G, desc="Open/close the inventory."})
    
    Monarch.DefineSetting("bind_voicemode", {name="Cycle Voice Mode", category="Keybinds", type="keybind", default=KEY_J, desc="Cycle through voice range/modes."})
    Monarch.DefineSetting("bind_mainmenu", {name="Open Main Menu", category="Keybinds", type="keybind", default=KEY_F3, desc="Open the main menu."})
    Monarch.DefineSetting("bind_reports", {name="Open Reports/Tickets", category="Keybinds", type="keybind", default=KEY_F4, desc="Open the staff tickets hub (staff only)."})
    Monarch.DefineSetting("bind_thirdperson", {name="Toggle Thirdperson", category="Keybinds", type="keybind", default=KEY_F2, desc="Toggle thirdperson camera view."})
end

DefineSettings()

hook.Add("DefineSettings", "MonarchDefaultSettings", DefineSettings)