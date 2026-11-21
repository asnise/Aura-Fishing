--!nonstrict
-- Skills window (C4, GDD 7.1): Keen Eye / Quick Hands / Multi-Cast, paid with skill points (+1 per
-- level-up, kept through Rebirth). Built with the UI/Window kit (same look as Aquarium / Store) until a
-- Figma design lands. Server: ProgressionService.UpgradeSkill (remote "UpgradeSkill").
--   Open: HUD.SkillsRequested (SKILLS button in the Character window header).
--   Header: unspent points. One row per skill: icon, "Name  Lv.N / Max", "now -> next" + description,
--   UPGRADE (cost in points) / MAX.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Registry = require(Shared.Registry)
local Remotes = require(Shared.Remotes)
local Skills = require(Shared.Skills)
local Format = require(Shared.Util.Format)

local New = require(script.Parent.Parent.UI.New)
local Window = require(script.Parent.Parent.UI.Window)
local HUD = require(script.Parent.HUDController)
local DataController = require(script.Parent.DataController)

local T = New.Theme

local SkillsController = {}

-- tile colour + art key per skill (Config/Skills.Icon wins when set)
local LOOK = {
	KeenEye = { Icon = "ui/icons/fishdex", Color = T.TintSky },
	QuickHands = { Icon = "ui/status/bite_alert", Color = T.TintPeach },
	MultiCast = { Icon = "ui/icons/extra_cast", Color = T.TintMint },
}

local win: any = nil
local busy = false

local function statText(stat: string, v: number): string
	local def = Registry.StatDefs[stat]
	if stat == "ExtraLines" then
		return `{math.floor(v)} extra line{if v == 1 then "" else "s"}`
	end
	return Format.Stat(stat, def, v)
end

local function render()
	if not win or not win.IsOpen() then
		return
	end
	local profile = DataController.Profile
	if not profile then
		return
	end
	local points = Skills.Points(profile)
	win.Header.Text = `Skill points: {New.Highlight(tostring(points), T.GemLip)}   (+1 every level-up, kept after Rebirth)`
	win.Header.RichText = true
	Window.Clear(win.Body)
	Window.List(win.Body, 10)
	for i, s in Skills.State(profile) do
		local look = LOOK[s.Id] or {}
		local now = statText(s.Stat, s.Current)
		local sub = if s.Next ~= nil
			then `{now}  ->  {New.Highlight(statText(s.Stat, s.Next), T.GoodLip)}\n{s.Description}`
			else `{now}  (MAX)\n{s.Description}`
		local canPay = s.Cost ~= nil and points >= s.Cost
		local row = Window.Row({
			Name = s.Id,
			Order = i,
			Height = 86,
			Icon = s.Icon or look.Icon,
			IconColor = look.Color,
			IconText = string.sub(s.Name, 1, 1),
			Title = `{s.Name}  <font color="#{T.SubText:ToHex()}">Lv.{s.Level} / {s.MaxLevel}</font>`,
			Sub = sub,
			Button = {
				Text = if s.Cost then `UPGRADE  {s.Cost} pt` else "MAX",
				Color = T.Good,
				Width = 170,
				Enabled = canPay,
				OnClick = function()
					if busy then
						return
					end
					busy = true
					local ok, msg = Remotes.Func("UpgradeSkill"):InvokeServer(s.Id)
					busy = false
					if type(msg) == "string" and msg ~= "" then
						HUD.Notify(msg, if ok then T.GoodLip else T.Bad)
					end
				end,
			},
		})
		row.Parent = win.Body
	end
end

function SkillsController.Open()
	if not win then
		win = Window.Create({ Name = "Skills", Title = "Skills", Size = Vector2.new(640, 420), StackOn = { "Character" } })
		win.OnOpen = render
	end
	win.Open()
	render()
end

function SkillsController.Init()
	HUD.SkillsRequested:Connect(SkillsController.Open)
	DataController.Changed:Connect(render)
end

return SkillsController
