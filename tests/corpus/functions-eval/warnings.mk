define R
A := 1
$$(warning at-two)
B := 2

$$(warning at-five)
endef
$(eval $(R))
all:
	@:
