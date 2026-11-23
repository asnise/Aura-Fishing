--!strict
-- Plays imported Particle Editor layers on the client at the controller's playhead.

local HttpService = game:GetService("HttpService")

local Playback = require(script.Parent.AuraProjectPlayback)

local AuraProjectRenderer = {}

local PARTICLES_PER_EMITTER = 64
local PARTICLES_PER_PROJECT = 128
local LAYERS_PER_PROJECT = 96
local PLANE_THICKNESS = 0.01
local TURN = 2 * math.pi

type Asset = { id: string, texture: string, width: number, height: number, beam: boolean? }
type Frame = { rect: Playback.Rect, bounds: Playback.Rect, anchor: Vector2, scale: number }
type Visual = {
	name: string, asset: Asset, color: Color3, blend: string, sheet: Playback.Sheet, grid: Playback.Grid,
	position: Vector3, size: Vector2, anchor: Vector2, rotation: number,
	frames: { [number]: Frame }, frameBounds: { Playback.Rect }?, maxBoundsHeight: number,
}
type Emitter = {
	rate: number, lifetime: number, speed: number, spread: number, radius: number, direction: { number },
	gravity: number, drag: number, spin: number, sizeEnd: number, seed: number, randomFrame: boolean,
	radial: boolean, burst: number,
}
type Ribbon = { radius: number, tilt: number, arc: number, speed: number, phase: number, scroll: number, taper: boolean }
type Billboard = { attachment: Attachment, gui: BillboardGui, image: ImageLabel, frame: number }
type Draw = (height: number, clock: number?, opacity: number, elapsed: number) -> ()
type Layer = { draw: Draw, timing: Playback.Timing, opacity: number }

export type Handle = { Update: (self: Handle, elapsedSeconds: number) -> (), Follow: (self: Handle) -> (), Destroy: (self: Handle) -> () }

local function mix(first: number, last: number, progress: number): number
	return first + (last - first) * progress
end

local function vector3(values: { number }): Vector3
	return Vector3.new(values[1], values[2], values[3])
end

local function newImage(parent: LayerCollector, visual: Visual): ImageLabel
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Image = visual.asset.texture
	image.ImageColor3 = visual.color
	image.Size = UDim2.fromScale(1, 1)
	image.Parent = parent
	return image
end

local function setImageRect(image: ImageLabel, rect: Playback.Rect)
	image.ImageRectOffset = Vector2.new(rect.x, rect.y)
	image.ImageRectSize = Vector2.new(rect.width, rect.height)
end

local function getFrame(visual: Visual, index: number): Frame?
	local frame = visual.frames[index]
	if frame then
		return frame
	end
	local rect = Playback.frameRect(visual.grid, index)
	if not rect then
		return nil
	end
	local measured = visual.frameBounds and visual.frameBounds[index - visual.sheet.first + 1]
	local bounds, anchorX, anchorY, scale = Playback.framePlacement(rect, measured, visual.maxBoundsHeight, visual.anchor.X, visual.anchor.Y)
	frame = { rect = rect, bounds = bounds, anchor = Vector2.new(anchorX, anchorY), scale = scale }
	visual.frames[index] = frame
	return frame
end

local function newBillboard(origin: Attachment, visual: Visual, depthBias: number): Billboard
	local attachment = Instance.new("Attachment")
	attachment.Name = visual.name
	attachment.Parent = origin

	local gui = Instance.new("BillboardGui")
	gui.Adornee = attachment
	gui.Enabled = false
	gui.ClipsDescendants = false
	gui.LightInfluence = 0
	gui.StudsOffset = Vector3.new(0, 0, depthBias)
	gui.Parent = attachment
	return { attachment = attachment, gui = gui, image = newImage(gui, visual), frame = -1 }
end

