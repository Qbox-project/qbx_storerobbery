local config = require 'config.server'
local sharedConfig = require 'config.shared'
local StartedRegister = {}
local StartedSafe = {}
local SafeCodes = {}
local CalledCops = {}
local ITEMS = exports.ox_inventory:Items()

local function GetClosestRegister(Coords)
    local ClosestRegisterIndex
    for i = 1, #sharedConfig.registers do
        if #(Coords - sharedConfig.registers[i].coords) <= 2 then
            if ClosestRegisterIndex then
                if #(Coords - sharedConfig.registers[i].coords) < #(Coords - sharedConfig.registers[ClosestRegisterIndex].coords) then
                    ClosestRegisterIndex = i
                end
            else
                ClosestRegisterIndex = i
            end
        end
    end
    return ClosestRegisterIndex
end

local function GetClosestSafe(Coords)
    local ClosestSafeIndex
    for i = 1, #sharedConfig.safes do
        if #(Coords - sharedConfig.safes[i].coords) <= 2 then
            ClosestSafeIndex = i
        end
    end
    return ClosestSafeIndex
end

local function alertPolice(text, source, camId)
    if CalledCops[source] then return end

    local chance = lib.callback.await('qbx-storerobbery:client:getAlertChance', source)
    if math.random() <= chance then
        CalledCops[source] = true
        TriggerEvent('police:server:policeAlert', text, camId, source)
    end

    SetTimeout(config.callCopsTimeout, function()
        CalledCops[source] = false
    end)
end

AddEventHandler('lockpicks:UseLockpick', function(PlayerSource, IsAdvanced)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(PlayerSource))
    local ClosestRegisterIndex = GetClosestRegister(PlayerCoords)
    local leoCount = exports.qbx_core:GetDutyCountType('leo')

    if not ClosestRegisterIndex then return end
    if sharedConfig.registers[ClosestRegisterIndex].robbed then return end
    if leoCount < config.minimumCops and config.notEnoughCopsNotify then
        exports.qbx_core:Notify(PlayerSource, Lang:t('error.no_police', {Required = config.minimumCops}), 'error')
        return
    end

    StartedRegister[PlayerSource] = true
    sharedConfig.registers[ClosestRegisterIndex].robbed = true

    alertPolice(Lang:t('alert.register'), PlayerSource, sharedConfig.registers[ClosestRegisterIndex].camId)
    TriggerClientEvent('qb-storerobbery:client:startRegister', PlayerSource, IsAdvanced)
end)

RegisterNetEvent('qb-storerobbery:server:failedregister', function(IsUsingAdvanced)
    local Player = exports.qbx_core:GetPlayer(source)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestRegisterIndex = GetClosestRegister(PlayerCoords)
    local DeleteChance = IsUsingAdvanced and math.random(0, 30) or math.random(0, 60)

    StartedRegister[source] = false
    sharedConfig.registers[ClosestRegisterIndex].robbed = false
    if DeleteChance > math.random(0, 100) then
        exports.qbx_core:Notify(source, Lang:t('error.lockpick_broken'), 'error')
        if IsUsingAdvanced then
            Player.Functions.RemoveItem('advancedlockpick', 1)
            TriggerClientEvent('inventory:client:ItemBox', source, ITEMS['advancedlockpick'], 'remove')
        else
            Player.Functions.RemoveItem('lockpick', 1)
            TriggerClientEvent('inventory:client:ItemBox', source, ITEMS['lockpick'], 'remove')
        end
    end
end)

RegisterNetEvent('qb-storerobbery:server:exitedregister', function()
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestRegisterIndex = GetClosestRegister(PlayerCoords)
    StartedRegister[source] = false
    sharedConfig.registers[ClosestRegisterIndex].robbed = false
end)

RegisterNetEvent('qb-storerobbery:server:cancelledregister', function()
    StartedRegister[source] = false
    TriggerClientEvent('qb-storerobbery:client:syncconfig', -1, sharedConfig.registers, sharedConfig.safes)
end)

RegisterNetEvent('qb-storerobbery:server:openregister', function(IsDone)
    local Player = exports.qbx_core:GetPlayer(source)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestRegisterIndex = GetClosestRegister(PlayerCoords)
    local Amount = exports.qbx_core:GetDutyCountType('leo')

    if not ClosestRegisterIndex then return end
    if #(PlayerCoords - sharedConfig.registers[ClosestRegisterIndex].coords) > 2 then return end
    if not StartedRegister[source] then return end
    if Amount < config.minimumCops and config.notEnoughCopsNotify then
        exports.qbx_core:Notify(source, Lang:t('error.no_police', {Required = config.minimumCops}), 'error')
        return
    end

    Player.Functions.AddMoney('cash', math.random(config.registerReward.min, config.registerReward.max))

    if not IsDone then return end

    TriggerClientEvent('qb-storerobbery:client:syncconfig', -1, sharedConfig.registers, sharedConfig.safes)
    if config.registerReward.chanceAtSticky > math.random(0, 100) then
        local Code = SafeCodes[sharedConfig.registers[ClosestRegisterIndex].safeKey]
        local Info
        if sharedConfig.safes[sharedConfig.registers[ClosestRegisterIndex].safeKey].type == 'keypad' then
            Info = {
                label = Lang:t('text.safe_code') .. tostring(Code)
            }
        else
            Info = {
                label = Lang:t('text.safe_code') .. tostring(math.floor((Code[1] % 360) / 3.60)) .. "-" .. tostring(math.floor((Code[2] % 360) / 3.60)) .. "-" .. tostring(math.floor((Code[3] % 360) / 3.60)) .. "-" .. tostring(math.floor((Code[4] % 360) / 3.60)) .. "-" .. tostring(math.floor((Code[5] % 360) / 3.60))
            }
        end
        Player.Functions.AddItem('stickynote', 1, false, Info)
        TriggerClientEvent('inventory:client:ItemBox', source, ITEMS['stickynote'], 'add')
    end

    StartedRegister[source] = false
    SetTimeout(math.random(config.registerRefresh.min, config.registerRefresh.max), function()
        sharedConfig.registers[ClosestRegisterIndex].robbed = false
        TriggerClientEvent('qb-storerobbery:client:syncconfig', -1, sharedConfig.registers, sharedConfig.safes)
    end)
end)

RegisterNetEvent('qb-storerobbery:server:trysafe', function()
    local src = GetPlayerPed(source)
    local PlayerCoords = GetEntityCoords(src)
    local ClosestSafeIndex = GetClosestSafe(PlayerCoords)
    local leoCount = exports.qbx_core:GetDutyCountType('leo')

    if not ClosestSafeIndex then return end
    if leoCount < config.minimumCops and config.notEnoughCopsNotify then
        exports.qbx_core:Notify(source, Lang:t('error.no_police', {Required = config.minimumCops}), 'error')
        return
    end

    sharedConfig.safes[ClosestSafeIndex].robbed = true
    StartedSafe[source] = true
    alertPolice(Lang:t('alert.safe'), source, sharedConfig.safes[ClosestSafeIndex].camId)
    TriggerClientEvent('qb-storerobbery:client:trysafe', source, ClosestSafeIndex, SafeCodes[ClosestSafeIndex])
end)

RegisterNetEvent('qb-storerobbery:server:failedsafe', function()
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestSafeIndex = GetClosestSafe(PlayerCoords)
    sharedConfig.safes[ClosestSafeIndex].robbed = false
    StartedSafe[source] = false
end)

RegisterNetEvent('qb-storerobbery:server:successsafe', function()
    local Player = exports.qbx_core:GetPlayer(source)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestSafeIndex = GetClosestSafe(PlayerCoords)
    local worthMarkedBills = math.random(config.safeReward.markedBillsWorth.min, config.safeReward.markedBillsWorth.max)
    local numMarkedBills = math.random(config.safeReward.markedBillsAmount.min, config.safeReward.markedBillsAmount.max)

    if not ClosestSafeIndex then return end
    if not StartedSafe[source] then return end

    local billsMeta = {
        worth = worthMarkedBills,
        description = Lang:t('text.value', { value = worthMarkedBills })
    }

    Player.Functions.AddItem('markedbills', numMarkedBills, false, billsMeta)

    if config.safeReward.chanceAtSpecial > math.random(0, 100) then
        Player.Functions.AddItem('rolex', math.random(config.safeReward.rolexAmount.min, config.safeReward.rolexAmount.max))
        TriggerClientEvent('inventory:client:ItemBox', source, ITEMS['rolex'], 'add')
        if config.safeReward.chanceAtSpecial / 2 > math.random(0, 100) then
            Player.Functions.AddItem('goldbar', config.safeReward.goldbarAmount)
            TriggerClientEvent('inventory:client:ItemBox', source, ITEMS['goldbar'], 'add')
        end
    end
    StartedSafe[source] = false
    TriggerClientEvent('qb-storerobbery:client:syncconfig', -1, sharedConfig.registers, sharedConfig.safes)
    SetTimeout(math.random(config.safeRefresh.min, config.safeRefresh.wax), function()
        sharedConfig.safes[ClosestSafeIndex].robbed = false
        TriggerClientEvent('qb-storerobbery:client:syncconfig', -1, sharedConfig.registers, sharedConfig.safes)
    end)
end)

AddEventHandler('playerJoining', function(source)
    TriggerClientEvent('qb-storerobbery:client:syncconfig', source, sharedConfig.registers, sharedConfig.safes)
end)

CreateThread(function()
    while true do
        SafeCodes = {}
        for i = 1, #sharedConfig.safes, 1 do
            local Safe = sharedConfig.safes[i]
            if Safe.type == "padlock" then
                SafeCodes[i] = { math.random(150, 450), math.random(1.0, 100.0), math.random(360, 450), math.random(300.0, 340.0), math.random(350, 400), math.random(320.0, 340.0), math.random(350, 600) }
            elseif Safe.type == "keypad" then
                SafeCodes[i] = math.random(1000, 9999)
            else
                print('[ERROR] Incorrect Safe type!')
            end
        end
        Wait(config.safeRefresh.Min)
    end
end)
