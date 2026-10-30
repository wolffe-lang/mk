define X !=
echo one; echo two
endef
$(info [$(X)] $(flavor X) $(origin X) [$(.SHELLSTATUS)])
all:
	@:
