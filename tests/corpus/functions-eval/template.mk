PROGS := one two
one_SRC := a.c
two_SRC := b.c
define T
$(1): $$($(1)_SRC)
	@echo $$@ needs $$^
ALL += $(1)
endef
$(foreach p,$(PROGS),$(eval $(call T,$(p))))
all: $(ALL)
	@echo all: $(ALL)
a.c b.c:
	@echo make $@
