
local Framework = nil
local PlayerData = {}
local ActiveJob = nil
local DepotManagerPed = nil
local DeliveryVehicle = nil
local CarriedPackage = nil
local Packages = {}
local PackageBlips = {}
local CurrentDeliveryBlip = nil
local ReturnBlip = nil


local function DebugPrint(message)
    if Config.Debug then
        lib.print.info('[TAKEALOT_DELIVERY] ' .. tostring(message))
    end
end

local function GetFrameworkObject()
    local fw = Config.GetFramework()
    if fw == 'qbox' then
        Framework = exports.qbx_core
        PlayerData = exports.qbx_core:GetPlayerData()
        return exports.qbx_core
    else
        Framework = exports['qb-core']:GetCoreObject()
        PlayerData = Framework.Functions.GetPlayerData()
        return Framework
    end
end

local function ShowNotification(message, type, duration)
    if Config.GetFramework() == 'qbox' then
        exports.qbx_core:Notify(message, type or 'inform', duration or 5000)
    else
        Framework.Functions.Notify(message, type or 'primary', duration or 5000)
    end
end

CreateThread(function()
    GetFrameworkObject()
    Wait(1000)
    SpawnDepotManager()
    
    local frameworkEvents = Config.GetFramework() == 'qbox' and {
        playerLoaded = 'QBCore:Client:OnPlayerLoaded',
        jobUpdate = 'QBCore:Client:OnJobUpdate'
    } or {
        playerLoaded = 'QBCore:Client:OnPlayerLoaded',
        jobUpdate = 'QBCore:Client:OnJobUpdate'
    }
    
    RegisterNetEvent(frameworkEvents.playerLoaded, function()
        PlayerData = Config.GetFramework() == 'qbox' and exports.qbx_core:GetPlayerData() or Framework.Functions.GetPlayerData()
    end)
    
    RegisterNetEvent(frameworkEvents.jobUpdate, function(job)
        PlayerData.job = job
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    CleanupJob()
    if DepotManagerPed then
        DeletePed(DepotManagerPed)
    end
end)

function SpawnDepotManager()
    local coords = Config.JobGiver.coords
    
    lib.requestModel(Config.JobGiver.model, 10000)
    DepotManagerPed = CreatePed(4, Config.JobGiver.model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
 
    TaskStartScenarioInPlace(DepotManagerPed, Config.JobGiver.scenario, 0, true)
    SetEntityInvincible(DepotManagerPed, true)
    SetBlockingOfNonTemporaryEvents(DepotManagerPed, true)
    FreezeEntityPosition(DepotManagerPed, true)
   
    local blip = AddBlipForEntity(DepotManagerPed)
    SetBlipSprite(blip, 616)
    SetBlipColour(blip, 3)
    SetBlipScale(blip, 0.9)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('TAKEALOT Depot - Marcus')
    EndTextCommandSetBlipName(blip)
    
    if Config.Target == 'ox_target' then
        exports.ox_target:addLocalEntity(DepotManagerPed, {
            {
                name = 'takealot_depot_menu',
                label = Config.JobGiver.label,
                icon = Config.JobGiver.icon,
                distance = Config.JobGiver.distance,
                onSelect = function()
                    ShowDepotMenu()
                end,
            }
        })
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:AddTargetEntity(DepotManagerPed, {
            options = {
                {
                    type = "client",
                    event = "takealot_delivery:client:showMenu",
                    icon = Config.JobGiver.icon,
                    label = Config.JobGiver.label,
                }
            },
            distance = Config.JobGiver.distance
        })
    end
    
    DebugPrint('TAKEALOT Depot Manager spawned successfully')
end

function ShowDepotMenu()
    if lib.progressCircle({
        duration = 1500,
        position = 'bottom',
        label = 'Talking to Marcus...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true,
        },
        anim = {
            dict = 'oddjobs@assassinate@vice@hooker',
            clip = 'argue_a',
        },
    }) then
        CreateDepotContextMenu()
    end
end

function CreateDepotContextMenu()
    local routeCooldowns = lib.callback.await('takealot_delivery:server:getRouteCooldowns', false)
    local activeJobCount = lib.callback.await('takealot_delivery:server:getActiveJobCount', false)
    
    local menuOptions = {
        {
            title = '🚚 TAKEALOT Paleto Depot',
            icon = 'fas fa-truck-fast',
            iconColor = 'FF383838',
            description = 'Professional package delivery services',
            readOnly = true,
            metadata = {
                '📊 Active Drivers: ' .. activeJobCount .. '/' .. Config.MaxActiveJobs,
                '👨‍💼 Depot Manager: Marcus',
                '🏢 Professional Delivery Services',
                '⭐ Established 2024'
            }
        }
    }
    
    if not ActiveJob then
        table.insert(menuOptions, {
            title = '📦 Available Delivery Routes',
            icon = 'fas fa-route',
            iconColor = 'FF442626',
            description = 'Choose your delivery route wisely',
            readOnly = true,
            colorScheme = 'blue'
        })
        
        for _, route in ipairs(Config.DeliveryRoutes) do
            local isOnCooldown = routeCooldowns[route.id] and routeCooldowns[route.id] > 0
            local routeIcon, routeIconColor = GetRouteIconAndColor(route.difficulty, isOnCooldown)
            
            table.insert(menuOptions, {
                title = '🚛 ' .. route.name,
                icon = routeIcon,
                iconColor = routeIconColor,
                iconAnimation = isOnCooldown and 'spin' or nil,
                description = '📝 ' .. route.description,
                colorScheme = isOnCooldown and 'red' or route.color,
                disabled = isOnCooldown,
                onSelect = function()
                    StartRouteConfirmation(route)
                end,
                metadata = BuildRouteMetadata(route, isOnCooldown, routeCooldowns[route.id])
            })
        end
    else
        BuildActiveJobOptions(menuOptions)
    end
    
    lib.registerContext({
        id = 'takealot_depot_menu',
        title = '🚚 TAKEALOT Delivery Services',
        options = menuOptions
    })
    
    lib.showContext('takealot_depot_menu')
end

function GetRouteIconAndColor(difficulty, isOnCooldown)
    if isOnCooldown then
        return 'fas fa-clock', '#E74C3C'
    end
    
    local icons = {
        Easy = { 'fas fa-smile', '#2ECC71' },
        Medium = { 'fas fa-meh', '#F39C12' },
        Hard = { 'fas fa-frown', '#E74C3C' },
        VIP = { 'fas fa-crown', '#9B59B6' }
    }
    
    return table.unpack(icons[difficulty] or { 'fas fa-route', '#2ECC71' })
end

function BuildRouteMetadata(route, isOnCooldown, cooldownTime)
    local packageText, paymentText
    
    if type(route.packageCount) == "table" then
        packageText = route.packageCount.min .. "-" .. route.packageCount.max
    else
        packageText = tostring(route.packageCount)
    end
    
    if type(route.payment) == "table" then
        paymentText = "$" .. route.payment.min .. "-$" .. route.payment.max
    else
        paymentText = "$" .. route.payment
    end
    
    local metadata = {
        '📦 Packages: ' .. packageText,
        '💰 Payment: ' .. paymentText,
        '⚡ Difficulty: ' .. route.difficulty,
        '⏱️ Time: ' .. route.estimatedTime,
        '🎯 Deliveries: ' .. #route.deliveries,
    }
    
    if isOnCooldown then
        local minutes = math.ceil(cooldownTime / 60)
        table.insert(metadata, "⏰ Cooldown: " .. minutes .. " minutes")
    else
        table.insert(metadata, '✅ Available Now')
    end
    
    return metadata
end

function BuildActiveJobOptions(menuOptions)
    if ActiveJob.stage == 'return' then
        table.insert(menuOptions, {
            title = '✅ Complete Delivery Job',
            icon = 'fas fa-clipboard-check',
            iconColor = '#2ECC71',
            description = '🏁 Return vehicle and receive payment',
            colorScheme = 'green',
            onSelect = function()
                CompleteJobConfirmation()
            end,
            metadata = {
                '🚛 Route: ' .. ActiveJob.routeName,
                '💰 Payment: $' .. ActiveJob.payment,
                '📊 Status: Ready for completion',
                '🎉 Well done!'
            }
        })
    else
        table.insert(menuOptions, {
            title = '⏳ Job in Progress',
            icon = 'fas fa-hourglass-half',
            iconColor = '#3498DB',
            iconAnimation = 'spin',
            description = '📊 Current delivery status',
            disabled = true,
            colorScheme = 'blue',
            metadata = BuildJobProgressMetadata()
        })
        
        table.insert(menuOptions, {
            title = '❌ Cancel Current Job',
            icon = 'fas fa-times-circle',
            iconColor = '#E74C3C',
            description = '🚫 Cancel delivery job (no payment)',
            colorScheme = 'red',
            onSelect = function()
                CancelJobDialog()
            end,
            metadata = {
                '⚠️ Warning: No payment will be given',
                '🚗 Vehicle will be reclaimed',
                '💔 Progress will be lost'
            }
        })
    end
end

function BuildJobProgressMetadata()
    return {
        '🚛 Route: ' .. ActiveJob.routeName,
        '📈 Stage: ' .. string.upper(ActiveJob.stage),
        ActiveJob.packagesCollected and ('📦 Progress: ' .. ActiveJob.packagesCollected .. '/' .. ActiveJob.totalPackages) or '🔄 In Progress',
        ActiveJob.deliveriesCompleted and ('🎯 Deliveries: ' .. ActiveJob.deliveriesCompleted .. '/' .. #ActiveJob.deliveries) or '📋 Loading'
    }
end

function StartRouteConfirmation(route)
    local packageText, paymentText
    
    if type(route.packageCount) == "table" then
        packageText = route.packageCount.min .. "-" .. route.packageCount.max
    else
        packageText = tostring(route.packageCount)
    end
    
    if type(route.payment) == "table" then
        paymentText = "$" .. route.payment.min .. "-$" .. route.payment.max
    else
        paymentText = "$" .. route.payment
    end
    
    local deliveryList = ""
    for i, delivery in ipairs(route.deliveries) do
        deliveryList = deliveryList .. i .. ". " .. delivery.name .. "\n"
    end
    
    local alert = lib.alertDialog({
        header = 'Confirm Delivery Route',
        content = string.format([[
**Route:** %s
**Description:** %s
**Packages:** %s
**Deliveries:** %s locations
**Payment:** %s
**Difficulty:** %s
**Estimated Time:** %s

**Delivery Locations:**
%s
Ready to start this delivery route?
        ]], route.name, route.description, packageText, #route.deliveries, paymentText, route.difficulty, route.estimatedTime, deliveryList),
        centered = true,
        cancel = true,
        labels = {
            cancel = 'Not Ready',
            confirm = 'Start Route'
        }
    })
    
    if alert == 'confirm' then
        TriggerServerEvent('takealot_delivery:server:startJob', route.id)
    end
end

function CompleteJobConfirmation()
    if not DeliveryVehicle or not DoesEntityExist(DeliveryVehicle) then
        lib.notify({
            title = 'Vehicle Required',
            description = 'You need to return in your delivery vehicle',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    local vehicleCoords = GetEntityCoords(DeliveryVehicle)
    local distance = #(playerCoords - vehicleCoords)
    
    if distance > 10.0 then
        lib.notify({
            title = 'Vehicle Too Far',
            description = 'Get closer to your delivery vehicle',
            type = 'error',
            duration = 5000
        })
        return
    end
    
    local alert = lib.alertDialog({
        header = 'Complete Delivery Job',
        content = string.format([[
**Route Completed:** %s
**Payment:** $%s

Ready to complete your delivery job and receive payment?
        ]], ActiveJob.routeName, ActiveJob.payment),
        centered = true,
        cancel = true,
        labels = {
            cancel = 'Not Yet',
            confirm = 'Complete Job'
        }
    })
    
    if alert == 'confirm' then
        TriggerServerEvent('takealot_delivery:server:completeJob', ActiveJob.id)
    end
end

function CancelJobDialog()
    local alert = lib.alertDialog({
        header = 'Cancel Delivery Job',
        content = 'Are you sure you want to cancel your current delivery job? You will not receive any payment and the vehicle will be reclaimed.',
        centered = true,
        cancel = true,
        labels = {
            cancel = 'Keep Job',
            confirm = 'Cancel Job'
        }
    })

    if alert == 'confirm' then
        TriggerServerEvent('takealot_delivery:server:cancelJob', ActiveJob.id)
    end
end

RegisterNetEvent('takealot_delivery:client:jobStarted', function(jobData)
    ActiveJob = jobData
    ActiveJob.stage = 'spawn_vehicle'
    ActiveJob.packagesCollected = 0
    ActiveJob.deliveriesCompleted = 0
    
    DebugPrint('Delivery job started: ' .. json.encode(jobData))
    
    SpawnDeliveryVehicle()
    ShowJobBriefing()
end)

function ShowJobBriefing()
    local briefing = table.concat(Config.DialogueOptions.welcome, '\n\n')
    
    lib.alertDialog({
        header = 'Delivery Briefing - ' .. Config.JobGiver.name,
        content = briefing .. '\n\nRoute: ' .. ActiveJob.routeName .. '\nPackages: ' .. ActiveJob.totalPackages,
        centered = true,
        cancel = false
    })
    
    ShowNotification('Vehicle spawned! Load packages and start your deliveries', 'inform', 8000)
end

function SpawnDeliveryVehicle()
    local spawnCoords = Config.Vehicle.spawn
    
    SpawnVehicleWithSetup({
        model = Config.Vehicle.model,
        coords = spawnCoords,
        label = 'TAKEALOT Delivery Van',
        callback = function(vehicle)
            DeliveryVehicle = vehicle
            ActiveJob.stage = 'load_packages'
            SpawnPackages()
            CreateVehicleLoadZone()
            DebugPrint('Delivery vehicle spawned successfully')
        end
    })
end

function SpawnVehicleWithSetup(data)
    local spawnCoords = data.coords
    local settings = Config.VehicleSettings
    
    if not spawnCoords or not spawnCoords.x then
        ShowNotification('Config Error: Invalid spawn coordinates', 'error')
        return
    end
    
    local x, y, z, w = spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w
    
    local oldVeh = GetClosestVehicle(x, y, z, 3.0, 0, 71)
    if oldVeh ~= 0 then
        ShowNotification('Spawn Blocked: Move vehicle from spawn point', 'error')
        return
    end
    
    lib.requestModel(data.model, 10000)
    
    local vehicle = CreateVehicle(GetHashKey(data.model), x, y, z, w, true, false)
    
    local timeout = 0
    while not DoesEntityExist(vehicle) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not DoesEntityExist(vehicle) then
        ShowNotification('Spawn Failed: Failed to create vehicle', 'error')
        return
    end
    
    local plateNumber = tostring(math.random(100, 999))
    local plate = Config.Vehicle.platePrefix .. plateNumber
    
    SetVehicleNumberPlateText(vehicle, plate)
    SetEntityHeading(vehicle, w)
    SetEntityAsMissionEntity(vehicle, true, true)
    
    if settings.SpawnInVehicle then
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end
    
    SetupVehicleFuelAndKeys(vehicle, settings)
    
    SetVehicleEngineOn(vehicle, settings.EngineOn or true, true, false)
    SetVehicleDirtLevel(vehicle, settings.DirtLevel or 0.0)
    
    ShowNotification(data.label .. ' spawned - Plate: ' .. plate, 'success')
    
    if data.callback then
        data.callback(vehicle)
    end
    
    return vehicle
end

function SetupVehicleFuelAndKeys(vehicle, settings)
    local fuelLevel = Config.Vehicle.fuel
    
    if settings.FuelScript and GetResourceState(settings.FuelScript) == 'started' then
        local fuelExports = {
            lc_fuel = function() exports.lc_fuel:SetFuel(vehicle, fuelLevel) end,
            ox_fuel = function() Entity(vehicle).state.fuel = fuelLevel end,
            ['ps-fuel'] = function() exports['ps-fuel']:SetFuel(vehicle, fuelLevel) end,
            ['cdn-fuel'] = function() exports['cdn-fuel']:SetFuel(vehicle, fuelLevel) end
        }
        
        if fuelExports[settings.FuelScript] then
            fuelExports[settings.FuelScript]()
        end
    else
        SetVehicleFuelLevel(vehicle, fuelLevel)
    end
   
    local vehiclePlate = GetVehicleNumberPlateText(vehicle)
    if settings.KeysScript and GetResourceState(settings.KeysScript) == 'started' then
        local keyExports = {
            ['qb-vehiclekeys'] = function() TriggerEvent("vehiclekeys:client:SetOwner", vehiclePlate) end,
            wasabi_carlock = function() exports.wasabi_carlock:GiveKey(vehiclePlate) end,
            cd_garage = function() TriggerEvent('cd_garage:AddKeys', exports.cd_garage:GetPlate(vehicle)) end
        }
        
        if keyExports[settings.KeysScript] then
            keyExports[settings.KeysScript]()
        end
    else
        TriggerEvent("vehiclekeys:client:SetOwner", vehiclePlate)
    end
end

function CreateVehicleLoadZone()
    if not DeliveryVehicle or not DoesEntityExist(DeliveryVehicle) then return end
    
    DebugPrint('Setting up vehicle target for package loading')
    
    if Config.Target == 'ox_target' then
        exports.ox_target:addLocalEntity(DeliveryVehicle, {
            {
                name = 'load_package_vehicle',
                label = 'Load Package',
                icon = 'fa-solid fa-box-open',
                distance = 4.0,
                canInteract = function()
                    return ActiveJob and ActiveJob.stage == 'load_packages' and CarriedPackage and DoesEntityExist(CarriedPackage)
                end,
                onSelect = function()
                    LoadPackage()
                end,
            }
        })
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:AddTargetEntity(DeliveryVehicle, {
            options = {
                {
                    type = "client",
                    event = "takealot_delivery:client:loadPackage",
                    icon = 'fa-solid fa-box-open',
                    label = 'Load Package',
                    canInteract = function()
                        return ActiveJob and ActiveJob.stage == 'load_packages' and CarriedPackage and DoesEntityExist(CarriedPackage)
                    end
                }
            },
            distance = 4.0
        })
    end
    
    DebugPrint('Vehicle target setup completed')
end

function SpawnPackages()
    if not ActiveJob then return end
    
    Packages = {}
    PackageBlips = {}
    
    local packageSpawns = Config.DepotPackageArea.spawns
    
    local totalPackages = ActiveJob.totalPackages
    if type(totalPackages) == "table" then
        totalPackages = totalPackages.min or 1
        DebugPrint('WARNING: totalPackages was a table, using min value: ' .. totalPackages)
    end
    
    for i = 1, totalPackages do
        if packageSpawns[i] then
            local coords = packageSpawns[i]
            local randomProp = Config.Packages.props[math.random(1, #Config.Packages.props)]
            
            lib.requestModel(randomProp, 5000)
            local package = CreateObject(randomProp, coords.x, coords.y, coords.z, true, false, true)
            PlaceObjectOnGroundProperly(package)
            
            Packages[i] = {
                object = package,
                coords = GetEntityCoords(package),
                collected = false,
                prop = randomProp
            }
            
            CreatePackageBlip(package, i)
            SetupPackageTarget(package, i)
        end
    end
    
    DebugPrint('Spawned ' .. #Packages .. ' packages at depot warehouse')
end

function CreatePackageBlip(package, index)
    local blip = AddBlipForEntity(package)
    SetBlipSprite(blip, 478)
    SetBlipColour(blip, 2)
    SetBlipScale(blip, 0.7)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('TAKEALOT Package')
    EndTextCommandSetBlipName(blip)
    PackageBlips[index] = blip
end

function SetupPackageTarget(package, index)
    if Config.Target == 'ox_target' then
        exports.ox_target:addLocalEntity(package, {
            name = 'collect_package_' .. index,
            label = Config.Packages.label,
            icon = Config.Packages.icon,
            distance = 3.0,
            canInteract = function()
                return not Packages[index].collected and not CarriedPackage
            end,
            onSelect = function()
                CollectPackage(index)
            end,
        })
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:AddTargetEntity(package, {
            options = {
                {
                    type = "client",
                    event = "takealot_delivery:client:collectPackage",
                    icon = Config.Packages.icon,
                    label = Config.Packages.label,
                    canInteract = function()
                        return not Packages[index].collected and not CarriedPackage
                    end,
                    packageIndex = index
                }
            },
            distance = 3.0
        })
    end
end

function CollectPackage(index)
    if CarriedPackage or Packages[index].collected then return end
    
    local package = Packages[index]
    if not DoesEntityExist(package.object) then return end
    
    if lib.progressCircle({
        duration = Config.Packages.collectTime,
        label = 'Collecting package...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'pickup_object',
            clip = 'pickup_low',
        },
    }) then
        ProcessPackageCollection(index, package)
    end
end

function ProcessPackageCollection(index, package)
    Packages[index].collected = true
    DeleteEntity(package.object)
    RemoveBlip(PackageBlips[index])
    
    if Config.Target == 'ox_target' then
        exports.ox_target:removeLocalEntity(package.object, 'collect_package_' .. index)
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:RemoveTargetEntity(package.object)
    end
    
    CarriedPackage = CreateObject(package.prop, 0, 0, 0, true, true, true)
    AttachEntityToEntity(CarriedPackage, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 60309), 0.025, 0.08, 0.255, -145.0, 290.0, 0.0, true, true, false, true, 1, true)
    
    lib.requestAnimDict(Config.Packages.carryAnim.dict)
    TaskPlayAnim(PlayerPedId(), Config.Packages.carryAnim.dict, Config.Packages.carryAnim.clip, 8.0, 8.0, -1, Config.Packages.carryAnim.flag, 0, false, false, false)
    
    ActiveJob.packagesCollected = ActiveJob.packagesCollected + 1
    
    ShowNotification(Config.Notifications.packageCollected, 'success')
    DebugPrint('Package collected. Progress: ' .. ActiveJob.packagesCollected .. '/' .. ActiveJob.totalPackages)
end

function LoadPackage()
    if not CarriedPackage then return end
    
    if lib.progressCircle({
        duration = Config.Packages.loadTime,
        label = 'Loading package into vehicle...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'pickup_object',
            clip = 'putdown_low',
        },
    }) then
        DeleteEntity(CarriedPackage)
        CarriedPackage = nil
        ClearPedTasks(PlayerPedId())
        
        ShowNotification('Package loaded successfully!', 'success')
        
        if ActiveJob.packagesCollected >= ActiveJob.totalPackages then
            AllPackagesLoaded()
        else
            local remaining = ActiveJob.totalPackages - ActiveJob.packagesCollected
            ShowNotification('Packages remaining: ' .. remaining .. '. Continue collecting!', 'inform', 5000)
        end
    end
end

function AllPackagesLoaded()
    ActiveJob.stage = 'delivering'
    ActiveJob.currentDeliveryIndex = 1
    
    ShowNotification(Config.Notifications.allPackagesLoaded, 'success', 8000)
    CreateDeliveryBlip()
    DebugPrint('All packages loaded, starting delivery route')
end

function CreateDeliveryBlip()
    if not ActiveJob or not ActiveJob.deliveries or not ActiveJob.deliveries[ActiveJob.currentDeliveryIndex] then return end
    
    local delivery = ActiveJob.deliveries[ActiveJob.currentDeliveryIndex]
    local coords = delivery.coords
    
    local blipX, blipY, blipZ
    if coords.w then 
        blipX, blipY, blipZ = coords.x, coords.y, coords.z
    else 
        blipX, blipY, blipZ = coords.x, coords.y, coords.z
    end
    
    CurrentDeliveryBlip = AddBlipForCoord(blipX, blipY, blipZ)
    SetBlipSprite(CurrentDeliveryBlip, 501)
    SetBlipColour(CurrentDeliveryBlip, 3)
    SetBlipScale(CurrentDeliveryBlip, 1.0)
    SetBlipRoute(CurrentDeliveryBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Delivery: ' .. delivery.name)
    EndTextCommandSetBlipName(CurrentDeliveryBlip)
    
    CreateDeliveryZone()
    DebugPrint('Delivery blip created for: ' .. delivery.name)
end

function CreateDeliveryZone()
    if not ActiveJob or not ActiveJob.deliveries or not ActiveJob.deliveries[ActiveJob.currentDeliveryIndex] then return end
    
    local delivery = ActiveJob.deliveries[ActiveJob.currentDeliveryIndex]
    local coords = delivery.coords
    local zoneX, zoneY, zoneZ
    if coords.w then 
        zoneX, zoneY, zoneZ = coords.x, coords.y, coords.z
    else 
        zoneX, zoneY, zoneZ = coords.x, coords.y, coords.z
    end
    
    local deliveryZone = lib.zones.sphere({
        coords = vec3(zoneX, zoneY, zoneZ),
        radius = 25.0,
        debug = Config.Debug,
        onEnter = function()
            if ActiveJob and ActiveJob.stage == 'delivering' then
                StartDeliveryProcess()
            end
        end
    })
    
    ActiveJob.deliveryZone = deliveryZone
end
function StartDeliveryProcess()
    if ActiveJob.stage ~= 'delivering' then return end
    
    local delivery = ActiveJob.deliveries[ActiveJob.currentDeliveryIndex]
    local playerCoords = GetEntityCoords(PlayerPedId())
    local vehicleCoords = GetEntityCoords(DeliveryVehicle)
    local distance = #(playerCoords - vehicleCoords)
    
    if distance > 25.0 then
        ShowNotification('Get closer to your delivery vehicle to start the delivery process', 'error')
        return
    end
    
    RemoveBlip(CurrentDeliveryBlip)
    if ActiveJob.deliveryZone then
        ActiveJob.deliveryZone:remove()
    end
    
    ActiveJob.stage = 'collecting_from_vehicle'
    ShowNotification('Exit your vehicle and collect the package from the back', 'inform', 5000)
    
    SpawnDeliveryNPC(delivery)
    Wait(1000)
    MonitorVehicleCollection()
    
    DebugPrint('Started delivery process for: ' .. delivery.name)
end

function MonitorVehicleCollection()
    if not DeliveryVehicle or not DoesEntityExist(DeliveryVehicle) then return end
    
    DebugPrint('Setting up vehicle target for package collection')
    
    if Config.Target == 'ox_target' then
        exports.ox_target:addLocalEntity(DeliveryVehicle, {
            {
                name = 'collect_package_vehicle',
                label = 'Collect Package from Vehicle',
                icon = 'fa-solid fa-hand-holding-box',
                distance = 4.0,
                canInteract = function()
                    return ActiveJob and ActiveJob.stage == 'collecting_from_vehicle' and not CarriedPackage
                end,
                onSelect = function()
                    CollectPackageFromVehicle()
                end,
            }
        })
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:AddTargetEntity(DeliveryVehicle, {
            options = {
                {
                    type = "client",
                    event = "takealot_delivery:client:collectFromVehicle",
                    icon = 'fa-solid fa-hand-holding-box',
                    label = 'Collect Package from Vehicle',
                    canInteract = function()
                        return ActiveJob and ActiveJob.stage == 'collecting_from_vehicle' and not CarriedPackage
                    end
                }
            },
            distance = 4.0
        })
    end
    
    DebugPrint('Vehicle collection target setup completed')
end

function CollectPackageFromVehicle()
    if CarriedPackage then return end
    
    if lib.progressCircle({
        duration = 3000,
        label = 'Collecting package from vehicle...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'pickup_object',
            clip = 'pickup_low',
        },
    }) then
        
        local randomProp = Config.Packages.props[math.random(1, #Config.Packages.props)]
        CarriedPackage = CreateObject(randomProp, 0, 0, 0, true, true, true)
        AttachEntityToEntity(CarriedPackage, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 60309), 0.025, 0.08, 0.255, -145.0, 290.0, 0.0, true, true, false, true, 1, true)
        
        lib.requestAnimDict(Config.Packages.carryAnim.dict)
        TaskPlayAnim(PlayerPedId(), Config.Packages.carryAnim.dict, Config.Packages.carryAnim.clip, 8.0, 8.0, -1, Config.Packages.carryAnim.flag, 0, false, false, false)
        
        ActiveJob.stage = 'delivering_to_npc'
        ShowNotification('Package collected! Deliver it to the customer', 'success')
        DebugPrint('Package collected from vehicle for delivery')
    end
end

function SpawnDeliveryNPC(delivery)
    local coords = delivery.coords
    local randomModel = Config.DeliveryNPCs.models[math.random(1, #Config.DeliveryNPCs.models)]
    local randomScenario = Config.DeliveryNPCs.scenarios[math.random(1, #Config.DeliveryNPCs.scenarios)]
    
    DebugPrint('Spawning NPC at: ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z)
    
    local modelToUse = IsModelInCdimage(randomModel) and randomModel or 's_m_m_postal_01'
    
    lib.requestModel(modelToUse, 10000)

    local spawnX, spawnY, spawnZ, spawnHeading
    if coords.w then 
        spawnX, spawnY, spawnZ, spawnHeading = coords.x, coords.y, coords.z, coords.w
    else 
        spawnX, spawnY, spawnZ, spawnHeading = coords.x, coords.y, coords.z, 0.0
    end

    local npc = CreatePed(4, modelToUse, spawnX, spawnY, spawnZ, spawnHeading, false, true)
    local timeout = 0
    while not DoesEntityExist(npc) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    if not DoesEntityExist(npc) then
        DebugPrint('Failed to create NPC at delivery location')
        ShowNotification('Failed to spawn customer NPC', 'error')
        return
    end
    
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    FreezeEntityPosition(npc, true)
    
    SetEntityHeading(npc, spawnHeading)
    TaskStartScenarioInPlace(npc, randomScenario, 0, true)
    
    ActiveJob.deliveryNPC = npc
  
    local npcBlip = AddBlipForEntity(npc)
    SetBlipSprite(npcBlip, 480)
    SetBlipColour(npcBlip, 2)
    SetBlipScale(npcBlip, 0.8)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Customer - ' .. delivery.name)
    EndTextCommandSetBlipName(npcBlip)
    ActiveJob.customerBlip = npcBlip
    
    SetupNPCTarget(npc)
    
    DebugPrint('NPC created successfully - Model: ' .. modelToUse .. ' - Heading: ' .. spawnHeading)
    ShowNotification('Customer is waiting for delivery!', 'inform', 5000)
end

function SetupNPCTarget(npc)
    if Config.Target == 'ox_target' then
        exports.ox_target:addLocalEntity(npc, {
            name = 'deliver_package_npc',
            label = Config.DeliveryNPCs.label,
            icon = Config.DeliveryNPCs.icon,
            distance = Config.DeliveryNPCs.interactionDistance,
            canInteract = function()
                return ActiveJob and ActiveJob.stage == 'delivering_to_npc' and CarriedPackage
            end,
            onSelect = function()
                DeliverPackageToNPC()
            end,
        })
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:AddTargetEntity(npc, {
            options = {
                {
                    type = "client",
                    event = "takealot_delivery:client:deliverToNPC",
                    icon = Config.DeliveryNPCs.icon,
                    label = Config.DeliveryNPCs.label,
                    canInteract = function()
                        return ActiveJob and ActiveJob.stage == 'delivering_to_npc' and CarriedPackage
                    end
                }
            },
            distance = Config.DeliveryNPCs.interactionDistance
        })
    end
end

function DeliverPackageToNPC()
    if not CarriedPackage or not ActiveJob.deliveryNPC then return end
    
    local playerPed = PlayerPedId()
    local npc = ActiveJob.deliveryNPC
    
    ClearPedTasks(npc)
    TaskTurnPedToFaceEntity(npc, playerPed, 2000)
    TaskLookAtEntity(npc, playerPed, 5000, 0, 2)
    
    local randomGreeting = Config.DeliveryNPCs.dialogue.greetings[math.random(1, #Config.DeliveryNPCs.dialogue.greetings)]
    local randomThanks = Config.DeliveryNPCs.dialogue.thanks[math.random(1, #Config.DeliveryNPCs.dialogue.thanks)]
   
    Wait(1000)
    
    if lib.progressCircle({
        duration = 4000,
        label = 'Delivering package to customer...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'mp_common',
            clip = 'givetake1_a',
        },
    }) then
        
        lib.requestAnimDict('mp_common')
        TaskPlayAnim(npc, 'mp_common', 'givetake1_b', 8.0, 8.0, 2000, 0, 0, false, false, false)
        
        DeleteEntity(CarriedPackage)
        CarriedPackage = nil
        ClearPedTasks(PlayerPedId())
        
        lib.notify({
            title = 'Customer',
            description = randomGreeting,
            type = 'success',
            duration = 3000
        })
        
        Wait(2000)
        
        lib.notify({
            title = 'Customer',
            description = randomThanks,
            type = 'inform',
            duration = 3000
        })
        
        CompleteDelivery()
        DebugPrint('Package delivered to NPC successfully')
    end
end

function CompleteDelivery()
    if not ActiveJob then return end
    
    local delivery = ActiveJob.deliveries[ActiveJob.currentDeliveryIndex]
    
    if ActiveJob.deliveryNPC then
        CleanupDeliveryNPC()
    end
    
    if ActiveJob.customerBlip then
        RemoveBlip(ActiveJob.customerBlip)
        ActiveJob.customerBlip = nil
    end
    
    ActiveJob.deliveriesCompleted = ActiveJob.deliveriesCompleted + 1
    ShowNotification('Delivery completed successfully!', 'success', 5000)
    
    if ActiveJob.currentDeliveryIndex < #ActiveJob.deliveries then
        ActiveJob.currentDeliveryIndex = ActiveJob.currentDeliveryIndex + 1
        ActiveJob.stage = 'delivering'
        CreateDeliveryBlip()
        ShowNotification('Next delivery: ' .. ActiveJob.deliveries[ActiveJob.currentDeliveryIndex].name, 'inform', 5000)
    else
        ActiveJob.stage = 'return'
        ShowNotification('All deliveries completed! Return to the depot for payment', 'success', 10000)
        CreateReturnBlip()
    end
    
    DebugPrint('Delivery completed: ' .. delivery.name)
end

function CleanupDeliveryNPC()
    if not ActiveJob.deliveryNPC then return end
    
    if Config.Target == 'ox_target' then
        exports.ox_target:removeLocalEntity(ActiveJob.deliveryNPC, 'deliver_package_npc')
    elseif Config.Target == 'qb-target' then
        exports['qb-target']:RemoveTargetEntity(ActiveJob.deliveryNPC)
    end
    
    if DoesEntityExist(ActiveJob.deliveryNPC) then
        local npcEntity = ActiveJob.deliveryNPC
        
        FreezeEntityPosition(npcEntity, false)
        SetEntityInvincible(npcEntity, false)
        
        local npcCoords = GetEntityCoords(npcEntity)
        local playerCoords = GetEntityCoords(PlayerPedId())
        local direction = npcCoords - playerCoords
        direction = direction / #direction
        local targetCoords = npcCoords + (direction * 50.0)
        
        TaskGoStraightToCoord(npcEntity, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, -1, 0.0, 0.0)
        
        DebugPrint('NPC walking away, will despawn in 10 seconds')
        
        SetTimeout(10000, function()
            if DoesEntityExist(npcEntity) then
                DeleteEntity(npcEntity)
                DebugPrint('NPC successfully deleted')
            end
        end)
    end
    
    ActiveJob.deliveryNPC = nil
end

function CreateReturnBlip()
    local coords = Config.JobGiver.coords
    
    ReturnBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(ReturnBlip, 479)
    SetBlipColour(ReturnBlip, 2)
    SetBlipScale(ReturnBlip, 1.0)
    SetBlipRoute(ReturnBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Return to TAKEALOT Depot')
    EndTextCommandSetBlipName(ReturnBlip)
    
    DebugPrint('Return blip created')
end

RegisterNetEvent('takealot_delivery:client:jobCompleted', function(payment)
    ShowNotification(string.format(Config.Notifications.jobCompleted, payment), 'success', 10000)

    local completion = table.concat(Config.DialogueOptions.completion, '\n\n')

    lib.alertDialog({
        header = 'Delivery Complete - ' .. Config.JobGiver.name,
        content = completion .. '\n\nPayment: $' .. payment,
        centered = true,
        cancel = false
    })

    CleanupJob()
    DebugPrint('Job completed with payment: $' .. tostring(payment))
end)

RegisterNetEvent('takealot_delivery:client:jobCancelled', function()
    ShowNotification(Config.Notifications.jobCancelled, 'inform', 8000)
    
    lib.alertDialog({
        header = 'Job Cancelled - ' .. Config.JobGiver.name,
        content = 'Your delivery job has been cancelled. The vehicle has been reclaimed and no payment has been made.',
        centered = true,
        cancel = false
    })
    
    CleanupJob()
    DebugPrint('Job cancelled by player')
end)

function CleanupJob()
    DebugPrint('Cleaning up delivery job')
    lib.hideTextUI()
    
    if CurrentDeliveryBlip then RemoveBlip(CurrentDeliveryBlip) end
    if ReturnBlip then RemoveBlip(ReturnBlip) end
    
    if ActiveJob then
        if ActiveJob.deliveryZone then
            ActiveJob.deliveryZone:remove()
        end
        
        if ActiveJob.deliveryNPC then
            if Config.Target == 'ox_target' then
                exports.ox_target:removeLocalEntity(ActiveJob.deliveryNPC, 'deliver_package_npc')
            elseif Config.Target == 'qb-target' then
                exports['qb-target']:RemoveTargetEntity(ActiveJob.deliveryNPC)
            end
            
            if DoesEntityExist(ActiveJob.deliveryNPC) then
                DeleteEntity(ActiveJob.deliveryNPC)
            end
        end
        
        if ActiveJob.customerBlip then
            RemoveBlip(ActiveJob.customerBlip)
        end
    end
    
    for i, package in pairs(Packages) do
        if DoesEntityExist(package.object) then
            if Config.Target == 'ox_target' then
                exports.ox_target:removeLocalEntity(package.object, 'collect_package_' .. i)
            elseif Config.Target == 'qb-target' then
                exports['qb-target']:RemoveTargetEntity(package.object)
            end
            DeleteEntity(package.object)
        end
        if PackageBlips[i] then
            RemoveBlip(PackageBlips[i])
        end
    end
    Packages = {}
    PackageBlips = {}
    
    if CarriedPackage and DoesEntityExist(CarriedPackage) then
        DeleteEntity(CarriedPackage)
        CarriedPackage = nil
        ClearPedTasks(PlayerPedId())
    end
    
    if DeliveryVehicle and DoesEntityExist(DeliveryVehicle) then
        if Config.Target == 'ox_target' then
            exports.ox_target:removeLocalEntity(DeliveryVehicle, {'load_package_vehicle', 'collect_package_vehicle'})
        elseif Config.Target == 'qb-target' then
            exports['qb-target']:RemoveTargetEntity(DeliveryVehicle)
        end
        
        DeleteEntity(DeliveryVehicle)
        DeliveryVehicle = nil
    end
    
    ActiveJob = nil
    DebugPrint('Job cleanup completed')
end

RegisterNetEvent('takealot_delivery:client:showMenu', function()
    ShowDepotMenu()
end)

RegisterNetEvent('takealot_delivery:client:collectPackage', function(data)
    if data.packageIndex then
        CollectPackage(data.packageIndex)
    end
end)

RegisterNetEvent('takealot_delivery:client:deliverToNPC', function()
    DeliverPackageToNPC()
end)

RegisterNetEvent('takealot_delivery:client:loadPackage', function()
    LoadPackage()
end)

RegisterNetEvent('takealot_delivery:client:collectFromVehicle', function()
    CollectPackageFromVehicle()
end)