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

## Standing rules (every prompt, every track)

1. **Read this file's rules before the first prompt of a session**, then the track's `prompts.md` from the
   top: it says where the previous prompts left the code.
2. **Edit in place.** Never rewrite a whole file. At most about 60 lines per edit; a new module is a new
   file. The sessions that hung were all rewriting a file in one go.
3. **Rebuild before every test run:** `wolf build main.lu -o mk`, then `wolf fmt --check *.lu`, `wolf test .`,
   `./test.sh`. All three green before any commit that says "green".
4. **Rows first, red.** Each feature prompt adds its rows (a corpus directory with a `Makefile`, its inputs
   and a `rows` file) and commits them while they are red: `rows: <feature> (red)`. Then the implementation
   commit makes them green. The history shows the gate red before green.
5. **One commit per item**, imperative, one line, no trailers: `include, -include and sinclude`, not
   "Implement include support". The prompt names each commit.
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
| `01-the-directives` | 0.3.0 | a real expander (nesting, computed names, `$(VAR:a=b)`); one-pass evaluation; `include`/`-include`/`sinclude`; `ifeq`/`ifneq`/`ifdef`/`ifndef`/`else`/`endif`; `define`/`endef`/`undefine`; `override`/`export`/`unexport`/`-e`; `MAKE`, `CURDIR`, `MAKEFILE_LIST`, `.DEFAULT_GOAL` | 7 |
| `02-the-functions` | 0.4.0 | text functions (`subst` … `lastword`), file-name functions (`dir` … `abspath`, `wildcard`), `if`/`or`/`and`/`intcmp`, `foreach`, `call`, `value`, `origin`, `flavor`, `eval`, `shell` and `!=`, `error`/`warning`/`info`, `file`, `let`; `MAKECMDGOALS` | 8 |
| `03-the-rules` | 0.5.0 | pattern rules and chains, static pattern rules, order-only `\|`, double-colon, grouped targets `&:`, every automatic variable (`$*` `$+` `$\|` `$%` and the `D`/`F` forms), recipes on the rule line (`;`), `.RECIPEPREFIX`, "overriding recipe" warnings, empty recipes | 7 |
| `04-the-special-targets` | 0.6.0 | `.DEFAULT`, `.PRECIOUS`, `.INTERMEDIATE`, `.SECONDARY`, `.NOTINTERMEDIATE`, `.DELETE_ON_ERROR`, `.IGNORE`, `.SILENT`, `.NOTPARALLEL`, `.WAIT`, `.ONESHELL`, `.POSIX`, `.SECONDEXPANSION`, `.EXTRA_PREREQS`, `.SHELLFLAGS`/`SHELL`; target- and pattern-specific variables; `VPATH`/`vpath`; intermediate-file deletion | 8 |
| `05-the-options` | 0.7.0 | `-B -q -t -o -W -i -S -w -C -I -r -R -l -O --trace --warn-undefined-variables --no-print-directory`; `MAKEFLAGS`/`MFLAGS`/`GNUMAKEFLAGS`/`MAKELEVEL`; `$(MAKE)` recursion with the 4.4 fifo jobserver; "Entering directory" | 8 |
| `06-the-builtins` | 0.8.0 | the implicit rule database and default variables (`gmake -p` on an empty Makefile is the golden: 155 rules, 157 variables), suffix rules and `.SUFFIXES`, archive members `lib(m.o)`; `-p` byte-identical | 6 |
| `07-the-proof` | 1.0.0 | a corpus of real Makefiles; a random-Makefile differential fuzzer against `gmake`; the message sweep; the README as a parity table | 4 |

Each track's `prompts.md` is written when the track opens, from the code as it then stands, so its hints
name real functions. `00` and `01` are written now.

## Ledger

| track | opened | judged | verdict |
|---|---|---|---|
| 00-the-oracle | 2026-10-23 | | |
