.DEFAULT_GOAL := second
first:
	@echo first
second:
	@echo second-[$(.DEFAULT_GOAL)]
