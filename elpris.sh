#!/bin/bash
#
# Bash script for fetching the price of electricity in Sweden, using the API
# at https://www.elprisetjustnu.se/elpris-api.
#
# Syntax for fetching the price via the API:
#   https://www.elprisetjustnu.se/api/v1/prices/[YEAR]/[MONTH]-[DAY]_[ZONE].json
#
# where:
#
#     Variable    Description                               Example
#     YEAR        Alla fyra siffror                            2025
#     MONTH       Always two digits, with leading zero           03
#     DAY         Always two digits, with leading zero           03
#     ZONE SE1 = Luleå / Norra Sverige
#          SE2 = Sundsvall / Norra Mellansverige
#          SE3 = Gotland / Stockholm / Södra Mellansverige
#          SE4 = Malmö / Södra Sverige                          SE3
#
# As an example, to fetch today's spot price of electricity at Gotland, Sweden
# (April 20, 2025, zone SE3), simply use the call
#
#        GET https://www.elprisetjustnu.se/api/v1/prices/2025/04-20_SE3.json
#
#     Copyright (C) 2024, Fredrik Jonsson
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

#
# Dependencies to other programs.
#
CURL=curl     # Transfer a URL
JQ=jq         # Command-line JSON processor

#
# Default initialization of variables and specification of the access point
# of the API to elprisetjustnu.se. If options for the zone and/or date is
# passed to the script as command-line options, then the API variable is
# changed accordingly before fetching of data.
#
ZONE="SE3"
YEAR=$( date '+%Y' )
MONTH=$( date '+%m' )
DAY=$( date '+%d' )
HOUR=$( date '+%H' )
MINUTE=$( date '+%M' )
URL="https://www.elprisetjustnu.se"
API="api/v1/prices/"$YEAR"/"$MONTH"-"$DAY"_"$ZONE".json"

License()
{
   echo "Fetching spot price of electricity in Scandinavia via the API to "
   echo "https://www.elprisetjustnu.se/."
   echo ""
   echo "   Copyright (C) 2025 under Gnu General Public License (GPLv3),"
   echo "   Fredrik Jonsson."
   echo ""
   echo "   This program is free software: you can redistribute it and/or"
   echo "   modify it under the terms of the GNU General Public License as"
   echo "   published by the Free Software Foundation, either version 3 of"
   echo "   the License, or (at your option) any later version."
   echo ""
   echo "   This program is distributed in the hope that it will be useful,"
   echo "   but WITHOUT ANY WARRANTY; without even the implied warranty of"
   echo "   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the"
   echo "   GNU General Public License for more details."
   echo ""
   echo "   You should have received a copy of the GNU General Public License"
   echo "   along with this program.  If not, see <https://www.gnu.org/licenses/>."
}

Help()
{
   echo "Fetching spot price of electricity in Scandinavia via the API to "
   echo "https://www.elprisetjustnu.se/."
   echo ""
   echo "Syntax: $0 [-p \"<lon>;<lat>\"|h|g]"
   echo "options:"
   echo "h           Print this Help."
   echo "g           Print the GPL license notification."
   echo "z <zone>    Specify the zone for the spot price to be fetched, where"
   echo "            <zone> is any of:"
   echo "                  SE1 = Luleå / Norra Sverige"
   echo "                  SE2 = Sundsvall / Norra Mellansverige"
   echo "                  SE3 = Gotland / Stockholm / Södra Mellansverige"
   echo "                  SE4 = Malmö / Södra Sverige"
   echo "            If the -z option is omitted, then SE3 will be used as"
   echo "            default."
   echo "d <date>    Specify the date for the spot price to be fetched, where"
   echo "            <date> is specified as YYYYMMDD. If the -d option is"
   echo "            omitted, then the current date will be used as default."
}

#
# Parse any present command-line options.
#
while getopts ":hgz:d:" option; do
    case $option in
	h) # Display help message
	    Help
	    exit;;
	g) # Display license message
	    License
	    exit;;
	z) # Get zone (SE1|SE2|SE3|SE4) for data to fetch
	    ZONE=$OPTARG
	    echo "Zone specified to $ZONE.";;
	d) # Get date (YYYYMMDD) for data to fetch
	    DATETIME=$OPTARG
	    if [[ $DATETIME =~ ^([[:digit:]]{4})([[:digit:]]{2})([[:digit:]]{2}) ]]; then
		YEAR="${BASH_REMATCH[1]}"
		MONTH="${BASH_REMATCH[2]}"
		DAY="${BASH_REMATCH[3]}"
	    fi
	    echo "Date specified to $YEAR/$MONTH/$DAY.";;
	\?) # Invalid option
	    echo "Error: Invalid option"
	    Help
	    exit;;
    esac
done

#
# Fetch spot price using the specified API.
#
API="api/v1/prices/"$YEAR"/"$MONTH"-"$DAY"_"$ZONE".json"
FETCHURL=$URL/$API
FILENAME="data-$ZONE-$YEAR$MONTH$DAY"
echo "Fetching spot price data for zone $ZONE at $YEAR/$MONTH/$DAY ($HOUR:$MINUTE)."
eval "$CURL -s $FETCHURL | $JQ '.' > $FILENAME.json"

#
# Convert and save the fetched JSON data as a regular CSV file.
#
$JQ --raw-output '
  ["time_start", "time_end", "SEK_per_kWh", "EUR_per_kWh", "EXR"],
  (.[] | [
    .time_start,
    .time_end,
    (.SEK_per_kWh | tostring),
    (.EUR_per_kWh | tostring),
    (.EXR | tostring)
  ])
  | @csv
' "$FILENAME.json" > "$FILENAME.csv"
echo "Spot prices in JSON format saved to $FILENAME.json"
echo "Spot prices in CSV format saved to $FILENAME.csv"

#
# Extract the lowest and highest SEK/kWh during the fetched time interval.
# We do this by first parsing the raw data for the lowest and highest price,
# followed by conversion of timestamps from UTC to local time.
#
min=$(jq -r 'min_by(.SEK_per_kWh) | "\(.time_start) \(.SEK_per_kWh)"' "$FILENAME.json")
max=$(jq -r 'max_by(.SEK_per_kWh) | "\(.time_start) \(.SEK_per_kWh)"' "$FILENAME.json")
read time_min price_min <<< "$min"
read time_max price_max <<< "$max"
price_min_ore=$(awk "BEGIN { printf \"%.5f\", $price_min * 100 }")
price_max_ore=$(awk "BEGIN { printf \"%.5f\", $price_max * 100 }")
time_min_local=$(date -d "$time_min" +"%H:%M")
time_max_local=$(date -d "$time_max" +"%H:%M")
echo "🔻 Lowest (at $time_min_local): ${price_min_ore} öre/kWh"
echo "🔺 Highest (at $time_max_local): ${price_max_ore} öre/kWh"

#
# Extract and format spot price data, including a basic header.
#
printf "%-25s %10s\n" "-------------------------" "----------"
printf "%-25s %10s\n" "Time Start" "Öre/kWh"
printf "%-25s %10s\n" "-------------------------" "----------"
$JQ --raw-output '.[] | "\(.time_start) \(.SEK_per_kWh)"' "$FILENAME.json" | while read time_start sek; do
    # Convert from UTC to local time
    local_time=$(date -d "$time_start" +"%Y-%m-%d %H:%M:%S")
    # Convert from SEK_to öre (SEK*100)
    ore=$(awk "BEGIN { printf \"%.1f\", $sek * 100 }")
    printf "%-20s %12s\n" "$local_time" "$ore"
done
printf "%-25s %10s\n" "-------------------------" "----------"
