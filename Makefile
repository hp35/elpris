#
# Makefile for managing installation and cleanup.
#
# Copyright (C) 1996-2025 under GPLv3, Fredrik Jonsson
#
all:
	make -C ./bash/

clean:
	-rm -Rf *~ *.json *.csv
	make clean -C ./bash/
