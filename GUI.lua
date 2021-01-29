class 'GUI'

function GUI:new(qa, i18n)
    self.qa = qa
    self.i18n = i18n
    return self
end

function GUI:load()
    self.qa:updateView("title", "text", self.i18n:get("title"))
    self.qa:updateView("button_refresh", "text", self.i18n:get("refresh_data"))
    self.qa:updateView("version", "text", self.i18n:get("version", "1.0.0"))
end
