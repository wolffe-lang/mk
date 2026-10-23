# continuation: backslash-joined lines and a # inside a recipe
OBJS = a.txt \
       b.txt \
       c.txt

all: $(OBJS)
	@echo "built $(OBJS)"
	# this is a shell comment, not a make comment
	@echo "done"
	@echo "one \
		two"
	@echo "three \
  four"

a.txt:
	printf "a\n" > a.txt

b.txt:
	printf "b\n" > b.txt

c.txt:
	printf "c\n" > c.txt
