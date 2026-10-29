N := a b
L := one two three
$(info $(let $(N),$(L),[$(a)][$(b)]))
all:
	@:
