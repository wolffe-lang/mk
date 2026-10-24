# self.mk — self-referencing variable
A = hello
B = $(A) $(B)
all:
	@echo $(B)
