if mods["Krastorio2"] then
  -- don't change this to automation-core
  if data.raw.recipe["basic-robots-roboport"] then
    data.raw.recipe["basic-robots-roboport"].ingredients =
    {
        {"iron-plate", 45},
        {"iron-gear-wheel", 45},
        {"electronic-circuit", 45}
    }
  end
end
