class "DailyNormChecker"

local DAY = 24 * 60 * 60
local HOUR = 60 * 60
local PM25_DAILY_NORM = 25

function DailyNormChecker:new(settings)
  self.settings = settings
  return self
end

function DailyNormChecker:record(recordDate, value)
  if value < PM25_DAILY_NORM then
    return
  end

  local averagesAboveNorm = self.settings:get("averages_above_norm") or {}
  local lastDayAverages = {}

  local canPersistNewRecord = true
  for _, measurement in pairs(averagesAboveNorm) do

    -- all persisted measurements must be older than one hour of new records to make to persist it
    if (recordDate - mesurement.d) < HOUR then
      canPersistNewRecord = false
    end

    -- drop measurements older than one day
    if ((os.time() - mesurement.d) < DAY) then
      table.insert(lastDayAverages, mesurement)
    end
  end
  if (canPersistNewRecord) then
    table.insert(lastDayAverages, {d = recordDate, v = value})
  end
  self.settings:persist("averages_above_norm", lastDayAverages)

  -- trigger custom event if required
  local countHoursAboveThreshold = table.getn(lastDayAverages)
  local exceededHoursThreshold = self.settings:get("exceeded_hours_norm_threshold")
  if (canPersistNewRecord and countHoursAboveThreshold >= exceededHoursThreshold and self.haveNotTriggeredWithinGivenHours(exceededHoursThreshold)) then
     self.settings:persist("last_custom_event_trigger", os.time())

    -- api.put("/custom_events", {})
  end
end

function DailyNormChecker:haveNotTriggeredWithinGivenHours(hours)
  return os.time() - self.settings:get("last_custom_event_trigger") > HOUR * hours
end


--[[
Assumptions:
-
]]
