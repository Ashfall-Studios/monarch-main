return function(PANEL)
    if not CLIENT then return end
    if not PANEL then return end

    local registerMainUISection = Monarch.LoadFile("modules/interfaces/inventory/sections/cl_main.lua")
    if isfunction(registerMainUISection) then
        registerMainUISection(PANEL)
    end
end
