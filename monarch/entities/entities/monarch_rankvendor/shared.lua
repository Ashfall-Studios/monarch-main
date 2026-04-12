ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Rank Vendor"
ENT.Author = "Monarch"
ENT.Category = "Monarch"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.RenderGroup = RENDERGROUP_BOTH

ENT.ContextLabel = "Browse Catalog"
ENT.ShouldShowContext = false

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "RankVendorID")
	self:NetworkVar("String", 1, "VendorName")
	self:NetworkVar("String", 2, "VendorDesc")
	self:NetworkVar("String", 3, "RequiredTeamsStr") -- Serialized string of allowed team IDs
	self:NetworkVar("Int", 0, "RequiredTeam") 
end

-- Helper function to check if a player's team is allowed
function ENT:IsPlayerTeamAllowed(ply)
	if not IsValid(ply) then return false end
	
	local teamsStr = self:GetRequiredTeamsStr()
	if teamsStr and teamsStr ~= "" then
		local allowedTeams = {}
		for teamId in string.gmatch(teamsStr, "%d+") do
			local id = tonumber(teamId)
			if id and id > 0 then
				table.insert(allowedTeams, id)
			end
		end

		if #allowedTeams > 0 then
			for _, teamId in ipairs(allowedTeams) do
				if ply:Team() == teamId then return true end
			end
			return false
		end
	end
	
	-- Fall back to single team check
	local reqTeam = self:GetRequiredTeam()
	if reqTeam > 0 then
		return ply:Team() == reqTeam
	end
	
	return true -- No team restriction
end

-- Set multiple required teams
function ENT:SetRequiredTeams(teams)
	if istable(teams) then
		local cleaned = {}
		local seen = {}
		local function addTeam(value)
			local id = tonumber(value)
			if id and id > 0 and not seen[id] then
				seen[id] = true
				cleaned[#cleaned + 1] = id
			end
		end

		if #teams > 0 then
			for _, teamId in ipairs(teams) do
				addTeam(teamId)
			end
		else
			for key, value in pairs(teams) do
				if value == true then
					addTeam(key)
				else
					addTeam(value)
				end
			end
		end

		if #cleaned > 0 then
			self:SetRequiredTeamsStr(table.concat(cleaned, ","))
		else
			self:SetRequiredTeamsStr("")
		end
	elseif isnumber(teams) then
		if teams > 0 then
			self:SetRequiredTeamsStr(tostring(teams))
		else
			self:SetRequiredTeamsStr("")
		end
	end
end

-- Get multiple required teams as a table
function ENT:GetRequiredTeamsTable()
	local teamsStr = self:GetRequiredTeamsStr()
	if teamsStr and teamsStr ~= "" then
		local allowedTeams = {}
		for teamId in string.gmatch(teamsStr, "%d+") do
			local id = tonumber(teamId)
			if id and id > 0 then
				table.insert(allowedTeams, id)
			end
		end
		if #allowedTeams > 0 then
			return allowedTeams
		end
	end
	
	-- Fall back to single team
	local reqTeam = self:GetRequiredTeam()
	if reqTeam > 0 then
		return {reqTeam}
	end
	
	return {}
end

function ENT:GetDisplayInfo()
	return {
		name = "",
		desc = "",
	}
end

ENT.HUDDisplayText = "Obtain a rank."