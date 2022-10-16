# qb-storerobbery
Gives the player the ability to rob the default stores around the map. Rob the registers through the use of the `lockpick` or `advancedlockpick` item. And crack the safes through minigames.

## Config
- OpenRegisterTime
  - Determines how long the progressbar and animation will last when robbing a register with a `lockpick`. Prefferably this should be a number divisble by 2. Number in milliseconds.
- RegisterReward
  - Minimum and maximum value that gets given to the player robbing a register. Reward is defaulted to cash
  - ChanceAtSticky
    - Percentage chance that the player will get a `stickynote` reward with the pin code to open the `keypad` safe type
- RegisterRefresh
  - Minimum and maximum time it takes for a register to refresh after being robbed. Number in milliseconds.
- SafeReward
  - MarkedBillsAmount
    - Minimum and maximum amount of `markedbills` bags you get when robbing a safe.
  - MarkedBillsWorth
    - The value that should be added to the `markedbills` bags.
  - ChanceAtSpecial
    - Chance in percentage of the player also getting `rolex` item when robbing a safe. With minimum and max values. The chance is divided by 2 to determine if the player should also get `goldbar` item. Aka half the chance of `rolex`.
- SafeRefresh
  - Time it takes for a safe to refresh after being robbed. Number in milliseconds.
- MinimumCops
  - The amount of cops required to start a store robbery. To fend of grinders and force RolePlaying.
- NotEnoughCopsNotify
  - Notify the player wheter or not there aren't enough cops when trying to rob.
- CallCopsTimeout
  - To prevent police report spam. Only create a police alert _per_ player per timeout. Number in milliseconds.
- UseDrawText
  - Wheter or not to use DrawTextUI or 3DText