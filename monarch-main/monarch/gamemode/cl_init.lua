include("shared.lua")

 function GM:PostDrawViewModel( vm, ply, weapon )

	if ( weapon.UseHands || !weapon:IsScripted() ) then

		local hands = LocalPlayer():GetHands()
		if ( IsValid( hands ) ) then hands:DrawModel() end

	elseif IsValid(weapon) then

		local model = weapon:GetModel()
		if model and string.find(string.lower(model), "c_") then
			local hands = LocalPlayer():GetHands()
			if IsValid(hands) then hands:DrawModel() end
		end
	end

end

hook.Add( "PreDrawHalos", "PropertiesHover", function() 

	if ( !IsValid( vgui.GetHoveredPanel() ) || !vgui.GetHoveredPanel():IsWorldClicker() ) then return end

	local ent = properties.GetHovered( EyePos(), LocalPlayer():GetAimVector() )
	if ( !IsValid( ent ) ) then return end

	if ent:GetNoDraw() then
		return
	end

	local c = Color( 255, 255, 255, 255 )
	c.r = 200 + math.sin( RealTime() * 50 ) * 55
	c.g = 200 + math.sin( RealTime() * 20 ) * 55
	c.b = 200 + math.cos( RealTime() * 60 ) * 55

	local t = { ent }
	if ( ent.GetActiveWeapon && IsValid( ent:GetActiveWeapon() ) ) then table.insert( t, ent:GetActiveWeapon() ) end
	halo.Add( t, c, 2, 2, 2, true, false )
end )