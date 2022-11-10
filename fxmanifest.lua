fx_version 'cerulean'
game 'gta5'

version '1.1.1'
repository 'https://github.com/QBCore-Remastered/qb-storerobbery'

ui_page 'html/index.html'

shared_scripts {
    'configs/default.lua',
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
    '@ox_lib/init.lua'
}

client_script 'client.lua'
server_script 'server.lua'

files {
    'html/index.html',
    'html/script.js',
    'html/style.css',
    'html/reset.css'
}

lua54 'yes'
