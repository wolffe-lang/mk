# mk — closeout 4 of 8: the second run and the dry run, as rows (giveaway allowed)

Edit `test.sh` in place; never rewrite it whole. Closeout 3's `same_as_make` already runs U1 and U2 twice and compares the second run, so these rows are matrix lines only.

### Step 1 — the rows
In the J3 loop closeout 3 wrote, add three lines per directory, so it reads:

```bash
for dir in $STANDARD fail missing cycle wide; do
    MATRIX="$MATRIX
J3 $dir -j 2
U1 $dir
U2 $dir -j 2
D1 $dir -n -j 2"
done
```

- **U1 / U2:** the second run, serial and with `-j 2`. Its output and status, such as ``Nothing to be done for `all'.`` and ``` `left' is up to date.```, equal make's.
- **D1:** `-n -j 2` prints what make prints and leaves no file behind (closeout 2's 2a).

### Step 2 — dispatch
In the run loop, change `J3)` to `J3 | U1 | U2 | D1)`.

**Verify:** `./test.sh` ends `Results: 84 passed, 0 failed (expected:       84)`. Paste the `U1`, `U2` and `D1` lines for `wide` and `phony`. Commit: `test.sh: U1/U2 second-run rows and D1 dry-run rows on every directory`. Then stop.
