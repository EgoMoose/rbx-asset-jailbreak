local process = require("@lune/process")

local PathHelper = {}

function PathHelper.relative(path: string)
	local root = tostring(debug.info(2, "s"):gsub("\\", "/"))
	local splitRoot = string.split(root, "/")

	for _, step in path:split("/") do
		local onlyDots = step:match("[%.]+") == step
		if onlyDots then
			for _ = 1, #step do
				table.remove(splitRoot)
			end
		else
			table.insert(splitRoot, step)
		end
	end

	local absPath = table.concat(splitRoot, "/")
	return "." .. absPath:sub(#process.cwd)
end

return PathHelper
