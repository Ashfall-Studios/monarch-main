include("shared.lua")

function ENT:Draw()
    self:DrawModel()
end

function ENT:OnPopulateEntityInfo(container)
    local name = self:GetRecepticleName()
    local displayName = (name and name ~= "") and name or self.PrintName
    container:AddRow("name", "Name"):SetText(displayName)
end

if CLIENT then
    properties.Add("recepticle_setname", {
        MenuLabel = "Set Name",
        Order = 100,
        MenuIcon = "icon16/tag_blue.png",

        Filter = function(self, ent, ply)
            if not IsValid(ent) then return false end
            if ent:GetClass() ~= "rp_monarch_recepticle" then return false end
            if not gamemode.Call("CanProperty", ply, "recepticle_setname", ent) then return false end
            return true
        end,

        Action = function(self, ent)
            Derma_StringRequest(
                "Set Container Name",
                "Enter a name for this container:",
                ent:GetRecepticleName() or "",
                function(text)
                    net.Start("Monarch_SetRecepticleName")
                        net.WriteEntity(ent)
                        net.WriteString(text)
                    net.SendToServer()
                end
            )
        end,

        MenuOpen = function(self, option, ent, tr)
            option:SetIcon("icon16/tag_blue.png")
        end
    })
end
