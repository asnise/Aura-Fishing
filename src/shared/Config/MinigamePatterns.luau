--!strict
-- Fish movement styles for the reel minigame. The client uses these to move the fish icon.
-- Speed:   base movement speed (bar heights / second) at Difficulty 1. Scales with difficulty.
-- Jitter:  chance per second to pick a new target position.
-- Bias:    preferred bar position (0 = bottom, 1 = top) or nil for none.
-- BurstChance: chance per second of a fast dash (for Erratic fish).

export type Pattern = { Speed: number, Jitter: number, Bias: number?, BurstChance: number }

local MinigamePatterns: { [string]: Pattern } = {
	Calm = { Speed = 0.25, Jitter = 0.6, Bias = nil, BurstChance = 0 },
	Darting = { Speed = 0.45, Jitter = 1.4, Bias = nil, BurstChance = 0.15 },
	Sinker = { Speed = 0.3, Jitter = 0.8, Bias = 0.15, BurstChance = 0.05 },
	Erratic = { Speed = 0.55, Jitter = 2.0, Bias = nil, BurstChance = 0.4 },
}

return MinigamePatterns
