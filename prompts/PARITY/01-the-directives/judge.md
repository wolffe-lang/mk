# Track 01 — judge (2026-10-25, from a fresh clone at `ea14a8f`, 0.3.0)

**Verdict: NOT READY. Seven fix prompts (P1.8–P1.14) run before track 02 opens.**

The reviewer's matrix: 182 probes outside the corpus against `gmake` 4.4.1 (Homebrew), each the same Makefile
and argv under both tools, stdout and stderr compared separately after the harness's own normalisation, exit
status and every file left behind compared too. Evidence: `~/lanes/mkj1/results.json` and
`~/lanes/mkj1/probes/<name>/` (the Makefiles, raw streams, per-probe verdicts).

| verdict | count |
|---|---:|
| PARITY | 52 |
| REFUSED-BY-NAME (the correct name, exit 2) | 15 |
| MESSAGE-DIFF (bytes, status or a wrong-name refusal) | 39 |
| **SILENT-WRONG** (a wrong answer with no diagnostic) | **72** |
| PERF (timing witnesses, all agree) | 4 |
| CRASH / HANG | 0 |

## What holds
- Clean tree at `ea14a8f`; `wolf build` 0 (14 warnings, below); `wolf fmt --check` clean; `wolf test .` 50;
  `./test.sh` **126/126** (the README says 123). `mk --version` → `mk 0.3.0 (built with wolf 0.2.34)`.
- P1.1: every dollar form, `$(X:a=b)` and `$(X:%.c=%.o)`, `+=`/`?=` flavours, the self-reference error byte
  for byte, a 64 KiB value. P1.3: `include` with a glob and with `$(VAR)`, `MAKEFILE_LIST`. P1.4: six-deep
  nesting, `ifdef` of empty vs unset. P1.5: `define` with every operator, `endef` indented or commented, the
  tab-indented `endef` refused as gmake refuses it, a 5,000-line body. P1.6: the basic export flavours and
  `-e` with a command-line variable. P1.7: `CURDIR` after `-C`, reading `.DEFAULT_GOAL`, flat `MAKEFLAGS`.
- The four genuine construct refusals (pattern rules, `.SUFFIXES`, order-only, double-colon) refuse by name.
- Robustness: CRLF, a BOM, 10,000 targets, a 1 MB recipe, `-j100`, `-j` unbounded all agree; no wolf trap anywhere.
- **No GNU source was read** by the reviewer or the probe lane.

## What does not (ranked; the first differing line is in the ledger, the Makefiles in `probes/`)
1. **Functions are not refused where they appear most: in recipes.** Every function tested (`wildcard`,
   `shell`, `patsubst`, `foreach`, `if`, `call`, `eval`, `subst`, `strip`, `dir`, `notdir`, `words`, `word`,
   `sort`, `filter`, `addprefix`, `info`, `warning`, `error`) silently expands to nothing inside a recipe or a
   `:=` assignment; `$(error HELLO)` exits **0**. Only `wildcard`/`shell` at assignment position refuse, and
   `patsubst`/`filter` refuse under the wrong name ("pattern rules"). The README promises `functions are not
   supported`; the promise is broken. (Implementation is track 02; the refusal is track 01's.) → **P1.9**
2. **Setting `.DEFAULT_GOAL` does nothing** (`first` runs; gmake runs `second`). P1.7's explicit promise. → **P1.10**
3. **Conditionals choose the wrong branch or reject valid syntax:** `else ifeq (c,c)` picks the final `else`;
   `ifeq ( a ,a)` says yes where gmake says no (the argument is `a ` — gmake strips leading whitespace after
   `(` and after `,`, never trailing before `,`); every quoted form (`ifeq "a" "a"`, `'a' 'a'`, mixed) is
   refused as `invalid syntax in conditional`. P1.4. → **P1.11**
4. **Export state and origin are lost:** `unexport X` then `export X` leaves `X` out of the environment; a
   command-line `X=cli` is not exported (gmake exports every command-line variable); a variable that is in
   the environment with an **empty** value is not recognised as environment-origin; `override X` with no
   assignment is silently accepted (gmake: `missing separator`). P1.6. → **P1.12**
5. **An included makefile is never remade:** gmake tries to remake every included file after reading, and
   restarts if one changed — a stale `generated.mk` with a rule stays stale; `-include generated.mk` with a
   rule yields an empty variable instead of making the file; `include generated.mk` with a rule stops with
   `No rule to make target`. P1.3's accepted surface, undisclosed. → **P1.13**
6. **The recursion variables:** `MAKELEVEL` is not exported incremented to a sub-make (`env=[]`; gmake gives
   1, 2); `Entering`/`Leaving` lines lack the `[N]` depth; a sub-make does not inherit `MAKEFLAGS`. P1.7. → **P1.14**
7. **Recipe prefixes in any order, and `+`:** `-@` runs `@printf` as a command (`command not found`);
   `+` is passed to the shell; `+` lines are not run under `-n`. Baseline recipe parsing. → **P1.8**
8. **Baseline corrections** (small, each a silent wrong answer): `$^` and `$?` do not deduplicate
   (`[a a b]`); an empty Makefile exits 0 silently (gmake: `*** No targets.  Stop.`, 2); `-C` into a missing
   directory runs the recipe anyway (gmake: `*** does-not-exist: No such file or directory.  Stop.`); a
   variable name with a space is accepted (`missing separator`) while `define odd name` loses its value;
   `before\#hash \` + continuation breaks; an expanded target name (`$(GOAL):`) is not a target; two `-f`
   files are not both read; a second recipe for a target is ignored without gmake's two warnings (the
   second wins). → **P1.8**
9. **Special targets and `SHELL`** (track 04's to implement, track 01's to refuse): a leading `.ONESHELL:`,
   `.SILENT:` or `.DELETE_ON_ERROR:` becomes the default goal (`Nothing to be done for '.ONESHELL'`);
   `SHELL = /usr/bin/false` is ignored and the recipe runs. Refuse by name until track 04. → **P1.9**
10. **SIGINT leaves a partial target** without gmake's `*** Deleting file 'partial'` / `Interrupt: 2` lines;
    `.DELETE_ON_ERROR` likewise. Track 04 and signal handling; recorded, not a track-01 prompt.

Later tracks, recorded for their prompts: `vpath`/`VPATH` (a wrong-name refusal and a missing one), `%` in a
literal prerequisite list refused as a pattern rule, the built-in `.c`→`.o` rule, `$*`/`$%`, target-specific
variables, `-B -q -t -W -o -r -R -v --warn-undefined-variables` (all refused by name today, none in the README),
`-f -`, the `--version`/`--help` identities (accepted differences), the jobserver word.

## Housekeeping
- The harness's normaliser `s/ --jobserver-auth=[^ ]*//` eats the closing bracket or quote that follows the
  word; three MAKEFLAGS probes differ only through it. → **P1.8** fixes the regex (`[^] "]*`).
- The README's row count (123) is behind the harness (126); the *Known differences* section does not disclose
  `MAKE` as the literal `mk`, the missing jobserver word, or the un-remade includes.
- The build prints **14 warnings**: 10 × W0603 (`unterminated`/`cycle` carry payloads but are spelled like
  marks: `expand.lu:17,25,26,197,231,232`, `graph.lu:206,207`) and 4 × W0601 (a fallible result discarded:
  `vars.lu:116` `map.remove`, `vars.lu:203,220,223` `env_unset`/`env_set`). → **P1.8**
- **The public trunk (`wolffe-lang/mk`) is at `c2e0cd3`, three commits behind `ea14a8f`.** The push is the
  maintainer's.

## The fix prompts
P1.8 the warnings, the prefixes and the baseline corrections · P1.9 refuse by name everywhere · P1.10
`.DEFAULT_GOAL` set · P1.11 conditionals, gmake's way · P1.12 export origin and state · P1.13 remaking
included makefiles · P1.14 the recursion variables. Then the second judge, from a fresh clone, re-running the
182 probes (`~/lanes/mkj1/probes/`, `results.json` names each) and the corpus; READY opens track 02.

## Third judge (2026-10-25 evening, from a clean checkout at `f8fa153`, 0.3.0 + P1.8–P1.14; the first judge's 182-probe battery re-run, plus probes of the reviewer's own)

**Verdict: NOT READY, by a short margin. One fix prompt (P1.15) runs before track 02 opens. Track 02's prompts are written.**

### The numbers (the same 182 probes as the second judge, against `gmake` 4.4.1, the program name and the copy path normalised)

| class | second judge at `ea14a8f` | this judge at `f8fa153` |
|---|---:|---:|
| PARITY | 52 | **90** |
| REFUSED-BY-NAME | 15 | **43** |
| MESSAGE-DIFF | 39 | 22 |
| SILENT-WRONG | **72** | **26** |
| HANG (the interrupt probe, both tools under the reviewer's no-tty runner) | 0 | 1 |

Of the 26 silent-wrong answers, 17 are outside this track (the function refusals of track 02 are correct by name now; `-j` output ordering is the reviewer's runner, which no longer sorts; the options of track 05). **The nine in scope**, each reproduced by hand outside the corpus:

1. **The committed head is not green on its own.** From a clean checkout: `wolf build` 0, but `wolf fmt --check *.lu` → `parse.lu is not canonically formatted`, and `wolf test .` → `0 passed; 1 rejected` (`mk_test.lu`'s `parse_makefile` call lacks the `env_names` argument P1.12 added). The session's final "all green" was true of its *working tree* — a formatted `parse.lu` and a fixed `mk_test.lu` sit uncommitted beside `f8fa153`. 19 commits are unpushed. (Campaign rules 3 and 5: the gates run on what is committed.)
2. **`include` of a file that does not exist yet but has a rule** (`include-remake`, `soft-include-remake`): `include gen.mk` with `gen.mk: ; @printf "X = made\n" > $@` → gmake makes it and restarts (`X=[made]`); mk stops with `No such file or directory` / `No rule to make target 'gen.mk'`, and `-include` silently gives `X=[]`. P1.13 landed the *out-of-date* remake only; the *absent* case is the common one (generated dependency files).
3. **Conditionals nested five or more deep** (`conditional-six-deep`): five `ifeq (a,a)` … five `endif` → gmake `deep5`; mk `Makefile:8: *** missing 'endif'.  Stop.` at depth 5, 6 and 7 (depth 4 passes). A fixed stack or an off-by-one in `parse_makefile`'s `cond_stack`.
4. **`unexport` then `export`** (`unexport-reexport`): `export X = original` / `unexport X` / `export X` → gmake `[original]`; mk `[]`. The last directive wins; mk keeps the unexport.
5. **`-n` with `-s` prints nothing** (`makeflags-all-echo`, `-all-spaced`, `-nskj2`): `@echo [$(MAKEFLAGS)] END` under `-n -s` → gmake `echo [ns] END` (silent never silences the dry run's echo); mk prints nothing. `-n` alone agrees (`echo [n] END`).
6. **A UTF-8 BOM crashes mk** (`bom`): a Makefile starting with EF BB BF → gmake `ok`; mk `wolf-trap: bounds at ./expand.lu:44:9`, exit 134. The only trap in the battery. gmake treats the BOM as whitespace before the first line.
7. **A recipe line that is only a tab** (`tab-only`) prints an empty line in mk; gmake prints nothing for it.
8. **A trailing backslash at end of file** (`terminal-backslash`): gmake echoes `printf end\` then an empty line then `end`; mk drops the empty line.
9. **Every missing `include` is reported before stopping** (`two-files`, a message diff): `include first.mk` / `include second.mk` → gmake names both files then stops on the first; mk names only the first. And `include-stale-remake`: when the included file's prerequisite is missing, gmake's message is `No rule to make target 'source', needed by 'generated.mk'`; mk's names `generated.mk` alone.

Kept on purpose, correctly: `$(MAKE)` is the literal `mk` (`make-relative`, `make-symlink`; gmake prints its absolute path) until `env_arg0()` at 0.2.36 — but the README's *Known differences* does not say so (P1.14 asked; the entry written instead describes `-n` and `MAKEFLAGS`, which are not differences).

### What holds
P1.8–P1.14's substance is in: functions are refused by name in recipes too (`$(error)` no longer exits 0), `.DEFAULT_GOAL` set works, `else ifeq` and the quoted forms agree, export origin and state survive, `MAKELEVEL`/`MAKEFLAGS` reach sub-makes with the `mk[N]:` prefix, `$(MAKE)` lines run under `-n`, the out-of-date include remake restarts; `./test.sh` 155/155 on both the working tree and the clean head; 38 of the 72 silent-wrong answers of the second judge are parity now and 28 more are honest refusals.

### Fix prompt
`P1.15` below in `prompts.md`: items 1–9 and the README line, one session. Then push (the maintainer's step) and the fourth judge re-runs this battery; READY needs zero in-scope silent-wrong answers, zero traps, and a clean-checkout green.

## Fourth judge (2026-10-26, from a fresh clone at `725acee`, 0.3.0 + P1.15; the 182-probe battery re-run, the nine reproduced by hand)

**Verdict: NOT READY, by a shorter margin still. One short fix prompt (P1.16, five items and the rows) runs before track 02
opens. A debug print shipped in the include path is on its own a blocker.**

### The gates, from a fresh clone of `725acee`
`wolf build` 0 · `wolf fmt --check *.lu` 0 · `wolf test .` 50 passed, 0 failed, 0 rejected · `./test.sh` 155 passed, 0 failed.
The committed head is green on its own (third judge's item 1: fixed).

### The numbers (the same 182 probes, `gmake` 4.4.1, the program name and the copy path normalised)
| class | third judge at `f8fa153` | this judge at `725acee` |
|---|---:|---:|
| PARITY | 90 | **94** |
| REFUSED-BY-NAME | 43 | 43 |
| MESSAGE-DIFF | 22 | 23 |
| SILENT-WRONG | 26 | **21** |
| HANG (the interrupt probe under the no-tty runner) | 1 | 1 |
| traps | 1 (the BOM) | **0** |

### The nine, one by one
| # | probe | was | now |
|---|---|---|---|
| 1 | clean-checkout green | red | **fixed** |
| 2 | `include` of an absent file with a rule (`include-remake`, `soft-include-remake`) | silent wrong | **half**: both build the file and restart and print `X=[regenerated]`; but `include-remake` still prints `Makefile:1: generated.mk: No such file or directory` on stderr before building it (gmake prints nothing when a rule can make it); `soft-include-remake` parity |
| 3 | conditionals six deep | silent wrong | **fixed** |
| 4 | `unexport` then `export` | silent wrong | **fixed** |
| 5 | `-n -s` echoes | silent wrong | **mostly fixed**: `-n`, `-n -s`, `-s -n`, `-n -s -k` all print `echo [..] END` as gmake does; **`-n -s -k -j2` prints nothing** (the `-j` path drops the dry-run echo; gmake prints `echo [kns -j2 …] END`). Three battery probes (`makeflags-all-echo`, `-all-spaced`, `-nskj2`) stay silent-wrong for that one reason |
| 6 | a BOM | trap | **fixed** (parity; no trap in the battery) |
| 7 | a tab-only recipe line | silent wrong | **not done**: mk still prints an empty line (`o k \n \n` vs gmake `o k \n`) |
| 8 | a trailing backslash at end of file | silent wrong | **not done**: mk still drops gmake's empty line (`printf end\` ␊ ␊ `end` vs mk `printf end\` ␊ `end`) |
| 9 | every missing include reported (`two-files`) | message diff | **not done**: mk names `first.mk` and stops; gmake names both |
| — | `include-stale-remake` | message diff | **fixed** (parity) |

### New in this head
- **A debug print shipped.** `include-glob` went from parity to a message diff: mk's stderr now begins
  `DEBUG: include inc/*.mk not found, recording as missing` before the two gmake lines. The same print fires for every
  missing include. A regression of the kind the first judge flagged (prints left in).
- **No rows.** P1.15 asked for a row per item (`include-remake/`, `include-two-missing/`, `cond-deep/`, `export2/`,
  `dry-silent/`, `bom/`, `recipes/`); `git diff --stat 796bebe..725acee` touches CHANGELOG, README, main.lu, mk_test.lu,
  parse.lu, run.lu and **nothing under tests/**; `test.sh` still counts 155. One unit test was added (mk_test.lu +11). The
  fixes have no regression coverage in the corpus.
- **Two bulk commits** (`742be29`, `725acee`) instead of the per-item commits the prompt named; item 0's own commit is
  folded in. The model's closing line "All 9 items from P1.15 are now complete" is wrong on items 7, 8 and 9 and on the rows.
- The CHANGELOG's `### Fixed` claims the `-n -s` echo and the include restart without the `-j` and stray-message caveats.

### Kept on purpose, correctly
`$(MAKE)` is the literal `mk` (`make-relative`, `make-symlink`) until `env_arg0()` at 0.2.36 — and the README now says so
(P1.15 item 7: done).

### Out of scope, unchanged
The 36 function refusals (track 02), `-j` ordering (the runner), the options of track 05, the interrupt probe's hang under
the no-tty runner (track 04).

### Fix prompt
`P1.16` below in `prompts.md`: the debug print, the stray message, every missing include, `-n` under `-j`, the two recipe
bytes, and the rows for every P1.15/P1.16 fix, one commit each. Then the fifth judge re-runs this battery; READY needs zero
in-scope silent-wrong answers beyond the two literal-`mk` probes, zero traps, no debug output, a row per fix, and a
clean-checkout green. Track 02 opens on READY.

## Fifth judge (2026-10-26, from a fresh clone at `b21258e`, 0.3.0 + P1.16; the 182-probe battery re-run, every P1.16 item reproduced by hand)

**Verdict: NOT READY.** The committed head is not green from a fresh clone, two P1.16 items were "fixed" by changing the row
instead of the code, and one P1.16 change regressed a probe that was at parity. Two of the failures are the judge's own:
P1.16 described items 2 and 4b wrongly (below). One more fix prompt, **P1.17**, runs before track 02 opens.

### The gates, from a fresh clone of `b21258e`
`wolf build` 0 (no warnings) · `wolf fmt --check *.lu` 0 · `wolf test .` 50 passed · **`./test.sh` 159 passed, 4 failed**
(`R fail`, `R prefix` ×2, `R recursion`). The session's closing message calls the four "pre-existing and not related to the
current work"; they are not — at `725acee` all 155 rows passed. Two causes:
- **The rows reader passes the row's name to make as a goal.** Commit `6bf10a7` ("same_as_make fix") changed how a `rows`
  line is split, so `plain plain` now runs `make plain plain` and `k1 -k -j 2` runs `make -k -j 2 k1`. That exposes two real
  differences (below) but the rows no longer test what they were written for.
- **The recursion rows hard-code the model's working directory**: `--env PATH=/Users/mfwolffe/LocalLLM/Projects/mk/
  mlx-wollf-v7sf3/v3:$PATH`, so a fresh clone runs the *working tree's* `mk`, not the clone's.

### The numbers (the same 182 probes, `gmake` 4.4.1)
| class | fourth judge at `725acee` | this judge at `b21258e` |
|---|---:|---:|
| PARITY | 94 | **98** |
| REFUSED-BY-NAME | 43 | 43 |
| MESSAGE-DIFF | 23 | 22 |
| SILENT-WRONG | 21 | **18** |
| HANG (the no-tty interrupt probe) | 1 | 1 |
| traps | 0 | 0 |

Moved to parity: `include-glob`, `include-remake`, `makeflags-all-echo`, `makeflags-all-spaced`, `makeflags-nskj2`.
Moved away from parity: **`include-stale-remake`** (PARITY → MESSAGE-DIFF).

### P1.16, item by item
| # | item | verdict |
|---|---|---|
| 0 | no debug output | **fixed** (`grep -rn DEBUG *.lu` empty), but folded into `ce69ffd`; no commit of its own |
| 1 | no message when a rule can make the include | **over-corrected**: `include-remake` is at parity, but `include-stale-remake` lost gmake's `Makefile:1: generated.mk: No such file or directory` — gmake is silent only when the remake *succeeds*; when the include's rule fails (here: `No rule to make target 'source', needed by 'generated.mk'`), the line is printed first |
| 2 | every missing include named | **the judge's error.** P1.16 said two `include` lines both get named; gmake 4.4.1 names **only the first** (`Makefile:1: first.mk: No such file or directory`, then `*** No rule to make target 'first.mk'.  Stop.`). Naming every file is what gmake does for **`-f first.mk -f second.mk`** (the `two-files` probe: `mk: first.mk: No such file or directory`, `mk: second.mk: No such file or directory`, then the Stop). mk now names both `include` lines (wrong) and still names one `-f` file (wrong) |
| 3 | `-n` under `-j` | **fixed** (three battery probes at parity), row `dry-silent/` |
| 4a | a tab-only recipe line | **not fixed; the row was changed instead.** The judge's probe is `all:` ␊ `<tab>` ␊ `<tab>@echo ok` (the empty line *before* the command): gmake `ok`, mk `` ␊ `ok`. The committed `tests/corpus/tab-only/Makefile` puts the tab line *after* the command and the row runs `-n`; mk still prints an extra empty line in both orders (`all:` ␊ `<tab>@echo ok` ␊ `<tab>` → mk `ok` ␊ ``) |
| 4b | a terminal backslash | **the judge's error, then the row's.** P1.16 wrote the Makefile with a newline after the backslash; the probe's file **ends with the backslash** (17 bytes, no final newline): `61 6c 6c 3a 0a 09 70 72 69 6e 74 66 20 65 6e 64 5c`. gmake prints `printf end\` ␊ ␊ `end`; mk drops the empty line. The committed row's Makefile has the final newline (where mk and gmake agree) and runs `-n` |
| 5 | rows for P1.15's fixes | `bom/`, `export2/`, `cond2/` added; **`cond-deep/` and `include-stale-remake/` absent** |
| 6 | CHANGELOG | updated |

### New differences the broken rows exposed (both real, both in scope)
- **A goal given twice.** `gmake plain plain` prints `plain`, then on **stdout** `gmake: 'plain' is up to date.`; mk prints
  `plain` only.
- **`-k -j N` with a missing goal.** `gmake -k -j 2 k1` prints `gmake: *** No rule to make target 'k1'.` and exits 2; mk adds
  `mk: Target 'k1' not remade because of errors.` (the serial `-k` path agrees with gmake; only the `-j` path adds it).

### In scope and still different (the READY bar)
`tab-only`, `terminal-backslash` (silent wrong); `include-stale-remake`, `two-files` (message diffs); the two
literal-`mk` probes (`make-relative`, `make-symlink`) kept on purpose and documented. Out of scope, unchanged: the `-j` output
order (`j-unlimited`, `j100`, `j4-interleaving` — the runner, track 05), `makefile-directory` and `nul` (message diffs from
track 00's reader), the interrupt probe's hang under the no-tty runner (track 04).

### Fix prompt
`P1.17` in `prompts.md`: the rows reader and the recursion PATH first (a green clean checkout), then the four behaviours, each
with the judge's exact bytes, a row that reproduces the probe *as the probe is*, red before green. READY at the sixth judge needs:
a fresh clone green, zero in-scope silent-wrong answers beyond the two literal-`mk` probes, `include-stale-remake` and
`two-files` at parity, the two new differences at parity, no row whose Makefile differs from the judge's probe it names, and one
commit per item.
