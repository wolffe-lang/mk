define BODY
GREETING := hello
NAME = $(GREETING) world
LATER = $$(GREETING) world
endef
$(eval $(BODY))
$(info [$(NAME)] [$(LATER)] $(flavor GREETING) $(flavor LATER))
all:
	@:
