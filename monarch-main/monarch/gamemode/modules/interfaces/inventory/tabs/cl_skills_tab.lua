return function(PANEL)
    if not CLIENT then return end
    if not PANEL then return end

    local registerSkillsSection = Monarch.LoadFile("modules/interfaces/inventory/sections/cl_skills.lua")
    if isfunction(registerSkillsSection) then
        registerSkillsSection(PANEL)
    end
end
