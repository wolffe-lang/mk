R = $(file >lazy.txt,late)
$(info before=[$(wildcard lazy.txt)])
$(info use=[$(R)])
$(info after=[$(file <lazy.txt)])
all:
	@:
