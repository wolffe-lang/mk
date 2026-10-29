$(file >blank.txt,)
$(info bytes=$(strip $(shell wc -c <blank.txt)))
all:
	@:
