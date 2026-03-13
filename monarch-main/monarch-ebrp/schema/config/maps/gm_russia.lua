local MapConfig = {}

MapConfig.DefaultSpawnVector = Vector(-3051.115234, 2407.534180, 127.942612)
MapConfig.BackDropCoord      = Vector(-1988.984375, 1683.275146, 448.016754)
MapConfig.BackDropAngs       = Angle(13.404781, 150.972122, 0.000000)

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