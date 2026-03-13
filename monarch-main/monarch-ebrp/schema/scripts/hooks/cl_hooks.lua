local LIGHT_RED = Color(255, 100, 100)

local CURFEW_START_SOUND = "overwatch/citywide/other_languages/overwatch_russian_offworldrelocation.mp3"
local CURFEW_END_SOUND = "overwatch/citywide/other_languages/overwatch_russian_inactionconspiracy.mp3"

local curfewActive = false

net.Receive("Curfew_Start", function()
	if curfewActive then return end
	curfewActive = true

	surface.PlaySound(CURFEW_START_SOUND)

	chat.AddText(LIGHT_RED, "Attention please. Curfew is now active, please return to your houses or housing blocks and await further instruction.")
end)

net.Receive("Curfew_End", function()
	if not curfewActive then return end
	curfewActive = false

	surface.PlaySound(CURFEW_END_SOUND)

	chat.AddText(LIGHT_RED, "Attention please. Curfew has now concluded, foot travel is now permitted.")
end)

Monarch = Monarch or {}
Monarch.Loyalty = Monarch.Loyalty or {}

if not Monarch.Loyalty._charScoped then
	include("monarch-ebrp/modules/loyalty/sh_lyt.lua")
	include("monarch-ebrp/modules/loyalty/cl_lyt.lua")
end
