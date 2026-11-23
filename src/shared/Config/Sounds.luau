--!strict
-- Sound content (BGM + SFX). Data only: Controllers/SoundController plays it. Adding a sound = adding a table entry here.
-- Registry validates every entry at startup. Handoff and how-to: docs/HANDOFF_SOUND.md
--
--   Buses     volume groups under one master. Player volume sliders map to Settings.MusicVolume / Settings.SFXVolume
--             (UI bus follows SFXVolume). Default = the volume of a new save / when no setting exists.
--   List[id]  Id          "rbxassetid://123" - "rbxassetid://0" or "" = not uploaded yet: the sound is silently skipped
--             Ids         optional: several variations, one is picked at random (Id is then ignored)
--             Bus         "Music" | "SFX" | "UI"
--             Volume      0..1 base volume (default 1), multiplied by the bus volume
--             Pitch       optional { min, max } random PlaybackSpeed per play (default 1)
--             Cooldown    optional seconds: a play inside this window after the last one is dropped (spammy sounds)
--             Max         optional max copies playing at once for this id (default 4 for SFX / UI)
--             Loop        true for ambience and BGM
--   Music     DefaultTrack = List id played when nothing else asks (nil = silence); FadeSeconds = crossfade time

export type Bus = "Music" | "SFX" | "UI"
export type Sound = {
	Id: string?,
	Ids: { string }?,
	Bus: Bus,
	Volume: number?,
	Pitch: { number }?,
	Cooldown: number?,
	Max: number?,
	Loop: boolean?,
}

local SoundAssets = require(script.Parent.SoundAssets)

local PLACEHOLDER = "rbxassetid://0"

-- Playlist from uploaded files (assets/bgm/<name>.mp3 -> SoundAssets, see tools/audio/upload_bgm.py).
-- Files not uploaded yet are left out; none uploaded = the placeholder (silent).
local function tracks(...: string): { string }
	local list = {}
	for _, name in { ... } do
		if SoundAssets[name] then
			table.insert(list, SoundAssets[name])
		end
	end
	if #list == 0 then
		table.insert(list, PLACEHOLDER)
	end
	return list
end

local Sounds = {
	Buses = {
		Music = { Default = 0.6 },
		SFX = { Default = 0.8 },
		UI = { Default = 0.8 },
	} :: { [string]: { Default: number } },

	Music = {
		DefaultTrack = "bgm_lake" :: string?,
		FadeSeconds = 1.5,
	},

	-- Placeholders: upload the audio, paste the asset id, done. Sounds with id 0 stay silent.
	List = {
		-- BGM
		bgm_lake = { Ids = tracks("The_Dock_at_Daybreak", "Morning_By_The_Dock", "Afternoon_at_the_Cove"), Bus = "Music", Volume = 0.7, Loop = true }, -- plays in turn
		bgm_menu = { Id = PLACEHOLDER, Bus = "Music", Volume = 0.7, Loop = true },
		bgm_aquarium = { Id = PLACEHOLDER, Bus = "Music", Volume = 0.65, Loop = true },
		bgm_cafe = { Id = PLACEHOLDER, Bus = "Music", Volume = 0.65, Loop = true },
		bgm_tide = { Id = PLACEHOLDER, Bus = "Music", Volume = 0.8, Loop = true },
		bgm_battle = { Id = PLACEHOLDER, Bus = "Music", Volume = 0.85, Loop = true },
		bgm_boss_abyss = { Id = PLACEHOLDER, Bus = "Music", Volume = 0.85, Loop = true },
		bgm_frenzy_fever = { Id = PLACEHOLDER, Bus = "Music", Volume = 0.8, Loop = true },

		-- UI
		ui_click = { Id = "rbxassetid://71074578488778", Bus = "UI", Volume = 0.6, Cooldown = 0.05, Pitch = { 0.97, 1.03 } },
		ui_open = { Id = "rbxassetid://93879432682941", Bus = "UI", Volume = 0.6, Cooldown = 0.1 },
		ui_close = { Id = "rbxassetid://94323577322587", Bus = "UI", Volume = 0.5, Cooldown = 0.1 },
		ui_confirm = { Id = "rbxassetid://127387377932846", Bus = "UI", Volume = 0.7 },
		ui_error = { Id = "rbxassetid://101690190320370", Bus = "UI", Volume = 0.6, Cooldown = 0.2 },
		coin = { Id = "rbxassetid://80105179287542", Bus = "UI", Volume = 0.7, Cooldown = 0.05, Pitch = { 0.95, 1.1 } },
		pearl_tick = { Id = "rbxassetid://70651891576491", Bus = "UI", Volume = 0.65, Cooldown = 0.05, Pitch = { 0.96, 1.04 } },

		-- Fishing
		cast = { Id = "rbxassetid://74758480622482", Bus = "SFX", Volume = 0.8 },
		cast_charge = { Id = "rbxassetid://107889695441411", Bus = "SFX", Volume = 0.65, Loop = true },
		cast_perfect = { Id = "rbxassetid://75093847179250", Bus = "SFX", Volume = 0.85 },
		splash = { Id = "rbxassetid://87770240450621", Bus = "SFX", Volume = 0.8, Pitch = { 0.9, 1.1 } },
		bite = { Id = "rbxassetid://104828746510894", Bus = "SFX", Volume = 0.9 },
		reel_tick = { Id = "rbxassetid://118294918612700", Bus = "SFX", Volume = 0.5, Cooldown = 0.08, Max = 3, Pitch = { 0.95, 1.05 } },
		catch = { Id = "rbxassetid://83477742044979", Bus = "SFX", Volume = 0.9 },
		catch_rare = { Id = "rbxassetid://130564956649467", Bus = "SFX", Volume = 1 },
		fish_escape = { Id = "rbxassetid://108249119731799", Bus = "SFX", Volume = 0.7 },

		-- Aura Gacha (Altar Charge & Eclipse Reveal)
		gacha_charge = { Id = "rbxassetid://91259156289669", Bus = "SFX", Volume = 0.8 },
		gacha_buildup = { Id = "rbxassetid://127807951499527", Bus = "SFX", Volume = 0.85 },
		gacha_common = { Id = "rbxassetid://100922292647829", Bus = "SFX", Volume = 0.8 },
		gacha_epic = { Id = "rbxassetid://82976685901449", Bus = "SFX", Volume = 0.9 },
		gacha_legendary = { Id = "rbxassetid://89915524358923", Bus = "SFX", Volume = 1.0 },
		aura_equip = { Id = "rbxassetid://103622442184860", Bus = "SFX", Volume = 0.8 },
		star_up = { Id = "rbxassetid://112650984522877", Bus = "SFX", Volume = 0.85 },

		-- Gameplay & Events
		dash = { Id = "rbxassetid://103785936090076", Bus = "SFX", Volume = 0.7, Cooldown = 0.3 },
		level_up = { Id = "rbxassetid://70983893959827", Bus = "SFX", Volume = 0.85 },
		chest_open = { Id = "rbxassetid://79366312982889", Bus = "SFX", Volume = 0.8 },
		tide_alert = { Id = "rbxassetid://113392761717848", Bus = "SFX", Volume = 0.9 },
	} :: { [string]: Sound },
}

return Sounds
