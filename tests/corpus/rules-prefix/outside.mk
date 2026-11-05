.RECIPEPREFIX = >
>X = 1# c
>Y = a \
>b
$(info [$(>X)] [$(X)] [$(>Y)])
.PHONY: all
>@echo ignored
all: ; @echo all
