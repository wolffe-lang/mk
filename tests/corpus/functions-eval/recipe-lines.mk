define R
t:
	@echo a
	@echo b
	@exit 1
endef
$(eval $(R))
