$(foreach x,a b c,$(eval ALL := $(ALL) $(x)))
$(info ALL=[$(ALL)] x=[$(x)])
$(info [$(eval A := 1)$(A)])
all:
	@:
