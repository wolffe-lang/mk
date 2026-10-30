define R
t:
	@echo t from assign
endef
Y := $(eval $(R))
all: t
	@echo all
