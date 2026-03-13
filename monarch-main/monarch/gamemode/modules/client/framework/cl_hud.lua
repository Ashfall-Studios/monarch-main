Monarch = Monarch or {}

if not Monarch.UI or not Monarch.UI.Scale then
    Monarch.LoadFile("modules/client/themes/cl_scale.lua")
end

Monarch.UI = Monarch.UI or {}

local Scale = Monarch.UI.Scale or function(v) return v end
local ScaleFont = Monarch.UI.ScaleFont or function(v) return v end

local darkCol = Color(30, 30, 30, 190)
local start, oldhp, newhp = 0, -1, -1
local barW = Scale(200)
local animationTime = 0.5

local currentSpread = 10

local mat = Material("icons/waypoint/cmb_circle_small.png", "mips smooth")

local colorselect = Color(0, 0, 0, 255)
local colorselect2 = Color(55, 55, 55, 49)
local colormat = Color(225, 0, 0, 255)
local healthColor = Color(255,0,0,255)
local armorColor = Color(0,75,255,255)
scrW, scrH = ScrW(), ScrH()
CreateClientConVar("combine_hud_enabled", "0", true, false)

local combine_overlay_is_enabled = GetConVar("combine_hud_enabled"):GetBool()
local thirdpersontoggled = GetConVar("monarch_thirdperson"):GetBool()
local color
local compassWidth = Scale(400)
local compassHeight = Scale(40)
local compassX = (ScrW() / 2) - (compassWidth / 2)
local compassY = Scale(20)
local tickSpacing = Scale(15)
local directionSpacing = Scale(90)
local directions = {"N", "E", "S", "W"}
local ply = LocalPlayer()

local cachedScrW, cachedScrH = ScrW(), ScrH()

local ENTITY_DISPLAY_DISTANCE = 150
local ITEM_DISPLAY_DISTANCE = 250  
local ENTITY_DISPLAY_FONT = "Monarch_UseInfo"
local ENTITY_TEXT_COLOR = Color(255, 255, 255, 255)
local ENTITY_BACKGROUND_COLOR = Color(0, 0, 0, 180)
local ENTITY_TEXT_PADDING = Scale(8)

local PLAYER_DISPLAY_DISTANCE = 150
local PLAYER_NAME_FONT = "terminal64"
local PLAYER_DESC_FONT = "DermaDefault"
local PLAYER_NAMEPLATE_BASE_SCALE = 0.1
local PLAYER_NAMEPLATE_3D2D_SCALE = 0.05
local PLAYER_NAMEPLATE_SIZE_MULT = PLAYER_NAMEPLATE_BASE_SCALE / PLAYER_NAMEPLATE_3D2D_SCALE
local PLAYER_ICON_SIZE = math.floor(Scale(85) * PLAYER_NAMEPLATE_SIZE_MULT)

local defaultPlayerIcon = Material("mrp/icons/unknown_player_bg2.png", "mips smooth")

local nextPlayerUpdate = 0
local cachedPlayers = {}
local playerUpdateInterval = 0.1

local whiteColor = Color(255, 255, 255, 255)
local grayColor = Color(200, 200, 200, 255)
local darkGrayColor = Color(60, 60, 60, 100)
local outlineColor = Color(100, 100, 100, 255)

local immerse_mode = (Monarch.GetSetting and Monarch.GetSetting("immerse_mode")) or false

hook.Add("Monarch_SettingChanged", "ImmersiveModeToggle", function(settingName, newValue)
    if settingName == "immerse_mode" then
        immerse_mode = newValue
    end
end)

surface.CreateFont("Monarch_StatsFont", {
    font = "Din Pro Regular",
    size = ScaleFont(25),
    weight = 300,
    antialias = true,
})

surface.CreateFont("Monarch_StatsFontSmaller", {
    font = "Din Pro Regular",
    size = ScaleFont(20),
    weight = 300,
    antialias = true,
})

surface.CreateFont("Monarch_LevelUp_Title", {
    font = "Din Pro Regular",
    size = ScaleFont(28),
    weight = 200,
    antialias = true,
})

surface.CreateFont("Monarch_LevelUp_Sub", {
    font = "Purista",
    size = ScaleFont(20),
    weight = 200,
    antialias = true,
})

surface.CreateFont("Monarch_LoyaltyNotification", {
    font = "Din Pro Regular",
    size = ScaleFont(24),
    weight = 600,
    antialias = true,
})

local LevelUpCard = {
    active = false,
    start = 0,
    duration = 8.0,
    title = "Level Up!",
    skillName = "",
    oldLvl = 0,
    newLvl = 0,
    oldXP = 0,
    newXP = 0,
}

net.Receive("Monarch_LevelUp", function()
end)

local hotPink = Color(148, 0, 211)

local wpnRow = 0
local wpnCol = 0
local wpnOpen = false
local wpnLastInput = CurTime()

local wpnColUsable = Color(102,102,102,210)
local wpnColUsable2 = Color(122,122,122,220)
local wpnColSell = Color(84,84,84,200)
local wpnColSell2 = Color(80,80,80,220)
local wpnColEmpty = Color(46,46,48,60)
local defMaterial = Material("materials/icons/unknown_person.png")
local wpnColEmpty2 = Color(27,27,27,60)
local wpnGradient = Material("vgui/gradient-l")

local wpnSlots = {
	"Tools",
	"Essential",
	"Primary",
	"Secondary",
	"Utilities",
	"Misc."
}

surface.CreateFont("Scroll-LightUI32", {
    font = "Purista",
    size = ScaleFont(48),
    weight = 400,
    antialias = true
})

surface.CreateFont("Scroll-LightUI20", {
    font = "Purista", 
    size = ScaleFont(28),
    weight = 400,
    antialias = true
})

healthIcon = Material("mrp/hud/health.png", "mips smooth")
armorIcon = Material("mrp/hud/armor.png", "mips smooth")
hungerIcon = Material("mrp/hud/hunger.png", "mips smooth")
thirstIcon = Material("mrp/hud/thirst.png", "mips smooth")
local micIconMat = Material("mrp/voice/mic.png", "mips smooth")
local micMoverMat = Material("mrp/voice/mic_mover.png", "mips smooth")
local micVoiceLerp = {}

local function BlurRect(x, y, w, h)
    surface.SetDrawColor(0, 0, 0, 100)
    surface.DrawRect(x, y, w, h)
end

local function DrawWeaponSelect()
    if (wpnLastInput + 5 < CurTime()) or not wpnOpen then
        wpnRow = 0
        wpnCol = 0
        return
    end

    local weps = {}
    for i = 1, 6 do
        weps[i] = {}
    end

    for _, wep in ipairs(LocalPlayer():GetWeapons()) do
        table.insert(weps[wep.Slot and wep.Slot + 1 or 1], wep)
    end

    local cardSize = Scale(120)  
    local categorySpacing = Scale(10)
    local startX = Scale(50)
    local totalCategoryHeight = (6 * cardSize) + (5 * categorySpacing)
    local startY = (ScrH() / 2) - (totalCategoryHeight / 2)

    for slot = 1, 6 do
        local y = startY + (slot - 1) * (cardSize + categorySpacing)
        local hasWeapons = #weps[slot] > 0
        local isSelected = wpnRow == slot

        BlurRect(startX, y, cardSize, cardSize)

        if isSelected then
            surface.SetDrawColor(60, 60, 60, 220)  
        elseif hasWeapons then
            surface.SetDrawColor(45, 45, 45, 200)  
        else
            surface.SetDrawColor(30, 30, 30, 180)  
        end
        surface.DrawRect(startX, y, cardSize, cardSize)

        if isSelected then
            surface.SetDrawColor(160, 160, 160, 255)  
        elseif hasWeapons then
            surface.SetDrawColor(120, 120, 120, 255)  
        else
            surface.SetDrawColor(80, 80, 80, 200)     
        end
        surface.DrawOutlinedRect(startX, y, cardSize, cardSize, Scale(2))

        surface.SetFont("Scroll-LightUI32")  
        local numText = tostring(slot)
        local numW, numH = surface.GetTextSize(numText)
        surface.SetTextColor(40, 40, 40, 150)  
        surface.SetTextPos(startX + cardSize/2 - numW/2, y + cardSize/2 - numH/2)
        surface.DrawText(numText)

        surface.SetFont("Scroll-LightUI20")
        local slotName = wpnSlots[slot]
        local textW, textH = surface.GetTextSize(slotName)
        local textColor = hasWeapons and Color(220, 220, 220, 255) or Color(80, 80, 80, 255)  

        surface.SetTextColor(0, 0, 0, 200)  
        surface.SetTextPos(startX + cardSize/2 - textW/2 + 1, y + cardSize - textH - Scale(8) + 1)
        surface.DrawText(slotName)

        surface.SetTextColor(textColor)
        surface.SetTextPos(startX + cardSize/2 - textW/2, y + cardSize - textH - Scale(8))
        surface.DrawText(slotName)
    end

    if wpnRow > 0 and #weps[wpnRow] > 0 then
        local selectedCategoryY = startY + (wpnRow - 1) * (cardSize + categorySpacing)
        local weaponStartX = startX + cardSize + Scale(25)  
        local weaponsPerRow = 4  

        for i, wep in ipairs(weps[wpnRow]) do
            local row = math.floor((i - 1) / weaponsPerRow)
            local col = (i - 1) % weaponsPerRow

            local x = weaponStartX + col * (cardSize + Scale(10))
            local y = selectedCategoryY + row * (cardSize + Scale(10))
            local isSelectedWeapon = wpnCol == i

            BlurRect(x, y, cardSize, cardSize)

            if isSelectedWeapon then
                surface.SetDrawColor(70, 70, 70, 220)  
            else
                surface.SetDrawColor(45, 45, 45, 200)  
            end
            surface.DrawRect(x, y, cardSize, cardSize)

            if isSelectedWeapon then
                surface.SetDrawColor(180, 180, 180, 255)  
            else
                surface.SetDrawColor(120, 120, 120, 255)  
            end
            surface.DrawOutlinedRect(x, y, cardSize, cardSize, Scale(2))

            surface.SetFont("Scroll-LightUI32")  
            local weaponNumText = tostring(i)
            local weaponNumW, weaponNumH = surface.GetTextSize(weaponNumText)
            surface.SetTextColor(40, 40, 40, 150)  
            surface.SetTextPos(x + cardSize/2 - weaponNumW/2, y + cardSize/2 - weaponNumH/2)
            surface.DrawText(weaponNumText)

            surface.SetFont("Scroll-LightUI20")
            local weaponName = wep:GetPrintName()
            local nameW, nameH = surface.GetTextSize(weaponName)

            if nameW > cardSize - Scale(10) then
                while nameW > cardSize - Scale(10) and string.len(weaponName) > 3 do
                    weaponName = string.sub(weaponName, 1, -2)
                    nameW, nameH = surface.GetTextSize(weaponName .. "...")
                end
                weaponName = weaponName .. "..."
                nameW, nameH = surface.GetTextSize(weaponName)  
            end

            surface.SetTextColor(0, 0, 0, 200)  
            surface.SetTextPos(x + cardSize/2 - nameW/2 + 1, y + Scale(8) + 1)
            surface.DrawText(weaponName)

            surface.SetTextColor(Color(200, 200, 200, 255))  
            surface.SetTextPos(x + cardSize/2 - nameW/2, y + Scale(8))
            surface.DrawText(weaponName)

            if wep.GetClip1 and wep:GetClip1() >= 0 then
                local ammoText = wep:GetClip1() .. "/" .. (LocalPlayer():GetAmmoCount(wep:GetPrimaryAmmoType()) or 0)
                surface.SetFont("Scroll-LightUI20")
                local ammoW, ammoH = surface.GetTextSize(ammoText)

                surface.SetTextColor(0, 0, 0, 200)  
                surface.SetTextPos(x + cardSize/2 - ammoW/2 + 1, y + cardSize - ammoH - Scale(8) + 1)
                surface.DrawText(ammoText)

                surface.SetTextColor(Color(180, 180, 180, 255))  
                surface.SetTextPos(x + cardSize/2 - ammoW/2, y + cardSize - ammoH - Scale(8))
                surface.DrawText(ammoText)
            end
        end
    end
end

local lastWeaponSwitch = 0

hook.Add("StartCommand", "PreventAutoAttack", function(ply, ucmd)
	if ply:InVehicle() then return end

	if ucmd:KeyDown(IN_ATTACK) and lastWeaponSwitch + 0.5 > CurTime() then
		ucmd:SetButtons(bit.band(ucmd:GetButtons(), bit.bnot(IN_ATTACK)))
	end
end)

