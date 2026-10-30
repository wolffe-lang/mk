$(eval A = 1)
$(eval B := $(A)2)
$(eval A = 9)
$(eval C ?= 3)
$(eval C ?= 4)
$(eval D += x)
$(eval D += y)
$(eval E != echo sh)
$(info [$(A)] [$(B)] [$(C)] [$(D)] [$(E)])
$(info $(flavor A) $(flavor B) $(flavor C) $(flavor D) $(flavor E) $(origin A))
all:
	@:
