--!nonstrict
-- Events hub action { Kind = "Teleport", Location = <Config/Locations id> }.
-- TODO: locations have no spawn points yet. When they do: add a client->server RemoteEvent (e.g.
-- "TeleportTo"(locationId)) and fire it here; the server validates and moves the character.
-- (See EventActions/Gacha.luau for how to add a new action kind.)

local Teleport = {}

function Teleport.Run(_event: any, ctx: any)
	ctx.notify("Teleport coming soon", ctx.theme.Sky)
end

return Teleport
