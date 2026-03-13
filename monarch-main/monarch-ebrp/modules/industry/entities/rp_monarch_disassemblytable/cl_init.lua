include("shared.lua")

local useTimeStart = 0
local useTimeDuration = 0
local showUseTimeUI = false

net.Receive("ShipmentUseTime", function()
    useTimeDuration = net.ReadFloat()
    Monarch_ShowUseBar(vgui.GetWorldPanel(), useTimeDuration, "Disassembling...")
end)

function ENT:Draw()
    self:DrawModel()

    local hasShipment = self:GetNWBool("HasShipment", false)

    if hasShipment then
        local pos = self:GetPos() + Vector(0, 0, 20)
        local ang = self:GetAngles()

        local shipmentModel = ClientsideModel("models/props/CS_militia/crate_extrasmallmill.mdl", RENDERMODE_NORMAL)
        if IsValid(shipmentModel) then
            shipmentModel:SetPos(pos)
            shipmentModel:SetAngles(ang)
            shipmentModel:SetNoDraw(true)
            shipmentModel:DrawModel()
            shipmentModel:Remove()
        end
    end
end