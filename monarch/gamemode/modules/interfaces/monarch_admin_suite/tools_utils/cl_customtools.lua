return function(ctx)
    local frame = ctx.frame
    local right = ctx.right
    local StyledButton = ctx.StyledButton
    local PanelControlButton = ctx.PanelControlButton
    local GetPalette = ctx.GetPalette
    local ClearRight = ctx.ClearRight
    local OpenCreateTicket = ctx.OpenCreateTicket
    local BuildTicketsView, BuildToolsView, BuildCustomToolsView, BuildPlayersView, BuildCharsView, BuildStaffView

    BuildCustomToolsView = function()
        ClearRight()
        local container = vgui.Create("DPanel", right)
        container:Dock(FILL)
        container.Paint = nil

        local tools = (Monarch and Monarch.GetAdminTools and Monarch.GetAdminTools()) or {}
        if not istable(tools) or #tools == 0 then
            local empty = vgui.Create("DLabel", container)
            empty:Dock(FILL)
            empty:SetText("No custom tools registered")
            empty:SetFont("InvMed")
            empty:SetTextColor(Color(220,220,220))
            empty:SetContentAlignment(5)
            return
        end

        local layout = vgui.Create("DIconLayout", container)
        layout:Dock(FILL)
        layout:SetSpaceX(10)
        layout:SetSpaceY(10)
        layout:DockMargin(10,10,10,10)

        for _, tool in ipairs(tools) do
            if tool and isfunction(tool.onUse) then
                local btn = StyledButton(layout, tostring(tool.label or tool.id or "Tool"))
                btn:SetSize(180, 42)
                btn.DoClick = function()
                    tool.onUse()
                end
            end
        end
    end

    return BuildCustomToolsView
end

