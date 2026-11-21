--!strict
-- Resources held by the command that is currently running, so the watchdog in init can
-- clean them up if it has to cancel a command that never finished (e.g. infinite WaitForChild).

local ChangeHistoryService = game:GetService("ChangeHistoryService")

local Running = {
	recording = nil :: string?,
	connections = {} :: { RBXScriptConnection },
	temps = {} :: { Instance },
}

function Running.track(conn: RBXScriptConnection): RBXScriptConnection
	table.insert(Running.connections, conn)
	return conn
end

function Running.untrack(conn: RBXScriptConnection)
	conn:Disconnect()
	local i = table.find(Running.connections, conn)
	if i then
		table.remove(Running.connections, i)
	end
end

function Running.trackTemp(inst: Instance): Instance
	table.insert(Running.temps, inst)
	return inst
end

function Running.untrackTemp(inst: Instance)
	inst:Destroy()
	local i = table.find(Running.temps, inst)
	if i then
		table.remove(Running.temps, i)
	end
end

-- Called after a command thread was cancelled: roll back its undo recording, drop listeners/temps.
function Running.abort()
	if Running.recording then
		pcall(function()
			ChangeHistoryService:FinishRecording(Running.recording :: string, Enum.FinishRecordingOperation.Cancel)
		end)
		Running.recording = nil
	end
	for _, c in Running.connections do
		c:Disconnect()
	end
	table.clear(Running.connections)
	for _, t in Running.temps do
		pcall(t.Destroy, t)
	end
	table.clear(Running.temps)
end

return Running
