reverse = $(2) $(1)
map = $(foreach a,$(2),$(call $(1),$(a)))
double = $(1)$(1)
foreach:
	@echo [$(foreach i,a b c,$(i).o)] [$(foreach i,,x)] [$(i)] [$(foreach i,1 2,$(foreach j,x y,$(i)$(j)))]
call:
	@echo [$(call reverse,a,b)] [$(call double,ab)] [$(call map,double,p q)] [$(call reverse)] [$(call nosuch,a)] [$(call reverse,a)]
callzero:
	@echo [$(call reverse,$(0),z)] [$(call double)]
X = x
S := simple
R = recursive $(S)
U = $(undefined_thing)
override OVR = o
ENVB ?= b
value:
	@echo '[$(value R)] [$(value S)] [$(value U)] [$(value nosuch)] [$(R)]'
origin:
	@echo [$(origin X)] [$(origin S)] [$(origin nosuch)] [$(origin MAKE)] [$(origin CURDIR)] [$(origin HOME)] [$(origin CMDV)] [$(origin OVR)] [$(origin @)] [$(origin MAKEFILE_LIST)] [$(origin ENVB)]
flavor:
	@echo [$(flavor X)] [$(flavor S)] [$(flavor nosuch)] [$(flavor MAKE)] [$(flavor CURDIR)] [$(flavor @)] [$(flavor HOME)] [$(flavor CMDV)]
