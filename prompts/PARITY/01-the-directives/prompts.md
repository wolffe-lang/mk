# Track 01 — the directives (0.3.0)

Do `prompts/PARITY/campaign.md`'s "Start of every session" first, `00-the-oracle/judge.md` included. Where the code
stands after track 00: the oracle is `gmake` 4.4.1, rows are `rows` files (a directory's inputs are its
git-tracked files, so **commit a fixture before its row can pass**), messages are 4.4.1's, `parse.lu` carries
each logical line as `Line { text, line }` and each `Rule` its `first_recipe_line`. The Makefile is still
read in two passes — `parse_makefile` collects `assignments`, `rules` and `phonies` into a
`Database`, then `build_vars` makes the `Vars` — and `expand` finds a reference's end with the first `)`.
This track makes the reader one-pass, the expander real, and lands every directive: `include`, the
conditionals, `define`, `override`/`export`, and the variables GNU make sets itself. Each refusal line in
`check_refusal` (parse.lu) is deleted in the prompt that lands its construct.

Every expected answer below was pasted from `gmake` 4.4.1. Where a prompt says "paste from gmake", run the
command and copy the bytes; never type a message from memory.

**On commits:** the commit names below are the shape to aim for while the work is ahead of you. Once edits
exist, never undo, stash, revert or re-type them to split them into those groups. If the changes interleave,
commit them as one batch whose message lists what it holds, say so in the verify, and move on (campaign rule 5).

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

## Fix prompts from the judge (2026-10-25, `judge.md`; run in order, one per session)

### P1.8 — the warnings, the recipe prefixes, the baseline corrections

Three small things, three commits, no new feature.

1. **Zero warnings.** `wolf build main.lu -o mk` prints 14. W0603 (10): the error tags `unterminated(int)` and
   `cycle(int, str)` carry payloads, so wolf wants them CapCase: rename to `Unterminated(int)` and
   `Cycle(int, str)` in every `! {…}` row and every `else`/match arm that names them (`expand.lu:17, 25, 26, 197,
   231, 232`, `graph.lu:206, 207`, and the arms that destructure them — `grep -n 'unterminated\|cycle' *.lu`
   finds every site; edit each in place, ≤ 60 lines per edit). W0601 (4): a fallible result dropped —
   `vars.lu:116` `map.remove(mut v.table, name)` is an intentional no-op when the name is absent: write
   `let _ = map.remove(mut v.table, name)`; `vars.lu:203, 220, 223` `env_unset(name)` / `env_set(name, expanded)`
   must propagate: add `?` (the enclosing `export_environment` already declares `! {invalid}`). Rebuild: zero
   warnings. Commit `build: zero warnings`.
2. **Recipe prefixes in any order, and `+`.** gmake strips any run of `@`, `-`, `+` (and spaces) from the front
   of a recipe line, in any order: `-@printf "prefix\n"` prints `prefix`; `+@printf …` too; `+printf "prefix\n"`
   echoes `printf "prefix\n"` then runs it. `+` means "run even under `-n`, `-t`, `-q`": under `-n`, gmake
   **executes** `+@printf executed\n > witness` (and prints the command line, as it prints every line under
   `-n`): the file `witness` exists afterwards. Today `run.lu:144–151, 312–313, 801–802, 847–854` peel one `@`
   then one `-`: replace each pair with one loop that peels `@`, `-`, `+` in any order and records three flags
   (silent, ignore_error, always_run); under `-n`, run the line when always_run. Rows: `prefix/` with
   `Makefile` recipes `-@`, `+`, `+@`, `@-+` on one target each and `rows`: `plain`, `n -n`. Commit red
   (`rows: recipe prefixes (red)`), then `recipe prefixes in any order; + runs under -n`.
