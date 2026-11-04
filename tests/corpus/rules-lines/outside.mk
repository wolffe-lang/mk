	X = 1
Y = a
	Y += b
ifeq (a,b)
	$(info hidden)
endif
all: ; @echo "[$(X)] [$(Y)]"
.PHONY: all
	@echo ignored
