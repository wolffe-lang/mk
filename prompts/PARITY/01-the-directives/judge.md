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
