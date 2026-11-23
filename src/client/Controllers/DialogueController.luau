--!nonstrict
-- NPC dialogue (B7, Figma 11). Layout baked into StarterGui.Dialogue (UI/Screens/Dialogue); content in
-- Config/Dialogues. Opened by the server when a world ProximityPrompt is used (RemoteEvent "OpenDialogue").
--   Line text types in (MaxVisibleGraphemes); tapping the box shows the whole line at once.
--   Choices run Config actions: SellAll (same confirm as the HUD SELL ALL), HotFish, Banner (gacha page),
--   Menu (Shop / Auras / Fishdex), Fusion (Rod Fusion window), Say, Talk (next chat line). Close: X, Escape, or walking away.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Inventory = require(Shared.Inventory)
local HotFish = require(Shared.HotFish)
local Format = require(Shared.Util.Format)

local UI = script.Parent.Parent.UI
local New = require(UI.New)
local Baked = require(UI.Baked)
local MenuManager = require(UI.MenuManager)
local Modal = require(UI.Modal)
local DialogueScreen = require(UI.Screens:WaitForChild("Dialogue")) :: any
local HUD = require(script.Parent.HUDController)
local DataController = require(script.Parent.DataController)
local GachaPageController = require(script.Parent.GachaPageController)

local T = New.Theme

local DialogueController = {}

local TYPE_SPEED = 55 -- characters per second
local WALK_AWAY = 22 -- studs from the NPC's prompt part before the talk closes

local gui: any = nil
local refs: any = nil
local npcId: string? = nil
local anchor: BasePart? = nil
local talkIndex: { [string]: number } = {}
local typing = 0 -- token of the running typewriter
local busy = false
local controls: any = nil -- Roblox PlayerModule controls: disabled while talking so the player cannot move

-- Frozen while a dialogue is open (walk away no longer closes it: use the X or pick a choice)
local function setMoveEnabled(on: boolean)
	if not controls then
		local module = Players.LocalPlayer:FindFirstChild("PlayerScripts") and Players.LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
		if not module then
			return
		end
		local ok, result = pcall(function()
			return require(module):GetControls()
		end)
		if not ok then
			return
		end
		controls = result
	end
	if on then
		controls:Enable()
	else
		controls:Disable()
	end
end

local function sellPreview(): (number, number, number)
	local profile = DataController.Profile
	local stats = DataController.Stats
	if not profile then
		return 0, 0, 0
	end
	return Inventory.SellAllPreview(profile, stats and stats.Values.SellMultiplier or 1)
end

local function hotText(): string
	local list = HotFish.Current()
	if #list == 0 then
		return "nothing special"
	end
	local parts = {}
	for _, e in list do
		local f = Registry.Fish[e.FishId]
		table.insert(parts, `x{e.Mult} for {if f then f.Name else e.FishId}`)
	end
	return table.concat(parts, " and ")
end

local function fill(line: string): string
	local coins, fish = sellPreview()
	line = string.gsub(line, "{coins}", Format.Number(coins))
	line = string.gsub(line, "{fish}", tostring(fish))
	line = string.gsub(line, "{hot}", hotText())
	return line
end

local function say(text: string)
	typing += 1
	local mine = typing
	local line = refs.Line
	line.Text = text
	line.MaxVisibleGraphemes = 0
	local total = utf8.len(text) or #text
	task.spawn(function()
		local shown = 0
		while shown < total and mine == typing do
			shown += math.max(1, math.floor(TYPE_SPEED * task.wait()))
			line.MaxVisibleGraphemes = math.min(shown, total)
		end
		if mine == typing then
			line.MaxVisibleGraphemes = -1
		end
	end)
end

local function finishTyping()
	typing += 1
	refs.Line.MaxVisibleGraphemes = -1
end

local function findPromptPart(promptName: string): BasePart?
	local map = Workspace:FindFirstChild("Map")
	local prompt = map and map:FindFirstChild(promptName, true)
	local part = prompt and prompt.Parent
	if part and part:IsA("BasePart") then
		return part
	elseif part and part:IsA("Model") then
		return part.PrimaryPart or part:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

-- Actions -------------------------------------------------------------------------------------------

local function sellAll()
	local total, count, mutated = sellPreview()
	if count == 0 then
		say("Your bag has no fish yet. Go catch something and come back!")
		return
	end
	local profile = DataController.Profile
	local stats = DataController.Stats
	local bonus = if profile then Inventory.HotBonus(profile, stats and stats.Values.SellMultiplier or 1) else 0
	Modal.Confirm({
		Title = `Sell all {count} fish?`,
		Message = `You'll get {New.Highlight(Format.Number(total) .. " coins")}.`
			.. (if mutated > 0 then ` {mutated} fish with mutations are included.` else "")
			.. (if bonus > 0 then ` Hot fish bonus {New.Highlight("+" .. Format.Number(bonus), T.BadLip)}.` else "")
			.. " Treasure chests stay in your bag.",
		ConfirmText = "Sell",
		ConfirmColor = T.Gold,
		Icon = "ui/status/sell_bag",
		IconColor = T.Gold,
	}, function()
		if busy then
			return
		end
		busy = true
		local ok, ok2, msg = pcall(function()
			return Remotes.Func("SellAll"):InvokeServer()
		end)
		busy = false
		if ok and ok2 then
			say(`Pleasure doing business! That's {Format.Number(total)} coins for you.`)
			HUD.Notify(tostring(msg), T.Gold)
		else
			say("Hmm, something went wrong with the scales. Try again?")
		end
	end)
end

local function run(action: any)
	local npc = npcId and Registry.Dialogues[npcId]
	if not npc then
		return
	end
	local kind = action.Kind
	if kind == "SellAll" then
		sellAll()
	elseif kind == "HotFish" then
		local list = HotFish.Current()
		if #list == 0 then
			say("No special prices this hour. Check the sign by my stall later!")
		else
			local left = math.max(0, list[1].EndsAt - os.time())
			say(`This hour I pay {hotText()}. About {math.ceil(left / 60)} minutes left, so be quick!`)
		end
	elseif kind == "Banner" then
		GachaPageController.Open(action.Banner) -- MenuManager closes the dialogue
	elseif kind == "Menu" then
		HUD.MenuRequested:Fire(action.Menu) -- MenuManager closes the dialogue
	elseif kind == "Fusion" then
		require(script.Parent.FusionController).Open() -- Rod Fusion window; MenuManager closes the dialogue
	elseif kind == "Say" then
		say(fill(action.Line))
	elseif kind == "Talk" then
		local i = (talkIndex[npcId :: string] or 0) % #npc.Talk + 1
		talkIndex[npcId :: string] = i
		say(fill(npc.Talk[i]))
	end
end

-- Window --------------------------------------------------------------------------------------------

local function ensure()
	if gui then
		return
	end
	gui = Baked.Get("Dialogue")
	gui.Enabled = false
	local root = Baked.Find(gui, "Root")
	refs = {
		Root = root,
		Box = Baked.Find(root, "Box"),
		Line = Baked.Find(root, "Box/Content/Line"),
		Name = Baked.Find(root, "Speaker/Name"),
		Choices = {},
	}
	New.FitToScreen(root, 12)
	refs.Line.TextColor3 = T.Text -- the sample is SubText; spoken lines read better in the main text colour
	refs.Box.Activated:Connect(finishTyping)
	Baked.Find(root, "Close").Activated:Connect(DialogueController.Close)
	for i = 1, DialogueScreen.MaxChoices do
		local b = Baked.Find(root, "Choice" .. i)
		refs.Choices[i] = b
		b.Activated:Connect(function()
			local npc = npcId and Registry.Dialogues[npcId]
			local c = npc and npc.Choices[i]
			if c then
				finishTyping()
				run(c.Action)
			end
		end)
	end
	RunService.Heartbeat:Connect(function()
		if not npcId or not anchor then
			return
		end
		local char = Players.LocalPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - anchor.Position).Magnitude > WALK_AWAY then
			DialogueController.Close()
		end
	end)
end

function DialogueController.Open(id: string)
	local npc = Registry.Dialogues[id]
	if not npc then
		warn(`[Dialogue] unknown npc "{tostring(id)}"`)
		return
	end
	MenuManager.WillOpen("Dialogue") -- closes Main Menu, windows and the item card
	ensure()
	npcId = id
	anchor = findPromptPart(npc.Prompt)
	refs.Name.Text = npc.Name
	for i, b in refs.Choices do
		local c = npc.Choices[i]
		b.Visible = c ~= nil
		if c then
			b.Label.Text = c.Label
			New.SetImageKey(b.Icon, c.Icon, T.Track)
		end
	end
	local _, fish = sellPreview()
	local pool = if npc.Busy and fish > 0 then npc.Busy else npc.Greetings
	gui.Enabled = true
	setMoveEnabled(false)
	say(fill(pool[math.random(1, #pool)]))
end

function DialogueController.Close()
	if not npcId then
		return
	end
	npcId = nil
	anchor = nil
	typing += 1
	setMoveEnabled(true)
	if gui then
		gui.Enabled = false
	end
	MenuManager.Closed("Dialogue")
end

function DialogueController.IsOpen(): boolean
	return npcId ~= nil
end

function DialogueController.Init()
	Remotes.Event("OpenDialogue").OnClientEvent:Connect(function(id)
		if type(id) == "string" then
			DialogueController.Open(id)
		end
	end)
	task.spawn(ensure)
end

MenuManager.Register("Dialogue", { Layer = "Dialogue", Open = DialogueController.Open, Close = DialogueController.Close, IsOpen = DialogueController.IsOpen })

return DialogueController
