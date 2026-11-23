--!nonstrict
-- Core sound system (BGM + SFX + UI). Content lives in Config/Sounds; this module only plays it.
--   SoundController.Play(id, opts?) -> Sound?        one-shot (or looped when the def says Loop)
--        opts: Volume (multiplier), Pitch (overrides the def's random pitch), At (Vector3 | BasePart | Attachment: 3D)
--   SoundController.PlayAt(id, at)                   shortcut for Play(id, { At = at })
--   SoundController.PushMusic(key, trackId, priority?)  a context asks for a BGM track (area, event, boss, dialogue...).
--        The highest priority wins (a later push of the same priority wins); the track crossfades in.
--   SoundController.PopMusic(key)                    the context no longer needs it: the next one (or the default) returns
--   SoundController.SetBusVolume(bus, 0..1)          live bus volume ("Music" | "SFX" | "UI"); saved volumes come from
--                                                    profile.Settings.MusicVolume / SFXVolume (UI follows SFX)
--   SoundController.Stop(sound)                      stop a looped sound returned by Play
-- Server -> client: Remotes.Event("PlaySound"):FireClient(player, id, at?)  (at = Vector3 or nil)
-- A sound with id "rbxassetid://0" (not uploaded yet) is silently skipped; an unknown id warns once.
-- Auto hooks: menus opening / closing play ui_open / ui_close. Handoff: docs/HANDOFF_SOUND.md

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local DataController = require(script.Parent.DataController)
local MenuManager = require(script.Parent.Parent.UI.MenuManager)

local SoundController = {}

local cfg = Registry.Sounds
local DEFAULT_MAX = 4

local master: SoundGroup
local groups: { [string]: SoundGroup } = {}
local lastPlayed: { [string]: number } = {}
local playing: { [string]: number } = {} -- id -> copies alive
local warned: { [string]: boolean } = {}
local templates: { [string]: Sound } = {} -- numeric asset id -> loaded Sound kept for cloning
local ready: { [string]: boolean } = {} -- asset ids downloaded by PreloadAsync (a one-shot is dropped, never played late)

-- ready[] is keyed by the numeric id so "rbxassetid://123" and the callback's content id always match
local function key(assetId: string): string
	return string.match(assetId, "%d+") or assetId
end

local function isSilent(assetId: string?): boolean
	return assetId == nil or assetId == "" or assetId == "rbxassetid://0"
end

local function pickAsset(def: any): string?
	if def.Ids and #def.Ids > 0 then
		return def.Ids[math.random(1, #def.Ids)]
	end
	return def.Id
end

-- Buses ----------------------------------------------------------------------------------------------

function SoundController.SetBusVolume(bus: string, volume: number)
	local group = groups[bus]
	if group then
		group.Volume = math.clamp(volume, 0, 1)
	end
end

-- Settings window sliders: bus = "Music" | "SFX" (UI follows SFX). Applies live, saves a moment after the last change.
local savePending: { [string]: number } = {}

function SoundController.GetVolume(bus: string): number
	local group = groups[bus]
	return if group then group.Volume else cfg.Buses[bus].Default
end

function SoundController.SetVolume(bus: string, volume: number)
	volume = math.clamp(volume, 0, 1)
	SoundController.SetBusVolume(bus, volume)
	if bus == "SFX" then
		SoundController.SetBusVolume("UI", volume)
	end
	local token = (savePending[bus] or 0) + 1
	savePending[bus] = token
	task.delay(0.6, function()
		if savePending[bus] == token then
			pcall(function()
				Remotes.Func("SetSetting"):InvokeServer(if bus == "Music" then "MusicVolume" else "SFXVolume", volume)
			end)
			task.delay(1, function()
				if savePending[bus] == token then
					savePending[bus] = nil -- the saved value now matches: profile syncs may apply again
				end
			end)
		end
	end)
end

local function buildGroups()
	master = Instance.new("SoundGroup")
	master.Name = "AuraMaster"
	master.Parent = SoundService
	for bus, def in cfg.Buses do
		local group = Instance.new("SoundGroup")
		group.Name = bus
		group.Volume = def.Default
		group.Parent = master
		groups[bus] = group
	end
end

-- One-shots ------------------------------------------------------------------------------------------

local function parentFor(at: any): Instance
	if typeof(at) == "Instance" then
		return at
	elseif typeof(at) == "Vector3" then
		-- a throwaway attachment on the terrain so concurrent 3D sounds keep their own position
		local a = Instance.new("Attachment")
		a.WorldPosition = at
		a.Parent = Workspace.Terrain
		Debris:AddItem(a, 30)
		return a
	end
	return SoundService
end

function SoundController.Play(id: string, opts: any?): Sound?
	local def = cfg.List[id]
	if not def then
		if not warned[id] then
			warned[id] = true
			warn(`[Sound] unknown sound "{tostring(id)}" (Config/Sounds)`)
		end
		return nil
	end
	local assetId = pickAsset(def)
	if isSilent(assetId) or not ready[key(assetId :: string)] then
		return nil
	end
	local now = os.clock()
	if def.Cooldown and lastPlayed[id] and now - lastPlayed[id] < def.Cooldown then
		return nil
	end
	local max = def.Max or DEFAULT_MAX
	if def.Bus ~= "Music" and (playing[id] or 0) >= max then
		return nil
	end
	lastPlayed[id] = now

	local o = opts or {}
	-- clone the preloaded template (already decoded) instead of a cold Sound: a new one lags before it starts
	local template = templates[key(assetId :: string)]
	local sound = if template then template:Clone() else Instance.new("Sound")
	sound.SoundId = assetId
	sound.Volume = (def.Volume or 1) * (o.Volume or 1)
	sound.Looped = def.Loop == true
	local pitch = o.Pitch or (if def.Pitch then def.Pitch[1] + math.random() * (def.Pitch[2] - def.Pitch[1]) else 1)
	sound.PlaybackSpeed = pitch
	sound.SoundGroup = groups[def.Bus]
	sound.Parent = parentFor(o.At)
	playing[id] = (playing[id] or 0) + 1
	local function release()
		playing[id] = math.max(0, (playing[id] or 1) - 1)
		sound:Destroy()
	end
	if not sound.Looped then
		sound.Ended:Connect(release)
		Debris:AddItem(sound, 60) -- safety net if Ended never fires
	end
	sound.Destroying:Connect(function()
		if sound.Looped then
			playing[id] = math.max(0, (playing[id] or 1) - 1)
		end
	end)
	sound:Play()
	return sound
end

function SoundController.PlayAt(id: string, at: any): Sound?
	return SoundController.Play(id, { At = at })
end

function SoundController.Stop(sound: Sound?)
	if sound and sound.Parent then
		sound:Destroy()
	end
end

-- Music ----------------------------------------------------------------------------------------------

local requests: { { Key: string, Track: string, Priority: number, Seq: number } } = {}
local seq = 0
local playlistIndex: { [string]: number } = {}
local current: { Track: string?, Sound: Sound? } = { Track = nil, Sound = nil }

local function fade(sound: Sound, to: number, seconds: number, stopAfter: boolean)
	local tween = TweenService:Create(sound, TweenInfo.new(seconds, Enum.EasingStyle.Sine), { Volume = to })
	if stopAfter then
		tween.Completed:Once(function()
			sound:Destroy()
		end)
	end
	tween:Play()
end

local function applyMusic()
	local best = nil
	for _, r in requests do
		if not best or r.Priority > best.Priority or (r.Priority == best.Priority and r.Seq > best.Seq) then
			best = r
		end
	end
	local wanted: string? = if best then best.Track else cfg.Music.DefaultTrack
	if wanted == current.Track then
		return
	end
	local seconds = cfg.Music.FadeSeconds
	if current.Sound then
		fade(current.Sound, 0, seconds, true)
		current.Sound = nil
	end
	current.Track = wanted
	local def = wanted and cfg.List[wanted]
	if not def then
		return
	end
	-- several Ids = a playlist: tracks play one after another (random first track); a single one loops
	local list = {}
	for _, assetId in def.Ids or { def.Id } do
		if not isSilent(assetId) then
			table.insert(list, assetId)
		end
	end
	if #list == 0 then
		return
	end
	local track: string = wanted :: string
	local index = (playlistIndex[track] or math.random(0, #list - 1)) % #list + 1
	if not ready[key(list[index])] then
		-- still downloading: ask again shortly instead of starting a track that would stutter in late
		current.Track = nil
		task.delay(1, applyMusic)
		return
	end
	playlistIndex[track] = index
	local sound = Instance.new("Sound")
	sound.SoundId = list[index]
	sound.Looped = #list == 1
	sound.Volume = 0
	sound.SoundGroup = groups.Music
	sound.Parent = SoundService
	sound:Play()
	fade(sound, def.Volume or 1, seconds, false)
	current.Sound = sound
	if #list > 1 then
		sound.Ended:Connect(function()
			if current.Sound == sound then
				current.Sound, current.Track = nil, nil
				sound:Destroy()
				applyMusic() -- next track of the playlist
			end
		end)
	end
end

function SoundController.PushMusic(key: string, track: string, priority: number?)
	if not cfg.List[track] or cfg.List[track].Bus ~= "Music" then
		warn(`[Sound] PushMusic "{key}": "{track}" is not a Music sound (Config/Sounds)`)
		return
	end
	SoundController.PopMusic(key, true)
	seq += 1
	table.insert(requests, { Key = key, Track = track, Priority = priority or 0, Seq = seq })
	applyMusic()
end

function SoundController.PopMusic(key: string, silent: boolean?)
	for i = #requests, 1, -1 do
		if requests[i].Key == key then
			table.remove(requests, i)
		end
	end
	if not silent then
		applyMusic()
	end
end

-- Init -----------------------------------------------------------------------------------------------

function SoundController.Init()
	buildGroups()

	-- saved volumes (Settings.MusicVolume / SFXVolume, written through the SetSetting remote)
	DataController.Observe(function(profile)
		local s = profile.Settings or {}
		if not savePending.Music then
			SoundController.SetBusVolume("Music", s.MusicVolume or cfg.Buses.Music.Default)
		end
		if not savePending.SFX then
			local sfx = s.SFXVolume or cfg.Buses.SFX.Default
			SoundController.SetBusVolume("SFX", sfx)
			SoundController.SetBusVolume("UI", sfx)
		end
	end)

	Remotes.Event("PlaySound").OnClientEvent:Connect(function(id, at)
		if type(id) == "string" then
			SoundController.Play(id, { At = if typeof(at) == "Vector3" then at else nil })
		end
	end)

	MenuManager.Changed:Connect(function(_, isOpen)
		SoundController.Play(if isOpen then "ui_open" else "ui_close")
	end)

	-- every button clicks (New.HookButton calls this)
	local New = require(script.Parent.Parent.UI.New)
	New.ClickHook = function()
		SoundController.Play("ui_click")
	end
	New.PlaySound = function(id)
		SoundController.Play(id)
	end

	-- Fishing: cast + splash, bite, catch / rare catch, level up, escapes and event alerts (no edits needed in the
	-- fishing code: the server remotes already say everything)
	Remotes.Event("FishingState").OnClientEvent:Connect(function(phase)
		if phase == "Waiting" then
			SoundController.Play("cast")
			task.delay(0.35, SoundController.Play, "splash")
		elseif phase == "Bite" then
			SoundController.Play("bite")
		end
	end)
	Remotes.Event("CatchResult").OnClientEvent:Connect(function(result)
		local fish = result and result.Entry and Registry.Fish[result.Entry.Fish]
		local rarity = fish and Registry.Rarities[fish.Rarity]
		SoundController.Play(if rarity and rarity.Tier >= 4 then "catch_rare" else "catch")
		if result and (result.LevelsGained or 0) > 0 then
			task.delay(0.6, SoundController.Play, "level_up")
		end
	end)
	Remotes.Event("Notify").OnClientEvent:Connect(function(text)
		if type(text) ~= "string" then
			return
		end
		if string.find(text, "got away", 1, true) or string.find(text, "line snapped", 1, true) then
			SoundController.Play("fish_escape")
		elseif string.find(text, "Glowing water", 1, true) or string.find(text, " rises in ", 1, true) then
			SoundController.Play("tide_alert")
		end
	end)
	-- coins coming in (selling) and coins spent (buying / upgrading / enhancing)
	local lastCoins: number? = nil
	local lastAura: string? = nil
	DataController.Observe(function(profile)
		if lastCoins and profile.Coins ~= lastCoins then
			SoundController.Play("coin")
		end
		lastCoins = profile.Coins
		local equipped = profile.Auras and profile.Auras.Equipped
		if lastAura ~= nil and equipped ~= lastAura and equipped then
			SoundController.Play("aura_equip")
		end
		lastAura = equipped or ""
	end)

	-- Download every real asset up front: small SFX / UI first (so clicks and catches work within seconds), then the
	-- big BGM files. Only downloaded assets play (see Play / applyMusic), nothing starts late or cuts in and out.
	task.spawn(function()
		local effects, music = {}, {}
		for _, def in cfg.List do
			for _, assetId in def.Ids or { def.Id } do
				if not isSilent(assetId) then
					table.insert(if def.Bus == "Music" then music else effects, assetId)
				end
			end
		end
		local player = Players.LocalPlayer
		for i, batch in { effects, music } do
			if #batch > 0 then
				-- Sound instances, not id strings: strings are requested as images ("Asset type does not match")
				local probes = {}
				for _, assetId in batch do
					local probe = Instance.new("Sound")
					probe.SoundId = assetId
					probe.Parent = ReplicatedStorage -- an unparented Sound never reports IsLoaded, so clones would start cold
					table.insert(probes, probe)
				end
				local ok, err = pcall(function()
					ContentProvider:PreloadAsync(probes, function(contentId, status)
						if status == Enum.AssetFetchStatus.Success then
							ready[key(contentId)] = true
						else
							warn(`[Sound] could not load {contentId}: {status.Name}`)
						end
					end)
				end)
				if not ok then
					warn(`[Sound] preload failed: {err}`)
				end
				for _, probe in probes do
					if i == 1 and ready[key(probe.SoundId)] then
						templates[key(probe.SoundId)] = probe -- kept (parked, never played) as the clone source
					else
						probe:Destroy()
					end
				end
			end
			-- the loading screen (src/first) waits for these
			player:SetAttribute(if i == 1 then "SoundsReady" else "MusicReady", true)
		end
	end)

	applyMusic() -- default BGM
end

return SoundController
