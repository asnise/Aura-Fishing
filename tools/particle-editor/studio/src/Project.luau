--!strict

local HttpService = game:GetService("HttpService")

type Object = { [string]: any }
type Range = { default: number, min: number, max: number, integer: boolean? }
export type Asset = { id: string, name: string, path: string, matte: string }
export type Binding = { id: string, width: number, height: number }
export type Data = { version: number, name: string, duration: number, loop: boolean, assets: { Asset }, layers: { Object } }
export type FrameMetadata = { bounds: { { x: number, y: number, width: number, height: number } }, maxHeight: number }

local Project = {}

local function fail(field: string, message: string): never
	error(field .. " " .. message, 0)
end

local function object(value: any, field: string): Object
	if type(value) ~= "table" then fail(field, "must be an object.") end
	for key in value do
		if type(key) ~= "string" then fail(field, "must be an object.") end
	end
	return value
end

local function array(value: any, field: string): { any }
	if value == nil then return {} end
	if type(value) ~= "table" then fail(field, "must be an array.") end
	local count = #value
	for key in value do
		if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > count then fail(field, "must be an array.") end
	end
	return value
end

local function label(value: any, field: string, fallback: string?): string
	if value == nil then value = fallback end
	if type(value) ~= "string" or not string.find(value, "%S") then fail(field, "must be text.") end
	return value
end

local function choice(value: any, field: string, options: { string }): string
	if value == nil then return options[1] end
	if type(value) ~= "string" or not table.find(options, value) then
		fail(field, "must be one of " .. table.concat(options, ", ") .. ".")
	end
	return value
end

local function boolean(value: any, field: string, fallback: boolean): boolean
	if value == nil then return fallback end
	if type(value) ~= "boolean" then fail(field, "must be true or false.") end
	return value
end

local function numeric(value: any, field: string, fallback: number, min: number, max: number, integer: boolean?): number
	if value == nil then value = fallback end
	if type(value) ~= "number" or value ~= value or value < min or value > max or (integer and value % 1 ~= 0) then
		fail(field, string.format("must be %s from %s to %s.", if integer then "an integer" else "a number", tostring(min), tostring(max)))
	end
	return value
end

local function ranges(data: Object, field: string, specs: { [string]: Range }): Object
	local result: Object = {}
	for key, spec in specs do
		result[key] = numeric(data[key], field .. "." .. key, spec.default, spec.min, spec.max, spec.integer)
	end
	return result
end

local function tuple(value: any, field: string, fallback: { number }, min: number, max: number): { number }
	if value == nil then return fallback end
	local items = array(value, field)
	if #items ~= #fallback then fail(field, "has the wrong number of coordinates.") end
	local result = {}
	for index, item in items do
		result[index] = numeric(item, field .. "[" .. index .. "]", fallback[index], min, max)
	end
	return result
end

local function readSheet(value: any, field: string): Object
	local data = object(if value == nil then {} else value, field)
	local columns = numeric(data.columns, field .. ".columns", 1, 1, 64, true)
	local rows = numeric(data.rows, field .. ".rows", 1, 1, 64, true)
	local last = columns * rows - 1
	local first = numeric(data.first, field .. ".first", 0, 0, last, true)
	local crop: Object? = nil
	if data.crop ~= nil then
		crop = ranges(object(data.crop, field .. ".crop"), field .. ".crop", {
			x = { default = 0, min = 0, max = 65536, integer = true },
			y = { default = 0, min = 0, max = 65536, integer = true },
			width = { default = 0, min = 1, max = 65536, integer = true },
			height = { default = 0, min = 1, max = 65536, integer = true },
		})
	end
	return {
		columns = columns, rows = rows, crop = crop,
		margin = numeric(data.margin, field .. ".margin", 0, 0, 4096, true),
		gap = numeric(data.gap, field .. ".gap", 0, 0, 4096, true),
		first = first,
		last = numeric(data.last, field .. ".last", last, first, last, true),
		fps = numeric(data.fps, field .. ".fps", 14, 0.1, 240),
		mode = choice(data.mode, field .. ".mode", { "loop", "once", "pingpong", "fixed" }),
		reverse = boolean(data.reverse, field .. ".reverse", false),
		normalize = boolean(data.normalize, field .. ".normalize", false),
	}
end

local TIMING = {
	start = { default = 0, min = 0, max = 600 },
	duration = { default = 6, min = 0.01, max = 600 },
	speed = { default = 1, min = 0.01, max = 100 },
	offset = { default = 0, min = -600, max = 600 },
	fadeIn = { default = 0.15, min = 0, max = 600 },
	fadeOut = { default = 0.2, min = 0, max = 600 },
}

