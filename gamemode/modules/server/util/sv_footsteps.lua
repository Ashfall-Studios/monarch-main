
if SERVER then
	local matSounds = {
		[MAT_CONCRETE] = {"player/footsteps/concrete1.wav", "player/footsteps/concrete2.wav", "player/footsteps/concrete3.wav", "player/footsteps/concrete4.wav"},
		[MAT_METAL]    = {"player/footsteps/metal1.wav", "player/footsteps/metal2.wav", "player/footsteps/metal3.wav", "player/footsteps/metal4.wav"},
		[MAT_DIRT]     = {"player/footsteps/dirt1.wav", "player/footsteps/dirt2.wav", "player/footsteps/dirt3.wav", "player/footsteps/dirt4.wav"},
		[MAT_WOOD]     = {"player/footsteps/wood1.wav", "player/footsteps/wood2.wav", "player/footsteps/wood3.wav", "player/footsteps/wood4.wav"},
		[MAT_GRASS]    = {"player/footsteps/grass1.wav", "player/footsteps/grass2.wav", "player/footsteps/grass3.wav", "player/footsteps/grass4.wav"},
		[MAT_SAND]     = {"player/footsteps/sand1.wav", "player/footsteps/sand2.wav", "player/footsteps/sand3.wav", "player/footsteps/sand4.wav"},
		[MAT_GLASS]    = {"player/footsteps/glass1.wav", "player/footsteps/glass2.wav", "player/footsteps/glass3.wav", "player/footsteps/glass4.wav"},
		[MAT_TILE]     = {"player/footsteps/tile1.wav", "player/footsteps/tile2.wav", "player/footsteps/tile3.wav", "player/footsteps/tile4.wav"},
		[MAT_FLESH]    = {"player/footsteps/mud1.wav", "player/footsteps/mud2.wav", "player/footsteps/mud3.wav", "player/footsteps/mud4.wav"},
		[MAT_COMPUTER] = {"player/footsteps/metal1.wav", "player/footsteps/metal2.wav", "player/footsteps/metal3.wav", "player/footsteps/metal4.wav"},
		[MAT_SNOW]     = {"player/footsteps/sand1.wav", "player/footsteps/sand2.wav", "player/footsteps/sand3.wav", "player/footsteps/sand4.wav"},
	}

	for _, bank in pairs(matSounds) do
		for _, snd in ipairs(bank) do
			util.PrecacheSound(snd)
		end
	end

	local defaultSounds = matSounds[MAT_CONCRETE]

	local function pickSound(matType)
		local bank = matSounds[matType] or defaultSounds
		return bank[math.random(1, #bank)]
	end

	hook.Add("Think", "Monarch_WalkingFootsteps", function()
		for _, ply in player.Iterator() do
			if not (IsValid(ply) and ply:Alive() and ply:OnGround()) then
				ply._LastFootstepVel = nil
				continue
			end
			local vel = ply:GetVelocity():Length2D()
			if vel < 5 then
				ply._LastFootstepVel = nil
				continue
			end

			local stepInterval = 0.35
			if vel <= 65 then
				stepInterval = 0.5
			else
				return
			end

			local now = CurTime()
			ply._NextStepTime = ply._NextStepTime or now

			if now >= ply._NextStepTime then
				local pos = ply:GetPos()
				local mins, maxs = ply:OBBMins(), ply:OBBMaxs()
				local start = Vector(pos.x, pos.y, pos.z + mins.z + 1)

				local tr = util.TraceHull({
					start = start,
					endpos = start - Vector(0, 0, 72),
					mins = Vector(-4, -4, 0),
					maxs = Vector(4, 4, 4),
					filter = ply,
					mask = MASK_PLAYERSOLID_BRUSHONLY
				})

				local matType = tr.MatType or MAT_CONCRETE
				local footstepSound = pickSound(matType)
				local pitch = math.random(95, 105)

				ply:EmitSound(footstepSound, 43, pitch, 1, CHAN_BODY)
				sound.Play(footstepSound, pos + Vector(0, 0, 40), 43, pitch, 1)
				ply._NextStepTime = now + stepInterval
			end
		end
	end)
end