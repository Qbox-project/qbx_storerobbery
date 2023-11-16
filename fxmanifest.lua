fx_version 'cerulean'
game 'gta5'

description 'QBX_Storerobbery'
repository 'https://github.com/Qbox-project/qbx_storerobbery'
version '1.1.1'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/utils.lua',
    '@qbx_core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
    'configs/default.lua',
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
use_experimental_fxv2_oal 'yes'