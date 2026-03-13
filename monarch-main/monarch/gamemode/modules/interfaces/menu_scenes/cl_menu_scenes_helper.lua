local sceneHelper = {}

function sceneHelper:StartCapture()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    self.captureStart = {
        pos = ply:EyePos(),
        ang = ply:EyeAngles(),
    }

    print("Scene start captured at:")
    print("  Position: " .. tostring(self.captureStart.pos))
    print("  Angle: " .. tostring(self.captureStart.ang))
end

function sceneHelper:EndCapture(name, duration)
    if not self.captureStart then
        print("ERROR: Must call StartCapture first!")
        return
    end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    duration = duration or 8
    name = name or "Scene"

    print("\n=== Scene Data ===")
    print("{")
    print('    name = "' .. name .. '",')
    print("    startPos = " .. tostring(self.captureStart.pos) .. ",")
    print("    startAng = " .. tostring(self.captureStart.ang) .. ",")
    print("    endPos = " .. tostring(ply:EyePos()) .. ",")
    print("    endAng = " .. tostring(ply:EyeAngles()) .. ",")
    print("    duration = " .. duration .. ",")
    print("},")
    print("===================\n")

    print("Copy the above into your Monarch.MenuScenes table")
end

concommand.Add("menu_scene_start", function(ply, cmd, args)
    if not IsValid(LocalPlayer()) or LocalPlayer():IsPlayer() == false then
        print("Must be in game to use this command")
        return
    end
    sceneHelper:StartCapture()
end)

concommand.Add("menu_scene_end", function(ply, cmd, args)
    local name = args[1] or "Scene"
    local duration = tonumber(args[2]) or 8
    sceneHelper:EndCapture(name, duration)
end)
