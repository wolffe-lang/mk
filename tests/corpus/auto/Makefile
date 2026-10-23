# auto: $@ $< $^ in recipes writing their values to files
all: c d

a:
	printf "a" > a

b: a
	printf "$@" > b

c: b
	printf "$<" > c

d: a b
	printf "$^" > d
