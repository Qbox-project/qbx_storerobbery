local QBCore = exports['qbx-core']:GetCoreObject()
local StartedRegister = {}
local StartedSafe = {}
local SafeCodes = {}
local CalledCops = {}

local function GetClosestRegister(Coords)
    local ClosestRegisterIndex
    for i = 1, #Config.Registers do
        if #(Coords - Config.Registers[i].coords) <= 2 then
            if ClosestRegisterIndex then
                if #(Coords - Config.Registers[i].coords) < #(Coords - Config.Registers[ClosestRegisterIndex].coords) then
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
    for i = 1, #Config.Safes do
        if #(Coords - Config.Safes[i].coords) <= 2 then
            ClosestSafeIndex = i
        end
    end
    return ClosestSafeIndex
end

local function PoliceAlert(Text, Source)
    if CalledCops[Source] then return end
    CalledCops[Source] = true
    TriggerEvent('police:server:policeAlert', Text)
    SetTimeout(Config.CallCopsTimeout, function()
        CalledCops[Source] = false
    end)
end

AddEventHandler('lockpicks:UseLockpick', function(PlayerSource, IsAdvanced)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(PlayerSource))
    local ClosestRegisterIndex = GetClosestRegister(PlayerCoords)
    local Amount = QBCore.Functions.GetDutyCountType('leo')

    if not ClosestRegisterIndex then return end
    if Config.Registers[ClosestRegisterIndex].robbed then return end
    if Amount < Config.MinimumCops then if Config.NotEnoughCopsNotify then QBCore.Functions.Notify(PlayerSource, Lang:t('error.no_police', { Required = Config.MinimumCops }), 'error') end return end

    StartedRegister[PlayerSource] = true
    Config.Registers[ClosestRegisterIndex].robbed = true
    PoliceAlert(Lang:t('alert.register'), PlayerSource)
    TriggerClientEvent('qb-storerobbery:client:startRegister', PlayerSource, IsAdvanced)
end)

RegisterNetEvent('qb-storerobbery:server:failedregister', function(IsUsingAdvanced)
    local Player = QBCore.Functions.GetPlayer(source)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestRegisterIndex = GetClosestRegister(PlayerCoords)
    local DeleteChance = IsUsingAdvanced and math.random(0, 30) or math.random(0, 60)

    StartedRegister[source] = false
    Config.Registers[ClosestRegisterIndex].robbed = false
    if DeleteChance > math.random(0, 100) then
        QBCore.Functions.Notify(source, Lang:t('error.lockpick_broken'), 'error')
        if IsUsingAdvanced then
            Player.Functions.RemoveItem('advancedlockpick', 1)
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['advancedlockpick'], 'remove')
        else
            Player.Functions.RemoveItem('lockpick', 1)
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['lockpick'], 'remove')
        end
    end
end)

RegisterNetEvent('qb-storerobbery:server:exitedregister', function()
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestRegisterIndex = GetClosestRegister(PlayerCoords)
    StartedRegister[source] = false
    Config.Registers[ClosestRegisterIndex].robbed = false
end)

RegisterNetEvent('qb-storerobbery:server:cancelledregister', function()
    StartedRegister[source] = false
    TriggerClientEvent('qb-storerobbery:client:syncconfig', -1, Config.Registers, Config.Safes)
end)

RegisterNetEvent('qb-storerobbery:server:openregister', function(IsDone)
    local Player = QBCore.Functions.GetPlayer(source)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestRegisterIndex = GetClosestRegister(PlayerCoords)
    local Amount = QBCore.Functions.GetDutyCountType('leo')

    if not ClosestRegisterIndex then return end
    if #(PlayerCoords - Config.Registers[ClosestRegisterIndex].coords) > 2 then return end
    if not StartedRegister[source] then return end
    if Amount < Config.MinimumCops then if Config.NotEnoughCopsNotify then QBCore.Functions.Notify(source, Lang:t('error.no_police', { Required = Config.MinimumCops }), 'error') end return end

    Player.Functions.AddMoney('cash', math.random(Config.RegisterReward.Min, Config.RegisterReward.Max))

    if not IsDone then return end

    TriggerClientEvent('qb-storerobbery:client:syncconfig', -1, Config.Registers, Config.Safes)
    if Config.RegisterReward.ChanceAtSticky > math.random(0, 100) then
        local Code = SafeCodes[Config.Registers[ClosestRegisterIndex].safeKey]
        local Info
        if Config.Safes[Config.Registers[ClosestRegisterIndex].safeKey].type == 'keypad' then
            Info = {
                label = Lang:t('text.safe_code') .. tostring(Code)
            }
        else
            Info = {
                label = Lang:t('text.safe_code') .. tostring(math.floor((Code[1] % 360) / 3.60)) .. "-" .. tostring(math.floor((Code[2] % 360) / 3.60)) .. "-" .. tostring(math.floor((Code[3] % 360) / 3.60)) .. "-" .. tostring(math.floor((Code[4] % 360) / 3.60)) .. "-" .. tostring(math.floor((Code[5] % 360) / 3.60))
            }
        end
        Player.Functions.AddItem('stickynote', 1, false, Info)
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['stickynote'], 'add')
    end

    StartedRegister[source] = false
    SetTimeout(math.random(Config.RegisterRefresh.Min, Config.RegisterRefresh.Max), function()
        Config.Registers[ClosestRegisterIndex].robbed = false
        TriggerClientEvent('qb-storerobbery:client:syncconfig', -1, Config.Registers, Config.Safes)
    end)
end)

RegisterNetEvent('qb-storerobbery:server:trysafe', function()
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestSafeIndex = GetClosestSafe(PlayerCoords)

    if not ClosestSafeIndex then return end

    Config.Safes[ClosestSafeIndex].robbed = true
    StartedSafe[source] = true
    PoliceAlert(Lang:t('alert.safe'), source)
    TriggerClientEvent('qb-storerobbery:client:trysafe', source, ClosestSafeIndex, SafeCodes[ClosestSafeIndex])
end)

RegisterNetEvent('qb-storerobbery:server:failedsafe', function()
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestSafeIndex = GetClosestSafe(PlayerCoords)
    Config.Safes[ClosestSafeIndex].robbed = false
    StartedSafe[source] = false
end)

RegisterNetEvent('qb-storerobbery:server:successsafe', function()
    local Player = QBCore.Functions.GetPlayer(source)
    local PlayerCoords = GetEntityCoords(GetPlayerPed(source))
    local ClosestSafeIndex = GetClosestSafe(PlayerCoords)

    if not ClosestSafeIndex then return end
    if not StartedSafe[source] then return end

    local Info = {
        worth = math.random(Config.SafeReward.MarkedBillsWorth.Min, Config.SafeReward.MarkedBillsWorth.Max)
    }
    Player.Functions.AddItem('markedbills', math.random(Config.SafeReward.MarkedBillsAmount.Min, Config.SafeReward.MarkedBillsAmount.Max), false, Info)
    TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['markedbills'], 'add')

    if Config.SafeReward.ChanceAtSpecial > math.random(0, 100) then
        Player.Functions.AddItem('rolex', math.random(Config.SafeReward.RolexAmount.Min, Config.SafeReward.RolexAmount.Max))
        TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['rolex'], 'add')
        if Config.SafeReward.ChanceAtSpecial / 2 > math.random(0, 100) then
            Player.Functions.AddItem('goldbar', Config.SafeReward.GoldbarAmount)
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items['goldbar'], 'add')
        end
    end
    StartedSafe[source] = false
    TriggerClientEvent('qb-storerobbery:client:syncconfig', -1, Config.Registers, Config.Safes)
    SetTimeout(math.random(Config.SafeRefresh.Min, Config.SafeRefresh.Max), function()
        Config.Safes[ClosestSafeIndex].robbed = false
        TriggerClientEvent('qb-storerobbery:client:syncconfig', -1, Config.Registers, Config.Safes)
    end)
end)

AddEventHandler('playerJoining', function(source)
    TriggerClientEvent('qb-storerobbery:client:syncconfig', source, Config.Registers, Config.Safes)
end)

CreateThread(function()
    while true do
        SafeCodes = {}
        for i = 1, #Config.Safes, 1 do
            local Safe = Config.Safes[i]
            if Safe.type == "padlock" then
                SafeCodes[i] = { math.random(150, 450), math.random(1.0, 100.0), math.random(360, 450), math.random(300.0, 340.0), math.random(350, 400), math.random(320.0, 340.0), math.random(350, 600) }
            elseif Safe.type == "keypad" then
                SafeCodes[i] = math.random(1000, 9999)
            else
                print('[ERROR] Incorrect Safe type!')
            end
        end
        Wait(Config.SafeRefresh.Min)
    end
end)

lib.versionCheck('Qbox-project/qb-storerobbery')
