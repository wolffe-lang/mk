	Z = 3# c
	W = a \
	    b
ifeq (a,b)
.RECIPEPREFIX = >
endif
all: in
	@echo tab-still [$(Z)] [$(W)]
.RECIPEPREFIX = >
in:
ifeq (a,a)
>@echo yes
endif
>@echo after
