--!strict
-- Minimal signal (Connect / Fire / Disconnect).

export type Connection = { Disconnect: (self: Connection) -> () }

local Signal = {}
Signal.__index = Signal

export type Signal = typeof(setmetatable({} :: { _handlers: { (...any) -> () } }, Signal))

function Signal.new(): Signal
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal.Connect(self: Signal, fn: (...any) -> ()): Connection
	table.insert(self._handlers, fn)
	local handlers = self._handlers
	return {
		Disconnect = function(_)
			local i = table.find(handlers, fn)
			if i then
				table.remove(handlers, i)
			end
		end,
	} :: any
end

function Signal.Fire(self: Signal, ...: any)
	for _, fn in table.clone(self._handlers) do
		task.spawn(fn, ...)
	end
end

return Signal
