all:
	  @echo silent
	 -@exit 1
	@ - exit 2
		@echo two-tabs
	   echo shown
semi: ;  -  @exit 1
	@echo after
dry:
	@  echo x
	-  true
	 + echo plus-runs
