F4Menu = F4Menu or {}

local function CanPlayerUseSpawnMenu(ply)
    if not IsValid(ply) then return false end
    if ply:IsSuperAdmin() then return true end
    return false
end

hook.Add("PlayerButtonDown", "MonarchMainMenuKey", function(ply, key)
    local bind = tonumber(Monarch.GetSetting and Monarch.GetSetting("bind_mainmenu") or KEY_F3) or KEY_F3
    if key == bind then
        if IsValid(g_SpawnMenu) and g_SpawnMenu:IsVisible() then
            if not CanPlayerUseSpawnMenu(LocalPlayer()) then
                g_SpawnMenu:Close()
            end
        end

        RunConsoleCommand("monarch_reloadmainmenu")
        return true
    end
end)

hook.Add("PlayerButtonDown", "MonarchRaiseToggle", function(ply, key)
    local bind = tonumber(Monarch.GetSetting and Monarch.GetSetting("toggle_weaponraised") or KEY_H)
    if key == bind then
        RunConsoleCommand("monarch_toggle_weapon")
        return true
    end
end)

hook.Add("PlayerButtonDown", "MonarchAdminHubKey", function(ply, key)
    local bind = tonumber(Monarch.GetSetting and Monarch.GetSetting("bind_reports") or KEY_F4) or KEY_F4
    if key ~= bind or ply ~= LocalPlayer() then return end
    if not ((Monarch and Monarch.IsAdminRank and Monarch.IsAdminRank(ply)) or ply:IsAdmin()) then return end
    net.Start("Monarch_Tickets_RequestOpen")
    net.SendToServer()
end)

hook.Add("CalcViewModelView", "Monarch_AmbientViewBob", function(wep, vm, oldEyePos, oldEyeAng, eyePos, eyeAng)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if GetConVar("monarch_viewbob_enable"):GetBool() == false then return end
    if not ply:Alive() then return end
    if GetConVar("monarch_thirdperson"):GetBool() then return end

    if (IsValid(Monarch.MainMenu) and Monarch.MainMenu:IsVisible()) or (IsValid(Monarch.card) and Monarch.card:IsVisible()) then
        return
    end

    if not IsValid(wep) or wep:GetClass() ~= "monarch_hands" then
        return
    end

    local intensity = math.Clamp(GetConVar("monarch_viewbob_intensity"):GetFloat(), 0, 2)
    local speedmul = math.Clamp(GetConVar("monarch_viewbob_speed"):GetFloat(), 0.1, 4)

    local t = CurTime() * speedmul

    local speed = math.Clamp(ply:GetVelocity():Length(), 0, 300)
    local moveFactor = Lerp(speed / 300, 0.25, 1)

    local base = 0.4 * intensity
    local bobX = math.sin(t * 1.3) * base * moveFactor
    local bobY = math.sin(t * 1.7) * base * 0.8 * moveFactor
    local bobZ = math.cos(t * 1.1) * base * 0.25 * moveFactor

    local angPitch = math.sin(t * 1.3) * (0.24 * intensity) * moveFactor
    local angYaw = math.cos(t * 1.7) * (0.16 * intensity) * moveFactor

    local newPos = eyePos + eyeAng:Right() * bobY + eyeAng:Up() * bobZ + eyeAng:Forward() * bobX
    local newAng = Angle(eyeAng.p + angPitch, eyeAng.y + angYaw, eyeAng.r)

    return newPos, newAng
end)

Monarch = Monarch or {}
Monarch.InventoryPanel = nil

function Monarch.ToggleInventory()
    if IsValid(Monarch.InventoryPanel) then
        local pnl = Monarch.InventoryPanel
        if pnl.AnimateClose and not pnl._closing then
            pnl:AnimateClose()
        else
            pnl:Remove()
        end
        Monarch.InventoryPanel = nil
        return
    end

    local ok, res = pcall(function()
        local created = vgui.Create("MonarchInventory")
        Monarch.InventoryPanel = created
        return created
    end)
    if not ok then

        print("[Monarch] Failed to open inventory:", res)
    end
end

hook.Add("PlayerButtonDown", "MonarchInventoryOpen", function(ply, button)
    local bind = tonumber(Monarch.GetSetting and Monarch.GetSetting("bind_inventory") or KEY_G) or KEY_G
    if button == bind and ply == LocalPlayer() then
        local shouldOpen = hook.Run("Monarch_OnTryInventory", ply, button)
        if shouldOpen == false then return end
        Monarch.ToggleInventory()
    end
end)

hook.Add("PlayerButtonDown", "MonarchThirdpersonToggle", function(ply, button)
        local bind = tonumber(Monarch.GetSetting and Monarch.GetSetting("bind_thirdperson") or KEY_F2) or KEY_F2
        if button == bind and ply == LocalPlayer() then
        local current = GetConVar("monarch_thirdperson"):GetBool()
        RunConsoleCommand("monarch_thirdperson", current and "0" or "1")
    end
end)

concommand.Add("monarch_inventory_toggle", function()
    Monarch.ToggleInventory()
end, nil, "Toggle Monarch inventory panel open/close")

thirdpersonEnabled = GetConVar("monarch_thirdperson"):GetBool()
Monarch.ThirdPersonLerp = Monarch.ThirdPersonLerp or {}
Monarch.ThirdPersonLerp.Blend = Monarch.ThirdPersonLerp.Blend or 0
Monarch.ThirdPersonLerp.Pos = Monarch.ThirdPersonLerp.Pos or nil
Monarch.ThirdPersonLerp.Ang = Monarch.ThirdPersonLerp.Ang or nil
Monarch.ThirdPersonLerp.Fov = Monarch.ThirdPersonLerp.Fov or nil

if CLIENT then
    CreateClientConVar("monarch_viewbob_enable", "1", true, false, "Enable subtle ambient viewbob")
    CreateClientConVar("monarch_viewbob_intensity", "0.5", true, false, "Viewbob intensity (0-2)")
    CreateClientConVar("monarch_viewbob_speed", "1.0", true, false, "Viewbob speed multiplier")
end

function GM:ShouldDrawLocalPlayer(ply)
    if GetConVar("monarch_thirdperson"):GetBool() then
        return true
    end

    if (Monarch.ThirdPersonLerp and (Monarch.ThirdPersonLerp.Blend or 0) > 0.02) then
        return true
    end
end

local loweredAngles = Angle(30, -30, -25)

hook.Add("Think", "cl_legs.Reload", function()
	local ply = LocalPlayer()
    local thirdpersonEnabled = GetConVar("monarch_thirdperson"):GetBool()
    if ply:InVehicle() then
        return
    end

    if thirdpersonEnabled then
        ply.NoShowLegs = true
    else
        ply.NoShowLegs = false
    end
end)

function GM:CalcView(player, origin, angles, fov)
    local view

    local ragdoll = player.Ragdoll

    local thirdpersonEnabled = GetConVar("monarch_thirdperson"):GetBool()
    local shouldShowLegs = GetConVar("monarch_shouldshowlegs"):GetBool()

    if player:InVehicle() then
        return
    end

    local wantsThirdPerson = thirdpersonEnabled and player:GetViewEntity() == player

    Monarch.ThirdPersonLerp = Monarch.ThirdPersonLerp or {}
    Monarch.ThirdPersonLerp.Blend = Lerp(FrameTime() * 10, Monarch.ThirdPersonLerp.Blend or 0, wantsThirdPerson and 1 or 0)

    if wantsThirdPerson then
        local viewAngles = angles
        local cameraAngles = player:GetAimVector():Angle()
        local mult = GetConVar("monarch_thirdperson_left"):GetBool() and -1 or 1
        local targetpos = Vector(0, 0, 60)

        if player:KeyDown(IN_DUCK) then
            targetpos.z = player:GetVelocity():Length() > 0 and 50 or 40
        end

        local pos = targetpos
        local offset = Vector(25, 10 * mult, 5) 
        cameraAngles.yaw = cameraAngles.yaw + 3

        local t = {
            start = player:GetPos() + pos,
            endpos = player:GetPos() + pos + cameraAngles:Forward() * -offset.x,
            filter = function(ent)
                return ent ~= player and not ent:GetNoDraw()
            end
        }

        local tr = util.TraceLine(t)
        pos = tr.HitPos

        pos = pos + cameraAngles:Right() * offset.y
        pos = pos + cameraAngles:Up() * offset.z

        if tr.Fraction < 1.0 then
            pos = pos + tr.HitNormal * 5
        end

        local wep = player:GetActiveWeapon()
        local fov = 100

        if IsValid(wep) and wep.GetIronsights and not wep.NoThirdpersonIronsights then
            fov = Lerp(FrameTime() * 15, wep.FOVMultiplier, wep:GetIronsights() and wep.IronsightsFOV or 1) * fov
        end

        local delta = player:EyePos() - origin

        local thirdPersonOffsets = {
            forward = 0,
            right = 0,
            up = 0
        }

        local finalPos = pos + delta
        finalPos = finalPos + cameraAngles:Forward() * thirdPersonOffsets.forward
        finalPos = finalPos + cameraAngles:Right() * thirdPersonOffsets.right
        finalPos = finalPos + cameraAngles:Up() * thirdPersonOffsets.up

        local startPos = Monarch.ThirdPersonLerp.Pos or origin
        local startFov = Monarch.ThirdPersonLerp.Fov or fov

        Monarch.ThirdPersonLerp.Pos = LerpVector(FrameTime() * 12, startPos, finalPos)
        Monarch.ThirdPersonLerp.Ang = viewAngles
        Monarch.ThirdPersonLerp.Fov = Lerp(FrameTime() * 12, startFov, fov)

        return {
            origin = Monarch.ThirdPersonLerp.Pos,
            angles = Monarch.ThirdPersonLerp.Ang,
            fov = Monarch.ThirdPersonLerp.Fov,
            drawviewer = true
        }
    elseif (Monarch.ThirdPersonLerp.Blend or 0) > 0.02 then
        local outPos = Monarch.ThirdPersonLerp.Pos and LerpVector(FrameTime() * 12, Monarch.ThirdPersonLerp.Pos, origin) or origin
        local outFov = Monarch.ThirdPersonLerp.Fov and Lerp(FrameTime() * 12, Monarch.ThirdPersonLerp.Fov, fov) or fov

        Monarch.ThirdPersonLerp.Pos = outPos
        Monarch.ThirdPersonLerp.Ang = angles
        Monarch.ThirdPersonLerp.Fov = outFov

        return {
            origin = outPos,
            angles = angles,
            fov = outFov,
            drawviewer = true
        }
    else
        Monarch.ThirdPersonLerp.Pos = nil
        Monarch.ThirdPersonLerp.Ang = nil
        Monarch.ThirdPersonLerp.Fov = nil
    end
end

hook.Add("CalcView", "MenuView", function(player, origin, angles, fov)
    if IsValid(Monarch.card) and Monarch.card:IsVisible() then
        return {
            origin = Config.BackDropCoord or Vector(0,0,0),
            angles = Config.BackDropAngs or Angle(0,0,0),
            fov = 70
        }
    end
    if (IsValid(Monarch.splash) and Monarch.splash:IsVisible()) or (IsValid(Monarch.MainMenu) and Monarch.MainMenu:IsVisible()) then
        local pos, ang = Config.BackDropCoord or Vector(0,0,0), Config.BackDropAngs or Angle(0,0,0)

        if Monarch.MenuScenes and Monarch.MenuScenes.GetCameraView then
            pos, ang = Monarch.MenuScenes:GetCameraView()
        end

        return {
            origin = pos,
            angles = ang,
            fov = 70
        }
    end
end)

hook.Add("CalcView", "Monarch_DeathView", function(ply, origin, angles, fov)
    if not ply:Alive() and IsValid(ply.DeathRagdoll) then
        local rag = ply.DeathRagdoll

        local attachID = rag:LookupAttachment("eyes")
        local pos, ang

        if attachID > 0 then
            local attach = rag:GetAttachment(attachID)
            pos = attach.Pos
            ang = attach.Ang
        else
            local bone = rag:LookupBone("ValveBiped.Bip01_Head1")
            if bone then
                pos, ang = rag:GetBonePosition(bone)
            else
                pos = rag:GetPos() + Vector(0,0,60)
                ang = rag:GetAngles()
            end
        end

        return {
            origin = pos,
            angles = ang,
            fov = fov
        }
    end
end)

concommand.Add("monarch_togglefeet", function(ply, cmd, args)
    local current = GetConVar("monarch_shouldshowlegs"):GetBool()
    RunConsoleCommand("monarch_shouldshowlegs", current and "0" or "1")
    local status = current and "disabled" or "enabled"
end)

