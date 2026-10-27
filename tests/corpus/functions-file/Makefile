dir:
	@echo [$(dir src/foo.c hacks)] [$(dir /foo)] [$(dir a//b)]
notdir:
	@echo [$(notdir src/foo.c hacks)] [$(notdir src/ b)]
suffix:
	@echo [$(suffix src/foo.c src-1.0/bar.c hacks)] [$(suffix .c a.)]
basename:
	@echo [$(basename src/foo.c src-1.0/bar hacks)] [$(basename a.b/c d)] [$(basename .c a. b)]
addsuffix:
	@echo [$(addsuffix .c,foo bar)] [$(addsuffix .c,)]
addprefix:
	@echo [$(addprefix src/,foo bar)] [$(addprefix p/,  a   b )]
join:
	@echo [$(join a b,.c .o)] [$(join a b c,.c .o)] [$(join a,b c)] [$(join a b,c)]
abspath:
	@echo [$(abspath x/../y)] [$(abspath /a/./b//c/)] [$(abspath )] [$(abspath /)] [$(abspath ../../../../../../../../z)]
