type AssetKind = "Image" | "Mesh"
type Handler = (assetId: number) -> (number, AssetKind)

local AssetTypeHandlers: { [Enum.AssetType]: Handler } = {}

-- Private

local function createInsertAndFinder(className: string, property: string, assetKind: AssetKind)
	return function(assetId: number)
		local foundId: number?
		local instances = game:GetObjects("rbxassetid://" .. assetId) :: { Instance }
		pcall(function()
			for _, child in instances do
				local instance = child:FindFirstChildWhichIsA(className, true)
				if instance then
					foundId = tonumber((instance :: any)[property]:match("%d+"))
					break
				end
			end
		end)
		for _, child in instances do
			child:Destroy()
		end
		return assert(foundId, "Unable to identify the asset id."), assetKind :: any
	end
end

-- Public

AssetTypeHandlers[Enum.AssetType.Image] = function(assetId)
	return assetId, "Image"
end

AssetTypeHandlers[Enum.AssetType.Mesh] = function(assetId)
	return assetId, "Mesh"
end

AssetTypeHandlers[Enum.AssetType.Decal] = createInsertAndFinder("Decal", "Texture", "Image")
AssetTypeHandlers[Enum.AssetType.MeshPart] = createInsertAndFinder("MeshPart", "MeshId", "Mesh")

AssetTypeHandlers[Enum.AssetType.Hat] = createInsertAndFinder("SpecialMesh", "MeshId", "Mesh")
for _, enum in Enum.AssetType:GetEnumItems() do
	if enum.Name:sub(-9) == "Accessory" then
		AssetTypeHandlers[enum] = createInsertAndFinder("SpecialMesh", "MeshId", "Mesh")
	end
end

-- TODO: classic t-shirts, shirts, pants?

return AssetTypeHandlers
