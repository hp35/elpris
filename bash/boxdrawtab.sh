#!/bin/bash
#
# Bash script for generating a table of box-drawing set of Unicode characters.
# See https://en.wikipedia.org/wiki/Box-drawing_characters for details.
#
#     Copyright (C) 2026, Fredrik Jonsson
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
AWK=awk

#
# Print a simple table of all box-drawing Unicode characters.
#
print_box_drawing_table() {
    USE_AWK="false"
    local start=0x2500
    local end=0x257F
    local cols=8
    local count=0
    if [[ "$FANCYBOX" == "true" ]]; then
        for ((code=start; code<=end; code++)); do
            $AWK -v cd="$code" 'BEGIN { printf "%c", cd }'
            printf "(U+%04X) " "$code"
            ((count++))
            if ((count % cols == 0)); then
                echo
            fi
        done
    else
        for ((code=start; code<=end; code++)); do
            # Print the Unicode character without AWK calls
            printf '%b' "\\u$(printf '%04X' "$code")"

            # Print the code label as such
            printf "(U+%04X) " "$code"

            ((count++))
            if ((count % cols == 0)); then
                echo
            fi
        done
    fi
    if ((count % cols != 0)); then
        echo
    fi
}

print_box_drawing_table
