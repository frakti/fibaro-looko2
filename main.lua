function QuickApp:onInit()
    QuickApp.i18n = i18n:new()
    QuickApp.GUI = GUI:new(self, self.i18n)

    self.lastSuccessResponse = {}

    self:debug("[LookO2] Init quick app")
    QuickApp.looko2Client = ApiClient:new(self:getVariable("API_TOKEN"))

    local settings = api.get('/globalVariables/looko2')
    if settings == nil then
        self:trace("[LookO2] Settings not found, creating with default values")
        api.post('/globalVariables', {
            name = 'looko2',
            value = json.encode({
                schema_version = 1
            })
        })
    end

    self.sensorsMap = {}

    self:initChildDevices({
        ["com.fibaro.multilevelSensor"] = AirQualitySensor
    })
    self:initializeChildDevices()
    self:createMissingSensors()
    self:loop()
    -- self:updateProperty('manufacturer', "LookO2")
end

function QuickApp:createChild(sensorLabel)
    local parentRoomId = api.get('/devices/' .. self.id).roomID
    local child = self:createChildDevice({
        name = sensorLabel,
        type = "com.fibaro.multilevelSensor",
    }, AirQualitySensor)

    api.put('/devices/' .. child.id, {roomID = parentRoomId, properties = {
      quickAppVariables = {{ name = sensorLabel }}
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
    for id,device in pairs(self.childDevices) do
        self.sensorsMap[device.name] = id
        self:debug("[LookO2][initChildDevices] Found ", device.name, " sensor under device ID ", id, " (type: ", device.type, ")")
    end
end



function QuickApp:loop()
  function scheduleNextReload(response)
    local nextRefreshAfter = 1800 - (os.time() - tonumber(response.Epoch)) -- seconds
    if nextRefreshAfter < 0 then
      nextRefreshAfter = 1800 -- TODO count occurences, high value suggests sensor might not be responding for some time
    end
    self:debug("[LookO2] Scheduling next data raload afer ",  nextRefreshAfter, " seconds")

    fibaro.setTimeout(nextRefreshAfter * 1000, function()
        self:loop()
    end)
  end

  self:reloadDeviceData(scheduleNextReload)
end


function QuickApp:reloadDeviceData(callback)
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
            self.lastSuccessResponse = response
            self:getChildDevice("PM2.5"):updateProperty("value", tonumber(response.PM25))
            self:getChildDevice("PM10"):updateProperty("value", tonumber(response.PM10))
            self:getChildDevice("PM1"):updateProperty("value", tonumber(response.PM1))

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

            local indexChange = tonumber(response.PreviousIJP) - tonumber(response.IJP);
            local increaseIcon = indexChange > 0 and " (📈+".. indexChange .. ")" or ""
            local decreaseIcon = indexChange < 0 and " (📉".. indexChange .. ")" or ""

            local sensorsLog = pickedIcon .. " " .. response.IJPStringEN .. increaseIcon .. decreaseIcon
            self:getChildDevice("PM2.5"):updateProperty("log", sensorsLog)
            self:getChildDevice("PM10"):updateProperty("log", sensorsLog)
            self:getChildDevice("PM1"):updateProperty("log", sensorsLog)

            local location = api.get('/settings/location')
            self:updateView(
                "summary", "text",

                self.i18n:get("last_measurement") .. os.date("%Y-%m-%d %X", tonumber(response.Epoch)) .. "\n \n" ..
                self.i18n:get("last_refresh") .. os.date("%Y-%m-%d %X"),
                self.i18n:get("picked_sensor_distanse"), geo_distance(tonumber(response.Lat),tonumber(response.Lon),location.latitude, location.longitude)
            )
            callback(response)
        end,
        function(message)
            self:debug("[LookO2] error:", message)
            callback({ Epoch = os.time() })
        end
    )
end

local function geo_distance(lat1, lon1, lat2, lon2)
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
    self:reloadDeviceData(
    function () end
  )
end
