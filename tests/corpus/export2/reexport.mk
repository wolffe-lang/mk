export X = original
unexport X
export X
all:
	@printf "make=[$(X)] shell=[%s]\n" "$X"
