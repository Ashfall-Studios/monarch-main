ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Vendor"
ENT.Author = "Monarch"
ENT.Category = "Monarch"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.RenderGroup = RENDERGROUP_BOTH
ENT.ShouldShowContext = false

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "VendorID")
	self:NetworkVar("String", 1, "VendorName")
	self:NetworkVar("String", 2, "VendorDesc")
	self:NetworkVar("Int", 0, "RequiredTeam")
end

function ENT:GetDisplayInfo()
	return {
		name = "",
		desc = "",
	}
end

ENT.HUDDisplayText = "Browse items allotted to your team."
ENT.ContextLabel = "Browse Catalog"