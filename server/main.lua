local config = require 'config.server'
local clientConfig = require 'config.client'
local sharedConfig = require 'config.shared'
local startedRegister = {}
local startedSafe = {}
local safeCodes = {}

local function getClosestRegister(coords)
    local closestRegisterIndex
    for i = 1, #sharedConfig.registers do
        if #(coords - sharedConfig.registers[i].coords) <= 2 then
            if closestRegisterIndex then
                if #(coords - sharedConfig.registers[i].coords) < #(coords - sharedConfig.registers[closestRegisterIndex].coords) then
                    closestRegisterIndex = i
                end
            else
                closestRegisterIndex = i
            end
        end
    end
    return closestRegisterIndex
end

local function getClosestSafe(coords)
    local closestSafeIndex
    for i = 1, #sharedConfig.safes do
        if #(coords - sharedConfig.safes[i].coords) <= 2 then
            closestSafeIndex = i
        end
    end
    return closestSafeIndex
end

local function updateRobbables()
    TriggerClientEvent('qbx_storerobbery:client:updatedRobbables', -1, sharedConfig.registers, sharedConfig.safes)
end

local function releaseRegister(source)
    local session = startedRegister[source]
    if not session then return end

    sharedConfig.registers[session.index].robbed = false
    startedRegister[source] = nil
    updateRobbables()
end

local function releaseSafe(source)
    local session = startedSafe[source]
    if not session then return end

    sharedConfig.safes[session.index].robbed = false
    startedSafe[source] = nil
    updateRobbables()
end

local function hasEnoughPolice(source)
    if exports.qbx_core:GetDutyCountType('leo') >= sharedConfig.minimumCops then return true end

    if sharedConfig.notEnoughCopsNotify then
        exports.qbx_core:Notify(source, locale('error.no_police', {Required = sharedConfig.minimumCops}), 'error')
    end
    return false
end

RegisterNetEvent('qbx_storerobbery:server:checkStatus', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or startedRegister[src] or not hasEnoughPolice(src) then return end

    local coords = GetEntityCoords(GetPlayerPed(src))
    local closestRegisterIndex = getClosestRegister(coords)
    local register = closestRegisterIndex and sharedConfig.registers[closestRegisterIndex]
    if not register or register.robbed then return end

    local hasLockpick = exports.ox_inventory:Search(src, 'count', 'lockpick') > 0
    local hasAdvanced = exports.ox_inventory:Search(src, 'count', 'advancedlockpick') > 0
    if not hasLockpick and not hasAdvanced then
        exports.qbx_core:Notify(src, 'You don\'t have the appropriate items', 'error')
        return
    end

    local isAdvanced = not hasLockpick and hasAdvanced
    register.robbed = true
    startedRegister[src] = {
        index = closestRegisterIndex,
        isAdvanced = isAdvanced,
        earliestCompletion = GetGameTimer() + clientConfig.openRegisterTime,
    }
    updateRobbables()
    TriggerClientEvent('qbx_storerobbery:client:initRegisterAttempt', src, isAdvanced)
end)

RegisterNetEvent('qbx_storerobbery:server:registerFailed', function()
    local src = source
    local session = startedRegister[src]
    if not session then return end

    local coords = GetEntityCoords(GetPlayerPed(src))
    if getClosestRegister(coords) ~= session.index then return end

    local removalChance = session.isAdvanced and math.random(0, 30) or math.random(0, 60)
    releaseRegister(src)
    if removalChance <= math.random(0, 100) then return end

    exports.qbx_core:Notify(src, locale('error.lockpick_broken'), 'error')
    exports.ox_inventory:RemoveItem(src, session.isAdvanced and 'advancedlockpick' or 'lockpick', 1)
end)

RegisterNetEvent('qbx_storerobbery:server:registerExited', function()
    releaseRegister(source)
end)

RegisterNetEvent('qbx_storerobbery:server:registerCanceled', function()
    releaseRegister(source)
end)

RegisterNetEvent('qbx_storerobbery:server:registerOpened', function(isDone)
    if isDone ~= true then return end

    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    local session = startedRegister[src]
    if not player or not session or GetGameTimer() < session.earliestCompletion then return end

    local coords = GetEntityCoords(GetPlayerPed(src))
    if getClosestRegister(coords) ~= session.index then return end

    local registerIndex = session.index
    local register = sharedConfig.registers[registerIndex]
    startedRegister[src] = nil
    player.Functions.AddMoney('cash', math.random(config.registerReward.min, config.registerReward.max))

    if config.registerReward.chanceAtSticky > math.random(0, 100) then
        local safe = sharedConfig.safes[register.safeKey]
        local code = safeCodes[register.safeKey]
        local info
        if safe.type == 'keypad' then
            info = {label = locale('text.safe_code') .. tostring(code)}
        else
            info = {
                label = locale('text.safe_code') .. tostring(math.floor((code[1] % 360) / 3.60)) .. '-' .. tostring(math.floor((code[2] % 360) / 3.60)) .. '-' .. tostring(math.floor((code[3] % 360) / 3.60)) .. '-' .. tostring(math.floor((code[4] % 360) / 3.60)) .. '-' .. tostring(math.floor((code[5] % 360) / 3.60))
            }
        end
        exports.ox_inventory:AddItem(src, 'stickynote', 1, info)
    end

    updateRobbables()
    SetTimeout(math.random(config.registerRefresh.min, config.registerRefresh.max), function()
        register.robbed = false
        updateRobbables()
    end)
end)

RegisterNetEvent('qbx_storerobbery:server:trySafe', function()
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player or startedSafe[src] or not hasEnoughPolice(src) then return end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local closestSafeIndex = getClosestSafe(playerCoords)
    local safe = closestSafeIndex and sharedConfig.safes[closestSafeIndex]
    if not safe or safe.robbed then return end

    safe.robbed = true
    startedSafe[src] = {
        index = closestSafeIndex,
        code = safeCodes[closestSafeIndex],
        earliestCompletion = GetGameTimer() + (safe.type == 'padlock' and 5000 or 0),
    }
    updateRobbables()
    TriggerClientEvent('qbx_storerobbery:client:initSafeAttempt', src, closestSafeIndex, safe.type == 'padlock' and safeCodes[closestSafeIndex] or nil)
end)

RegisterNetEvent('qbx_storerobbery:server:failedSafeCracking', function()
    local src = source
    local session = startedSafe[src]
    if not session then return end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    if getClosestSafe(playerCoords) ~= session.index then return end
    releaseSafe(src)
end)

local function completeSafe(src, combination)
    local player = exports.qbx_core:GetPlayer(src)
    local session = startedSafe[src]
    if not player or not session or GetGameTimer() < session.earliestCompletion then return false end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    if getClosestSafe(playerCoords) ~= session.index then return false end

    local safe = sharedConfig.safes[session.index]
    if safe.type == 'keypad' and tonumber(combination) ~= session.code then return false end
    if safe.type == 'padlock' and combination ~= nil then return false end

    local worthMarkedBills = math.random(config.safeReward.markedBillsWorth.min, config.safeReward.markedBillsWorth.max)
    local numMarkedBills = math.random(config.safeReward.markedBillsAmount.min, config.safeReward.markedBillsAmount.max)
    local billsMeta = {
        worth = worthMarkedBills,
        description = locale('text.value', {value = worthMarkedBills})
    }

    startedSafe[src] = nil
    player.Functions.AddItem('markedbills', numMarkedBills, false, billsMeta)
    if config.safeReward.chanceAtSpecial > math.random(0, 100) then
        player.Functions.AddItem('rolex', math.random(config.safeReward.rolexAmount.min, config.safeReward.rolexAmount.max))
        if config.safeReward.chanceAtSpecial / 2 > math.random(0, 100) then
            player.Functions.AddItem('goldbar', config.safeReward.goldbarAmount)
        end
    end

    updateRobbables()
    SetTimeout(math.random(config.safeRefresh.min, config.safeRefresh.max), function()
        safe.robbed = false
        updateRobbables()
    end)
    return true
end

RegisterNetEvent('qbx_storerobbery:server:safeCracked', function()
    completeSafe(source)
end)

lib.callback.register('qbx_storerobbery:server:trySafeCombination', function(source, combination)
    return completeSafe(source, combination)
end)

AddEventHandler('playerJoining', function()
    TriggerClientEvent('qbx_storerobbery:client:updatedRobbables', source, sharedConfig.registers, sharedConfig.safes)
end)

AddEventHandler('playerDropped', function()
    releaseRegister(source)
    releaseSafe(source)
end)

lib.callback.register('qbx_storerobbery:server:leoCount', function()
    return exports.qbx_core:GetDutyCountType('leo')
end)

CreateThread(function()
    while true do
        safeCodes = {}
        for i = 1, #sharedConfig.safes do
            local safe = sharedConfig.safes[i]
            if safe.type == 'padlock' then
                safeCodes[i] = {math.random(150, 450), math.random(1.0, 100.0), math.random(360, 450), math.random(300.0, 340.0), math.random(350, 400), math.random(320.0, 340.0), math.random(350, 600)}
            elseif safe.type == 'keypad' then
                safeCodes[i] = math.random(1000, 9999)
            else
                print('[ERROR] Incorrect Safe type!')
            end
        end
        Wait(config.safeRefresh.min)
    end
end)
