if mods["Krastorio2"] then
  -- don't change this to automation-core
  if data.raw.recipe["basic-robots-roboport"] then
    data.raw.recipe["basic-robots-roboport"].ingredients = {
      { type = "item", name = "iron-plate", amount = 45 },
      { type = "item", name = "iron-gear-wheel", amount = 45 },
      { type = "item", name = "electronic-circuit", amount = 45 },
    }
  end
end
