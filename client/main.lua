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
    lib.requestAnimDict('veh@break_in@0h@p_m_one@')
    TaskPlayAnim(cache.ped, 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds', 3.0, 3.0, -1, 16, 0, false, false, false)
    CreateThread(function()
        while openingRegister do
            TaskPlayAnim(cache.ped, 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds', 3.0, 3.0, -1, 16, 0, false, false, false)
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
end

local function dropFingerprint()
    if IsWearingGloves() then return end
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
    if lib.progressBar({
        duration = config.openRegisterTime,
        label = Lang:t('text.emptying_the_register'),
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
        exports.qbx_core:Notify(Lang:t('error.process_canceled'), 'error')
    end
    cb('ok')
end)

RegisterNUICallback('fail', function(_, cb)
    startLockpick(false)
    dropFingerprint()
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
                        lib.showTextUI(Lang:t('text.register_empty'), {position = 'left-center'})
                        exports['qbx-core']:DrawText()
                    end
                else
                    DrawText3D(Lang:t('text.register_empty'), sharedConfig.registers[i].coords)
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
                    text = Lang:t('text.safe_opened')
                else
                    text = Lang:t('text.try_combination')
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
                    DrawText3D(text, sharedConfig.safes[i].coords)
                end
            end
        end
        if not nearby and hasShownText then hasShownText = false lib.hideTextUI() end
        Wait(time)
    end
end)
