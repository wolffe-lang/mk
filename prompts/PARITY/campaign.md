# mk — the parity campaign

**Goal.** `mk` answers every Makefile the way GNU make 4.4.1 does: the same recipes in a valid order, the
same files, the same messages byte for byte, the same exit status. Today it refuses eight constructs by
name (pattern rules, `include`, conditionals, `define`, `.SUFFIXES`, order-only prerequisites, double-colon
rules, functions) and knows nothing of the built-in rule database, `vpath`, special targets beyond `.PHONY`,
target-specific variables, recursion, or most options. The campaign removes each refusal and then every
remaining difference, in **tracks**. A track is a sprint whose unit of work is a prompt: the prompts in
`prompts/PARITY/<TRACK>/prompts.md`, given to the model one at a time, in order. At the end of each track
the reviewer judges from a fresh clone and the next track opens only on READY.

**The oracle of record is GNU make 4.4.1** (`gmake`, Homebrew). Apple's 3.81 at `/usr/bin/make` is no
longer compared against. Every expected answer in a prompt or a row is pasted from `gmake`, never typed
from memory, and every difference `mk` keeps on purpose is a named line in the README.

## Background: mk as it stands

`mk` is a `make` written in wolf by wollf-v7sf3, a 27B model, driven through opencode by the prompts in
`prompts/`: `prompt.md` built it in phases from `SPEC.md` (the specification: what the subset is, the
corpus, the rows), then `prompt-followup.md`, `prompt-resume.md`, `prompt-final.md`, `prompt-release.md`,
`prompt-close1.md` … `prompt-close8.md` and `prompt-ship.md` took it to the state a reviewer could judge
from a fresh clone and publish: `https://github.com/wolffe-lang/mk`, 0.1.0, Apache-2.0, trunk `43da3d0`.

What it does today, in 2,479 lines of wolf, one module, one `main`:

| file | holds |
|---|---|
| `main.lu` | `Flags`, `parse_flags` (`-f -C -n -s -k -j [N] -p`, `NAME=VALUE`, goals; usage errors in GNU's words), `build_vars`, `main` |
| `parse.lu` | `join_continuations`, `strip_comment`, `check_refusal` (the eight refusals by name), `parse_assignment`/`parse_rule`/`parse_phony`, `parse_makefile` → `Database` (assignments, rules, phonies), `print_database` for `-p` |
| `vars.lu` | `Vars`, `set_var` with the four flavours (`=` `:=` `?=` `+=`), `var_value`, `expand` (`$(X)`, `${X}`, `$$`; the environment as a fallback), `expand_auto` (`$@ $< $^ $?`) |
| `graph.lu` | `Graph`/`Node`, `build_graph`, `is_out_of_date` (missing, a newer prerequisite by mtime, rebuilt this run, phony), `newer_prereqs` |
| `run.lu` | `build_goals_serial` (recursive, `-n`/`-s`/`-k`), `build_goals_parallel` (a process table, up to N `sh -c` scripts in flight, the same decisions), the cycle drop |
| `mk_test.lu` | 42 unit tests (parser, flavours, expansion) |
| `test.sh` | 94 rows against GNU make: each in a fresh copy of a `tests/corpus/<dir>/`; `same_as_make` compares sorted output, exit status and the files written |

What it refuses, each by name with exit 2: pattern rules, `include`, conditionals, `define`, `.SUFFIXES`,
order-only prerequisites, double-colon rules, functions. What it does not know at all: built-in rules and
variables, `vpath`, special targets other than `.PHONY`, target-specific variables, `$(MAKE)` recursion,
and every option outside the seven above. `SPEC.md` §2 and the README's *The subset* tables are the exact
line. The campaign crosses it.

How it was built matters for how it is extended. The model writes well inside one function and one file
and loses the thread when a prompt asks for a whole new file at once or a change in several places with no
map; it reproduces GNU's messages only when the bytes are in front of it; it trusts its own oracle over the
real one unless told the real one is the judge. So each prompt below names the functions to touch, pastes
the bytes to match, keeps the edits small, and ends in a verify it must paste back.

## Start of every session

Before the first prompt of a session, in the project directory:

1. `cp ../../../WOLF-NOTES.md ./WOLF-NOTES.md` (the wolf toolchain as installed; shared by every project
   here; it is git-ignored, never commit it) and read it fully.
2. Read `README.md`, `SPEC.md`, `CHANGELOG.md`, and this file's *Standing rules*.
3. Read the current track's `prompts.md` from the top, and the previous track's `judge.md` if there is one.
4. `wolf build main.lu -o mk && wolf fmt --check *.lu && wolf test . && ./test.sh | tail -1` must be green
   before the first edit; if it is not, stop and say so.

## When wolf says `cannot compile this yet — … @A..B`

That line is the compiler's conservatism ledger, not a syntax error, and it names **no file**: `A..B` is a byte
range into ONE of the `.lu` files of the module. Never guess which; find it:

```sh
for f in *.lu; do python3 -c "import sys;b=open('$f','rb').read();print('$f', repr(b[A:B]) if len(b)>B else '')"; done
```

(with `A` and `B` the numbers from the message). The file whose bytes read as code at that range is the one. The
usual cause is not what the message says: a call to a function that **may fail** (`-> T ! {…}`) used as a plain
value, with no `else |e| …` handler and no `?`, makes the value's type a result, and the next method call on it
(`.words()`, `.len`, …) is then reported as "methods on builtin types". Add the handler the other call sites
use, rebuild, and the real error appears with its file and line. Try `lupin main.lu` too: its diagnostics
differ from the compiler's and often name the place. Do not rewrite the file the message seems to point at.

## Standing rules (every prompt, every track)

1. **Start of every session** above, every time: the notes, the README, the spec, this file, the track.
2. **Edit in place.** Never rewrite a whole file. At most about 60 lines per edit; a new module is a new
   file. The sessions that hung were all rewriting a file in one go.
3. **Rebuild before every test run:** `wolf build main.lu -o mk`, then `wolf fmt --check *.lu`, `wolf test .`,
   `./test.sh`. All three green before any commit that says "green".
4. **Rows first, red.** Each feature prompt adds its rows (a corpus directory with a `Makefile`, its inputs
   and a `rows` file) and commits them while they are red: `rows: <feature> (red)`. Then the implementation
   commit makes them green. The history shows the gate red before green.
5. **One commit per item**, imperative, one line, no trailers: `include, -include and sinclude`, not
   "Implement include support". The prompt names each commit. **But never undo, stash, revert or re-type
   finished edits to get there.** The commit list is the shape to aim for while the work is still ahead;
   once edits exist in the tree, the only commands are `git add` and `git commit`. If the changes are
   interleaved and cannot be staged in the groups the prompt named, commit them as one batch with a message
   that lists what it holds (`include and -I DIR: the directive, the search path, the rows`), say so in the
   verify, and move on. A clean history is worth less than the working tree; a reviewer would rather read one
   honest batch commit than a tidy sequence made by deleting and rewriting working code.
6. **The README moves with the code.** A construct leaves the *Refused* table and enters the *Accepted* table
   in the same prompt that lands it, with its one-line example. The usage block is re-pasted from `./mk --help`
   whenever `--help` changes. The *Tests* section's row count is updated at every track's last prompt. A
   difference kept on purpose goes under a *Known differences from GNU make* heading the moment it is known.
7. **The CHANGELOG moves with the code.** While a track is open the top section is `## Unreleased`, with
   `### Added`, `### Changed`, `### Fixed`; every prompt adds its lines. The track's last prompt renames the
   section to the track's version with the date, bumps `VERSION` in `main.lu`, and commits `Release 0.N.0`.
8. **Clean room.** GNU make's *manual* and `gmake` itself (its output, `gmake -p`, `gmake --help`) are the
   references. **GNU make's source code is never read**, nor any other make's. A row's expected bytes come
   from running `gmake`.
9. **Rows compare three things**: sorted output with the program name normalised, the exit status, and every
   file left in the directory (name and bytes). `same_as_make` in `test.sh` does this; a row that compares
   less says why in a comment.
10. **Stop at the end of each prompt** and paste the verify lines it asks for. Never start the next prompt.
11. **At the track's last prompt, stop for the judge.** The reviewer clones, builds, runs their own matrix
    against `gmake`, and writes `<TRACK>/judge.md`: READY, or fix prompts appended to `prompts.md` as
    `P<track>.<n>` to run before the next track.

## The tracks

| track | version | what lands | prompts |
|---|---|---|---|
| `00-the-oracle` | 0.2.0 | `gmake` 4.4.1 as the oracle; 4.x messages (`'x'` quotes, `[Makefile:N: target]` on errors); data-driven rows (`rows` files) | 3 |
| `01-the-directives` | 0.3.0 | a real expander (nesting, computed names, `$(VAR:a=b)`); one-pass evaluation; `include`/`-include`/`sinclude`; `ifeq`/`ifneq`/`ifdef`/`ifndef`/`else`/`endif`; `define`/`endef`/`undefine`; `override`/`export`/`unexport`/`-e`; `MAKE`, `CURDIR`, `MAKEFILE_LIST`, `.DEFAULT_GOAL` | 7 + 7 fix prompts |
| `02-the-functions` | 0.4.0 | text functions (`subst` … `lastword`), file-name functions (`dir` … `abspath`, `wildcard`), `if`/`or`/`and`/`intcmp`, `foreach`, `call`, `value`, `origin`, `flavor`, `eval`, `shell` and `!=`, `error`/`warning`/`info`, `file`, `let`; `MAKECMDGOALS` | 8 |
| `03-the-rules` | 0.5.0 | pattern rules and chains, static pattern rules, order-only `\|`, double-colon, grouped targets `&:`, every automatic variable (`$*` `$+` `$\|` `$%` and the `D`/`F` forms), recipes on the rule line (`;`), `.RECIPEPREFIX`, "overriding recipe" warnings, empty recipes | 7 |
| `04-the-special-targets` | 0.6.0 | `.DEFAULT`, `.PRECIOUS`, `.INTERMEDIATE`, `.SECONDARY`, `.NOTINTERMEDIATE`, `.DELETE_ON_ERROR`, `.IGNORE`, `.SILENT`, `.NOTPARALLEL`, `.WAIT`, `.ONESHELL`, `.POSIX`, `.SECONDEXPANSION`, `.EXTRA_PREREQS`, `.SHELLFLAGS`/`SHELL`; target- and pattern-specific variables; `VPATH`/`vpath`; intermediate-file deletion | 8 |
| `05-the-options` | 0.7.0 | `-B -q -t -o -W -i -S -w -C -I -r -R -l -O --trace --warn-undefined-variables --no-print-directory`; `MAKEFLAGS`/`MFLAGS`/`GNUMAKEFLAGS`/`MAKELEVEL`; `$(MAKE)` recursion with the 4.4 fifo jobserver; "Entering directory" | 8 |
| `06-the-builtins` | 0.8.0 | the implicit rule database and default variables (`gmake -p` on an empty Makefile is the golden: 155 rules, 157 variables), suffix rules and `.SUFFIXES`, archive members `lib(m.o)`; `-p` byte-identical | 6 |
| `07-the-proof` | 1.0.0 | a corpus of real Makefiles; a random-Makefile differential fuzzer against `gmake`; the message sweep; the README as a parity table | 4 |

Each track's `prompts.md` is written when the track opens, from the code as it then stands, so its hints
name real functions. `00`, `01` and `02` are written now.

## Ledger

| track | opened | judged | verdict |
|---|---|---|---|
| 00-the-oracle | 2026-10-23 | 2026-10-23, 2026-10-24 | NOT READY on 2026-10-23 (three probes outside the corpus; P0.4–P0.6); **READY** on 2026-10-24 at `5942bdd` (0.2.1): 100/100, the three probes agree (`00-the-oracle/judge.md`) |
| 01-the-directives | 2026-10-24 | P1.1 judged 2026-10-24 | P1.1 **NOT READY**: nothing committed, fmt red, unterminated and self-referencing variables not GNU's error, `$xy`, `sh` vs `/bin/sh`, an unasked 0.2.2 (`01-the-directives/judge-P1.1.md`, fix prompt P1.1b) |
| 01-the-directives | 2026-10-24 | 2026-10-25 at `ea14a8f` (0.3.0) | **NOT READY**: 182 probes vs gmake 4.4.1 → 52 parity, 15 refused by name, 39 message diffs, **72 silent wrong answers**, 0 crashes; functions not refused in recipes (`$(error)` exits 0), `.DEFAULT_GOAL` set ignored, `else ifeq` and quoted `ifeq` wrong, export origin/state lost, includes never remade, MAKELEVEL not exported, `-@`/`+` prefixes, `$^` dedup, 14 build warnings (`01-the-directives/judge.md`; fix prompts P1.8–P1.14) |
| 01-the-directives | 2026-10-24 | 2026-10-25 evening at `f8fa153` (0.3.0 + P1.8–P1.14) | **NOT READY, by a short margin**: the battery re-run → 90 parity, 43 refused by name, 22 message diffs, **26 silent wrong** (9 in scope), 1 trap (a BOM); the committed head not green on its own (fmt, the unit-test call site), 19 commits unpushed; fix prompt P1.15 (`01-the-directives/judge.md`, third judge). **Track 02's prompts written** (`02-the-functions/prompts.md`, P2.1–P2.8); it opens when the fourth judge says READY |
