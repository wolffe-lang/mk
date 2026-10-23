# mk

**A Make subset in wolf: targets, prerequisites, recipes, variables, automatic variables, mtime-driven rebuilds, `-n`, `-k`, and `-j N` parallel builds over a dependency graph — checked against GNU `make` on a corpus of Makefiles.**

---

## 1. What & why

`make` is the oldest build tool still in daily use and its core is small: a graph of
files, a rule for how to produce each from others, and a timestamp comparison that
decides what is out of date. Everything else (pattern rules, functions, `include`,
`.SUFFIXES`, archives) is accretion. `mk` implements the core faithfully enough that for
a corpus of plain Makefiles its decisions are **identical** to GNU make's: the same
recipes, in a valid order, the same files produced, the same no-op on a second run, the
same failure propagation.

The parallel scheduler is the interesting part. `-j 4` runs up to four recipes at once
but never a target before its prerequisites are done, never two recipes for one target,
and stops starting new work after a failure unless `-k`. Doing that with a process table
and a dependency graph, correctly, is the exercise.

### What this exercises

Process spawning and waiting (`std.process`), file mtimes (`fs.modified_ms`), a DAG with
cycle detection, a topological scheduler with bounded parallelism, a line-oriented
parser with continuation lines and tab-prefixed recipes, variable expansion with
recursion and immediate/deferred semantics, and a differential test against a real tool.

---

## 2. Background & core concepts

### 2.1 The Makefile subset

```make
CC := cc
CFLAGS = -O2 $(EXTRA)
OBJS = a.o b.o
all: prog
prog: $(OBJS)
	$(CC) -o $@ $^
%.o: %.c            # NOT in the subset (pattern rules): refused by name
a.o: a.c a.h
	$(CC) $(CFLAGS) -c -o $@ $<
.PHONY: all clean
clean:
	rm -f prog $(OBJS)
```

- **Rules:** `targets: prerequisites` followed by recipe lines that start with a **tab**.
  Multiple targets on one rule mean the rule applies to each. A target may appear in
  several rules; prerequisites accumulate and at most one rule may carry a recipe.
- **Variables:** `NAME = value` (recursive: expanded when used), `NAME := value`
  (immediate: expanded when defined), `NAME ?= value` (set if unset), `NAME += value`
  (append; keeps the flavour). Reference `$(NAME)` or `${NAME}`; `$$` is a literal `$`.
  Undefined variables expand to empty. Environment variables are visible as variables
  (Makefile assignments win unless `-e`, which is out of scope).
- **Automatic variables:** `$@` (the target), `$<` (the first prerequisite), `$^` (all
  prerequisites, deduplicated, in order), `$?` (prerequisites newer than the target).
- **Comments:** `#` to end of line (not inside a recipe line, where the shell sees it).
  **Continuation:** a trailing backslash joins the next line (with a single space).
- **`.PHONY`:** its prerequisites are always out of date and never files.
- **Recipe execution:** each recipe line runs in its own `sh -c`; a leading `@` silences
  the echo; a leading `-` ignores the exit status. Lines are echoed before running unless
  `@` or `-s`. The target's recipe is run only if the target is out of date.
- **Out of date:** the target does not exist, or any prerequisite is newer (mtime
  strictly greater), or any prerequisite was rebuilt in this run, or the target is phony.
  A prerequisite that does not exist and has no rule is an error: `mk: *** No rule to
  make target 'x', needed by 'y'.  Stop.` (match GNU's wording where the oracle compares
  stderr; see §7).
- **Default goal:** the first target in the file (not starting with `.`).

### 2.2 Parallel scheduling

Build the graph for the goals. A target is *ready* when every prerequisite is done
(up to date or rebuilt). Keep up to `N` recipes running; when one finishes, mark its
target done (or failed) and start the next ready targets. A failure stops new starts
(unless `-k`, which keeps building targets that do not depend on the failed one) and
waits for the running ones; the exit status is 2. The order of *starts* is: among ready
targets, the order they were discovered in a depth-first walk of the goals, so `-j 1`
produces exactly GNU make's serial order.

