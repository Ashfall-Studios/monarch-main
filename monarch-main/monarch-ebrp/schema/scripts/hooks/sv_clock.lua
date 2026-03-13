local function CheckClockInventory()
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or not ply:Alive() then continue end

        local hasClock = false
        if ply.HasInventoryItem then
            hasClock = ply:HasInventoryItem("util_rustyclock")
        end

        ply:SetNWBool("MonarchHasClock", hasClock)
    end
end

timer.Create("Monarch_ClockCheck", 1, 0, CheckClockInventory)

hook.Add("PlayerSpawn", "Monarch_ClockSync", function(ply)
    timer.Simple(0.5, function()
        if not IsValid(ply) then return end
        local hasClock = false
        if ply.HasInventoryItem then
            hasClock = ply:HasInventoryItem("util_rustyclock")
        end
        ply:SetNWBool("MonarchHasClock", hasClock)
    end)
end)
