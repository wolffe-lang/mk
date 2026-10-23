# pattern rules are not supported
%.o: %.c
	gcc -c -o $@ $<
