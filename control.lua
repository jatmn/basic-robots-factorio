local util = require("util")

function add_start_items(player)
  if not global.added_start_items then
    global.added_start_items = {}
  end
  if not global.added_start_items[player.index] and settings.global["basic-robots-starter-equipment"].value then
    global.added_start_items[player.index] = true
    -- util.insert_safe(player, start_items)
    player.insert{name="light-armor", count=1}
    player.insert{name="basic-robots-construction-robot", count=15}
    
    local inv = player.character.get_inventory(defines.inventory.character_armor)
    if inv then
      local armor = inv[1]
      if armor and armor.grid then
        armor.grid.clear()
        armor.grid.put{name="basic-robots-personal-roboport-equipment"}
        local holder = armor.grid.put{name="basic-robots-battery-holder-equipment"}
        if holder.burner then
          holder.burner.inventory.insert{name="basic-robots-single-use-battery", count=50}
        end
      end
    end
  end
end
script.on_event(defines.events.on_player_created, function (event)
  local player = game.players[event.player_index]
  if player.character then
    add_start_items(player)
  end
end)
script.on_event(defines.events.on_cutscene_cancelled, function (event)
  local player = game.players[event.player_index]
  if player.character then
    add_start_items(player)
  end
end)
