MapConfig = MapConfig or {}

MapConfig.DefaultSpawnVector = Vector(-2850.554443, -12502.377930, 64.036118)
MapConfig.BackDropCoord = Vector(-3784.385498, -315.268890, 1010.624268)
MapConfig.BackDropAngs = Angle(15.789705, 119.877007, 0.000000)

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