$(file >empty.txt)
$(info bytes=$(strip $(shell wc -c <empty.txt)))
all:
	@:
