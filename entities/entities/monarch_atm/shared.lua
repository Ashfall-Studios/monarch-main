ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "ATM"
ENT.Author = "Monarch"
ENT.Category = "Monarch"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.ShouldShowContext = false

function ENT.FormatMoney(amount)
	if Monarch and Monarch.FormatMoney then
		return Monarch.FormatMoney(amount)
	end
	amount = tonumber(amount) or 0
	return "$"..tostring(amount)
end

ENT.HUDDisplayText = "Manage your bank account."