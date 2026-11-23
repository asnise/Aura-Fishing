--!strict

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")

local Project = require(script.Parent.Project)

local VFX_FOLDER = "AuraVFX"
local MARKER_NAME = "ParticleProject"
local MARKER_ATTRIBUTE = "AuraParticleProject"

local ModelImport = {}

local function validAuraId(auraId: string): boolean
	return #auraId <= 64 and auraId:match("^[%a_][%w_]*$") ~= nil
end

function ModelImport.build(auraId: string, project: Project.Data, bindings: { [string]: Project.Binding }, frames: { [string]: Project.FrameMetadata }?): Model
	if not validAuraId(auraId) then
		error("Enter an Aura ID such as TidalBloom, using letters, digits or underscores.", 0)
	end
	local payload = Project.encodeForGame(project, bindings, frames)
	local model = Instance.new("Model")
	model.Name = auraId
	model:SetAttribute(MARKER_ATTRIBUTE, true)
	local marker = Instance.new("StringValue")
	marker.Name = MARKER_NAME
	marker:SetAttribute(MARKER_ATTRIBUTE, true)
	marker.Value = payload
	marker.Parent = model
	return model
end

function ModelImport.apply(auraId: string, project: Project.Data, bindings: { [string]: Project.Binding }, frames: { [string]: Project.FrameMetadata }?): Model
	if not RunService:IsEdit() then error("Stop the playtest before importing an aura.", 0) end
	local folder = ReplicatedStorage:FindFirstChild(VFX_FOLDER)
	if folder and not folder:IsA("Folder") then error("ReplicatedStorage.AuraVFX must be a Folder.", 0) end
	local existing = if folder then folder:FindFirstChild(auraId) else nil
	local existingMarker: StringValue? = nil
	if existing then
		local marker = existing:FindFirstChild(MARKER_NAME)
		if not existing:IsA("Model") or existing:GetAttribute(MARKER_ATTRIBUTE) ~= true
			or not marker or not marker:IsA("StringValue") or marker:GetAttribute(MARKER_ATTRIBUTE) ~= true then
			error("This Aura ID already has a Studio model. Rename that model to keep it before importing.", 0)
		end
		existingMarker = marker
	end

	local draft = ModelImport.build(auraId, project, bindings, frames)
	local recording = ChangeHistoryService:TryBeginRecording("AuraParticleImporter", "Import aura " .. auraId)
	if not recording then
		draft:Destroy()
		error("Studio is recording another edit. Try importing again.", 0)
	end

	local createdFolder: Folder? = nil
	local result = draft
	local ok, issue = pcall(function()
		if existingMarker then
			existingMarker.Value = (draft:FindFirstChild(MARKER_NAME) :: StringValue).Value
			result = existing :: Model
		else
			if not folder then
				local newFolder = Instance.new("Folder")
				newFolder.Name = VFX_FOLDER
				createdFolder = newFolder
				newFolder.Parent = ReplicatedStorage
				folder = newFolder
			end
			draft.Parent = folder
		end
	end)
	if not ok then
		draft:Destroy()
		if createdFolder then createdFolder:Destroy() end
		ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Cancel)
		error(issue, 0)
	end
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
	if existingMarker then draft:Destroy() end
	Selection:Set({ result })
	return result
end

return ModelImport
