ProtonSocialBridge = ProtonSocialBridge or {}

local function character(src)
  local player = exports.qbx_core:GetPlayer(src)
  local data = player and player.PlayerData or {}
  local char = data.charinfo or {}
  return {
    citizenId = data.citizenid,
    characterName = ((char.firstname or '') .. ' ' .. (char.lastname or '')):gsub('^%s+', ''):gsub('%s+$', ''),
    job = data.job and data.job.name or nil,
    source = src,
  }
end

local function discordId(src)
  for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
    local value = identifier:match('^discord:(.+)$')
    if value then return value end
  end
  return nil
end

function ProtonSocialBridge.issueTicket(src)
  if not ProtonSocialBridgeConfig.enabled then return false, 'bridge_disabled' end
  local c = character(src)
  if not c.citizenId then return false, 'character_unavailable' end
  TriggerEvent('cityos_mobile:server:auditOnly', 'proton', 'ticket_requested', true, 'character=' .. tostring(c.citizenId))
  if ProtonSocialBridgeConfig.apiBase == '' or ProtonSocialBridgeConfig.apiSecret == '' then return false, 'api_ticket_exchange_not_configured' end
  local result, response
  PerformHttpRequest(ProtonSocialBridgeConfig.apiBase .. '/internal/cityos/tickets', function(status, body)
    result, response = status, body
    if status < 200 or status >= 300 then
      TriggerClientEvent('proton_social_bridge:client:error', src, 'ticket request failed (' .. tostring(status) .. ')')
      return
    end
    local ok, decoded = pcall(json.decode, body or '')
    if not ok or type(decoded) ~= 'table' or type(decoded.ticket) ~= 'string' then
      TriggerClientEvent('proton_social_bridge:client:error', src, 'invalid ticket response')
      return
    end
    local base = ProtonSocialBridgeConfig.webUrl:gsub('/$', '')
    TriggerClientEvent('cityos_mobile:client:browserOpen', src, {
      ok = true,
      appId = ProtonSocialBridgeConfig.appId,
      manifest = {
        id = ProtonSocialBridgeConfig.appId,
        name = 'ProtonSpace',
        icon = 'PS',
        launch = { type = 'browser' },
        browser = { source = 'absolute', route = base .. '/?surface=game&ticket=' .. decoded.ticket .. '&v=' .. tostring(os.time()), mode = 'contained' },
      },
    })
    print(('[proton_social_bridge] browser handoff delivered src=%s'):format(tostring(src)))
  end, 'POST', json.encode({ citizenId = c.citizenId, characterName = c.characterName, discordId = discordId(src), serverKey = 'most_hated_rp' }), { ['Content-Type'] = 'application/json', ['X-CityOS-Ticket-Secret'] = ProtonSocialBridgeConfig.apiSecret })
  return true, 'ticket_request_queued'
end

exports('IssueTicket', ProtonSocialBridge.issueTicket)

RegisterNetEvent('proton_social_bridge:server:requestTicket', function()
  local src = source
  local ok, reason = ProtonSocialBridge.issueTicket(src)
  if not ok then TriggerClientEvent('proton_social_bridge:client:error', src, reason) end
end)

RegisterNetEvent('proton_social_bridge:server:clientStage', function(stage, detail)
  print(('[proton_social_bridge] client stage src=%s stage=%s detail=%s'):format(tostring(source), tostring(stage), tostring(detail or '')))
end)
