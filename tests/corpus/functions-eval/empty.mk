$(info [$(eval X := 1)])
$(info [$(eval )][$(eval)])
$(info X=$(X))
R := [$(eval Z := 2)]
$(info R=$(R) Z=$(Z))
all:
	@:
