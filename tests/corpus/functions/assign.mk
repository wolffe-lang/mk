# functions are not supported
Y := $(foreach v,a b,$(v).c)
all:
	@echo $(Y)
