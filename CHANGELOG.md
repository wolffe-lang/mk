# Changelog

## Unreleased

### Added

- A recipe after `;` on the rule line (`all: dep ; @echo $<`): the text after the `;` is the rule's first recipe line, its leading whitespace dropped; a `#` in it is recipe text, not a comment, and a backslash-newline in it stays for the shell. A `;` in a value (`X = a ; b`) or in a comment (`t: p # c ; d`) is not a recipe
- An empty recipe (`t: ;`, or recipe lines that expand to nothing) runs nothing and prints nothing, and the target counts as remade

### Fixed

- A `;` on a rule line was a prerequisite named `;` (`No rule to make target ';'`); a `|`, `::` or `%` in the recipe after it was refused as an order-only prerequisite, a double-colon rule or a pattern rule; `t:;X=1` was an assignment to a variable named `t:;X`
- A goal whose update started no command says what gmake says, under `-n` and `-j` too: `'t' is up to date.` for an empty recipe (mk printed an empty line), `Nothing to be done for 't'.` for a target with no recipe, a phony one or a file with no rule (mk said nothing for a file), and the same again for a goal named twice (mk said `is up to date` even for a target with no recipe, and under `-s`)
- A prerequisite that does not exist once its rule has run is newer than its target and is in `$?`, as gmake reads it: `out: FORCE` with `FORCE:` (no recipe, no prerequisites) remakes `out` every time; mk said `'out' is up to date.`, and under `-j` a target with no recipe left its dependents unmade
- A recipe line inside a conditional (`all:`, `ifeq (a,a)`, `\t@echo yes`, `endif`) is the rule's; mk dropped every recipe line after the directive. A tab line outside a rule is read as gmake reads it: a directive or an assignment as a makefile line, a blank or comment one skipped, any other `*** recipe commences before first target.  Stop.` (mk ignored them, and `\tX = 1` set nothing)
- A rule or an assignment continued onto a line that starts with a tab (`all: a \` then `\tb`) is one line; mk took the tab line for a recipe line, and `X = a \` then `\tb` gave `a`
- Whitespace before, between and after the recipe prefixes is skipped, as gmake does: `\t  @echo x` is silent, `\t@ - exit 2` is ignored, `\t   echo x` echoes `echo x`; mk passed `@echo` to the shell

## 0.4.0 (2026-10-30)

### Added

- The text functions: `subst`, `patsubst`, `strip`, `findstring`, `filter`, `filter-out`, `sort`, `word`, `wordlist`,
  `words`, `firstword`, `lastword`, with gmake's argument splitting (commas at depth zero, the last argument keeping the
  rest) and gmake's fatal lines for a bad `word`/`wordlist` count (`FILE:LINE: *** … .  Stop.`, exit 2)
- A `%` inside a function on an assignment or rule line is no longer taken for a pattern rule
- The file-name functions: `dir`, `notdir`, `suffix`, `basename`, `addsuffix`, `addprefix`, `join`, `wildcard` (sorted,
  each match with its pattern's directory prefix; a line with `$(wildcard …)` is no longer refused at read time),
  `realpath` (a missing file is dropped), `abspath` (the file need not exist)
- The conditional functions `if`, `or`, `and` and `intcmp`, expanding only the branch they choose (an `$(error …)` in
  the other branch never fires), with gmake's fatal lines for a non-numeric or missing `intcmp` argument
- `intcmp` orders negatives as numbers; gmake 4.4.1's both-negative answer is recorded as a divergence (README)
- `foreach`, `call` (bound in a copy of the table, so nesting restores nothing), `value`, `origin`, `flavor`
- `info`, `warning`, `error` (a top-level function line is expanded when read; a recipe's lines are all expanded before the first runs), and `MAKECMDGOALS`
- `shell` and the `!=` assignment (`$(flavor)` of a `!=` variable is `recursive`, as gmake's)
- `eval` reads its text as makefile lines at once: a variable it sets is seen by the next reference (so `$(foreach x,a b,$(eval L := $(L) $(x)))` accumulates), its rules and `.PHONY` join the database in reading order, every line it reads is reported at the eval's own line, and in a recipe it sets variables for the later lines and targets but defines no rule (`prerequisites cannot be defined in recipes`); `foreach`, `call` and `let` keep what an `eval` inside them did
- `let` binds expanded words locally (the last name keeps the remaining text), with automatic origin and simple flavor
- `file` reads, overwrites and appends at expansion time, preserving text commas and spaces; writes return empty, absent reads return empty, omitted text creates an empty file, and explicit text receives a final newline only when needed
- `.SHELLSTATUS` records the last `shell` or `!=` exit status, with override origin and simple flavor; recursive and lazy calls expose it later in the same expansion, and a signal reports 128 plus its number
- an unclosed `$( ` or `${` stops as gmake does — `unterminated call to function 'NAME': missing ')'` for a function, `unterminated variable reference` otherwise — at read time through `:=`, `!=` and a top-level call, and before a recipe's first line runs

### Changed

- No function is refused: the `functions are not supported` refusal and the name list behind it (`is_gmake_function`) are deleted
- `mk --version` prints `mk 0.4.0 (tested with wolf 0.2.36)`: wolf cannot embed the compiler's own version, so the line names the wolf the release was tested with; test.sh's VR row checks it, and the `VERSION` file, against the wolf the gates run with (at 0.3.1 they said 0.2.34 and 0.3.0)

### Fixed

- A pattern without `%` in `patsubst` and substitution references matches a whole word
- A `define` body keeps its recipe lines, its directives and a nested `define … endef` as text, and a `define` in a branch not taken is dropped
- An assignment's operator is the one at its first `=` (`L = $(eval X := 1)` is a recursive `L`)
- A variable in a rule's target list names each of its words as a target (`$(PROGRAMS):`), and none when it is empty
- An unclosed call with nothing after the function's name (`Y := $(word` at the end of a line) names the function, as gmake does
- A fatal error in an assignment (`Y := $(error HELLO)`, with `export` or `override`, in `!=`, a bad `word` index, an unclosed call) stops the reader at once with gmake's `FILE:LINE: *** … .  Stop.`, an included file's too; an error inside a `-include`d or `sinclude`d file is not forgiven, only a missing file is
- `define NAME !=` runs its body as one shell command line (gmake joins the body's lines with spaces) and stores the output as a recursive variable, setting `.SHELLSTATUS`; the variable was named `NAME !` and stayed empty

## 0.3.1 (2026-10-26)

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
- `include` of an absent file that has no rule reports the error (no "No such file or directory" when a rule can make it)
- A goal given twice (`make plain plain`) prints `mk: 'plain' is up to date.` for the repeat, serial and `-j`
- `-k -j N`: no "not remade because of errors" line for a goal with no rule or a failed recipe; only a failed prerequisite earns it, as gmake
- `include` names only the first missing file; `-f` names every missing file before stopping
- A missing include whose rule cannot succeed is named before the "No rule" line (the `include-stale-remake` probe)
- A recipe line that is only a tab runs nothing; a final backslash with no newline keeps gmake's empty line
- `cond-deep`: eight nested `ifeq` as a guard row
- Conditionals five or more deep now work (the `endif` was incorrectly popping all entries)
- `else ifeq` followed by `else` now works correctly
- `unexport` then `export` re-exports (the last directive wins)
- `-n` with `-s` still echoes (silent never silences the dry run's echo)
- `-n` under `-j` echoes (dry run prints recipe lines even with `-j`)
- Tab-only recipe line prints nothing; trailing backslash at end of file keeps gmake's empty line
- A BOM (U+FEFF) at the start of a file is skipped
- README *Known differences* updated to reflect the one real difference (`$(MAKE)` expands to literal `mk`)

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
