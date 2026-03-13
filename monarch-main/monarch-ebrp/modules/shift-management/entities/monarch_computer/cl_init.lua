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
local CURRENT_APP = "factory"

local APP_DATA = {
	factory = { name = "Factory Data" },
	personnel = { name = "Personnel" },
	quotas = { name = "Quotas" },
	shift = { name = "Shift Manager" },
}

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
	if not _G.MONARCH_SHIFT_FONTS_CREATED then
		_G.MONARCH_SHIFT_FONTS_CREATED = true
		surface.CreateFont("MonarchShift_Title", {
			font = "Tahoma",
			size = 20,
			weight = 700,
			antialias = false,
		})
		surface.CreateFont("MonarchShift_Sub", {
			font = "Tahoma",
			size = 14,
			weight = 400,
			antialias = false,
		})
		surface.CreateFont("MonarchShift_Text", {
			font = "Tahoma",
			size = 13,
			weight = 400,
			antialias = false,
		})
		surface.CreateFont("MonarchShift_Small", {
			font = "Tahoma",
			size = 11,
			weight = 400,
			antialias = false,
		})
	end
end

local WORKER_STATUS = {}

local QUOTA_DATA = {}
local RECEPTACLE_DATA = {}
local FACTORY_LOGS = {}

local function InitializeQuotas()

	local recepticles = ents.FindByClass("rp_monarch_recepticle")
	for _, ent in ipairs(recepticles) do
		if IsValid(ent) then
			local name = ent:GetName() 
			if not QUOTA_DATA[name] then
				QUOTA_DATA[name] = {quota = 100, current = 0}
				FACTORY_LOGS[name] = {count = 0, status = "ACTIVE"}
			end
		end
	end
end

InitializeQuotas()

local function GetWorkers()
	local workers = {}
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and ply:GetWhitelist(1) > 1 then
			local char = ply.MonarchActiveChar or {}
			local name = ply:GetRPName() or ply:Nick()
			local teamName = team.GetName(ply:Team()) or "Unknown"

			local statusData = WORKER_STATUS[name] or {status = "working", notify = ""}

			table.insert(workers, {
				name = name,
				status = statusData.status,
				notify = statusData.notify,
				role = teamName,
				ply = ply
			})
		end
	end
	return workers
end

local function GetQuotas()
	local result = {}
	for name, data in pairs(QUOTA_DATA) do
		table.insert(result, {
			receptacle = name,
			quota = data.quota,
			current = data.current
		})
	end
	return result
end

local SHIFT_DATA = {
	is_active = false,
	start_time = nil,
	elapsed = 0
}

local function GetShiftInfo()
	return SHIFT_DATA
end

local function CreateFrame()
	if IsValid(GLOBAL_FRAME) then return GLOBAL_FRAME end

	local sw, sh = ScrW(), ScrH()
	local pad = 18
	local radius = 10
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
		surface.SetMaterial(Material("icon16/computer.png"))
		surface.DrawTexturedRect(4, 4, 16, 16)

		draw.SimpleText("Shift Management System", "MonarchShift_Sub", 26, h / 2, COLORS.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local closeBtn = vgui.Create("DButton", top)
	closeBtn:Dock(RIGHT)
	closeBtn:SetWide(22)
	closeBtn:DockMargin(0, 2, 2, 2)
	closeBtn:SetText("")
	closeBtn._down = false
	closeBtn.Paint = function(self, w, h)
			local raised = not self:IsDown()
		DrawPanel(0, 0, w, h, COLORS.panel, raised)
		draw.SimpleText("×", "MonarchShift_Title", w / 2, h / 2 - 2, COLORS.stroke, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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

	local function SetApp(nextApp)
		if frame._active == nextApp then return end
		frame._switchFrom = frame._active
		frame._switchTo = nextApp
		frame._switchStart = CurTime()
		frame._switching = true
		frame._active = nextApp
		CURRENT_APP = nextApp
	end

	local APP_ICONS = {
		factory = "icon16/cog.png",
		personnel = "icon16/group.png",
		quotas = "icon16/chart_bar.png",
		shift = "icon16/clock.png",
	}

	local function MakeNavButton(parent, appId)
		local btn = vgui.Create("DButton", parent)
		btn:Dock(TOP)
		btn:SetTall(42)
		btn:DockMargin(6, 6, 6, 0)
		btn:SetText("")
		btn._down = false
		btn.Paint = function(self, w, h)
			local isActive = (frame._active == appId)
			local raised = not (self:IsDown() or isActive)
			DrawPanel(0, 0, w, h, COLORS.panel, raised)

			local iconPath = APP_ICONS[appId] or "icon16/cog.png"
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(Material(iconPath))
			surface.DrawTexturedRect(6, h / 2 - 8, 16, 16)

			draw.SimpleText(APP_DATA[appId].name, "MonarchShift_Text", 36, h / 2, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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

	MakeNavButton(sidebar, "factory")
	MakeNavButton(sidebar, "personnel")
	MakeNavButton(sidebar, "quotas")
	MakeNavButton(sidebar, "shift")

	local function DrawHeader(w, title, subtitle)
		draw.SimpleText(title, "MonarchShift_Title", 8, 8, COLORS.text)
		if subtitle and subtitle ~= "" then
			draw.SimpleText(subtitle, "MonarchShift_Small", 8, 28, COLORS.textDim)
		end
	end

	local function PaintFactory(self, w, h)
		if self._btnStart then self._btnStart:SetVisible(false) end
		if self._btnEnd then self._btnEnd:SetVisible(false) end
		DrawHeader(w, "Factory Data", "View factory data linked to receptacles.")

		local quotas = GetQuotas()
		local y = 50

		for i = 1, #quotas do
			local q = quotas[i]
			local log = FACTORY_LOGS[q.receptacle] or {count = 0, status = "ACTIVE"}

			local rowH = 32
			local rx, rw = 8, w - 16
			DrawPanel(rx, y, rw, rowH, COLORS.panel, true)
			draw.SimpleText(q.receptacle, "MonarchShift_Text", rx + 8, y + rowH / 2, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(tostring(log.count), "MonarchShift_Text", rx + rw * 0.58, y + rowH / 2, COLORS.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			local progress = math.Clamp((q.current or 0) / math.max(q.quota or 1, 1), 0, 1)
			local sCol = (progress >= 1.0) and COLORS.green or (progress >= 0.5) and COLORS.yellow or COLORS.red
			draw.SimpleText(log.status, "MonarchShift_Text", rx + rw - 8, y + rowH / 2, sCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			y = y + rowH + 4
		end
	end

	local function CreateStatusDialog(worker)
		local dlg = vgui.Create("DFrame")
		dlg:SetTitle("")
		dlg:SetSize(400, 310)
		dlg:Center()
		dlg:MakePopup()
		dlg:SetDeleteOnClose(true)
		dlg:ShowCloseButton(false)
		dlg:SetDraggable(true)

		dlg.Paint = function(self, w, h)
			DrawPanel(0, 0, w, h, COLORS.panel, true)
		end

		local titleBar = vgui.Create("DPanel", dlg)
		titleBar:SetTall(26)
		titleBar:Dock(TOP)
		titleBar:DockMargin(3, 0, 3, 0)
		titleBar.Paint = function(self, w, h)
			surface.SetDrawColor(0, 0, 128, 255)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(Material("icon16/user_edit.png"))
			surface.DrawTexturedRect(4, 5, 16, 16)
			draw.SimpleText("Set Worker Status - " .. worker.name, "MonarchShift_Sub", 26, h / 2, COLORS.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		local closeBtn = vgui.Create("DButton", titleBar)
		closeBtn:Dock(RIGHT)
		closeBtn:SetWide(22)
		closeBtn:DockMargin(0, 2, 2, 2)
		closeBtn:SetText("")
		closeBtn.Paint = function(self, w, h)
			local raised = not self:IsDown()
			DrawPanel(0, 0, w, h, COLORS.panel, raised)
			draw.SimpleText("×", "MonarchShift_Title", w / 2, h / 2 - 2, COLORS.stroke, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		closeBtn.DoClick = function()
			surface.PlaySound(mouse_click)
			dlg:Close()
		end

		local contentPanel = vgui.Create("DPanel", dlg)
		contentPanel:Dock(FILL)
		contentPanel:DockMargin(8, 4, 8, 8)
		contentPanel.Paint = function(self, w, h) end

		local statusLabel = vgui.Create("DLabel", contentPanel)
		statusLabel:SetPos(0, 8)
		statusLabel:SetSize(50, 20)
		statusLabel:SetText("Status:")
		statusLabel:SetFont("MonarchShift_Text")
		statusLabel:SetTextColor(COLORS.text)

		local statusCombo = vgui.Create("DComboBox", contentPanel)
		statusCombo:SetPos(60, 8)
		statusCombo:SetSize(310, 22)
		statusCombo:SetFont("MonarchShift_Text")
		statusCombo.Paint = function(self, w, h)
			DrawPanel(0, 0, w, h, COLORS.white, false)
		end
		statusCombo:AddChoice("Working", "working")
		statusCombo:AddChoice("Break", "break")
		statusCombo:AddChoice("Training", "training")
		statusCombo:AddChoice("Lunch", "lunch")
		statusCombo:AddChoice("Off Duty", "off_duty")
		statusCombo:SetValue(worker.status or "working")

		local notifLabel = vgui.Create("DLabel", contentPanel)
		notifLabel:SetPos(0, 40)
		notifLabel:SetSize(100, 20)
		notifLabel:SetText("Notification:")
		notifLabel:SetFont("MonarchShift_Text")
		notifLabel:SetTextColor(COLORS.text)

		local notifText = vgui.Create("DTextEntry", contentPanel)
		notifText:SetPos(0, 65)
		notifText:SetSize(370, 125)
		notifText:SetMultiline(true)
		notifText:SetFont("MonarchShift_Text")
		notifText:SetPlaceholderText("Enter custom notification message (leave blank for no notification)...")
		notifText:SetValue(worker.notify or "")
		notifText.Paint = function(self, w, h)
			DrawPanel(0, 0, w, h, COLORS.white, false)
			self:DrawTextEntryText(COLORS.text, COLORS.accent, COLORS.text)
		end

		local sendBtn = vgui.Create("DButton", contentPanel)
		sendBtn:SetPos(0, 200)
		sendBtn:SetSize(370, 28)
		sendBtn:SetText("")
		sendBtn.Paint = function(self, w, h)
			local raised = not self:IsDown()
			DrawPanel(0, 0, w, h, COLORS.panel, raised)
			draw.SimpleText("Send", "MonarchShift_Text", w / 2, h / 2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		sendBtn.DoClick = function()
			local newStatus = statusCombo:GetValue()
			local notification = notifText:GetValue()

			net.Start("monarch_workshift_setworkerstatus")
			net.WriteString(worker.name)
			net.WriteString(newStatus)
			net.WriteString(notification)
			net.SendToServer()

			surface.PlaySound(mouse_click)
			dlg:Close()
		end

		return dlg
	end

	local function PaintPersonnel(self, w, h)
		if self._btnStart then self._btnStart:SetVisible(false) end
		if self._btnEnd then self._btnEnd:SetVisible(false) end
		local workers = GetWorkers()
		DrawHeader(w, "Personnel", string.format("Active personnel: %d", #workers))
		local y = 50

		if not self._workerRows then
			self._workerRows = {}
		end
		self._workerRows = {}

		for i = 1, #workers do
			local p = workers[i]
			local rowH = 32
			local rx, rw = 8, w - 16
			DrawPanel(rx, y, rw, rowH, COLORS.panel, true)
			draw.SimpleText(p.name, "MonarchShift_Text", rx + 8, y + rowH / 2, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(p.role, "MonarchShift_Small", rx + rw * 0.52, y + rowH / 2, COLORS.textFaint, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			local sCol = (p.status == "working") and COLORS.green or COLORS.yellow
			draw.SimpleText(string.upper(p.status), "MonarchShift_Text", rx + rw - 8, y + rowH / 2, sCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

			self._workerRows[i] = {
				x = rx, y = y, w = rw, h = rowH,
				worker = p
			}

			y = y + rowH + 4
		end
	end

	local original_paint = nil
	local function SetupPersonnelInteraction(view)
		view.OnMousePressed = function(self, mcode)
			if mcode == MOUSE_LEFT then
				local x, y = self:LocalCursorPos()
				if view._workerRows then
					for i, row in ipairs(view._workerRows) do
						if x >= row.x and x <= row.x + row.w and y >= row.y and y <= row.y + row.h then
							surface.PlaySound(mouse_click)
							CreateStatusDialog(row.worker)
							break
						end
					end
				end
			end
		end

		view.OnCursorMoved = function(self, x, y)
			if view._workerRows and frame._active == "personnel" then
				local hoverRow = false
				for i, row in ipairs(view._workerRows) do
					if x >= row.x and x <= row.x + row.w and y >= row.y and y <= row.y + row.h then
						hoverRow = true
						break
					end
				end
				if hoverRow then
					self:SetCursor("hand")
				else
					self:SetCursor("arrow")
				end
			end
		end
	end

	local function PaintQuotas(self, w, h)
		if self._btnStart then self._btnStart:SetVisible(false) end
		if self._btnEnd then self._btnEnd:SetVisible(false) end
		local quotas = GetQuotas()
		DrawHeader(w, "Quotas", "Current shift targets and receptacles")
		self._quotaAnim = self._quotaAnim or {}
		self._quotaButtons = self._quotaButtons or {}
		local y = 50
		for i = 1, #quotas do
			local q = quotas[i]
			local rowH = 50
			local rx, rw = 8, w - 16
			DrawPanel(rx, y, rw, rowH, COLORS.panel, true)
			draw.SimpleText(q.receptacle, "MonarchShift_Text", rx + 8, y + 12, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(string.format("%d / %d", q.current or 0, q.quota or 0), "MonarchShift_Small", rx + rw - 100, y + 12, COLORS.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			local progress = math.Clamp((q.current or 0) / math.max(q.quota or 1, 1), 0, 1)
			self._quotaAnim[i] = Lerp(FrameTime() * 8, self._quotaAnim[i] or 0, progress)
			local barX, barY = rx + 8, y + 28
			local barW, barH = rw - 80, 14

			DrawPanel(barX, barY, barW, barH, COLORS.white, false)

			surface.SetDrawColor(COLORS.accent2)
			surface.DrawRect(barX + 2, barY + 2, (barW - 4) * self._quotaAnim[i], barH - 4)

			local btnKey = q.receptacle .. "_setquota"
			if not self._quotaButtons[btnKey] then
				local btn = vgui.Create("DButton", self)
				btn:SetText("")
				btn:SetSize(60, 24)
				btn.Paint = function(b, bw, bh)
					local raised = not b:IsDown()
					DrawPanel(0, 0, bw, bh, COLORS.panel, raised)
					draw.SimpleText("Set", "MonarchShift_Small", bw / 2, bh / 2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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
						draw.SimpleText("Set Quota - " .. q.receptacle, "MonarchShift_Sub", 12, 15, COLORS.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					end

					local entry = vgui.Create("DTextEntry", pop)
					entry:SetPos(12, 40)
					entry:SetSize(pop:GetWide() - 24, 24)
					entry:SetNumeric(true)
					entry:SetText(tostring(q.quota or 0))
					entry:SetFont("MonarchShift_Text")
					entry:SetTextColor(COLORS.text)
					entry:SetPaintBackground(false)
					entry.Paint = function(e, ew, eh)
						DrawPanel(0, 0, ew, eh, COLORS.white, false)
						draw.SimpleText(e:GetText(), "MonarchShift_Text", 4, eh / 2, COLORS.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					end

					local ok = vgui.Create("DButton", pop)
					ok:SetSize(80, 26)
					ok:SetPos(pop:GetWide() - 92, pop:GetTall() - 36)
					ok:SetText("")
					ok.Paint = function(b, bw, bh)
						local raised = not b:IsDown()
						DrawPanel(0, 0, bw, bh, COLORS.panel, raised)
						draw.SimpleText("OK", "MonarchShift_Small", bw / 2, bh / 2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					end
					ok.DoClick = function()
						surface.PlaySound(mouse_click)
						local val = math.max(0, math.floor(tonumber(entry:GetText()) or 0))
						val = math.Clamp(val, 0, 65535)
						QUOTA_DATA[q.receptacle].quota = val
						net.Start("monarch_shift_setquota")
						net.WriteString(q.receptacle)
						net.WriteUInt(val, 16)
						net.SendToServer()
						pop:Close()
					end

					local cancel = vgui.Create("DButton", pop)
					cancel:SetSize(80, 26)
					cancel:SetPos(12, pop:GetTall() - 36)
					cancel:SetText("")
					cancel.Paint = function(b, bw, bh)
						local raised = not b:IsDown()
						DrawPanel(0, 0, bw, bh, COLORS.panel, raised)
						draw.SimpleText("Cancel", "MonarchShift_Small", bw / 2, bh / 2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					end
					cancel.DoClick = function()
						surface.PlaySound(mouse_click)
						pop:Close()
					end
				end
				self._quotaButtons[btnKey] = btn
			end
			local btn = self._quotaButtons[btnKey]
			btn:SetPos(rx + rw - 70, y + 13)
			btn:SetVisible(true)

			y = y + rowH + 4
		end
	end

	local function PaintShift(self, w, h)
		local shift = GetShiftInfo()
		DrawHeader(w, "Shift Manager", "Start and end shifts")

		if shift.is_active and shift.start_time then
			shift.elapsed = CurTime() - shift.start_time
		end
		local hrs = math.floor((shift.elapsed or 0) / 3600)
		local mins = math.floor(((shift.elapsed or 0) % 3600) / 60)
		local secs = math.floor((shift.elapsed or 0) % 60)

		local rx, rw = 8, w - 16
		DrawPanel(rx, 50, rw, 70, COLORS.panel, true)
		local statusText = shift.is_active and "ACTIVE" or "INACTIVE"
		local statusCol = shift.is_active and COLORS.green or COLORS.red
			draw.SimpleText("Status:", "MonarchShift_Text", rx + 8, 64, COLORS.text)
			draw.SimpleText(statusText, "MonarchShift_Text", rx + 60, 64, statusCol)
			draw.SimpleText("Elapsed:", "MonarchShift_Text", rx + 8, 90, COLORS.text)
			draw.SimpleText(string.format("%02d:%02d:%02d", hrs, mins, secs), "MonarchShift_Text", rx + 60, 90, COLORS.text)

		local btnY = 130
		local btnW = math.min(200, math.floor((rw - 8) / 2))
		if not self._btnStart then
			self._btnStart = vgui.Create("DButton", content)
			self._btnStart._down = false
		end
		if not self._btnEnd then
			self._btnEnd = vgui.Create("DButton", content)
			self._btnEnd._down = false
		end
		local btnStart = self._btnStart
		local btnEnd = self._btnEnd

		btnStart:SetText("")
		btnEnd:SetText("")
		btnStart:SetPos(rx, btnY)
		btnEnd:SetPos(rx + btnW + 4, btnY)
		btnStart:SetSize(btnW, 28)
		btnEnd:SetSize(btnW, 28)
		btnStart:SetVisible(true)
		btnEnd:SetVisible(true)

		btnStart.Paint = function(b, bw, bh)
			local raised = not (b._down or shift.is_active)
			DrawPanel(0, 0, bw, bh, shift.is_active and COLORS.shadow or COLORS.panel, raised)
			draw.SimpleText("Start Shift", "MonarchShift_Text", bw / 2, bh / 2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		btnStart.OnMousePressed = function(self, mcode)
			if DButton and DButton.OnMousePressed then DButton.OnMousePressed(self, mcode) end
		end
		btnStart.OnMouseReleased = function(self, mcode)
			if DButton and DButton.OnMouseReleased then DButton.OnMouseReleased(self, mcode) end
		end
		btnStart.DoClick = function()
			if shift.is_active then return end
			SHIFT_DATA.is_active = true
			SHIFT_DATA.start_time = CurTime()
			SHIFT_DATA.elapsed = 0
			surface.PlaySound(mouse_click)
			net.Start("monindustry_workshift_svrstart")
			net.SendToServer()
		end

		btnEnd.Paint = function(b, bw, bh)
			local raised = not (b._down or not shift.is_active)
			DrawPanel(0, 0, bw, bh, not shift.is_active and COLORS.shadow or COLORS.panel, raised)
			draw.SimpleText("End Shift", "MonarchShift_Text", bw / 2, bh / 2, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		btnEnd.OnMousePressed = function(self, mcode)
			if DButton and DButton.OnMousePressed then DButton.OnMousePressed(self, mcode) end
		end
		btnEnd.OnMouseReleased = function(self, mcode)
			if DButton and DButton.OnMouseReleased then DButton.OnMouseReleased(self, mcode) end
		end
		btnEnd.DoClick = function()
			if not shift.is_active then return end
			SHIFT_DATA.is_active = false
			SHIFT_DATA.elapsed = (SHIFT_DATA.start_time and (CurTime() - SHIFT_DATA.start_time)) or SHIFT_DATA.elapsed
			SHIFT_DATA.start_time = nil
			surface.PlaySound(mouse_click)
			net.Start("monindustry_workshift_svrend")
			net.SendToServer()
		end
	end

	local view = vgui.Create("DPanel", content)
	view:Dock(FILL)
	view:DockMargin(4, 4, 4, 4)
	SetupPersonnelInteraction(view)
	view.Paint = function(self, w, h)

		if frame._isLoading then
			local t = math.Clamp((CurTime() - frame._loadStart) / frame._loadDur, 0, 1)
			local e = EaseInOut(t)
			surface.SetDrawColor(COLORS.panel)
			surface.DrawRect(0, 0, w, h)
			draw.SimpleText("Loading...", "MonarchShift_Title", w / 2, h / 2 - 24, COLORS.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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

		if self._quotaButtons then
			for _, btn in pairs(self._quotaButtons) do
				if IsValid(btn) then
					btn:SetVisible(active == "quotas")
				end
			end
		end

		if active == "factory" then
			PaintFactory(self, w, h)
		elseif active == "personnel" then
			PaintPersonnel(self, w, h)
		elseif active == "quotas" then
			PaintQuotas(self, w, h)
		elseif active == "shift" then
			PaintShift(self, w, h)
		end
		surface.SetAlphaMultiplier(1)
	end

	GLOBAL_FRAME = frame
	return frame
end

function ENT:Initialize()

end

net.Receive("Monarch_ComputerUI_Open", function()
	local frame = CreateFrame()
	if frame then
		frame:SetVisible(true)
		frame:MakePopup()
	end
end)

net.Receive("monindustry_workshift_start", function()
	chat.AddText(Color(200,200,0), "Attention all occupants. A new workshift has begun, please assume a workstation.")
end)

net.Receive("monindustry_workshift_end", function()
	chat.AddText(Color(200,200,0), "Attention all occupants. The workshift has now concluded, please prepare to leave your workstations.")
end)

net.Receive("monarch_workshift_notification", function()
	local workerName = net.ReadString()
	local newStatus = net.ReadString()
	local notification = net.ReadString()
	local ply = net.ReadPlayer()

	ply:Notify(notification, NOTIFY_GENERIC, 10)
end)

net.Receive("monarch_workshift_statusupdated", function()
	local workerName = net.ReadString()
	local newStatus = net.ReadString()
	local notification = net.ReadString()

	WORKER_STATUS[workerName] = {
		status = newStatus,
		notify = notification
	}
end)

net.Receive("monarch_shift_quotaupdate", function()
	local receptacleName = net.ReadString()
	local quotaAmount = net.ReadUInt(16)
	local currentAmount = net.ReadUInt(16)

	QUOTA_DATA[receptacleName] = {
		quota = quotaAmount,
		current = currentAmount
	}
end)

net.Receive("monarch_shift_receptacleupdate", function()
	local receptacleName = net.ReadString()
	local receptacleUID = net.ReadString()

	RECEPTACLE_DATA[receptacleName] = receptacleUID
end)

net.Receive("monarch_shift_factorylogupdate", function()
	local receptacleName = net.ReadString()
	local count = net.ReadUInt(16)
	local status = net.ReadString()

	FACTORY_LOGS[receptacleName] = {
		count = count,
		status = status
	}
end)