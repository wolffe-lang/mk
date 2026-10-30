all: b
	@echo all sees x=$(X)
b:
	$(eval X := from-b)@echo b
