local config = require 'config.client'
local sharedConfig = require 'config.shared'
local isUsingAdvanced
local openingRegister
local openRegisterDict = 'veh@break_in@0h@p_m_one@'
local openRegisterAnim = 'low_force_entry_ds'
local currentCombination

local function StartLockpick(bool)
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        action = "ui",
        toggle = bool,
    })
    SetCursorLocation(0.5, 0.2)
end

local function OpeningRegisterHandler(LockpickTime)
    openingRegister = true
    lib.requestAnimDict(openRegisterDict)
    TaskPlayAnim(cache.ped, openRegisterDict, openRegisterAnim, 3.0, 3.0, -1, 16, 0, false, false, false)
    CreateThread(function()
        while openingRegister do
            TaskPlayAnim(cache.ped, openRegisterDict, openRegisterAnim, 3.0, 3.0, -1, 16, 0, false, false, false)
            Wait(2000)
            LockpickTime = LockpickTime - 2000
            TriggerServerEvent('qb-storerobbery:server:openregister', false)
            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
            if LockpickTime <= 0 then
                openingRegister = false
                StopAnimTask(cache.ped, openRegisterDict, openRegisterAnim, 1.0)
            end
        end
    end)
end

local function SafeAnim()
    lib.requestAnimDict('amb@prop_human_bum_bin@idle_b')
    TaskPlayAnim(cache.ped, 'amb@prop_human_bum_bin@idle_b', 'idle_d', 8.0, 8.0, -1, 50, 0, false, false, false)
    Wait(2500)
    TaskPlayAnim(cache.ped, 'amb@prop_human_bum_bin@idle_b', 'exit', 8.0, 8.0, -1, 50, 0, false, false, false)
end

lib.callback.register('qbx-storerobbery:client:getAlertChance', function()
    local chance = config.policeAlertChance
    if GetClockHours() >= 1 and GetClockHours() <= 6 then
        chance = config.policeNightAlertChance
    end
    return chance
end)

CreateThread(function()
    local HasShownText
    while true do
        local PlayerCoords = GetEntityCoords(cache.ped)
        local WaitTime = 800
        local Nearby = false
        for i = 1, #sharedConfig.registers do
            if #(PlayerCoords - sharedConfig.registers[i].coords) <= 1.4 and sharedConfig.registers[i].robbed then
                WaitTime = 0
                Nearby = true
                if config.useDrawText then
                    if not HasShownText then
                        HasShownText = true
                        lib.showTextUI(Lang:t('text.register_empty'), {position = 'left-center'})
                        exports['qbx-core']:DrawText()
                    end
                else
                    DrawText3D(Lang:t('text.register_empty'), sharedConfig.registers[i].coords)
                end
            end
        end
        if not Nearby and HasShownText then
            HasShownText = false
            lib.hideTextUI()
        end
        Wait(WaitTime)
    end
end)

CreateThread(function()
    local HasShownText
    while true do
        local PlayerCoords = GetEntityCoords(cache.ped)
        local WaitTime = 800
        local Nearby = false
        local Text
        for i = 1, #sharedConfig.safes do
            if #(PlayerCoords - sharedConfig.safes[i].coords) <= 1.4 then
                WaitTime = 0
                Nearby = true
                if sharedConfig.safes[i].robbed then
                    Text = Lang:t('text.safe_opened')
                else
                    Text = Lang:t('text.try_combination')
                    if IsControlJustPressed(0, 38) then
                        TriggerServerEvent('qb-storerobbery:server:trysafe')
                    end
                end
                if config.useDrawText then
                    if not HasShownText then
                        HasShownText = true
                        lib.showTextUI(Text, {position = 'left-center'})
                    end
                else
                    DrawText3D(Text, sharedConfig.safes[i].coords)
                end
            end
        end
        if not Nearby and HasShownText then HasShownText = false lib.hideTextUI() end
        Wait(WaitTime)
    end
end)

RegisterNetEvent('qb-storerobbery:client:startRegister', function(IsAdvanced)
    isUsingAdvanced = IsAdvanced
    StartLockpick(true)
end)

RegisterNUICallback('success', function(_, cb)
    StartLockpick(false)
    OpeningRegisterHandler(config.openRegisterTime)
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
        TriggerServerEvent('qb-storerobbery:server:openregister', true)
    else -- if canceled
        openingRegister = false
        TriggerServerEvent('qb-storerobbery:server:cancelledregister')
        QBCore.Functions.Notify(Lang:t('error.process_canceled'), 'error')
    end
    cb('ok')
end)

RegisterNUICallback('fail', function(_, cb)
    StartLockpick(false)
    if not IsWearingGloves() then
        local FingerDropChance = isUsingAdvanced and math.random(0, 30) or math.random(0, 60)
        if FingerDropChance > math.random(0, 100) then TriggerServerEvent('evidence:server:CreateFingerDrop', GetEntityCoords(cache.ped)) end
    end
    TriggerServerEvent('qb-storerobbery:server:failedregister', isUsingAdvanced)
    cb('ok')
end)

RegisterNUICallback('exit', function(_, cb)
    StartLockpick(false)
    TriggerServerEvent('qb-storerobbery:server:exitedregister')
    cb('ok')
end)

RegisterNetEvent('qb-storerobbery:client:syncconfig', function(Registers, Safes)
    sharedConfig.registers = Registers
    sharedConfig.safes = Safes
end)

RegisterNetEvent('qb-storerobbery:client:trysafe', function(ClosestSafeIndex, Combination)
    currentCombination = Combination
    if sharedConfig.safes[ClosestSafeIndex].type == 'keypad' then
        SendNUIMessage({
            action = 'openKeypad',
        })
        SetNuiFocus(true, true)
    else
        TriggerEvent('SafeCracker:StartMinigame', currentCombination)
    end
end)

RegisterNetEvent('SafeCracker:EndMinigame', function(HasWon)
    if HasWon then
        TriggerServerEvent('qb-storerobbery:server:successsafe')
        SafeAnim()
    else
        TriggerServerEvent('qb-storerobbery:server:failedsafe')
    end
end)

RegisterNUICallback('PadLockClose', function(_, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('qb-storerobbery:server:failedsafe')
    cb('ok')
end)

RegisterNUICallback('CombinationFail', function(_, cb)
    local SoundId = GetSoundId()
    PlaySound(SoundId, 'Place_Prop_Fail', 'DLC_Dmod_Prop_Editor_Sounds', false, 0, true)
    ReleaseSoundId(SoundId)
    cb('ok')
end)

RegisterNUICallback('TryCombination', function(data, cb)
    SetNuiFocus(false, false)
    if tonumber(data.combination) == currentCombination then
        TriggerServerEvent('qb-storerobbery:server:successsafe')
        SendNUIMessage({
            action = "closeKeypad",
            error = false
        })
        SafeAnim()
    else
        TriggerServerEvent('qb-storerobbery:server:failedsafe')
        SendNUIMessage({
            action = "closeKeypad",
            error = true
        })
    end
    cb('ok')
end)
