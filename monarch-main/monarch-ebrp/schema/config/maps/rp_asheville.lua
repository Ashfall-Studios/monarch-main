Config = Config or {}

Config.DefaultSpawnVector = Vector(-2816.419678, 2166.432373, -143.965897)
Config.DefaultSpawnVectors = {
	Vector(-2816.419678, 2166.432373, -143.965897),
}

Config.BackDropCoord = Vector(-6645.544922, 2190.875488, 2686.789307)
Config.BackDropAngs  = Angle(10.798551, -38.951351, 0.000000)

Monarch = Monarch or {}
Monarch.Doors = Monarch.Doors or {}

Monarch.Doors.RegisterGroup("Citizens", function(ply)
    if ply:Team() == TEAM_CITIZEN then return true end
end)

Monarch.Doors.RegisterGroup("VP", function(ply)
    if ply:Team() == TEAM_COP or ply:Team() == TEAM_STASI then return true end
end)

Monarch.Doors.RegisterGroup("NVA", function(ply)
    if ply:Team() == TEAM_MIL or ply:Team() == TEAM_STASI then return true end
end)

Monarch.Doors.RegisterGroup("Government", function(ply)
    if ply:Team() == TEAM_COP or ply:Team() == TEAM_MIL or ply:Team() == TEAM_STASI then return true end
end)

Monarch.Doors.RegisterGroup("None", function(ply)
end)