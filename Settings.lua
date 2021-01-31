class 'Settings'

local defaultSettings = {
  lastSuccessResponse = nil
}

function Settings:new()
    local settings = api.get('/globalVariables/looko2')
    self.settings = settings and json.decode(settings.value) or defaultSettings

    if not settings then
      api.post('/globalVariables', {
          name = 'looko2',
          value = json.encode(defaultSettings)
      })
    end

    return self
end

function Settings:persist(key, value)
  self.settings[key] = value
  local result = api.put('/globalVariables/looko2', {
      value = json.encode(self.settings)
  })
end

function Settings:get(key)
  return self.settings[key]
end
