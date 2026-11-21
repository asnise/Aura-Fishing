--!strict
-- Client bootstrap. Controllers are ModuleScripts with Init(); add new ones to ORDER.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Controllers = script.Parent:WaitForChild("Controllers")

local ORDER: { ModuleScript } = {
	Controllers.DataController,
	Controllers.HUDController,
	Controllers.FishingController,
	Controllers.MenuController,
	Controllers.InventoryController,
	Controllers.CharacterController,
	Controllers.SkillsController,
	Controllers.GachaPageController,
	Controllers.DialogueController,
	Controllers.EventController,
	Controllers.DailyLoginController,
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

Remotes.Event("ClientReady"):FireServer()
