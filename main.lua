function QuickApp:onInit()
  self:debug("[LookO2] Initializing app")
    QuickApp.i18n = i18n:new()
    QuickApp.GUI = GUI:new(self, self.i18n)
    QuickApp.settings = Settings:new()
    QuickApp.dailyParticleMeanChecker = DailyParticleMeanChecker:new(self.settings)
    self.GUI:load(self.settings)
    QuickApp.looko2Client = ApiClient:new(self:getVariable("API_TOKEN"))
    self.sensorsMap = {}
    self:initChildDevices({
        ["com.fibaro.multilevelSensor"] = AirQualitySensor
    })
    self:initializeChildDevices()
    self:createMissingSensors()

    local secondsToNextRefresh = self.settings:get("nextRefreshAt") - os.time()
    if secondsToNextRefresh <= 0 then
      self:debug("[LookO2][onInit] It's been more than 30 minutes since last data refresh, triggering it immedietely")
      self:loop()
    else
      self:debug("[LookO2][onInit] Scheduling first data refresh to trigger ater", secondsToNextRefresh, " seconds")
      fibaro.setTimeout(secondsToNextRefresh * 1000, function()
        self:loop()
      end)
    end
end

function QuickApp:createChild(sensorLabel)
    local parentRoomId = api.get('/devices/' .. self.id).roomID
    local child = self:createChildDevice({
        name = sensorLabel,
        type = "com.fibaro.multilevelSensor",
    }, AirQualitySensor)

    api.put('/devices/' .. child.id, {roomID = parentRoomId, properties = {
      quickAppVariables = {{ name = "sensor", value = sensorLabel }}
    }})

    self:trace("[LookO2][createChild] Device for ", sensorLabel, " sensor created under ID ", child.id)
    return child
end

function QuickApp:getChildDevice(sensorLabel)
    local deviceId = self.sensorsMap[sensorLabel]
    return self.childDevices[deviceId]
end

function QuickApp:createMissingSensors()
    for i, name in ipairs({"PM1", "PM2.5", "PM10"}) do
        if self.sensorsMap[name] == nil then

          self:debug("[LookO2][createMissingSensors] ",name, " is missing, creating ")
          self.sensorsMap[name] = self:createChild(name)
        end
    end
end

function QuickApp:initializeChildDevices()
    for id, device in pairs(self.childDevices) do
      local quickAppVariables = {}
      for _, var in pairs(device.properties.quickAppVariables) do
          quickAppVariables[var.name] = var.value
      end

      self.sensorsMap[quickAppVariables.sensor] = id
      self:debug("[LookO2][initChildDevices] Found ", quickAppVariables.sensor, " sensor under device ID: ", id)
    end
end



function QuickApp:loop()
  local nextRefreshAfter = 30 * 60;
  self:debug("[LookO2] Scheduling next data raload afer ",  nextRefreshAfter, " seconds")
  fibaro.setTimeout(nextRefreshAfter * 1000, function()
    self:loop()
  end)
  self.settings:persist('nextRefreshAt', os.time() + nextRefreshAfter)

  self:reloadDeviceData()
end

function QuickApp:onFindNearestDevice(event)
  local location = api.get('/settings/location')
  self.looko2Client:getClosestSensor(
    location.latitude, location.longitude,
    function (response)

      local distance = geo_distance(tonumber(response.Lat), tonumber(response.Lon), location.latitude, location.longitude)
      self:updateView(
          "nearest_sensor", "text",
          self.i18n:get("nearest_sensor_summary", response.Device, distance)
      )
    end
  )
end

function QuickApp:reloadDeviceData()
  local icons = {
    not_available = "💤",
    very_good = "🔵",
    good = "🟢",
    moderate = "🟡",
    satisfactory = "🟠",
    bad = "🔴",
    hazardous = "🟣"
  }

  self:debug("[LookO2][reloadDeviceData] Triggered")
  self.looko2Client:getLastSensorMesurement(
      self:getVariable("DEVICE_ID"),
      function(response)
          self:debug("[LookO2] Got API response", response)
          self.settings:persist('lastSuccessResponse', response)

          self:getChildDevice("PM2.5"):updateValue(tonumber(response.PM25))
          self:getChildDevice("PM10"):updateValue(tonumber(response.PM10))
          self:getChildDevice("PM1"):updateValue(tonumber(response.PM1))

          local airQualityIndex = tonumber(response.IJP)
          if (airQualityIndex == 0) then
            pickedIcon = icons.very_good
          elseif (airQualityIndex <= 2) then
            pickedIcon = icons.good
          elseif (airQualityIndex <= 4) then
            pickedIcon = icons.moderate
          elseif (airQualityIndex <= 6) then
            pickedIcon = icons.satisfactory
          elseif (airQualityIndex <= 9) then
            pickedIcon = icons.bad
          else
            pickedIcon = icons.hazardous
          end

          local indexChange = tonumber(response.IJP) - tonumber(response.PreviousIJP);
          local increaseIcon = indexChange > 0 and " (📈+".. indexChange .. ")" or ""
          local decreaseIcon = indexChange < 0 and " (📉".. indexChange .. ")" or ""

          local sensorsLog = pickedIcon .. " " .. response.IJPStringEN .. increaseIcon .. decreaseIcon
          self:getChildDevice("PM2.5"):updateProperty("log", sensorsLog)
          self:getChildDevice("PM10"):updateProperty("log", sensorsLog)
          self:getChildDevice("PM1"):updateProperty("log", sensorsLog)

          local location = api.get('/settings/location')
          self:updateView(
              "summary", "text",
              self.i18n:get(
                "last_collect_summary",
                self:getVariable("DEVICE_ID"),
                geo_distance(tonumber(response.Lat), tonumber(response.Lon), location.latitude, location.longitude),
                os.date("%Y-%m-%d %X"),
                os.date("%Y-%m-%d %X", tonumber(response.Epoch)),
                tonumber(response.PM1),
                tonumber(response.PM25), (tonumber(response.PM25) / 25) * 100,
                tonumber(response.PM10), (tonumber(response.PM10) / 50) * 100,
                tonumber(response.Temperature),
                pickedIcon .. self.i18n:pickByLang({ pl = response.IJPString, en = response.IJPStringEN}) .. increaseIcon .. decreaseIcon,
                self.i18n:pickByLang({
                  pl = response.IJPDescription,
                  en = response.IJPDescriptionEN
                })
              )
          )

          self.dailyParticleMeanChecker:record(tonumber(response.Epoch), tonumber(response.AveragePM25))
      end,
      function(message)
          self:debug("[LookO2][reloadDeviceData] error:", message)
      end
  )
end

function geo_distance(lat1, lon1, lat2, lon2)
  if lat1 == nil or lon1 == nil or lat2 == nil or lon2 == nil then
    return nil
  end
  local dlat = math.rad(lat2-lat1)
  local dlon = math.rad(lon2-lon1)
  local sin_dlat = math.sin(dlat/2)
  local sin_dlon = math.sin(dlon/2)
  local a = sin_dlat * sin_dlat + math.cos(math.rad(lat1)) * math.cos(math.rad(lat2)) * sin_dlon * sin_dlon
  local c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
  -- 6378 km is the earth's radius at the equator.
  -- 6357 km would be the radius at the poles (earth isn't a perfect circle).
  -- Thus, high latitude distances will be slightly overestimated
  -- To get miles, use 3963 as the constant (equator again)
  local d = 6378 * c
  return d
end

function QuickApp:onRefreshClick(event)
    self:reloadDeviceData()
end
