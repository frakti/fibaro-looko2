class 'i18n'

function i18n:new()
    local lang = api.get("/settings/info").defaultLanguage
    if not translations[lang] then
        lang = 'en'
    end
    self.translations = translations[lang]
    self.lang = lang
    return self
end

function i18n:get(key, ...)
    if self.translations[key] then
        return string.format(self.translations[key], ...)
    end
    return key
end

function i18n:pickByLang(translations)
  local pickedTranslation = translations[self.lang]
  if not pickedTranslation then
    return translations["en"]
  end
  return pickedTranslation
end
