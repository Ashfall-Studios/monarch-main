include("shared.lua")

local factoryUseStart = 0
local factoryUseDuration = 0
local showFactoryUI = false

net.Receive("FactoryUseTime", function()
    factoryUseDuration = net.ReadFloat()
    Monarch_ShowUseBar(vgui.GetWorldPanel(), factoryUseDuration, "Manufacturing...")
end)

function ENT:Draw()
    self:DrawModel()

    local matCount = self:GetNWInt("MaterialCount", 0)
    local reqMats = self:GetNWInt("ReqMats", 2)
    local isProcessing = self:GetNWBool("IsProcessing", false)
    local isBroken = self:GetNWBool("IsBroken", false)
    local color

    if isProcessing then
        color = Color(160, 32, 240, 255)
    elseif matCount >= reqMats then
        color = Color(160, 32, 240, 255)
    elseif matCount > 0 then
        color = Color(255, 165, 0, 255)
    else
        color = Color(255, 0, 0, 255)
    end

    if isBroken then
        color = Color(255, 0, 0, 255 * (0.5 + 0.5 * math.sin(CurTime() * 2)))
    end

    local f, r, u = self:GetForward(), self:GetRight(), self:GetUp()

	local pos = self:GetPos() + f*38 + r*0.1 + u*45

    render.SetMaterial(Material("sprites/glow04_noz"))
    render.DrawSprite(pos, 16, 16, color)

    render.DrawSprite(pos, 8, 8, Color(255, 255, 255, 100))
end
