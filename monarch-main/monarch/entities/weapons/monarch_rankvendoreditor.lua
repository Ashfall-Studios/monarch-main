AddCSLuaFile()

if CLIENT then
	SWEP.PrintName = "Rank Vendor Editor"
	SWEP.Slot = 0
	SWEP.SlotPos = 0
	SWEP.CLMode = 0

	net.Receive("Monarch_RankVendor_List", function()
		Monarch = Monarch or {}
		Monarch.RankVendorsClient = net.ReadTable() or {}
	end)
end

SWEP.HoldType = "fists"
SWEP.Category = "Monarch"
SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"

SWEP.Primary.Delay = 1
SWEP.Primary.Recoil = 0	
SWEP.Primary.Damage = 0
SWEP.Primary.NumShots = 0
SWEP.Primary.Cone = 0 	
SWEP.Primary.ClipSize = -1	
SWEP.Primary.DefaultClip = -1	
SWEP.Primary.Automatic = false	
SWEP.Primary.Ammo = "none"
SWEP.IsAlwaysRaised = true

SWEP.Secondary.Delay = 0.9
SWEP.Secondary.Recoil = 0
SWEP.Secondary.Damage = 0
SWEP.Secondary.NumShots = 1
SWEP.Secondary.Cone = 0
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.NextGo = 0

if SERVER then
	function SWEP:Equip(owner)
		if not owner:IsAdmin() then
			owner:StripWeapon("monarch_rankvendoreditor")
		end
	end

	function SWEP:PrimaryAttack()
	end

	function SWEP:Reload()
	end

	function SWEP:SecondaryAttack()
	end
