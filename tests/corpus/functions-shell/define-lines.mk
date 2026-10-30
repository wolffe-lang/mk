define X !=
echo a
exit 3
endef
$(info [$(X)] [$(.SHELLSTATUS)])
all:
	@:
