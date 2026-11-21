--!strict
-- Events hub (Figma E0 · Events). The hub is only a list of banner CARDS; each card has an OPEN
-- button that runs the event's Action. The content lives elsewhere (its own page, a teleport, a
-- menu...), so adding an event = adding an entry here (+ its data). A new kind of action = one new
-- client module in UI/EventActions/<Kind>.luau (Run(event)); the hub itself never changes.
--
-- Action kinds:
--   { Kind = "Gacha", Banner = <Config/AuraBanners id> }   opens the gacha page for that banner
--   { Kind = "Menu", Window = "Shop"|"Auras"|"Fishdex"|"Inventory" }
--   { Kind = "Teleport", Location = <Config/Locations id> } (needs the location's spawn; not built yet)
--   { Kind = "Info", Title, Body }                          small popup / coming soon
--
-- Card: Banner image (UIAssets key, wide art; falls back to Icon), Title, Subtitle, Tag pill
-- ("LIMITED"/"NEW"/"SOON"), timer from StartsUTC/EndsUTC (Gacha cards use the banner's dates
-- when unset). Disabled = card shown greyed, OPEN not clickable. Hidden outside its dates.

export type Event = {
	Title: string,
	Subtitle: string?,
	Icon: string, -- UIAssets key (small)
	Banner: string?, -- UIAssets key (card art)
	Order: number,
	Tag: string?,
	Disabled: boolean?,
	StartsUTC: number?,
	EndsUTC: number?,
	Action: { [string]: any },
	Art: { Top: Color3, Bottom: Color3, Color: Color3? }?, -- card art gradient (+ ray colour)
}

local Events: { [string]: Event } = {
	NeonTide = {
		Art = { Top = Color3.fromRGB(229, 219, 250), Bottom = Color3.fromRGB(211, 236, 250), Color = Color3.fromRGB(176, 124, 240) },
		Title = "Neon Tide Banner",
		Subtitle = "Neon Wave x2 | Featured: Abyssal Shadow",
		Icon = "auras/AbyssalShadow",
		Order = 1,
		Tag = "LIMITED",
		Action = { Kind = "Gacha", Banner = "NeonTide" },
	},
	Altar = {
		Art = { Top = Color3.fromRGB(229, 219, 250), Bottom = Color3.fromRGB(251, 216, 226), Color = Color3.fromRGB(183, 156, 242) },
		Title = "Aura Altar",
		Subtitle = "Standard aura roll | Legendary every 100, Mythic at 300",
		Icon = "ui/icons/auras",
		Order = 2,
		Action = { Kind = "Gacha", Banner = "Altar" },
	},
	NagaTide = {
		Art = { Top = Color3.fromRGB(210, 240, 226), Bottom = Color3.fromRGB(211, 236, 250), Color = Color3.fromRGB(127, 211, 176) },
		Title = "Naga Tide",
		Subtitle = "Every :00 and :30 | glowing water somewhere in the sea",
		Icon = "fish/NagaHatchling",
		Order = 3,
		Tag = "30 MIN",
		Action = {
			Kind = "Info",
			Title = "Naga Tide",
			Body = "Every hour at :00 and :30 (UTC) a patch of glowing water appears in the sea for 5 minutes. Fish with your bobber inside it: +50% Luck and a chance at a Naga Hatchling. The more anglers fish there together, the better the chance!",
		},
	},
	DailyLogin = {
		Art = { Top = Color3.fromRGB(251, 234, 184), Bottom = Color3.fromRGB(255, 220, 207), Color = Color3.fromRGB(242, 181, 68) },
		Title = "Daily Login",
		Subtitle = "Claim free rewards every day",
		Icon = "ui/icons/quests",
		Order = 4,
		Tag = "DAILY",
		Action = { Kind = "DailyLogin" },
	},
}

return Events
