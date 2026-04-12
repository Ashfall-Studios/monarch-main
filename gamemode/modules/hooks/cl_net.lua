net.Receive("CreateMainMenu", function(len,ply)
    vgui.Create("MonarchSplash")
end)

net.Receive("Monarch_SleepingState", function()
    vgui.Create("MonarchSleepScreen")
    LocalPlayer().IsSleeping = true
end)

net.Receive("Monarch_UpdateSleepingState", function()
    local isSleeping = net.ReadBool()
    LocalPlayer().IsSleeping = isSleeping
    if not isSleeping then
        for _, panel in pairs(vgui.GetWorldPanel():GetChildren()) do
            if panel.ClassName == "MonarchSleepScreen" and IsValid(panel) then
                panel:Close()
                break
            end
        end
    end
end)

net.Receive("Monarch_Unconscious", function()
    vgui.Create("MonarchUnconsciousScreen")
end)

net.Receive("Monarch_WakeUp", function()
    for _, panel in pairs(vgui.GetWorldPanel():GetChildren()) do
        if panel.ClassName == "MonarchUnconsciousScreen" and IsValid(panel) then
            panel:Close()
            break
        end
    end
end)

hook.Add("CalcView", "Monarch_UnconsciousView", function(ply, pos, angles, fov)
    if not IsValid(ply) then return end
    if not ply:GetNWBool("IsUnconscious", false) then return end

    local ragdoll = ply:GetNWEntity("UnconsciousRagdoll")
    if not IsValid(ragdoll) then return end

    local headBone = ragdoll:LookupBone("ValveBiped.Bip01_Head1")
    if not headBone then return end

    local headPos, headAng = ragdoll:GetBonePosition(headBone)
    if not headPos then return end

    return {
        origin = headPos + Vector(0, 0, 4),
        angles = headAng,
        fov = fov
    }
end)

local drinking = false
local drinkStart = 0
local drinkDuration = 2 
local drinkEnt = nil

net.Receive("Monarch_DrinkStart", function()
    drinkEnt = net.ReadEntity()
    if not IsValid(drinkEnt) then return end

    drinking = true
    drinkStart = CurTime()
end)

hook.Add("Think", "Monarch_DrinkThink", function()
    if not drinking or not IsValid(drinkEnt) then return end

    local ply = LocalPlayer()

    if not ply:KeyDown(IN_USE) or ply:GetEyeTrace().Entity ~= drinkEnt then
        drinking = false
        drinkEnt = nil
        return
    end

    if CurTime() - drinkStart >= drinkDuration then
        net.Start("Monarch_DrinkFinish")
            net.WriteEntity(drinkEnt)
        net.SendToServer()

        drinking = false
        drinkEnt = nil
    end
end)

net.Receive("Monarch_DeathHandle", function()
    Monarch.HasActiveCharacter = false
end)

net.Receive("monarchRagdollLink", function()
	local ragdoll = net.ReadEntity()

	if IsValid(ragdoll) then
        LocalPlayer().DeathRagdoll = ragdoll
		LocalPlayer().Ragdoll = ragdoll
	end
end)

net.Receive("Monarch_Inventory_Update", function()
    local inventoryData = net.ReadTable()
    local steamID = LocalPlayer():SteamID64()
    Monarch.Inventory = Monarch.Inventory or {}
    Monarch.Inventory.Data = Monarch.Inventory.Data or {}
    Monarch.Inventory.Data[steamID] = inventoryData

    local function FindInventoryPanel(parent)
        if not IsValid(parent) then return nil end
        for _, child in pairs(parent:GetChildren()) do
            if child.ClassName == "MonarchInventory" and IsValid(child) and child.SetupItems then
                return child
            end
            local found = FindInventoryPanel(child)
            if found then return found end
        end
        return nil
    end
    local panel = FindInventoryPanel(vgui.GetWorldPanel())
    if panel then
        panel:SetupItems()
    end
end)
net.Receive("Monarch_OpenDeathScreen", function()
    vgui.Create("MonarchDeathScreen")
end)

net.Receive("Monarch_CPR_Begin", function()
    local duration = math.max(0.05, net.ReadFloat() or 0)
    local label = net.ReadString() or "Performing CPR..."

    if duration <= 0 then return end
    if not isfunction(Monarch_ShowUseBar) then return end

    Monarch._activeCPROverlay = Monarch_ShowUseBar(vgui.GetWorldPanel() or nil, duration, label, function()
        Monarch._activeCPROverlay = nil
    end, true)
end)

net.Receive("Monarch_CPR_Cancel", function()
    if IsValid(Monarch._activeCPROverlay) then
        Monarch._activeCPROverlay:Remove()
    elseif IsValid(Monarch._activeUseOverlay) then
        -- Fallback in case another call replaced the CPR overlay handle.
        Monarch._activeUseOverlay:Remove()
    end

    Monarch._activeCPROverlay = nil
end)
