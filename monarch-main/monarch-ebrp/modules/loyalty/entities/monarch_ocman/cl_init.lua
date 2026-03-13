
include("monarch-ebrp/modules/loyalty/sh_lyt.lua")
include("monarch-ebrp/modules/loyalty/cl_lyt.lua")
include("monarch-ebrp/modules/police/cl_police.lua")
include("shared.lua")

local mouse_click = "comp/mouse2.mp3"
local boot_finish = "comp/boot_finish.mp3"

local COLORS = {
	bg = Color(0, 124, 124, 255),
	panel = Color(192, 192, 192, 255),
	panel2 = Color(0, 0, 128, 255),
	stroke = Color(0, 0, 0, 255),
	strokeSoft = Color(128, 128, 128, 255),
	text = Color(0, 0, 0, 255),
	textDim = Color(64, 64, 64, 255),
	textFaint = Color(128, 128, 128, 255),
	accent = Color(0, 0, 128, 255),
	accent2 = Color(0, 0, 128, 255),
	green = Color(0, 128, 0, 255),
	red = Color(192, 0, 0, 255),
	yellow = Color(255, 255, 0, 255),
	white = Color(255, 255, 255, 255),
	highlight = Color(223, 223, 223, 255),
	shadow = Color(128, 128, 128, 255),
	darkshadow = Color(64, 64, 64, 255),
}

local GLOBAL_FRAME = nil
local CURRENT_APP = "loyalty"
local SELECTED_CITIZEN = nil

local APP_DATA = {
	loyalty = { name = "Loyalty Tiers" },
	party = { name = "Party Membership" },
	notes = { name = "Occupant Notes" },
	taxation = { name = "Taxation Management" },
	warrants = { name = "Active Warrants" },
	criminal = { name = "Criminal Records" },
	citations = { name = "Citations" },
	bail = { name = "Bail Management" },
	detainees = { name = "Detention" },
}

local function GetLocalCharName(ply)
	if not IsValid(ply) then return "Unknown" end
	if ply.GetCharName then
		local n = ply:GetCharName()
		if isstring(n) and n ~= "" then return n end
	end
	if ply.MonarchActiveChar and ply.MonarchActiveChar.name then
		local n = ply.MonarchActiveChar.name
		if isstring(n) and n ~= "" then return n end
	end
	if ply.GetRPName then
		local n = ply:GetRPName()
		if isstring(n) and n ~= "" then return n end
	end
	return ply:Nick()
end

local function GetLocalCharID(ply)
	if not IsValid(ply) then return nil end
	if ply.GetCharID then
		local cid = ply:GetCharID()
		if cid then return tostring(cid) end
	end
	if ply.MonarchActiveChar and ply.MonarchActiveChar.id then
		return tostring(ply.MonarchActiveChar.id)
	end
	if ply.MonarchLastCharID then
		return tostring(ply.MonarchLastCharID)
	end
	return nil
end

local function GetOnlineCharChoices()
	local choices = {}
	for _, ply in ipairs(player.GetAll()) do
		local cid = GetLocalCharID(ply) or ply:GetNWString("MonarchCharID", nil)
		local cname = (GetRPName and GetRPName(ply)) or GetLocalCharName(ply) or ply:Nick()
		if cid and cid ~= "" then
			table.insert(choices, {
				id = tostring(cid),
				name = cname,
				display = cname
			})
		end
	end

	table.sort(choices, function(a, b) return (a.name or "") < (b.name or "") end)
	return choices
end

local function PopulateCharDropdown(combo)
	combo:Clear()
	local items = GetOnlineCharChoices()
	for _, entry in ipairs(items) do
		combo:AddChoice(entry.display, entry)
	end
	return items
end

local function BuildPlayerList()
	local data = Monarch.Loyalty.GetClientData()
	local citizens, seen = {}, {}
	for _, ply in ipairs(player.GetAll()) do
		local charKey = GetLocalCharID(ply)
		if charKey then
			local entry = data[charKey] or {}
			local currentName = GetLocalCharName(ply)
			local displayName = entry.char_name or entry.name or currentName or ("Character " .. charKey)
			table.insert(citizens, {
				char_id = charKey,
				steamid = entry.steamid or ply:SteamID(),
				name = displayName,
				loyalty_points = entry.loyalty_points or entry.loyalty_tier or 0,
				party_tier = entry.party_tier or 0,
				tax_rate = entry.tax_rate or 0.30,
				note = entry.note or "",
			})
			seen[charKey] = true
		end
	end

	for charKey, entry in pairs(data) do
		if not seen[charKey] then
			local displayName = entry.char_name or entry.name or ("Character " .. tostring(charKey))
			table.insert(citizens, {
				char_id = charKey,
				steamid = entry.steamid or "unknown",
				name = displayName,
				loyalty_points = entry.loyalty_points or entry.loyalty_tier or 0,
				party_tier = entry.party_tier or 0,
				tax_rate = entry.tax_rate or 0.30,
				note = entry.note or "",
			})
		end
	end

	return citizens
end

local function DrawPanel(x, y, w, h, fill, raised)
	surface.SetDrawColor(fill)
	surface.DrawRect(x, y, w, h)

	if raised then
		surface.SetDrawColor(COLORS.white)
		surface.DrawRect(x, y, w - 1, 1)
		surface.DrawRect(x, y, 1, h - 1)

		surface.SetDrawColor(COLORS.darkshadow)
		surface.DrawRect(x + w - 1, y, 1, h)
		surface.DrawRect(x, y + h - 1, w, 1)

		surface.SetDrawColor(COLORS.highlight)
		surface.DrawRect(x + 1, y + 1, w - 3, 1)
		surface.DrawRect(x + 1, y + 1, 1, h - 3)

		surface.SetDrawColor(COLORS.shadow)
		surface.DrawRect(x + w - 2, y + 1, 1, h - 2)
		surface.DrawRect(x + 1, y + h - 2, w - 2, 1)
	else
		surface.SetDrawColor(COLORS.darkshadow)
		surface.DrawRect(x, y, w, 1)
		surface.DrawRect(x, y, 1, h)

		surface.SetDrawColor(COLORS.white)
		surface.DrawRect(x + w - 1, y + 1, 1, h - 1)
		surface.DrawRect(x + 1, y + h - 1, w - 1, 1)

		surface.SetDrawColor(COLORS.shadow)
		surface.DrawRect(x + 1, y + 1, w - 2, 1)
		surface.DrawRect(x + 1, y + 1, 1, h - 2)

		surface.SetDrawColor(COLORS.highlight)
		surface.DrawRect(x + w - 2, y + 2, 1, h - 3)
		surface.DrawRect(x + 2, y + h - 2, w - 3, 1)
	end
end

local function LerpColor(frac, from, to)
	return Color(
		Lerp(frac, from.r, to.r),
		Lerp(frac, from.g, to.g),
		Lerp(frac, from.b, to.b),
		Lerp(frac, from.a or 255, to.a or 255)
	)
end

local function EaseInOut(t)
	return t < 0.5 and (2 * t * t) or (1 - math.pow(-2 * t + 2, 2) / 2)
end