local function drawBillboard(billboard: Billboard, visual: Visual, frameIndex: number, position: Vector3,
	scale: number, opacity: number, rotation: number)
	if scale <= 0 or opacity <= 0 then
		billboard.gui.Enabled = false
		return
	end
	local frame = getFrame(visual, frameIndex)
	if not frame then
		billboard.gui.Enabled = false
		return
	end
	if frameIndex ~= billboard.frame then
		setImageRect(billboard.image, frame.rect)
		billboard.frame = frameIndex
	end
	scale *= frame.scale
	local width, height = visual.size.X * scale, visual.size.Y * scale
	local dx, dy = (0.5 - frame.anchor.X) * width, (0.5 - frame.anchor.Y) * height
	local angle = math.rad(rotation % 360)
	local cosine, sine = math.cos(angle), math.sin(angle)
	billboard.attachment.Position = position
	billboard.gui.Size = UDim2.fromScale(width, height)
	billboard.gui.SizeOffset = Vector2.new((dx * cosine - dy * sine) / width, -(dx * sine + dy * cosine) / height)
	billboard.image.Rotation = rotation % 360
	billboard.image.ImageTransparency = 1 - opacity
	billboard.gui.Enabled = true
end

local function newPlane(root: BasePart, parent: Instance, name: string): (Part, Weld)
	local part = Instance.new("Part")
	part.Name = name
	part.Transparency = 1
	part.CastShadow = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.RootPriority = -127
	part.CFrame = root.CFrame
	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	part.Parent = parent
	return part, weld
end

local function newSurface(part: BasePart, face: Enum.NormalId): SurfaceGui
	local surface = Instance.new("SurfaceGui")
	surface.Adornee = part
	surface.Face = face
	surface.Enabled = false
	surface.LightInfluence = 0
	surface.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	surface.CanvasSize = Vector2.new(512, 512)
	surface.Parent = part
	return surface
end

local function makeSprite(root: BasePart, parent: Instance, origin: Attachment, visual: Visual,
	settings: { plane: string, depthBias: number, scaleStart: number, scaleEnd: number }, duration: number): Draw
	if settings.plane == "ground" then
		local part, weld = newPlane(root, parent, visual.name)
		local surface = newSurface(part, Enum.NormalId.Top)
		local image = newImage(surface, visual)
		local rotation = CFrame.Angles(0, -math.rad(visual.rotation), 0)
		local currentFrame = -1
		return function(height, clock, opacity, elapsed)
			if clock == nil then
				surface.Enabled = false
				return
			end
			local progress = Playback.scaleProgress(visual.sheet, duration, clock, elapsed)
			local scale = mix(settings.scaleStart, settings.scaleEnd, progress)
			if scale <= 0 then
				surface.Enabled = false
				return
			end
			local index = Playback.frameIndex(visual.sheet, clock)
			local frame = getFrame(visual, index)
			if not frame then
				surface.Enabled = false
				return
			end
			if index ~= currentFrame then
				setImageRect(image, frame.rect)
				currentFrame = index
			end
			scale *= frame.scale
			local width, depth = visual.size.X * scale, visual.size.Y * scale
			part.Size = Vector3.new(math.max(0.01, width), PLANE_THICKNESS, math.max(0.01, depth))
			local center = Vector3.new((0.5 - frame.anchor.X) * width, 0, (0.5 - frame.anchor.Y) * depth)
			local position = visual.position + Vector3.new(0, height + PLANE_THICKNESS / 2, 0)
			weld.C0 = CFrame.new(position) * rotation * CFrame.new(center)
			image.ImageTransparency = 1 - opacity
			surface.Enabled = true
		end
	end

	local billboard = newBillboard(origin, visual, settings.depthBias)
	return function(_, clock, opacity, elapsed)
		if clock == nil then
			billboard.gui.Enabled = false
			return
		end
		local progress = Playback.scaleProgress(visual.sheet, duration, clock, elapsed)
		local scale = mix(settings.scaleStart, settings.scaleEnd, progress)
		drawBillboard(billboard, visual, Playback.frameIndex(visual.sheet, clock), visual.position, scale, opacity, visual.rotation)
	end
end

local function sample(seed: number, index: number, channel: number): number
	local value = math.sin(seed * 11.033 + index * 12.9898 + channel * 78.233) * 43758.5453
	return value - math.floor(value)
end

