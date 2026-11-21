--!strict
-- JSON <-> Roblox value conversion.
-- encode: Roblox value -> JSON-safe value ({"Vector3":[x,y,z]}, "Enum.Font.Gotham", ...).
-- decode: JSON value -> Roblox value, guided by the property's current value (so plain arrays work).

local Path = require(script.Parent.Path)

local Codec = {}

local function round(n: number): number
	if n ~= n then
		return 0
	end
	if n == math.huge or n == -math.huge then
		return n > 0 and 1e308 or -1e308
	end
	return math.floor(n * 1e4 + 0.5) / 1e4
end

local function nums(...: number): { number }
	local out = {}
	for i, v in { ... } do
		out[i] = round(v)
	end
	return out
end

function Codec.encode(v: any, depth: number?): any
	local t = typeof(v)
	local d = depth or 0
	if t == "nil" or t == "boolean" or t == "string" then
		return v
	elseif t == "number" then
		if v ~= v then
			return "NaN"
		elseif v == math.huge then
			return "inf"
		elseif v == -math.huge then
			return "-inf"
		end
		return v
	elseif t == "Vector3" then
		return { Vector3 = nums(v.X, v.Y, v.Z) }
	elseif t == "Vector2" then
		return { Vector2 = nums(v.X, v.Y) }
	elseif t == "Vector3int16" then
		return { Vector3int16 = { v.X, v.Y, v.Z } }
	elseif t == "Vector2int16" then
		return { Vector2int16 = { v.X, v.Y } }
	elseif t == "UDim" then
		return { UDim = nums(v.Scale, v.Offset) }
	elseif t == "UDim2" then
		return { UDim2 = nums(v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset) }
	elseif t == "Color3" then
		return { Color3 = nums(v.R, v.G, v.B), hex = "#" .. v:ToHex() }
	elseif t == "CFrame" then
		return { CFrame = nums(v:GetComponents()) }
	elseif t == "EnumItem" then
		return tostring(v)
	elseif t == "BrickColor" then
		return { BrickColor = v.Name }
	elseif t == "Instance" then
		return { Instance = Path.of(v) }
	elseif t == "NumberRange" then
		return { NumberRange = nums(v.Min, v.Max) }
	elseif t == "Rect" then
		return { Rect = nums(v.Min.X, v.Min.Y, v.Max.X, v.Max.Y) }
	elseif t == "Font" then
		return { Font = { Family = v.Family, Weight = v.Weight.Name, Style = v.Style.Name } }
	elseif t == "NumberSequence" then
		local kps = {}
		for _, k in v.Keypoints do
			table.insert(kps, nums(k.Time, k.Value, k.Envelope))
		end
		return { NumberSequence = kps }
	elseif t == "ColorSequence" then
		local kps = {}
		for _, k in v.Keypoints do
			table.insert(kps, nums(k.Time, k.Value.R, k.Value.G, k.Value.B))
		end
		return { ColorSequence = kps }
	elseif t == "table" then
		if d > 6 then
			return "<table depth limit>"
		end
		local out = {}
		local isArray = #v > 0
		for k, x in v do
			if isArray then
				out[k] = Codec.encode(x, d + 1)
			else
				out[tostring(k)] = Codec.encode(x, d + 1)
			end
		end
		return out
	end
	-- Content, Faces, Axes, PhysicalProperties, functions, ...
	return { ["$type"] = t, value = tostring(v) }
end

local TYPED = {
	"Vector3",
	"Vector2",
	"Vector3int16",
	"Vector2int16",
	"UDim",
	"UDim2",
	"Color3",
	"CFrame",
	"BrickColor",
	"Instance",
	"NumberRange",
	"Rect",
	"Font",
	"NumberSequence",
	"ColorSequence",
	"Enum",
}

local function hexColor(s: string): Color3?
	local h = string.match(s, "^#?(%x%x%x%x%x%x)$")
	if h then
		return Color3.fromHex(h)
	end
	return nil
end

local function color(v: any): Color3
	if typeof(v) == "string" then
		local c = hexColor(v)
		if c then
			return c
		end
		error("bad Color3 hex: " .. v, 0)
	end
	local r, g, b = v[1] or v.R or v.r, v[2] or v.G or v.g, v[3] or v.B or v.b
	if r > 1 or g > 1 or b > 1 then
		return Color3.fromRGB(r, g, b)
	end
	return Color3.new(r, g, b)
end

local function enumItem(enumType: Enum?, v: any): EnumItem
	if typeof(v) == "string" then
		local enumName, item = string.match(v, "^Enum%.(%w+)%.(%w+)$")
		if enumName then
			return (Enum :: any)[enumName][item]
		end
		assert(enumType, "need Enum.Type.Item form here")
		for _, e in enumType:GetEnumItems() do
			if e.Name == v then
				return e
			end
		end
		error(string.format('"%s" is not a member of %s', v, tostring(enumType)), 0)
	elseif typeof(v) == "number" and enumType then
		for _, e in enumType:GetEnumItems() do
			if e.Value == v then
				return e
			end
		end
	end
	error("bad enum value " .. tostring(v), 0)
end

local function font(v: any): Font
	if typeof(v) == "string" then
		if string.find(v, "^rbxasset") then
			return Font.new(v)
		end
		local ok, f = pcall(Font.fromName, v)
		if ok then
			return f
		end
		return Font.fromEnum((Enum.Font :: any)[v])
	end
	local w = v.Weight and (Enum.FontWeight :: any)[v.Weight] or Enum.FontWeight.Regular
	local s = v.Style and (Enum.FontStyle :: any)[v.Style] or Enum.FontStyle.Normal
	local fam = v.Family
	if not string.find(fam, "^rbxasset") then
		return Font.fromName(fam, w, s)
	end
	return Font.new(fam, w, s)
end

local function build(kind: string, v: any, current: any): any
	if kind == "Vector3" then
		return Vector3.new(v[1] or v.X or 0, v[2] or v.Y or 0, v[3] or v.Z or 0)
	elseif kind == "Vector2" then
		return Vector2.new(v[1] or v.X or 0, v[2] or v.Y or 0)
	elseif kind == "Vector3int16" then
		return Vector3int16.new(v[1], v[2], v[3])
	elseif kind == "Vector2int16" then
		return Vector2int16.new(v[1], v[2])
	elseif kind == "UDim" then
		return UDim.new(v[1] or 0, v[2] or 0)
	elseif kind == "UDim2" then
		if #v == 2 then -- [scaleX, scaleY] shorthand
			return UDim2.fromScale(v[1], v[2])
		end
		return UDim2.new(v[1] or 0, v[2] or 0, v[3] or 0, v[4] or 0)
	elseif kind == "Color3" then
		return color(v)
	elseif kind == "CFrame" then
		if #v == 3 then
			return CFrame.new(v[1], v[2], v[3])
		end
		return CFrame.new(table.unpack(v))
	elseif kind == "BrickColor" then
		return BrickColor.new(v)
	elseif kind == "Instance" then
		if v == nil or v == "" then
			return nil
		end
		return Path.require(v)
	elseif kind == "NumberRange" then
		return NumberRange.new(v[1], v[2] or v[1])
	elseif kind == "Rect" then
		return Rect.new(v[1], v[2], v[3], v[4])
	elseif kind == "Font" then
		return font(v)
	elseif kind == "NumberSequence" then
		if typeof(v) == "number" then
			return NumberSequence.new(v)
		end
		local kps = {}
		for _, k in v do
			table.insert(kps, NumberSequenceKeypoint.new(k[1], k[2], k[3] or 0))
		end
		return NumberSequence.new(kps)
	elseif kind == "ColorSequence" then
		if typeof(v) == "string" then
			return ColorSequence.new(color(v))
		end
		local kps = {}
		for _, k in v do
			table.insert(kps, ColorSequenceKeypoint.new(k[1], Color3.new(k[2], k[3], k[4])))
		end
		return ColorSequence.new(kps)
	elseif kind == "Enum" then
		return enumItem(current and current.EnumType, v)
	end
	error("unknown type " .. kind, 0)
end

-- Decode a JSON value for a property whose current value is `current`.
function Codec.decode(v: any, current: any): any
	if typeof(v) == "table" then
		-- explicit {"Type": value} form
		for _, kind in TYPED do
			if v[kind] ~= nil then
				return build(kind, v[kind], current)
			end
		end
		if v["$type"] then
			error("cannot set values of type " .. tostring(v["$type"]), 0)
		end
	end
	local ct = typeof(current)
	if ct == "EnumItem" then
		return enumItem(current.EnumType, v)
	elseif ct == "Color3" or ct == "Vector3" or ct == "Vector2" or ct == "UDim" or ct == "UDim2" or ct == "CFrame"
		or ct == "BrickColor" or ct == "NumberRange" or ct == "Rect" or ct == "Font" or ct == "NumberSequence"
		or ct == "ColorSequence" or ct == "Vector3int16" or ct == "Vector2int16"
	then
		return build(ct, v, current)
	elseif ct == "Instance" or (current == nil and typeof(v) == "string" and string.find(v, "%.")) then
		-- reference property (current nil = unset ref like PrimaryPart)
		if ct == "Instance" or Path.resolve(v) then
			return build("Instance", v, current)
		end
	elseif ct == "number" and typeof(v) == "string" then
		return tonumber(v)
	end
	return v
end

-- Set one property with type-guided decoding; errors carry the property name.
function Codec.setProperty(inst: Instance, name: string, value: any)
	local okRead, current = pcall(function()
		return (inst :: any)[name]
	end)
	if not okRead then
		error(string.format("%s has no property %s", inst.ClassName, name), 0)
	end
	local decoded = Codec.decode(value, current)
	local ok, err = pcall(function()
		(inst :: any)[name] = decoded
	end)
	if not ok then
		error(string.format("set %s.%s: %s", inst.ClassName, name, tostring(err)), 0)
	end
end

-- Attribute values: same typed forms, plain JSON otherwise. nil (JSON null) removes.
function Codec.decodeAttribute(v: any): any
	if typeof(v) == "table" then
		return Codec.decode(v, nil)
	elseif typeof(v) == "string" then
		local c = string.match(v, "^#%x%x%x%x%x%x$") and hexColor(v)
		return c or v
	end
	return v
end

return Codec
