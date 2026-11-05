.RECIPEPREFIX = >
all: b
>$(CMDS)
define R
b:
>@echo from-eval-define
endef
$(eval $(R))
define CMDS
@echo one
@echo two
endef
