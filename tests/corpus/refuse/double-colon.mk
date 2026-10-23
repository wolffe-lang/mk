# double-colon rules are not supported
prog:: a.o
	gcc -o $@ $^
