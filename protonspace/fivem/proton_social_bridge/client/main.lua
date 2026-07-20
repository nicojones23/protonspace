RegisterNetEvent('proton_social_bridge:client:open', function(route)
  if type(route) ~= 'string' or route:find('javascript:', 1, true) then return end
  -- Deep-link delivery is intentionally inert until the signed CityOS ticket flow is configured.
  TriggerEvent('cityos_mobile:client:toast', 'ProtonSpace web login is not configured yet')
end)
