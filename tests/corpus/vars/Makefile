# vars: all four flavours, +=, $$, an env var, a command-line override
A = one
B := $(A) two
A = uno
C ?= three
C ?= nope
D = x
D += y
E := $$HOME
all: vars.out
vars.out:
	@echo A=$(A) B=$(B) C=$(C) D=$(D) E=$(E) H=$(HOME_SET) O=$(OVR) > vars.out
