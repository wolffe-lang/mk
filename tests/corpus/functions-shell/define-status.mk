define X !=
echo out; exit 3
endef
$(info [$(X)] [$(.SHELLSTATUS)])
all:
	@:
