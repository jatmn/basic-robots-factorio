local util = require("util")

script.on_init(function()
	if settings.startup["basic-robots-starter-equipment"].value == true then
		if remote.interfaces["freeplay"] then
			local created_items = remote.call("freeplay", "get_created_items")
			created_items["light-armor"] = 1
			created_items["basic-robots-construction-robot"] = 15
      created_items["basic-robots-personal-roboport-equipment"] = 1
			created_items["basic-robots-battery-holder-equipment"] = 1
			created_items["basic-robots-single-use-battery"] = 50
			remote.call("freeplay", "set_created_items", created_items)
		end
	end
end)
