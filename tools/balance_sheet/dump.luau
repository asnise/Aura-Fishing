-- Stubs for the Roblox globals the config files touch, then dump every config table as JSON.
local function color() return { __color = true } end
Color3 = { fromRGB = color, new = color }
Vector2 = { new = function(x, y) return { x = x, y = y } end }
UDim2 = { new = function() return {} end }
Font = { new = function() return {} end, fromEnum = function() return {} end }
Enum = setmetatable({}, { __index = function() return setmetatable({}, { __index = function() return 0 end }) end })

local CONFIG = "./cfg/"
local names = { "GameConfig", "Rarities", "Mutations", "StatDefs", "Fish", "Auras", "AuraBanners", "AuraStars", "Equipment", "Products", "Mastery", "Skills", "Quests", "DailyLogin", "Treasures", "TideEvents", "Events", "MinigamePatterns", "Features", "DepthZones", "Locations" }

local BACKSLASH = string.char(92)
local QUOTE = string.char(34)
local function esc(s)
	s = string.gsub(s, BACKSLASH, BACKSLASH .. BACKSLASH)
	s = string.gsub(s, QUOTE, BACKSLASH .. QUOTE)
	s = string.gsub(s, string.char(10), BACKSLASH .. "n")
	s = string.gsub(s, string.char(13), "")
	s = string.gsub(s, string.char(9), " ")
	return s
end

local function enc(v, depth)
	local t = type(v)
	if t == "number" then
		if v ~= v then return "null" end
		if v == math.huge then return QUOTE .. "inf" .. QUOTE end
		if v == -math.huge then return QUOTE .. "-inf" .. QUOTE end
		return tostring(v)
	elseif t == "boolean" then
		return tostring(v)
	elseif t == "string" then
		return QUOTE .. esc(v) .. QUOTE
	elseif t == "table" then
		if v.__color then return QUOTE .. "color" .. QUOTE end
		if depth > 9 then return "null" end
		local n = 0
		for _ in v do n += 1 end
		if n > 0 and n == #v then
			local out = {}
			for i, x in ipairs(v) do out[i] = enc(x, depth + 1) end
			return "[" .. table.concat(out, ",") .. "]"
		end
		local keys = {}
		for k in v do table.insert(keys, k) end
		table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
		local out = {}
		for _, k in keys do
			if type(v[k]) ~= "function" then
				table.insert(out, QUOTE .. esc(tostring(k)) .. QUOTE .. ":" .. enc(v[k], depth + 1))
			end
		end
		return "{" .. table.concat(out, ",") .. "}"
	end
	return "null"
end

local result = {}
for _, name in names do
	local ok, mod = pcall(function() return require(CONFIG .. name) end)
	if ok then
		table.insert(result, QUOTE .. name .. QUOTE .. ":" .. enc(mod, 0))
	else
		table.insert(result, QUOTE .. name .. QUOTE .. ":{" .. QUOTE .. "__error" .. QUOTE .. ":" .. QUOTE .. esc(tostring(mod)) .. QUOTE .. "}")
	end
end
print("{" .. table.concat(result, ",") .. "}")
