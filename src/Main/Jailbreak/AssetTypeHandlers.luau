type Result = {
	meshAssetId: number?,
	imageAssetId: number?,
}

type Handler = (assetId: number) -> { Result }

type Mapping = {
	className: string,
	property: string,
	assetIdKey: "meshAssetId" | "imageAssetId",
}

local AssetTypeHandlers: { [Enum.AssetType]: Handler } = {}

-- Private

local function createInsertAndFindMapping(mappings: { Mapping })
	return function(assetId: number)
		local result: Result = {}
		local instances = game:GetObjects("rbxassetid://" .. assetId) :: { Instance }

		for _, mapping in mappings do
			for _, child in instances do
				local instance: Instance?
				if child:IsA(mapping.className) then
					instance = child
				else
					instance = child:FindFirstChildWhichIsA(mapping.className, true)
				end

				if instance then
					local foundId
					pcall(function()
						foundId = assert(tonumber((instance :: any)[mapping.property]:match("%d+")))
					end)

					if foundId then
						result[mapping.assetIdKey] = foundId
					end
				end
			end
		end

		for _, child in instances do
			child:Destroy()
		end

		return { result }
	end
end

local specialMeshHandler = createInsertAndFindMapping({
	{
		className = "SpecialMesh",
		property = "MeshId",
		assetIdKey = "meshAssetId",
	},
	{
		className = "SpecialMesh",
		property = "TextureId",
		assetIdKey = "imageAssetId",
	},
})

-- Public

AssetTypeHandlers[Enum.AssetType.Image] = function(assetId)
	return { {
		imageAssetId = assetId,
	} }
end

AssetTypeHandlers[Enum.AssetType.Mesh] = function(assetId)
	return { {
		meshAssetId = assetId,
	} }
end

AssetTypeHandlers[Enum.AssetType.Decal] = createInsertAndFindMapping({ {
	className = "Decal",
	property = "Texture",
	assetIdKey = "imageAssetId",
} })

AssetTypeHandlers[Enum.AssetType.MeshPart] = createInsertAndFindMapping({
	{
		className = "MeshPart",
		property = "MeshId",
		assetIdKey = "meshAssetId",
	},
	{
		className = "MeshPart",
		property = "TextureID",
		assetIdKey = "imageAssetId",
	},
})

AssetTypeHandlers[Enum.AssetType.Hat] = specialMeshHandler
for _, enum in Enum.AssetType:GetEnumItems() do
	if enum.Name:sub(-9) == "Accessory" then
		AssetTypeHandlers[enum] = specialMeshHandler
	end
end

AssetTypeHandlers[Enum.AssetType.TShirt] = createInsertAndFindMapping({ {
	className = "ShirtGraphic",
	property = "Graphic",
	assetIdKey = "imageAssetId",
} })

AssetTypeHandlers[Enum.AssetType.Shirt] = createInsertAndFindMapping({ {
	className = "Shirt",
	property = "ShirtTemplate",
	assetIdKey = "imageAssetId",
} })

AssetTypeHandlers[Enum.AssetType.Pants] = createInsertAndFindMapping({ {
	className = "Pants",
	property = "PantsTemplate",
	assetIdKey = "imageAssetId",
} })

return AssetTypeHandlers
