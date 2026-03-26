# Bash script for logging of the spot price of electricity in Scandinavia

The ELPRIS bash script (`elpris.sh`) fetches the spot price of electricity in
Scandinavia via the API to https://www.elprisetjustnu.se/. In addition to
merely displaying the captured data, the ELPRIS script also saved it to a
JSON and CSV file, with naming convention data-ZONE-DATE.json and
data-ZONE-DATE.csv, respectively.

If used with the -o option, the script also generates human-readable textfiles
containing summaries in two different forms: A short brief list with minimum,
maximum and hourly rates, and a similar one in which we also include a simple
ASCII graph illustrating the daily evolution of the price between its minimum
and maximum.

## Using the script
```
  Syntax: ./elpris.sh [-h|-g|-z <zone>|-d <date>|-o <dir>|-c|-q|-b <brk>]
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
   -o <dir>    Specify the output directory <dir> to which the ELPRIS
             script should save the fetched raw data as well as the
             standard text file summaries generated from it. If the
             -o option is omitted, then the current directory will
             be used for the default storage. If you wish a clean
             execution without any remaining files, use the -c option
             described below. Example: 'elpris -o ~/elpris/log/'
   -c        Clean execution of the ELPRIS script, with only terminal
             output and no generated files left behind. This option
             overrides any setting specified by the -o option.
             Example: 'elpris -c'
   -q        Display quarterly rates (every 15 minutes) instead of the
             default hourly rates. Example: 'elpris -t'
   -b <brk>  Define the relative limit (breakpoint) <brk> of price
             above which the mean price points in the graph should be
             coloured in red instead of white. The relative limit <bpt>
             should be stated as a regular decimal number between 0.0
             and 1.0.  Example: 'elpris -b 0.65', to have all mean
             values above 65% between the daily lowest and highest
             price marked in red. Default: <brk>=0.80 (80 percent).
   -f        Toggle the 'Fancy Box' option, using the box-drawing
             characters of Unicode for the display of the tables.
             Default: on/true.
```

## Sample output from the script
The default Unicode output:
```
┌────────────────────────────────────────────────────────────────────────────┐
│Spot price at quarterly rate for zone SE3, Thu Mar 26 10:51:03 PM CET 2026. │
├────────────────────────────────────────────────────────────────────────────┤
│🔺 Highest (at 07:45):   63.4 öre/kWh                                       │
│🔻 Lowest  (at 07:45):    4.2 öre/kWh                                       │
├────────────────────────────────────────────────────────────────────────────┤
│Time (start)       Öre/kWh (p±Δp) |min (4.2)                      (63.4) max│
├────────────────────────────────────────────────────────────────────────────┤
│2026-03-26 00:00:00   14.7 ± 3.3  |     |-*-|                               │
│2026-03-26 01:00:00    8.8 ± 1.6  |  |*|                                    │
│2026-03-26 02:00:00    7.1 ± 0.5  | *|                                      │
│2026-03-26 03:00:00    6.3 ± 0.9  | *|                                      │
│2026-03-26 04:00:00    9.2 ± 1.9  | |-*|                                    │
│2026-03-26 05:00:00   10.9 ± 4.1  |  |-*--|                                 │
│2026-03-26 06:00:00   49.2 ± 14.9 |                  |-----------*-------|  │
│2026-03-26 07:00:00   60.4 ± 2.8  |                                    |*--|│
│2026-03-26 08:00:00   59.8 ± 3.7  |                                  |--*-| │
│2026-03-26 09:00:00   45.5 ± 11.6 |                     |-----*---------|   │
│2026-03-26 10:00:00   30.6 ± 17.7 |      |----------*------------|          │
│2026-03-26 11:00:00   13.7 ± 5.0  |   |--*---|                              │
│2026-03-26 12:00:00    6.5 ± 2.5  ||*-|                                     │
│2026-03-26 13:00:00    6.4 ± 1.0  ||*|                                      │
│2026-03-26 14:00:00    8.7 ± 4.2  ||--*-|                                   │
│2026-03-26 15:00:00   24.5 ± 15.7 |   |---------*----------|                │
│2026-03-26 16:00:00   43.7 ± 12.7 |                |---------*------|       │
│2026-03-26 17:00:00   54.9 ± 4.3  |                               |--*--|   │
│2026-03-26 18:00:00   58.6 ± 0.2  |                                    *    │
│2026-03-26 19:00:00   59.7 ± 2.5  |                                   |-*|  │
│2026-03-26 20:00:00   57.3 ± 2.4  |                                  |*-|   │
│2026-03-26 21:00:00   55.4 ± 2.1  |                                |-*|     │
│2026-03-26 22:00:00   53.3 ± 3.0  |                               |-*-|     │
│2026-03-26 23:00:00   51.2 ± 3.3  |                             |-*-|       │
└────────────────────────────────────────────────────────────────────────────┘
```

Regular ASCII output, using the `-f` option (toggling the "fancy" mode):
```
Fetching spot price at quarterly rate for zone SE3 at 2026/03/18 (17:29).
-----------------------------------------------------------------------------
🔺 Highest (at 19:00):  178.6 öre/kWh
🔻 Lowest  (at 12:30):    2.4 öre/kWh
-----------------------------------------------------------------------------
Time (start)       Öre/kWh (p±Δp) |min (2.4)                     (178.6) max|
-----------------------------------------------------------------------------
2026-03-18 00:00:00   29.7 ± 10.6 |    |-*--|                               |
2026-03-18 01:00:00   21.5 ± 0.9  |    *                                    |
2026-03-18 02:00:00   20.4 ± 0.3  |    *                                    |
2026-03-18 03:00:00   20.9 ± 0.3  |    *                                    |
2026-03-18 04:00:00   22.1 ± 0.3  |    *                                    |
2026-03-18 05:00:00   48.3 ± 26.3 |    |-----*-----|                        |
2026-03-18 06:00:00   75.7 ± 8.0  |              |-*|                       |
2026-03-18 07:00:00  120.1 ± 21.9 |                     |----*----|         |
2026-03-18 08:00:00   87.1 ± 17.3 |              |----*--|                  |
2026-03-18 09:00:00   50.0 ± 27.5 |  |-------*----|                         |
2026-03-18 10:00:00   12.0 ± 15.8 ||-*----|                                 |
2026-03-18 11:00:00    3.0 ± 0.2  |*                                        |
2026-03-18 12:00:00    2.4 ± 0.0  |*                                        |
2026-03-18 13:00:00    3.0 ± 0.1  |*                                        |
2026-03-18 14:00:00    3.6 ± 1.5  |*                                        |
2026-03-18 15:00:00   29.1 ± 26.8 ||-----*-----|                            |
2026-03-18 16:00:00   61.9 ± 20.7 |        |----*---|                       |
2026-03-18 17:00:00  134.1 ± 39.4 |                    |--------*--------|  |
2026-03-18 18:00:00  167.7 ± 9.7  |                                  |--*-| |
2026-03-18 19:00:00  157.5 ± 24.5 |                            |------*----||
2026-03-18 20:00:00  137.1 ± 14.7 |                           |--*---|      |
2026-03-18 21:00:00  106.1 ± 29.3 |                |------*-----|           |
2026-03-18 22:00:00   69.9 ± 32.6 |       |-------*------|                  |
2026-03-18 23:00:00   38.6 ± 17.6 |     |--*----|                           |
-----------------------------------------------------------------------------
```
## Installation

Installation in a Linux/OSX/Unix machine is simple. In order to install the
script and a symbolic link in the default location `/usr/local/bin/`, simply
exectute the following in a terminal:
```bash
cd bash; sudo make install
```
If you wish the script to be installed elsewhere, simpley edit the `TARGET`
field in the enclosed `bash/Makefile`.

## The API used for fetching spot price of electricity

Before proceeding with the instructions for installation and configuration,
let's just mention a few words about the way data for the spot price is
fetched. The application, which is written in Python, makes use of the free
API at https://www.elprisetjustnu.se/elpris-api, with the syntax simply being
`https://www.elprisetjustnu.se/api/v1/prices/[YEAR]/[MONTH]-[DAY]_[ZONE].json`

where

| Variable | Description                                       | Example |
|----------|---------------------------------------------------|---------|
|  YEAR    | Four digits                                       |    2025 |
|  MONTH   | Always two digits, with leading zero              |      04 |
|  DAY     | Always two digits, with leading zero              |      20 |
|  ZONE    |   SE1 = Luleå / Norra Sverige                     |         |
|          |   SE2 = Sundsvall / Norra Mellansverige           |         |
|          |   SE3 = Gotland / Stockholm / Södra Mellansverige |         |
|          |   SE4 = Malmö / Södra Sverige                     |  SE3    |

As an example, to fetch today's spot price of electricity at Gotland, Sweden
(April 20, 2025, zone SE3), simply use the call
`GET https://www.elprisetjustnu.se/api/v1/prices/2025/04-20_SE3.json`

## Copyright
Copyright (C) 2025, Fredrik Jonsson, under GPLv3. See enclosed LICENSE.

## Location of master source code
The source and documentation can be found at https://github.com/hp35/elpris
