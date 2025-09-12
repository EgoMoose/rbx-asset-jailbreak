local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")

local Constants = require("@root/src/Constants")

local requestTicket = 0
local userCookie = assert(roblox.getAuthCookie(), "Failed to get auth cookie.")

local function downloadAssetId(assetId: number, path: string): string?
	local response = net.request({
		method = "GET",
		url = `https://assetdelivery.roblox.com/v2/assetId/{assetId}`,
		headers = { Cookie = userCookie },
	})

	if response.ok then
		local decoded = serde.decode("json", response.body)
		local assetTypeId = decoded.assetTypeId :: number

		local className: string?
		if assetTypeId == 1 then
			className = "EditableImage"
		elseif assetTypeId == 4 then
			className = "EditableMesh"
		end

		if className then
			local downloadLink = decoded.locations[1].location
			local downloadResponse = net.request(downloadLink :: string)

			if downloadResponse.ok then
				fs.writeFile(path, downloadResponse.body)
				return className
			end
		end
	end

	return nil
end

local function getDownloadFolderPath()
	local contentPath = roblox.studioContentPath()
	local folderPath = contentPath .. "/jailbreak"
	if not fs.isDir(folderPath) then
		fs.writeDir(folderPath)
	end
	return folderPath
end

type AssetRequest = {
	type: "Asset",
	assetId: number,
}

local function handleAssetRequest(request: AssetRequest): net.ServeResponse
	requestTicket = requestTicket + 1

	local ticket = requestTicket
	local folderPath = getDownloadFolderPath()
	local className = downloadAssetId(request.assetId, folderPath .. "/" .. ticket)

	if className then
		return {
			status = 200,
			body = serde.encode("json", {
				ticket = ticket,
				className = className,
			}),
		}
	end

	return {
		status = 403,
		body = "Forbidden",
	}
end

type FreedomRequest = {
	type: "Freedom",
	guid: string,
}

local function handleFreedomRequest(request: FreedomRequest): net.ServeResponse
	return {
		status = 200,
		body = "Success",
	}
end

net.serve(Constants.ServePort, function(request)
	if request.path == "/ping" then
		return {
			status = 200,
			body = "Success",
		}
	elseif request.path == "/jailbreak" then
		local decodedRequest = serde.decode("json", request.body) :: AssetRequest | FreedomRequest
		if decodedRequest.type == "Asset" then
			return handleAssetRequest(decodedRequest)
		elseif decodedRequest.type == "Freedom" then
			return handleFreedomRequest(decodedRequest)
		end
	end

	return {
		status = 404,
		body = "Not Found",
	}
end)

print(`Serving on port {Constants.ServePort}`)
print("Press ctrl + c to cancel")