### 2.3 `-n`

Print every recipe line that would run (after expansion, without the `@`), in order,
running nothing, except lines that contain `$(MAKE)` (out of scope: treat as any line).

---

## 3. Functional requirements (numbered, testable)

- **FR-1** Parse the subset of §2.1 from `Makefile` (or `-f FILE`); refuse by name
  anything outside it (`mk: Makefile:12: pattern rules are not supported`, exit 2):
  pattern rules, `include`, `ifeq`/`ifdef`, functions (`$(wildcard …)` etc.), `define`,
  `.SUFFIXES`, `|` order-only prerequisites, `::` rules.
- **FR-2** Variable flavours and `+=`, `?=`, `$$`, env visibility, `NAME=value` on the
  command line (overrides the file).
- **FR-3** Automatic variables `$@ $< $^ $?`.
- **FR-4** The out-of-date rule of §2.1 with millisecond mtimes; `.PHONY`.
- **FR-5** Recipe execution semantics: `sh -c` per line, echo, `@`, `-`, exit status
  propagation; `mk: *** [Makefile:LINE: target] Error N` on failure, exit 2.
- **FR-6** Goals on the command line; the default goal otherwise.
- **FR-7** `-n` as §2.3; `-s` silent; `-k` keep going; `-j N` as §2.2 (`-j` alone = the
  CPU count); `-C DIR` changes directory first; `-f FILE`.
- **FR-8** Cycle detection: `mk: Circular a <- b dependency dropped.` on stderr, as GNU,
  continuing without that edge.
- **FR-9** A missing prerequisite with no rule: the error of §2.1, exit 2.
- **FR-10** `-j N` never runs two recipes for the same target, never starts a target
  before its prerequisites are done, and a run with `-j 8` produces files byte-identical
  to `-j 1` on the corpus.
- **FR-11** `-p` prints the parsed database (variables with their flavour, rules with
  their prerequisites and recipes) in a stable format for the tests.
