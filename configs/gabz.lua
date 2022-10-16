Config = {}

Config.OpenRegisterTime = 24000
Config.RegisterReward = {
    Min = 80,
    Max = 200,
    ChanceAtSticky = 30
}

Config.RegisterRefresh = {
    Min = 420000,
    Max = 900000
}

Config.SafeReward = {
    MarkedBillsAmount = {
        Min = 1,
        Max = 3
    },
    MarkedBillsWorth = {
        Min = 230,
        Max = 600
    },
    ChanceAtSpecial = 40,
    RolexAmount = {
        Min = 2,
        Max = 7
    },
    GoldbarAmount = 2
}

Config.SafeRefresh = {
    Min = 1200000,
    Max = 2400000
}

Config.MinimumCops = 2
Config.NotEnoughCopsNotify = true
Config.CallCopsTimeout = 240000
Config.UseDrawText = false

Config.Registers = {
    [1] = { coords = vector3(-47.24, -1757.65, 29.53), robbed = false, time = 0, safeKey = 1, camId = 4 },
    [2] = { coords = vector3(-48.58, -1759.21, 29.59), robbed = false, time = 0, safeKey = 1, camId = 4 },
    [3] = { coords = vector3(-1486.26, -378.0, 40.16), robbed = false, time = 0, safeKey = 2, camId = 5 },
    [4] = { coords = vector3(-1222.03, -908.32, 12.32), robbed = false, time = 0, safeKey = 3, camId = 6 },
    [5] = { coords = vector3(-706.08, -915.42, 19.21), robbed = false, time = 0, safeKey = 4, camId = 7 },
    [6] = { coords = vector3(-706.16, -913.5, 19.21), robbed = false, time = 0, safeKey = 4, camId = 7 },
    [7] = { coords = vector3(24.91, -1345.7, 29.5), robbed = false, time = 0, safeKey = 5, camId = 8 },
    [8] = { coords = vector3(24.8, -1347.81, 29.5), robbed = false, time = 0, safeKey = 5, camId = 8 },
    [9] = { coords = vector3(1134.15, -982.53, 46.41), robbed = false, time = 0, safeKey = 6, camId = 9 },
    [10] = { coords = vector3(1165.05, -324.49, 69.2), robbed = false, time = 0, safeKey = 7, camId = 10 },
    [11] = { coords = vector3(1164.7, -322.58, 69.2), robbed = false, time = 0, safeKey = 7, camId = 10 },
    [12] = { coords = vector3(373.37, 327.85, 103.57), robbed = false, time = 0, safeKey = 8, camId = 11 },
    [13] = { coords = vector3(372.86, 325.83, 103.57), robbed = false, time = 0, safeKey = 8, camId = 11 },
    [14] = { coords = vector3(-1818.9, 792.9, 138.08), robbed = false, time = 0, safeKey = 9, camId = 12 },
    [15] = { coords = vector3(-1820.17, 794.28, 138.08), robbed = false, time = 0, safeKey = 9, camId = 12 },
    [16] = { coords = vector3(-2966.46, 390.89, 15.04), robbed = false, time = 0, safeKey = 10, camId = 13 },
    [17] = { coords = vector3(-3040.63, 584.44, 7.91), robbed = false, time = 0, safeKey = 11, camId = 14 },
    [18] = { coords = vector3(-3038.57, 585.12, 7.91), robbed = false, time = 0, safeKey = 11, camId = 14 },
    [19] = { coords = vector3(-3243.85, 1000.46, 12.83), robbed = false, time = 0, safeKey = 12, camId = 15 },
    [20] = { coords = vector3(-3241.68, 1000.37, 12.83), robbed = false, time = 0, safeKey = 12, camId = 15 },
    [21] = { coords = vector3(548.85, 2669.7, 42.16), robbed = false, time = 0, safeKey = 13, camId = 16 },
    [22] = { coords = vector3(548.54, 2671.94, 42.16), robbed = false, time = 0, safeKey = 13, camId = 16 },
    [23] = { coords = vector3(1165.9, 2710.81, 38.15), robbed = false, time = 0, safeKey = 14, camId = 17 },
    [24] = { coords = vector3(2676.79, 3280.61, 55.24), robbed = false, time = 0, safeKey = 15, camId = 18 },
    [25] = { coords = vector3(2678.72, 3279.53, 55.24), robbed = false, time = 0, safeKey = 15, camId = 18 },
    [26] = { coords = vector3(1959.64, 3741.61, 32.34), robbed = false, time = 0, safeKey = 16, camId = 19 },
    [27] = { coords = vector3(1960.73, 3739.77, 32.34), robbed = false, time = 0, safeKey = 16, camId = 19 },
    [28] = { coords = vector3(1728.95, 6416.5, 35.04), robbed = false, time = 0, safeKey = 17, camId = 20 },
    [29] = { coords = vector3(1728.02, 6414.57, 35.04), robbed = false, time = 0, safeKey = 17, camId = 20 },
    [30] = { coords = vector3(-161.07, 6321.23, 31.5), robbed = false, time = 0, safeKey = 18, camId = 27 },
    [31] = { coords = vector3(160.44, 6640.92, 31.7), robbed = false, time = 0, safeKey = 19, camId = 28 },
    [32] = { coords = vector3(161.96, 6642.43, 31.7), robbed = false, time = 0, safeKey = 19, camId = 29 },
    [33] = { coords = vector3(1696.67, 4924.37, 42.06), robbed = false, time = 0, safeKey = 20, camId = 35 },
    [34] = { coords = vector3(1698.28, 4923.32, 42.06), robbed = false, time = 0, safeKey = 20, camId = 35 },
    [35] = { coords = vector3(2555.58, 381.32, 108.62), robbed = false, time = 0, safeKey = 21, camId = 36 },
    [36] = { coords = vector3(2557.7, 381.24, 108.62), robbed = false, time = 0, safeKey = 21, camId = 36 },
}

Config.Safes = {
    [1] = { coords = vector3(-43.43, -1748.3, 29.42), type = "keypad", robbed = false, camId = 4 },
    [2] = { coords = vector3(-1478.94, -375.5, 39.16), type = "padlock", robbed = false, camId = 5 },
    [3] = { coords = vector3(-1220.85, -916.05, 11.329), type = "padlock", robbed = false, camId = 6 },
    [4] = { coords = vector3(-709.74, -904.15, 19.21), type = "keypad", robbed = false, camId = 7 },
    [5] = { coords = vector3(31.29, -1339.27, 29.5), type = "keypad", robbed = false, camId = 8 },
    [6] = { coords = vector3(1126.77, -980.1, 45.41), type = "padlock", robbed = false, camId = 9 },
    [7] = { coords = vector3(1159.46, -314.05, 69.2), type = "keypad", robbed = false, camId = 10 },
    [8] = { coords = vector3(381.13, 332.54, 103.57), type = "keypad", robbed = false, camId = 11 },
    [9] = { coords = vector3(-1829.27, 798.76, 138.19), type = "keypad", robbed = false, camId = 12 },
    [10] = { coords = vector3(-2959.64, 387.08, 14.04), type = "padlock", robbed = false, camId = 13 },
    [11] = { coords = vector3(-3048.68, 588.57, 7.91), type = "keypad", robbed = false, camId = 14 },
    [12] = { coords = vector3(-3249.66, 1007.36, 12.83), type = "keypad", robbed = false, camId = 15 },
    [13] = { coords = vector3(543.7, 2662.58, 42.16), type = "keypad", robbed = false, camId = 16 },
    [14] = { coords = vector3(1169.31, 2717.79, 37.15), type = "padlock", robbed = false, camId = 17 },
    [15] = { coords = vector3(2674.36, 3289.25, 55.24), type = "keypad", robbed = false, camId = 18 },
    [16] = { coords = vector3(1961.87, 3750.28, 32.34), type = "keypad", robbed = false, camId = 19 },
    [17] = { coords = vector3(1737.45, 6419.43, 35.04), type = "keypad", robbed = false, camId = 20 },
    [18] = { coords = vector3(-168.40, 6318.80, 30.58), type = "padlock", robbed = false, camId = 27 },
    [19] = { coords = vector3(170.99, 6642.49, 31.7), type = "keypad", robbed = false, camId = 30 },
    [20] = { coords = vector3(1707.9, 4920.49, 42.06), type = "keypad", robbed = false, camId = 35 },
    [21] = { coords = vector3(2549.48, 387.95, 108.62), type = "keypad", robbed = false, camId = 36 },
}
