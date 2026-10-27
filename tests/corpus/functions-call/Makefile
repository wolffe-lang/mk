reverse = $(2) $(1)
map = $(foreach a,$(2),$(call $(1),$(a)))
double = $(1)$(1)
foreach:
	@echo [$(foreach i,a b c,$(i).o)] [$(foreach i,,x)] [$(i)] [$(foreach i,1 2,$(foreach j,x y,$(i)$(j)))]
call:
	@echo [$(call reverse,a,b)] [$(call double,ab)] [$(call map,double,p q)] [$(call reverse)] [$(call nosuch,a)] [$(call reverse,a)]
callzero:
	@echo [$(call reverse,$(0),z)] [$(call double)]
