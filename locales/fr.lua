local Translations = {
    error = {
        no_police = "Pas assez de policiers (%{Required} Requis)",
        process_canceled = "Annulé..",
        lockpick_broken = "Vous avez cassé l'outil de crochetage"
    },
    text = {
        register_empty = "La caisse est vide",
        try_combination = "~g~E~w~ - Essayer la combinaison",
        safe_opened = "Coffre-fort ouvert",
        emptying_the_register= "Vide la caisse..",
        safe_code = "Code du Coffre-fort: "
    },
}

if GetConvar('qb_locale', 'en') == 'fr' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end

