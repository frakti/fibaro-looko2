class "GitHubResources"

function GitHubResources:new()
    self.repository = "frakti/fibaro-looko2"
    self.branch = "master"
    return self
end

function GitHubResources:fetchResource(key, success, error)
  local url = string.format("https://raw.githubusercontent.com/%s/%s/%s", self.repository, self.branch, key)
  local client = net.HTTPClient({timeout=10000})
    client:request(url, {
      options = {
        method = "GET",
        headers = {}
      },
      success = success,
      error = function (error)
        QuickApp:error(json.encode(error))
      end
    })
end
