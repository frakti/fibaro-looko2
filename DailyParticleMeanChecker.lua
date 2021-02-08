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

  QuickApp:debug("[DNC] Measurement above norm", recordDate, value)
  local hourlyParticleAverages = self.settings:get("hourlyParticleAverages") or {}
  QuickApp:debug("[DNC] Fetched averages above norm", json.encode(hourlyParticleAverages))
  local lastDayAverages = {}

  local canPersistNewRecord = true
  for _, measurement in pairs(hourlyParticleAverages) do

    -- all persisted measurements must be older than one hour of new records to make to persist it
    QuickApp:debug("[DNC] IT:" .. _ .. "Check is after 1 hour", recordDate - measurement.d, recordDate - measurement.d > HOUR)
    if (recordDate - measurement.d) < HOUR then
      canPersistNewRecord = false
    end

    -- drop measurements older than one day
     QuickApp:debug("[DNC] IT:" .. _ .. "Check is from last 24 hours", os.time() - measurement.d  < DAY)
    if ((os.time() - measurement.d) < DAY) then
      table.insert(lastDayAverages, measurement)

      if measurement.d < PM25_DAILY_MEAN then
        countHoursAboveThreshold = countHoursAboveThreshold + 1
      end
    end

  end
  if (canPersistNewRecord) then
    table.insert(lastDayAverages, {d = recordDate, v = value})
    if value < PM25_DAILY_MEAN then
      countHoursAboveThreshold = countHoursAboveThreshold + 1
    end
  end
  self.settings:persist("hourlyParticleAverages", lastDayAverages)

  -- trigger custom event if required
  -- local countHoursAboveThreshold = rawlen(lastDayAverages)

  QuickApp:debug("[DNC] Can send event", canPersistNewRecord, countHoursAboveThreshold >= exceededHoursThreshold, self:haveNotTriggeredWithinGivenHours(exceededHoursThreshold))

  if (countHoursAboveThreshold >= exceededHoursThreshold and self:haveNotTriggeredWithinGivenHours(exceededHoursThreshold)) then
     self.settings:persist("lastEventTriggerAt", os.time() - 1) -- decreasing to avoid too fast record and missed trigger
    QuickApp:debug("[DNC] Trigger custom event")
    api.post("/customEvents/" .. EVENT_NAME)
  end
end

function DailyParticleMeanChecker:haveNotTriggeredWithinGivenHours(hours)
  return os.time() - self.settings:get("lastEventTriggerAt") > HOUR * hours
end
