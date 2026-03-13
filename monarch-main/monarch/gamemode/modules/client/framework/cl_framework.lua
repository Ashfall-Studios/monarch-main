local cache = {}
local _GetChildBonesRecursive
local mdl = ""

local ENTITY, PLAYER = FindMetaTable("Entity"), FindMetaTable("Player")
local VECTOR = FindMetaTable("Vector")
local DistToSqr = VECTOR.DistToSqr
local Dot = VECTOR.Dot
local GetModel = ENTITY.GetModel
local GetChildBones = ENTITY.GetChildBones
local next = next
local pairs, ipairs = pairs, ipairs
local hook_Run = hook.Run
local render = render
local render_GetRenderTarget = render.GetRenderTarget
local render_SetColorModulation = render.SetColorModulation
local render_GetColorModulation = render.GetColorModulation
local math_NormalizeAngle = math.NormalizeAngle

_GetChildBonesRecursive = function(ent, bone, src)
	local t = src or {}
	table.insert(t, bone)
	local cbones = GetChildBones(ent, bone)

	if cbones then
		for _, bone in next, cbones do
			_GetChildBonesRecursive(ent, bone, t)
		end
	end

	return t
end

local function GetChildBonesRecursive(ent, bone)
	local mdl = GetModel(ent)
	local mdlbones = cache[mdl]

	if not mdlbones then
		mdlbones = {}
		cache[mdl] = mdlbones
	end

	local ret = mdlbones[bone]
	if ret then return ret end
	ret = _GetChildBonesRecursive(ent, bone)
	mdlbones[bone] = ret

	return ret
end

local forwardDistance = 13

local defaultConVars = {
	cl_gm_body = "1",
	cl_gm_body_in_vehicle = "0",
	cl_gm_body_forward_distance = "13",
	cl_gm_body_enable_shadow = "0"
}
local queue = {}
local work = false

local MarkToRemove = function(ent)
	if not IsValid(ent) then
		return
	end

	work = true
	ent:SetNoDraw(true)
	table.insert(queue, ent)
end

hook.Add("Think", "legs.MarkToRemove", function()
	if not work then
		return
	end

	for key, ent in pairs(queue) do
		if ent:IsValid() then
			ent:Remove()
		end

		queue[key] = nil
	end

	if not next(queue) then
		work = false
	end
end)

hook.Add("LocalPlayer_Validated", "cl_gmod_legs", function(ply)
	hook.Remove("LocalPlayer_Validated", "cl_gmod_legs")

	local playermodelbones = {"ValveBiped.Bip01_Head1","ValveBiped.Bip01_R_Trapezius","ValveBiped.Bip01_R_Bicep","ValveBiped.Bip01_R_Shoulder", "ValveBiped.Bip01_R_Elbow","ValveBiped.Bip01_R_Wrist","ValveBiped.Bip01_R_Ulna","ValveBiped.Bip01_L_Trapezius","ValveBiped.Bip01_L_Bicep","ValveBiped.Bip01_L_Shoulder", "ValveBiped.Bip01_L_Elbow","ValveBiped.Bip01_L_Wrist","ValveBiped.Bip01_L_Ulna", "ValveBiped.Bip01_Neck1","ValveBiped.Bip01_Hair1","ValveBiped.Bip01_Hair2","ValveBiped.Bip01_L_Clavicle","ValveBiped.Bip01_R_Clavicle","ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_L_Forearm", "ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_L_Wrist", "ValveBiped.Bip01_R_Wrist", "ValveBiped.Bip01_L_Finger4", "ValveBiped.Bip01_L_Finger41", "ValveBiped.Bip01_L_Finger42", "ValveBiped.Bip01_L_Finger3", "ValveBiped.Bip01_L_Finger31", "ValveBiped.Bip01_L_Finger32", "ValveBiped.Bip01_L_Finger2", "ValveBiped.Bip01_L_Finger21", "ValveBiped.Bip01_L_Finger22", "ValveBiped.Bip01_L_Finger1", "ValveBiped.Bip01_L_Finger11", "ValveBiped.Bip01_L_Finger12", "ValveBiped.Bip01_L_Finger0", "ValveBiped.Bip01_L_Finger01", "ValveBiped.Bip01_L_Finger02", "ValveBiped.Bip01_R_Finger4", "ValveBiped.Bip01_R_Finger41", "ValveBiped.Bip01_R_Finger42", "ValveBiped.Bip01_R_Finger3", "ValveBiped.Bip01_R_Finger31", "ValveBiped.Bip01_R_Finger32", "ValveBiped.Bip01_R_Finger2", "ValveBiped.Bip01_R_Finger21", "ValveBiped.Bip01_R_Finger22", "ValveBiped.Bip01_R_Finger1", "ValveBiped.Bip01_R_Finger11", "ValveBiped.Bip01_R_Finger12", "ValveBiped.Bip01_R_Finger0", "ValveBiped.Bip01_R_Finger01", "ValveBiped.Bip01_R_Finger02"}
	local playermodelbones_kv = {}

	for key, v in pairs(playermodelbones) do
		playermodelbones_kv[v] = true
	end

	local ply = ply or LocalPlayer()

	local GetBoneName = ENTITY.GetBoneName
	local LookupBone = ENTITY.LookupBone

	local MATRIX = FindMetaTable("VMatrix")
	local Scale, Translate, SetTranslation, SetAngles = MATRIX.Scale, MATRIX.Translate, MATRIX.SetTranslation, MATRIX.SetAngles
	local GetTranslation, GetAngles = MATRIX.GetTranslation, MATRIX.GetAngles
	local SetBoneMatrix = ENTITY.SetBoneMatrix
	local render = render
	local cam_Start3D, render_EnableClipping, render_PushCustomClipPlane, render_PopCustomClipPlane, render_EnableClipping, cam_End3D =
		cam.Start3D, render.EnableClipping, render.PushCustomClipPlane, render.PopCustomClipPlane, render.EnableClipping, cam.End3D
	local SetupBones = ENTITY.SetupBones
	local _EyePos = ENTITY.EyePos
	local CurTime = CurTime
	local FrameTime = FrameTime
	local GetCycle = ENTITY.GetCycle
	local DrawModel = ENTITY.DrawModel
	local ManipulateBonePosition = ENTITY.ManipulateBonePosition
	local ManipulateBoneScale = ENTITY.ManipulateBoneScale
	local GetAttachment = ENTITY.GetAttachment
	local GetNWBool = ENTITY.GetNWBool
	local LookupAttachment = ENTITY.LookupAttachment
	local GetCurrentViewOffset = PLAYER.GetCurrentViewOffset
	local Crouching = PLAYER.Crouching
	local OnGround = ENTITY.OnGround
	local ShouldDrawLocalPlayer = PLAYER.ShouldDrawLocalPlayer
	local Alive = PLAYER.Alive
	local GetRagdollEntity = PLAYER.GetRagdollEntity
	local InVehicle = PLAYER.InVehicle
	local FL_ANIMDUCKING = FL_ANIMDUCKING

	local GetObserverMode = PLAYER.GetObserverMode

	MarkToRemove(ply.Body)
	MarkToRemove(ply.Body_NoDraw)
	MarkToRemove(ply.Body_Shadow)

	local hook = hook
	local math = math
	local remap = math.Remap
	local eyeAngles = Angle()
	local suppress = false

	local isDucking = false
	local finalPos = Vector()
	local limit_check = 0
	local timeCache = 0.15
	local vector_origin = Vector(0, 0, 0)

	local find, insert = string.find, table.insert

	local SetPoseParameter, GetPoseParameter = ENTITY.SetPoseParameter, ENTITY.GetPoseParameter
	local SetPlaybackRate, GetPlaybackRate = ENTITY.SetPlaybackRate, ENTITY.GetPlaybackRate
	local GetBoneMatrix = ENTITY.GetBoneMatrix

	local a1, b1, c1 = 0, 0, 0
	local headPos = Vector(0,10000,0)
	local limitJump = 0

	local onGround = true
	local JUMPING_ = false
	local vehicle_steer,d1,e1 = 0, 0, 0
	local GetNumPoseParameters, GetPoseParameterRange = ENTITY.GetNumPoseParameters, ENTITY.GetPoseParameterRange
	local GetPoseParameterName, GetSequence = ENTITY.GetPoseParameterName, ENTITY.GetSequence
	local GetRenderAngles, SetRenderAngles = PLAYER.GetRenderAngles, PLAYER.SetRenderAngles
	local faggot = Vector()
	local GetPos, GetViewOffset = ENTITY.GetPos, PLAYER.GetViewOffset
	local vector_normal = Vector(1, 1, 1)
	local vector_fixCrouch = Vector()
	local CreateShadow, DestroyShadow, SetRenderBounds = ENTITY.CreateShadow, ENTITY.DestroyShadow, ENTITY.SetRenderBounds
	local vrmod = vrmod
	local mins_render, maxs_render = Vector(-128, -128, 0), Vector(128, 128, 0)
	local eyePos = Vector()
	local ply_EyePos = Vector()

	hook.Add("SetupMove", "legs.SetupMove", function(ply, move)
		if not IsFirstTimePredicted() then
			return
		end

		if bit.band(move:GetButtons(), IN_JUMP) ~= 0
			and bit.band(move:GetOldButtons(), IN_JUMP) == 0
			and OnGround(ply) then
			JUMPING_, onGround = not JUMPING_, false
		end
	end)

	hook.Add("FinishMove", "legs.FinishMove", function(ply, move)
		if not IsFirstTimePredicted() then
			return
		end

		local isOnGround = OnGround(ply)

		if onGround ~= isOnGround then
			onGround = isOnGround

			if onGround then
				limitJump = CurTime() + FrameTime()
			end
		end
	end)

	local validBones = {}

	hook.Add("CalcView", "body.CalcView", function(ply, vec, ang)

		if ply:InVehicle() then return end

		vehicle_steer = GetPoseParameter(ply, "vehicle_steer")
		d1 = GetPoseParameter(ply, "head_yaw")
		e1 = GetPoseParameter(ply, "head_pitch")

		local a1, b1, c1 = GetPoseParameter(ply, "body_yaw", 0), GetPoseParameter(ply, "aim_yaw", 0), GetPoseParameter(ply, "aim_pitch", 0)

		SetPoseParameter(ply, "body_yaw", 0)
		SetPoseParameter(ply, "aim_yaw", 0)
		SetPoseParameter(ply, "aim_pitch", 0)

		SetPoseParameter(ply, "vehicle_steer", 0)
		SetPoseParameter(ply, "head_yaw", 0)
		SetPoseParameter(ply, "head_pitch", 0)

		SetupBones(ply)

		local h = LookupAttachment(ply, "eyes")

		if h then
			local mat = GetAttachment(ply, h)

			if mat then
				local pos = mat.Pos
				vec.x = vec.x - (vec.x - pos.x)
				vec.y = vec.y - (vec.y - pos.y)
			end
		end

		SetPoseParameter(ply, "vehicle_steer", vehicle_steer)
		SetPoseParameter(ply, "head_yaw", d1)
		SetPoseParameter(ply, "head_pitch", e1)

		SetPoseParameter(ply, "body_yaw", a1)
		SetPoseParameter(ply, "aim_yaw", b1)
		SetPoseParameter(ply, "aim_pitch", c1)
	end)

	local removeGarbage = function(bonesSuccess, boneCount)
		local ent = ply.Body
		local goofyUhhPosition = GetPos(ply) + GetViewOffset(ply) - eyeAngles:Forward() * 32
		local inVeh = InVehicle(ply)
		local forward = eyeAngles:Forward() * forwardDistance

		for i = 0, boneCount - 1 do
			local boneName = GetBoneName(ent, i)
			local mat = GetBoneMatrix(ent, i)

			if mat then
				if playermodelbones_kv[boneName] then
					SetTranslation(mat, goofyUhhPosition)

					bonesSuccess[i] = true

					local recursive = GetChildBonesRecursive(ent, i)

					for key = 1, #recursive do
						local bone = recursive[key]

						if not bonesSuccess[bone] then
							bonesSuccess[bone] = true

							local mat = GetBoneMatrix(ent, bone)

							if mat then
								SetTranslation(mat, goofyUhhPosition)

								SetBoneMatrix(ent, bone, mat)
							end
						end
					end
				elseif not bonesSuccess[i] then
					local bone = LookupBone(ply, boneName)

					if bone then
						local mat2 = GetBoneMatrix(ply, bone)

						if mat2 then
							SetTranslation(mat, GetTranslation(mat2) - forward - vector_fixCrouch)
							SetAngles(mat, GetAngles(mat2))
						end
					end
				end

				SetBoneMatrix(ent, i, mat)
			end
		end
	end

	local Legs_NoDraw_Angle = Angle(0, 0, 0)
	local potentionalBones, timeCacheBones = {}, 0

	local spineBones = {
		["ValveBiped.Bip01_Spine2"] = true,
		["ValveBiped.Bip01_Spine4"] = true
	}

	local miscSpineBones = {}
	local ik_foot = hook.GetTable()["PostPlayerDraw"]

	if ik_foot then
		ik_foot = ik_foot["IKFoot_PostPlayerDraw"]
	end

	local body_is_rendering = true
	local angle_render = Angle()

	if VMS and VMS.GetViewModels then
		VMS_GetViewModels = VMS_GetViewModels or VMS.GetViewModels
		local VMS_GetViewModels = VMS_GetViewModels

		function VMS.GetViewModels(...)
			local mdls = VMS_GetViewModels(...)

			if IsValid(ply.Body) then
				table.insert(mdls, ply.Body)
			end

			return mdls
		end
	end

	local shadow_buildBonePosition = function()
		ply.Body_Shadow.Callback = ply.Body_Shadow:AddCallback("BuildBonePositions", function(ent, boneCount)
			local ang = GetRenderAngles(ply)
			local forward = eyeAngles:Forward() * forwardDistance + vector_fixCrouch

			SetRenderAngles(ply, eyeAngles)
			a1, b1, d1 = GetPoseParameter(ply, "body_yaw", 0), GetPoseParameter(ply, "aim_yaw", 0), GetPoseParameter(ply, "head_yaw", 0)

			SetPoseParameter(ply, "body_yaw", 0)
			SetPoseParameter(ply, "aim_yaw", 0)
			SetPoseParameter(ply, "head_yaw", 0)

			SetupBones(ply)

			for i = 0, boneCount - 1 do
				local boneName = GetBoneName(ent, i)
				local lookupBone = LookupBone(ply, boneName)

				if lookupBone then
					local mat = GetBoneMatrix(ply, lookupBone)

					if mat then
						local mat2 = GetBoneMatrix(ent, i)

						if mat2 then
							SetTranslation(mat2, GetTranslation(mat) - forward)
							SetAngles(mat2, GetAngles(mat))
							SetBoneMatrix(ent, i, mat2)
						end
					end
				end
			end

			SetRenderAngles(ply, ang)

			SetPoseParameter(ply, "body_yaw", a1)
			SetPoseParameter(ply, "aim_yaw", b1)
			SetPoseParameter(ply, "head_yaw", d1)
		end)
	end

	local buildBonePosition = function()
		ply.Body.Callback = ply.Body:AddCallback("BuildBonePositions", function(ent, boneCount)
			if not ply.TimeToDuck
				or suppress then
				return
			end

			local ang = GetRenderAngles(ply)
			local inVehicle = InVehicle(ply)

			if not inVehicle then
				SetRenderAngles(ply, eyeAngles)
			end

			a1, b1, c1 = GetPoseParameter(ply, "body_yaw", 0), GetPoseParameter(ply, "aim_yaw", 0), GetPoseParameter(ply, "aim_pitch", 0)

			SetPoseParameter(ply, "body_yaw", 0)
			SetPoseParameter(ply, "aim_yaw", 0)
			SetPoseParameter(ply, "aim_pitch", 0)

			local currentSequence = ply:GetSequence()

			if ent.Seq ~= currentSequence then
				ent.Seq = currentSequence

				ply:ResetSequenceInfo()
			end

			SetupBones(ply)

			local legsNoDraw = ply.Body_NoDraw

			for i = 0, GetNumPoseParameters(ply) - 1 do
				local flMin, flMax = GetPoseParameterRange(ply, i)
				local sPose = GetPoseParameterName(ply, i)
				local remap = remap(GetPoseParameter(ply, sPose), 0, 1, flMin, flMax)
				SetPoseParameter(legsNoDraw, sPose, remap)
				SetPoseParameter(ent, sPose, remap)
			end

			if ik_foot then
				ik_foot(ply)
			end

			hook_Run("body.SetupBones", ent)

			local bonesSuccess = {}
			removeGarbage(bonesSuccess, boneCount)

			SetPoseParameter(ply, "body_yaw", a1)
			SetPoseParameter(ply, "aim_yaw", b1)
			SetPoseParameter(ply, "aim_pitch", c1)

			SetupBones(legsNoDraw)

			local this = (2 - (0.8 * ply.TimeToDuck))
			local cacheThis = this
			local CT = CurTime()

			if not inVehicle then
				if timeCacheBones < CT then
					timeCacheBones, potentionalBones, miscSpineBones, timeCache = CT + timeCache, {}, {}, 0.15

					for boneName in pairs(spineBones) do
						local bone = LookupBone(ent, boneName)

						if bone then
							local bones = GetChildBonesRecursive(ent, bone)

							for i = 1, #bones do
								miscSpineBones[bones[i]] = true
							end
						end
					end

					for i = 1, #validBones do
						local array = validBones[i]
						local bone, isPelvis = array[2], array[1]

						if bonesSuccess[bone] then
							continue
						end

						local recursive = GetChildBonesRecursive(ent, bone)

						for key = 1, #recursive do
							local i = recursive[key]

							if not bonesSuccess[i]
								and (isPelvis and i == bone or not isPelvis)
								and i then
								bonesSuccess[i] = true

								local boneName = GetBoneName(ent, i)
								local mat = GetBoneMatrix(ent, i)

								if mat then
									local b = LookupBone(legsNoDraw, boneName)

									if b then
										local mat2 = GetBoneMatrix(legsNoDraw, b)

										if mat2 then
											local matTR, mat2TR = GetTranslation(mat), GetTranslation(mat2) - vector_fixCrouch

											if boneName == "ValveBiped.Bip01_Pelvis" then
												Legs_NoDraw_Angle.y = (math_NormalizeAngle(eyeAngles.y - GetAngles(mat).y) + 90) / 1.25
											elseif spineBones[boneName] then
												this = 4
											elseif miscSpineBones[i] then
												this = 5
											end

											SetTranslation(mat, mat2TR - (mat2TR - matTR) / this)
											this = cacheThis
											SetAngles(mat, GetAngles(mat2))
											SetBoneMatrix(ent, i, mat)

											potentionalBones[#potentionalBones + 1] = {
												[1] = i,
												[2] = boneName
											}
										end
									end
								end
							else
								table.remove(cache[ent:GetModel()][bone], key)

								timeCache, timeCacheBones = 0, 0
							end
						end
					end
				else
					for key = 1, #potentionalBones do
						local array = potentionalBones[key]
						local i, boneName = array[1], array[2]
						local mat = GetBoneMatrix(ent, i)

						if mat then
							local b = LookupBone(legsNoDraw, boneName)

							if b then
								local mat2 = GetBoneMatrix(legsNoDraw, b)

								if mat2 then
									if boneName == "ValveBiped.Bip01_Pelvis" then
										Legs_NoDraw_Angle.y = (math_NormalizeAngle(eyeAngles.y - GetAngles(mat).y) + 90) / 1.25
									elseif spineBones[boneName] then
										this = 4
									elseif miscSpineBones[i] then
										this = 5
									end

									local matTR, mat2TR = GetTranslation(mat), GetTranslation(mat2) - vector_fixCrouch

									SetTranslation(mat, mat2TR - (mat2TR - matTR) / this)
									this = cacheThis
									SetAngles(mat, GetAngles(mat2))
									SetBoneMatrix(ent, i, mat)
								end
							end
						end
					end
				end
			end

			SetRenderAngles(ply, ang)
		end)

		ply.Body.FullyLoaded = true
	end

	local SetParent, SetPos, SetAngles, SetCycle = ENTITY.SetParent, ENTITY.SetPos, ENTITY.SetAngles, ENTITY.SetCycle

	hook.Add("RenderScene", "firstperson_shadow.RenderScene", function(vec, ee)
		local ply_Body = ply.Body

		if IsValid(ply_Body) then
			DestroyShadow(ply_Body)

			local nodrawbody = ply.Body_NoDraw

			if IsValid(nodrawbody) then
				DestroyShadow(nodrawbody)
				nodrawbody:SetNoDraw(true)
			end
		end

		local self = ply.Body_Shadow

		if not IsValid(self) then
			return
		end
	end)

	hook.Add("RenderScene", "firstperson.RenderScene", function(vec, ee)
		eyePos, ply_EyePos = vec, ply:EyePos()
		eyeAngles = ply:EyeAngles()
		eyeAngles.p = 0

		if ply:InVehicle() then
			if IsValid(ply.Body) then
				ply.Body:SetNoDraw(true)
			end
			if IsValid(ply.Body_NoDraw) then
				ply.Body_NoDraw:SetNoDraw(true)
			end
			if IsValid(ply.Body_Shadow) then
				ply.Body_Shadow:SetNoDraw(true)
			end
			return
		end

		isDucking = bit.band(ply:GetFlags(), FL_ANIMDUCKING) > 0
			and onGround

		local FT = FrameTime()

		ply.TimeToDuck = math.Clamp((ply.TimeToDuck or 0) + FT * 3.5 * (isDucking and 1 or -1), 0, 1)

		local realEyeAngles = EyeAngles()
		local body = ply.Body
		local inVeh = ply:InVehicle()

		local thirdPersonCvar = GetConVar("monarch_thirdperson")
		local thirdPersonEnabled = thirdPersonCvar and thirdPersonCvar:GetBool() or false

		local isThirdPerson = ShouldDrawLocalPlayer(ply) or thirdPersonEnabled

		suppress = isThirdPerson
			or not Alive(ply)
			or not IsValid(body)
			or ply.NoShowLegs
			or not IsValid(ply.Body_Shadow)
			or not IsValid(ply.Body_NoDraw)
			or GetRagdollEntity(ply):IsValid()
			or GetObserverMode(ply) ~= 0
			or (ply.IsProne and ply:IsProne())
			or realEyeAngles.p > 115
			or realEyeAngles.p < -115
			or (vrmod and vrmod.IsPlayerInVR and vrmod.IsPlayerInVR(ply))

		if suppress then
			local reasons = {}
			if ShouldDrawLocalPlayer(ply) then table.insert(reasons, "ShouldDrawLocalPlayer") end
			if not Alive(ply) then table.insert(reasons, "not Alive") end
			if not IsValid(body) then table.insert(reasons, "invalid body") end
			if ply.NoShowLegs then table.insert(reasons, "NoShowLegs flag") end
			if not IsValid(ply.Body_Shadow) then table.insert(reasons, "invalid Body_Shadow") end
			if not IsValid(ply.Body_NoDraw) then table.insert(reasons, "invalid Body_NoDraw") end
			if GetRagdollEntity(ply):IsValid() then table.insert(reasons, "ragdoll active") end
			if GetObserverMode(ply) ~= 0 then table.insert(reasons, "observer mode") end
			if ply.IsProne and ply:IsProne() then table.insert(reasons, "prone") end
			if realEyeAngles.p > 115 then table.insert(reasons, "pitch too high: " .. realEyeAngles.p) end
			if realEyeAngles.p < -115 then table.insert(reasons, "pitch too low: " .. realEyeAngles.p) end
			if vrmod and vrmod.IsPlayerInVR and vrmod.IsPlayerInVR(ply) then table.insert(reasons, "VR mode") end
			if thirdPersonEnabled then table.insert(reasons, "third person enabled") end

		end

		local CT = SysTime()

		if limit_check < CT and IsValid(body) and IsValid(ply.Body_Shadow) then
			limit_check = CT + timeCache

			if ply.Body.Callback then
				local getCallbacks = ply.Body:GetCallbacks("BuildBonePositions")

				if not getCallbacks[ply.Body.Callback] then
					buildBonePosition()
				end
			else
				buildBonePosition()
			end

			if ply.Body_Shadow.Callback then
				local getCallbacks = ply.Body_Shadow:GetCallbacks("BuildBonePositions")

				if not getCallbacks[ply.Body_Shadow.Callback] then
					shadow_buildBonePosition()
				end
			else
				shadow_buildBonePosition()
			end

			body:SetSkin(ply:GetSkin())
			body:SetMaterial(ply:GetMaterial())

			if not suppress then
				local bodyGroups = ply:GetBodyGroups()

				for k = 1, #bodyGroups do
					local v = bodyGroups[k]
					local bg = ply:GetBodygroup(v.id)

					body:SetBodygroup(v.id, bg)
					ply.Body_NoDraw:SetBodygroup(v.id, bg)
				end
			end

			validBones = {}

			for i = 0, body:GetBoneCount() - 1 do
				local boneName = GetBoneName(body, i)
				local isPelvis = find(boneName, "Pelvis", 1, true) or false

				if find(boneName, "Spine", 1, true)
					or isPelvis
					or find(boneName, "Jacket", 1, true) then
					validBones[#validBones + 1] = {
						[1] = isPelvis,
						[2] = i
					}
				end
			end
		end

		if suppress then

			if IsValid(body) then
				body:SetNoDraw(true)
			end
			if IsValid(ply.Body_NoDraw) then
				ply.Body_NoDraw:SetNoDraw(true)
			end
			if IsValid(ply.Body_Shadow) then
				ply.Body_Shadow:SetNoDraw(true)
			end
			return
		else

			if IsValid(body) then
				body:SetNoDraw(false)
			end
		end

		local getPos = GetPos(ply)
		local getView = GetViewOffset(ply)
		local cycle = GetCycle(ply)

		if not isThirdPerson then
			SetParent(body, ply)
			SetPos(body, getPos)
			SetPlaybackRate(body, GetPlaybackRate(ply))
			SetCycle(body, cycle)

			local currentView = GetCurrentViewOffset(ply)
			local forward = eyeAngles:Forward() * forwardDistance
			local onGround = ply:OnGround()

			ply.TimeToFaggot = math.Clamp((ply.TimeToFaggot or 0) + FT * (Crouching(ply) and 4 or 10000) * (not onGround and 1 or -1), 0, 1)

			if not InVehicle(ply) then
				SetPos(ply.Body_NoDraw, getPos - forward)
				SetAngles(ply.Body_NoDraw, eyeAngles - Legs_NoDraw_Angle)
				SetAngles(body, eyeAngles)
			end

			faggot = (not onGround or limitJump > CurTime()) and getView - currentView or vector_origin
			vector_fixCrouch = (faggot * ply.TimeToFaggot)

			finalPos = getPos
				+ currentView
				+ vector_fixCrouch
		end
	end)

	local vector_down = Vector(0, 0, -1)
	local erroredModels = {}
	local DestroyShadow = ENTITY.DestroyShadow
	local oldSeq, oldSequenceName = 0, ""

	concommand.Add("cl_gm_body_refresh", function()
		MarkToRemove(ply.Body)
		MarkToRemove(ply.Body_NoDraw)
	end)

	hook.Add("Think", "body.Think", function()
		local current = ply.wardrobe or GetModel(ply)
		local currentSequence = ply:GetSequence()

		if oldSeq ~= currentSequence then
			oldSeq = currentSequence

			local currentSequenceName = ply:GetSequenceName(currentSequence)

			if currentSequenceName == oldSequenceName then
				MarkToRemove(ply.Body)
				MarkToRemove(ply.Body_NoDraw)
				MarkToRemove(ply.Body_Shadow)
			end

			oldSequenceName = currentSequenceName
		end

		if (not IsValid(ply.Body)
			or GetModel(ply.Body) ~= current) then

			MarkToRemove(ply.Body)
			MarkToRemove(ply.Body_NoDraw)
			MarkToRemove(ply.Body_Shadow)

			ply.Body = ents.CreateClientProp(current)
			ply.Body:SetModel(current)
			ply.Body:DestroyShadow()
			ply.Body:SetIK(false)
			ply.Body:PhysicsDestroy()
			SetupBones(ply.Body)
			ply.Body.GetPlayerColor = function()
				return ply:GetPlayerColor()
			end

			timer.Simple(0, function()
				if not IsValid(ply.Body)
					or not IsValid(ply.Body_NoDraw) then
					return
				end

				local seq = tonumber(ply:GetSequence()) or -1

				if seq < 0 then
					seq = ply.Body:LookupSequence("idle_all_01")
				end

				if seq < 0 then
					seq = ply.Body:LookupSequence("idle_all_02")

					if seq < 0 then
						seq = ply.Body:LookupSequence("idle1")
					end
				end

				if seq < 0 then
					seq = 0
				end

				ply.Body_NoDraw:ResetSequence(seq)
				ply.Body:ResetSequence(seq)

				ply.Body.FullyLoaded = true
			end)

			ply.Body_NoDraw = ents.CreateClientProp(current)
			ply.Body_NoDraw:SetModel(current)
			ply.Body_NoDraw:SetNoDraw(true)
			ply.Body_NoDraw:SetIK(false)
			ply.Body_NoDraw:PhysicsDestroy()
			ply.Body_NoDraw.GetPlayerColor = function()
				return ply:GetPlayerColor()
			end

			ply.Body.RenderOverride = function(self, flag)
				if bit.band(flag, STUDIO_SHADOWDEPTHTEXTURE) ~= 0 then
					return
				end

				local ply_Body = ply.Body

				if hook_Run("ShouldDisableLegs", ply_Body) == true then
					body_is_rendering = false

					return
				end

				body_is_rendering = true

				local shootPos = _EyePos(ply)

				if render_GetRenderTarget()
					and DistToSqr(EyePos(), shootPos) > 1024 then
					return
				end

				local ret = hook_Run("PreDrawBody", ply_Body)

				if ret == false then
					return
				end

				local color = ply:GetColor()
				local m1, m2, m3 = render_GetColorModulation()
				local inVeh = InVehicle(ply)
				local bEnabled = false

				if not inVeh then
					cam_Start3D(ply_EyePos, nil, nil, nil, nil, nil, nil, 0.5, -1)		
						render_PushCustomClipPlane(vector_down, Dot(vector_down, ply_EyePos))
						bEnabled = render_EnableClipping(true)					
				end

					render_SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
						DrawModel(ply_Body)
					render_SetColorModulation(m1, m2, m3)

				if not inVeh then
						render_PopCustomClipPlane()
						render_EnableClipping(bEnabled)
					cam_End3D()
				end

				hook_Run("PostDrawBody", ply_Body)
			end

			ply.Body_Shadow = ents.CreateClientProp(current)
			ply.Body_Shadow:SetModel(current)
			ply.Body_Shadow:SetIK(false)
			ply.Body_Shadow:PhysicsDestroy()
			ply.Body_Shadow.RenderOverride = function() end

			ply.Body.FullyLoaded = false 
			timeCacheBones = 0
		end
	end)

	hook.Add("PreDrawBody", "cl_body.PreDrawBody_Compat", function()
		if VWallrunning
			or inmantle
			or (VMLegs and VMLegs:IsActive())
			or (ply.StopKick or 0) > CurTime() then
			return false
		end
	end)
end)

