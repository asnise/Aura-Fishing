--!strict
-- Server bootstrap. Services are plain ModuleScripts with Init(); add new ones to ORDER.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
require(Shared.Registry) -- validate content first: bad config stops here with a clear error
require(Shared.Remotes) -- create remotes before any client asks for them

local Services = script.Parent:WaitForChild("Services")
local World = script.Parent:WaitForChild("World")

local ORDER: { ModuleScript } = {
	World.WorldBuilder,
	Services.DataService,
	Services.ProgressionService,
	Services.FishingService,
	Services.ShopService,
	Services.AuraService,
	Services.MonetizationService,
	Services.AquariumService,
	Services.QuestService,
	Services.RebirthService,
	Services.TideEventService,
	Services.HotspotService,
	Services.DailyLoginService,
	Services.DevService,
	Services.BoundaryService,
}

for _, module in ORDER do
	local service = require(module) :: any
	if service.Init then
		service.Init()
	end
end

print("[AuraFishing] server ready")