local SETTINGS: { [string]: { [string]: Range } } = {
	sprite = {
		scaleStart = { default = 1, min = 0, max = 30 },
		scaleEnd = { default = 1, min = 0, max = 30 },
		depthBias = { default = 0, min = -1000, max = 1000 },
	},
	emitter = {
		rate = { default = 12, min = 0, max = 600 },
		lifetime = { default = 1.5, min = 0.01, max = 60 },
		speed = { default = 1.2, min = 0, max = 250 },
		spread = { default = 50, min = 0, max = 360 },
		radius = { default = 0.35, min = 0, max = 250 },
		gravity = { default = -0.25, min = -250, max = 250 },
		drag = { default = 0.18, min = 0, max = 30 },
		spin = { default = 22, min = -3600, max = 3600 },
		sizeEnd = { default = 0.54, min = 0, max = 30 },
		seed = { default = 42, min = -2147483648, max = 2147483647, integer = true },
		burst = { default = 0, min = 0, max = 600, integer = true },
	},
	ribbon = {
		radius = { default = 1.65, min = 0.001, max = 250 },
		tilt = { default = 15, min = -360, max = 360 },
		arc = { default = 360, min = 1, max = 360 },
		speed = { default = 34, min = -3600, max = 3600 },
		phase = { default = 0, min = -36000, max = 36000 },
		scroll = { default = 0, min = -100, max = 100 },
	},
}

local SIZE = { sprite = { 2.8, 2.8 }, emitter = { 0.34, 0.34 }, ribbon = { 1, 1.7 } }
local NAMES = { sprite = "Sprite", emitter = "Emitter", ribbon = "Ribbon" }

local function readLayer(data: Object, field: string, assets: { [string]: boolean }): Object
	local kind = choice(data.kind, field .. ".kind", { "sprite", "emitter", "ribbon" })
	local assetId = if data.assetId ~= nil then label(data.assetId, field .. ".assetId") else nil
	if assetId and not assets[assetId] then fail(field .. ".assetId", "does not match a texture in the project.") end
	local color = label(data.color, field .. ".color", "#ffffff")
	if not string.match(color, "^#%x%x%x%x%x%x$") then fail(field .. ".color", "must be a six-digit hex color.") end
	local at = field .. "." .. kind
	local settings = object(if data[kind] == nil then {} else data[kind], at)
	local kindSettings = ranges(settings, at, SETTINGS[kind])
	if kind == "sprite" then
		kindSettings.plane = choice(settings.plane, at .. ".plane", { "billboard", "ground" })
	elseif kind == "emitter" then
		kindSettings.direction = tuple(settings.direction, at .. ".direction", { 0, 1, 0 }, -250, 250)
		kindSettings.randomFrame = boolean(settings.randomFrame, at .. ".randomFrame", true)
		kindSettings.radial = boolean(settings.radial, at .. ".radial", false)
	else
		kindSettings.taper = boolean(settings.taper, at .. ".taper", false)
	end
	return {
		id = label(data.id, field .. ".id"),
		name = label(data.name, field .. ".name", NAMES[kind]),
		kind = kind, assetId = assetId,
		visible = boolean(data.visible, field .. ".visible", true),
		tier = numeric(data.tier, field .. ".tier", 1, 1, 3, true),
		position = tuple(data.position, field .. ".position", if kind == "ribbon" then { 0, 2.48, 0 } else { 0, 0.15, 0 }, -1000, 1000),
		size = tuple(data.size, field .. ".size", SIZE[kind], 0.001, 1000),
		anchor = tuple(data.anchor, field .. ".anchor", { 0.5, 0.5 }, -4, 4),
		rotation = numeric(data.rotation, field .. ".rotation", 0, -36000, 36000),
		color = string.lower(color),
		opacity = numeric(data.opacity, field .. ".opacity", 0.85, 0, 1),
		blend = choice(data.blend, field .. ".blend", { "screen", "add", "normal" }),
		sheet = readSheet(data.sheet, field .. ".sheet"),
		timing = ranges(object(if data.timing == nil then {} else data.timing, field .. ".timing"), field .. ".timing", TIMING),
		[kind] = kindSettings,
	}
end

function Project.decode(contents: string): Data
	if #contents > 4 * 1024 * 1024 then fail("Project", "must be smaller than 4 MB.") end
	local valid, decoded = pcall(HttpService.JSONDecode, HttpService, (contents:gsub("^\239\187\191", "")))
	if not valid then fail("Project", "must be valid JSON.") end
	local data = object(decoded, "Project")
	if data.version ~= 1 then fail("Project.version", "must equal 1.") end
	local assets: { Asset } = {}
	local assetIds: { [string]: boolean } = {}
	for index, item in array(data.assets, "assets") do
		local field = "assets[" .. index .. "]"
		local entry = object(item, field)
		local id = label(entry.id, field .. ".id")
		if assetIds[id] then fail(field .. ".id", "is already used.") end
		assetIds[id] = true
		local path = label(entry.path, field .. ".path")
		if path:find("[%c]") or path:find("^%w+://") then fail(field .. ".path", "must be a local file name.") end
		table.insert(assets, {
			id = id, name = label(entry.name, field .. ".name", id), path = path,
			matte = choice(entry.matte, field .. ".matte", { "luma", "rgba" }),
		})
	end
	local layers: { Object } = {}
	local layerIds: { [string]: boolean } = {}
	for index, item in array(data.layers, "layers") do
		local field = "layers[" .. index .. "]"
		local layer = readLayer(object(item, field), field, assetIds)
		if layerIds[layer.id] then fail(field .. ".id", "is already used.") end
		layerIds[layer.id] = true
		table.insert(layers, layer)
	end
	return {
		version = 1,
		name = label(data.name, "Project.name", "Untitled effect"),
		duration = numeric(data.duration, "Project.duration", 6, 0.1, 600),
		loop = boolean(data.loop, "Project.loop", true),
		assets = assets, layers = layers,
	}
end

function Project.requiredAssets(project: Data): { Asset }
	local used: { [string]: boolean } = {}
	for _, layer in project.layers do
		if layer.visible and layer.assetId then used[layer.assetId] = true end
	end
	local assets = {}
	for _, asset in project.assets do
		if used[asset.id] then table.insert(assets, asset) end
	end
	return assets
end

-- True when every visible layer using the asset is a single-frame ribbon: those play on Beams, which need the
-- image rotated 90 degrees (scripts/luma_export.py writes the *_beam.png copy to upload).
local function beamOnly(project: Data, assetId: string): boolean
	local found = false
	for _, layer in project.layers do
		if layer.visible and layer.assetId == assetId then
			local sheet = layer.sheet
			if layer.kind ~= "ribbon" or sheet.columns ~= 1 or sheet.rows ~= 1 or sheet.crop then return false end
			found = true
		end
	end
	return found
end

function Project.encodeForGame(project: Data, bindings: { [string]: Binding }, frames: { [string]: FrameMetadata }?): string
	local assets = {}
	local required = Project.requiredAssets(project)
	if #required == 0 then fail("Project", "needs a visible layer with a texture.") end
	for _, asset in required do
		local binding = bindings[asset.id]
		if not binding or not binding.id:match("^[1-9]%d*$") then fail(asset.name, "needs a Roblox image ID.") end
		local width = numeric(binding.width, asset.name .. " width", 0, 1, 1024, true)
		local height = numeric(binding.height, asset.name .. " height", 0, 1, 1024, true)
		table.insert(assets, {
			id = asset.id, texture = "rbxassetid://" .. binding.id, width = width, height = height,
			beam = if beamOnly(project, asset.id) then true else nil,
		})
	end
	local layers = {}
	for _, layer in project.layers do
		if layer.visible and layer.assetId then
			local binding = bindings[layer.assetId]
			local sheet = layer.sheet
			local crop = sheet.crop
			local width = if crop then math.min(binding.width - crop.x, crop.width) else binding.width
			local height = if crop then math.min(binding.height - crop.y, crop.height) else binding.height
			if width < 2 * sheet.margin + (sheet.columns - 1) * sheet.gap + sheet.columns
				or height < 2 * sheet.margin + (sheet.rows - 1) * sheet.gap + sheet.rows then
				fail(layer.name, "has a crop or grid that does not fit the texture.")
			end
		end
		local metadata = if frames then frames[layer.id] else nil
		if metadata then
			local normalized = table.clone(layer)
			normalized.frameBounds = metadata.bounds
			normalized.maxBoundsHeight = metadata.maxHeight
			table.insert(layers, normalized)
		else
			table.insert(layers, layer)
		end
	end
	return HttpService:JSONEncode({
		version = project.version, name = project.name, duration = project.duration, loop = project.loop,
		assets = assets, layers = layers,
	})
end

return Project
