--!strict
local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

-- 1234 -> "1,234"; 1234567 -> "1.23M"
function Format.Number(n: number): string
	n = math.floor(n)
	if math.abs(n) < 100000 then
		local s = tostring(n)
		local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
		if formatted:sub(1, 1) == "," then
			formatted = formatted:sub(2)
		end
		return (formatted:gsub("^%-,", "-"))
	end
	local i = 1
	local v = n
	while math.abs(v) >= 1000 and i < #SUFFIXES do
		v /= 1000
		i += 1
	end
	return string.format("%.2f%s", v, SUFFIXES[i])
end

function Format.Percent(v: number): string
	return string.format("%+d%%", math.floor(v * 100 + 0.5))
end

-- One stat bonus as badge text: "+15% Luck", "-20% Auto Wait", "150m depth", "+0.30 Reel Power".
function Format.Stat(key: string, def: { [string]: any }?, v: number): string
	if not def then
		return `+{v} {key}`
	end
	if def.Percent then
		local pct = Format.Percent(v)
		if def.Reduces then
			pct = (if v < 0 then "+" else "-") .. string.sub(pct, 2)
		end
		return `{pct} {def.Display}`
	elseif key == "MaxDepth" then
		return `{v}m depth`
	end
	return string.format("+%.2f %s", v, def.Display)
end

-- A rod mod as chip text. Cap Breaker (key "MaxCatchBarSize", def of the target stat): "+4% Max Catch Bar".
function Format.Mod(stat: string, defs: { [string]: any }, v: number): string
	local cap = if string.sub(stat, 1, 3) == "Max" then defs[string.sub(stat, 4)] else nil
	if cap then
		local pct = Format.Percent(v)
		if cap.Reduces then
			pct = (if v < 0 then "+" else "-") .. string.sub(pct, 2)
		end
		return if cap.Percent then `{pct} Max {cap.Display}` else string.format("%+.2f Max %s", v, cap.Display)
	end
	local def = defs[stat]
	if def and not def.Percent and stat ~= "MaxDepth" then
		return string.format("%+.2f %s", v, def.Display) -- keeps the sign of negative rolls
	end
	return Format.Stat(stat, def, v)
end

function Format.Chance(oneIn: number): string
	return "1/" .. Format.Number(oneIn)
end

return Format
