Config = {}
Config.Debug = false
Config.Framework = 'qbox'-- 'qbcore', 'qbox', or 'auto'
Config.Target = 'ox_target'-- Target system ('ox_target', 'qb-target')
Config.MaxActiveJobs = 5
Config.GlobalRouteCooldown = 30 -- minutes before same route can be taken again

Config.JobGiver = {
    model = 's_m_m_postal_01',
    coords = vec4(-407.04, 6149.18, 31.68, 229.2), 
    scenario = 'WORLD_HUMAN_CLIPBOARD',
    name = 'Marcus (Depot Manager)',
    label = 'Talk to Marcus - TAKEALOT Deliveries',
    icon = 'fa-solid fa-truck-fast',
    distance = 2.5
}

Config.Vehicle = {
    model = 'fltakealot', 
    spawn = vec4(-402.92, 6165.45, 31.52, 352.9),
    fuel = 100.0,
    platePrefix = "TAKEALOT"
}

Config.Packages = {
    props = {
        'bzzz_prop_custom_box_1a', 
        'bzzz_prop_custom_box_2a',   
        'bzzz_prop_custom_box_3a'     
    },
    carryAnim = {
        dict = 'anim@heists@box_carry@',
        clip = 'idle',
        flag = 49
    },
    collectTime = 2500,
    loadTime = 3000,
    label = 'Collect TAKEALOT Package',
    icon = 'fa-solid fa-box'
}

Config.DepotPackageArea = {
    center = vec3(-375.2, 6050.8, 31.5),
    spawns = {
        vec3(-431.74, 6159.83, 31.48),
        vec3(-429.55, 6161.57, 31.48),
        vec3(-426.84, 6164.64, 31.48),
        vec3(-423.78, 6167.61, 31.48),
        vec3(-419.6, 6171.66, 31.48),
        vec3(-423.89, 6174.83, 31.48),
        vec3(-432.74, 6165.32, 31.48),
        vec3(-446.46, 6144.57, 31.48),
        vec3(-440.55, 6148.24, 31.48),
        vec3(-437.44, 6145.98, 31.48),
        vec3(-434.84, 6162.78, 32.7),
        vec3(-426.42, 6171.41, 31.48),
        vec3(-421.0, 6173.76, 31.48),
        vec3(-424.4, 6170.07, 31.48),
        vec3(-446.93, 6141.3, 31.48),
        vec3(-444.14, 6144.31, 31.48),
        vec3(-433.76, 6142.3, 31.48),
        vec3(-442.98, 6143.72, 31.48),
        vec3(-411.37, 6180.71, 31.48),
        vec3(-412.83, 6175.06, 31.48),
    }
}

Config.DeliveryNPCs = {
    models = {
        's_m_m_postal_01', 
        's_f_y_airhostess_01', 
        's_m_y_construct_01',
        's_f_m_shop_high_01', 
        's_m_m_gardener_01',
        's_f_y_hooker_01', 
        's_m_y_dealer_01',   
        's_f_y_shop_low_01'    
    },
    scenarios = {
        'WORLD_HUMAN_STAND_MOBILE',
        'WORLD_HUMAN_CLIPBOARD',
        'WORLD_HUMAN_SMOKING',
        'WORLD_HUMAN_HANG_OUT_STREET'
    },
    dialogue = {
        greetings = {
            "Eish! My TAKEALOT finally pulled up, neh!",
            "Sho! Been waiting for this parcel like it's my SASSA payout!",
            "Dankie my broer, you came through like a champ!",
            "Aweh! I thought this thing got lost in the township post!",
            "Heita! Thats service with speed, madala!",
            "Wuuuuu! Youre saving lives out here, boss!",
            "Yoh! This is exactly what I needed to vibe right now!"
        },
        thanks = {
            "Safe trip, drive nice nice!",
            "Respect, you guys move like skopo on payday!",
            "TAKEALOT always on point, no cap!",
            "Big up to the crew — you okes are solid!",
            "Shot for the hookup, really appreciate it!",
            "Blessings on blessings! See you again soon!",
            "Next time, bring amagwinya too, haibo!"
        }
    },
    interactionDistance = 3.0,
    despawnTime = 30000, 
    label = 'Deliver Package',
    icon = 'fa-solid fa-handshake'
}


