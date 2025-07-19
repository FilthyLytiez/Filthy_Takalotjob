
local Framework = nil
local ActiveJobs = {}
local RouteCooldowns = {}
local nextJobId = 1

local function GetFrameworkObject()
    local fw = Config.GetFramework()
    if fw == 'qbox' then
        Framework = exports.qbx_core
        return exports.qbx_core
    else
        Framework = exports['qb-core']:GetCoreObject()
        return Framework
    end
end

CreateThread(function()
    Wait(500)
    GetFrameworkObject()
    print('^2[TAKEALOT DELIVERY]^7 Server successfully initialized!')
end)


local function GetPlayer(src)
    if Config.GetFramework() == 'qbox' then
        return exports.qbx_core:GetPlayer(src)
    else
        return Framework.Functions.GetPlayer(src)
    end
end

local function ShowNotification(src, message, type, duration)
    if Config.GetFramework() == 'qbox' then
        TriggerClientEvent('QBCore:Notify', src, message, type or 'inform', duration or 5000)
    else
        TriggerClientEvent('QBCore:Notify', src, message, type or 'primary', duration or 5000)
    end
end

local function AddMoney(player, amount, reason)
    if Config.GetFramework() == 'qbox' then
        exports.ox_inventory:AddItem(player.PlayerData.source, 'money', amount)
    else
        player.Functions.AddMoney('cash', amount, reason or 'takealot-delivery')
    end
end

local function IsRouteOnCooldown(routeId)
    if RouteCooldowns[routeId] then
        local timeLeft = RouteCooldowns[routeId] - os.time()
        if timeLeft > 0 then
            return true, timeLeft
        else
            RouteCooldowns[routeId] = nil
        end
    end
    return false, 0
end

local function SetRouteCooldown(routeId)
    RouteCooldowns[routeId] = os.time() + (Config.GlobalRouteCooldown * 60)
end

local function CountActiveJobs()
    local count = 0
    for _ in pairs(ActiveJobs) do
        count = count + 1
    end
    return count
end

local function GetRouteById(routeId)
    for _, route in ipairs(Config.DeliveryRoutes) do
        if route.id == routeId then
            return route
        end
    end
    return nil
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    for jobId, job in pairs(ActiveJobs) do
        if job.player then
            TriggerClientEvent('takealot_delivery:client:jobCancelled', job.player)
        end
    end
    
    print('^3[TAKEALOT DELIVERY]^7 Resource stopped, cleaned up ' .. CountActiveJobs() .. ' active jobs')
end)

lib.callback.register('takealot_delivery:server:getActiveJobCount', function(source)
    return CountActiveJobs()
end)

lib.callback.register('takealot_delivery:server:getRouteCooldowns', function(source)
    local cooldowns = {}
    for routeId, expireTime in pairs(RouteCooldowns) do
        local timeLeft = expireTime - os.time()
        if timeLeft > 0 then
            cooldowns[routeId] = timeLeft
        else
            RouteCooldowns[routeId] = nil
        end
    end
    return cooldowns
end)

RegisterNetEvent('takealot_delivery:server:startJob', function(routeId)
    local src = source
    local player = GetPlayer(src)
    
    if not player then return end
    
    local route = GetRouteById(routeId)
    if not route then
        ShowNotification(src, 'Invalid route selected', 'error')
        return
    end
    
    local isOnCooldown, timeLeft = IsRouteOnCooldown(routeId)
    if isOnCooldown then
        local minutes = math.ceil(timeLeft / 60)
        ShowNotification(src, 'Route is on cooldown for ' .. minutes .. ' more minutes', 'error')
        return
    end
    
    if CountActiveJobs() >= Config.MaxActiveJobs then
        ShowNotification(src, Config.Notifications.jobActive, 'error')
        return
    end
    
    for _, job in pairs(ActiveJobs) do
        if job.player == src then
            ShowNotification(src, Config.Notifications.jobActive, 'error')
            return
        end
    end
    
    local jobId = nextJobId
    nextJobId = nextJobId + 1
   
    local packageCount = type(route.packageCount) == "table" 
        and math.random(route.packageCount.min, route.packageCount.max) 
        or route.packageCount
    
    local payment = type(route.payment) == "table" 
        and math.random(route.payment.min, route.payment.max) 
        or route.payment
    
    local randomizedDeliveries = {}
    for i, delivery in ipairs(route.deliveries) do
        local deliveryPackages = type(delivery.packages) == "table" 
            and math.random(delivery.packages.min, delivery.packages.max) 
            or delivery.packages
        
        randomizedDeliveries[i] = {
            name = delivery.name,
            coords = delivery.coords,
            packages = deliveryPackages
        }
    end
    
    local jobData = {
        id = jobId,
        player = src,
        playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        startTime = os.time(),
        stage = 'started',
        routeId = routeId,
        routeName = route.name,
        totalPackages = packageCount,
        deliveries = randomizedDeliveries,
        payment = payment
    }
    
    ActiveJobs[jobId] = jobData
    
    TriggerClientEvent('takealot_delivery:client:jobStarted', src, jobData)
    SetRouteCooldown(routeId)
    SetTimeout(45 * 60 * 1000, function()
        if ActiveJobs[jobId] then
            TriggerClientEvent('takealot_delivery:client:jobCancelled', src)
            ActiveJobs[jobId] = nil
        end
    end)
end)

RegisterNetEvent('takealot_delivery:server:completeJob', function(jobId)
    local src = source
    local job = ActiveJobs[jobId]
    
    if not job then
        ShowNotification(src, 'Invalid job completion attempt', 'error')
        return
    end
    
    if job.player ~= src then
        ShowNotification(src, 'You are not authorized to complete this job', 'error')
        return
    end
    
    local player = GetPlayer(src)
    if not player then return end

    AddMoney(player, job.payment, 'takealot-delivery-completion')
    
    ActiveJobs[jobId] = nil
    
    TriggerClientEvent('takealot_delivery:client:jobCompleted', src, job.payment)
end)

RegisterNetEvent('takealot_delivery:server:cancelJob', function(jobId)
    local src = source
    local job = ActiveJobs[jobId]
    
    -- Validation
    if not job then
        ShowNotification(src, 'No active job to cancel', 'error')
        return
    end
    
    if job.player ~= src then
        ShowNotification(src, 'You are not authorized to cancel this job', 'error')
        return
    end
    ActiveJobs[jobId] = nil
    
    TriggerClientEvent('takealot_delivery:client:jobCancelled', src)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    
    for jobId, job in pairs(ActiveJobs) do
        if job.player == src then
            ActiveJobs[jobId] = nil
            break
        end
    end
end)

function GetActiveJobsCount()
    return CountActiveJobs()
end

function GetRouteCooldownsCount()
    local count = 0
    for _ in pairs(RouteCooldowns) do
        count = count + 1
    end
    return count
end

function ClearRouteCooldown(routeId)
    if RouteCooldowns[routeId] then
        RouteCooldowns[routeId] = nil
        return true
    end
    return false
end

function GetJobInfo(playerId)
    for jobId, job in pairs(ActiveJobs) do
        if job.player == playerId then
            return {
                id = jobId,
                routeName = job.routeName,
                stage = job.stage,
                payment = job.payment,
                startTime = job.startTime
            }
        end
    end
    return nil
end

exports('GetActiveJobsCount', GetActiveJobsCount)
exports('GetRouteCooldownsCount', GetRouteCooldownsCount)
exports('ClearRouteCooldown', ClearRouteCooldown)
exports('GetJobInfo', GetJobInfo)