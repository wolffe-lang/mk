$(file >out.txt,hello)
$(file >>out.txt,world)
$(info [$(file <out.txt)])
all:
	@:
