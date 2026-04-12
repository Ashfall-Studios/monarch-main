Monarch = Monarch or {}
Monarch.Doors = Monarch.Doors or {}

if CLIENT then
    local function GetNW()
        return Monarch.Doors.NW or {}
    end

    local function GetEyeDoor(maxDist)
        maxDist = maxDist or 150
        local ply = LocalPlayer()
        if not IsValid(ply) then return nil end
        local tr = ply:GetEyeTrace()
        if not tr or not tr.Hit or not IsValid(tr.Entity) then return nil end
        if tr.HitPos:DistToSqr(ply:GetShootPos()) > (maxDist*maxDist) then return nil end
        local ent = tr.Entity
        if not Monarch.Doors.IsDoor(ent) then return nil end
        return ent
    end

    local lockCooldown = 0

    local lockingWantsLocked = nil 

    hook.Add("PlayerButtonDown", "Monarch.Doors.Keybinds", function(ply, button)
        if not IsValid(ply) or ply ~= LocalPlayer() then return end

        local ent = GetEyeDoor(150)
        if not IsValid(ent) then return end

        local NW = GetNW()

        if button == MOUSE_LEFT or button == MOUSE_RIGHT then
            if CurTime() < lockCooldown then return end

            if Monarch.Doors.CanPlayerAccessDoor(ply, ent) then

                local activeWeapon = ply:GetActiveWeapon()
                if not IsValid(activeWeapon) or activeWeapon:GetClass() ~= "monarch_keys" then
                    return
                end

                local wantsLocked = (button == MOUSE_LEFT)
                local currentlyLocked = ent:GetNWBool(NW.LOCKED, false)

                if wantsLocked ~= currentlyLocked then
                    net.Start("Monarch.Doors.ToggleLock")
                        net.WriteEntity(ent)
                        net.WriteBool(wantsLocked)
                    net.SendToServer()

                    local lockTime = Monarch.Doors.Config.LockTime or 1
                    lockCooldown = CurTime() + lockTime
                    lockingWantsLocked = wantsLocked

                    local label = wantsLocked and "Locking door..." or "Unlocking door..."
                    if Monarch and Monarch_ShowUseBar then

                        Monarch_ShowUseBar(vgui.GetWorldPanel(), lockTime, label)
                    end
                end
            end
        end

        if button == KEY_F2 then
            if Monarch.Doors.IsPurchaser and Monarch.Doors.IsPurchaser(ply, ent) then
                net.Start("Monarch.Doors.TrySell")
                    net.WriteEntity(ent)
                net.SendToServer()
            elseif Monarch.Doors.IsOwner and Monarch.Doors.IsOwner(ply, ent) then
                return
            else
                net.Start("Monarch.Doors.TryBuy")
                    net.WriteEntity(ent)
                net.SendToServer()
            end
        end
    end)

    local doorHudAlpha = 0
    local doorHudFadeSpeed = 8

    hook.Add("HUDPaint", "Monarch.Doors.HUD", function()

    local ent = GetEyeDoor(150)
    local NW = GetNW()

        local targetAlpha = IsValid(ent) and 255 or 0
        doorHudAlpha = math.Approach(doorHudAlpha, targetAlpha, doorHudFadeSpeed * FrameTime() * 255)

    if doorHudAlpha < 1 then return end
    if not IsValid(ent) then return end

    local doorName = ent:GetNWString("DoorName", "")
    if doorName == "" then return end

        local owner = ent:GetNWEntity(NW.OWNER)
    local group = ent:GetNWString(NW.GROUP, "")
    local hasGroup = group ~= ""
    local forSale = ent:GetNWBool(NW.FORSALE, false)
        local price = math.max(ent:GetNWInt(NW.PRICE, 0), 0)
        local locked = ent:GetNWBool(NW.LOCKED, false)

        local alpha = doorHudAlpha
        local textCol = Color(255, 255, 255, alpha)
        local subCol = Color(230, 230, 230, alpha * 0.75)
        local accentCol = Color(210, 210, 210, alpha * 0.8)

        local sw, sh = ScrW(), ScrH()
        local cx, cy = sw * 0.5, sh * 0.70

        draw.SimpleText(doorName, "InvTitle", cx, cy - 27, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local ownerText = ""
        if IsValid(owner) then
        elseif hasGroup then

        elseif forSale then
            local afford = LocalPlayer().GetMoney and (LocalPlayer():GetMoney() or 0) >= price
            local priceCol = afford and Color(100, 200, 120, alpha) or Color(210, 100, 100, alpha)
            local priceText = price > 0 and (Monarch.FormatMoney and Monarch.FormatMoney(price) or ("$"..tostring(price))) or "Available"
            draw.SimpleText("For Sale", "InvSmall", cx, cy -5, subCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(priceText, "InvMed", cx, cy + 18, priceCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText("Unowned", "InvSmall", cx, cy + 2, subCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        if hasGroup then
            local showForSale = (forSale and not hasGroup) 
            local groupY = showForSale and cy + 36 or cy + 10
            draw.SimpleText(group, "InvSmall", cx, groupY, accentCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local showForSale = (forSale and not hasGroup)
        local hintY = showForSale and (hasGroup and cy + 52 or cy + 40) or (hasGroup and cy + 36 or cy + 24)
        local canAccess = Monarch.Doors.CanPlayerAccessDoor(LocalPlayer(), ent)

        local localOwnsDoor = Monarch.Doors.IsOwner and Monarch.Doors.IsOwner(LocalPlayer(), ent)
        local localIsPurchaser = Monarch.Doors.IsPurchaser and Monarch.Doors.IsPurchaser(LocalPlayer(), ent)

        if localIsPurchaser then
            draw.SimpleText("[F2] Sell  ·  [LMB] Lock  ·  [RMB] Unlock", "InvSmall", cx, hintY, Color(255,255,255, alpha * 0.5), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif localOwnsDoor then
            draw.SimpleText("[LMB] Lock  ·  [RMB] Unlock", "InvSmall", cx, hintY, Color(255,255,255, alpha * 0.5), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif showForSale then

            if canAccess then
                draw.SimpleText("[F2] Purchase  ·  [LMB] Lock  ·  [RMB] Unlock", "InvSmall", cx, hintY, Color(255,255,255, alpha * 0.5), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                draw.SimpleText("[F2] Purchase", "InvSmall", cx, hintY, Color(255,255,255, alpha * 0.5), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        elseif IsValid(owner) then
            if canAccess then
                draw.SimpleText("[LMB] Lock  ·  [RMB] Unlock", "InvSmall", cx, hintY, Color(255,255,255, alpha * 0.5), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        elseif hasGroup then

            if canAccess then
                draw.SimpleText("[LMB] Lock  ·  [RMB] Unlock", "InvSmall", cx, hintY, Color(255,255,255, alpha * 0.5), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        else

            if canAccess then
                draw.SimpleText("[F2] Purchase  ·  [LMB] Lock  ·  [RMB] Unlock", "InvSmall", cx, hintY, Color(255,255,255, alpha * 0.5), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                draw.SimpleText("[F2] Purchase", "InvSmall", cx, hintY, Color(255,255,255, alpha * 0.5), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end)

    if Monarch.RegisterChatCommand then
        Monarch.RegisterChatCommand("/buydoor", {
            adminOnly = false,
            description = "Buy the door you're looking at",
            usage = "/buydoor",
            minArgs = 0,
            callback = function()
                local ent = GetEyeDoor(150)
                if not IsValid(ent) then chat.AddText(Color(200,200,200), "Look at a door.") return end
                net.Start("Monarch.Doors.TryBuy")
                    net.WriteEntity(ent)
                net.SendToServer()
            end
        })
        Monarch.RegisterChatCommand("/selldoor", {
            adminOnly = false,
            description = "Sell your owned door you're looking at",
            usage = "/selldoor",
            minArgs = 0,
            callback = function()
                local ent = GetEyeDoor(150)
                if not IsValid(ent) then chat.AddText(Color(200,200,200), "Look at a door.") return end
                net.Start("Monarch.Doors.TrySell")
                    net.WriteEntity(ent)
                net.SendToServer()
            end
        })
    end
end

