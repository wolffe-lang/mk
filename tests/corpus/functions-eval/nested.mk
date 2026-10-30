$(eval $$(eval X := inner))
$(info X=$(X))
$(eval $$(eval $$$$(eval Y := deep)))
$(info Y=$(Y))
all:
	@:
