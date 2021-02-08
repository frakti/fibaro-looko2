function QuickApp:onInit()
    QuickApp.i18n = i18n:new()
    QuickApp.GUI = GUI:new(self, self.i18n)
    QuickApp.settings = Settings:new()
    QuickApp.sensorResultFactory = SensorResultFactory:new(self.i18n)
    QuickApp.dailyParticleMeanChecker = DailyParticleMeanChecker:new(self, self.settings)
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
      self:trace("[LookO2][onInit] It's been more than 30 minutes since last data refresh, triggering it immedietely")
      self:loop()
    else
      self:trace("[LookO2][onInit] Scheduling first data refresh to trigger ater", secondsToNextRefresh, " seconds")
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

          self:trace("[LookO2][createMissingSensors] ",name, " is missing, creating")
          self.sensorsMap[name] = self:createChild(name)
        end
    end
end

function QuickApp:initializeChildDevices()
    for id, device in pairs(self.childDevices) do
      local sensor
      for _, var in pairs(device.properties.quickAppVariables) do
          if var.sensor then
            sensor = var.sensor
            break
          end
      end

      self.sensorsMap[sensor] = id
    end
end



function QuickApp:loop()
  local nextRefreshAfter = 30 * 60;
  self:trace("[LookO2] Scheduling next data raload afer ",  nextRefreshAfter, " seconds")
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

      local distance = calculateGeoDistance(tonumber(response.Lat), tonumber(response.Lon), location.latitude, location.longitude)
      self:updateView(
          "nearest_sensor", "text",
          self.i18n:get("nearest_sensor_summary", response.Device, distance)
      )
    end
  )
end

function QuickApp:reloadDeviceData()
  self.looko2Client:getLastSensorMesurement(
      self:getVariable("DEVICE_ID"),
      function(response)
          if not response.PM25 then
            self:error("[LookO2][fetch] Provided DEVICE_ID is wrong and doesn't correspond to any existing LookO2 sensor")
            return
          end

          local result = self.sensorResultFactory:create(response)

          local indexChange = result.currentIJP - result.previousIJP
          local increaseIcon = indexChange > 0 and " (📈+".. indexChange .. ")" or ""
          local decreaseIcon = indexChange < 0 and " (📉".. indexChange .. ")" or ""
          local sensorsLog = result.airQualityIndexIcon .. " " .. result.shortDescription .. increaseIcon .. decreaseIcon
          local location = api.get('/settings/location')

          self:getChildDevice("PM2.5"):updateValue(result.PM25, sensorsLog)
          self:getChildDevice("PM10"):updateValue(result.PM10, sensorsLog)
          self:getChildDevice("PM1"):updateValue(result.PM1, sensorsLog)
          self:updateView(
              "summary", "text",
              self.i18n:get(
                "last_collect_summary",
                self:getVariable("DEVICE_ID"),
                calculateGeoDistance(result.location.lat, result.location.long, location.latitude, location.longitude),
                os.date("%Y-%m-%d %X"),
                os.date("%Y-%m-%d %X", result.readAt),
                result.PM1,
                result.PM25, (result.PM25 / 25) * 100,
                result.PM10, (result.PM10 / 50) * 100,
                result.temperature,
                sensorsLog,
                result.longDescription
              )
              .. ((result.sensorIssues.dirty or result.sensorIssues.abandoned) and self.i18n:get("sensor_issue_dirty") or "")
              .. (result.sensorIssues.offline and self.i18n:get("sensor_issue_offline") or "")
          )

          self.dailyParticleMeanChecker:record(result.readAt, result.avgPM25)
      end,
      function(message)
          self:error("[LookO2][fetch] Couldn't read data from server, cause:", message)
      end
  )
end

-- Used solution from StackOverflow: https://stackoverflow.com/a/21193869
function calculateGeoDistance(lat1, lon1, lat2, lon2)
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
