--!strict
-- NPC dialogue (B7, Figma 11 · Dialogue). Data only: Controllers/DialogueController shows it.
-- An NPC is opened by its world ProximityPrompt (server fires "OpenDialogue"(npcId)).
--
--   Name      speaker name on the mint tag
--   Prompt    name of the ProximityPrompt in Workspace.Map that opens this NPC (ActionText -> "Talk")
--   Greetings lines picked at random when the talk opens. Lines may use {coins}, {fish}, {hot}
--             (filled by the controller from the player's bag / the hot fish of the hour)
--   Busy      greeting used instead when the bag has fish (Marlin) - optional
--   Talk      lines for the "Just chatting" choice (cycled in order)
--   Choices   up to 4 speech-bubble buttons: { Label, Icon (UIAssets key), Action }
--     Action.Kind = "SellAll"            sell every fish (same confirm as the HUD SELL ALL)
--                 "HotFish"              say which fish sell for more this hour
--                 "Banner", Banner = id  open a gacha page (Config/AuraBanners)
--                 "Menu", Menu = name    open a menu window (Shop / Auras / Fishdex)
--                 "Say", Line = text     answer with one line
--                 "Talk"                 next line from Talk

export type Action = { Kind: string, Banner: string?, Menu: string?, Line: string? }
export type Choice = { Label: string, Icon: string, Action: Action }
export type Npc = {
	Name: string,
	Prompt: string,
	Greetings: { string },
	Busy: { string }?,
	Talk: { string },
	Choices: { Choice },
}

local Dialogues: { [string]: Npc } = {
	Marlin = {
		Name = "Old Marlin",
		Prompt = "SellPrompt",
		Greetings = {
			"Ahoy there! Nothing in your bag yet. The fish won't catch themselves, you know.",
			"Calm water today. Good day for a long cast.",
		},
		Busy = {
			"Back again? The lake has been generous today... want me to take that catch off your hands?",
			"{fish} fish! I can give you {coins} coins for the lot.",
		},
		Talk = {
			"Deeper water hides rarer fish. Get a longer line from my shop and try your luck.",
			"Every hour I pay extra for a few kinds of fish. Watch the HOT FISH sign by my stall.",
			"Manual catches are worth more than auto. Keep a streak going and the coins add up.",
			"Some say a great serpent sleeps at the bottom of the trench. I've only seen its eyes.",
		},
		Choices = {
			{ Label = "Sell All Fish", Icon = "icon_fish", Action = { Kind = "SellAll" } },
			{ Label = "Hot fish today?", Icon = "icon_flame", Action = { Kind = "HotFish" } },
			{ Label = "Browse gear", Icon = "icon_reel", Action = { Kind = "Menu", Menu = "Shop" } },
			{ Label = "Just chatting", Icon = "icon_chat", Action = { Kind = "Talk" } },
		},
	},
	Sela = {
		Name = "Sela",
		Prompt = "RollPrompt",
		Greetings = {
			"Welcome to the Aura Altar. The stars are listening tonight.",
			"Feel that hum? The altar is ready when you are.",
		},
		Talk = {
			"An aura follows you while you fish. Rare ones bring luck, and sometimes strange mutations.",
			"Every roll brings you closer to a Legendary. The altar never forgets how long you've waited.",
			"I keep the old records of every aura ever seen. Ask for the Aura Dex in your bag.",
		},
		Choices = {
			{ Label = "Open the Altar", Icon = "icon_star", Action = { Kind = "Banner", Banner = "Altar" } },
			{
				Label = "Star Tokens?",
				Icon = "icon_info",
				Action = {
					Kind = "Say",
					Line = "Roll an aura you already have and it turns into Star Tokens. Spend them on STAR UP: each star makes that aura stronger.",
				},
			},
			{ Label = "Just chatting", Icon = "icon_chat", Action = { Kind = "Talk" } },
		},
	},
}

return Dialogues
