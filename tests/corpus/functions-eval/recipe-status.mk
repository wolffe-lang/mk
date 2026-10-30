X := $(shell exit 4)
all:
	@echo one $(shell exit 3)
	@echo two status=$(.SHELLSTATUS)
later: all
	@echo later status=$(.SHELLSTATUS)
