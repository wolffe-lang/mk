X = x
E =
if:
	@echo [$(if $(X),yes,no)] [$(if $(E),yes,no)] [$(if $(E),yes)] [$(if  $(X) ,a,b)]
or:
	@echo [$(or $(E),two,three)] [$(or $(E),$(E))] [$(or a b,c)]
and:
	@echo [$(and $(X),two,three)] [$(and $(X),$(E),three)] [$(and $(E),two)]
lazy:
	@echo [$(if $(E),$(error never),lazy)] [$(or yes,$(error never))] [$(and $(E),$(error never))]
nested:
	@echo [$(if $(X),$(or $(E),$(and a,b)),no)] [$(if ,,)]
