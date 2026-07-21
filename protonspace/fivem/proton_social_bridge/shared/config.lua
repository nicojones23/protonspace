ProtonSocialBridgeConfig = {
  enabled = GetConvar('protonspace_bridge_enabled', 'false') == 'true',
  apiBase = GetConvar('protonspace_api_url', ''),
  apiSecret = GetConvar('protonspace_api_secret', ''),
  webUrl = GetConvar('protonspace_web_url', 'https://protonspace.mhprotonspace.org/'),
  ticketTtlSeconds = 45,
  appId = 'proton',
}