else
	local uiBg = Color(18, 18, 18, 240)
	local uiPanel = Color(30, 30, 30, 240)
	local uiText = Color(235, 235, 235)
	local uiMuted = Color(160, 160, 160)
	local uiAccent = Color(95, 95, 95)

	local function StyleFrame(frame, title)
		frame:SetTitle("")
		frame:ShowCloseButton(false)
		frame.Paint = function(_, w, h)
			draw.RoundedBox(6, 0, 0, w, h, uiBg)
			draw.RoundedBox(6, 0, 0, w, 34, Color(24, 24, 24, 250))
			surface.SetDrawColor(uiAccent)
			surface.DrawRect(0, 33, w, 2)
			draw.SimpleText(title, "DermaDefaultBold", 12, 17, uiText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			surface.SetDrawColor(55, 55, 55, 220)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end
		local closeBtn = vgui.Create("DButton", frame)
		closeBtn:SetSize(28, 24)
		closeBtn:SetPos(frame:GetWide() - 34, 5)
		closeBtn:SetText("")
		closeBtn.Paint = function(self, w, h)
			draw.SimpleText("✕", "DermaDefaultBold", w * 0.5, h * 0.5, self:IsHovered() and uiAccent or uiMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		closeBtn.DoClick = function() frame:Close() end
	end

	local function StyleButton(btn, label, accent)
		btn:SetText("")
		btn.Paint = function(self, w, h)
			local bg = self:IsHovered() and Color(36, 36, 36, 240) or uiPanel
			draw.RoundedBox(4, 0, 0, w, h, bg)
			surface.SetDrawColor(accent or uiAccent)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			draw.SimpleText(label, "DermaDefaultBold", w * 0.5, h * 0.5, uiText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	local function StyleTextEntry(entry)
		entry:SetTextColor(uiText)
		entry.Paint = function(self, w, h)
			draw.RoundedBox(4, 0, 0, w, h, uiPanel)
			self:DrawTextEntryText(uiText, uiAccent, uiText)
			surface.SetDrawColor(60, 60, 60, 220)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end
	end

	local function StyleTabs(tabs)
		tabs:DockMargin(8, 40, 8, 8)
		tabs.Paint = function(_, w, h)
			draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 20, 220))
		end

		if IsValid(tabs.tabScroller) then
			tabs.tabScroller:SetOverlap(0)
			tabs.tabScroller.Paint = function(_, w, h)
				draw.RoundedBox(4, 0, 0, w, h, Color(24, 24, 24, 235))
				surface.SetDrawColor(55, 55, 55, 220)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
			end
		end

		local function ApplyTabPaint()
			if not tabs.Items then return end
			for _, sheet in ipairs(tabs.Items) do
				local tab = sheet.Tab
				if IsValid(tab) then
					if tab._styledLabel == nil then
						tab._styledLabel = "Configuration"
						tab:SetText("")
						surface.SetFont("DermaDefaultBold")
						local tw = surface.GetTextSize(tab._styledLabel)
						tab:SetWide(math.max(140, tw + 30))
					end
					tab.Paint = function(self, w, h)
						local active = tabs:GetActiveTab() == self
						local bg = active and Color(34, 34, 34, 245) or Color(26, 26, 26, 220)
						draw.RoundedBox(4, 0, 0, w, h, bg)
						surface.SetDrawColor(active and uiAccent or Color(55, 55, 55, 220))
						surface.DrawOutlinedRect(0, 0, w, h, 1)
						if active then
							surface.SetDrawColor(uiAccent)
							surface.DrawRect(0, h - 2, w, 2)
						end
						draw.SimpleText(self._styledLabel or "", "DermaDefaultBold", w * 0.5, h * 0.5, active and uiText or uiMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					end
				end
			end
		end

		tabs.Think = ApplyTabPaint
		ApplyTabPaint()
	end

	local function FitModelPreview(preview)
		if not IsValid(preview) or not IsValid(preview.Entity) then return end
		preview.Entity:SetNoDraw(false)
		preview.Entity:SetMaterial("")
		preview.Entity:SetColor(Color(255, 255, 255, 255))
		local mins, maxs = preview.Entity:GetModelBounds()
		if mins == maxs then
			mins, maxs = preview.Entity:GetRenderBounds()
		end
		local center = (mins + maxs) * 0.5
		local size = maxs - mins
		local radius = math.max(size.x, size.y, size.z)
		if radius <= 0 then radius = 40 end
		radius = math.Clamp(radius, 18, 140)
		preview:SetFOV(45)
		preview:SetLookAt(center)
		preview:SetCamPos(center + Vector(radius * 1.25, radius * 1.25, radius * 0.42))
		preview:SetAmbientLight(Color(65, 65, 65))
		preview:SetDirectionalLight(BOX_TOP, Color(200, 200, 200))
		preview:SetDirectionalLight(BOX_FRONT, Color(120, 120, 120))
		preview:SetDirectionalLight(BOX_RIGHT, Color(120, 120, 120))
	end

	local function QueueFitModelPreview(preview, attempt)
		attempt = attempt or 1
		timer.Simple(0.05, function()
			if not IsValid(preview) then return end
			if IsValid(preview.Entity) then
				local mins, maxs = preview.Entity:GetRenderBounds()
				if (maxs - mins):LengthSqr() > 1 then
					FitModelPreview(preview)
					return
				end
			end
			if attempt < 15 then
				QueueFitModelPreview(preview, attempt + 1)
			else
				FitModelPreview(preview)
			end
		end)
	end

	local function EnablePreviewRotation(preview)
		preview._yaw = 30
		preview._dragging = false
		preview:SetCursor("sizeall")

		preview.OnMousePressed = function(self, mouseCode)
			if mouseCode ~= MOUSE_LEFT then return end
			self._dragging = true
			self._lastMouseX = gui.MouseX()
			self:MouseCapture(true)
		end

		preview.OnMouseReleased = function(self, mouseCode)
			if mouseCode ~= MOUSE_LEFT then return end
			self._dragging = false
			self:MouseCapture(false)
		end

		preview.OnCursorMoved = function(self)
			if not self._dragging then return end
			local mx = gui.MouseX()
			local dx = mx - (self._lastMouseX or mx)
			self._lastMouseX = mx
			self._yaw = (self._yaw or 0) - (dx * 0.5)
		end

		preview.LayoutEntity = function(self, ent)
			ent:SetAngles(Angle(0, self._yaw or 0, 0))
		end
	end

	function SWEP:PrimaryAttack()
		if self.NextGo > CurTime() then return end

		net.Start("Monarch_RankVendor_List")
		net.SendToServer()

		local trace = {}
		trace.start = self.Owner:EyePos()
		trace.endpos = trace.start + self.Owner:GetAimVector() * 140
		trace.filter = self.Owner

		local tr = util.TraceLine(trace)
		local ent = tr.Entity

		if IsValid(ent) and ent:GetClass() == "monarch_rankvendor" then

			timer.Simple(0.1, function()
				if not IsValid(ent) then return end

				local frame = vgui.Create("DFrame")
					frame:SetSize(math.min(ScrW() - 60, 980), math.min(ScrH() - 40, 900))
				frame:Center()
				frame:MakePopup()
					StyleFrame(frame, "Configure Rank Vendor")

				local panel = vgui.Create("DPanel", frame)
				panel:Dock(FILL)
				panel:DockMargin(8, 40, 8, 8)
				panel:DockPadding(5,5,5,5)
					panel.Paint = function(_, w, h)
						draw.RoundedBox(4, 0, 0, w, h, Color(22, 22, 22, 220))
					end

				local vendors = {}
				local vendorSource = (Monarch and Monarch.RankVendorsClient) or (Monarch and Monarch.RankVendors)
				if vendorSource then
					for id,data in pairs(vendorSource) do
						vendors[#vendors+1] = {id=id,name=data.name or id,desc=data.desc or ""}
					end
				end
					table.sort(vendors,function(a,b) return a.id<b.id end)

				local scroll = vgui.Create("DScrollPanel", panel)
				scroll:Dock(LEFT)
				scroll:SetWide(340)

				for _, v in ipairs(vendors) do
					local btn = vgui.Create("DButton", scroll)
					btn:Dock(TOP)
					btn:DockMargin(0,0,0,5)
					btn:SetTall(56)
					btn:SetText("")
					btn.Paint = function(self,w,h)
							local col = self:IsHovered() and Color(45,45,45) or uiPanel
						draw.RoundedBox(4,0,0,w,h,col)
							draw.SimpleText(v.name,"DermaDefaultBold",10,10,uiText)
							draw.SimpleText(v.id,"DermaDefault",10,26,uiMuted)
						local d=v.desc if #d>42 then d=d:sub(1,42).."..." end
							draw.SimpleText(d,"DermaDefault",10,40,uiText)
							surface.SetDrawColor(uiAccent)
							surface.DrawOutlinedRect(0, 0, w, h, 1)
					end
					btn.DoClick = function()
						net.Start("Monarch_SetRankVendorID")
						net.WriteEntity(ent)
						net.WriteString(v.id)
						net.SendToServer()
						self.Owner:Notify("Rank vendor type set: "..v.name)
					end
				end

				local right = vgui.Create("DPanel", panel)
				right:Dock(FILL)
				right:DockMargin(10,0,0,0)
					right.Paint = function(_, w, h)
						draw.RoundedBox(4, 0, 0, w, h, Color(22, 22, 22, 220))
					end

				local currentModel = ent:GetModel()
				if not isstring(currentModel) or currentModel == "" or not util.IsValidModel(currentModel) then
					currentModel = "models/Humans/Group01/male_07.mdl"
				end
				local previewWrap = vgui.Create("DPanel", right)
				previewWrap:Dock(FILL)
				previewWrap:DockMargin(0, 0, 0, 6)
				previewWrap.Paint = function(_, w, h)
					draw.RoundedBox(4, 0, 0, w, h, Color(16, 16, 16, 240))
					surface.SetDrawColor(60, 60, 60, 220)
					surface.DrawOutlinedRect(0, 0, w, h, 1)
				end

				local preview = vgui.Create("DModelPanel", previewWrap)
				preview:Dock(FILL)
				preview:DockMargin(6, 6, 6, 6)
				preview:SetModel(currentModel)
				EnablePreviewRotation(preview)
				QueueFitModelPreview(preview)

				local controls = vgui.Create("DPanel", right)
				controls:Dock(BOTTOM)
				controls:SetTall(230)
				controls.Paint = nil

				local entry = vgui.Create("DTextEntry", controls)
				entry:Dock(TOP)
				entry:DockMargin(0,8,0,0)
				entry:SetPlaceholderText("Enter model path (e.g. models/Humans/Group01/male_07.mdl)")
				entry:SetText(currentModel)
					StyleTextEntry(entry)

				local applyBtn = vgui.Create("DButton", controls)
				applyBtn:Dock(TOP)
				applyBtn:DockMargin(0,6,0,0)
				applyBtn:SetTall(34)
					StyleButton(applyBtn, "Apply Model", uiAccent)
				applyBtn.DoClick = function()
					local path = entry:GetValue():Trim()
					if path=="" then self.Owner:Notify("Model path empty") return end
					if not util.IsValidModel(path) then
						self.Owner:Notify("Invalid model path")
						return
					end
					preview:SetModel(path)
					QueueFitModelPreview(preview)
					net.Start("Monarch_SetRankVendorModel")
					net.WriteEntity(ent)
					net.WriteString(path)
					net.SendToServer()
					self.Owner:Notify("Rank vendor model updated.")
				end

				local resetBtn = vgui.Create("DButton", controls)
				resetBtn:Dock(TOP)
				resetBtn:DockMargin(0,6,0,0)
				resetBtn:SetTall(34)
					StyleButton(resetBtn, "Clear Model (Default)", Color(120, 120, 120))
				resetBtn.DoClick = function()
					net.Start("Monarch_ClearRankVendorModel")
					net.WriteEntity(ent)
					net.SendToServer()
					preview:SetModel("models/Humans/Group01/male_07.mdl")
					QueueFitModelPreview(preview)
					self.Owner:Notify("Rank vendor model cleared.")
				end

				local removeBtn = vgui.Create("DButton", controls)
				removeBtn:Dock(TOP)
				removeBtn:DockMargin(0,6,0,0)
				removeBtn:SetTall(34)
					StyleButton(removeBtn, "Remove Vendor Entity", Color(95, 95, 95))
				removeBtn.DoClick = function()
					net.Start("Monarch_RemoveRankVendor")
					net.WriteEntity(ent)
					net.SendToServer()
					frame:Close()
				end

				local saveBtn = vgui.Create("DButton", controls)
				saveBtn:Dock(TOP)
				saveBtn:DockMargin(0,6,0,0)
				saveBtn:SetTall(34)
					StyleButton(saveBtn, "Save This Vendor", uiAccent)

				saveBtn.DoClick = function()
					net.Start("Monarch_SaveSingleRankVendor")
					net.WriteEntity(ent)
					net.SendToServer()
					surface.PlaySound("buttons/button14.wav")
				end

				self.NextGo = CurTime() + .3
			end)
		else
			self.Owner:Notify("Aim at a monarch_rankvendor entity!")
		end
	end

	function SWEP:SecondaryAttack()
		if self.NextGo > CurTime() then return end

		local trace = {}
		trace.start = self.Owner:EyePos()
		trace.endpos = trace.start + self.Owner:GetAimVector() * 140
		trace.filter = self.Owner

		local tr = util.TraceLine(trace)
		local ent = tr.Entity

		if IsValid(ent) and ent:GetClass() == "monarch_rankvendor" then
			net.Start("Monarch_ResetRankVendor")
			net.WriteEntity(ent)
			net.SendToServer()

			self.Owner:Notify("Reset rank vendor!")
			surface.PlaySound("buttons/button10.wav")
		else
			self.Owner:Notify("Aim at a monarch_rankvendor entity!")
		end

		self.NextGo = CurTime() + .3
	end

	function SWEP:Reload()
		self.Owner:Notify("Use LEFT CLICK to configure, RIGHT CLICK to reset")
	end

	function SWEP:DrawHUD()
		local line1 = "Rank Vendor Editor - Aim at monarch_rankvendor"
		local line2 = "LEFT CLICK: Configure rank vendor type"
		local line3 = "RIGHT CLICK: Reset rank vendor"
		local line4 = "RELOAD: Show help"
		surface.SetFont("DermaDefaultBold")
		local maxW = surface.GetTextSize(line1)
		surface.SetFont("DermaDefault")
		maxW = math.max(maxW, surface.GetTextSize(line2), surface.GetTextSize(line3), surface.GetTextSize(line4))
		local x, y = 100, 100
		local padX, padY = 12, 8
		local boxW = maxW + (padX * 2)
		local boxH = 72
		local boxX = x - padX
		local boxY = y - padY
		draw.RoundedBox(4, boxX, boxY, boxW, boxH, Color(18, 18, 18, 220))
		surface.SetDrawColor(uiAccent)
		surface.DrawRect(boxX, boxY, boxW, 2)
		draw.SimpleText(line1, "DermaDefaultBold", x, y, uiText)
		draw.SimpleText(line2, "DermaDefault", x, y + 20, uiMuted)
		draw.SimpleText(line3, "DermaDefault", x, y + 35, uiMuted)
		draw.SimpleText(line4, "DermaDefault", x, y + 50, uiMuted)

		for v, k in pairs(ents.FindByClass("monarch_rankvendor")) do
			if k:GetPos():DistToSqr(LocalPlayer():GetPos()) < (1000 ^ 2) then
				local sPos = k:GetPos():ToScreen()
				local vendorName = k:GetRankVendorID() or "Unconfigured"
				draw.SimpleText("Rank Vendor: " .. vendorName, "ChatFont", sPos.x, sPos.y, uiAccent, TEXT_ALIGN_CENTER)
			end
		end
	end
end

if SERVER then
	util.AddNetworkString("Monarch_SetRankVendorID")
	util.AddNetworkString("Monarch_ResetRankVendor")
	util.AddNetworkString("Monarch_SetRankVendorModel")
	util.AddNetworkString("Monarch_ClearRankVendorModel")
	util.AddNetworkString("Monarch_RemoveRankVendor")
	util.AddNetworkString("Monarch_SaveSingleRankVendor")
	util.AddNetworkString("Monarch_RankVendor_List")

	net.Receive("Monarch_RankVendor_List", function(_, ply)
		if not IsValid(ply) or not ply:IsAdmin() then return end
		local payload = {}
		if Monarch and Monarch.RankVendors then
			for id, data in pairs(Monarch.RankVendors) do
				payload[id] = {
					name = data.name,
					desc = data.desc,
					model = data.model,
					team = data.team
				}
			end
		end
		net.Start("Monarch_RankVendor_List")
		net.WriteTable(payload)
		net.Send(ply)
	end)

	net.Receive("Monarch_SetRankVendorID", function(len, ply)
		if not ply:IsAdmin() then return end

		local ent = net.ReadEntity()
		local vendorID = net.ReadString()

		if IsValid(ent) and ent:GetClass() == "monarch_rankvendor" then
			ent:SetRankVendorID(vendorID)

			if Monarch and Monarch.RankVendors and Monarch.RankVendors[vendorID] then
				local cfg = Monarch.RankVendors[vendorID]
				ent:SetVendorName(cfg.name or "Rank Vendor")
				ent:SetVendorDesc(cfg.desc or "Purchase ranks and promotions")
				ent:SetRequiredTeam(cfg.team or 0)

				if cfg.model then
					ent:SetModel(cfg.model)
				end
			end

			ply:Notify("Rank vendor configured as: " .. vendorID .. " - Click 'Save This Vendor' to save")
		end
	end)

	net.Receive("Monarch_ResetRankVendor", function(len, ply)
		if not ply:IsAdmin() then return end

		local ent = net.ReadEntity()

		if IsValid(ent) and ent:GetClass() == "monarch_rankvendor" then
			ent:SetRankVendorID("")
			ent:SetVendorName("Rank Vendor")
			ent:SetVendorDesc("Purchase ranks and promotions")
			ent:SetRequiredTeam(0)
			ent:SetModel("models/Humans/Group01/male_07.mdl")

			ply:Notify("Rank vendor reset! - Click 'Save This Vendor' to save")
		end
	end)

	net.Receive("Monarch_SetRankVendorModel", function(_, ply)
		if not ply:IsAdmin() then return end
		local ent = net.ReadEntity()
		local path = net.ReadString()
		if IsValid(ent) and ent:GetClass()=="monarch_rankvendor" and util.IsValidModel(path) then
			ent:SetModel(path)
			ent.MonarchSaveData = ent.MonarchSaveData or {}
			ent.MonarchSaveData.model = path
			ply:Notify("Rank vendor model set - Click 'Save This Vendor' to save")
		end
	end)

	net.Receive("Monarch_ClearRankVendorModel", function(_, ply)
		if not ply:IsAdmin() then return end
		local ent = net.ReadEntity()
		if IsValid(ent) and ent:GetClass()=="monarch_rankvendor" then
			ent:SetModel("models/Humans/Group01/male_07.mdl")
			if ent.MonarchSaveData then ent.MonarchSaveData.model = nil end
			ply:Notify("Rank vendor model reset - Click 'Save This Vendor' to save")
		end
	end)

	net.Receive("Monarch_RemoveRankVendor", function(_, ply)
		if not ply:IsAdmin() then return end
		local ent = net.ReadEntity()
		if IsValid(ent) and ent:GetClass()=="monarch_rankvendor" then

			if ent._persistUID and Monarch and Monarch._removedRankVendorUIDs then
				Monarch._removedRankVendorUIDs[ent._persistUID] = true
			end
			ply:Notify("Rank vendor removed - Changes will save with other vendors")
			ent:Remove()
		end
	end)

	net.Receive("Monarch_SaveSingleRankVendor", function(_, ply)
		if not ply:IsAdmin() then return end
		local ent = net.ReadEntity()
		if IsValid(ent) and ent:GetClass() == "monarch_rankvendor" then
			if not Monarch then
				ply:Notify("Error: Monarch table not initialized")
				return
			end
			if not Monarch.RankVendor_SaveSingle then
				ply:Notify("Error: Save function not loaded - try reloading the entity")
				PrintTable(Monarch)
				return
			end
			Monarch.RankVendor_SaveSingle(ent)
			ply:Notify("Rank vendor saved successfully")
		end
	end)
end
