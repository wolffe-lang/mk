# mk — the release round (giveaway allowed)

The reviewer copied the working tree into an empty directory, built it, and ran `mk` beside GNU make 3.81
(`/usr/bin/make`) on every corpus directory, serially and with `-j 2`, twice each (a build, then an
up-to-date run), in separate copies for each tool, comparing sorted output, exit status and the files
produced. 46 of 48 runs agree, and `cycle` and `missing` under `-j` are fixed. What is left blocks a public
release: one wrong exit status, one wrong variable value, three message mismatches, an altered licence, and a
tree that still ships generated files. **Nothing from the last round is committed yet**: `git status` shows
every change unstaged and `prompts/` untracked. One commit per item below, in order, then stop and paste the
last lines of each verify.

### RELEASE 1 — `-k -j N` reports a failed build as success

In `tests/corpus/fail`, from clean:

| | output (sorted) | exit |
|---|---|---|
| `make -k -j 2` | `exit 3`, ``make: *** [result] Error 3``, ``make: Target `all' not remade because of errors.`` | 2 |
| `mk -k -j 2` | `exit 3`, ``mk: *** [result] Error 3`` | **0** |

`mk -k` serially gets both right, so the parallel path must make the same two decisions: a failed recipe
marks the run failed (exit 2 at the end, whatever else builds), and every goal that could not be remade
prints the serial path's ``Target `X' not remade because of errors.`` line.

### RELEASE 2 — a command-line variable must win while the Makefile is parsed

In `tests/corpus/vars`, `make A=override` writes
`A=override B=override two C=three D=x y E=<your $HOME> H= O=` and `mk A=override` writes
`B=one two`. `B := $(A) two` is expanded while parsing, and a `NAME=VALUE` from the command line overrides
every Makefile assignment of NAME from the start, including when an immediate (`:=`) assignment reads it.
Seed the variable table with the command-line values before parsing, and make a Makefile assignment to a
command-line name a no-op (not just overwritten afterwards).

### RELEASE 3 — the up-to-date message for a goal with no recipe

In `tests/corpus/wide`, run twice. The second `make` prints ``make: Nothing to be done for `all'.`` and
exit 0. `mk` prints nothing, serially and with `-j 2`. A goal with no recipe whose prerequisites all turned
out up to date (nothing was remade beneath it) prints ``Nothing to be done for `GOAL'.``; a goal with a
recipe that is up to date keeps printing ``` `GOAL' is up to date.``` as it already does.

### RELEASE 4 — `-s` and an ignored error

In `tests/corpus/ignore`, `make -s` prints nothing and exits 0. `mk -s` prints
``mk: [result] Error 1 (ignored)``. Under `-s` that line is not printed.

### RELEASE 5 — `-k` and a missing prerequisite

In `tests/corpus/missing`, `make -k` prints
``make: *** No rule to make target `missing_file', needed by `result'.`` (no `  Stop.`) and exits 2.
`mk -k` adds `  Stop.`. Under `-k` the line has no `  Stop.`; without `-k` it keeps it.

### RELEASE 6 — rows that would have caught all of this

`test.sh`'s J3 runs 14 rows but covers 12 directories (`diamond` and `vars` twice, `refuse` never), and it
never compares the exit status: `local x=$(...)` throws the status away. Fix the J3 list, capture each
tool's status separately (`out=$(...); st=$?` on its own line, not inside `local`), and add:

- a second-run row (`R2`) per directory with a Makefile, serial and `-j 2`: run once, then compare the
  second run's output and status;
- `-k -j 2` on `fail`, `A=override` on `vars` comparing the written `vars.out`, `-s` on `ignore`, `-k` on
  `missing`;
- for `refuse`, `mk -j 2 -f X.mk` equal to `mk -f X.mk` (same line, exit 2) for each file.

Plant: undo RELEASE 1 and show the `-k -j 2` row red, then green. Update the expected row count.

### RELEASE 7 — the licence is the official text, not a retyping

`LICENSE` differs from the Apache License 2.0 in four places: §1's "Contribution" reads "submitted to the
Licensor" for "submitted to Licensor", §3 drops "to You" from "any patent licenses granted to You under this
License", §4 Redistribution drops "and in Source or Object form," (which narrows the grant), and the APPENDIX
is gone. A licence is never typed from memory. Replace it with the official file and check it:

```
curl -fsSL https://www.apache.org/licenses/LICENSE-2.0.txt -o LICENSE
shasum -a 256 LICENSE   # cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30
```

### RELEASE 8 — the tree ships only inputs

`.gitignore` names files that do not exist (`wide/a` … `wide/z`, `diamond/a` … `d`, `vars/result`, …) and
misses the real outputs, so 56 generated files are still tracked, among them `vars/vars.out`, which holds the
reviewer's home directory. The outputs are exactly the rule targets that exist as files:
`auto/a b c d`, `continuation/a.txt b.txt c.txt`, `diamond/base left right`, `fail/other`,
`ignore/result`, `leaf/out1.txt out2.txt`, `phony/prog`, `vars/vars.out`, `wide/t01` … `wide/t40`
(each under `tests/corpus/`). `git rm --cached` all of them, replace the corpus part of `.gitignore` with
patterns for exactly these, and keep every Makefile, source file and `golden-p.txt` tracked. After a full
`./test.sh`, `git status --short` must be empty.

### RELEASE 9 — `--version`

Still `mk 0.1.0`. It must print `mk 0.1.0 (built with wolf 0.2.34)`, both parts from constants in one place,
exit 0.

### RELEASE 10 — the README says only what the binary does

- The usage block is the whole of `./mk --help`, pasted, byte for byte. `--help` says `-j N` while the usage
  line says `[-j [N]]`: make them agree with what the binary does with a bare `-j` (it accepts one; say so).
- The "No rule to make target" example is the binary's line, with its backtick quotes, pasted.
- The opening claim ("builds it identically to GNU make") stays only as far as the rows prove it: say what
  `test.sh` compares, row by row, and keep the sentence to that.
- The `Files` table lists `REVIEW.md`, which is deleted. It lists exactly `git ls-files` at the top level,
  plus `prompts/` and `tests/corpus/`.
- `prompts/` holds `prompt.md`, `prompt-followup.md`, `prompt-resume.md`, `prompt-final.md` and this file.

**Verify:** `wolf build main.lu -o mk` exit 0; `wolf fmt --check *.lu`; `wolf test .` and `./test.sh` green
with the new rows; the plant red then green; `git status --short` empty after the tests; then
`git clone . /tmp/mk-fresh && cd /tmp/mk-fresh && wolf build main.lu -o mk && ./test.sh` green;
`shasum -a 256 LICENSE` as above; `./mk --help` diffed against the README's usage block, empty.
