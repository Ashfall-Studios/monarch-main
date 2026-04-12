Monarch = Monarch or {}
Monarch.Team = Monarch.Team or {}
Monarch.Team.Name = Monarch.Team.Name or {}
pmeta = FindMetaTable("Player")
meta = meta or {}
meta.OldSetTeam = meta.OldSetTeam or meta.SetTeam

Bteam = 0

function Monarch.Team.SetupTeam(data) 

    if Monarch.Team.Name[data.name] then
        local existingTeamID = Monarch.Team.Name[data.name]

        Monarch.Team[existingTeamID] = {
            name = data.name,
            color = data.color,
            desc = data.desc,
            SpawnPos = data.SpawnPos,
            Model = data.model,
            HasProgression = data.HasProgression or data.hasProgression,
            forceChangeModel = data.forceChangeModel or data.forcechangemodel,
            hungerFactor = data.hungerFactor or data.hungerfactor,
            bodygroups = data.bodygroups,
            Weapons = data.weapons,
            material = data.material,
            handsModel = data.handsModel,
            onBecome = data.onBecome
        }
        team.SetUp(existingTeamID, data.name, data.color, false)
        return existingTeamID
    end

    Bteam = Bteam + 1

    Monarch.Team[Bteam] = {
        name = data.name,
        color = data.color,
        desc = data.desc,
        SpawnPos = data.SpawnPos,
        Model = data.model,
        HasProgression = data.HasProgression or data.hasProgression,
        forceChangeModel = data.forceChangeModel or data.forcechangemodel,
        hungerFactor = data.hungerFactor or data.hungerfactor,
        bodygroups = data.bodygroups,
        Weapons = data.weapons,
        material = data.material,
        handsModel = data.handsModel,
        onBecome = data.onBecome
    }

    Monarch.Team.Name[data.name] = Bteam

    team.SetUp(Bteam, data.name, data.color, false)
    return Bteam
end

function pmeta:GetTeamID()
    local teamID = self:GetPData("TeamID")
    return teamID
end

function pmeta:GetTeamName()
    local teamName = self:GetNWString("TeamName")
    return teamName
end

function pmeta:Monarch_SetTeam(team)
    local td = Monarch.Team[team]

    self:StripWeapons()

    if not td then
        print("Team data not found for team ID:", team)
        return false
    end

    self:SetNWInt("Hydration", self:GetNWInt("Hydration", 100))
    self:SetNWInt("Hunger", self:GetNWInt("Hunger", 100))
    self:SetNWInt("Exhaustion", self:GetNWInt("Exhaustion", 100))

    if td.onBecome then
        td.onBecome(self)
    end

    self:SetNWInt("TeamID", team)

    if td.name then
        self:SetNWString("TeamName", td.name)
    end

    local forceModel = (td.forceChangeModel == true)
    if forceModel then
        if td.Model then
            self:SetModel(td.Model)
        else
            self:SetModel(Config.DefaultModel)
        end
    elseif not (self.MonarchActiveChar and self.MonarchActiveChar.id) then
        if td.Model then
            self:SetModel(td.Model)
        else
            self:SetModel(Config.DefaultModel)
        end
    end

    if td.disabled == true then
        notification.AddLegacy("This team is disabled in this build of monarch.", NOTIFY_GENERIC, 5)
        return false
    end

    if td.WalkSpeed then
       self:SetWalkSpeed(td.WalkSpeed) 
    end

    if td.SprintSpeed then
        self:SetRunSpeed(td.SprintSpeed)
    end

    if td.SpawnPos then
        self:SetPos(td.SpawnPos)
    else
        self:SetPos(Config.DefaultSpawnVector)
    end

    if td.SpawnAngle then
        self:SetAngles(td.SpawnAngle)
    end

    if td.bodygroups then
        for _, bodygroupData in pairs(td.bodygroups) do
            self:SetBodygroup(bodygroupData[1], bodygroupData[2] or math.random(0, self:GetBodygroupCount(bodygroupData[1])))
        end
    else
        self:SetBodyGroups("0000000")
    end

    self:SetTeam(team)
    self:SetupHands()
    return true
end

function Monarch.Team.GetTeams()
    return Monarch.Team
end
