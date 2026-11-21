--!strict
-- Edit-mode UI capture support. The Node side grabs the Studio window; the plugin only prepares the view:
--   capture_prepare  make the target visible (and optionally isolate it), add a #FF00FF calibration marker,
--                    return GUI-space rects so Node can map them to window pixels
--   capture_marker   show/hide the marker (Node takes a second shot without it)
--   capture_restore  put every changed property back (also happens automatically after 30 s)
-- All property changes run inside one ChangeHistory recording that is cancelled on restore, so nothing
-- lands in the undo history.

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local StarterGui = game:GetService("StarterGui")

local Path = require(script.Parent.Path)

local MARKER_SIZE = 32
local AUTO_RESTORE_SEC = 30

type Session = {
	saved: { { inst: Instance, prop: string, value: any } },
	temps: { Instance },
	marker: ScreenGui,
	recording: string?,
	selection: { Instance },
	done: boolean,
}

local sessions: { [string]: Session } = {}

local function restore(token: string): boolean
	local s = sessions[token]
	if not s or s.done then
		return false
	end
	s.done = true
	sessions[token] = nil
	for i = #s.saved, 1, -1 do
		local e = s.saved[i]
		pcall(function()
			(e.inst :: any)[e.prop] = e.value
		end)
	end
	for _, t in s.temps do
		pcall(t.Destroy, t)
	end
	pcall(s.marker.Destroy, s.marker)
	if s.recording then
		pcall(function()
			ChangeHistoryService:FinishRecording(s.recording :: string, Enum.FinishRecordingOperation.Cancel)
		end)
	end
	pcall(function()
		Selection:Set(s.selection)
	end)
	return true
end

local function frames(n: number)
	for _ = 1, n do
		task.wait(0.05)
	end
end

local Capture = {}

Capture.capture_prepare = function(p: any)
	local target = Path.require(p.path)
	if not (target:IsA("GuiObject") or target:IsA("LayerCollector")) then
		error(Path.of(target) .. " is a " .. target.ClassName .. ", not a GUI object", 0)
	end
	if not target:IsDescendantOf(StarterGui) then
		error(
			Path.of(target)
				.. " is not under StarterGui, so it is not drawn in the edit viewport. Mount it first (mount_ui_module) or move it.",
			0
		)
	end
	local screenGui = if target:IsA("LayerCollector") then target else target:FindFirstAncestorWhichIsA("LayerCollector")
	assert(screenGui, "no ScreenGui ancestor")

	local okRec, rec = pcall(function()
		return ChangeHistoryService:TryBeginRecording("StudioBridge: capture (temporary)")
	end)
	local s: Session = {
		saved = {},
		temps = {},
		marker = Instance.new("ScreenGui"),
		recording = if okRec then rec else nil,
		selection = Selection:Get(),
		done = false,
	}
	local token = HttpService:GenerateGUID(false)
	sessions[token] = s

	local function set(inst: Instance, prop: string, value: any)
		local cur = (inst :: any)[prop]
		if cur ~= value then
			table.insert(s.saved, { inst = inst, prop = prop, value = cur })
			;(inst :: any)[prop] = value
		end
	end

	local ok, err = pcall(function()
		Selection:Set({}) -- selection outlines would show up in the shot
		set(StarterGui, "ShowDevelopmentGui", true)

		-- make the target and its ancestors visible
		local node: Instance? = target
		while node and node ~= StarterGui do
			if node:IsA("GuiObject") then
				set(node, "Visible", true)
			elseif node:IsA("LayerCollector") then
				set(node, "Enabled", true)
			end
			node = node.Parent
		end

		if p.isolate ~= false then
			-- hide visible siblings at each level up to the ScreenGui, and every other ScreenGui
			local cur: Instance = target
			while cur ~= screenGui and cur.Parent do
				for _, sib in (cur.Parent :: Instance):GetChildren() do
					if sib ~= cur and sib:IsA("GuiObject") and sib.Visible then
						set(sib, "Visible", false)
					end
				end
				cur = cur.Parent :: Instance
			end
			for _, g in StarterGui:GetChildren() do
				if g ~= screenGui and g:IsA("LayerCollector") and g.Enabled then
					set(g, "Enabled", false)
				end
			end
		end

		if p.background then
			local bg = Instance.new("ScreenGui")
			bg.Name = "__BridgeCaptureBackground"
			bg.IgnoreGuiInset = true
			bg.DisplayOrder = (screenGui :: any).DisplayOrder and ((screenGui :: any).DisplayOrder - 1) or -1
			local f = Instance.new("Frame")
			f.Size = UDim2.fromScale(1, 1)
			f.BorderSizePixel = 0
			f.BackgroundColor3 = Color3.fromHex((string.gsub(p.background, "#", "")))
			f.Parent = bg
			bg.Parent = StarterGui
			table.insert(s.temps, bg)
		end

		local marker = s.marker
		marker.Name = "__BridgeCaptureMarker"
		marker.DisplayOrder = 2147483647
		marker.IgnoreGuiInset = true
		local m = Instance.new("Frame")
		m.Name = "Marker"
		m.Size = UDim2.fromOffset(MARKER_SIZE, MARKER_SIZE)
		m.BackgroundColor3 = Color3.fromRGB(255, 0, 255)
		m.BorderSizePixel = 0
		m.Parent = marker
		marker.Parent = CoreGui -- not part of the place
	end)
	if not ok then
		restore(token)
		error(err, 0)
	end

	frames(4)
	local markerFrame = s.marker:FindFirstChild("Marker") :: Frame
	local camera = workspace.CurrentCamera
	local guiObj = target :: any
	task.delay(AUTO_RESTORE_SEC, restore, token)
	return {
		token = token,
		place = game.Name,
		markerSize = MARKER_SIZE,
		marker = { x = markerFrame.AbsolutePosition.X, y = markerFrame.AbsolutePosition.Y },
		target = {
			x = guiObj.AbsolutePosition.X,
			y = guiObj.AbsolutePosition.Y,
			w = guiObj.AbsoluteSize.X,
			h = guiObj.AbsoluteSize.Y,
		},
		viewport = { w = camera and camera.ViewportSize.X or 0, h = camera and camera.ViewportSize.Y or 0 },
		changed = #s.saved,
		autoRestoreSec = AUTO_RESTORE_SEC,
	}
end

Capture.capture_marker = function(p: any)
	local s = sessions[p.token]
	if not s then
		error("unknown or expired capture token", 0)
	end
	s.marker.Enabled = p.visible == true
	frames(4)
	return { visible = s.marker.Enabled }
end

Capture.capture_restore = function(p: any)
	return { restored = restore(p.token) }
end

function Capture.restoreAll()
	for token in sessions do
		restore(token)
	end
end

return Capture
