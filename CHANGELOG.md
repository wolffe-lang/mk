# Changelog

## Unreleased

### Added

- Recursive-descent variable expander (`expand.lu`) with balanced references:
  `$(A$(B))` expands the inside first, so computed names work
- `${NAME}` syntax (brace-delimited references)
- Substitution references: `$(VAR:.c=.o)` replaces trailing `.c` with `.o` on every word
- Pattern substitution: `$(VAR:%.c=%.o)` where `%` matches any run of characters
- Cycle detection: a variable referencing itself recursively returns empty
- `var_value` checks the environment for variables not in the table
- Environment variables are looked up when a Makefile variable is undefined (`FOO=bar mk` sees `$(FOO)`)
- `tests/corpus/expand/` — exercises all expansion forms
- `tests/corpus/expand-bad/` — error cases (unterminated references)
- 5 new unit tests: computed names, nested references, substitution, pattern substitution, cycle detection

### Changed

- `expand` moved from `vars.lu` to `expand.lu` with a new error row `{unterminated, cycle}`
- `vars.lu` now imports from `expand.lu` and delegates expansion
- `parse.lu`, `run.lu`, `graph.lu` handle the new `expand` error row
- README updated with new accepted constructs and test counts (47 unit tests, 102 corpus rows)

## 0.2.1 (2026-10-23)

### Fixed

- Recipe continuations: a continued line keeps its newline and loses one tab;
  the error line number is the first recipe line plus the logical index
- A line that is not blank, not a comment, not a recipe line, not an assignment,
  not a rule and not a refusal is a "missing separator" error (exit 2)
- A `-f` file that cannot be read prints the two gmake lines (exit 2)
- `-C` prints `Leaving` on every exit, including parse errors and missing files

## 0.2.0 (2026-10-23)

### Changed

- The oracle of record is GNU make 4.4.1 (was 3.81); messages quote `'name'` and recipe
  errors carry `Makefile:line`
- Rows are files: each corpus directory carries a `rows` file (one row per line, first
  word the name, rest the arguments; `again…` compares the second run; copies cleaned to
  tracked files; the harness finds every `tests/corpus/*/rows`)

## 0.1.0 (2026-10-23)

Initial release. A `make` for the plain Makefile subset.

### Supported

- Targets, prerequisites, recipes (tab-prefixed)
- Variables: `=` (recursive), `:=` (immediate), `?=` (conditional), `+=` (append)
- Variable reference: `$(NAME)`, `${NAME}`
- Automatic variables: `$@`, `$<`, `$^`, `$?`
- `$$` → literal `$` for the shell
- `#` comments, continuation lines (`\`)
- `.PHONY` targets
- `@` (silent), `-` (ignore errors) in recipes
- `-n` (dry run), `-s` (silent), `-k` (keep going), `-j N` (parallel)
- `-f FILE`, `-C DIR`, `NAME=VALUE` overrides
- `-p` (print parsed database)
- mtime-driven rebuilds
- Cycle detection (drops back-edges)

### Not supported (refused by name, exit 2)

- Pattern rules (`%.o: %.c`)
- `include` / `-include`
- `ifeq` / `ifdef` / `ifndef` / `else` / `endif`
- `define` / `endef`
- `.SUFFIXES`
- `|` order-only prerequisites
- `::` double-colon rules
- `$(wildcard …)`, `$(patsubst …)`, `$(shell …)`

### Fixed

- `-k -j` exit status (was 0, now 2)
- command-line variables while parsing (were lost)
- ``Nothing to be done`` (was missing for a goal with no recipe)
- `-s` and `-k` messages, serial and `-j` (were inconsistent)
- `-n -j` runs nothing (was running recipes)
- usage errors name the problem (were silent)
- `-j` without a number sets no limit (ran one job at a time)
- the official licence (was a retyping)
- `--version` names the wolf it was built with
