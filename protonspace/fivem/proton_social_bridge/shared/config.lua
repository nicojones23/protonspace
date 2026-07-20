ProtonSocialBridgeConfig = {
  enabled = GetConvar('protonspace_bridge_enabled', 'false') == 'true',
  apiBase = GetConvar('protonspace_api_url', ''),
  apiSecret = GetConvar('protonspace_api_secret', ''),
  ticketTtlSeconds = 45,
  appId = 'protonspace',
}
