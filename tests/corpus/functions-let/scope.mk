a := outer
$(info [$(let a,inner,$(a))] [$(a)])
all:
	@:
