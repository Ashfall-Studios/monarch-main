

if CLIENT then
    local SNAP = nil
    local QUEUE = { current = nil, pending = {}, completed = {} }
    local CRAFT_UI = {
        frame = nil,
        openActive = false,
        recipeScroll = nil,
        renderRecipes = nil,
        horzLayout = nil,
        updateQueue = nil
    }

    local function GetRecipeItemId(recipe)
        if not istable(recipe) then return nil end
        if isstring(recipe.Output) and recipe.Output ~= "" then
            return recipe.Output
        end
        if istable(recipe.Outputs) and recipe.Outputs[1] and isstring(recipe.Outputs[1].id) and recipe.Outputs[1].id ~= "" then
            return recipe.Outputs[1].id
        end
        local item = recipe.item
        if istable(item) then
            local id = item.class or item.id or item.UniqueID
            if isstring(id) and id ~= "" then
                return id
            end
        end
        return nil
    end

    net.Receive("Monarch_Crafting_RecipesChunk", function()
        local startIdx = net.ReadUInt(16)
        local isFinal = net.ReadBool()
        local chunk = net.ReadTable() or {}

        if not CRAFT_UI.openActive or not SNAP then return end

        SNAP._recipeItemIds = SNAP._recipeItemIds or {}

        for _, r in ipairs(chunk) do
            local itemId = GetRecipeItemId(r)
            local key = isstring(itemId) and itemId ~= "" and string.lower(itemId) or nil

            if not key then
                table.insert(SNAP.recipes, r)
            elseif not SNAP._recipeItemIds[key] then
                SNAP._recipeItemIds[key] = true
                table.insert(SNAP.recipes, r)
            end
        end

        if IsValid(CRAFT_UI.recipeScroll) and CRAFT_UI.renderRecipes then
            CRAFT_UI.renderRecipes()
        end
    end)

    net.Receive("Monarch_Crafting_Canceled", function()
        QUEUE = { current = nil, pending = {}, completed = {} }
        if IsValid(CRAFT_UI.horzLayout) then
            CRAFT_UI.horzLayout:Clear()
        end
    end)

    net.Receive("Monarch_Crafting_Update", function()
        local data = net.ReadTable() or { current = nil, pending = {}, completed = {} }
        if not CRAFT_UI.openActive then return end

        QUEUE = data
        if CRAFT_UI.updateQueue then
            CRAFT_UI.updateQueue()
        end
    end)

    net.Receive("Monarch_Crafting_Open", function()
        if IsValid(CRAFT_UI.frame) then
            CRAFT_UI.frame:Remove()
        end

        local ent = net.ReadEntity()
        local base = net.ReadTable() or {}
        SNAP = { benches = base.benches or {}, recipes = {}, queue = base.queue or {}, _recipeItemIds = {} }
        CRAFT_UI.openActive = true

        local frame = vgui.Create("DFrame")
        local sw, sh = ScrW(), ScrH()
        local W, H = sw, sh
        frame:SetSize(W, H)
        frame:SetPos(0, 0)
        frame:SetTitle("")
        frame:ShowCloseButton(false)
        frame:MakePopup()

        frame:SetAlpha(0)
        frame:AlphaTo(255, 0.15, 0)
        frame.topBarH = 28
        frame.Paint = function(s, w, h)

            surface.SetDrawColor(20,20,20,240)
            surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(50,50,50,255)
            surface.DrawOutlinedRect(0,0,w,h,1)
        end
        if Monarch and Monarch.Theme and Monarch.Theme.AttachSkin then Monarch.Theme.AttachSkin(frame) end

        local closeBtn = vgui.Create("DButton", frame)
        closeBtn:SetSize(24, 30)
        closeBtn:SetPos(frame:GetWide() - 48 - closeBtn:GetWide(), math.floor((frame.topBarH - 20) * 0.5))
        closeBtn:SetText("CLOSE X")
        closeBtn:SetFont("InvSmall")
        closeBtn:SetTextColor(color_white)
        closeBtn:SizeToContentsX()
        closeBtn.Paint = function(s, w, h)
            local bg = s:IsHovered() and Color(120,50,50) or Color(90,40,40)
            surface.SetDrawColor(bg)
            surface.DrawRect(0,0,w,h)
            surface.SetDrawColor(140,60,60)
            surface.DrawOutlinedRect(0,0,w,h,1)
        end
        closeBtn.DoClick = function()
            if not IsValid(frame) then return end
            frame:AlphaTo(0, 0.15, 0, function()
                if IsValid(frame) then frame:Remove() end
            end)
        end

        local main = vgui.Create("DPanel", frame)
        main:Dock(FILL)
        main:DockMargin(8, 8, 8, 8)
        main.Paint = function(s, w, h)

            surface.SetDrawColor(20,20,20,200)
            surface.DrawRect(0,0,w,h)
        end

        local benchPanel = vgui.Create("DPanel", main)
        benchPanel:Dock(LEFT)
        benchPanel:SetWide(math.floor(W * 0.14))
        benchPanel.Paint = function(s, w, h)
            surface.SetDrawColor(16,16,16,220)
            surface.DrawRect(0,0,w,h)
        end

        local benchScroll = vgui.Create("DScrollPanel", benchPanel)
        benchScroll:Dock(FILL)
        benchScroll.Paint = function(s, w, h)
            surface.SetDrawColor(16,16,16,220)
            surface.DrawRect(0,0,w,h)
        end
        local selectedBench = "__ALL__" 

        local renderRecipes 
        local pendingRecipeChunks = 0
        local function renderBenchCards()
            benchScroll:Clear()

            local allCard = vgui.Create("DButton", benchScroll)
            allCard:Dock(TOP)
            allCard:DockMargin(0,0,0,8)
            allCard:SetTall(44)
            allCard:SetText("")
            allCard.benchId = "__ALL__"
            allCard.benchName = "All"
            allCard._allowed = true
            function allCard:Paint(w,h)
                local col = (selectedBench == self.benchId) and Color(60,60,60,255) or Color(35,35,35,255)
                draw.RoundedBox(6, 0, 0, w, h, col)
                surface.SetDrawColor(90,90,90,255)
                surface.DrawOutlinedRect(0,0,w,h,2)
                local nameCol = color_white
                local title = self.benchName
                draw.SimpleText(title, "InvMed", 16, h/2, nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                return true
            end
            allCard.DoClick = function()
                selectedBench = allCard.benchId
                renderBenchCards()
                if renderRecipes then renderRecipes() end
            end
            for _, b in ipairs(SNAP.benches or {}) do
                local card = vgui.Create("DButton", benchScroll)
                card:Dock(TOP)
                card:DockMargin(0,0,0,8)
                card:SetTall(44)
                card:SetText("")
                card.benchId = b.id
                card.benchName = b.Name or b.id
                card._allowed = (b.Allowed ~= false)
                card._reqLvl = tonumber(b.RequiredLevel) or 0
                card._playerLvl = tonumber(b.PlayerLevel) or 0
                function card:Paint(w,h)
                    local col = (selectedBench == self.benchId) and Color(60,60,60,255) or Color(35,35,35,255)
                    draw.RoundedBox(6, 0, 0, w, h, col)
                    surface.SetDrawColor(90,90,90,255)
                    surface.DrawOutlinedRect(0,0,w,h,2)
                    local nameCol = self._allowed and color_white or Color(200,160,160)
                    local title = self._allowed and self.benchName or "Locked"
                    draw.SimpleText(title, "InvMed", 16, h/2, nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                    return true
                end
                card.DoClick = function()
                    if not card._allowed then return end
                    selectedBench = card.benchId
                    renderBenchCards()
                    if renderRecipes then renderRecipes() end
                end
            end
        end

        local recipeScroll = vgui.Create("DScrollPanel", main)
        recipeScroll:Dock(LEFT)
        recipeScroll:SetWide(math.floor(W * 0.50))
        recipeScroll:DockMargin(8,0,8,0)
        recipeScroll.Paint = function(s, w, h)
            surface.SetDrawColor(16,16,16,220)
            surface.DrawRect(0,0,w,h)
        end

        local vbar = recipeScroll:GetVBar()
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


        renderRecipes = function()
            recipeScroll:Clear()

            if not selectedBench then
                local hint = vgui.Create("DPanel", recipeScroll)
                hint:Dock(FILL)
                function hint:Paint(w,h)
                    draw.SimpleText("Select a workbench to view recipes", "InvMed", w*0.5, h*0.5-0.08, Color(230,230,230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText("Choose a bench from the left.", "InvSmall", w*0.5, h*0.5+18, Color(200,200,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                return
            end

            local benchAllowedMap = {}
            for _, b in ipairs(SNAP.benches or {}) do benchAllowedMap[b.id] = b.Allowed ~= false end

            for _, r in ipairs(SNAP.recipes or {}) do
                if selectedBench == "__ALL__" or r.Bench == selectedBench then
                    local itemHeight = 80
                    local card = vgui.Create("DButton", recipeScroll)
                    card:Dock(TOP)
                    card:DockMargin(8, 6, 8, 6)
                    card:SetTall(itemHeight)
                    card:SetText("")

                    local locked = (benchAllowedMap[r.Bench] == false) or (r.CanCraft == false)
                    local isIllegal = r.item and r.item.Illegal or false

                    function card:Paint(w, h)

                        local borderCol = Color(90, 90, 90)

                        local base = self:IsHovered() and Color(50, 50, 50, 255) or Color(35, 35, 35, 255)
                        draw.RoundedBox(4, 0, 0, w, h, base)

                        surface.SetDrawColor(borderCol)
                        surface.DrawOutlinedRect(0, 0, w, h, 2)

                        surface.SetDrawColor(60, 60, 60, 180)
                        surface.DrawOutlinedRect(2, 2, w - 4, h - 4, 1)

                        if locked then
                            surface.SetDrawColor(0, 0, 0, 140)
                            surface.DrawRect(0, 0, w, h)
                        end
                        return true
                    end

                    local iconSize = 68
                    local iconX = 8
                    local iconY = (itemHeight - iconSize) / 2

                    local iconContainer = vgui.Create("DPanel", card)
                    iconContainer:SetSize(iconSize, iconSize)
                    iconContainer:SetPos(iconX, iconY)
                    iconContainer.Paint = function(self, w, h)
                        draw.RoundedBox(2, 0, 0, w, h, Color(45, 45, 45, 200))
                        local bcol = isIllegal and Color(150, 100, 100) or Color(80, 80, 80)

                        surface.SetDrawColor(bcol)
                        surface.SetMaterial(Material("icons/inventory/cmb_poly.png"))
                        surface.DrawTexturedRect(0, 0, w-1, h-1)
                    end

                    local icon = vgui.Create("ModelImage", iconContainer)
                    icon:Dock(FILL)
                    icon:DockMargin(2, 2, 2, 2)
                    local mdl = r.item and r.item.Model or ""
                    if mdl and mdl ~= "" then icon:SetModel(mdl) end

                    local nameLabel = vgui.Create("DLabel", card)
                    nameLabel:SetPos(iconX + iconSize + 12, 8)
                    nameLabel:SetSize(300, itemHeight - 16)
                    nameLabel:SetText(r.item and r.item.Name or "Unknown")
                    nameLabel:SetFont("InvMed")
                    nameLabel:SetTextColor(locked and Color(150, 100, 100) or color_white)

                    function card:DoClick()
                        if frame.updatePreview then
                            frame.updatePreview(r)
                        end
                    end

                end
            end
        end

        local previewPanel = vgui.Create("DPanel", frame)
        previewPanel:Dock(RIGHT)
        previewPanel:SetWide(math.floor(W * 0.28))
        previewPanel:DockMargin(8, frame.topBarH + 4, 8, 8)
        previewPanel:SetVisible(false)
        previewPanel.Paint = function(self, w, h)
            surface.SetDrawColor(16,16,16,220)
            surface.DrawRect(0,0,w,h)
        end

        local previewScroll = vgui.Create("DScrollPanel", previewPanel)
        previewScroll:Dock(FILL)
        previewScroll:DockMargin(8, 8, 8, 8)
        previewScroll.Paint = nil

        local vbar = previewScroll:GetVBar()
        vbar.Paint = function(s, w, h)
            surface.SetDrawColor(25, 25, 25, 255)
            surface.DrawRect(0, 0, w, h)
        end
        vbar.btnGrip.Paint = function(s, w, h)
            surface.SetDrawColor(70, 70, 70)
            surface.DrawRect(0, 0, w, h)
        end

        local modelTitleContainer = vgui.Create("DPanel", previewScroll)
        modelTitleContainer:Dock(TOP)
        modelTitleContainer:SetTall(140)
        modelTitleContainer:DockMargin(0, 8, 0, 12)
        modelTitleContainer.Paint = nil

        local modelContainer = vgui.Create("DPanel", modelTitleContainer)
        modelContainer:Dock(LEFT)
        modelContainer:SetWide(130)
        modelContainer:DockMargin(0, 0, 12, 0)
        function modelContainer:Paint(w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 35, 255))
            surface.SetDrawColor(90, 90, 90, 255)

            local bcol = self.isIllegal and Color(150, 100, 100) or Color(80, 80, 80)
            surface.SetDrawColor(bcol)
            surface.DrawOutlinedRect(0, 0, w, h, 2)

            surface.SetMaterial(Material("icons/inventory/cmb_poly.png"))
            surface.DrawTexturedRect(0, 0, w - 1, h -  1)
        end

        local modelPanel = vgui.Create("DModelPanel", modelContainer)
        modelPanel:Dock(FILL)
        modelPanel:DockMargin(4, 4, 4, 4)
        modelPanel:SetCamPos(Vector(60, 90, 0))
        modelPanel:SetLookAt(Vector(0, 0, 0))
        modelPanel:SetFOV(18)
        modelPanel:SetAnimated(false)

        function modelPanel:LayoutEntity(ent)
            ent:SetAngles(Angle(0, 0, 0))
        end

        local titleInfoPanel = vgui.Create("DPanel", modelTitleContainer)
        titleInfoPanel:Dock(FILL)
        titleInfoPanel:DockMargin(8, 0, 0, 0)
        function titleInfoPanel:Paint(w, h)
        end

        local itemName = vgui.Create("DLabel", titleInfoPanel)
        itemName:Dock(TOP)
        itemName:SetTall(40)
        itemName:SetText("Select a recipe")
        itemName:SetFont("InvTitle")
        itemName:SetTextColor(Color(255, 255, 255, 255))
        itemName:SetWrap(false)
        itemName:DockMargin(0, 0, 8, 0)

        function itemName:Paint(w, h)
            local text = self:GetText()
            local x, y = 0, 0
            local maxWidth = w - 4

            surface.SetFont(self:GetFont())
            local textW = surface.GetTextSize(text)
            if textW > maxWidth then
                while text and surface.GetTextSize(text .. "...") > maxWidth and #text > 0 do
                    text = text:sub(1, -2)
                end
                text = text .. "..."
            end

            draw.SimpleText(text, self:GetFont(), x, y, self:GetTextColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            return true
        end

        local infoLabel = vgui.Create("DLabel", titleInfoPanel)
        infoLabel:Dock(FILL)
        infoLabel:SetText("")
        infoLabel:SetFont("InvSmall")
        infoLabel:SetTextColor(Color(200, 200, 200, 255))
        infoLabel:SetWrap(true)
        infoLabel:DockMargin(0, 4, 8, 0)

        local itemDesc = vgui.Create("DLabel", previewScroll)
        itemDesc:SetText("")
        itemDesc:SetFont("InvSmall")
        itemDesc:SetTextColor(Color(200, 200, 200))
        itemDesc:Dock(TOP)
        itemDesc:SetTall(60)
        itemDesc:DockMargin(12, 0, 12, 12)
        itemDesc:SetWrap(true)

        local matsContainer = vgui.Create("DPanel", previewScroll)
        matsContainer:Dock(TOP)
        matsContainer:SetTall(120)
        matsContainer:DockMargin(0, 0, 0, 0)
        function matsContainer:Paint(w, h)
        end

        local matsHeader = vgui.Create("DPanel", matsContainer)
        matsHeader:Dock(TOP)
        matsHeader:SetTall(20)
        matsHeader:DockMargin(8, 8, 8, 4)
        function matsHeader:Paint() end

        local matsHeaderRight = vgui.Create("DLabel", matsHeader)
        matsHeaderRight:Dock(RIGHT)
        matsHeaderRight:SetWide(64)
        matsHeaderRight:DockMargin(0, 0, 4, 0)
        matsHeaderRight:SetText("Inventory")
        matsHeaderRight:SetFont("InvSmall")
        matsHeaderRight:SetTextColor(Color(200, 200, 200))
        matsHeaderRight:SetContentAlignment(6) 

        local matsHeaderLeft = vgui.Create("DLabel", matsHeader)
        matsHeaderLeft:Dock(FILL)
        matsHeaderLeft:SetText("Ingredients")
        matsHeaderLeft:SetFont("InvSmall")
        matsHeaderLeft:SetTextColor(Color(200, 200, 200))
        matsHeaderLeft:SetContentAlignment(4) 

        local matsList = vgui.Create("DScrollPanel", matsContainer)
        matsList:Dock(FILL)
        matsList:DockMargin(8, 0, 8, 4)
        function matsList:Paint(w, h)

            return true
        end

        local matsVBar = matsList:GetVBar()
        if matsVBar then
            matsVBar.Paint = function(s, w, h)
                surface.SetDrawColor(25, 25, 25, 255)
                surface.DrawRect(0, 0, w, h)
            end
            matsVBar.btnGrip.Paint = function(s, w, h)
                surface.SetDrawColor(70, 70, 70)
                surface.DrawRect(0, 0, w, h)
            end
        end

        local outputsContainer = vgui.Create("DPanel", previewScroll)
        outputsContainer:Dock(TOP)
        outputsContainer:SetTall(100)
        outputsContainer:DockMargin(0, 4, 0, 0)
        function outputsContainer:Paint(w, h)
        end

        local outputsHeader = vgui.Create("DPanel", outputsContainer)
        outputsHeader:Dock(TOP)
        outputsHeader:SetTall(20)
        outputsHeader:DockMargin(8, 8, 8, 4)
        function outputsHeader:Paint() end

        local outputsHeaderRight = vgui.Create("DLabel", outputsHeader)
        outputsHeaderRight:Dock(RIGHT)
        outputsHeaderRight:SetWide(64)
        outputsHeaderRight:DockMargin(0, 0, 4, 0)
        outputsHeaderRight:SetText("Amount")
        outputsHeaderRight:SetFont("InvSmall")
        outputsHeaderRight:SetTextColor(Color(200, 200, 200))
        outputsHeaderRight:SetContentAlignment(6)

        local outputsHeaderLeft = vgui.Create("DLabel", outputsHeader)
        outputsHeaderLeft:Dock(FILL)
        outputsHeaderLeft:SetText("Outputs")
        outputsHeaderLeft:SetFont("InvSmall")
        outputsHeaderLeft:SetTextColor(Color(200, 200, 200))
        outputsHeaderLeft:SetContentAlignment(4)

        local outputsList = vgui.Create("DScrollPanel", outputsContainer)
        outputsList:Dock(FILL)
        outputsList:DockMargin(8, 0, 8, 4)
        function outputsList:Paint(w, h)

            return true
        end

        local outputsVBar = outputsList:GetVBar()
        if outputsVBar then
            outputsVBar.Paint = function(s, w, h)
                surface.SetDrawColor(25, 25, 25, 255)
                surface.DrawRect(0, 0, w, h)
            end
            outputsVBar.btnGrip.Paint = function(s, w, h)
                surface.SetDrawColor(70, 70, 70)
                surface.DrawRect(0, 0, w, h)
            end
        end

        local function getInventoryCount(itemId)
            local sid = IsValid(LocalPlayer()) and LocalPlayer():SteamID64() or nil
            if not sid then return 0 end
            local inv = Monarch and Monarch.Inventory and Monarch.Inventory.Data and Monarch.Inventory.Data[sid]
            if not inv then return 0 end

            local ref = (Monarch.Inventory and Monarch.Inventory.ItemsRef) or {}
            local target = ref[itemId] or itemId
            local total = 0

            for _, item in pairs(inv) do
                local cls = item and (item.class or item.id)
                if cls then
                    local mapped = ref[cls] or cls
                    if mapped == target then
                        total = total + (tonumber(item.amount) or 1)
                    end
                end
            end

            return total
        end

        local function getItemDisplayName(itemId)
            if not itemId then return "Unknown" end
            local inv = Monarch and Monarch.Inventory
            local ref = inv and inv.ItemsRef
            local items = inv and inv.Items
            local mapped = ref and ref[itemId] or itemId
            local def = items and mapped and items[mapped]
            if def and def.Name and def.Name ~= "" then
                return def.Name
            end
            return tostring(itemId)
        end

        local craftBtn = vgui.Create("DButton", previewPanel)
        craftBtn:Dock(BOTTOM)
        craftBtn:SetTall(44)
        craftBtn:DockMargin(8, 8, 8, 8)
        craftBtn:SetText("CRAFT")
        craftBtn:SetFont("InvMed")
        craftBtn:SetTextColor(color_white)
        craftBtn.Paint = function(s, w, h)
            s:SetCursor(s:IsEnabled() and "hand" or "arrow")
            local hover = s:IsEnabled() and s:IsHovered()
            local bg = hover and Color(60, 60, 60, 255) or Color(35, 35, 35, 255)
            draw.RoundedBox(4, 0, 0, w, h, bg)
            surface.SetDrawColor(90, 90, 90, 255)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
            surface.SetDrawColor(60, 60, 60, 180)
            surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)
            local textCol = s:IsEnabled() and color_white or Color(150, 100, 100)
            draw.SimpleText(s:GetText(), s:GetFont(), w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return true
        end
        craftBtn.DoClick = function()
            if not craftBtn:IsEnabled() then return end
            if frame.selectedRecipe then
                net.Start("Monarch_Crafting_RequestCraft")
                net.WriteTable(frame.selectedRecipe)
                net.SendToServer()
            end
        end

        local function checkCraftButtonState(recipe)
            if not recipe or not recipe.Mats then
                craftBtn:SetEnabled(true)
                craftBtn:SetText("CRAFT")
                return
            end

            for itemId, needed in pairs(recipe.Mats) do
                local have = getInventoryCount(itemId)
                if have < tonumber(needed) then
                    craftBtn:SetEnabled(false)
                    craftBtn:SetText("CRAFT (Not Enough Materials)")
                    return
                end
            end

            craftBtn:SetEnabled(true)
            craftBtn:SetText("CRAFT")
        end

        local function updatePreview(recipe)
            frame.selectedRecipe = recipe
            if not recipe or not recipe.item then
                modelPanel:SetModel("")
                itemName:SetText("Select a recipe")
                itemDesc:SetText("")
                infoLabel:SetText("")
                matsList:Clear()
                outputsList:Clear()
                previewPanel:SetVisible(false)
                craftBtn:SetEnabled(false)
                craftBtn:SetText("CRAFT")
                return
            end


            previewPanel:SetVisible(true)

            local item = recipe.item
            if item and item.Model and item.Model ~= "" then
                modelPanel:SetModel(item.Model)
                modelPanel:SetAnimated(false)
            else
                modelPanel:SetModel("models/error.mdl")
            end

            modelContainer.isIllegal = item and item.Illegal or false
            itemName:SetText(item and item.Name or "Unknown Item")
            itemDesc:SetText(item and item.Description or "No description")

            local duration = tonumber(recipe.Time) or 0
            local skillReq = tonumber(recipe.NeedLevel) or 1
            local skillName = recipe.Skill or recipe.SkillName or "Crafting"

            infoLabel:SetText(string.format("Duration: %ds\nSkill: %s", duration, skillName))

            matsList:Clear()
            outputsList:Clear()

            local hasMats = false
            local matsRowCount = 0
            if recipe.Mats and next(recipe.Mats) then
                hasMats = true
                for itemId, take in pairs(recipe.Mats) do
                    matsRowCount = matsRowCount + 1
                    local t = tonumber(take) or 1
                    local matItemName = (recipe.MatsNice and recipe.MatsNice[itemId]) or tostring(itemId)

                    local matRow = vgui.Create("DPanel", matsList)
                    matRow:Dock(TOP)
                    matRow:SetTall(22)
                    matRow:DockMargin(0, 2, 0, 0)
                    function matRow:Paint(w, h)
                        surface.SetDrawColor(45, 45, 45, 100)
                        surface.DrawRect(0, 0, w, h)
                        return true
                    end

                    local matLabel = vgui.Create("DLabel", matRow)
                    matLabel:Dock(FILL)
                    matLabel:DockMargin(6, 0, 6, 0)
                    matLabel:SetText(string.format("%dx %s", t, matItemName))
                    matLabel:SetFont("InvSmall")
                    matLabel:SetTextColor(Color(220, 220, 220))
                    matLabel:SetContentAlignment(4) 

                    local invLabel = vgui.Create("DLabel", matRow)
                    invLabel:Dock(RIGHT)
                    invLabel:SetWide(64)
                    invLabel:DockMargin(0, 0, 4, 0)
                    invLabel:SetText(tostring(getInventoryCount(itemId)))
                    invLabel:SetFont("InvSmall")
                    invLabel:SetTextColor(Color(180, 180, 180))
                    invLabel:SetContentAlignment(6) 
                end
            elseif recipe.Materials and #recipe.Materials > 0 then
                hasMats = true
                for _, mat in ipairs(recipe.Materials) do
                    matsRowCount = matsRowCount + 1
                    local needed = tonumber(mat.amount) or 1

                    local matRow = vgui.Create("DPanel", matsList)
                    matRow:Dock(TOP)
                    matRow:SetTall(22)
                    matRow:DockMargin(0, 2, 0, 0)
                    function matRow:Paint(w, h)
                        surface.SetDrawColor(45, 45, 45, 100)
                        surface.DrawRect(0, 0, w, h)
                        return true
                    end

                    local matLabel = vgui.Create("DLabel", matRow)
                    matLabel:Dock(FILL)
                    matLabel:DockMargin(6, 0, 6, 0)
                    matLabel:SetText(string.format("%dx %s", needed, mat.name or "Unknown"))
                    matLabel:SetFont("InvSmall")
                    matLabel:SetTextColor(Color(220, 220, 220))
                    matLabel:SetContentAlignment(4) 

                    local invLabel = vgui.Create("DLabel", matRow)
                    invLabel:Dock(RIGHT)
                    invLabel:SetWide(64)
                    invLabel:DockMargin(0, 0, 4, 0)
                    invLabel:SetText(tostring(getInventoryCount(mat.id or mat.name)))
                    invLabel:SetFont("InvSmall")
                    invLabel:SetTextColor(Color(180, 180, 180))
                    invLabel:SetContentAlignment(6) 
                end
            end

            if not hasMats then
                matsRowCount = 1
                local noMats = vgui.Create("DLabel", matsList)
                noMats:Dock(TOP)
                noMats:SetTall(22)
                noMats:SetText("No materials required")
                noMats:SetFont("InvSmall")
                noMats:SetTextColor(Color(150, 150, 150))
            end

            matsContainer:SetTall(36 + (matsRowCount * 24) + 4)

            local outputs = {}
            if recipe.Outputs and #recipe.Outputs > 0 then
                for _, output in ipairs(recipe.Outputs) do
                    if istable(output) and output.id and output.id ~= "" then
                        outputs[#outputs + 1] = {
                            id = output.id,
                            amount = math.max(1, math.floor(tonumber(output.amount) or 1))
                        }
                    end
                end
            elseif recipe.Output and recipe.Output ~= "" then
                outputs[#outputs + 1] = { id = recipe.Output, amount = 1 }
            end

            local outputsRowCount = 0
            if #outputs > 0 then
                outputsRowCount = #outputs
                table.sort(outputs, function(a, b)
                    return tostring(a.id) < tostring(b.id)
                end)

                for _, output in ipairs(outputs) do
                    local outputName = getItemDisplayName(output.id)

                    local outputRow = vgui.Create("DPanel", outputsList)
                    outputRow:Dock(TOP)
                    outputRow:SetTall(22)
                    outputRow:DockMargin(0, 2, 0, 0)
                    function outputRow:Paint(w, h)
                        surface.SetDrawColor(45, 45, 45, 100)
                        surface.DrawRect(0, 0, w, h)
                        return true
                    end

                    local outputLabel = vgui.Create("DLabel", outputRow)
                    outputLabel:Dock(FILL)
                    outputLabel:DockMargin(6, 0, 6, 0)
                    outputLabel:SetText(outputName)
                    outputLabel:SetFont("InvSmall")
                    outputLabel:SetTextColor(Color(220, 220, 220))
                    outputLabel:SetContentAlignment(4)

                    local amountLabel = vgui.Create("DLabel", outputRow)
                    amountLabel:Dock(RIGHT)
                    amountLabel:SetWide(64)
                    amountLabel:DockMargin(0, 0, 4, 0)
                    amountLabel:SetText(tostring(output.amount))
                    amountLabel:SetFont("InvSmall")
                    amountLabel:SetTextColor(Color(180, 180, 180))
                    amountLabel:SetContentAlignment(6)
                end
            else
                outputsRowCount = 1
                local noOutputs = vgui.Create("DLabel", outputsList)
                noOutputs:Dock(TOP)
                noOutputs:SetTall(22)
                noOutputs:SetText("No outputs configured")
                noOutputs:SetFont("InvSmall")
                noOutputs:SetTextColor(Color(150, 150, 150))
            end

            outputsContainer:SetTall(36 + (outputsRowCount * 24) + 4)

            matsList:InvalidateLayout(true)
            matsContainer:InvalidateLayout(true)
            outputsList:InvalidateLayout(true)
            outputsContainer:InvalidateLayout(true)
            previewScroll:InvalidateLayout(true)

            checkCraftButtonState(recipe)
        end

        frame.updatePreview = updatePreview

        CRAFT_UI.frame = frame
        CRAFT_UI.recipeScroll = recipeScroll
        CRAFT_UI.renderRecipes = renderRecipes

    renderBenchCards()
    renderRecipes()

        local queuePanel = vgui.Create("DPanel", frame)
        queuePanel:Dock(BOTTOM)
        queuePanel:SetTall(math.floor(H * 0.22))
        queuePanel:DockMargin(8, 8, 8, 8)
        queuePanel.Paint = function(s, w, h)
            surface.SetDrawColor(16,16,16,220)
            surface.DrawRect(0,0,w,h)
        end

        local qtitle = vgui.Create("DLabel", queuePanel)
        qtitle:Dock(TOP)
    qtitle:SetText("Queue")
    qtitle:SetFont("InvTitle")
        qtitle:SizeToContents()
        qtitle:DockMargin(8,8,8,8)

        local horzLayout = vgui.Create("DPanel", queuePanel)
        horzLayout:Dock(FILL)
        horzLayout.Paint = nil
        function horzLayout:PerformLayout()

            local x = 8
            local y = 8
            for _, child in ipairs(self:GetChildren()) do
                if IsValid(child) then
                    child:SetPos(x, y)
                    x = x + child:GetWide() + 8
                end
            end
        end

        local claimBtn = vgui.Create("DButton", queuePanel)
        claimBtn:Dock(BOTTOM)
        claimBtn:SetTall(44)
        claimBtn:DockMargin(8, 8, 8, 8)
        claimBtn:SetText("CLAIM ITEMS")
        claimBtn:SetFont("InvMed")
        claimBtn:SetTextColor(color_white)
        claimBtn.Paint = function(s, w, h)
            s:SetCursor(s:IsEnabled() and "hand" or "arrow")
            local hover = s:IsEnabled() and s:IsHovered()
            local bg = hover and Color(60, 60, 60, 255) or Color(35, 35, 35, 255)
            draw.RoundedBox(4, 0, 0, w, h, bg)
            surface.SetDrawColor(90, 90, 90, 255)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
            surface.SetDrawColor(60, 60, 60, 180)
            surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)
            local textCol = s:IsEnabled() and color_white or Color(150, 100, 100)
            draw.SimpleText(s:GetText(), s:GetFont(), w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return true
        end
        claimBtn.DoClick = function()
            if not claimBtn:IsEnabled() then return end
            net.Start("Monarch_Crafting_ClaimRewards")
            net.SendToServer()
        end

        local function updateQueue()

            if not IsValid(horzLayout) then return end

            horzLayout:Clear()

            local hasCompleted = QUEUE.completed and #QUEUE.completed > 0
            claimBtn:SetEnabled(hasCompleted)

            if frame.selectedRecipe then
                checkCraftButtonState(frame.selectedRecipe)
            end

            if QUEUE.current then
                local newCurrentCard = vgui.Create("DPanel", horzLayout)
                newCurrentCard:SetSize(70, 70)
                newCurrentCard:SetText("")
                function newCurrentCard:Paint(w,h)
                    local base = Color(35,35,35,255)
                    draw.RoundedBox(6, 0, 0, w, h, base)
                    surface.SetDrawColor(90,90,90,255)
                    surface.DrawOutlinedRect(0,0,w,h,2)
                    surface.SetDrawColor(60,60,60,120)
                    surface.DrawOutlinedRect(1,1,w-2,h-2,1)
                    local frac = tonumber(self._frac or 0) or 0
                    local barW, barH = w - 8, 6
                    local x, y = 4, h - barH - 4
                    surface.SetDrawColor(Color(60,60,60,180))
                    surface.DrawRect(x, y, barW, barH)
                    surface.SetDrawColor(Color(120,180,120))
                    surface.DrawRect(x, y, math.max(0, math.min(barW, barW * frac)), barH)
                end

                local mdl = ""
                for _, r in ipairs(SNAP.recipes or {}) do
                    if r.idx == QUEUE.current.idx then
                        mdl = (r.item and r.item.Model) or ""
                        break
                    end
                end

                local newCurrentModel = vgui.Create("ModelImage", newCurrentCard)
                newCurrentModel:Dock(FILL)
                newCurrentModel:DockMargin(2, 2, 2, 10)
                if mdl and mdl ~= "" then
                    newCurrentModel:SetModel(mdl)
                end

                local duration = math.max(0.01, (QUEUE.current.endTime or 0) - (QUEUE.current.startTime or 0))
                local remain = math.max(0, (QUEUE.current.endTime or 0) - CurTime())
                local frac = 1 - (remain / duration)
                newCurrentCard._frac = frac
            end

            local allQueuedItems = {}
            for i, e in ipairs(QUEUE.pending or {}) do
                table.insert(allQueuedItems, { item = e, isCompleted = false, index = i })
            end
            for i, e in ipairs(QUEUE.completed or {}) do
                table.insert(allQueuedItems, { item = e, isCompleted = true, index = i })
            end

            for _, qItem in ipairs(allQueuedItems) do
                local e = qItem.item
                local nm = e.Output
                local mdl = ""
                local duration = 0
                for _, r in ipairs(SNAP.recipes or {}) do
                    if r.idx == e.idx then
                        nm = (r.item and r.item.Name) or r.Output
                        mdl = (r.item and r.item.Model) or ""
                        duration = r.Time or 0
                        break
                    end
                end

                local cardSize = 70
                local card = vgui.Create("DButton", horzLayout)
                card:SetSize(cardSize, cardSize)
                card:SetText("")
                card._progress = 0 

                function card:Paint(w, h)
                    draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 35, 255))
                    local borderCol = qItem.isCompleted and Color(120, 180, 120) or Color(90, 90, 90)
                    surface.SetDrawColor(borderCol, 255)
                    surface.DrawOutlinedRect(0, 0, w, h, 2)
                    surface.SetDrawColor(60, 60, 60, 180)
                    surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)

                    local barH = 6
                    local barY = h - barH - 2
                    surface.SetDrawColor(Color(60, 60, 60, 180))
                    surface.DrawRect(2, barY, w - 4, barH)
                    if qItem.isCompleted then
                        surface.SetDrawColor(Color(120, 180, 120))
                        surface.DrawRect(2, barY, w - 4, barH)
                    else
                        surface.SetDrawColor(Color(100, 180, 100))
                        surface.DrawRect(2, barY, (w - 4) * self._progress, barH)
                    end

                    return true
                end

                local icon = vgui.Create("ModelImage", card)
                icon:Dock(FILL)
                icon:DockMargin(2, 2, 2, 10)
                if mdl and mdl ~= "" then icon:SetModel(mdl) end

                card.DoClick = function()
                    if not qItem.isCompleted then
                        net.Start("Monarch_Crafting_CancelItem")
                        net.WriteUInt(qItem.index, 16)
                        net.SendToServer()
                    end
                end
            end

            horzLayout:InvalidateLayout(true)
        end

        CRAFT_UI.horzLayout = horzLayout
        CRAFT_UI.updateQueue = updateQueue

        function frame:OnRemove()
            CRAFT_UI.openActive = false

            if CRAFT_UI.frame == self then
                CRAFT_UI.frame = nil
                CRAFT_UI.recipeScroll = nil
                CRAFT_UI.renderRecipes = nil
                CRAFT_UI.horzLayout = nil
                CRAFT_UI.updateQueue = nil
            end

            if LocalPlayer and LocalPlayer():IsValid() then
                net.Start("Monarch_Crafting_CancelAll")
                net.SendToServer()
            end
        end

        updateQueue()
        frame.Think = function()

            if IsValid(frame) then updateQueue() end
        end
    end)
end

