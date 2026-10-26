Track 01 — pickup for P1.14, the last phase of the track (a fresh session, 2026-10-25 evening)

Do `prompts/PARITY/campaign.md`'s "Start of every session" first: `cp ../../../WOLF-NOTES.md .` and read it, then README,
SPEC, CHANGELOG, the campaign's *Standing rules*, `00-the-oracle/judge.md`, this track's `prompts.md` from the top (P1.14 is
its last phase, line ~356) and `judge-P1.1.md`. Then read this file to the end before touching anything. **Do not rewrite any
file. At most ~60 lines per edit. Do not write probe programs under /tmp. Do not run `wolf build mk_test.lu`** (`wolf build
main.lu -o mk` builds the whole directory; `wolf test .` runs the unit tests). When you notice you are about to write the same
paragraph a second time, stop writing and run a command instead.

## Where the track stands

Committed and green at HEAD `43ba195`: P1.1–P1.13. **Uncommitted in the tree, all of P1.14's code, and it works:**
- `main.lu` (+61/−): `MAKELEVEL` read from the environment at start, the variable set, exported as N+1; `mk_prefix(level)` →
  `mk:` / `mk[N]:`; the level read once before the `-C` block so the nine `Entering directory`/`Leaving directory` prints and the
  `-C` error lines carry the prefix; `MAKEFLAGS` built from the flags and exported.
- `run.lu` (+76/−64), `vars.lu` (+8), `mk_test.lu` (+4): the prefix on every stderr line; `wolf test .` green.
- `test.sh` (+37/−9): `same_as_make` now consumes `--env NAME=value … --` wherever it sits and expands the values with `eval`
  (so `$PATH` means the harness's PATH). Correct. One bug remains, below.
- `tests/corpus/recursion/` — **untracked**: `Makefile`, `sub/Makefile`, `sub/deep/Makefile`, `rows` (`levels`, `flags -k -j2`,
  `dry -n`, each with `--env PATH=<this dir>:$PATH --`).

By hand, from `tests/corpus/recursion`, `gmake -C .`/`./mk -C .`, `-k -j2`, all print identical normalized output and exit 0.
`./test.sh | tail -1` says `153 passed, 2 failed (expected: 155)`, but read on: that count hides a harness fault.

## Step 0 — the harness, two lines of cause

**Fault A (the one you were circling on):** `./test.sh: line 511: args[@]: unbound variable` (and 512, 515, 516). This is
bash 3.2 (`/bin/bash` on this Mac) under `set -u`: expanding `"${args[@]}"` when the array is **empty** is an error. It fires
for every row that has NO extra arguments (`j3`, `again`, `R`, `build`, …), not for `flags`/`dry`. Those rows print `ok` only
because both sides fail the same way (empty output, the same status) — a false green. The script already guards the other
array the right way: `${envs[@]+"${envs[@]}"}`. Do the same for `args` at the four sites:

```
"${args[@]}"   →   ${args[@]+"${args[@]}"}
```

Verify: `./test.sh 2>&1 | grep -c unbound` prints `0`.

**Fault B (why `flags` and `dry` both exit 2 in the harness and pass by hand):** `clean_copy` deletes from the temp copy every
file that `git ls-files tests/corpus/recursion` does not list. The recursion corpus is untracked, so the copy is emptied —
Makefiles and all — and both tools fail with no makefile (exit 2). The fix is the one the prompt already asked for:

```
git add tests/corpus/recursion
```

Verify: `./test.sh 2>&1 | grep -E "^(ok|FAIL).*recursion"` → `levels` and `flags` ok. `dry` may still fail: that is P1.14's
last bullet, real work, below.

Commit the harness fix on its own: `test.sh: guard an empty args array under set -u`. (The corpus add goes into the P1.14
commit.)

## Step 1 — the one piece of P1.14 not yet written: `$(MAKE)` lines run under `-n`

By hand, `gmake -n` in `tests/corpus/recursion` prints the `printf` line, then **runs** `gmake -C sub` (the manual, *How the
MAKE Variable Works*: under `-n`, a recipe line containing `$(MAKE)` or `${MAKE}` is executed, not just printed), so the output
shows `Entering directory '…/sub'`, the sub's printf line, `gmake -C deep`, and so on down. `mk -n` prints `mk -C sub` and
stops. Implement it where P1.8's `+` prefix is handled (run.lu ~102: a line starting with `+` runs under `-n`): a recipe line
that **contains** `$(MAKE)` or `${MAKE}` **before expansion** takes the same path as a `+` line. Read that code first; the
change is a condition, not a new mechanism. Then `wolf build main.lu -o mk && ./test.sh 2>&1 | grep -E "^(ok|FAIL).*recursion"`.
If `dry` still differs, paste both normalized outputs side by side (the harness's `normalize` + `sort`, as the two sed lines
you used before) and name the one line that differs before changing anything.

## Step 2 — close the phase as the prompt says

1. `wolf fmt --check *.lu`, `wolf test .`, `./test.sh | tail -1` → `155 passed, 0 failed (expected: 155)`.
2. Commit: `recursion: MAKELEVEL, the [N] prefix, MAKEFLAGS inherited, $(MAKE) lines run under -n` (the corpus included).
3. README *Known differences*: `MAKE` is the literal `mk` until `env_arg0()` (0.2.36); the jobserver word is absent from
   `MAKEFLAGS` (track 05's). Re-paste the row count (155). CHANGELOG entry for P1.14.
4. `git log --oneline | head -12`. Stop for the second judge.