local function makeEmitter(origin: Attachment, visual: Visual, emitter: Emitter, limit: number): Draw
	local pool: { Billboard } = {}
	local activeCount = 0
	local direction = vector3(emitter.direction)
	direction = if direction.Magnitude > 0 then direction.Unit else Vector3.yAxis
	local right = Vector3.new(direction.Z, 0, -direction.X)
	right = if right.Magnitude > 0.0001 then right.Unit else Vector3.xAxis
	local up = direction:Cross(right)
	local cosSpread = math.cos(math.rad(emitter.spread / 2))
	local sheet = visual.sheet
	local frameCount = sheet.last - sheet.first + 1

	local function drawParticle(slot: number, index: number, age: number, opacity: number)
		local billboard = pool[slot]
		if not billboard then
			billboard = newBillboard(origin, visual, 0)
			pool[slot] = billboard
		end
		local angle = sample(emitter.seed, index, 0) * TURN
		local cosine, sine = math.cos(angle), math.sin(angle)
		local radius = emitter.radius * (if emitter.radial then 1 else math.sqrt(sample(emitter.seed, index, 1)))
		local forward = mix(1, cosSpread, sample(emitter.seed, index, 2))
		local sideways = math.sqrt(math.max(0, 1 - forward * forward))
		local directionAngle = sample(emitter.seed, index, 3) * TURN
		local velocity = direction * forward + (right * math.cos(directionAngle) + up * math.sin(directionAngle)) * sideways
		if emitter.radial then
			velocity = Vector3.new(velocity.X * cosine - velocity.Z * sine, velocity.Y, velocity.X * sine + velocity.Z * cosine)
		end
		local travel, fall = Playback.particleTravel(age, emitter.drag)
		local position = visual.position + Vector3.new(cosine * radius, emitter.gravity * fall, sine * radius)
			+ velocity * (emitter.speed * travel)
		local frame = if emitter.randomFrame then sheet.first + math.floor(sample(emitter.seed, index, 4) * frameCount)
			else Playback.frameIndex(sheet, age)
		local progress = math.clamp(age / emitter.lifetime, 0, 1)
		drawBillboard(billboard, visual, frame, position, mix(1, emitter.sizeEnd, progress),
			opacity * math.sin(math.pi * progress), visual.rotation + emitter.spin * age)
	end

	return function(_, clock, opacity, _)
		local count = 0
		if clock ~= nil then
			local burst, first, last = Playback.particleRange(emitter.rate, emitter.lifetime, emitter.burst, clock, limit)
			for index = 1, burst do
				count += 1
				drawParticle(count, -index, clock, opacity)
			end
			for index = first, last do
				count += 1
				drawParticle(count, index, math.max(0, clock - index / emitter.rate), opacity)
			end
		end
		for index = count + 1, activeCount do
			pool[index].gui.Enabled = false
		end
		activeCount = count
	end
end

local function ribbonStart(visual: Visual, ribbon: Ribbon, clock: number): number
	return math.rad((ribbon.phase + visual.rotation + ribbon.speed * clock + (0.5 - visual.anchor.X) * ribbon.arc) % 360)
end

local function ribbonTaper(ribbon: Ribbon, progress: number): number
	return if ribbon.taper then math.max(0, math.sin(math.pi * progress)) ^ 1.15 else 1
end

local function ribbonAxes(visual: Visual, ribbon: Ribbon): (Vector3, Vector3)
	local tilt = math.rad(ribbon.tilt)
	return Vector3.new(ribbon.radius * visual.size.X, 0, 0), Vector3.new(0, math.sin(tilt), math.cos(tilt)) * ribbon.radius
end

local function ribbonBasis(tangent: Vector3): (Vector3, Vector3, Vector3)
	local right = tangent.Unit
	local back = right:Cross(Vector3.yAxis)
	back = if back.Magnitude > 0.0001 then back.Unit else Vector3.zAxis
	return right, back:Cross(right), back
end

local function makeBeamRibbon(origin: Attachment, visual: Visual, ribbon: Ribbon): Draw
	local beamCount = math.max(if ribbon.taper then 4 else 1, math.ceil(ribbon.arc / 60))
	local step = math.rad(ribbon.arc / beamCount)
	local handleLength = (4 / 3) * math.tan(step / 4)
	local xAxis, acrossAxis = ribbonAxes(visual, ribbon)
	-- A Beam maps its image with u across the width and v along the length, so beam textures are uploaded
	-- rotated 90 degrees (luma_export.py). Static + TextureLength (studs) shows each beam's own slice of the
	-- whole arc; length = ellipse perimeter (Ramanujan) over the arc.
	local semiA, semiB = xAxis.Magnitude, acrossAxis.Magnitude
	local arcLength = math.pi * (3 * (semiA + semiB) - math.sqrt((3 * semiA + semiB) * (semiA + 3 * semiB))) * ribbon.arc / 360
	local nodes: { Attachment } = {}
	local widths: { number } = {}
	local fades: { number } = {}
	local beams: { Beam } = {}
	for index = 1, beamCount + 1 do
		local node = Instance.new("Attachment")
		node.Name = visual.name
		node.Parent = origin
		nodes[index] = node
		local taper = ribbonTaper(ribbon, (index - 1) / beamCount)
		widths[index] = visual.size.Y * mix(0.45, 1, taper)
		fades[index] = taper
	end
	for index = 1, beamCount do
		local beam = Instance.new("Beam")
		beam.Enabled = false
		beam.Attachment0 = nodes[index]
		beam.Attachment1 = nodes[index + 1]
		beam.Texture = visual.asset.texture
		beam.TextureMode = Enum.TextureMode.Static
		beam.TextureLength = math.max(0.01, arcLength)
		beam.TextureSpeed = 0
		beam.Color = ColorSequence.new(visual.color)
		beam.LightEmission = if visual.blend == "add" then 1 elseif visual.blend == "screen" then 0.65 else 0
		beam.LightInfluence = 0
		beam.Segments = math.max(3, math.ceil(ribbon.arc / beamCount / 7.5))
		beam.Width0 = widths[index]
		beam.Width1 = widths[index + 1]
		beam.Parent = nodes[index]
		beams[index] = beam
	end
	local lastOpacity = -1
	local lastScroll = -1
	return function(_, clock, opacity, _)
		if clock == nil then
			for _, beam in beams do
				beam.Enabled = false
			end
			return
		end
		local start = ribbonStart(visual, ribbon, clock)
		local scroll = (ribbon.scroll * clock) % 1
		local prevTangent = 0
		for index, node in nodes do
			local angle = start + (index - 1) * step
			local sine, cosine = math.sin(angle), math.cos(angle)
			local tangent = acrossAxis * cosine - xAxis * sine
			local right, up, back = ribbonBasis(tangent)
			local position = visual.position + xAxis * cosine + acrossAxis * sine
				+ Vector3.yAxis * ((visual.anchor.Y - 0.5) * widths[index])
			node.CFrame = CFrame.fromMatrix(position, right, up, back)
			local currentTangent = tangent.Magnitude * handleLength
			local beam = beams[index - 1]
			if beam then
				beam.CurveSize0 = prevTangent
				beam.CurveSize1 = currentTangent
				if opacity ~= lastOpacity then
					beam.Transparency = NumberSequence.new(1 - opacity * fades[index - 1], 1 - opacity * fades[index])
				end
				if scroll ~= lastScroll then
					beam:SetTextureOffset(((index - 2) / beamCount + scroll) % 1)
				end
				beam.Enabled = true
			end
			prevTangent = currentTangent
		end
		lastOpacity, lastScroll = opacity, scroll
	end
end

type RibbonFace = { surface: SurfaceGui, image: ImageLabel, wrap: ImageLabel? }
type RibbonSlice = { part: Part, weld: Weld, front: RibbonFace, back: RibbonFace }

local function cutRibbonImage(image: ImageLabel, rect: Playback.Rect, start: number, span: number,
	left: number, width: number, mirror: boolean, opacity: number)
	local first = math.min(rect.width - 1, math.round(rect.width * start))
	local last = math.clamp(math.round(rect.width * (start + span)), first + 1, rect.width)
	image.ImageRectOffset = Vector2.new(rect.x + (if mirror then last else first), rect.y)
	image.ImageRectSize = Vector2.new(if mirror then first - last else last - first, rect.height)
	image.Position = UDim2.fromScale(if mirror then 1 - left - width else left, 0)
	image.Size = UDim2.fromScale(width, 1)
	image.ImageTransparency = 1 - opacity
end

local function drawRibbonFace(face: RibbonFace, rect: Playback.Rect, start: number, span: number, mirror: boolean, opacity: number)
	local first = math.min(span, 1 - start)
	local fraction = first / span
	cutRibbonImage(face.image, rect, start, first, 0, fraction, mirror, opacity)
	if face.wrap then
		local wraps = fraction < 1 - 1e-7
		if wraps then
			cutRibbonImage(face.wrap, rect, 0, span - first, fraction, 1 - fraction, mirror, opacity)
		end
		face.wrap.Visible = wraps
	end
	face.surface.Enabled = true
end

-- Fallback for ribbons without a rotated beam texture: short double-sided panels so the frame can be cropped.
local function makeAtlasRibbon(root: BasePart, parent: Instance, visual: Visual, ribbon: Ribbon): Draw
	local count = math.max(4, math.ceil(ribbon.arc / 20))
	local span = 1 / count
	local step = math.rad(ribbon.arc) * span
	local xAxis, acrossAxis = ribbonAxes(visual, ribbon)
	local slices: { RibbonSlice } = {}
	local function newFace(part: Part, normal: Enum.NormalId): RibbonFace
		local surface = newSurface(part, normal)
		return { surface = surface, image = newImage(surface, visual), wrap = if ribbon.scroll ~= 0 then newImage(surface, visual) else nil }
	end
	for index = 1, count do
		local part, weld = newPlane(root, parent, visual.name)
		slices[index] = { part = part, weld = weld, front = newFace(part, Enum.NormalId.Front), back = newFace(part, Enum.NormalId.Back) }
	end
	return function(height, clock, opacity, _)
		local frame = if clock ~= nil then getFrame(visual, Playback.frameIndex(visual.sheet, clock)) else nil
		if clock == nil or not frame then
			for _, slice in slices do
				slice.front.surface.Enabled = false
				slice.back.surface.Enabled = false
			end
			return
		end
		local start = ribbonStart(visual, ribbon, clock)
		local scroll = (ribbon.scroll * clock) % 1
		local leftPoint = xAxis * math.cos(start) + acrossAxis * math.sin(start)
		for index, slice in slices do
			local angle = start + index * step
			local rightPoint = xAxis * math.cos(angle) + acrossAxis * math.sin(angle)
			local delta = rightPoint - leftPoint
			local right, up, back = ribbonBasis(delta)
			local taper = ribbonTaper(ribbon, (index - 0.5) * span)
			local width = visual.size.Y * mix(0.45, 1, taper)
			local center = visual.position + (leftPoint + rightPoint) * 0.5
				+ Vector3.yAxis * (height + (visual.anchor.Y - 0.5) * width)
			slice.part.Size = Vector3.new(math.max(0.01, delta.Magnitude), math.max(0.01, width / math.max(up.Y, 0.5)), PLANE_THICKNESS)
			slice.weld.C0 = CFrame.fromMatrix(center, right, up, back)
			local u = ((index - 1) * span + scroll) % 1
			drawRibbonFace(slice.front, frame.bounds, u, span, true, opacity * taper)
			drawRibbonFace(slice.back, frame.bounds, u, span, false, opacity * taper)
			leftPoint = rightPoint
		end
	end
end

local function floorHeight(root: BasePart): number
	local character = root.Parent
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return -root.Size.Y / 2
	end
	local height = humanoid.HipHeight + root.Size.Y / 2
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		local leg = character and character:FindFirstChild("Left Leg")
		height += if leg and leg:IsA("BasePart") then leg.Size.Y else 2
	end
	return -height
end

local function makeVisual(layer: any, assets: { [string]: Asset }): Visual?
	if type(layer) ~= "table" or layer.visible ~= true or type(layer.assetId) ~= "string" or type(layer.sheet) ~= "table" then
		return nil
	end
	local asset = assets[layer.assetId]
	if not asset then
		return nil
	end
	local sheet: Playback.Sheet = layer.sheet
	local crop = sheet.crop
	if crop ~= nil and (type(crop) ~= "table" or type(crop.x) ~= "number" or type(crop.y) ~= "number"
		or type(crop.width) ~= "number" or type(crop.height) ~= "number") then
		return nil
	end
	local grid = Playback.frameGrid(sheet, asset.width, asset.height)
	if not grid or sheet.last < sheet.first or not Playback.frameRect(grid, sheet.first) or not Playback.frameRect(grid, sheet.last) then
		return nil
	end
	return {
		name = layer.name, asset = asset, sheet = sheet, grid = grid, blend = layer.blend,
		color = Color3.fromHex(layer.color), position = vector3(layer.position),
		size = Vector2.new(layer.size[1], layer.size[2]), anchor = Vector2.new(layer.anchor[1], layer.anchor[2]),
		rotation = layer.rotation, frames = {},
		frameBounds = if sheet.normalize and type(layer.frameBounds) == "table" then layer.frameBounds else nil,
		maxBoundsHeight = if type(layer.maxBoundsHeight) == "number" then layer.maxBoundsHeight else 0,
	}
end

function AuraProjectRenderer.mount(marker: StringValue, root: BasePart): Handle
	local ok, data = pcall(function()
		return HttpService:JSONDecode(marker.Value)
	end)
	local layers: { Layer } = {}
	local origin = Instance.new("Attachment")
	origin.Name = "AuraProjectOrigin"
	local container = Instance.new("Folder")
	container.Name = "AuraProjectPlanes"
	-- Everything is welded to this anchored part, which only copies the character position. The aura
	-- keeps world orientation, so it does not turn, lean or tilt with the character (walking, swimming).
	local anchor = Instance.new("Part")
	anchor.Name = "AuraProjectFrame"
	anchor.Anchored = true
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.CastShadow = false
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CFrame = CFrame.new(root.Position)
	anchor.Parent = container
	local duration, loop = 1, false
	if ok and type(data) == "table" and data.version == 1 and type(data.duration) == "number"
		and data.duration > 0 and data.duration <= 600 and type(data.assets) == "table" and type(data.layers) == "table" then
		duration, loop = data.duration, data.loop == true
		local assets: { [string]: Asset } = {}
		for _, asset in data.assets do
			if type(asset) == "table" and type(asset.id) == "string" and type(asset.texture) == "string"
				and string.match(asset.texture, "^rbxassetid://%d+$") and type(asset.width) == "number" and type(asset.height) == "number"
				and asset.width >= 1 and asset.width <= 65536 and asset.height >= 1 and asset.height <= 65536 then
				assets[asset.id] = asset
			end
		end
		local remaining = PARTICLES_PER_PROJECT
		for _, layer in data.layers do
			if #layers >= LAYERS_PER_PROJECT then
				break
			end
			local visual = makeVisual(layer, assets)
			if visual and layer.opacity > 0 then
				local draw: Draw? = nil
				if layer.kind == "sprite" then
					draw = makeSprite(anchor, container, origin, visual, layer.sprite, layer.timing.duration)
				elseif layer.kind == "emitter" then
					local e: Emitter = layer.emitter
					local limit = math.min(remaining, PARTICLES_PER_EMITTER, math.ceil(e.rate * e.lifetime) + e.burst)
					if limit > 0 then
						draw = makeEmitter(origin, visual, e, limit)
						remaining -= limit
					end
				elseif layer.kind == "ribbon" then
					if visual.asset.beam == true then
						draw = makeBeamRibbon(origin, visual, layer.ribbon)
					else
						draw = makeAtlasRibbon(anchor, container, visual, layer.ribbon)
					end
				end
				if draw then
					table.insert(layers, { draw = draw, timing = layer.timing, opacity = layer.opacity })
				end
			end
		end
	end
	local lastHeight: number? = nil
	if #layers > 0 then
		local height = floorHeight(root)
		lastHeight = height
		origin.Position = Vector3.new(0, height, 0)
		origin.Parent = anchor
		container.Parent = marker
	end
	local destroyed = false
	return {
		Follow = function(_)
			if not destroyed then
				anchor.CFrame = CFrame.new(root.Position)
			end
		end,
		Update = function(_, elapsedSeconds)
			if destroyed or #layers == 0 then
				return
			end
			local height = floorHeight(root)
			if height ~= lastHeight then
				lastHeight = height
				origin.Position = Vector3.new(0, height, 0)
			end
			local time = Playback.playhead(duration, loop, elapsedSeconds)
			for _, layer in layers do
				local clock, opacity, elapsed = Playback.timingState(layer.timing, time)
				layer.draw(height, clock, opacity * layer.opacity, elapsed)
			end
		end,
		Destroy = function(_)
			if not destroyed then
				destroyed = true
				container:Destroy()
				origin:Destroy()
				table.clear(layers)
			end
		end,
	}
end

return AuraProjectRenderer
