# eval in an assignment: X alone is not a makefile line
Y := $(eval X)
all:
	@echo $(Y)
