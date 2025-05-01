#!/bin/bash
#
# Bash script for fetching, analyzing and presenting the daily price of
# electricity in Sweden, using the open API at
# https://www.elprisetjustnu.se/elpris-api.
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
OUTDIR="./"
CLEANMODE="true"

#
# Function for the generation of the current date as a nicely formatted string.
#
get_formatted_date() {
    # Get parts of the date
    local month=$(date +"%B")
    local day=$(date +"%-d")
    local weekday=$(date +"%A")
    local year=$(date +"%Y")

    # Determine suffix
    local suffix
    if [[ $day -eq 1 || $day -eq 21 || $day -eq 31 ]]; then
        suffix="st"
    elif [[ $day -eq 2 || $day -eq 22 ]]; then
        suffix="nd"
    elif [[ $day -eq 3 || $day -eq 23 ]]; then
        suffix="rd"
    else
        suffix="th"
    fi

    # Return formatted string
    echo "${month} ${day}:${suffix} (${weekday}), ${year}"
}

#
# Function for the displaying of the GPLv3 licensing information.
#
function License()
{
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
   echo ""
}

#
# Function for the displaying of a help message on the usage of the program.
#
function Help()
{
   echo "The ELPRIS script fetches the spot price of electricity in Scandinavia"
   echo "via the API to https://www.elprisetjustnu.se/. In addition to merely"
   echo "displaying the captured data, the ELPRIS script also saved it to a"
   echo "JSON and CSV file, with naming convention data-ZONE-DATE.json and"
   echo "data-ZONE-DATE.csv, respectively."
   echo ""
   echo "Syntax: $0 [-h|-g|-z <zone>|-d <date>|-o <dir>|-c]"
   echo "options:"
   echo " -h          Print this Help."
   echo " -g          Print the GPL license notification."
   echo " -z <zone>   Specify the zone for the spot price to be fetched, where"
   echo "             <zone> is any of:"
   echo "                   SE1 = Luleå / Norra Sverige"
   echo "                   SE2 = Sundsvall / Norra Mellansverige"
   echo "                   SE3 = Gotland / Stockholm / Södra Mellansverige"
   echo "                   SE4 = Malmö / Södra Sverige"
   echo "             If the -z option is omitted, then SE3 will be used as"
   echo "             default. Example: 'elpris -z SE1'"
   echo " -d <date>   Specify the date for the spot price to be fetched, where"
   echo "             <date> is specified as YYYYMMDD. If the -d option is"
   echo "             omitted, then the current date will be used as default."
   echo "             Example: 'elpris -d 20250421'"
   echo " -o <dir>    Specify the output directory <dir> to which the ELPRIS"
   echo "             script should save the fetched raw data as well as the"
   echo "             standard text file summaries generated from it. If the"
   echo "             -o option is omitted, then the current directory will be"
   echo "             used for the default storage. If you wish a clean"
   echo "             execution without any remaining files, use the -c option"
   echo "             described below. Example: 'elpris -o ~/elpris/log/'"
   echo " -c          Clean execution of the ELPRIS script, with only terminal"
   echo "             output and no generated files left behind. This option"
   echo "             overrides any setting specified by the -o option."
   echo "             Example: 'elpris -c'"
}

function PrintLineSeparator()
{
   local count=${1:-77}
   printf '%*s\n' "$count" '' | tr ' ' '-'
}

#
# Function for the fetching of spot price using the specified API.
#
function FetchSpotPrice()
{
   API="api/v1/prices/"$YEAR"/"$MONTH"-"$DAY"_"$ZONE".json"
   FETCHURL=$URL/$API
   FILENAME="$OUTDIR/data-$ZONE-$YEAR$MONTH$DAY"
   DATE=$YEAR/$MONTH/$DAY
   echo "Fetching spot price data for zone $ZONE at $DATE ($HOUR:$MINUTE)."
   eval "$CURL -s $FETCHURL | $JQ '.' > $FILENAME.json"

   #
   # Convert and save the fetched JSON data as a regular CSV file. This
   # stage is omitted whenever the script is operating in "clean" mode.
   #
   if [ "$CLEANMODE" = "true" ]; then
      return
   fi

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
}

#
# Function for the extraction of the lowest and highest SEK/kWh during the
# fetched time interval. We do this by first parsing the raw data for the
# lowest and highest price, followed by conversion of timestamps from UTC
# to local time.
#
function ExtractMinMax()
{
   min=$($JQ --raw-output '
            min_by(.SEK_per_kWh) | "\(.time_start) \(.SEK_per_kWh)"
         ' "$FILENAME.json")
   max=$($JQ --raw-output '
            max_by(.SEK_per_kWh) | "\(.time_start) \(.SEK_per_kWh)"
         ' "$FILENAME.json")
   read time_min price_min <<< "$min"
   read time_max price_max <<< "$max"
   price_min=$(awk "BEGIN { printf \"%.1f\", $price_min * 100 }")
   price_max=$(awk "BEGIN { printf \"%.1f\", $price_max * 100 }")
   time_min_local=$(date -d "$time_min" +"%H:%M")
   time_max_local=$(date -d "$time_max" +"%H:%M")
   PrintLineSeparator 77
   echo "🔻 Lowest (at $time_min_local): ${price_min} öre/kWh"
   echo "🔺 Highest (at $time_max_local): ${price_max} öre/kWh"
}

#
# Function for the extraction and formatting of spot price data, including
# the generation of a basic header.
#
function DisplaySpotPrices()
{
   PrintLineSeparator 77
   printf "%-22s %8s" "Time (start)" "Öre/kWh"
   printf "%-25s %21s\n" "    |min" "max|"
   PrintLineSeparator 77
   $JQ --raw-output '
      .[] | "\(.time_start) \(.SEK_per_kWh)"
   ' "$FILENAME.json" | while read time_start sek; do
      #
      # Convert from UTC to local time.
      #
      local_time=$(date -d "$time_start" +"%Y-%m-%d %H:%M:%S")

      #
      # Convert from SEK to öre (SEK*100)
      #
      ore=$(awk "BEGIN { printf \"%.1f\", $sek * 100 }")

      #
      # Determine the number n of blank spaces for placement of the '|'
      # marker, as well as the complementary number nc in order to fill
      # up the remainder of the row of the table.
      #
      n=$(awk "BEGIN {
                  printf \"%d\",
                    40*($ore-($price_min))/($price_max-($price_min))
               }")
      nc=$(awk "BEGIN { printf \"%d\", 40 - $n }")
      printf "%-22s %8s %3c" "$local_time" "$ore" "|"

      #
      # Print the low/high '|' marker in a simple graph, with n leading
      # and nc training spaces.
      #
      for k in $(seq 1 $n); do printf " "; done; printf "|"
      for k in $(seq 1 $nc); do printf " "; done; printf "|\n"
   done
   PrintLineSeparator 77
}

#
# Function for the saving of a somewhat more readable summary of the
# daily spot prices.
#
function SaveSpotPrices()
{
   #
   # If clean mode of operation has been specified, then skip saving
   # the spot prices to file, and only let the script display the
   # summary in the terminal output.
   #
   if [ "$CLEANMODE" = "true" ]; then
        return
   fi

   #
   # We generate human-readable textfiles containing summaries in two
   # different forms: A short brief list with minimum, maximum and hourly
   # rates, and a similar one in which we also include a simple ASCII graph
   # illustrating the daily evolution of the price between its minimum and
   # maximum.
   #
   declare -a arr=("graph" "nograph")
   for typ in "${arr[@]}"
   do
      if [[ "$typ" == "graph" ]] ; then
         OUTFILE="$OUTDIR/sum-$ZONE-$YEAR$MONTH$DAY-graph".txt
      elif [[ "$typ" == "nograph" ]] ; then
         OUTFILE="$OUTDIR/sum-$ZONE-$YEAR$MONTH$DAY".txt
      else
         echo "Unrecognized summary type $typ"
         exit 1
      fi
      formatted_date=$(get_formatted_date)
      echo "Saving summary for $formatted_date to $OUTFILE"

      if [[ "$typ" == "graph" ]] ; then
          PrintLineSeparator 77 > $OUTFILE

         echo "Summary for $formatted_date." >> $OUTFILE
         echo "🔻 Lowest (at $time_min_local): ${price_min} öre/kWh">>$OUTFILE
         echo "🔺 Highest (at $time_max_local): ${price_max} öre/kWh">>$OUTFILE
         PrintLineSeparator 77 >> $OUTFILE
         printf "%-22s %8s" "Time (start)" "Öre/kWh">>$OUTFILE
         printf "%-25s %21s\n" "    |min" "max|">>$OUTFILE
         PrintLineSeparator 77 >> $OUTFILE
      elif [[ "$typ" == "nograph" ]] ; then
         PrintLineSeparator 32 > $OUTFILE
         echo "$formatted_date.">>$OUTFILE
         echo "🔻 Lowest ($time_min_local): ${price_min} öre/kWh">>$OUTFILE
         echo "🔺 Highest ($time_max_local): ${price_max} öre/kWh">>$OUTFILE
         PrintLineSeparator 32 >> $OUTFILE
         printf "%-22s %8s\n" "Time (start)" "Öre/kWh">>$OUTFILE
         PrintLineSeparator 32 >> $OUTFILE
      fi
      
      $JQ --raw-output '
         .[] | "\(.time_start) \(.SEK_per_kWh)"
      ' "$FILENAME.json" | while read time_start sek; do
         #
         # Convert from UTC to local time.
         #
         local_time=$(date -d "$time_start" +"%Y-%m-%d %H:%M:%S")

         #
         # Convert from SEK to öre (SEK*100)
         #
         ore=$(awk "BEGIN { printf \"%.1f\", $sek * 100 }")

         #
         # Determine the number n of blank spaces for placement of the '|'
         # marker, as well as the complementary number nc in order to fill
         # up the remainder of the row of the table.
         #
         n=$(awk "BEGIN {
                printf \"%d\",
                   40*($ore-($price_min))/($price_max-($price_min))
             }")
         nc=$(awk "BEGIN { printf \"%d\", 40 - $n }")
         if [[ "$typ" == "graph" ]] ; then
            printf "%-22s %8s %3c" "$local_time" "$ore" "|" >> $OUTFILE
            #
            # Print the low/high '|' marker in a simple graph, with n leading
            # and nc training spaces.
            #
            for k in $(seq 1 $n); do
		printf " "  >> $OUTFILE;
	    done;
	    printf "|" >> $OUTFILE
            for k in $(seq 1 $nc); do
		printf " " >> $OUTFILE;
	    done;
	    printf "|\n" >> $OUTFILE
         elif [[ "$typ" == "nograph" ]] ; then
            printf "%-22s %8s\n" "$local_time" "$ore" >> $OUTFILE
         fi
      done

      if [[ "$typ" == "graph" ]] ; then
         PrintLineSeparator 77 >> $OUTFILE
      elif [[ "$typ" == "nograph" ]] ; then
         PrintLineSeparator 32 >> $OUTFILE
      fi

   done
}

#
# Function for cleanup of any remaining files, in case clean mode of
# operation has been specified.
#
function CleanUp()
{
   if [ "$CLEANMODE" = "true" ]; then
      rm $FILENAME.json
      return
   fi
}

#
# Parse any present command-line options.
#
while getopts ":hgz:d:o:c" option; do
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
         if [[
            $DATETIME =~ ^([[:digit:]]{4})([[:digit:]]{2})([[:digit:]]{2})
         ]]; then
            YEAR="${BASH_REMATCH[1]}"
            MONTH="${BASH_REMATCH[2]}"
            DAY="${BASH_REMATCH[3]}"
         fi
         echo "Date specified to $YEAR/$MONTH/$DAY.";;
      o) # Specify output directory for the data and summary files
         OUTDIR=$OPTARG
         CLEANMODE="false"
         echo "Output directory specified to $OUTDIR.";;
      c) # Specify clean operation with no files left behind
         CLEANMODE="true";;
      \?) # Invalid option
         echo "Error: Invalid option"
         Help
         exit;;
   esac
done

FetchSpotPrice
ExtractMinMax
DisplaySpotPrices
SaveSpotPrices
CleanUp
