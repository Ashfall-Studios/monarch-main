local refWidth = 1920
local refHeight = 1080

local screenWidth = ScrW()
local screenHeight = ScrH()

local scaleX = screenWidth / refWidth
local scaleY = screenHeight / refHeight

function scaleFont(x)
    return x * math.min(scaleX, scaleY) 
end

surface.CreateFont("MonarchZone_TypeWriter", {
    font = "Din Pro Bold",
    size = 24,
    weight = 300,
    italic = true,
    antialias = true,
})

surface.CreateFont("MonarchZone_TypeWriterNoItalic", {
    font = "Din Pro Bold",
    size = 24,
    weight = 300,
    italic = true,
    antialias = true,
})

surface.CreateFont("MonarchZone_Time", {
    font = "Din Pro Medium",
    size = 24,
    italic = true,
    weight = 300,
    antialias = true,
})

surface.CreateFont("Monarch-Normal", {
    font = "Moonstrike",
    extended = false,
    size = scaleFont(25),
    weight = 500,
    antialias = true,
    shadow = false
})

surface.CreateFont("Monarch-Small", {
    font = "Moonstrike",
    extended = false,
    size = scaleFont(20),
    bold = true,
    weight = 500,
    antialias = true,
    shadow = false
})

surface.CreateFont("Monarch-LightUI16", {
    font = "GinesoSoft-ExtBoo",
    extended = false,
    size = scaleFont(20),
    weight = 200,
    bold = true,
    antialias = true,
    shadow = false
})

surface.CreateFont("Monarch-LightUI20", {
    font = "GinesoSoft-ExtBoo",
    extended = false,
    size = scaleFont(20),
    weight = 200,
    antialias = true,
    shadow = false
})

surface.CreateFont("Monarch-Large", {
    font = "Moonstrike",
    extended = false,
    size = scaleFont(35),
    bold = true,
    weight = 500,
    antialias = true,
    shadow = false
})

surface.CreateFont("Monarch-LightUI35", {
    font = "Arial",
    size = scaleFont(35),
    weight = 25,
    bold = false,
    antialias = true,
    shadow = false
})

surface.CreateFont("Monarch-SemiboldUI25", {
    font = "GinesoSoft-ExtBoo",
    extended = false,
    size = scaleFont(35),
    weight = 200,
    antialias = true,
    shadow = false
})

surface.CreateFont("Monarch-LightUI45", {
    font = "Arial",
    extended = false,
    size = scaleFont(45),
    bold = false,
    weight = 25,
    antialias = true,
    shadow = false
})

surface.CreateFont("Monarch-Huge", {
    font = "Moonstrike",
    extended = false,
    size = scaleFont(45),
    bold = true,
    weight = 500,
    antialias = true,
    shadow = false
})

surface.CreateFont("Monarch-SuperLarge", {
    font = "Moonstrike",
    extended = false,
    size = scaleFont(200),
    bold = true,
    weight = 500,
    antialias = true,
    shadow = false
})

surface.CreateFont("Monarch-Tiny", {
    font = "Roboto-Thin",
    extended = false,
    size = scaleFont(18),
    bold = true,
    weight = 250,
    antialias = true,
    shadow = false
})

surface.CreateFont("DermaDefault", {
    font = "GinesoSoft-ExtBoo",
    extended = false,
    size = 15,
    weight = 500,
    antialias = true,
    shadow = false
})

surface.CreateFont("DermaDefaultBold", {
    font = "GinesoSoft-ExtBoo",
    extended = false,
    bold = true,
    size = 15,
    weight = 500,
    antialias = true,
    shadow = false
})

surface.CreateFont("Monarch-HUDUI.36", {    
    font = "ITC Avant Garde Std Bk",
    extended = false,
    bold = true,
    size = scaleFont(36),
    weight = 500,
    antialias = true,
    shadow = false
})

surface.CreateFont("MChar_Title",  {font="Roboto", size=48, weight=800, antialias=true})
surface.CreateFont("MChar_SubHUD",  {font="Roboto", size=32, weight=800, shadow=true, antialias=true})
surface.CreateFont("MChar_Sub",    {font="Roboto", size=24, weight=600, antialias=true})
surface.CreateFont("MChar_Text",   {font="Roboto", size=18, weight=500, antialias=true})
surface.CreateFont("MChar_Button", {font="Roboto", size=20, weight=600, antialias=true})

surface.CreateFont("Inventory_Title",  {font="Din Pro Bold", size=48, weight=600, shadow = true, antialias=true})
surface.CreateFont("Inventory_SubTitle",  {font="Din Pro Bold", size=24, weight=600, shadow = true, antialias=true})

