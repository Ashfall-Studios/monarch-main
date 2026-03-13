MapConfig = MapConfig or {}

MapConfig.DefaultSpawnVector = Vector(-2158.721924, 518.841614, -39.968750) 
MapConfig.BackDropCoord = Vector(-1210.959106, 3542.885498, 699.864075)
MapConfig.BackDropAngs = Angle(35.803959, 91.276260, 0.000000)

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