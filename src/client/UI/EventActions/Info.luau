--!nonstrict
-- Events hub action { Kind = "Info", Title, Body }: show the text as a toast (coming-soon events).
-- (See EventActions/Gacha.luau for how to add a new action kind.)

local Info = {}

function Info.Run(event: any, ctx: any)
	local a = event.Action
	ctx.notify(a.Body or a.Title or event.Title, ctx.theme.Text)
end

return Info
