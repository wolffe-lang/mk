# fail: a recipe that exits 3; another independent target
all: result

result:
	exit 3
	printf "result" > result

other:
	printf "other" > other
