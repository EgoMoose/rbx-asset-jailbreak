local HttpService = game:GetService("HttpService") :: HttpService
local AssetService = game:GetService("AssetService") :: AssetService
local SelectionService = game:GetService("Selection") :: Selection
local MarketplaceService = game:GetService("MarketplaceService") :: MarketplaceService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Constants = require(pluginRoot.Constants)

local AssetTypeHandlers = require(script.AssetTypeHandlers)

local Jailbreak = {}

-- Types

type DownloadDecoded = {
	unique: string,
}

-- Private

local function tryResponse<T>(response: typeof(HttpService:RequestAsync(nil :: any)), callback: (T) -> ()?): (boolean, string?)
	if response.Success and response.StatusCode == 200 and response.Body then
		local decoded = HttpService:JSONDecode(response.Body)
		if callback then
			callback(decoded)
		end
		return true
	end
	return false, `HttpFail {response.StatusCode}: {response.Body}`
end

local function request(assetId: number, assetKind: "Image" | "Mesh")
	local downloadResponse = HttpService:RequestAsync({
		Method = "POST",
		Compress = Enum.HttpCompression.None,
		Headers = { ["content-type"] = "application/json" },
		Url = `http://localhost:{Constants.ServePort}/download`,
		Body = HttpService:JSONEncode({
			assetId = assetId,
		}),
	})

	local instance: Instance?
	assert(tryResponse(downloadResponse, function(decoded: DownloadDecoded)
		local content = Content.fromUri(`rbxasset://{Constants.FolderName}/{decoded.unique}`)

		if assetKind == "Image" then
			local editableImage = AssetService:CreateEditableImageAsync(content)

			local label = Instance.new("ImageLabel")
			label.BackgroundTransparency = 1
			label.ImageContent = Content.fromObject(editableImage)
			label.Size = UDim2.fromOffset(editableImage.Size.X, editableImage.Size.Y)
			label.Parent = workspace

			instance = label
		elseif assetKind == "Mesh" then
			local editableMesh = AssetService:CreateEditableMeshAsync(content)

			local meshPart = AssetService:CreateMeshPartAsync(Content.fromObject(editableMesh))
			meshPart.Parent = workspace

			instance = meshPart
		end

		local deleteResponse = HttpService:RequestAsync({
			Method = "POST",
			Compress = Enum.HttpCompression.None,
			Headers = { ["content-type"] = "application/json" },
			Url = `http://localhost:{Constants.ServePort}/delete`,
			Body = HttpService:JSONEncode({
				unique = decoded.unique,
			}),
		})

		local success, err = tryResponse(deleteResponse)
		if not success and err then
			warn("Failed to clear download\n" .. err)
		end
	end))

	return instance :: Instance
end

-- Public

function Jailbreak.try(input: string | number)
	local link = tostring(input)
	local assetId = assert(tonumber(link:match("%d+")), "Unable to identify the asset id.")
	local productInfo = assert(MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset), "Unable to retrieve product info.")

	-- selene: allow(incorrect_standard_library_use)
	local assetType = assert(Enum.AssetType:FromValue(productInfo.AssetTypeId :: number), "Unable to read asset type")

	local result
	local handler = AssetTypeHandlers[assetType]
	if handler then
		result = request(handler(assetId))
	end

	if not result then
		error("Invalid asset type request " .. tostring(assetType))
	end

	result.Name = productInfo.Name
	SelectionService:Set({ result })
	return result
end

return Jailbreak
