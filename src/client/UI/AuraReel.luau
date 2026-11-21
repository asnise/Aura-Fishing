--!nonstrict
-- Runs the selected Eclipse reveal and opens the existing Item Card over the result controls.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)

local New = require(script.Parent.New)
local Baked = require(script.Parent.Baked)
local MenuManager = require(script.Parent.MenuManager)
local ItemDetail = require(script.Parent.ItemDetail)
local Motion = require(script.Parent.AuraRevealMotion)
local ReelScreen = require(script.Parent.Screens.AuraReel)

local T = New.Theme
local WHITE = Color3.new(1, 1, 1)
local AuraReel = {}

local gui: ScreenGui? = nil
local refs: any = nil
local playing = false
local current: any = nil

-- Undo a press/hover look left on a baked button when the screen was hidden mid-click.
local function resetButton(button: TextButton, face: Color3)
	local surface = button:FindFirstChild("Face") :: Frame?
	if surface then
		surface.Position = UDim2.fromOffset(0, 0)
	end
	local lip = button:FindFirstChild("Lip") :: Frame?
	if lip then
		lip.Visible = true
	end
	New.SetButtonColor(button, face)
end

local function stopTick(roll)
	if roll.tick then
		roll.tick:Disconnect()
		roll.tick = nil
	end
end

local function hide()
	if current then
		stopTick(current)
	end
	current = nil
	ItemDetail.Hide()
	MenuManager.Closed("AuraReel")
	if gui then
		gui.Enabled = false
	end
	playing = false
end

local function ensure()
	if gui then
		return
	end
	local g = Baked.Get("AuraReel")
	if not g:FindFirstChild("RarityOverlay") or not g:FindFirstChild("Ring", true) then
		-- Older place copies can still contain the previous baked reveal.
		local parent = g.Parent
		local updated = ReelScreen.Build()
		g:Destroy()
		updated.Parent = parent
		New.ApplyImages(updated)
		New.HookButtons(updated)
		g = updated
	end
	gui = g
	local function find(path: string): any
		return Baked.Find(g, path)
	end
	refs = {
		Dim = find("Dim"),
		Overlay = find("RarityOverlay"),
		EclipseDim = find("EclipseDim"),
		Rim = find("Canvas/EclipseRim"),
		Wave = find("Canvas/Shockwave"),
		Sparkle = find("Canvas/CoreSparkle"),
		Card = find("Canvas/Card"),
		Pop = find("Canvas/Card/Pop"),
		Rarity = find("Canvas/Card/Row/Rarity"),
		AuraName = find("Canvas/Card/Row/AuraName"),
		NewBadge = find("Canvas/Card/Row/NewBadge"),
		Equip = find("Canvas/Card/Buttons/Equip"),
		RollAgain = find("Canvas/Card/Buttons/RollAgain"),
		Close = find("Canvas/Card/Buttons/Close"),
	}
	local scale = find("Canvas/Scale")
	local function rescale()
		local size = g.AbsoluteSize
		if size.X > 0 and size.Y > 0 then
			scale.Scale = math.min(size.X / ReelScreen.Canvas.X, size.Y / ReelScreen.Canvas.Y)
			if playing and current and current.revealed then
				task.defer(ItemDetail.Place)
			end
		end
	end
	rescale()
	g:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)

	refs.TapHint = New.Text({
		Name = "TapHint",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.fromOffset(260, 28),
		Text = "Tap to close",
		TextColor3 = Color3.new(1, 1, 1),
		FontFace = T.FontBadge,
		TextSize = 16,
		Visible = false,
		ZIndex = 50,
		Parent = g,
		[New.Children] = { New("UIStroke", { Color = T.Text, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }) },
	})
	refs.Dim.Activated:Connect(function()
		if current and not current.revealed then
			current.skip()
		elseif current then
			current.close() -- tap anywhere outside the card
		end
	end)
	-- the card closes itself on an outside tap: that ends the reveal too
	ItemDetail.Hidden:Connect(function()
		if current and current.revealed then
			current.close()
		end
	end)
	refs.Equip.Activated:Connect(function()
		if current and current.revealed then
			current.equip()
		end
	end)
	refs.RollAgain.Activated:Connect(function()
		if current and current.revealed then
			current.rollAgain()
		end
	end)
	refs.Close.Activated:Connect(function()
		if current and current.revealed then
			current.close()
		end
	end)
end

-- The ring picture is a child that scales with the frame, so stroke and glow grow like the Figma node.
local function renderRing(ring, size, alpha, filled)
	ring.Size = UDim2.fromOffset(size, size)
	ring.Ring.ImageTransparency = 1 - alpha
	if filled then
		ring.BackgroundTransparency = 1 - alpha
	end
	ring.Visible = alpha > 0
end

function AuraReel.IsPlaying(): boolean
	return playing
end

function AuraReel.Play(auraId: string, opts: any?)
	local aura = Registry.Auras[auraId]
	if playing or not aura then
		return
	end
	opts = opts or {}
	MenuManager.WillOpen("AuraReel")
	playing = true
	ensure()
	local rarity = Registry.Rarities[aura.Rarity]
	local color = rarity.Color
	local clip = Motion.ForTier(rarity.Tier)
	local roll: any = {}
	current = roll

	refs.Card.Visible = false
	refs.TapHint.Visible = false
	refs.Overlay.BackgroundColor3 = color
	refs.Rim.Ring.ImageColor3 = color
	refs.Wave.Ring.ImageColor3 = color
	local function render(time: number)
		local sample = Motion.Sample
		refs.Dim.BackgroundTransparency = 1 - sample(clip.Background, time)
		refs.Overlay.BackgroundTransparency = 1 - sample(clip.Overlay, time)
		local diameter = 36 * sample(clip.SparkleScale, time)
		refs.Sparkle.Size = UDim2.fromOffset(diameter, diameter)
		refs.Sparkle.ImageTransparency = 1 - sample(clip.Sparkle, time)
		refs.Sparkle.Rotation = sample(clip.Rotation, time)
		if clip.Rim then
			refs.EclipseDim.BackgroundTransparency = 1 - sample(clip.Dim, time)
			renderRing(refs.Rim, 462 * sample(clip.RimScale, time), sample(clip.Rim, time), true)
			renderRing(refs.Wave, 478 * sample(clip.WaveScale, time), sample(clip.Wave, time), false)
		else
			refs.EclipseDim.BackgroundTransparency = 1
			refs.Rim.Visible = false
			refs.Wave.Visible = false
		end
	end

	local function reveal()
		if roll.revealed then
			return
		end
		roll.revealed = true
		refs.Rarity.Text = string.upper(rarity.Name)
		refs.Rarity.BackgroundColor3 = color
		refs.AuraName.Text = aura.Name
		refs.NewBadge.Visible = opts.isNew == true
		refs.Equip.Text = if opts.equipped then "EQUIPPED" else "EQUIP"
		resetButton(refs.Equip, if opts.equipped then T.Good:Lerp(WHITE, 0.3) else T.Good)
		refs.RollAgain.Text = opts.rollAgainText or "ROLL AGAIN"
		resetButton(refs.RollAgain, T.Gem)
		resetButton(refs.Close, Color3.fromRGB(201, 187, 163))
		-- only the Item Card Detail shows (it has its own Equip / Star Up); the bottom rarity bar stays hidden
		refs.Card.Visible = false
		refs.TapHint.Visible = true
		task.defer(function()
			if current == roll then
				ItemDetail.Show({ Kind = "Aura", Id = auraId, Info = true }, refs.Card, true)
			end
		end)
	end

	roll.close = function()
		hide()
		if opts.onClose then
			opts.onClose()
		end
	end
	roll.equip = function()
		if not opts.equipped and opts.onEquip then
			opts.onEquip()
		end
		if current == roll then
			roll.close()
		end
	end
	roll.rollAgain = function()
		hide()
		if opts.onRollAgain then
			opts.onRollAgain()
		end
	end
	roll.skip = function()
		stopTick(roll)
		render(clip.EndAt)
		reveal()
	end

	render(0)
	local screen = gui :: ScreenGui
	screen.Enabled = true
	local start = os.clock()
	roll.tick = RunService.RenderStepped:Connect(function()
		local time = math.min(os.clock() - start, clip.EndAt)
		render(time)
		if time >= clip.RevealAt then
			reveal()
		end
		if time >= clip.EndAt then
			stopTick(roll)
		end
	end)
end

MenuManager.Register("AuraReel", { Layer = "Modal", Close = hide, IsOpen = AuraReel.IsPlaying })

return AuraReel
