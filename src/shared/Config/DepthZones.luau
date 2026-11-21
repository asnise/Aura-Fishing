--!strict
-- Depth bands (GDD 4.2). Purely descriptive: fish declare their own DepthMin/DepthMax,
-- these bands are used for UI labels and colour.

export type DepthZone = { Name: string, Min: number, Max: number, Color: Color3 }

local DepthZones: { DepthZone } = {
	{ Name = "Shallow Water", Min = 0, Max = 50, Color = Color3.fromRGB(90, 200, 255) },
	{ Name = "Mid Water", Min = 51, Max = 200, Color = Color3.fromRGB(40, 120, 220) },
	{ Name = "Deep Sea", Min = 201, Max = 800, Color = Color3.fromRGB(30, 60, 160) },
	{ Name = "Abyssal Trench", Min = 801, Max = 2000, Color = Color3.fromRGB(60, 20, 110) },
	{ Name = "Void", Min = 2001, Max = math.huge, Color = Color3.fromRGB(20, 0, 30) },
}

return DepthZones
