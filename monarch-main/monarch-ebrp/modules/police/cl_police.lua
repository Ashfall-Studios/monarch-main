
if not CLIENT then return end

Monarch = Monarch or {}
Monarch.Police = Monarch.Police or {}
Monarch.Police.Warrants = Monarch.Police.Warrants or { List = {} }
Monarch.Police.Criminal = Monarch.Police.Criminal or { Records = {} }
Monarch.Police.Citations = Monarch.Police.Citations or { List = {} }
Monarch.Police.Bail = Monarch.Police.Bail or { Records = {} }
Monarch.Police.Detainees = Monarch.Police.Detainees or { List = {}, Charges = {} }

net.Receive("Monarch.Police.Warrants.UpdateData", function()
	Monarch.Police.Warrants.List = net.ReadTable() or {}
end)

net.Receive("Monarch.Police.Criminal.UpdateData", function()
	Monarch.Police.Criminal.Records = net.ReadTable() or {}
end)

net.Receive("Monarch.Police.Citations.UpdateData", function()
	Monarch.Police.Citations.List = net.ReadTable() or {}
end)

net.Receive("Monarch.Police.Bail.UpdateData", function()
	Monarch.Police.Bail.Records = net.ReadTable() or {}
end)

net.Receive("Monarch.Police.Detainees.UpdateData", function()
	Monarch.Police.Detainees.List = net.ReadTable() or {}
end)

net.Receive("Monarch.Police.Detainees.GetCharges", function()
	Monarch.Police.Detainees.Charges = net.ReadTable() or {}
end)

function Monarch.Police.CreateWarrantPanel(parent)
	local panel = vgui.Create("DPanel", parent)
	panel:SetSize(parent:GetWide(), parent:GetTall())
	panel:SetBackgroundColor(Color(30, 30, 30))

	local scroll = vgui.Create("DScrollPanel", panel)
	scroll:Dock(FILL)
	scroll:SetPadding(5)

	function panel:Refresh()
		scroll:Clear()

		if #Monarch.Police.Warrants.List == 0 then
			local label = vgui.Create("DLabel", scroll)
			label:SetText("No active warrants")
			label:SetTextColor(Color(255, 255, 255))
			label:SetSize(scroll:GetWide(), 20)
		end

		for _, warrant in ipairs(Monarch.Police.Warrants.List) do
			if warrant.active then
				local item = vgui.Create("DPanel", scroll)
				item:SetHeight(80)
				item:Dock(TOP)
				item:DockMargin(0, 5, 0, 5)
				item:SetBackgroundColor(Color(50, 50, 50))

				local label = vgui.Create("DLabel", item)
				label:SetPos(5, 5)
				label:SetSize(item:GetWide() - 10, 15)
				label:SetText(warrant.char_name .. " - " .. warrant.reason)
				label:SetTextColor(Color(255, 100, 100))

				local issuer = vgui.Create("DLabel", item)
				issuer:SetPos(5, 25)
				issuer:SetSize(item:GetWide() - 10, 12)
				issuer:SetText("Issued by: " .. warrant.issued_by)
				issuer:SetTextColor(Color(200, 200, 200))
				issuer:SetFont("DermaDefault")

				local severity = vgui.Create("DLabel", item)
				severity:SetPos(5, 40)
				severity:SetSize(item:GetWide() - 10, 12)
				severity:SetText("Severity: " .. warrant.severity .. " | Arrests: " .. warrant.arrests)
				severity:SetTextColor(Color(200, 200, 200))
				severity:SetFont("DermaDefault")

				local revokeBtn = vgui.Create("DButton", item)
				revokeBtn:SetPos(5, 55)
				revokeBtn:SetSize(item:GetWide() - 10, 20)
				revokeBtn:SetText("Revoke Warrant")
				function revokeBtn:DoClick()
					net.Start("Monarch.Police.Warrants.RevokeWarrant")
						net.WriteString(warrant.char_id)
					net.SendToServer()
					panel:Refresh()
				end
			end
		end
	end

	panel:Refresh()
	return panel
end

function Monarch.Police.CreateCriminalPanel(parent)
	local panel = vgui.Create("DPanel", parent)
	panel:SetSize(parent:GetWide(), parent:GetTall())
	panel:SetBackgroundColor(Color(30, 30, 30))

	local scroll = vgui.Create("DScrollPanel", panel)
	scroll:Dock(FILL)
	scroll:SetPadding(5)

	function panel:Refresh()
		scroll:Clear()

		if #Monarch.Police.Criminal.Records == 0 then
			local label = vgui.Create("DLabel", scroll)
			label:SetText("No criminal records")
			label:SetTextColor(Color(255, 255, 255))
			label:SetSize(scroll:GetWide(), 20)
		end

		for _, record in ipairs(Monarch.Police.Criminal.Records) do
			local item = vgui.Create("DPanel", scroll)
			item:SetHeight(100)
			item:Dock(TOP)
			item:DockMargin(0, 5, 0, 5)
			item:SetBackgroundColor(Color(50, 50, 50))

			local label = vgui.Create("DLabel", item)
			label:SetPos(5, 5)
			label:SetSize(item:GetWide() - 10, 15)
			label:SetText(record.char_name)
			label:SetTextColor(Color(255, 200, 100))

			local arrests = vgui.Create("DLabel", item)
			arrests:SetPos(5, 25)
			arrests:SetSize(item:GetWide() - 10, 12)
			arrests:SetText("Arrests: " .. record.arrest_count .. " | Convictions: " .. record.conviction_count)
			arrests:SetTextColor(Color(200, 200, 200))
			arrests:SetFont("DermaDefault")

			local charges = vgui.Create("DLabel", item)
			charges:SetPos(5, 40)
			charges:SetSize(item:GetWide() - 10, 12)
			charges:SetText("Active Charges: " .. #record.active_charges)
			charges:SetTextColor(Color(200, 200, 200))
			charges:SetFont("DermaDefault")

			if #record.active_charges > 0 then
				local chargeList = table.concat(record.active_charges, ", ")
				if string.len(chargeList) > 50 then
					chargeList = string.sub(chargeList, 1, 50) .. "..."
				end
				local chargeLabel = vgui.Create("DLabel", item)
				chargeLabel:SetPos(5, 55)
				chargeLabel:SetSize(item:GetWide() - 10, 12)
				chargeLabel:SetText("Charges: " .. chargeList)
				chargeLabel:SetTextColor(Color(255, 100, 100))
				chargeLabel:SetFont("DermaDefault")
			end
		end
	end

	panel:Refresh()
	return panel
end

function Monarch.Police.CreateCitationsPanel(parent)
	local panel = vgui.Create("DPanel", parent)
	panel:SetSize(parent:GetWide(), parent:GetTall())
	panel:SetBackgroundColor(Color(30, 30, 30))

	local scroll = vgui.Create("DScrollPanel", panel)
	scroll:Dock(FILL)
	scroll:SetPadding(5)

	function panel:Refresh()
		scroll:Clear()

		if #Monarch.Police.Citations.List == 0 then
			local label = vgui.Create("DLabel", scroll)
			label:SetText("No citations issued")
			label:SetTextColor(Color(255, 255, 255))
			label:SetSize(scroll:GetWide(), 20)
		end

		for _, citation in ipairs(Monarch.Police.Citations.List) do
			local item = vgui.Create("DPanel", scroll)
			item:SetHeight(80)
			item:Dock(TOP)
			item:DockMargin(0, 5, 0, 5)
			item:SetBackgroundColor(Color(50, 50, 50))

			local label = vgui.Create("DLabel", item)
			label:SetPos(5, 5)
			label:SetSize(item:GetWide() - 10, 15)
			label:SetText(citation.char_name .. " - $" .. citation.fine_amount)
			label:SetTextColor(citation.paid and Color(100, 255, 100) or Color(255, 100, 100))

			local violation = vgui.Create("DLabel", item)
			violation:SetPos(5, 25)
			violation:SetSize(item:GetWide() - 10, 12)
			violation:SetText("Violation: " .. citation.violation)
			violation:SetTextColor(Color(200, 200, 200))
			violation:SetFont("DermaDefault")

			local status = vgui.Create("DLabel", item)
			status:SetPos(5, 40)
			status:SetSize(item:GetWide() - 10, 12)
			status:SetText("Status: " .. (citation.paid and "PAID" or "OUTSTANDING") .. " | Issued by: " .. citation.issued_by)
			status:SetTextColor(Color(200, 200, 200))
			status:SetFont("DermaDefault")
		end
	end

	panel:Refresh()
	return panel
end

function Monarch.Police.CreateBailPanel(parent)
	local panel = vgui.Create("DPanel", parent)
	panel:SetSize(parent:GetWide(), parent:GetTall())
	panel:SetBackgroundColor(Color(30, 30, 30))

	local scroll = vgui.Create("DScrollPanel", panel)
	scroll:Dock(FILL)
	scroll:SetPadding(5)

	function panel:Refresh()
		scroll:Clear()

		if #Monarch.Police.Bail.Records == 0 then
			local label = vgui.Create("DLabel", scroll)
			label:SetText("No bail records")
			label:SetTextColor(Color(255, 255, 255))
			label:SetSize(scroll:GetWide(), 20)
		end

		for _, record in ipairs(Monarch.Police.Bail.Records) do
			local item = vgui.Create("DPanel", scroll)
			item:SetHeight(90)
			item:Dock(TOP)
			item:DockMargin(0, 5, 0, 5)
			item:SetBackgroundColor(Color(50, 50, 50))

			local label = vgui.Create("DLabel", item)
			label:SetPos(5, 5)
			label:SetSize(item:GetWide() - 10, 15)
			label:SetText(record.char_name .. " - Bail: $" .. record.bail_amount)
			label:SetTextColor(Color(100, 150, 255))

			local status = vgui.Create("DLabel", item)
			status:SetPos(5, 25)
			status:SetSize(item:GetWide() - 10, 12)
			status:SetText("Status: " .. (record.posted and "POSTED" or "UNPAID"))
			status:SetTextColor(record.posted and Color(100, 255, 100) or Color(255, 100, 100))
			status:SetFont("DermaDefault")

			if record.posted then
				local postedBy = vgui.Create("DLabel", item)
				postedBy:SetPos(5, 40)
				postedBy:SetSize(item:GetWide() - 10, 12)
				postedBy:SetText("Posted by: " .. record.posted_by .. " ($" .. record.posted_amount .. ")")
				postedBy:SetTextColor(Color(200, 200, 200))
				postedBy:SetFont("DermaDefault")
			end

			local setBy = vgui.Create("DLabel", item)
			setBy:SetPos(5, 55)
			setBy:SetSize(item:GetWide() - 10, 12)
			setBy:SetText("Set by: " .. record.set_by)
			setBy:SetTextColor(Color(200, 200, 200))
			setBy:SetFont("DermaDefault")
		end
	end

	panel:Refresh()
	return panel
end

function Monarch.Police.CreateDetaineesPanel(parent)
	local panel = vgui.Create("DPanel", parent)
	panel:SetSize(parent:GetWide(), parent:GetTall())
	panel:SetBackgroundColor(Color(30, 30, 30))

	local scroll = vgui.Create("DScrollPanel", panel)
	scroll:Dock(FILL)
	scroll:SetPadding(5)

	function panel:Refresh()
		scroll:Clear()

		local detained = {}
		for _, detainee in ipairs(Monarch.Police.Detainees.List) do
			if not detainee.released then
				table.insert(detained, detainee)
			end
		end

		if #detained == 0 then
			local label = vgui.Create("DLabel", scroll)
			label:SetText("No detainees")
			label:SetTextColor(Color(255, 255, 255))
			label:SetSize(scroll:GetWide(), 20)
		end

		for _, detainee in ipairs(detained) do
			local item = vgui.Create("DPanel", scroll)
			item:SetHeight(100)
			item:Dock(TOP)
			item:DockMargin(0, 5, 0, 5)
			item:SetBackgroundColor(Color(50, 50, 50))

			local label = vgui.Create("DLabel", item)
			label:SetPos(5, 5)
			label:SetSize(item:GetWide() - 10, 15)
			label:SetText(detainee.char_name)
			label:SetTextColor(Color(255, 100, 100))

			local reason = vgui.Create("DLabel", item)
			reason:SetPos(5, 25)
			reason:SetSize(item:GetWide() - 10, 12)
			reason:SetText("Reason: " .. detainee.reason)
			reason:SetTextColor(Color(200, 200, 200))
			reason:SetFont("DermaDefault")

			local arrestedBy = vgui.Create("DLabel", item)
			arrestedBy:SetPos(5, 40)
			arrestedBy:SetSize(item:GetWide() - 10, 12)
			arrestedBy:SetText("Arrested by: " .. detainee.arrested_by)
			arrestedBy:SetTextColor(Color(200, 200, 200))
			arrestedBy:SetFont("DermaDefault")

			local notes = vgui.Create("DLabel", item)
			notes:SetPos(5, 55)
			notes:SetSize(item:GetWide() - 10, 12)
			notes:SetText("Notes: " .. (detainee.processing_notes ~= "" and detainee.processing_notes or "None"))
			notes:SetTextColor(Color(150, 150, 150))
			notes:SetFont("DermaDefault")
		end
	end

	panel:Refresh()
	return panel
end

hook.Add("InitPostEntity", "Monarch.Police.RequestData", function()
	net.Start("Monarch.Police.Warrants.GetData")
	net.SendToServer()

	net.Start("Monarch.Police.Criminal.GetData")
	net.SendToServer()

	net.Start("Monarch.Police.Citations.GetData")
	net.SendToServer()

	net.Start("Monarch.Police.Bail.GetData")
	net.SendToServer()

	net.Start("Monarch.Police.Detainees.GetData")
	net.SendToServer()
end)
