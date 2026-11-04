a:
	@echo first
# c

a:
# gap
	@echo second
b: ; @echo first
b:
	@echo second
c:
	@echo first
c: ; @echo second
d:
	@echo first
d:
ifeq (a,a)
	@echo second
endif