function GM:PlayerBindPress(ply, bind, pressed)
    if not pressed then return end
    if LocalPlayer():InVehicle() then return end
    if not Monarch.hudEnabled then return end

    if bind == "+zoom" or bind == "zoom" or string.find(bind, "zoom", 1, true) then
        return true
    end

    local isInvShifting = false 
    local shiftBy = 1

    if not bind:StartWith("slot") then 
        if bind == "+attack" then
            if wpnOpen and not (wpnLastInput + 5 < CurTime()) then
                local weps = {}
                for i = 1, 6 do
                    weps[i] = {}
                end

                for _, wep in ipairs(LocalPlayer():GetWeapons()) do
                    local slot = (wep.Slot and wep.Slot + 1) or 1
                    table.insert(weps[slot], wep)
                end

                local swp = (weps[wpnRow] or {})[wpnCol]

                if IsValid(swp) then
                    lastWeaponSwitch = CurTime()
                    input.SelectWeapon(swp)
                    wpnOpen = false
                    wpnLastInput = 0
                    surface.PlaySound("common/wpn_select.wav")
                end
                return true
            end
        elseif bind == "invprev" or bind == "mwheelup" then
            if input.IsMouseDown(MOUSE_LEFT) then return end
            isInvShifting = true 
            shiftBy = -1
        elseif bind == "invnext" or bind == "mwheeldown" then
            if input.IsMouseDown(MOUSE_LEFT) then return end
            isInvShifting = true 
            shiftBy = 1
        end
        if not isInvShifting then return end
    end

    local currentSlot = isInvShifting and (wpnRow != 0 and wpnRow or (IsValid(LocalPlayer():GetActiveWeapon()) and (LocalPlayer():GetActiveWeapon().Slot or 0) + 1 or 1)) or tonumber(bind:sub(5))

    wpnOpen = true 
    wpnLastInput = CurTime()

    local weps = {}
    for i = 1, 6 do
        weps[i] = {}
    end
    for _, wep in ipairs(LocalPlayer():GetWeapons()) do
        local slot = (wep.Slot and wep.Slot + 1) or 1
        table.insert(weps[slot], wep)
    end

    if wpnRow != currentSlot then

        wpnRow = currentSlot
        wpnCol = 1
        surface.PlaySound("ui/buttonrollover.wav")
    else

        local maxCol = #weps[wpnRow]

        if isInvShifting then

            if maxCol > 0 then
                local newCol = wpnCol + shiftBy

                if newCol > maxCol then

                    local newSlot = wpnRow + shiftBy

                    if newSlot > 6 then
                        newSlot = 1
                    elseif newSlot < 1 then
                        newSlot = 6
                    end

                    local attempts = 0
                    while #weps[newSlot] == 0 and attempts < 6 do
                        newSlot = newSlot + shiftBy
                        if newSlot > 6 then
                            newSlot = 1
                        elseif newSlot < 1 then
                            newSlot = 6
                        end
                        attempts = attempts + 1
                    end

                    if #weps[newSlot] > 0 then
                        wpnRow = newSlot
                        wpnCol = 1
                        surface.PlaySound("ui/buttonrollover.wav")
                    end

                elseif newCol <= 0 then

                    local newSlot = wpnRow + shiftBy

                    if newSlot < 1 then
                        newSlot = 6
                    elseif newSlot > 6 then
                        newSlot = 1
                    end

                    local attempts = 0
                    while #weps[newSlot] == 0 and attempts < 6 do
                        newSlot = newSlot + shiftBy
                        if newSlot < 1 then
                            newSlot = 6
                        elseif newSlot > 6 then
                            newSlot = 1
                        end
                        attempts = attempts + 1
                    end

                    if #weps[newSlot] > 0 then
                        wpnRow = newSlot
                        wpnCol = #weps[newSlot] 
                        surface.PlaySound("ui/buttonrollover.wav")
                    end

                else

                    wpnCol = newCol
                    surface.PlaySound("ui/buttonrollover.wav")
                end
            else

                local newSlot = wpnRow + shiftBy

                if newSlot < 1 then
                    newSlot = 6
                elseif newSlot > 6 then
                    newSlot = 1
                end

                local attempts = 0
                while #weps[newSlot] == 0 and attempts < 6 do
                    newSlot = newSlot + shiftBy
                    if newSlot < 1 then
                        newSlot = 6
                    elseif newSlot > 6 then
                        newSlot = 1
                    end
                    attempts = attempts + 1
                end

                wpnRow = newSlot
                wpnCol = 1
                surface.PlaySound("ui/buttonrollover.wav")
            end
        else

            if maxCol > 0 then
                wpnCol = wpnCol >= maxCol and 1 or wpnCol + 1
                surface.PlaySound("ui/buttonrollover.wav")
            else
                wpnCol = 1
            end
        end
    end

    return true
end
hook.Add("HUDPaint", "MonarchWeaponSelect", function()
    local lp = LocalPlayer()
    DrawWeaponSelect()
end)

local function GetTeamIconMaterial(teamID)
    if not teamID or teamID == 0 then
        return defaultPlayerIcon
    end

    if Monarch and Monarch.Team then
        local teamData = Monarch.Team[teamID]
        if teamData and teamData.material then
            if not teamData.material:IsError() then
                return teamData.material
            end
        end
    end

    return defaultPlayerIcon
end

hook.Add("HUDDrawPickupHistory", "myam:D", function()
    return true 
end)

hook.Add( "HUDItemPickedUp", "nosound>:(", function()
    return true
end )

hook.Add("HUDDrawTargetID", "HidePlayerTags", function()
    return false
end)

local visiblePlayers = {}
local nextVisibleUpdate = 0