Config.DeliveryRoutes = {
    {
        id = 1,
        name = "Paleto Bay Residential",
        description = "Local neighborhood deliveries",
        packageCount = {min = 8, max = 12},
        payment = {min = 7500, max = 15000},
        difficulty = "Easy",
        estimatedTime = "15-20 minutes",
        color = "green",
        deliveries = {
            {name = "Road Side", coords = vec4(-1489.83, 4975.97, 62.72, 180.0), packages = {min = 1, max = 3}},
            {name = "Lumber Yard", coords = vec4(-580.212, 5332.702, 69.214, 90.0), packages = {min = 1, max = 3}},
            {name = "Chilliad State", coords = vec4(-1127.99, 4950.31, 219.62, 270.0), packages = {min = 1, max = 3}},
            {name = "Hookies", coords = vec4(-2172.81, 4282.06, 48.09, 45.0), packages = {min = 1, max = 2}},
            {name = "Zancudo", coords = vec4(-2305.41, 3427.35, 30.01, 135.0), packages = {min = 1, max = 2}}
        }
    },
    {
        id = 2,
        name = "Grapeseed Express", 
        description = "Rural farming community",
        packageCount = {min = 10, max = 15},
        payment = {min = 10500, max = 25000},
        difficulty = "Medium",
        estimatedTime = "20-25 minutes", 
        color = "blue",
        deliveries = {
            
            {name = "North Califa", coords = vec4(1339.64, 4310.98, 37.04, 261.85), packages = {min = 2, max = 4}},
            {name = "Grape Seed Main St", coords = vec4(1663.82, 4661.93, 42.39, 335.41), packages = {min = 1, max = 3}},
            {name = "Grape Seed Barn", coords = vec4(1898.86, 4925.85, 47.87, 238.69), packages = {min = 1, max = 3}},
            {name = "Grape Union Rd", coords = vec4(2439.41, 4976.05, 45.81, 244.39), packages = {min = 1, max = 3}},
            {name = "Catfish View", coords = vec4(3303.97, 5185.2, 18.71, 44.36), packages = {min = 1, max = 3}},
            
        }
    },
    {
        id = 3,
        name = "Sandy Shores Circuit",
        description = "Desert town deliveries", 
        packageCount = {min = 12, max = 18},
        payment = {min = 15500, max = 35000},
        difficulty = "Medium",
        estimatedTime = "25-30 minutes",
        color = "orange",
        deliveries = {
            {name = "Sandy Shores Motel", coords = vec4(1775.19, 3740.92, 33.65, 120.0), packages = {min = 2, max = 4}},
            {name = "Route 68", coords = vec4(59.19, 2795.27, 56.88, 270.0), packages = {min = 1, max = 3}},
            {name = "Trailer Park Office", coords = vec4(1975.1, 3815.99, 32.43, 45.0), packages = {min = 2, max = 3}},
            {name = "Auto Repair Shop", coords = vec4(1190.17, 2650.45, 36.84, 180.0), packages = {min = 1, max = 2}},
            {name = "Sandy Medical Center", coords = vec4(1822.56, 3688.55, 33.22, 90.0), packages = {min = 2, max = 4}},
            {name = "Desert Diner", coords = vec4(1469.87, 6543.12, 13.9, 225.0), packages = {min = 1, max = 2}},
            {name = "Mining Office", coords = vec4(2320.65, 2535.82, 46.56, 315.0), packages = {min = 1, max = 3}}
        }
    },
    {
        id = 4,
        name = "Highway Express",
        description = "Long distance highway route",
        packageCount = {min = 15, max = 22},
        payment = {min = 35500, max = 60000},
        difficulty = "Hard", 
        estimatedTime = "35-45 minutes",
        color = "red",
        deliveries = {
            {name = "Elgin Ave", coords = vec4(156.31, -1065.96, 29.05, 180.0), packages = {min = 3, max = 5}},
            {name = "Airport Cargo", coords = vec4(-941.11, -2954.42, 12.95, 90.0), packages = {min = 2, max = 4}},
            {name = "Port Authority", coords = vec4(861.52, -3183.9, 4.94, 270.0), packages = {min = 2, max = 3}},
            {name = "Downtown Office", coords = vec4(733.84, -1294.87, 26.04, 45.0), packages = {min = 1, max = 3}},
            {name = "Mirror Park Home", coords = vec4(1010.71, -423.36, 64.35, 304.0), packages = {min = 2, max = 4}},
            {name = "Burro Heights", coords = vec4(1576.92, -1685.7, 87.14, 225.0), packages = {min = 1, max = 2}},
            {name = "North Warehouse", coords = vec4(1248.85, -1737.43, 50.58, 315.0), packages = {min = 2, max = 3}},
            {name = "East Distribution", coords = vec4(849.57, -1995.26, 28.98, 180.0), packages = {min = 1, max = 2}}
        }
    },
    {
        id = 5,
        name = "Premium VIP Route",
        description = "High-value exclusive deliveries",
        packageCount = {min = 6, max = 12},
        payment = {min = 48500, max = 75500},
        difficulty = "VIP",
        estimatedTime = "20-30 minutes",
        color = "purple",
        deliveries = {
            {name = "Vinewood Hills", coords = vec4(-86.48, 834.84, 234.92, 90.0), packages = {min = 1, max = 2}},
            {name = "Eclipse Towers", coords = vec4(-773.37, 312.33, 84.7, 180.0), packages = {min = 1, max = 3}},
            {name = "Ritchman St", coords = vec4(-1733.22, 379.64, 88.73, 270.0), packages = {min = 1, max = 2}},
            {name = "Vinewood Hills 2", coords = vec4(-1032.97, 685.66, 160.3, 45.0), packages = {min = 1, max = 2}},
            {name = "Banham Canyon", coords = vec4(-3093.58, 349.51, 6.54, 273.0), packages = {min = 1, max = 2}},
            {name = "Chumash Beach House", coords = vec4(-1520.77, 849.43, 180.59, 25.0), packages = {min = 1, max = 2}}
        }
    }
}

Config.VehicleSettings = {
    FuelScript = 'lc_fuel',-- 'lc_fuel', 'ox_fuel', 'ps-fuel', 'cdn-fuel', or nil
    KeysScript = 'qb-vehiclekeys',-- 'qb-vehiclekeys', 'wasabi_carlock', 'cd_keys'
    SpawnInVehicle = false,
    DirtLevel = 0.0,
    EngineOn = true
}

Config.Notifications = {
    routeOnCooldown = "Aweh, that route is closed for now. Chill a bit, come back later.",
    jobActive = "Hao mfethu! You already doing a run. Finish that one first.",
    noVehicle = "You need to be inside your skadonk to make that drop, dawg.",
    packageCollected = "Sharp! You picked up the stuff, now pack it in your ride.",
    allPackagesLoaded = "Everythings packed, grootman. Time to make those moves!",
    deliveryComplete = "Sick drop, boss! Youre killing this delivery game.",
    routeComplete = "Thats the whole route! Pull up at the depot for your payday.",
    jobCompleted = "Yoh! You smashed that! 💸 You just got paid: $%s",
    jobCancelled = "Deliverys been shut down. We took your whip back to the depot.",
    vehicleRequired = "Stand close to your bakkie or dont even try load, fam.",
    packageDelivered = "Package dropped like a hot kota, respect!",
    wrongLocation = "Nah gents, this ain't the spot. Check your GPS again."
}

Config.DialogueOptions = {
    welcome = {
        "Sho! Welcome to the TAKEALOT depo here ePaleto, king!",
        "If you got hands and hustle, we got routes for you, broer.",
        "Each route? Different kinda beast. The harder the drive, the phatter the pay.",
        "Finish the job clean, come back here, and get that mula!",
        "Dont be reckless — some routes are still cooking. Wait your turn, ouens!"
    },
    completion = {
        "Eyyy, you handled those drops like a real kasi delivery plug!",
        "Our clients are happy-happy, even left you some five-star vibes!",
        "Cash dropped in your account, just like that. 💰 Mooi neh?",
        "If the hustle calls again, you know where to pull up!",
        "Keep the customers happy — no one likes a salty driver!"
    }
}

-- =============================================================================
-- FRAMEWORK DETECTION FUNCTION DONT FUCKEN TOUCH
-- =============================================================================
function Config.GetFramework()
    if Config.Framework == 'auto' then
        if GetResourceState('qb-core') == 'started' then
            return 'qbcore'
        elseif GetResourceState('qbx_core') == 'started' then
            return 'qbox'
        else
            return 'qbcore' 
        end
    else
        return Config.Framework
    end
end