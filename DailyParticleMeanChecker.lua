class "DailyParticleMeanChecker"

local DAY = 24 * 60 * 60
local HOUR = 60 * 60
local EVENT_NAME = "PM25_Mean_Exceeded"

function DailyParticleMeanChecker:new(qa, settings)
  self.qa = qa
  self.settings = settings

  local _, code = api.get("/customEvents/" .. EVENT_NAME)
  if code == 404 then
    QuickApp:debug("[DailyParticleMeanChecker] Event definition doesn't exist, creating it")
    api.post("/customEvents", {
      name = EVENT_NAME,
      userDescription = "Triggered when fine particle (PM2.5) 24-hour mean is exceeded for predefined number of hours (EXCEEDED_HOURS variable in LoookO2 QuickApp)"
    })
  end

  return self
end

function DailyParticleMeanChecker:record(recordDate, value)
  local exceededHoursThreshold = tonumber(self.qa:getVariable("EXCEEDED_HOURS")) or 12
  local PM25_DAILY_MEAN = tonumber(self.qa:getVariable("PM25_DAILY_MEAN")) or 25

  local countHoursAboveThreshold = 0

  local hourlyParticleAverages = self.settings:get("hourlyParticleAverages") or {}
  local lastDayAverages = {}

  local canPersistNewRecord = true
  for _, average in pairs(hourlyParticleAverages) do

    -- all persisted averages must be older than one hour of new records to make to persist it
    if (recordDate - average.d) < HOUR then
      canPersistNewRecord = false
    end

    -- drop averages older than one day
    if ((os.time() - average.d) < DAY) then
      table.insert(lastDayAverages, average)

      if average.v > PM25_DAILY_MEAN then
        countHoursAboveThreshold = countHoursAboveThreshold + 1
      end
    end
  end
  if (canPersistNewRecord) then
    table.insert(lastDayAverages, {d = recordDate, v = value})
    if value > PM25_DAILY_MEAN then
      countHoursAboveThreshold = countHoursAboveThreshold + 1
    end
  end
  self.settings:persist("hourlyParticleAverages", lastDayAverages)

  if (countHoursAboveThreshold >= exceededHoursThreshold and self:haveNotTriggeredWithinGivenHours(exceededHoursThreshold)) then
     self.settings:persist("lastEventTriggerAt", os.time() - 1) -- decreasing to avoid too fast record and missed trigger
    api.post("/customEvents/" .. EVENT_NAME)
  end
end

function DailyParticleMeanChecker:haveNotTriggeredWithinGivenHours(hours)
  return os.time() - self.settings:get("lastEventTriggerAt") > HOUR * hours
end