local mat_bg_left   = Material("mrp/hud/bar/corner.png")
local mat_bg_center = Material("mrp/hud/bar/center.png")
local mat_bg_right  = Material("mrp/hud/bar/corner_right.png")

local mat_fill_left   = Material("mrp/hud/bar/corner_fill.png")
local mat_fill_center = Material("mrp/hud/bar/center_fill.png")
local mat_fill_right  = Material("mrp/hud/bar/corner_fillb.png")

local barTotalWidth = 350
local barHeight     = 20
local cornerW       = 16
local staminaBarY   = ScrH() - 80

local lastStaminaValue = 100
local lastRawStaminaValue = 100
local lastDecreaseTime = 0
local staminaAlpha     = 0
local staminaTrailValue = 100
local staminaTrailHoldUntil = 0
local staminaTrailForceDropAt = 0
local staminaBufferedValue = 100
local staminaPendingLoss = 0
local staminaLastLossTime = 0

local staminaEpsilon   = 0.1
local staminaHideDelay = 3
local fadeSpeed        = 4
local staminaTrailHoldTime = 0.6
local staminaTrailLerpSpeed = 60
local staminaTrailForcedInterval = 2
local staminaPileupThreshold = 20
local staminaPileupFlushDelay = 0.45

hook.Add("HUDPaint", "MonarchStaminaHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local rawStamina = ply:GetNWFloat("Stamina", ply:GetNWFloat("StaminaDisplay", 100))
    local maxStamina = ply:GetNWFloat("MaxStamina", 100)
    if maxStamina <= 0 then maxStamina = 100 end

    rawStamina = math.Clamp(rawStamina, 0, maxStamina)
    staminaBufferedValue = math.Clamp(staminaBufferedValue, 0, maxStamina)
    staminaTrailValue = math.Clamp(staminaTrailValue, 0, maxStamina)

    local now = CurTime()
    local rawLossDelta = lastRawStaminaValue - rawStamina
    local isLosingRawStamina = rawLossDelta > staminaEpsilon
    local isRegenningRawStamina = rawStamina > (lastRawStaminaValue + staminaEpsilon)

    if isLosingRawStamina then
        staminaPendingLoss = staminaPendingLoss + rawLossDelta
        staminaLastLossTime = now
    end

    -- Batch visible stamina loss into chunks so sprinting does not jitter each point.
    if staminaPendingLoss >= staminaPileupThreshold then
        staminaBufferedValue = math.max(rawStamina, staminaBufferedValue - staminaPendingLoss)
        staminaPendingLoss = 0
    elseif staminaPendingLoss > staminaEpsilon and (isRegenningRawStamina or (now - staminaLastLossTime) >= staminaPileupFlushDelay) then
        staminaBufferedValue = math.max(rawStamina, staminaBufferedValue - staminaPendingLoss)
        staminaPendingLoss = 0
    end

    if rawStamina > staminaBufferedValue then
        staminaBufferedValue = rawStamina
        staminaPendingLoss = 0
    end

    local stamina = staminaBufferedValue
    local isLosingStamina = stamina < (lastStaminaValue - staminaEpsilon)

    if isLosingRawStamina or isLosingStamina then
        lastDecreaseTime = now

        if staminaTrailValue < lastStaminaValue then
            staminaTrailValue = lastStaminaValue
        end
        if staminaTrailForceDropAt <= 0 then
            staminaTrailForceDropAt = now + staminaTrailForcedInterval
        end

        if now < staminaTrailForceDropAt then
            staminaTrailHoldUntil = now + staminaTrailHoldTime
        else
            staminaTrailHoldUntil = 0
        end
    else
        staminaTrailHoldUntil = 0
        staminaTrailForceDropAt = 0
    end

    if stamina > staminaTrailValue then
        staminaTrailValue = stamina
    elseif staminaTrailValue > stamina and now >= staminaTrailHoldUntil then
        staminaTrailValue = math.Approach(staminaTrailValue, stamina, staminaTrailLerpSpeed * FrameTime())

        if isLosingStamina and staminaTrailValue <= (stamina + 0.5) then
            staminaTrailForceDropAt = now + staminaTrailForcedInterval
        end
    end

    lastStaminaValue = stamina
    lastRawStaminaValue = rawStamina

    local showBar = (now - lastDecreaseTime) < staminaHideDelay

    if showBar then
        staminaAlpha = math.Approach(staminaAlpha, 80, fadeSpeed * FrameTime() * 100)
    else
        staminaAlpha = math.Approach(staminaAlpha, 0, fadeSpeed * FrameTime() * 100)
    end
    if staminaAlpha <= 0 then return end

    local barX = (ScrW() - barTotalWidth) / 2
    local y    = staminaBarY

    surface.SetDrawColor(0, 0, 0, math.Clamp(staminaAlpha * 0.45, 0, 90))

    surface.SetDrawColor(255, 255, 255, staminaAlpha)
    surface.SetMaterial(mat_bg_left)
    surface.DrawTexturedRect(barX, y, cornerW, barHeight)
    surface.SetMaterial(mat_bg_center)
    surface.DrawTexturedRect(barX + cornerW, y, barTotalWidth - 2 * cornerW, barHeight)
    surface.SetMaterial(mat_bg_right)
    surface.DrawTexturedRect(barX + barTotalWidth - cornerW, y, cornerW, barHeight)

    local staminaDisplayPercent = math.Clamp(staminaTrailValue / maxStamina, 0, 1)
    local fillWidth = math.floor(barTotalWidth * staminaDisplayPercent)

    if fillWidth > 0 then
        local fillX = barX
        render.SetScissorRect(fillX, y, fillX + fillWidth, y + barHeight, true)

        surface.SetDrawColor(255, 255, 255, staminaAlpha)
        surface.SetMaterial(mat_fill_left)
        surface.DrawTexturedRect(barX, y, cornerW, barHeight)
        surface.SetMaterial(mat_fill_center)
        surface.DrawTexturedRect(barX + cornerW, y, barTotalWidth - 2 * cornerW, barHeight)
        surface.SetMaterial(mat_fill_right)
        surface.DrawTexturedRect(barX + barTotalWidth - cornerW, y, cornerW, barHeight)

        render.SetScissorRect(0, 0, 0, 0, false)
    end

end)

