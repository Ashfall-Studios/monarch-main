Monarch = Monarch or {}
Monarch.ChatFonts = Monarch.ChatFonts or {}

Monarch.ChatFonts.Default = "Monarch-Normal"
Monarch.ChatFonts.Small = "Monarch-Small"
Monarch.ChatFonts.Large = "Monarch-Large"
Monarch.ChatFonts.Bold = "Monarch-Bold"
Monarch.ChatFonts.Title = "Monarch-Title"

Monarch.ChatFonts.CommandFonts = {
    ["default"] = "Monarch-Normal",
    ["ic"] = "Monarch-Normal",
    ["ooc"] = "Monarch-Small",
    ["looc"] = "Monarch-Small",
    ["admin"] = "Monarch-Bold",
    ["staff"] = "Monarch-Bold",
    ["system"] = "Monarch-Title",
    ["alert"] = "Monarch-Bold",
    ["whisper"] = "Monarch-Small",
    ["yell"] = "Monarch-Large",
}

function Monarch.GetChatFont(commandType)
    local fontName = Monarch.ChatFonts.CommandFonts[string.lower(commandType or "default")] or Monarch.ChatFonts.Default
    return fontName
end

function Monarch.SetChatFont(commandType, fontName)
    if not commandType or not fontName then return end
    Monarch.ChatFonts.CommandFonts[string.lower(commandType)] = fontName
end

function Monarch.ChatAddTextWithFont(fontName, ...)
    if not fontName or fontName == "" then
        chat.AddText(...)
        return
    end

    local parts = {...}

    pcall(function()
        surface.SetFont(fontName)
    end)

    chat.AddText(unpack(parts))
end

if CLIENT then
    local fonts = {
        ["Monarch-Small"] = {
            font = "Din Pro Medium",
            size = 22,
            weight = 600,
            antialias = true,
            shadow = true
        },
        ["Monarch-Normal"] = {
            font = "Din Pro Medium",
            size = 32,
            weight = 600,
            antialias = true,
            shadow = true
        },
        ["Monarch-Large"] = {
            font = "Din Pro Medium",
            size = 36,
            weight = 600,
            antialias = true,
            shadow = true
        },
        ["Monarch-Bold"] = {
            font = "Din Pro Bold",
            size = 32,
            weight = 700,
            antialias = true,
            shadow = true
        },
        ["Monarch-Title"] = {
            font = "Din Pro Medium",
            size = 42,
            weight = 800,
            antialias = true,
            shadow = true
        }
    }
    
    for fontName, fontData in pairs(fonts) do
        pcall(function()
            surface.CreateFont(fontName, fontData)
        end)
    end
end