3. **Baseline corrections**, one commit `baseline: $^ $? dedup, empty Makefile, -C missing, duplicate recipes,
   the normaliser`:
   - `$^` and `$?` list each prerequisite once, in order of first appearance (`out.c: a a b` → `[a b]`;
     `vars.lu:170 expand_auto`).
   - An empty Makefile (or one with no rule) and no goal: `mk: *** No targets.  Stop.` on stderr, exit 2
     (`main.lu:298 run`, after parsing).
   - `-C` into a missing directory: `mk: *** does-not-exist: No such file or directory.  Stop.`, exit 2, **before**
     anything runs (gmake prints `Entering`/`Leaving` around it only when `-C` succeeded once already; here it
     prints the two directory lines of the *current* directory — paste `gmake -C does-not-exist` in an empty
     dir and copy its three lines exactly).
   - A second rule with a recipe for the same target: the second recipe wins, with gmake's two warnings on stderr
     in this order: `Makefile:4: warning: overriding recipe for target 'all'` then
     `Makefile:2: warning: ignoring old recipe for target 'all'` (the line numbers are the rules' lines).
   - A variable name containing a space in an ordinary assignment is `Makefile:1: *** missing separator.  Stop.`;
     but `define odd name` … `endef` is legal and `$(odd name)` expands to its value (`parse_assignment`,
     `parse_define`, `expand_var`).
   - `X = before\#hash \` newline ` after` → `[before#hash after]` (the `\#` escape survives
     `join_continuations` and `strip_comment`).
   - A target whose name is a variable reference, `$(GOAL):`, is expanded when the rule is read (`parse_rule`).
   - Two `-f` files are both read, in order (`parse_flags`: a list, not a string).
   - `test.sh`: the normaliser's `s/ --jobserver-auth=[^ ]*//` eats the `]` or `"` after the word; make it
     `s/ --jobserver-auth=[^] "]*//`.
   Rows: `baseline/` (one Makefile per case where a directory can hold several; `rows` naming each), committed red
   first. README: the *Known differences* section gains nothing here (these are fixes), the *Tests* row count is
   re-pasted from `./test.sh | tail -1`.

**Verify:** `wolf build main.lu -o mk 2>&1 | grep -c warning` → `0`; the `prefix/` and `baseline/` rows;
`./test.sh | tail -1`. Stop.

### P1.9 — refuse by name, everywhere

mk's contract is: a construct it does not implement is refused **by its name**, exit 2, one line on stderr; never
a silent wrong answer. Three breaches, one commit each.

1. **Functions in any position.** `$(error HELLO)` inside a recipe exits 0 today and prints `result=[]`. Every
   `$(name …)` whose `name` is a gmake function (`subst patsubst strip findstring filter filter-out sort word
   wordlist words firstword lastword dir notdir suffix basename addsuffix addprefix join wildcard realpath abspath
   if or and intcmp foreach file call value eval origin flavor shell error warning info let`) is refused as
   `mk: Makefile:N: functions are not supported` — in a recipe, in an assignment, in a prerequisite list, in a
   conditional. The refusal must come from `expand_inner`/`call_function` in `expand.lu` (the one place every
   `$(…)` passes), **not** from `check_refusal`'s line scan, so the position no longer matters. `patsubst` and
   `filter` currently say `pattern rules are not supported`: the function name is the refusal, the `%` inside
   its arguments is not a pattern rule. Row: `functions/` with a recipe `$(error X)`, an assignment
   `Y := $(subst a,b,abc)`, and `$(info hi)` at top level; `rows`: `recipe`, `assign`, `info` — each expects
   exit 2 and gmake's *different* behaviour, so these rows are **refusal rows**: compare mk against the
   expected line in a `# expect:` comment, as the pattern-rule row does.
2. **Special targets.** A rule whose target is one of `.ONESHELL .SILENT .DELETE_ON_ERROR .PRECIOUS .INTERMEDIATE
   .SECONDARY .NOTINTERMEDIATE .IGNORE .NOTPARALLEL .WAIT .POSIX .SECONDEXPANSION .EXTRA_PREREQS .DEFAULT
   .LOW_RESOLUTION_TIME` (every gmake special target except `.PHONY`, `.SUFFIXES`, `.DEFAULT_GOAL`,
   `.EXPORT_ALL_VARIABLES`, which mk knows) is refused `mk: Makefile:N: .ONESHELL is not supported` — never
   made the default goal, never `Nothing to be done for '.ONESHELL'`.
3. **`SHELL` and `.SHELLFLAGS`.** An assignment to `SHELL` or `.SHELLFLAGS` in a Makefile is refused
   `mk: Makefile:N: SHELL is not supported` until track 04 implements it; today `SHELL = /usr/bin/false` is
   ignored and the recipe runs.

README: the *Refused* table gains `special targets` (the list) and `SHELL`/`.SHELLFLAGS`, and its functions row
says "in any position". CHANGELOG `### Fixed`.

**Verify:** `printf 'all:\n\t@echo $(error X)\n' > /tmp/m && ./mk -f /tmp/m; echo $?` → the refusal line and `2`;
the three new rows; `./test.sh | tail -1`. Stop.

### P1.10 — `.DEFAULT_GOAL` set

```
.DEFAULT_GOAL := second
first:
	@echo first
second:
	@echo second-[$(.DEFAULT_GOAL)]
```
gmake prints `second-[second]`; mk runs `first`. Rule (the manual, *Special Variables*): when no goal is given on
the command line, the goal is the value of `.DEFAULT_GOAL` after the Makefile is read; if it was never set, it is
the first target (`main.lu:438–442` sets it, but `build_goals` ignores it). If the value names more than one
word: `mk: *** .DEFAULT_GOAL contains more than one target.  Stop.` (paste gmake's line). Setting it to empty
and then defining targets makes the next target the default (gmake's documented idiom). Row: `defaultgoal/`
(`rows`: `set`, `empty-then-target`, `two-words`). Commit red, then `.DEFAULT_GOAL: set changes the goal`.

**Verify:** the three rows; `./test.sh | tail -1`. Stop.

### P1.11 — conditionals, gmake's way

Three witnesses, pasted from gmake 4.4.1:

```
ifeq (a,b)            ifeq ( a ,a)          ifeq "a" "a"        ifeq " a " "a"      ifeq 'a' "a"
X = bad1              X = yes               X = yes             X = yes             X = yes
else ifeq (c,c)       else                  else                else                else
X = yes               X = no                X = no              X = no              X = no
else                  endif                 endif               endif               endif
X = bad2              → no                  → yes               → no                → yes
endif
→ yes
```
Rules (`parse_conditional`, `eval_conditional`, `parse.lu:433–586`):
- `else ifeq …` / `else ifneq …` / `else ifdef …` / `else ifndef …` on one line is a new condition tested only when
  every earlier branch of the same `if` was false. Today it falls to the trailing `else` (prints `bad2`).
- The parenthesised form `(A,B)`: A is the text from after `(` to the first top-level `,` with **leading**
  whitespace removed, trailing kept (` a ` → `a `); B is the text after the `,` to the matching `)` with
  leading whitespace removed. Both are expanded, then compared byte for byte. Do **not** strip both sides
  (the P1.4 prompt said so and was wrong: the witness is `( a ,a)` → `no`).
- The quoted forms `"A" "B"`, `'A' 'B'` and mixed: each argument is the text between its quotes, exactly
  (` a ` stays ` a `), expanded, compared. Any whitespace between the two quoted arguments.
- `ifeq` with neither form: `Makefile:N: *** invalid syntax in conditional.  Stop.` (already right).
Rows: `cond2/` with the five witnesses as five targets or five small Makefiles under one directory (`rows`
naming each). Commit red, then `conditionals: else-if chains, gmake's whitespace, the quoted forms`.
README's *Accepted* table: the conditional row gains the quoted forms and `else ifeq`.

**Verify:** the rows; `./test.sh | tail -1`. Stop.

### P1.12 — export origin and state

Four witnesses (gmake 4.4.1; the recipe is `@printf "make=[$(X)] shell=[%s]\n" "$$X"` unless shown):
1. `export X = original` / `unexport X` / `export X` → the recipe sees `[original]` (mk: `[]`): `unexport` clears
   the exported flag and `export NAME` sets it again; neither touches the value (`vars.lu:155 set_var_exported`,
   `export_environment`).
2. `mk X=cli` with `all: @printf "make=[$(X)] shell=[%s]\n" "$$X"` → `make=[cli] shell=[cli]`: **every
   command-line variable is exported** (the manual, *Communicating Variables to a Sub-make*). mk gives
   `shell=[]`.
3. `X= mk` (the environment holds `X` with an empty value) and `X = fromfile` in the Makefile → `shell=[fromfile]`:
   a variable present in the environment, even empty, has environment origin and is exported when the Makefile
   reassigns it. mk tests the value, not the presence — use the environment's *names* (`env_names()` or iterate
   `env_all()`; if wolf-std has no way to list the environment, file the gap and say so in the README).
4. `override X` with no operator on its line → `Makefile:1: *** missing separator.  Stop.`, exit 2 (mk accepts it).
Rows: `export2/` (`rows`: `reexport`, `cli X=cli`, `emptyenv` with `# env: X=` — extend the harness's `# env:`
line to allow an empty value — and `override-bare`). Commit red, then `export: origin by presence, unexport then
export, command-line variables exported; bare override refused`.

**Verify:** the four rows; `./test.sh | tail -1`. Stop.

### P1.13 — remaking included makefiles

gmake, after reading every makefile, treats each included file as a goal: if a rule can remake it and it is out of
date (or missing), gmake makes it, then **restarts** reading from scratch with the new contents (the manual, *How
Makefiles Are Remade*). Three witnesses, each with `all: @printf "X=[$(X)]\n"` and the rule
`generated.mk: @printf "X = regenerated\n" > $@`:
- `include generated.mk`, file absent → gmake makes it and prints `X=[regenerated]` (mk: `No rule to make
  target 'generated.mk'`, exit 2 — because today the missing include is fatal before the rules are read);
- `-include generated.mk`, file absent → `X=[regenerated]` (mk: `X=[]`);
- `include generated.mk` with `generated.mk: source` and `source` newer → the stale `X = stale` file is rewritten
  (16 bytes `X = regenerated\n`) and the output is `X=[regenerated]`.
Implementation (`parse_include` records every included path and whether it was found; `main.lu:298 run`):
after `build_graph`, for each included path that has a rule in the graph, decide with `is_out_of_date`; make the
out-of-date ones with the ordinary machinery (their recipes echo as recipes do, unless `-s`/`@`); if any was
remade (or was missing and now exists), re-run the whole parse-and-build once with a flag so a second restart
does not loop (gmake restarts at most until nothing changes; one restart satisfies these witnesses — say so in
the README). A missing `include` whose target has **no** rule stays the fatal error it is today, with gmake's two
lines (`Makefile:1: generated.mk: No such file or directory` then `*** No rule to make target 'generated.mk'.
Stop.` — paste them). Rows: `include2/` (`rows`: `missing`, `soft-missing`, `stale`, each comparing the files
left behind). Commit red, then `include: remake out-of-date included makefiles and restart`.

**Verify:** the three rows; `./test.sh | tail -1`. Stop.

### P1.14 — the recursion variables

Witness (`sub/Makefile` and `sub/deep/Makefile` each echo the same line and recurse one level further):
```
all:
	@printf "L=[$(MAKELEVEL)] env=[%s]\n" "$$MAKELEVEL"
	@$(MAKE) -C sub
```
gmake: `L=[0] env=[1]`, then `gmake[1]: Entering directory '…/sub'`, `L=[1] env=[2]`, `gmake[2]: Entering
directory '…/sub/deep'`, `L=[2] env=[3]`, and the matching `Leaving` lines. mk: `env=[]` and `L=[0]` at every
level, and no `[N]`.
- `MAKELEVEL`: read from the environment at start (default 0); the variable is that number; the environment of
  every recipe carries `MAKELEVEL` = that number **+ 1** (export it always).
- The program-name prefix on `Entering directory`/`Leaving directory` and on every `mk: ***` line is `mk[N]:`
  when `MAKELEVEL` is N > 0 (`mk:` at level 0). One function builds the prefix; every stderr line uses it.
- `MAKEFLAGS` is exported to recipes (so a sub-make inherits `-k`, `-s`, `-n`, `-j2`; the jobserver word is track
  05's and stays absent, as the README says).
- Under `-n`, a recipe line that contains `$(MAKE)` or `${MAKE}` is **run**, not just printed (the manual, *How
  the MAKE Variable Works*): gmake's `-n` with `@$(MAKE) -C sub` prints the sub-make's `Entering` lines. Same
  mechanism as P1.8's `+`.
Rows: `recursion/` (`rows`: `levels`, `flags -k -j2` — the sub-make echoes `[$(MAKEFLAGS)]` — and `dry -n`).
Commit red, then `recursion: MAKELEVEL, the [N] prefix, MAKEFLAGS inherited, $(MAKE) lines run under -n`.
README *Known differences*: `MAKE` is the literal `mk` until `env_arg0()` (0.2.36); the jobserver word is absent.
Re-paste the row count. CHANGELOG. Stop for the second judge (the reviewer re-runs the 182 probes).

**Verify:** the three rows; `./test.sh | tail -1`; `git log --oneline | head -12`. Stop.

### P1.15 — the third judge's nine (a fresh session)

Read `judge.md`'s *Third judge* section first. Every item was reproduced outside the corpus against `gmake` 4.4.1; the
expected bytes are there. Order and commits:

0. **Make the committed head green.** `wolf fmt *.lu` (parse.lu reflows), fix `mk_test.lu`'s `parse_makefile` call (the
   seventh argument `env_names`), run the three gates, commit `fmt and the unit-test call site`. Nothing else in this commit.
1. **`include` of an absent file that has a rule.** In the include path (parse.lu, where P1.13 remakes an out-of-date
   include): when the named file does not exist, do not fail yet — record it as *missing*, finish reading the Makefile, then
   if a rule can make it, build it and restart the read (the same restart P1.13 uses); if no rule can, print gmake's two
   lines (`Makefile:1: gen.mk: No such file or directory` then `mk: *** No rule to make target 'gen.mk'.  Stop.`, exit 2).
   `-include`/`sinclude` of an absent file with a rule also builds it (gmake does); without a rule stays silent. Report
   **every** missing include before stopping (`first.mk`, `second.mk`, then the `No rule` line for the first). When the
   include's own prerequisite is missing the message is `No rule to make target 'source', needed by 'generated.mk'`.
   Rows: `include-remake/` (absent + rule, `include` and `-include` rows), `include-two-missing/`. Commit red, then
   `include: build an absent included file that has a rule, report every missing include`.
2. **Conditionals five or more deep.** Find why `cond_stack` stops at four (a literal capacity, a `len` compared to a
   constant, a `line_num` off by one at the fifth push); nest eight in a unit test and a row (`cond-deep/`). Commit
   `conditionals: any nesting depth`.
3. **`unexport` then `export` re-exports.** The last directive for a name wins, in file order; row in `export2/`; commit
   `export: the last directive wins`.
4. **`-n` with `-s` still echoes.** `-s` suppresses the echo of a line that will run; under `-n` nothing runs and gmake
   prints every line it would run, `-s` or not. Row in `recursion/` or a new `dry-silent/` with `-n -s` and `-n -s -k -j2`
   (`MAKEFLAGS` is `ns` / `kns -j2`: the single letters sorted, then `-jN`). Commit `dry run: -s does not silence -n`.
5. **A BOM is whitespace.** Skip EF BB BF at the start of a makefile's first line (and of an included file); never index past
   a line's end in `expand_inner` (the trap at expand.lu:44 is a bounds read: guard it so a malformed byte sequence is an
   error with the file and line, not a trap). Row `bom/` with the BOM bytes committed as a fixture. Commit `reader: a BOM is
   whitespace; no bounds trap in the expander`.
6. **A tab-only recipe line** is an empty recipe line gmake does not print. **A trailing backslash at end of file** keeps
   gmake's extra empty line in the echo (paste the bytes from `gmake` into the row). Rows in `recipes/`. Commit
   `recipes: tab-only lines and a terminal backslash`.
7. **README** *Known differences*: replace the two lines that describe behaviours that agree with gmake (`$(MAKE)` under
   `-n`, `MAKEFLAGS` inheritance belong in *Accepted*) with the one real difference: `$(MAKE)` expands to the literal `mk`
   until wolf 0.2.36's `env_arg0()` (gmake prints its absolute path). Re-paste the row count. CHANGELOG `### Fixed`.
   Commit `README: the one known difference`.

**Verify:** from a *fresh clone* of your pushed head — not the working tree — `wolf build main.lu -o mk && wolf fmt --check
*.lu && wolf test . && ./test.sh | tail -1`, all green, pasted; then the nine probes from `judge.md` run by hand with gmake
beside mk, pasted. `git log --oneline | head -12`. Stop for the fourth judge.
