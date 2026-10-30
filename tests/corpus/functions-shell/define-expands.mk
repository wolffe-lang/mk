B = bee
define X !=
echo $(B)
endef
B = later
$(info [$(X)] $(flavor X))
all:
	@:
