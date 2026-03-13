include("shared.lua")

ENT.AutomaticFrameAdvance = true

function ENT:Initialize()
	local seq = self:LookupSequence("idle_all_01") or self:LookupSequence("idle") or 0
	self:ResetSequence(seq)
end

function ENT:Think()
	if (self._nextSeq or 0) < CurTime() then
		local seq = self:LookupSequence("idle_all_01") or self:LookupSequence("idle") or 0
		self:ResetSequence(seq)
		self._nextSeq = CurTime() + 30
	end

	self:SetNextClientThink(CurTime() + 1)
	return true
end

function ENT:Draw()
	self:DrawModel()
end

local blurDrawPanel = {
	[1] = function(x, y, w, h)
		render.UpdateScreenEffectTexture()
		render.SetScissorRect(x, y, x+w, y+h, true)
		DrawBokehDOF(6, 0, 0)
		render.SetScissorRect(0, 0, 0, 0, false)
	end
}

local function BlurRect(x, y, w, h)
	surface.SetDrawColor(20, 20, 20, 25)
	surface.DrawRect(x or 0, y or 0, w or ScrW(), h or ScrH())
	blurDrawPanel[1](x, y, w, h)
end

local function LerpColor(t, from, to)
	if type(from) ~= "table" then from = to end
	if type(to) ~= "table" then to = from end
	if not from then from = Color(255, 255, 255, 255) end
	if not to then to = from end
	return Color(
		Lerp(t, from.r or 255, to.r or 255),
		Lerp(t, from.g or 255, to.g or 255),
		Lerp(t, from.b or 255, to.b or 255),
		Lerp(t, from.a or 255, to.a or 255)
	)
end

local function checkRankWhitelists(vendor, ranks)

	local vendorTeam = IsValid(vendor) and vendor:GetRequiredTeam() or 0
	local ply = LocalPlayer()

	for _, rank in ipairs(ranks) do
		local newAllowed = true
		local reason = ""

		if rank.team and rank.team > 0 and ply:Team() ~= rank.team then
			newAllowed = false
			reason = "You must be on the " .. team.GetName(rank.team) .. " team"
		end

		if newAllowed and rank.whitelistLevel and rank.whitelistLevel > 0 then
			local teamForWL = rank.team
			if not teamForWL or teamForWL == 0 then
				teamForWL = ply:Team() 
			end
			if not teamForWL or teamForWL == 0 then
				teamForWL = 0
			end
			local currentLevel = ply:GetNWInt("MonarchWhitelist_" .. teamForWL, -1)
			if currentLevel < 0 then currentLevel = 0 end
			if currentLevel < rank.whitelistLevel then
				newAllowed = false
				reason = "Requires whitelist level " .. rank.whitelistLevel .. ". you have level " .. currentLevel
			end
		end

		if newAllowed and rank.requiredWhitelistTeam and rank.requiredWhitelistLevel then
			local currentLevel = ply:GetNWInt("MonarchWhitelist_" .. rank.requiredWhitelistTeam, -1)
			if currentLevel < 0 then currentLevel = 0 end
			if currentLevel < rank.requiredWhitelistLevel then
				newAllowed = false
				reason = "Requires whitelist level " .. rank.requiredWhitelistLevel .. " for " .. team.GetName(rank.requiredWhitelistTeam)
			end
		end

		rank.allowed = newAllowed
		if reason ~= "" then
			rank.lockedReason = reason
		end
	end
end

local function openRankVendorUI(vendor, name, desc, ranks)
	if IsValid(Monarch._rankVendorFrame) then
		Monarch._rankVendorFrame:Remove()
	end

	checkRankWhitelists(vendor, ranks)

	if CLIENT then
		net.Start("Monarch_RequestWhitelistSync")
		net.SendToServer()

		timer.Simple(0.25, function()
			if IsValid(Monarch._rankVendorFrame) then
				net.Start("Monarch_RequestWhitelistSync")
				net.SendToServer()
			end
		end)
	end

	local frame = vgui.Create("DFrame")
	frame:SetSize(ScrW(), ScrH())
	frame:SetPos(0, 0)
	frame:SetTitle("")
	frame:SetDraggable(false)
	frame:ShowCloseButton(false)
	frame:MakePopup()
	frame:SetAlpha(0)
	frame:AlphaTo(255, 0.15, 0)

	Monarch._rankVendorFrame = frame
	Monarch.hudEnabled = false

	frame.selectedRank = nil
	frame.vendor = vendor
	frame.ranks = ranks
	frame.particles = {}
	for i = 1, 20 do
		table.insert(frame.particles, {
			x = math.random(0, ScrW()),
			y = math.random(0, ScrH()),
			baseX = math.random(0, ScrW()),
			baseY = math.random(0, ScrH()),
			size = math.random(1, 3.5),
			alpha = math.random(30, 50),
			speed = math.random(0.5, 1),
			glowSize = math.random(5, 8)
		})
	end

	frame.mouseX = ScrW() / 2
	frame.mouseY = ScrH() / 2
	frame.nextWhitelistCheck = 0
	frame.lastDetailRebuild = 0
	frame.vendorTeam = IsValid(vendor) and vendor:GetRequiredTeam() or 0

	function frame:Think()
		self.mouseX, self.mouseY = gui.MousePos()

		if CurTime() >= self.nextWhitelistCheck then
			self.nextWhitelistCheck = CurTime() + 0.5

			local needsUpdate = false
			local selectedRankNeedsUpdate = false
			local ply = LocalPlayer()

			for _, rank in ipairs(self.ranks) do
				local oldAllowed = rank.allowed
				local oldReason = rank.lockedReason or ""
				local newAllowed = true
				local reason = ""

				if rank.team and rank.team > 0 and ply:Team() ~= rank.team then
					newAllowed = false
					reason = "You must be on the " .. team.GetName(rank.team) .. " team"
				end

			if newAllowed and rank.whitelistLevel and rank.whitelistLevel > 0 then
				local teamForWL = rank.team
				if not teamForWL or teamForWL == 0 then
					teamForWL = ply:Team()
				end
				if not teamForWL or teamForWL == 0 then
					teamForWL = self.vendorTeam
				end
				if not teamForWL or teamForWL == 0 then
					teamForWL = 0
				end

			local currentLevel = ply:GetNWInt("MonarchWhitelist_" .. teamForWL, -1)

			if currentLevel < 0 then currentLevel = 0 end
			if currentLevel < rank.whitelistLevel then
				newAllowed = false
				reason = "Requires whitelist level " .. rank.whitelistLevel .. ". you have level " .. currentLevel
			end
		end

		if newAllowed and rank.requiredWhitelistTeam and rank.requiredWhitelistLevel then
			local reqLevel = ply:GetNWInt("MonarchWhitelist_" .. rank.requiredWhitelistTeam, -1)
			if reqLevel < 0 then reqLevel = 0 end
			if reqLevel < rank.requiredWhitelistLevel then
				newAllowed = false
				reason = "Requires whitelist level " .. rank.requiredWhitelistLevel .. " for " .. team.GetName(rank.requiredWhitelistTeam)
			end
		end

				if oldAllowed ~= newAllowed or oldReason ~= reason then
					rank.allowed = newAllowed
					rank.lockedReason = reason
					needsUpdate = true
					if self.selectedRank == rank then
						selectedRankNeedsUpdate = true
					end
				end
			end

			if selectedRankNeedsUpdate and (CurTime() - self.lastDetailRebuild) > 0.5 then
				if self.selectedRank and IsValid(self.detailPanel) and self.buildDetailFunc then
					self.lastDetailRebuild = CurTime()
					self.buildDetailFunc(self.selectedRank)
				end
			end
		end
	end
	function frame:DrawFloatingParticles(w, h)
		for i, particle in ipairs(self.particles) do
			local mouseInfluenceX = ((self.mouseX or ScrW()/2) - ScrW()/2) * 0.01 * particle.speed
			local mouseInfluenceY = ((self.mouseY or ScrH()/2) - ScrH()/2) * 0.01 * particle.speed

			particle.x = particle.baseX + math.sin(CurTime() * particle.speed + i) * 50 + mouseInfluenceX
			particle.y = particle.baseY + math.cos(CurTime() * particle.speed * 0.7 + i) * 30 + mouseInfluenceY

			if particle.x < -10 then particle.baseX = w + 10 end
			if particle.x > w + 10 then particle.baseX = -10 end
			if particle.y < -10 then particle.baseY = h + 10 end
			if particle.y > h + 10 then particle.baseY = -10 end

			local pulseScale = 1 + math.sin(CurTime() * 2 + i) * 0.3
			local currentGlowSize = particle.glowSize * pulseScale

			surface.SetDrawColor(255, 255, 255, particle.alpha * 0.1)
			surface.DrawRect(particle.x - currentGlowSize/2, particle.y - currentGlowSize/2, currentGlowSize, currentGlowSize)

			local midGlowSize = currentGlowSize * 0.6
			surface.SetDrawColor(255, 165, 0, particle.alpha * 0.3)
			surface.DrawRect(particle.x - midGlowSize/2, particle.y - midGlowSize/2, midGlowSize, midGlowSize)

			local innerGlowSize = currentGlowSize * 0.3
			surface.SetDrawColor(100, 54, 0, particle.alpha * 0.6)
			surface.DrawRect(particle.x - innerGlowSize/2, particle.y - innerGlowSize/2, innerGlowSize, innerGlowSize)

			surface.SetDrawColor(255, 255, 255, particle.alpha)
			surface.DrawRect(particle.x, particle.y, particle.size, particle.size)
		end
	end

	function frame:Paint(w, h)
		self:DrawFloatingParticles(w, h)
		BlurRect(0, 0, w, h)

		surface.SetDrawColor(255, 255, 255, 100)
		surface.SetMaterial(Material("mrp/menu_stuff/bg_grunge.png"))
		surface.DrawTexturedRect(0, 0, w, h)

		self:DrawFloatingParticles(w, h)
		BlurRect(0, 0, w, h)

		draw.SimpleText(name or "Recruiter", "InvLarge", 50, 50, color_white)
		draw.SimpleText(desc or "Select an available rank", "InvMed", 50, 100, Color(200, 200, 200))
	end

	local listPanel = vgui.Create("DPanel", frame)
	listPanel:SetPos(50, 150)
	listPanel:SetSize(400, ScrH() - 200)
	listPanel.Paint = nil

	local scroll = vgui.Create("DScrollPanel", listPanel)
	scroll:Dock(FILL)
	scroll.Paint = nil
	local sbar = scroll:GetVBar()
	function sbar:Paint(w, h) surface.SetDrawColor(40, 40, 40, 255) surface.DrawRect(0, 0, w, h) end
	function sbar.btnUp:Paint(w, h) surface.SetDrawColor(60, 60, 60, 255) surface.DrawRect(0, 0, w, h) end
	function sbar.btnDown:Paint(w, h) surface.SetDrawColor(60, 60, 60, 255) surface.DrawRect(0, 0, w, h) end
	function sbar.btnGrip:Paint(w, h) surface.SetDrawColor(100, 100, 100, 255) surface.DrawRect(0, 0, w, h) end

	local detail = vgui.Create("DPanel", frame)
	detail:SetPos(470, 150)
	detail:SetSize(ScrW() - 520, ScrH() - 200)
	detail.Paint = nil
	frame.detailPanel = detail

	local buildDetail
	buildDetail = function(rank)
		frame.buildDetailFunc = buildDetail
		detail:Clear()
		if not rank then return end

		local modelContainer = vgui.Create("DPanel", detail)
		modelContainer:SetPos(detail:GetWide() - 360 - 20, 20)
		modelContainer:Dock(FILL)
		modelContainer.Paint = nil

		local modelPanel = vgui.Create("DModelPanel", modelContainer)
		modelPanel:Dock(FILL)
		modelPanel:DockMargin(0, 0, 0, 0)
		modelPanel:SetFOV(42)
		modelPanel:SetCamPos(Vector(90, 55, 60))
		modelPanel:SetLookAt(Vector(0, 0, 48))
		modelPanel:SetAnimated(false)
		local mdl = rank.model or ""
		if mdl and mdl ~= "" then
			modelPanel:SetModel(mdl)
		else
			modelPanel:SetModel("models/error.mdl")
		end
		function modelPanel:LayoutEntity(ent)
			ent:SetAngles(Angle(0, 0, 0))
		end

		local y = 20
		local nameLabel = vgui.Create("DLabel", detail)
		nameLabel:SetPos(20, y)
		nameLabel:SetFont("InvLarge")
		nameLabel:SetText(rank.name or "Rank")
		nameLabel:SetTextColor(color_white)
		nameLabel:SizeToContents()

		y = y + 60
		local reqText = ""
		if rank.team and rank.team > 0 then
			local teamName = team.GetName(rank.team) or ("Team "..rank.team)
			reqText = reqText .. "Team: " .. teamName .. "  "
		end
		if rank.group and rank.group ~= "" then
			reqText = reqText .. "Group: " .. rank.group .. "  "
		end
		if reqText ~= "" then
			local reqLabel = vgui.Create("DLabel", detail)
			reqLabel:SetPos(20, y)
			reqLabel:SetFont("InvSmall")
			reqLabel:SetText(reqText)
			reqLabel:SetTextColor(Color(200, 150, 100))
			reqLabel:SizeToContents()
			y = y + 30
		end

		local descLabel = vgui.Create("DLabel", detail)
		descLabel:SetPos(20, y)
		descLabel:SetFont("InvSmall")
		descLabel:SetText(rank.desc or "")
		descLabel:SetTextColor(Color(180,180,180))
		descLabel:SetWide(detail:GetWide() - 40)
		descLabel:SetWrap(true)
		descLabel:SetAutoStretchVertical(true)
		y = y + descLabel:GetTall() + 30

		local allowed = rank.allowed
		local lockedReason = rank.lockedReason or ""

	local selectBtn = vgui.Create("DButton", detail)
	selectBtn:SetPos(20, y)
		selectBtn:SetSize(220, 45)
		selectBtn:SetText("")
		selectBtn.hoverLerp = 0
		selectBtn.Disabled = not allowed

		function selectBtn:Paint(w, h)
			local baseColor = allowed and Color(125, 125, 125, 255) or Color(80, 80, 80, 255)
			local bgColor = Color(30, 30, 30, 255)
			local hoverColor = allowed and Color(190, 190, 190, 255) or Color(110, 110, 110, 255)
			local col = LerpColor(self.hoverLerp, baseColor, hoverColor)
			surface.SetDrawColor(bgColor)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(col)
			surface.DrawOutlinedRect(0, 0, w, h, 2)
			local label = allowed and "Select Rank" or "Cannot Become"
			draw.SimpleText(label, "InvMed", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		function selectBtn:Think()
			local target = (self:IsHovered() and allowed) and 1 or 0
			self.hoverLerp = Lerp(FrameTime() * 8, self.hoverLerp, target)
		end
		function selectBtn:OnCursorEntered() if allowed then end end
		function selectBtn:DoClick()
			if not allowed then return end
			surface.PlaySound("menu/ui_click.mp3")
			net.Start("Monarch_RankVendor_Select")
			net.WriteEntity(vendor)
			net.WriteString(rank.id)
			net.SendToServer()
			frame:AlphaTo(0, 0.15, 0, function()
				if IsValid(frame) then frame:Remove() end
			end)
		end

		if not allowed and lockedReason ~= "" then
			local lockLbl = vgui.Create("DLabel", detail)
			lockLbl:SetPos(20, y + 60)
			lockLbl:SetFont("InvSmall")
			lockLbl:SetText("Reason: " .. lockedReason)
			lockLbl:SetTextColor(Color(220,130,130))
			lockLbl:SetWide(detail:GetWide() - 40)
			lockLbl:SetWrap(true)
			lockLbl:SetAutoStretchVertical(true)
		end
	end

	for _, rank in ipairs(ranks) do
		local card = vgui.Create("DButton", scroll)
		card:Dock(TOP)
		card:DockMargin(0, 0, 0, 10)
		card:SetTall(100)
		card:SetText("")
		card.hoverLerp = 0
		card.rank = rank
		function card:Paint(w, h)
			local col = self:IsHovered() and Color(50, 50, 50) or Color(30, 30, 30)
			if frame.selectedRank == self.rank then col = Color(60, 60, 60) end
			draw.RoundedBox(4, 0, 0, w, h, col)
			surface.SetDrawColor(self:IsHovered() and Color(100, 100, 100) or Color(70, 70, 70))
			surface.DrawOutlinedRect(0, 0, w, h, 2)
			draw.SimpleText(self.rank.name or "Rank", "InvMed", 10, 10, color_white)
			local desc = self.rank.desc or ""
			if #desc > 50 then desc = string.sub(desc, 1, 50) .. "..." end
			draw.SimpleText(desc, "InvSmall", 10, 60, Color(150,150,150))
			if not self.rank.allowed then
				draw.SimpleText("Cannot Become", "InvSmall", w - 10, 10, Color(220,130,130), TEXT_ALIGN_RIGHT)
			end
		end
		function card:Think() local target = self:IsHovered() and 1 or 0 self.hoverLerp = Lerp(FrameTime()*8, self.hoverLerp, target) end
		function card:DoClick()
			surface.PlaySound("ui/hls_ui_select.wav")
			frame.selectedRank = self.rank
			buildDetail(self.rank)
		end
	end

	local closeBtn = vgui.Create("DButton", frame)
	closeBtn:SetPos(ScrW() - 170, 50)
	closeBtn:SetSize(120, 45)
	closeBtn:SetText("")
	closeBtn.hoverLerp = 0
	function closeBtn:Paint(w, h)
		local baseColor = Color(125, 125, 125, 255)
		local bgColor = Color(30, 30, 30, 255)
		local hoverColor = Color(255, 100, 100, 255)
		local col = LerpColor(self.hoverLerp, baseColor, hoverColor)
		surface.SetDrawColor(bgColor) surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(col) surface.DrawOutlinedRect(0, 0, w, h, 2)
		draw.SimpleText("Close", "InvMed", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	function closeBtn:Think() local target = self:IsHovered() and 1 or 0 self.hoverLerp = Lerp(FrameTime()*8, self.hoverLerp, target) end
	function closeBtn:DoClick()
		surface.PlaySound("ui/hls_ui_button4.wav")
		frame:AlphaTo(0, 0.15, 0, function()
			if IsValid(frame) then
				frame:Close()
				Monarch.hudEnabled = true
			end
		end)
	end
	function frame:OnRemove() Monarch.hudEnabled = true end
end

net.Receive("Monarch_RankVendor_Open", function()
	local vendor = net.ReadEntity()
	local name = net.ReadString()
	local desc = net.ReadString()
	local count = net.ReadUInt(16)

	local ranks = {}
	for i = 1, count do
		local r = {
			id = net.ReadString(),
			name = net.ReadString(),
			desc = net.ReadString(),
			model = net.ReadString(),
			price = net.ReadUInt(32), 
			team = net.ReadUInt(16),
			group = net.ReadString(),
			grouprank = net.ReadString()
		}
		r.allowed = net.ReadBool()
		r.lockedReason = net.ReadString() or ""

		r.whitelistLevel = net.ReadUInt(8)
		r.requiredWhitelistTeam = net.ReadUInt(16)
		r.requiredWhitelistLevel = net.ReadUInt(8)
		if r.whitelistLevel == 0 then r.whitelistLevel = nil end
		if r.requiredWhitelistTeam == 0 then r.requiredWhitelistTeam = nil end
		if r.requiredWhitelistLevel == 0 then r.requiredWhitelistLevel = nil end

		table.insert(ranks, r)
	end

	openRankVendorUI(vendor, name, desc, ranks)
end)

hook.Add("EntityNetworkedVarChanged", "Monarch_RankVendor_WhitelistChanged", function(ent, varName, oldValue, newValue)
	if ent ~= LocalPlayer() then return end
	if type(varName) ~= "string" then return end
	if not string.StartWith(varName, "MonarchWhitelist_") then return end

	local frame = Monarch and Monarch._rankVendorFrame
	if not IsValid(frame) then return end

	frame.nextWhitelistCheck = 0
end)

if CLIENT then
	net.Receive("Monarch_WhitelistChanged", function()
		local frame = Monarch and Monarch._rankVendorFrame
		if IsValid(frame) then
			frame.nextWhitelistCheck = 0
		end
	end)
end