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

function SensorResultFactory:new(i18n)
  self.i18n = i18n
  return self
end

function SensorResultFactory:create(response)
  return {
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
    airQualityIndexIcon = resolveAirQualityIndexIcon(tonumber(response.IJP))
  }
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
