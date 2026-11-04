X = a \
	b
all: p \
	q \
	r
	@echo "[$^] [$(X)]"
p q r: ; @:
semi: p \
	q ; @echo "[$^]"
