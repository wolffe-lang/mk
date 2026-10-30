F = got-$(1)
X = initial
Y := $(error HELLO)
all:
	@printf "result=[%s] X=[%s]\n" "$(Y)" "$(X)"
