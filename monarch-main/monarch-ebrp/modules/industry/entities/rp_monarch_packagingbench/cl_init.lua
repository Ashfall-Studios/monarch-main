include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local productCount = self:GetNWInt("ProductCount", 0)
    local isProcessing = self:GetNWBool("IsProcessing", false)

    if productCount > 0 and not isProcessing then
        local color

        if productCount >= 3 then
            color = Color(160, 32, 240, 255)
        else
            color = Color(255, 165, 0, 255)
        end

        local pos = self:GetPos() + Vector(0, 0, 30)
        local ang = self:GetAngles()

        render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
        render.MaterialOverride(Material("models/wireframe"))

        local packageModel = ClientsideModel("models/props_junk/cardboard_box003a.mdl", RENDERMODE_TRANSALPHA)
        if IsValid(packageModel) then
            packageModel:SetPos(pos)
            packageModel:SetAngles(ang)
            packageModel:SetNoDraw(true)
            packageModel:DrawModel()
            packageModel:Remove()
        end

        render.MaterialOverride()
        render.SetColorModulation(1, 1, 1)
    end
end

net.Receive("PackageUseTime", function()
    local processTime = net.ReadFloat()
    Monarch_ShowUseBar(vgui.GetWorldPanel(), processTime, "Packaging...")
end)