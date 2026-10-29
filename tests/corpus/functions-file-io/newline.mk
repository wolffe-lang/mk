define TEXT
hello

endef
$(file >newline.txt,$(TEXT))
$(info bytes=$(strip $(shell wc -c <newline.txt)))
all:
	@:
