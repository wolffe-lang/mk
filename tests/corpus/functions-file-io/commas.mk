T := a,b,c
$(file >commas.txt,one,two,$(T))
$(info [$(file <commas.txt)])
all:
	@:
