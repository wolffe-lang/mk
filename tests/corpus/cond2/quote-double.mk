ifeq "a" "a"
X = yes
else
X = no
endif
all:
	@echo $(X)
