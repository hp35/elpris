#
# Makefile for managing installation and cleanup.
#
# Copyright (C) 1996-2025 under GPLv3, Fredrik Jonsson
#
all:
	echo "Run make clean in order to clean up the current directory."

clean:
	-rm -Rf *~ *.json *.csv
