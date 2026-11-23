--!strict

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StudioService = game:GetService("StudioService")

local ImportSession = require(script.ImportSession)
local ModelImport = require(script.ModelImport)
local Project = require(script.Project)
local View = require(script.View)

if not RunService:IsEdit() then return end

local pluginInstance: Plugin = plugin
local view = View.new(pluginInstance)
local toolbar = pluginInstance:CreateToolbar("Aura Fishing")
local toggle = toolbar:CreateButton("AuraParticleImporter", "Open the Aura Particle Importer", "", "Aura Importer")
toggle.ClickableWhenViewportHidden = true
toggle.Click:Connect(function() view.widget.Enabled = not view.widget.Enabled end)
view.widget:GetPropertyChangedSignal("Enabled"):Connect(function() toggle:SetActive(view.widget.Enabled) end)
toggle:SetActive(view.widget.Enabled)

local project: Project.Data? = nil
local rows: { ImportSession.Row } = {}
local usePlaceOwner = game.CreatorId > 0
local busy = false
local unloaded = false

local function owner(): ImportSession.Owner
	if usePlaceOwner and game.CreatorId > 0 then
		local kind = if game.CreatorType == Enum.CreatorType.Group then Enum.AssetCreatorType.Group else Enum.AssetCreatorType.User
		return { kind = kind, id = game.CreatorId }
	end
	return { kind = Enum.AssetCreatorType.User, id = StudioService:GetUserId() }
end

local function counts(): (number, number)
	local ready, pending = 0, 0
	local files: { [string]: boolean } = {}
	for _, row in rows do
		if row.binding then
			ready += 1
		elseif row.picked then
			local key = row.asset.matte .. ":" .. row.picked.digest
			if not files[key] then
				files[key] = true
				pending += 1
			end
		end
	end
	return ready, pending
end

local function status(message: string)
	if not unloaded then view.status.Text = message end
end

local paint: () -> ()

local function run(action: () -> ())
	if busy or unloaded then return end
	if not RunService:IsEdit() then status("Stop the playtest to import an aura."); return end
	busy = true
	paint()
	local ok, issue = pcall(function()
		action()
		return nil
	end)
	if not ok then
		status(tostring(issue))
		warn("Aura Particle Importer: " .. tostring(issue))
	end
	busy = false
	if not unloaded then paint() end
end

local function chooseRow(row: ImportSession.Row)
	run(function()
		local file = StudioService:PromptImportFileAsync({ "png" })
		if not file or not file:IsA("File") then return end
		ImportSession.choose(row, file, owner(), pluginInstance)
		status(if row.binding then "Reused the uploaded image for " .. row.asset.name else "Selected " .. file.Name)
	end)
end

