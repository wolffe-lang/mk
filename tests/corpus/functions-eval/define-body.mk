define BODY
ifeq (a,b)
X := 1
endif
	@echo recipe line
endef
ifeq (a,b)
define DEAD
dead
endef
endif
$(info [$(value BODY)] [$(DEAD)] $(origin DEAD) [$(X)])
all:
	@:
