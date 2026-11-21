--!nonstrict
-- Starter Pack offer modal controller (Figma 3546:36782, Screen C19 · Starter Pack offer).
-- Static layout is baked into StarterGui ("StarterPackModal", builder: UI/Screens/StarterPackModal.luau).
-- This module binds data, events, and handles Open/Close with MenuManager.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Products = require(Shared.Config.Products)

local New = require(script.Parent.New)
local Baked = require(script.Parent.Baked)
local MenuManager = require(script.Parent.MenuManager)
local ItemDetail = require(script.Parent.ItemDetail)

local StarterPackModal = {}

local gui: ScreenGui? = nil
local refs: { [string]: any } = {}
local pendingBuy: (() -> ())? = nil

-- Item rows follow Products.StarterPack.Rewards order. Tap a row to open its Item Detail card;
-- Gems have no card, so the row shows a one-line explanation instead.
local GEMS_HINT = "Spend Gems on Aura Altar rolls"

local function bindRows(items: Instance)
	local rewards = Products.Products.StarterPack.Rewards
	local rows = {}
	for _, row in items:GetChildren() do
		if row:IsA("Frame") then
			table.insert(rows, row)
		end
	end
	table.sort(rows, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i, row in rows do
		local reward = rewards[i]
		local label = row:FindFirstChild("Label") :: TextLabel?
		if not reward or not label then
			continue
		end
		local original = label.Text
		row.Active = true
		row.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			if reward.Kind == "Gems" then
				label.Text = if label.Text == original then GEMS_HINT else original
			elseif reward.Kind == "Bait" then
				ItemDetail.Show({ Kind = "Bait", Id = reward.Id, Info = true }, row)
			elseif reward.Kind == "Item" then
				ItemDetail.Show({ Kind = if reward.Category == "Rods" then "Rod" else "Line", Id = reward.Id, Info = true }, row)
			end
		end)
	end
end

local function ensureGui(): ScreenGui
	if gui and gui.Parent then
		return gui
	end

	local g = Baked.Get("StarterPackModal")
	local find = function(path: string): any
		return Baked.Find(g, path)
	end

	local buy = find("Window/Footer/ButtonsRow/BtnBuy")
	local face = buy:FindFirstChild("Face")
	local content = face and face:FindFirstChild("Content")
	refs = {
		Gui = g,
		Window = find("Window"),
		Price = if content then content:FindFirstChild("Price") else buy:FindFirstChild("Price"),
		BtnBuy = buy,
		BtnLater = find("Window/Footer/ButtonsRow/BtnLater"),
	}

	-- A baked UIScale has no listeners: fit the window to the screen again at runtime (phones are ~360px tall).
	New.FitWindow(refs.Window)
	-- Item Detail (DisplayOrder 30) must sit above this modal; older bakes still use 35.
	g.DisplayOrder = 25
	bindRows(find("Window/Body/Items"))

	if refs.BtnLater then
		refs.BtnLater.Activated:Connect(function()
			StarterPackModal.Close()
		end)
	end
	if refs.BtnBuy then
		refs.BtnBuy.Activated:Connect(function()
			local cb = pendingBuy
			StarterPackModal.Close()
			if cb then
				cb()
			else
				Remotes.Event("PromptProduct"):FireServer("StarterPack")
			end
		end)
	end

	gui = g
	return g
end

function StarterPackModal.Close()
	pendingBuy = nil
	if gui then
		gui.Enabled = false
	end
	MenuManager.Closed("StarterPackModal")
end

function StarterPackModal.IsOpen(): boolean
	return gui ~= nil and gui.Enabled == true
end

function StarterPackModal.Open(price: number?, onBuy: (() -> ())?)
	MenuManager.WillOpen("StarterPackModal")
	local g = ensureGui()

	local pDef = Products.Products.StarterPack
	local displayPrice = price or (pDef and pDef.Price) or 49
	if refs.Price then
		refs.Price.Text = tostring(displayPrice)
	end
	pendingBuy = onBuy

	g.Enabled = true
end

MenuManager.Register("StarterPackModal", {
	Layer = "Modal",
	Close = StarterPackModal.Close,
	IsOpen = StarterPackModal.IsOpen,
})

return StarterPackModal
