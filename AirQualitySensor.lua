-- Each devicVe type you create should have its own class which inherits from the QuickAppChild type.
class 'AirQualitySensor' (QuickAppChild)

OWSensor.class = 'com.fibaro.multilevelSensor'

function AirQualitySensor:__init(device)
    QuickAppChild.__init(self, device)
    self:updateProperty("unit", "㎍/㎥")
end

function AirQualitySensor:updateValue(value)
    self:debug("[AirQualitySensor] Change value of ", self.unit, " (device: ", self.id, ") from ", self.id, " to ", value)
    self:updateProperty("value", value)
end
