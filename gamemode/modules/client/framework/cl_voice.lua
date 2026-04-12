if CLIENT then

    hook.Add("HUDShouldDraw", "Monarch_HideDefaultVoice", function(name)
        if name == "CHudVoiceStatus" then
            return false
        end
    end)

    local speakingPlayers = {}

    local micIcon = Material("mrp/hud/mic.png", "smooth")

    local ANIM_DURATION = 0.15 
    local ICON_SIZE = 72
    local PADDING = 10
    local NAME_PADDING = 8
    local VERTICAL_SPACING = 8

    surface.CreateFont("Monarch_VoiceNameFont", {
        font = "Purista",
        size = 30,
        weight = 500,
        antialias = true,
    })

    surface.CreateFont("Monarch_VoiceNameFontShadow", {
        font = "Purista",
        size = 30,
        weight = 800,
        antialias = true,
    })

    function GM:PlayerStartVoice(ply)
        if not IsValid(ply) then return true end
        local data = speakingPlayers[ply]
        if not data then
            speakingPlayers[ply] = {
                startTime = CurTime(),
                alpha = 0,
                slideProgress = 0,
                fadeOut = false,
            }
        else

            data.startTime = CurTime()
            data.fadeOut = false
        end
        return true 
    end

    function GM:PlayerEndVoice(ply)
        if not IsValid(ply) then return true end
        local data = speakingPlayers[ply]
        if data and not data.fadeOut then
            data.fadeOut = true
            data.fadeStart = CurTime()
        end
        return true 
    end

    hook.Add("Think", "Monarch_VoiceTracker", function()
        for _, ply in player.Iterator() do
            if IsValid(ply) then
                local isSpeaking = ply:IsSpeaking()
                local data = speakingPlayers[ply]
                if isSpeaking and not data then
                    speakingPlayers[ply] = {
                        startTime = CurTime(),
                        alpha = 0,
                        slideProgress = 0,
                        fadeOut = false,
                    }
                elseif (not isSpeaking) and data and not data.fadeOut then
                    data.fadeOut = true
                    data.fadeStart = CurTime()
                end
            end
        end

        for ply, data in pairs(speakingPlayers) do
            if not IsValid(ply) or (data.fadeOut and CurTime() - (data.fadeStart or 0) > ANIM_DURATION) then
                speakingPlayers[ply] = nil
            end
        end
    end)

    hook.Add("HUDPaint", "Monarch_VoiceIndicator", function()
        if not speakingPlayers or table.IsEmpty(speakingPlayers) then return end

        local scrW, scrH = ScrW(), ScrH()
        local startX = scrW - PADDING
        local startY = scrH * 0.8

        local yOffset = 0

        for ply, data in pairs(speakingPlayers) do
            if IsValid(ply) then
                local elapsed = CurTime() - data.startTime

                if data.fadeOut then
                    local fadeElapsed = CurTime() - data.fadeStart
                    data.slideProgress = 1 - math.Clamp(fadeElapsed / ANIM_DURATION, 0, 1)
                else
                    data.slideProgress = math.Clamp(elapsed / ANIM_DURATION, 0, 1)
                end

                local progress = data.slideProgress
                progress = 1 - math.pow(1 - progress, 3) 

                local charName
                if ply == LocalPlayer() then

                    if Monarch and Monarch.VoiceModes and Monarch.VoiceModes.CurrentModeName then
                        charName = Monarch.VoiceModes.CurrentModeName
                    else
                        charName = "Speaking"
                    end
                else
                    local introName
                    if Monarch and Monarch.Introductions and Monarch.Introductions.GetDisplayName then
                        introName = Monarch.Introductions.GetDisplayName(ply)
                    end

                    if introName and introName ~= "" and introName ~= "Unknown" then
                        charName = introName
                    else
                        charName = "Unrecognized"
                    end
                end

                if not charName then
                    if ply.MonarchActiveChar and ply.MonarchActiveChar.name then
                        charName = ply.MonarchActiveChar.name
                    elseif ply.GetRPName then
                        charName = ply:GetRPName()
                    else
                        charName = ply:Nick()
                    end
                end

                surface.SetFont("Monarch_VoiceNameFont")
                local textW, textH = surface.GetTextSize(charName)

                local totalWidth = ICON_SIZE + NAME_PADDING + textW + PADDING * 2
                local totalHeight = math.max(ICON_SIZE, textH) + PADDING * 2

                local slideOffset = (1 - progress) * (totalWidth + 20)

                local alpha = math.floor(255 * progress)

                local panelX = startX - totalWidth + slideOffset
                local panelY = startY + yOffset

                local iconX = panelX + PADDING
                local iconY = panelY + (totalHeight - ICON_SIZE) / 2 + 2

                if micIcon and not micIcon:IsError() then
                    surface.SetDrawColor(255, 255, 255, alpha)
                    surface.SetMaterial(micIcon)
                    surface.DrawTexturedRect(iconX, iconY, ICON_SIZE, ICON_SIZE)
                end

                local textX = iconX + ICON_SIZE + NAME_PADDING
                local textY = panelY + (totalHeight - textH) / 2

                local textColor = Color(230, 232, 236, alpha)

                if ply == LocalPlayer() and Monarch and Monarch.VoiceModes and Monarch.VoiceModes.CurrentModeColor then
                    local modeColor = Monarch.VoiceModes.CurrentModeColor
                    textColor = Color(modeColor.r, modeColor.g, modeColor.b, alpha)
                end
                
                draw.SimpleText(charName, "Monarch_VoiceNameFontShadow", textX - 9, textY + 3, Color(0,0,0,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(charName, "Monarch_VoiceNameFont", textX - 8, textY, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                

                yOffset = yOffset + totalHeight + VERTICAL_SPACING
            end
        end
    end)
end