- **FR-12** Exit: 0 up to date / built; 2 any error (GNU's convention); 1 is unused.

---

## 4. Interface / CLI spec

```
mk [-f FILE] [-C DIR] [-n] [-s] [-k] [-j [N]] [-p] [NAME=VALUE]... [GOAL]...
mk --help
```

---

## 5. Architecture guidance (described, not prescribed)

- `parse.lu` — lines with continuations and comments; assignments (four flavours);
  rules; recipes; `.PHONY`; refusals by name with line numbers.
- `vars.lu` — the variable table (`Map[str, Var]` with `value` and `flavour`), expansion
  with recursion (detect infinite recursion: `mk: *** Recursive variable 'X' references
  itself (eventually).  Stop.`), the automatic variables injected per target.
- `graph.lu` — targets, prerequisites merged across rules, the DFS discovery order,
  cycle detection, out-of-date decision (`fs.modified_ms`, `fs.exists`).
- `run.lu` — the scheduler: a ready queue in discovery order, up to N children via
  `std.process` (`command("sh")`, args `-c LINE`), `wait_status` on each, the results;
  for `-j 1` the loop is the serial case. The std has no wait-any at this pin: either
  poll children with `process.poll()` (read `process.lu` for its shape) or run each
  recipe line in a task and collect over a channel; say which and why.
- `main.lu` — flags, goals, exit status.
- `*_test.lu` — the parser on tricky lines, variable flavours, `$?` computation on a
  synthetic graph, cycle detection, the ready-order.

---

## 6. Build

```
wolf build main.lu -o mk
wolf test .
./test.sh        # the corpus against GNU make; exit 0 on pass
wolf fmt --check *.lu
```

GNU make on this machine is `/usr/bin/make` (or `gmake` if installed): `test.sh` checks
`make --version` says GNU.

---

## 7. Testing & acceptance

### 7.1 The corpus (`tests/corpus/NAME/Makefile`, each with its source files)

Write at least these, each self-contained (recipes use `cat`, `cp`, `printf`, `sort`,
`sleep`: no compiler needed):

1. `linear`: a → b → c chain of `cp`.
2. `diamond`: `all: left right`, both depend on `base`.
3. `vars`: all four flavours, `+=`, `$$`, an env var, a command-line override.
4. `auto`: `$@ $< $^ $?` in recipes writing their values to files.
5. `phony`: `.PHONY: all clean`; a file named `clean` exists.
6. `fail`: a recipe that exits 3 in the middle; another independent target.
7. `ignore`: `-false` then a real line; `@echo`.
8. `missing`: a prerequisite with no rule.
9. `cycle`: `a: b`, `b: a`.
10. `wide`: 40 independent targets each `sleep 0.2; printf x > $@` (for `-j`).
11. `refuse`: one file per refused construct (pattern rule, include, ifeq, wildcard).
12. `continuation`: backslash-joined lines and a `#` inside a recipe.

### 7.2 Rows (per corpus directory, in a fresh copy each time)

| row | check |
|---|---|
| N1 | `mk -n` output equals `make -n` output byte for byte (serial order) for 1–5, 7, 12 |
| B1 | after `mk` and after `make` (separate fresh copies), the set of files and their bytes are identical for 1–5, 7, 12 (`diff -r`) |
| B2 | a second `mk` prints `mk: Nothing to be done for 'all'.`-equivalent (match GNU's text) and runs nothing (compare with `make`'s second run output) |
| B3 | touch one source, run both: the same recipes run (compare the echoed lines) |
| F1 | `fail`: both exit 2; the error line's shape `*** [Makefile:L: target] Error 3`; with `-k` the independent target is still built by both |
| M1 | `missing`: both exit 2 with the no-rule message |
| C1 | `cycle`: both print the circular-dependency warning and exit 0 |
| R1 | `refuse`: `mk` exits 2 naming the construct and the line (GNU accepts these: the row compares only `mk`) |
| J1 | `wide`: `mk -j 8` finishes in under 2 s where `-j 1` takes ~8 s; the 40 files are identical to the `-j 1` run; never more than 8 `sleep` processes at once (`ps` sampled by the test) |
| J2 | `diamond` with `base`'s recipe `sleep 1`: under `-j 4`, `left` and `right` start only after `base` finishes (their recipes record `date +%s%N` into files; the test compares) |
| P1 | `-p` on `vars` prints each variable with its flavour (`:=`/`=`) and expanded value, matching a golden file |

### 7.3 Definition of Done

1. `wolf build`, `wolf fmt --check`, `wolf test .` clean.
2. Every row of §7.2 passes on the full corpus; `./test.sh` exits 0, `ok <row> <dir>`
   per line.
3. No recipe ever runs twice for one target in one run (J1's output has exactly 40
   echoes).

---

## 8. Milestones

1. **M1** Parser + `-p` on `vars`, `continuation`, the refusals (R1, P1).
2. **M2** Serial build of `linear`, `diamond`, `phony`, `auto` (N1, B1, B2, B3).
3. **M3** Failure semantics, `-k`, `missing`, `cycle` (F1, M1, C1).
4. **M4** `-j N` with the scheduler (J1, J2), `-C`, `-f`, `-s`.
5. **M5** `test.sh` over the whole corpus; the golden for `-p`.

## 9. Stretch goals

- Pattern rules `%.o: %.c` (the first accretion worth having).
- `$(wildcard)`, `$(patsubst)`, `$(shell)`.
- `include` and `-include`.
- A `--graph` that prints the DAG in DOT.

## 10. Constraints & non-goals

- One directory, std only. No reading of GNU make's source; its documentation and the
  binary's behaviour are the oracle.
- Not a replacement for make on real projects: the subset is the contract.
