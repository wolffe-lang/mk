# leaf: two source files, one shared between two targets
# Tests that leaf prerequisites (files with no rule) work correctly
all: out1.txt out2.txt

out1.txt: src1.txt shared.txt
	cat src1.txt shared.txt > out1.txt

out2.txt: src2.txt shared.txt
	cat src2.txt shared.txt > out2.txt