paint = function()
	local ready, pending = counts()
	local enabled = not busy
	local uploadOwner = owner()
	view.count.Text = string.format("Textures    %d/%d linked", ready, #rows)
	view.owner.Text = string.format("Upload to %s (%s %s)", if usePlaceOwner then "place owner" else "Studio account", uploadOwner.kind.Name, tostring(uploadOwner.id))
	view.upload.Text = if pending == 1 then "Upload 1 PNG" elseif pending > 1 then string.format("Upload %d PNGs", pending) else "Upload PNGs"
	view.auraId.TextEditable = enabled and project ~= nil
	View.setEnabled(view.open, enabled)
	View.setEnabled(view.applyIds, enabled and #rows > 0)
	View.setEnabled(view.choose, enabled and #rows > 0)
	View.setEnabled(view.owner, enabled and game.CreatorId > 0)
	View.setEnabled(view.upload, enabled and pending > 0)
	local complete = #rows > 0
	for _, row in rows do
		if not row.binding and not row.picked then complete = false end
	end
	View.setEnabled(view.import, enabled and complete)
	local items: { View.Row } = {}
	for _, row in rows do
		local picked, binding = row.picked, row.binding
		local detail = if binding then string.format("Linked    %d x %d", binding.width, binding.height)
			elseif picked then string.format("Ready to upload    %d x %d", picked.width, picked.height)
			else "Choose a PNG or link an existing image"
		if row.asset.matte == "luma" then detail ..= "    Luma alpha" end
		table.insert(items, {
			name = row.asset.name, fileName = row.asset.path, status = detail, imageId = if binding then binding.id else nil,
			choose = function() chooseRow(row) end,
			useId = function(id)
				run(function()
					ImportSession.useId(row, id)
					status(if row.binding then "Linked image for " .. row.asset.name else "Cleared image for " .. row.asset.name)
				end)
			end,
		})
	end
	View.fill(view.rows, items, enabled)
end

-- Re-opening an aura that was imported before reuses the image IDs stored in its model.
local function linkFromModel(auraId: string): number
	local vfx = ReplicatedStorage:FindFirstChild("AuraVFX")
	local model = vfx and vfx:FindFirstChild(auraId)
	local value = model and model:FindFirstChild("ParticleProject")
	if not value or not value:IsA("StringValue") then return 0 end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, value.Value)
	if not ok or type(data) ~= "table" or type(data.assets) ~= "table" then return 0 end
	local linked = 0
	for _, row in rows do
		if row.binding then continue end
		for _, saved in data.assets do
			local id = if type(saved) == "table" and saved.id == row.asset.id and type(saved.texture) == "string"
				then saved.texture:match("^rbxassetid://([1-9]%d*)$") else nil
			if id and type(saved.width) == "number" and type(saved.height) == "number" then
				row.binding = { id = id, width = saved.width, height = saved.height }
				row.manual = true
				linked += 1
			end
		end
	end
	return linked
end

local function rowKey(path: string): string
	local name = path:lower():match("([^/\\]+)$") or path:lower()
	name = name:gsub("%.png$", "")
	name = name:gsub("_beam$", "")
	return name
end

-- Lines are either "<id>" (assigned to the next unlinked row, in list order) or "<file>.png <id>".
local function applyPastedIds(text: string): (number, number)
	local byName: { [string]: string } = {}
	local ordered: { string } = {}
	for line in text:gmatch("[^\r\n]+") do
		local id = line:match("rbxassetid://(%d+)") or line:match("(%d%d%d%d%d%d+)")
		if not id then continue end
		local file = line:lower():gsub("rbxassetid://%d+", ""):match("([%w_%-%.]+)%.png")
		if file then byName[rowKey(file)] = id else table.insert(ordered, id) end
	end
	local applied, failed = 0, 0
	local nextId = 1
	for _, row in rows do
		local id = byName[rowKey(row.asset.path)]
		if not id and not row.binding and ordered[nextId] then
			id = ordered[nextId]
			nextId += 1
		end
		if id then
			if pcall(ImportSession.useId, row, id) then applied += 1 else failed += 1 end
		end
	end
	return applied, failed
end

local function uploadAll()
	ImportSession.upload(rows, owner(), pluginInstance, status)
	local ready = counts()
	status(if ready == #rows then "Textures linked. Import the aura when ready." else "Choose or link the remaining textures.")
end

local function importAura()
	local current = project
	if not current then return end
	local auraId = view.auraId.Text:match("^%s*(.-)%s*$") or ""
	local frames, unavailable = ImportSession.measureFrames(current, rows, status)
	local model = ModelImport.apply(auraId, current, ImportSession.bindings(rows), frames)
	if unavailable > 0 then
		status(string.format("Imported %s. %d layers use full cells. Choose their PNGs and reimport to normalize.", model.Name, unavailable))
	else
		status("Imported " .. model.Name .. ". Equip it in Play to preview.")
	end
end

-- One dialog: select project.json plus the PNGs next to it (Ctrl+A in the folder). Textures are matched by
-- file name, uploaded and imported in one go; rows stay editable if anything could not be matched.
view.open.Activated:Connect(function()
	run(function()
		local selected = StudioService:PromptImportFilesAsync({ "json", "png" })
		local jsons: { File } = {}
		local pngs: { File } = {}
		for _, file in selected or {} do
			if not file:IsA("File") then continue end
			table.insert(if file.Name:lower():match("%.json$") then jsons else pngs, file)
		end
		if #jsons == 0 then
			if #pngs > 0 then status("Also select the project.json.") end
			return
		end
		if #jsons > 1 then error("Select one project.json at a time.", 0) end
		local file = jsons[1]
		if file.Size > 4 * 1024 * 1024 then error("Choose a project.json under 4 MB.", 0) end
		local opened = Project.decode(file:GetBinaryContents())
		project = opened
		rows = ImportSession.rows(opened)
		view.projectName.Text = opened.name
		view.auraId.Text = (opened.name:gsub("[^%w_]", ""))
		view.rows.CanvasPosition = Vector2.zero
		if #rows == 0 then status("Add a visible layer with a texture in Particle Editor."); return end
		ImportSession.chooseBatch(rows, pngs, owner(), pluginInstance)
		local fromModel = linkFromModel(view.auraId.Text)
		for _, row in rows do
			if not row.binding and not row.picked then
				status("Some textures were not found. Use Choose PNG on the rows below, then Import aura.")
				return
			end
		end
		if fromModel > 0 then status(string.format("Reused %d image IDs from the existing %s model.", fromModel, view.auraId.Text)) end
		uploadAll()
		if counts() == #rows then importAura() end
	end)
end)

view.applyIds.Activated:Connect(function()
	run(function()
		local applied, failed = applyPastedIds(view.bulk.Text)
		status(string.format("Linked %d images%s. Press Import aura.", applied, if failed > 0 then string.format(", %d IDs could not be read", failed) else ""))
	end)
end)

view.choose.Activated:Connect(function()
	run(function()
		local selected = StudioService:PromptImportFilesAsync({ "png" })
		local files: { File } = {}
		for _, file in selected or {} do
			if file:IsA("File") then table.insert(files, file) end
		end
		if #files == 0 then return end
		local matched, ambiguous = ImportSession.chooseBatch(rows, files, owner(), pluginInstance)
		if ambiguous > 0 then
			status(string.format("Matched %d textures. Use Choose PNG on rows with shared filenames.", matched))
		elseif matched == 0 then
			status("Use Choose PNG on a texture row to select a file with a different name.")
		else
			status(string.format("Matched %d textures. Upload the PNGs when ready.", matched))
		end
	end)
end)

view.owner.Activated:Connect(function()
	run(function()
		usePlaceOwner = not usePlaceOwner
		ImportSession.changeOwner(rows, owner(), pluginInstance)
		status("Updated the owner for new uploads.")
	end)
end)

view.upload.Activated:Connect(function() run(uploadAll) end)
view.import.Activated:Connect(function()
	run(function()
		uploadAll()
		if counts() == #rows then importAura() end
	end)
end)

pluginInstance.Unloading:Connect(function() unloaded = true end)
paint()
