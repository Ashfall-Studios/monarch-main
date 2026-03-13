AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Category = "Monarch"
ENT.Spawnable = false
ENT.AdminSpawnable = false

local function Monarch_UpdateItemHUDDisplay(ent)
    if not IsValid(ent) then return end

    local itemClass = ent.ItemClass or ent:GetNWString("ItemClass", "unknown")
    local itemData = (Monarch.Inventory and Monarch.Inventory.Items and Monarch.Inventory.Items[itemClass]) or nil
    if (not itemData) and Monarch.Inventory and Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[itemClass] then
        local itemKey = Monarch.Inventory.ItemsRef[itemClass]
        itemData = Monarch.Inventory.Items and Monarch.Inventory.Items[itemKey]
    end

    local displayName = (itemData and (itemData.Name or itemData.name)) or itemClass or "Unknown Item"
    local stackAmount = math.max(1, tonumber(ent:GetNWInt("StackAmount") or ent.StackAmount or 1) or 1)
    if stackAmount > 1 then
        ent.HUDDisplayText = "Press 'E' to pickup [" .. displayName .. " x" .. stackAmount .. "]."
    else
        ent.HUDDisplayText = "Press 'E' to pickup [" .. displayName .. "]."
    end
end

function ENT:Initialize()
    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self.ClassName = "monarch_item" 
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetMass(1)
        end
        self.ItemClass = self.ItemClass or "unknown"
        self.StackAmount = math.max(1, tonumber(self.StackAmount or 1) or 1)
        self:SetNWInt("StackAmount", self.StackAmount)

        self:SetNWBool("ForSale", false)
        self:SetNWInt("SalePrice", 0)
        self:SetNWEntity("Seller", NULL)
        self.CanPickup = true
        timer.Simple(300, function() 
            if IsValid(self) then
                self:Remove()
            end
        end)

        timer.Simple(0, function()
            if IsValid(self) then
                self:UprightOnGround()
            end
        end)
    end
end

function ENT:SetItemClass(itemClass)
    self.ItemClass = itemClass
    self:SetNWString("ItemClass", itemClass)

    local itemData = (Monarch.Inventory and Monarch.Inventory.Items and Monarch.Inventory.Items[itemClass]) or nil
    if (not itemData) and Monarch.Inventory and Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[itemClass] then
        local itemKey = Monarch.Inventory.ItemsRef[itemClass]
        itemData = Monarch.Inventory.Items and Monarch.Inventory.Items[itemKey]
    end

    local defModel = itemData and itemData.Model or nil
    if defModel and defModel ~= "" then
        self:SetModel(defModel)
    else

        local cur = self:GetModel()
        if not isstring(cur) or cur == "" then
            self:SetModel("models/props_junk/cardboard_box004a.mdl")
        end
    end

    Monarch_UpdateItemHUDDisplay(self)

    if SERVER then
        timer.Simple(0, function()
            if IsValid(self) then
                self:UprightOnGround()
            end
        end)
    end
end

function ENT:SetStackAmount(n)
    n = math.max(1, math.floor(tonumber(n) or 1))
    self.StackAmount = n
    self:SetNWInt("StackAmount", n)
    Monarch_UpdateItemHUDDisplay(self)
end

if SERVER then
    function ENT:UprightOnGround()
        if not IsValid(self) then return end

        local ang = self:GetAngles()
        self:SetAngles(Angle(0, ang.y, 0))

        local start = self:GetPos() + Vector(0, 0, 16)
        local tr = util.TraceLine({
            start = start,
            endpos = start - Vector(0, 0, 256),
            filter = self
        })
        if tr.Hit then
            local mins = self:OBBMins()
            local height = -mins.z 
            self:SetPos(tr.HitPos + tr.HitNormal * height)
        end
    end
end

function ENT:GetStackAmount()
    return math.max(1, tonumber(self:GetNWInt("StackAmount") or self.StackAmount or 1) or 1)
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if not self.CanPickup then return end

    if SERVER then

        if self:GetNWBool("ForSale", false) then
            local seller = self:GetNWEntity("Seller")
            if IsValid(seller) and seller ~= activator then
                net.Start("Monarch.Item.ShowMenu")
                    net.WriteEntity(self)
                net.Send(activator)
                return
            end

        end

        local itemClass = self.ItemClass or self:GetNWString("ItemClass", "unknown")
        local count = self.GetStackAmount and self:GetStackAmount() or 1

        if itemClass == "cash" then
            activator:AddMoney(count)
            self:Remove()
            return
        end

        local addedCount = activator.GiveInventoryItem and activator:GiveInventoryItem(itemClass, count) or 0

        if type(addedCount) == "boolean" then

            if addedCount then
                self:Remove()
            else
                if activator.Notify then activator:Notify("Your inventory is full.") end
            end
        else

            if addedCount > 0 then
                local remaining = count - addedCount
                if remaining > 0 then

                    self.StackAmount = remaining
                    self:SetNWInt("StackAmount", remaining)
                    if activator.ChatPrint then
                        activator:ChatPrint("Inventory full: picked up " .. addedCount .. " of " .. count .. " items.")
                    end
                else

                    self:Remove()
                end
            else
                if activator.Notify then activator:Notify("Your inventory is full.(1)") end
            end
        end
    end
end

if CLIENT then

    local function OpenListPricePrompt(ent, onClose)
        if not IsValid(ent) then return end
        local pw, ph = 360, 160
        local pf = vgui.Create("DFrame")
        pf:SetSize(pw, ph)
        pf:Center()
        pf:SetTitle("")
        pf:ShowCloseButton(true)
        pf:MakePopup()
        pf.Paint = function(s, pw2, ph2)
            surface.SetDrawColor(20,20,20,240)
            surface.DrawRect(0,0,pw2,ph2)
            surface.SetDrawColor(50,50,50,255)
            surface.DrawOutlinedRect(0,0,pw2,ph2,1)
            surface.SetDrawColor(30,30,30,255)
            surface.DrawRect(0,0,pw2,28)
            surface.SetDrawColor(70,70,70,255)
            surface.DrawLine(0,28,pw2,28)
            draw.SimpleText("List For Sale", "InvMed", 12, 6, color_white)
        end

        local lbl = vgui.Create("DLabel", pf)
        lbl:SetPos(12, 38)
        lbl:SetText("Enter price to sell this item for:")
        lbl:SetFont("InvSmall")
        lbl:SizeToContents()

        local entry = vgui.Create("DTextEntry", pf)
        entry:SetPos(12, 60)
        entry:SetSize(pw-24, 28)
        entry:SetFont("InvSmall")
        entry:SetText("100")
        entry:SetNumeric(true)
        entry.Paint = function(s, pw2, ph2)
            surface.SetDrawColor(40,40,40,255)
            surface.DrawRect(0,0,pw2,ph2)
            surface.SetDrawColor(120,120,120,255)
            surface.DrawOutlinedRect(0,0,pw2,ph2,1)
            s:DrawTextEntryText(color_white, Color(80,160,255), color_white)
        end

        local btnW = (pw - 28 - 8) / 2
        local btnCancel = vgui.Create("DButton", pf)
        btnCancel:SetPos(12, ph - 44)
        btnCancel:SetSize(btnW, 32)
        btnCancel:SetText("Cancel")
        btnCancel:SetFont("InvSmall")
        btnCancel:SetTextColor(color_white)
        btnCancel.Paint = function(s, pw, ph)
            local bg = s:IsHovered() and Color(70,70,70) or Color(50,50,50)
            surface.SetDrawColor(bg)
            surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(120,120,120)
            surface.DrawOutlinedRect(0,0,pw,ph,1)
        end
        btnCancel.DoClick = function() pf:Remove() end

        local btnOk = vgui.Create("DButton", pf)
        btnOk:SetPos(12 + btnW + 8, ph - 44)
        btnOk:SetSize(btnW, 32)
        btnOk:SetText("Confirm")
        btnOk:SetFont("InvSmall")
        btnOk:SetTextColor(color_white)
        btnOk.Paint = btnCancel.Paint
        local function submit()
            if not IsValid(ent) then return end
            local text = entry:GetText() or ""
            local amt = math.max(0, math.floor(tonumber(text) or 0))
            if amt <= 0 then return end
            net.Start("Monarch.Item.ListForSale")
                net.WriteEntity(ent)
                net.WriteUInt(amt, 32)
            net.SendToServer()
            pf:Remove()
            if onClose then onClose() end
        end
        btnOk.DoClick = submit
        entry.OnEnter = submit
    end

    local function OpenItemInteractionMenu(ent)
        if not IsValid(ent) then return end
        if IsValid(ent._MonarchMenu) then ent._MonarchMenu:Remove() end
        local w, h = 280, 186

        local itemClass = ent:GetNWString("ItemClass", "unknown")
        local itemData = (Monarch.Inventory and Monarch.Inventory.Items and Monarch.Inventory.Items[itemClass]) or nil
        if (not itemData) and Monarch.Inventory and Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[itemClass] then
            local itemKey = Monarch.Inventory.ItemsRef[itemClass]
            itemData = Monarch.Inventory.Items and Monarch.Inventory.Items[itemKey]
        end
        local canSell = true
        if itemData and itemData.CanSell ~= nil then
            canSell = itemData.CanSell and true or false
        end
        local f = vgui.Create("DFrame")
        f:SetSize(w, h)
        f:Center()
        f:SetTitle("")
        f:ShowCloseButton(true)
        f:MakePopup()
        ent._MonarchMenu = f
        f.Paint = function(s, pw, ph)
            surface.SetDrawColor(20,20,20,240)
            surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(50,50,50,255)
            surface.DrawOutlinedRect(0,0,pw,ph,1)
            surface.SetDrawColor(30,30,30,255)
            surface.DrawRect(0,0,pw,28)
            surface.SetDrawColor(70,70,70,255)
            surface.DrawLine(0,28,pw,28)
            local header = (itemData and (itemData.Name or itemData.name)) or itemClass or "Item"
            draw.SimpleText(header, "InvMed", 12, 6, color_white)
        end

        local btnPickup = vgui.Create("DButton", f)
        btnPickup:SetSize(w-20, 36)
        btnPickup:SetPos(10, 40)
        btnPickup:SetText("Pick Up")
        btnPickup:SetFont("InvSmall")
        btnPickup:SetTextColor(color_white)
        btnPickup.Paint = function(s, pw, ph)
            local bg = s:IsHovered() and Color(70,70,70) or Color(50,50,50)
            surface.SetDrawColor(bg)
            surface.DrawRect(0,0,pw,ph)
            surface.SetDrawColor(120,120,120)
            surface.DrawOutlinedRect(0,0,pw,ph,1)
        end
        btnPickup.DoClick = function()
            if not IsValid(ent) then return end
            net.Start("Monarch.Item.Pickup")
                net.WriteEntity(ent)
            net.SendToServer()
            f:Remove()
        end

        if canSell and not ent:GetNWBool("ForSale", false) then
            local btnSell = vgui.Create("DButton", f)
            btnSell:SetSize(w-20, 36)
            btnSell:SetPos(10, 86)
            btnSell:SetText("List For Sale")
            btnSell:SetFont("InvSmall")
            btnSell:SetTextColor(color_white)
            btnSell.Paint = btnPickup.Paint
            btnSell.DoClick = function()
                if not IsValid(ent) then return end
                OpenListPricePrompt(ent, function()
                    if IsValid(f) then f:Remove() end
                end)
            end
        end

        if ent:GetNWBool("ForSale", false) and ent:GetNWEntity("Seller") == LocalPlayer() then
            local btnCancelSale = vgui.Create("DButton", f)
            btnCancelSale:SetSize(w-20, 36)
            btnCancelSale:SetPos(10, 132)
            btnCancelSale:SetText("Cancel Sale")
            btnCancelSale:SetFont("InvSmall")
            btnCancelSale:SetTextColor(Color(230,200,80))
            btnCancelSale.Paint = function(s, pw2, ph2)
                local bg = s:IsHovered() and Color(90,70,30) or Color(70,50,20)
                surface.SetDrawColor(bg)
                surface.DrawRect(0,0,pw2,ph2)
                surface.SetDrawColor(160,140,80)
                surface.DrawOutlinedRect(0,0,pw2,ph2,1)
            end
            btnCancelSale.DoClick = function()
                if not IsValid(ent) then return end
                net.Start("Monarch.Item.CancelSale")
                    net.WriteEntity(ent)
                net.SendToServer()
                f:Remove()
            end
        end
    end

    net.Receive("Monarch.Item.OpenMenu", function()
        local ent = net.ReadEntity()
        OpenItemInteractionMenu(ent)
    end)

    local function IsCursorOverBuyButton(ent, origin, ang, scale, halfW, halfH)
        local lp = LocalPlayer()
        if not IsValid(lp) then return false end
        local eye = lp:EyePos()
        local dir = lp:EyeAngles():Forward()
        local hit = util.IntersectRayWithPlane(eye, dir, origin, ang:Up())
        if not hit then return false end
        local localPos = WorldToLocal(hit, Angle(0,0,0), origin, ang)
        local x = localPos.x / scale
        local y = -localPos.y / scale 

        return x >= -halfW and x <= halfW and y >= -halfH and y <= halfH
    end

    function ENT:Draw()
        self:DrawModel()

        local itemClass = self:GetNWString("ItemClass", "unknown")

        local itemData = (Monarch.Inventory and Monarch.Inventory.Items and Monarch.Inventory.Items[itemClass]) or nil
        if (not itemData) and Monarch.Inventory and Monarch.Inventory.ItemsRef and Monarch.Inventory.ItemsRef[itemClass] then
            local itemKey = Monarch.Inventory.ItemsRef[itemClass]
            itemData = Monarch.Inventory.Items and Monarch.Inventory.Items[itemKey]
        end

        if self:GetNWBool("ForSale", false) then
            local price = tonumber(self:GetNWInt("SalePrice", 0)) or 0
            local label = (Monarch and Monarch.FormatMoney) and Monarch.FormatMoney(price) or ("$"..tostring(price))

            local topLocalZ = self:OBBMaxs().z
            local pos = self:LocalToWorld(Vector(0, 0, topLocalZ + 2))
            local ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
            local scale = 0.12

            surface.SetFont("InvSmall")
            local txt = "Buy - "..label
            local tw, th = surface.GetTextSize(txt)
            local btnW = math.max(120, tw + 24)
            local btnH = 24
            local halfW, halfH = btnW * 0.5, btnH * 0.5
            local panelW, panelH = btnW + 32, btnH + 16
            local hovered = IsCursorOverBuyButton(self, pos, ang, scale, halfW, halfH)
            cam.Start3D2D(pos, ang, scale)

                surface.SetDrawColor(20,20,20,230)
                surface.DrawRect(-panelW*0.5, -panelH*0.5, panelW, panelH)
                surface.SetDrawColor(50,50,50,255)
                surface.DrawOutlinedRect(-panelW*0.5, -panelH*0.5, panelW, panelH)

                surface.SetDrawColor(hovered and Color(80,80,80,255) or Color(60,60,60,255))
                surface.DrawRect(-halfW, -halfH, btnW, btnH)
                surface.SetDrawColor(120,120,120,255)
                surface.DrawOutlinedRect(-halfW, -halfH, btnW, btnH)

                draw.SimpleText(txt, "InvSmall", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()

            self._buyUI = {pos = pos, ang = ang, scale = scale, halfW = halfW, halfH = halfH}
        // ...existing code...
        end
    end

    function ENT:Think()
        local lp = LocalPlayer()
        if not IsValid(lp) then return end
        if not lp:Alive() then return end

        self._lastBuyTry = self._lastBuyTry or 0
        local overButton = false
        local isBuy = false
        if self:GetNWBool("ForSale", false) and self._buyUI then
            local ui = self._buyUI

            local eye = lp:EyePos()
            local dir = lp:EyeAngles():Forward()
            local hit = util.IntersectRayWithPlane(eye, dir, ui.pos, ui.ang:Up())
            if hit then
                local localPos = WorldToLocal(hit, Angle(0,0,0), ui.pos, ui.ang)
                local x = localPos.x / ui.scale
                local y = -localPos.y / ui.scale
                local halfW = ui.halfW or 80
                local halfH = ui.halfH or 14
                overButton = x >= -halfW and x <= halfW and y >= -halfH and y <= halfH
                isBuy = overButton
            end
        elseif (not self:GetNWBool("ForSale", false)) and self._sellUI then
            local ui = self._sellUI
            local eye = lp:EyePos()
            local dir = lp:EyeAngles():Forward()
            local hit = util.IntersectRayWithPlane(eye, dir, ui.pos, ui.ang:Up())
            if hit then
                local localPos = WorldToLocal(hit, Angle(0,0,0), ui.pos, ui.ang)
                local x = localPos.x / ui.scale
                local y = -localPos.y / ui.scale
                local halfW = ui.halfW or 60
                local halfH = ui.halfH or 11
                overButton = x >= -halfW and x <= halfW and y >= -halfH and y <= halfH
                isBuy = false
            end
        else

            overButton = false
        end

        local pressed = lp:KeyPressed(IN_USE) or input.IsMouseDown and input.IsMouseDown(MOUSE_LEFT)
        if overButton and pressed and CurTime() > self._lastBuyTry + 0.3 then
            self._lastBuyTry = CurTime()
            if isBuy then
                net.Start("Monarch.Item.AttemptBuy")
                    net.WriteEntity(self)
                net.SendToServer()
            else

                OpenListPricePrompt(self)
            end
        end
    end

    net.Receive("Monarch.Item.ShowMenu", function()
        local ent = net.ReadEntity()
        if IsValid(ent) then
            OpenItemInteractionMenu(ent)
        end
    end)
end

if SERVER then

    util.AddNetworkString("Monarch.Item.ShowMenu")
    util.AddNetworkString("Monarch.Item.Pickup")
    util.AddNetworkString("Monarch.Item.ListForSale")
    util.AddNetworkString("Monarch.Item.AttemptBuy")
    util.AddNetworkString("Monarch.Item.CancelSale")

    local function validBuyer(ply, ent)
        local valid = IsValid(ply) and ply:IsPlayer() and IsValid(ent) and (ent:GetClass() == "monarch_item" or ent.ClassName == "monarch_item")
        if not valid then
            print("[DEBUG] validBuyer failed:", ply, ent, ent and ent:GetClass(), ent and ent.ClassName)
        end
        return valid
    end

    net.Receive("Monarch.Item.Pickup", function(_, ply)
        local ent = net.ReadEntity()
        if not validBuyer(ply, ent) then print("[DEBUG] Invalid buyer or entity") return end
        if ent:GetNWBool("ForSale", false) then
            local seller = ent:GetNWEntity("Seller")
            if IsValid(seller) and seller ~= ply then
                if ply.Notify then ply:Notify("This item is listed for sale.") end
                return
            end

        end

        local itemClass = ent.ItemClass or ent:GetNWString("ItemClass", "unknown")
        local count = ent.GetStackAmount and ent:GetStackAmount() or 1
        if ply.GiveInventoryItem and ply:GiveInventoryItem(itemClass, count) then
            ent:Remove()
        else
            if ply.Notify then ply:Notify("Your inventory is full.") end
        end
    end)

    net.Receive("Monarch.Item.ListForSale", function(_, ply)
        local ent = net.ReadEntity()
        local price = math.max(0, math.floor(net.ReadUInt(32) or 0))
        if not validBuyer(ply, ent) then return end
        if price <= 0 then return end
        if ent:GetNWBool("ForSale", false) then
            if ply.Notify then ply:Notify("Item is already for sale.") end
            return
        end

        if ply:GetPos():DistToSqr(ent:GetPos()) > (150*150) then return end

        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then 
            phys:EnableMotion(false)
            phys:Wake()
        end

        ent:UprightOnGround()

        timer.Simple(0.1, function()
            if IsValid(ent) then
                ent:SetNWBool("ForSale", true)
                ent:SetNWInt("SalePrice", price)
                ent:SetNWEntity("Seller", ply)
                if ply.Notify then ply:Notify("Listed for sale at "..((Monarch and Monarch.FormatMoney) and Monarch.FormatMoney(price) or ("$"..price))..".") end
            end
        end)
    end)

    net.Receive("Monarch.Item.AttemptBuy", function(_, ply)
        local ent = net.ReadEntity()
        if not validBuyer(ply, ent) then return end
        if ply:GetPos():DistToSqr(ent:GetPos()) > (150*150) then return end
        if not ent:GetNWBool("ForSale", false) then return end
        local price = tonumber(ent:GetNWInt("SalePrice", 0)) or 0
        local seller = ent:GetNWEntity("Seller")
        if price <= 0 then return end

        local cur = 0
        if ply.GetMoney then
            local ok, res = pcall(ply.GetMoney, ply)
            if ok then cur = tonumber(res) or 0 end
        else
            cur = tonumber(ply:GetNWInt("Money") or 0) or 0
        end
        if cur < price then
            if ply.Notify then ply:Notify("You can't afford this.") end
            return
        end

        if ply.AddMoney then ply:AddMoney(-price) else ply:SetNWInt("Money", math.max(0, cur - price)) end

        if IsValid(seller) and seller:IsPlayer() then
            if seller.AddMoney then seller:AddMoney(price) else seller:SetNWInt("Money", (tonumber(seller:GetNWInt("Money") or 0) or 0) + price) end
        end

        local itemClass = ent.ItemClass or ent:GetNWString("ItemClass", "unknown")
        local count = ent.GetStackAmount and ent:GetStackAmount() or 1
        if ply.GiveInventoryItem and ply:GiveInventoryItem(itemClass, count) then
            ent:Remove()
        else
            if ply.AddMoney then ply:AddMoney(price) else ply:SetNWInt("Money", cur) end
            if ply.Notify then ply:Notify("Inventory full. Purchase cancelled.") end
        end
    end)

    net.Receive("Monarch.Item.CancelSale", function(_, ply)
        local ent = net.ReadEntity()
        if not validBuyer(ply, ent) then return end
        if not ent:GetNWBool("ForSale", false) then return end
        local seller = ent:GetNWEntity("Seller")
        if not IsValid(seller) or seller ~= ply then return end

        ent:SetNWBool("ForSale", false)
        ent:SetNWInt("SalePrice", 0)
        ent:SetNWEntity("Seller", NULL)
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(true) end
        ent:UprightOnGround()
        if ply.Notify then ply:Notify("Sale cancelled.") end
    end)
end

scripted_ents.Register(ENT, "monarch_item")