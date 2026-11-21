--!nonstrict
-- Events hub action { Kind = "Gacha", Banner = <Config/AuraBanners id> }: open the gacha page for that banner.
--
-- HOW TO ADD A NEW ACTION KIND: create UI/EventActions/<Kind>.luau returning { Run = function(event, ctx) }
-- and use { Kind = "<Kind>", ... } in Config/Events (Registry checks the kind names). The hub itself never
-- changes. ctx (from EventController):
--   openBanner(bannerId)  open the gacha page
--   notify(text, color?)  HUD toast                  hud              HUDController (signals: MenuRequested, ...)
--   theme                 New.Theme

local Gacha = {}

function Gacha.Run(event: any, ctx: any)
	ctx.openBanner(event.Action.Banner)
end

return Gacha
