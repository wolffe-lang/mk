R = $(shell exit 7)
$(info before [$(.SHELLSTATUS)] [$(origin .SHELLSTATUS)])
$(info use [$(R)] [$(.SHELLSTATUS)])
$(info after [$(.SHELLSTATUS)])
all:
	@:
