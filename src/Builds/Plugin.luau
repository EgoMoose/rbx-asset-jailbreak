local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Jailbreak = require(pluginRoot.Main.Jailbreak)

local Plugin = {}

function Plugin.build(plugin: Plugin)
	-- selene: allow(global_usage)
	_G.jailbreak = Jailbreak.try
end

return Plugin
