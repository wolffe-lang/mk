# Track 02 — the functions (0.4.0)

Do `prompts/PARITY/campaign.md`'s "Start of every session" first, `01-the-directives/judge.md` (all four judges) included.
Where the code stands after track 01: the expander is `expand.lu` — `expand` → `expand_inner(v, s, visiting, line)` scans a
reference to its balanced close, expands computed names, and when the inside's first word is one of `is_gmake_function`'s
names (expand.lu:237) returns `Refuse(line, msg)` so every caller prints `functions are not supported` by name and exits 2
(P1.9 made that hold in recipes too). The hook P1.1 left is `call_function(v: Vars, args: str, visiting: str) -> str`
(expand.lu:531), which returns `""` today. `try_substitution`, `split_words`, `apply_simple_sub` and `apply_pattern_sub`
(expand.lu:400–530) already do word splitting and `%` patterns; `glob.lu` already expands wildcards for targets. The
reader is one-pass (`parse_makefile` in parse.lu); `check_refusal` there still refuses `!=`, `$(eval …)` and friends at
parse time. The special variables are set in `main.lu` around line 390 (`MAKE`, `CURDIR`, `MAKEFILE_LIST`, `MAKEFLAGS`,
`MAKELEVEL`, `.DEFAULT_GOAL`). Recipe-time expansion goes through `expand_auto`'s callers in run.lu.

This track makes `call_function` real, one family per prompt, and deletes each name from the refusal list as it lands
(`is_gmake_function` keeps only the names not yet landed; when it is empty, the refusal path and the README's *Refused*
rows for functions go). Every expected answer below is pasted from `gmake` 4.4.1 — where a prompt says "paste", run the
command and copy the bytes; never type a result from memory. The manual (not the source) is the reference for a function's
meaning.

**On arguments.** A function reference is `$(name arg1,arg2,…)`: the name ends at the first whitespace; the arguments are
split on commas **at nesting depth zero** (a comma inside `$(…)` or `${…}` belongs to the inner reference); leading
whitespace of the first argument is dropped, the rest kept; each argument is expanded when the function needs its value
(`if`, `or`, `and`, `foreach`, `call` expand lazily — their arguments are expanded by the function, not before). Write
`fn split_args(args: str) -> List[str]` once in expand.lu, test it with nested references and a literal comma inside
`$(subst)`, and route every function through it.

**On commits:** the names below are the shape; campaign rule 5 (never undo finished edits to split them).

### P2.1 — the text functions

`subst`, `patsubst`, `strip`, `findstring`, `filter`, `filter-out`, `sort`, `word`, `wordlist`, `words`, `firstword`,
`lastword`. `patsubst` reuses `apply_pattern_sub` (one `%` per pattern; words that do not match pass through); `sort`
removes duplicates as well as sorting (gmake's rule); `word`/`wordlist` with a non-number or 0 are gmake's errors — paste
them (`*** non-numeric first argument to 'word' function: ''.  Stop.` is the shape; get the bytes). Witnesses to paste
beside: `$(subst ee,EE,feet on the street)`, `$(patsubst %.c,%.o,x.c.c bar.c)`, `$(strip   a   b  )`,
`$(findstring a,a b c)`, `$(filter %.c %.s,foo.c bar.c baz.s ugh.h)`, `$(filter-out …)`, `$(sort foo bar lose foo)`,
`$(word 2, foo bar baz)`, `$(wordlist 2, 3, foo bar baz)`, `$(words foo bar)`, `$(firstword …)`, `$(lastword …)`.
Rows: `functions-text/` (one target per function, plus the two error rows in `functions-text-bad/`). Unit tests: one per
function plus `split_args`. Delete these twelve names from `is_gmake_function`. README *Accepted* gains them with one example
each; the *Refused* row for functions names only what remains. Commit red (`rows: the text functions (red)`), then
`functions: subst … lastword, and split_args`.

**Verify:** `wolf test .`; `./test.sh | tail -1`; the row's `./mk` and `gmake` outputs pasted side by side. Stop.

### P2.2 — the file-name functions

`dir`, `notdir`, `suffix`, `basename`, `addsuffix`, `addprefix`, `join`, `wildcard`, `realpath`, `abspath`. `wildcard`
through `glob.lu` (sorted as gmake sorts: the directory order is not promised by gmake, so the row sorts). `realpath` of a
missing file is empty; `abspath` does not require existence. Witnesses: `$(dir src/foo.c hacks)` → `src/ ./`,
`$(notdir src/foo.c hacks)` → `foo.c hacks`, `$(suffix src/foo.c src-1.0/bar.c hacks)` → `.c .c`,
`$(basename src/foo.c src-1.0/bar hacks)`, `$(addsuffix .c,foo bar)`, `$(addprefix src/,foo bar)`, `$(join a b,.c .o)` → `a.c b.o`,
`$(wildcard *.c)` with two committed `.c` fixtures, `$(realpath nope)`, `$(abspath x/../y)`. Rows `functions-file/`;
tests; names deleted; README. Commits: `rows: the file-name functions (red)`, `functions: dir … abspath, wildcard`.

**Verify** as P2.1. Stop.

### P2.3 — the conditional functions

`if`, `or`, `and`, `intcmp`. Lazy: `$(if c,t,e)` expands `c`, then only `t` or `e` (test it with `$(error)` in the branch
not taken — it must not fire — the row lands after P2.5 refuses nothing; until then use `$(info)` once P2.5 lands, so put
this row's laziness test in P2.5 and keep a plain one here). `or` is the first non-empty argument, `and` the last if all are
non-empty. `intcmp`'s five-argument form and its errors: paste from gmake (`$(intcmp 1,2)`, `$(intcmp 2,2,lt,eq,gt)`,
`$(intcmp a,1)`). Rows `functions-cond/`; tests; names deleted; README. Commits: `rows: the conditional functions (red)`,
`functions: if, or, and, intcmp`.

### P2.4 — `foreach`, `call`, `value`, `origin`, `flavor`

`$(foreach var,list,text)`: `var` is set for each word (a temporary, restored after); `$(call fn,a,b)`: `$(1)`, `$(2)`, `$(0)`
bound during the expansion of `fn`'s value (nesting restores the outer ones); `$(value V)` is the unexpanded text;
`$(origin V)` is one of `undefined`, `default`, `environment`, `environment override`, `file`, `command line`, `override`,
`automatic` — the `Vars` entry already records origin since P1.12 (`set_var`'s origin argument), so this is a lookup;
`$(flavor V)` is `undefined`, `recursive` or `simple`. Witnesses pasted for each, including `$(origin MAKE)` (`default`),
`$(origin CURDIR)`, a `-e`'d environment variable, a command-line one. Rows `functions-call/`; tests; names deleted;
README. Commits: `rows: foreach, call, value, origin, flavor (red)`, `functions: foreach, call, value, origin, flavor`.

### P2.5 — `error`, `warning`, `info`, and `MAKECMDGOALS`

`$(error text)` at read time: `Makefile:N: *** text.  Stop.` exit 2 (N the line of the reference); inside a recipe it fires
when the recipe line is expanded, before the line runs, and the message's N is that recipe line; `$(warning text)`:
`Makefile:N: text` on stderr, continue; `$(info text)`: `text` on stdout, continue — paste all three from gmake, with the
exact spacing. `MAKECMDGOALS` is the goals given on the command line, space-joined, set beside the other special
variables in main.lu. The laziness row from P2.3 lands here (`$(if ,$(error no),yes)` prints `yes`). Rows `functions-msg/`
(with error rows in `functions-msg-bad/`); tests; names deleted (`error`, `warning`, `info` leave `is_gmake_function`; with
them the refusal path in `expand_inner` is dead code if every name has landed — delete it and the README's functions
*Refused* row, else keep what remains). Commits: `rows: error, warning, info, MAKECMDGOALS (red)`,
`functions: error, warning, info; MAKECMDGOALS`.

### P2.6 — `shell` and `!=`

`$(shell cmd)` runs `cmd` with `/bin/sh -c`, captures stdout, turns each newline into a space and drops the trailing one,
sets `.SHELLSTATUS` to the exit status; `V != cmd` is the assignment form (`check_refusal` in parse.lu loses its `!=` line;
the reader treats `!=` before `=`/`:=`/`?=`/`+=` as gmake's precedence does — paste `A != echo one; echo two` → `one two`).
A failing command still assigns (its stdout) and `.SHELLSTATUS` carries the status. Rows `functions-shell/`; tests; README.
Commits: `rows: shell and != (red)`, `functions: shell and the != assignment`.

### P2.7 — `eval`, `let`, `file`

`$(eval text)` parses `text` as makefile lines in place (the one-pass reader gets an entry point that reads from a string
at the current line: `parse_makefile`'s loop over `Line`s is the reuse — give it a source that is a string with a base line
number); variables and rules defined that way exist from then on. `$(let a b rest,1 2 3 4,$(a)-$(b)-$(rest))` → `1-2-3 4`
(the last name takes the remainder). `$(file >name,text)` writes (a trailing newline added), `>>` appends, `<` reads (the
trailing newline dropped); a missing read file is gmake's error — paste. Rows `functions-eval/`, `functions-file-io/` (the
written files are compared by the harness's file check; the row cleans nothing); tests; `check_refusal` loses `$(eval`;
README. Commits: `rows: eval, let, file (red)`, `functions: eval, let, file`.

### P2.8 — the release and the judge

`is_gmake_function` is empty and deleted with the refusal path; the README's *Accepted* table lists every function with one
example and the *Refused* table has no function row; `./mk --help` re-pasted if it changed; the *Tests* count re-pasted;
CHANGELOG `## Unreleased` → `## 0.4.0 (date)`; `VERSION` in main.lu → `0.4.0`; commit `Release 0.4.0`. **Verify:** from a
fresh clone, the four gates; `./mk --version` → `mk 0.4.0 (built with wolf …)`; `git log --oneline | head -20`.
Stop for the judge (the reviewer re-runs the 182-probe battery — the 36 `Track 02` refusals must become parity — and
their own function matrix).
