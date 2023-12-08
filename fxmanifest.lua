fx_version 'cerulean'
game 'gta5'

description 'qbx_storerobbery'
repository 'https://github.com/Qbox-project/qbx_storerobbery'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/utils.lua',
    '@qbx_core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
}

client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'html/index.html'

files {
    'config/client.lua',
    'config/shared.lua',
    'html/index.html',
    'html/script.js',
    'html/style.css',
    'html/reset.css'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
