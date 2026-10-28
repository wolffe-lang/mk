X = one
$(info reading: $(X))
$(warning careful: $(X)   spaced)
info:
	@echo [$(info in recipe)done]
warn:
	@echo [$(warning in recipe)done]
goals:
	@echo [$(MAKECMDGOALS)]
lazy:
	@echo [$(if ,$(error no),yes)] [$(if yes,$(info branch),no)]
