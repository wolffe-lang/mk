out: FORCE
	@echo "out ran [$?]"
FORCE:
semi: FORCE ; @echo "semi ran [$?]"
final: group
	@echo "final ran [$?]"
group: a
a: ; @echo a
