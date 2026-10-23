# Track 01 — the directives (0.3.0)

Do `prompts/PARITY/campaign.md`'s "Start of every session" first, `00-the-oracle/judge.md` included. Where the code
stands after track 00: the oracle is `gmake` 4.4.1, rows are `rows` files, messages are 4.4.1's. The
Makefile is still read in two passes — `parse_makefile` collects `assignments`, `rules` and `phonies` into a
`Database`, then `build_vars` makes the `Vars` — and `expand` finds a reference's end with the first `)`.
This track makes the reader one-pass, the expander real, and lands every directive: `include`, the
conditionals, `define`, `override`/`export`, and the variables GNU make sets itself. Each refusal line in
`check_refusal` (parse.lu) is deleted in the prompt that lands its construct.

Every expected answer below was pasted from `gmake` 4.4.1. Where a prompt says "paste from gmake", run the
command and copy the bytes; never type a message from memory.

### P1.1 — the expander

`expand` in `vars.lu` stops a `$(…)` at the first `)`, so `$(A$(B))` and `$(foo bar)` break. Rewrite it as
a small recursive-descent expander in a new file `expand.lu` (`vars.lu` keeps `Vars`, the setters and
`var_value`; `expand` moves and `vars.lu`'s old body is deleted, not kept beside it):

- `$$` → `$`. `$x` (one character) → the variable `x`. `$(NAME)` and `${NAME}` with **balanced** parens or
  braces: scan to the matching close, counting depth, and expand the inside **first** (so `$(A$(B))` reads
  variable `AB`'s value when `B` is `B`… i.e. computed names). A reference whose inside, after expansion,
  contains whitespace is a function call — not yet; for now it expands to empty, and P2 of the next track
  takes the hook: write `fn call_function(v: Vars, name: str, args: str) -> str` returning `""` and route
  there when the inside has a space.
- Substitution references: `$(VAR:.c=.o)` replaces a trailing `.c` with `.o` on every word of VAR's value;
  `$(VAR:%.c=%.o)` is the pattern form (`%` matches any run of characters, the same `%` on the right).
  `gmake` witnesses, paste them: `A = a.c b.c` then `@echo $(A:.c=.o)` and `$(A:%.c=%.o)` → `a.o b.o`.
- An unterminated reference is an error at parse time, with the Makefile's name and line:
  `Makefile:1: *** unterminated variable reference.  Stop.` exit 2. `expand` needs to fail, so its signature
  becomes `expand(v: Vars, s: str) -> str ! {unterminated}` and the callers propagate (parse-time ones print
  the message with `file:line`; recipe-time ones — `expand_auto`'s callers in `run.lu` — print it with the
  recipe line's number).
- Recursive variables expand on every use; an immediate one was expanded when set (unchanged). A variable
  referencing itself recursively is GNU's error, paste it: `A = $(A)` with `all: ; @echo $(A)` →
  `Makefile:1: *** Recursive variable 'A' references itself (eventually).  Stop.` — detect a cycle with a
  depth or a visiting set, never by crashing.

Rows (commit red first as `rows: the expander (red)`): a directory `expand/` with a `Makefile` exercising
nested references, computed names, `${}` inside `$()`, both substitution forms, `$$` in a recipe; and
`expand-bad/` with `rows` lines `unterm -f unterm.mk` and `self -f self.mk` (two small `.mk` files; the
Makefile proper may be empty — no, give it `all: ;` so the directory still builds). Unit tests in `mk_test.lu`
for each form (at least eight). Commit: `expand: balanced references, computed names, substitution references`.
README *Accepted* gains `computed names | $($(x))` and `substitution references | $(SRC:.c=.o)`. CHANGELOG
`### Added`.

**Verify:** `wolf test .` count; `./test.sh | tail -1`; `./mk -f tests/corpus/expand/Makefile` pasted beside
`gmake -f tests/corpus/expand/Makefile`. Stop.

### P1.2 — one pass

GNU make reads a Makefile once, top to bottom, and a line sees every assignment above it: `A := $(B)` before
`B = 1` makes `A` empty, `C = $(B)` after makes `C` `1` (`gmake` prints `[][1]` for `@echo [$(A)][$(C)]`).
Conditionals and `include` need that. Fold `build_vars` into the parser:

- `parse_makefile(text, mut v: Vars, cli_names)` applies each assignment to `v` as it is read (`set_var`,
  respecting `cli_names` as `build_vars` did); `Database.assignments` stays for `-p`. `:=` expands at that
  moment with the `v` so far; `=` stores the text; `?=` sets only if unset; `+=` keeps the flavour: an append
  to a recursive variable appends text, to an immediate one appends the expanded text.
- The environment: before reading, every environment variable becomes a variable of origin `environment`
  (`-e` later makes them win; for now Makefile assignments override them, as today).
- `main.lu` builds `v` first, passes it in, and `build_vars` is deleted.

Rows: `order/` with the `[][1]` Makefile and `rows` `build`; a second rule showing `+=` on both flavours
(paste gmake's output). Commit red, then `read the Makefile in one pass`. CHANGELOG `### Changed`.

**Verify:** `./test.sh | tail -1`; the `order` row's `ok` line; `git diff --stat HEAD~2 HEAD`. Stop.

### P1.3 — include

- `include a.mk b.mk`, `-include`, `sinclude`: read each file at that point, in order, with the same `Vars`
  and `Database` (rules accumulate; the default goal stays the first target seen anywhere). Names are
  expanded first (`include $(DIR)/x.mk`) and may hold `*`/`?` globs: write `fn glob(pattern: str) -> List[str]`
  in a new `glob.lu` (sorted results; `std.fs` listing; `$(wildcard)` next track reuses it).
- Search: the name as given, then each `-I DIR` in order (`-I` is a new flag: `-I DIR` and `-IDIR`, repeatable;
  `--help` gains `  -I DIR     search DIR for included makefiles`; re-paste the README usage block).
- A missing file: paste from gmake, two lines then exit 2:
  ```
  Makefile:1: nope.mk: No such file or directory
  gmake: *** No rule to make target 'nope.mk'.  Stop.
  ```
  (4.4 tries to *make* the missing makefile; `mk` has no rule for it either, so the second line is the
  ordinary no-rule line with no `needed by`.) `-include`/`sinclude` missing: silent. A Makefile that is itself
  missing (`-f nope`): `mk: nope: No such file or directory` then the same no-rule line (paste).
- `MAKEFILE_LIST`: a space-separated list of every makefile read so far, in order, appended as each is read
  (so a line in `a.mk` sees `Makefile a.mk`).
- Delete the `include` refusal from `check_refusal`.

Rows: `include/` (a Makefile including two `.mk` files, one via a glob, one setting a variable the Makefile
echoes, `MAKEFILE_LIST` echoed), `include-missing/` (`rows`: `hard`, `soft -f soft.mk`, `nofile -f nope`).
Commit red, then `include, -include and sinclude`, `-I DIR`. README: `include` moves from *Refused* to
*Accepted*; usage block re-pasted. CHANGELOG `### Added`.

**Verify:** the three `include-missing` rows `ok`; `./mk -f nope; echo $?`; `./test.sh | tail -1`. Stop.

### P1.4 — conditionals

`ifeq`, `ifneq`, `ifdef`, `ifndef`, `else`, `else ifeq …` (a chain), `endif`, nested to any depth, anywhere
a line can be — including between recipe lines (a conditional line in a recipe is a directive, not a recipe
line, when it starts without a tab; with a tab it is a recipe line passed to the shell). Keep a stack in
the reader: each entry says whether lines are live and whether an `else` has been seen.

- `ifeq (a,b)`, `ifeq "a" "b"`, `ifeq 'a' 'b'`, and mixed quotes; both sides expanded, then compared after
  stripping leading and trailing whitespace. `ifdef NAME`: true when the variable (the *name*, expanded
  once if it contains `$`) has a non-empty value; `ifndef` the opposite.
- Errors, pasted from gmake (file and line of the offending line; `Stop.`, exit 2):
  ```
  Makefile:4: *** missing 'endif'.  Stop.                 ← at EOF, the line is the last line + 1
  Makefile:1: *** extraneous 'else'.  Stop.
  Makefile:3: *** only one 'else' per conditional.  Stop.
  Makefile:1: *** invalid syntax in conditional.  Stop.   ← ifeq a b (no parens or quotes)
  ```
- Delete the conditional refusals.

Rows: `cond/` (every form, nesting, a chain, a conditional inside a recipe, an `ifdef` of an empty variable
and of an unset one) and `cond-bad/` (`rows` with the four errors, each `-f` its own `.mk`). Commit red, then
`conditionals: ifeq, ifneq, ifdef, ifndef, else, endif`. README *Accepted* gains the conditionals. CHANGELOG.

**Verify:** `./mk -f tests/corpus/cond/Makefile` beside `gmake -f …`; the four error rows; `./test.sh | tail -1`. Stop.

### P1.5 — define and undefine

- `define NAME` … `endef`: the body, verbatim with its newlines, becomes NAME's value; `define NAME =`,
  `:=`, `+=`, `?=` set the flavour (no operator = recursive). Nested `define` inside a body counts: an inner
  `define` needs its own `endef`. The body is not expanded at definition unless `:=`.
- A multi-line value used in a recipe expands to several recipe lines, each run by its own shell (so a
  canned recipe of three lines prints three times, like three recipe lines). Witness: paste gmake's output
  for a `define run` with two `@echo` lines used as `all: ; $(run)`.
- `undefine NAME` removes the variable (`ifdef` is then false); `override define` and `override undefine`.
- Errors, pasted: a missing `endef` → `Makefile:1: *** missing 'endef', unterminated 'define'.  Stop.`; an
  extra `endef` is 4.4.1's `missing separator` line at that line (paste).
- Delete the `define` refusal.

Rows: `define/` and `define-bad/`. Commit red, then `define, endef and undefine`. README *Accepted*. CHANGELOG.

**Verify:** the canned-recipe row `ok`; `./test.sh | tail -1`. Stop.

### P1.6 — override, export, unexport, -e

- `override NAME = v` (and `:=`, `+=`, `?=`): wins over a command-line `NAME=…`; an ordinary assignment
  to a command-line name stays a no-op (as today).
- `export NAME`, `export NAME = v`, `export` alone (every variable), `unexport NAME`, `unexport` alone:
  the set of variables a recipe's environment carries. By default a recipe sees the environment `mk` was
  started with, plus variables that *came* from the environment, plus `export`ed ones; a Makefile-set
  variable is not in a recipe's environment unless exported. Witnesses, paste from gmake:
  `X=1` with `@echo $$X-$(X)` under `X=env gmake` → `1-1`; with `export Y=2` and `@echo $$Y` → `2`.
- `-e`: environment variables override Makefile assignments (the `X=env gmake -e` witness → `env-env`).
  `--help` gains `-e`; re-paste the usage block.
- `.EXPORT_ALL_VARIABLES` as a target name means `export` alone.

Rows: `export/` (`rows`: `plain`, `env` is not possible as a row — `same_as_make` runs both tools in the
harness's own environment, so give the Makefile its own `X := fromfile` and compare `$$X`; and a row `e -e`
whose Makefile reads a variable the harness sets: add to `same_as_make` an optional `# env: NAME=VALUE`
line in `rows` that both tools get). Commit red, then `override, export, unexport`, `-e`. README. CHANGELOG.

**Verify:** the `export` rows; `./test.sh | tail -1`. Stop.

### P1.7 — the variables make sets, and the release

- `MAKE` (the program as invoked: `argv[0]`… wolf has `env_arg0()` only from 0.2.36; until then the literal
  `mk`), `CURDIR` (the working directory after `-C`), `MAKEFILE_LIST` (P1.3), `MAKEFLAGS` (the single-letter
  flags given, in gmake's spelling: `k`, `n`, `s`, and `-j2` as ` -j2`; paste `gmake -k -j2` on a Makefile
  echoing `[$(MAKEFLAGS)]` → `[k -j2 --jobserver-auth=…]`; the jobserver word is track 05's — strip it and
  say so in the README's known differences), `MAKELEVEL` (`0`), `.DEFAULT_GOAL` (read: the default goal;
  set: changes it). Rows: `special/` with the harness's normalisation extended to replace the `MAKE` word
  (`gmake` or `mk`) in output lines: add `s/\b(gmake|mk)\b/MAKE/` to `normalize` only for rows whose
  `rows` line carries `# normalize-make` — no: keep it simple, normalise the word everywhere in `normalize`.
- Close the track: fmt/test/test.sh green; `VERSION` `0.3.0`; CHANGELOG `## 0.3.0 (<today>)`; README row
  count, the *Refused* table now lists only pattern rules, `.SUFFIXES`, order-only, double-colon and
  functions; commit `Release 0.3.0: the directives`; the clone proof as in P0.3.

**Verify:** the clone's result lines; `./mk --version`; `git log --oneline | head -20`. Stop for the judge.
