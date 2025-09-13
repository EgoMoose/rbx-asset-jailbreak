local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Jailbreak = require(pluginRoot.Main.Jailbreak)

local Plugin = {}

function Plugin.build(plugin: Plugin)
	local binding = Instance.new("BindableFunction")
	binding.Name = "AssetJailbreak"
	binding.Archivable = false
	binding.OnInvoke = Jailbreak.try

	-- selene: allow(global_usage)
	_G.jailbreak = function(...)
		-- we have to call this as a binding otherwise we lose plugin security clearance
		-- which means we can't make http requests
		return binding:Invoke(...)
	end

	plugin.Unloading:Connect(function()
		binding:Destroy()
	end)
end

return Plugin
