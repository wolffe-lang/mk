A = x
undefine A
ifdef A
$(error still)
endif
override define B
b1
endef
all:
	@echo [$(A)][$(B)]
