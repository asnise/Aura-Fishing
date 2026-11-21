--!strict
-- Instance path helpers. Paths are dot-separated from the DataModel ("Workspace.Map.Dock",
-- optional leading "game."), or an array of names when a name itself contains a dot.

local Path = {}

local function split(path: any): { string }
	if typeof(path) == "table" then
		local out = {}
		for _, s in path do
			table.insert(out, tostring(s))
		end
		return out
	end
	local out = {}
	for part in string.gmatch(tostring(path or ""), "[^%.]+") do
		table.insert(out, part)
	end
	return out
end

-- Resolve a path to an Instance. Returns nil + reason on failure.
function Path.resolve(path: any): (Instance?, string?)
	if path == nil or path == "" or path == "game" then
		return game, nil
	end
	local parts = split(path)
	if parts[1] == "game" then
		table.remove(parts, 1)
	end
	if #parts == 0 then
		return game, nil
	end
	local current: Instance = game
	for i, name in parts do
		local child = current:FindFirstChild(name)
		if not child and i == 1 then
			local ok, svc = pcall(game.GetService, game, name)
			if ok and svc then
				child = svc
			end
		end
		if not child then
			local children = {}
			for j, c in current:GetChildren() do
				if j > 25 then
					table.insert(children, "...")
					break
				end
				table.insert(children, c.Name)
			end
			return nil,
				string.format(
					'"%s" not found in %s (children: %s)',
					name,
					Path.of(current),
					#children > 0 and table.concat(children, ", ") or "none"
				)
		end
		current = child
	end
	return current, nil
end

function Path.require(path: any): Instance
	local inst, err = Path.resolve(path)
	if not inst then
		error(err, 0)
	end
	return inst
end

-- Full path of an instance ("Workspace.Map.Dock"; "game" for the DataModel).
function Path.of(inst: Instance?): string
	if inst == nil then
		return "nil"
	end
	if inst == game then
		return "game"
	end
	local parts = {}
	local cur: Instance? = inst
	while cur and cur ~= game do
		table.insert(parts, 1, cur.Name)
		cur = cur.Parent
	end
	if cur == nil then
		return "(detached)." .. table.concat(parts, ".")
	end
	return table.concat(parts, ".")
end

-- Roots that Rojo syncs from src/ (see default.project.json). Editing them in Studio gets overwritten.
Path.ROJO_ROOTS = {
	"ReplicatedStorage.Shared",
	"ServerScriptService.Server",
	"StarterPlayer.StarterPlayerScripts.Client",
}

function Path.rojoRoot(inst: Instance): string?
	local p = Path.of(inst)
	for _, root in Path.ROJO_ROOTS do
		if p == root or string.sub(p, 1, #root + 1) == root .. "." then
			return root
		end
	end
	return nil
end

return Path
