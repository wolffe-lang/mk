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

## Fix prompts from the judge (read `judge.md` first)

### P0.4 — recipe lines: the number gmake reports, and the continued line's tab

Rows first, red: a directory `tests/corpus/recipes/` with this Makefile (tabs are real tabs) and `rows` of
`build` and `keep -k`; commit the inputs (`git add` the Makefile and rows: the copy is cleaned to tracked
files, so an uncommitted fixture vanishes before the row runs), then `rows: recipes (red)`.
```make
a:
	@echo one \
	 two \
	 three
	@true
	printf "[%s]\n" x \
		  y \
	z
	false \
	 more
```
gmake prints (paste it yourself and compare): the `printf` line echoed as three lines `printf "[%s]\n" x \`,
`	  y \` (ONE tab), `z` (no tab), then `[x] [y] [z]` on three lines, then `false \` / ` more` echoed, then
`gmake: *** [Makefile:6: a] Error 1` — 6, because the recipe's first line is physical 2 and `false` is the
fourth logical recipe line (index 4): **N = first recipe line + logical index**, continuation and blank
lines not counted.

Then the code, in `parse.lu`:
1. `join_continuations` already carries each logical line's first physical number. For a recipe line, when
   joining a continuation, keep the backslash and the newline in the text (gmake hands them to the shell)
   and drop exactly one leading tab from the continued physical line. Non-recipe lines keep today's join
   (backslash-newline → one space).
2. `Rule` gains `first_recipe_line: int` (the physical line of its first recipe line, 0 if none). The error
   in `run.lu` prints `first_recipe_line + index`, where `index` is the recipe line's position in
   `rule.recipe` (0-based); `recipe_lines` is then unused — delete it.
`./test.sh` green with the new rows (`Results: 96`). Commits: `recipes: a continued line keeps its
newline and loses one tab`, `recipes: the error line is first recipe line + logical index`. CHANGELOG
`### Fixed` under a new `## Unreleased`.

**Verify:** `./mk -C tests/corpus/recipes 2>&1 | sed "s|$(cd tests/corpus/recipes && pwd -P)|DIR|"` pasted
beside the same with `gmake`; `./test.sh | tail -1`. Stop.

### P0.5 — every exit under -C says Leaving; missing separator; the missing -f file

Rows first, red: `tests/corpus/early/` with `Makefile` = `all:\n\t@true\n`, `bad.mk` = `all:\nfoo bar\n`,
and `rows`:
```
sep -f bad.mk
nofile -f nope
sepC -C . -f bad.mk
nofileC -C . -f nope
```
Commit the inputs, then `rows: early exits (red)`. Expected (paste from gmake, with `gmake:` → `mk:`):
```
Makefile:2: *** missing separator.  Stop.            ← bad.mk:2 here, since the file is bad.mk
mk: nope: No such file or directory
mk: *** No rule to make target 'nope'.  Stop.
```
each exit 2, and under `-C` the `Entering`/`Leaving` lines around them.

The code:
1. `parse.lu`: a line that is not blank, not a comment, not a recipe line, not an assignment, not a rule
   and not a refusal is an error: `{file}:{line}: *** missing separator.  Stop.`, exit 2. Give the parse
   error path the makefile's name (it has the line already).
2. `main.lu`: a `-f` file that cannot be read prints the two gmake lines above (the name as given), exit 2.
3. `main.lu`: one exit path. Make `main` compute the status into a variable and fall through to a single
   place that prints `Leaving` (when `-C` was given) and returns; every `return 2` after `Entering` becomes
   an assignment and a jump to that place (a `var status`, and the early-exit blocks set it and skip the
   rest; wolf has no goto, so wrap the middle in a function `run(f) -> int` called once: `let status =
   run(f)`, then the Leaving line, then `return status`). `-C` to a directory that does not exist: paste
   gmake's answer (`gmake -C /nonexistent`) and match it, including whether Leaving is printed.
Commits: `missing separator`, `-f: the missing file's two lines`, `-C: Leaving on every exit`. CHANGELOG
`### Fixed`.

**Verify:** the four `early` rows `ok`; `./test.sh | tail -1` (100); `./mk -C . -f nope; echo $?` from
`tests/corpus/early`. Stop.

### P0.6 — close again

fmt/test/test.sh green; `VERSION` `0.2.1`; CHANGELOG `## Unreleased` → `## 0.2.1 (<today>)`; README's row
count (100) in both places; commit `Release 0.2.1: recipe lines and early exits`; the clone proof as in
P0.3. Stop for the judge.
