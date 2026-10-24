# expand.mk — exercises all variable expansion forms
A = hello
B = world
AB = nested
hello = world
D = a.c b.c
NAME = AB

all:
	@echo "simple: $(A)"
	@echo "nested: $(A$(B))"
	@echo "computed: $($(NAME))"
	@echo "brace: ${A}"
	@echo "dollar: $$HOME"
	@echo "sub: $(D:.c=.o)"
	@echo "pattern: $(D:%.c=%.o)"
