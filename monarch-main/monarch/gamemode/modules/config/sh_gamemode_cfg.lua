Config = Config or {}

Config.MinNameLength = 3
Config.MaxNameLength = 16
Config.Gravity = 1
Config.NotificationLength = 5
Config.GamemodeColor = Color(55, 57, 61, 255)
Config.NotifySound = "ui/hls_hint.wav"
Config.NotifyLeaveSound = ""
Config.InteractMenuSound = "ui/hls_ui_scroll_click.wav"
Config.InteractionMenuClick = "ui/hls_ui_select.wav"
Config.InteractionMenuOptionsMat = "icons/dropdown/option_icon.png"
Config.DefaultMoney = 1000
Config.LogoMaterial = Material("ml-light.png", "mips smooth")
Config.Version = 1
Config.Discord = "https://discord.gg/BDRdamZJYs"
Config.Forums = "https://google.com"

Config.DeafultWeps = {"monarch_hands", "monarch_keys"}
Config.DefaultModel = "models/player/Group01/male_07.mdl"
Config.DefaultTeam = TEAM_CITIZEN
Config.RagdollDespawnTime = 60
Config.StartingMoney = 200
Config.ShouldDrawMedals = true
Config.AdminCanUseSpawnMenu = true
Config.AllowedSpawnMenuGroups = {"admin", "superadmin", "moderator"} 
Config.LOOCCooldown = 15
Config.ShouldDrawTeamIcons = true
Config.MaxChars = 5
Config.StorageGridCols = 5
Config.StorageGridRows = 6

Config.DefaultSpawnVector  = Config.DefaultSpawnVector  or Vector(-3051.115234, 2407.534180, 127.942612)
Config.DefaultSpawnVectors = Config.DefaultSpawnVectors or { Config.DefaultSpawnVector }
Config.BackDropCoord      = Config.BackDropCoord      or Vector(-1988.984375, 1683.275146, 448.016754)
Config.BackDropAngs       = Config.BackDropAngs       or Angle(13.404781, 150.972122, 0)

Config.DefaultStamina = 150
Config.DefaultStaminaDrainRate = 6
Config.DefaultStaminaRegenRate = 3.5

Config.FactionIcons = {
    "icons/player_factions/legacy/crew_anonymous.png",
    "icons/player_factions/legacy/crew_bomb.png",
    "icons/player_factions/legacy/crew_briefcase.png",
    "icons/player_factions/legacy/crew_chef.png",
    "icons/player_factions/legacy/crew_chemist.png",
    "icons/player_factions/legacy/crew_crossbones.png",
    "icons/player_factions/legacy/crew_crossedmachete.png",
    "icons/player_factions/legacy/crew_crown.png",
    "icons/player_factions/legacy/crew_fire.png",
    "icons/player_factions/legacy/crew_gasmask.png",
    "icons/player_factions/legacy/crew_ghost.png",
    "icons/player_factions/legacy/crew_lock.png",
    "icons/player_factions/legacy/crew_skull.png",
    "icons/player_factions/legacy/crew_snowflake.png",
    "icons/player_factions/legacy/crew_spider.png",
    "icons/player_factions/legacy/crew_star.png",
    "icons/player_factions/legacy/crew_tools.png",
}

Config.CharacterModels = {
    "models/willardnetworks_custom/citizens/male01.mdl",
    "models/willardnetworks_custom/citizens/male02.mdl",
    "models/willardnetworks_custom/citizens/male03.mdl",
    "models/willardnetworks_custom/citizens/male04.mdl",
    "models/willardnetworks_custom/citizens/male05.mdl",
    "models/willardnetworks_custom/citizens/male06.mdl",
    "models/willardnetworks_custom/citizens/male07.mdl",
    "models/willardnetworks_custom/citizens/male08.mdl",
    "models/willardnetworks_custom/citizens/male09.mdl",
    "models/willardnetworks_custom/citizens/male10.mdl",
}

Config.FemaleCharacterModels = {
    "models/willardnetworks_custom/citizens/female_01.mdl",
    "models/willardnetworks_custom/citizens/female_02.mdl",
    "models/willardnetworks_custom/citizens/female_03.mdl",
    "models/willardnetworks_custom/citizens/female_04.mdl",
    "models/willardnetworks_custom/citizens/female_05.mdl",
    "models/willardnetworks_custom/citizens/female_06.mdl",
    "models/willardnetworks_custom/citizens/female_07.mdl",
    "models/willardnetworks_custom/citizens/female_08.mdl",
    "models/willardnetworks_custom/citizens/female_09.mdl",
    "models/willardnetworks_custom/citizens/female_10.mdl",
}

Config.DefaultJogSpeed = 200
Config.DefaultSpeedWalkSpeed = 140
Config.DefaultWalkSpeed = 60
Config.DeathTimer = 150
Config.UnconsciousTimer = 15
Config.ExhaustionCollapseTime = 10
Config.CPRTime = 6
Config.CPRSuccessChance = 0.35
Config.CPRUseDistance = 130
Config.CPRAttemptCooldown = 1.5
Config.SchemaName = "Monarch Roleplay"

Config.ThirstDecayAmount = 1.3
Config.HungerDecayAmount = 1.7
Config.ExhaustionDecayAmount = 1
Config.TickTime = 90 

Config.Discord = ""
Config.Forums = ""
Config.Donations = ""

Config.LoadButtonText = "Enter The City..."

Config.DefaultOperator = "STEAM_0:0:581542620" 

Monarch = Monarch or {}
Monarch.Doors = Monarch.Doors or {}

if Monarch.Doors.RegisterGroup then
    Monarch.Doors.RegisterGroup("Citizens", function(ply)
        if ply:Team() == TEAM_CITIZEN then return true end
    end)

    Monarch.Doors.RegisterGroup("Civil Protection", function(ply)
        if ply:Team() == TEAM_CP then return true end
    end)

    Monarch.Doors.RegisterGroup("Transhuman Arm", function(ply)
        if ply:Team() == TEAM_OTA then return true end
    end)

    Monarch.Doors.RegisterGroup("Combine", function(ply)
        if ply:Team() == TEAM_CP or ply:Team() == TEAM_OTA then return true end
    end)

    Monarch.Doors.RegisterGroup("None", function(ply)
    end)
end

-- Look in modules/server/framework/sv_sql.lua for database configuration. For security purposes I do not recommend placing it here.