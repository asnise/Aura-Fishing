--!strict
-- Events hub action { Kind = "DailyLogin" }: open the Daily Login window.

local DailyLogin = {}

function DailyLogin.Run(_event: any, ctx: any)
	if ctx.hud.DailyLoginRequested then
		ctx.hud.DailyLoginRequested:Fire()
	end
end

return DailyLogin
