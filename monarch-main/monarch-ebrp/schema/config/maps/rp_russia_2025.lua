MapConfig = MapConfig or {}

MapConfig.DefaultSpawnVector = Vector(-1496.571777, -53.332527, -543.978699)
MapConfig.BackDropCoord = Vector(-142.783386, -494.999298, -68.553276)
MapConfig.BackDropAngs = Angle(23.083759, -89.175339, 0.000000)

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