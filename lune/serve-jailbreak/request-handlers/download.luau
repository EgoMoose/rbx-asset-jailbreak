local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")

local Constants = require("@root/src/Constants")

local userCookie = assert(roblox.getAuthCookie(), "Failed to get auth cookie.")

local Download = {}
local downloadUnique = 0

type Decoded = {
	assetId: number,
}

local function download(assetId: number, name: string)
	local response = net.request({
		method = "GET",
		url = `https://assetdelivery.roblox.com/v1/asset/?id={assetId}`,
		headers = { Cookie = userCookie },
	})

	if response.ok then
		local downloadsPath = `{roblox.studioContentPath()}/{Constants.FolderName}`
		if not fs.isDir(downloadsPath) then
			fs.writeDir(downloadsPath)
		end

		fs.writeFile(`{downloadsPath}/{name}`, response.body)

		return true
	end

	return false
end

function Download.process(decoded: Decoded): net.ServeResponse
	downloadUnique = downloadUnique + 1

	local unique = tostring(downloadUnique)
	local success = download(decoded.assetId, unique)

	if success then
		return {
			status = 200,
			body = serde.encode("json", {
				unique = unique,
			}),
		}
	end

	return {
		status = 401,
		body = "Unauthorized",
	}
end

return Download
