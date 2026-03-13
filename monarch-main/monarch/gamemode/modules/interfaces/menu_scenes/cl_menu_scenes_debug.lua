

local debugEnabled = false
local debugOverlay = false

CreateConVar("menu_scenes_debug", "0", FCVAR_ARCHIVE, "Enable menu scenes debug info")
CreateConVar("menu_scenes_show_positions", "0", FCVAR_ARCHIVE, "Show current scene positions")

hook.Add("HUDPaint", "MenuScenesDebug", function()
    local cvarDebug = GetConVar("menu_scenes_debug")
    if not cvarDebug or not cvarDebug:GetBool() then return end
    if not Monarch.MenuScenes or not IsValid(Monarch.MainMenu) then return end

    local scenes = Monarch.MenuScenes
    local name, current, total = scenes:GetSceneInfo()

    local x, y = 10, 10
    local lineHeight = 20

    surface.SetFont("DermaDefault")
    surface.SetTextColor(255, 255, 0, 255)

    surface.SetTextPos(x, y)
    surface.DrawText("=== MENU SCENES DEBUG ===")
    y = y + lineHeight

    surface.SetTextColor(100, 255, 100, 255)
    surface.SetTextPos(x, y)
    surface.DrawText("Current Scene: " .. name .. " (" .. current .. "/" .. total .. ")")
    y = y + lineHeight

    local scene = scenes.scenes[scenes.currentScene]
    if scene then
        local progress = math.min((scenes.sceneTransitionTime) / scene.duration, 1)
        local percent = math.Round(progress * 100)

        surface.SetTextColor(100, 150, 255, 255)
        surface.SetTextPos(x, y)
        surface.DrawText("Progress: " .. percent .. "% (" .. math.Round(scenes.sceneTransitionTime, 2) .. "s / " .. scene.duration .. "s)")
        y = y + lineHeight
    end

    surface.SetTextColor(255, 100, 100, 255)
    surface.SetTextPos(x, y)
    surface.DrawText("Fade Alpha: " .. math.Round(scenes.fadeAlpha))
    y = y + lineHeight

    local cvarPos = GetConVar("menu_scenes_show_positions")
    if cvarPos and cvarPos:GetBool() then
        y = y + 10

        surface.SetTextColor(200, 200, 200, 255)

        if scene then
            local pos, ang = scenes:GetCameraView()

            surface.SetTextPos(x, y)
            surface.DrawText("Start Pos: " .. tostring(scene.startPos))
            y = y + lineHeight

            surface.SetTextPos(x, y)
            surface.DrawText("End Pos: " .. tostring(scene.endPos))
            y = y + lineHeight

            surface.SetTextPos(x, y)
            surface.DrawText("Current Pos: " .. tostring(pos))
            y = y + lineHeight

            surface.SetTextPos(x, y)
            surface.DrawText("Current Ang: " .. tostring(ang))
        end
    end
end)

concommand.Add("menu_scenes_info", function(ply, cmd, args)
    if not Monarch.MenuScenes then
        print("Menu scenes not loaded")
        return
    end

    print("\n=== MENU SCENES INFO ===")
    local name, current, total = Monarch.MenuScenes:GetSceneInfo()
    print("Current Scene: " .. name .. " (" .. current .. "/" .. total .. ")")
    print("Total Scenes: " .. total)

    for i, scene in ipairs(Monarch.MenuScenes.scenes) do
        print("\n[Scene " .. i .. "] " .. scene.name)
        print("  Start: " .. tostring(scene.startPos) .. " @ " .. tostring(scene.startAng))
        print("  End: " .. tostring(scene.endPos) .. " @ " .. tostring(scene.endAng))
        print("  Duration: " .. scene.duration .. "s")
    end
    print("=======================\n")
end)

concommand.Add("menu_scenes_next", function(ply, cmd, args)
    if Monarch.MenuScenes then
        Monarch.MenuScenes:NextScene()
        print("Advanced to next scene")
    end
end)

concommand.Add("menu_scenes_reset", function(ply, cmd, args)
    if Monarch.MenuScenes then
        Monarch.MenuScenes:Initialize()
        print("Menu scenes reset to first scene")
    end
end)

concommand.Add("menu_scenes_toggle_debug", function(ply, cmd, args)
    local cvarDebug = GetConVar("menu_scenes_debug")
    local enabled = cvarDebug and cvarDebug:GetBool()
    RunConsoleCommand("menu_scenes_debug", enabled and "0" or "1")
    print("Menu scenes debug: " .. (enabled and "DISABLED" or "ENABLED"))
end)

concommand.Add("menu_scenes_toggle_positions", function(ply, cmd, args)
    local cvarPos = GetConVar("menu_scenes_show_positions")
    local enabled = cvarPos and cvarPos:GetBool()
    RunConsoleCommand("menu_scenes_show_positions", enabled and "0" or "1")
    print("Position display: " .. (enabled and "DISABLED" or "ENABLED"))
end)
