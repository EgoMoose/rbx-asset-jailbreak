local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")

local Constants = require("@root/src/Constants")

local Delete = {}

type Decoded = {
	unique: string,
}

local function deleteFile(unique: string)
	local folderPath = `{roblox.studioContentPath()}/{Constants.FolderName}`
	local filePath = `{folderPath}/{unique}`
	if fs.isDir(folderPath) and fs.isFile(filePath) then
		fs.removeFile(filePath)
		return true
	end
	return false
end

function Delete.process(decoded: Decoded): net.ServeResponse
	local success = deleteFile(decoded.unique)

	if success then
		return {
			status = 200,
			body = serde.encode("json", {}),
		}
	end

	return {
		status = 400,
		body = "Bad request",
	}
end

return Delete
