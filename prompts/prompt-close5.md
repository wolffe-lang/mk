# mk — closeout 5 of 8: the flag rows, the refuse row, and the plant (giveaway allowed)

Edit `test.sh` in place; never rewrite it whole.

### Step 1 — the flag rows
After the J3/U1/U2/D1 loop, add:

```bash
MATRIX="$MATRIX
K1 fail -k -j 2
K1 missing -k
K1 missing -k -j 2
S1 ignore -s
S1 ignore -s -j 2
V1 vars A=override
V1 vars A=override -j 2
RJ refuse"
```

In the run loop, change `J3 | U1 | U2 | D1)` to `J3 | U1 | U2 | D1 | K1 | S1 | V1)`. RJ goes through `run_test`, below. V1 compares the `vars.out` both tools write. make's is `A=override B=override two C=three D=x y E=<your $HOME> H= O=`.

### Step 2 — RJ, refusals under -j
Insert this function just above `# P1: mk -p on vars matches the golden file`, and add `RJ) test_rj "$copy" "$dir" ;;` to `run_test`'s `case`, after the `P1)` line:

```bash
# RJ: every refused construct answers the same under -j 2: mk -j 2 -f X.mk prints what
# mk -f X.mk prints, and both exit 2
test_rj() {
    local copy="$1" dir="$2"
    local pass_all=true
    for mkfile in "$copy"/*.mk; do
        local one two st1=0 st2=0
        one=$("$MK" -f "$mkfile" 2>&1 </dev/null) || st1=$?
        two=$("$MK" -j 2 -f "$mkfile" 2>&1 </dev/null) || st2=$?
        if [ "$one" != "$two" ] || [ "$st1" -ne 2 ] || [ "$st2" -ne 2 ]; then
            pass_all=false
        fi
    done
    if $pass_all; then
        echo "ok RJ $dir"
        PASS=$((PASS + 1))
    else
        echo "FAIL: RJ $dir"
        FAIL=$((FAIL + 1))
    fi
}
```

**Verify step 2:** `./test.sh` ends `Results: 92 passed, 0 failed (expected:       92)`. Commit: `test.sh: K1/S1/V1 flag rows and RJ refusals under -j 2`.

### Step 3 — the plant (a gate never seen red is not a gate)
1. Undo closeout 2a only: make the parallel path ignore `dry_run` again, with the smallest edit. Rebuild.
2. Run `./test.sh 2>&1 | grep -E 'FAIL|Results'` and paste it. The `D1` rows must be `FAIL`, with `Results: … failed` and exit 1.
3. Restore the fix (`git diff run.lu` must be empty afterwards). Rebuild, and run `./test.sh` green at 92 again.

Nothing of the plant is committed.

**Verify:**
- the red paste and the green `Results` line;
- `git status --short run.lu` empty;
- `git log --oneline | head -3`.

Then stop.
