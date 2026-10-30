# one
# two
define BAD
A := 1
B := 2
not a rule
endef
$(eval $(BAD))
all:
	@:
