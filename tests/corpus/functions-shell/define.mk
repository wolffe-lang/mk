B = old
define X !=
printf shell
endef
B = new
all:
	@printf "[$(X)]\n"
