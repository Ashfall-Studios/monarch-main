if SERVER then
    AddCSLuaFile()
    return
end

eChat = {}

local clr = {
    RPColorG = Color(255,255,255),
    RPColorY = Color(200, 180, 70),
    RPColorW = Color(200, 180, 255),
    white = Color(255, 255, 255),
    gray = Color(170,170,170),
    bezevii = Color(255,150,150),
    yellow = Color(255,170,0),
    red = Color(255, 50, 100),
    blue = Color(100,150,255),
    green = Color(50, 255, 100)
}

eChat.fonts = {
    default = "eChat_28",
    small = "eChat_14",
    medium = "eChat_InputPreview",
    large = "eChat_28",
    radio = "eChat_Radio",
    admin = "eChat_Admin",
    system = "eChat_System",
    announcement = "eChat_Announcement"
}

surface.CreateFont("eChat_Radio", {
    font = "Purista",
    size = 16,
    weight = 600,
    antialias = true,
    shadow = true,
    extended = true,
})

surface.CreateFont("eChat_16", {
    font = "Purista",
    size = 16,
    antialias = true,
    shadow = true,
    extended = true,
})

surface.CreateFont("eChat_14", {
    font = "Purista",
    size = 14,
    weight = 500,
    antialias = true,
    shadow = true,
    extended = true,
})

surface.CreateFont("eChat_28", {
    font = "Purista",
    size = 28,
    weight = 500,
    antialias = true,
    shadow = true,
    extended = true,
})

surface.CreateFont("eChat_Admin", {
    font = "Purista",
    size = 18,
    weight = 700,
    antialias = true,
    shadow = true,
    extended = true,
})

surface.CreateFont("eChat_System", {
    font = "Purista",
    size = 17,
    weight = 500,
    antialias = true,
    shadow = true,
    extended = true,
})

eChat.config = {
    timeStamps = false, 
    position = 1,	
    fadeTime = 12,
    messageFadeTime = 8, 
    messageMaxLifetime = 600, 
    fadeInDuration = 0.2, 
    fadeOutDuration = 2.0, 
    fadeOutStart = 10, 
    passiveHistoryFadeStart = 60,
    passiveHistoryFadeDuration = 8,
    defaultFont = "eChat_36", 
}

surface.CreateFont( "eChat_36", {
    font = "Din Pro Regular",
    size = 19,
    weight = 300,
    antialias = true,
    shadow = true,
    extended = true,
} )

surface.CreateFont( "eChat_Announcement", {
    font = "Din Pro Medium",
    size = 21,
    weight = 500,
    antialias = true,
    shadow = true,
    extended = true,
} )

surface.CreateFont( "eChat_18", {
    font = "Din Pro Medium",
    size = 21,
    weight = 300,
    antialias = true,
    shadow = true,
    extended = true,
} )

surface.CreateFont( "eChat_20", {
    font = "Din Pro Medium",
    size = 21,
    weight = 300,
    antialias = true,
    shadow = true,
    extended = true,
} )

surface.CreateFont( "eChat_InputPreview", {
    font = "Din Pro Medium",
    size = 16,
    weight = 250,
    antialias = true,
    shadow = true,
    extended = true,
} )

local function GetRPName(ply)
    if not IsValid(ply) then return "Unknown" end

    local tempName = ply:GetNWString("temp_rpname", "")
    if tempName and tempName ~= "" then
        return tempName
    end

    local rpName = ply:GetNWString("rpname", "")
    if rpName and rpName ~= "" then
        return rpName
    end

    local pdataName = ply:GetPData("rpname", "")
    if pdataName and pdataName ~= "" then
        return pdataName
    end
end

local function GetDisplayName(ply)
    if not IsValid(ply) then return "Unknown" end

    if Monarch and Monarch.Introductions and Monarch.Introductions.GetDisplayName then
        return Monarch.Introductions.GetDisplayName(ply)
    end

    if ply == LocalPlayer() then
        return GetRPName(ply)
    end

    return "Unknown"
end

eChat.commandOverlay = {}
eChat.filteredCommands = {}
eChat.selectedCommandIndex = 1

local sampleCommands = {
    ["!help"] = {
        description = "Show available commands",
        usage = "!help [command]",
        adminOnly = false,
        aliases = {"/help", "!commands"}
    },
    ["!goto"] = {
        description = "Teleport to a player",
        usage = "!goto <player>",
        adminOnly = true,
        aliases = {}
    },
    ["!setteam"] = {
        description = "Set a player's team",
        usage = "!setteam <player> <team_id>",
        adminOnly = true,
        aliases = {}
    },
    ["/name"] = {
        description = "Set your RP name",
        usage = "/name <new_name>",
        adminOnly = false,
        aliases = {}
    },
    ["/looc"] = {
        description = "Send a local out-of-character message",
        usage = "/looc <message>",
        adminOnly = false,
        aliases = {"//"}
    }
}

local function GetRegisteredCommands()
    if Monarch and Monarch.ChatCommands then
        if Monarch.ChatCommands.registeredCommands then
            return Monarch.ChatCommands.registeredCommands
        end
        if registeredCommands then
            return registeredCommands
        end
    end

    if registeredCommands then
        return registeredCommands
    end

    return sampleCommands
end

local function FilterCommands(input)
    local commands = GetRegisteredCommands()
    local filtered = {}
    local inputLower = string.lower(input)

    for cmdName, cmd in pairs(commands) do
        local canUse = true
        if cmd.adminOnly and not LocalPlayer():IsAdmin() then
            canUse = false
        end

        if canUse then
            local nameMatch = string.find(string.lower(cmdName), inputLower, 1, true) == 1
            local aliasMatch = false

            if cmd.aliases then
                for _, alias in ipairs(cmd.aliases) do
                    if string.find(string.lower(alias), inputLower, 1, true) == 1 then
                        aliasMatch = true
                        break
                    end
                end
            end

            if nameMatch or aliasMatch then
                table.insert(filtered, {
                    name = cmdName,
                    command = cmd,
                    score = nameMatch and 1 or 0.5
                })
            end
        end
    end

    table.sort(filtered, function(a, b)
        if a.score == b.score then
            return a.name < b.name
        end
        return a.score > b.score
    end)

    return filtered
end

local function CreateCommandOverlay()
    if IsValid(eChat.commandOverlay.panel) then
        eChat.commandOverlay.panel:Remove()
    end

    eChat.commandOverlay.panel = vgui.Create("DPanel")
    eChat.commandOverlay.panel:SetParent(eChat.frame)
    eChat.commandOverlay.panel:SetSize(eChat.frame:GetWide() - 10, 200)
    eChat.commandOverlay.panel:SetPos(5, eChat.chatLog:GetTall() - 200)
    eChat.commandOverlay.panel:SetZPos(1000)
    eChat.commandOverlay.panel.Paint = function(self, w, h)

        if not w or not h or w <= 0 or h <= 0 then return end

        surface.SetDrawColor(20, 20, 20, 240)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(60, 60, 60, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        surface.SetDrawColor(40, 40, 40, 255)
        surface.DrawRect(0, 0, w, 25)

        surface.SetFont("eChat_InputPreview")
        local titleText = "Available Commands"
        local titleW, titleH = surface.GetTextSize(titleText)

        if titleW and titleH then 
            draw.SimpleText(titleText, "eChat_InputPreview", 5, 2, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        local startY = 30
        local lineHeight = 16
        local maxVisible = math.floor((h - 35) / lineHeight)

        if not eChat.filteredCommands then
            eChat.filteredCommands = {}
        end

        for i, cmdData in ipairs(eChat.filteredCommands) do
            if i > maxVisible then break end

            local y = startY + (i - 1) * lineHeight
            local isSelected = i == eChat.selectedCommandIndex

            if isSelected then
                surface.SetDrawColor(52, 152, 219, 100)
                surface.DrawRect(2, y - 2, w - 4, lineHeight)
            end

            if cmdData and cmdData.name then
                surface.SetFont("eChat_InputPreview")
                local nameW, nameH = surface.GetTextSize(cmdData.name)

                if nameW and nameH then
                    local nameColor = isSelected and Color(255, 255, 255) or Color(200, 200, 200)
                    draw.SimpleText(cmdData.name, "eChat_InputPreview", 5, y, nameColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end

                if cmdData.command and cmdData.command.description then
                    local desc = cmdData.command.description
                    if string.len(desc) > 60 then
                        desc = string.sub(desc, 1, 57) .. "..."
                    end

                    surface.SetFont("eChat_InputPreview")
                    local descW, descH = surface.GetTextSize(desc)

                    if descW and descH then
                        local descColor = isSelected and Color(220, 220, 220) or Color(150, 150, 150)
                        draw.SimpleText(desc, "eChat_InputPreview", 130, y + 2, descColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    end
                end
            end
        end

        if #eChat.filteredCommands > maxVisible then
            local moreText = "... and " .. (#eChat.filteredCommands - maxVisible) .. " more"
            surface.SetFont("eChat_InputPreview")
            local moreW, moreH = surface.GetTextSize(moreText)

            if moreW and moreH then
                draw.SimpleText(moreText, "eChat_InputPreview", w - 5, h - 15, Color(120, 120, 120), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            end
        end

        if #eChat.filteredCommands == 0 then
            local noText = "No commands found"
            surface.SetFont("eChat_InputPreview")
            local noW, noH = surface.GetTextSize(noText)

            if noW and noH then
                draw.SimpleText(noText, "eChat_InputPreview", 5, startY, Color(255, 100, 100), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
        end
    end

    eChat.commandOverlay.panel:SetVisible(false)
end

local function UpdateCommandOverlay(input)

    if not input or input == "" then
        if IsValid(eChat.commandOverlay.panel) then
            eChat.commandOverlay.panel:SetVisible(false)
        end
        return
    end

    local firstChar = string.sub(input, 1, 1)
    if firstChar ~= "!" and firstChar ~= "/" then
        if IsValid(eChat.commandOverlay.panel) then
            eChat.commandOverlay.panel:SetVisible(false)
        end
        return
    end

    local spacePos = string.find(input, " ")
    local commandPart = spacePos and string.sub(input, 1, spacePos - 1) or input

    eChat.filteredCommands = FilterCommands(commandPart)
    eChat.selectedCommandIndex = 1

    if #eChat.filteredCommands > 0 then
        if not IsValid(eChat.commandOverlay.panel) then
            CreateCommandOverlay()
        end
        eChat.commandOverlay.panel:SetVisible(true)
    else
        if IsValid(eChat.commandOverlay.panel) then
            eChat.commandOverlay.panel:SetVisible(false)
        end
    end
end

local function SelectCommand(direction)
    if #eChat.filteredCommands == 0 then return end

    eChat.selectedCommandIndex = eChat.selectedCommandIndex + direction

    if eChat.selectedCommandIndex < 1 then
        eChat.selectedCommandIndex = #eChat.filteredCommands
    elseif eChat.selectedCommandIndex > #eChat.filteredCommands then
        eChat.selectedCommandIndex = 1
    end

end

local function AutoCompleteCommand()
    if #eChat.filteredCommands == 0 or not eChat.selectedCommandIndex then return end

    local selectedCmd = eChat.filteredCommands[eChat.selectedCommandIndex]
    if selectedCmd then
        local currentText = eChat.entry:GetText()
        local spacePos = string.find(currentText, " ")
        local afterCommand = spacePos and string.sub(currentText, spacePos) or ""

        eChat.entry:SetText(selectedCmd.name .. afterCommand)
        eChat.entry:SetCaretPos(string.len(selectedCmd.name))

        UpdateCommandOverlay(selectedCmd.name)
    end
end

local function CopyColor(col)
    if not col then return Color(255, 255, 255, 255) end
    return Color(col.r or 255, col.g or 255, col.b or 255, col.a or 255)
end

local function BuildChatLine(parent, segments)
    if not IsValid(parent) or not istable(segments) or #segments == 0 then return end

    local line = parent:Add("DPanel")
    line:Dock(TOP)
    line:DockMargin(2, 0, 2, 2)
    line._bornAt = CurTime()

    line._segments = table.Copy(segments)
    line._rows = {}
    line._lastWrapWidth = 0

    local function measure(font, text)
        surface.SetFont(font)
        return surface.GetTextSize(text)
    end

    local function tokenize(text)
        local tokens = {}
        for token in string.gmatch(text, "%S+%s*") do
            table.insert(tokens, token)
        end

        if #tokens == 0 and text ~= "" then
            table.insert(tokens, text)
        end

        return tokens
    end

    function line:RebuildWrap()
        local wrapWidth = math.max((self:GetWide() or 0) - 4, 16)
        if wrapWidth == self._lastWrapWidth and self._rows and #self._rows > 0 then return end

        self._lastWrapWidth = wrapWidth
        self._rows = {{segments = {}, width = 0, height = 16}}

        local function currentRow()
            return self._rows[#self._rows]
        end

        local function newRow()
            table.insert(self._rows, {segments = {}, width = 0, height = 16})
            return currentRow()
        end

        local function addPiece(text, font, color)
            if text == "" then return end

            local row = currentRow()
            local pieceW, pieceH = measure(font, text)

            if row.width > 0 and (row.width + pieceW) > wrapWidth then
                row = newRow()
                text = string.gsub(text, "^%s+", "")
                if text == "" then return end
                pieceW, pieceH = measure(font, text)
            end

            if pieceW <= wrapWidth then
                table.insert(row.segments, {
                    text = text,
                    font = font,
                    color = color
                })
                row.width = row.width + pieceW
                row.height = math.max(row.height, pieceH)
                return
            end

            local chunk = ""
            for i = 1, #text do
                local ch = string.sub(text, i, i)
                local test = chunk .. ch
                local testW = measure(font, test)
                local activeRow = currentRow()
                local remaining = wrapWidth - activeRow.width

                if testW > remaining and chunk ~= "" then
                    addPiece(chunk, font, color)
                    chunk = ch
                elseif testW > wrapWidth then
                    if chunk ~= "" then
                        addPiece(chunk, font, color)
                        chunk = ""
                    end
                    addPiece(ch, font, color)
                else
                    chunk = test
                end
            end

            if chunk ~= "" then
                addPiece(chunk, font, color)
            end
        end

        for _, segment in ipairs(self._segments or {}) do
            local font = segment.font or eChat.config.defaultFont
            local color = segment.color or color_white
            local text = segment.text or ""

            if text ~= "" then
                local pieces = tokenize(text)
                for _, piece in ipairs(pieces) do
                    addPiece(piece, font, color)
                end
            end
        end

        local totalHeight = 0
        for _, row in ipairs(self._rows) do
            totalHeight = totalHeight + math.max(16, row.height)
        end

        self:SetTall(math.max(16, totalHeight + 2))
    end

    line.Think = function(self)
        self:RebuildWrap()
    end

    line.Paint = function(self, w, h)
        local alphaMul = 1
        if not eChat.isBoxOpen then
            local age = CurTime() - (self._bornAt or CurTime())
            local fadeStart = eChat.config.passiveHistoryFadeStart or 60
            local fadeDuration = math.max(0.01, eChat.config.passiveHistoryFadeDuration or 8)
            if age > fadeStart then
                alphaMul = 1 - math.Clamp((age - fadeStart) / fadeDuration, 0, 1)
            end
        end

        local y = 0
        for _, row in ipairs(self._rows or {}) do
            local x = 0
            local rowH = math.max(16, row.height)
            for _, segment in ipairs(row.segments or {}) do
                local c = segment.color or color_white
                local a = math.Clamp((c.a or 255) * alphaMul, 0, 255)
                draw.SimpleText(segment.text, segment.font, x, y, Color(c.r or 255, c.g or 255, c.b or 255, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                surface.SetFont(segment.font)
                local segW = surface.GetTextSize(segment.text)
                x = x + segW
            end
            y = y + rowH
        end
    end
end

local function FlushBufferedChatLine(chatLog)
    if not IsValid(chatLog) or not istable(chatLog._lineSegments) then return end
    if #chatLog._lineSegments == 0 then return end

    BuildChatLine(chatLog, chatLog._lineSegments)
    chatLog._lineSegments = {}

    timer.Simple(0, function()
        if IsValid(chatLog) then
            chatLog:GotoTextEnd()
        end
    end)
end

local function SetupChatLogMethods(chatLog)
    chatLog._lineSegments = {}
    chatLog._currentFont = eChat.config.defaultFont
    chatLog._currentColor = Color(255, 255, 255, 255)

    function chatLog:SetFontInternal(fontName)
        if isstring(fontName) and fontName ~= "" then
            self._currentFont = fontName
        else
            self._currentFont = eChat.config.defaultFont
        end
    end

    function chatLog:InsertColorChange(r, g, b, a)
        self._currentColor = Color(r or 255, g or 255, b or 255, a or 255)
    end

    function chatLog:AppendText(text)
        text = tostring(text or "")
        if text == "" then return end

        local parts = string.Explode("\n", text, false)
        for i, part in ipairs(parts) do
            if part ~= "" then
                table.insert(self._lineSegments, {
                    text = part,
                    font = self._currentFont or eChat.config.defaultFont,
                    color = CopyColor(self._currentColor)
                })
            end

            if i < #parts then
                FlushBufferedChatLine(self)
            end
        end
    end

    function chatLog:SetText(text)
        if text == "" then
            self:Clear()
            self._lineSegments = {}
        end
    end

    function chatLog:GotoTextEnd()
        self:InvalidateLayout(true)
        self:PerformLayout()

        local canvas = self.GetCanvas and self:GetCanvas() or nil
        if IsValid(canvas) then
            canvas:InvalidateLayout(true)
            canvas:SizeToChildren(false, true)
            canvas:PerformLayout()
        end

        local vbar = self:GetVBar()
        if IsValid(vbar) then
            local canvasTall = IsValid(canvas) and (canvas:GetTall() or 0) or 0
            local targetScroll = math.max(0, canvasTall - self:GetTall())
            vbar:SetScroll(targetScroll)

            if IsValid(canvas) and self.ScrollToChild then
                local children = canvas:GetChildren()
                local lastChild = children[#children]
                if IsValid(lastChild) then
                    self:ScrollToChild(lastChild)
                end
            end
        end
    end

    function chatLog:SetVerticalScrollbarEnabled(enabled)
        local vbar = self:GetVBar()
        if IsValid(vbar) then
            vbar:SetEnabled(enabled and true or false)
            vbar:SetVisible(enabled and true or false)
        end
    end
end

function eChat.buildBox()
    eChat.isBoxOpen = false
    eChat.frame = vgui.Create("DFrame")
    eChat.frame:SetSize( ScrW()*0.375, ScrH()*0.35 )
    eChat.frame:SetTitle("")
    eChat.frame:ShowCloseButton( false )
    eChat.frame:SetDraggable( true )
    eChat.frame:SetSizable( true )
    eChat.frame:SetPos( ScrW()*0.0116, (ScrH() - eChat.frame:GetTall()) - ScrH()*0.177)
    eChat.frame:SetMinWidth( 300 )
    eChat.frame:SetMinHeight( 150)
    eChat.frame.Paint = function( self, w, h )
        eChat.blur( self, 10, 20, 255 )

        local gradientMaterial = Material("vgui/gradient-d")
        if gradientMaterial and not gradientMaterial:IsError() then
            surface.SetMaterial(gradientMaterial)
            surface.SetDrawColor(0, 0,0, 240)
            surface.DrawTexturedRect(2, 2, w-4, h-4)
        end

        local gradientMaterial2 = Material("vgui/gradient-u")
        if gradientMaterial2 and not gradientMaterial2:IsError() then
            surface.SetMaterial(gradientMaterial2)
            surface.SetDrawColor(5, 5, 5, 200)
            surface.DrawTexturedRect(2, 2, w-4, h-4)
        end

        if not gradientMaterial or gradientMaterial:IsError() then
            surface.SetDrawColor(15, 10, 20, 240)
            surface.DrawRect(2, 2, w-4, h-4)
        end

        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    end
    eChat.oldPaint = eChat.frame.Paint
    eChat.frame.Think = function()
        if input.IsKeyDown( KEY_ESCAPE ) and IsValid(eChat.frame) then
            eChat.hideBox()
        end
    end

    eChat.entry = vgui.Create("DTextEntry", eChat.frame) 
    eChat.entry:SetSize( eChat.frame:GetWide() - 50, 20 )
    eChat.entry:SetTextColor( color_white )
    eChat.entry:SetFont("eChat_InputPreview")
    eChat.entry:SetDrawBorder( false )
    eChat.entry:SetDrawBackground( false )
    eChat.entry:SetCursorColor( color_white )
    eChat.entry:SetHighlightColor( Color(52, 152, 219) )
    eChat.entry:SetPos( 45, eChat.frame:GetTall() - eChat.entry:GetTall() - 8 )
    eChat.entry.Paint = function( self, w, h )
        surface.SetDrawColor(40, 40, 40, 200)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(20, 20, 20, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        derma.SkinHook( "Paint", "TextEntry", self, w, h )
    end

    eChat.entry.OnTextChanged = function( self )
        if self and self.GetText then 
            local text = self:GetText() or ""
            gamemode.Call( "ChatTextChanged", text )

            UpdateCommandOverlay(text)
        end
    end

    eChat.entry.OnKeyCodeTyped = function( self, code )
        local types = {"", "teamchat", "console"}

        if code == KEY_ESCAPE then
            eChat.hideBox()
            gui.HideGameUI()

        elseif code == KEY_TAB then
            if IsValid(eChat.commandOverlay.panel) and eChat.commandOverlay.panel:IsVisible() then
                AutoCompleteCommand()
                return
            end

            eChat.TypeSelector = (eChat.TypeSelector and eChat.TypeSelector + 1) or 1

            if eChat.TypeSelector > 3 then eChat.TypeSelector = 1 end
            if eChat.TypeSelector < 1 then eChat.TypeSelector = 3 end

            eChat.ChatType = types[eChat.TypeSelector]

            timer.Simple(0.001, function() eChat.entry:RequestFocus() end)

        elseif code == KEY_UP then
            if IsValid(eChat.commandOverlay.panel) and eChat.commandOverlay.panel:IsVisible() then
                SelectCommand(-1)
                return
            end

        elseif code == KEY_DOWN then
            if IsValid(eChat.commandOverlay.panel) and eChat.commandOverlay.panel:IsVisible() then
                SelectCommand(1)
                return
            end

        elseif code == KEY_ENTER then
            local currentText = string.Trim(self:GetText())

            if currentText == "" then
                eChat.TypeSelector = 1
                eChat.hideBox()
                return
            end

            if currentText ~= "" then
                local firstChar = string.sub(currentText, 1, 1)
                local hasSpace = string.find(currentText, " ")

                if (firstChar == "!" or firstChar == "/") then

                    if IsValid(eChat.commandOverlay.panel) and eChat.commandOverlay.panel:IsVisible() and #eChat.filteredCommands > 0 and not hasSpace then
                        local selected = eChat.filteredCommands[eChat.selectedCommandIndex]
                        if selected and selected.name then
                            currentText = selected.name
                            eChat.entry:SetText(currentText)
                            eChat.entry:SetCaretPos(string.len(currentText))
                        end
                    end

                    if eChat.ChatType == types[2] then
                        LocalPlayer():ConCommand("say_team \"" .. currentText .. "\"")
                    elseif eChat.ChatType == types[3] then
                        LocalPlayer():ConCommand(currentText)
                    else
                        LocalPlayer():ConCommand("say \"" .. currentText .. "\"")
                    end

                    eChat.TypeSelector = 1
                    eChat.hideBox()
                    return

                else

                    if eChat.ChatType == types[2] then
                        LocalPlayer():ConCommand("say_team \"" .. currentText .. "\"")
                    elseif eChat.ChatType == types[3] then
                        LocalPlayer():ConCommand(currentText)
                    else
                        LocalPlayer():ConCommand("say \"" .. currentText .. "\"")
                    end

                    eChat.TypeSelector = 1
                    eChat.hideBox()
                    return
                end
            end
        end
    end

    eChat.chatLog = vgui.Create("DScrollPanel", eChat.frame)
    eChat.chatLog:SetSize( eChat.frame:GetWide() - 10, eChat.frame:GetTall() - 40 )
    eChat.chatLog:SetPos( 5, 5 )
    eChat.chatLog._alpha = 0 
    SetupChatLogMethods(eChat.chatLog)
    
    -- Style the scrollbar
    local vbar = eChat.chatLog:GetVBar()
    vbar:SetWide(8)
    vbar:SetHideButtons(true)
    
    vbar.Paint = function(self, w, h)
    end
    
    vbar.btnGrip.Paint = function(self, w, h)
    end
    
    eChat.chatLog.Paint = function( self, w, h )
    end
    eChat.chatLog.Think = function( self )
        if eChat.lastMessage then
            if CurTime() - eChat.lastMessage > eChat.config.fadeTime then
                self:SetVisible( false )
            else
                self:SetVisible( true )
            end
        end
        self:SetSize( eChat.frame:GetWide() - 10, eChat.frame:GetTall() - eChat.entry:GetTall() - 20 )

        if eChat._messageTimestamps and #eChat._messageTimestamps > 0 then
            local now = CurTime()
            local newestMessage = eChat._messageTimestamps[#eChat._messageTimestamps]
            local messageAge = now - newestMessage

            local alpha = 255

            if messageAge < eChat.config.fadeInDuration then
                alpha = math.Clamp((messageAge / eChat.config.fadeInDuration) * 255, 0, 255)

            elseif messageAge > eChat.config.fadeOutStart then
                local fadeProgress = (messageAge - eChat.config.fadeOutStart) / eChat.config.fadeOutDuration
                alpha = math.Clamp((1 - fadeProgress) * 255, 0, 255)
            end

            self._alpha = alpha
        end

        self:GotoTextEnd()

        local vbar = self:GetVBar()
        if IsValid(vbar) then
            local allowScrollbar = eChat.isBoxOpen == true
            vbar:SetEnabled(allowScrollbar)
            vbar:SetVisible(allowScrollbar)
        end
    end
    eChat.oldPaint2 = eChat.chatLog.Paint

    local text = "Say :"

    local say = vgui.Create("DLabel", eChat.frame)
    say:SetText("")
    surface.SetFont( "eChat_InputPreview")
    local w, h = surface.GetTextSize( text )
    say:SetSize( w + 5, 20 )
    say:SetPos( 5, eChat.frame:GetTall() - eChat.entry:GetTall() - 8 )

    say.Paint = function( self, w, h )
        surface.SetDrawColor(40, 40, 40, 200)
        surface.DrawRect(0, 0, w, h)

        surface.SetDrawColor(20, 20, 20, 255)
        surface.DrawOutlinedRect(0, 0, w, h, 1)

        draw.DrawText( text, "eChat_InputPreview", 2, 1, color_white )
    end

    say.Think = function( self )
        local types = {"", "teamchat", "console"}
        local s = {}

        if eChat.ChatType == types[2] then 
            text = "Team :"
        elseif eChat.ChatType == types[3] then
            text = "Cmd :"
        else
            text = "Say :"
            s.pw = 45
            s.sw = eChat.frame:GetWide() - 50
        end

        if s then
            if not s.pw then s.pw = self:GetWide() + 10 end
            if not s.sw then s.sw = eChat.frame:GetWide() - self:GetWide() - 15 end
        end

        local w, h = surface.GetTextSize( text )
        self:SetSize( w + 5, 20 )
        self:SetPos( 5, eChat.frame:GetTall() - eChat.entry:GetTall() - 8 )

        eChat.entry:SetSize( s.sw, 20 )
        eChat.entry:SetPos( s.pw, eChat.frame:GetTall() - eChat.entry:GetTall() - 8 )
    end	

    CreateCommandOverlay()

    eChat.hideBox()
end

function eChat.hideBox()
    eChat.isBoxOpen = false
    eChat.frame.Paint = function() end

    eChat.chatLog.Paint = function(self, w, h)

        if self._alpha and self._alpha < 255 then
            surface.SetAlphaMultiplier(self._alpha / 255)
        end
    end

    eChat.chatLog.PaintOver = function(self, w, h)

        surface.SetAlphaMultiplier(1)
    end

    eChat.chatLog:SetVerticalScrollbarEnabled( false )
    local vbar = eChat.chatLog:GetVBar()
    if IsValid(vbar) then
        vbar:SetVisible(false)
    end
    eChat.chatLog:GotoTextEnd()

    eChat.lastMessage = eChat.lastMessage or CurTime() - eChat.config.fadeTime

    if IsValid(eChat.commandOverlay.panel) then
        eChat.commandOverlay.panel:SetVisible(false)
    end

    local children = eChat.frame:GetChildren()
    for _, pnl in pairs( children ) do
        if pnl == eChat.frame.btnMaxim or pnl == eChat.frame.btnClose or pnl == eChat.frame.btnMinim then continue end

        if pnl != eChat.chatLog then
            pnl:SetVisible( false )
        end
    end

    eChat.frame:SetMouseInputEnabled( false )
    eChat.frame:SetKeyboardInputEnabled( false )
    gui.EnableScreenClicker( false )

    gamemode.Call("FinishChat")

    eChat.entry:SetText( "" )
    gamemode.Call( "ChatTextChanged", "" )
end

function eChat.showBox()
    eChat.isBoxOpen = true
    eChat.frame.Paint = eChat.oldPaint

    eChat.chatLog.Paint = function(self, w, h)

    end

    eChat.chatLog.PaintOver = function(self, w, h)

        surface.SetAlphaMultiplier(1)
    end

    eChat.chatLog:SetVerticalScrollbarEnabled( true )
    local vbar = eChat.chatLog:GetVBar()
    if IsValid(vbar) then
        vbar:SetVisible(true)
    end
    eChat.lastMessage = nil

    local children = eChat.frame:GetChildren()
    for _, pnl in pairs( children ) do
        if pnl == eChat.frame.btnMaxim or pnl == eChat.frame.btnClose or pnl == eChat.frame.btnMinim then continue end

        pnl:SetVisible( true )
    end

    if IsValid(eChat.commandOverlay.panel) then
        eChat.commandOverlay.panel:SetVisible(false)
    end

    eChat.frame:MakePopup()
    eChat.entry:RequestFocus()

    gamemode.Call("StartChat")
end

local blur = Material( "pp/blurscreen" )
function eChat.blur( panel, layers, density, alpha )
    local x, y = panel:LocalToScreen(0, 0)

    surface.SetDrawColor( 255, 255, 255, alpha )
    surface.SetMaterial( blur )

    for i = 1, 3 do
        blur:SetFloat( "$blur", ( i / layers ) * density )
        blur:Recompute()

        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect( -x, -y, ScrW(), ScrH() )
    end
end

local oldAddText = chat.AddText

function chat.AddText(...)
    chat.PlaySound()

    if not eChat.chatLog then
        eChat.buildBox()
    end

    local args = {...}
    local playerObj, messageStr
    local customFont = nil

    if type(args[1]) == "string" and eChat.fonts[args[1]] then
        customFont = eChat.fonts[args[1]]
        table.remove(args, 1) 
    elseif eChat.nextFont then
        customFont = eChat.nextFont
        eChat.nextFont = nil 
    end

    for i, obj in ipairs(args) do
        if IsValid(obj) and obj:IsPlayer() then
            playerObj = obj
        elseif type(obj) == "string" then
            messageStr = obj
        end
    end

    if customFont then
        eChat.chatLog:SetFontInternal(customFont)
    else
        eChat.chatLog:SetFontInternal(eChat.config.defaultFont)
    end

    if IsValid(playerObj) and messageStr and not (string.sub(messageStr, 1, 1) == "!" or string.sub(messageStr, 1, 1) == "/") then
        local teamCol = Color(170,170,200)
        local name = playerObj:GetRPName()
        local text = messageStr

        text = string.Trim(text)
        if string.sub(text, 1, 1) == ":" then
            text = string.Trim(string.sub(text, 2))
        end

        local combineInner = string.match(text, "^<::%s*(.-)%s*::>$")
        if combineInner then
            combineInner = string.Trim(combineInner)
            local innerLastChar = string.sub(combineInner, -1)
            if not string.find(innerLastChar, "[.!?]") then
                combineInner = combineInner .. "."
            end
            text = "<:: " .. combineInner .. " ::>"
        else
            local lastChar = string.sub(text, -1)
            if not string.find(lastChar, "[.!?]") then
                text = text .. "."
            end
        end

        eChat.chatLog:InsertColorChange(teamCol.r, teamCol.g, teamCol.b, 255)
        eChat.chatLog:AppendText(name)
        eChat.chatLog:InsertColorChange(255, 220, 0, 255)
        eChat.chatLog:AppendText(" ")
        eChat.chatLog:AppendText("says ")
        eChat.chatLog:AppendText('"' .. text .. '"')
        eChat.chatLog:AppendText("\n")
    else

        for _, obj in ipairs(args) do
            if type(obj) == "table" then
                eChat.chatLog:InsertColorChange(obj.r, obj.g, obj.b, obj.a or 255)
            elseif type(obj) == "string" then
                eChat.chatLog:AppendText(obj)
            elseif IsValid(obj) and obj:IsPlayer() then
                local col = GAMEMODE.GetTeamColor and GAMEMODE:GetTeamColor(obj) or Color(255,255,255)
                eChat.chatLog:InsertColorChange(col.r, col.g, col.b, 255)
                local displayName = GetDisplayName(obj)
                eChat.chatLog:AppendText(displayName)
            end
        end
        eChat.chatLog:AppendText("\n")
    end

    eChat.chatLog:SetVisible(true)
    eChat.lastMessage = CurTime()
    eChat.chatLog:InsertColorChange(255, 255, 255, 255)

    eChat._messageTimestamps = eChat._messageTimestamps or {}
    table.insert(eChat._messageTimestamps, CurTime())

    eChat.chatLog:GotoTextEnd()

    eChat.chatLog:SetFontInternal(eChat.config.defaultFont)
end

local function CleanupOldMessages()
    if not eChat._messageTimestamps then return end

    local now = CurTime()
    local maxLifetime = eChat.config.messageMaxLifetime or 600 
    local removedAny = false

    for i = #eChat._messageTimestamps, 1, -1 do
        if now - eChat._messageTimestamps[i] > maxLifetime then
            table.remove(eChat._messageTimestamps, i)
            removedAny = true
        end
    end

    if removedAny and IsValid(eChat.chatLog) then

        if #eChat._messageTimestamps == 0 then
            eChat.chatLog:SetText("")
        end

        eChat.chatLog:GotoTextEnd()
    end
end

local originalChatLogThink = nil
hook.Add("Think", "eChat_MessageExpiration", function()
    if not IsValid(eChat.chatLog) then return end

    CleanupOldMessages()
end)

hook.Remove( "ChatText", "echat_joinleave")
hook.Add( "ChatText", "echat_joinleave", function( index, name, text, type )
    if not eChat.chatLog then
        eChat.buildBox()
    end

    if type != "chat" then
        eChat.chatLog:InsertColorChange( 255, 255, 255, 255 )
        eChat.chatLog:AppendText( text.."\n" )
        eChat.chatLog:GotoTextEnd()
        eChat.chatLog:SetVisible( true )
        eChat.lastMessage = CurTime()
        return true
    end
end)

hook.Remove("PlayerBindPress", "echat_hijackbind")
hook.Add("PlayerBindPress", "echat_hijackbind", function(ply, bind, pressed)
    if string.sub( bind, 1, 11 ) == "messagemode" then
        if bind == "messagemode2" then 
            eChat.ChatType = "teamchat"
        else
            eChat.ChatType = ""
        end

        if IsValid( eChat.frame ) then
            eChat.showBox()
        else
            eChat.buildBox()
            eChat.showBox()
        end
        return true
    end
end)

hook.Remove("HUDShouldDraw", "echat_hidedefault")
hook.Add("HUDShouldDraw", "echat_hidedefault", function( name )
    if name == "CHudChat" then
        return false
    end
end)

local oldGetChatBoxPos = chat.GetChatBoxPos
function chat.GetChatBoxPos()
    return eChat.frame:GetPos()
end

function chat.GetChatBoxSize()
    return eChat.frame:GetSize()
end

chat.Open = eChat.showBox
function chat.Close(...) 
    if IsValid( eChat.frame ) then 
        eChat.hideBox(...)
    else
        eChat.buildBox()
        eChat.showBox()
    end
end

eChat.buildBox()