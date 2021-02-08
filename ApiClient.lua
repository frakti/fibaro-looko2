class 'ApiClient'

function ApiClient:new(token)
    self.token = token
    self.baseUrl = "http://api.looko2.com/"
    return self
end

function ApiClient:getLastSensorMesurement(deviceId, success, error)
    self:get("?method=GetLOOKO&id="..deviceId.."&token="..self.token, success, error)
end

function ApiClient:getAllSensors(success, error)
    self:get("?method=GetAll&token="..self.token, success, error)
end

function ApiClient:getClosestSensor(lat, long, success, error)
    self:get("?method=GPSGetClosestLooko&lat="..lat.."&lon="..long.."&token="..self.token, success, error)
end

function ApiClient:get(query, success, error)
    local client = net.HTTPClient()
    client:request(self.baseUrl..query, {
        options = {
            method = "GET",
            headers = {
                ["Accept"] = "application/json"
            }
        },
        success = function (response)
            if response.data == "Invalid token" then
              error("Provided LookO2 API token is invalid")
              return
            end
            success(json.decode(response.data))
        end,
        error = error
    })
end
