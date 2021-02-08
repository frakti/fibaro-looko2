translations = {
  pl = {
    ['title'] = 'LookO2 - Czujniki Jakości Powietrza',
    ['refresh_data'] = 'Odśwież dane czujników',
    ['find_nearest_device'] = 'Znajdź najbliższy czujnik',
    ['last_collect_summary'] = [[
      Wybrany czujnik: <font color="green">%s</font> (<font color="green">%.2f km</font> od Twojej lokalizacji).
      Data pobrania danych z API: <font color="green">%s</font>
      Data ostatniego odczytu sensora: <font color="green">%s</font>

      Odczyt:
      - Stężenie PM1: <font color="green">%s ㎍/㎥</font>
      - Stężenie PM2.5: <font color="green">%s ㎍/㎥ (%.0f%%)</font>
      - Stężenie PM10: <font color="green">%s ㎍/㎥ (%.0f%%)</font>
      - Temperatura: <font color="green">%s °C</font>
      - Stan jakości powietrza: %s
      - Opis: %s
    ]],
    ['sensor_issue_dirty'] = '<font color="red">UWAGA! Wybrany czujnik może nie pokazywać dokładnych danych. Podejrzenie zabrudzenia.</font>',
    ['sensor_issue_offline'] = '<font color="red">UWAGA! Wybrany czujnik nie pokazuje aktualnych danych. Ostatni odczyt jest starszy niż 1 dzień.</font>',
    ['sensor_issue_log'] = 'Problem z wybranym sensorem',
    ['nearest_sensor_summary'] = 'Najbliższe urządzenie to <font color="green">%s</font>, które jest położone <font color="green">%.2f km</font> od ustawionej lokalizacji.',
    ['version'] = 'Wersja: %s',
  },
  en = {
    ['title'] = 'LookO2 - Air Quality Sensors',
    ['refresh_data'] = 'Refresh sensors data',
    ['find_nearest_device'] = 'Find nearest sensor',
    ['last_collect_summary'] = [[
      Picked sensor: <font color="green">%s</font> (it's <font color="green">%.2f km</font> from your location).
      Fetch date from API: <font color="green">%s</font>
      Last sensor reading date: <font color="green">%s</font>

      Readings:
      - PM1: <font color="green">%s ㎍/㎥</font>
      - PM2.5: <font color="green">%s ㎍/㎥ (%.0f%%)</font>
      - PM10: <font color="green">%s ㎍/㎥ (%.0f%%)</font>
      - Temperature: <font color="green">%s °C</font>
      - Air quality rating: %s
      - Description: %s
    ]],
    ['sensor_issue_dirty'] = '<font color="red">ATTENTION! Picked sensor may not present precise data. Looks like it\'s dirty.</font>',
    ['sensor_issue_offline'] = '<font color="red">ATTENTION! Picked sensor doesn\'t present up-to-date data. Last reading is older than one day.</font>',
    ['sensor_issue_log'] = 'Picked sensor issue',
    ['nearest_sensor_summary'] = 'The nearest device is <font color="green">%s</font> which is <font color="green">%.2f km</font> from location you\'ve defined in HC settings.',
    ['version'] = 'Version: %s',
  }
}
