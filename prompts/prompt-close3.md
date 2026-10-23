# mk — closeout 3 of 8: one helper that compares everything (giveaway allowed)

Edit `test.sh` in place, in the small steps below; never rewrite it whole. The reviewer ran the code in this prompt against today's `mk` and it behaves as described.

**Why.** Most rows capture output with `local x=$(...)`, which throws the exit status away. J3 never compares the status, and it lists `diamond` and `vars` twice. One helper fixes that for every new row: it runs make and mk with the same arguments, each in its own clean copy, and compares the sorted output, the exit status and every file left behind. Each later row is then one matrix line, not a new function. Under `set -e`, a status is caught as `out=$(cmd) || st=$?`; a bare `out=$(cmd); st=$?` would stop the script at the first failure.

### Step 1 — `ROOT`
After the line `CORPUS_DIR="tests/corpus"`, add one line:

```bash
ROOT=$(pwd)
```

### Step 2 — the helper
Insert this function just above the line `# Run the matrix (use a temp file to avoid subshell issues with while-read)`:

```bash
# same_as_make ROW DIR ARGS... — make and mk with ARGS, each in its own clean copy of DIR.
# U1 and U2 run each tool once first and compare the second run. Compared: the sorted
# output (make:/mk: read as TOOL:), the exit status, and every file left (names and bytes).
same_as_make() {
    local row="$1" dir="$2"
    shift 2
    local a b
    a=$(mktemp -d)
    b=$(mktemp -d)
    cp -R "$CORPUS_DIR/$dir/." "$a/"
    cp -R "$CORPUS_DIR/$dir/." "$b/"
    clean_copy "$a" "$dir"
    clean_copy "$b" "$dir"
    if [ "$row" = U1 ] || [ "$row" = U2 ]; then
        (cd "$a" && "$MAKE" "$@" >/dev/null 2>&1 </dev/null) || true
        (cd "$b" && "$ROOT/mk" "$@" >/dev/null 2>&1 </dev/null) || true
    fi
    local make_out mk_out make_st=0 mk_st=0
    make_out=$(cd "$a" && "$MAKE" "$@" 2>&1 </dev/null) || make_st=$?
    mk_out=$(cd "$b" && "$ROOT/mk" "$@" 2>&1 </dev/null) || mk_st=$?
    make_out=$(printf '%s\n' "$make_out" | sed 's/^make:/TOOL:/' | sort)
    mk_out=$(printf '%s\n' "$mk_out" | sed 's/^mk:/TOOL:/' | sort)
    local make_files mk_files
    make_files=$(cd "$a" && find . -type f | sort | while read -r f; do echo "$f"; cat "$f"; done | shasum)
    mk_files=$(cd "$b" && find . -type f | sort | while read -r f; do echo "$f"; cat "$f"; done | shasum)
    rm -rf "$a" "$b"
    if [ "$make_out" = "$mk_out" ] && [ "$make_st" = "$mk_st" ] && [ "$make_files" = "$mk_files" ]; then
        echo "ok $row $dir $*"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $row $dir $* (make exit $make_st, mk exit $mk_st)"
        FAIL=$((FAIL + 1))
    fi
}
```

### Step 3 — the run loop reads arguments
Replace the loop

```bash
while read -r row dir; do
    run_test "$row" "$dir"
done < "$MATRIX_FILE"
```

with

```bash
while read -r row dir args; do
    case "$row" in
        J3) same_as_make "$row" "$dir" $args ;;
        *) run_test "$row" "$dir" ;;
    esac
done < "$MATRIX_FILE"
```

### Step 4 — J3 through the helper, on the right twelve directories
Replace

```bash
for dir in $STANDARD fail missing cycle wide diamond vars; do
    MATRIX="$MATRIX
J3 $dir"
done
```

with

```bash
for dir in $STANDARD fail missing cycle wide; do
    MATRIX="$MATRIX
J3 $dir -j 2"
done
```

Then delete the function `test_j3` (its comment line included) and the line `J3) test_j3 "$copy" "$dir" ;;` in `run_test`. Nothing calls them any more.

**Verify:** `./test.sh` prints `ok J3 <dir> -j 2` for each of the twelve directories, and ends `Results: 48 passed, 0 failed (expected:       48)`. Commit: `test.sh: same_as_make compares output, status and files; J3 uses it on the twelve directories`. Then stop.