hook.Add("HUDPaint", "DrawPlayerNames", function()
    if not LocalPlayer():HasGodMode() then return end
    if CurTime() > nextVisibleUpdate then
        visiblePlayers = {}
        for _, v in player.Iterator() do
            if v ~= LocalPlayer() and v:Alive() then
                table.insert(visiblePlayers, v)
            end
        end
        nextVisibleUpdate = CurTime() + 0.2
    end
    for _, v in ipairs(visiblePlayers) do
        local point = v:GetPos()
        local data2D = point:ToScreen()
        draw.SimpleText(v:Nick(), "Default", data2D.x, data2D.y, team.GetColor(v:Team()), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

local function GetDisplayName(ply)
    if not IsValid(ply) then return "Unrecognized" end

    if Monarch and Monarch.Introductions and Monarch.Introductions.GetDisplayName then
        return Monarch.Introductions.GetDisplayName(ply)
    end

    if ply == LocalPlayer() then
        return GetRPName(ply)
    end

    return "Unrecognized"
end

local function DrawWorldNameplate(displayPos, nameplateAngle, opts)
    local nameText = opts.name or "Unrecognized"
    local descText = opts.desc
    local iconMaterial = opts.iconMaterial or defaultPlayerIcon
    local teamColor = opts.teamColor or Color(170, 170, 200)
    local alpha = opts.alpha or 255
    local scale = opts.scale or PLAYER_NAMEPLATE_3D2D_SCALE
    local showIcon = Config.ShouldDrawTeamIcons

    local worldSnap = scale * 0.25
    local snappedDisplayPos = Vector(
        math.Round(displayPos.x / worldSnap) * worldSnap,
        math.Round(displayPos.y / worldSnap) * worldSnap,
        math.Round(displayPos.z / worldSnap) * worldSnap
    )

    local snappedAngle = Angle(
        math.Round(nameplateAngle.p * 2) / 2,
        math.Round(nameplateAngle.y * 2) / 2,
        math.Round(nameplateAngle.r * 2) / 2
    )

    surface.SetFont("Monarch3D2D_Name")
    local _, nameH = surface.GetTextSize(nameText)

    local hasDesc = descText and descText ~= ""
    if hasDesc then
        surface.SetFont("Monarch3D2D_Desc")
    end

    local iconSize = PLAYER_ICON_SIZE
    local padding = math.floor(16 * PLAYER_NAMEPLATE_SIZE_MULT)
    local iconX, iconY = 0, 0
    local textStartX = math.floor(showIcon and (iconSize + padding) or 0)
    local textNameY = 0
    local textShadowY = -1
    local descY = math.floor(nameH + (padding / 2))
    local descShadowY = descY + 1
    local outlineThickness = 2

    cam.Start3D2D(snappedDisplayPos, snappedAngle, scale)
        if showIcon then
            outlineColor.a = alpha
            surface.SetDrawColor(outlineColor.r, outlineColor.g, outlineColor.b, outlineColor.a)
            surface.DrawOutlinedRect(iconX - outlineThickness, iconY - outlineThickness, iconSize + outlineThickness * 2, iconSize + outlineThickness * 2, outlineThickness)

            darkGrayColor.a = alpha * 0.8
            surface.SetDrawColor(0, 0, 0, 100)
            surface.DrawRect(iconX, iconY, iconSize, iconSize)

            if iconMaterial and not iconMaterial:IsError() then
                surface.SetMaterial(iconMaterial)
                whiteColor.a = alpha
                surface.SetDrawColor(whiteColor.r, whiteColor.g, whiteColor.b, whiteColor.a)
                surface.DrawTexturedRect(iconX - 4, iconY - 4, iconSize + 8, iconSize + 8)
            else
                surface.SetMaterial(defMaterial)
                whiteColor.a = alpha
                surface.SetDrawColor(whiteColor.r, whiteColor.g, whiteColor.b, whiteColor.a)
                surface.DrawTexturedRect(iconX - 4, iconY - 4, iconSize + 8, iconSize + 8)
            end
        end

        local nameColor = Color(teamColor.r or 170, teamColor.g or 170, teamColor.b or 200, alpha)

        surface.SetFont("Monarch3D2D_Name")
        surface.SetTextColor(Color(0,0,0,alpha))
        surface.SetTextPos(textStartX + 5, textNameY + 2)
        surface.DrawText(nameText)

        surface.SetFont("Monarch3D2D_Name")
        surface.SetTextColor(nameColor.r, nameColor.g, nameColor.b, nameColor.a)
        surface.SetTextPos(textStartX, textNameY)
        surface.DrawText(nameText)

        surface.SetFont("Monarch3D2D_Desc")
        grayColor.a = alpha
        surface.SetTextColor(0,0,0, grayColor.a)
        surface.SetTextPos(textStartX+5, descY + 2)
        if hasDesc then surface.DrawText(descText) end

        surface.SetFont("Monarch3D2D_Desc")
        grayColor.a = alpha
        surface.SetTextColor(grayColor.r, grayColor.g, grayColor.b, grayColor.a)
        surface.SetTextPos(textStartX, descY)
        if hasDesc then surface.DrawText(descText) end

    cam.End3D2D()
end

hook.Add("PostDrawOpaqueRenderables", "Draw3D2DPlayerNames", function()
    local localPlayer = LocalPlayer()
    if not IsValid(localPlayer) then return end

    local trace = localPlayer:GetEyeTrace()
    local targetEntity = trace.Entity
    if not IsValid(targetEntity) then return end
    if targetEntity:IsPlayer() then
        if targetEntity == localPlayer then return end

        local distance = localPlayer:GetPos():Distance(targetEntity:GetPos())
        if distance > PLAYER_DISPLAY_DISTANCE then
            return
        end

        local localViewAngle = localPlayer:EyeAngles()
        local localRight = localViewAngle:Right()
        local sideOffset = Config.ShouldDrawTeamIcons and (localRight * 13) or (localRight * 3)

        local heightOffset = Vector(0, 0, targetEntity:OBBMaxs().z * 0.95)
        local displayPos = targetEntity:GetPos() + sideOffset + heightOffset

        local toCamera = localPlayer:EyePos() - displayPos
        toCamera:Normalize()

        local nameplateAngle = Angle(0, math.deg(math.atan2(toCamera.y, toCamera.x)) + 90, 90)

        local playerName = GetDisplayName(targetEntity)
        local playerTeam = targetEntity:Team()
        local teamName = team.GetName(playerTeam) or "Unrecognized"

        local iconMaterial = (playerName == "Unrecognized") and defaultPlayerIcon or GetTeamIconMaterial(playerTeam)

        DrawWorldNameplate(displayPos, nameplateAngle, {
            name = playerName,
            desc = teamName,
            iconMaterial = iconMaterial,
            teamColor = team.GetColor(playerTeam),
            scale = PLAYER_NAMEPLATE_3D2D_SCALE,
            alpha = 255
        })
        return
    end

    local class = targetEntity:GetClass()
    if class == "monarch_vendor" or class == "monarch_rankvendor" then
        local distance = localPlayer:GetPos():Distance(targetEntity:GetPos())
        if distance > PLAYER_DISPLAY_DISTANCE then
            return
        end

        local localRight = localPlayer:EyeAngles():Right()
        local sideOffset = Config.ShouldDrawTeamIcons and (localRight * 13) or (localRight * 3)

        local heightOffset = Vector(0, 0, targetEntity:OBBMaxs().z * 0.95)
        local displayPos = targetEntity:GetPos() + sideOffset + heightOffset

        local toCamera = localPlayer:EyePos() - displayPos
        toCamera:Normalize()

        local nameplateAngle = Angle(0, math.deg(math.atan2(toCamera.y, toCamera.x)) + 90, 90)

        local vendorName = (targetEntity.GetVendorName and targetEntity:GetVendorName()) or "Vendor"
        local vendorTeam = (targetEntity.GetRequiredTeam and targetEntity:GetRequiredTeam()) or 0
        local iconMaterial = GetTeamIconMaterial(vendorTeam)

        DrawWorldNameplate(displayPos, nameplateAngle, {
            name = vendorName,
            desc = nil,
            iconMaterial = iconMaterial,
            teamColor = Color(160,160,200),
            scale = PLAYER_NAMEPLATE_3D2D_SCALE,
            alpha = 255
        })
    end
end)

local nextEntityCheck = 0
local entityCheckInterval = 0.05

local usePromptAlpha = 0
local usePromptFadeSpeed = 9
local useKeycapMat = Material("mrp/key_cap_icon_dark.png")
local lastUsePromptText = nil

hook.Add("HUDPaint", "DrawUsePromptText", function()
    local localPlayer = LocalPlayer()
    if not IsValid(localPlayer) then return end

    local trace = localPlayer:GetEyeTrace()
    local ent = trace.Entity
    local promptText

    if IsValid(ent) then
        local distance = localPlayer:GetPos():Distance(ent:GetPos())
        local maxDist = (ent:GetClass() == "monarch_item") and ITEM_DISPLAY_DISTANCE or ENTITY_DISPLAY_DISTANCE
        if distance <= maxDist then
            if ent:GetClass() == "monarch_item" then

                local itemClass = ent:GetNWString("ItemClass", "")
                if itemClass == "" then
                    itemClass = ent.ItemClass or "unknown"
                end
                local itemData = (Monarch.Inventory and Monarch.Inventory.Items and Monarch.Inventory.Items[itemClass]) or nil
                if (not itemData) and Monarch.Inventory and Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[itemClass] then
                    local itemKey = Monarch.Inventory.ItemsRef[itemClass]
                    itemData = Monarch.Inventory.Items and Monarch.Inventory.Items[itemKey]
                end
                local itemName = (itemData and (itemData.Name or itemData.name)) or itemClass or "Item"
                local stack = tonumber(ent:GetNWInt("StackAmount") or 1) or 1
                if stack > 1 then
                    itemName = string.format("%s x%d", itemName, stack)
                end
                promptText = "Pick up " .. itemName
            elseif ent:GetClass() == "func_button" or ent:GetClass() == "gmod_button" then
                promptText = "Use the button"
            elseif ent:IsPlayer() then
                promptText = "Interact with '"..GetDisplayName(ent).."'"
            elseif ent:IsVehicle() then
                promptText = "Enter the vehicle"
            elseif ent:GetClass() == "func_useable" or ent:GetClass() == "gmod_useable" then
                promptText = "Use this"
            elseif ent.HUDDisplayText then
                promptText = ent.HUDDisplayText
            end
        end
    end

    if not promptText and Monarch and Monarch.StaticUse and Monarch.StaticUse.GetPromptFromTrace then
        promptText = Monarch.StaticUse.GetPromptFromTrace(localPlayer, trace) -- specific to hl2rp
    end

    if promptText then
        lastUsePromptText = promptText
        usePromptAlpha = Lerp(FrameTime() * usePromptFadeSpeed, usePromptAlpha, 150)
    else
        usePromptAlpha = Lerp(FrameTime() * usePromptFadeSpeed, usePromptAlpha, 0)
        if usePromptAlpha < 1 then
            lastUsePromptText = nil
        end
    end

    local displayPrompt = promptText or lastUsePromptText

    if usePromptAlpha > 1 and displayPrompt then
        local centerX = ScrW() / 2
        local centerY = ScrH() / 2 + 390
        local iconSize = 64
        local half = iconSize * 0.5

        surface.SetFont("DispLgr")
        local textW, textH = surface.GetTextSize(displayPrompt)
        local gap = 10
        local totalW = iconSize + gap + textW
        local startX = centerX - (totalW * 0.5)
        local iconX = startX
        local iconY = centerY - half

        surface.SetMaterial(useKeycapMat)
        local keycapAlpha = math.Clamp(math.floor(usePromptAlpha * 1.75), 0, 255)
        surface.SetDrawColor(255, 255, 255, keycapAlpha)
        surface.DrawTexturedRect(iconX, iconY, iconSize, iconSize)

        local letterAlpha = math.Clamp(math.floor(usePromptAlpha), 0, 255)
        local blurAlpha = math.Clamp(math.floor(letterAlpha * 0.65), 0, 255)
        local iconCenterX = iconX + half
        draw.SimpleText("E", "DispMedBlur", iconCenterX, centerY - 1, Color(0, 0, 0, blurAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("E", "DispLgr", iconCenterX, centerY, Color(255, 255, 255, letterAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local textX = iconX + iconSize + gap + textW * 0.5
        local textY = centerY

        draw.SimpleText(displayPrompt, "DispMedBlur", textX, textY - 1, Color(0, 0, 0, blurAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(displayPrompt, "DispLgr", textX, textY, Color(255, 255, 255, letterAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    end
end)

local instructionsPromptAlpha = 0
local instructionsPromptFadeSpeed = 9
local lastInstructionsPromptText = nil

hook.Add("HUDPaint", "DrawInstructionsPromptText", function()
    local localPlayer = LocalPlayer()
    if not IsValid(localPlayer) then return end

    local trace = localPlayer:GetEyeTrace()
    local ent = trace.Entity
    local promptText

    if IsValid(ent) then
        local distance = localPlayer:GetPos():Distance(ent:GetPos())
        local maxDist = (ent:GetClass() == "monarch_item") and ITEM_DISPLAY_DISTANCE or ENTITY_DISPLAY_DISTANCE
        if distance <= maxDist then
            if ent.HUDInstructionsText then
                promptText = ent.HUDInstructionsText
            end
        end
    end

    if promptText then
        lastInstructionsPromptText = promptText
        instructionsPromptAlpha = Lerp(FrameTime() * instructionsPromptFadeSpeed, instructionsPromptAlpha, 150)
    else
        instructionsPromptAlpha = Lerp(FrameTime() * instructionsPromptFadeSpeed, instructionsPromptAlpha, 0)
        if instructionsPromptAlpha < 1 then
            lastInstructionsPromptText = nil
        end
    end

    local displayPrompt = promptText or lastInstructionsPromptText

    if instructionsPromptAlpha > 1 and displayPrompt then
        local centerX = ScrW() / 2
        local centerY = ScrH() / 2 + 440
        local textW, textH = surface.GetTextSize(displayPrompt)

        local letterAlpha = math.Clamp(math.floor(instructionsPromptAlpha), 0, 255)
        local blurAlpha = math.Clamp(math.floor(letterAlpha * 0.65), 0, 255)

        surface.SetFont("DispLgr")
        local textX = centerX
        local textY = centerY

        draw.SimpleText(displayPrompt, "DispMedBlur", textX, textY - 1, Color(0, 0, 0, blurAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(displayPrompt, "DispLgr", textX, textY, Color(255, 255, 255, letterAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

local tab = {
    [ "$pp_colour_addr" ] = 0,
    [ "$pp_colour_addg" ] = 0,
    [ "$pp_colour_addb" ] = 0,
    [ "$pp_colour_brightness" ] = -0.05,
    [ "$pp_colour_contrast" ] = 1,
    [ "$pp_colour_colour" ] = 0.7,
    [ "$pp_colour_mulr" ] = 0,
    [ "$pp_colour_mulg" ] = 0.25,
    [ "$pp_colour_mulb" ] = 0
}

local CROSSHAIR_SIZE = 32
local CROSSHAIR_BASE_ALPHA = 50
local CROSSHAIR_INTERACT_SCALE = 1.2
local CROSSHAIR_INTERACT_ALPHA = 255
local CROSSHAIR_LERP_SPEED = 10
local crosshairMat = Material("mrp/hud/crossair/crosshair.png")

local VIGNETTE_START = 75        
local VIGNETTE_CRIT  = 30        
local VIGNETTE_MIN_ALPHA = 50    
local VIGNETTE_MAX_ALPHA = 220   
local VIGNETTE_PULSE_FREQ = 0.9  
local VIGNETTE_PULSE_STRENGTH = 0.5 
local vignetteMat = Material("overlays/blood_vignette.png", "smooth")
local vignetteAlphaLast = 0

local baseVignetteMat = Material("mrp/menu_stuff/vignette.png", "smooth")
local REGULAR_VIGNETTE_ALPHA = 255

hook.Add( "RenderScreenspaceEffects", "color_modify_example", function()
    DrawColorModify( tab )

    local shouldVignette = Monarch.GetSetting and Monarch.GetSetting("hud_vignette") or false
    if shouldVignette == true then
        surface.SetMaterial(baseVignetteMat)
        surface.SetDrawColor(255,255,255, REGULAR_VIGNETTE_ALPHA)
        surface.DrawTexturedRect(0,0,ScrW(),ScrH())
    end

    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:Alive() then return end
    local hp = lp:Health()

    if hp >= VIGNETTE_START then
        vignetteAlphaLast = Lerp(FrameTime()*5, vignetteAlphaLast, 0)
        if vignetteAlphaLast <= 1 then return end
        surface.SetMaterial(vignetteMat)
        surface.SetDrawColor(255,255,255, vignetteAlphaLast)
        surface.DrawTexturedRect(0,0,ScrW(),ScrH())
        return
    end

    local span = (VIGNETTE_START - VIGNETTE_CRIT)
    local t = 1 - math.Clamp((hp - VIGNETTE_CRIT) / span, 0, 1) 
    local baseAlpha = VIGNETTE_MIN_ALPHA + t * (VIGNETTE_MAX_ALPHA - VIGNETTE_MIN_ALPHA)

    if hp <= VIGNETTE_CRIT then
        local pulse = 1 + math.sin(CurTime() * math.pi * 2 * VIGNETTE_PULSE_FREQ) * VIGNETTE_PULSE_STRENGTH
        baseAlpha = baseAlpha * pulse
    end

    vignetteAlphaLast = Lerp(FrameTime()*5, vignetteAlphaLast, baseAlpha)

    surface.SetMaterial(vignetteMat)
    surface.SetDrawColor(255,255,255, math.Clamp(vignetteAlphaLast, 0, 255))
    surface.DrawTexturedRect(0,0,ScrW(),ScrH())
end)

local function IsDoorEntity(ent)
    if not IsValid(ent) then return false end
    local className = ent:GetClass() or ""
    if className:find("door", 1, true) then return true end
    if ent.IsDoor and isfunction(ent.IsDoor) and ent:IsDoor() then return true end
    if ent.isDoor and isfunction(ent.isDoor) and ent:isDoor() then return true end
    return false
end

local crosshairDrawSize = CROSSHAIR_SIZE
local crosshairDrawAlpha = CROSSHAIR_BASE_ALPHA

hook.Add("HUDPaint", "MonarchCircularCrosshair", function() 
    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:Alive() then return end
    if Monarch.GetSetting and not Monarch.GetSetting("hud_cursor") then return end
    if lp:ShouldDrawLocalPlayer() then return end
    if lp:InVehicle() then return end
    if lp:IsRagdoll() then return end

    local wep = lp:GetActiveWeapon()
    if not IsValid(wep) then return end
    local isHands = IsValid(wep) and IsValid(lp) and not lp:IsRagdoll() and wep:GetClass() == "monarch_hands" or wep:GetClass() == "monarch_keys"
    if lp:KeyDown(IN_ATTACK2) and not isHands then return end

    if not Monarch.hudEnabled then return end

    local isInteractable = false
    local trace = lp:GetEyeTrace()
    local ent = trace.Entity
    if IsValid(ent) then
        local distance = lp:GetPos():Distance(ent:GetPos())
        if distance <= ENTITY_DISPLAY_DISTANCE then
            local className = ent:GetClass()
            if ent:IsPlayer() or ent:IsVehicle() or IsDoorEntity(ent) or className == "func_button" or className == "gmod_button" or className == "func_useable" or className == "gmod_useable" or ent.HUDDisplayText then
                isInteractable = true
            end
        end
    end

    local cx, cy = cachedScrW * 0.5, cachedScrH * 0.5
    local targetSize = isInteractable and (CROSSHAIR_SIZE * CROSSHAIR_INTERACT_SCALE) or CROSSHAIR_SIZE
    local targetAlpha = isInteractable and CROSSHAIR_INTERACT_ALPHA or CROSSHAIR_BASE_ALPHA

    crosshairDrawSize = Lerp(FrameTime() * CROSSHAIR_LERP_SPEED, crosshairDrawSize, targetSize)
    crosshairDrawAlpha = Lerp(FrameTime() * CROSSHAIR_LERP_SPEED, crosshairDrawAlpha, targetAlpha)

    local half = crosshairDrawSize * 0.5

    surface.SetMaterial(crosshairMat)
    surface.SetDrawColor(255, 255, 255, crosshairDrawAlpha)
    surface.DrawTexturedRect(cx - half, cy - half, crosshairDrawSize, crosshairDrawSize)
end)

hook.Add("OnScreenSizeChanged", "MonarchCacheScreenSize", function()
    cachedScrW, cachedScrH = ScrW(), ScrH()
end)

concommand.Add("monarch_toggle_thirdperson", function(ply, cmd, args)
    if not IsValid(ply) then return end

    local currentValue = GetConVar("monarch_thirdperson"):GetBool()
    local newValue = not currentValue

    RunConsoleCommand("monarch_thirdperson", newValue and "1" or "0")

    thirdpersontoggled = newValue
end)

concommand.Add("mtp", function(ply, cmd, args)
    RunConsoleCommand("monarch_toggle_thirdperson")
end)
local hudYOffset = 0
local hudTargetYOffset = 0
local lastActivity = CurTime()
local lastHealth, lastArmor = -1, -1
local hudForced = false
local hudForcedTime = 0
local LOW_STAT_THRESHOLD = 35

hook.Add("HUDPaint", "Monarch_MainHud", function()
    if immerse_mode then return end
    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:Alive() then return end

    if not Monarch.hudEnabled then return end

    local health, armor = lp:Health(), lp:Armor()

    if health ~= lastHealth or armor ~= lastArmor then
        lastActivity = CurTime()
        lastHealth, lastArmor = health, armor
    end

    if input.WasKeyPressed(KEY_LALT) then
        hudForced = not hudForced
        if hudForced then
            hudForcedTime = CurTime()
            hudTargetYOffset = 0
        end
    end

    local inactive = (CurTime() - lastActivity > 15)
    local forceExpired = hudForced and (CurTime() - hudForcedTime > 15)

    if (inactive and not hudForced) or forceExpired then
        hudTargetYOffset = 0
        if forceExpired then hudForced = false end
    else
        hudTargetYOffset = 0
    end

    hudYOffset = Lerp(FrameTime() * 5, hudYOffset, hudTargetYOffset)

    surface.SetFont("HUDLgr")
    local hpText = tostring(health)
    local hpMaxText = " | " .. lp:GetMaxHealth()
    local hpW, hpH = surface.GetTextSize(hpText)

    local arText = tostring(armor)
    local arMaxText = " | " .. lp:GetMaxArmor()
    local arW, arH = surface.GetTextSize(arText)

    local hunger = (lp.GetHunger and lp:GetHunger()) or lp:GetNWInt("Hunger", 100)
    local thirst = (lp.GetHydration and lp:GetHydration()) or lp:GetNWInt("Hydration", 100)
    hunger = math.Clamp(math.floor(tonumber(hunger) or 100), 0, 100)
    thirst = math.Clamp(math.floor(tonumber(thirst) or 100), 0, 100)

    local hungerText = tostring(hunger)
    local hungerMaxText = " | 100"
    local hungerW = surface.GetTextSize(hungerText)

    local thirstText = tostring(thirst)
    local thirstMaxText = " | 100"
    local thirstW = surface.GetTextSize(thirstText)

    local normalStatColor = Color(200, 200, 200)
    local lowStatColor = Color(235, 80, 80)

    local function GetStatColor(value, shouldFlash)
        if value >= LOW_STAT_THRESHOLD then
            return normalStatColor
        end

        if shouldFlash then
            local pulse = 0.5 + 0.5 * math.sin(CurTime() * 8)
            return Color(
                math.floor(Lerp(pulse, lowStatColor.r, 200)),
                math.floor(Lerp(pulse, lowStatColor.g, 200)),
                math.floor(Lerp(pulse, lowStatColor.b, 200))
            )
        end

        return lowStatColor
    end

    local healthStatColor = GetStatColor(health, true)
    local armorStatColor = normalStatColor
    local hungerStatColor = normalStatColor
    local thirstStatColor = normalStatColor

    local baseY = cachedScrH - 72 + hudYOffset
    local sectionStartX = 25
    local sectionSpacing = 220

    local healthX = sectionStartX
    local armorX = healthX + sectionSpacing
    local hungerX = armorX + sectionSpacing
    local thirstX = hungerX + sectionSpacing

    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(healthIcon)
    surface.DrawTexturedRect(healthX, baseY, 64, 64)

    local hudBlurAlpha = 140
    draw.SimpleText(hpText, "HUDMedBlur", healthX + 60, baseY + 32, Color(0,0,0,hudBlurAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(hpText, "HUDLgr", healthX + 60, baseY + 30, healthStatColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(hpMaxText, "HUDMedBlur", healthX + 60 + hpW + 5, baseY + 30, Color(0,0,0,hudBlurAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(hpMaxText, "HUDMed", healthX + 60 + hpW + 5, baseY + 30, normalStatColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(armorIcon)
    surface.DrawTexturedRect(armorX, baseY, 64, 64)

    draw.SimpleText(arText, "HUDMedBlur", armorX + 60, baseY + 30, Color(0,0,0,hudBlurAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(arText, "HUDLgr", armorX + 60, baseY + 30, armorStatColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(arMaxText, "HUDMedBlur", armorX + 60 + arW + 5, baseY + 30, Color(0,0,0,hudBlurAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(arMaxText, "HUDMed", armorX + 60 + arW + 5, baseY + 30, normalStatColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(hungerIcon)
    surface.DrawTexturedRect(hungerX, baseY, 64, 64)

    draw.SimpleText(hungerText, "HUDMedBlur", hungerX + 60, baseY + 30, Color(0,0,0,hudBlurAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(hungerText, "HUDLgr", hungerX + 60, baseY + 30, hungerStatColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(hungerMaxText, "HUDMedBlur", hungerX + 60 + hungerW + 5, baseY + 30, Color(0,0,0,hudBlurAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(hungerMaxText, "HUDMed", hungerX + 60 + hungerW + 5, baseY + 30, normalStatColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(thirstIcon)
    surface.DrawTexturedRect(thirstX, baseY, 64, 64)

    draw.SimpleText(thirstText, "HUDMedBlur", thirstX + 60, baseY + 30, Color(0,0,0,hudBlurAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(thirstText, "HUDLgr", thirstX + 60, baseY + 30, thirstStatColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(thirstMaxText, "HUDMedBlur", thirstX + 60 + thirstW + 5, baseY + 30, Color(0,0,0,hudBlurAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(thirstMaxText, "HUDMed", thirstX + 60 + thirstW + 5, baseY + 30, normalStatColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    if LocalPlayer().IsBleeding and LocalPlayer():IsBleeding() then
        local iconSize = 48
        local margin = 20
        local x = cachedScrW - margin - iconSize
        local y = cachedScrH - margin - iconSize
        local pulse = 0.5 + 0.5 * math.sin(CurTime() * 2) 
        local alpha = math.Clamp(math.floor(80 + 175 * pulse), 0, 255)
        surface.SetMaterial(healthIcon)
        surface.SetDrawColor(255, 50, 50, alpha)
        surface.DrawTexturedRect(x, y, iconSize, iconSize)
    end
end)

surface.CreateFont("MonarchInventoryIndicator", {
    font = "Din Pro Bold",
    size = 50,
    weight = 500,
})

Monarch.InventoryOpen = false
Monarch.InventoryIndicatorAlpha = 0
Monarch.InventoryIndicatorTargetAlpha = 0

local function CheckInventoryPanelOpen()
    local world = vgui.GetWorldPanel()
    if IsValid(world) then
        for _, child in ipairs(world:GetChildren()) do
            if child.ClassName == "MonarchInventory" and IsValid(child) and child:IsVisible() then
                Monarch.InventoryOpen = true
                Monarch.InventoryIndicatorTargetAlpha = 255
                return
            end
        end
    end
    Monarch.InventoryOpen = false
    Monarch.InventoryIndicatorTargetAlpha = 0
end

hook.Add("Think", "Monarch_InventoryIndicator_Detect", function()
    CheckInventoryPanelOpen()

    local lerpSpeed = FrameTime() * 500
    if Monarch.InventoryIndicatorAlpha < Monarch.InventoryIndicatorTargetAlpha then
        Monarch.InventoryIndicatorAlpha = math.min(Monarch.InventoryIndicatorAlpha + lerpSpeed, Monarch.InventoryIndicatorTargetAlpha)
    elseif Monarch.InventoryIndicatorAlpha > Monarch.InventoryIndicatorTargetAlpha then
        Monarch.InventoryIndicatorAlpha = math.max(Monarch.InventoryIndicatorAlpha - lerpSpeed, Monarch.InventoryIndicatorTargetAlpha)
    end
end)

hook.Add("PostPlayerDraw", "Monarch_InventoryIndicator_Draw", function(ply)
    if not IsValid(ply) then return end
    if Monarch.InventoryIndicatorAlpha <= 0 then return end
    if ply ~= LocalPlayer() then return end

    local pos = ply:GetPos() + Vector(0,0, 75)
    local eyeAngles = EyeAngles()
    local ang = Angle(0, eyeAngles.y - 90, 90)

    cam.Start3D2D(pos, ang, 0.05)
        surface.SetFont("MonarchInventoryIndicator")
        surface.SetTextColor(200, 200, 200, Monarch.InventoryIndicatorAlpha)

        local text = "Searching belongings"
        local tw, th = surface.GetTextSize(text)

        surface.SetTextPos(-tw / 2, 0)
        surface.DrawText(text.."...")
    cam.End3D2D()
end)

hook.Add("PostPlayerDraw", "Monarch_VoiceMicIndicator", function(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    if ply == LocalPlayer() and not LocalPlayer():ShouldDrawLocalPlayer() then return end
    if not ply:IsSpeaking() then return end

    local lp = LocalPlayer()
    if IsValid(lp) and lp ~= ply and lp:GetPos():DistToSqr(ply:GetPos()) > (900 * 900) then return end

    local volume = 0
    if ply.VoiceVolume then
        volume = math.Clamp(tonumber(ply:VoiceVolume()) or 0, 0, 1)
    end

    local voiceKey = ply:EntIndex()
    local previousVolume = micVoiceLerp[voiceKey] or 0
    local smoothingSpeed = (volume > previousVolume) and 20 or 12
    local smoothVolume = Lerp(FrameTime() * smoothingSpeed, previousVolume, volume)
    micVoiceLerp[voiceKey] = smoothVolume

    local easedVolume = smoothVolume * smoothVolume * (3 - (2 * smoothVolume))

    local pos = ply:GetPos() + Vector(0, 0, ply:OBBMaxs().z + 5)
    local eyeAngles = EyeAngles()
    local ang = Angle(0, eyeAngles.y - 90, 90)

    local baseSize = 100
    local moverSize = 65
    local moverTravel = 22
    local moverBaseY = -moverSize * 0.15
    local moverHeightBase = 10
    local moverHeight = moverHeightBase - (easedVolume * moverTravel * 5)
    local moverY = moverBaseY + (moverHeight - moverHeightBase)

    cam.Start3D2D(pos, ang, 0.05)
        surface.SetMaterial(micIconMat)
        surface.SetDrawColor(255, 255, 255, 240)
        surface.DrawTexturedRect(-baseSize * 0.5, -baseSize * 0.5, baseSize, baseSize)
    cam.End3D2D()
end)

-- Debug HUD to show entity information
CreateClientConVar("monarch_debug_entity", "0", true, false, "Shows entity debug information")

hook.Add("HUDPaint", "Monarch_DebugEntityInfo", function()
    if not GetConVar("monarch_debug_entity"):GetBool() then return end
    
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    
    local trace = lp:GetEyeTrace()
    if not trace.Hit then return end
    
    local ent = trace.Entity
    local x, y = 20, ScrH() / 2
    local lineHeight = 20
    
    -- Background
    surface.SetDrawColor(0, 0, 0, 200)
    surface.DrawRect(x - 5, y - 5, 400, 250)
    
    -- Title
    draw.SimpleText("=== ENTITY DEBUG ===", "DermaDefault", x, y, Color(255, 255, 0), TEXT_ALIGN_LEFT)
    y = y + lineHeight
    
    if IsValid(ent) then
        local dist = math.Round(lp:GetPos():Distance(ent:GetPos()), 1)
        
        draw.SimpleText("Class: " .. ent:GetClass(), "DermaDefault", x, y, Color(255, 255, 255), TEXT_ALIGN_LEFT)
        y = y + lineHeight
        
        draw.SimpleText("Model: " .. (ent:GetModel() or "none"), "DermaDefault", x, y, Color(200, 200, 200), TEXT_ALIGN_LEFT)
        y = y + lineHeight
        
        draw.SimpleText("Distance: " .. dist .. " units", "DermaDefault", x, y, Color(150, 255, 150), TEXT_ALIGN_LEFT)
        y = y + lineHeight
        
        draw.SimpleText("EntIndex: " .. ent:EntIndex(), "DermaDefault", x, y, Color(150, 200, 255), TEXT_ALIGN_LEFT)
        y = y + lineHeight
        
        -- Door-specific info
        if string.find(ent:GetClass(), "door", 1, true) then
            y = y + 5
            draw.SimpleText("--- DOOR INFO ---", "DermaDefault", x, y, Color(255, 200, 0), TEXT_ALIGN_LEFT)
            y = y + lineHeight
            
            local owner = ent:GetNWEntity("MonarchDoorOwner")
            draw.SimpleText("Owner: " .. (IsValid(owner) and owner:Nick() or "None"), "DermaDefault", x, y, Color(255, 255, 255), TEXT_ALIGN_LEFT)
            y = y + lineHeight
            
            local group = ent:GetNWString("MonarchDoorGroup", "")
            draw.SimpleText("Group: " .. (group ~= "" and group or "None"), "DermaDefault", x, y, Color(255, 255, 255), TEXT_ALIGN_LEFT)
            y = y + lineHeight
            
            local locked = ent:GetNWBool("MonarchDoorLocked", false)
            draw.SimpleText("Locked: " .. (locked and "YES" or "NO"), "DermaDefault", x, y, locked and Color(255, 100, 100) or Color(100, 255, 100), TEXT_ALIGN_LEFT)
            y = y + lineHeight
            
            local doorName = ent:GetNWString("DoorName", "")
            draw.SimpleText("Name: " .. (doorName ~= "" and doorName or "None"), "DermaDefault", x, y, Color(200, 200, 255), TEXT_ALIGN_LEFT)
            y = y + lineHeight
        end
        
    else
        draw.SimpleText("No Entity", "DermaDefault", x, y, Color(255, 100, 100), TEXT_ALIGN_LEFT)
    end
end)


