--!strict
-- Eclipse keyframes from Figma 3717:1425 and 3717:1547, in seconds.

local Motion = {}
local EASE_OUT, EASE_IN, LINEAR = 1, 2, 3

type Key = { number }
type Track = { Key }

function Motion.Sample(track: Track, time: number): number
	for i = 2, #track do
		local previous, nextKey = track[i - 1], track[i]
		local nextTime = nextKey[1]
		if time <= nextTime then
			local previousTime = previous[1]
			local alpha = math.clamp((time - previousTime) / (nextTime - previousTime), 0, 1)
			local ease = nextKey[3]
			if ease == EASE_OUT then
				alpha = 1 - (1 - alpha) ^ 3
			elseif ease == EASE_IN then
				alpha *= alpha
			elseif ease ~= LINEAR then
				alpha = alpha * alpha * (3 - 2 * alpha)
			end
			local from = previous[2]
			return from + ((nextKey[2]) - from) * alpha
		end
	end
	return track[#track][2]
end

function Motion.ForTier(tier: number)
	local eclipse = tier >= 5
	local mythic = tier >= 6
	local hit = if mythic then 2.08 elseif eclipse then 1.68 else 1.44
	local function at(offset: number): number
		return math.round((hit + offset) * 100) / 100
	end

	return {
		RevealAt = at(0.28),
		EndAt = at(0.82),
		Background = { { 0, 0 }, { 0.36, 1, EASE_OUT } },
		Sparkle = { { 0, 0 }, { 0.13, 1, EASE_OUT }, { at(-0.18), 1 }, { at(0.15), 0, EASE_OUT } },
		SparkleScale = { { 0, 0 }, { 0.55, 10, EASE_OUT }, { at(-0.23), 8.3 }, { hit, 10, EASE_IN } },
		Rotation = { { 0, 0 }, { at(0.13), if mythic then 890 else 720, LINEAR } },
		Overlay = if eclipse
			then { { 0.55, 0 }, { at(-0.2), 0.07 }, { at(0.17), if mythic then 0.82 else 0.66, EASE_OUT }, { at(0.82), 0.19 } }
			else { { 0.56, 0 }, { hit, 0.6 }, { at(0.70), 0.19, EASE_OUT } },
		Dim = if eclipse then { { 0.72, 0 }, { at(-0.30), if mythic then 0.90 else 0.74 }, { at(0.04), 0.88 }, { at(0.64), 0.22, EASE_OUT } } else nil,
		Rim = if eclipse then { { 0.78, 0 }, { at(-0.43), 1, EASE_OUT }, { at(-0.14), 1 }, { at(0.35), 0, EASE_OUT } } else nil,
		RimScale = if eclipse then { { 0.78, 1.28 }, { at(-0.22), 0.55 }, { at(0.24), if mythic then 3.2 else 1.95, EASE_OUT } } else nil,
		Wave = if eclipse then { { at(-0.56), 0 }, { at(-0.30), 0.62, EASE_OUT }, { hit, 0.92 }, { at(0.56), 0, EASE_OUT } } else nil,
		WaveScale = if eclipse then { { at(-0.56), if mythic then 1.18 else 0.44 }, { hit, if mythic then 0.42 else 0.75, EASE_IN }, { at(0.60), if mythic then 3.65 else 2.55, EASE_OUT } } else nil,
	}
end

return Motion
