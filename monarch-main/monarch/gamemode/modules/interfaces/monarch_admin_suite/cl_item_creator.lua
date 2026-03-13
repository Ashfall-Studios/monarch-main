Monarch = Monarch or {}
Monarch.UI = Monarch.UI or {}

if IsValid(Monarch.UI.ItemCreator) then
    Monarch.UI.ItemCreator:Remove()
end

local function enumeratePlayers()
    local choices = {}
    for _, p in player.Iterator() do
        table.insert(choices, { name = p:Nick(), sid64 = p:SteamID64() })
    end
    table.SortByMember(choices, "name", true)
    return choices
end

local function getAllItems()
    local list = {}
    local items = Monarch.Inventory and Monarch.Inventory.Items or {}
    local ref = Monarch.Inventory and Monarch.Inventory.ItemsRef or {}
    local seen = {}

    for uid, key in pairs(ref) do
        if isstring(uid) and items[key] then
            table.insert(list, { id = uid, def = items[key] })
            seen[uid] = true
        end
    end

    for _, def in pairs(items) do
        if istable(def) then
            local uid = def.UniqueID
            if isstring(uid) and uid ~= "" and not seen[uid] then
                table.insert(list, { id = uid, def = def })
                seen[uid] = true
            end
        end
    end

    table.SortByMember(list, "id", true)
    return list
end

local PANEL = {}

