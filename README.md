# mk

> **Built by wollf.** This program was written by [wollf-v7sf3](https://huggingface.co/wolffe-lang/wollf-v7sf3),
> a 27B model trained to write wolf, driven through opencode by the prompts in `prompts/`, with a human
> reviewer judging each phase and writing the next. Every claim below is pasted from the binary; the test
> script is the reason to trust it.

A `make` for a growing part of GNU make — targets, prerequisites, recipes, variables in
every flavour, automatic variables, mtime-driven rebuilds, `-n`, `-k`, `-j N`, `include`,
conditionals, `define`, and every GNU make function. What it refuses it names (*Refused*
below); what it does differently on purpose is under *Known differences*. `test.sh` compares
`mk` against GNU make 4.4.1 row by row: the output, the exit status and the files written.

The refusals and usage errors are checked by name.

## Install

```
wolf build main.lu -o mk
```

Requires wolf (https://github.com/wolffe-lang/wolf-lang) and a POSIX shell; tested with
wolf 0.2.36, the version `./mk --version` names.

## Usage

```
Usage: mk [-f FILE] [-C DIR] [-n] [-s] [-k] [-j [N]] [-p] [-I DIR] [-e] [NAME=VALUE]... [GOAL]...
       mk --help
       mk --version

  -p         print the parsed database (variables sorted, rules in file order)
  -n         print recipes without running them
  -s         silent mode (do not print recipes)
  -k         keep going after a failure
  -j [N]     allow up to N jobs at once; no N: no limit
  -f FILE    read FILE as the Makefile
  -C DIR     change to DIR before doing anything
  -I DIR     search DIR for included makefiles
  -e         environment variables override Makefile assignments
  --version  print the version and exit
  NAME=VALUE set a variable from the command line
```

## The subset

### Accepted

| construct | example |
|---|---|
| rules | `all: prog` |
| recipes | `\t$(CC) -o $@ $^` (tab-prefixed) |
| a recipe on the rule line | `all: dep ; @echo $<` (the text after `;` is the first recipe line; a `#` in it is not a comment) |
| empty recipe | `t: ;` (runs nothing; as a goal, `'t' is up to date.`) |
| variables (recursive) | `CFLAGS = -O2` |
| variables (immediate) | `CC := cc` |
| variables (conditional) | `DEBUG ?= 0` |
| variables (append) | `CFLAGS += -g` |
| variable reference | `$(CFLAGS)`, `${CFLAGS}` |
| automatic variables | `$@` `$<` `$^` `$?` |
| `$$` literal dollar | `$$HOME` → `$HOME` for the shell |
| `#` comments | `# this is a comment` |
| continuation lines | `VAR = foo \`<newline>` bar` |
| `.PHONY` | `.PHONY: all clean` |
| `@` silent | `\t@echo hello` |
| `-` ignore errors | `\t-rm -f *.o` |
| computed names | `$($(x))` |
| substitution references | `$(SRC:.c=.o)` |
| text functions | `$(subst a,b,$(X))` `$(patsubst %.c,%.o,$(SRC))` `$(strip $(X))` `$(findstring a,$(X))` `$(filter %.c,$(SRC))` `$(filter-out %.h,$(SRC))` `$(sort $(X))` `$(word 2,$(X))` `$(wordlist 2,3,$(X))` `$(words $(X))` `$(firstword $(X))` `$(lastword $(X))` |
| file-name functions | `$(dir $(X))` `$(notdir $(X))` `$(suffix $(X))` `$(basename $(X))` `$(addsuffix .o,$(X))` `$(addprefix src/,$(X))` `$(join $(A),$(B))` `$(wildcard *.c)` `$(realpath $(X))` `$(abspath $(X))` |
| conditional functions | `$(if $(C),yes,no)` `$(or $(A),$(B))` `$(and $(A),$(B))` `$(intcmp $(A),$(B),lt,eq,gt)` — only the chosen branch is expanded |
| `foreach`, `call`, `value`, `origin`, `flavor` | `$(foreach i,$(LIST),$(i).o)` `$(call fn,a,b)` (`$(1)`, `$(2)`, `$(0)` bound for the call) `$(value V)` (the unexpanded text) `$(origin V)` (`undefined`, `default`, `environment`, `environment override`, `file`, `command line`, `override`, `automatic`) `$(flavor V)` (`undefined`, `recursive`, `simple`) |
| `info`, `warning`, `error`, `MAKECMDGOALS` | `$(info text)` (stdout, expands to nothing) `$(warning text)` (`FILE:LINE: text` on stderr) `$(error text)` (`FILE:LINE: *** text.  Stop.`, exit 2; a recipe's lines are all expanded before the first runs, as gmake does) `$(MAKECMDGOALS)` (the command-line goals) |
| `shell`, `!=` | `$(shell cmd)` (`/bin/sh -c`, standard output with the trailing newlines dropped and the others turned into spaces) `V != cmd` (run once when read, stored as a recursive variable; a failing command still assigns) |
| `.SHELLSTATUS` | `X := $(shell exit 3)` then `$(.SHELLSTATUS)` is `3`, origin `override`, flavor `simple`; a recursive shell's status is visible later in the same expansion |
| `let` | `$(let a b rest,1 2 3 4,$(a)-$(b)-$(rest))` is `1-2-3 4`; bindings are local, automatic-origin and simple-flavor; the last name keeps the remaining text |
| `file` | `$(file >out.txt,hello)` overwrites, `>>` appends, `<` reads and drops only the final newline; missing reads and writes return empty; omitted text creates zero bytes, explicit text gains a newline only if needed |
| `eval` | `$(foreach p,$(PROGS),$(eval $(call T,$(p))))` reads the text as makefile lines at once: a variable it sets is seen by the next reference, its rules join in reading order, every line is reported at the eval's own line; in a recipe it sets variables for the later lines and targets but defines no rule |
| `include` / `-include` / `sinclude` | `include $(DIR)/x.mk` |
| `-I DIR` | search DIR for included makefiles |
| `ifeq` / `ifneq` / `ifdef` / `ifndef` / `else` / `endif` | `ifeq ($(A),$(B))` |
| `define` / `endef` | `define NAME` … `endef` |
| `undefine` | `undefine NAME` |
| `override NAME = v` | `override A = 2` (wins over CLI) |
| `export NAME` / `export NAME = v` | `export Y = 2` |
| `export` (bare) | every variable exported |
| `unexport NAME` | `unexport HOME` |
| `-e` | environment variables override Makefile assignments |

### Refused (exit 2, one line on stderr naming the construct)

| construct | message |
|---|---|
| pattern rules | `pattern rules are not supported` |
| `.SUFFIXES` | `.SUFFIXES is not supported` |
| `|` order-only prerequisites | `order-only prerequisites are not supported` |
| `::` double-colon rules | `double-colon rules are not supported` |

## Out-of-date rule

A target is out of date when:

1. It does not exist, or
2. Any prerequisite is newer (mtime strictly greater), or
3. Any prerequisite was rebuilt in this run, or
4. The target is `.PHONY`

A prerequisite with no rule that does not exist is an error:
`mk: *** No rule to make target 'missing_file', needed by 'result'.  Stop.`

## `-j` and `-k` semantics

- `-j N` runs up to N recipes simultaneously. A target starts only after all its
  prerequisites are done. The order of starts is the discovery order from a depth-first
  walk, so `-j 1` produces exactly GNU make's serial order.
- `-k` keeps building targets that do not depend on a failed one. The exit status is 2.

## Exit codes

- `0` — up to date or built successfully
- `2` — any error (GNU's convention)

## Known differences from GNU make

- Usage errors print `mk`'s own option list, not GNU make's (`gmake -x` prints 50 lines
  of options; `mk -x` prints its usage; the first line agrees and the E1 row checks it)
- `$(MAKE)` expands to the literal `mk` (gmake prints its absolute path); this changes
  when mk reads its own path with `env_arg0()` (in wolf since 0.2.36)
- `$(eval …)` in an `ifeq`/`ifdef` condition, or in a rule's target or prerequisite list,
  runs on a copy of the variables (mk expands rule lines after reading, gmake while
  reading), so what it defines does not reach the makefile

### Divergences from gmake 4.4.1

| construct | divergence |
|---|---|
| `$(intcmp -5,-3,…)` | gmake 4.4.1 orders two negatives by magnitude (`gt`); mk orders them as numbers (`lt`), as the manual says (R-mk-1) |

## Tests

```
wolf build main.lu -o mk
wolf test .              # 88 unit tests
./test.sh                # 335 rows against GNU make
wolf fmt --check *.lu
```

`test.sh` runs each corpus directory in a fresh `mktemp -d` copy, comparing `mk` against
GNU `gmake` on the same Makefile. A row passes when the two tools agree on the observable
behaviour (output, exit status and the files written). The oracle is GNU make 4.4.1 beside it.

Each corpus directory but `refuse` carries a `rows` file (one row per line; the first word
is the row name, the rest are the arguments). A name starting with `again` compares the
second run of each tool. A copy is cleaned to the directory's git-tracked files. The
harness finds every `tests/corpus/*/rows` and feeds them into the matrix.

The 335 rows cover 62 directories. 295 are R rows, every line of 60 `rows` files compared
by `same_as_make`; the other 40 are fixed kinds: N1 (dry-run output), B1 (files after
build) and B2 (second run) on 8 directories each, B3 (build from a subset) on 5, F1
(failure with `-k`), M1 (missing target), C1 (cycle), J1 (wide build), J2 (diamond with
`-j`), R1 (refusals) and RJ (refusals under `-j`) on `refuse`, P1 (print database), E1
(usage errors), VR (`--version` names the `VERSION` file and the wolf the gates run with)
and D1 (the `divergences` row: mk's answer, not gmake's).

## Measured numbers

| test | `-j 1` | `-j 8` |
|---|---|---|
| `wide` (40 targets, `sleep 0.2` each) | 8.4 s | 1.1 s |

Machine: Apple M5 Pro, macOS, wolf 0.2.34. Date: 2026-10-23.

## Files

| file | purpose |
|---|---|
| `main.lu` | CLI parsing, entry point, `-p` delegation |
| `parse.lu` | Makefile parser: lines, continuations, assignments, rules, recipes |
| `vars.lu` | Variable table, setters, `var_value` (checks environment) |
| `expand.lu` | Recursive-descent variable expander with balanced references |
| `graph.lu` | Dependency graph, DFS, cycle detection, out-of-date decision |
| `run.lu` | Scheduler: serial and parallel execution, `-n`/`-s`/`-k` |
| `mk_test.lu` | Unit tests for the parser and variable flavours |
| `test.sh` | Corpus tests against GNU make (335 rows) |
| `SPEC.md` | The original specification (the prompt that built this) |
| `CHANGELOG.md` | Version history |
| `README.md` | this file |
| `LICENSE` | Apache License 2.0 |
| `.gitignore` | Ignore build artifacts and corpus outputs |
| `prompts/` | The prompts that built mk |
| `tests/corpus/` | Self-contained Makefiles with source files |
