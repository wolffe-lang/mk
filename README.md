# mk

> **Built by wollf.** This program was written by [wollf-v7sf3](https://huggingface.co/wolffe-lang/wollf-v7sf3),
> a 27B model trained to write wolf, driven through opencode by the prompts in `prompts/`, with a human
> reviewer judging each phase and writing the next. Every claim below is pasted from the binary; the test
> script is the reason to trust it.

A `make` for the plain Makefile subset — targets, prerequisites, recipes, variables,
automatic variables, mtime-driven rebuilds, `-n`, `-k`, and `-j N` — refusing everything
else by name. If your Makefile has no pattern rules, no `include`, no `ifeq`, no functions,
`mk` builds it as GNU make does on the corpus below. `test.sh` compares `mk` against GNU make 4.4.1:
- on 12 corpus directories: the first and the second run, serially and with `-j 2`, and `-n -j 2`;
- on their own directories: `-k`, `-s` and a command-line variable;
- each comparing the output, the exit status and the files written.

The refusals and usage errors are checked by name.

## Install

```
wolf build main.lu -o mk
```

Requires wolf 0.2.34 (https://github.com/wolffe-lang/wolf-lang) and a POSIX shell.

## Usage

```
Usage: mk [-f FILE] [-C DIR] [-n] [-s] [-k] [-j [N]] [-p] [-I DIR] [NAME=VALUE]... [GOAL]...
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
  --version  print the version and exit
  NAME=VALUE set a variable from the command line
```

## The subset

### Accepted

| construct | example |
|---|---|
| rules | `all: prog` |
| recipes | `\t$(CC) -o $@ $^` (tab-prefixed) |
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
| `$(wildcard …)` / `$(patsubst …)` / `$(shell …)` | `functions are not supported` |

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
  when wolf 0.2.36's `env_arg0()` lands

## Tests

```
wolf build main.lu -o mk
wolf test .              # 50 unit tests
./test.sh                # 155 corpus rows against GNU make
wolf fmt --check *.lu
```

`test.sh` runs each corpus directory in a fresh `mktemp -d` copy, comparing `mk` against
GNU `gmake` on the same Makefile. A row passes when the two tools agree on the observable
behaviour (output, exit status and the files written). The oracle is GNU make 4.4.1 beside it.

Each corpus directory carries a `rows` file (one row per line; the first word is the row
name, the rest are the arguments). A name starting with `again` compares the second run
of each tool. A copy is cleaned to the directory's git-tracked files. The harness finds
every `tests/corpus/*/rows` and feeds them into the matrix.

The 123 rows cover 15 directories across 19 test kinds: N1 (dry-run output), B1 (files
after build), B2 (second run), B3 (build from a subset), F1 (failure with `-k`), M1
(missing target), C1 (cycle), J1 (wide build), J2 (diamond with `-j`), R1 (refusals),
P1 (print database), J3 (parallel), U1/U2 (second-run comparison), D1 (dry-run with
`-j`), K1 (keep-going), S1 (silent), V1 (command-line variables), RJ (refusals under
`-j`), E1 (usage errors), and R (corpus rows with `same_as_make`).

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
| `test.sh` | Corpus tests against GNU make (100 rows) |
| `SPEC.md` | The original specification (the prompt that built this) |
| `CHANGELOG.md` | Version history |
| `README.md` | this file |
| `LICENSE` | Apache License 2.0 |
| `.gitignore` | Ignore build artifacts and corpus outputs |
| `prompts/` | The prompts that built mk |
| `tests/corpus/` | Self-contained Makefiles with source files |
