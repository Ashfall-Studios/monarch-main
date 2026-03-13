return function(PANEL)
    if not CLIENT then return end
    if not PANEL then return end

    local registerSettingsSection = Monarch.LoadFile("modules/interfaces/inventory/sections/cl_settings.lua")
    if isfunction(registerSettingsSection) then
        registerSettingsSection(PANEL)
    end
end
