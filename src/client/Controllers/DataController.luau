--!strict
-- Holds the latest profile snapshot from the server and derived stats.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Stats = require(Shared.Stats)
local Signal = require(Shared.Util.Signal)

local DataController = {}
DataController.Profile = nil :: any
DataController.Stats = nil :: Stats.ComputedStats?
DataController.Changed = Signal.new() -- (profile, stats)

function DataController.Init()
	Remotes.Event("DataSync").OnClientEvent:Connect(function(profile)
		DataController.Profile = profile
		DataController.Stats = Stats.Compute(profile)
		DataController.Changed:Fire(profile, DataController.Stats)
	end)
end

-- Calls fn now (if loaded) and on every change.
function DataController.Observe(fn: (any, Stats.ComputedStats) -> ())
	if DataController.Profile then
		task.spawn(fn, DataController.Profile, DataController.Stats :: Stats.ComputedStats)
	end
	return DataController.Changed:Connect(fn)
end

return DataController
