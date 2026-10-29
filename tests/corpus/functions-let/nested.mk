a := outer
$(info $(let a,one,[$(a)]$(let a,two,[$(a)])[$(a)]))
$(info [$(a)])
all:
	@:
