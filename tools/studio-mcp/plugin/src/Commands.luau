--!strict
-- Command handlers. Each handler gets (params, ctx) and returns a JSON-safe result or errors.

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local LogService = game:GetService("LogService")
local Selection = game:GetService("Selection")
local ScriptEditorService = game:GetService("ScriptEditorService")
local StarterGui = game:GetService("StarterGui")

local Path = require(script.Parent.Path)
local Codec = require(script.Parent.Codec)
local Running = require(script.Parent.Running)

type Ctx = { classes: () -> { [string]: { super: string?, props: { string } } }?, version: string }

local Commands: { [string]: (params: any, ctx: Ctx) -> any } = {}

-- Run fn as one undo step. On error the recording is cancelled (changes rolled back).
local function withUndo(name: string, fn: () -> ...any): any
	local recording: string? = nil
	local okBegin, id = pcall(function()
		return ChangeHistoryService:TryBeginRecording("StudioBridge: " .. name)
	end)
	if okBegin then
		recording = id
		Running.recording = id
	end
	local ok, result = xpcall(fn, function(e)
		return e
	end)
	if recording then
		Running.recording = nil
		ChangeHistoryService:FinishRecording(
			recording,
			if ok then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
		)
	elseif ok then
		ChangeHistoryService:SetWaypoint("StudioBridge: " .. name)
	end
	if not ok then
		error(result, 0)
	end
	return result
end

local function isScript(inst: Instance): boolean
	return inst:IsA("LuaSourceContainer")
end

---------------------------------------------------------------- basic

Commands.noop = function()
	return "pong"
end

Commands.ping = function(_, ctx)
	return { pong = true, version = ctx.version, place = game.Name, placeId = game.PlaceId }
end

Commands.get_tree = function(p)
	local root = Path.require(p.path)
	local maxDepth = p.depth or 2
	local maxNodes = p.maxNodes or 400
	local filter: string? = p.classFilter
	local count = 0
	local truncated = false

	local function node(inst: Instance, depth: number): any
		count += 1
		local n: any = { name = inst.Name, className = inst.ClassName }
		local children = inst:GetChildren()
		if #children == 0 then
			return n
		end
		if depth >= maxDepth then
			n.childCount = #children
			return n
		end
		n.children = {}
		for _, c in children do
			if count >= maxNodes then
				truncated = true
				n.more = #children - #n.children
				break
			end
			if filter and not c:IsA(filter) then
				-- still walk through for matching descendants
				local sub = node(c, depth + 1)
				if sub.children and #sub.children > 0 then
					table.insert(n.children, sub)
				else
					count -= 1
				end
			else
				table.insert(n.children, node(c, depth + 1))
			end
		end
		return n
	end

	if root == game and p.path == nil then
		-- default: the services people care about
		local out = { name = "game", className = "DataModel", children = {} }
		for _, svc in {
			"Workspace",
			"Lighting",
			"ReplicatedStorage",
			"ServerScriptService",
			"ServerStorage",
			"StarterGui",
			"StarterPack",
			"StarterPlayer",
			"SoundService",
			"Teams",
		} do
			local ok, s = pcall(game.GetService, game, svc)
			if ok and s then
				table.insert(out.children, node(s, 1))
			end
		end
		return { path = "game", tree = out, nodes = count, truncated = truncated }
	end
	return { path = Path.of(root), tree = node(root, 0), nodes = count, truncated = truncated }
end

Commands.find_instances = function(p)
	local root = Path.require(p.path)
	local limit = p.limit or 100
	local name = p.name and string.lower(p.name)
	local out = {}
	local total = 0
	for _, d in root:GetDescendants() do
		local match = true
		if name then
			local okFind, found = pcall(string.find, string.lower(d.Name), name)
			match = okFind and found ~= nil
		end
		if match and p.className then
			match = d:IsA(p.className)
		end
		if match then
			total += 1
			if #out < limit then
				table.insert(out, { path = Path.of(d), className = d.ClassName })
			end
		end
	end
	return { results = out, total = total, truncated = total > #out }
end

---------------------------------------------------------------- properties

local FALLBACK_PROPS = {
	"Name", "Parent", "Archivable", "Position", "Size", "CFrame", "Anchored", "CanCollide", "Transparency",
	"Color", "Material", "AnchorPoint", "BackgroundColor3", "BackgroundTransparency", "Visible", "ZIndex",
	"LayoutOrder", "Text", "TextColor3", "TextSize", "FontFace", "Image", "ImageColor3", "Enabled",
}

local function propertyNames(inst: Instance, ctx: Ctx): { string }
	local classes = ctx.classes()
	if not classes then
		return FALLBACK_PROPS
	end
	local names, seen = {}, {}
	local cls: string? = inst.ClassName
	local guard = 0
	while cls and classes[cls] and guard < 50 do
		guard += 1
		for _, n in classes[cls].props do
			if not seen[n] then
				seen[n] = true
				table.insert(names, n)
			end
		end
		cls = classes[cls].super
	end
	if #names == 0 then
		return FALLBACK_PROPS
	end
	table.sort(names)
	return names
end

local SKIP_PROPS = { Source = true, RobloxLocked = true, Capabilities = true, Sandboxed = true, UniqueId = true }

Commands.get_properties = function(p, ctx)
	local inst = Path.require(p.path)
	local names = p.properties or propertyNames(inst, ctx)
	local props = {}
	local unreadable = {}
	for _, n in names do
		if SKIP_PROPS[n] and not p.properties then
			continue
		end
		local ok, v = pcall(function()
			return (inst :: any)[n]
		end)
		if ok then
			if typeof(v) ~= "RBXScriptSignal" and typeof(v) ~= "function" then
				props[n] = Codec.encode(v)
			end
		elseif p.properties then
			table.insert(unreadable, n)
		end
	end
	local attrs = {}
	for k, v in inst:GetAttributes() do
		attrs[k] = Codec.encode(v)
	end
	local result: any = {
		path = Path.of(inst),
		className = inst.ClassName,
		properties = props,
		attributes = attrs,
		tags = inst:GetTags(),
		childCount = #inst:GetChildren(),
		rojoManaged = Path.rojoRoot(inst) ~= nil,
	}
	if #unreadable > 0 then
		result.unreadable = unreadable
	end
	if isScript(inst) then
		result.sourceLines = #string.split((inst :: any).Source, "\n")
	end
	return result
end

local function applyAttributes(inst: Instance, attrs: any, remove: any)
	if attrs then
		for k, v in attrs do
			inst:SetAttribute(k, Codec.decodeAttribute(v))
		end
	end
	if remove then
		for _, k in remove do
			inst:SetAttribute(k, nil)
		end
	end
end

-- Apply props; Parent last so the instance is fully set up before it appears.
local function applyProps(inst: Instance, props: any)
	if not props then
		return
	end
	local parent = nil
	for k, v in props do
		if k == "Parent" then
			parent = v
		else
			Codec.setProperty(inst, k, v)
		end
	end
	if parent ~= nil then
		Codec.setProperty(inst, "Parent", parent)
	end
end

Commands.set_properties = function(p)
	local inst = Path.require(p.path)
	return withUndo("set " .. inst.Name, function()
		applyProps(inst, p.props)
		applyAttributes(inst, p.attributes, p.removeAttributes)
		for _, t in p.addTags or {} do
			inst:AddTag(t)
		end
		for _, t in p.removeTags or {} do
			inst:RemoveTag(t)
		end
		local warning = Path.rojoRoot(inst)
			and "Instance is synced by Rojo from src/; this change will be overwritten on the next sync." or nil
		return { path = Path.of(inst), warning = warning }
	end)
end

Commands.create_instance = function(p)
	local parent = Path.require(p.parent)
	return withUndo("create " .. tostring(p.className), function()
		local inst = Instance.new(p.className)
		local props = p.props or {}
		local explicitParent = props.Parent
		props.Parent = nil
		applyProps(inst, props)
		applyAttributes(inst, p.attributes, nil)
		inst.Parent = if explicitParent then Path.require(explicitParent) else parent
		return {
			path = Path.of(inst),
			className = inst.ClassName,
			warning = Path.rojoRoot(inst) and "Created inside a Rojo-synced folder; Rojo may delete it on sync." or nil,
		}
	end)
end

Commands.delete_instance = function(p)
	local inst = Path.require(p.path)
	if inst == game or inst.Parent == game then
		error("refusing to delete a service or the DataModel: " .. Path.of(inst), 0)
	end
	local fullPath = Path.of(inst)
	for _, root in Path.ROJO_ROOTS do
		if fullPath == root then
			error("refusing to delete the Rojo-synced root " .. root, 0)
		end
	end
	withUndo("delete " .. inst.Name, function()
		inst.Parent = nil -- Parent=nil instead of Destroy keeps it restorable by undo
	end)
	return { deleted = fullPath }
end

---------------------------------------------------------------- scripts

Commands.get_script_source = function(p)
	local inst = Path.require(p.path)
	if not isScript(inst) then
		error(Path.of(inst) .. " is a " .. inst.ClassName .. ", not a script", 0)
	end
	local src: string = (inst :: any).Source
	local lines = string.split(src, "\n")
	local first = p.startLine or 1
	local last = math.min(p.endLine or #lines, #lines)
	local slice = table.concat(lines, "\n", first, last)
	return {
		path = Path.of(inst),
		className = inst.ClassName,
		totalLines = #lines,
		startLine = first,
		endLine = last,
		source = slice,
		rojoManaged = Path.rojoRoot(inst) ~= nil,
	}
end

Commands.set_script_source = function(p)
	local inst = Path.require(p.path)
	if not isScript(inst) then
		error(Path.of(inst) .. " is a " .. inst.ClassName .. ", not a script", 0)
	end
	local root = Path.rojoRoot(inst)
	if root and not p.force then
		error(
			string.format(
				"%s is under %s, which Rojo syncs from src/. Edit the file in src/ instead (or pass force=true; Rojo will overwrite it).",
				Path.of(inst),
				root
			),
			0
		)
	end
	local source: string = p.source
	withUndo("edit " .. inst.Name, function()
		local ok = pcall(function()
			ScriptEditorService:UpdateSourceAsync(inst :: any, function()
				return source
			end)
		end)
		if not ok then
			(inst :: any).Source = source
		end
	end)
	return {
		path = Path.of(inst),
		lines = #string.split(source, "\n"),
		warning = root and "Rojo-managed script edited with force=true; Rojo will overwrite it." or nil,
	}
end

---------------------------------------------------------------- run_luau

local runCounter = 0

-- Require a temporary ModuleScript that wraps `body`. Returns (fn, nil) or (nil, compileError).
local function compile(body: string): (((...any) -> ...any)?, string?)
	runCounter += 1
	local ms = Running.trackTemp(Instance.new("ModuleScript")) :: ModuleScript
	ms.Name = "StudioBridgeRun" .. runCounter
	-- Header on the same line keeps user line numbers intact.
	ms.Source = "return function(...) " .. body .. "\nend"
	local errors: { string } = {}
	local conn = Running.track(LogService.MessageOut:Connect(function(msg, kind)
		if kind == Enum.MessageType.MessageError then
			table.insert(errors, msg)
		end
	end))
	local ok, result = pcall(require, ms)
	task.wait() -- let MessageOut deliver the syntax error text
	Running.untrack(conn)
	local tempName = ms.Name
	Running.untrackTemp(ms)
	if ok and typeof(result) == "function" then
		return result, nil
	end
	local detail: { string } = {}
	for _, e in errors do
		if string.find(e, tempName, 1, true) or string.find(e, "Expected") or string.find(e, "syntax") then
			table.insert(detail, (string.gsub(e, "[%w%.]*" .. tempName, "code")))
		end
	end
	return nil, (#detail > 0 and table.concat(detail, "\n") or tostring(result))
end

Commands.run_luau = function(p)
	local code: string = p.code
	local fn: any, compileErr: string? = nil, nil
	-- A single line without statements is treated as an expression first.
	local statement = string.match(code, "^%s*return%s")
		or string.match(code, "^%s*local%s")
		or string.match(code, "^%s*[%a_][%w_%.]*%s*=[^=]") -- assignment
		or string.match(code, "^%s*(%a+)") == "for"
		or string.match(code, "^%s*(%a+)") == "if"
		or string.match(code, "^%s*(%a+)") == "while"
		or string.match(code, "^%s*(%a+)") == "do"
		or string.match(code, "^%s*(%a+)") == "function"
	if not string.find(code, "\n") and not statement then
		fn = compile("return (" .. code .. ")")
	end
	if not fn then
		fn, compileErr = compile(code)
	end
	if not fn then
		return { error = "compile error: " .. tostring(compileErr), output = {}, returns = {} }
	end

	local output = {}
	local conn = Running.track(LogService.MessageOut:Connect(function(msg, kind)
		if #output < 500 then
			local tag = if kind == Enum.MessageType.MessageWarning
				then "warn"
				elseif kind == Enum.MessageType.MessageError then "error"
				elseif kind == Enum.MessageType.MessageInfo then "info"
				else "print"
			table.insert(output, { kind = tag, text = msg })
		end
	end))
	local packed: any
	local runErr: string? = nil
	local t0 = os.clock()
	local ok, err = pcall(function()
		withUndo("run_luau", function()
			local res = table.pack(xpcall(fn, function(e)
				return debug.traceback(tostring(e), 2)
			end))
			if not res[1] then
				error(res[2], 0)
			end
			packed = res
		end)
	end)
	if not ok then
		runErr = tostring(err)
	end
	task.wait() -- flush MessageOut
	Running.untrack(conn)

	local returns = {}
	if packed then
		for i = 2, packed.n do
			returns[i - 1] = Codec.encode(packed[i])
		end
	end
	return {
		returns = returns,
		output = output,
		error = runErr,
		elapsedMs = math.floor((os.clock() - t0) * 1000),
	}
end

---------------------------------------------------------------- selection

Commands.get_selection = function()
	local out = {}
	for _, inst in Selection:Get() do
		table.insert(out, { path = Path.of(inst), className = inst.ClassName })
	end
	return out
end

Commands.set_selection = function(p)
	local list = {}
	for _, path in p.paths or {} do
		table.insert(list, Path.require(path))
	end
	Selection:Set(list)
	local out = {}
	for _, inst in list do
		table.insert(out, Path.of(inst))
	end
	return { selected = out }
end

---------------------------------------------------------------- UI preview

local GENERATED_ROOTS = {
	"StarterPlayer.StarterPlayerScripts.Client.UI.Generated",
	"ReplicatedStorage.Shared",
	"StarterPlayer.StarterPlayerScripts.Client",
}
local SOLO_ATTR = "StudioBridgeHidden"

local function findModule(spec: any): ModuleScript
	if typeof(spec) == "table" or string.find(spec, "%.") then
		local inst = Path.require(spec)
		assert(inst:IsA("ModuleScript"), Path.of(inst) .. " is not a ModuleScript")
		return inst :: ModuleScript
	end
	for _, rootPath in GENERATED_ROOTS do
		local root = Path.resolve(rootPath)
		if root then
			local direct = root:FindFirstChild(spec)
			if direct and direct:IsA("ModuleScript") then
				return direct
			end
			for _, d in root:GetDescendants() do
				if d.Name == spec and d:IsA("ModuleScript") then
					return d
				end
			end
		end
	end
	error(string.format('UI module "%s" not found under %s', spec, table.concat(GENERATED_ROOTS, ", ")), 0)
end

local function countRefs(refs: any): (number, { string })
	local names = {}
	if typeof(refs) == "table" then
		for k in refs do
			table.insert(names, tostring(k))
		end
	end
	table.sort(names)
	return #names, names
end

local function unsolo()
	for _, g in StarterGui:GetChildren() do
		if g:IsA("LayerCollector") and g:GetAttribute(SOLO_ATTR) then
			g.Enabled = true
			g:SetAttribute(SOLO_ATTR, nil)
		end
	end
end

Commands.mount_ui_module = function(p)
	local module = findModule(p.modulePath)
	local guiName: string = p.screenGuiName or "FigmaPreview"

	-- require() caches per ModuleScript, so require a fresh clone to pick up Rojo/Figma changes.
	local clone = Running.trackTemp(module:Clone()) :: ModuleScript
	clone.Name = module.Name .. "_StudioBridgePreview"
	local usesScript = string.find(clone.Source, "script%.") ~= nil
	if usesScript then
		clone.Parent = module.Parent -- keep script.Parent-relative requires working
	end
	local okReq, build = pcall(require, clone)
	Running.untrackTemp(clone)
	if not okReq then
		error("require " .. Path.of(module) .. " failed: " .. tostring(build), 0)
	end
	if typeof(build) ~= "function" then
		error(Path.of(module) .. " did not return a function(parent) -> { Root, Refs }", 0)
	end

	return withUndo("mount " .. module.Name, function()
		local gui = StarterGui:FindFirstChild(guiName)
		if gui and not gui:IsA("ScreenGui") then
			error("StarterGui." .. guiName .. " exists and is not a ScreenGui", 0)
		end
		if not gui then
			local sg = Instance.new("ScreenGui")
			sg.Name = guiName
			sg.ResetOnSpawn = false
			sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			sg.IgnoreGuiInset = true
			sg:SetAttribute("StudioBridgePreview", true)
			sg.Parent = StarterGui
			gui = sg
		else
			gui:ClearAllChildren()
		end
		assert(gui)
		;(gui :: ScreenGui).Enabled = true
		StarterGui.ShowDevelopmentGui = true

		if p.solo then
			for _, g in StarterGui:GetChildren() do
				if g ~= gui and g:IsA("LayerCollector") and g.Enabled then
					g:SetAttribute(SOLO_ATTR, true)
					g.Enabled = false
				end
			end
		end

		local result = build(gui)
		local root = typeof(result) == "table" and result.Root or nil
		local refCount, refNames = countRefs(typeof(result) == "table" and result.Refs or nil)
		Selection:Set({ if typeof(root) == "Instance" then root else gui })
		return {
			module = Path.of(module),
			screenGui = Path.of(gui),
			root = typeof(root) == "Instance" and Path.of(root) or nil,
			refCount = refCount,
			refs = refNames,
			descendants = #gui:GetDescendants(),
			note = "Visible in the Studio viewport (StarterGui.ShowDevelopmentGui = true). Not saved by Rojo; unmount_ui_module removes it.",
		}
	end)
end

Commands.unmount_ui_module = function(p)
	local guiName: string = p.screenGuiName or "FigmaPreview"
	return withUndo("unmount " .. guiName, function()
		local gui = StarterGui:FindFirstChild(guiName)
		local removed = false
		if gui then
			gui.Parent = nil
			removed = true
		end
		unsolo()
		return { removed = removed }
	end)
end

---------------------------------------------------------------- capture (see Capture.luau)

local Capture = require(script.Parent.Capture)
Commands.capture_prepare = Capture.capture_prepare
Commands.capture_marker = Capture.capture_marker
Commands.capture_restore = Capture.capture_restore

return Commands
