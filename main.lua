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

    self:loop(30)
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
    self:debug("[LookO2] Reload device data. Picked Metric: ", metric)
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