surface.CreateFont("MainmenuLarge", {
	font = "Purista",
	size = 100,
	weight = 100,
	antialias = true,
    shadow = true,
	blursize = 0
})

surface.CreateFont("MainmenuMedium", {
	font = "Purista",
	size = 60,
	weight = 100,
	antialias = true,
    shadow = true,
	blursize = 0
})

surface.CreateFont("MainmenuSmall", {
    font = "Purista",
    size = 45,
    weight = 100,
    antialias = true,
    shadow = true,
    blursize = 0
})

surface.CreateFont("SplashSmall", {
    font = "Purista",
    size = 35,
    weight = 100,
    antialias = true,
    shadow = true,
    blursize = 0
})

surface.CreateFont("SkillsTitle", {
    font = "Din Pro Bold",
    size = 28,
    weight = 100,
    antialias = true,
    shadow = true,
    blursize = 0
})

surface.CreateFont("SkillsLabel", {
    font = "Din Pro Regular",
    size = 22,
    weight = 100,
    antialias = true,
    shadow = true,
    blursize = 0
})

surface.CreateFont("InvMed", {
    font = "Din Pro Medium",
    size = 25,
    weight = 100,
    antialias = true,
    shadow = true,
    blursize = 0
})

surface.CreateFont("InvMedLight", {
    font = "Din Pro Regular",
    size = 25,
    weight = 100,
    antialias = true,
    shadow = true,
    blursize = 0
})

surface.CreateFont("InvSmall", {
    font = "Din Pro Medium",
    size = 17,
    weight = 100,
    antialias = true,
    shadow = true,
    blursize = 0
})

surface.CreateFont("InvStackSmall", {
    font = "Din Pro Regular",
    size = 19,
    weight = 100,
    antialias = true,
    blursize = 0
})

surface.CreateFont("InvSmallItalic", {
    font = "Din Pro Medium",
    size = 17,
    weight = 100,
    antialias = true,
    shadow = true,
    blursize = 0,
    italic = true
})

surface.CreateFont("InvLarge", {
    font = "Din Pro Medium",
    size = 50,
    weight = 100,
    antialias = true,
    shadow = true,
    blursize = 0
})

surface.CreateFont("InvLargeShadow", {
    font = "Din Pro Medium",
    size = 50,
    weight = 100,
    antialias = true,
    shadow = true,
    blursize = 0
})

surface.CreateFont("InvTitle", {
    font = "Din Pro Medium",
    size = 38,
    weight = 100,
    antialias = true,
    shadow = true,
    blursize = 0
})

surface.CreateFont("ThickUI-Element23", {
	font = "Din Pro Regular",
	size = 23,
	weight = 100,
	antialias = true,
	blursize = 0
})

surface.CreateFont("ThickUI-Element23Shadow", {
	font = "Din Pro Regular",
	size = 23,
	weight = 100,
	antialias = true,
	blursize = 4
})

surface.CreateFont("ThickUI-Element13", {
	font = "Din Pro Regular",
	size = 16,
	weight = 100,
	antialias = true,
	blursize = 0
})

surface.CreateFont("ChatFont", {
	font = "Din Pro Regular",
	size = 16,
	weight = 150,
    shadow = true,
	antialias = true,
	blursize = 0
})

local TerminalFont = "Quicksand Light"

surface.CreateFont("terminal64", {
	font = TerminalFont,
	size = 64,
	weight = 800,
	antialias = true,
	shadow = false,
} )

surface.CreateFont("terminal64-blurred", {
	font = TerminalFont,
	size = 64,
	weight = 800,
	antialias = true,
	shadow = false,
	blursize = 6
} )

surface.CreateFont("terminal50", {
	font = TerminalFont,
	size = 50,
	weight = 800,
	antialias = true,
	shadow = false,
} )

surface.CreateFont("terminal40", {
	font = TerminalFont,
	size = 40,
	weight = 800,
	antialias = true,
	shadow = false,
} )

surface.CreateFont("terminal32", {
	font = TerminalFont,
	size = 32,
	weight = 800,
	antialias = true,
	shadow = false,
} )

surface.CreateFont("terminal24", {
	font = TerminalFont,
	size = 24,
	weight = 800,
	antialias = true,
	shadow = false,
} )

surface.CreateFont("terminal18", {
	font = TerminalFont,
	size = 18,
	weight = 800,
	antialias = true,
	shadow = false,
} )

surface.CreateFont("terminal16", {
	font = TerminalFont,
	size = 16,
	weight = 800,
	antialias = true,
	shadow = false,
} )

surface.CreateFont("terminal14", {
	font = TerminalFont,
	size = 14,
	weight = 800,
	antialias = true,
	shadow = false,
} )

