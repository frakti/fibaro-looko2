class 'AirQualitySensor' (QuickAppChild)

AirQualitySensor.class = 'com.fibaro.multilevelSensor'

function AirQualitySensor:__init(device)
    QuickAppChild.__init(self, device)
    self:updateProperty("unit", "㎍/㎥")
end

function AirQualitySensor:updateValue(value, log)
    self:updateProperty("value", value)
    self:updateProperty("log", log or "")
end
