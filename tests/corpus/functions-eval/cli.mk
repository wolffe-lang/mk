$(eval X := file)
$(eval override Y := forced)
$(info X=$(X) $(origin X) Y=$(Y) $(origin Y))
all:
	@:
