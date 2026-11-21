--!nonstrict
-- Sample profile matching the Figma frames (05/06 Shop, 07 Auras, 09 Fishdex, 14 Modal).
-- Used only by Studio previews (tools/ui/preview.mjs, the "Aura UI" Studio panel) so a baked screen
-- can be shown filled in edit mode and compared with Figma. Never used in a live game.

local SampleData = {}

SampleData.Profile = {
	Level = 5,
	Coins = 12450,
	Gems = 320,
	Equipped = { Rods = "DriftwoodRod", Lines = "CottonLine", Bags = "StarterPouch", Baits = "Worm" },
	Owned = { Rods = { DriftwoodRod = true, BambooRod = true }, Lines = { CottonLine = true }, Bags = { StarterPouch = true } },
	Consumables = { Baits = { Worm = 14, Shrimp = 0, GlowGrub = 3 } },
	Auras = {
		Equipped = "NeonWave",
		Owned = { SparklingDew = 3, NeonWave = 1, SolarFlare = 1 },
		Stars = { NeonWave = 3, SparklingDew = 5, SolarFlare = 1 },
		StarTokens = 7,
	},
	Settings = { LowFX = false },
	Fishdex = {
		PebbleMinnow = { Count = 23, Best = 0.38 },
		BubbleCarp = { Count = 41, Best = 2.71 },
		ReedPerch = { Count = 12, Best = 1.20 },
		SunscaleSardine = { Count = 30, Best = 0.29 },
		PearlClam = { Count = 6, Best = 0.66 },
		LilyTrout = { Count = 4, Best = 3.10 },
		GlowEel = { Count = 1, Best = 1.5 },
	},
}

-- Preview views: id -> { Screen = ScreenGui name, Window = child to show (or nil = whole screen), Tab = shop tab }
SampleData.Views = {
	{ Id = "hud", Label = "01 HUD", Screen = "HUD" },
	{ Id = "minigame", Label = "03 Reel Minigame (Pond Card)", Screen = "Minigame", Window = "Panel" },
	{ Id = "modal", Label = "14 Modal (Sell All)", Screen = "Modal" },
	{ Id = "shop", Label = "05 Shop - Rods", Screen = "Menus", Window = "Shop", Tab = "Rods" },
	{ Id = "baits", Label = "06 Shop - Baits", Screen = "Menus", Window = "Shop", Tab = "Baits" },
	{ Id = "auras", Label = "07 Auras", Screen = "Menus", Window = "Auras" },
	{ Id = "fishdex", Label = "09 Fishdex", Screen = "Menus", Window = "Fishdex" },
	{ Id = "inventory", Label = "13 Inventory", Screen = "Inventory", Window = "Window" },
	{ Id = "mainmenu", Label = "12 Main Menu", Screen = "MainMenu" },
	{ Id = "aurareel", Label = "Aura Gacha - Reel Slot", Screen = "AuraReel" },
	{ Id = "components", Label = "Components (prefabs)", Screen = "Components" },
	{ Id = "events", Label = "E0 Events hub", Screen = "Events", Window = "Window" },
	{ Id = "gacha", Label = "E1 Gacha page (Neon Tide)", Screen = "GachaPage", Window = "Window" },
}

-- Show one view in the edit-mode viewport. `ui` = a folder holding New, MenuFill, Screens (fresh copies).
-- Hides every other baked screen. Returns the GuiObject that was shown (for selection).
function SampleData.Show(viewId: string, ui: Instance): Instance?
	local SG = game:GetService("StarterGui")
	local view
	for _, v in SampleData.Views do
		if v.Id == viewId then
			view = v
		end
	end
	for _, g in SG:GetChildren() do
		if g:IsA("ScreenGui") and g:GetAttribute("BakedFrom") then
			g.Enabled = false
			if g.Name == "Menus" then
				for _, w in g:GetChildren() do
					if w:IsA("GuiObject") then
						w.Visible = false
					end
				end
			end
		end
	end
	if not view then
		return nil -- "off": everything hidden
	end
	local gui = SG:FindFirstChild(view.Screen)
	if not gui then
		error(`StarterGui.{view.Screen} is not baked yet (node tools/ui/bake.mjs)`)
	end
	local New = require(ui:FindFirstChild("New")) :: any
	local T = New.Theme
	gui.Enabled = true
	if view.Screen == "Modal" then
		gui.Window.Body.Title.Text = "Sell all 18 fish?"
		gui.Window.Body.Message.Text = "You'll get 2,340 coins. Fish with mutations are included."
		gui.Window.Footer.Confirm.Text = "Confirm"
		New.SetButtonColor(gui.Window.Footer.Confirm, T.Good)
		return gui.Window
	elseif view.Screen == "MainMenu" then
		gui.Hub.Glass.Phone.Grid.Auras.Dot.Visible = true
		gui.Hub.Glass.Phone.Grid.Quests.Dot.Visible = true
		gui.Hub.Glass.Phone.Grid.Shop.Badge.Text = "SALE"
		gui.Hub.Glass.Phone.Grid.Shop.Badge.Visible = true
		gui.Hub.Glass.Phone.Grid.Rebirth.Badge.Text = "Lv.100"
		gui.Hub.Glass.Phone.Grid.Rebirth.Badge.Visible = true
		gui.Hub.Glass.Phone.Header.AvatarDot.Visible = true
		return gui.Hub
	elseif view.Screen ~= "Menus" then
		-- static screens baked with Figma sample data (HUD, Components, Minigame, AuraReel...)
		return gui:FindFirstChild(view.Window or "") or gui
	end
	local Fill = require(ui:FindFirstChild("MenuFill")) :: any
	local windows = { Shop = gui.Shop, Auras = gui.Auras, Fishdex = gui.Fishdex }
	Fill.Setup({
		windows = windows,
		pages = { Shop = 1, Auras = 1, Fishdex = 1 },
		pageCount = {},
		handlers = {},
		currentTab = view.Tab,
		invoke = function() end,
		refresh = function() end,
		rollAura = function() end,
		setSetting = function() end,
	})
	Fill[view.Window](SampleData.Profile)
	windows[view.Window].Visible = true
	return windows[view.Window]
end

return SampleData
