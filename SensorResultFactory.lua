class "SensorResultFactory"

local icons = {
  not_available = "💤",
  very_good = "🔵",
  good = "🟢",
  moderate = "🟡",
  satisfactory = "🟠",
  bad = "🔴",
  hazardous = "🟣"
}
local DAY = 24 * 60 * 60

function SensorResultFactory:new(i18n)
  self.i18n = i18n
  return self
end

function SensorResultFactory:create(response)
  local result = {
    readAt = tonumber(response.Epoch),
    PM25 = tonumber(response.PM25),
    PM10 = tonumber(response.PM10),
    PM1 = tonumber(response.PM1),
    avgPM25 = tonumber(response.AveragePM25),
    temperature = tonumber(response.Temperature),
    currentIJP = tonumber(response.IJP),
    previousIJP = tonumber(response.PreviousIJP),
    location = {
      lat = tonumber(response.Lat),
      long = tonumber(response.Lon),
    },
    shortDescription = self.i18n:pickByLang({ pl = response.IJPString, en = response.IJPStringEN}),
    longDescription = self.i18n:pickByLang({ pl = response.IJPDescription, en = response.IJPDescriptionEN }),
  }

  result.airQualityIndexIcon = resolveAirQualityIndexIcon(result.currentIJP)
  result.sensorIssues = discoverSensorsIssues(result)

  return result
end


function resolveAirQualityIndexIcon(airQualityIndex)
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
  return pickedIcon
end

function discoverSensorsIssues(result)
  return {
    dirty = result.PM25 > 30000 or result.PM10 > 30000, -- based on feedback from LookO2 Team
    offline =  os.time() - result.readAt > DAY,
    abandoned = result.PM25 == 0 and result.PM10 == 0 and result.PM1 == 0 -- based on feedback from LookO2 Team
  }
end
