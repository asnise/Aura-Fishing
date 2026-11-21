--!strict
-- Third-party assets that need attribution (C10). Shown in the in-game Credits window
-- (Main Menu > Settings) and mirrored in CREDITS.md at the repo root.
-- Add a row whenever a licence asks for credit (CC BY etc.).

export type Credit = {
	Name: string,
	Use: string, -- where it appears in the game
	Author: string,
	License: string,
	Url: string, -- plain text (Roblox cannot open links)
}

local Credits: { Credit } = {
	{
		Name = "Font Awesome Free (Lock icon)",
		Use = "Lock icon on locked slots and items",
		Author = "Fonticons, Inc.",
		License = "CC BY 4.0",
		Url = "fontawesome.com/license/free",
	},
}

return Credits