local hidden = {}
hidden["CHudHealth"] = true
hidden["CHudBattery"] = true
hidden["CHudAmmo"] = true
hidden["CHudSecondaryAmmo"] = true
hidden["CHudCrosshair"] = true
hidden["CHudHistoryResource"] = true
hidden["CHudDeathNotice"] = true 
hidden["CHudChat"] = true

function GM:HUDShouldDraw(element)
    if (hidden[element]) then
        return false
    end
    return true
end

function GM:DrawDeathNotice(x, y)
end

hook.Add("Think", "MonarchStaminaClientSync", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local isSprinting = ply:KeyDown(IN_SPEED)
    if ply.LastSprintState ~= isSprinting then
        ply.LastSprintState = isSprinting
        net.Start("MonarchSprintState")
        net.WriteBool(isSprinting)
        net.SendToServer()
    end
end)

function GM:SpawnMenuOpen()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return false end
    return ply:IsSuperAdmin() and ply:Alive()
end

local fadeInTime  = 1
local holdTime    = 0.1
local fadeOutTime = 1

local effectStart = 0
local effectEnd   = 0
local active      = false
local unconscious = false

function StartTiredEffect()
    effectStart = CurTime()
    effectEnd   = effectStart + fadeInTime + holdTime + fadeOutTime
    active      = true
end

hook.Add("HUDPaint", "Monarch_TiredEffect", function()
    if not active then return end

    local now = CurTime()
    if now > effectEnd then
        active = false
        return
    end

    local alpha = 0
    local t = now - effectStart

    if t < fadeInTime then
        alpha = Lerp(t / fadeInTime, 0, 255)
    elseif t < fadeInTime + holdTime then
        alpha = 255
    else
        local outT = (t - fadeInTime - holdTime) / fadeOutTime
        alpha = Lerp(outT, 255, 0)
    end

    surface.SetDrawColor(0, 0, 0, alpha)
    surface.DrawRect(0, 0, ScrW(), ScrH())
end)

timer.Create("Monarch_Exhaustion_Check", 155, 0, function()
    if Monarch.GetSetting("disable_eng_sounds") then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local exhaustion = ply:GetNWInt("Exhaustion", 100)
    local sound = "needs/energy_male_yawn_0" .. math.random(1, 4) ..".wav" 
    if exhaustion <= 60 then
        if exhaustion <= 25 and not ply:GetNWBool("IsUnconscious", false) then

            net.Start("Monarch_TriggerCollapse")
            net.SendToServer()
        else
            ply:EmitSound(sound)
            StartTiredEffect()
        end
    end
end)

