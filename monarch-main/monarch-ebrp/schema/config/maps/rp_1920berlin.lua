Config = Config or {}

Config.DefaultSpawnVector = Vector(-9611.386719, 5599.165039, 7567.979492)
Config.DefaultSpawnVectors = {
	Vector(-9611.386719, 5599.165039, 7567.979492),
	Vector(-9513.748047, 5602.757812, 7567.997070),
}

Config.BackDropCoord = Vector(-6523.353027, 6214.404297, 8198.629883)
Config.BackDropAngs  = Angle(9.470934, 89.835747, 0.000000)

Monarch.MenuScenes = {
    {
        name = "Reichstag",
        startPos = Vector(-7703.761230, 6854.530273, 7837.708984),
        startAng = Angle(1.809198, 90.101227, 0.000000),
        endPos = Vector(-5184.744141, 6932.359375, 7837.645996),
        endAng = Angle(1.809198, 90.101227, 0.000000),
        duration = 24,
    },

    {
        name = "Train Station",
        startPos = Vector(4198.549316, 4205.395020, 7763.295898),
        startAng = Angle(3.692804, 11.583071, 0.000000),
        endPos = Vector(6310.231445, 4635.531250, 7600.725098),
        endAng = Angle(0.565136, -0.093790, 0.000000),
        duration = 24,
    },

    {
        name = "Brandenburg Gate",
        startPos = Vector(3866.332520, 11132.182617, 7700.019531),
        startAng = Angle(3.056746, 177.981766, 0.000000),
        endPos = Vector(367.534637, 11119.006836, 7649.454590),
        endAng = Angle(3.056746, 177.981766, 0.000000),
        duration = 24,
    },

    {
        name = "River",
        startPos = Vector(-10913.520508, 8851.015625, 7286.330078),
        startAng = Angle(1.106188, -91.325592, 0.000000),
        endPos = Vector(-10932.558594, 6984.688965, 7271.089355),
        endAng = Angle(1.106188, -91.325592, 0.000000),
        duration = 24,
    },

}

local colorModifyTab = {
    ["$pp_colour_addr"] = 0.00,
    ["$pp_colour_addg"] = 0.00,
    ["$pp_colour_addb"] = 0.00,
    ["$pp_colour_brightness"] = -0.03,
    ["$pp_colour_contrast"] = 0.85,
    ["$pp_colour_colour"] = 0.35,
    ["$pp_colour_mulr"] = 0.0,
    ["$pp_colour_mulg"] = 0.0,
    ["$pp_colour_mulb"] = 0.0,
}

hook.Add("RenderScreenspaceEffects", "berlin_desat", function()
	DrawColorModify(colorModifyTab)
end)

if SERVER then
	timer.Simple(0.1, function()
		local lightEnv = ents.FindByClass("light_environment")[1]
		if IsValid(lightEnv) then
			lightEnv:SetKeyValue("ambient", "40 40 40")
			lightEnv:SetKeyValue("brightness", "60 60 60 50")

			lightEnv:Fire("SetAngles", tostring(lightEnv:GetAngles()))
		end

		local envSun = ents.FindByClass("env_sun")[1]
		if IsValid(envSun) then
			envSun:Fire("TurnOff")
		end

		local cloudy = ents.FindByClass("gw_t1_cloudy")[1]

		if not IsValid(cloudy) then
			cloudy = ents.Create("gw_t1_cloudy")
			if IsValid(cloudy) then
				cloudy:SetPos(Vector(0, 0, 0))
				cloudy:Spawn()
				cloudy:Activate()
			end
		end
	end)
end