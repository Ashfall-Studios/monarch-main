TEAM_CITIZEN = Monarch.Team.SetupTeam({
    name = "Occupant",
    color = Color(0, 122, 0),
    model = "models/player/Group03/female_05.mdl",
    material = Material("icons/npc_icon_citizen.png", "mips smooth"),
    onBecome = function(self)
        self:Give("monarch_hands")
    end
})

TEAM_COP = Monarch.Team.SetupTeam({
    name = "Police Force",
    color = Color(150, 207, 188),
    material = Material("icons/player_factions/faction_eye.png", "mips smooth"),
    onBecome = function(self)
        self:Give("monarch_hands")
    end
})

TEAM_MIL = Monarch.Team.SetupTeam({
    name = "State Defense Forces",
    color = Color(68, 98, 205),
    material = Material("icons/player_factions/faction_fist.png", "mips smooth"),
    onBecome = function(self)
        self:Give("monarch_hands")
    end
})

TEAM_STASI = Monarch.Team.SetupTeam({
    name = "State Security",
    color =  Color(207, 207, 55),
    material = Material("icons/player_factions/faction_eye.png", "mips smooth"),
    onBecome = function(self)
        self:Give("monarch_hands")
    end
})

TEAM_GOV = Monarch.Team.SetupTeam({
    name = "DDR Government",
    color = Color(150, 150, 207),
    material = Material("icons/player_factions/faction_star.png", "mips smooth"),
    onBecome = function(self)
        self:Give("monarch_hands")
    end
})

TEAM_CITIZEN = 1
TEAM_COP = 2
TEAM_MIL = 3
TEAM_STASI = 4
TEAM_GOV = 5