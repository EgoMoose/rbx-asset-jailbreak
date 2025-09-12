local fs = require("@lune/fs")
local net = require("@lune/net")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")
local roblox = require("@lune/roblox")

local Constants = require("@root/src/Constants")
local PathHelper = require("@self/path-helper")

type RequestHandler = {
	process: (any) -> net.ServeResponse,
}

local success, err = pcall(function()
	local requestHandlers = {}
	for _, fileName in fs.readDir(PathHelper.relative("request-handlers")) do
		local noExtension = fileName:sub(1, -6)
		requestHandlers["/" .. noExtension] = require(`@self/request-handlers/{noExtension}`) :: RequestHandler
	end

	local serve = net.serve(Constants.ServePort, function(request)
		local requestHandler = requestHandlers[request.path]
		if requestHandler then
			local decoded = serde.decode("json", request.body)
			return requestHandler.process(decoded)
		end

		return {
			status = 404,
			body = "Not Found",
		}
	end)

	print(`Serving on port {Constants.ServePort}`)
	stdio.prompt("text", "Press enter to finish")

	serve.stop()
end)

local downloadsPath = `{roblox.studioContentPath()}/{Constants.FolderName}`
if fs.isDir(downloadsPath) then
	fs.removeDir(downloadsPath)
end

if not success then
	error(err)
end
