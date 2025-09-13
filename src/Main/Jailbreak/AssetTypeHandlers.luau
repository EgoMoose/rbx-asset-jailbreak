type AssetKind = "Image" | "Mesh"
type Handler = (assetId: number) -> {
	{
		name: string?,
		assetId: number,
		assetKind: AssetKind,
	}
}

local AssetTypeHandlers: { [Enum.AssetType]: Handler } = {}

-- Private

local function createInsertAndFinder(className: string, property: string, assetKind: AssetKind)
	return function(assetId: number)
		local foundId: number?
		local instances = game:GetObjects("rbxassetid://" .. assetId) :: { Instance }
		pcall(function()
			for _, child in instances do
				local instance: Instance?
				if child:IsA(className) then
					instance = child
				else
					instance = child:FindFirstChildWhichIsA(className, true)
				end

				if instance then
					foundId = tonumber((instance :: any)[property]:match("%d+"))
					break
				end
			end
		end)
		for _, child in instances do
			child:Destroy()
		end

		return { {
			name = nil,
			assetId = assert(foundId, "Unable to identify the asset id."),
			assetKind = assetKind,
		} }
	end
end

-- Public

AssetTypeHandlers[Enum.AssetType.Image] = function(assetId)
	return { {
		assetId = assetId,
		assetKind = "Image",
	} }
end

AssetTypeHandlers[Enum.AssetType.Mesh] = function(assetId)
	return { {
		assetId = assetId,
		assetKind = "Mesh",
	} }
end

AssetTypeHandlers[Enum.AssetType.Decal] = createInsertAndFinder("Decal", "Texture", "Image")
AssetTypeHandlers[Enum.AssetType.MeshPart] = createInsertAndFinder("MeshPart", "MeshId", "Mesh")

AssetTypeHandlers[Enum.AssetType.Hat] = createInsertAndFinder("SpecialMesh", "MeshId", "Mesh")
for _, enum in Enum.AssetType:GetEnumItems() do
	if enum.Name:sub(-9) == "Accessory" then
		AssetTypeHandlers[enum] = createInsertAndFinder("SpecialMesh", "MeshId", "Mesh")
	end
end

AssetTypeHandlers[Enum.AssetType.TShirt] = createInsertAndFinder("ShirtGraphic", "Graphic", "Image")
AssetTypeHandlers[Enum.AssetType.Shirt] = createInsertAndFinder("Shirt", "ShirtTemplate", "Image")
AssetTypeHandlers[Enum.AssetType.Pants] = createInsertAndFinder("Pants", "PantsTemplate", "Image")

return AssetTypeHandlers
