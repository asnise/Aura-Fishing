--!strict

local Project = require(script.Parent.Project)
local Textures = require(script.Parent.Textures)
local Playback = require(script.Parent.Playback)

export type Owner = { id: number, kind: Enum.AssetCreatorType }
type Picked = { file: File, digest: string, width: number, height: number }
export type Row = {
	asset: Project.Asset,
	picked: Picked?,
	binding: Project.Binding?,
	manual: boolean,
}

type Cache = { [string]: string }

local CACHE_SETTING = "AuraParticleImageIdsV1"
local ImportSession = {}

local function fileName(path: string): string
	return string.lower(path:match("([^/\\]+)$") or path)
end

local function cacheKey(owner: Owner, row: Row, picked: Picked): string
	return owner.kind.Name .. ":" .. owner.id .. ":" .. row.asset.matte .. ":" .. picked.digest
end

local function readCache(pluginInstance: Plugin): Cache
	local cached = pluginInstance:GetSetting(CACHE_SETTING)
	return if type(cached) == "table" then cached else {}
end

local function cachedBinding(cache: Cache, owner: Owner, row: Row, picked: Picked): Project.Binding?
	local id = cache[cacheKey(owner, row, picked)]
	if type(id) == "string" and id:match("^[1-9]%d*$") then
		return { id = id, width = picked.width, height = picked.height }
	end
	return nil
end

local function readFile(file: File): Picked
	local info = Textures.inspect(file)
	return { file = file, digest = info.digest, width = info.width, height = info.height }
end

local function assign(row: Row, picked: Picked, owner: Owner, cache: Cache)
	row.picked = picked
	row.binding = cachedBinding(cache, owner, row, picked)
	row.manual = false
end

function ImportSession.rows(project: Project.Data): { Row }
	local rows = {}
	for _, asset in Project.requiredAssets(project) do
		table.insert(rows, { asset = asset, manual = false })
	end
	return rows
end

function ImportSession.choose(row: Row, file: File, owner: Owner, pluginInstance: Plugin)
	assign(row, readFile(file), owner, readCache(pluginInstance))
end

function ImportSession.chooseBatch(rows: { Row }, files: { File }, owner: Owner, pluginInstance: Plugin): (number, number)
	local byName: { [string]: { Row } } = {}
	for _, row in rows do
		if row.manual then continue end
		local name = fileName(row.asset.path)
		if not byName[name] then byName[name] = {} end
		table.insert(byName[name], row)
	end
	local selected: { [string]: File } = {}
	local duplicates: { [string]: boolean } = {}
	for _, file in files do
		local name = fileName(file.Name)
		if selected[name] then duplicates[name] = true end
		selected[name] = file
	end
	local cache = readCache(pluginInstance)
	local matched = 0
	local ambiguous = 0
	for name, file in selected do
		local group = byName[name]
		if not group then continue end
		local path = group[1].asset.path:gsub("\\", "/"):gsub("^%./", ""):lower()
		local matchingPaths = not duplicates[name]
		for _, row in group do
			if row.asset.path:gsub("\\", "/"):gsub("^%./", ""):lower() ~= path then matchingPaths = false end
		end
		if not matchingPaths then
			ambiguous += 1
			continue
		end
		local picked = readFile(file)
		for _, row in group do
			assign(row, picked, owner, cache)
			matched += 1
		end
	end
	return matched, ambiguous
end

function ImportSession.changeOwner(rows: { Row }, owner: Owner, pluginInstance: Plugin)
	local cache = readCache(pluginInstance)
	for _, row in rows do
		if row.picked and not row.manual then
			row.binding = cachedBinding(cache, owner, row, row.picked)
		end
	end
end

function ImportSession.useId(row: Row, text: string)
	local id = text:match("^%s*(.-)%s*$") or ""
	if id == "" then
		row.binding = nil
		row.manual = false
		return
	end
	id = id:gsub("^rbxassetid://", "")
	if not id:match("^[1-9]%d*$") then error("Enter a Roblox image Asset ID.", 0) end
	local ok, width, height = pcall(Textures.readSize, id)
	if not ok then
		local picked = row.picked
		if not picked then error("Studio could not read this image. Choose its matching PNG to provide the sheet size.", 0) end
		width, height = picked.width, picked.height
	end
	row.binding = { id = id, width = width, height = height }
	row.manual = true
end

function ImportSession.upload(rows: { Row }, owner: Owner, pluginInstance: Plugin, progress: (string) -> ())
	if owner.id <= 0 then error("Sign in to Roblox Studio before uploading.", 0) end
	local cache = readCache(pluginInstance)
	for _, row in rows do
		local picked = row.picked
		if row.binding or not picked then continue end
		local cached = cachedBinding(cache, owner, row, picked)
		if cached then
			row.binding = cached
			continue
		end
		progress("Uploading " .. row.asset.name)
		local name = row.asset.name:gsub("%c", " ")
		local ok, id = pcall(Textures.upload, picked.file, row.asset.matte, owner, name)
		if not ok then error(row.asset.name .. " upload failed. " .. tostring(id), 0) end
		row.binding = { id = id, width = picked.width, height = picked.height }
		local key = cacheKey(owner, row, picked)
		cache[key] = id
		local saved, issue = pcall(function()
			local latest = readCache(pluginInstance)
			latest[key] = id
			pluginInstance:SetSetting(CACHE_SETTING, latest)
		end)
		if not saved then warn("Aura Particle Importer could not save image ID " .. id .. ". " .. tostring(issue)) end
	end
end

function ImportSession.bindings(rows: { Row }): { [string]: Project.Binding }
	local bindings: { [string]: Project.Binding } = {}
	for _, row in rows do
		if row.binding then bindings[row.asset.id] = row.binding end
	end
	return bindings
end

local function visibleBounds(pixels: buffer, width: number, rect: Playback.Rect): Playback.Rect?
	local left, top = rect.x + rect.width, rect.y + rect.height
	local right, bottom = rect.x - 1, rect.y - 1
	for y = rect.y, rect.y + rect.height - 1 do
		for x = rect.x, rect.x + rect.width - 1 do
			if buffer.readu8(pixels, (y * width + x) * 4 + 3) >= 14 then
				left, top = math.min(left, x), math.min(top, y)
				right, bottom = math.max(right, x), math.max(bottom, y)
			end
		end
	end
	return if right >= left then { x = left, y = top, width = right - left + 1, height = bottom - top + 1 } else nil
end

local function measureSheet(pixels: buffer, width: number, height: number, sheet: Playback.Sheet): Project.FrameMetadata?
	local grid = Playback.frameGrid(sheet, width, height)
	if not grid then return nil end
	local bounds = {}
	local maxHeight = 0
	for frame = sheet.first, sheet.last do
		local rect = Playback.frameRect(grid, frame)
		if not rect then return nil end
		local visible = visibleBounds(pixels, width, rect)
		if visible then maxHeight = math.max(maxHeight, visible.height) end
		table.insert(bounds, visible or rect)
	end
	return { bounds = bounds, maxHeight = maxHeight }
end

function ImportSession.measureFrames(project: Project.Data, rows: { Row }, progress: (string) -> ()): ({ [string]: Project.FrameMetadata }, number)
	local grouped: { [string]: { { [string]: any } } } = {}
	for _, layer in project.layers do
		if layer.visible and layer.assetId and layer.sheet.normalize then
			if not grouped[layer.assetId] then grouped[layer.assetId] = {} end
			table.insert(grouped[layer.assetId], layer)
		end
	end
	local frames: { [string]: Project.FrameMetadata } = {}
	local unavailable = 0
	for _, row in rows do
		local layers, binding = grouped[row.asset.id], row.binding
		if not layers or not binding then continue end
		progress("Measuring frames for " .. row.asset.name)
		local picked = row.picked
		local source: File | string = if picked and not row.manual then picked.file else binding.id
		local ok, pixels, width, height = pcall(Textures.readPixels, source, row.asset.matte)
		if not ok and picked and row.manual then
			ok, pixels, width, height = pcall(Textures.readPixels, picked.file, row.asset.matte)
		end
		if not ok or width ~= binding.width or height ~= binding.height then
			unavailable += #layers
			continue
		end
		for _, layer in layers do
			local measured = measureSheet(pixels, width, height, layer.sheet)
			if measured then frames[layer.id] = measured else unavailable += 1 end
		end
	end
	return frames, unavailable
end

return ImportSession
