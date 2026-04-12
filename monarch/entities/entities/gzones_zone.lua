if SERVER then
	ENT.Base = "base_brush"
	ENT.Type = "brush"
	ENT.IsZoneTrigger = true

	function ENT:SetBounds(min, max)
	    print("Setting bounds")
	    self:DrawShadow(false)
		self:SetNotSolid(true)
	    self:SetSolid(SOLID_BBOX)
	    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)

	    self:SetCollisionBounds(min, max)
	    self:SetTrigger(true)
	    self:SetMoveType(MOVETYPE_NONE)
	end

	function ENT:StartTouch(ent)
	    if not ent:IsPlayer() then
	        return
	    end

		ent.ShowZone = true
	    ent:SetZone(self.Zone)
	end

	function ENT:EndTouch(ent)
		ent:SetZone(999999)
	end

	function ENT:Touch(ent)
		return
	end

	function ENT:UpdateTransmitState()
		return TRANSMIT_NEVER
	end
end