function PANEL:Init()
    local sw, sh = ScrW(), ScrH()

    local side = math.floor(sw * (1/3))
    local W, H = side, side

    self:SetSize(W, H)
    self:Center()
    self:MakePopup()
    self:SetTitle("")
    self:ShowCloseButton(false)

    self.topBarH = 28
    self.Paint = function(s, w, h)

        surface.SetDrawColor(20,20,20,240)
        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(50,50,50,255)
        surface.DrawOutlinedRect(0,0,w,h,1)

        surface.SetDrawColor(30,30,30,255)
        surface.DrawRect(0,0,w,self.topBarH)
        surface.SetDrawColor(70,70,70,255)
        surface.DrawLine(0,self.topBarH,w,self.topBarH)
        surface.SetFont("InvMed")
        local tw, th = surface.GetTextSize("Item Creator")
        local ty = math.floor((self.topBarH - th) * 0.5)
        draw.SimpleText("Item Creator", "InvMed", 12, ty, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    self.closeBtn = vgui.Create("DButton", self)
    self.closeBtn:SetSize(24, 20)
    self.closeBtn:SetPos(self:GetWide() - 28, math.floor((self.topBarH - self.closeBtn:GetTall()) * 0.5))
    self.closeBtn:SetText("X")
    self.closeBtn:SetFont("InvSmall")
    self.closeBtn:SetTextColor(color_white)
    self.closeBtn.Paint = function(s, w, h)
        local bg = s:IsHovered() and Color(120,50,50) or Color(90,40,40)
        surface.SetDrawColor(bg)
        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(140,60,60)
        surface.DrawOutlinedRect(0,0,w,h,1)
    end
    self.closeBtn.DoClick = function() self:Remove() end

    self.playerCombo = vgui.Create("DComboBox", self)
    self.playerCombo:SetPos(10, self.topBarH + 6)
    self.playerCombo:SetSize(W - 20, 24)
    self.playerCombo:SetValue("Select player...")
    self.playerCombo:SetTextColor(color_white)
    self.playerCombo:SetFont("InvSmall")
    self.playerCombo.Paint = function(s, w, h)
        surface.SetDrawColor(35,35,35,255)
        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(90,90,90,255)
        surface.DrawOutlinedRect(0,0,w,h,1)
    end

    self.playerMap = {}
    for _, row in ipairs(enumeratePlayers()) do
        self.playerMap[row.name] = row.sid64
        self.playerCombo:AddChoice(row.name)
    end

    self.playerCombo.OnMenuOpened = function(pnl, menu)
        if not IsValid(menu) then return end
        menu.Paint = function(s, w, h)
            surface.SetDrawColor(30,30,30,255)
            surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(80,80,80,255)
            surface.DrawOutlinedRect(0,0,w,h,1)
        end
        local function styleOptions(parent)
            if not IsValid(parent) then return end
            for _, child in ipairs(parent:GetChildren()) do
                if IsValid(child) then
                    local cls = child.GetClassName and child:GetClassName() or ""
                    if cls == "DMenuOption" then
                        child.Paint = function(s, w, h)
                            local bg = s:IsHovered() and Color(70,70,70) or Color(45,45,45)
                            surface.SetDrawColor(bg)
                            surface.DrawRect(0,0,w,h)
                            surface.SetTextColor(255,255,255)
                        end
                    else

                        styleOptions(child)
                    end
                end
            end
        end
        styleOptions(menu)
    end

    self.searchEntry = vgui.Create("DTextEntry", self)
    self.searchEntry:SetPos(10, self.topBarH + 36)
    self.searchEntry:SetSize(W - 20, 24)
    self.searchEntry:SetPlaceholderText("Search items...")
    self.searchEntry:SetUpdateOnType(true)
    self.searchEntry:SetFont("InvSmall")
    self.searchEntry:SetTextColor(color_white)
    self.searchEntry:SetCursorColor(Color(220,220,220))
    self.searchEntry:SetHighlightColor(Color(90,90,90,160))
    self.searchEntry.Paint = function(s, w, h)
        surface.SetDrawColor(35,35,35,255)
        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(90,90,90,255)
        surface.DrawOutlinedRect(0,0,w,h,1)

        s:DrawTextEntryText(Color(255,255,255), Color(220,220,220), Color(180,180,180))

        if s:GetValue() == "" and not s:HasFocus() then
            draw.SimpleText("Search items...", "InvSmall", 6, h * 0.5, Color(170,170,170), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    self.searchEntry.OnValueChange = function()
        self:PopulateItems()
    end

    self.scroll = vgui.Create("DScrollPanel", self)
    self.scroll:SetPos(10, self.topBarH + 66)
    self.scroll:SetSize(W - 20, H - (self.topBarH + 76))
    local vbar = self.scroll:GetVBar()
    vbar.Paint = function(s, w, h)
        surface.SetDrawColor(25,25,25,255)
        surface.DrawRect(0,0,w,h)
    end
    vbar.btnUp.Paint = function(s, w, h)
        surface.SetDrawColor(45,45,45)
        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(90,90,90)
        surface.DrawOutlinedRect(0,0,w,h,1)
    end
    vbar.btnDown.Paint = vbar.btnUp.Paint
    vbar.btnGrip.Paint = function(s, w, h)
        surface.SetDrawColor(70,70,70)
        surface.DrawRect(0,0,w,h)
        surface.SetDrawColor(120,120,120)
        surface.DrawOutlinedRect(0,0,w,h,1)
    end

    self.grid = vgui.Create("DIconLayout", self.scroll)
    self.grid:Dock(FILL)
    self.grid:SetSpaceX(8)
    self.grid:SetSpaceY(8)

    self:PopulateItems()
end

function PANEL:PopulateItems()
    self.grid:Clear()
    local items = getAllItems()
    local query = ""
    if IsValid(self.searchEntry) then
        query = string.Trim(string.lower(self.searchEntry:GetValue() or ""))
    end

    local tileW, tileH = 110, 134

    for _, entry in ipairs(items) do
        local id, def = entry.id, entry.def
        local displayName = tostring(def.Name or id)
        if query ~= "" then
            local idMatch = string.find(string.lower(tostring(id or "")), query, 1, true) ~= nil
            local nameMatch = string.find(string.lower(displayName), query, 1, true) ~= nil
            if not idMatch and not nameMatch then
                continue
            end
        end

        local pnl = self.grid:Add("DPanel")
        pnl:SetSize(tileW, tileH)
        pnl.Paint = function(s, w, h)
            surface.SetDrawColor(35,35,35,255)
            surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(90,90,90,255)
            surface.DrawOutlinedRect(0,0,w,h,1)
        end

        local mdl = vgui.Create("DModelPanel", pnl)
        mdl:SetSize(tileW, tileH - 28)
        mdl:SetPos(0, 0)
        mdl:SetModel(def.Model or "models/props_junk/cardboard_box004a.mdl")

        mdl:SetFOV(def.FOV or 26)
        mdl:SetAmbientLight(Vector(80,80,80))
        mdl:SetColor(Color(255,255,255))
        mdl.LayoutEntity = function() return end
        local function autoFit()
            if not IsValid(mdl.Entity) then return end
            local ent = mdl.Entity
            local mn, mx = ent:GetRenderBounds()
            local size = math.max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z)
            local center = (mn + mx) * 0.5
            local camDist = (size <= 0) and 50 or (size * 1.2)
            local camPos = center + Vector(camDist, camDist, camDist)
            if def.CamPos then camPos = def.CamPos end
            mdl:SetCamPos(camPos)
            mdl:SetLookAt(def.LookAt or center)
        end
        timer.Simple(0, autoFit)

        local btn = vgui.Create("DButton", pnl)
        btn:SetText("Give")
        btn:SetFont("InvSmall")
        btn:SetTextColor(color_white)
        btn:SetSize(tileW - 10, 22)
        btn:SetPos(5, tileH - 24)
        btn.Paint = function(s, w, h)
            local bg = s:IsHovered() and Color(70,70,70) or Color(50,50,50)
            surface.SetDrawColor(bg)
            surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(120,120,120)
            surface.DrawOutlinedRect(0,0,w,h,1)
        end
    btn:SetTooltip(displayName)

        btn.DoClick = function()
            local name = self.playerCombo:GetValue()
            local sid64 = self.playerMap[name]
            if not sid64 then return end
            net.Start("Monarch_Admin_GiveItem")
                net.WriteString(sid64)
                net.WriteString(id)
                net.WriteUInt(1, 8)
            net.SendToServer()
        end
    end
end

vgui.Register("MonarchItemCreator", PANEL, "DFrame")

net.Receive("Monarch_Admin_ShowItemCreator", function()
    if IsValid(Monarch.UI.ItemCreator) then Monarch.UI.ItemCreator:Remove() end
    AddCSLuaFile()
    Monarch.UI.ItemCreator = vgui.Create("MonarchItemCreator")
end)

