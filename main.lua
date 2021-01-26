function QuickApp:onInit()
    self:debug("[LookO2] Init quick app")
    QuickApp.looko2Client = ApiClient:new(self:getVariable("API_TOKEN"))

    local settings = api.get('/globalVariables/looko2')
    if settings == nil then
        self:trace("[LookO2] Settings not found, creating with default values")
        api.post('/globalVariables', {
            name = 'looko2',
            value = json.encode({
                schema_version = 1,
                picked_metric = "PM2.5"
            })
        })
    end

    self.sensorsMap = {}

    self:initChildDevices({
        ["com.fibaro.multilevelSensor"] = AirQualitySensor
    })
    self:initChildDevices()
    self:createMissingSensors()
    --self:loop(30)
    -- self:updateProperty('manufacturer', "LookO2")
end


function QuickApp:createChild(sensorLabel)
    local child = self:createChildDevice({
        name = sensorLabel,
        type = "com.fibaro.multilevelSensor",
    }, AirQualitySensor)

    self:trace("[LookO2][createChild] Device for ", sensorLabel, " sensor created under ID ", child.id)
    return child
end


function QuickApp:createMissingSensors()
    for i, name in ipairs({"PM1", "PM2.5", "PM10"}) do
        if self.sensorsMap[name] == nil then

          self:debug("[LookO2][createMissingSensors] ",name, " is missing, creating ")
          self.sensorsMap[name] = self:createChild(name)
        end
    end
end

function QuickApp:initChildDevices()
    for id,device in pairs(self.childDevices) do
        self.sensorsMap[device.name] = id
        self:debug("[LookO2][initChildDevices] Found ", device.name, " sensor under device ID ", id, " (type: ", device.type, ")")
    end
end


function QuickApp:loop(minutes)
    -- re-run after 30 minutes
    fibaro.setTimeout(minutes * 60 * 1000, function()
        self:loop()
    end)

    local settings = json.decode(api.get('/globalVariables/looko2').value)
    self:reloadDeviceData(settings.picked_metric)
end


function QuickApp:reloadDeviceData(metric)
    self:debug("[LookO2][reloadDeviceData] Picked Metric: ", metric)
    self.looko2Client:getLastSensorMesurement(
        self:getVariable("DEVICE_ID"),
        function(response)
            self:debug("[LookO2] Got API response", response)

            self:updateProperty("unit", metric)
            if (metric == "PM2.5") then
                self:updateProperty("value", tonumber(response.PM25))
            elseif (metric == "PM10") then
                self:updateProperty("value", tonumber(response.PM10))
            elseif (metric == "PM1") then
                self:updateProperty("value", tonumber(response.PM1))
            else
                self:updateProperty("value", tonumber(response.PM25))
                self:updateProperty("unit", "PM2.5")
            end
        end,
        function(message)
            self:debug("[LookO2] error:", message)
        end
    )
end

function QuickApp:updatePickedMetric(metric)
    self:debug("[LookO2] Update settings. Picked Metric: ", metric)

    self:updateView("buttonPM1", "text", "PM1 [ ]")
    self:updateView("buttonPM25", "text", "PM25 [ ]")
    self:updateView("buttonPM10", "text", "PM10 [ ]")

    if (metric == "PM1") then
        self:updateView("buttonPM1", "text", "PM1 [X]")
    elseif (metric == "PM2.5") then
        self:updateView("buttonPM25", "text", "PM25 [X]")
    elseif (metric == "PM10") then
        self:updateView("buttonPM10", "text", "PM10 [X]")
    end

    local response = api.put('/globalVariables/looko2', {
        value = json.encode({
            schema_version = 1,
            picked_metric = metric
        })
    })
end

function QuickApp:onButtonPM25Click(event)
    self:updatePickedMetric("PM2.5")
    self:reloadDeviceData("PM2.5")
end

function QuickApp:onButtonPM10Click(event)
    self:updatePickedMetric("PM10")
    self:reloadDeviceData("PM10")
end

function QuickApp:onButtonPM1Click(event)
    self:updatePickedMetric("PM1")
    self:reloadDeviceData("PM1")
end

function QuickApp:initializeChildren()
    self.builder:initChildren({
        [OWSensor.class] = OWSensor,
        [OWTemperature.class] = OWTemperature,
        [OWWind.class] = OWWind,
        [OWHumidity.class] = OWHumidity,
        [OWRain.class] = OWRain,
    })
end
