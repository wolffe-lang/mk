define RULE
out.txt: in.txt
	@echo build $$@ from $$<
	@cp $$< $$@
endef
$(eval $(RULE))
