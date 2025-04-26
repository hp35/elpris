#
# Makefile for managing installation and cleanup.
#
# Copyright (C) 1996-2025 under GPLv3, Fredrik Jonsson
#
TARGET=/usr/local/bin/

define run_and_check
	@$(1); \
	exit_code=$$?; \
	if [ $$exit_code -eq 1 ]; then \
		echo "Error: '$(1)' failed with exit code 1."; \
		echo "Suggestion: Try running 'sudo make install'."; \
	fi; \
	exit $$exit_code
endef

all:
	./elpris.sh

install:
	@echo "Installing the ELPRIS script at "$(TARGET)" as $$USER"
	$(call run_and_check, rm -Rf $(TARGET)/elpris.sh $(TARGET)/elpris)
	$(call run_and_check, cp elpris.sh $(TARGET))
	$(call run_and_check, ln -s $(TARGET)/elpris.sh $(TARGET)/elpris)
	@echo "Successfully installed the script at "$(TARGET)" as $$USER"

clean:
	-rm -Rf *~ *.json *.csv
