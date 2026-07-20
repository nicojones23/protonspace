fx_version 'cerulean'
game 'gta5'
name 'proton_social_bridge'
description 'Thin CityOS bridge for ProtonSpace identity, presence, notifications, and safe deep links'
version '0.1.0'
lua54 'yes'

shared_scripts { 'shared/config.lua' }
server_scripts { 'server/main.lua' }
client_scripts { 'client/main.lua' }
dependencies { 'qbx_core' }