timer.Create("Monarch_HungerWarning", 120, 0, function()
    if Monarch.GetSetting("disable_hunger_sounds") then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local exhaustion = ply:GetNWInt("Hunger", 100)
    local sound = "needs/hunger_warning_0" .. math.random(1,4) .. ".mp3" 
    if exhaustion <= 40 then
        ply:EmitSound(sound)
    end
end)

do
    local function requireSuperAdmin()
        local lp = LocalPlayer()
        if not IsValid(lp) then return false end
        if not lp:IsSuperAdmin() then
            if chat and chat.AddText then
                chat.AddText(Color(255, 100, 100), "[Monarch] Superadmin only.")
            end
            return false
        end
        return true
    end

    concommand.Add("monarch_prompt_setlootmodel", function()
        if not requireSuperAdmin() then return end
        local lp = LocalPlayer()
        local tr = lp:GetEyeTrace()
        local ent = IsValid(tr.Entity) and tr.Entity or nil
        if not IsValid(ent) or ent:GetClass() ~= "monarch_loot" then
            Derma_Message("Look at a monarch_loot entity to configure it.", "Set Loot Model", "OK")
            return
        end

        local current = ent:GetModel() or ""
        Thrawn_Derma_StringRequest(
            "Set Loot Model",
            "Enter model path for this loot entity (e.g. models/props_c17/FurnitureShelf001a.mdl):",
            current,
            function(text)
                text = string.Trim(tostring(text or ""))
                if text == "" then return end
                RunConsoleCommand("monarch_setlootmodel", text)
            end,
            function() end,
            "Apply",
            "Cancel"
        )
    end)

    concommand.Add("monarch_prompt_setloot", function(_, _, args)
        if not requireSuperAdmin() then return end
        local lp = LocalPlayer()
        local tr = lp:GetEyeTrace()
        local ent = IsValid(tr.Entity) and tr.Entity or nil
        if not IsValid(ent) or ent:GetClass() ~= "monarch_loot" then
            Derma_Message("Look at a monarch_loot entity to configure it.", "Set Loot Definition", "OK")
            return
        end

        local defDefault = tostring(args and args[1] or "")
        Thrawn_Derma_StringRequest(
            "Set Loot Definition",
            "Enter loot def ID (registered UniqueID):",
            defDefault,
            function(defid)
                defid = string.Trim(tostring(defid or ""))
                if defid == "" then return end

                Thrawn_Derma_StringRequest(
                    "Persistent UID (optional)",
                    "Enter a custom unique ID for persistence, or leave blank to auto-generate:",
                    "",
                    function(uid)
                        uid = string.Trim(tostring(uid or ""))
                        if uid ~= "" then
                            RunConsoleCommand("monarch_setloot", defid, uid)
                        else
                            RunConsoleCommand("monarch_setloot", defid)
                        end
                    end,
                    function()
                        RunConsoleCommand("monarch_setloot", defid)
                    end,
                    "Apply",
                    "Skip"
                )
            end,
            function() end,
            "Next",
            "Cancel"
        )
    end)
end

Monarch = Monarch or {}
Monarch.Music = Monarch.Music or {}

local Music = Monarch.Music
local state = {
    enabled = true,
    volume = 0.6,
    soundtrack = "Default",
    tracks = {},
    chan = nil,
    nextTimer = nil,
    idx = 0,
}

local function killTimer()
    if state.nextTimer and timer.Exists(state.nextTimer) then
        timer.Remove(state.nextTimer)
    end
    state.nextTimer = nil
end

local function stopChannel()
    if IsValid(state.chan) then
        state.chan:Stop()
    end
    state.chan = nil
end

local function getKits()
    local adv = Monarch and Monarch.AdvSettings or {}
    return (adv and (adv.music_kits or adv.soundtracks or adv.music)) or {}
end

local function pickTracksFor(name)
    local kits = getKits()
    local entry = kits[name]
    local tracks = {}
    if istable(entry) then

        for _, p in ipairs(entry) do
            if isstring(p) and p ~= "" then table.insert(tracks, p) end
        end
    end
    return tracks
end

local function currentTracks()
    local t = pickTracksFor(state.soundtrack)
    if #t == 0 and state.soundtrack ~= "Default" then

        t = pickTracksFor("Default")
        if #t == 0 then
            for k,v in pairs(getKits()) do if istable(v) and #v > 0 then t = pickTracksFor(k) break end end
        end
    end
    return t
end

local function scheduleNext(delay)
    killTimer()
    state.nextTimer = "Monarch_Music_Next_"..tostring(SysTime())
    timer.Create(state.nextTimer, math.max(0.1, delay or 2), 1, function()
        if not state.enabled then return end
        Music.PlayNext()
    end)
end

function Music.Stop()
    killTimer()
    stopChannel()
end

function Music.PlayNext()
    if not state.enabled then return end
    local tracks = currentTracks()
    if not tracks or #tracks == 0 then
        Music.Stop()
        return
    end
    state.idx = ((state.idx or 0) % #tracks) + 1
    local path = tracks[state.idx]

    local owner = LocalPlayer()
    if not IsValid(owner) then scheduleNext(2) return end
    stopChannel()
    local ok, chan = pcall(CreateSound, owner, path)
    if not ok or not chan then

        if string.match(path, "^https?://") then
            sound.PlayURL(path, "noblock", function(station)

                if not state.enabled then
                    if IsValid(station) then station:Stop() end
                    return
                end

                if not IsValid(station) then scheduleNext(5) return end
                state.chan = station
                station:Play()
                station:SetVolume(math.Clamp(state.volume, 0, 1))
                local dur = station:GetLength() or 0
                if dur <= 0 then dur = 120 end
                scheduleNext(dur + 0.5)
            end)
            return
        end

        scheduleNext(1)
        return
    end
    state.chan = chan
    chan:Play()
    chan:ChangeVolume(math.Clamp(state.volume, 0, 1), 0)
    local dur = SoundDuration(path) or 0
    if not dur or dur <= 0 then dur = 120 end
    scheduleNext(dur + 0.5)
end

function Music.RefreshTracks()
    state.tracks = currentTracks()
end

function Music.ShouldKeepPlaying()

    local tracks = currentTracks()
    return state.enabled and istable(tracks) and #tracks > 0
end

function Music.SetEnabled(b)
    state.enabled = b and true or false
    if not state.enabled then
        Music.Stop()
    else

        state.idx = 0
        Music.RefreshTracks()
        Music.PlayNext()
    end
end

function Music.SetVolume(v)
    local vol = tonumber(v) or 0

    if vol > 1 then vol = vol / 100 end
    state.volume = math.Clamp(vol, 0, 1)
    if IsValid(state.chan) then
        if state.chan.SetVolume then
            state.chan:SetVolume(state.volume)
        elseif state.chan.ChangeVolume then
            state.chan:ChangeVolume(state.volume, 0)
        end
    end
end

function Music.SetSoundtrack(name)
    name = tostring(name or "Default")
    state.soundtrack = name
    state.idx = 0
    Music.RefreshTracks()
    if state.enabled then
        Music.PlayNext()
    end
end

hook.Add("InitPostEntity", "Monarch_Music_Init", function()
    local enabled = Monarch.GetSetting and Monarch.GetSetting("music_enabled") or true
    local vol = Monarch.GetSetting and Monarch.GetSetting("music_volume") or 60
    local kit = Monarch.GetSetting and Monarch.GetSetting("music_soundtrack") or "Default"
    Music.SetVolume(vol)
    Music.SetSoundtrack(kit)
    Music.SetEnabled(tobool(enabled))
end)

concommand.Add("monarch_music_refreshkits", function()
    Music.RefreshTracks()
    if state.enabled and not IsValid(state.chan) then
        Music.PlayNext()
    end
end)

Monarch.VoiceModes = Monarch.VoiceModes or {}

Monarch.VoiceModes.CurrentMode = Monarch.VoiceModes.DefaultMode
Monarch.VoiceModes.CurrentModeName = "Speaking"
Monarch.VoiceModes.CurrentModeColor = Color(200, 200, 200)

local lastModeChange = 0
local MODE_DISPLAY_DURATION = 3 
local lastVoiceModeBlockedNotify = 0
local VOICEMODE_BLOCKED_NOTIFY_COOLDOWN = 1.0

surface.CreateFont("Monarch_VoiceModeFont", {
    font = "Purista",
    size = 28,
    weight = 600,
    antialias = true,
})

surface.CreateFont("Monarch_VoiceModeSmall", {
    font = "Purista",
    size = 20,
    weight = 500,
    antialias = true,
})

local function IsVoiceModeSelectionBlocked()
    if eChat and IsValid(eChat.frame) and eChat.frame:IsKeyboardInputEnabled() then
        return true
    end

    if gui and gui.IsGameUIVisible and gui.IsGameUIVisible() then
        return true
    end

    if vgui and vgui.GetKeyboardFocus and IsValid(vgui.GetKeyboardFocus()) then
        return true
    end

    if vgui and vgui.CursorVisible and vgui.CursorVisible() then
        return true
    end

    return false
end

local function NotifyVoiceModeBlocked()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    if CurTime() - lastVoiceModeBlockedNotify < VOICEMODE_BLOCKED_NOTIFY_COOLDOWN then return end
    lastVoiceModeBlockedNotify = CurTime()
end

local function CycleVoiceMode()
    if IsVoiceModeSelectionBlocked() then
        NotifyVoiceModeBlocked()
        return
    end

    local nextMode = Monarch.VoiceModes.GetNextMode(Monarch.VoiceModes.CurrentMode)
    local mode = Monarch.VoiceModes.GetMode(nextMode)

    if not mode then
        return
    end

    Monarch.VoiceModes.CurrentMode = nextMode
    Monarch.VoiceModes.CurrentModeName = mode.name
    Monarch.VoiceModes.CurrentModeColor = mode.color

    net.Start("Monarch_VoiceMode_Set")
        net.WriteString(nextMode)
    net.SendToServer()

    lastModeChange = CurTime()

    LocalPlayer():Notify("You are now " .. mode.name, 5)
end

net.Receive("Monarch_VoiceMode_Notify", function()
    local modeId = net.ReadString()
    local modeName = net.ReadString()
    local modeColor = net.ReadColor()

    Monarch.VoiceModes.CurrentMode = modeId
    Monarch.VoiceModes.CurrentModeName = modeName
    Monarch.VoiceModes.CurrentModeColor = modeColor

    lastModeChange = CurTime()
end)

hook.Add("PlayerBindPress", "Monarch_VoiceMode_Keybind", function(ply, bind, pressed)
    if not pressed then return end

    if bind == "toggleconsole" then return end 
end)

local lastJPress = 0
local J_COOLDOWN = 0.2

hook.Add("Think", "Monarch_VoiceMode_KeyCheck", function()
    if not IsValid(LocalPlayer()) then return end

    local bind = tonumber(Monarch.GetSetting and Monarch.GetSetting("bind_voicemode") or KEY_J) or KEY_J
    if input.IsKeyDown(bind) then
        if CurTime() - lastJPress > J_COOLDOWN then
            lastJPress = CurTime()
            CycleVoiceMode()
        end
    end
end)

hook.Add("PlayerButtonDown", "MonarchFastWalkToggle", function(ply, key)
    if ply ~= LocalPlayer() then return end
    local bind = tonumber(Monarch.GetSetting and Monarch.GetSetting("bind_fastwalk") or KEY_H) or KEY_H
    if key ~= bind then return end
    net.Start("Monarch_FastWalk_Toggle")
    net.SendToServer()
end)

concommand.Add("monarch_voicemode", function(ply, cmd, args)
    if not IsValid(ply) then return end

    if IsVoiceModeSelectionBlocked() then
        NotifyVoiceModeBlocked()
        return
    end

    if #args > 0 then
        local modeId = args[1]
        local mode = Monarch.VoiceModes.GetMode(modeId)

        if mode then
            Monarch.VoiceModes.CurrentMode = modeId
            Monarch.VoiceModes.CurrentModeName = mode.name
            Monarch.VoiceModes.CurrentModeColor = mode.color

            net.Start("Monarch_VoiceMode_Set")
                net.WriteString(modeId)
            net.SendToServer()

            lastModeChange = CurTime()
            LocalPlayer():Notify("You are now " .. mode.name, 5)
        end
    else
        CycleVoiceMode()
    end
end, nil, "Change or cycle voice mode. Usage: monarch_voicemode [mode_id]")