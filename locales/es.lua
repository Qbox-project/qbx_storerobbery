local Translations = {
    error = {
        no_police = "No hay suficientes policia (%{Required} son requeridos)",
        process_canceled = "Proceso cancelado..",
        lockpick_broken = "Has roto la ganzúa"
    },
    text = {
        register_empty = "La caja registradora está vacía",
        try_combination = "~g~E~w~ - Ingresa la combinación",
        safe_opened = "Caja abierta",
        emptying_the_register= "Vaciando caja registradora..",
        safe_code = "Código de seguridad: "
    },
}

if GetConvar('qb_locale', 'en') == 'es' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
