# Bash script for logging of the spot price of electricity in Scandinavia

The ELPRIS bash script (`elpris.sh`) fetches the spot price of electricity in
Scandinavia via the API to https://www.elprisetjustnu.se/. In addition to
merely displaying the captured data, the ELPRIS script also saved it to a
JSON and CSV file, with naming convention data-ZONE-DATE.json and
data-ZONE-DATE.csv, respectively.

```
Syntax: ./elpris.sh [-h|-g|-z <zone>|-d <date>]
options:
 -h          Print this Help.
 -g          Print the GPL license notification.
 -z <zone>   Specify the zone for the spot price to be fetched, where
             <zone> is any of:
                   SE1 = Luleå / Norra Sverige
                   SE2 = Sundsvall / Norra Mellansverige
                   SE3 = Gotland / Stockholm / Södra Mellansverige
                   SE4 = Malmö / Södra Sverige
             If the -z option is omitted, then SE3 will be used as
             default. Example: 'elpris -z SE1'
 -d <date>   Specify the date for the spot price to be fetched, where
             <date> is specified as YYYYMMDD. If the -d option is
             omitted, then the current date will be used as default.
             Example: 'elpris -d 20250421'
```

## Sample output from the script
```
Fetching spot price data for zone SE3 at 2025/04/22 (10:48).
Spot prices in JSON format saved to data-SE3-20250422.json
Spot prices in CSV format saved to data-SE3-20250422.csv
-----------------------------------------------------------------------------
🔻 Lowest (at 00:00): 33.66400 öre/kWh
🔺 Highest (at 20:00): 292.29800 öre/kWh
-----------------------------------------------------------------------------
Time (start)           Öre/kWh    |min                                   max|
-----------------------------------------------------------------------------
2025-04-22 00:00:00        33.7   ||                                        |
2025-04-22 01:00:00        34.1   ||                                        |
2025-04-22 02:00:00        41.7   | |                                       |
2025-04-22 03:00:00        46.6   |  |                                      |
2025-04-22 04:00:00        52.6   |  |                                      |
2025-04-22 05:00:00        61.5   |    |                                    |
2025-04-22 06:00:00        63.3   |    |                                    |
2025-04-22 07:00:00       146.6   |                 |                       |
2025-04-22 08:00:00       184.4   |                       |                 |
2025-04-22 09:00:00       125.0   |              |                          |
2025-04-22 10:00:00       105.5   |           |                             |
2025-04-22 11:00:00        99.7   |          |                              |
2025-04-22 12:00:00        90.4   |        |                                |
2025-04-22 13:00:00        73.0   |      |                                  |
2025-04-22 14:00:00        79.4   |       |                                 |
2025-04-22 15:00:00        87.1   |        |                                |
2025-04-22 16:00:00        92.7   |         |                               |
2025-04-22 17:00:00       110.3   |           |                             |
2025-04-22 18:00:00       134.4   |               |                         |
2025-04-22 19:00:00       211.4   |                           |             |
2025-04-22 20:00:00       292.3   |                                        ||
2025-04-22 21:00:00       172.1   |                     |                   |
2025-04-22 22:00:00       131.9   |               |                         |
2025-04-22 23:00:00       114.3   |            |                            |
-----------------------------------------------------------------------------
```

## Copyright
Copyright (C) 2025, Fredrik Jonsson, under GPLv3. See enclosed LICENSE.

## Location of master source code
The source and documentation can be found at https://github.com/hp35/elpris
