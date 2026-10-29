$(info $(if ,$(file >never.txt,no),skipped))
$(info absent=[$(wildcard never.txt)])
all:
	@:
