all: a b
a b: ; @echo $@
b: a
