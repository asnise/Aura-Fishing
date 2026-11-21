--!nonstrict
-- Dev panel (F2). Asks the server once ("ping") whether this player is a dev (Config/Dev); if not,
-- F2 does nothing. Commands run on the server (DevService) — the panel only sends text.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local Baked = require(script.Parent.Parent.UI.Baked)

local DevController = {}

local isDev = false
local gui: ScreenGui? = nil
local log: TextLabel? = nil
local lines: { string } = {}

local function append(text: string)
	table.insert(lines, 1, text)
	while #lines > 20 do
		table.remove(lines)
	end
	if log then
		log.Text = table.concat(lines, "\n")
	end
end

local function run(line: string)
	if line == "" then
		return
	end
	local ok, msg = Remotes.Func("DevCommand"):InvokeServer(line)
	append(`{if ok then "[OK]" else "[FAIL]"} {line}\n   {msg}`)
end

local function ensure()
	if gui then
		return
	end
	local g = Baked.Get("DevPanel")
	gui = g
	local w = Baked.Find(g, "Window")
	log = Baked.Find(w, "Output/Log")
	local input = Baked.Find(w, "Input")
	Baked.Find(w, "Close").Activated:Connect(function()
		g.Enabled = false
	end)
	Baked.Find(w, "Run").Activated:Connect(function()
		run(input.Text)
	end)
	input.FocusLost:Connect(function(enter)
		if enter then
			run(input.Text)
		end
	end)
	for _, b in Baked.Find(w, "Quick"):GetChildren() do
		if b:IsA("GuiButton") and b:GetAttribute("Command") then
			b.Activated:Connect(function()
				run(b:GetAttribute("Command"))
			end)
		end
	end
end

function DevController.Toggle()
	if not isDev then
		return
	end
	ensure()
	local g = gui :: ScreenGui
	g.Enabled = not g.Enabled
end

function DevController.Init()
	task.spawn(function()
		local ok, res = pcall(function()
			return Remotes.Func("DevCommand"):InvokeServer("ping")
		end)
		isDev = ok and res == true
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.F2 then
			DevController.Toggle()
		end
	end)
end

return DevController
