include("shared.lua")

local sinkDrinkEnt = nil
local sinkDrinkStart = 0
local sinkDrinkDuration = 2

local function FinishSinkDrink(ent)
	if not IsValid(ent) then return end
	net.Start("Monarch_DrinkFinish")
		net.WriteEntity(ent)
	net.SendToServer()
end

net.Receive("Monarch_DrinkStart", function()
	local sink = net.ReadEntity()
	if not IsValid(sink) then return end

	if isfunction(Monarch_ShowUseBar) then
		Monarch_ShowUseBar(vgui.GetWorldPanel() or nil, sinkDrinkDuration, "Drinking...", function()
			FinishSinkDrink(sink)
		end)
		return
	end

	sinkDrinkEnt = sink
	sinkDrinkStart = CurTime()
end)

hook.Add("Think", "Monarch.RPSinkDrinkFallback", function()
	if not IsValid(sinkDrinkEnt) then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then
		sinkDrinkEnt = nil
		return
	end

	local tr = ply:GetEyeTrace()
	if not ply:KeyDown(IN_USE) or not tr or tr.Entity ~= sinkDrinkEnt then
		sinkDrinkEnt = nil
		return
	end

	if CurTime() - sinkDrinkStart >= sinkDrinkDuration then
		FinishSinkDrink(sinkDrinkEnt)
		sinkDrinkEnt = nil
	end
end)

