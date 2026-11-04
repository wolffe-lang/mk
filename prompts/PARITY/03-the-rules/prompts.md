# Track 03 — the rules (0.5.0)

Do `prompts/PARITY/campaign.md`'s "Start of every session" first. Track 02 has no `judge.md`: its judge re-ran P2.8 from
a fresh clone of `aa2931e` (`Release 0.4.0`) on wolf 0.2.36 (`fmt=0`, `wolf test: 88 passed`, `Results: 335 passed, 0
failed (expected: 335)`, `mk 0.4.0 (tested with wolf 0.2.36)`), and the 182-probe battery read 143 parity, 17 message
diffs, 7 refused by name, 14 silent wrong, 1 hang (`Track 02` 39 of 39, `Track 02 (!=)` 1 of 1). `4e9ba82` on top of it
only stops tracking the binary; its gates read the same.

**Where the code stands at `4e9ba82`.** The reader is `parse_lines` (parse.lu:739). A logical line comes from
`join_continuations` (parse.lu:103), which strips comments from every line that does not start with a tab and joins a
non-recipe continuation with one space. A line that starts with a tab is a recipe line of the current rule (parse.lu:795;
`.RECIPEPREFIX` is not read). Every other line goes first through `check_refusal` (parse.lu:236): a `%` among the targets
(`percent_in_targets`, parse.lu:1780) is `pattern rules are not supported`, **any** `|` in the line is `order-only
prerequisites are not supported`, **any** `::` is `double-colon rules are not supported`. Then come the conditionals,
`define`, `export`, `override`, `parse_assignment` (parse.lu:323), `include`, `.PHONY`, and `parse_rule` (parse.lu:364),
which splits at the first `:` into `Rule { targets, prereqs, recipe, first_recipe_line, line }`. Target and prerequisite
names are kept **unexpanded**: `build_graph` (graph.lu:217) expands them after the whole makefile is read and `add_node`
(graph.lu:54) merges rules per target, printing the "overriding recipe" warnings. `is_out_of_date` (graph.lu:118) and
`newer_prereqs` (graph.lu:179) decide what runs. `build_recursive` (run.lu:262) and `build_target` (run.lu:125) run the
serial build, `build_goals_parallel` (run.lu:659) the `-j` one, and `expand_auto` (vars.lu:312) substitutes `$@ $< $^ $?`
as **text** into each expanded recipe line. `$(@)` works through the table (run.lu:155); `$(@D)`, `$(@F)`, `$+`, `$|`,
`$*` and `$%` expand to nothing or reach the shell literally.

**Measured at `4e9ba82`** (gmake 4.4.1 against mk; every probe is a fresh directory, raw bytes, stdout and stderr in one
stream, gmake run under the name `mk`). The battery's five `Track 03` probes: `double-colon` and `order-only` are refused
by name, `pattern-rule` is refused where gmake says `mk: *** No rule to make target 'x.out'.  Stop.`, `duplicate-recipes`
differs in its line numbers, `percent-prerequisite` is at parity. The battery's six `automatic-*` probes (`Track 00 …;
Track 03 for */%`) measure nothing: their prerequisites `a` and `b` do not exist, so both tools stop with `No rule to make
target 'a', needed by 'out.c'`. The judge should replace them with probes whose prerequisites exist. New probes:

| construct | gmake 4.4.1 | mk at `4e9ba82` |
|---|---|---|
| `all: ; @echo hi` | `hi` | `mk: *** No rule to make target ';', needed by 'all'.  Stop.` (silent wrong: `;` is a prerequisite) |
| `all: ;` (empty recipe) | `mk: 'all' is up to date.` | the same `No rule to make target ';'` |
| `all:` + `\t$(EMPTY)` | `mk: 'all' is up to date.` | an empty line |
| `.PHONY: all` + `all: ;` | `mk: Nothing to be done for 'all'.` | `No rule to make target ';'` |
| `out: FORCE` + `FORCE:`, `out` exists | the recipe runs, `$?` is `FORCE` | `mk: 'out' is up to date.` (silent wrong) |
| `.RECIPEPREFIX = >` + `>@echo hi` | `hi` | `Makefile:3: *** missing separator.  Stop.` |
| `all:` + `\t  @echo x` | `x` (whitespace before `@` is skipped) | `/bin/sh: @echo: command not found` |
| `all: a \` + `\tb` (a rule line continued with a tab) | prerequisites `a b` | the tab line is a recipe line |
| two recipes for `all` (lines 1–2, 3–4) | `Makefile:4: warning: overriding recipe for target 'all'` and `Makefile:2: warning: ignoring old recipe for target 'all'` | lines 3 and 1 (the rules' lines, not the recipes'); an included file's rule is named by the main makefile; printed after reading, so after a later `$(info)` |
| `X := 1`, `t: $(X)`, `X := 2` | builds `1` | builds `2` (rule lines expanded after reading) |
| `SEMI := ;` + `all: a $(SEMI) echo x` | the `;` from the variable starts the recipe | `No rule to make target ';'` |
| `all: a \| b` | `$\|` is `b`; `b` never makes `all` out of date | refused by name |
| `X = a\|b`, `X = a::b` (values) | assigned | refused by name (over-refusal) |
| `all:: a` + `all:: b` | each rule runs on its own, `$?` per rule; with no prerequisites it always runs | refused by name |
| `all:` + `all::` | `Makefile:3: *** target file 'all' has both : and :: entries.  Stop.` | refused by name |
| `X ::= v`, `Y :::= v` | `simple`, `recursive` | refused as double-colon rules |
| `$(objs): %.o: %.c` | static pattern, `$*` the stem | `No rule to make target '%.o:', needed by 'a.o'` (silent wrong) |
| `a b &:` + recipe, `all: a b` | the recipe runs once (`making a`) | runs twice (silent wrong) |
| `%.o: %.c`, goal `a.o`, `a.c` exists | `$*` is `a` | refused by name |
| `%.b: %.a`, `%.c: %.b`, goal `x.c` | `cp x.a x.b`, `cp x.b x.c`, `rm x.b` | refused by name |
| `all: a b a` + `$+` | `a b a` | `$+` reaches the shell literally |
| `all: dir/sub/x.c y.c` + `$(@D) $(@F) $(<D) $(<F) $(^D) $(^F)` | `. all dir/sub x.c dir/sub . x.c y.c` | all six empty |
| `a.o: ; echo $*` / `x.txt: ; echo $*` | `a` / empty | `No rule to make target ';'` (and `$*` is the shell's) |
| `all: ; @echo [$$@]` | `[]` (the shell's `$@`) | `[all]` once `;` works: `expand_auto` substitutes the `$@` that `$$@` became |
| `all:` + `\t@echo é` (any non-ASCII byte in a recipe, a value or a target) | `é` | `wolf-trap: bounds` at expand.lu:97 or parse.lu:1784, exit 134 |

**What the campaign row gets wrong** (measured, above and in the sessions):
- A recipe on the rule line and the empty recipe are not missing features. They are silent wrong answers today (`;` is a
  prerequisite named `;`). So is the `FORCE:` idiom, a rule with neither recipe nor prerequisites.
- mk already prints the "overriding recipe" warnings, with the wrong line, the wrong file for an included rule, and at the
  wrong moment. gmake 4.4.1's words are `warning: overriding recipe for target 'T'` and `warning: ignoring old recipe for
  target 'T'` (not 3.x's "overriding commands").
- Chains cannot reach parity without deleting intermediate files, which the campaign puts in track 04: the simplest chain
  prints `rm x.b` and removes `x.b`, under `-n` too. Plain deletion belongs to the chain session here;
  `.INTERMEDIATE`/`.SECONDARY`/`.PRECIOUS`/`.NOTINTERMEDIATE` stay in 04.
- `$*` of an explicit rule depends on the suffix list, track 06's `.SUFFIXES`: `a.o: ; echo $*` prints `a` because `.o` is
  a default suffix, and `x.txt` gives nothing. Track 03 needs gmake's default list as a constant (`gmake -p -f /dev/null`:
  `.SUFFIXES: .out .a .ln .o .c .cc .C .cpp .p .f .F .m .r .y .l .ym .yl .s .S .mod .sym .def .h .info .dvi .tex .texinfo
  .texi .txinfo .w .ch .web .sh .elc .el`).
- The `D`/`F` forms are ordinary default variables in gmake (`@D = $(patsubst %/,%,$(dir $@))`, `@F = $(notdir $@)`, 14
  in all for `@ % ^ * + ? <`). There is no `|D` or `|F`, which mk's `is_automatic_name` (vars.lu:264) lists.
- Pattern rules meet the built-in rule database (track 06) and makefile remaking in every row: gmake tries to remake the
  makefile itself through a user's pattern rule (`%.o: common.h` made gmake run `cc Makefile.o -o Makefile` and fail).
  Pattern-rule rows must stay away from built-in suffixes and from rules that can match `Makefile`, until track 06, and
  mk's makefile remaking must try the pattern rules or the README must name the difference.
- Static pattern rules, grouped targets and order-only `|` are silently wrong or over-refused, not cleanly refused.

**On commits:** the names below are the shape; campaign rule 5 (never undo finished edits to split them). Each session
brief is measured on gmake 4.4.1 and rehearsed on a clone first, and replayed literally before it is handed over.

### P3.1 — the recipe on the rule line, the empty recipe, and the rule with neither

`sessions/P3.1-the-rule-line.md`, 82 steps, rehearsed and replayed. A `;` after a rule's `:` starts its first recipe line
(`rule_semicolon` in parse.lu finds it outside `$(…)` and before any `=` or `#`). `parse_lines` reads only the head before
it (refusals, assignment, `.PHONY`, a top-level `$(…)`, the rule), so `|`, `::` and `%` in the recipe are recipe text.
`strip_comment` keeps a `#` after it, and a backslash-newline in it stays for the shell, as gmake prints it under `-n`.
`t: ;` is an empty recipe: a line that expands to nothing is neither echoed nor run (serial, `-n`, `-j`). gmake's message
for a goal whose update started no command (`Vars.commands_started` serially, a `ran` map under `-j`) replaces the old
not-out-of-date messages: `'t' is up to date.` for an empty recipe, `Nothing to be done for 't'.` for no recipe, a phony
target or a file with no rule, and the same for a goal named twice. `build_recursive` loses `is_goal`. A prerequisite that
does not exist once its rule has run is newer and is in `$?` (`is_out_of_date`, `newer_prereqs`), which is the `FORCE:`
idiom. The nine untracked files under `functions-file-io/` are what that directory's rows write when gmake or mk is run
inside it by hand (`test.sh` copies to `mktemp -d` and leaves nothing): they go into `.gitignore`. Rows `rules-semicolon/`
(26), `rules-empty/` (34), `rules-force/` (8). End: `fmt=0`, 92 unit tests, `Results: 403 passed, 0 failed (expected:
403)`, warnings 0. The battery on the rehearsed head reads 144 parity: `ten-thousand-targets` (`Nothing to be done for
'all'.`) moves from silent wrong, and nothing else moves. Seven commits: `gitignore: what the functions-file-io rows
write when run by hand`, `rows: a recipe after ; on the rule line (red)`, `parse: a recipe after ; on the rule line`,
`rows: empty recipes and the goal messages (red)`, `run: an empty recipe runs nothing; a goal that started no command
says so`, `rows: a target with neither recipe nor prerequisites is newer (red)`, `graph: a missing prerequisite is newer
than its target`.

### P3.2 — recipe lines: inside a conditional, outside a rule, the prefix characters, a tab continuation, the warning's line

`sessions/P3.2-recipe-lines.md`, 36 steps with three restart points, rehearsed and replayed, sized for the `:8002` context
(about 30k tokens). Measuring it found a worse defect than the ones planned: mk ends a rule at **any** non-recipe line,
so a recipe line inside a conditional is silently dropped. `all:`, `ifeq (a,a)`, `\t@echo yes`, `endif` prints `yes` in
gmake and `mk: Nothing to be done for 'all'.` in mk, and the same holds under `-n` and `-j`. `.RECIPEPREFIX` moves to
P3.2b to make room for it.
- Only a live line other than a conditional directive ends a rule; a recipe line in a branch not taken is dropped, and
  so is a line in a dead branch, which ends nothing (`dead:`, `ifeq (a,b)`, `X = 1`, `endif`, `\t@echo after-dead`).
- A tab line outside a rule: gmake reads a directive or an assignment as a makefile line (`\tX = 1` before the first
  target sets `X`), skips a blank or comment one, and stops at any other with `FILE:N: *** recipe commences before first
  target.  Stop.`, also after an assignment that ends a rule, after `define … endef`, `include`, `export` or a top-level
  `$(info)`, and in an included file. This is P2.7b's "a tab line before the first target is silently ignored". After
  `.PHONY:`, `.EXPORT_ALL_VARIABLES:` or a refused rule, a tab line is that rule's ignored recipe (`special_rule`).
- A rule or assignment line continued onto a tab line is one line (`X = a \` then `\tb` was `a`, silently).
- Whitespace before, between and after `@`, `-`, `+` is skipped (`\t@ - exit 2` is ignored; `\t\t@echo x` is silent).
- The overriding warnings name each recipe's first line; the included file's name and the moment stay P3.3's.
Rows `rules-lines/` (20). End: 93 unit tests, `Results: 423 passed, 0 failed (expected: 423)`, warnings 0. Five commits:
`rows: recipe lines (red)`, `parse: recipe lines inside a conditional; a tab line outside a rule`, `parse: a rule or
assignment line continued onto a tab line`, `run: whitespace around the recipe prefix characters`, `graph: the
overriding warning names the recipe's first line`.

### P3.2b — `.RECIPEPREFIX`

Measured on gmake 4.4.1. `.RECIPEPREFIX = >` makes a `>` line a recipe line from the next line on, and a tab line an
ordinary one: `\t@echo tab` is `Makefile:3: *** missing separator.  Stop.`, `\tfoo: ; @echo foo` is a rule, `\tX = 1`
an assignment. Only the first character counts (`>>` is `>`), and an empty value restores the tab. A `#` in a prefix line
is recipe text. A continuation line drops one leading prefix character, as with a tab (`-n` prints `echo one \` and
`two`). A prefix line before any rule is `recipe commences before first target`. `override` and `:=` work. The value is
read raw: `.RECIPEPREFIX = $(P)` with `P = >` makes `$` the prefix, so `>@echo` is `missing separator`. A
`.RECIPEPREFIX` in a branch not taken changes nothing. One set in an included file holds for the including file's later
lines. `$(eval)` text and an included file start from the current value.

The design problem is that `join_continuations` decides recipe lines, comments and continuations for a whole file
before `parse_lines` evaluates anything, while the prefix can change mid-file: in a conditional, from an include, from
`$(eval)`. The proposal:
- `join_continuations(lines, prefix)` starts from the variable's current first character (`parse_makefile`, `eval_text`).
- It follows the `.RECIPEPREFIX` assignments it sees outside `if…endif` and `define…endef` blocks.
- It turns a prefix line into a tab line, so `parse_lines` stays as it is, and a non-prefix tab line into an untabbed one.
- It records the prefix each logical line was joined with (`Line.prefix`).
- `parse_lines` refuses by name when the variable's first character differs from the line's recorded prefix: a
  `.RECIPEPREFIX` set in a taken branch, in an included file, by `$(eval)`, or with `:=` and a reference. mk is then never
  silently wrong.

Rows `rules-prefix/`; commits `rows: .RECIPEPREFIX (red)`, `parse: .RECIPEPREFIX`.

### P3.3 — rule lines are read when they are read

gmake expands a rule's targets and prerequisites when it reads the rule line (the manual's "immediate" context) and the
recipe when it runs. mk expands both lists in `build_graph` after the whole makefile is read. Move that expansion into the
reader: when `parse_lines` finishes a rule line, its target and prerequisite lists are expanded in `v` as it is then
(`expand_store`, so an `$(eval)` there defines what it defines, and the rule-line half of the README's known difference
about `$(eval)` goes). `build_graph` then only merges. `X := 1`, `t: $(X)`, `X := 2` builds `1`. A `;` that comes from a
variable starts the recipe (`SEMI := ;`, `all: a $(SEMI) echo x` prints `echo x` and `x`). `Rule` gains `file`, so an
included rule is reported with its own file name (`inc.mk:2: warning: ignoring old recipe for target 'all'`). The two
warnings are printed when the overriding rule is complete, before the lines after it are read, so before a later
`$(info …)`. Paste the probe `override-warn-info` from gmake: `read line 3`, the two warnings, `read line 6`, `second`. After
P3.2 the warnings' lines are right and only the file is wrong (`Makefile:2:` where gmake says `inc.mk:2:`). The lists are
expanded where `parse_rule` reads the rule line; the warnings belong where P3.2's `parse_lines` ends a rule (a live line
other than a conditional directive), since the recipe is complete only there. Rows
`rules-read/`; commits `rows: rule lines read when read (red)`, `parse: targets and prerequisites expanded when the rule
is read`, `parse: the overriding warnings when the rule is read, with its file`.

### P3.4 — order-only prerequisites and the automatic variables

- `targets: normal | order-only`. The `|` refusal goes from `check_refusal`, and with it the over-refusal of `|` in
  values. `Rule` and `Node` gain `order_only: List[str]`. Order-only prerequisites are built first but never make the
  target out of date and are not in `$^`, `$+`, `$?` or `$<`. A name in both lists is normal (`all: a | a` gives `$^` `a`,
  `$|` empty). `all: |` is legal. A `|` that comes from a variable splits too (after P3.3).
- The automatic variables become variables set per target in the recipe's table (`rv`, run.lu:154, and the `-n`/`-j`
  paths): `@ < ^ ? + | * %`, with `$^` and `$?` deduplicated and `$+` not. The 14 `D`/`F` forms are defined the way
  `gmake -p` prints them (`@D = $(patsubst %/,%,$(dir $@))`, `@F = $(notdir $@)`, …). `expand_inner`'s `$x` path
  (expand.lu:311) reads an automatic character as a variable, and `expand_auto` is deleted. It substitutes text after
  expansion, so `$$@` reaches the shell as the target's name (gmake passes `$@` to the shell, which prints nothing).
- `$*` of an explicit rule is the target minus a suffix from gmake's default list (above), else empty. `$%` is empty
  (archive members are track 06). `$(|D)` and `$(|F)` are undefined in gmake (empty), unlike the 14 others.
Rows `rules-order-only/`, `rules-automatic/`; commits `rows: order-only prerequisites (red)`, `rules: order-only
prerequisites`, `rows: the automatic variables (red)`, `run: the automatic variables are variables`.

### P3.5 — double-colon rules

`check_refusal`'s `::` goes, and with it the refusals of `X ::= v` (simple) and `Y :::= v` (recursive, the POSIX form),
which become assignments (`parse_assignment` and `parse_define` learn both operators). Each `t::` rule is its own rule:
its recipe runs only when that rule's own prerequisites are newer, `$?` and `$^` are that rule's, rules run in file
order, and a double-colon rule with no prerequisites always runs. A double-colon rule with no recipe still builds its
prerequisites (`dc-no-recipe`: `make a`, `make b`, `b-rule`). Mixing `t:` and `t::` is fatal at the second one, either
order: `Makefile:3: *** target file 'all' has both : and :: entries.  Stop.`. `add_node` keeps a list of rules for a
double-colon target instead of merging. Rows `rules-double-colon/`; commits `rows: double-colon rules (red)`, `rules:
double-colon rules`, `parse: ::= and :::= assignments`.

### P3.6 — static pattern rules

`targets: target-pattern: prereq-patterns`, after the target list is expanded (P3.3). Each target that matches the
pattern becomes an explicit rule: its stem replaces the first `%` of each prerequisite pattern (`%%.c` gives `a%.c`), and
a prerequisite without `%` is kept as it is. `$*` is the stem. A pattern with a directory matches it literally
(`src/%.o: src/%.c`, stem `a`). A target that does not match gets the warning `Makefile:2: target 'x.c' doesn't match the
target pattern` and no rule; mk goes on. A pattern with no `%` is fatal: `Makefile:1: *** target pattern contains no '%'.
Stop.`. `$(filter %.o,$(files)): %.o: %.c` is the manual's idiom. `parse_rule` sees the second `:` (mk takes `%.o:` for a
prerequisite today). Rows `rules-static/`; commits `rows: static pattern rules (red)`, `rules: static pattern rules`.

### P3.7 — pattern rules

`percent_in_targets` stops refusing; a rule whose target has a `%` goes to the database's pattern rules, in file order,
and is never the default goal (`%.o: %.c` then `all: ; @echo all` builds `all`; a makefile with only pattern rules is
`mk: *** No targets.  Stop.`). A target with no explicit recipe gets one from the first pattern rule that matches with
the shortest stem (`a%.o` beats `%.o` for `ab.o`, `$*` `b`) whose prerequisites exist or can be made. With `%.o: %.c` and
`%.o: %.s`, `x.c` decides for the first and only `x.s` for the second. An explicit rule's own prerequisites are appended
(`a.o: extra.h` plus `%.o: %.c` gives `$^` `a.c extra.h`). A pattern without `/` matches the file name part and the
directory is put back: `%.o` on `dir/a.o` has `$*` `dir/a`, `$(*D)` `dir`, `$(*F)` `a`; `a%.o: b%.c` on `sub/a.o` has
`$*` `sub/` and `$<` `sub/b.c`. A match-anything rule `%: %.src` works. A pattern rule with no recipe cancels an earlier
one (`mk: *** No rule to make target 'a.o'.  Stop.`). When no rule can make the prerequisite, gmake names the target:
`mk: *** No rule to make target 'x.out'.  Stop.` (the battery's `pattern-rule`), `… 'q.o', needed by 'all'.  Stop.`. A
`%` from a variable makes a pattern rule too (`PAT = %.o`, `$(PAT): %.c`). Makefile remaking (above): measure what gmake
does with `Makefile` before choosing between trying the pattern rules and naming the difference. Rows `rules-pattern/`,
built-in-free suffixes only; commits `rows: pattern rules (red)`, `rules: pattern rules`.

### P3.8 — chains, intermediate files and grouped targets

- A pattern rule's prerequisite that does not exist may itself be made by a pattern rule (a chain). A file made that way
  and not mentioned in the makefile is intermediate: gmake deletes it after the goal, printing `rm x.b` (under `-s` it
  prints nothing and still deletes; under `-n` it prints `rm x.b` and deletes nothing). A second run does not remake an
  intermediate that is missing
  while its ultimate prerequisite is older than the target. A file named anywhere in the makefile (`keep: x.b`) is not
  intermediate and stays.
- Grouped targets `a b &: …`: one recipe run makes all of them (`all: a b` prints `making a` once), and `$@` is the target
  that triggered it. A pattern rule with several targets (`%.x %.y: %.in`) is grouped by definition. mk takes `&` for
  something else today and runs the recipe twice.
Rows `rules-chain/`, `rules-grouped/`; commits `rows: chains and intermediate files (red)`, `rules: chains and intermediate
files`, `rows: grouped targets (red)`, `rules: grouped targets`.

### P3.9 — the release and the judge

The README's *Refused* table loses the pattern, order-only and double-colon rows. *Accepted* gains each construct with one
example, and *Known differences* names what was kept. The *Tests* counts are re-pasted. CHANGELOG `## Unreleased` becomes
`## 0.5.0 (date)`, `VERSION` in main.lu and the `VERSION` file become `0.5.0`, and the commit is `Release 0.5.0`.
**Verify:** from a fresh clone, the four gates, warnings 0, and `./mk --version` → `mk 0.5.0 (tested with wolf 0.2.36)`.
Stop for the judge, who re-runs the battery (the five `Track 03` probes must be parity, the six `automatic-*` probes
rewritten with existing prerequisites) and their own rules matrix.

### Found by P3.1's author (2026-11-02), measured on gmake 4.4.1, not fixed (no rows yet)
- Any non-ASCII byte in a recipe, a variable value or a target name traps (`wolf-trap: bounds`, exit 134) where the code
  slices strings one byte at a time (`expand_inner`, expand.lu:97; `percent_in_targets`, parse.lu:1784; others). A
  comment is safe. `s.get(i..i + 1) else ""` is the non-trapping form (P3.1's `rule_semicolon` uses it). This belongs in a
  session of its own before the battery grows a UTF-8 probe.
- Under `-j`, a goal whose prerequisite ran a command for an earlier goal is not reported (`a: x ; @echo a`, `b: x ;`,
  `x: ; @echo x`, `-j 2 a b`): gmake prints `x`, `mk: 'b' is up to date.`, `a`; mk prints `x`, `a`. The serial build
  matches gmake (P3.1's `ran` map is per target; gmake counts per goal).

### Found by P3.2's author (2026-11-03), measured on gmake 4.4.1, not fixed (no rows yet)
- `export`, `override` and `undefine` lines in a branch not taken are executed. `ifeq (a,b)`, `export X = 1`, `endif` gives
  `[1] [1]` for `[$$X] [$(X)]` (gmake `[] []`), a dead `override X = changed` wins (`[changed]`, gmake `[keep]`), and a dead
  `undefine X` undefines it. `parse_lines` handles these directives before its liveness check (a dead `define` is dropped
  correctly). This is track 01's conditionals, a small session of its own.
- `.RECIPEPREFIX` is P3.2b, above.
