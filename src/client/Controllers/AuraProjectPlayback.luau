--!strict
-- Timeline and atlas coordinates shared by the Roblox aura layer renderers.

local Playback = {}

export type Rect = { x: number, y: number, width: number, height: number }
export type Sheet = {
	columns: number, rows: number, margin: number, gap: number, crop: Rect?,
	first: number, last: number, fps: number, mode: string, reverse: boolean, normalize: boolean,
}
export type Timing = {
	start: number, duration: number, speed: number, offset: number,
	fadeIn: number, fadeOut: number,
}
export type Grid = {
	columns: number, rows: number, left: number, top: number,
	cellWidth: number, cellHeight: number, gap: number,
}

function Playback.frameGrid(sheet: Sheet, width: number, height: number): Grid?
	local columns, rows = sheet.columns, sheet.rows
	if columns < 1 or rows < 1 then
		return nil
	end
	local crop, margin, gap = sheet.crop, sheet.margin, sheet.gap
	local left = (if crop then math.max(0, crop.x) else 0) + margin
	local top = (if crop then math.max(0, crop.y) else 0) + margin
	local right = (if crop then math.min(width, crop.x + crop.width) else width) - margin
	local bottom = (if crop then math.min(height, crop.y + crop.height) else height) - margin
	local cellWidth = (right - left - (columns - 1) * gap) / columns
	local cellHeight = (bottom - top - (rows - 1) * gap) / rows
	if not (cellWidth >= 1 and cellHeight >= 1) then
		return nil
	end
	return {
		columns = columns, rows = rows, left = left, top = top,
		cellWidth = cellWidth, cellHeight = cellHeight, gap = gap,
	}
end

function Playback.frameRect(grid: Grid, index: number): Rect?
	if index < 0 or index >= grid.columns * grid.rows or index % 1 ~= 0 then
		return nil
	end
	local column, row = index % grid.columns, math.floor(index / grid.columns)
	local left = grid.left + column * (grid.cellWidth + grid.gap)
	local top = grid.top + row * (grid.cellHeight + grid.gap)
	local x, y = math.round(left), math.round(top)
	return { x = x, y = y, width = math.round(left + grid.cellWidth) - x, height = math.round(top + grid.cellHeight) - y }
end

function Playback.framePlacement(rect: Rect, bounds: Rect?, maxHeight: number, anchorX: number, anchorY: number): (Rect, number, number, number)
	if type(bounds) ~= "table" or type(bounds.x) ~= "number" or type(bounds.y) ~= "number"
		or type(bounds.width) ~= "number" or type(bounds.height) ~= "number" or bounds.width <= 0 or bounds.height <= 0
		or bounds.x < rect.x or bounds.y < rect.y or bounds.x + bounds.width > rect.x + rect.width
		or bounds.y + bounds.height > rect.y + rect.height then
		return rect, anchorX, anchorY, 1
	end
	return bounds, (bounds.x - rect.x + bounds.width * anchorX) / rect.width,
		(bounds.y - rect.y + bounds.height * anchorY) / rect.height, math.clamp(maxHeight / bounds.height, 1, 1.65)
end

function Playback.frameIndex(sheet: Sheet, clock: number): number
	local length = sheet.last - sheet.first + 1
	local step = math.floor(clock * sheet.fps)
	local offset = 0
	if sheet.mode == "once" then
		offset = math.clamp(step, 0, length - 1)
	elseif sheet.mode == "loop" then
		offset = step % length
	elseif sheet.mode == "pingpong" and length > 1 then
		local period = 2 * (length - 1)
		local phase = step % period
		offset = math.min(phase, period - phase)
	end
	return if sheet.reverse then sheet.last - offset else sheet.first + offset
end

function Playback.scaleProgress(sheet: Sheet, duration: number, clock: number, elapsed: number): number
	local length = sheet.last - sheet.first + 1
	if length > 1 and sheet.mode == "loop" then
		return (clock * sheet.fps % length) / length
	elseif length > 1 and sheet.mode == "pingpong" then
		local period = 2 * (length - 1)
		local phase = clock * sheet.fps % period
		return math.min(phase, period - phase) / (length - 1)
	end
	return elapsed / duration
end

function Playback.timingState(timing: Timing, time: number): (number?, number, number)
	local elapsed = time - timing.start
	if elapsed < 0 or elapsed > timing.duration then
		return nil, 0, elapsed
	end
	local fadeIn = if timing.fadeIn > 0 then elapsed / timing.fadeIn else 1
	local fadeOut = if timing.fadeOut > 0 then (timing.duration - elapsed) / timing.fadeOut else 1
	local opacity = math.min(1, fadeIn, fadeOut)
	if opacity <= 0 then
		return nil, 0, elapsed
	end
	return elapsed * timing.speed + timing.offset, opacity, elapsed
end

function Playback.playhead(duration: number, loop: boolean, elapsed: number): number
	local time = math.max(0, elapsed)
	return if loop then time % duration else math.min(duration, time)
end

function Playback.particleRange(rate: number, lifetime: number, burstSize: number, clock: number, limit: number): (number, number, number)
	if clock < 0 then
		return 0, 1, 0
	end
	local burst = if clock < lifetime then math.min(burstSize, limit) else 0
	local last = math.floor(clock * rate)
	local first = math.max(1, math.floor((clock - lifetime) * rate) + 1, last - limit + burst + 1)
	return burst, first, last
end

function Playback.particleTravel(age: number, drag: number): (number, number)
	if drag > .0001 then
		local travel = (1 - math.exp(-age * drag)) / drag
		return travel, (age - travel) / drag
	end
	return age, age * age / 2
end

return Playback
