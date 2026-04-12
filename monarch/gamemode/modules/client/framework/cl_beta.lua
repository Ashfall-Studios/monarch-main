local betaMat = Material("betastage.png", "smooth")

hook.Add("HUDPaint", "DrawBetaWatermark", function()
    surface.SetMaterial(betaMat)
    surface.SetDrawColor(255, 255, 255, 25)
    surface.DrawTexturedRect(ScrW() - 500, ScrH() - ((ScrH() / 2) - 350), ScrW() / 7, ScrH() / 4)
end)