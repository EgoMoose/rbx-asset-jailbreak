local HttpService = game:GetService("HttpService") :: HttpService
local AssetService = game:GetService("AssetService") :: AssetService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Constants = require(pluginRoot.Constants)

local Plugin = {}

type Decoded = {
	ticket: number,
	className: string,
}

local function jailbreak(assetId: number)
	local response = HttpService:RequestAsync({
		Method = "POST",
		Compress = Enum.HttpCompression.None,
		Headers = { ["content-type"] = "application/json" },
		Url = `http://localhost:{Constants.ServePort}/jailbreak`,
		Body = HttpService:JSONEncode({
			type = "Asset",
			assetId = assetId,
		}),
	})

	if response.StatusCode == 200 and response.Body then
		local decoded = HttpService:JSONDecode(response.Body) :: Decoded
		local content = Content.fromUri(`rbxasset://jailbreak/{decoded.ticket}`)

		if decoded.className == "EditableMesh" then
			local editMesh = AssetService:CreateEditableMeshAsync(content)
			local meshPart = AssetService:CreateMeshPartAsync(Content.fromObject(editMesh))
			meshPart.Parent = workspace
		elseif decoded.className == "EditableImage" then
			local editImage = AssetService:CreateEditableImageAsync(content)

			local screen = Instance.new("ScreenGui")
			screen.Parent = game.StarterGui

			local label = Instance.new("ImageLabel")
			label.Size = UDim2.fromOffset(editImage.Size.X, editImage.Size.Y)
			label.BackgroundTransparency = 1
			label.ImageContent = Content.fromObject(editImage)
			label.Parent = screen
		end
	end
end

function Plugin.build(plugin: Plugin)
	_G.jailbreak = jailbreak
end

return Plugin
