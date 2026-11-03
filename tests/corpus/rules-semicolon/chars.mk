all: pipe colons percent
pipe: ; @echo a | tr a b
colons: ; @echo a::b
percent: ; @printf '%s\n' pct
