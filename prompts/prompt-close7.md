# mk — closeout 7 of 8: usage errors say what is wrong, and a bare -j sets no limit (giveaway allowed)

Edit in place, rebuild after each change, and make one commit per item.

### CLOSE 7a — a usage error names its problem

Every usage error exits 2 and prints **nothing**:

| command | `mk` today | GNU make 3.81 (stderr, exit 2) |
|---|---|---|
| `mk -x` | nothing, exit 2 | `make: invalid option -- x`, then its usage |
| `mk -f` (no file) | nothing, exit 2 | `make: option requires an argument -- f`, then its usage |
| `mk -j 0` | nothing, exit 2 | ``make: the `-j' option requires a positive integral argument``, then its usage |

For each kind of usage error in `parse_flags` (unknown option, a missing argument to `-f`, `-C` or `-j`, a bad job count), print one line to stderr naming it, in GNU make's words with `mk:`:
- `mk: invalid option -- x`
- `mk: option requires an argument -- f`
- ``mk: the `-j' option requires a positive integral argument``

Then print the usage, the first two lines of `--help` (`Usage: mk …` and `       mk --help`), also on stderr. Nothing goes to stdout, and the exit status stays 2. A long option mk does not know (`--foo`) prints `mk: unrecognized option '--foo'`. Commit: `Usage errors name the problem and print the usage`.

### CLOSE 7b — `-j` without a number sets no limit

In GNU make, a `-j` not followed by a whole number above 0 means **no limit**, and the next argument is read as usual. From clean in `tests/corpus/wide` (40 targets, each `sleep 0.2`):

| command | GNU make | `mk` today |
|---|---|---|
| `-j` (last argument) | all 40 at once, 0.24 s, exit 0 | one at a time, 8.6 s |
| `-j all` | all 40 at once, `all` is the goal, exit 0 | nothing printed, exit 2 |

In `parse_flags`, read the argument after `-j` as a job count only when it is a whole number above 0. A `-j` with no count means no limit; represent that as a job count no smaller than the number of targets. `-j 0` and `-j -3` stay the 7a error. Update `--help`'s line to `  -j [N]     allow up to N jobs at once; no N: no limit`. Commit: `-j without a number sets no limit`.

### CLOSE 7c — the rows

1. Add `J3 wide -j all` and `E1 wide` to the `MATRIX="$MATRIX` block closeout 5 wrote, after `RJ refuse`.
2. Insert this function just above `# P1: mk -p on vars matches the golden file`, and add `E1) test_e1 "$copy" "$dir" ;;` to `run_test`'s `case`, after the `RJ)` line:

```bash
# E1: a usage error names its problem on stderr's first line, prints nothing on
# stdout, and exits 2
test_e1() {
    local copy="$1" dir="$2"
    local pass_all=true
    local cases="-x|mk: invalid option -- x
-f|mk: option requires an argument -- f
-j 0|mk: the \`-j' option requires a positive integral argument"
    while IFS='|' read -r args want; do
        local out err first st=0
        out=$(cd "$copy" && "$ROOT/mk" $args 2>/dev/null </dev/null) || st=$?
        err=$(cd "$copy" && "$ROOT/mk" $args 2>&1 >/dev/null </dev/null || true)
        first=$(printf '%s\n' "$err" | head -1)
        if [ "$st" -ne 2 ] || [ -n "$out" ] || [ "$first" != "$want" ]; then
            echo "  E1: mk $args: exit $st, first line: $first"
            pass_all=false
        fi
    done <<< "$cases"
    if $pass_all; then
        echo "ok E1 $dir"
        PASS=$((PASS + 1))
    else
        echo "FAIL: E1 $dir"
        FAIL=$((FAIL + 1))
    fi
}
```

**Verify:**
- `./test.sh` ends `Results: 94 passed, 0 failed (expected:       94)`;
- `cd tests/corpus/wide && rm -f t[0-9][0-9] && time ../../../mk -j > /dev/null; rm -f t[0-9][0-9]; cd -` is under 2 s;
- `./mk -x; echo $?`, pasted.

Commit: `test.sh: E1 usage errors and -j followed by a goal`. Then stop.
