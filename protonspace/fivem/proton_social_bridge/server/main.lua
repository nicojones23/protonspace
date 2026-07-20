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

function ProtonSocialBridge.issueTicket(src)
  if not ProtonSocialBridgeConfig.enabled then return false, 'bridge_disabled' end
  local c = character(src)
  if not c.citizenId then return false, 'character_unavailable' end
  TriggerEvent('cityos_mobile:server:auditOnly', 'proton', 'ticket_requested', true, 'character=' .. tostring(c.citizenId))
  if ProtonSocialBridgeConfig.apiBase == '' or ProtonSocialBridgeConfig.apiSecret == '' then return false, 'api_ticket_exchange_not_configured' end
  local result, response
  PerformHttpRequest(ProtonSocialBridgeConfig.apiBase .. '/internal/cityos/tickets', function(status, body)
    result, response = status, body
  end, 'POST', json.encode({ citizenId = c.citizenId, characterName = c.characterName }), { ['Content-Type'] = 'application/json', ['X-CityOS-Ticket-Secret'] = ProtonSocialBridgeConfig.apiSecret })
  return true, 'ticket_request_queued'
end

exports('IssueTicket', ProtonSocialBridge.issueTicket)
