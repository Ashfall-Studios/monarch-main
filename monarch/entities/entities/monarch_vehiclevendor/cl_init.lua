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

local function BlurRect(x, y, w, h)
	surface.SetDrawColor(20, 20, 20, 25)
	surface.DrawRect(x or 0, y or 0, w or ScrW(), h or ScrH())
	render.UpdateScreenEffectTexture()
	render.SetScissorRect(x, y, x + w, y + h, true)
	DrawBokehDOF(6, 0, 0)
	render.SetScissorRect(0, 0, 0, 0, false)
end

local function LerpColor(t, from, to)
	return Color(
		Lerp(t, from.r, to.r),
		Lerp(t, from.g, to.g),
		Lerp(t, from.b, to.b),
		Lerp(t, from.a or 255, to.a or 255)
	)
end

local function openVehicleVendorUI(vendor, name, desc, vehicles)
	if IsValid(Monarch._vehicleVendorFrame) then Monarch._vehicleVendorFrame:Remove() end

	local frame = vgui.Create("DFrame")
	frame:SetSize(ScrW(), ScrH())
	frame:SetPos(0, 0)
	frame:SetTitle("")
	frame:SetDraggable(false)
	frame:ShowCloseButton(false)
	frame:MakePopup()
	frame:SetAlpha(0)
	frame:AlphaTo(255, 0.15, 0)

	Monarch._vehicleVendorFrame = frame
	Monarch.hudEnabled = false
	frame.selectedVehicle = nil

	frame.particles = {}
	for i = 1, 20 do
		frame.particles[i] = {
			x = math.random(0, ScrW()), y = math.random(0, ScrH()),
			baseX = math.random(0, ScrW()), baseY = math.random(0, ScrH()),
			size = math.random(1, 3.5), alpha = math.random(30, 50), speed = math.random(0.5, 1)
		}
	end

	function frame:Paint(w, h)
		surface.SetDrawColor(255, 255, 255, 100)
		surface.SetMaterial(Material("mrp/menu_stuff/bg_grunge.png"))
		surface.DrawTexturedRect(0, 0, w, h)

		for i, p in ipairs(self.particles) do
			p.x = p.baseX + math.sin(CurTime() * p.speed + i) * 50
			p.y = p.baseY + math.cos(CurTime() * p.speed * 0.7 + i) * 30
			surface.SetDrawColor(255, 255, 255, p.alpha)
			surface.DrawRect(p.x, p.y, p.size, p.size)
		end

		BlurRect(0, 0, w, h)

		draw.SimpleText(name or "Vehicle Vendor", "InvLarge", 50, 50, color_white)
		draw.SimpleText(desc or "Select a vehicle to purchase and spawn", "InvMed", 50, 100, Color(200, 200, 200))
	end

	local vehicleList = vgui.Create("DPanel", frame)
	vehicleList:SetPos(50, 150)
	vehicleList:SetSize(400, ScrH() - 200)
	vehicleList.Paint = nil

	local scroll = vgui.Create("DScrollPanel", vehicleList)
	scroll:Dock(FILL)
	scroll.Paint = nil
	local sbar = scroll:GetVBar()
	function sbar:Paint(w, h) surface.SetDrawColor(40, 40, 40, 255) surface.DrawRect(0, 0, w, h) end
	function sbar.btnUp:Paint(w, h) surface.SetDrawColor(60, 60, 60, 255) surface.DrawRect(0, 0, w, h) end
	function sbar.btnDown:Paint(w, h) surface.SetDrawColor(60, 60, 60, 255) surface.DrawRect(0, 0, w, h) end
	function sbar.btnGrip:Paint(w, h) surface.SetDrawColor(100, 100, 100, 255) surface.DrawRect(0, 0, w, h) end

	local vehicleDetail = vgui.Create("DPanel", frame)
	vehicleDetail:SetPos(470, 150)
	vehicleDetail:SetSize(ScrW() - 520, ScrH() - 200)
	vehicleDetail.Paint = nil

	for _, vehData in ipairs(vehicles) do
		local card = vgui.Create("DButton", scroll)
		card:Dock(TOP)
		card:DockMargin(0, 0, 0, 10)
		card:SetTall(100)
		card:SetText("")
		card.hoverLerp = 0
		card.vehData = vehData

		local thumb = vgui.Create("DModelPanel", card)
		thumb:SetPos(6, 6)
		thumb:SetSize(88, 88)
		thumb:SetMouseInputEnabled(false)
		local mdlPath = vehData.model
		if not mdlPath or mdlPath == "" then mdlPath = "models/props_c17/FurnitureDrawer001a.mdl" end
		if util and util.IsValidModel and not util.IsValidModel(mdlPath) then mdlPath = "models/props_c17/FurnitureDrawer001a.mdl" end
		thumb:SetModel(mdlPath)
		thumb:SetFOV(45)
		thumb.LayoutEntity = function() return end
		timer.Simple(0, function()
			if not IsValid(thumb) then return end
			local ent = thumb:GetEntity()
			if not IsValid(ent) then return end
			local mn, mx = ent:GetRenderBounds()
			local center = (mn + mx) * 0.5
			ent:SetPos(-center)
			local radius = (mx - mn):Length() * 0.5
			radius = radius < 1 and 1 or radius
			local dist = radius / math.tan(math.rad(thumb:GetFOV()) * 0.5)
			thumb:SetCamPos(Vector(1, 1, 0.5):GetNormalized() * dist)
			thumb:SetLookAt(vector_origin)
		end)

		function card:Paint(w, h)
			local col = self:IsHovered() and Color(50, 50, 50) or Color(30, 30, 30)
			if frame.selectedVehicle == self.vehData then col = Color(60, 60, 60) end
			draw.RoundedBox(4, 0, 0, w, h, col)
			surface.SetDrawColor(self:IsHovered() and Color(100, 100, 100) or Color(70, 70, 70))
			surface.DrawOutlinedRect(0, 0, w, h, 2)

			local textX = 104
			draw.SimpleText(self.vehData.name or "Unknown", "InvMed", textX, 10, color_white)
			local priceText = self.vehData.price > 0 and ("$" .. string.Comma(self.vehData.price)) or "Team Only"
			local priceCol = self.vehData.price > 0 and Color(100, 255, 100) or Color(100, 180, 255)
			draw.SimpleText(priceText, "InvMed", w - 10, 10, priceCol, TEXT_ALIGN_RIGHT)

			local desc = self.vehData.desc or ""
			if #desc > 50 then desc = desc:sub(1, 50) .. "..." end
			draw.SimpleText(desc, "InvSmall", textX, 60, Color(150, 150, 150))

			if self.vehData.owned then
				draw.SimpleText("OWNED", "InvSmall", textX, 78, Color(100, 255, 100))
			end
		end

		function card:DoClick()
			surface.PlaySound("ui/hls_ui_select.wav")
			frame.selectedVehicle = self.vehData
			vehicleDetail:Clear()

			local data = self.vehData
			local y = 20

			local nameLabel = vgui.Create("DLabel", vehicleDetail)
			nameLabel:SetPos(20, y)
			nameLabel:SetFont("InvLarge")
			nameLabel:SetText(data.name or "Unknown")
			nameLabel:SetTextColor(color_white)
			nameLabel:SizeToContents()
			y = y + 50

			if data.price > 0 then
				local priceLabel = vgui.Create("DLabel", vehicleDetail)
				priceLabel:SetPos(20, y)
				priceLabel:SetFont("InvMed")
				priceLabel:SetText("Price: $" .. string.Comma(data.price))
				priceLabel:SetTextColor(Color(100, 255, 100))
				priceLabel:SizeToContents()
				y = y + 30
			else
				local teamLabel = vgui.Create("DLabel", vehicleDetail)
				teamLabel:SetPos(20, y)
				teamLabel:SetFont("InvMed")
				teamLabel:SetText("Team Vehicle")
				teamLabel:SetTextColor(Color(100, 180, 255))
				teamLabel:SizeToContents()
				y = y + 30
			end

			y = y + 20
			local descLabel = vgui.Create("DLabel", vehicleDetail)
			descLabel:SetPos(20, y)
			descLabel:SetFont("InvSmall")
			descLabel:SetText(data.desc or "No description")
			descLabel:SetTextColor(Color(180, 180, 180))
			descLabel:SetWide(vehicleDetail:GetWide() - 40)
			descLabel:SetWrap(true)
			descLabel:SetAutoStretchVertical(true)

			timer.Simple(0, function()
				if not IsValid(vehicleDetail) or not IsValid(descLabel) then return end
				local btnY = descLabel:GetY() + descLabel:GetTall() + 30

				local spawnBtn = vgui.Create("DButton", vehicleDetail)
				spawnBtn:SetPos(20, btnY)
				spawnBtn:SetSize(200, 45)
				spawnBtn:SetText("")
				spawnBtn.hoverLerp = 0
				spawnBtn:SetMouseInputEnabled(data.eligible)
				function spawnBtn:Paint(w, h)
					local base = data.eligible and Color(125, 125, 125) or Color(255, 80, 80)
					local bg = Color(30, 30, 30)
					local hov = data.eligible and Color(100, 255, 100) or Color(255, 80, 80)
					local c = LerpColor(self.hoverLerp, base, hov)
					surface.SetDrawColor(bg) surface.DrawRect(0, 0, w, h)
					surface.SetDrawColor(c) surface.DrawOutlinedRect(0, 0, w, h, 2)
					local txt = data.eligible and (data.owned and "Spawn Vehicle" or "Purchase & Spawn") or "Cannot Access"
					draw.SimpleText(txt, "InvMed", w / 2, h / 2, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
				function spawnBtn:Think()
					if data.eligible then
						self.hoverLerp = Lerp(FrameTime() * 8, self.hoverLerp, self:IsHovered() and 1 or 0)
					end
					self:SetDisabled(not data.eligible)
				end
				function spawnBtn:OnCursorEntered() if data.eligible then end end
				function spawnBtn:DoClick()
					if not data.eligible then return end
					surface.PlaySound("menu/ui_click.mp3")
					net.Start("Monarch_VehicleVendorSpawn") 
					net.WriteEntity(vendor) 
					net.WriteString(data.class) 
					net.SendToServer()
				end
			end)
		end
	end

	local closeBtn = vgui.Create("DButton", frame)
	closeBtn:SetPos(ScrW() - 170, 50)
	closeBtn:SetSize(120, 45)
	closeBtn:SetText("")
	closeBtn.hoverLerp = 0
	function closeBtn:Paint(w, h)
		local base = Color(125, 125, 125)
		local bg = Color(30, 30, 30)
		local hov = Color(255, 100, 100)
		local c = LerpColor(self.hoverLerp, base, hov)
		surface.SetDrawColor(bg) surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(c) surface.DrawOutlinedRect(0, 0, w, h, 2)
		draw.SimpleText("Close", "InvMed", w / 2, h / 2, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	function closeBtn:Think() self.hoverLerp = Lerp(FrameTime() * 8, self.hoverLerp, self:IsHovered() and 1 or 0) end
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

net.Receive("Monarch_VehicleVendorOpen", function()
	local vendor = net.ReadEntity()
	local name = net.ReadString()
	local desc = net.ReadString()
	local vehCount = net.ReadUInt(8)

	local vehicles = {}
	for i = 1, vehCount do
		local veh = {
			class = net.ReadString(),
			name = net.ReadString(),
			desc = net.ReadString(),
			model = net.ReadString(),
			price = net.ReadUInt(32),
			owned = net.ReadBool(),
			eligible = net.ReadBool()
		}
		table.insert(vehicles, veh)
	end

	openVehicleVendorUI(vendor, name, desc, vehicles)
end)

net.Receive("Monarch_VehicleVendorNotify", function()
	local msg = net.ReadString()
	if LocalPlayer().Notify then
		LocalPlayer():Notify(msg)
	else
		chat.AddText(Color(255, 100, 100), "[Vehicle Vendor] ", color_white, msg)
	end
end)
