Q := $(shell echo hi; exit 2)
$(info output [$(Q)] [$(.SHELLSTATUS)])
all:
	@:
