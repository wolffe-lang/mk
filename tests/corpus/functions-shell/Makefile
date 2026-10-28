A != echo one; echo two
B := $(shell echo x; echo y; echo; echo)
C = $(shell echo run >&2; echo c)
D != echo a; exit 3
E := [$(shell true)]
N!=echo n
all:
	@echo [$(A)] [$(B)] [$(D)] $(E) [$(N)]
lazy:
	@echo [$(C)] [$(C)]
flavor:
	@echo $(flavor A) $(flavor B) $(flavor C) $(flavor N)
rule:
	@echo [$(shell echo in recipe)]
err:
	@echo [$(shell echo to-stderr 1>&2; echo out)]
