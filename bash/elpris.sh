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
AWK=awk       # For text processing

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
OUTDIR="/tmp/"
CLEANMODE="true"
HOURMODE="true"
FANCYBOX="true"

#
# Color definitions.
#
BLUE='\033[0;34m'
RED='\033[0;31m'
WHITE='\033[0;37m'
BRIGHTWHITE='\033[0;97m'
GRAY='\033[1;33m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

#
# Definitions of the GRAPHWIDTH, which states how many characters the
# presented graph should occupy in the terminal window, and BREAKPOINT,
# which states the relative limit of price above which the mean price
# points in the graph should be coloured in red instead of white.
#
GRAPHWIDTH=40
BREAKPOINT=0.80

#
# Function for the generation of the current date as a nicely formatted string.
#
get_formatted_date() {
    #
    # Get parts of the date.
    #
    local month=$(date -u +"%B")
    local day=$(date -u +"%-d")
    local weekday=$(date -u +"%A")
    local year=$(date -u +"%Y")

    #
    # Determine suffix.
    #
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

    #
    # Return formatted string.
    #
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
  echo "   along with this program. If not, see <https://www.gnu.org/licenses/>."
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
  echo "Syntax: $0 [-h|-g|-z <zone>|-d <date>|-o <dir>|-c|-q|-b <break>]"
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
  echo " -q          Display quarterly rates (every 15 minutes) instead of the"
  echo "             default hourly rates. Example: 'elpris -t'"
  echo " -b <break>  Define the relative limit (breakpoint) <break> of price"
  echo "             above which the mean price points in the graph should be"
  echo "             coloured in red instead of white. The relative limit <bpt>"
  echo "             should be stated as a regular decimal number between 0.0"
  echo "             and 1.0.  Example: 'elpris -b 0.65', to have all mean"
  echo "             values above 65% between the daily lowest and highest"
  echo "             price marked in red."
  echo " -f          Toggle the 'Fancy Box' option, using the box-drawing"
  echo "             characters of Unicode for the display of the tables."
  echo "             Default: on/true."
}

#
# Print vertically oriented separator lines, either in Unicode (with the
# default "fancy box" printing, or simply in ASCII as a line of dashes.
#
function PrintLineSeparator()
{
    local count=${1:-77}
    if [[ "$FANCYBOX" == "true" ]]; then
        if [[ $1 == "top" ]]; then          # '┌──────────────────────────┐'
            $AWK 'BEGIN { printf "%c", 0x250C }'
            $AWK 'BEGIN {for (k=0;k<76;k++) { printf "%c", 0x2500 } }'
            $AWK 'BEGIN { printf "%c", 0x2510 ; printf "\n"}'
        elif [[ $1 == "mid" ]]; then        # '├──────────────────────────┤'
            $AWK 'BEGIN { printf "%c", 0x251C }'
            $AWK 'BEGIN {for (k=0;k<76;k++) { printf "%c", 0x2500 } }'
            $AWK 'BEGIN { printf "%c", 0x2524 ; printf "\n"}'
        elif [[ $1 == "midcross" ]]; then   # '├────────────┼─────────────┤'
            $AWK 'BEGIN { printf "%c", 0x251C }'
            $AWK 'BEGIN {for (k=0;k<34;k++) { printf "%c", 0x2500 } }'
            $AWK 'BEGIN { printf "%c", 0x253C }'
            $AWK 'BEGIN {for (k=0;k<41;k++) { printf "%c", 0x2500 } }'
            $AWK 'BEGIN { printf "%c", 0x2524 ; printf "\n"}'
        elif [[ $1 == "midtee" ]]; then     # '├────────────┬─────────────┤'
            $AWK 'BEGIN { printf "%c", 0x251C }'
            $AWK 'BEGIN {for (k=0;k<34;k++) { printf "%c", 0x2500 } }'
            $AWK 'BEGIN { printf "%c", 0x252C }'
            $AWK 'BEGIN {for (k=0;k<41;k++) { printf "%c", 0x2500 } }'
            $AWK 'BEGIN { printf "%c", 0x2524 ; printf "\n"}'
        elif [[ $1 == "midinvtee" ]]; then  # '└────────────┴─────────────┘'
            $AWK 'BEGIN { printf "%c", 0x2514 }'
            $AWK 'BEGIN {for (k=0;k<34;k++) { printf "%c", 0x2500 } }'
            $AWK 'BEGIN { printf "%c", 0x2534 }'
            $AWK 'BEGIN {for (k=0;k<41;k++) { printf "%c", 0x2500 } }'
            $AWK 'BEGIN { printf "%c", 0x2518 ; printf "\n"}'
        elif [[ $1 == "bot" ]]; then        # '└──────────────────────────┘'
            $AWK 'BEGIN { printf "%c", 0x2514 }'
            $AWK 'BEGIN {for (k=0;k<76;k++) { printf "%c", 0x2500 } }'
            $AWK 'BEGIN { printf "%c", 0x2518 ; printf "\n"}'
        else                                # '────────────────────────────'
            $AWK 'BEGIN {for (k=0;k<77;k++) { printf "%c", 0x2500 } printf "\n"}'
        fi
    else
        printf '%*s\n' "$count" '' | tr ' ' '-'
    fi
}

#
# Print a simple table of all box-drawing Unicode characters.
#
print_box_drawing_table() {
    local start=0x2500
    local end=0x257F
    local cols=8
    local count=0
    for ((code=start; code<=end; code++)); do
        $AWK -v cd="$code" 'BEGIN { printf "%c", cd }'
        printf "(U+%04X) " "$code"
        ((count++))
        if ((count % cols == 0)); then
            echo
        fi
    done
    if ((count % cols != 0)); then
        echo
    fi
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
    if [[ "$FANCYBOX" == "true" ]]; then
        PrintLineSeparator "top"
        $AWK 'BEGIN { printf "%c", 0x2502 }'    # '│', Unicode vertical bar
        printf "Spot price at quarterly rate for zone $ZONE, `date -u`."
        $AWK 'BEGIN { printf " %c\n", 0x2502 }' # '│', Unicode vertical bar
        PrintLineSeparator "mid"
    else
        PrintLineSeparator
        echo "Spot price at quarterly rate for zone $ZONE, `date -u`."
        PrintLineSeparator
    fi
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
    price_min=$($AWK "BEGIN { printf \"%.1f\", ($price_min) * 100 }")
    price_max=$($AWK "BEGIN { printf \"%.1f\", ($price_max) * 100 }")
    time_min_local=$(date -d "$time_min" +"%H:%M")
    time_max_local=$(date -d "$time_max" +"%H:%M")
    if [[ "$FANCYBOX" == "true" ]]; then
        $AWK 'BEGIN { printf "%c", 0x2502 }'      # '│', Unicode vertical bar
        printf "🔺 Highest (at %s): %6s %-47s" $time_max_local \
                       $price_max "öre/kWh"
        $AWK 'BEGIN { printf "%c\n", 0x2502 }'    # '│', Unicode vertical bar
        $AWK 'BEGIN { printf "%c", 0x2502 }'      # '│', Unicode vertical bar
        printf "🔻 Lowest  (at %s): %6s %-47s" $time_min_local \
                       $price_min "öre/kWh"
        $AWK 'BEGIN { printf "%c\n", 0x2502 }'    # '│', Unicode vertical bar
        PrintLineSeparator "midtee"
    else
        printf "🔺 Highest (at %s): %6s öre/kWh\n" $time_max_local $price_max
        printf "🔻 Lowest  (at %s): %6s öre/kWh\n" $time_min_local $price_min
        PrintLineSeparator
    fi
}

#
# Function for the extraction and formatting of spot price data, including
# the generation of a basic header.
#
function DisplaySpotPrices()
{
    if [ "$HOURMODE" = "false" ]; then

        #
        # Display the price per kWh at a quarterly rate, for every 15 minutes.
        # The quarterly rate was introduced in Sweden on October 1, 2023.
        #
        if [[ "$FANCYBOX" == "true" ]]; then
            $AWK 'BEGIN { printf "%c", 0x2502 }'    # '│', Unicode vertical bar
            printf "%-21s %12s" "Time (start)" "Öre/kWh"
            printf "%-1s" " "
            $AWK 'BEGIN { printf "%c", 0x2502 }'    # '│', Unicode vertical bar
            $AWK 'BEGIN { printf "%c", 0x21E0 }'    # '⇠', Unicode left arrow
            printf "%-22s %16s" "min" "max"
            $AWK 'BEGIN { printf "%c", 0x21E2 }'    # '⇢', Unicode right arrow
            $AWK 'BEGIN { printf "%c\n", 0x2502 }'  # '│', Unicode vertical bar
            PrintLineSeparator "midcross"
        else
            printf "%-23s %-6s " "Time (start)" "Öre/kWh"
            printf "%-23s %21s\n" "  |min" "max|"
            PrintLineSeparator
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
            ore=$($AWK "BEGIN { printf \"%.1f\", $sek * 100 }")

            #
            # Determine the number n of blank spaces for placement of the '|'
            # marker, as well as the complementary number nc in order to fill
            # up the remainder of the row of the table.
            #
            n=$($AWK "BEGIN {
                     printf \"%d\",
                       $GRAPHWIDTH*($ore-($price_min))/($price_max-($price_min))
                  }")
            nc=$($AWK "BEGIN { printf \"%d\", $GRAPHWIDTH - $n }")
            if [[ "$FANCYBOX" == "true" ]]; then
                $AWK 'BEGIN { printf "%c", 0x2502 }' # '│', Unicode vertical bar
                printf "%-21s %11s " "$local_time" "$ore"
                $AWK 'BEGIN { printf "%c", 0x2502 }' # '│', Unicode vertical bar
            else
                printf "%-22s %8s %3c" "$local_time" "$ore" "|"
            fi

            #
            # Print the low/high '|' marker in a simple graph, with n leading
            # and nc training spaces.
            #
            for k in $(seq 1 $n); do printf " "; done; printf "|"
            for k in $(seq 1 $nc); do printf " "; done;
            if [[ "$FANCYBOX" == "true" ]]; then
                $AWK 'BEGIN { printf "%c\n", 0x2502 }' # '│', Unicode vert bar
	    else
                printf "|\n"
            fi

        done

    elif [ "$HOURMODE" = "true" ]; then

        #
        # Display the price per kWh at an hourly rate, for every 60 minutes.
        #
        if [[ "$FANCYBOX" == "true" ]]; then
            $AWK 'BEGIN { printf "%c", 0x2502 }'    # '│', Unicode vertical bar
            printf "%-18s %16s " "Time (start)" "Öre/kWh (p±Δp)"
            $AWK 'BEGIN { printf "%c", 0x2502 }'    # '│', Unicode vertical bar
            $AWK 'BEGIN { printf "%c", 0x21E0 }'    # '⇠', Unicode left arrow
            printf "%-14s%25s" "min ($price_min)" "($price_max) max"
            $AWK 'BEGIN { printf "%c", 0x21E2 }'    # '⇢', Unicode right arrow
            $AWK 'BEGIN { printf "%c\n", 0x2502 }'  # '│', Unicode vertical bar
            PrintLineSeparator "midcross"
        else
            printf "%-22s %8s" "Time (start)" "Öre/kWh"
            printf "%-25s %21s\n" "    |min" "max|"
            PrintLineSeparator
        fi

        #
        # Aggregate per hour: mean, min, max
        #
        $JQ --raw-output '
            group_by(.time_start[0:13])[] |
                {
                    hour: .[0].time_start[0:13],
                    mean: (map(.SEK_per_kWh) | add / length),
                    min:  (map(.SEK_per_kWh) | min),
                    max:  (map(.SEK_per_kWh) | max)
                } |
                "\(.hour) \(.mean) \(.min) \(.max)"
            ' "$FILENAME.json" | while read hour mean min max; do

            #
            # Convert from UTC to local time.
            #
            local_hour=$(date -d "$hour:00" +"%Y-%m-%d %H:%M:%S")
            mean_ore=$($AWK "BEGIN { printf \"%.1f\", ($mean)*100 }")
            min_ore=$($AWK "BEGIN { printf \"%.1f\", ($min)*100 }")
            max_ore=$($AWK "BEGIN { printf \"%.1f\", ($max)*100 }")
            dore=$($AWK "BEGIN { printf \"%.1f\", (($max_ore)-($min_ore))/2.0 }")

            #
            # Scale positions relative to daily min/max
            #
            pos_mean=$($AWK "BEGIN {
                if ($price_max==$price_min) print 0;
                else printf \"%d\", $GRAPHWIDTH*(($mean_ore)-($price_min))\
                                           /(($price_max)-($price_min))
            }")
            pos_min=$($AWK "BEGIN {
                if ($price_max==$price_min) print 0;
                else printf \"%d\", $GRAPHWIDTH*(($min_ore)-($price_min))\
                                           /(($price_max)-($price_min))
            }")
            pos_max=$($AWK "BEGIN {
                if ($price_max==$price_min) print 0;
                else printf \"%d\", $GRAPHWIDTH*(($max_ore)-($price_min))\
                                           /(($price_max)-($price_min))
            }")

	    #
            # Display the first half of the row, with time stamp, mean price
            # and the measure of deviation.
            #
            bp=$($AWK "BEGIN { printf \"%1.2f\", \
                       ($BREAKPOINT)*(($price_max)-($price_min)) }")
            if [[ "$FANCYBOX" == "true" ]]; then
                $AWK 'BEGIN { printf "%c", 0x2502 }' # '│', Unicode vertical bar
                if (( $(echo "$bp < $mean_ore" |bc -l) )); then
                    printf "%-19s ${YELLOW}%6s ± %-4s${NC} " \
                                "$local_hour" "$mean_ore" "$dore"
                    $AWK 'BEGIN { printf "%c", 0x2502 }' # '│', Unicode vert bar
                else
                    printf "%-19s %6s ± %-4s " "$local_hour" "$mean_ore" "$dore"
                    $AWK 'BEGIN { printf "%c", 0x2502 }' # '│', Unicode vert bar
                fi
            else
                if (( $(echo "$bp < $mean_ore" |bc -l) )); then
                    printf "%-19s ${YELLOW}%6s ± %-4s${NC} |" \
                                "$local_hour" "$mean_ore" "$dore"
                else
                    printf "%-19s %6s ± %-4s |" "$local_hour" "$mean_ore" "$dore"
                fi
            fi

            #
            # Display the second half of the row, with position indicators
            # for the mean and deviation, to get a "graph-like" evolution
            # of the price of electricity over the day. If the price is above
            # the breakpoint (typically the default value of BREAKPOINT being
            # 80% between the minimum and maximum quarterly price of
            # electricity during the day), then the marker is colored in red.
            #
            for ((i=0;i<=GRAPHWIDTH;i++)); do
                if [[ $i -eq $pos_mean ]]; then
                    if (( $(echo "$bp < $mean_ore" |bc -l) )); then
                        printf "${RED}*${NC}"
                    else
                        printf "${BRIGHTWHITE}*${NC}"
                    fi
                elif [[ $i -eq $pos_min || $i -eq $pos_max ]]; then
                    printf "${BLUE}|${NC}"
                elif (($pos_min < $i && $i < $pos_max)); then
                    printf "${BLUE}-${NC}"
                else
                    printf " "
                fi
            done
            if [[ "$FANCYBOX" == "true" ]]; then
                $AWK 'BEGIN { printf "%c\n", 0x2502 }' # '│', Unicode vert bar
            else
                printf "|\n"
            fi
        done

    fi

    #
    # Bottom line, in fancy (Unicode) or regular (ASCII) mode.
    #
    if [[ "$FANCYBOX" == "true" ]]; then
        PrintLineSeparator "midinvtee"
    else
        PrintLineSeparator
    fi
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
             PrintLineSeparator > $OUTFILE
             echo "Summary for $formatted_date." >> $OUTFILE
             echo "🔻 Lowest (at $time_min_local): ${price_min} öre/kWh"\
                                                                   >>$OUTFILE
             echo "🔺 Highest (at $time_max_local): ${price_max} öre/kWh"\
                                                                   >>$OUTFILE
             PrintLineSeparator >> $OUTFILE
             printf "%-22s %8s" "Time (start)" "Öre/kWh">>$OUTFILE
             printf "%-25s %21s\n" "    |min" "max|">>$OUTFILE
             PrintLineSeparator >> $OUTFILE
        elif [[ "$typ" == "nograph" ]] ; then
            PrintLineSeparator 32 > $OUTFILE
            echo "$formatted_date.">>$OUTFILE
            echo "🔻 Lowest ($time_min_local): ${price_min} öre/kWh">>$OUTFILE
            echo "🔺 Highest ($time_max_local): ${price_max} öre/kWh">>$OUTFILE
            PrintLineSeparator 32 >> $OUTFILE
            printf "%-22s %8s\n" "Time (start)" "Öre/kWh">>$OUTFILE
            PrintLineSeparator 32 >> $OUTFILE
        fi

        if [ "$HOURMODE" = "false" ]; then
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
                ore=$($AWK "BEGIN { printf \"%.1f\", $sek * 100 }")

                #
                # Determine the number n of blank spaces for placement of the '|'
                # marker, as well as the complementary number nc in order to fill
                # up the remainder of the row of the table.
                #
                n=$($AWK "BEGIN {
                   printf \"%d\",
                      $GRAPHWIDTH*($ore-($price_min))/($price_max-($price_min))
                    }")
                nc=$($AWK "BEGIN { printf \"%d\", $GRAPHWIDTH - $n }")
                if [[ "$typ" == "graph" ]] ; then
                    printf "%-22s %8s %3c" "$local_time" "$ore" "|" >> $OUTFILE
                    #
                    # Print the low/high '|' marker in a simple graph, with
                    # n leading and nc training spaces.
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

        elif [ "$HOURMODE" = "true" ]; then

            $JQ --raw-output '
                group_by(.time_start[0:13])[] |
                {
                    hour: .[0].time_start[0:13],
                    mean: (map(.SEK_per_kWh) | add / length),
                    min:  (map(.SEK_per_kWh) | min),
                    max:  (map(.SEK_per_kWh) | max)
                } |
                "\(.hour) \(.mean) \(.min) \(.max)"
            ' "$FILENAME.json" | while read hour mean min max; do
                local_hour=$(date -d "$hour:00" +"%H:00")
                mean_ore=$($AWK "BEGIN { printf \"%.1f\", $mean * 100 }")
                min_ore=$($AWK "BEGIN { printf \"%.1f\", $min * 100 }")
                max_ore=$($AWK "BEGIN { printf \"%.1f\", $max * 100 }")
                pos_mean=$($AWK "BEGIN {
                    if ($price_max==$price_min) print 0;
                    else printf \"%d\", $GRAPHWIDTH*($mean_ore-$price_min)\
                                                /($price_max-$price_min)
                }")
                pos_min=$($AWK "BEGIN {
                    if ($price_max==$price_min) print 0;
                    else printf \"%d\", $GRAPHWIDTH*($min_ore-$price_min)\
                                                /($price_max-$price_min)
                }")
                pos_max=$($AWK "BEGIN {
                    if ($price_max==$price_min) print 0;
                    else printf \"%d\", $GRAPHWIDTH*($max_ore-$price_min)\
                                                /($price_max-$price_min)
                }")
                printf "%-16s %10s  |" "$local_hour" "$mean_ore" >> $OUTFILE
                for ((i=0;i<=GRAPHWIDTH;i++)); do
                    if [[ $i -eq $pos_mean ]]; then
                        printf "|" >> $OUTFILE
                    elif [[ $i -eq $pos_min || $i -eq $pos_max ]]; then
                        printf "|" >> $OUTFILE
                    else
                        printf " " >> $OUTFILE
                    fi
                done
                printf "|\n" >> $OUTFILE
            done

        else
            echo "Unknown option for -t"
        fi
        if [[ "$typ" == "graph" ]] ; then
             PrintLineSeparator >> $OUTFILE
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
while getopts ":hgz:d:o:cqb:f" option; do
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
     q) # Specify quarterly mode, displaying the spot prize in quarterly rate
        HOURMODE="false"
        echo "Operating in quarterly mode.";;
     b) # Specify relative breakpoint above which prices will be tagged in red
        BREAKPOINT=$OPTARG
        echo "Relative breakpoint specified to $BREAKPOINT.";;
     f) # Toggle the FANCY box setting for using Unicode box-drawing characters
        if [[ "$FANCYBOX" == "true" ]]; then
           FANCYBOX="false"
        else
           FANCYBOX="true"
        fi
        echo "Toggled fancy box display; now set to $FANCYBOX.";;
     \?) # Invalid option
        echo "Error: Invalid option"
        Help
        exit;;
   esac
done

#
# The 'main()' of the ELPRIS script. This is where we start as well as end.
#
FetchSpotPrice
ExtractMinMax
DisplaySpotPrices
SaveSpotPrices
CleanUp
