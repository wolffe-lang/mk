# Changelog

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
- ``Nothing to be done`` (was printed for every up-to-date target)
- `-s` and `-k` messages, serial and `-j` (were inconsistent)
- `-n -j` runs nothing (was running recipes)
- usage errors name the problem (were silent)
- `-j` without a number sets no limit (was an error)
- the official licence (was a retyping)
- `--version` names the wolf it was built with
