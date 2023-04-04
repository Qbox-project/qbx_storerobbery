local QBCore = exports['qbx-core']:GetCoreObject()
local IsUsingAdvanced
local OpeningRegister
local OpenRegisterDict = 'veh@break_in@0h@p_m_one@'
local OpenRegisterAnim = 'low_force_entry_ds'
local CurrentCombination

local function StartLockpick(bool)
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        action = "ui",
        toggle = bool,
    })
    SetCursorLocation(0.5, 0.2)
end

local function LoadAnimDict(dict) while not HasAnimDictLoaded(dict) do RequestAnimDict(dict) Wait(0) end end

local function OpeningRegisterHandler(LockpickTime)
    OpeningRegister = true
    LoadAnimDict(OpenRegisterDict)
    TaskPlayAnim(cache.ped, OpenRegisterDict, OpenRegisterAnim, 3.0, 3.0, -1, 16, 0, false, false, false)
    CreateThread(function()
        while OpeningRegister do
            TaskPlayAnim(cache.ped, OpenRegisterDict, OpenRegisterAnim, 3.0, 3.0, -1, 16, 0, false, false, false)
            Wait(2000)
            LockpickTime = LockpickTime - 2000
            TriggerServerEvent('qb-storerobbery:server:openregister', false)
            TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
            if LockpickTime <= 0 then
                OpeningRegister = false
                StopAnimTask(cache.ped, OpenRegisterDict, OpenRegisterAnim, 1.0)
            end
        end
    end)
end

local function SafeAnim()
    LoadAnimDict('amb@prop_human_bum_bin@idle_b')
    TaskPlayAnim(cache.ped, 'amb@prop_human_bum_bin@idle_b', 'idle_d', 8.0, 8.0, -1, 50, 0, false, false, false)
    Wait(2500)
    TaskPlayAnim(cache.ped, 'amb@prop_human_bum_bin@idle_b', 'exit', 8.0, 8.0, -1, 50, 0, false, false, false)
end

local function DrawText3D(coords, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText("STRING")
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

CreateThread(function()
    local HasShownText
    while true do
        local PlayerCoords = GetEntityCoords(cache.ped)
        local WaitTime = 800
        local Nearby = false
        for i = 1, #Config.Registers do
            if #(PlayerCoords - Config.Registers[i].coords) <= 1.4 and Config.Registers[i].robbed then
                WaitTime = 0
                Nearby = true
                if Config.UseDrawText then
                    if not HasShownText then HasShownText = true exports['qbx-core']:DrawText(Lang:t('text.register_empty')) end
                else
                    DrawText3D(Config.Registers[i].coords, Lang:t('text.register_empty'))
                end
            end
        end
        if not Nearby and HasShownText then HasShownText = false exports['qbx-core']:HideText() end
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
        for i = 1, #Config.Safes do
            if #(PlayerCoords - Config.Safes[i].coords) <= 1.4 then
                WaitTime = 0
                Nearby = true
                if Config.Safes[i].robbed then
                    Text = Lang:t('text.safe_opened')
                else
                    Text = Lang:t('text.try_combination')
                    if IsControlJustPressed(0, 38) then
                        TriggerServerEvent('qb-storerobbery:server:trysafe')
                    end
                end
                if Config.UseDrawText then
                    if not HasShownText then HasShownText = true exports['qbx-core']:DrawText(Text) end
                else
                    DrawText3D(Config.Safes[i].coords, Text)
                end
            end
        end
        if not Nearby and HasShownText then HasShownText = false exports['qbx-core']:HideText() end
        Wait(WaitTime)
    end
end)

RegisterNetEvent('qb-storerobbery:client:startRegister', function(IsAdvanced)
    IsUsingAdvanced = IsAdvanced
    StartLockpick(true)
end)

RegisterNUICallback('success', function(_, cb)
    StartLockpick(false)
    OpeningRegisterHandler(Config.OpenRegisterTime)
    QBCore.Functions.Progressbar('search_register', Lang:t('text.emptying_the_register'), Config.OpenRegisterTime, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        OpeningRegister = false
        TriggerServerEvent('qb-storerobbery:server:openregister', true)
    end, function() -- Cancel
        OpeningRegister = false
        TriggerServerEvent('qb-storerobbery:server:cancelledregister')
        QBCore.Functions.Notify(Lang:t('error.process_canceled'), 'error')
    end)
    cb('ok')
end)

RegisterNUICallback('fail', function(_, cb)
    StartLockpick(false)
    if not QBCore.Functions.IsWearingGloves() then
        local FingerDropChance = IsUsingAdvanced and math.random(0, 30) or math.random(0, 60)
        if FingerDropChance > math.random(0, 100) then TriggerServerEvent('evidence:server:CreateFingerDrop', GetEntityCoords(cache.ped)) end
    end
    TriggerServerEvent('qb-storerobbery:server:failedregister', IsUsingAdvanced)
    cb('ok')
end)

RegisterNUICallback('exit', function(_, cb)
    StartLockpick(false)
    TriggerServerEvent('qb-storerobbery:server:exitedregister')
    cb('ok')
end)

RegisterNetEvent('qb-storerobbery:client:syncconfig', function(Registers, Safes)
    Config.Registers = Registers
    Config.Safes = Safes
end)

RegisterNetEvent('qb-storerobbery:client:trysafe', function(ClosestSafeIndex, Combination)
    CurrentCombination = Combination
    if Config.Safes[ClosestSafeIndex].type == 'keypad' then
        SendNUIMessage({
            action = 'openKeypad',
        })
        SetNuiFocus(true, true)
    else
        TriggerEvent('SafeCracker:StartMinigame', CurrentCombination)
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
    if tonumber(data.combination) == CurrentCombination then
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
