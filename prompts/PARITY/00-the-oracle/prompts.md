# Track 00 — the oracle (0.2.0)

Do `prompts/PARITY/campaign.md`'s "Start of every session" first. Where the code stands: `mk` 0.1.0 at trunk
`43da3d0`, 2,479 lines of wolf in `main.lu` (flags), `parse.lu` (lines → `Database`), `vars.lu` (`Vars`,
`expand`), `graph.lu` (`Graph`, `is_out_of_date`), `run.lu` (serial and parallel schedulers). `test.sh` runs
94 rows against `/usr/bin/make` (3.81). This track changes no feature: it moves the oracle to `gmake` 4.4.1,
makes `mk`'s messages 4.4.1's byte for byte, and gives later tracks a way to add rows by adding files.

**On commits:** the commit names below are the shape to aim for while the work is ahead of you. Once edits
exist, never undo, stash, revert or re-type them to split them into those groups. If the changes interleave,
commit them as one batch whose message lists what it holds, say so in the verify, and move on (campaign rule 5).

### P0.1 — the oracle is gmake 4.4.1

1. In `test.sh`, `MAKE="make"` becomes `MAKE="${MAKE:-gmake}"`, and the pre-flight checks the version:
   `"$MAKE" --version | head -1` must be `GNU Make 4.4.1`, else `echo "ERROR: $MAKE is not GNU Make 4.4.1"`
   and exit 2 (a loud failure, like the other pre-flights).
2. `normalize()` is `sed -E 's/^(gmake|make|mk):/MAKE:/'` and `same_as_make` uses the same three names:
   `gmake` prints `gmake:`, not `make:`.
3. Run `./test.sh`. **46 rows go red** (paste the `Results` line): 4.4.1 quotes names `'x'` where 3.81
   wrote `` `x' ``, and its recipe errors carry the recipe's place. Commit the harness alone, red:
   `test.sh: the oracle is GNU make 4.4.1 (46 rows red)`.
4. Make `mk`'s messages 4.4.1's. Every line below was pasted from `gmake`; `mk` prints the same with `mk:`
   for `gmake:`:
   ```
   gmake: *** No rule to make target 'x', needed by 'all'.  Stop.
   gmake: *** No rule to make target 'x', needed by 'all'.        ← under -k, no Stop.
   gmake: Target 'all' not remade because of errors.
   gmake: 'all' is up to date.
   gmake: Nothing to be done for 'all'.
   gmake: Circular b <- a dependency dropped.
   gmake: *** [Makefile:2: all] Error 3
   gmake: [Makefile:2: all] Error 3 (ignored)
   gmake: the '-j' option requires a positive integer argument
   gmake: Entering directory '/private/tmp/x'      ← under -C (and -w), first line of output
   gmake: Leaving directory '/private/tmp/x'       ← and the last line, even after an error
   ```
   **The directory lines.** 4.4.1 prints them whenever `-C` is given (and under `-w`; `--no-print-directory`
   is track 05's). The path is the **physical** working directory after the change, symlinks resolved.
   wolf gives it to you: `main.lu` already has `use std.env` and calls `env.set_cwd(f.dir)` for `-C`
   (line 340); `env.cwd() -> str ! {io}` beside it returns exactly that physical path (WOLF-NOTES §std.env;
   the reviewer ran it: `env.set_cwd("sub")` then `env.cwd()` → `/private/tmp/…/sub`, from a symlinked path
   too). Print `mk: Entering directory '…'` right after `set_cwd` and `mk: Leaving directory '…'` as the
   last line before exit, on stdout as gmake does. **The harness side:** the two tools run in different
   temporary copies, so their paths differ. In `same_as_make`, after capturing each tool's output, replace
   that tool's own copy path with the token `DIR` (`sed "s|$a|DIR|g"` on make's output, `sed "s|$b|DIR|g"`
   on mk's) before `normalize`. Rows that ran `-C "$copy"` already exist (N1, B1, M1, …); do the same
   replacement in them, with the copy's realpath (`cd "$copy" && pwd -P`), because gmake prints the physical
   path and `mktemp -d` on macOS returns the `/var/folders/…` spelling of a `/private/var/folders/…` directory.
   The `[Makefile:2: all]` part is new: the Makefile's name as given (`-f` or `Makefile`) and the **line of
   the recipe line that failed**, not the rule's line. `parse.lu`'s `Rule` has `line` (the rule's); give each
   recipe line its own line number (a `List[int]` beside `recipe`, filled in `parse_makefile` where recipe
   lines are appended; `join_continuations` must keep the first physical line's number for a joined line,
   so carry numbers through it). `run.lu` prints it in both schedulers (`build_target` and the
   `build_goals_parallel` script's `|| echo` line, which needs the number baked into the script string).
   Change messages one family at a time, rebuilding and rerunning between, and commit each family:
   `messages: 'name' quotes as 4.4.1`, `messages: recipe errors carry Makefile:line`, `messages: the -j
   option text`, `messages: Entering and Leaving directory under -C`, `test.sh: the copy path is DIR`.
5. `./test.sh` green at 94. README: the opening line names GNU make 4.4.1; the `No rule` example and the
   `-j` text are re-pasted from `./mk`; `make` → `gmake` wherever the oracle is named. CHANGELOG: open
   `## Unreleased` with `### Changed` — "the oracle of record is GNU make 4.4.1; messages quote 'name' and
   recipe errors carry Makefile:line". Commit: `README and CHANGELOG: the oracle is 4.4.1`.

**Verify:** the red `Results` line from step 3; the green one; `./mk -C tests/corpus/fail 2>&1 | tail -1`
pasted beside `gmake -C tests/corpus/fail 2>&1 | tail -1`; `git log --oneline | head -6`. Stop.

### P0.2 — rows are files

Superseded by `pickup-P0.2.md` in this directory, written when the first session halted before a rewrite of
`test.sh`: the same goal (rows as `rows` files, `again…` rows compare the second run, copies cleaned to the
directory's git-tracked files, the matrix rows migrated), as five small edits with a commit each.

### P0.3 — close the track

1. `wolf fmt --check *.lu`, `wolf test .`, `./test.sh` green; `git status --short` empty.
2. `main.lu`: `VERSION` becomes `0.2.0`. CHANGELOG: `## Unreleased` → `## 0.2.0 (<today>)`. README: the
   *Tests* row count, and under a new heading **Known differences from GNU make** one line: usage errors
   print `mk`'s own option list, not GNU make's (`gmake -x` prints 50 lines of options; `mk -x` prints its
   usage; the first line agrees and the E1 row checks it).
3. Commit: `Release 0.2.0: the oracle is GNU make 4.4.1`.
4. `rm -rf /tmp/mk-t0 && git clone -q . /tmp/mk-t0 && cd /tmp/mk-t0 && wolf build main.lu -o mk && wolf fmt --check *.lu && wolf test . | tail -1 && ./test.sh | tail -1`.

**Verify:** the clone's two result lines; `./mk --version`; `git log --oneline | head -12`. Stop here: the
reviewer judges the track before `01-the-directives` opens.
