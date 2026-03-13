return function(PANEL)
    if not CLIENT then return end
    if not PANEL then return end

    local registerFactionsSection = Monarch.LoadFile("modules/interfaces/inventory/sections/cl_factions.lua")
    if isfunction(registerFactionsSection) then
        registerFactionsSection(PANEL)
    end
end
