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

local function downloadContent(assetId: number)
	local downloadResponse = HttpService:RequestAsync({
		Method = "POST",
		Compress = Enum.HttpCompression.None,
		Headers = { ["content-type"] = "application/json" },
		Url = `http://localhost:{Constants.ServePort}/download`,
		Body = HttpService:JSONEncode({
			assetId = assetId,
		}),
	})

	local result
	assert(tryResponse(downloadResponse, function(decoded: DownloadDecoded)
		result = {
			content = Content.fromUri(`rbxasset://{Constants.FolderName}/{decoded.unique}`),
			release = function()
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
			end,
		}
	end))
	return result
end

local function request(meshAssetId: number?, imageAssetId: number?)
	local instance: Instance

	if meshAssetId and not imageAssetId then
		local download = downloadContent(meshAssetId)
		local editableMesh = AssetService:CreateEditableMeshAsync(download.content)

		local meshPart = AssetService:CreateMeshPartAsync(Content.fromObject(editableMesh))
		meshPart.Anchored = true
		instance = meshPart

		download.release()
	elseif not meshAssetId and imageAssetId then
		local download = downloadContent(imageAssetId)
		local editableImage = AssetService:CreateEditableImageAsync(download.content)

		local label = Instance.new("ImageLabel")
		label.BackgroundTransparency = 1
		label.ImageContent = Content.fromObject(editableImage)
		label.Size = UDim2.fromOffset(editableImage.Size.X, editableImage.Size.Y)
		instance = label

		download.release()
	elseif meshAssetId and imageAssetId then
		local meshDownload = downloadContent(meshAssetId)
		local imageDownload = downloadContent(imageAssetId)

		local editableMesh = AssetService:CreateEditableMeshAsync(meshDownload.content)
		local editableImage = AssetService:CreateEditableImageAsync(imageDownload.content)

		local meshPart = AssetService:CreateMeshPartAsync(Content.fromObject(editableMesh))
		meshPart.Anchored = true
		meshPart.TextureContent = Content.fromObject(editableImage)
		instance = meshPart

		meshDownload.release()
		imageDownload.release()
	end

	return instance
end

-- Public

function Jailbreak.try(input: string | number)
	local link = tostring(input)
	local assetId = assert(tonumber(link:match("%d+")), "Unable to identify the asset id.")
	local productInfo = assert(MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset), "Unable to retrieve product info.")

	-- selene: allow(incorrect_standard_library_use)
	local assetType = assert(Enum.AssetType:FromValue(productInfo.AssetTypeId :: number), "Unable to read asset type")

	local instances: { Instance }
	local handler = AssetTypeHandlers[assetType]
	if handler then
		instances = {}
		local results = handler(assetId)
		for _, result in results do
			local instance = request(result.meshAssetId, result.imageAssetId)
			instance.Name = productInfo.Name
			instance.Parent = workspace
			table.insert(instances, instance)
		end
	end

	if not instances then
		error("Invalid asset type request " .. tostring(assetType))
	end

	SelectionService:Set(instances)

	return instances
end

return Jailbreak
