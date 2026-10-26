# Changelog

## 0.3.0 (2026-10-24)

### Added

- Special variables: `MAKE` (the program name), `CURDIR` (the working directory
  after `-C`), `MAKEFILE_LIST` (already present), `MAKEFLAGS` (the flags given,
  in gmake's spelling: `k`, `n`, `s`, and `-jN`), `MAKELEVEL` (`0`),
  `.DEFAULT_GOAL` (the first target in the file)
- `tests/corpus/special/` — exercises the special variables
- The test harness normalizes `gmake`/`mk` to `MAKE` and strips gmake's
  `--jobserver-auth=…` from `MAKEFLAGS` so the comparison is fair

### Changed

- `main.lu` sets the special variables after parsing the CLI flags
- `test.sh` normalizes the MAKE word and strips the jobserver auth in `normalize`
- `test.sh` replaces temp directory paths in file contents for `same_as_make`

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
- `parse_makefile` now takes `mut v: Vars` and `cli_names` and applies assignments as they're read,
  giving correct order-dependent behavior (`A := $(B)` before `B = 1` makes `A` empty)
- `+=` keeps the flavour: append to `:=` expands the value, append to `=` stores text
- `build_vars` is deleted from `main.lu`
- `include`, `-include`, and `sinclude` are accepted: names are expanded, globs are expanded,
  files are read in order with the same `Vars` and `Database`
- `-I DIR` is a new flag: search DIR for included makefiles
- `MAKEFILE_LIST` is a space-separated list of every makefile read so far, in order
- `ifeq`, `ifneq`, `ifdef`, `ifndef`, `else`, `endif` are accepted: a conditional stack tracks
  which lines are live; errors include missing `endif`, extraneous `else`, two `else` in one
  conditional, and invalid syntax in `ifeq`/`ifneq`
- `define NAME` … `endef` is accepted: the body, verbatim with its newlines, becomes NAME's value;
  `define NAME =`, `:=`, `+=`, `?=` set the flavour; nested `define` inside a body counts
- `undefine NAME` removes the variable (`ifdef` is then false); `override define` and `override undefine`
  are accepted (the `override` is stripped; P1.6 gives it its meaning)
- Recipe lines split on bare newlines: a newline ends a recipe line unless a backslash precedes it
  (that pair is a continuation the shell sees); a `define` body's bare newlines become separate lines
- `override NAME = v` wins over a command-line `NAME=…`; an ordinary assignment to a CLI name stays a no-op
- `export NAME`, `export NAME = v`, bare `export` (every variable), `unexport NAME`
- `-e` flag: environment variables override Makefile assignments
- `export_environment` sets exactly the variables GNU exports: environment-origin ones,
  `export`ed ones, everything under bare `export`; an `unexport`ed name is removed
- `tests/corpus/export/` — exercises export, unexport, override, and `-e`
- `tests/corpus/recursion/` — exercises recursive make invocations with `$(MAKE)`
- `$(MAKE)` in a recipe line is run under `-n` (dry-run mode), like `+` prefix lines,
  so recursive make invocations work correctly in dry-run mode
- Sub-makes inherit flags from `MAKEFLAGS` in the environment, matching GNU make's behavior
- `MAKELEVEL` is read from the environment and incremented for sub-makes
- The `mk[N]:` prefix is used for error messages in sub-makes
- README updated with new accepted constructs and test counts (50 unit tests, 155 corpus rows)

### Fixed

- `include` of an absent file that has a rule now builds it and restarts (like gmake does)
- Conditionals five or more deep now work (the `endif` was incorrectly popping all entries)
- `else ifeq` followed by `else` now works correctly
- `unexport` then `export` re-exports (the last directive wins)
- `-n` with `-s` still echoes (silent never silences the dry run's echo)
- A BOM (U+FEFF) at the start of a file is skipped
- README *Known differences* updated to reflect the one real difference (`$(MAKE)` expands to literal `mk`)

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
