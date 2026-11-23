--!nonstrict
-- Generic confirm modal (Figma 14). Screen is baked in StarterGui ("Modal"); this module only binds it.
--   Modal.Confirm({ Title = "Sell all 18 fish?", Message = "...", ConfirmText = "Sell", ConfirmColor = New.Theme.Gold,
--                   Icon = "ui/status/sell_bag", CancelText?, OnCancel? }, function() ... end)

local New = require(script.Parent.New)
local Baked = require(script.Parent.Baked)
local MenuManager = require(script.Parent.MenuManager)
local T = New.Theme

local Modal = {}

local gui: any = nil
local refs: any = nil
local pending: (() -> ())? = nil
local pendingCancel: (() -> ())? = nil

local function ensure()
	if gui then
		return
	end
	gui = Baked.Get("Modal")
	local g = gui :: ScreenGui
	refs = {
		Window = Baked.Find(g, "Window"),
		Icon = Baked.Find(g, "Window/Body/Icon"),
		Title = Baked.Find(g, "Window/Body/Title"),
		Message = Baked.Find(g, "Window/Body/Message"),
		Cancel = Baked.Find(g, "Window/Footer/Cancel"),
		Confirm = Baked.Find(g, "Window/Footer/Confirm"),
	}
	New.FitWindow(refs.Window, Vector2.new(600, 349))
	refs.Cancel.Activated:Connect(function()
		local cb = pendingCancel
		Modal.Close()
		if cb then
			cb()
		end
	end)
	refs.Confirm.Activated:Connect(function()
		local cb = pending
		Modal.Close()
		New.Sfx("ui_confirm")
		if cb then
			cb()
		end
	end)
end

function Modal.Close()
	pending = nil
	pendingCancel = nil
	if gui then
		gui.Enabled = false
	end
	MenuManager.Closed("Modal")
end

function Modal.IsOpen(): boolean
	return gui ~= nil and (gui :: ScreenGui).Enabled
end

function Modal.Confirm(opts: { [string]: any }, onConfirm: () -> ())
	MenuManager.WillOpen("Modal")
	ensure()
	refs.Title.Text = opts.Title or "Are you sure?"
	refs.Message.RichText = true -- prices use New.Highlight
	refs.Message.Text = opts.Message or ""
	refs.Confirm.Text = opts.ConfirmText or "Confirm"
	refs.Cancel.Text = opts.CancelText or "Cancel"
	New.SetButtonColor(refs.Confirm, opts.ConfirmColor or T.Good)
	refs.Icon.Visible = opts.Icon ~= false
	if type(opts.Icon) == "string" then
		New.SetImageKey(refs.Icon, opts.Icon, opts.IconColor, opts.IconText)
	end
	pendingCancel = opts.OnCancel -- optional: runs when Cancel is pressed
	pending = onConfirm;
	(gui :: any).Enabled = true
end

MenuManager.Register("Modal", { Layer = "Modal", Close = Modal.Close, IsOpen = Modal.IsOpen })

return Modal
