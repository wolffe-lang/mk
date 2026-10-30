# one
# two
define BAD
A := 1
B := 2
$$(error boom)
endef

$(eval $(BAD))
all:
	@:
