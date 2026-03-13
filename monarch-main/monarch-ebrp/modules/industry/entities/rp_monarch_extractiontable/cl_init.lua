include("shared.lua")

local useTimeStart = 0
local useTimeDuration = 0
local showUseTimeUI = false

net.Receive("UseTime", function()
    useTimeDuration = net.ReadFloat()
    Monarch_ShowUseBar(vgui.GetWorldPanel(), useTimeDuration, "Extracting...")
end)

function ENT:Draw()
    self:DrawModel()

    local hasContainer = self:GetNWBool("HasContainer", false)

    if hasContainer then
        local pos = self:GetPos() + Vector(0, 0, 15)
        local ang = self:GetAngles()

        local containerModel = ClientsideModel("models/props/stalker2/wood_crate_02/w_wood_crate_02.mdl", RENDERMODE_NORMAL)
        if IsValid(containerModel) then
            containerModel:SetPos(pos)
            containerModel:SetAngles(ang)
            containerModel:SetNoDraw(true)
            containerModel:DrawModel()
            containerModel:Remove()
        end
    end
end