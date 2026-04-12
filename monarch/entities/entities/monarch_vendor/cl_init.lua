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

local function openVendorUI(vendor, name, desc, items)
	if IsValid(Monarch._vendorFrame) then Monarch._vendorFrame:Remove() end

	local frame = vgui.Create("DFrame")
	frame:SetSize(ScrW(), ScrH())
	frame:SetPos(0, 0)
	frame:SetTitle("")
	frame:SetDraggable(false)
	frame:ShowCloseButton(false)
	frame:MakePopup()
	frame:SetAlpha(0)
	frame:AlphaTo(255, 0.15, 0)

	Monarch._vendorFrame = frame
	Monarch.hudEnabled = false
	frame.selectedItem = nil

	frame.particles = {}
	for i = 1, 20 do
		frame.particles[i] = {
			x = math.random(0, ScrW()), y = math.random(0, ScrH()),
			baseX = math.random(0, ScrW()), baseY = math.random(0, ScrH()),
			size = math.random(1, 3.5), alpha = math.random(30, 50), speed = math.random(0.5, 1), glowSize = math.random(5, 8)
		}
	end

	function frame:Paint(w, h)
		local bg = Config and Config.MainMenuBackground
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

		draw.SimpleText(name or "Vendor", "InvLarge", 50, 50, color_white)
		draw.SimpleText(desc or "Select an item to purchase", "InvMed", 50, 100, Color(200, 200, 200))
	end

	local itemList = vgui.Create("DPanel", frame)
	itemList:SetPos(50, 150)
	itemList:SetSize(400, ScrH() - 200)
	itemList.Paint = nil

	local scroll = vgui.Create("DScrollPanel", itemList)
	scroll:Dock(FILL)
	scroll.Paint = nil
	local sbar = scroll:GetVBar()
	function sbar:Paint(w, h) surface.SetDrawColor(40, 40, 40, 255) surface.DrawRect(0, 0, w, h) end
	function sbar.btnUp:Paint(w, h) surface.SetDrawColor(60, 60, 60, 255) surface.DrawRect(0, 0, w, h) end
	function sbar.btnDown:Paint(w, h) surface.SetDrawColor(60, 60, 60, 255) surface.DrawRect(0, 0, w, h) end
	function sbar.btnGrip:Paint(w, h) surface.SetDrawColor(100, 100, 100, 255) surface.DrawRect(0, 0, w, h) end

	local itemDetail = vgui.Create("DPanel", frame)
	itemDetail:SetPos(470, 150)
	itemDetail:SetSize(ScrW() - 520, ScrH() - 200)
	itemDetail.Paint = nil

	for _, itemData in ipairs(items) do
		local card = vgui.Create("DButton", scroll)
		card:Dock(TOP)
		card:DockMargin(0, 0, 0, 10)
		card:SetTall(100)
		card:SetText("")
		card.hoverLerp = 0
		card.itemData = itemData

		local thumb = vgui.Create("DModelPanel", card)
		thumb:SetPos(6, 6)
		thumb:SetSize(88, 88)
		thumb:SetMouseInputEnabled(false)
		local mdlPath = itemData.model
		if not mdlPath or mdlPath == "" then mdlPath = "models/props_junk/PopCan01a.mdl" end
		if util and util.IsValidModel and not util.IsValidModel(mdlPath) then mdlPath = "models/props_junk/PopCan01a.mdl" end
		thumb:SetModel(mdlPath)
		thumb:SetFOV(30)
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
			if frame.selectedItem == self.itemData then col = Color(60, 60, 60) end
			draw.RoundedBox(4, 0, 0, w, h, col)
			surface.SetDrawColor(self:IsHovered() and Color(100, 100, 100) or Color(70, 70, 70))
			surface.DrawOutlinedRect(0, 0, w, h, 2)

			local textX = 104
			draw.SimpleText(self.itemData.name or "Unknown", "InvMed", textX, 10, color_white)
			draw.SimpleText("$" .. string.Comma(self.itemData.price or 0), "InvMed", w - 10, 10, Color(100, 255, 100), TEXT_ALIGN_RIGHT)

			local lineY = 40

			local desc = self.itemData.desc or ""
			if #desc > 50 then desc = desc:sub(1, 50) .. "..." end
			draw.SimpleText(desc, "InvSmall", textX, 60, Color(150, 150, 150))
		end

		function card:DoClick()
			surface.PlaySound("ui/hls_ui_select.wav")
			frame.selectedItem = self.itemData
			itemDetail:Clear()

			local data = self.itemData
			local y = 20

			local nameLabel = vgui.Create("DLabel", itemDetail)
			nameLabel:SetPos(20, y)
			nameLabel:SetFont("InvLarge")
			nameLabel:SetText(data.name or "Unknown")
			nameLabel:SetTextColor(color_white)
			nameLabel:SizeToContents()
			y = y + 50

			local priceLabel = vgui.Create("DLabel", itemDetail)
			priceLabel:SetPos(20, y)
			priceLabel:SetFont("InvMed")
			priceLabel:SetText("Price: $" .. string.Comma(data.price or 0))
			priceLabel:SetTextColor(Color(100, 255, 100))
			priceLabel:SizeToContents()
			y = y + 30

			local sp = tonumber(data.sellPrice or 0) or 0
			if sp > 0 then
				local sellLabel = vgui.Create("DLabel", itemDetail)
				sellLabel:SetPos(20, y)
				sellLabel:SetFont("InvSmall")
				sellLabel:SetText("Sell Value: $" .. string.Comma(sp))
				sellLabel:SetTextColor(Color(150, 255, 150))
				sellLabel:SizeToContents()
				y = y + 24
			end

			y = y + 40
			local descLabel = vgui.Create("DLabel", itemDetail)
			descLabel:SetPos(20, y)
			descLabel:SetFont("InvSmall")
			descLabel:SetText(data.desc or "No description")
			descLabel:SetTextColor(Color(180, 180, 180))
			descLabel:SetWide(itemDetail:GetWide() - 40)
			descLabel:SetWrap(true)
			descLabel:SetAutoStretchVertical(true)

			timer.Simple(0, function()
				if not IsValid(itemDetail) or not IsValid(descLabel) then return end
				local btnY = descLabel:GetY() + descLabel:GetTall() + 30

				local buyBtn = vgui.Create("DButton", itemDetail)
				buyBtn:SetPos(20, btnY)
				buyBtn:SetSize(200, 45)
				buyBtn:SetText("")
				buyBtn.hoverLerp = 0
					local canBuy = (data.eligible ~= false)
					buyBtn:SetDisabled(not canBuy)
				function buyBtn:Paint(w, h)
						local bg = Color(30, 30, 30)
						local c
						if canBuy then
							c = LerpColor(self.hoverLerp, Color(125, 125, 125), Color(100, 255, 100))
						else
							c = Color(100, 100, 100)
						end
					surface.SetDrawColor(bg) surface.DrawRect(0, 0, w, h)
					surface.SetDrawColor(c) surface.DrawOutlinedRect(0, 0, w, h, 2)
						local txt = canBuy and "Purchase" or "Cannot Purchase"
					draw.SimpleText(txt, "InvMed", w / 2, h / 2, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
				function buyBtn:Think()
						self.hoverLerp = Lerp(FrameTime() * 8, self.hoverLerp, (canBuy and self:IsHovered()) and 1 or 0)
				end
				function buyBtn:DoClick()
						if not canBuy then return end
					surface.PlaySound("menu/ui_click.mp3")
					net.Start("Monarch_VendorBuy") net.WriteEntity(vendor) net.WriteString(data.class) net.SendToServer()
				end

				local sp2 = tonumber(data.sellPrice or 0) or 0
				if sp2 > 0 then
					local sellBtn = vgui.Create("DButton", itemDetail)
					sellBtn:SetPos(240, btnY)
					sellBtn:SetSize(200, 45)
					sellBtn:SetText("")
					sellBtn.hoverLerp = 0
					function sellBtn:Paint(w, h)
						local base = Color(125, 125, 125)
						local bg = Color(30, 30, 30)
						local hov = Color(255, 180, 100)
						local c = LerpColor(self.hoverLerp, base, hov)
						surface.SetDrawColor(bg) surface.DrawRect(0, 0, w, h)
						surface.SetDrawColor(c) surface.DrawOutlinedRect(0, 0, w, h, 2)
						local txt = (data.owned or 0) > 0 and ("Sell ($" .. string.Comma(sp2) .. ")") or "Cannot Sell"
						draw.SimpleText(txt, "InvMed", w / 2, h / 2, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					end
					function sellBtn:Think()
						self.hoverLerp = Lerp(FrameTime() * 8, self.hoverLerp, self:IsHovered() and 1 or 0)
						self:SetDisabled((data.owned or 0) <= 0)
					end
					function sellBtn:DoClick()
						if (data.owned or 0) <= 0 then return end
						surface.PlaySound("menu/ui_click.mp3")
						net.Start("Monarch_VendorSell") net.WriteEntity(vendor) net.WriteString(data.class) net.SendToServer()
					end
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

net.Receive("Monarch_VendorOpen", function()
	local vendor = net.ReadEntity()
	local name = net.ReadString()
	local desc = net.ReadString()
	local itemCount = net.ReadUInt(8)

	local items = {}
	for i = 1, itemCount do
		local it = {
			class = net.ReadString(),
			name = net.ReadString(),
			desc = net.ReadString(),
			model = net.ReadString(),
			price = net.ReadUInt(32),
			stock = net.ReadUInt(16),
			sellPrice = net.ReadUInt(32),
			owned = net.ReadUInt(16),
			eligible = net.ReadBool()
		}
		table.insert(items, it)
	end

	openVendorUI(vendor, name, desc, items)
end)

net.Receive("Monarch_VendorNotify", function()
	local msg = net.ReadString()
	if LocalPlayer().Notify then
		LocalPlayer():Notify(msg)
	else
		chat.AddText(Color(255, 100, 100), "[Vendor] ", color_white, msg)
	end
end)