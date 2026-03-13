if SERVER then
	AddCSLuaFile("cl_police.lua")

	include("sv_warrants.lua")
	include("sv_criminal.lua")
	include("sv_citations.lua")
	include("sv_bail.lua")
	include("sv_detainees.lua")
end

if CLIENT then
	include("cl_police.lua")
end