function HIGH_RES(low, high)
	return low
end

hook.Add("Think", "cl_legs.Load", function()
	local ply = LocalPlayer()

	if IsValid(ply) then
		hook.Remove("Think", "cl_legs.Load")

		hook_Run("LocalPlayer_Validated", ply)
	end
end)

hook.Add("CalcView", "legs.ThirdPersonCheck", function(ply, pos, angles, fov)
    local isThirdPerson = GetConVar("monarch_thirdperson"):GetBool()

    if isThirdPerson then
        if IsValid(ply.Body) then
            ply.Body:SetNoDraw(true)
        end
        if IsValid(ply.Body_NoDraw) then
            ply.Body_NoDraw:SetNoDraw(true)
        end
        if IsValid(ply.Body_Shadow) then
            ply.Body_Shadow:SetNoDraw(true)
        end
    end
end)

net.Receive("Monarch_DrinkStart", function()
    local sink = net.ReadEntity()
    if not IsValid(sink) then return end

	if isfunction(Monarch_ShowUseBar) then
		Monarch_ShowUseBar(vgui.GetWorldPanel() or nil, 2, "Drinking...", function()
			if not IsValid(sink) then return end

			net.Start("Monarch_DrinkFinish")
				net.WriteEntity(sink)
			net.SendToServer()
		end)
		return
	end

	local drinkStart = CurTime()
	hook.Add("Think", "Monarch_DrinkStart_Fallback", function()
		local ply = LocalPlayer()
		if not IsValid(ply) or not IsValid(sink) then
			hook.Remove("Think", "Monarch_DrinkStart_Fallback")
			return
		end

		local tr = ply:GetEyeTrace()
		if not ply:KeyDown(IN_USE) or not tr or tr.Entity ~= sink then
			hook.Remove("Think", "Monarch_DrinkStart_Fallback")
			return
		end

		if CurTime() - drinkStart < 2 then return end

		net.Start("Monarch_DrinkFinish")
			net.WriteEntity(sink)
		net.SendToServer()

		hook.Remove("Think", "Monarch_DrinkStart_Fallback")
	end)
end)