surface.CreateFont("Monarch-Elements18-Shadow", {
	font = "Arial",
	size = 18,
	weight = 900,
	antialias = true,
	shadow = true,
} )

surface.CreateFont("Monarch-Elements18", {
	font = "Arial",
	size = 18,
	weight = 800,
	antialias = true,
	shadow = false,
} )

hook.Run("PostLoadFonts")

surface.CreateFont("MonarchSB_Name", {
    font = "Purista",
    size = 24,
    weight = 600,
    antialias = true,
    shadow = true
})

surface.CreateFont("MonarchSB_Badge", {
    font = "Purista",
    size = 14,
    weight = 800,
    antialias = true,
    shadow = false
})

surface.CreateFont("MonarchSB_Meta", {
    font = "Purista",
    size = 14,
    weight = 400,
    antialias = true,
    shadow = true
})

surface.CreateFont("HUDLgrBold", {
	font = "Din Pro Medium",
	size = 28,
	weight = 800
})

surface.CreateFont("HUDHg", {
	font = "Din Pro Medium",
	size = 48,
	weight = 400
})

surface.CreateFont("HUDLgr", {
	font = "Din Pro Medium",
	size = 28,
	weight = 500
})

surface.CreateFont("HUDLgrItalic", {
	font = "Din Pro Medium",
	size = 24,
	weight = 200,
	italic = true
})

surface.CreateFont("HUDLgrBlur", {
	font = "Din Pro Medium",
	size = 28,
	weight = 500,
	blursize = 3
})

surface.CreateFont("HUDMed", {
	font = "Din Pro Medium",
	size = 20,
	weight = 500
})

surface.CreateFont("HUDMedBlur", {
	font = "Din Pro Medium",
	size = 20,
	weight = 500,
	blursize = 3
})

surface.CreateFont("HUDSmaller", {
	font = "Din Pro Medium",
	size = 15,
	weight = 500
})

surface.CreateFont("HUDSmallerBlur", {
	font = "Din Pro Medium",
	size = 15,
	weight = 500,
	blursize = 3
})

surface.CreateFont("MoneySm", {
	font = "Din Pro Medium",
	size = 16,
	weight = 20
})

surface.CreateFont("MoneySmBlur", {
	font = "Din Pro Medium",
	size = 16,
	weight = 500,
	blursize = 3
})

surface.CreateFont("MoneyLg", {
	font = "Din Pro Medium",
	size = 19,
	weight = 500
})

surface.CreateFont("MoneyLgBlur", {
	font = "Din Pro Medium",
	size = 19,
	weight = 500
})

surface.CreateFont("Voice", {
	font = "Din Pro Medium",
	size = 22,
	weight = 200
})

surface.CreateFont("VoiceBlur", {
	font = "Din Pro Medium",
	size = 22,
	weight = 200,
	blursize = 3
})

surface.CreateFont("Monarch3D2D_Name", {
    font = "Din Pro Bold",
    size = 72,
    weight = 600,
    shadow = true,
    antialias = true,
})

surface.CreateFont("Monarch3D2D_NameShadow", {
    font = "Din Pro Bold",
    size = 72,
    weight = 400,
    antialias = true,
    shadow = false,
    blursize = 0
})

surface.CreateFont("Monarch3D2D_Desc", {
    font = "Din Pro Medium",
    size = 52,
    weight = 400,
    shadow = true,
})

surface.CreateFont("Monarch3D2D_DescShadow", {
    font = "Din Pro Medium",
    size = 52,
    weight = 400,
    antialias = true,
    shadow = false,
    blursize = 0
})

surface.CreateFont("Monarch_UseInfo", {
    font = "Din Pro Regular",
    size = 34,
    weight = 400,
    shadow = true,
})

surface.CreateFont("DispLgrBold", {
	font = "Din Pro Regular",
	size = 28,
	weight = 800
})

surface.CreateFont("DispHg", {
	font = "Din Pro Regular",
	size = 48,
	weight = 400
})

surface.CreateFont("DispLgr", {
	font = "Din Pro Regular",
	size = 28,
	weight = 500
})

surface.CreateFont("DispLgrItalic", {
	font = "Din Pro Regular",
	size = 24,
	weight = 200,
	italic = true
})

surface.CreateFont("DispLgrBlur", {
	font = "Din Pro Regular",
	size = 28,
	weight = 500,
	blursize = 3
})

surface.CreateFont("DispMed", {
	font = "Din Pro Regular",
	size = 20,
	weight = 500
})

surface.CreateFont("DispMedBlur", {
	font = "Din Pro Regular",
	size = 20,
	weight = 500,
	blursize = 3
})
