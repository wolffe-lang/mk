# Track 00 — the oracle (0.2.0)

Read `prompts/PARITY/campaign.md`, "Standing rules", first. Where the code stands: `mk` 0.1.0 at trunk
`43da3d0`, 2,479 lines of wolf in `main.lu` (flags), `parse.lu` (lines → `Database`), `vars.lu` (`Vars`,
`expand`), `graph.lu` (`Graph`, `is_out_of_date`), `run.lu` (serial and parallel schedulers). `test.sh` runs
94 rows against `/usr/bin/make` (3.81). This track changes no feature: it moves the oracle to `gmake` 4.4.1,
makes `mk`'s messages 4.4.1's byte for byte, and gives later tracks a way to add rows by adding files.

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
   ```
   The `[Makefile:2: all]` part is new: the Makefile's name as given (`-f` or `Makefile`) and the **line of
   the recipe line that failed**, not the rule's line. `parse.lu`'s `Rule` has `line` (the rule's); give each
   recipe line its own line number (a `List[int]` beside `recipe`, filled in `parse_makefile` where recipe
   lines are appended; `join_continuations` must keep the first physical line's number for a joined line,
   so carry numbers through it). `run.lu` prints it in both schedulers (`build_target` and the
   `build_goals_parallel` script's `|| echo` line, which needs the number baked into the script string).
   Change messages one family at a time, rebuilding and rerunning between, and commit each family:
   `messages: 'name' quotes as 4.4.1`, `messages: recipe errors carry Makefile:line`, `messages: the -j
   option text`.
5. `./test.sh` green at 94. README: the opening line names GNU make 4.4.1; the `No rule` example and the
   `-j` text are re-pasted from `./mk`; `make` → `gmake` wherever the oracle is named. CHANGELOG: open
   `## Unreleased` with `### Changed` — "the oracle of record is GNU make 4.4.1; messages quote 'name' and
   recipe errors carry Makefile:line". Commit: `README and CHANGELOG: the oracle is 4.4.1`.

**Verify:** the red `Results` line from step 3; the green one; `./mk -C tests/corpus/fail 2>&1 | tail -1`
pasted beside `gmake -C tests/corpus/fail 2>&1 | tail -1`; `git log --oneline | head -6`. Stop.

### P0.2 — rows are files

Later tracks add dozens of rows. Today each row kind is a bash function and a matrix line. Make rows data.

1. A corpus directory may hold a file named `rows`. Each non-empty, non-`#` line is one row:
   ```
   # ID    ARGS...             (ARGS may be empty; the whole line after ID is the arguments)
   build
   again
   dry      -n
   keep     -k -j 2
   ```
   `test.sh` discovers every `tests/corpus/*/rows` and runs each line through `same_as_make` with the row
   name `<dir>/<ID>`. An ID that starts with `again` runs both tools once first and compares the second run
   (the U1/U2 shape). Everything else is `same_as_make` as it is: a fresh clean copy per tool, output
   normalised and sorted, exit status, files left.
2. `clean_copy` knows the outputs per directory by name. Replace it with one rule: before a row runs, every
   file the directory's `rows` file does **not** list under a `# keep:` line is removed from the copy, and a
   directory with no `# keep:` line keeps only `Makefile`, `rows`, `*.mk`, `golden-p.txt` and anything named in
   `# keep:`. Write it so the twelve existing directories need no `# keep:` line but `leaf` (`src1.txt
   src2.txt shared.txt`) and `vars` (`golden-p.txt` is kept by name already).
3. Move the matrix rows that are already `same_as_make` rows into `rows` files: for each of the twelve
   directories, `rows` holds `j3 -j 2`, `u1`, `again-j2 -j 2`, `d1 -n -j 2`, and the per-directory K1/S1/V1
   lines become `k1 -k -j 2` in `fail` and `missing`, `k1b -k` in `missing`, `s1 -s` and `s1j -s -j 2` in
   `ignore`, `v1 A=override` and `v1j A=override -j 2` in `vars`, `jall -j all` in `wide`. Delete those
   MATRIX lines and the `J3 | U1 | …` dispatch arm. N1/B1/B2/B3/F1/M1/C1/J1/J2/R1/P1/RJ/E1 stay as functions.
4. The row count stays 94 (paste the `Results` line). Plant: add a line `bad -k` to `tests/corpus/missing/rows`
   with a deliberately wrong expectation — there is none to edit, so instead temporarily change `-k` to `-kx`
   in that line; the row must print `FAIL: missing/bad -kx` and the script exit 1; remove the line.
5. README *Tests*: describe `rows` files in four lines (the format, `again`, `# keep:`, where the harness
   finds them). CHANGELOG `### Changed`: "rows are files". Commits: `test.sh: rows files, discovered per
   directory`, `tests: the matrix rows as rows files`, `README: rows files`.

**Verify:** `./test.sh | tail -1` (94); the plant's `FAIL:` line; `git status --short` empty;
`ls tests/corpus/*/rows | wc -l` (12). Stop.

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
