define C
ifeq (a,a)
X := 1
endef
$(eval $(C))
all:
	@:
