ENT.Base			= "base_anim"
ENT.Type			= "anim"
ENT.PrintName		= "Product Recepticle"
ENT.Author			= "Thrawn"
ENT.Category 		= "Monarch: Industry"
ENT.AutomaticFrameAdvance = true

ENT.Spawnable = true
ENT.AdminOnly = true

ENT.HUDInstructionsText = "Put finished packages in here."

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "RecepticleName")
end

function ENT:GetName()
	local name = self:GetRecepticleName()
	return (name and name ~= "") and name or self.PrintName
end

