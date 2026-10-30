$(eval .PHONY: p)
define P
p:
	@echo phony p
endef
$(eval $(P))
all: p
