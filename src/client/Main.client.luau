--!strict
-- Client bootstrap. Controllers are ModuleScripts with Init(); add new ones to ORDER.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Controllers = script.Parent:WaitForChild("Controllers")

local ORDER: { ModuleScript } = {
	Controllers.DataController,
	Controllers.SoundController,
	Controllers.HUDController,
	Controllers.FishingController,
	Controllers.MenuController,
	Controllers.InventoryController,
	Controllers.CharacterController,
	Controllers.DashController,
	Controllers.SkillsController,
	Controllers.GachaPageController,
	Controllers.FusionController,
	Controllers.DialogueController,
	Controllers.EventController,
	Controllers.DailyLoginController,
	Controllers.TradeController,
	Controllers.MainMenuController,
	Controllers.EconomyController,
	Controllers.QuestController,
	Controllers.AuraFXController,
	Controllers.TitleController,
	Controllers.HotFishController,
	Controllers.TideEventController,
	Controllers.DevController,
	Controllers.BoundaryController,
}

for _, module in ORDER do
	local controller = require(module) :: any
	if controller.Init then
		controller.Init()
	end
end

require(script.Parent:WaitForChild("UI"):WaitForChild("MenuManager")).BindBackKey()

-- the loading screen (src/first/Loading.client.luau) waits for these two flags
local localPlayer = game:GetService("Players").LocalPlayer
local dataReady = false
require(Controllers.DataController).Observe(function()
	if not dataReady then
		dataReady = true
		localPlayer:SetAttribute("DataReady", true)
	end
end)
localPlayer:SetAttribute("ClientReady", true)

Remotes.Event("ClientReady"):FireServer()
