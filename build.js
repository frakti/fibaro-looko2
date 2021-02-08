"use strict";

const fs = require("fs");

const FILES_LIST = [
  { "name": "main", "isMain": true },
  { "name": "ApiClient" },
  { "name": "AirQualitySensor" },
  { "name": "DailyParticleMeanChecker" },
  { "name": "GUI" },
  { "name": "i18n" },
  { "name": "SensorResultFactory" },
  { "name": "Settings" },
  { "name": "translations" },
]

const template = JSON.parse( fs.readFileSync("looko2-template.fqa") );

for (let file of FILES_LIST) {
  const content = fs.readFileSync(`${file.name}.lua`);
  template.files.push({
    name: file.name,
    isMain: file.isMain || false,
    isOpen: false,
    content: content.toString()
  })
}

fs.writeFileSync("looko2-release.fqa", JSON.stringify(template, null, 2));
