local e, i, r
local tint

function remove_tech_effect(name, type)
	local tech = data.raw.technology[name]
	for i, effect in ipairs(tech.effects) do
		if effect.type == type then
			table.remove(tech.effects, i)
			break
		end
	end
end

-- Armour Upgrade
data:extend({
	{
		type = "equipment-grid",
		name = "basic-robots-tiny-grid",
		width = 4,
		height = 2,
		equipment_categories = { "armor" },
	},
})
data.raw.armor["light-armor"].equipment_grid = "basic-robots-tiny-grid"
data.raw.armor["heavy-armor"].equipment_grid = "basic-robots-tiny-grid"

-- Robot Upgrades
-- Make MK1 personal roboport clearly better than basic
data.raw["roboport-equipment"]["personal-roboport-equipment"].charging_station_count = 4
data.raw["roboport-equipment"]["personal-roboport-equipment"].robot_limit = 15

if settings.startup["basic-robots-speed-rebalance"].value then
	-- Double base robot speed
	data.raw["construction-robot"]["construction-robot"].speed = 0.12
	data.raw["logistic-robot"]["logistic-robot"].speed = 0.10
	-- Robot base speed is double, reduce upgrade amount
	data.raw.technology["worker-robots-speed-1"].effects[1].modifier = 0.050
	data.raw.technology["worker-robots-speed-2"].effects[1].modifier = 0.090
	data.raw.technology["worker-robots-speed-3"].effects[1].modifier = 0.130
	data.raw.technology["worker-robots-speed-4"].effects[1].modifier = 0.180
	data.raw.technology["worker-robots-speed-5"].effects[1].modifier = 0.250
	data.raw.technology["worker-robots-speed-6"].effects[1].modifier = 0.325
end

-- Basic robots
tint = { 0.8, 0.8, 0.6 }
e = table.deepcopy(data.raw["construction-robot"]["construction-robot"])
e.name = "basic-robots-construction-robot"
e.minable.result = e.name
e.max_energy = "750kJ"
e.idle.tint = tint
--e.idle.hr_version.tint = tint
e.in_motion.tint = tint
--e.in_motion.hr_version.tint = tint
e.working.tint = tint
--e.working.hr_version.tint = tint

data:extend({
	e,
	{
		type = "item",
		name = "basic-robots-construction-robot",
		icons = { {
			icon = "__base__/graphics/icons/construction-robot.png",
			tint = tint,
		} },
		icon_size = 64,
		icon_mipmaps = 4,
		subgroup = "logistic-network",
		order = "a[robot]-b[construction-robot]",
		place_result = "basic-robots-construction-robot",
		stack_size = 50,
	},
	{
		type = "recipe",
		name = "basic-robots-construction-robot",
		results = {
			{ type = "item", name = "basic-robots-construction-robot", amount = 1 },
		},
		main_product = "basic-robots-construction-robot",
		enabled = false,
		ingredients = {
			{ type = "item", name = "electronic-circuit", amount = 10 },
			{ type = "item", name = "iron-gear-wheel", amount = 10 },
			{ type = "item", name = "iron-plate", amount = 10 },
		},
	},
})

if settings.startup["basic-robots-enable-logistics"].value then
	e = table.deepcopy(data.raw["logistic-robot"]["logistic-robot"])
	e.name = "basic-robots-logistic-robot"
	e.minable.result = e.name
	e.max_energy = "750kJ"
	e.idle.tint = tint
	-- e.idle.hr_version.tint = tint
	e.in_motion.tint = tint
	--e.in_motion.hr_version.tint = tint
	e.idle_with_cargo.tint = tint
	--e.idle_with_cargo.hr_version.tint = tint
	e.in_motion_with_cargo.tint = tint
	--e.in_motion_with_cargo.hr_version.tint = tint
	data:extend({
		e,
		{
			type = "item",
			name = "basic-robots-logistic-robot",
			icons = { {
				icon = "__base__/graphics/icons/logistic-robot.png",
				tint = tint,
			} },
			icon_size = 64,
			icon_mipmaps = 4,
			subgroup = "logistic-network",
			order = "a[robot]-a[logistic-robot]",
			place_result = "basic-robots-logistic-robot",
			stack_size = 50,
		},
		{
			type = "recipe",
			name = "basic-robots-logistic-robot",
			results = {
				{ type = "item", name = "basic-robots-logistic-robot", amount = 1 },
			},
			main_product = "basic-robots-logistic-robot",
			enabled = false,
			ingredients = {
				{ type = "item", name = "electronic-circuit", amount = 10 },
				{ type = "item", name = "iron-gear-wheel", amount = 10 },
				{ type = "item", name = "iron-plate", amount = 10 },
			},
		},
	})
end

if
	settings.startup["basic-robots-enable-roboport"].value or settings.startup["basic-robots-enable-logistics"].value
then
	-- Containers
	e = table.deepcopy(data.raw["container"]["iron-chest"])
	e.type = "logistic-container"
	e.name = "basic-robots-logistic-chest-passive-provider"
	e.icons = { { icon = e.icon, tint = { 1, 0.5, 0.5 } } }
	e.icon = nil
	e.minable.result = e.name
	e.logistic_mode = "passive-provider"
	e.next_upgrade = "passive-provider-chest"
	e.inventory_size = 16
	e.picture.layers[1].tint = { 1, 0.5, 0.5 }
	--e.picture.layers[1].hr_version.tint= {1, 0.5, 0.5}

	data:extend({
		e,
		{
			type = "item",
			name = "basic-robots-logistic-chest-passive-provider",
			icons = {
				{
					icon = "__base__/graphics/icons/iron-chest.png",
					tint = { 1, 0.5, 0.5 },
				},
			},
			icon_size = 64,
			icon_mipmaps = 4,
			subgroup = "logistic-network",
			order = "b[storage]-c[logistic-chest-passive-provider]",
			place_result = "basic-robots-logistic-chest-passive-provider",
			stack_size = 50,
		},
		{
			type = "recipe",
			name = "basic-robots-logistic-chest-passive-provider",
			enabled = false,
			ingredients = {
				{ type = "item", name = "iron-chest", amount = 1 },
				{ type = "item", name = "iron-gear-wheel", amount = 5 },
				{ type = "item", name = "electronic-circuit", amount = 5 },
			},
			results = {
				{ type = "item", name = "basic-robots-logistic-chest-passive-provider", amount = 1 },
			},
			main_product = "basic-robots-logistic-chest-passive-provider",
		},
	})

	e = table.deepcopy(data.raw["container"]["iron-chest"])
	e.type = "logistic-container"
	e.name = "basic-robots-logistic-chest-storage"
	e.icons = { { icon = e.icon, tint = { 1, 1, 0.25 } } }
	e.icon = nil
	e.minable.result = e.name
	e.logistic_mode = "storage"
	e.max_logistic_slots = 1
	e.next_upgrade = "storage-chest"
	e.inventory_size = 16
	e.picture.layers[1].tint = { 1, 1, 0.25 }
	--e.picture.layers[1].hr_version.tint= {1, 1, 0.25}

	data:extend({
		e,
		{
			type = "item",
			name = "basic-robots-logistic-chest-storage",
			icons = {
				{
					icon = "__base__/graphics/icons/iron-chest.png",
					tint = { 1, 1, 0.25 },
				},
			},
			icon_size = 64,
			icon_mipmaps = 4,
			subgroup = "logistic-network",
			order = "b[storage]-c[logistic-chest-storage]",
			place_result = "basic-robots-logistic-chest-storage",
			stack_size = 50,
		},
		{
			type = "recipe",
			name = "basic-robots-logistic-chest-storage",
			enabled = false,
			ingredients = {
				{ type = "item", name = "iron-chest", amount = 1 },
				{ type = "item", name = "iron-gear-wheel", amount = 5 },
				{ type = "item", name = "electronic-circuit", amount = 5 },
			},
			results = {
				{ type = "item", name = "basic-robots-logistic-chest-storage", amount = 1 },
			},
			main_product = "basic-robots-logistic-chest-storage",
		},
	})
end

-- Requester chest by cHL
e = table.deepcopy(data.raw["container"]["iron-chest"])
e.type = "logistic-container"
e.name = "basic-robots-logistic-chest-requester"
e.icons = { { icon = e.icon, tint = { 0.5, 0.5, 1 } } }
e.icon = nil
e.minable.result = e.name
e.logistic_mode = "requester"
e.next_upgrade = "requester-chest"
e.inventory_size = 16
e.trash_inventory_size = 5
e.picture.layers[1].tint = { 0.5, 0.5, 1 }
--e.picture.layers[1].hr_version.tint= {0.5, 0.5, 1}

data:extend({
	e,
	{
		type = "item",
		name = "basic-robots-logistic-chest-requester",
		icons = { {
			icon = "__base__/graphics/icons/iron-chest.png",
			tint = { 0.5, 0.5, 1 },
		} },
		icon_size = 64,
		icon_mipmaps = 4,
		subgroup = "logistic-network",
		order = "b[storage]-c[logistic-chest-requester]",
		place_result = "basic-robots-logistic-chest-requester",
		stack_size = 50,
	},
	{
		type = "recipe",
		name = "basic-robots-logistic-chest-requester",
		enabled = false,
		ingredients = {
			{ type = "item", name = "iron-chest", amount = 1 },
			{ type = "item", name = "iron-gear-wheel", amount = 5 },
			{ type = "item", name = "electronic-circuit", amount = 5 },
		},
		results = {
			{ type = "item", name = "basic-robots-logistic-chest-requester", amount = 1 },
		},
		main_product = "basic-robots-logistic-chest-requester",
	},
})

data:extend({
	{
		type = "technology",
		name = "basic-robots-robotics-requester",
		icon_size = 256,
		icon_mipmaps = 4,
		icon = "__base__/graphics/technology/robotics.png",
		prerequisites = { "basic-robots-robotics" },
		unit = {
			count = 100,
			ingredients = {
				{ "automation-science-pack", 1 },
			},
			time = 15,
		},
		effects = {
			{ type = "unlock-recipe", recipe = "basic-robots-logistic-chest-requester" },
		},
		order = "c-i",
	},
})

-- Basic roboport
if settings.startup["basic-robots-enable-roboport"].value then
	data.raw["roboport"]["roboport"].fast_replaceable_group = "roboport"
	e = table.deepcopy(data.raw["roboport"]["roboport"])
	e.name = "basic-robots-roboport"
	e.minable.result = e.name
	e.icons = { { icon = e.icon, tint = { 0.6, 0.4, 0.1 } } }
	e.icon = nil
	e.energy_source.input_flow_limit = "2MW"
	e.energy_source.buffer_capacity = "10MJ"
	e.recharge_minimum = "5MJ"
	e.charging_energy = "500kW"
	e.logistics_radius = 25
	e.construction_radius = 30
	e.next_upgrade = "roboport"
	e.robot_slots_count = 4
	e.material_slots_count = 4
	e.base.layers[1].tint = { 0.6, 0.4, 0.1 }
	--e.base.layers[1].hr_version.tint = {0.6, 0.4, 0.1}
	e.base_patch.tint = { 0.6, 0.4, 0.1 }
	--e.base_patch.hr_version.tint = {0.6, 0.4, 0.1}
	e.base_animation.tint = { 0.6, 0.4, 0.1 }
	--e.base_animation.hr_version.tint = {0.6, 0.4, 0.1}
	e.door_animation_up.tint = { 0.6, 0.4, 0.1 }
	--e.door_animation_up.hr_version.tint = {0.6, 0.4, 0.1}
	e.door_animation_down.tint = { 0.6, 0.4, 0.1 }
	--e.door_animation_down.hr_version.tint = {0.6, 0.4, 0.1}

	i = table.deepcopy(data.raw.item["roboport"])
	i.name = e.name
	i.place_result = e.name

	data:extend({
		e,
		{
			type = "item",
			name = "basic-robots-roboport",
			icons = {
				{
					icon = "__base__/graphics/icons/roboport.png",
					tint = { 0.6, 0.4, 0.1 },
				},
			},
			icon_size = 64,
			icon_mipmaps = 4,
			subgroup = "logistic-network",
			order = "c[signal]-a[roboport]",
			place_result = "basic-robots-roboport",
			stack_size = 10,
		},
		{
			type = "recipe",
			name = "basic-robots-roboport",
			enabled = false,
			energy_required = 5,
			ingredients = {
				{ type = "item", name = "iron-plate", amount = 45 },
				{ type = "item", name = "iron-gear-wheel", amount = 45 },
				{ type = "item", name = "electronic-circuit", amount = 45 },
			},
			results = {
				{ type = "item", name = "basic-robots-roboport", amount = 1 },
			},
			main_product = "basic-robots-roboport",
		},
	})
end

-- Basic personal roboport

e = table.deepcopy(data.raw["roboport-equipment"]["personal-roboport-equipment"])
e.name = "basic-robots-personal-roboport-equipment"
e.take_result = e.name
e.construction_radius = 15
e.charging_station_count = 4
e.robot_limit = 10
e.sprite.tint = { 0.6, 0.4, 0.1 }

data:extend({
	e,
	{
		type = "item",
		name = "basic-robots-personal-roboport-equipment",
		icons = {
			{
				icon = "__base__/graphics/icons/personal-roboport-equipment.png",
				tint = { 0.6, 0.4, 0.1 },
			},
		},
		icon_size = 64,
		icon_mipmaps = 4,
		place_as_equipment_result = "basic-robots-personal-roboport-equipment",
		subgroup = "utility-equipment",
		order = "e[robotics]-a[personal-roboport-equipment]",
		default_request_amount = 1,
		stack_size = 20,
	},
	{
		type = "recipe",
		name = "basic-robots-personal-roboport-equipment",
		enabled = false,
		energy_required = 10,
		ingredients = {
			{ type = "item", name = "electronic-circuit", amount = 10 },
			{ type = "item", name = "iron-gear-wheel", amount = 40 },
			{ type = "item", name = "iron-plate", amount = 20 },
		},
		results = {
			{ type = "item", name = "basic-robots-personal-roboport-equipment", amount = 1 },
		},
		main_product = "basic-robots-personal-roboport-equipment",
	},
})

-- Battery Holder
data:extend({
	{
		type = "fuel-category",
		name = "basic-robots-single-use-battery",
	},
	{
		type = "generator-equipment",
		name = "basic-robots-battery-holder-equipment",
		shape = { width = 2, height = 2, type = "full" },
		sprite = {
			filename = "__base__/graphics/icons/battery-equipment.png",
			tint = { 0.7, 0.7, 0.7 },
			width = 64,
			height = 64,
			priority = "medium",
		},
		burner = {
			type = "burner",
			fuel_categories = { "basic-robots-single-use-battery" },
			fuel_inventory_size = 1,
			burnt_inventory_size = 0,
		},
		energy_source = {
			type = "electric",
			usage_priority = "primary-output",
		},
		power = "150kW",
		categories = { "armor" },
	},
	{
		type = "item",
		name = "basic-robots-battery-holder-equipment",
		icons = { { icon = "__base__/graphics/icons/battery-equipment.png", tint = { 0.7, 0.7, 0.7 } } },
		icon_size = 64,
		icon_mipmaps = 4,
		place_as_equipment_result = "basic-robots-battery-holder-equipment",
		subgroup = "equipment",
		order = "e[robotics]-a[personal-roboport-equipment]",
		default_request_amount = 1,
		stack_size = 20,
	},
	{
		type = "recipe",
		name = "basic-robots-battery-holder-equipment",
		enabled = false,
		energy_required = 10,
		ingredients = {
			{ type = "item", name = "electronic-circuit", amount = 5 },
			{ type = "item", name = "copper-cable", amount = 10 },
			{ type = "item", name = "iron-plate", amount = 5 },
		},
		results = {
			{ type = "item", name = "basic-robots-battery-holder-equipment", amount = 1 },
		},
		main_product = "basic-robots-battery-holder-equipment",
	},
})
-- Single-use battery
data:extend({
	{
		type = "item",
		name = "basic-robots-single-use-battery",
		icons = { { icon = "__base__/graphics/icons/battery.png", tint = { 0.7, 0.7, 0.7 } } },
		icon_size = 64,
		icon_mipmaps = 4,
		subgroup = "intermediate-product",
		order = "e[electronic-circuit]",
		stack_size = 50,
		fuel_category = "basic-robots-single-use-battery",
		fuel_value = "2MJ",
	},
	{
		type = "recipe",
		name = "basic-robots-single-use-battery",
		energy_required = 20,
		category = "advanced-crafting",
		ingredients = {
			{ type = "item", name = "iron-plate", amount = 1 },
			{ type = "item", name = "copper-plate", amount = 2 },
			{ type = "item", name = "copper-cable", amount = 4 },
		},
		results = {
			{ type = "item", name = "basic-robots-single-use-battery", amount = 1 },
		},
		main_product = "basic-robots-single-use-battery",
	},
})

-- Research
data:extend({
	{
		type = "technology",
		name = "basic-robots-robotics",
		icon_size = 256,
		icon_mipmaps = 4,
		icon = "__base__/graphics/technology/robotics.png",
		prerequisites = { "logistics" },
		unit = {
			count = 50,
			ingredients = {
				{ "automation-science-pack", 1 },
			},
			time = 15,
		},
		effects = {
			{ type = "unlock-recipe", recipe = "basic-robots-construction-robot" },
			{ type = "unlock-recipe", recipe = "basic-robots-personal-roboport-equipment" },
			{ type = "unlock-recipe", recipe = "basic-robots-battery-holder-equipment" },
			{ type = "unlock-recipe", recipe = "basic-robots-single-use-battery" },
			-- { type = "ghost-time-to-live", modifier = 60 * 60 * 60 * 24 * 7 }
		},
		order = "c-i",
	},
})

data.raw.technology["robotics"].prerequisites = { "electric-engine", "battery", "basic-robots-robotics" }
--remove_tech_effect("construction-robotics", "ghost-time-to-live")
if settings.startup["basic-robots-enable-roboport"].value then
	table.insert(
		data.raw.technology["basic-robots-robotics"].effects,
		{ type = "unlock-recipe", recipe = "basic-robots-roboport" }
	)
end
if settings.startup["basic-robots-enable-logistics"].value then
	table.insert(
		data.raw.technology["basic-robots-robotics"].effects,
		{ type = "unlock-recipe", recipe = "basic-robots-logistic-robot" }
	)
	table.insert(
		data.raw.technology["basic-robots-robotics"].effects,
		{ type = "character-logistic-requests", modifier = true }
	)
	table.insert(
		data.raw.technology["basic-robots-robotics"].effects,
		{ type = "character-logistic-trash-slots", modifier = 30 }
	)
	remove_tech_effect("logistic-robotics", "character-logistic-requests")
	remove_tech_effect("logistic-robotics", "character-logistic-trash-slots")
end
if settings.startup["basic-robots-enable-logistics"].value and settings.startup["basic-robots-enable-roboport"] then
	table.insert(
		data.raw.technology["basic-robots-robotics"].effects,
		{ type = "unlock-recipe", recipe = "basic-robots-logistic-chest-passive-provider" }
	)
	table.insert(
		data.raw.technology["basic-robots-robotics"].effects,
		{ type = "unlock-recipe", recipe = "basic-robots-logistic-chest-storage" }
	)
end

-- Move first upgrade tier to red/green
data.raw.technology["worker-robots-speed-1"].prerequisites = { "basic-robots-robotics", "logistic-science-pack" }
data.raw.technology["worker-robots-speed-1"].unit = {
	count = 50,
	ingredients = {
		{ "automation-science-pack", 1 },
		{ "logistic-science-pack", 1 },
	},
	time = 30,
}
data.raw.technology["worker-robots-speed-2"].prerequisites = { "worker-robots-speed-1", "robotics" }
data.raw.technology["worker-robots-storage-1"].prerequisites = { "basic-robots-robotics", "logistic-science-pack" }
data.raw.technology["worker-robots-storage-1"].unit = {
	count = 200,
	ingredients = {
		{ "automation-science-pack", 1 },
		{ "logistic-science-pack", 1 },
	},
	time = 30,
}
data.raw.technology["worker-robots-storage-2"].prerequisites = { "worker-robots-storage-1", "robotics" }
if mods["Krastorio2"] then
	data.raw.technology["basic-robots-robotics"].prerequisites = { "basic-logistics" }
	data.raw.recipe["basic-robots-construction-robot"].ingredients = {
		{ "automation-core", 5 },
		{ "electric-motor", 5 },
		{ "iron-plate", 10 },
	}
	data.raw.recipe["basic-robots-logistic-robot"].ingredients = {
		{ "automation-core", 5 },
		{ "electric-motor", 5 },
		{ "iron-plate", 10 },
	}
end
