SRC = a.c b.c
OBJ = $(patsubst %.c,%.o,$(SRC))
all: $(filter %.o,$(OBJ) x.c)
	@echo [$^]
a.o b.o:
	@echo built $@
