# Quick App - LookO2 Air Quality Sensor

LookO2 Air Quality sensors integration in our Fibaro HC3.

# Usage

Fill variables:

- `API_TOKEN` - you can get one by contacting kontakt@looko2.com
- `DEVICE_ID` - pick one from [LookO2 map](https://www.looko2.com/heatmap.php) and use ID from URL `search` query param (soon improve it to be more user friendly)

# Roadmap

Current version is not yet ready to be published. Firstly would like to cover:

- [X] Basic app with periodic API pooling and Fibaro device value update
- [ ] Cache previous LookO2 response with TTL 30 minutes (based on `Epoch` from previous response)
- [ ] Create children devices of all desired metrics
- [ ] Pick nearest LookO2 device based location defined in HC settings
- [ ] Add some examples of Scenes using this Quick App
- [ ] Prepare polish docs version
- [ ] Prepare first release

# Development Resources
- [LookO2 API documentation](https://looko2web.nazwa.pl/aktualnosci/api/)
- [Fibaro API](https://manuals.fibaro.com/knowledge-base-browse/rest-api/) - can't find HC3 API but apparently API I'm using still works
