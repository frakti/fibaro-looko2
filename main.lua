function QuickApp:onInit()
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
    self:loop(30)
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


function QuickApp:loop(minutes)
    -- re-run after 30 minutes
    fibaro.setTimeout(minutes * 60 * 1000, function()
        self:loop()
    end)

    local settings = json.decode(api.get('/globalVariables/looko2').value)
    self:reloadDeviceData(settings)
end


function QuickApp:reloadDeviceData(settings)
    self:debug("[LookO2][reloadDeviceData] Triggered")
    self.looko2Client:getLastSensorMesurement(
        self:getVariable("DEVICE_ID"),
        function(response)
            self:debug("[LookO2] Got API response", response)
            self:getChildDevice("PM2.5"):updateProperty("value", tonumber(response.PM25))
            self:getChildDevice("PM10"):updateProperty("value", tonumber(response.PM10))
            self:getChildDevice("PM1"):updateProperty("value", tonumber(response.PM1))

            self:updateView(
                "updated_at", "text",
                "Server data: " .. os.date("%Y-%m-%d %X", tonumber(response.Epoch)) .. "\n \n" ..
                "Last refresh at: " .. os.date("%Y-%m-%d %X")
            )
        end,
        function(message)
            self:debug("[LookO2] error:", message)
        end
    )
end

function QuickApp:onRefreshClick(event)
    self:reloadDeviceData()
end
