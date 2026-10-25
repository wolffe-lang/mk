include generated.mk
all:
	@printf "X=[$(X)]\n"
generated.mk:
	@printf "X = regenerated\n" > $@
