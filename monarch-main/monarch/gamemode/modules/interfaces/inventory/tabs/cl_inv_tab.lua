return function(PANEL)
    if not CLIENT then return end
    if not PANEL then return end

    local registerInventoryCore = Monarch.LoadFile("modules/interfaces/inventory/sections/cl_inv_core.lua")
    if isfunction(registerInventoryCore) then
        registerInventoryCore(PANEL)
    end

    local registerInventorySlots = Monarch.LoadFile("modules/interfaces/inventory/sections/cl_inventory.lua")
    if isfunction(registerInventorySlots) then
        registerInventorySlots(PANEL)
    end

    local registerEquipSlots = Monarch.LoadFile("modules/interfaces/inventory/sections/cl_equip.lua")
    if isfunction(registerEquipSlots) then
        registerEquipSlots(PANEL)
    end
end