do
	if not _G.MONARCH_OCMAN_FONTS_CREATED then
		_G.MONARCH_OCMAN_FONTS_CREATED = true
		surface.CreateFont("MonarchOcman_Title", {
			font = "Tahoma",
			size = 20,
			weight = 700,
			antialias = false,
		})
		surface.CreateFont("MonarchOcman_Sub", {
			font = "Tahoma",
			size = 14,
			weight = 400,
			antialias = false,
		})
		surface.CreateFont("MonarchOcman_Text", {
			font = "Tahoma",
			size = 13,
			weight = 400,
			antialias = false,
		})
		surface.CreateFont("MonarchOcman_Small", {
			font = "Tahoma",
			size = 11,
			weight = 400,
			antialias = false,
		})
	end
end

local function CreateFrame()
	if IsValid(GLOBAL_FRAME) then return GLOBAL_FRAME end

	Monarch.Loyalty.RequestData()

	local sw, sh = ScrW(), ScrH()
	local pad = 18
	local sidebarW = math.max(260, math.floor(sw * 0.18))
	surface.PlaySound(boot_finish)

	local frame = vgui.Create("DFrame")
	frame:SetTitle("")
	frame:SetSize(sw, sh)
	frame:SetPos(0, 0)
	frame:MakePopup()
	frame:SetDraggable(false)
	frame:ShowCloseButton(false)
	frame:SetKeyboardInputEnabled(true)
	frame:SetMouseInputEnabled(true)
	frame:SetDeleteOnClose(false)
	frame:SetAlpha(0)
	frame:AlphaTo(255, 0.18, 0)

	frame._loadStart = CurTime()
	frame._loadDur = 0.9
	frame._isLoading = true
	frame._active = CURRENT_APP
	frame._switchFrom = CURRENT_APP
	frame._switchTo = CURRENT_APP
	frame._switchStart = 0
	frame._switchDur = 0.18
	frame._switching = false

	function frame:Close()
		if not IsValid(self) then return end
		self:AlphaTo(0, 0.12, 0, function()
			if IsValid(self) then 
				self:SetVisible(false)
				GLOBAL_FRAME = nil
			end
		end)
	end

	frame.OnKeyCodePressed = function(self, key)
		if key == KEY_ESCAPE then
			self:Close()
			return
		end
	end

	local bgMat = Material("comp_bg.jpg")

	frame.Paint = function(self, w, h)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(bgMat)
		surface.DrawTexturedRect(0, 0, w, h)
	end

	local container = vgui.Create("DPanel", frame)
	container:SetPos(pad, pad)
	container:SetSize(sw - pad * 2, sh - pad * 2)
	container.Paint = function(self, w, h)
		DrawPanel(0, 0, w, h, COLORS.panel, true)
	end

	local top = vgui.Create("DPanel", container)
	top:SetTall(26)
	top:Dock(TOP)
	top:DockMargin(3, 3, 3, 0)
	top.Paint = function(self, w, h)
		surface.SetDrawColor(0, 0, 128, 255)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(Material("icon16/user_suit.png"))
		surface.DrawTexturedRect(4, 4, 16, 16)

		draw.SimpleText("Occupant Management Operating System", "MonarchOcman_Sub", 26, h / 2, COLORS.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local closeBtn = vgui.Create("DButton", top)
	closeBtn:Dock(RIGHT)
	closeBtn:SetWide(22)
	closeBtn:DockMargin(0, 2, 2, 2)
	closeBtn:SetText("")
	closeBtn.Paint = function(self, w, h)
		local raised = not self:IsDown()
		DrawPanel(0, 0, w, h, COLORS.panel, raised)
		draw.SimpleText("×", "MonarchOcman_Title", w / 2, h / 2 - 2, COLORS.stroke, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	closeBtn.OnMousePressed = function(self, mcode)
		if DButton and DButton.OnMousePressed then DButton.OnMousePressed(self, mcode) end
	end
	closeBtn.OnMouseReleased = function(self, mcode)
		if DButton and DButton.OnMouseReleased then DButton.OnMouseReleased(self, mcode) end
	end
	closeBtn.DoClick = function()
		surface.PlaySound(mouse_click)
		frame:Close()
	end

	local body = vgui.Create("DPanel", container)
	body:Dock(FILL)
	body:DockMargin(3, 3, 3, 3)
	body.Paint = function(self, w, h) end

	local sidebar = vgui.Create("DPanel", body)
	sidebar:Dock(LEFT)
	sidebar:SetWide(sidebarW)
	sidebar:DockMargin(0, 0, 6, 0)
	sidebar.Paint = function(self, w, h)
		DrawPanel(0, 0, w, h, COLORS.panel, false)
	end

	local content = vgui.Create("DPanel", body)
	content:Dock(FILL)
	content.Paint = function(self, w, h)
		DrawPanel(0, 0, w, h, COLORS.white, false)
	end

	local function HideAllWidgets()
		if not IsValid(view) then return end
		local hideBucket = function(bucket)
			if not bucket then return end
			for _, ctrl in pairs(bucket) do
				if IsValid(ctrl) then ctrl:SetVisible(false) end
			end
		end
		hideBucket(view._tierButtons)
		hideBucket(view._partyButtons)
		hideBucket(view._noteButtons)
		hideBucket(view._taxSliders)
		if IsValid(view._generalTaxSlider) then view._generalTaxSlider:SetVisible(false) end
		if IsValid(view._noteEntry) then view._noteEntry:SetVisible(false) end
		if IsValid(view._noteSaveBtn) then view._noteSaveBtn:SetVisible(false) end
	end

	local function ResetWidgets()
		if not IsValid(view) then return end
		local buckets = {view._tierButtons, view._partyButtons, view._noteButtons, view._taxSliders}
		for _, bucket in ipairs(buckets) do
			if bucket then
				for _, ctrl in pairs(bucket) do
					if IsValid(ctrl) then ctrl:Remove() end
				end
			end
		end
		if IsValid(view._noteEntry) then view._noteEntry:Remove() end
		if IsValid(view._noteSaveBtn) then view._noteSaveBtn:Remove() end
		if IsValid(view._generalTaxSlider) then view._generalTaxSlider:Remove() end
		view._tierButtons = nil
		view._partyButtons = nil
		view._noteButtons = nil
		view._taxSliders = nil
		view._noteEntry = nil
		view._noteSaveBtn = nil
		view._noteLoadedFor = nil
		view._generalTaxSlider = nil
		view._taxValues = nil
	end

	local function SetApp(nextApp)
		if frame._active == nextApp then return end
		HideAllWidgets()
		ResetWidgets()

		if frame._warrantRevokeBtns then for _, b in pairs(frame._warrantRevokeBtns) do if IsValid(b) then b:SetVisible(false) end end end
		if IsValid(frame._warrantForm) then frame._warrantForm:SetVisible(false) end
		if frame._citationMarkBtns then for _, b in pairs(frame._citationMarkBtns) do if IsValid(b) then b:SetVisible(false) end end end
		if IsValid(frame._citationForm) then frame._citationForm:SetVisible(false) end
		frame._switchFrom = frame._active
		frame._switchTo = nextApp
		frame._switchStart = CurTime()
		frame._switching = true
		frame._active = nextApp
		CURRENT_APP = nextApp
		SELECTED_CITIZEN = nil
	end

	local APP_ICONS = {
		loyalty = "icon16/report.png",
		party = "icon16/flag_red.png",
		notes = "icon16/note.png",
		taxation = "icon16/money.png",
		warrants = "icon16/user_red.png",
		criminal = "icon16/book.png",
		citations = "icon16/page_white_text.png",
		bail = "icon16/coins.png",
		detainees = "icon16/lock.png",
	}

	local function MakeNavButton(parent, appId)
		local btn = vgui.Create("DButton", parent)
		btn:Dock(TOP)
		btn:SetTall(42)
		btn:DockMargin(6, 6, 6, 0)
		btn:SetText("")
		btn.Paint = function(self, w, h)
			local isActive = (frame._active == appId)
			local raised = not (self:IsDown() or isActive)
			DrawPanel(0, 0, w, h, COLORS.panel, raised)

			local iconPath = APP_ICONS[appId] or "icon16/computer.png"
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(Material(iconPath))
			surface.DrawTexturedRect(6, h / 2 - 8, 16, 16)

			draw.SimpleText(APP_DATA[appId].name, "MonarchOcman_Text", 28, h / 2, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		btn.OnMousePressed = function(self, mcode)
			if DButton and DButton.OnMousePressed then DButton.OnMousePressed(self, mcode) end
		end
		btn.OnMouseReleased = function(self, mcode)
			if DButton and DButton.OnMouseReleased then DButton.OnMouseReleased(self, mcode) end
		end
		btn.DoClick = function()
			surface.PlaySound(mouse_click)
			SetApp(appId)
		end
		return btn
	end

	MakeNavButton(sidebar, "loyalty")
	MakeNavButton(sidebar, "party")
	MakeNavButton(sidebar, "notes")
	MakeNavButton(sidebar, "taxation")
	MakeNavButton(sidebar, "warrants")
	MakeNavButton(sidebar, "criminal")
	MakeNavButton(sidebar, "citations")
	MakeNavButton(sidebar, "bail")
	MakeNavButton(sidebar, "detainees")

	local function DrawHeader(w, title, subtitle)
		draw.SimpleText(title, "MonarchOcman_Title", 8, 8, COLORS.text)
		if subtitle and subtitle ~= "" then
			draw.SimpleText(subtitle, "MonarchOcman_Small", 8, 28, COLORS.textDim)
		end
	end

	local function PaintLoyalty(self, w, h)
		DrawHeader(w, "Loyalty Points", "Assign numeric loyalty scores")

		local citizens = BuildPlayerList()
		table.sort(citizens, function(a, b) return (a.loyalty_points or 0) > (b.loyalty_points or 0) end)

		local y = 50

		for i = 1, #citizens do
			local c = citizens[i]
			local rowH = 36
			local rx, rw = 8, w - 16

			if y + rowH < h then
				DrawPanel(rx, y, rw, rowH, COLORS.panel, true)

				draw.SimpleText(c.name, "MonarchOcman_Text", rx + 8, y + rowH / 2, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

				local pts = c.loyalty_points or 0
				draw.SimpleText(tostring(pts) .. " pts", "MonarchOcman_Text", rx + rw - 100, y + rowH / 2, COLORS.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

				if not self._tierButtons then self._tierButtons = {} end
				local btnKey = tostring(c.char_id or c.steamid) .. "_points"
				if not self._tierButtons[btnKey] then
					local btn = vgui.Create("DButton", self)
					btn:SetText("")
					btn:SetSize(70, 24)
					btn.Paint = function(b, bw, bh)
						local raised = not b:IsDown()
						DrawPanel(0, 0, bw, bh, COLORS.panel, raised)
						draw.SimpleText("Set", "MonarchOcman_Small", bw / 2, bh / 2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					end
					btn.OnMousePressed = function(b, mcode)
						if DButton and DButton.OnMousePressed then DButton.OnMousePressed(b, mcode) end
					end
					btn.OnMouseReleased = function(b, mcode)
						if DButton and DButton.OnMouseReleased then DButton.OnMouseReleased(b, mcode) end
					end
					btn.DoClick = function()
						surface.PlaySound(mouse_click)

						local pop = vgui.Create("DFrame")
						pop:SetTitle("")
						pop:SetSize(280, 150)
						pop:Center()
						pop:MakePopup()
						pop:SetDraggable(true)
						pop:ShowCloseButton(false)
						pop.Paint = function(_, pw, ph)
							DrawPanel(0, 0, pw, ph, COLORS.panel, true)
							surface.SetDrawColor(0, 0, 128, 255)
							surface.DrawRect(4, 4, pw - 8, 22)
							draw.SimpleText("Set Loyalty Points", "MonarchOcman_Sub", 12, 15, COLORS.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
						end

						local entry = vgui.Create("DTextEntry", pop)
						entry:SetPos(12, 40)
						entry:SetSize(pop:GetWide() - 24, 24)
						entry:SetNumeric(true)
						entry:SetText(tostring(pts))
						entry:SetFont("MonarchOcman_Text")
						entry:SetTextColor(COLORS.text)
						entry:SetPaintBackground(false)
						entry.Paint = function(e, ew, eh)
							DrawPanel(0, 0, ew, eh, COLORS.white, false)
							draw.SimpleText(e:GetText(), "MonarchOcman_Text", 4, eh / 2, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
						end

						local ok = vgui.Create("DButton", pop)
						ok:SetSize(80, 26)
						ok:SetPos(pop:GetWide() - 92, pop:GetTall() - 36)
						ok:SetText("")
						ok.Paint = function(b, bw, bh)
							local raised = not b:IsDown()
							DrawPanel(0, 0, bw, bh, COLORS.panel, raised)
							draw.SimpleText("OK", "MonarchOcman_Small", bw / 2, bh / 2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
						end
						ok.DoClick = function()
							surface.PlaySound(mouse_click)
							local val = tonumber(entry:GetText()) or 0
							val = math.Clamp(math.floor(val), 0, 65535)
							Monarch.Loyalty.UpdateLoyaltyPoints(c.char_id, val)
							pop:Close()
						end

						local cancel = vgui.Create("DButton", pop)
						cancel:SetSize(80, 26)
						cancel:SetPos(12, pop:GetTall() - 36)
						cancel:SetText("")
						cancel.Paint = function(b, bw, bh)
							local raised = not b:IsDown()
							DrawPanel(0, 0, bw, bh, COLORS.panel, raised)
							draw.SimpleText("Cancel", "MonarchOcman_Small", bw / 2, bh / 2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
						end
						cancel.DoClick = function()
							surface.PlaySound(mouse_click)
							pop:Close()
						end
					end
					self._tierButtons[btnKey] = btn
				end
				local btn = self._tierButtons[btnKey]
				btn:SetPos(rx + rw - 80, y + 6)
				btn:SetVisible(true)
			else
				local hideKey = tostring(c.char_id or c.steamid) .. "_points"
				if self._tierButtons and self._tierButtons[hideKey] then
					self._tierButtons[hideKey]:SetVisible(false)
				end
			end

			y = y + rowH + 4
		end
	end

	local function PaintParty(self, w, h)
		DrawHeader(w, "Party Membership", "Manage party member standings")

		local citizens = BuildPlayerList()
		table.sort(citizens, function(a, b) return (a.party_tier or 0) > (b.party_tier or 0) end)

		local y = 50

		for i = 1, #citizens do
			local c = citizens[i]
			local rowH = 36
			local rx, rw = 8, w - 16

			if y + rowH < h then
				DrawPanel(rx, y, rw, rowH, COLORS.panel, true)

				draw.SimpleText(c.name, "MonarchOcman_Text", rx + 8, y + rowH / 2, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

				local tier = c.party_tier or 0
				local tierName = Monarch.Loyalty.GetPartyTierName(tier)
				local tierCol = Monarch.Loyalty.GetPartyTierColor(tier)
				draw.SimpleText(tierName, "MonarchOcman_Text", rx + rw - 100, y + rowH / 2, tierCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

				if not self._partyButtons then self._partyButtons = {} end
				local btnKey = tostring(c.char_id or c.steamid) .. "_party"
				if not self._partyButtons[btnKey] then
					local btn = vgui.Create("DButton", self)
					btn:SetText("")
					btn:SetSize(70, 24)
					btn.Paint = function(b, bw, bh)
						local raised = not b:IsDown()
						DrawPanel(0, 0, bw, bh, COLORS.panel, raised)
						draw.SimpleText("Change", "MonarchOcman_Small", bw / 2, bh / 2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					end
					btn.OnMousePressed = function(b, mcode)
						if DButton and DButton.OnMousePressed then DButton.OnMousePressed(b, mcode) end
					end
					btn.OnMouseReleased = function(b, mcode)
						if DButton and DButton.OnMouseReleased then DButton.OnMouseReleased(b, mcode) end
					end
					btn.DoClick = function()
						surface.PlaySound(mouse_click)
						local menu = DermaMenu()
						for t = 0, 4 do
							menu:AddOption(Monarch.Loyalty.GetPartyTierName(t), function()
								Monarch.Loyalty.UpdatePartyTier(c.char_id, t)
							end):SetIcon("icon16/flag_red.png")
						end
						menu:Open()
					end
					self._partyButtons[btnKey] = btn
				end
				local btn = self._partyButtons[btnKey]
				btn:SetPos(rx + rw - 80, y + 6)
				btn:SetVisible(true)
			else
				local hideKey = tostring(c.char_id or c.steamid) .. "_party"
				if self._partyButtons and self._partyButtons[hideKey] then
					self._partyButtons[hideKey]:SetVisible(false)
				end
			end

			y = y + rowH + 4
		end
	end

	local function PaintNotes(self, w, h)
		DrawHeader(w, "Occupant Notes", "Record observations and notes on citizens")

		local citizens = BuildPlayerList()
		table.sort(citizens, function(a, b) return (a.name or "") < (b.name or "") end)

		local selectedCitizen
		if SELECTED_CITIZEN then
			for _, c in ipairs(citizens) do
				if c.char_id == SELECTED_CITIZEN then
					selectedCitizen = c
					break
				end
			end
		end

		local listW = math.floor(w * 0.4)
		local y = 50

		for i = 1, #citizens do
			local c = citizens[i]
			local rowH = 28
			local rx, rw = 8, listW - 12

			if y + rowH < h then
				local isSelected = (SELECTED_CITIZEN == c.char_id)
				DrawPanel(rx, y, rw, rowH, isSelected and COLORS.accent2 or COLORS.panel, not isSelected)

				local textCol = isSelected and COLORS.white or COLORS.text
				draw.SimpleText(c.name, "MonarchOcman_Text", rx + 6, y + rowH / 2, textCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

				if not self._noteButtons then self._noteButtons = {} end
				if not self._noteButtons[c.char_id] then
					local btn = vgui.Create("DButton", self)
					btn:SetText("")
					btn.Paint = function() end
					btn.DoClick = function()
						SELECTED_CITIZEN = c.char_id
						surface.PlaySound(mouse_click)
					end
					self._noteButtons[c.char_id] = btn
				end
				local btn = self._noteButtons[c.char_id]
				btn:SetPos(rx, y)
				btn:SetSize(rw, rowH)
				btn:SetVisible(true)
			else
				if self._noteButtons and self._noteButtons[c.char_id] then
					self._noteButtons[c.char_id]:SetVisible(false)
				end
			end

			y = y + rowH + 2
		end

		if selectedCitizen then
			local noteX = listW + 8
			local noteW = w - listW - 16
			local noteH = h - 60

			DrawPanel(noteX, 50, noteW, noteH, COLORS.white, false)

			draw.SimpleText("Notes on: " .. selectedCitizen.name, "MonarchOcman_Text", noteX + 8, 58, COLORS.text)

			if not self._noteEntry then
				self._noteEntry = vgui.Create("DTextEntry", self)
				self._noteEntry:SetMultiline(true)
				self._noteEntry:SetFont("MonarchOcman_Text")
				self._noteEntry:SetTextColor(COLORS.text)
				self._noteEntry:SetPaintBackground(false)
			end
			self._noteEntry:SetPos(noteX + 8, 80)
			self._noteEntry:SetSize(noteW - 16, noteH - 70)
			if self._noteLoadedFor ~= SELECTED_CITIZEN then
				self._noteEntry:SetText(selectedCitizen.note or "")
				self._noteLoadedFor = SELECTED_CITIZEN
			end
			self._noteEntry:SetVisible(true)

			if not self._noteSaveBtn then
				self._noteSaveBtn = vgui.Create("DButton", self)
				self._noteSaveBtn:SetText("")
				self._noteSaveBtn:SetSize(100, 26)
				self._noteSaveBtn.Paint = function(b, bw, bh)
					local raised = not b:IsDown()
					DrawPanel(0, 0, bw, bh, COLORS.panel, raised)
					draw.SimpleText("Save Note", "MonarchOcman_Small", bw / 2, bh / 2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
				self._noteSaveBtn.OnMousePressed = function(b, mcode)
					if DButton and DButton.OnMousePressed then DButton.OnMousePressed(b, mcode) end
				end
				self._noteSaveBtn.OnMouseReleased = function(b, mcode)
					if DButton and DButton.OnMouseReleased then DButton.OnMouseReleased(b, mcode) end
				end
				self._noteSaveBtn.DoClick = function()
					surface.PlaySound(mouse_click)
					if SELECTED_CITIZEN and self._noteEntry then
						Monarch.Loyalty.UpdateNote(SELECTED_CITIZEN, self._noteEntry:GetValue())
					end
				end
			end
			self._noteSaveBtn:SetPos(noteX + noteW - 110, 50)
			self._noteSaveBtn:SetVisible(true)
		else
			if self._noteEntry then self._noteEntry:SetVisible(false) end
			if self._noteSaveBtn then self._noteSaveBtn:SetVisible(false) end
		end
	end

	local function PaintTaxation(self, w, h)
		DrawHeader(w, "Taxation Management", "Adjust tax rates for citizens")

		local citizens = BuildPlayerList()
		table.sort(citizens, function(a, b) return (a.tax_rate or 0.3) > (b.tax_rate or 0.3) end)
		self._taxValues = self._taxValues or {}

		local y = 50
		if self._generalTaxRate == nil then
			local avg = 0
			for _, c in ipairs(citizens) do avg = avg + (c.tax_rate or 0) end
			self._generalTaxRate = (#citizens > 0) and (avg / #citizens) or 0.30
		end
		if not self._generalTaxSlider then
			self._generalTaxSlider = vgui.Create("DNumSlider", self)
			self._generalTaxSlider:SetMin(0)
			self._generalTaxSlider:SetMax(100)
			self._generalTaxSlider:SetDecimals(0)
			self._generalTaxSlider.Label:SetVisible(false)
			self._generalTaxSlider.TextArea:SetVisible(false)
			self._generalTaxSlider.Slider.Paint = function(s, sw, sh)
				DrawPanel(0, 0, sw, sh, COLORS.white, false)
				local knobW = 12
				local knobX = (self._generalTaxSlider:GetValue() / 100) * (sw - knobW)
				DrawPanel(knobX, 2, knobW, sh - 4, COLORS.panel, true)
			end
			if self._generalTaxSlider.Slider and self._generalTaxSlider.Slider.Knob then
				self._generalTaxSlider.Slider.Knob.Paint = function(k, kw, kh)
					DrawPanel(0, 0, kw, kh, COLORS.panel, true)
				end
			end
			self._generalTaxSlider.OnValueChanged = function(_, val)
				local rate = val / 100
				self._generalTaxRate = rate
				for _, c in ipairs(citizens) do
					Monarch.Loyalty.UpdateTaxRate(c.char_id, rate)
				end
			end
		end
		self._generalTaxSlider:SetPos(160, y + 4)
		self._generalTaxSlider:SetSize(math.min(300, w - 180), 20)
		self._generalTaxSlider:SetVisible(true)
		if not (self._generalTaxSlider.Slider and self._generalTaxSlider.Slider.Knob and self._generalTaxSlider.Slider.Knob.Depressed) then
			self._generalTaxSlider:SetValue((self._generalTaxRate or 0.30) * 100)
		end
		draw.SimpleText("General Taxation", "MonarchOcman_Text", 8, y + 10, COLORS.text)
		y = y + 36
		draw.SimpleText("Individual Taxation", "MonarchOcman_Sub", 8, y + 8, COLORS.textDim)
		y = y + 28

		for i = 1, #citizens do
			local c = citizens[i]
			local rowH = 40
			local rx, rw = 8, w - 16

			if y + rowH < h then
				DrawPanel(rx, y, rw, rowH, COLORS.panel, true)

				draw.SimpleText(c.name, "MonarchOcman_Text", rx + 8, y + 12, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

				local taxRate = c.tax_rate or 0.30
				local taxText = string.format("%.0f%%", taxRate * 100)
				draw.SimpleText("Tax Rate: " .. taxText, "MonarchOcman_Small", rx + 8, y + 26, COLORS.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

				if not self._taxSliders then self._taxSliders = {} end
				local sliderKey = tostring(c.char_id or c.steamid)
				local slider = self._taxSliders[sliderKey]
				if not IsValid(slider) then
					slider = vgui.Create("DNumSlider", self)
					slider:SetMin(0)
					slider:SetMax(100)
					slider:SetDecimals(0)
					slider:SetSize(200, 20)
					slider.Label:SetVisible(false)
					slider.TextArea:SetVisible(false)
					slider.Slider.Paint = function(s, sw, sh)
						DrawPanel(0, 0, sw, sh, COLORS.white, false)
						local knobW = 12
						local knobX = (slider:GetValue() / 100) * (sw - knobW)
						DrawPanel(knobX, 2, knobW, sh - 4, COLORS.panel, true)
					end
					if slider.Slider and slider.Slider.Knob then
						slider.Slider.Knob.Paint = function(k, kw, kh)
							DrawPanel(0, 0, kw, kh, COLORS.panel, true)
						end
					end
					slider.OnValueChanged = function(s, val)
						self._taxValues[sliderKey] = val / 100
						Monarch.Loyalty.UpdateTaxRate(c.char_id, val / 100)
					end
					self._taxSliders[sliderKey] = slider
				end
				slider:SetPos(rx + rw - 210, y + 8)
				slider:SetVisible(true)
				local current = self._taxValues[sliderKey] or taxRate
				local isHeld = slider.Slider and slider.Slider.Knob and slider.Slider.Knob.Depressed
				if not isHeld then
					slider:SetValue(current * 100)
				end
			else
				if self._taxSliders and self._taxSliders[sliderKey] then
					self._taxSliders[sliderKey]:SetVisible(false)
				end
			end

			y = y + rowH + 4
		end
	end

	local function PaintWarrants(self, w, h)
		DrawHeader(w, "Active Warrants", "Manage outstanding warrants")

		if self._warrantRevokeBtns then
			for _, b in pairs(self._warrantRevokeBtns) do
				if IsValid(b) then b:SetVisible(frame._active == "warrants") end
			end
		end
		if frame._active ~= "warrants" then return end

		local warrants = Monarch.Police.Warrants.List or {}
		local activeWarrants = {}
		for _, warrant in ipairs(warrants) do
			if warrant.active then
				table.insert(activeWarrants, warrant)
			end
		end
		table.sort(activeWarrants, function(a, b) return (a.issued_time or 0) > (b.issued_time or 0) end)
		local seenButtons = {}

		if not self._warrantForm then
			local form = vgui.Create("DPanel", self)
			form:SetSize(w - 16, 60)
			form:SetPos(8, 50)
			form.Paint = function() end
			form._char = vgui.Create("DComboBox", form)
			form._char:SetPos(0, 0)
			form._char:SetSize(220, 20)
			form._char:SetValue("Select character")
			form._char.OnGetFocus = function(box)
				PopulateCharDropdown(box)
			end
			form._char.OnSelect = function(_, _, _, data)
				form._selected = data
			end
			form._reason = vgui.Create("DTextEntry", form)
			form._reason:SetPos(0, 24)
			form._reason:SetSize(238, 20)
			form._reason:SetPlaceholderText("Reason")
			form._severity = vgui.Create("DComboBox", form)
			form._severity:SetPos(246, 0)
			form._severity:SetSize(110, 20)
			form._severity:SetValue("Severity")
			form._severity:AddChoice("misdemeanor")
			form._severity:AddChoice("felony")
			form._severity:AddChoice("capital")
			form._severity.OnSelect = function(_, _, text)
				form._selectedSeverity = text
			end
			form._issue = vgui.Create("DButton", form)
			form._issue:SetPos(246, 24)
			form._issue:SetSize(110, 20)
			form._issue:SetText("Issue Warrant")
			form._issue.DoClick = function()
				local sel = form._selected
				if not sel then return end
				local cid = tostring(sel.id)
				local cname = sel.name or "Unknown"
				local reason = form._reason:GetValue() ~= "" and form._reason:GetValue() or "Warrant"
				local severity = form._selectedSeverity or form._severity:GetOptionText(form._severity:GetSelectedID() or 0) or "misdemeanor"
				net.Start("Monarch.Police.Warrants.IssueWarrant")
					net.WriteString(cid)
					net.WriteString(cname)
					net.WriteString(reason)
					net.WriteString(severity)
				net.SendToServer()
			end
			PopulateCharDropdown(form._char)
			self._warrantForm = form
		end
		self._warrantForm:SetVisible(frame._active == "warrants")

		local y = 50
		if IsValid(self._warrantForm) then
			y = self._warrantForm:GetY() + self._warrantForm:GetTall() + 8
		end
		for i = 1, #activeWarrants do
			local warrant = activeWarrants[i]
			local rowH = 80
			local rx, rw = 8, w - 16

			if y + rowH < h then
				DrawPanel(rx, y, rw, rowH, COLORS.panel, true)

				draw.SimpleText(warrant.char_name or "Unknown", "MonarchOcman_Text", rx + 8, y + 8, COLORS.red, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("Reason: " .. (warrant.reason or "N/A"), "MonarchOcman_Small", rx + 8, y + 24, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("Issued by: " .. (warrant.issued_by or "Unknown"), "MonarchOcman_Small", rx + 8, y + 38, COLORS.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("Severity: " .. (warrant.severity or "misdemeanor"), "MonarchOcman_Small", rx + 8, y + 52, COLORS.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("Arrests: " .. (warrant.arrests or 0), "MonarchOcman_Small", rx + 8, y + 66, COLORS.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

				if not self._warrantRevokeBtns then self._warrantRevokeBtns = {} end
				if not self._warrantPending then self._warrantPending = {} end
				local key = tostring(warrant.char_id)
				seenButtons[key] = true
				if not self._warrantPending[key] then
					local btn = self._warrantRevokeBtns[key]
					if not IsValid(btn) then
						btn = vgui.Create("DButton", self)
						btn:SetText("Revoke")
						btn:SetSize(70, 22)
						btn.DoClick = function()
							net.Start("Monarch.Police.Warrants.RevokeWarrant")
								net.WriteString(warrant.char_id)
							net.SendToServer()
							self._warrantPending[key] = true
							btn:SetVisible(false)
						end
						self._warrantRevokeBtns[key] = btn
					end
					btn:SetPos(rx + rw - 80, y + rowH - 26)
					btn:SetVisible(true)
				end
			end

			y = y + rowH + 4
		end

		if self._warrantRevokeBtns then
			for key, btn in pairs(self._warrantRevokeBtns) do
				if not seenButtons[key] and IsValid(btn) then
					btn:SetVisible(false)
				end
			end
		end
		if self._warrantPending then
			for key in pairs(self._warrantPending) do
				if not seenButtons[key] then
					self._warrantPending[key] = nil
				end
			end
		end

		if #activeWarrants == 0 then
			draw.SimpleText("No active warrants", "MonarchOcman_Text", w / 2, 100, COLORS.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	end

	local function PaintCriminal(self, w, h)
		DrawHeader(w, "Criminal Records", "View criminal history database")

		local records = Monarch.Police.Criminal.Records or {}
		table.sort(records, function(a, b) return (a.arrest_count or 0) > (b.arrest_count or 0) end)

		local y = 50
		for i = 1, #records do
			local rec = records[i]
			local rowH = 90
			local rx, rw = 8, w - 16

			if y + rowH < h then
				DrawPanel(rx, y, rw, rowH, COLORS.panel, true)

				draw.SimpleText(rec.char_name or "Unknown", "MonarchOcman_Text", rx + 8, y + 8, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("Arrests: " .. (rec.arrest_count or 0), "MonarchOcman_Small", rx + 8, y + 24, COLORS.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("Convictions: " .. (rec.conviction_count or 0), "MonarchOcman_Small", rx + 8, y + 38, COLORS.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

				local chargeCount = #(rec.active_charges or {})
				draw.SimpleText("Active Charges: " .. chargeCount, "MonarchOcman_Small", rx + 8, y + 52, chargeCount > 0 and COLORS.red or COLORS.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

				if chargeCount > 0 then
					local chargeList = table.concat(rec.active_charges, ", ")
					if string.len(chargeList) > 50 then
						chargeList = string.sub(chargeList, 1, 50) .. "..."
					end
					draw.SimpleText(chargeList, "MonarchOcman_Small", rx + 8, y + 66, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				end
			end

			y = y + rowH + 4
		end

		if #records == 0 then
			draw.SimpleText("No criminal records", "MonarchOcman_Text", w / 2, 100, COLORS.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	end

	local function PaintCitations(self, w, h)
		DrawHeader(w, "Citations", "Manage issued citations and fines")

		local citations = Monarch.Police.Citations.List or {}
		table.sort(citations, function(a, b)
			if a.paid ~= b.paid then return not a.paid end
			return (a.issued_time or 0) > (b.issued_time or 0)
		end)

		if not self._citationForm then
			local form = vgui.Create("DPanel", self)
			form:SetSize(w - 16, 60)
			form:SetPos(8, 50)
			form.Paint = function() end
			form._char = vgui.Create("DComboBox", form)
			form._char:SetPos(0, 0)
			form._char:SetSize(220, 20)
			form._char:SetValue("Select character")
			form._char.OnGetFocus = function(box)
				PopulateCharDropdown(box)
			end
			form._char.OnSelect = function(_, _, _, data)
				form._selected = data
			end
			form._violation = vgui.Create("DTextEntry", form)
			form._violation:SetPos(0, 24)
			form._violation:SetSize(238, 20)
			form._violation:SetPlaceholderText("Violation")
			form._fine = vgui.Create("DNumberWang", form)
			form._fine:SetPos(246, 0)
			form._fine:SetSize(90, 20)
			form._fine:SetMin(0)
			form._fine:SetMax(1000000)
			form._fine:SetValue(100)
			form._notes = vgui.Create("DTextEntry", form)
			form._notes:SetPos(246, 24)
			form._notes:SetSize(200, 20)
			form._notes:SetPlaceholderText("Notes (optional)")
			form._issue = vgui.Create("DButton", form)
			form._issue:SetPos(452, 0)
			form._issue:SetSize(120, 44)
			form._issue:SetText("Issue Citation")
			form._issue.DoClick = function()
				local sel = form._selected
				if not sel then return end
				local cid = tostring(sel.id)
				local cname = sel.name or "Unknown"
				local violation = form._violation:GetValue() ~= "" and form._violation:GetValue() or "Violation"
				local fine = math.max(0, tonumber(form._fine:GetValue() or 0) or 0)
				local notes = form._notes:GetValue() or ""
				net.Start("Monarch.Police.Citations.IssueCitation")
					net.WriteString(cid)
					net.WriteString(cname)
					net.WriteString(violation)
					net.WriteUInt(fine, 32)
					net.WriteString(notes)
				net.SendToServer()
			end
			PopulateCharDropdown(form._char)
			self._citationForm = form
		end
		self._citationForm:SetVisible(frame._active == "citations")

		local y = 50
		local seenMarkBtns = {}
		if IsValid(self._citationForm) then
			y = self._citationForm:GetY() + self._citationForm:GetTall() + 8
		end
		for i = 1, #citations do
			local c = citations[i]
			local rowH = 70
			local rx, rw = 8, w - 16

			if y + rowH < h then
				DrawPanel(rx, y, rw, rowH, COLORS.panel, true)

				local statusColor = c.paid and COLORS.green or COLORS.red
				draw.SimpleText(c.char_name or "Unknown", "MonarchOcman_Text", rx + 8, y + 8, statusColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("Fine: $" .. (c.fine_amount or 0), "MonarchOcman_Small", rx + 8, y + 24, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("Violation: " .. (c.violation or "N/A"), "MonarchOcman_Small", rx + 8, y + 38, COLORS.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("Status: " .. (c.paid and "PAID" or "OUTSTANDING"), "MonarchOcman_Small", rx + 8, y + 52, statusColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

				if not c.paid then
					if not self._citationMarkBtns then self._citationMarkBtns = {} end
					if not self._citationPending then self._citationPending = {} end
					local key = c.id or (c.char_id .. "_" .. tostring(i))
					seenMarkBtns[key] = true
					if not self._citationPending[key] then
						local btn = self._citationMarkBtns[key]
						if not IsValid(btn) then
							btn = vgui.Create("DButton", self)
							btn:SetText("Mark Paid")
							btn:SetSize(80, 22)
							btn.DoClick = function()
								net.Start("Monarch.Police.Citations.MarkPaid")
									net.WriteString(c.id or "")
									net.WriteString(c.char_id or "")
								net.SendToServer()
								self._citationPending[key] = true
								btn:SetVisible(false)
							end
							self._citationMarkBtns[key] = btn
						end
						btn:SetPos(rx + rw - 90, y + rowH - 26)
						btn:SetVisible(true)
					end
				elseif self._citationMarkBtns then
					local key = c.id or (c.char_id .. "_" .. tostring(i))
					local btn = self._citationMarkBtns[key]
					if IsValid(btn) then btn:SetVisible(false) end
					if self._citationPending then self._citationPending[key] = nil end
				end
			end

			y = y + rowH + 4
		end

		if self._citationMarkBtns then
			for key, btn in pairs(self._citationMarkBtns) do
				if not seenMarkBtns[key] and IsValid(btn) then
					btn:SetVisible(false)
				end
			end
		end
		if self._citationPending then
			for key in pairs(self._citationPending) do
				if not seenMarkBtns[key] then
					self._citationPending[key] = nil
				end
			end
		end

		if #citations == 0 then
			draw.SimpleText("No citations issued", "MonarchOcman_Text", w / 2, 100, COLORS.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	end

	local function PaintBail(self, w, h)
		DrawHeader(w, "Bail Management", "Track bail amounts and status")

		local records = Monarch.Police.Bail.Records or {}
		table.sort(records, function(a, b)
			if a.posted ~= b.posted then return not a.posted end
			return (a.bail_amount or 0) > (b.bail_amount or 0)
		end)

		local y = 50
		for i = 1, #records do
			local rec = records[i]
			local rowH = 80
			local rx, rw = 8, w - 16

			if y + rowH < h then
				DrawPanel(rx, y, rw, rowH, COLORS.panel, true)

				local statusColor = rec.posted and COLORS.green or COLORS.red
				draw.SimpleText(rec.char_name or "Unknown", "MonarchOcman_Text", rx + 8, y + 8, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("Bail Amount: $" .. (rec.bail_amount or 0), "MonarchOcman_Small", rx + 8, y + 24, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("Status: " .. (rec.posted and "POSTED" or "UNPAID"), "MonarchOcman_Small", rx + 8, y + 38, statusColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("Set by: " .. (rec.set_by or "Unknown"), "MonarchOcman_Small", rx + 8, y + 52, COLORS.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

				if rec.posted and rec.posted_by then
					draw.SimpleText("Posted by: " .. rec.posted_by, "MonarchOcman_Small", rx + 8, y + 66, COLORS.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				end
			end

			y = y + rowH + 4
		end

		if #records == 0 then
			draw.SimpleText("No bail records", "MonarchOcman_Text", w / 2, 100, COLORS.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	end

	local function PaintDetainees(self, w, h)
		DrawHeader(w, "Detention", "View currently detained individuals")

		local detainees = Monarch.Police.Detainees.List or {}
		local active = {}
		for _, det in ipairs(detainees) do
			if not det.released then
				table.insert(active, det)
			end
		end
		table.sort(active, function(a, b) return (a.arrest_time or 0) > (b.arrest_time or 0) end)

		if not self._arrestForm then

			net.Start("Monarch.Police.Detainees.GetCharges")
			net.SendToServer()

			local form = vgui.Create("DPanel", self)
			form:SetSize(w - 16, 90)
			form:SetPos(8, 50)
			form.Paint = function() end

			form._chargeLabel = vgui.Create("DLabel", form)
			form._chargeLabel:SetPos(0, 0)
			form._chargeLabel:SetSize(60, 20)
			form._chargeLabel:SetText("Charge:")
			form._chargeLabel:SetTextColor(Color(255, 255, 255))

			form._charge = vgui.Create("DComboBox", form)
			form._charge:SetPos(60, 0)
			form._charge:SetSize(200, 20)
			form._charge:SetValue("Select Charge")
			form._selectedTime = 600

			timer.Simple(0.5, function()
				if not IsValid(form._charge) then return end
				for _, charge in ipairs(Monarch.Police.Detainees.Charges or {}) do
					local minutes = math.floor(charge.time / 60)
					form._charge:AddChoice(charge.name .. " (" .. minutes .. " min)", charge.time)
				end
			end)

			form._charge.OnSelect = function(panel, index, value, data)
				form._selectedTime = data or 600
				if string.find(value, "Custom") then
					form._timeEntry:SetVisible(true)
				else
					form._timeEntry:SetVisible(false)
				end
			end

			form._timeLabel = vgui.Create("DLabel", form)
			form._timeLabel:SetPos(0, 25)
			form._timeLabel:SetSize(60, 20)
			form._timeLabel:SetText("Time:")
			form._timeLabel:SetTextColor(Color(255, 255, 255))

			form._timeEntry = vgui.Create("DTextEntry", form)
			form._timeEntry:SetPos(60, 25)
			form._timeEntry:SetSize(80, 20)
			form._timeEntry:SetPlaceholderText("Minutes")
			form._timeEntry:SetNumeric(true)
			form._timeEntry:SetVisible(false)
			form._timeEntry.OnChange = function(entry)
				local mins = tonumber(entry:GetValue()) or 10
				form._selectedTime = mins * 60
			end

			form._reasonLabel = vgui.Create("DLabel", form)
			form._reasonLabel:SetPos(0, 50)
			form._reasonLabel:SetSize(60, 20)
			form._reasonLabel:SetText("Details:")
			form._reasonLabel:SetTextColor(Color(255, 255, 255))

			form._reason = vgui.Create("DTextEntry", form)
			form._reason:SetPos(60, 50)
			form._reason:SetSize(200, 20)
			form._reason:SetPlaceholderText("Additional details")

			form._arrest = vgui.Create("DButton", form)
			form._arrest:SetPos(270, 0)
			form._arrest:SetSize(140, 70)
			form._arrest:SetText("Detain Cuffed Target")
			form._arrest.DoClick = function()
				local tr = LocalPlayer():GetEyeTrace()
				local target = IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.HitPos:DistToSqr(LocalPlayer():EyePos()) < (120 * 120) and tr.Entity
				if not target or not target:GetNWBool("MonarchCuffed", false) then return end
				local char = target.MonarchActiveChar or {}
				local cid = char.id or target:GetNWString("MonarchCharID", "") or ""
				local cname = char.name or target:Nick()
				if cid == "" then return end

				local chargeText, chargeTime = form._charge:GetSelected()
				if not chargeText or chargeText == "Select Charge" then return end

				local details = form._reason:GetValue()
				local reason = chargeText
				if details ~= "" then
					reason = reason .. " - " .. details
				end

				local sentenceTime = form._selectedTime or 600

				net.Start("Monarch.Police.Detainees.Arrest")
					net.WriteString(tostring(cid))
					net.WriteString(cname)
					net.WriteString(reason)
					net.WriteUInt(sentenceTime, 32)
				net.SendToServer()
			end
			self._arrestForm = form
		end
		self._arrestForm:SetVisible(frame._active == "detainees")

		local y = 50
		if IsValid(self._arrestForm) then
			y = self._arrestForm:GetY() + self._arrestForm:GetTall() + 8
		end
		for i = 1, #active do
			local det = active[i]
			local rowH = 100
			local rx, rw = 8, w - 16

			if y + rowH < h then
				DrawPanel(rx, y, rw, rowH, COLORS.panel, true)

				draw.SimpleText(det.char_name or "Unknown", "MonarchOcman_Text", rx + 8, y + 8, COLORS.red, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("Reason: " .. (det.reason or "N/A"), "MonarchOcman_Small", rx + 8, y + 24, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText("Arrested by: " .. (det.arrested_by or "Unknown"), "MonarchOcman_Small", rx + 8, y + 38, COLORS.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

				if det.release_time then
					local remaining = det.release_time - os.time()
					if remaining > 0 then
						local mins = math.floor(remaining / 60)
						local secs = remaining % 60
						draw.SimpleText("Time Remaining: " .. mins .. "m " .. secs .. "s", "MonarchOcman_Small", rx + 8, y + 52, COLORS.green, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					else
						draw.SimpleText("Time Remaining: Pending Release", "MonarchOcman_Small", rx + 8, y + 52, COLORS.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
					end
				end

				local notes = det.processing_notes or ""
				if notes ~= "" then
					if string.len(notes) > 50 then
						notes = string.sub(notes, 1, 50) .. "..."
					end
					draw.SimpleText("Notes: " .. notes, "MonarchOcman_Small", rx + 8, y + 66, COLORS.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				else
					draw.SimpleText("Notes: None", "MonarchOcman_Small", rx + 8, y + 66, COLORS.textFaint, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				end
			end

			y = y + rowH + 4
		end

		if #active == 0 then
			draw.SimpleText("No detainees", "MonarchOcman_Text", w / 2, 100, COLORS.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	end

	local view = vgui.Create("DPanel", content)
	view:Dock(FILL)
	view:DockMargin(4, 4, 4, 4)
	view.Paint = function(self, w, h)

		if frame._active == "loyalty" then
			if self._partyButtons then for _, c in pairs(self._partyButtons) do if IsValid(c) then c:SetVisible(false) end end end
			if self._noteButtons then for _, c in pairs(self._noteButtons) do if IsValid(c) then c:SetVisible(false) end end end
			if IsValid(self._noteEntry) then self._noteEntry:SetVisible(false) end
			if IsValid(self._noteSaveBtn) then self._noteSaveBtn:SetVisible(false) end
			if self._taxSliders then for _, c in pairs(self._taxSliders) do if IsValid(c) then c:SetVisible(false) end end end
			if IsValid(self._generalTaxSlider) then self._generalTaxSlider:SetVisible(false) end
		elseif frame._active == "party" then
			if self._tierButtons then for _, c in pairs(self._tierButtons) do if IsValid(c) then c:SetVisible(false) end end end
			if self._noteButtons then for _, c in pairs(self._noteButtons) do if IsValid(c) then c:SetVisible(false) end end end
			if IsValid(self._noteEntry) then self._noteEntry:SetVisible(false) end
			if IsValid(self._noteSaveBtn) then self._noteSaveBtn:SetVisible(false) end
			if self._taxSliders then for _, c in pairs(self._taxSliders) do if IsValid(c) then c:SetVisible(false) end end end
			if IsValid(self._generalTaxSlider) then self._generalTaxSlider:SetVisible(false) end
		elseif frame._active == "notes" then
			if self._tierButtons then for _, c in pairs(self._tierButtons) do if IsValid(c) then c:SetVisible(false) end end end
			if self._partyButtons then for _, c in pairs(self._partyButtons) do if IsValid(c) then c:SetVisible(false) end end end
			if self._taxSliders then for _, c in pairs(self._taxSliders) do if IsValid(c) then c:SetVisible(false) end end end
			if IsValid(self._generalTaxSlider) then self._generalTaxSlider:SetVisible(false) end
		elseif frame._active == "taxation" then
			if self._tierButtons then for _, c in pairs(self._tierButtons) do if IsValid(c) then c:SetVisible(false) end end end
			if self._partyButtons then for _, c in pairs(self._partyButtons) do if IsValid(c) then c:SetVisible(false) end end end
			if self._noteButtons then for _, c in pairs(self._noteButtons) do if IsValid(c) then c:SetVisible(false) end end end
			if IsValid(self._noteEntry) then self._noteEntry:SetVisible(false) end
			if IsValid(self._noteSaveBtn) then self._noteSaveBtn:SetVisible(false) end
		end

		if frame._active ~= "loyalty" then
			if self._tierButtons then for _, c in pairs(self._tierButtons) do if IsValid(c) then c:SetVisible(false) end end end
		end

		if frame._active ~= "warrants" then
			if IsValid(self._warrantForm) then self._warrantForm:SetVisible(false) end
			if self._warrantRevokeBtns then for _, b in pairs(self._warrantRevokeBtns) do if IsValid(b) then b:SetVisible(false) end end end
		end
		if frame._active ~= "citations" then
			if IsValid(self._citationForm) then self._citationForm:SetVisible(false) end
			if self._citationMarkBtns then for _, b in pairs(self._citationMarkBtns) do if IsValid(b) then b:SetVisible(false) end end end
		end
		if frame._active ~= "detainees" then
			if IsValid(self._arrestForm) then self._arrestForm:SetVisible(false) end
		end

		if frame._isLoading then
			local t = math.Clamp((CurTime() - frame._loadStart) / frame._loadDur, 0, 1)
			local e = EaseInOut(t)
			surface.SetDrawColor(COLORS.panel)
			surface.DrawRect(0, 0, w, h)
			draw.SimpleText("Loading...", "MonarchOcman_Title", w / 2, h / 2 - 24, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			local barW, barH = math.min(300, w * 0.4), 16
			local bx, by = (w - barW) / 2, h / 2 + 18
			DrawPanel(bx, by, barW, barH, COLORS.white, false)
			surface.SetDrawColor(COLORS.accent2)
			surface.DrawRect(bx + 2, by + 2, (barW - 4) * e, barH - 4)
			if t >= 1 then
				frame._isLoading = false
			end
			return
		end

		local active = frame._active
		local alpha = 255
		if frame._switching then
			local t = math.Clamp((CurTime() - frame._switchStart) / frame._switchDur, 0, 1)
			local e = EaseInOut(t)
			alpha = math.floor(255 * e)
			if t >= 1 then
				frame._switching = false
			end
		end
		surface.SetAlphaMultiplier(alpha / 255)
		if active == "loyalty" then
			PaintLoyalty(self, w, h)
		elseif active == "party" then
			PaintParty(self, w, h)
		elseif active == "notes" then
			PaintNotes(self, w, h)
		elseif active == "taxation" then
			PaintTaxation(self, w, h)
		elseif active == "warrants" then
			PaintWarrants(self, w, h)
		elseif active == "criminal" then
			PaintCriminal(self, w, h)
		elseif active == "citations" then
			PaintCitations(self, w, h)
		elseif active == "bail" then
			PaintBail(self, w, h)
		elseif active == "detainees" then
			PaintDetainees(self, w, h)
		end
		surface.SetAlphaMultiplier(1)
	end

	GLOBAL_FRAME = frame
	return frame
end

function ENT:Initialize()
end

net.Receive("Monarch.Police.Citations.NotifyIssued", function()
	local violation = net.ReadString()
	local fine = net.ReadUInt(32)
	local officer = net.ReadString()
	local msg = string.format("You received a citation for %s ($%d) from %s", violation ~= "" and violation or "a violation", fine or 0, officer ~= "" and officer or "an officer")
	if LocalPlayer and IsValid(LocalPlayer()) and LocalPlayer().Notify then
		LocalPlayer():Notify(msg .. ". You can pay this at the Police Station.")
	else
		chat.AddText(Color(200, 50, 50), msg)
	end
end)

net.Receive("Monarch_OcmanUI_Open", function()
	local frame = CreateFrame()
	if frame then
		frame:SetVisible(true)
		frame:MakePopup()
	end
end)
