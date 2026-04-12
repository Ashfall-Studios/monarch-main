return function()
    if not CLIENT then return end

    Monarch = Monarch or {}
    Monarch.InventoryUI = Monarch.InventoryUI or {}
    Monarch.InventoryUI.Tabs = Monarch.InventoryUI.Tabs or {}

    function Monarch.InventoryUI.GetDisplayName(ply)
        if not IsValid(ply) then return "" end
        return (ply.GetRPName and ply:GetRPName()) or ply:Nick()
    end
end
