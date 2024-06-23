local config = require 'config.client'
local sharedConfig = require 'config.shared'
local isUsingAdvanced
local openingRegister
local currentCombination

local function startLockpick(bool)
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        action = "ui",
        toggle = bool,
    })
    SetCursorLocation(0.5, 0.2)
end

local function openingRegisterHandler(lockpickTime)
    openingRegister = true
    lib.playAnim(cache.ped, 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds', 3.0, 3.0, -1, 16, 0, false, false, false)
    CreateThread(function()
        while openingRegister do
            lib.playAnim(cache.ped, 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds', 3.0, 3.0, -1, 16, 0, false, false, false)
            Wait(2000)
            lockpickTime = lockpickTime - 2000
            TriggerServerEvent('qbx_storerobbery:server:registerOpened', false)
            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
            if lockpickTime <= 0 then
                openingRegister = false
                StopAnimTask(cache.ped, 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds', 1.0)
            end
        end
    end)
end

local function safeAnim()
    lib.requestAnimDict('amb@prop_human_bum_bin@idle_b')
    TaskPlayAnim(cache.ped, 'amb@prop_human_bum_bin@idle_b', 'idle_d', 8.0, 8.0, -1, 50, 0, false, false, false)
    Wait(2500)
    TaskPlayAnim(cache.ped, 'amb@prop_human_bum_bin@idle_b', 'exit', 8.0, 8.0, -1, 50, 0, false, false, false)
    RemoveAnimDict('amb@prop_human_bum_bin@idle_b')
end

local function checkInteractStatus(register)
    if sharedConfig.registers[register].robbed then
        return false
    end

    local leoCount = lib.callback.await('qbx_storerobbery:server:leoCount', false)
    if leoCount > sharedConfig.minimumCops then
        return true
    end

    return false
end

local function alertPolice()
    local hours = GetClockHours()
    local chance = config.policeAlertChance

    if qbx.isWearingGloves() or hours >= 1 and hours <= 6 then
        chance = config.policeNightAlertChance
    end

    if math.random() <= chance then
        TriggerServerEvent('police:server:policeAlert')
    end
end

local function dropFingerprint()
    if qbx.isWearingGloves() then return end
    if config.fingerprintChance > math.random(0, 100) then
        local coords = GetEntityCoords(cache.ped)
        TriggerServerEvent('evidence:server:CreateFingerDrop', coords)
    end
end

RegisterNetEvent('qbx_storerobbery:client:initRegisterAttempt', function(isAdvanced)
    isUsingAdvanced = isAdvanced
    startLockpick(true)
end)

RegisterNetEvent('qbx_storerobbery:client:initSafeAttempt', function(closestSafeIndex, combination)
    currentCombination = combination
    if sharedConfig.safes[closestSafeIndex].type == 'keypad' then
        SendNUIMessage({
            action = 'openKeypad',
        })
        SetNuiFocus(true, true)
    else
        TriggerEvent('SafeCracker:StartMinigame', currentCombination)
    end
end)

RegisterNetEvent('SafeCracker:EndMinigame', function(hasWon)
    if hasWon then
        TriggerServerEvent('qbx_storerobbery:server:safeCracked')
        safeAnim()
    else
        TriggerServerEvent('qbx_storerobbery:server:failedSafeCracking')
    end
end)

RegisterNetEvent('qbx_storerobbery:client:updatedRobbables', function(registers, safes)
    sharedConfig.registers = registers
    sharedConfig.safes = safes
end)

lib.callback.register('qbx_storerobbery:client:getAlertChance', function()
    local chance = config.policeAlertChance
    if GetClockHours() >= 1 and GetClockHours() <= 6 then
        chance = config.policeNightAlertChance
    end
    return chance
end)

RegisterNUICallback('success', function(_, cb)
    startLockpick(false)
    openingRegisterHandler(config.openRegisterTime)
    alertPolice()
    if lib.progressBar({
        duration = config.openRegisterTime,
        label = locale('text.emptying_the_register'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            mouse = false,
            combat = true
        }
    }) then -- if completed
        openingRegister = false
        TriggerServerEvent('qbx_storerobbery:server:registerOpened', true)
    else -- if canceled
        openingRegister = false
        TriggerServerEvent('qbx_storerobbery:server:registerCanceled')
        exports.qbx_core:Notify(locale('error.process_canceled'), 'error')
    end
    cb('ok')
end)

RegisterNUICallback('fail', function(_, cb)
    startLockpick(false)
    dropFingerprint()
    alertPolice()
    TriggerServerEvent('qbx_storerobbery:server:registerFailed', isUsingAdvanced)
    cb('ok')
end)

RegisterNUICallback('exit', function(_, cb)
    startLockpick(false)
    TriggerServerEvent('qbx_storerobbery:server:registerExited')
    cb('ok')
end)

RegisterNUICallback('padLockClose', function(_, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('qbx_storerobbery:server:failedSafeCracking')
    cb('ok')
end)

RegisterNUICallback('combinationFail', function(_, cb)
    local soundId = GetSoundId()
    PlaySound(soundId, 'Place_Prop_Fail', 'DLC_Dmod_Prop_Editor_Sounds', false, 0, true)
    ReleaseSoundId(soundId)
    cb('ok')
end)

RegisterNUICallback('tryCombination', function(data, cb)
    SetNuiFocus(false, false)
    if tonumber(data.combination) == currentCombination then
        TriggerServerEvent('qbx_storerobbery:server:safeCracked')
        SendNUIMessage({
            action = "closeKeypad",
            error = false
        })
        safeAnim()
    else
        TriggerServerEvent('qbx_storerobbery:server:failedSafeCracking')
        SendNUIMessage({
            action = "closeKeypad",
            error = true
        })
    end
    cb('ok')
end)

local function createRegisters()
    CreateThread(function()
        for k, v in pairs(sharedConfig.registers) do
            exports.ox_target:addBoxZone({
                coords = v.coords,
                size = vec3(1.5, 1.5, 1.5),
                rotation = 0.0,
                debug = config.debugPoly,
                options = {
                    {
                        name = k..'_register',
                        icon = 'cash-register',
                        label = 'Open Register',
                        canInteract = function()
                            return checkInteractStatus(k)
                        end,
                        serverEvent = 'qbx_storerobbery:server:checkStatus',
                    }
                }
            })
        end
    end)
end

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= cache.resource then return end
    createRegisters()
end)

-- Update so that the target doesnt show also
CreateThread(function()
    local hasShownText
    while true do
        local coords = GetEntityCoords(cache.ped)
        local time = 800
        local nearby = false
        for i = 1, #sharedConfig.registers do
            if #(coords - sharedConfig.registers[i].coords) <= 1.4 and sharedConfig.registers[i].robbed then
                time = 0
                nearby = true
                if config.useDrawText then
                    if not hasShownText then
                        hasShownText = true
                        lib.showTextUI(locale('text.register_empty'), {position = 'left-center'})
                        exports['qbx-core']:DrawText()
                    end
                else
                    qbx.drawText3d({text = locale('text.register_empty'), coords = sharedConfig.registers[i].coords})
                end
            end
        end
        if not nearby and hasShownText then
            hasShownText = false
            lib.hideTextUI()
        end
        Wait(time)
    end
end)

CreateThread(function()
    local hasShownText
    while true do
        local coords = GetEntityCoords(cache.ped)
        local time = 800
        local nearby = false
        local text
        for i = 1, #sharedConfig.safes do
            if #(coords - sharedConfig.safes[i].coords) <= 1.4 then
                time = 0
                nearby = true
                if sharedConfig.safes[i].robbed then
                    text = locale('text.safe_opened')
                else
                    text = locale('text.try_combination')
                    if IsControlJustPressed(0, 38) then
                        TriggerServerEvent('qbx_storerobbery:server:trySafe')
                    end
                end
                if config.useDrawText then
                    if not hasShownText then
                        hasShownText = true
                        lib.showTextUI(text, {position = 'left-center'})
                    end
                else
                    qbx.drawText3d({text = text, coords = sharedConfig.safes[i].coords})
                end
            end
        end
        if not nearby and hasShownText then hasShownText = false lib.hideTextUI() end
        Wait(time)
    end
end)
