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
intcmp:
	@echo [$(intcmp 1,2)] [$(intcmp 2,2)] [$(intcmp 3,2)] [$(intcmp 1,2,lt)] [$(intcmp 2,2,lt)] [$(intcmp 2,2,lt,eq)] [$(intcmp 3,2,lt,eq)]
intcmp5:
	@echo [$(intcmp 1,2,lt,eq,gt)] [$(intcmp 2,2,lt,eq,gt)] [$(intcmp 3,2,lt,eq,gt)] [$(intcmp -5,-3,lt,eq,gt)] [$(intcmp 1,2,a,b,c,d)]
