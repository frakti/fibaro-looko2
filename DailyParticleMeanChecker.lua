class "DailyParticleMeanChecker"

local DAY = 24 * 60 * 60
local HOUR = 60 * 60

function DailyParticleMeanChecker:new(settings)
  self.settings = settings
  return self
end

function DailyParticleMeanChecker:record(recordDate, value)
  local countHoursAboveThreshold = 0

  QuickApp:debug("[DNC] Measurement above norm", recordDate, value)
  local averagesAboveNorm = self.settings:get("averagesAboveNorm") or {}
  QuickApp:debug("[DNC] Fetched averages above norm", json.encode(averagesAboveNorm))
  local lastDayAverages = {}

  local canPersistNewRecord = true
  for _, measurement in pairs(averagesAboveNorm) do

    -- all persisted measurements must be older than one hour of new records to make to persist it
    QuickApp:debug("[DNC] IT:" .. _ .. "Check is after 1 hour", recordDate - measurement.d, recordDate - measurement.d > HOUR)
    if (recordDate - measurement.d) < HOUR then
      canPersistNewRecord = false
    end

    -- drop measurements older than one day
     QuickApp:debug("[DNC] IT:" .. _ .. "Check is from last 24 hours", os.time() - measurement.d  < DAY)
    if ((os.time() - measurement.d) < DAY) then
      table.insert(lastDayAverages, measurement)

      if measurement.d < PM25_DAILY_NORM then
        countHoursAboveThreshold = countHoursAboveThreshold + 1
      end
    end

  end
  if (canPersistNewRecord) then
    table.insert(lastDayAverages, {d = recordDate, v = value})
    if value < PM25_DAILY_NORM then
      countHoursAboveThreshold = countHoursAboveThreshold + 1
    end
  end
  self.settings:persist("averagesAboveNorm", lastDayAverages)

  -- trigger custom event if required
  -- local countHoursAboveThreshold = rawlen(lastDayAverages)
  local exceededHoursThreshold = self.settings:get("exceededHoursNormThreshold")
  QuickApp:debug("[DNC] Can send event", canPersistNewRecord, countHoursAboveThreshold >= exceededHoursThreshold, self:haveNotTriggeredWithinGivenHours(exceededHoursThreshold))

  if (countHoursAboveThreshold >= exceededHoursThreshold and self:haveNotTriggeredWithinGivenHours(exceededHoursThreshold)) then
     self.settings:persist("lastEventTriggerAt", os.time() - 1) -- decreasing to avoid too fast record and missed trigger
    QuickApp:debug("[DNC] Trigger custom event")
    api.post("/customEvents/PM25_Norm_Exceeded")
  end
end

function DailyParticleMeanChecker:haveNotTriggeredWithinGivenHours(hours)
  return os.time() - self.settings:get("lastEventTriggerAt") > HOUR * hours
end
