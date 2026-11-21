--!nonstrict
-- Data -> Events hub card (pure functions, no remotes: Studio previews require this too).
--   EventHub.Window(event) -> startsUTC?, endsUTC?   (Gacha events fall back to their banner's dates)
--   EventHub.IsVisible(event, now)                    hidden before its start / after its end
--   EventHub.Sorted(now) -> { {Id, Event} }           visible events by Order
--   EventHub.CardInfo(event, now) -> info for Screens/Events.SetCard
--   EventHub.TimeLeft(seconds) -> "13d 05h left"

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared:WaitForChild("Registry"))

local New = require(script.Parent.New)
local T = New.Theme

local EventHub = {}

local function bannerOf(event: any): any
	local a = event.Action
	return if a and a.Kind == "Gacha" then Registry.AuraBanners[a.Banner] else nil
end
EventHub.BannerOf = bannerOf

function EventHub.Window(event: any): (number?, number?)
	local b = bannerOf(event)
	local starts = event.StartsUTC or (b and b.StartsUTC)
	local ends = event.EndsUTC or (b and b.EndsUTC)
	return starts, ends
end

function EventHub.IsVisible(event: any, now: number): boolean
	local starts, ends = EventHub.Window(event)
	return (starts == nil or now >= starts) and (ends == nil or now < ends)
end

function EventHub.Sorted(now: number): { any }
	local out = {}
	for id, e in Registry.Events do
		if EventHub.IsVisible(e, now) then
			table.insert(out, { Id = id, Event = e })
		end
	end
	table.sort(out, function(a, b)
		if a.Event.Order ~= b.Event.Order then
			return a.Event.Order < b.Event.Order
		end
		return a.Id < b.Id
	end)
	return out
end

function EventHub.TimeLeft(seconds: number): string
	if seconds <= 0 then
		return "Ended"
	end
	local d = seconds // 86400
	local h = (seconds % 86400) // 3600
	local m = (seconds % 3600) // 60
	if d > 0 then
		return string.format("%dd %02dh left", d, h)
	elseif h > 0 then
		return string.format("%dh %02dm left", h, m)
	end
	return string.format("%dm left", math.max(1, m))
end

-- Card art: optional event.Art = { Top = Color3, Bottom = Color3, Color = Color3? } (tile gradient + rays/glow
-- tint); defaults: lilac -> sky tile, rays in the featured aura's rarity colour (Gacha) or lavender.
function EventHub.CardInfo(event: any, now: number): { [string]: any }
	local b = bannerOf(event)
	local _, ends = EventHub.Window(event)
	local art = type(event.Art) == "table" and event.Art or {}
	local tint = art.Color or T.Gem
	if not art.Color and b and b.Featured then
		local aura = Registry.Auras[b.Featured]
		tint = Registry.Rarities[aura.Rarity].Color
	end
	return {
		Title = event.Title,
		Subtitle = event.Subtitle,
		Icon = event.Icon,
		Banner = event.Banner,
		Tag = event.Tag,
		Timer = if ends and not event.Disabled then EventHub.TimeLeft(ends - now) else nil,
		Disabled = event.Disabled == true,
		ArtTop = art.Top,
		ArtBottom = art.Bottom,
		ArtColor = tint,
	}
end

return EventHub
