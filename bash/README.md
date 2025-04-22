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

## Copyright
Copyright (C) 2025, Fredrik Jonsson, under GPLv3. See enclosed LICENSE.

## Location of master source code
The source and documentation can be found at https://github.com/hp35/elpris
