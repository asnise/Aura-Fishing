--!strict

local AssetService = game:GetService("AssetService")
local EncodingService = game:GetService("EncodingService")

local PNG_HEADER = "\137PNG\r\n\26\n\0\0\0\13IHDR"
local MAX_DIMENSION = 1024
local MAX_EXACT_INTEGER = 9007199254740991

local Textures = {}

local function checkSize(width: number, height: number)
	if width < 1 or height < 1 or width > MAX_DIMENSION or height > MAX_DIMENSION then
		error("Texture width and height must be between 1 and 1024 pixels.", 0)
	end
end

local function readPng(file: File): (string, number, number)
	local contents = file:GetBinaryContents()
	if #contents < 33 or contents:sub(1, #PNG_HEADER) ~= PNG_HEADER then
		error(string.format("%q does not have a valid PNG header.", file.Name), 0)
	end
	local width, height = string.unpack(">I4I4", contents, #PNG_HEADER + 1)
	checkSize(width, height)
	return contents, width, height
end

local function loadImage(uri: string, source: string): EditableImage
	local ok, image = pcall(function(): EditableImage?
		return AssetService:CreateEditableImageAsync(Content.fromUri(uri))
	end)
	if not ok then error(string.format("Studio could not read %s: %s", source, tostring(image)), 0) end
	if not image then error("Studio could not read " .. source .. ".", 0) end
	return image
end

local function applyLuma(pixels: buffer)
	for offset = 0, buffer.len(pixels) - 1, 4 do
		local red = buffer.readu8(pixels, offset)
		local green = buffer.readu8(pixels, offset + 1)
		local blue = buffer.readu8(pixels, offset + 2)
		local luminance = (0.2126 * red + 0.7152 * green + 0.0722 * blue) / 255
		local opacity = buffer.readu8(pixels, offset + 3) * luminance
		local alpha = math.floor(opacity)
		local fraction = opacity - alpha
		-- Canvas stores pixels in a Uint8ClampedArray, which rounds ties to even.
		if fraction > 0.5 or (fraction == 0.5 and alpha % 2 == 1) then
			alpha += 1
		end
		buffer.writeu32(pixels, offset, alpha * 0x1000000 + 0xFFFFFF)
	end
end

function Textures.inspect(file: File): { width: number, height: number, digest: string }
	local contents, width, height = readPng(file)
	local hash = EncodingService:ComputeStringHash(contents, Enum.HashAlgorithm.Sha256)
	local hex = table.create(#hash)
	for index = 1, #hash do
		hex[index] = string.format("%02x", string.byte(hash, index))
	end
	return { width = width, height = height, digest = table.concat(hex) }
end

function Textures.upload(file: File, matte: string, owner: { id: number, kind: Enum.AssetCreatorType }, name: string): string
	if matte ~= "rgba" and matte ~= "luma" then error("Texture matte must be rgba or luma.", 0) end
	local _, width, height = readPng(file)
	local image = loadImage(file:GetTemporaryId(), string.format("%q", file.Name))
	local ok, result, response = pcall(function()
		if image.Size.X ~= width or image.Size.Y ~= height then
			error("Studio changed the texture size on import.", 0)
		end
		if matte == "luma" then
			local pixels = image:ReadPixelsBuffer(Vector2.zero, image.Size)
			applyLuma(pixels)
			image:WritePixelsBuffer(Vector2.zero, image.Size, pixels)
		end
		return AssetService:CreateAssetAsync(image, Enum.AssetType.Image, {
			CreatorId = owner.id,
			CreatorType = owner.kind,
			Name = name,
			Description = "Aura Fishing particle texture",
		})
	end)
	image:Destroy()
	if not ok then error(string.format("Could not upload %q: %s", file.Name, tostring(result)), 0) end
	if result ~= Enum.CreateAssetResult.Success then
		error(string.format("Could not upload %q (%s): %s", file.Name, tostring(result), tostring(response)), 0)
	end
	if type(response) == "string" and response:match("^[1-9]%d*$") then
		return response
	end
	if type(response) == "number" and response >= 1 and response <= MAX_EXACT_INTEGER and response % 1 == 0 then
		return string.format("%.0f", response)
	end
	error("Roblox did not return a usable image ID.", 0)
end

function Textures.readSize(imageId: string): (number, number)
	if not imageId:match("^[1-9]%d*$") then error("Enter a numeric Roblox image ID.", 0) end
	local image = loadImage("rbxassetid://" .. imageId, "image " .. imageId)
	local size = image.Size
	image:Destroy()
	checkSize(size.X, size.Y)
	return size.X, size.Y
end

function Textures.readPixels(source: File | string, matte: string): (buffer, number, number)
	local fromFile = type(source) ~= "string"
	local uri = if type(source) == "string" then "rbxassetid://" .. source else source:GetTemporaryId()
	local image = loadImage(uri, "texture pixels")
	local size = image.Size
	local ok, pixels = pcall(image.ReadPixelsBuffer, image, Vector2.zero, size)
	image:Destroy()
	if not ok then error("Studio could not measure the texture pixels.", 0) end
	if fromFile and matte == "luma" then applyLuma(pixels) end
	return pixels, size.X, size.Y
end

return Textures
