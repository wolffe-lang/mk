ifeq (a,b)
X = bad1
else ifeq (c,c)
X = yes
else
X = bad2
endif
all:
	@echo $(X)
