fx_version 'cerulean'

game 'gta5'

description 'Collectathon'

author 'Karl Saunders'

version '1.1.0'

shared_scripts {
    'config.lua',
    'utils.lua',
}

server_scripts {
    -- '@mysql-async/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}