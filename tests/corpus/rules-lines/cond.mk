all:
ifeq (a,a)
	@echo yes
endif
	@echo after
else:
	@echo before
ifeq (a,b)
	@echo no
else ifeq (c,c)
	@echo two
else
	@echo three
endif
nested:
ifeq (a,a)
ifdef NOPE
	@echo hidden
endif
	@echo outer
endif
dead:
ifeq (a,b)
X = 1
endif
	@echo after-dead
err:
ifeq (a,a)
	@true
endif
	@exit 4
