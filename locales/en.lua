local Translations = {
    error = {
        no_police = "Not Enough Police (%{Required} Required)",
        process_canceled = "Process canceled..",
        lockpick_broken = "You Broke The Lock Pick"
    },
    text = {
        register_empty = "The Cash Register Is Empty",
        try_combination = "~g~E~w~ - Try Combination",
        safe_opened = "Safe Opened",
        emptying_the_register = "Emptying The Register..",
        safe_code = "Safe Code: "
    },
    alert = {
        register = 'Someone is prying the register!',
        safe = 'Someone is cracking the safe!'
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
