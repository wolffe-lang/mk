A = hello
B = world
C =

ifeq ($(A),hello)
X = yes
else
X = no
endif

ifneq ($(B),foo)
Y = not_foo
else
Y = is_foo
endif

ifdef A
Z = a_set
else
Z = a_unset
endif

ifndef C
W = c_unset
else
W = c_set
endif

all:
	@echo X=$(X) Y=$(Y) Z=$(Z) W=$(W)
