X := $(if yes,$(shell exit 4),$(shell exit 9))$(.SHELLSTATUS)
$(info lazy [$(X)] [$(.SHELLSTATUS)])
all:
	@:
