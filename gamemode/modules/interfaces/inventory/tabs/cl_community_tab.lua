return function(PANEL)
    if not CLIENT then return end
    if not PANEL then return end

    local registerCommunitySection = Monarch.LoadFile("modules/interfaces/inventory/sections/cl_community.lua")
    if isfunction(registerCommunitySection) then
        registerCommunitySection(PANEL)
    end
end
