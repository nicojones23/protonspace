RegisterNetEvent('proton_social_bridge:client:open', function(route)
  if type(route) ~= 'string' or route:find('javascript:', 1, true) then return end
  TriggerServerEvent('proton_social_bridge:server:requestTicket')
end)

RegisterNetEvent('proton_social_bridge:client:ticket', function(ticket)
  if type(ticket) ~= 'string' or ticket == '' then
    TriggerEvent('cityos_mobile:client:toast', 'ProtonSpace identity link failed')
    return
  end
  local base = ProtonSocialBridgeConfig.webUrl:gsub('/$', '')
  TriggerEvent('cityos_mobile:client:browserOpen', {
    ok = true,
    appId = ProtonSocialBridgeConfig.appId,
    manifest = {
      id = ProtonSocialBridgeConfig.appId,
      name = 'ProtonSpace',
      icon = 'PS',
      launch = { type = 'browser' },
      browser = { source = 'absolute', route = base .. '/?surface=game&ticket=' .. ticket .. '&v=' .. tostring(GetGameTimer()), mode = 'contained' },
    },
  })
end)

RegisterNetEvent('proton_social_bridge:client:error', function(reason)
  TriggerEvent('cityos_mobile:client:toast', 'ProtonSpace: ' .. tostring(reason or 'bridge unavailable'))
end)
