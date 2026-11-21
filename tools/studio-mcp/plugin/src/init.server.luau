--!strict
-- Studio Bridge plugin (Aura Fishing): long-polls the local MCP bridge (http://127.0.0.1:3060)
-- and runs the commands it receives in edit mode. Toolbar button toggles the status widget.

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Commands = require(script.Commands)
local Widget = require(script.Widget)
local Running = require(script.Running)

local VERSION = "0.2.0"
local SETTING_ENABLED = "StudioBridge_Enabled"
local SETTING_PORT = "StudioBridge_Port"
local POLL_WAIT_MS = 15000

-- Only the edit DataModel talks to the bridge (Play spawns extra plugin instances).
if not RunService:IsEdit() then
	return
end

local plugin: Plugin = plugin
local clientId = HttpService:GenerateGUID(false)
local port = tonumber(plugin:GetSetting(SETTING_PORT)) or 3060
local enabled = plugin:GetSetting(SETTING_ENABLED)
if enabled == nil then
	enabled = true
end
local session = 0 -- bumps on every (re)connect so old loops exit
local classesCache: any = nil
local stats = { commands = 0, errors = 0 }

local toolbar = plugin:CreateToolbar("Studio Bridge")
local button = toolbar:CreateButton("Bridge", "Show Studio Bridge status (Aura Fishing MCP)", "")
button.ClickableWhenViewportHidden = true

local ui = Widget.new(plugin)
button.Click:Connect(function()
	ui.widget.Enabled = not ui.widget.Enabled
end)
ui.widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	button:SetActive(ui.widget.Enabled)
end)

local function base(): string
	return "http://127.0.0.1:" .. port
end

local HEADERS = { ["X-Studio-Bridge"] = "1", ["Content-Type"] = "application/json" }

local function request(method: string, path: string, body: any?): (boolean, any)
	local ok, res = pcall(function()
		return HttpService:RequestAsync({
			Url = base() .. path,
			Method = method,
			Headers = HEADERS,
			Body = if body ~= nil then HttpService:JSONEncode(body) else nil,
		})
	end)
	if not ok then
		return false, tostring(res)
	end
	if not res.Success then
		return false, string.format("HTTP %d %s", res.StatusCode, res.Body)
	end
	local okJson, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
	if not okJson then
		return false, "bad JSON from bridge"
	end
	return true, data
end

local function loadClasses()
	if classesCache then
		return classesCache
	end
	local ok, data = request("GET", "/classes")
	if ok and typeof(data) == "table" and next(data) then
		classesCache = data
	end
	return classesCache
end

local ctx = { classes = loadClasses, version = VERSION }

-- Commands run one at a time in order (keeps undo history clean).
local queue: { any } = {}
local working = false

local function postResult(id: string, ok: boolean, result: any)
	local payload: any = { id = id, ok = ok }
	if ok then
		payload.result = result
	else
		payload.error = tostring(result)
	end
	local encOk, encErr = pcall(HttpService.JSONEncode, HttpService, payload)
	if not encOk then
		payload = { id = id, ok = false, error = "result not JSON-encodable: " .. tostring(encErr) }
	end
	for attempt = 1, 3 do
		local sent = request("POST", "/result", payload)
		if sent then
			return
		end
		task.wait(0.5 * attempt)
	end
end

local DEFAULT_TIMEOUT_MS = 30000
local current: thread? = nil -- thread of the command being run (so stop/watchdog can cancel it)

local function errorHandler(e: any): any
	if typeof(e) == "string" and not string.find(e, "^%[") then
		return e
	end
	return debug.traceback(tostring(e), 2)
end

-- Run one command in its own thread. Returns (ok, result). If it is still running shortly before the
-- caller's timeout (e.g. yielding forever in WaitForChild), the thread is cancelled, its undo recording
-- is rolled back and an error is returned, so later commands are not blocked.
local function runOne(cmd: any): (boolean, any)
	local handler = Commands[cmd.command]
	if not handler then
		return false, "unknown command: " .. tostring(cmd.command)
	end
	local timeoutMs = tonumber(cmd.timeoutMs) or DEFAULT_TIMEOUT_MS
	-- Give up well before the caller does, so our error (not a bare timeout) reaches it even if Studio is slow.
	local margin = math.max(1500, timeoutMs * 0.1)
	local deadline = os.clock() + math.max(timeoutMs - margin, 500) / 1000
	local done, ok, result = false, false, nil
	local thread = task.spawn(function()
		ok, result = xpcall(handler, errorHandler, cmd.params or {}, ctx)
		done = true
	end)
	current = thread
	while not done and current == thread and os.clock() < deadline do
		task.wait(0.05)
	end
	if done then
		current = nil
		return ok, result
	end
	if current ~= thread then
		return false, tostring(cmd.command) .. " was cancelled (bridge turned off)"
	end
	current = nil
	pcall(task.cancel, thread)
	Running.abort()
	return false,
		string.format(
			"%s was still running after %.1fs and was cancelled (changes rolled back). Usually an endless yield such as WaitForChild on a missing instance in edit mode.",
			tostring(cmd.command),
			timeoutMs / 1000
		)
end

local function runQueue()
	if working then
		return
	end
	working = true
	while #queue > 0 do
		local cmd = table.remove(queue, 1)
		local ok, result = runOne(cmd)
		stats.commands += 1
		if not ok then
			stats.errors += 1
		end
		ui:log(string.format("%s %s", ok and "OK " or "ERR", cmd.command))
		task.spawn(postResult, cmd.id, ok, result)
	end
	working = false
end

local function pollLoop(mySession: number)
	local failures = 0
	while enabled and session == mySession do
		local query = string.format(
			"/poll?client=%s&place=%s&version=%s&wait=%d",
			clientId,
			HttpService:UrlEncode(game.Name),
			VERSION,
			POLL_WAIT_MS
		)
		local ok, data = request("GET", query)
		if session ~= mySession then
			break
		end
		if ok then
			if failures > 0 or ui.state ~= "connected" then
				ui:setState("connected", "127.0.0.1:" .. port)
				task.spawn(loadClasses)
			end
			failures = 0
			for _, cmd in (data and data.commands) or {} do
				table.insert(queue, cmd)
			end
			if #queue > 0 then
				task.spawn(runQueue)
			end
		else
			failures += 1
			local msg = tostring(data)
			if string.find(msg, "Http requests") or string.find(msg, "not enabled") or string.find(msg, "permission") then
				ui:setState("blocked", "HTTP to localhost not allowed — see README (Plugin permissions)")
			else
				ui:setState("waiting", "Waiting for MCP server on 127.0.0.1:" .. port)
			end
			task.wait(math.min(1 + failures, 5))
		end
	end
end

local function start()
	session += 1
	local mySession = session
	ui:setState("waiting", "Connecting to 127.0.0.1:" .. port)
	task.spawn(pollLoop, mySession)
end

local function abortCurrent()
	if current then
		pcall(task.cancel, current)
		current = nil
		Running.abort()
	end
	table.clear(queue)
	working = false
end

local function stop()
	session += 1
	abortCurrent()
	ui:setState("off", "Bridge off")
end

ui.onToggle = function()
	enabled = not enabled
	plugin:SetSetting(SETTING_ENABLED, enabled)
	if enabled then
		start()
	else
		stop()
	end
end

ui.onPortChanged = function(newPort: number)
	port = newPort
	plugin:SetSetting(SETTING_PORT, port)
	classesCache = nil
	if enabled then
		start()
	end
end

ui:setPort(port)
ui.getStats = function()
	return stats
end

plugin.Unloading:Connect(function()
	session += 1
	abortCurrent()
	require(script.Capture).restoreAll()
end)

if enabled then
	start()
else
	stop()
end
