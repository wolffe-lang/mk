X := $(shell exit 3)
$(info [$(.SHELLSTATUS)] [$(origin .SHELLSTATUS)] [$(flavor .SHELLSTATUS)])
Y := $(shell true)
$(info [$(.SHELLSTATUS)])
all:
	@:
