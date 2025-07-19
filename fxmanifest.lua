fx_version 'cerulean'
game 'gta5'

name "takealot_delivery"
author "Filthy_Lytiez"
description 'TAKEALOT Delivery Job Script by Filthy_Lytiez'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@lation_ui/init.lua',--uncoment if you use lation ui
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

files {
    'stream/**/*.ydr',
    'stream/**/*.ytd',
    'stream/**/*.ytyp'
}

data_file 'DLC_ITYP_REQUEST' 'stream/bzzz_prop_gopostal_boxes.ytyp'

dependencies {
    'ox_lib'
}

lua54 'yes'