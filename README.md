# mk

> Written by wollf-v7sf3 under the OpenCode harness with human review.
> The test matrix (36 rows against GNU make) is the reason to trust it.

A `make` for the plain Makefile subset — targets, prerequisites, recipes, variables,
automatic variables, mtime-driven rebuilds, `-n`, `-k`, and `-j N` — refusing everything
else by name. If your Makefile has no pattern rules, no `include`, no `ifeq`, no functions,
`mk` builds it identically to GNU make.

## Install

```
wolf build main.lu -o mk
```

Requires wolf (https://wolf-lang.org) and a POSIX shell.

## Usage

```
mk [-f FILE] [-C DIR] [-n] [-s] [-k] [-j [N]] [-p] [NAME=VALUE]... [GOAL]...
mk --help
```

- `-f FILE` — read FILE as the Makefile (default: `Makefile`)
- `-C DIR` — change to DIR before doing anything
- `-n` — print recipes without running them
- `-s` — silent mode (do not print recipes)
- `-k` — keep going after a failure
- `-j N` — allow up to N jobs simultaneously
- `-p` — print the parsed database (variables sorted, rules in file order)
- `NAME=VALUE` — set a variable from the command line

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

### Refused (exit 2, one line on stderr naming the construct)

| construct | message |
|---|---|
| pattern rules | `pattern rules are not supported` |
| `include` / `-include` | `include is not supported` |
| `ifeq` / `ifdef` / `ifndef` / `else` / `endif` | `conditional directives are not supported` |
| `define` / `endef` | `define is not supported` |
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
`mk: *** No rule to make target 'x', needed by 'y'.  Stop.`

## `-j` and `-k` semantics

- `-j N` runs up to N recipes simultaneously. A target starts only after all its
  prerequisites are done. The order of starts is the discovery order from a depth-first
  walk, so `-j 1` produces exactly GNU make's serial order.
- `-k` keeps building targets that do not depend on a failed one. The exit status is 2.

## Exit codes

- `0` — up to date or built successfully
- `2` — any error (GNU's convention)

## Tests

```
wolf build main.lu -o mk
wolf test .              # 42 unit tests
./test.sh                # 36 corpus rows against GNU make
wolf fmt --check *.lu
```

`test.sh` runs each corpus directory in a fresh `mktemp -d` copy, comparing `mk` against
GNU `make` on the same Makefile. A row passes when the two tools agree on the observable
behaviour (output, exit code, or file system state). The oracle is GNU make beside it.

## Measured numbers

| test | `-j 1` | `-j 8` |
|---|---|---|
| `wide` (40 targets, `sleep 0.2` each) | 8.4 s | 1.1 s |

Machine: Apple M5 Pro, macOS, wolf 0.1.0. Date: 2026-10-23.

## Files

| file | purpose |
|---|---|
| `main.lu` | CLI parsing, entry point, `-p` delegation |
| `parse.lu` | Makefile parser: lines, continuations, assignments, rules, recipes |
| `vars.lu` | Variable table, expansion, automatic variables |
| `graph.lu` | Dependency graph, DFS, cycle detection, out-of-date decision |
| `run.lu` | Scheduler: serial and parallel execution, `-n`/`-s`/`-k` |
| `mk_test.lu` | Unit tests for the parser and variable flavours |
| `test.sh` | Corpus tests against GNU make (36 rows) |
| `SPEC.md` | The original specification (the prompt that built this) |
| `REVIEW.md` | Cross-file review notes |
| `CHANGELOG.md` | Version history |
| `LICENSE` | MIT (the licence wolffe-lang's other tools use) |
| `tests/corpus/` | Self-contained Makefiles with source files |
