--!nonstrict
-- Events hub action { Kind = "Menu", Window = "Shop"|"Auras"|"Fishdex"|"Inventory" }: open that window.
-- (See EventActions/Gacha.luau for how to add a new action kind.)

local Menu = {}

function Menu.Run(event: any, ctx: any)
	local window = event.Action.Window
	if window == "Inventory" then
		ctx.hud.InventoryRequested:Fire()
	else
		ctx.hud.MenuRequested:Fire(window)
	end
end

return Menu
