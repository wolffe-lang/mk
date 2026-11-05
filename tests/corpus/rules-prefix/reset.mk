.RECIPEPREFIX = >>
a: b
>@echo a
.RECIPEPREFIX =
b: c
	@echo b
override .RECIPEPREFIX := +
c:
+@echo c
