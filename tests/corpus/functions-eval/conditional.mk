MODE := fast
define PICK
ifeq ($(MODE),fast)
SPEED := 10
else
SPEED := 1
endif
endef
$(eval $(PICK))
$(info speed=$(SPEED))
MODE := slow
$(eval $(PICK))
$(info speed=$(SPEED))
all:
	@:
